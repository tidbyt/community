"""
Applet: Weather Map
Summary: Weather Map
Description: Display real-time precipitation radar for a location. Supports rainfall and snow. Powered by the RainViewer API.
Author: Felix Bruns
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# The RainViewer API endpoints used to retrieve rain radar images.
#
# This applet uses APIs provided by https://www.rainviewer.com/api.html,
# which are free, with data sourced from many different providers in the
# world.
#
# Please consider becoming a Patron to support them:
#   https://www.patreon.com/rainviewer
#
WEATHER_MAPS_URL = "https://api.rainviewer.com/public/weather-maps.json"
IMAGE_URL_LAYOUT = "{host}{path}/{size}/{zoom}/{lat}/{lng}/{color}/{smooth}_{snow}.png"

# The RainViewer API provides data for the past 2 hours and a forecast
# of 30 minutes.
#
# Keep tile images from the past cached for 2 hours, as after that
# point they definitely won't be used again.
#
# Keep tile images from the forecast cached for only a short time, as
# they will frequently change.
#
IMAGE_CACHE_PAST_TTL_SECONDS = 7200
IMAGE_CACHE_FORECAST_TTL_SECONDS = 120

# A list of color schemes available in the RainViewer API:
#
#   https://www.rainviewer.com/api/color-schemes.html
#
# There seem to be more color schemes at least up to value "22". These
# are currently omitted here, as it is unclear whether RainViewer allows
# API callers to use those freely or restrict them to their mobile apps.
#
# Additionally mappings from names to values are unknown for these.
#
# The color scheme with value "0" is actually a "Black & White" image
# containing "dBZ" (decibels) values encoded in the image pixels, and
# is therefore also excluded from the below list, as it is useless to
# display as-is.
#
COLOR_SCHEMES = [
    schema.Option(display = "Original", value = "1"),
    schema.Option(display = "Universal Blue", value = "2"),
    schema.Option(display = "TITAN", value = "3"),
    schema.Option(display = "The Weather Channel (TWC)", value = "4"),
    schema.Option(display = "Meteored", value = "5"),
    schema.Option(display = "NEXRAD Level III", value = "6"),
    schema.Option(display = "Rainbow @ SELEX-IS", value = "7"),
    schema.Option(display = "Dark Sky", value = "8"),
]
DEFAULT_COLOR_SCHEME = COLOR_SCHEMES[1]

# A list of delays to choose from.
FRAME_DELAYS = [
    schema.Option(display = "100 ms", value = "100"),
    schema.Option(display = "250 ms", value = "250"),
    schema.Option(display = "500 ms", value = "500"),
    schema.Option(display = "750 ms", value = "750"),
    schema.Option(display = "1 s", value = "1000"),
]
DEFAULT_FRAME_DELAY = FRAME_DELAYS[1]

# A list of supported time formats and the corresponding layout strings.
TIME_FORMATS = [
    schema.Option(
        display = "Off",
        value = "off",
    ),
    schema.Option(
        display = "12-hour",
        value = "3:04 PM",
    ),
    schema.Option(
        display = "24-hour",
        value = "15:04",
    ),
]
DEFAULT_TIME_FORMAT = TIME_FORMATS[2]

# A list of supported distance units.
UNIT_FORMATS = [
    schema.Option(
        display = "Off",
        value = "off",
    ),
    schema.Option(
        display = "Kilometers",
        value = "km",
    ),
    schema.Option(
        display = "Miles",
        value = "mi",
    ),
]
DEFAULT_UNIT_FORMAT = UNIT_FORMATS[0]

# There theoretically are zoom levels 0 through 23, but zooming in closer
# than an area 9x9 km is of questionable usability due to Tidbyt screen size.
#
# The following table lists zoom levels and their corresponding resolution
# in meters / kilometers per pixel at a resolution of 256 and 64 pixels.
#
# Source: https://www.maptiler.com/google-maps-coordinates-tile-bounds-projection
#
# Given these values we can choose a minimum required accuracy that we can
# truncate latitude and longitude to, in order to protect the users privacy,
# by not leaking their exact location to a third-party API.
#
# The maximum accuracy we allow is 0.01 degrees (two decimal places), which
# corresponds to about 1.11 km.
#
# See: https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude
#
#  1    degree ~ 111    km
#  0.1  degree ~  11.1  km
#  0.01 degree ~   1.11 km
#
# +-------+-------------+-------------+---------------+
# | Level | 1px @ 256px | 1px @ 64 px | Accuracy used |
# +-------+-------------+-------------+---------------+
# |     0 |    ~ 157 km |    ~ 626 km | 1    degree   |
# |     1 |     ~ 78 km |    ~ 313 km | 1    degree   |
# |     2 |     ~ 39 km |    ~ 157 km | 1    degree   |
# |     3 |     ~ 20 km |     ~ 78 km | 0.1  degree   |
# |     4 |     ~ 10 km |     ~ 39 km | 0.1  degree   |
# |     5 |      ~ 5 km |     ~ 20 km | 0.1  degree   |
# |     6 |    ~ 2.5 km |     ~ 10 km | 0.1  degree   |
# |     7 |    ~ 1.2 km |      ~ 5 km | 0.01 degree   |
# |     8 |     ~ 600 m |    ~ 2.5 km | 0.01 degree   |
# |     9 |     ~ 300 m |    ~ 1.2 km | 0.01 degree   |
# |    10 |     ~ 150 m |     ~ 600 m | 0.01 degree   |
# |    11 |      ~ 80 m |     ~ 300 m | 0.01 degree   |
# |    12 |      ~ 40 m |     ~ 150 m | 0.01 degree   |
# +-------+-------------+-------------+---------------+
#
ZOOM_LEVEL_TABLE = [
    # Level | 1px @ 256px | Accuracy
    #
    # Use "#.0", as the API only accepts floating point values,
    # and will return the wrong image tile if we use an integer.
    (0, 156543.0339, "#.0"),
    (1, 78271.51696, "#.0"),
    (2, 39135.75848, "#.0"),
    (3, 19567.87924, "#.#"),
    (4, 9783.939620, "#.#"),
    (5, 4891.969810, "#.#"),
    (6, 2445.984905, "#.#"),
    (7, 1222.992452, "#.##"),
    (8, 611.4962263, "#.##"),
    (9, 305.7481131, "#.##"),
    (10, 152.8740566, "#.##"),
    (11, 76.43702829, "#.##"),
    (12, 38.21851414, "#.##"),
]

def get_zoom_level_size(zoom_level):
    """Get the width a zoom level covers in kilometers and miles.

    Args:
        zoom_level: A zoom level.

    Returns:
        A tuple containing the values in kilometers and miles.
    """
    (_, m_per_pixel, _) = ZOOM_LEVEL_TABLE[zoom_level]
    km = 256 * m_per_pixel // 1000
    mi = km * 0.621371
    return (km, mi)

# A list of zoom levels to choose from
#
# This goes from "0" (earth) to "23" (2 cm per pixel)
ZOOM_LEVELS = [
    schema.Option(
        display = "%d km / %d mi" % get_zoom_level_size(level),
        value = "%d" % level,
    )
    for level in range(len(ZOOM_LEVEL_TABLE))
]
DEFAULT_ZOOM_LEVEL = ZOOM_LEVELS[7]

DEFAULT_SNOW_OPTION = "1"
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def render_frame(frame, image, opts):
    """Render a frame of the weather layer animation.

    Args:
        frame: A frame object.
        image: A binary image.
        opts: A struct of rendering options.

    Returns:
        A definition of the frame to render.
    """
    location = getattr(opts, "location")
    time_format = getattr(opts, "time_format")
    time_utc = time.from_timestamp(int(frame["time"]))
    time_in_location = time_utc.in_location(location["timezone"])
    time_str = time_in_location.format(time_format)
    zoom_level = getattr(opts, "zoom_level")
    (km, mi) = get_zoom_level_size(zoom_level)
    unit_format = getattr(opts, "unit_format")
    unit_str = "%d km" % km if unit_format == "km" else "%d mi" % mi

    show_time = True if time_format != "off" else False
    show_unit = True if unit_format != "off" else False

    return render.Stack(children = [
        render.Padding(
            pad = (0, -16, 0, 0),
            child = render.Image(
                src = image,
                width = 64,
                height = 64,
            ),
        ),
        render.Box(
            height = 7,
            color = "#0007",
            child = render.Text(
                content = time_str,
                offset = -1,
                color = "#fff",
                font = "tom-thumb",
            ),
        ) if show_time else None,
        render.Padding(
            child = render.Box(
                height = 7,
                color = "#0007",
                child = render.Text(
                    content = unit_str,
                    offset = -1,
                    color = "#fff",
                    font = "tom-thumb",
                ),
            ),
            pad = (0, 32 - 7, 0, 0),
        ) if show_unit else None,
        render.Box(child = render.Circle(
            diameter = 3,
            color = "#f00a",
        )),
    ])

def create_image_url(frame, opts):
    """Create a tile image URL given the frame and rendering options.

    Args:
        frame: A frame object.
        opts: A struct of rendering options.

    Returns:
        An image URL.
    """
    zoom_level = getattr(opts, "zoom_level")
    location = getattr(opts, "location")
    (_, _, accuracy) = ZOOM_LEVEL_TABLE[zoom_level]

    # Truncate latitude and longitude to protect the users privacy,
    # by not leaking their exact location to a third-party API.
    lat = humanize.float(accuracy, float(location["lat"]))
    lng = humanize.float(accuracy, float(location["lng"]))

    return IMAGE_URL_LAYOUT.format(
        host = getattr(opts, "host"),
        path = frame["path"],
        lat = lat,
        lng = lng,
        size = 256,
        zoom = zoom_level,
        color = getattr(opts, "color_scheme"),
        smooth = 0,
        snow = getattr(opts, "snow"),
    )

def fetch_image(frame, opts, is_from_past):
    """Fetch an image given the frame and rendering options (with caching).

    Args:
        frame: A frame object.
        opts: A struct of rendering options.
        is_from_past: Whether the image is from the past or from a forecast.

    Returns:
        A string of binary image data.
    """
    url = create_image_url(frame, opts)

    data = cache.get(url)
    if data != None:
        return data

    response = http.get(url = url)
    if response.status_code != 200:
        print("Image request failed with status %d" % response.status_code)
        return None

    data = response.body()

    ttl_seconds = IMAGE_CACHE_PAST_TTL_SECONDS if is_from_past else IMAGE_CACHE_FORECAST_TTL_SECONDS
    cache.set(url, data, ttl_seconds = ttl_seconds)

    return data

def fetch_images(radar, opts):
    images_past = [(frame, fetch_image(frame, opts, True)) for frame in radar["past"]]
    images_forecast = [(frame, fetch_image(frame, opts, False)) for frame in radar["nowcast"]]
    return images_past + images_forecast

def render_error():
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = "Error loading weather maps!",
                color = "#f00",
            ),
        ),
    )

def main(config):
    """The applet entry point.

    Args:
        config: The applet configuration.

    Returns:
        A definition of what to render.
    """
    response = http.get(url = WEATHER_MAPS_URL)

    if response.status_code != 200:
        print("API request failed with status %d" % response.status_code)
        return render_error()

    data = response.json()
    opts = struct(
        host = data["host"],
        location = json.decode(config.get("location", DEFAULT_LOCATION)),
        zoom_level = int(config.get("zoom_level", DEFAULT_ZOOM_LEVEL.value)),
        color_scheme = int(config.get("color_scheme", DEFAULT_COLOR_SCHEME.value)),
        frame_delay = int(config.get("frame_delay", DEFAULT_FRAME_DELAY.value)),
        time_format = config.get("time_format", DEFAULT_TIME_FORMAT.value),
        unit_format = config.get("unit_format", DEFAULT_UNIT_FORMAT.value),
        snow = "1" if config.bool("snow") else "0",
    )

    # Fetch all radar images.
    frames_and_images = fetch_images(data["radar"], opts)

    # Render an error message if any of the frames failed to render.
    if any([image == None for (frame, image) in frames_and_images]):
        return render_error()

    # Render a frame for each item of radar data in the past and in the forecast.
    frames = [render_frame(frame, image, opts) for (frame, image) in frames_and_images]

    return render.Root(
        child = render.Animation(children = frames),
        delay = getattr(opts, "frame_delay"),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather radar.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "zoom_level",
                name = "Zoom Level",
                desc = "Pick a zoom level.",
                icon = "globe",
                default = DEFAULT_ZOOM_LEVEL.value,
                options = ZOOM_LEVELS,
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color Scheme",
                desc = "Pick a color scheme.",
                icon = "palette",
                default = DEFAULT_COLOR_SCHEME.value,
                options = COLOR_SCHEMES,
            ),
            schema.Dropdown(
                id = "frame_delay",
                name = "Speed",
                desc = "Pick a delay between frames.",
                icon = "stopwatch",
                default = DEFAULT_FRAME_DELAY.value,
                options = FRAME_DELAYS,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Overlay",
                desc = "Pick a time format.",
                icon = "clock",
                default = DEFAULT_TIME_FORMAT.value,
                options = TIME_FORMATS,
            ),
            schema.Dropdown(
                id = "unit_format",
                name = "Coverage Overlay",
                desc = "Pick a distance unit.",
                icon = "ruler",
                default = DEFAULT_UNIT_FORMAT.value,
                options = UNIT_FORMATS,
            ),
            schema.Toggle(
                id = "snow",
                name = "Snow Layer",
                desc = "Enable or disable snow layer.",
                icon = "snowflake",
                default = True,
            ),
        ],
    )

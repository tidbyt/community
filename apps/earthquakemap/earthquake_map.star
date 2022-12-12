"""
Applet: Earthquake Map
Summary: Map of global earthquakes
Description: Display a map of earthquakes based on USGS data. (v0.2.0)
Author: Brian McLaughlin (SpinStabilized)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------

# The following DEFAULT_ configurations are strings for compatibility with the
# `config` and `schema` libraries.
DEFAULT_MAG_FILTER = "4"
DEFAULT_TIME_FILTER_DURATION = "1"
DEFAULT_TIME_FILTER_UNITS = "days"
DEFAULT_HIDE_WHEN_EMPTY = False
DEFAULT_MAP_CENTER_ID = "Prime Meridian"
DEFAULT_USER_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""
DEFAULT_INCLUDE_EARTHQUAKE = True
DEFAULT_INCLUDE_ICEQUAKE = True
DEFAULT_INCLUDE_QUARRY = True
DEFAULT_INCLUDE_EXPLOSION = True
DEFAULT_INCLUDE_OTHER = True
DEFAULT_MAP_BRIGHTNESS = "0.25"

HTTP_STATUS_OK = 200

API_CACHE_TTL = 60  # seconds

EARTHQUAKES_LAST_30_DAYS_URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------
def uint8_to_hex(uint8, add_prefix = False):
    """Take an integer value and return a hex string.

    Given an 8 bit unsigned integer, convert the value to a hex string. If the
    given value is not an unisgned integer, no guarantee is given of the
    returned value. If the integer is larger than 255 (8-bits), only the hex
    value of the lower 8-bits will be returned.

    Args:
        uint8: 8-bit, unsigned, integer
        add_prefix: Boolean to indicate if "0x" should be prepended to the result.

    Returns:
        Hex string representation of the input.
    """
    hex_numerals = [
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
    ]
    hex_string = "0x" if add_prefix else ""
    hex_string = hex_string + hex_numerals[(uint8 & 0xf0) >> 4]
    hex_string = hex_string + hex_numerals[uint8 & 0xf]
    return hex_string

#-------------------------------------------------------------------------------
# USGS API Functions
#-------------------------------------------------------------------------------

def get_usgs_data(magnitude_filter = None, time_filter = None, type_filter = None):
    """Retrieve GeoJSON earthquake data from the USGS.

    Retrieve all earthquake data in GeoJSON format from the las 30 days and
    will return a list of events.

    For more information on the USGS earthquake API GeoJSON enpoints please
    visit:

    https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php

    Args:
       magnitude_filter (number): The lower-bound magnitude to display.
       time_filter (number): Time period in seconds from the current time to
       display.
       type_filter (dict): Filter on various types of events

    Returns:
       A list of earthquake events in the following format -
            [(lon, lat), magnitude, time]
    """
    if magnitude_filter == None:
        magnitude_filter = 0
    if time_filter == None:
        time_filter = duration_calc(30, "days")
    time_filter = time.parse_duration("{}s".format(time_filter))

    geojson_raw = cache.get("raw_earthquake_data")
    if geojson_raw == None:
        api_reply = http.get(EARTHQUAKES_LAST_30_DAYS_URL)
        if api_reply.status_code == HTTP_STATUS_OK:
            geojson_raw = api_reply.body()
        else:
            geojson_raw = '{"features":[]}'

        cache.set("raw_earthquake_data", geojson_raw, ttl_seconds = 60)

    events = []

    current_time = time.now().in_location("UTC")
    geojson_events = json.decode(geojson_raw)["features"]
    for event in geojson_events:
        if event["properties"]["mag"] != None:
            new_event = [
                (
                    float(event["geometry"]["coordinates"][0]),
                    float(event["geometry"]["coordinates"][1]),
                ),
                float(event["properties"]["mag"]),
                time.from_timestamp(int(event["properties"]["time"] // 1000)),  # convert from ms to seconds
                event["properties"]["type"],
            ]

            if new_event[1] >= magnitude_filter and \
               current_time - new_event[2] <= time_filter and \
               (type_filter == None or type_filter[new_event[3]]):
                events.append(new_event)

    events = sorted(events, key = lambda item: item[2])
    return events

def duration_calc(time_filter, units = None):
    """Convert a time for filtering to seconds.

    Args:
       time_filter (number): The time period for filtering.
       units (string): Unit for the filter time period. Defaults to minutes.

    Returns:
       (number) The input time in seconds.
    """
    conversion_dict = {
        "seconds": 1,
        "minutes": 60,
        "hours": 60 * 60,
        "days": 60 * 60 * 24,
    }

    if units == None or units not in conversion_dict.keys():
        units = "minutes"

    return time_filter * conversion_dict[units]

#-------------------------------------------------------------------------------
# Map Utility Functions
#-------------------------------------------------------------------------------

def mag_to_color(magnitude):
    """Converts an earthquake magnitude to a color to display.

    Accepts an earthquake magnitude as a numeric value and converts it into a
    color based on the color map. Magnitudes above the highest index in the
    color map will be clipped as the strongest indicator. Provides color as a
    string representation of a 16-bit hex RGB color code (#rrggbb).

    Args:
        magnitude: An earthquake magnitude

    Returns:
        A string RGB 16 bit hex color code of the format #rrggbb
    """
    color_map = [
        "#00b5b8",  # Mag 0, Teal
        "#bf40bf",  # Mag 1, Purple
        "#08e8de",  # Mag 2, Light Blue
        "#0000ff",  # Mag 3, Blue
        "#00ff00",  # Mag 4, Green
        "#fff000",  # Mag 5, Yellow
        "#ffaa1d",  # Mag 6, Orange
        "#ff0000",  # Mag 7+, Red
    ]
    int_mag = len(color_map) - 1 if magnitude >= len(color_map) else int(magnitude)
    return color_map[int_mag]

def map_projection(longitude, latitude, screen_width = 64, screen_height = 32):
    """Project's a map longitude/latitude to screen coordinates.

    Args:
        longitude: A map coordinate longitude
        latitude: A map coordinate latitude
        screen_width: size of the screen/image to project to
        screen_height: height of the screen/image to project to

    Returns:
        An (x, y) tuple in the screen/image pixel coordinates
    """
    radius = screen_width / (2 * math.pi)
    longitude_radians = math.radians(longitude + 180)
    latitude_radians = math.radians(latitude)

    x = longitude_radians * radius
    y_from_eq = radius * math.log(math.tan(math.pi / 4 + latitude_radians / 2))
    y = screen_height / 2 - y_from_eq
    return int(x), int(y)

def render_map(map_array, map_center = 0, brightness = 0.25):
    """Shift pixels to account for map central merdian.

    Args:
        map_array: 2-dimensional array indicating coastlines
        map_center: Map center meridian
        brightness: Brightness of the map [0...255], default 25% (0.25)

    Returns:
        A `render.Stack` of pixels that represent the map.
    """
    map_stack = []
    for y, row in enumerate(map_array):
        for x, map_pixel in enumerate(row):
            if map_pixel:
                x = pixel_shift(x, map_center)
                map_stack.append(
                    pixel(x, y, "#FFFFFF", brightness),
                )
    return render.Stack(children = map_stack)

def pixel_shift(x, center_longitude = 0):
    """Shift pixels to account for map central merdian.

    Args:
        x: Tidbyt display x position [0...63]
        center_longitude: Map center meridian

    Returns:
        A new x coordinate shifted with the merdian
    """
    new_center_x, _ = map_projection(center_longitude, 0)
    current_center_x, _ = map_projection(0, 0)
    delta = current_center_x - new_center_x
    new_x = x + delta
    if new_x > 63:
        new_x = new_x - 64
    if new_x < 0:
        new_x = 64 - new_x
    return new_x

#-------------------------------------------------------------------------------
# Render Utility Functions
#-------------------------------------------------------------------------------

def pixel(x, y, color, alpha = 1.0):
    """Pixel by pixel drawing for Tidbyt

    Accepts a pixel coordinate as x and y integers on the Tidbyt display as well
    as a color definition and provides a `render.Padding` object back to be used
    in rendering. The color definition uses the Tidbyt color specifications #rgb,
    #rrggbb, #rgba, and #rrggbbaa.

    This is based on the work of Tidbyt Discuss user kay where they developed
    some amazing spirte based demos for the Tidbyt:

    https://discuss.tidbyt.com/t/animating-with-sprites/978

    Note: If the color provided is suspected of having an alpha already defined,
    the value of the alpha parameter to the function is ignored.

    Args:
        x: Tidbyt display x position [0...63]
        y: Tidbyt display x position [0...31]
        color: Hex color value
        alpha: Decimal percentage of full brightness [0...1]

    Returns:
        A `render.Padding` object for the pixel location
    """
    if len(color) != 5 and len(color) != 9:
        color = color + uint8_to_hex(int(alpha * 255))
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = 1, height = 1, color = color),
    )

def blink_pixel(x, y, color):
    """Pixel by pixel drawing for Tidbyt, a blinking pixel

    Accepts a pixel coordinate as x and y integers on the Tidbyt display as well
    as a color definition and provides a `render.Padding` object back to be used
    in rendering. The color definition uses the Tidbyt color specifications
    #rgb and #rrggbb. If a color has an alpha, the alpha will be ignored.

    This is based on the work of Tidbyt Discuss user kay where they developed
    some amazing spirte based demos for the Tidbyt:

    https://discuss.tidbyt.com/t/animating-with-sprites/978

    Note: If the color provided is suspected of having an alpha already defined,
    the value of the alpha parameter to the function is ignored.

    Args:
        x: Tidbyt display x position [0...63]
        y: Tidbyt display x position [0...31]
        color: Hex color value

    Returns:
        A `render.Animation` object for the pixel location
    """
    if len(color) == 5:
        color = color[:-1]
    if len(color) == 9:
        color = color[:-2]

    # alpha_range = [i / 100 for i in range(0, 100, 10)] + [i / 100 for i in range(99, 1, -10)]
    alpha_range = [0, 100]
    blink_pixel = [pixel(x, y, color, alpha = i) for i in alpha_range]

    return render.Animation(
        children = blink_pixel,
    )

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

def main(config):
    """Main function body.

    Args:
       config: A Tidbyt configuration object

    Returns:
        A `render.Root` object.
    """

    # Define configuration, use defaults if a configuration parameter can't be
    # found.
    magnitude_filter = int(config.str("mag_filter", DEFAULT_MAG_FILTER))
    time_filter_duration = int(config.get("time_filter_duration", DEFAULT_TIME_FILTER_DURATION))
    time_filter_units = config.get("time_filter_units", DEFAULT_TIME_FILTER_UNITS)
    hide_when_empty = config.bool("hide_when_empty", DEFAULT_HIDE_WHEN_EMPTY)
    map_center_id = config.str("map_center_id", DEFAULT_MAP_CENTER_ID)
    user_location = config.str("location", DEFAULT_USER_LOCATION)
    type_filter = {
        "earthquake": config.bool("include_earthquake", DEFAULT_INCLUDE_EARTHQUAKE),
        "ice quake": config.bool("include_icequake", DEFAULT_INCLUDE_ICEQUAKE),
        "quarry blast": config.bool("include_quarry", DEFAULT_INCLUDE_QUARRY),
        "explosion": config.bool("include_explosion", DEFAULT_INCLUDE_EXPLOSION),
        "other event": config.bool("include_other", DEFAULT_INCLUDE_OTHER),
    }
    map_brightness = float(config.get("map_brightness", DEFAULT_MAP_BRIGHTNESS))

    time_filter = duration_calc(time_filter_duration, time_filter_units)

    if map_center_id == "Prime Meridian":
        map_center = 0
    elif map_center_id == "Date Line":
        map_center = -180
    elif map_center_id == "Tidbyt Location":
        map_center = int(float(json.decode(user_location)["lng"]))
    else:
        map_center = 0

    # Process the earthquakes and generate render data
    earthquake_events = get_usgs_data(
        magnitude_filter = magnitude_filter,
        time_filter = time_filter,
        type_filter = type_filter,
    )

    if earthquake_events:
        render_stack = [render_map(WORLD_MAP_ARRAY, map_center, map_brightness)]
        if len(earthquake_events) > 1:
            for event in earthquake_events[:-1]:
                x, y = map_projection(event[0][0], event[0][1])
                x = pixel_shift(x, map_center)
                render_stack.append(
                    pixel(x, y, mag_to_color(event[1])),
                )

        last_event = earthquake_events[-1]
        x, y = map_projection(last_event[0][0], last_event[0][1])
        x = pixel_shift(x, map_center)
        render_stack.append(
            blink_pixel(x, y, mag_to_color(last_event[1])),
        )

        return render.Root(
            delay = 500,
            child = render.Stack(
                children = render_stack,
            ),
        )
    elif not hide_when_empty:
        return render.Root(
            child = render_map(WORLD_MAP_ARRAY, map_center),
        )
    else:
        return []

def get_schema():
    """Provide the schema for the Tidbyt app configuration.

    Returns:
        A `schema.Schema` object.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "hide_when_empty",
                name = "Hide When Empty",
                desc = "Enable to hide app when there are no earthquakes to display.",
                icon = "eyeSlash",
                default = DEFAULT_HIDE_WHEN_EMPTY,
            ),
            schema.Dropdown(
                id = "map_brightness",
                name = "Map Layer Brightness",
                desc = "Set the brightness of the map layer from 0 to 100%.",
                icon = "sun",
                options = [
                    schema.Option(display = "  0%", value = "0.00"),
                    schema.Option(display = "  5%", value = "0.05"),
                    schema.Option(display = " 10%", value = "0.10"),
                    schema.Option(display = " 15%", value = "0.15"),
                    schema.Option(display = " 20%", value = "0.20"),
                    schema.Option(display = " 25%", value = "0.25"),
                    schema.Option(display = " 30%", value = "0.30"),
                    schema.Option(display = " 35%", value = "0.35"),
                    schema.Option(display = " 40%", value = "0.40"),
                    schema.Option(display = " 45%", value = "0.45"),
                    schema.Option(display = " 50%", value = "0.50"),
                    schema.Option(display = " 55%", value = "0.55"),
                    schema.Option(display = " 60%", value = "0.60"),
                    schema.Option(display = " 65%", value = "0.65"),
                    schema.Option(display = " 70%", value = "0.70"),
                    schema.Option(display = " 75%", value = "0.75"),
                    schema.Option(display = " 80%", value = "0.80"),
                    schema.Option(display = " 85%", value = "0.85"),
                    schema.Option(display = " 90%", value = "0.90"),
                    schema.Option(display = " 95%", value = "0.95"),
                    schema.Option(display = "100%", value = "1.00"),
                ],
                default = DEFAULT_MAP_BRIGHTNESS,
            ),
            schema.Dropdown(
                id = "mag_filter",
                name = "Magnitude Filter",
                desc = "Minimum magnitude to display.",
                icon = "houseCrack",
                options = [
                    schema.Option(display = "0", value = "0"),
                    schema.Option(display = "1", value = "1"),
                    schema.Option(display = "2", value = "2"),
                    schema.Option(display = "3", value = "3"),
                    schema.Option(display = "4", value = "4"),
                    schema.Option(display = "5", value = "5"),
                    schema.Option(display = "6", value = "6"),
                    schema.Option(display = "7", value = "7"),
                ],
                default = DEFAULT_MAG_FILTER,
            ),
            schema.Text(
                id = "time_filter_duration",
                name = "Duration Filter",
                desc = "Duration in specified units to filter.",
                icon = "clock",
                default = DEFAULT_TIME_FILTER_DURATION,
            ),
            schema.Dropdown(
                id = "time_filter_units",
                name = "Duration Filter Units",
                desc = "Units of time for the duration filter.",
                icon = "clock",
                options = [
                    schema.Option(display = "Day(s)", value = "days"),
                    schema.Option(display = "Hour(s)", value = "hours"),
                    schema.Option(display = "Minute(s)", value = "minutes"),
                    schema.Option(display = "Second(s)", value = "seconds"),
                ],
                default = DEFAULT_TIME_FILTER_UNITS,
            ),
            schema.Toggle(
                id = "include_earthquake",
                name = "Include Earthquakes",
                desc = "Include earthquake events in display.",
                icon = "houseCrack",
                default = DEFAULT_INCLUDE_EARTHQUAKE,
            ),
            schema.Toggle(
                id = "include_icequake",
                name = "Include Ice Quakes",
                desc = "Include ice quake events in display. (US Only)",
                icon = "icicles",
                default = DEFAULT_INCLUDE_ICEQUAKE,
            ),
            schema.Toggle(
                id = "include_quarry",
                name = "Include Quarry Blasts",
                desc = "Include quarry blasting events in display. (US Only)",
                icon = "hillRockslide",
                default = DEFAULT_INCLUDE_QUARRY,
            ),
            schema.Toggle(
                id = "include_explosion",
                name = "Include Explosions",
                desc = "Include explosion events in display. (US Only)",
                icon = "explosion",
                default = DEFAULT_INCLUDE_EXPLOSION,
            ),
            schema.Toggle(
                id = "include_other",
                name = "Include Other Events",
                desc = "Include other, unspecified, events in display. (US Only)",
                icon = "question",
                default = DEFAULT_INCLUDE_OTHER,
            ),
            schema.Dropdown(
                id = "map_center_id",
                name = "Map Center",
                desc = "The meridian at the center of the map.",
                icon = "compass",
                options = [
                    schema.Option(display = "Prime Merdian", value = "Prime Meridian"),
                    schema.Option(display = "Date Line", value = "Date Line"),
                    schema.Option(display = "Tidbyt Location", value = "Tidbyt Location"),
                ],
                default = DEFAULT_MAP_CENTER_ID,
            ),
            schema.Generated(
                id = "location_option",
                source = "map_center_id",
                handler = schema_location,
            ),
        ],
    )

def schema_location(map_center_id):
    if map_center_id == "Tidbyt Location":
        return [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to select the map central meridian.",
                icon = "locationDot",
            ),
        ]
    else:
        return []

#------------------------------------------------------------------------------
# Resources
#------------------------------------------------------------------------------

# Coastline Map generated from GeoJSON data found at:
# https://github.com/simonepri/geo-maps/blob/master/info/earth-coastlines.md
WORLD_MAP_ARRAY = [
    [0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
    [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
]

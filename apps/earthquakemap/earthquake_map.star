"""
Applet: Earthquake Map
Summary: Map of global earthquakes
Description: Display a map of earthquakes based on USGS data.
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
DEFAULT_MAG_FILTER = "1"
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

HTTP_STATUS_OK = 200

API_CACHE_TTL = 60  # seconds

EARTHQUAKES_LAST_30_DAYS_URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson"

#-------------------------------------------------------------------------------
# USGS API Functions
#-------------------------------------------------------------------------------

def get_usgs_data(magnitude_filter = None, time_filter = None):
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
            ]

            if new_event[1] >= magnitude_filter and \
               current_time - new_event[2] <= time_filter:
                events.append(new_event)

    events = sorted(events, key = lambda item: item[1])
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
        "#ffffff",  # Mag 0, White
        "#330044",  # Mag 1, Violet
        "#220066",  # Mag 2, Indigo
        "#1133cc",  # Mag 3, Blue
        "#33dd00",  # Mag 4, Green
        "#ffda21",  # Mag 5, Yellow
        "#ff6622",  # Mag 6, Orange
        "#d10000",  # Mag 7+, Red
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

def render_map(map_array, map_center = 0):
    """Shift pixels to account for map central merdian.

    Args:
        map_array: 2-dimensional array indicating coastlines
        map_center: Map center meridian

    Returns:
        A `render.Stack` of pixels that represent the map.
    """
    map_stack = []
    for y, row in enumerate(map_array):
        for x, map_pixel in enumerate(row):
            if map_pixel:
                x = pixel_shift(x, map_center)
                map_stack.append(
                    pixel(x, y, "#404040"),
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

def pixel(x, y, color):
    """Pixel by pixel drawing for Tidbyt

    Accepts a pixel coordinate as x and y integers on the Tidbyt display as well
    as a color definition and provides a `render.Padding` object back to be used
    in rendering. The color definition uses the Tidbyt color specifications #rgb,
    #rrggbb, #rgba, and #rrggbbaa.

    This is based on the work of Tidbyt Discuss user kay where they developed
    some amazing spire based demos for the Tidbyt:

    https://discuss.tidbyt.com/t/animating-with-sprites/978

    Args:
        x: Tidbyt display x position [0...63]
        y: Tidbyt display x position [0...31]
        color: foo

    Returns:
        A `render.Padding` object for the pixel location
    """
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = 1, height = 1, color = color),
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
    magnitude_filter = int(config.str("mag_filter") or DEFAULT_MAG_FILTER)
    time_filter_duration = int(config.get("time_filter_duration") or DEFAULT_TIME_FILTER_DURATION)
    time_filter_units = config.get("time_filter_units") or DEFAULT_TIME_FILTER_UNITS
    hide_when_empty = config.bool("hide_when_empty") or DEFAULT_HIDE_WHEN_EMPTY
    map_center_id = config.str("map_center_id") or DEFAULT_MAP_CENTER_ID
    user_location = config.str("user_location") or DEFAULT_USER_LOCATION

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
    )

    if earthquake_events:
        render_stack = [render_map(WORLD_MAP_ARRAY, map_center)]
        for event in earthquake_events:
            x, y = map_projection(event[0][0], event[0][1])
            x = pixel_shift(x, map_center)
            render_stack.append(
                pixel(x, y, mag_to_color(event[1])),
            )

        return render.Root(
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
                default = False,
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
                default = "4",
            ),
            schema.Text(
                id = "time_filter_duration",
                name = "Duration Filter",
                desc = "Duration in specified units to filter.",
                icon = "clock",
                default = "2",
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
                default = "days",
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
                default = "Prime Meridian",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to select the map central meridian.",
                icon = "locationDot",
            ),
        ],
    )

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

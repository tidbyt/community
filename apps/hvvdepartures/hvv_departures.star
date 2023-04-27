"""
Applet: HVV Departures
Summary: HVV Departures
Description: Display real-time departure times for trains, buses and ferries in Hamburg (HVV).
Author: fxb (Felix Bruns)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# The API endpoints used to retrieve locations and departures.
#
# This applet uses APIs provided by https://transport.rest/, which provide
# real-time data, without any API keys, reasonable rate-limits and for free.
#
# Currently this applet only supports departure times for Hamburg (HVV),
# but can theoretically be re-used for Berlin & Brandenburg (VBB, BVG) or
# even "Deutsche Bahn" long-distance trains.
#
# Please consider supporting the maintainer of these APIs:
#   https://github.com/sponsors/derhuerst
#
HVV_REST_API_LOCATIONS_URL = "https://v5.hvv.transport.rest/locations"
HVV_REST_API_DEPARTURES_URL = "https://v5.hvv.transport.rest/stops/%s/departures"

# Cache API responses for a short time, as we want things to be as recent as possible.
CACHE_TTL_SECONDS = 30

# The RFC3339 date and time format string used by Go / Starlark.
RFC3339_FORMAT = "2006-01-02T15:04:05Z07:00"

# The default station ID to use, if none is set by the user.
# This currently defaults to "Hamburg Hbf" (main station).
DEFAULT_STATION_ID = "90"

# Background images for known lines, as well as the HVV logo.
IMAGE_LOGO = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAKCAYAAADVTVykAAABhUlEQVR4AbzTA4ycQRTA8VfbthvUtm3bilXHNYLathnVto2zbWsx97/LYrIKDi/5LR8G+USUPMFslBFL5DQdUh07sU+KPJT8RxB2oy9KMbghfBBVHAtoglVIRDJa6wtAfSzEXmxBJ1TGRCxGbdGC720xD8PR2ZLT1yGnMqZjkTBwPd4jFfdRW1tAJE4iA8riFwbhLhQW5TQZXFJrfgAGbMVEKDxFRS2nD5IRKgyMxRG0FEtoCzBjHzpbnIHCTQxBDP6jo1aXiQA0y248sATvX5CFMfk5TYaU4/NlJGKFMLimOIS2AAO7q+hwvAqfc5oOrs37NihsRTlshMIOrWYB4nHNMnw2YnCD3mXFIRwXECNaUFDDMuAbn6vx3hxp+ItZCMZntHe478uIwly8RgpGirtw9xQYmgypri/AknsRRoRBYR5KOvQbjkyEwozHnEb5wlpAD3hDIdDgcKyWnEp4AYV0TBNPQUIV7MBOhwXkNTqGTSygnJY/D0cw2EPPgZba3OUj5wgA0xFcXLHDZ2kAAAAASUVORK5CYII=")
IMAGE_METRO_BUS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAJCAYAAAA7KqwyAAAAd0lEQVR42qWMsQ2AMAwET2IPkp4paGlYgxnYkykgKLSIKPgLJDogvPSS/f4zlxZ8H/CHOT/4UJe7Zlxrh6jCS0cxSIG6sWDT4aM3sdgwKSj0hIY/JuDmUlgsK66zJRU8SGKRVvxgwf4B3sVwKUO14Ma3D9QVA3AC2DYHRN4mmqoAAAAASUVORK5CYII=")
IMAGE_XPRESS_BUS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAJCAYAAAA7KqwyAAAAaklEQVR4AZ3QsQ2AIBCFYRL3cAEWsLWlYQ1nYBEnYwobbAlG3yteLXeX/OX3igu69dwyGuj9aaAsJ7yjNoFVoxGO6DZgRRM5UB1Y1eDFigOXF9NyIKHHgWmSHnmgbsCdhlYDCyqGgUJD+wGOhfahrZQnuQAAAABJRU5ErkJggg==")
IMAGE_NIGHT_BUS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAJCAQAAACRI2S5AAAAXElEQVR42n3PoQ2AQAAEwU2+k7VUgcXQBjXQJ1VgwBLIIXDwT07OmgPE0dO8djoCIPZuH45xswfs3Ksc426HS5NjXPjlGFx/gxUHryZfDoiTR5UPp+dmca4GswVu/YOM52Hx5vcAAAAASUVORK5CYII=")
IMAGE_S1 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAa0lEQVR4AWMAAfEpWuZSU7WeSk7Tei01Tfs/NgyVeyI5TcMYrklyqtZHkCQxGKRWcrK6CQPIJpAAifgJA5D4QKpGoGVvGEAMcjDZNpLvR1DwkhSq07Q+iU7SMgRHCSh4QaaAnIDPeSA1ME0Aow/ZmIBU42QAAAAASUVORK5CYII=")
IMAGE_S11 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAcUlEQVR4AWMAAfEpWuaSU7VPS03T/o8Pg9RITtMwRtKktZ2BGNDAwCQ5TXuH5GR1EwaQKYQ1aLOhatY6yQByAgNpAKyH/hrBfgS5m2hdaQysYD+CghcUUhDNhDUBLdopOknLEMwHBS/IFELxCFID0wQAw2VH51lki9YAAAAASUVORK5CYII=")
IMAGE_S2 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAWElEQVR4AWMAgS0iluZAfBqI/+PDUDXGyJq2M+AHMLVMQLwDiE1AnNNEaGBD03wSxPjPQBqA6KG/RmhIMZGgiRXmR2NoSDERqWknEBvCBExAphARjydhmgBamVICM40gzAAAAABJRU5ErkJggg==")
IMAGE_S21 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAbUlEQVR42p1QQQqAQAj0CYF+JFpa99ct65PqVIfqA9Uc6hTRKgyIOo4OIQbWWDhNRXQ2Sccb0Cuso0nsHpKxbmj+AWaz9IGghEINoEzGujqICyHxwK3o/xH21rh6Ce25CS0hYC+24ISv8zBzk04OP+ukjEgl2AAAAABJRU5ErkJggg==")
IMAGE_S3_S31 = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAbElEQVR4AWMAgWCFbPMQhdynIYp5r4H4PzYMllPIexIgl2eM0KSY+xEiSRiD1AbL5pgwQG36TwoG2cwANOEDqRqDFXLfMIAY5GCybSTfj6DgJSVUgxXzPgXL5xqCowQUvCBTQE7A5zyQGpgmAHpv3XJOylpCAAAAAElFTkSuQmCC")
IMAGE_AKN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAJCAYAAAACTR1pAAAAVElEQVR4AWMAgX8NkuZA/BSIPwDxfxz4NRA/AWJjZE0fIZKEMVStCQPUpv8k4icMMOeRiN8wgBjkYLJtpMiPxiSG6icgNoRFiQk0jt7gcx5IDUwTAGj6M5mAtFVfAAAAAElFTkSuQmCC")

# Configuration for backgrounds and colors for all known lines.
LINE_CONFIG = {
    # Subways (U-Bahn)
    "u1": {"background-color": "#0072bc", "color": "#ffffff"},
    "u2": {"background-color": "#ed1c24", "color": "#ffffff"},
    "u3": {"background-color": "#ffde00", "color": "#2f2f2f"},
    "u4": {"background-color": "#00aaad", "color": "#ffffff"},

    # Suburban trains (S-Bahn)
    "s1": {"image": IMAGE_S1, "color": "#ffffff"},
    "s11": {"image": IMAGE_S11, "color": "#1a962b"},
    "s2": {"image": IMAGE_S2, "color": "#b41439"},
    "s21": {"image": IMAGE_S21, "color": "#ffffff"},
    "s3": {"image": IMAGE_S3_S31, "color": "#ffffff"},
    "s31": {"image": IMAGE_S3_S31, "color": "#ffffff"},

    # AKN commuter trains
    "a1": {"image": IMAGE_AKN, "color": "#ffffff"},
    "a2": {"image": IMAGE_AKN, "color": "#ffffff"},
    "a3": {"image": IMAGE_AKN, "color": "#ffffff"},

    # Buses (MetroBus, XpressBus, NachtBus)
    "metro_bus": {"image": IMAGE_METRO_BUS, "color": "#ffffff"},
    "xpress_bus": {"image": IMAGE_XPRESS_BUS, "color": "#ffffff"},
    "night_bus": {"image": IMAGE_NIGHT_BUS, "color": "#ffffff"},

    # Regional trains (Regional-Bahn, Regional-Express)
    "rb": {"background-color": "#2f2f2f", "color": "#ffffff"},
    "re": {"background-color": "#2f2f2f", "color": "#ffffff"},
}

# These are used as fallbacks in case there is no specific config above.
# Basically this will result in only rendering the plain line name, without
# any background image or color.
DEFAULT_SUBWAY_CONFIG = {"color": "#ffffff"}
DEFAULT_SUBURBAN_CONFIG = {"color": "#ffffff"}
DEFAULT_BUS_CONFIG = {"color": "#ffffff"}
DEFAULT_REGIONAL_TRAIN_CONFIG = {"color": "#ffffff"}

# Other colors used throughout the applet.
COLOR_BACKGROUND = "#000000"
COLOR_SEPARATOR = "#1f1f1f"
COLOR_MESSAGE_INFO = "#ffffff"
COLOR_MESSAGE_ERROR = "#ff9900"
COLOR_DEPARTURE_TIME = "#ff9900"
COLOR_DEPARTURE_TIME_DELAYED = "#ff0000"
COLOR_DEPARTURE_TIME_ON_TIME = "#00ff00"

def render_subway_icon(id, name):
    """Render a rectangular subway (U-Bahn) icon.

    Args:
        id: The id of the subway line.
        name: The name of the subway line.

    Returns:
        A definition of what to render.
    """
    data = LINE_CONFIG.get(id, DEFAULT_SUBWAY_CONFIG)
    background_color = data["background-color"]
    color = data["color"]
    return render.Box(width = 18, height = 15, padding = 2, child = render.Stack(children = [
        render.Box(width = 14, height = 9, color = background_color) if background_color != None else None,
        render.Box(width = 16, height = 9, child = render.Text(name, offset = -1, font = "tom-thumb", color = color)),
    ]))

def render_suburban_icon(id, name):
    """Render a pill shaped suburban train (S-Bahn) icon.

    Args:
        id: The id of the suburban train line.
        name: The name of the suburban train line.

    Returns:
        A definition of what to render.
    """
    data = LINE_CONFIG.get(id, DEFAULT_SUBURBAN_CONFIG)
    image = data["image"]
    color = data["color"]
    return render.Box(width = 18, height = 15, padding = 2, child = render.Stack(children = [
        render.Image(width = 14, height = 9, src = image) if image != None else None,
        render.Box(width = 16, height = 9, child = render.Text(name, offset = -1, font = "tom-thumb", color = color)),
    ]))

def render_bus_icon(id, name):
    """Render a diamond like bus (MetroBus, XpressBus or NachtBus) icon.

    Args:
        id: The id of the bus line.
        name: The name of the bus line.

    Returns:
        A definition of what to render.
    """
    is_xpress_bus = id[0] == "x"
    is_night_bus = len(id) == 3 and id[0] == "6"
    data = LINE_CONFIG.get("xpress_bus" if is_xpress_bus else "night_bus" if is_night_bus else "metro_bus", DEFAULT_BUS_CONFIG)
    image = data["image"]
    color = data["color"]
    expand = len(name) > 3
    return render.Box(width = 18, height = 15, padding = 0 if expand else 1, child = render.Stack(children = [
        render.Image(width = 18 if expand else 16, height = 9, src = image) if image != None else None,
        render.Box(width = 20 if expand else 18, height = 9, child = render.Text(name, offset = -1, font = "tom-thumb", color = color)),
    ]))

def render_regional_train_icon(id, name):
    """Render a rectangular regional (express) train (Regional-Bahn, Regional-Express) icon.

    Args:
        id: The id of the regional train line.
        name: The name of the regional train line.

    Returns:
        A definition of what to render.
    """
    data = LINE_CONFIG.get(id[0:2], DEFAULT_REGIONAL_TRAIN_CONFIG)
    background_color = data["background-color"]
    color = data["color"]
    return render.Box(width = 18, height = 15, padding = 1, child = render.Stack(children = [
        render.Box(width = 15, height = 13, color = background_color),
        render.Column(children = [
            render.Box(height = 6, child = render.Text(name[0:2], offset = -1, font = "tom-thumb", color = color)),
            render.Box(height = 6, child = render.Text(name[2:], offset = -1, font = "tom-thumb", color = color)),
        ]),
    ]))

def render_line_icon(line):
    """Render an icon for a given line.

    Args:
        line: A "line" dictionary, retrieved from the API.

    Returns:
        A definition of what to render.
    """
    id = line["id"]
    name = line["name"]
    product = line["product"]

    #print("Product:", product, "Mode:", line["mode"])

    if product == "subway":
        return render_subway_icon(id, name)
    elif product == "suburban" or \
         product == "akn":
        return render_suburban_icon(id, name)
    elif product == "regional-train" or \
         product == "regional-express-train":
        return render_regional_train_icon(id, name)
    elif product == "bus" or \
         product == "express-bus":
        return render_bus_icon(id, name)
    elif product == "anruf-sammel-taxi" or \
         product == "long-distance-train" or \
         product == "long-distance-bus":
        # Currently unsupported (taxi & long distance trains).
        return None

    # Fallback to just rendering nothing.
    return None

def render_relative_departure_time(time_actual):
    """Render a relative departure time.

    Args:
        time_actual: The actual departure time.

    Returns:
        A definition of what to render.
    """
    diff_minutes = math.floor((time_actual - time.now()).minutes)

    return render.Text(
        content = "now" if diff_minutes <= 0 else ("%s min" % diff_minutes),
        height = 7,
        font = "tb-8",
        color = COLOR_DEPARTURE_TIME,
    )

def render_absolute_departure_time(format, time_planned, time_actual):
    """Render an absolute departure time, including a delay indicator.

    Args:
        format: The time layout string to use.
        time_planned: The planned departure time.
        time_actual: The actual departure time.

    Returns:
        A definition of what to render.
    """
    delay_minutes = math.floor((time_actual - time_planned).minutes)

    return render.Row(children = [
        render.Text(
            content = time_planned.format(format),
            height = 7,
            font = "tb-8",
            color = COLOR_DEPARTURE_TIME,
        ),
        render.Text(
            content = "+%d" % delay_minutes,
            height = 7,
            font = "tom-thumb",
            color = COLOR_DEPARTURE_TIME_DELAYED if delay_minutes > 0 else COLOR_DEPARTURE_TIME_ON_TIME,
        ),
    ])

def render_departure_time(time_format, time_planned, time_actual):
    """Render a relative or an absolute departure time.

    Args:
        time_format: The time layout string to use or "relative".
        time_planned: The planned departure time.
        time_actual: The actual departure time.

    Returns:
        A definition of what to render.
    """
    if time_format == "relative":
        return render_relative_departure_time(time_actual)
    else:
        return render_absolute_departure_time(time_format, time_planned, time_actual)

def render_departure(departure, time_format):
    """Render which line, including icon, departs at what time.

    Args:
        departure: A "departure" dictionary, retrieved from the API.
        time_format: The time layout string to use or "relative".

    Returns:
        A definition of what to render.
    """
    time_planned = time.parse_time(departure["plannedWhen"])
    time_actual = time.parse_time(departure["when"])

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Box(
                width = 18,
                height = 15,
                child = render_line_icon(departure["line"]),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 48,
                        child = render.Text(
                            content = departure["direction"],
                            height = 8,
                            font = "tb-8",
                        ),
                    ),
                    render.Marquee(
                        render_departure_time(time_format, time_planned, time_actual),
                        width = 48,
                    ),
                ],
            ),
        ],
    )

def fetch_departures(station_id, extra_params = {}, duration_minutes = 1440, max_results = 2):
    """Fetch departures given a station identifier.

    Args:
        station_id: A station identifier to fetch departures for.
        extra_params: Additional request parameters.
        duration_minutes: Get departures up to X minutes into the future.
        max_results: Return at most this number of results.

    Returns:
        An API response containing the departures.
    """
    url = HVV_REST_API_DEPARTURES_URL % station_id

    # Set base request parameters.
    params = {
        "duration": str(duration_minutes),
        "results": str(max_results),
        "includeRelatedStations": "true",
        "linesOfStops": "false",
        "remarks": "false",
        "stopovers": "false",
    }

    # Add additional request parameters.
    params.update(extra_params)

    # Construct a unique cache key.
    cache_key = base64.encode(url + json.encode(params))
    cache_data = cache.get(cache_key)

    if cache_data != None:
        return json.decode(cache_data)
    else:
        response = http.get(url = url, params = params)

        if response.status_code != 200:
            print("API request failed with status %d" % response.status_code)
            return None

        data = response.json()

        cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL_SECONDS)

        return data

def get_config_option_value(config, key, default = None):
    """Get the value of a 'schema.Option' from the applet configuration.

    Args:
        config: The applet configuration.
        key: The configuration key.
        default: The default value to fallback to.

    Returns:
        The value of the 'schema.Option' or the fallback value.
    """
    blob = config.str(key)
    data = json.decode(blob) if blob != None else None
    return data["value"] if data != None else default

def bool_str(value):
    return "true" if value == True else "false"

def parse_config(config):
    """Parse the applet configuration into some convenient structures.

    Args:
        config: The applet configuration.

    Returns:
        A tuple of transformed applet configuration values.
    """
    station_id = get_config_option_value(config, "station_id", DEFAULT_STATION_ID)
    direction_id = get_config_option_value(config, "direction_id")
    time_format = config.str("time_format", "relative")
    time_offset = time.parse_duration(config.str("time_offset", "0m"))

    # Which means of transport are selected?
    include_subway = config.bool("include_subway", True)
    include_suburban = config.bool("include_suburban", True)
    include_bus = config.bool("include_bus", True)
    include_express_bus = config.bool("include_express_bus", True)
    include_rb = config.bool("include_rb", True)
    include_re = config.bool("include_re", True)
    include_akn = config.bool("include_akn", True)
    include_ferry = config.bool("include_ferry", True)
    is_anything_selected = include_subway or include_suburban or \
                           include_bus or include_express_bus or \
                           include_rb or include_re or \
                           include_akn or include_ferry

    # API request parameters derived from the applet configuration.
    params = {
        "subway": bool_str(include_subway),
        "suburban": bool_str(include_suburban),
        "bus": bool_str(include_bus),
        "express-bus": bool_str(include_express_bus),
        "akn": bool_str(include_akn),
        "regional-train": bool_str(include_rb),
        "regional-express-train": bool_str(include_re),
        "ferry": bool_str(include_ferry),
        "anruf-sammel-taxi": "false",
        "long-distance-train": "false",
        "long-distance-bus": "false",
    }

    # If a direction was set, add it to the API request parameters.
    if direction_id != None:
        params["direction"] = direction_id

    if time_offset != 0:
        params["when"] = (time.now() + time_offset).format(RFC3339_FORMAT)

    return (station_id, time_format, is_anything_selected, params)

def render_message(message, color):
    """Render a message in a given color, below the HVV logo.

    Args:
        message: The message to show.
        color: The message color to use.

    Returns:
        A definition of what to render.
    """
    return render.Root(
        child = render.Box(
            color = COLOR_BACKGROUND,
            child = render.Column(
                children = [
                    render.Box(height = 16, child = render.Image(IMAGE_LOGO)),
                    render.Box(height = 16, child = render.WrappedText(
                        content = message,
                        font = "tom-thumb",
                        color = color,
                    )),
                ],
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
    (station_id, time_format, is_anything_selected, params) = parse_config(config)

    # None of the products are selected...
    if is_anything_selected == False:
        return render_message("Choose at least one vessel", COLOR_MESSAGE_INFO)

    # Fetch departures and show an error message, if it fails.
    departures = fetch_departures(station_id, params)
    if departures == None:
        return render_message("Error fetching departures!", COLOR_MESSAGE_ERROR)

    # Slice departures to a maximum of two, although
    # it is already specified in the API request.
    departures = departures[0:2]

    # No departures were found...
    if len(departures) == 0:
        return render_message("Couldn't find any departures", COLOR_MESSAGE_INFO)

    return render.Root(
        child = render.Box(
            color = COLOR_BACKGROUND,
            child = render.Column(
                expanded = True,
                children = [
                    render_departure(departures[0], time_format) if len(departures) > 0 else None,
                    render.Box(width = 64, height = 1, color = COLOR_SEPARATOR),
                    render_departure(departures[1], time_format) if len(departures) > 1 else None,
                ],
            ),
        ),
    )

def find_stations(query, max_results = 2):
    """Search the API for a list of stations matching a (fuzzy) query.

    Args:
        query: The (fuzzy) query string.
        max_results: Return at most this number of results.

    Returns:
        A list of 'schema.Option', each corresponding to a station.
    """
    query = query.strip(" ")
    if len(query) == 0:
        return []

    response = http.get(url = HVV_REST_API_LOCATIONS_URL, params = {
        "query": query,
        "fuzzy": "true",
        "results": str(max_results),
        "stops": "true",
        "addresses": "false",
        "poi": "false",
        "linesOfStops": "false",
    })

    if response.status_code != 200:
        print("API request failed with status %d" % response.status_code)
        return []

    data = response.json()

    return [schema.Option(display = station["name"], value = station["id"]) for station in data]

def get_schema():
    time_format_options = [
        schema.Option(
            display = "Relative",
            value = "relative",
        ),
        schema.Option(
            display = "Absolute (24h)",
            value = "15:04",
        ),
        schema.Option(
            display = "Absolute (12h)",
            value = "3:04 PM",
        ),
    ]

    time_offset_options = [
        schema.Option(
            display = "now",
            value = "0m",
        ),
        schema.Option(
            display = "in 5 minutes",
            value = "5m",
        ),
        schema.Option(
            display = "in 10 minutes",
            value = "10m",
        ),
        schema.Option(
            display = "in 15 minutes",
            value = "15m",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station_id",
                name = "Station",
                desc = "Pick a station",
                icon = "mapPin",
                handler = find_stations,
            ),
            schema.Typeahead(
                id = "direction_id",
                name = "Direction",
                desc = "Pick a direction (optional)",
                icon = "locationArrow",
                handler = find_stations,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time format",
                desc = "Pick a time format",
                icon = "clock",
                default = time_format_options[0].value,
                options = time_format_options,
            ),
            schema.Dropdown(
                id = "time_offset",
                name = "Time offset",
                desc = "Pick a time offset",
                icon = "plus",
                default = time_offset_options[0].value,
                options = time_offset_options,
            ),
            schema.Toggle(
                id = "include_subway",
                name = "U-Bahn",
                desc = "Include subways",
                icon = "trainSubway",
                default = True,
            ),
            schema.Toggle(
                id = "include_suburban",
                name = "S-Bahn",
                desc = "Include suburban trains",
                icon = "train",
                default = True,
            ),
            schema.Toggle(
                id = "include_bus",
                name = "MetroBus",
                desc = "Include buses",
                icon = "bus",
                default = True,
            ),
            schema.Toggle(
                id = "include_express_bus",
                name = "XpressBus",
                desc = "Include express buses",
                icon = "bus",
                default = True,
            ),
            schema.Toggle(
                id = "include_akn",
                name = "AKN",
                desc = "Include AKN commuter trains",
                icon = "train",
                default = True,
            ),
            schema.Toggle(
                id = "include_rb",
                name = "RB",
                desc = "Include regional trains",
                icon = "train",
                default = True,
            ),
            schema.Toggle(
                id = "include_re",
                name = "RE",
                desc = "Include regional express trains",
                icon = "train",
                default = True,
            ),
            schema.Toggle(
                id = "include_ferry",
                name = "Ferry",
                desc = "Include ferrys",
                icon = "ship",
                default = True,
            ),
        ],
    )

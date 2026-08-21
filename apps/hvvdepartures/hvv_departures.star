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
# This applet used to run on https://transport.rest/'s HVV-specific API, but
# HVV shut off the underlying HAFAS API that powered it, so that API no
# longer exists (v5.hvv.transport.rest is gone, and the "hvv-rest" project
# behind it has been archived: https://github.com/derhuerst/hvv-rest).
#
# It now uses https://transitous.org/, a community-run, GTFS/GTFS-RT-based
# public transport router that covers Hamburg (HVV) among many other
# regions, again without requiring an API key.
#
# Transitous asks API consumers to identify themselves via a descriptive
# User-Agent header and to reach out if usage becomes non-trivial, see:
#   https://transitous.org/api/
#
# Please consider supporting the Transitous project:
#   https://transitous.org/
#
TRANSITOUS_API_GEOCODE_URL = "https://api.transitous.org/api/v1/geocode"
TRANSITOUS_API_STOPTIMES_URL = "https://api.transitous.org/api/v6/stoptimes"
TRANSITOUS_REQUEST_HEADERS = {
    "User-Agent": "tidbyt-hvv-departures/2.0 (+https://github.com/tidbyt/community/tree/main/apps/hvvdepartures)",
}

# Cache API responses for a short time, as we want things to be as recent as possible.
CACHE_TTL_SECONDS = 30

# The RFC3339 date and time format string used by Go / Starlark.
RFC3339_FORMAT = "2006-01-02T15:04:05Z07:00"

# The default station ID to use, if none is set by the user.
# This currently defaults to "Hamburg Hbf" (main station).
DEFAULT_STATION_ID = "de-DELFI_de:02000:10950_G"

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

# These are used as fallbacks in case there is no specific config above
# (e.g. for a newly introduced line, such as Hamburg's S5). Basically this
# will result in only rendering the plain line name, without any background
# image or color.
DEFAULT_SUBWAY_CONFIG = {"background-color": None, "color": "#ffffff"}
DEFAULT_SUBURBAN_CONFIG = {"image": None, "color": "#ffffff"}
DEFAULT_BUS_CONFIG = {"image": None, "color": "#ffffff"}
DEFAULT_REGIONAL_TRAIN_CONFIG = {"background-color": None, "color": "#ffffff"}

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
        line: A "line" dictionary, built from the Transitous API response.

    Returns:
        A definition of what to render.
    """
    id = line["id"]
    name = line["name"]
    product = line["product"]

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

    # Fallback for ferries and anything else we don't have a dedicated icon
    # for (e.g. taxi or long distance trains/buses): just an empty box.
    return render.Box(width = 18, height = 15)

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

# Maps our internal "category" (derived from a stop time's mode, line name
# and agency, since Transitous does not expose the same fine-grained product
# distinctions HVV's old API had) to the "product" string that
# 'render_line_icon' expects.
CATEGORY_TO_PRODUCT = {
    "subway": "subway",
    "suburban": "suburban",
    "akn": "akn",
    "rb": "regional-train",
    "re": "regional-express-train",
    "bus": "bus",
    "express_bus": "express-bus",
    "ferry": "ferry",
}

# Maps our internal "category" to the Transitous API's "mode" enum value(s),
# used to only request the modes we actually care about.
CATEGORY_TO_API_MODE = {
    "subway": "SUBWAY",
    "suburban": "SUBURBAN",
    "akn": "REGIONAL_RAIL",
    "rb": "REGIONAL_RAIL",
    "re": "REGIONAL_RAIL",
    "bus": "BUS",
    "express_bus": "BUS",
    "ferry": "FERRY",
}

def classify_stop_time(stop_time):
    """Classify a Transitous 'stopTimes' entry into one of our categories.

    Transitous only exposes a coarse "mode" (SUBWAY, SUBURBAN, REGIONAL_RAIL,
    BUS, FERRY, ...), unlike HVV's old API which had a dedicated "product" per
    line (subway, suburban, akn, regional-train, regional-express-train, bus,
    express-bus). AKN and RB/RE all show up as "REGIONAL_RAIL", and regular
    and Xpress buses both show up as "BUS", so we further distinguish them
    based on the line's (lowercased) short name, the same way the old code
    told Xpress and NachtBus lines apart.

    Args:
        stop_time: A single entry from the Transitous 'stoptimes' response.

    Returns:
        A tuple of (category, id, name). "category" is None if this stop
        time doesn't map to any product we know how to render (e.g. a
        long-distance train passing through a station we queried).
    """
    mode = stop_time.get("mode")
    name = stop_time.get("routeShortName") or stop_time.get("displayName") or ""
    id = name.lower()

    if mode == "SUBWAY":
        return ("subway", id, name)
    elif mode == "SUBURBAN":
        return ("suburban", id, name)
    elif mode == "FERRY":
        return ("ferry", id, name)
    elif mode == "BUS":
        is_xpress_bus = len(id) > 0 and id[0] == "x"
        return ("express_bus" if is_xpress_bus else "bus", id, name)
    elif mode == "REGIONAL_RAIL":
        is_akn = len(id) > 1 and id[0] == "a" and id[1] in "0123456789"
        if is_akn:
            return ("akn", id, name)
        elif id.startswith("re"):
            return ("re", id, name)
        elif id.startswith("rb"):
            return ("rb", id, name)

    # Fallback for anything we don't recognize (e.g. long-distance trains).
    return (None, id, name)

def fetch_departures(station_id, categories, at_time = None, max_results = 2):
    """Fetch departures given a station identifier.

    Args:
        station_id: A Transitous stop identifier to fetch departures for.
        categories: The set of categories (see 'classify_stop_time') to
            include in the result.
        at_time: Optional RFC3339 timestamp to fetch departures from,
            instead of the current time.
        max_results: Return at most this number of results.

    Returns:
        A list of "departure" dictionaries (in the shape 'render_departure'
        expects), or None if the request failed.
    """
    if len(categories) == 0:
        return []

    # Only ask the API for the modes we actually need, then further filter
    # and classify results client-side (see 'classify_stop_time').
    modes = {}
    for category in categories:
        modes[CATEGORY_TO_API_MODE[category]] = True

    # Overfetch, since some of what we get back (e.g. long-distance trains
    # mixed in with "REGIONAL_RAIL", or disabled bus/regional sub-categories)
    # gets filtered out client-side afterwards.
    params = {
        "stopId": station_id,
        "n": str(max_results * 15),
        "mode": ",".join(modes.keys()),
    }

    if at_time != None:
        params["time"] = at_time

    # Construct a unique cache key.
    cache_key = base64.encode(station_id + json.encode(params))
    cache_data = cache.get(cache_key)

    if cache_data != None:
        data = json.decode(cache_data)
    else:
        response = http.get(
            url = TRANSITOUS_API_STOPTIMES_URL,
            params = params,
            headers = TRANSITOUS_REQUEST_HEADERS,
        )

        if response.status_code != 200:
            print("API request failed with status %d" % response.status_code)
            return None

        data = response.json()

        cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL_SECONDS)

    departures = []
    for stop_time in data.get("stopTimes", []):
        (category, id, name) = classify_stop_time(stop_time)
        if category == None or category not in categories:
            continue

        place = stop_time.get("place", {})
        departures.append({
            "line": {
                "id": id,
                "name": name,
                "product": CATEGORY_TO_PRODUCT[category],
            },
            "direction": stop_time.get("headsign", ""),
            "plannedWhen": place.get("scheduledDeparture"),
            "when": place.get("departure"),
        })

        if len(departures) >= max_results:
            break

    return departures

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

def is_legacy_station_id(station_id):
    """Check whether a station ID is in HVV's old (now defunct) numeric format.

    Args:
        station_id: The configured station ID.

    Returns:
        True if this looks like an old HVV station ID (e.g. "90"), which
        can't be resolved against the current (Transitous-based) API.
    """
    return station_id != None and len(station_id) > 0 and station_id.isdigit()

def parse_config(config):
    """Parse the applet configuration into some convenient structures.

    Args:
        config: The applet configuration.

    Returns:
        A tuple of transformed applet configuration values.
    """
    station_id = get_config_option_value(config, "station_id", DEFAULT_STATION_ID)
    time_format = config.str("time_format", "relative")
    time_offset = time.parse_duration(config.str("time_offset", "0m"))

    # Which means of transport are selected? Each maps to one of the
    # categories used in 'classify_stop_time' / 'fetch_departures'.
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

    categories = []
    if include_subway:
        categories.append("subway")
    if include_suburban:
        categories.append("suburban")
    if include_bus:
        categories.append("bus")
    if include_express_bus:
        categories.append("express_bus")
    if include_akn:
        categories.append("akn")
    if include_rb:
        categories.append("rb")
    if include_re:
        categories.append("re")
    if include_ferry:
        categories.append("ferry")

    return (station_id, time_format, time_offset, is_anything_selected, categories)

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
    (station_id, time_format, time_offset, is_anything_selected, categories) = parse_config(config)

    # None of the products are selected...
    if is_anything_selected == False:
        return render_message("Choose at least one vessel", COLOR_MESSAGE_INFO)

    # The station was configured before the switch away from HVV's old,
    # now-defunct API, whose (purely numeric) station IDs no longer resolve.
    if is_legacy_station_id(station_id):
        return render_message("Please re-select your station in the app settings", COLOR_MESSAGE_INFO)

    at_time = (time.now() + time_offset).format(RFC3339_FORMAT) if time_offset != 0 else None

    # Fetch departures and show an error message, if it fails.
    departures = fetch_departures(station_id, categories, at_time)
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

    response = http.get(
        url = TRANSITOUS_API_GEOCODE_URL,
        params = {
            "text": query,
            "type": "STOP",
            "numResults": str(max_results),
        },
        headers = TRANSITOUS_REQUEST_HEADERS,
    )

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

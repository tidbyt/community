"""
Applet: Tube
Summary: London Underground arrivals
Description: Upcoming arrivals for a particular Tube, Elizabeth Line, DLR or Overground station.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Can handle 500 requests per minute
ENCRYPTED_APP_KEY = "AV6+xWcEgG4Ru4ZCA4ggWDRK+4zP4YCk4pCZrLiuXoCVSc677Sipk1Wnrag92v1k4qfa9n8e9FuCdsoLbov5osfGWOWUCYDkR3xh/uEsXOLVJvAr8iUXf6RSac2PXnDZ//z+hhgBzVldDDI/9CD8K8MJa0u75SG9EhZYidD9OXh0NggRHeE="
STATION_URL = "https://api.tfl.gov.uk/StopPoint"
ARRIVALS_URL = "https://api.tfl.gov.uk/StopPoint/%s/Arrivals"
NO_DATA_IN_CACHE = ""

HOLBORN_ID = "940GZZLUHBN"

WHITE = "#FFF"
BLACK = "#000"
ORANGE = "#FFA500"
FONT = "tom-thumb"

MODES = ["tube", "elizabeth-line", "dlr", "overground", "tram"]
LINES = {
    "bakerloo": {
        "display": "Bakerloo",
        "colour": "#894E24",
        "textColour": WHITE,
    },
    "central": {
        "display": "Central",
        "colour": "#DC241F",
        "textColour": WHITE,
    },
    "circle": {
        "display": "Circle",
        "colour": "#FFCC00",
        "textColour": BLACK,
    },
    "district": {
        "display": "District",
        "colour": "#007229",
        "textColour": WHITE,
    },
    "dlr": {
        "display": "Docklands",
        "colour": "#00AFAD",
        "textColour": BLACK,
    },
    "elizabeth": {
        "display": "Elizabeth",
        "colour": "#6950A1",
        "textColour": WHITE,
    },
    "hammersmith-city": {
        "display": "H'smith & City",
        "colour": "#D799AF",
        "textColour": BLACK,
    },
    "jubilee": {
        "display": "Jubilee",
        "colour": "#6A7278",
        "textColour": WHITE,
    },
    "london-overground": {
        "display": "Overground",
        "colour": "#D05F0E",
        "textColour": BLACK,
    },
    "metropolitan": {
        "display": "Metropolitan",
        "colour": "#751056",
        "textColour": WHITE,
    },
    "northern": {
        "display": "Northern",
        "colour": BLACK,
        "textColour": WHITE,
    },
    "piccadilly": {
        "display": "Piccadilly",
        "colour": "#0019A8",
        "textColour": WHITE,
    },
    "tram": {
        "display": "Tram",
        "colour": "#66CC00",
        "textColour": WHITE,
    },
    "victoria": {
        "display": "Victoria",
        "colour": "#00A0E2",
        "textColour": BLACK,
    },
    "waterloo-city": {
        "display": "W'loo & City",
        "colour": "#76D0BD",
        "textColour": BLACK,
    },
}

def app_key():
    return secret.decrypt(ENCRYPTED_APP_KEY) or ""  # Fall back to freebie quota

# Get list of stations near a given location, or look up from cache if available.
def fetch_stations(loc):
    truncated_lat = math.round(1000.0 * float(loc["lat"])) / 1000.0  # Truncate to 3dp for better caching
    truncated_lng = math.round(1000.0 * float(loc["lng"])) / 1000.0  # Means to the nearest ~110 metres.
    cache_key = "{},{}".format(truncated_lat, truncated_lng)

    cached = cache.get(cache_key)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        STATION_URL,
        params = {
            "app_key": app_key(),
            "lat": str(truncated_lat),
            "lon": str(truncated_lng),
            "radius": "500",
            "stopTypes": "NaptanMetroStation,NaptanRailStation",
            "returnLines": "true",
            "modes": ",".join(MODES),
            "categories": "none",
        },
    )
    if resp.status_code != 200:
        print("TFL station search failed with status ", resp.status_code)
        cache.set(cache_key, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    if not resp.json().get("stopPoints"):
        print("TFL station search does not contain stops")
        cache.set(cache_key, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(cache_key, resp.body(), ttl_seconds = 86400)  # Tube stations don't move often
    return resp.json()

# API gives errors when searching for locations outside the United Kingdom.
def outside_uk_bounds(loc):
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    if lat <= 49.9 or lat >= 58.7 or lng <= -11.05 or lng >= 1.78:
        return True
    return False

# We know we're talking about stations.
def format_option_station(name):
    suffixes = [
        " Underground Station",
        " DLR Station",
        " Rail Station",
        " (London)",
        " Tram Stop",
    ]
    for suffix in suffixes:
        name = name.removesuffix(suffix)

    if name != "London Bridge":
        name = name.removeprefix("London ")

    return name

# We have a lot of space at the top, but scrolling marquees is slow
def format_title_station(name):
    name = format_option_station(name)

    replacements = {
        "Street": "St",
        "Road": "Rd",
        "Great": "Gt",
        "Square": "Sq",
    }
    words = name.split(" ")
    for i in range(len(words)):
        if words[i] in replacements:
            print(words[i])
            words[i] = replacements[words[i]]

    return " ".join(words)

# Space is even more cramped, so abbreviate more
def format_destination_station(name):
    name = format_option_station(name)

    replacements = {
        "Central": "C",
        "Court": "Ct",
        "East": "E",
        "Great": "Gt",
        "Green": "Grn",
        "Junction": "Jct",
        "Lane": "Ln",
        "North": "N",
        "Palace": "P",
        "Park": "Pk",
        "Road": "Rd",
        "South": "S",
        "Square": "Sq",
        "Station": "Stn",
        "Street": "St",
        "West": "W",
    }
    words = name.split(" ")
    for i in range(len(words)):
        if words[i] in replacements:
            words[i] = replacements[words[i]]
        if words[i] == "&":
            words[i + 1] = words[i + 1][0]

    return " ".join(words)

# Find and extract details of all stations near a given location.
def get_stations(location):
    loc = json.decode(location)
    if outside_uk_bounds(loc):
        return [schema.Option(
            display = "Default option - location is outside the UK",
            value = json.encode({
                "station_id": HOLBORN_ID,
                "station_name": "Holborn",
                "line_id": "central",
            }),
        )]

    data = fetch_stations(loc)
    if not data:
        return []
    options = []
    for station in data["stopPoints"]:
        if not station.get("id"):
            print("TFL station result does not include id")
            continue
        if not station.get("commonName"):
            print("TFL station result does not include name")
            continue
        if not station.get("lineModeGroups"):
            print("TFL station result does not include lines")
            continue

        station_name = format_option_station(station["commonName"])
        for line_group in station["lineModeGroups"]:
            if not line_group.get("modeName"):
                print("TFL station result does not include mode")
                continue
            if not line_group.get("lineIdentifier"):
                print("TFL station result does not include line identifier")
                continue
            if line_group["modeName"] not in MODES:
                continue

            for line in line_group["lineIdentifier"]:
                line_name = LINES[line]["display"]
                option = schema.Option(
                    display = "%s - %s" % (station_name, line_name),
                    # Return a composite value to avoid multiple API calls
                    value = json.encode({
                        "station_id": station["id"],
                        "station_name": station_name,
                        "line_id": line,
                    }),
                )
                options.append(option)
    return options

# Lookup upcoming arrivals for our given station, or use cache if available.
def fetch_arrivals(stop_id):
    cached = cache.get(stop_id)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        ARRIVALS_URL % stop_id,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        print("TFL StopPoint request failed with status ", resp.status_code)
        cache.set(stop_id, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(stop_id, resp.body(), ttl_seconds = 30)
    return resp.json()

# TFL response gives the times until a train arrives in seconds. Everyone is used
# to seeing it in minutes on display boards.
def format_times(seconds):
    result = ""
    for time in sorted(seconds):
        mins = int(math.round(time / 60.0))
        text = str(mins)
        if len(result) == 0:
            result = text
            continue
        proposed = result + "," + text
        if len(proposed) > 4:  # Otherwise line is too long
            break
        result = proposed
    return result

# Group arrivals data by platform/direction and format for humans
def get_arrivals(stop_id, line_id):
    all_arrivals = fetch_arrivals(stop_id)
    if not all_arrivals:
        return []
    by_direction = {}
    for arrival in all_arrivals:
        if not arrival.get("lineId"):
            print("TFL arrivals data does not include line")
            continue
        if not arrival.get("platformName"):
            print("TFL arrivals data does not include platform")
            continue
        if not arrival.get("timeToStation"):
            print("TFL arrivals data does not include arrival time")
            continue
        if arrival["lineId"] != line_id:
            continue
        if arrival.get("destinationNaptanId") == stop_id:
            continue

        direction = format_destination_station(arrival["destinationName"])
        time = arrival["timeToStation"]  # in seconds
        if by_direction.get(direction):
            by_direction[direction].append(time)
        else:
            by_direction[direction] = [time]

    return {
        direction: format_times(times)
        for direction, times in
        # East before West, North before South
        sorted(by_direction.items())
    }

# The colour associated with each line is famous.
def colour(line_id):
    return LINES[line_id]["colour"]

# Make sure text is readable.
def textColour(line_id):
    return LINES[line_id]["textColour"]

# Add a a row of text for each direction
# Should only ever have two directions at a station.
def render_arrivals_frame(arrivals):
    return render.Column(
        main_align = "space_evenly",
        expanded = True,
        children = [
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.WrappedText(
                            content = arrival[0],
                            color = ORANGE,
                            font = FONT,
                            width = 44,
                            height = 6,
                        ),
                        render.WrappedText(
                            content = arrival[1],
                            color = ORANGE,
                            font = FONT,
                            width = 17,
                            height = 6,
                            align = "right",
                        ),
                    ],
                ),
            )
            for arrival in arrivals
        ],
    )

def render_arrivals(arrivals):
    if len(arrivals) == 0:
        return [
            render.Box(
                width = 64,
                child = render.WrappedText(
                    content = "No arrivals data",
                    width = 62,
                    align = "center",
                    color = ORANGE,
                    font = FONT,
                ),
            ),
        ]

    frames = []
    for i in range(0, len(arrivals), 3):
        frame = render_arrivals_frame(arrivals.items()[i:i + 3])
        frames.extend([frame] * 100)
    return render.Animation(
        children = frames,
    )

def main(config):
    station_and_line = config.get("station_and_line")
    if not station_and_line:
        station_id = HOLBORN_ID
        station_name = "Holborn"
        line_id = "central"
    else:
        data = json.decode(json.decode(station_and_line)["value"])
        station_id = data["station_id"]
        station_name = format_title_station(data["station_name"])
        line_id = data["line_id"]

    arrivals = get_arrivals(station_id, line_id)

    # Considered including a roundel logo because we all love them, but
    # some station names are very long like High Street Kensington or
    # King's Cross St. Pancras, so we need all the space for the name.
    return render.Root(
        delay = 25,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 13,
                    # Include line colour because you might want to monitor
                    # different lines at a given station.
                    color = colour(line_id),
                    child = render.Padding(
                        # Better wrapping for King's Cross St Pancras
                        pad = (1, 1, 1, 0),
                        child = render.Column(
                            children = [
                                render.Marquee(
                                    width = 62,
                                    align = "center",
                                    child = render.Text(
                                        content = station_name,
                                        color = textColour(line_id),
                                        font = FONT,
                                    ),
                                ),
                                render.WrappedText(
                                    content = LINES[line_id]["display"],
                                    color = textColour(line_id),
                                    font = FONT,
                                    align = "center",
                                    width = 62,
                                    height = 8,
                                ),
                            ],
                        ),
                    ),
                ),
                render.Box(height = 1, width = 1),  # Spacing between box and text
                render_arrivals(arrivals),
            ],
        ),
    )

# Considered using separate options for station and line, but I don't think
# there's a way to make one depend on the other. It would be bad if users had
# to wade through 11 lines that don't stop at their station to find what they
# want, so do it when doing the search.
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station_and_line",
                name = "Station and line",
                desc = "The station and line to get arrival times for",
                icon = "trainSubway",
                handler = get_stations,
            ),
        ],
    )

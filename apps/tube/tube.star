"""
Applet: Tube
Summary: London Underground arrivals
Description: Upcoming arrivals for a particular Tube station.
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
STATION_URL = "https://api.tfl.gov.uk/StopPoint/%s"
ARRIVALS_URL = "https://api.tfl.gov.uk/StopPoint/%s/Arrivals"

HOLBORN_ID = "940GZZLUHBN"

WHITE = "#FFF"
BLACK = "#000"
ORANGE = "#FFA500"

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
    "elizabeth": {
        "display": "Elizabeth",
        "colour": "#6950A1",
        "textColour": WHITE,
    },
    "hammersmith-city": {
        "display": "Hammersmith & City",
        "colour": "#D799AF",
        "textColour": BLACK,
    },
    "jubilee": {
        "display": "Jubilee",
        "colour": "#6A7278",
        "textColour": WHITE,
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
    "victoria": {
        "display": "Victoria",
        "colour": "#00A0E2",
        "textColour": BLACK,
    },
    "waterloo-city": {
        "display": "Waterloo & City",
        "colour": "#76D0BD",
        "textColour": BLACK,
    },
}

def app_key():
    return secret.decrypt(ENCRYPTED_APP_KEY) or ""  # Fall back to freebie quota

# Get list of stations near a given location, or look up from cache if available.
def fetch_stations(location):
    cached = cache.get(location)
    if cached:
        return json.decode(cached)
    loc = json.decode(location)
    resp = http.get(
        STATION_URL,
        params = {
            "app_key": app_key(),
            "lat": loc["lat"],
            "lon": loc["lng"],
            "stopTypes": "NaptanPublicBusCoachTram",
            "modes": "tube",
        },
    )
    if resp.status_code != 200:
        fail("TFL station search failed with status ", resp.status_code)
    if "stopPoints" not in resp.json():
        fail("TFL station search does not contain stops")
    cache.set(location, resp.body(), ttl_seconds = 86400)  # Tube stations don't move often
    return resp.json()

# Find and extract details of all stations near a given location.
def get_stations(location):
    data = fetch_stations(location)
    options = []
    for station in data:
        if "id" not in station:
            fail("TFL station result does not include id")
        if "commonName" not in station:
            fail("TFL station result does not include name")
        if "lineModeGroups" not in station:
            fail("TFL station result does not include lines")

        station_name = station["commonName"].removesuffix(" Underground Station")
        for line_group in station["lineModeGroups"]:
            if "modeName" not in line_group:
                fail("TFL station result does not include mode")
            if "lineIdentifier" not in line_group:
                fail("TFL station result does not include line identifier")
            if line_group["modeName"] != "tube":
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
    if cached:
        return json.decode(cached)
    resp = http.get(
        ARRIVALS_URL % stop_id,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        fail("TFL StopPoint request failed with status ", resp.status_code)
    cache.set(stop_id, resp.body(), ttl_seconds = 30)
    return resp.json()

# TFL response gives the times until a train arrives in seconds. Everyone is used
# to seeing it in minutes on display boards.
def format_times(seconds):
    result = ""
    for time in sorted(seconds):
        mins = int(math.round(time / 60.0))
        if mins == 0:
            text = "due"
        else:
            text = str(mins)
        if len(result) == 0:
            result = text
            continue
        proposed = result + ", " + text
        if len(proposed) > 8:  # Otherwise line is too long
            break
        result = proposed
    return result

# Group arrivals data by platform/direction and format for humans
def get_arrivals(stop_id, line_id):
    all_arrivals = fetch_arrivals(stop_id)
    by_direction = {}
    for arrival in all_arrivals:
        if "lineId" not in arrival:
            fail("TFL arrivals data does not include line")
        if "platformName" not in arrival:
            fail("TFL arrivals data does not include platform")
        if "timeToStation" not in arrival:
            fail("TFL arrivals data does not include arrival time")

        if arrival["lineId"] != line_id:
            continue

        # Eastbound - Platform 2 -> East
        direction = arrival["platformName"].split(" ")[0][:-5]
        time = arrival["timeToStation"]  # in seconds
        if direction in by_direction:
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
def render_arrivals(arrivals):
    if len(arrivals) == 0:
        return [
            render.Box(
                width = 64,
                child = render.Text(
                    content = "No arrivals",
                    color = ORANGE,
                ),
            ),
        ]

    return [
        render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(direction, color = ORANGE),
                    render.Text(times, color = ORANGE),
                ],
            ),
        )
        for direction, times in arrivals.items()
    ]

def main(config):
    station_and_line = config.get("station_and_line")
    if not station_and_line:
        station_id = HOLBORN_ID
        station_name = "Holborn"
        line_id = "central"
    else:
        data = json.decode(json.decode(station_and_line)["value"])
        station_id = data["station_id"]
        station_name = data["station_name"]
        line_id = data["line_id"]

    arrivals = get_arrivals(station_id, line_id)

    # Considered including a roundel logo because we all love them, but
    # some station names are very long like High Street Kensington or
    # King's Cross St. Pancras, so we need all the space for the name.
    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 16,
                    # Include line colour because you might want to monitor
                    # different lines at a given station. Realize it's not
                    # the most accessible thing to rely on colour but the
                    # space is extremely limited for text and London doesn't
                    # abbreviate line names.
                    color = colour(line_id),
                    # TODO: centre text so second line isn't aligned with
                    # the left edge of the first line.
                    child = render.Padding(
                        # Better wrapping for King's Cross St Pancras
                        pad = (1, 0, 1, 0),
                        # pad = 0,
                        child = render.WrappedText(
                            content = station_name,
                            color = textColour(line_id),
                        ),
                    ),
                ),
            ] + render_arrivals(arrivals),
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
                icon = "train-subway-tunnel",
                handler = get_stations,
            ),
        ],
    )

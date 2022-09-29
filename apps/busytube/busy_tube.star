"""
Applet: Busy Tube
Summary: London station crowding
Description: Tells you how busy a given TfL-operated station in London currently is. Data updated every five minutes.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

RED = "#d3212c"
GREEN = "#69b34c"
ORANGE = "#ff980e"
GREY = "#666"
WHITE = "#fff"

DEFAULT_STATION_NAME = "Russell Square"
DEFAULT_NAPTAN_ID = "940GZZLURSQ"

STATION_URL = "https://api.tfl.gov.uk/StopPoint"
CROWDING_LIVE_URL = "https://api.tfl.gov.uk/Crowding/%s/Live"
CROWDING_TYPICAL_URL = "https://api.tfl.gov.uk/Crowding/%s/%s"
ENCRYPTED_APP_KEY = "AV6+xWcEidogMm49QBNMdHN1M2Ysyt35b6k5o9A1/jHKh4sM5Czv5BffoQw0QBvCR7jr/pFvd4eHZqjuLWYkEX4MTpBTAjTFeTGS3ynqTeumZB7CCghUoULPLDscavZpf9X9m/OzQXsPlNS86qKGcLaJ4B/AaVZ8CLvccNTtKgoJYWq8zYI="
NO_DATA_IN_CACHE = ""

CONTAINER_WIDTH = 62
CONTAINER_HEIGHT = 30
GRAPH_WIDTH = 63  # Container is 62 wide, but that leaves an empty column for some reason
GRAPH_HEIGHT = 14
HOURS_PER_DAY = 24
MINUTES_PER_HOUR = 60
MINUTES_PER_DAY = 1440
QUIET_MAX = 0.4
BUSY_MAX = 0.7

def app_key():
    return secret.decrypt(ENCRYPTED_APP_KEY)  # No freebie quota available, have to use app key

# Get list of stations near a given location, or look up from cache if available.
def fetch_stations(loc):
    rounded_lat = math.round(1000.0 * float(loc["lat"])) / 1000.0  # truncate to 3dp, which means
    rounded_lng = math.round(1000.0 * float(loc["lng"])) / 1000.0  # to the nearest ~110 metres.
    cache_key = "{},{}".format(rounded_lat, rounded_lng)

    cached = cache.get(cache_key)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        STATION_URL,
        params = {
            "app_key": app_key(),
            "lat": str(rounded_lat),
            "lon": str(rounded_lng),
            "radius": "500",
            "stopTypes": "NaptanMetroStation",
            "returnLines": "false",
            "modes": "tube",
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

# Find and extract details of all stations near a given location.
def list_stations(location):
    loc = json.decode(location)
    if outside_uk_bounds(loc):
        return [schema.Option(
            display = "Default option - location is outside the UK",
            value = json.encode({
                "naptanId": DEFAULT_NAPTAN_ID,
                "name": DEFAULT_STATION_NAME,
            }),
        )]

    data = fetch_stations(loc)
    if not data:
        return []
    options = []
    for station in data["stopPoints"]:
        if not station.get("naptanId"):
            print("TFL station result does not include naptanId")
            continue
        if not station.get("commonName"):
            print("TFL station result does not include name")
            continue

        station_name = station["commonName"].removesuffix(" Underground Station")
        option = schema.Option(
            display = station_name,
            value = json.encode({
                "naptanId": station["naptanId"],
                "name": station_name,
            }),
        )
        options.append(option)
    return options

# Fetch data about how crowded the station currently is
def fetch_live_crowdedness(naptan_id):
    live_url = CROWDING_LIVE_URL % naptan_id
    cached = cache.get(live_url)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        live_url,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        print("TFL live crowding query failed with status ", resp.status_code)
        cache.set(live_url, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    if not resp.json().get("dataAvailable"):
        print("TFL live crowdedness data not available")
        cache.set(live_url, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(live_url, resp.body(), ttl_seconds = 300)  # Data is updated every 5 mins
    return resp.json()

# Extract data about currrent crowdedness from API response
def get_live_crowdedness(naptan_id):
    resp = fetch_live_crowdedness(naptan_id)
    if not resp:
        return None
    return resp["percentageOfBaseline"]

# Follows same numbering as humanize.day_of_week
def weekday_name(date):
    day_of_week = humanize.day_of_week(date)
    if day_of_week == 0:
        return "SUN"
    if day_of_week == 1:
        return "MON"
    if day_of_week == 2:
        return "TUE"
    if day_of_week == 3:
        return "WED"
    if day_of_week == 4:
        return "THU"
    if day_of_week == 5:
        return "FRI"
    if day_of_week == 6:
        return "SAT"
    fail("Invalid day of the week")

# Fetch data about how crowded the station typically is on a given day
def fetch_typical_crowdedness(naptan_id, now):
    typical_url = CROWDING_TYPICAL_URL % (naptan_id, weekday_name(now))
    cached = cache.get(typical_url)
    if cached:
        return json.decode(cached)
    resp = http.get(
        typical_url,
        params = {
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        print("TFL live crowding query failed with status ", resp.status_code)
        return None
    if not resp.json().get("isFound"):
        print("TFL live crowdedness data not available")
        return None
    cache.set(typical_url, resp.body(), ttl_seconds = 604800)  # Data only needed once a week
    return resp.json()

# Convert a time period from the API into a float we can use to plot.
# "13:45-14:00" -> 13.75
def extract_time(timeBand):
    hour = int(timeBand[0:2])
    minute = int(timeBand[3:5]) / float(MINUTES_PER_HOUR)
    return hour + minute

# Extract data about typical crowdedness from API response.
def get_typical_crowdedness(naptan_id, now):
    resp = fetch_typical_crowdedness(naptan_id, now)
    if not resp:
        return []
    data = []
    for band in resp["timeBands"]:
        data.append((extract_time(band["timeBand"]), band["percentageOfBaseLine"]))
    return data

# Using labels suggested by TfL themselves
# https://techforum.tfl.gov.uk/t/data-drop-near-real-time-crowding-data-api/1916
def format(crowdedness):
    if not crowdedness:
        return "Unknown", GREY, "?%"
    number = "{}%".format(int(100 * crowdedness))
    if crowdedness < QUIET_MAX:
        return "Quiet", GREEN, number
    if crowdedness < BUSY_MAX:
        return "Busy", ORANGE, number
    return "Very busy", RED, number

def main(config):
    station = config.get("station")
    if not station:
        station_name = DEFAULT_STATION_NAME
        naptan_id = DEFAULT_NAPTAN_ID
    else:
        data = json.decode(json.decode(station)["value"])
        station_name = data["name"]
        naptan_id = data["naptanId"]

    # Find out how busy things currently are.
    pct_peak_crowdedness = get_live_crowdedness(naptan_id)

    # Pick a colour and phrase to convey status.
    status, status_colour, status_number = format(pct_peak_crowdedness)

    # Show where we are in the graph.
    now = time.now().in_location("Europe/London")
    pct_of_day = ((MINUTES_PER_HOUR * now.hour) + now.minute) / float(MINUTES_PER_DAY)
    now_indicator = int(pct_of_day * GRAPH_WIDTH)

    # Get the data to fill the graph of typical busyness.
    typical_crowdedness = get_typical_crowdedness(naptan_id, now)

    return render.Root(
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Box(
                width = CONTAINER_WIDTH,
                height = CONTAINER_HEIGHT,
                child = render.Column(
                    children = [
                        # Station name
                        render.Marquee(
                            width = CONTAINER_WIDTH,
                            scroll_direction = "horizontal",
                            align = "center",
                            child = render.Text(station_name),
                        ),
                        # Current crowdedness
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Text(status, color = status_colour),
                                render.Text(status_number, color = status_colour),
                            ],
                        ),
                        # Typical crowdedness for this day of the week
                        render.Stack(
                            children = [
                                render.Plot(
                                    data = typical_crowdedness,
                                    width = GRAPH_WIDTH,
                                    height = GRAPH_HEIGHT,
                                    color = WHITE,
                                    x_lim = (0, HOURS_PER_DAY),
                                    y_lim = (0, 1),
                                    fill = True,
                                ),
                                # Current time of day
                                render.Padding(
                                    pad = (now_indicator, 0, 0, 0),
                                    child = render.Box(
                                        height = GRAPH_HEIGHT,
                                        width = 1,
                                        color = status_colour,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station",
                name = "Station",
                desc = "The tube station to check capacity for",
                icon = "trainSubway",
                handler = list_stations,
            ),
        ],
    )

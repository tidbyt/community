"""
Applet: London Bus Stop
Summary: Upcoming arrivals
Description: Shows upcoming arrivals at a specific bus stop in London.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_STOP_ID = "490020255S"
STOP_URL = "https://api.tfl.gov.uk/StopPoint"
ARRIVALS_URL = "https://api.tfl.gov.uk/StopPoint/%s/Arrivals"

# Allows 500 queries per minute
ENCRYPTED_API_KEY = "AV6+xWcELQeKmsYDiEPA6VUWk2IZKw+uc9dkaM5cXT/xirUKWgWKfsRAQz2pOxq0eKTNhb/aShsRjavxA84Ay12p6NaZDnDOgVeVxoMCCOnWxJsxmURHogJHpVQpuqBTNttfvafOj0PC1zUXkEpcN7EYhveycs6qxmouIwpDzY5I93wpTy4="
NO_DATA_IN_CACHE = ""

RED = "#DA291C"  # Pantone 485 C - same as the buses
ORANGE = "#FFA500"  # Like the countdown timers at bus stops
COUNTDOWN_HEIGHT = 24
FONT = "tom-thumb"

def app_key():
    return secret.decrypt(ENCRYPTED_API_KEY) or ""  # fall back to anonymous quota

# Validate and get stop details from search results.
def extract_stop(stop):
    if not stop.get("commonName"):
        print(stop)
        print("TFL StopPoint search result does not contain name")
        return None
    if not stop.get("stopLetter"):
        print(stop)
        print("TFL StopPoint search result does not contain stop code")
        return None
    if not stop.get("id"):
        print(stop)
        print("TFL StopPoint search result does not contain id")
        return None

    return schema.Option(
        display = "%s - %s" % (stop["stopLetter"], stop["commonName"]),
        value = stop["id"],
    )

# Perform the actual fetch of stops for a location, but use cache if available
def fetch_stops(loc):
    truncated_lat = math.round(1000.0 * float(loc["lat"])) / 1000.0  # Truncate to 3dp for better caching
    truncated_lng = math.round(1000.0 * float(loc["lng"])) / 1000.0  # Means to the nearest ~110 metres.
    cache_key = "{},{}".format(truncated_lat, truncated_lng)

    cached = cache.get(cache_key)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        STOP_URL,
        params = {
            "app_key": app_key(),
            "lat": str(truncated_lat),
            "lon": str(truncated_lng),
            "radius": "300",
            "stopTypes": "NaptanPublicBusCoachTram",
            "modes": "bus",
            "returnLines": "false",
            "categories": "Direction",
        },
    )
    if resp.status_code != 200:
        print("TFL StopPoint search failed with status ", resp.status_code)
        cache.set(cache_key, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    if not resp.json().get("stopPoints"):
        print("TFL StopPoint search does not contain stops")
        cache.set(cache_key, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(cache_key, resp.body(), ttl_seconds = 86400)  # Bus stops don't move often
    return resp.json()

# API gives errors when searching for locations outside the United Kingdom.
def outside_uk_bounds(loc):
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    if lat <= 49.9 or lat >= 58.7 or lng <= -11.05 or lng >= 1.78:
        return True
    return False

# Find list of stops near a given location.
def get_stops(location):
    loc = json.decode(location)
    if outside_uk_bounds(loc):
        return [schema.Option(
            display = "Default option - location is outside the UK",
            value = DEFAULT_STOP_ID,
        )]

    data = fetch_stops(loc)
    if not data:
        return []
    extracted = [extract_stop(stop) for stop in data["stopPoints"]]
    return [e for e in extracted if e]

# Perform the actual fetch for a stop, but use cache if available.
def fetch_stop(stop_id):
    cached = cache.get(stop_id)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    resp = http.get(
        url = STOP_URL + "/" + stop_id,
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

# Look up a particular stop by its Naptan ID. There can be a hierarchy of
# StopPoints. It seems like for buses, there is a parent ID for all the stops
# with a given name/at a given junction, and then a child ID for each stop.
# Assumed here that you're looking up a child stop, since you don't get any
# arrivals data if you look up the parent ID.
def get_stop(stop_id):
    data = fetch_stop(stop_id)
    if not data:
        return None

    # Looking up a child returns a response about the parent, which contains
    # a child object.
    for child in data["children"]:
        if child["naptanId"] != stop_id:
            continue

        if not child.get("commonName"):
            print("TFL StopPoint response did not contain name")
            continue
        if not child.get("stopLetter"):
            print("TFL StopPoint response did not contain stop letter")
            continue

        return {
            "name": child["commonName"],
            "code": child["stopLetter"],
        }

    return None

def get_arrivals(stop_id):
    resp = http.get(
        ARRIVALS_URL % stop_id,
        params = {
            "serviceTypes": "bus,night",
            "app_key": app_key(),
        },
    )
    if resp.status_code != 200:
        fail("TFL Arrivals request failed with status ", resp.status_code)

    arrivals = []
    for arrival in resp.json():
        if not arrival.get("lineName"):
            print("TFL Arrivals response did not contain line")
            continue
        if not arrival.get("timeToStation"):
            print("TFL Arrivals response did not contain arrival prediction")
            continue
        arrivals.append({
            "line": arrival["lineName"],
            "due_in_seconds": arrival["timeToStation"],
            "destination": arrival["destinationName"],
        })

    arrivals = sorted(arrivals, key = lambda x: x["due_in_seconds"])
    for i in range(len(arrivals)):
        arrivals[i]["index"] = i + 1
    return arrivals

# How long till a given bus comes?
def render_due(index, line, due_in_seconds):
    # Not 100% confident this is what the countdown timers at stops do,
    # but they have both "due" and "1 min", so there must be a difference.
    if due_in_seconds < 30:
        due = "due"
    else:
        due = "%d min" % math.round(due_in_seconds / 60.0)

    return render.Row(
        expanded = True,
        children = [
            # Include an index to a) mimic the countdown timers at bus stops
            # and b) if I can work out how to scroll to show more than 3 for
            # particularly busy stops.
            render.WrappedText(
                content = str(index),
                width = 8,
                color = ORANGE,
                font = FONT,
            ),
            render.WrappedText(
                content = line,
                width = 20,
                color = ORANGE,
                font = FONT,
            ),
            render.Row(
                main_align = "end",
                expanded = True,
                children = [
                    render.Text(
                        content = due,
                        color = ORANGE,
                        font = FONT,
                    ),
                ],
            ),
        ],
    )

# Where is a given bus going?
def render_destination(index, destination):
    return render.Row(
        expanded = True,
        children = [
            # Include an index to a) mimic the countdown timers at bus stops
            # and b) if I can work out how to scroll to show more than 4 for
            # particularly busy stops.
            render.WrappedText(
                content = str(index),
                width = 8,
                color = ORANGE,
                font = FONT,
            ),
            render.Text(
                content = destination,
                color = ORANGE,
                font = FONT,
            ),
        ],
    )

# Renders two frames for a set of four arrivals.
def render_arrivals_section(arrivals):
    if len(arrivals) == 0:
        return render.Box(
            height = COUNTDOWN_HEIGHT,
            child = render.WrappedText(
                content = "No upcoming arrivals",
                color = ORANGE,
            ),
        )

    return [
        # Show the number and how long to wait for each bus.
        render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Box(
                height = COUNTDOWN_HEIGHT,
                child = render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render_due(a["index"], a["line"], a["due_in_seconds"])
                        for a in arrivals
                    ],
                ),
            ),
        ),
        # Show the destination for each bus.
        render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Box(
                height = COUNTDOWN_HEIGHT,
                child = render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render_destination(a["index"], a["destination"])
                        for a in arrivals
                    ],
                ),
            ),
        ),
    ]

# Show up to 4 on a screen for as many screens as needed
def render_arrivals(arrivals):
    sections = []
    for i in range(0, len(arrivals), 4):
        sections.extend(render_arrivals_section(arrivals[i:i + 4]))
    frames = []
    for s in sections:
        frames.extend([s] * 100)
    return render.Animation(
        children = frames,
    )

def render_stop_details(name, code):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            # There's no room to say where each bus is heading, so just give the
            # direction for the stop. That makes it long, so scroll it.
            render.Padding(
                pad = (1, 1, 1, 0),
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 50,
                    height = 6,
                    child = render.Text(
                        content = name,
                        font = FONT,
                    ),
                ),
            ),
            # There are often multiple nearby stops with the same name, so be precise.
            # Can be up to two letters long.
            render.Box(
                width = 13,
                height = 7,
                child = render.Padding(
                    pad = (1, 1, 0, 0),
                    child = render.Text(
                        content = code,
                        font = FONT,
                    ),
                ),
                color = RED,
            ),
        ],
    )

def render_separator():
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Box(
            height = 1,
            color = ORANGE,
        ),
    )

def main(config):
    # Get data from TfL
    stop_id = config.get("stop_id")
    if not stop_id:
        stop_id = DEFAULT_STOP_ID
    else:
        stop_id = json.decode(stop_id)["value"]

    stop = get_stop(stop_id)
    if not stop:
        arrivals = []
        stop_name = "Unknown stop"
        stop_code = "?"
    else:
        arrivals = get_arrivals(stop_id)
        stop_name = stop["name"]
        stop_code = stop["code"]

    return render.Root(
        delay = 25,
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                # Top part is about the stop, because there are several near my flat
                # and I want to keep an eye on all of them
                render_stop_details(stop_name, stop_code),
                render_separator(),
                # Bottom part shows the countdown for the next few arrivals
                render_arrivals(arrivals[:12]),  # Up to 3 screens
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop_id",
                name = "Bus Stop",
                desc = "A list of bus stops based on a location.",
                icon = "bus",
                handler = get_stops,
            ),
        ],
    )

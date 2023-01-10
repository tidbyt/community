"""
Applet: Tube Status
Summary: Current status from TfL
Description: Shows the current status of each line on London Underground and other TfL services.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Allows 500 queries per minute
ENCRYPTED_APP_KEY = "AV6+xWcE2sENYC+/SYTqo/7oaIT8Q+BjV27Q/Bm9b1C19OEsiEuWKQQ3KKx6ymZQk2DOkiaPMjvoYmBlYZl/yr6AqusGweRYyA/gZ26zZBYX6krBCckHACEZQIS0mtAkwZmiLoGxhH2XpUkBBQdmBBwjODAqrcthPYPCm7u597BdzWyhljQ="
STATUS_URL = "https://api.tfl.gov.uk/Line/Mode/%s/Status"

WHITE = "#FFF"
BLACK = "#000"

DISPLAY_SCROLL = "DISPLAY_SCROLL"
DISPLAY_SEQUENTIAL = "DISPLAY_SEQUENTIAL"
NO_DATA_IN_CACHE = ""

LINES = {
    "bakerloo": {
        "colour": "#894E24",
        "display": "Bakerloo",
        "index": 0,
        "textColour": WHITE,
    },
    "central": {
        "colour": "#DC241F",
        "display": "Central",
        "index": 1,
        "textColour": WHITE,
    },
    "circle": {
        "colour": "#FFCC00",
        "display": "Circle",
        "index": 2,
        "textColour": BLACK,
    },
    "district": {
        "colour": "#007229",
        "display": "District",
        "index": 3,
        "textColour": WHITE,
    },
    "dlr": {
        "colour": "#00AFAD",
        "display": "Docklands",
        "index": 14,
        "textColour": BLACK,
    },
    "elizabeth": {
        "colour": "#6950A1",
        "display": "Elizabeth",
        "index": 4,
        "textColour": WHITE,
    },
    "hammersmith-city": {
        "colour": "#D799AF",
        "display": "H'smith & City",
        "index": 5,
        "textColour": BLACK,
    },
    "jubilee": {
        "colour": "#6A7278",
        "display": "Jubilee",
        "index": 6,
        "textColour": WHITE,
    },
    "london-overground": {
        "colour": "#D05F0E",
        "display": "Overground",
        "index": 12,
        "textColour": BLACK,
    },
    "metropolitan": {
        "colour": "#751056",
        "display": "Metropolitan",
        "index": 7,
        "textColour": WHITE,
    },
    "northern": {
        "colour": BLACK,
        "display": "Northern",
        "index": 8,
        "textColour": WHITE,
    },
    "piccadilly": {
        "colour": "#0019A8",
        "display": "Piccadilly",
        "index": 9,
        "textColour": WHITE,
    },
    "tram": {
        "colour": "#66CC00",
        "display": "Tram",
        "index": 15,
        "textColour": WHITE,
    },
    "victoria": {
        "colour": "#00A0E2",
        "display": "Victoria",
        "index": 10,
        "textColour": BLACK,
    },
    "waterloo-city": {
        "colour": "#76D0BD",
        "display": "W'loo & City",
        "index": 11,
        "textColour": BLACK,
    },
}

# Based on https://api.tfl.gov.uk/Line/Meta/Severity
# Edited to fit width of tidbyt screen
SEVERITIES = {
    0: "Special Srvce",
    1: "Closed",
    2: "Suspended",
    3: "Part Suspend",
    4: "Planned Close",
    5: "Part Closure",
    6: "Severe Delays",
    7: "Reduced Srvce",
    8: "Bus Service",
    9: "Minor Delays",
    10: "Good Service",
    11: "Part Closed",
    12: "Exit Only",
    13: "No Step Free",
    14: "Changed freq",
    15: "Diverted",
    16: "Not Running",
    17: "Issues Rptd",
    18: "No Issues",
    19: "Information",
    20: "Closed",
}

# Cache response for all users. It's always the same info with the same inputs so
# no need to fetch repeatedly.
def fetch_response():
    cache_key = "api_response"  # it's always the same input
    cached = cache.get(cache_key)
    if cached == NO_DATA_IN_CACHE:
        return None
    if cached:
        return json.decode(cached)
    app_key = secret.decrypt(ENCRYPTED_APP_KEY) or ""  # fall back to anonymous quota
    resp = http.get(
        url = STATUS_URL % ",".join(["tube", "elizabeth-line", "overground", "dlr", "tram"]),
        params = {
            "app_key": app_key,
        },
    )
    if resp.status_code != 200:
        print("TFL status request failed with status code ", resp.status_code)
        cache.set(cache_key, NO_DATA_IN_CACHE, ttl_seconds = 30)
        return None
    cache.set(cache_key, resp.body(), ttl_seconds = 60)
    return resp.json()

def fetch_lines():
    lines = []
    resp = fetch_response()
    if not resp:
        return None
    for line in resp:
        if "id" not in line:
            print("TFL status request did not contain line id")
            continue
        id = line["id"]

        if "lineStatuses" not in line:
            print("TFL status request did not contain status")
            continue
        if len(line["lineStatuses"]) == 0:
            print("TFL status request did not contain any status")
            continue
        if "statusSeverity" not in line["lineStatuses"][0]:
            print("TFL status request did not contain severity for line")
            continue
        severity = line["lineStatuses"][0]["statusSeverity"]

        if id not in LINES:
            print("Unknown line ID ", id)
            continue
        if severity not in SEVERITIES:
            print("Unknown severity level ", severity)
            continue

        lines.append({
            "colour": LINES[id]["colour"],
            "display": LINES[id]["display"],
            "index": LINES[id]["index"],
            "status": SEVERITIES[severity],
            "textColour": LINES[id]["textColour"],
        })

    # Sort in the familiar order, even if hand-curated.
    return sorted(lines, key = lambda x: x["index"])

def render_status(status):
    return render.Box(
        width = 64,
        height = 16,
        color = status["colour"],
        child = render.Column(
            main_align = "start",
            children = [
                render.WrappedText(
                    width = 62,
                    height = 8,
                    content = status["display"],
                    color = status["textColour"],
                ),
                render.WrappedText(
                    width = 62,
                    height = 8,
                    content = status["status"],
                    color = status["textColour"],
                ),
            ],
        ),
    )

def render_marquee(lines):
    return render.Marquee(
        scroll_direction = "vertical",
        height = 32,
        offset_start = 32,
        offset_end = 0,
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [render_status(line) for line in lines],
        ),
    )

def render_sequential(lines):
    frames = []
    for i in range(0, len(lines), 2):
        panes = [render_status(lines[i])]
        if i + 1 < len(lines):
            panes.append(render_status(lines[i + 1]))

        frame = render.Column(
            children = panes,
        )
        frames.append(frame)

    return render.Animation(
        children = frames,
    )

def render_error(message):
    return render.Root(
        child = render.WrappedText(
            content = message,
            width = 64,
            height = 32,
            align = "center",
        ),
    )

def main(config):
    lines = fetch_lines()
    if not lines or len(lines) == 0:
        return render_error("Could not load tube status")

    display_mode = config.get("display_mode", DISPLAY_SEQUENTIAL)
    if display_mode == DISPLAY_SCROLL:
        rendered = render_marquee(lines)
        delay = 49
    elif display_mode == DISPLAY_SEQUENTIAL:
        rendered = render_sequential(lines)
        delay = 2000

    return render.Root(
        delay = delay,
        child = rendered,
    )

def get_schema():
    display_modes = [
        schema.Option(
            display = "Scrolling",
            value = DISPLAY_SCROLL,
        ),
        schema.Option(
            display = "Sequential",
            value = DISPLAY_SEQUENTIAL,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display_mode",
                name = "Display mode",
                desc = "How to animate the status for different lines",
                icon = "display",
                default = DISPLAY_SEQUENTIAL,
                options = display_modes,
            ),
        ],
    )

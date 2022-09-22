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

LINES = {
    "bakerloo": {
        "display": "Bakerloo",
        "colour": "#894E24",
        "textColour": WHITE,
        "index": 0,
    },
    "central": {
        "display": "Central",
        "colour": "#DC241F",
        "textColour": WHITE,
        "index": 1,
    },
    "circle": {
        "display": "Circle",
        "colour": "#FFCC00",
        "textColour": BLACK,
        "index": 2,
    },
    "district": {
        "display": "District",
        "colour": "#007229",
        "textColour": WHITE,
        "index": 3,
    },
    "elizabeth": {
        "display": "Elizabeth",
        "colour": "#6950A1",
        "textColour": WHITE,
        "index": 4,
    },
    "hammersmith-city": {
        "display": "H'smith & City",
        "colour": "#D799AF",
        "textColour": BLACK,
        "index": 5,
    },
    "jubilee": {
        "display": "Jubilee",
        "colour": "#6A7278",
        "textColour": WHITE,
        "index": 6,
    },
    "metropolitan": {
        "display": "Metropolitan",
        "colour": "#751056",
        "textColour": WHITE,
        "index": 7,
    },
    "northern": {
        "display": "Northern",
        "colour": BLACK,
        "textColour": WHITE,
        "index": 8,
    },
    "piccadilly": {
        "display": "Piccadilly",
        "colour": "#0019A8",
        "textColour": WHITE,
        "index": 9,
    },
    "victoria": {
        "display": "Victoria",
        "colour": "#00A0E2",
        "textColour": BLACK,
        "index": 10,
    },
    "waterloo-city": {
        "display": "W'loo & City",
        "colour": "#76D0BD",
        "textColour": BLACK,
        "index": 11,
    },
    "london-overground": {
        "display": "Overground",
        "colour": "#D05F0E",
        "textColour": BLACK,
        "index": 12,
    },
    "dlr": {
        "display": "Docklands",
        "colour": "#00AFAD",
        "textColour": BLACK,
        "index": 14,
    },
    "tram": {
        "display": "Tram",
        "colour": "#66CC00",
        "textColour": WHITE,
        "index": 15,
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
        fail("TFL status request failed with status code ", resp.status_code)
    cache.set(cache_key, resp.body(), ttl_seconds = 60)
    return resp.json()

def fetch_lines():
    lines = []
    for line in fetch_response():
        if "id" not in line:
            fail("TFL status request did not contain line id")
        id = line["id"]

        if "lineStatuses" not in line:
            fail("TFL status request did not contain status")
        if len(line["lineStatuses"]) == 0:
            fail("TFL status request did not contain any status")
        if "statusSeverity" not in line["lineStatuses"][0]:
            fail("TFL status request did not contain severity for line")
        severity = line["lineStatuses"][0]["statusSeverity"]

        if id not in LINES:
            fail("Unknown line ID ", id)
        if severity not in SEVERITIES:
            fail("Unknown severity level ", severity)

        lines.append({
            "display": LINES[id]["display"],
            "colour": LINES[id]["colour"],
            "textColour": LINES[id]["textColour"],
            "index": LINES[id]["index"],
            "status": SEVERITIES[severity],
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

def main(config):
    lines = fetch_lines()

    return render.Root(
        delay = 49,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 32,
            offset_end = 0,
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [render_status(line) for line in lines],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

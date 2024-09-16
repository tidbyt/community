"""
Applet: Tube Status
Summary: Current status from TfL
Description: Shows the current status of each line on London Underground and other TfL services.
Author: dinosaursrarr
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Allows 500 queries per minute
ENCRYPTED_APP_KEY = "AV6+xWcEeixSBkR1KHTzJPTxGSqVwSCoXVa90hniq68hepDEK6uLPeeaVIhCHcXK6sdiBY/7M7a8Z794VOQDkmUWQS8Xi+ieOBxZQFl31GWq5Obm58GH+jmYHn5TXC1UJJobXfFuxoENuB7VG/mfB8UJpSh0zyPqje6F4iPih+MOsTW2U5c="
STATUS_URL = "https://api.tfl.gov.uk/Line/Mode/%s/Status"
USER_AGENT = "Tidbyt tube_status"

WHITE = "#FFF"
BLACK = "#000"
BECK_BLUE = "#0019A8"

DISPLAY_SCROLL = "DISPLAY_SCROLL"
DISPLAY_SEQUENTIAL = "DISPLAY_SEQUENTIAL"
PROBLEMS_FIRST = "PROBLEMS_FIRST"

LINES = {
    "bakerloo": {
        "display": "Bakerloo",
        "colour": "#894E24",
        "textColour": WHITE,
        "doubleLines": False,
        "index": 0,
    },
    "central": {
        "display": "Central",
        "colour": "#DC241F",
        "textColour": WHITE,
        "doubleLines": False,
        "index": 1,
    },
    "circle": {
        "display": "Circle",
        "colour": "#FFCC00",
        "textColour": BLACK,
        "doubleLines": False,
        "index": 2,
    },
    "district": {
        "display": "District",
        "colour": "#007229",
        "textColour": WHITE,
        "doubleLines": False,
        "index": 3,
    },
    "elizabeth": {
        "display": "Elizabeth",
        "colour": "#6950A1",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 4,
    },
    "hammersmith-city": {
        "display": "H'smith + City",
        "colour": "#D799AF",
        "textColour": BLACK,
        "doubleLines": False,
        "index": 5,
    },
    "jubilee": {
        "display": "Jubilee",
        "colour": "#6A7278",
        "textColour": WHITE,
        "doubleLines": False,
        "index": 6,
    },
    "metropolitan": {
        "display": "Metropolitan",
        "colour": "#751056",
        "textColour": WHITE,
        "doubleLines": False,
        "index": 7,
    },
    "northern": {
        "display": "Northern",
        "colour": BLACK,
        "textColour": WHITE,
        "doubleLines": False,
        "index": 8,
    },
    "piccadilly": {
        "display": "Piccadilly",
        "colour": BECK_BLUE,
        "textColour": WHITE,
        "doubleLines": False,
        "index": 9,
    },
    "victoria": {
        "display": "Victoria",
        "colour": "#00A0E2",
        "textColour": BLACK,
        "doubleLines": False,
        "index": 10,
    },
    "waterloo-city": {
        "display": "W'loo + City",
        "colour": "#76D0BD",
        "textColour": BLACK,
        "doubleLines": False,
        "index": 11,
    },
    "london-overground": {
        "display": "Overground",
        "colour": "#D05F0E",
        "textColour": BLACK,
        "doubleLines": True,
        "index": 12,
    },
    "liberty": {
        "display": "Liberty",
        "colour": "#61686B",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 13,
    },
    "lioness": {
        "display": "Lioness",
        "colour": "#FFA600",
        "textColour": BLACK,
        "doubleLines": True,
        "index": 14,
    },
    "mildmay": {
        "display": "Mildmay",
        "colour": "#006FE6",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 15,
    },
    "suffragette": {
        "display": "Suffragette",
        "colour": "#18A95D",
        "textColour": BLACK,
        "doubleLines": True,
        "index": 16,
    },
    "weaver": {
        "display": "Weaver",
        "colour": "#9B0058",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 17,
    },
    "windrush": {
        "display": "Windrush",
        "colour": "#DC241F",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 18,
    },
    "dlr": {
        "display": "Docklands",
        "colour": "#00AFAD",
        "textColour": BLACK,
        "doubleLines": True,
        "index": 19,
    },
    "tram": {
        "display": "Tram",
        "colour": "#66CC00",
        "textColour": WHITE,
        "doubleLines": True,
        "index": 20,
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
    app_key = secret.decrypt(ENCRYPTED_APP_KEY) or ""  # fall back to anonymous quota
    resp = http.get(
        url = STATUS_URL % ",".join(["tube", "elizabeth-line", "overground", "dlr", "tram"]),
        params = {
            "app_key": app_key,
        },
        headers = {
            "User-Agent": USER_AGENT,
        },
        ttl_seconds = 60,
    )
    if resp.status_code != 200:
        print("TFL status request failed with status code ", resp.status_code)
        return None
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
            "display": LINES[id]["display"],
            "colour": LINES[id]["colour"],
            "textColour": LINES[id]["textColour"],
            "doubleLines": LINES[id]["doubleLines"],
            "index": LINES[id]["index"],
            "status": SEVERITIES[severity],
        })

    # Sort in the familiar order, even if hand-curated.
    return sorted(lines, key = lambda x: x["index"])

def render_status(status):
    return render.Box(
        width = 64,
        height = 16,
        color = BLACK,
        child = render.Row(
            main_align = "start",
            children = [
                render.Box(
                    width = 1,
                    height = 16,
                    color = status["colour"],
                ),
                render.Box(
                    width = 1,
                    height = 16,
                    color = BLACK if status["doubleLines"] else status["colour"],
                ),
                render.Box(
                    width = 1,
                    height = 16,
                    color = status["colour"],
                ),
                render.Box(
                    width = 1,
                    height = 16,
                    color = BLACK,
                ),
                render.Column(
                    children = [
                        render.WrappedText(
                            width = 60,
                            height = 8,
                            content = status["display"],
                            color = WHITE,
                        ),
                        render.WrappedText(
                            width = 60,
                            height = 8,
                            content = status["status"],
                            color = WHITE,
                        ),
                    ],
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
        frames.append(
            render.Column(
                children = panes,
            ),
        )

    return render.Animation(
        children = frames,
    )

def render_remainder(all_good, whole_screen):
    height = 32 if whole_screen else 16
    return render.Box(
        width = 64,
        height = height,
        color = BECK_BLUE,
        child = render.Column(
            main_align = "start",
            children = [
                render.WrappedText(
                    width = 62,
                    height = height,
                    content = "Good service %s lines" % ("on all" if all_good else "other"),
                    color = WHITE,
                ),
            ],
        ),
    )

def render_problems(lines):
    frames = []
    problems = [line for line in lines if line["status"] != SEVERITIES[10]]
    all_affected = len(problems) == len(lines)

    if not problems:
        return render_remainder(True, True)

    for i in range(0, len(problems), 2):
        panes = [render_status(problems[i])]
        if i + 1 < len(problems):
            panes.append(render_status(problems[i + 1]))
        frames.append(
            render.Column(
                children = panes,
            ),
        )

    if not all_affected:
        # Add to bottom half of last frame if there's space
        if len(frames[-1].children) == 1:
            frames[-1] = render.Column(
                children = [
                    frames[-1].children[0],
                    render_remainder(False, False),
                ],
            )
        else:
            # Otherwise make a new frame
            frames.append(
                render.Column(
                    children = [render_remainder(False, True)],
                ),
            )

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
    elif display_mode == PROBLEMS_FIRST:
        rendered = render_problems(lines)
        delay = 2000
    else:
        rendered = []
        delay = 50

    return render.Root(
        max_age = 120,
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
        schema.Option(
            display = "Problems first",
            value = PROBLEMS_FIRST,
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
                default = PROBLEMS_FIRST,
                options = display_modes,
            ),
        ],
    )

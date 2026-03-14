"""
PATH Train Real-Time Departures for Tidbyt

Fetches live departure data from the Port Authority PATH API
and displays the next upcoming trains for a user-selected station
on a 64x32 RGB LED matrix.

Author: Shri
"""

load("http.star", "http")

# render: Tidbyt UI toolkit — provides widgets like Text, Row, Column, Box
# http: HTTP client for fetching data from external APIs
# json: JSON encoding/decoding (loaded for compatibility, rep.json() handles parsing)
# schema: Defines user-configurable settings shown in the Tidbyt mobile app
load("render.star", "render")
load("schema.star", "schema")

# Port Authority real-time PATH train data endpoint.
# Returns JSON with departure info for all stations, updated every ~30 seconds.
PATH_API_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json"

# Station code to display name mapping.
# Codes match the "consideredStation" field in the API response.
STATIONS = {
    "NWK": "Newark",
    "HAR": "Harrison",
    "JSQ": "Journal Sq",
    "GRV": "Grove St",
    "NEW": "Newport",
    "EXP": "Exchange Pl",
    "HOB": "Hoboken",
    "WTC": "World Trade",
    "CHR": "Christopher",
    "09S": "9th St",
    "14S": "14th St",
    "23S": "23rd St",
    "33S": "33rd St",
}

# Default station shown when the user hasn't configured one yet.
DEFAULT_STATION = "HOB"

def main(config):
    """Main entry point called by the Tidbyt runtime on each render cycle.

    Args:
        config: Dictionary of user settings from get_schema() (e.g. selected station).

    Returns:
        render.Root: The top-level widget tree to display on the Tidbyt.
    """

    # Read the user's selected station, or fall back to default.
    station = config.get("station", DEFAULT_STATION)

    # Fetch real-time data from the PATH API.
    # ttl_seconds=30 caches the response for 30s to avoid excessive requests.
    rep = http.get(PATH_API_URL, ttl_seconds = 30)
    if rep.status_code != 200:
        return render.Root(
            child = render.Text("API Error", color = "#FF0000"),
        )

    # Parse the JSON response and extract departures for our station.
    # API structure: { results: [{ consideredStation: "HOB", destinations: [{ messages: [...] }] }] }
    data = rep.json()
    departures = []

    for result in data.get("results", []):
        if result.get("consideredStation") == station:
            # Each destination (e.g. "World Trade Center") has an array of messages,
            # where each message represents an upcoming train with ETA info.
            for dest in result.get("destinations", []):
                for msg in dest.get("messages", []):
                    departures.append(msg)
            break

    # If no trains are scheduled, show a "No trains" message.
    if len(departures) == 0:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(STATIONS.get(station, station), color = "#4D92FB", font = "tb-8"),
                    render.Text("No trains", color = "#888888"),
                ],
            ),
        )

    # Sort departures by ETA (soonest first) using secondsToArrival.
    departures = sorted(departures, key = lambda d: int(d.get("secondsToArrival", "9999")))

    # Limit to 3 departures — the 32px tall display fits ~3 rows below the header.
    departures = departures[:3]

    # Build the widget tree: a header row + one row per departure.
    rows = []

    # Station name header in blue, with 1px bottom padding to separate from train rows.
    rows.append(
        render.Padding(
            pad = (0, 0, 0, 1),
            child = render.Text(
                STATIONS.get(station, station),
                color = "#4D92FB",
                font = "tb-8",
            ),
        ),
    )

    # Render each departure as a row: [colored dot + destination] ... [ETA]
    for dep in departures:
        head_sign = dep.get("headSign", "???")
        eta = dep.get("arrivalTimeMessage", "?")

        # The API returns line colors as comma-separated hex values (e.g. "4D92FB,FF6319"
        # for multi-line stops). Use the first color for the indicator dot.
        colors = dep.get("lineColor", "FFFFFF").split(",")
        line_color = "#" + colors[0]

        # Abbreviate long destination names to fit the 64px wide display.
        short_name = shorten(head_sign)

        rows.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    # Left side: colored line indicator dot + destination name
                    render.Row(
                        children = [
                            render.Box(width = 3, height = 3, color = line_color),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.Text(short_name, font = "tom-thumb"),
                            ),
                        ],
                    ),
                    # Right side: ETA in orange (e.g. "2 min", "Arriving")
                    render.Text(eta, color = "#FFA500", font = "tom-thumb"),
                ],
            ),
        )

    # Wrap all rows in a Column inside the required Root widget.
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = rows,
        ),
    )

def shorten(name):
    """Abbreviate destination names to fit the 64px wide Tidbyt display.

    The API returns full names like "33rd Street via Hoboken" which are too
    long for the tiny screen. This maps them to compact alternatives.

    Args:
        name: Full destination name from the API's headSign field.

    Returns:
        Shortened display name, or the original if no mapping exists.
    """
    replacements = {
        "World Trade Center": "WTC",
        "33rd Street": "33rd St",
        "33rd Street via Hoboken": "33rd/HOB",
        "Journal Square": "Jrnl Sq",
        "Journal Square via Hoboken": "JSQ/HOB",
        "Hoboken": "Hoboken",
        "Newark": "Newark",
        "Christopher Street": "Chris St",
        "Exchange Place": "Exchg Pl",
        "Grove Street": "Grove St",
        "Newport": "Newport",
        "Harrison": "Harrison",
        "14th Street": "14th St",
        "23rd Street": "23rd St",
        "9th Street": "9th St",
    }
    return replacements.get(name, name)

def get_schema():
    """Defines the user-configurable settings for the Tidbyt mobile app.

    Returns a schema with a dropdown to select the PATH station.
    This appears when the user adds or edits the app on their Tidbyt device.
    """
    options = [
        schema.Option(display = STATIONS[code], value = code)
        for code in [
            "HOB",
            "WTC",
            "JSQ",
            "NWK",
            "NEW",
            "EXP",
            "GRV",
            "HAR",
            "CHR",
            "09S",
            "14S",
            "23S",
            "33S",
        ]
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Select your PATH station",
                icon = "train",
                default = DEFAULT_STATION,
                options = options,
            ),
        ],
    )

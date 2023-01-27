"""
Applet: Fuzzy Clock
Author: Max Timkovich
Summary: Human readable time
Description: Display the time in a groovy, human-readable way.
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 40.7,
    "lng": -74.0,
    "locality": "Brooklyn",
}
DEFAULT_TIMEZONE = "US/Eastern"

words = {
    1: "ONE",
    2: "TWO",
    3: "THREE",
    4: "FOUR",
    5: "FIVE",
    6: "SIX",
    7: "SEVEN",
    8: "EIGHT",
    9: "NINE",
    10: "TEN",
    11: "ELEVEN",
    12: "TWELVE",
    15: "QUARTER",
    20: "TWENTY",
    25: "TWENTY-FIVE",
    30: "HALF",
}

def round(minutes):
    """Returns:
        minutes: rounded to the nearest 5.
        up: if we rounded up or down.
    """
    rounded = (minutes + 2) % 60 // 5 * 5
    up = False

    if rounded > 30:
        rounded = 60 - rounded
        up = True
    elif minutes > 30 and rounded == 0:
        up = True

    return rounded, up

def fuzzy_time(config, hours, minutes):
    glue = "PAST"
    rounded, up = round(minutes)

    if up:
        hours += 1

        glue = "TILL" if config.get("dialect") == "american" else "TO"

    # Handle 24 hour time.
    if hours > 12:
        hours -= 12

    # Handle midnight.
    if hours == 0:
        hours = 12

    if rounded == 0:
        return [words[hours], "O’CLOCK"]

    return [words[rounded], glue, words[hours]]

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    fuzzed = fuzzy_time(config, now.hour, now.minute)

    # Add some left padding for ~style~.
    texts = [render.Text(" " * i + s) for i, s in enumerate(fuzzed)]

    return render.Root(
        child = render.Padding(
            pad = 4,
            child = render.Column(
                children = texts,
            ),
        ),
    )

def get_schema():
    dialectOptions = [
        schema.Option(
            display = "American English",
            value = "american",
        ),
        schema.Option(
            display = "British English",
            value = "british",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "dialect",
                name = "Dialect",
                icon = "language",
                desc = "British or American English",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
        ],
    )

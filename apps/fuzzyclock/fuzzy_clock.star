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

numbersPerLang = {
    "nl-NL": {
        1: "ÉÉN",
        2: "TWEE",
        3: "DRIE",
        4: "VIER",
        5: "VIJF",
        6: "ZES",
        7: "ZEVEN",
        8: "ACHT",
        9: "NEGEN",
        10: "TIEN",
        11: "ELF",
        12: "TWAALF",
    },
    "de-DE": {
        1: "EINS",
        2: "ZWEI",
        3: "DREI",
        4: "VIER",
        5: "FÜNF",
        6: "SECHS",
        7: "SIEBEN",
        8: "ACHT",
        9: "NEUN",
        10: "ZEHN",
        11: "ELF",
        12: "ZWÖLF",
    },
    "en-US": {
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
    },
}
numbersPerLang["en-GB"] = numbersPerLang["en-US"]
numbersPerLang["nl-BE"] = numbersPerLang["nl-NL"]
numbersPerLang["de-DE-alt"] = numbersPerLang["de-DE"]
numbersPerLang["de-DE-alt2"] = numbersPerLang["de-DE"]
numbersPerLang["de-CH"] = numbersPerLang["de-DE"]
numbersPerLang["de-CH-alt"] = numbersPerLang["de-DE"]

patternsPerLang = {
    "de-CH": {
        0: "{hour}\nUHR",
        5: "FÜNF\nAB\n{hour}",
        10: "ZEHN\nAB\n{hour}",
        15: "VIERTEL\nAB\n{hour}",
        20: "ZEHN\nVOR HALB\n{next_hour}",
        25: "FÜNF\nVOR HALB\n{next_hour}",
        30: "HALB\n{next_hour}",
        35: "FÜNF\nNACH HALB\n{next_hour}",
        40: "ZEHN\nNACH HALB\n{next_hour}",
        45: "VIERTEL\nVOR\n{next_hour}",
        50: "ZEHN\nVOR\n{next_hour}",
        55: "FÜNF\nVOR\n{next_hour}",
    },
    "de-CH-alt": {
        0: "{hour}\nUHR",
        5: "FÜNF\nAB\n{hour}",
        10: "ZEHN\nAB\n{hour}",
        15: "VIERTEL\nAB\n{hour}",
        20: "ZWANZIG\nAB\n{hour}",
        25: "FÜNF\nVOR HALB\n{next_hour}",
        30: "HALB\n{next_hour}",
        35: "FÜNF\nNACH HALB\n{next_hour}",
        40: "ZWANZIG\nVOR {next_hour}",
        45: "VIERTEL\nVOR {next_hour}",
        50: "ZEHN\nVOR\n{next_hour}",
        55: "FÜNF\nVOR\n{next_hour}",
    },
    "de-DE": {
        0: "{hour}\nUHR",
        5: "FÜNF\nNACH {hour}",
        10: "ZEHN\nNACH {hour}",
        15: "VIERTEL\nNACH\n{hour}",
        20: "ZEHN\nVOR HALB\n{next_hour}",
        25: "FÜNF\nVOR HALB\n{next_hour}",
        30: "HALB\n{next_hour}",
        35: "FÜNF\nNACH HALB\n{next_hour}",
        40: "ZEHN\nNACH HALB\n{next_hour}",
        45: "VIERTEL\nVOR\n{next_hour}",
        50: "ZEHN\nVOR\n{next_hour}",
        55: "FÜNF\nVOR\n{next_hour}",
    },
    "de-DE-alt": {
        0: "{hour}\nUHR",
        5: "FÜNF\nNACH\n{hour}",
        10: "ZEHN\nNACH\n{hour}",
        15: "VIERTEL\nNACH\n{hour}",
        20: "ZWANZIG\nNACH\n{hour}",
        25: "FÜNF\nVOR HALB\n{next_hour}",
        30: "HALB\n{next_hour}",
        35: "FÜNF\nNACH HALB\n{next_hour}",
        40: "ZWANZIG\nVOR\n{next_hour}",
        45: "VIERTEL\nVOR\n{next_hour}",
        50: "ZEHN\nVOR\n{next_hour}",
        55: "FÜNF\nVOR\n{next_hour}",
    },
    "de-DE-alt2": {
        0: "{hour}\nUHR",
        5: "FÜNF\nNACH\n{hour}",
        10: "ZEHN\nNACH\n{hour}",
        15: "VIERTEL\n{next_hour}",
        20: "ZEHN\nVOR HALB\n{next_hour}",
        25: "FÜNF\nVOR HALB\n{next_hour}",
        30: "HALB\n{next_hour}",
        35: "FÜNF\nNACH HALB\n{next_hour}",
        40: "FÜNF VOR\nDREIVIERTEL\n{next_hour}",
        45: "DREI\nVIERTEL\n{next_hour}",
        50: "ZEHN\nVOR\n{next_hour}",
        55: "FÜNF\nVOR\n{next_hour}",
    },
    "en-GB": {
        0: "{hour}\nO’CLOCK",
        5: "FIVE\nPAST\n{hour}",
        10: "TEN\nPAST\n{hour}",
        15: "QUARTER\nPAST\n{hour}",
        20: "TWENTY\nPAST\n{hour}",
        25: "TWENTY-FIVE\nPAST\n{hour}",
        30: "HALF\nPAST\n{hour}",
        35: "TWENTY-FIVE\nTILL\n{next_hour}",
        40: "TWENTY\nTILL\n{next_hour}",
        45: "QUARTER\nTILL\n{next_hour}",
        50: "TEN\nTILL\n{next_hour}",
        55: "FIVE\nTILL\n{next_hour}",
    },
    "en-US": {
        0: "{hour}\nO’CLOCK",
        5: "FIVE\nPAST\n{hour}",
        10: "TEN\nPAST\n{hour}",
        15: "QUARTER\nPAST\n{hour}",
        20: "TWENTY\nPAST\n{hour}",
        25: "TWENTY-FIVE\nPAST\n{hour}",
        30: "HALF\nPAST\n{hour}",
        35: "TWENTY-FIVE\nTO\n{next_hour}",
        40: "TWENTY\nTO\n{next_hour}",
        45: "QUARTER\nTO\n{next_hour}",
        50: "TEN\nTO\n{next_hour}",
        55: "FIVE\nTO\n{next_hour}",
    },
    "nl-BE": {
        0: "{hour} UUR",
        5: "VIJF\nNA\n{hour}",
        10: "TIEN\nNA\n{hour}",
        15: "KWART\nNA\n{hour}",
        20: "TIEN VOOR HALF\n{next_hour}",
        25: "VIJF VOOR HALF\n{next_hour}",
        30: "HALF\n{next_hour}",
        35: "VIJF\nNA HALF\n{next_hour}",
        40: "TIEN\nNA HALF\n{next_hour}",
        45: "KWART\nVOOR\n{next_hour}",
        50: "TIEN\nVOOR\n{next_hour}",
        55: "VIJF\nVOOR\n{next_hour}",
    },
    "nl-NL": {
        0: "{hour}\nUUR",
        5: "VIJF\nOVER\n{hour}",
        10: "TIEN\nOVER\n{hour}",
        15: "KWART\nOVER\n{hour}",
        20: "TIEN\nVOOR HALF\n{next_hour}",
        25: "VIJF\nVOOR HALF\n{next_hour}",
        30: "HALF\n{next_hour}",
        35: "VIJF\nOVER HALF\n{next_hour}",
        40: "TIEN\nOVER HALF\n{next_hour}",
        45: "KWART\nVOOR\n{next_hour}",
        50: "TIEN\nVOOR\n{next_hour}",
        55: "VIJF\nVOOR\n{next_hour}",
    },
}

def display_hour(hour):
    """Returns:
        hour to display (in 12h format with 12 instead of 0)
    """

    # Handle 24 hour time.
    if hour > 12:
        hour -= 12

    # Handle midnight.
    if hour == 0:
        hour = 12

    return hour

def fuzzy_time(hours, minutes, language):
    numbers = numbersPerLang[language]
    patterns = patternsPerLang[language]

    # Round up to the next 5 minutes
    rounded = (minutes + 2) % 60 // 5 * 5
    if minutes > 55 and rounded == 0:
        hours += 1

    pattern = patterns[rounded]
    cur_hour = numbers[display_hour(hours)]
    next_hour = numbers[display_hour(hours + 1)]
    return pattern.format(hour = cur_hour, next_hour = next_hour).splitlines()

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    hours = now.hour
    minutes = now.minute
    language = config.get("dialect") or "en-US"

    # backwards compatibility
    if language == "american":
        language = "en-US"
    elif language == "british":
        language = "en-GB"

    fuzzed = fuzzy_time(hours, minutes, language)

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
            value = "en-US",
        ),
        schema.Option(
            display = "British English",
            value = "en-GB",
        ),
        schema.Option(
            display = "Deutsch",
            value = "de-DE",
        ),
        schema.Option(
            display = "Deutsch (Alternative)",
            value = "de-DE-alt",
        ),
        schema.Option(
            display = "Deutsch (Alternative 2)",
            value = "de-DE-alt2",
        ),
        schema.Option(
            display = "Deutsch (Schweiz)",
            value = "de-CH",
        ),
        schema.Option(
            display = "Deutsch (Schweiz, Alternative)",
            value = "de-CH-alt",
        ),
        schema.Option(
            display = "Dutch",
            value = "nl-NL",
        ),
        schema.Option(
            display = "Dutch (Belgium)",
            value = "nl-BE",
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
                name = "Language",
                icon = "language",
                desc = "Language in which to display time",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
        ],
    )

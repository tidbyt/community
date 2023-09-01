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
numbersPerLang["de-AT"] = numbersPerLang["de-DE"]
numbersPerLang["de-DE-alt"] = numbersPerLang["de-DE"]
numbersPerLang["de-DE-alt2"] = numbersPerLang["de-DE"]
numbersPerLang["de-CH"] = numbersPerLang["de-DE"]
numbersPerLang["de-CH-alt"] = numbersPerLang["de-DE"]

patternsPerLang = {
    "de-AT": {
        0: "{hour},UHR",
        5: "FÜNF,ÜBER,{hour}",
        10: "ZEHN,ÜBER,{hour}",
        15: "VIERTEL,ÜBER,{hour}",
        20: "ZEHN,VOR HALB,{next_hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "ZEHN,NACH HALB,{next_hour}",
        45: "VIERTEL,VOR,{next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "de-CH": {
        0: "{hour},UHR",
        5: "FÜNF,AB,{hour}",
        10: "ZEHN,AB,{hour}",
        15: "VIERTEL,AB,{hour}",
        20: "ZEHN,VOR HALB,{next_hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "ZEHN,NACH HALB,{next_hour}",
        45: "VIERTEL,VOR,{next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "de-CH-alt": {
        0: "{hour},UHR",
        5: "FÜNF,AB,{hour}",
        10: "ZEHN,AB,{hour}",
        15: "VIERTEL,AB,{hour}",
        20: "ZWANZIG,AB,{hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "ZWANZIG,VOR {next_hour}",
        45: "VIERTEL,VOR {next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "de-DE": {
        0: "{hour},UHR",
        5: "FÜNF,NACH {hour}",
        10: "ZEHN,NACH {hour}",
        15: "VIERTEL,NACH,{hour}",
        20: "ZEHN,VOR HALB,{next_hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "ZEHN,NACH HALB,{next_hour}",
        45: "VIERTEL,VOR,{next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "de-DE-alt": {
        0: "{hour},UHR",
        5: "FÜNF,NACH,{hour}",
        10: "ZEHN,NACH,{hour}",
        15: "VIERTEL,NACH,{hour}",
        20: "ZWANZIG,NACH,{hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "ZWANZIG,VOR,{next_hour}",
        45: "VIERTEL,VOR,{next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "de-DE-alt2": {
        0: "{hour},UHR",
        5: "FÜNF,NACH,{hour}",
        10: "ZEHN,NACH,{hour}",
        15: "VIERTEL,{next_hour}",
        20: "ZEHN,VOR HALB,{next_hour}",
        25: "FÜNF,VOR HALB,{next_hour}",
        30: "HALB,{next_hour}",
        35: "FÜNF,NACH HALB,{next_hour}",
        40: "FÜNF VOR,DREIVIERTEL,{next_hour}",
        45: "DREI,VIERTEL,{next_hour}",
        50: "ZEHN,VOR,{next_hour}",
        55: "FÜNF,VOR,{next_hour}",
    },
    "en-US": {
        0: "{hour},O’CLOCK",
        5: "FIVE,PAST,{hour}",
        10: "TEN,PAST,{hour}",
        15: "QUARTER,PAST,{hour}",
        20: "TWENTY,PAST,{hour}",
        25: "TWENTY-FIVE,PAST,{hour}",
        30: "HALF,PAST,{hour}",
        35: "TWENTY-FIVE,TILL,{next_hour}",
        40: "TWENTY,TILL,{next_hour}",
        45: "QUARTER,TILL,{next_hour}",
        50: "TEN,TILL,{next_hour}",
        55: "FIVE,TILL,{next_hour}",
    },
    "en-GB": {
        0: "{hour},O’CLOCK",
        5: "FIVE,PAST,{hour}",
        10: "TEN,PAST,{hour}",
        15: "QUARTER,PAST,{hour}",
        20: "TWENTY,PAST,{hour}",
        25: "TWENTY-FIVE,PAST,{hour}",
        30: "HALF,PAST,{hour}",
        35: "TWENTY-FIVE,TO,{next_hour}",
        40: "TWENTY,TO,{next_hour}",
        45: "QUARTER,TO,{next_hour}",
        50: "TEN,TO,{next_hour}",
        55: "FIVE,TO,{next_hour}",
    },
    "nl-BE": {
        0: "{hour} UUR",
        5: "VIJF,NA,{hour}",
        10: "TIEN,NA,{hour}",
        15: "KWART,NA,{hour}",
        20: "TIEN,VOOR HALF,{next_hour}",
        25: "VIJF,VOOR HALF,{next_hour}",
        30: "HALF,{next_hour}",
        35: "VIJF,NA HALF,{next_hour}",
        40: "TIEN,NA HALF,{next_hour}",
        45: "KWART,VOOR,{next_hour}",
        50: "TIEN,VOOR,{next_hour}",
        55: "VIJF,VOOR,{next_hour}",
    },
    "nl-NL": {
        0: "{hour},UUR",
        5: "VIJF,OVER,{hour}",
        10: "TIEN,OVER,{hour}",
        15: "KWART,OVER,{hour}",
        20: "TIEN,VOOR HALF,{next_hour}",
        25: "VIJF,VOOR HALF,{next_hour}",
        30: "HALF,{next_hour}",
        35: "VIJF,OVER HALF,{next_hour}",
        40: "TIEN,OVER HALF,{next_hour}",
        45: "KWART,VOOR,{next_hour}",
        50: "TIEN,VOOR,{next_hour}",
        55: "VIJF,VOOR,{next_hour}",
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

    # Special case
    if language.startswith("de") and cur_hour == "EINS" and rounded == 0:
        cur_hour = "EIN"  # "EIN UHR" instead of "EINS UHR"

    return pattern.format(hour = cur_hour, next_hour = next_hour).split(",")

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
            display = "Deutsch (Österreich)",
            value = "de-AT",
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

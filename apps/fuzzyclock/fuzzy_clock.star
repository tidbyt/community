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
        15: "KWART",
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
        15: "VIERTEL",
        20: "ZWANZIG",
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
        15: "QUARTER",
        20: "TWENTY",
        25: "TWENTY-FIVE",
        30: "HALF",
    },
}
numbersPerLang["en-GB"] = numbersPerLang["en-US"]
numbersPerLang["nl-BE"] = numbersPerLang["nl-NL"]
numbersPerLang["de-CH"] = numbersPerLang["de-DE"]

wordsPerLang = {
    "nl-NL": {
        "hour": "UUR",
        "half": "HALF",
        "to": "VOOR",
        "past": "OVER",
    },
    "nl-BE": {
        "hour": "UUR",
        "half": "HALF",
        "to": "VOOR",
        "past": "NA",
    },
    "de-DE": {
        "hour": "UHR",
        "half": "HALB",
        "to": "VOR",
        "past": "NACH",
    },
    "de-CH": {
        "hour": "UHR",
        "half": "HALB",
        "to": "VOR",
        "past": "AB",
    },
    "en-US": {
        "hour": "O’CLOCK",
        "half": "HALF",
        "to": "TILL",
        "past": "PAST",
    },
    "en-GB": {
        "hour": "O’CLOCK",
        "half": "HALF",
        "to": "TO",
        "past": "PAST",
    },
}

# At which point a dialect switches from one hour to the next
# Example: 6:20
# en-US: TWENTY PAST SIX
# nl-NL: TEN TO HALF SEVEN
roundUpFrom = {
    "de-DE": 15,
    "de-CH": 15,
    "en-GB": 30,
    "en-US": 30,
    "nl-NL": 15,
    "nl-BE": 15,
}

def round(minutes, up_threshold):
    """Returns:
        minutes: rounded to the nearest 5.
        up: if we rounded up or down.
    """
    rounded = (minutes + 2) % 60 // 5 * 5
    up = False

    if rounded > up_threshold:
        up = True
    elif minutes > 30 and rounded == 0:
        up = True

    return rounded, up

def fuzzy_time(hours, minutes, language):
    numbers = numbersPerLang[language]
    words = wordsPerLang[language]

    glue = words["past"]
    rounded, up = round(minutes, roundUpFrom[language])

    if up:
        hours += 1
        glue = words["to"]

    # Handle 24 hour time.
    if hours > 12:
        hours -= 12

    # Handle midnight.
    if hours == 0:
        hours = 12

    # Handle the whole hours
    if rounded == 0:
        return [numbers[hours], words["hour"]]

    if up:
        if roundUpFrom[language] < 30:
            if rounded < 30:
                return [numbers[30 - rounded], words["to"] + " " + words["half"], numbers[hours]]

            if rounded == 30:
                return [words["half"], numbers[hours]]

            if rounded < 45:
                return [numbers[rounded - 30], words["past"] + " " + words["half"], numbers[hours]]

        rounded = 60 - rounded

    return [numbers[rounded], glue, numbers[hours]]

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
            display = "Deutsch (Schweiz)",
            value = "de-CH",
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

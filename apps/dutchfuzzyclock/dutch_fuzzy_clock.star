"""
Applet: Dutch Fuzzy Clock
Summary: Dutch readable time
Description: Display the time in the wierd Dutch way.
Author: Remy Blok
"""
# Special thanks to Max Timkovich for the original English Fuzzy Clock

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 52.4,
    "lng": 4.9,
    "locality": "Amsterdam",
}
DEFAULT_TIMEZONE = "Europe/Amsterdam"

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
    },
}
numbersPerLang["en-GB"] = numbersPerLang["en-US"]

wordsPerLang = {
    "nl-NL": {
        "hour": "UUR",
        "half": "HALF",
        "to": "VOOR",
        "past": "OVER",
    },
    "en-US": {
        "hour": "O'CLOCK",
        "half": "HALF",
        "to": "TILL",
        "past": "PAST",
    },
    "en-GB": {
        "hour": "O'CLOCK",
        "half": "HALF",
        "to": "TO",
        "past": "PAST",
    },
}

def fuzzy_time(hours, minutes, language):
    numbers = numbersPerLang[language]
    words = wordsPerLang[language]

    # Handle 24 hour time.
    if hours > 12:
        hours -= 12

    # Handle midnight/midday.
    if hours == 0:
        hours = 12

    # round to nearest 5 minutes
    rounded = (minutes + 2) % 60 // 5 * 5

    # handle the whole hours, also when it is almost the next hour
    if rounded == 0:
        if minutes > 55:
            hours += 1
        return [numbers[hours], words["hour"]]

    # first quarter of the hour
    if rounded <= 15:
        return [numbers[rounded], words["past"], numbers[hours]]

    # next 45 mins we already talk about the next hour
    hours += 1

    if rounded < 30:
        return [numbers[30 - rounded], words["to"] + " " + words["half"], numbers[hours]]

    if rounded == 30:
        return [words["half"], numbers[hours]]

    if rounded < 45:
        return [numbers[-30 + rounded], words["past"] + " " + words["half"], numbers[hours]]

    return [numbers[60 - rounded], words["to"], numbers[hours]]

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    hours = now.hour
    minutes = now.minute
    language = config.get("language") or "nl-NL"

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
            display = "Dutch",
            value = "nl-NL",
        ),
        schema.Option(
            display = "American English",
            value = "en-US",
        ),
        schema.Option(
            display = "British English",
            value = "en-GB",
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
                id = "language",
                name = "Language",
                icon = "language",
                desc = "Dutch, or British or American English",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
        ],
    )

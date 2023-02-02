"""
Applet: Spanish WoD
Summary: Word of the day in Spanish
Description: Displays the spanish word of the day including definition and translation.
Author: logancornelius
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")

DEFAULT_WHO = "world"

SPANISH_DICTIONARY_URL_1 = "https://www.dictionaryapi.com/api/v3/references/spanish/json/"
SPANISH_DICTIONARY_URL_2 = "?key=d5ccb112-d698-45d6-ad07-c17a7b829b8d"
CACHE_KEY = "wotd"
CACHE_LLAVE = "pdd"
CACHE_TTL = 10800  # 3 hours
WOTD_CALENDAR_URL = "https://www.merriam-webster.com/word-of-the-day/calendar"  # Most succinct wotd definition

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def main():
    print("Starting")

    cached_wotd_dict = cache.get(CACHE_KEY)

    if cached_wotd_dict != None:
        print("Cache hit")

        wotd_dict = json.decode(cached_wotd_dict)
        word = wotd_dict["word"]
        definition = wotd_dict["definition"]
        definicion = wotd_dict["definicion"]
    else:
        print("Cache miss")

        wotd_page_response = http.get(WOTD_CALENDAR_URL)

        if wotd_page_response.status_code != 200:
            print("Got code '%s' from page response" % wotd_page_response.status_code)
            return render_error()

        selector = html(wotd_page_response.body())
        word_parsed = selector.find(".wod-l-hover").first().text()
        definition_parsed = selector.find(".definition-block").first().children().first().text()

        if word_parsed == "" or definition_parsed == "":
            print("Failed to find word or definition from page")
            return render_error()

        # Values begin with lower cased letters on the calendar note cards
        word = word_parsed[0].upper() + word_parsed[1:] + ":"
        definition = definition_parsed[0].upper() + definition_parsed[1:] + "."

        word_info = http.get(SPANISH_DICTIONARY_URL_1 + word + SPANISH_DICTIONARY_URL_2)
        if word_info.status_code != 200:
            fail("Websters request failed with status %d", word_info.status_code)
        definicion = word_info.json()[0]["shortdef"][0]

        cache.set(
            CACHE_KEY,
            json.encode({"word": word, "definition": definition, "definicion": definicion}),
            CACHE_TTL,
        )

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word,
                                color = "#00eeff",
                                font = "5x8",
                            ),
                            render.WrappedText(
                                content = definicion,
                                font = "5x8",
                            ),
                        ],
                    ),
                    height = 25,
                    offset_start = 23,
                    scroll_direction = "vertical",
                ),
                render.Box(
                    height = 1,
                    color = "#fa0",
                ),
                render.Text(
                    content = "Palabra del Dia",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )

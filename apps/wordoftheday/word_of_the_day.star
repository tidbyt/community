"""
Applet: Word Of The Day
Summary: Shows the Word Of The Day
Description: Displays the Merriam-Webster Word Of The Day.
Author: greg-n
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_KEY = "wotd"
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

        cache.set(
            CACHE_KEY,
            json.encode({"word": word, "definition": definition}),
            CACHE_TTL,
        )

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Marquee(
                    child = render.Column(
                        children = [
                            render.WrappedText(
                                content = word,
                                color = "#fa0",
                                font = "5x8",
                            ),
                            render.WrappedText(
                                content = definition,
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
                    color = "#00eeff",
                ),
                render.Text(
                    content = "Today's Word",
                    height = 6,
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
        delay = 140,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

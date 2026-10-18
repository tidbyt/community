"""
Applet: Word Of The Day
Summary: Shows the Word Of The Day
Description: Displays the Merriam-Webster Word Of The Day.
Author: greg-n
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_KEY = "wotd"
CACHE_TTL = 3600  # 1 hour

# The calendar and word pages sit behind a bot challenge; the RSS feed is open and carries the word and an abbreviated definition.
WOTD_FEED_URL = "https://www.merriam-webster.com/wotd/feed/rss2"

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong getting today's word!"),
    )

def between(text, start, end):
    start_index = text.find(start)
    if start_index == -1:
        return ""
    start_index += len(start)
    end_index = text.find(end, start_index)
    if end_index == -1:
        return ""
    return text[start_index:end_index]

def parse_feed(body):
    """Returns (word, definition) for the newest item in the feed, or None."""
    item_start = body.find("<item>")
    if item_start == -1:
        return None
    item = body[item_start:]

    word = between(item, "<title><![CDATA[", "]]></title>")
    definition = between(item, "<merriam:shortdef><![CDATA[", "]]></merriam:shortdef>")
    if word == "" or definition == "":
        return None
    return word, definition

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

        wotd_feed_response = http.get(WOTD_FEED_URL)

        if wotd_feed_response.status_code != 200:
            print("Got code '%s' from feed response" % wotd_feed_response.status_code)
            return render_error()

        parsed = parse_feed(wotd_feed_response.body())

        if parsed == None:
            print("Failed to find word or definition in feed")
            return render_error()

        word = parsed[0][0].upper() + parsed[0][1:] + ":"
        definition = parsed[1][0].upper() + parsed[1][1:] + "."

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
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

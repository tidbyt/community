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
load("xpath.star", "xpath")

CACHE_KEY = "wotd"
CACHE_TTL = 10800  # 3 hours
WOTD_RSS_URL = "https://www.merriam-webster.com/wotd/feed/rss2"  # Official feed; merriam:shortdef is the most succinct wotd definition

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

        wotd_feed_response = http.get(WOTD_RSS_URL)

        if wotd_feed_response.status_code != 200:
            print("Got code '%s' from feed response" % wotd_feed_response.status_code)
            return render_error()

        feed_body = wotd_feed_response.body()

        # xpath.loads errors out on non-XML, such as a bot check page served with a 200
        if "<rss" not in feed_body:
            print("Feed response was not RSS")
            return render_error()

        feed = xpath.loads(feed_body)

        # Items run newest first, so the first one is today's word
        word_parsed = feed.query("/rss/channel/item[1]/title")
        definition_parsed = feed.query("/rss/channel/item[1]/merriam:shortdef")

        # query returns None for a missing node
        if not word_parsed or not definition_parsed:
            print("Failed to find word or definition from feed")
            return render_error()

        # Values begin with lower cased letters in the feed
        word = word_parsed[0].upper() + word_parsed[1:] + ":"
        definition = definition_parsed[0].upper() + definition_parsed[1:] + "."

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

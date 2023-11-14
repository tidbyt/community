"""
Applet: RSS Misc Feeds
Summary: Provides misc RSS Feeds
Description: Based upon a curated list, allow user to select display of various RSS feeds not covered in standalone apps.
Author: jvivona
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23318
# jvivoan - 20231114 - added more articles as per request ** NOTE:  Marquee is limited to 320px high - so text will get cut off after about 40 total lines of text regardless of what you select here  **

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

FEEDS_LIST = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/rssmiscfeeds/feeds.json"

DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#cccccc33"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#65d0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#ff8c00"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

def main(config):
    feed_source = json.decode(get_cacheable_data(FEEDS_LIST))
    selected_feed = feed_source[int(config.get("feed", "0"))]
    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_feed(selected_feed["url"], articlecount, selected_feed)

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Text(selected_feed["shortName"], color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(articles, selected_feed["showdesc"]),
                        ),
                ),
            ],
        ),
    )

def render_article(news, showDesc):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText(article[0].strip(), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
        if showDesc:
            news_text.append(render.WrappedText(article[1].strip(), font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 8, color = SPACER_COLOR))

    return (news_text)

def get_schema():
    feeds = json.decode(get_cacheable_data(FEEDS_LIST))

    feed_options = []

    if len(feeds) > 0:
        for feed in feeds:
            feed_options.append(
                schema.Option(
                    display = feed["display"],
                    value = feed["value"],
                ),
            )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feed",
                name = "RSS Feed",
                desc = "Select which feed to display",
                icon = "newspaper",
                default = feed_options[1].value,
                options = feed_options,
            ),
            schema.Dropdown(
                id = "articlecount",
                name = "Article Count",
                desc = "Select number of articles to display",
                icon = "hashtag",
                default = "3",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
                    ),
                ],
            ),
        ],
    )

def get_feed(url, articlecount, selected_feed):
    articles = []
    data = get_cacheable_data(url)

    data_xml = xpath.loads(data)
    for i in range(1, articlecount + 1):
        title_query = "//%s[%s]/title" % (selected_feed["itemElement"], str(i))
        desc_query = "//%s[%s]/%s" % (selected_feed["itemElement"], str(i), selected_feed["descElement"])
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

def get_cacheable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

"""
Applet: CNN News
Summary: CNN News Headlines
Description: Display CNN News headslines for selected section.
Author: jvivona
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23066

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_NEWS = "cnn_latest"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#ff0000aa"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#65d0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#65d0e6"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

RSS_STUB = "http://rss.cnn.com/rss/{}.rss"

SECTION_TITLE = {
    "cnn_topstories": "Top",
    "cnn_latest": "Latest",
    "cnn_world": "World",
    "cnn_allpolitics": "Pol",
    "cnn_tech": "Tech",
    "cnn_showbiz": "Ent",
    "cnn_us": "US",
    "cnn_travel": "Travel",
    "cnn_health": "Health",
}

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_cacheable_data(edition.lower(), articlecount)

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
                    child = render.Text("CNN (" + SECTION_TITLE[edition] + ")", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(articles),
                        ),
                ),
            ],
        ),
    )

def render_article(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText(article[0], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))

        #news_text.append(render.WrappedText(article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 8, color = SPACER_COLOR))

    return (news_text)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "news_edition",
                name = "News Section",
                desc = "Select which section to display",
                icon = "newspaper",
                default = "cnn_latest",
                options = [
                    schema.Option(
                        display = "Top Stories",
                        value = "cnn_topstories",
                    ),
                    schema.Option(
                        display = "Latest News",
                        value = "cnn_latest",
                    ),
                    schema.Option(
                        display = "Entertainment",
                        value = "cnn_showbiz",
                    ),
                    schema.Option(
                        display = "Health",
                        value = "cnn_health",
                    ),
                    schema.Option(
                        display = "Politics",
                        value = "cnn_allpolitics",
                    ),
                    schema.Option(
                        display = "Technology",
                        value = "cnn_tech",
                    ),
                    schema.Option(
                        display = "Travel",
                        value = "cnn_travel",
                    ),
                    schema.Option(
                        display = "US",
                        value = "cnn_us",
                    ),
                    schema.Option(
                        display = "World",
                        value = "cnn_world",
                    ),
                ],
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
                ],
            ),
        ],
    )

def get_cacheable_data(url, articlecount):
    key = url
    data = cache.get(key)
    articles = []

    if data == None:
        res = http.get(RSS_STUB.format(url))
        if res.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
        data = res.body()
        cache.set(key, data, ttl_seconds = CACHE_TTL_SECONDS)

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

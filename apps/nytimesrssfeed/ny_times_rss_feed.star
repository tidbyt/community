"""
Applet: NY Times News
Author: jvivona
Summary: NY Times News Headlines
Description: Gets latest new articles from NT Times and displays up to 3 articles
    for selected section.
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 24260

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

# we grab the current news from the open api and cache it at this api location to prevent getting rate limited website,
# data is refreshed on a regular basis
RSS_STUB = "https://www.nytimes.com/services/xml/rss/nyt/{}.xml"
DEFAULT_NEWS = "HomePage"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#cccccc33"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

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
                    child = render.Text("NYT (%s)" % edition.replace("HomePage", "Home").replace("FashionandStyle", "Fashion").replace("NYRegion", "NY Region").replace("MiddleEast", "Mid East").replace("AsiaPacific", "Asia Pac"), color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(get_cacheable_data(edition, int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))), config.bool("display_summary", True)),
                        ),
                ),
            ],
        ),
    )

def render_article(news, display_summary):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText(article[0], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
        if display_summary:
            news_text.append(render.WrappedText(article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR))
        news_text.append(render.Box(width = 64, height = 3, color = SPACER_COLOR))

    return (news_text)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "news_edition",
                name = "News Section",
                desc = "Select which news section to display",
                icon = "newspaper",
                default = "HomePage",
                options = [
                    schema.Option(
                        display = "Home Page",
                        value = "HomePage",
                    ),
                    schema.Option(
                        display = "News: World",
                        value = "World",
                    ),
                    schema.Option(
                        display = "News: Africa",
                        value = "Africa",
                    ),
                    schema.Option(
                        display = "News: Americas",
                        value = "Americas",
                    ),
                    schema.Option(
                        display = "News: Asia Pacific",
                        value = "AsiaPacific",
                    ),
                    schema.Option(
                        display = "News: Europe",
                        value = "Europe",
                    ),
                    schema.Option(
                        display = "News: Middle East",
                        value = "MiddleEast",
                    ),
                    schema.Option(
                        display = "News: United States",
                        value = "US",
                    ),
                    schema.Option(
                        display = "News: New York Region",
                        value = "NYRegion",
                    ),
                    schema.Option(
                        display = "Business",
                        value = "Business",
                    ),
                    schema.Option(
                        display = "Technology",
                        value = "Technology",
                    ),
                    schema.Option(
                        display = "Sports",
                        value = "Sports",
                    ),
                    schema.Option(
                        display = "Science",
                        value = "Science",
                    ),
                    schema.Option(
                        display = "Health",
                        value = "Health",
                    ),
                    schema.Option(
                        display = "Arts",
                        value = "Arts",
                    ),
                    schema.Option(
                        display = "Fashion and Style",
                        value = "FashionandStyle",
                    ),
                    schema.Option(
                        display = "Travel",
                        value = "Travel",
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
            schema.Toggle(
                id = "display_summary",
                name = "Display Article Summary?",
                desc = "Display Artilce Summary in addition to title?",
                icon = "fileLines",
                default = True,
            ),
        ],
    )

def get_cacheable_data(url, articlecount):
    articles = []
    res = http.get(RSS_STUB.format(url), ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    data = res.body()

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), data_xml.query(desc_query)))

    return articles

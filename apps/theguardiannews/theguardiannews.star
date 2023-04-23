"""
Applet: The Guardian News
Author: jvivona
Summary: Guardian News Headlines
Description: Gets latest new articles from The Guardian and displays up to 3 articles
    for selected edition.
"""

# update - 2023-03-07 - back to the live website feed - now that their IT group has stablized everything.  add in 1st sentence of description

load("cache.star", "cache")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23066

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

# we grab the current news from the open api and cache it at this api location to prevent getting rate limited website,
# data is refreshed on a regular basis
RSS_STUB = "https://www.theguardian.com/{}/rss"
DEFAULT_NEWS = "Intl"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#0000ff"
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

    # api returns max 3 articles
    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    news = get_cacheable_data(edition.lower(), articlecount)

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
                    child = render.Text("Guardian (%s)" % edition, color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(news),
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
        news_text.append(render.WrappedText(article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR))
        news_text.append(render.Box(width = 64, height = 3, color = SPACER_COLOR))

    return (news_text)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "news_edition",
                name = "News Edition",
                desc = "Select which news edition to display",
                icon = "newspaper",
                default = "Intl",
                options = [
                    schema.Option(
                        display = "Australia",
                        value = "AU",
                    ),
                    schema.Option(
                        display = "International",
                        value = "Intl",
                    ),
                    schema.Option(
                        display = "United Kingdom",
                        value = "UK",
                    ),
                    schema.Option(
                        display = "United States",
                        value = "US",
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
    if url == "intl":
        url = "international"  # this was changed during the switch in dec 2022 from guardian - keep our text for display - but convert
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
        desc1stpara = re.match(r"<p>(.*?)<\/p>", str(data_xml.query(desc_query)).replace("None", ""))

        articles.append((data_xml.query(title_query), desc1stpara[0][1]))

    return articles

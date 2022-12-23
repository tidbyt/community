load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("cache.star", "cache")

# cache data for 15 minutes - cycle through with cache on the API side
CACHE_TTL_SECONDS = 900

# we grab the current news from the open api and cache it at this api location to prevent getting rate limited website,
# data is refreshed on a regular basis
NEWS_API = "https://tidbyt.apis.ajcomputers.com/theguardian/api/"
DEFAULT_NEWS = "Intl"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#0000ff"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = -1
ARTICLE_AREA_HEIGHT = 24

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    # api returns max 3 articles
    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    news = json.decode(get_cacheable_data(NEWS_API + edition.lower()))

    return render.Root(
        delay = 70,
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
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(news, articlecount),
                        ),
                ),
            ],
        ),
    )

def render_article(news, articlecount):
    #formats color and font of text
    articlenumber = 0
    news_text = []

    for article in news:
        if articlenumber < articlecount:
            news_text.append(render.Text("%s:" % article["sectionName"], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
            news_text.append(render.WrappedText("%s" % article["webTitle"], font = ARTICLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
            if articlenumber < 2:
                news_text.append(render.Box(width = 64, height = 3, color = SPACER_COLOR))
            articlenumber = articlenumber + 1

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

def get_cacheable_data(url):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, res.body(), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()

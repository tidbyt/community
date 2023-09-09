"""
Applet: CBC RSS Feed
Summary: Display CBC RSS News Feeds
Description: Uses CBC.cs RSS feeds to display headlines.
Author: jvivona
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23248

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_NEWS = "canada"
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

RSS_STUB = "https://www.cbc.ca/webfeed/rss/rss-{}"

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
                    child = render.Text("CBC.ca News", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
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
                default = "canada",
                options = [
                    schema.Option(
                        value = "arts",
                        display = "Arts & Entertainment",
                    ),
                    schema.Option(
                        value = "business",
                        display = "Business",
                    ),
                    schema.Option(
                        value = "canada",
                        display = "Canada",
                    ),
                    schema.Option(
                        value = "health",
                        display = "Health",
                    ),
                    schema.Option(
                        value = "Indigenous",
                        display = "Indigenous",
                    ),
                    schema.Option(
                        value = "offbeat",
                        display = "Offbeat",
                    ),
                    schema.Option(
                        value = "politics",
                        display = "Politics",
                    ),
                    schema.Option(
                        value = "technology",
                        display = "Technology & Science",
                    ),
                    schema.Option(
                        value = "topstories",
                        display = "Top Stories",
                    ),
                    schema.Option(
                        value = "world",
                        display = "World",
                    ),
                    schema.Option(
                        value = "sports",
                        display = "Sports - Top Stories",
                    ),
                    schema.Option(
                        value = "sports-cfl",
                        display = "Sports - CFL",
                    ),
                    schema.Option(
                        value = "sports-curling",
                        display = "Sports - Curling",
                    ),
                    schema.Option(
                        value = "sports-figureskating",
                        display = "Sports - Figure Skating",
                    ),
                    schema.Option(
                        value = "sports-mlb",
                        display = "Sports - MLB",
                    ),
                    schema.Option(
                        value = "sports-nba",
                        display = "Sports - NBA",
                    ),
                    schema.Option(
                        value = "sports-nfl",
                        display = "Sports - NFL",
                    ),
                    schema.Option(
                        value = "sports-nhl",
                        display = "Sports - NHL",
                    ),
                    schema.Option(
                        value = "sports-soccer",
                        display = "Sports - Soccer",
                    ),
                    schema.Option(
                        value = "canada-britishcolumbia",
                        display = "Region - British Columbia",
                    ),
                    schema.Option(
                        value = "canada-calgary",
                        display = "Region - Calgary",
                    ),
                    schema.Option(
                        value = "canada-edmonton",
                        display = "Region - Edmonton",
                    ),
                    schema.Option(
                        value = "canada-hamiltonnews",
                        display = "Region - Hamilton",
                    ),
                    schema.Option(
                        value = "canada-kamloops",
                        display = "Region - Kamloops",
                    ),
                    schema.Option(
                        value = "canada-kitchenerwaterloo",
                        display = "Region - Kitchener-Waterloo",
                    ),
                    schema.Option(
                        value = "canada-london",
                        display = "Region - London",
                    ),
                    schema.Option(
                        value = "canada-manitoba",
                        display = "Region - Manitoba",
                    ),
                    schema.Option(
                        value = "canada-montreal",
                        display = "Region - Montreal",
                    ),
                    schema.Option(
                        value = "canada-newbrunswick",
                        display = "Region - New Brunswick",
                    ),
                    schema.Option(
                        value = "canada-newfoundland",
                        display = "Region - Newfoundland & Labrador",
                    ),
                    schema.Option(
                        value = "canada-north",
                        display = "Region - North",
                    ),
                    schema.Option(
                        value = "canada-novascotia",
                        display = "Region - Nova Scotia",
                    ),
                    schema.Option(
                        value = "canada-ottawa",
                        display = "Region - Ottawa",
                    ),
                    schema.Option(
                        value = "canada-pei",
                        display = "Region - Prince Edward Island",
                    ),
                    schema.Option(
                        value = "canada-saskatchewan",
                        display = "Region - Saskatchewan",
                    ),
                    schema.Option(
                        value = "canada-saskatoon",
                        display = "Region - Saskatoon",
                    ),
                    schema.Option(
                        value = "canada-sudbury",
                        display = "Region - Sudbury",
                    ),
                    schema.Option(
                        value = "canada-thunderbay",
                        display = "Region - Thunder Bay",
                    ),
                    schema.Option(
                        value = "canada-toronto",
                        display = "Region - Toronto",
                    ),
                    schema.Option(
                        value = "canada-windsor",
                        display = "Region - Windsor",
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
    articles = []

    res = http.get(RSS_STUB.format(url), ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    data = res.body()

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

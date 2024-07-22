"""
Applet: RSS Reader
Summary: RSS Feed Reader
Description: Displays entries from an RSS feed URL.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_FEED_URL = "https://discuss.tidbyt.com/latest.rss"
DEFAULT_ARTICLE_COUNT = "3"
DEFAULT_FEED_NAME = "Tidbyt Forums"
DEFAULT_TITLE_COLOR = "#db7e35"
DEFAULT_TITLE_BG_COLOR = "#333333"
DEFAULT_ARTICLE_COLOR = "#65d1e6"
DEFAULT_SHOW_CONTENT = False
DEFAULT_CONTENT_COLOR = "#ff8c00"
DEFAULT_FONT = "tom-thumb"

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get config values
    feed_url = config.get("feed_url", DEFAULT_FEED_URL)
    feed_name = config.get("feed_name", DEFAULT_FEED_NAME)
    title_color = config.get("title_color", DEFAULT_TITLE_COLOR)
    title_bg_color = config.get("title_bg_color", DEFAULT_TITLE_BG_COLOR)
    article_count = int(config.get("article_count", DEFAULT_ARTICLE_COUNT))
    article_color = config.get("article_color", DEFAULT_ARTICLE_COLOR)
    show_content = config.bool("show_content", DEFAULT_SHOW_CONTENT)
    content_color = config.get("content_color", DEFAULT_CONTENT_COLOR)
    font = config.get("font", DEFAULT_FONT)

    # if feed name is empty, show as "RSS Feed"
    if feed_name.strip() == "":
        feed_name = "RSS Feed"

    # if feed url is empty, use default
    if feed_url.strip() == "":
        feed_url = DEFAULT_FEED_URL

    # get feed articles
    articles = get_feed(feed_url, article_count)

    # render view
    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = title_bg_color,
                    child = render.Text(feed_name, color = title_color, font = "tom-thumb"),
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child = render.Column(
                        main_align = "space_between",
                        children = render_articles(articles, show_content, article_color, content_color, font),
                    ),
                ),
            ],
        ),
    )

def render_articles(articles, show_content, article_color, content_color, font):
    """Renders the widgets to display the articles.

    Args:
        articles (list): The list of articles to render.
        show_content (bool): Indicates if the article content should be rendered.
        article_color (str): Color of the article title.
        content_color (str): Color of the article content.

    Returns:
        list: List of widgets.
    """

    #formats color and font of text
    article_text = []

    for article in articles:
        article_text.append(render.WrappedText(article[0].strip(), color = article_color, font = font))
        if show_content:
            article_text.append(render.WrappedText(article[1].strip(), color = content_color, font = font))
        article_text.append(render.Box(width = 64, height = 8, color = "#000000"))

    return article_text

def get_feed(url, article_count):
    """Retrieves an RSS feeds and builds a list with article's titles and content.

    Args:
        url (str): The RSS feed URL.
        article_count (int): The number of articles to retrieve from the feed.

    Returns:
        list: List of tuples with (article title, article content).
    """

    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("Request to %s failed with status code: %d: %s" % (url, res.status_code, res.body()))

    articles = []
    data_xml = xpath.loads(res.body())
    for i in range(1, article_count + 1):
        title_query = "//item[%s]/title" % str(i)
        desc_query = "//item[%s]/description" % str(i)
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed_url",
                name = "RSS Feed URL",
                desc = "The URL of the RSS feed to display.",
                icon = "rss",
                default = DEFAULT_FEED_URL,
            ),
            schema.Text(
                id = "feed_name",
                name = "RSS Feed Name",
                desc = "The name of the RSS feed.",
                icon = "font",
                default = DEFAULT_FEED_NAME,
            ),
            schema.Dropdown(
                id = "article_count",
                name = "Article Count",
                desc = "Number of articles to display",
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
            schema.Dropdown(
                id = "font",
                name = "Text Size",
                desc = " Font size for text.",
                icon = "textHeight",
                default = DEFAULT_FONT,
                options = [
                    schema.Option(
                        display = "Default",
                        value = DEFAULT_FONT,
                    ),
                    schema.Option(
                        display = "Larger",
                        value = "tb-8",
                    ),
                ],
            ),
            schema.Toggle(
                id = "show_content",
                name = "Show Article Content",
                desc = "Show the article's content.",
                icon = "toggleOff",
                default = DEFAULT_SHOW_CONTENT,
            ),
            schema.Color(
                id = "title_color",
                name = "Feed Name Color",
                desc = "The color of the RSS feed name.",
                icon = "brush",
                default = DEFAULT_TITLE_COLOR,
            ),
            schema.Color(
                id = "title_bg_color",
                name = "Feed Name Background",
                desc = "The color of the RSS feed name background.",
                icon = "brush",
                default = DEFAULT_TITLE_BG_COLOR,
            ),
            schema.Color(
                id = "article_color",
                name = "Article Title Color",
                desc = "The color of the article's title.",
                icon = "brush",
                default = DEFAULT_ARTICLE_COLOR,
            ),
            schema.Color(
                id = "content_color",
                name = "Article Content Color",
                desc = "The color of the article's content.",
                icon = "brush",
                default = DEFAULT_CONTENT_COLOR,
            ),
        ],
    )

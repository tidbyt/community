load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("xpath.star", "xpath")
load("random.star", "random")

VERSION = "23205"
CACHE_TTL_SECONDS = 1800
DEFAULT_FEED = "1002"  # Top Stories
DEFAULT_ARTICLE_COUNT = "3"
DEFAULT_DISPLAY_TIME = "3"  # in seconds
DEFAULT_ANIMATION_SPEED = "100"  # milliseconds
DEFAULT_THEME = "dark_blue"
DEFAULT_FONT = "tb-8"
DEFAULT_SHOW_TIME = True
DEFAULT_SHOW_TITLE = True
DEFAULT_SHOW_STORY = True
DEFAULT_AUTO_REFRESH = True
DEFAULT_TEXT_COLOR = "#ffffff"
DEFAULT_HEADER_HEIGHT = "6"
DEFAULT_LOGO_WIDTH = "12"
DEFAULT_RANDOMIZE_FEEDS = False

NPR_FEEDS = {
    "1002": {"name": "Top Stories", "rss_url": "https://feeds.npr.org/1002/rss.xml"},
    "1001": {"name": "News", "rss_url": "https://feeds.npr.org/1001/rss.xml"},
    "1003": {"name": "National", "rss_url": "https://feeds.npr.org/1003/rss.xml"},
    "1004": {"name": "World", "rss_url": "https://feeds.npr.org/1004/rss.xml"},
    "1006": {"name": "Business", "rss_url": "https://feeds.npr.org/1006/rss.xml"},
    "1007": {"name": "Science", "rss_url": "https://feeds.npr.org/1007/rss.xml"},
    "1008": {"name": "Culture", "rss_url": "https://feeds.npr.org/1008/rss.xml"},
    "1012": {"name": "Politics", "rss_url": "https://feeds.npr.org/1012/rss.xml"},
    "1014": {"name": "Politics", "rss_url": "https://feeds.npr.org/1014/rss.xml"},
    "1017": {"name": "Economy", "rss_url": "https://feeds.npr.org/1017/rss.xml"},
    "1019": {"name": "Technology", "rss_url": "https://feeds.npr.org/1019/rss.xml"},
    "1024": {"name": "Research News", "rss_url": "https://feeds.npr.org/1024/rss.xml"},
    "1025": {"name": "Environment", "rss_url": "https://feeds.npr.org/1025/rss.xml"},
    "1026": {"name": "Space", "rss_url": "https://feeds.npr.org/1026/rss.xml"},
    "1032": {"name": "Books", "rss_url": "https://feeds.npr.org/1032/rss.xml"},
    "1039": {"name": "Music", "rss_url": "https://feeds.npr.org/1039/rss.xml"},
    "1045": {"name": "Movies", "rss_url": "https://feeds.npr.org/1045/rss.xml"},
    "1053": {"name": "Food", "rss_url": "https://feeds.npr.org/1053/rss.xml"},
    "1055": {"name": "Sports", "rss_url": "https://feeds.npr.org/1055/rss.xml"},
    "1066": {"name": "Your Health", "rss_url": "https://feeds.npr.org/1066/rss.xml"},
    "1071": {"name": "Law", "rss_url": "https://feeds.npr.org/1071/rss.xml"},
}

NPR_LOGO_URL = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/National_Public_Radio_logo.svg/320px-National_Public_Radio_logo.svg.png"

THEMES = {
    "dark_blue": {
        "background": "#0f1a2a",
        "title": "#3a7ca5",
        "headline": "#65d0e6",
        "description": "#cccccc",
        "time": "#888888",
    },
    "light_blue": {
        "background": "#e6f3ff",
        "title": "#3498db",
        "headline": "#2980b9",
        "description": "#333333",
        "time": "#666666",
    },
    "dark_mode": {
        "background": "#000000",
        "title": "#ffffff",
        "headline": "#cccccc",
        "description": "#999999",
        "time": "#666666",
    },
    "light_mode": {
        "background": "#ffffff",
        "title": "#000000",
        "headline": "#333333",
        "description": "#666666",
        "time": "#999999",
    },
}

def random_feed():
    feed_keys = list(NPR_FEEDS.keys())
    random_index = random.number(0, len(feed_keys) - 1)
    return feed_keys[random_index]

def main(config):
    randomize_feeds = config.bool("randomize_feeds", DEFAULT_RANDOMIZE_FEEDS)

    if randomize_feeds:
        feed = random_feed()
    else:
        feed = config.get("feed", DEFAULT_FEED)

    theme = config.get("theme", DEFAULT_THEME)
    font = config.get("font", DEFAULT_FONT)
    display_time = int(config.get("display_time", DEFAULT_DISPLAY_TIME))
    animation_speed = int(config.get("animation_speed", DEFAULT_ANIMATION_SPEED))
    text_color = config.get("text_color", DEFAULT_TEXT_COLOR)
    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    show_time = config.bool("show_time", DEFAULT_SHOW_TIME)
    show_title = config.bool("show_title", DEFAULT_SHOW_TITLE)
    show_story = config.bool("show_story", DEFAULT_SHOW_STORY)
    auto_refresh = config.bool("auto_refresh", DEFAULT_AUTO_REFRESH)
    header_height = int(config.get("header_height", DEFAULT_HEADER_HEIGHT))
    logo_width = int(config.get("logo_width", DEFAULT_LOGO_WIDTH))

    colors = dict(THEMES[theme])
    colors["text"] = text_color

    articles = get_cacheable_data(feed, articlecount)

    return render.Root(
        delay = animation_speed,
        child = render_feed(feed, articles, colors, font, show_time, show_title, show_story, header_height, logo_width),
        show_full_animation = True,
    )

def render_feed(feed, articles, colors, font, show_time, show_title, show_story, header_height, logo_width):
    return render.Column(
        children = [
            render_header(feed, colors, header_height, logo_width),
            render.Marquee(
                height = 32 - header_height,
                scroll_direction = "vertical",
                offset_start = 32 - header_height,
                child = render.Column(
                    children = render_articles(articles, colors, font, show_time, show_title, show_story),
                ),
            ),
        ],
    )

def render_header(feed, colors, header_height, logo_width):
    return render.Box(
        width = 64,
        height = header_height,
        color = colors["title"],
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render_logo(colors, logo_width, header_height),
                render.Padding(
                    pad = (0, 0, 1, 0),
                    child = render.Text(
                        content = NPR_FEEDS[feed]["name"],
                        font = "tom-thumb",
                        color = colors["background"],
                    ),
                ),
            ],
        ),
    )

def render_logo(colors, width, height):
    cached_logo = cache.get(NPR_LOGO_URL)

    if cached_logo != None:
        return render.Image(src = base64.decode(cached_logo), width = width, height = height)

    res = http.get(NPR_LOGO_URL)
    if res.status_code == 200:
        cache.set(NPR_LOGO_URL, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)
        return render.Image(src = res.body(), width = width, height = height)

    return render.Text("NPR", font = "tom-thumb", color = colors["background"])

def render_articles(articles, colors, font, show_time, show_title, show_story):
    news_elements = []
    for article in articles:
        article_elements = []
        if show_title:
            article_elements.append(
                render.WrappedText(
                    content = article["title"],
                    width = 64,
                    color = colors["text"],
                    font = font,
                ),
            )
        if show_story:
            if article_elements:
                article_elements.append(render.Box(height = 1))
            article_elements.append(
                render.WrappedText(
                    content = article["description"],
                    width = 64,
                    color = colors["text"],
                    font = font,
                ),
            )
        if show_time and article["pubDate"]:
            if article_elements:
                article_elements.append(render.Box(height = 1))
            article_elements.append(
                render.Text(
                    content = format_time(article["pubDate"]),
                    color = colors["time"],
                    font = "tom-thumb",
                ),
            )
        if article_elements:
            news_elements.extend(article_elements)
            news_elements.append(render.Box(height = 2))
    return news_elements

def get_cacheable_data(feed, articlecount):
    rss_url = NPR_FEEDS[feed]["rss_url"]
    if not rss_url:
        return [{"title": "Error", "description": "No RSS URL provided", "pubDate": ""}]

    res = http.get(rss_url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        return [{"title": "Error", "description": "Failed to fetch news from %s (Status: %d)" % (NPR_FEEDS[feed]["name"], res.status_code), "pubDate": ""}]

    data = res.body()
    data_xml = xpath.loads(data)
    articles = []

    for i in range(1, articlecount + 1):
        title_query = "//item[%d]/title" % i
        description_query = "//item[%d]/description" % i
        pubDate_query = "//item[%d]/pubDate" % i

        title = data_xml.query(title_query)
        description = data_xml.query(description_query)
        pubDate = data_xml.query(pubDate_query)

        if title and description:
            description = description.split("<")[0].strip()
            if len(description) > 200:
                description = description[:200] + "..."

            articles.append({
                "title": title,
                "description": description,
                "pubDate": pubDate,
            })

    return articles

def format_time(timestamp):
    if timestamp == "":
        return ""
    parsed_time = time.parse_time(timestamp, "Mon, 02 Jan 2006 15:04:05 -0700")
    if parsed_time == None:
        return ""
    return str(parsed_time.month) + "/" + str(parsed_time.day) + " " + str(parsed_time.hour) + ":" + ("0" + str(parsed_time.minute))[-2:]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "randomize_feeds",
                name = "Randomize Feeds",
                desc = "Randomly select a feed on each refresh",
                icon = "shuffle",
                default = DEFAULT_RANDOMIZE_FEEDS,
            ),
            schema.Dropdown(
                id = "feed",
                name = "NPR Feed",
                desc = "Select an NPR feed",
                icon = "newspaper",
                default = DEFAULT_FEED,
                options = [schema.Option(display = feed["name"], value = key) for key, feed in NPR_FEEDS.items()],
            ),
            schema.Dropdown(
                id = "articlecount",
                name = "Article Count",
                desc = "Select number of articles to display",
                icon = "hashtag",
                default = DEFAULT_ARTICLE_COUNT,
                options = [schema.Option(display = str(i), value = str(i)) for i in range(1, 6)],
            ),
            schema.Dropdown(
                id = "display_time",
                name = "Display Time",
                desc = "Select how long to display each article (in seconds)",
                icon = "clock",
                default = DEFAULT_DISPLAY_TIME,
                options = [
                    schema.Option(display = "1 second", value = "1"),
                    schema.Option(display = "3 seconds", value = "3"),
                    schema.Option(display = "5 seconds", value = "5"),
                ],
            ),
            schema.Dropdown(
                id = "animation_speed",
                name = "Animation Speed",
                desc = "Select the speed of the scrolling animation",
                icon = "gauge",
                default = DEFAULT_ANIMATION_SPEED,
                options = [
                    schema.Option(display = "Slow", value = "150"),
                    schema.Option(display = "Medium", value = "100"),
                    schema.Option(display = "Fast", value = "50"),
                ],
            ),
            schema.Dropdown(
                id = "theme",
                name = "Color Theme",
                desc = "Select the color theme for the app",
                icon = "paintbrush",
                default = DEFAULT_THEME,
                options = [schema.Option(display = key.replace("_", " ").title(), value = key) for key in THEMES.keys()],
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Select custom text color for article content",
                icon = "palette",
                default = DEFAULT_TEXT_COLOR,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Select the font for article text",
                icon = "font",
                default = DEFAULT_FONT,
                options = [
                    schema.Option(display = "CG-pixel-3x5-mono", value = "CG-pixel-3x5-mono"),
		    schema.Option(display = "TB-8", value = "tb-8"),
		    schema.Option(display = "Dina_r400-6", value = "Dina_r400-6"),
                    schema.Option(display = "5x8", value = "5x8"),
		    schema.Option(display = "6x13", value = "6x13"),
		    schema.Option(display = "10x20", value = "10x20"),
		    schema.Option(display = "Tom-Thumb", value = "tom-thumb"),
		    schema.Option(display = "CG-pixel-4x5-Mono", value = "CG-pixel-4x5-mono"),
                ],
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show Time",
                desc = "Display article publication time",
                icon = "clock",
                default = DEFAULT_SHOW_TIME,
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show Title",
                desc = "Display article titles",
                icon = "heading",
                default = DEFAULT_SHOW_TITLE,
            ),
            schema.Toggle(
                id = "show_story",
                name = "Show Story",
                desc = "Display article content",
                icon = "align-left",
                default = DEFAULT_SHOW_STORY,
            ),
            schema.Toggle(
                id = "auto_refresh",
                name = "Auto Refresh",
                desc = "Automatically refresh content",
                icon = "arrows-rotate",
                default = DEFAULT_AUTO_REFRESH,
            ),
            schema.Dropdown(
                id = "header_height",
                name = "Header Height",
                desc = "Select the height of the header",
                icon = "arrows-up-down",
                default = DEFAULT_HEADER_HEIGHT,
                options = [schema.Option(display = str(i), value = str(i)) for i in range(4, 13)],
            ),
            schema.Dropdown(
                id = "logo_width",
                name = "Logo Width",
                desc = "Select the width of the NPR logo",
                icon = "arrows-left-right",
                default = DEFAULT_LOGO_WIDTH,
                options = [schema.Option(display = str(i), value = str(i)) for i in range(12, 25, 2)],
            ),
        ],
    )

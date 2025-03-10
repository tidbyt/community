"""
Applet: Stackernews
Summary: Shows top post Stacker.news
Description: Shows the top post (or random of last 5 posts) on Stacker.news in category bitcoin, nostr, tech, meta, jobs, or all categories.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

DEFAULT_ITEM_CATEGORY = "home"
DEFAULT_ITEM_PERIOD = "day"
DEFAULT_ITEM_SORTING = "sats"
DEFAULT_POST = "latest"

CATEGORIES = {
    "home": {"name": "All", "color": "#fff"},
    "bitcoin": {"name": "BTC", "color": "#f6911d"},
    "nostr": {"name": "Nostr", "color": "#cc21cc"},
    "tech": {"name": "Tech", "color": "#039b26"},
    "meta": {"name": "Meta", "color": "#51a2ff"},
    "jobs": {"name": "Jobs", "color": "#cc143c"},
}

COLOR_ALTER = "#fada5e"

LOGO = base64.decode("""
R0lGODlhCwAHALMAAP/qZfzfYEE5GD41GAAAAPvfcHFiKyolEP/iYaqYQvvbX56KPFpOIhEPBqiTP4JyMiH5BAAAAAAALAAAAAALAAcAAAQkkJBTjLzSlFuaXISzSQonFY8UIEJ1AS1DIAiXEOMQnAImDYQIADs=
""")

def get_feed(category = DEFAULT_ITEM_CATEGORY, ttl_seconds = 60 * 5):
    url = "https://stacker.news/"
    if category != "home":
        url += "/~{}".format(category)
    url += "/rss"

    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Stacker.news request failed with status %d @ %s", response.status_code, url)
    return response.body()

def get_nth_item_from_raw_xml(raw_xml, nth = 1):
    feed_item = xpath.loads(raw_xml).query_node("//rss/channel/item[{}]".format(nth))
    author = feed_item.query("/atom:author/atom:name")

    # Skip ads
    if author == "ad":
        return get_nth_item_from_raw_xml(raw_xml, nth + 1)

    return {
        "title": feed_item.query("/title"),
        "pubdate": feed_item.query("/pubDate"),
        "category": feed_item.query("/category"),
        "author": feed_item.query("/atom:author/atom:name"),
    }

# https://search.r-project.org/CRAN/refmans/anytime/html/iso8601.html
# Support for Thu, 01 Sep 2016 10:11:12.123456 -0500
def parse_RFC2822_datetime(input):
    months = {
        "Jan": 1,
        "Feb": 2,
        "Mar": 3,
        "Apr": 4,
        "May": 5,
        "Jun": 6,
        "Jul": 7,
        "Aug": 8,
        "Sep": 9,
        "Oct": 10,
        "Nov": 11,
        "Dec": 12,
    }
    parts_date = input.split()
    parts_time = parts_date[4].split(":")
    return time.time(
        year = int(parts_date[3]),
        month = months[parts_date[2]],
        day = int(parts_date[1]),
        hour = int(parts_time[0]),
        minute = int(parts_time[1]),
        second = int(parts_time[2]),
        location = parts_date[5],
    )

def main(config):
    post = config.str("post", DEFAULT_POST)

    item_nth = 1 if post == "latest" else int(random.number(1, 5))

    item_category = config.str("category", DEFAULT_ITEM_CATEGORY)

    rss_feed = get_feed(category = item_category)
    item = get_nth_item_from_raw_xml(rss_feed, item_nth)

    category = item_category
    if item_category == "home":
        category = item["category"] or "home"  # rss feed backwards compatible

    category_name = CATEGORIES[category]["name"]
    category_color = CATEGORIES[category]["color"]

    return render.Root(
        delay = 90,
        child = render.Column(
            children = [
                render.Stack(
                    children = [
                        render.Padding(
                            pad = (18, 0, 0, 0),
                            child = render.Box(
                                color = category_color,
                                width = 28,
                                height = 7,
                                child = render.Padding(
                                    pad = (0, 1, 0, 0),
                                    child =
                                        render.Text(
                                            content = category_name.upper(),
                                            color = "#000",
                                        ),
                                ),
                            ),
                        ),
                        render.Padding(
                            pad = (0, 7, 0, 0),
                            child = render.Box(
                                color = category_color,
                                width = 64,
                                height = 1,
                            ),
                        ),
                        render.Image(
                            src = LOGO,
                            width = 11,
                            height = 7,
                        ),
                    ],
                ),
                render.Marquee(
                    height = 24,
                    offset_start = 24,
                    offset_end = 24,
                    scroll_direction = "vertical",
                    child = render.Column(
                        children = [
                            render.WrappedText(item["title"]),
                            render.Padding(
                                pad = (1, 3, 0, 0),
                                child = render.WrappedText(
                                    content = humanize.time(
                                        parse_RFC2822_datetime(item["pubdate"]),
                                    ) + " by " + item["author"],
                                    font = "tom-thumb",
                                    color = COLOR_ALTER,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    category_options = []
    for i in CATEGORIES:
        category_options.append(schema.Option(display = CATEGORIES[i]["name"], value = i))

    post_options = [
        schema.Option(
            display = "The latest post",
            value = "latest",
        ),
        schema.Option(
            display = "Random from latest 5 posts",
            value = "random",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "Category",
                desc = "Select a category.",
                default = CATEGORIES.keys()[0],
                options = category_options,
                icon = "newspaper",
            ),
            schema.Dropdown(
                id = "post",
                name = "What to display",
                desc = "Choose to display latest post, or random post.",
                default = post_options[0].value,
                options = post_options,
                icon = "filter",
            ),
        ],
    )

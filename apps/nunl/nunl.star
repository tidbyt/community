"""
Applet: Nunl
Summary: Latest news from nu.nl
Description: Shows random one of the latest news items from the Dutch website nu.nl.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

DEFAULT_CATEGORY = "Algemeen"

LOGO = base64.decode("""
R0lGODlhCgAKAJEDALUMFv///wIAUQAAACH5BAEAAAMALAAAAAAKAAoAAAIanIWmyDkNX5giVCGvDQBo3X2T9UDMYSoophQAOw==
""")

def get_news_feed(category = DEFAULT_CATEGORY, ttl_seconds = 60 * 5):
    url = "https://www.nu.nl/rss/{}".format(category)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Nu.nl request failed with status %d @ %s", response.status_code, url)
    return response.body()

def get_nth_item_from_raw_xml(raw_xml, nth = 1):
    feed_item = xpath.loads(raw_xml).query_node("//rss/channel/item[{}]".format(nth))
    return {
        "title": feed_item.query("/title"),
        "image": feed_item.query("/enclosure/@url"),
    }

def get_image(image_url):
    response = http.get(url = image_url.replace("sqr256.jpg", "std160"), ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        fail("Image from nu.nl request failed with status %d @ %s", response.status_code, image_url)
    return response.body()

def main(config):
    category = config.str("category", DEFAULT_CATEGORY)

    news_feed = get_news_feed(category)
    nth_item = random.number(1, 10)
    news_item = get_nth_item_from_raw_xml(news_feed, nth_item)

    return render.Root(
        show_full_animation = True,
        max_age = 60 * 5,
        child = render.Stack(
            children = [
                render.Image(
                    src = get_image(news_item["image"]),
                    width = 64,
                    height = 32,
                ),
                render.Column(
                    main_align = "space_between",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (1, 1, 1, 1),
                            child = render.Image(
                                src = LOGO,
                                width = 10,
                                height = 10,
                            ),
                        ),
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#0008",
                            child = render.Marquee(
                                width = 64,
                                offset_start = 64,
                                child = render.Text(
                                    content = news_item["title"],
                                    font = "tb-8",
                                    color = "#fff",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    categories = [
        schema.Option(display = "Algemeen", value = "Algemeen"),
        schema.Option(display = "Economie", value = "Economie"),
        schema.Option(display = "Sport", value = "Sport"),
        schema.Option(display = "Achterklap", value = "Achterklap"),
        schema.Option(display = "Opmerkelijk", value = "Opmerkelijk"),
        schema.Option(display = "Muziek", value = "Muziek"),
        schema.Option(display = "Film", value = "Film"),
        schema.Option(display = "Wetenschap", value = "Wetenschap"),
        schema.Option(display = "Tech", value = "Tech"),
        schema.Option(display = "Gezondheid", value = "Gezondheid"),
        schema.Option(display = "Podcast", value = "Podcast"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "News category",
                desc = "Choose a news category",
                default = categories[0].value,
                options = categories,
                icon = "newspaper",
            ),
        ],
    )

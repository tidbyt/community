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

def parse_news_feed(raw_xml):
    result = []
    for feed_item in xpath.loads(raw_xml).query_all_nodes("//rss/channel/item"):
        result.append({
            "title": feed_item.query("/title"),
            "image": feed_item.query("/enclosure/@url"),
        })
    return result

def get_image(image_url):
    response = http.get(url = image_url.replace("sqr256.jpg", "wd854"), ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        fail("Image from nu.nl request failed with status %d @ %s", response.status_code, image_url)
    return response.body()

def main(config):
    category = config.str("category", DEFAULT_CATEGORY)

    news_item_list = parse_news_feed(get_news_feed(category))
    random_index = random.number(0, len(news_item_list) - 1)

    return render.Root(
        show_full_animation = True,
        max_age = 60 * 5,
        child = render.Stack(
            children = [
                render.Image(
                    src = get_image(news_item_list[random_index]["image"]),
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
                                    content = news_item_list[random_index]["title"],
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

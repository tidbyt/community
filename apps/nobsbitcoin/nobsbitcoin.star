"""
Applet: NoBsBitcoin
Summary: Latest from NoBsBitcoin
Description: Shows the the latest news article from NoBsBitcoin.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

DEFAULT_CATEGORY = "all"

LOGO = base64.decode("""
R0lGODlhKAAdAIABAAEzhAAAACH5BAEAAAEALAAAAAAoAB0AAAKNjI+JAOoPE5sz2kdzvlcrz30VR4VBaS4jxqTRaqCuJc/2iedngze8vuvtfBtfTGg8KodLopHXQh5+udHPKZQmgVLds3nFVqJP8u28QsnSYTIRrJpSW2H5Rh6PzbfRoVmfF4RXp3fnh2eHeBhEdZZS46jSVxiZCAFpgnkJ88KZaWjnOaNB2lhZWkljylEAADs=
""")

def get_news_feed(category = DEFAULT_CATEGORY, ttl_seconds = 60 * 5):
    url = "https://www.nobsbitcoin.com/rss/"
    if category != "all":
        url = "https://www.nobsbitcoin.com/tag/{}/rss/".format(category)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Nobsbitcoin.com request failed with status %d @ %s", response.status_code, url)
    return response.body()

def get_latest_item_from_raw_xml(raw_xml):
    feed_item = xpath.loads(raw_xml).query_node("//rss/channel/item[1]")
    return {
        "description": feed_item.query("/description"),
        "image": feed_item.query("/media:content/@url"),
    }

def get_image(image_url):
    response = http.get(url = image_url, ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        fail("Image from nobsbitcoin.com request failed with status %d @ %s", response.status_code, image_url)
    return response.body()

def main(config):
    category = config.str("category", DEFAULT_CATEGORY)

    news_feed = get_news_feed(category)
    news_item = get_latest_item_from_raw_xml(news_feed)

    return render.Root(
        delay = 120,
        show_full_animation = True,
        max_age = 60 * 5,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (11, 2, 0, 0),
                    child = render.Image(
                        src = LOGO,
                        width = 40,
                        height = 29,
                    ),
                ),
                render.Padding(
                    pad = (1, 1, 1, 1),
                    child = render.Marquee(
                        width = 62,
                        height = 30,
                        offset_start = 30,
                        offset_end = 30,
                        scroll_direction = "vertical",
                        child = render.WrappedText(
                            content = news_item["description"],
                            font = "tom-thumb",
                            color = "#fff",
                            align = "center",
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    categories = [
        schema.Option(display = "All", value = "all"),
        schema.Option(display = "News", value = "news"),
        schema.Option(display = "Releases", value = "releases"),
        schema.Option(display = "Research", value = "research"),
        schema.Option(display = "Guides", value = "guides"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "Category",
                desc = "Choose a category",
                default = categories[0].value,
                options = categories,
                icon = "newspaper",
            ),
        ],
    )

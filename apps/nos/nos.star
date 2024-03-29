"""
Applet: NOS
Summary: Laatste nieuws van NOS
Description: Laat een willekeurig recente nieuwsbericht zien van de website nos.nl.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

DEFAULT_CATEGORY = "nosnieuwsalgemeen"

LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAGRJREFUeNpifCYnwgAEU4A4GogFGCDgAxAvBeIcRqACkGQmEDMxoIJ/QDwdpOA9VOd3yYevuUAyz+VFvwEpTpBJIAX/QYJASUZk7UBFYHF0YzEAE9RBMGMZ0NgfiHIkXm8CBBgAX08js92LI2MAAAAASUVORK5CYII=
""")

def get_news_feed(category = DEFAULT_CATEGORY, ttl_seconds = 60 * 5):
    url = "https://feeds.nos.nl/{}".format(category)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Nos.nl request failed with status %d @ %s", response.status_code, url)
    return response.body()

def get_nth_item_from_raw_xml(raw_xml, nth = 1):
    feed_item = xpath.loads(raw_xml).query_node("//rss/channel/item[{}]".format(nth))
    return {
        "title": feed_item.query("/title"),
        "image": feed_item.query("/enclosure/@url"),
    }

def get_image(image_url):
    # wd320
    response = http.get(url = image_url.replace("1008x567", "128x72a"), ttl_seconds = 60 * 60 * 24 * 7)
    if response.status_code != 200:
        fail("Image from nos.nl request failed with status %d @ %s", response.status_code, image_url)
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
                                width = 8,
                                height = 8,
                            ),
                        ),
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#0008",
                            child = render.Marquee(
                                width = 64,
                                offset_start = 64,
                                offset_end = 64,
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
        schema.Option(display = "Nieuws algemeen", value = "nosnieuwsalgemeen"),
        schema.Option(display = "Nieuws binnenland", value = "nosnieuwsbinnenland"),
        schema.Option(display = "Nieuws buitenland", value = "nosnieuwsbuitenland"),
        schema.Option(display = "Nieuws politiek", value = "nosnieuwspolitiek"),
        schema.Option(display = "Nieuws economie", value = "nosnieuwseconomie"),
        schema.Option(display = "Nieuws opmerkelijk", value = "nosnieuwsopmerkelijk"),
        schema.Option(display = "Nieuws koningshuis", value = "nosnieuwskoningshuis"),
        schema.Option(display = "Nieuws cultuur en media", value = "nosnieuwscultuurenmedia"),
        schema.Option(display = "Nieuws tech", value = "nosnieuwstech"),
        schema.Option(display = "Sport algemeen", value = "nossportalgemeen"),
        schema.Option(display = "Sport voetbal", value = "nosvoetbal"),
        schema.Option(display = "Sport wielrennen", value = "nossportwielrennen"),
        schema.Option(display = "Sport schaatsen", value = "nossportschaatsen"),
        schema.Option(display = "Sport tennis", value = "nossporttennis"),
        schema.Option(display = "Sport formule1", value = "nossportformule1"),
        schema.Option(display = "Nieuwsuur", value = "nieuwsuuralgemeen"),
        schema.Option(display = "NOS op 3", value = "nosop3"),
        schema.Option(display = "NOS Jeugdjournaal", value = "jeugdjournaal"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "category",
                name = "Nieuws categorie",
                desc = "Kies een nieuws categorie",
                default = DEFAULT_CATEGORY,
                options = categories,
                icon = "newspaper",
            ),
        ],
    )

"""
Applet: Gartner News
Summary: Gartner News Display
Description: Display Gartner News Feed.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/base64.star", "base64")  #Used to read encoded image
load("http.star", "http")  #HTTP Client
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

GARTNER_LOGO = base64.decode("""
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""")

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """
    GARTNER_RSS_URL = "https://www.gartner.com/en/newsroom/rss"
    number_of_items = 0
    seconds_xml_valid_for = 3 * 60 * 60  #3 hours

    xml_body = cache.get(GARTNER_RSS_URL)
    if xml_body == None:
        gartner_xml = http.get(GARTNER_RSS_URL)

        if gartner_xml.status_code == 200:
            xml_body = gartner_xml.body()
            number_of_items = xml_body.count("<item>")
            cache.set(GARTNER_RSS_URL, xml_body, ttl_seconds = seconds_xml_valid_for)
        else:
            number_of_items = 0
    else:
        number_of_items = xml_body.count("<item>")

    if number_of_items == 0:
        return []
    else:
        display_text = ["", ""]  # number of display_text rows to display is two
        text_limit = 180
        marquee_row = 0

        for i in range(1, number_of_items + 1):
            current_query = "//item[" + str(i) + "]/title"
            current_title = xpath.loads(xml_body).query(current_query)
            current_query = "//item[" + str(i) + "]/pubDate"
            #current_pub_date = xpath.loads(xml_body).query(current_query)
            #current_date = get_pub_date(current_pub_date, timezone)

            #current_item_time = time.parse_time(current_time_stamp).in_location(timezone) + get_local_offset(config)
            #date_diff = get_local_time(config) - current_date
            if len(display_text[marquee_row]) + len(current_title) > text_limit:
                if marquee_row < len(display_text) - 1:
                    marquee_row = marquee_row + 1
                else:
                    break

            if len(display_text[marquee_row]) == 0:
                display_text[marquee_row] = current_title
            else:
                display_text[marquee_row] = "%s - %s" % (display_text[marquee_row], current_title)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(GARTNER_LOGO),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(height = 3),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 5,
                            offset_end = 64,
                            child = render.Text(display_text[0], color = "#FFf000", font = "5x8"),  #display_text[0], --5x8 allows 180 (900) -- CG-pixel-3x5-mono allows 227 (681) -- CG-pixel-4x5-mono allows 180
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(height = 3),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(display_text[0]) * 5,
                            offset_end = 64,
                            child = render.Text(display_text[1], color = "#FFF000", font = "tb-8"),  #display_text[1]  --6x13 allows 152 -- Dina_r400-6 allows 152 (900)
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )

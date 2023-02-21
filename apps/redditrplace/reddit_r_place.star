"""
Applet: Reddit R-Place
Summary: Bits of r/place
Description: See tidbits of what Redditors created for r/place.
Author: funkfinger
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

VIEWPORT_WIDTH = 64
VIEWPORT_HEIGHT = 32

CACHE_TTL_SECONDS = 3600 * 24 * 30  # 30 days in seconds.

place_image = {
    "2022": {
        "url": "https://i.imgur.com/rzUhL4w.png",
        "width": 2000,
        "height": 2000,
    },
    "2017": {
        # "url": "https://i.imgur.com/2Jq2ina.png",
        "url": "https://i.imgur.com/2yz7Go2.png",  # this is the cleaned version...
        "width": 1000,
        "height": 1000,
    },
}

def main(config):
    """ Main function

    Returns:
        the animation rendered
    """

    max_scroll = int(config.get("max_move", "200"))

    edition = config.get("edition", "2022")
    image = place_image[edition]

    # set max x & y based on tidbyt viewport size...
    max_x = image["width"] - VIEWPORT_WIDTH
    max_y = image["height"] - VIEWPORT_HEIGHT

    # set the final scroll location first - then work backwoard...
    x_end = random.number(0, max_x)
    y_end = random.number(0, max_y)

    # create rectangle points of where we can start the scroll
    possible_move_area_left = x_end - max_scroll if x_end - max_scroll > 0 else 0
    possible_move_area_top = y_end - max_scroll if y_end - max_scroll > 0 else 0
    possible_move_area_right = x_end + max_scroll if x_end + max_scroll < image["width"] else image["width"]
    possible_move_area_bottom = y_end + max_scroll if y_end + max_scroll < image["height"] else image["height"]

    x_start = random.number(possible_move_area_left, possible_move_area_right)
    y_start = random.number(possible_move_area_top, possible_move_area_bottom)

    # debug...
    # print("x1: %d, y1: %d" % (x_start, y_start))
    # print("x2: %d, y2: %d" % (x_end, y_end))

    # create the animation
    ani = animation.Transformation(
        child = get_image(image["url"]),
        duration = 100,
        delay = 10,
        direction = "alternate",
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(-x_start, -y_start)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(-x_end, -y_end)],
            ),
        ],
    )

    return render.Root(
        ani,
    )

def get_schema():
    options = [
        schema.Option(
            display = "2022",
            value = "2022",
        ),
        schema.Option(
            display = "2017",
            value = "2017",
        ),
    ]

    max_move_options = [
        schema.Option(
            display = "0 pixels (static)",
            value = "0",
        ),
        schema.Option(
            display = "50 pixels",
            value = "50",
        ),
        schema.Option(
            display = "100 pixels",
            value = "100",
        ),
        schema.Option(
            display = "150 pixels",
            value = "150",
        ),
        schema.Option(
            display = "200 pixels - default",
            value = "200",
        ),
        schema.Option(
            display = "250 pixels",
            value = "250",
        ),
        schema.Option(
            display = "300 pixels",
            value = "300",
        ),
        schema.Option(
            display = "400 pixels",
            value = "400",
        ),
        schema.Option(
            display = "500 pixels",
            value = "500",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "edition",
                name = "Edition",
                desc = "Edition of r/place to show",
                icon = "palette",
                default = options[0].value,
                options = options,
            ),
            schema.Dropdown(
                id = "max_move",
                name = "Maximum Scroll Movement",
                desc = "Maximum pixels to scroll",
                icon = "hashtag",
                default = max_move_options[4].value,
                options = max_move_options,
            ),
        ],
    )

def get_image(url):
    """ get the final r/place image

    Parameters:
        url - URL of image to display

    Returns:
        the rendered image
    """
    image = cache.get(url)

    if image != None:
        return render.Image(base64.decode(image))

    image = http.get(url).body()

    cache.set(url, base64.encode(image), ttl_seconds = CACHE_TTL_SECONDS)

    return render.Image(image)

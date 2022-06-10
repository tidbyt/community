"""
Applet: Reddit R-Place
Summary: Bits of r/place
Description: See tidbits of what Redditors created for r/place.
Author: funkfinger
"""

load("render.star", "render")
load("http.star", "http")
load("random.star", "random")
load("animation.star", "animation")
load("schema.star", "schema")
load("cache.star", "cache")
load("encoding/base64.star", "base64")

HEIGHT = 32
WIDTH = 64

CACHE_TTL_SECONDS = 3600 * 24 * 30  # 30 days in seconds.

place_image = {
    "2022": {
        "url": "https://i.imgur.com/rzUhL4w.png",
        "width": 2000,
        "multiplier": 3,
    },
    "2017": {
        "url": "https://i.imgur.com/2Jq2ina.png",
        "width": 1000,
        "multiplier": 1,
    },
}

def main(config):
    """ Main function

    Returns:
        the animation rendered
    """

    edition = config.get("edition", "2022")
    image = place_image[edition]

    TILE_WIDTH = WIDTH * image["multiplier"]
    TILE_HEIGHT = HEIGHT * image["multiplier"]

    # grab a coordinate from r/place image...
    x = -1 * (random.number(WIDTH, image["width"] - TILE_WIDTH))
    y = -1 * (random.number(HEIGHT, image["width"] - TILE_HEIGHT))

    # randomized which way it scrolls...
    scroll_x = x - ((random.number(0, 2 * WIDTH)) - WIDTH)
    scroll_y = y - ((random.number(0, 2 * HEIGHT)) - HEIGHT)

    # create the animation
    ani = animation.AnimatedPositioned(
        child = get_image(image["url"]),
        duration = 100,
        curve = "ease_in_out",
        x_start = x,
        y_start = y,
        x_end = scroll_x,
        y_end = scroll_y,
        delay = 10,
        hold = 1,
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

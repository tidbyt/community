"""
Applet: Reddit R-Place
Summary: Bits of r/place 2022
Description: See tidbits of what Redditors created for r/place 2022.
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

TILE_WIDTH = WIDTH * 3
TILE_HEIGHT = HEIGHT * 3

CACHE_TTL_SECONDS = 3600 * 24 * 30  # 30 days in seconds.

def main():
    """ Main function

    Returns:
        the animation rendered
    """

    # grab a coordinate from r/place image...
    x = -1 * (random.number(WIDTH, 2000 - TILE_WIDTH))
    y = -1 * (random.number(HEIGHT, 2000 - TILE_HEIGHT))

    # randomized which way it scrolls...
    scroll_x = x - ((random.number(0, 2 * WIDTH)) - WIDTH)
    scroll_y = y - ((random.number(0, 2 * HEIGHT)) - HEIGHT)

    # create the animation
    ani = animation.AnimatedPositioned(
        child = get_image(),
        duration = 100,
        curve = "ease_in_out",
        x_start = x,
        y_start = y,
        x_end = scroll_x,
        y_end = scroll_y,
        delay = 10,
        hold = 1500,
    )

    return render.Root(
        ani,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# get a the final r/place image
def get_image():
    """ get image function

    Returns:
        the rendered image
    """
    url = "https://i.imgur.com/rzUhL4w.png"
    image = cache.get(url)

    if image != None:
        return render.Image(base64.decode(image))

    image = http.get(url).body()

    cache.set(url, base64.encode(image), ttl_seconds = CACHE_TTL_SECONDS)

    return render.Image(image)

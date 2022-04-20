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

HEIGHT = 32
WIDTH = 64

TILE_WIDTH = WIDTH * 3
TILE_HEIGHT = HEIGHT * 3

def main():
    # grab a coordinate from r/place image...
    x = -1 * (random.number(WIDTH, 2000 - TILE_WIDTH))
    y = -1 * (random.number(HEIGHT, 2000 - TILE_HEIGHT))

    # randomized which way it scrolls...
    scrollX = x - ((random.number(0, 2 * WIDTH)) - WIDTH)
    scrollY = y - ((random.number(0, 2 * HEIGHT)) - HEIGHT)

    # get a the final r/place image
    url = "https://i.imgur.com/rzUhL4w.png"
    image = render.Image(http.get(url).body())

    # create the animation
    ani = animation.AnimatedPositioned(
        child = image,
        duration = 100,
        curve = "ease_in_out",
        x_start = x,
        y_start = y,
        x_end = scrollX,
        y_end = scrollY,
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

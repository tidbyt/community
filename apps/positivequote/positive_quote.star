"""
Applet: Positive Quote
Summary: Display a positive quote
Description: Shows the user a random positive quote.
Author: Brian Bell
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TTL_SECONDS = 30

def main(config):
    affirmation = get_affirmation()
    image = base64.decode(get_affirmation_image())

    return render.Root(
        delay = 150,
        child = render.Stack(
            children = [
                render.Image(src = image, height = 32, width = 64),
                render.Padding(
                    pad = 2,
                    child = render.Box(
                        color = "#00000099",
                        child = render.Padding(
                            pad = (2, 1, 2, 1),
                            child = render.Marquee(
                                align = "center",
                                height = 26,
                                offset_start = 0,
                                offset_end = -11,
                                scroll_direction = "vertical",
                                child = render.WrappedText(content = affirmation, font = "tom-thumb"),
                            ),
                        ),
                    ),
                ),
            ],
        ),
    )

def get_affirmation():
    affirmation = cache.get("affirmation")
    if not affirmation:
        response = http.get("https://www.affirmations.dev")
        if response.status_code != 200:
            fail("Failed to retrieve affirmation: %d - %s" % (response.status_code, response.body()))
        affirmation = response.json()["affirmation"]
        cache.set("affirmation", affirmation, ttl_seconds = TTL_SECONDS)
    return affirmation

def get_affirmation_image():
    image = cache.get("affirmation_image")
    if not image:
        response = http.get("https://random.imagecdn.app/500/250")
        if response.status_code != 200:
            fail("Failed to retrieve image: %d - %s" % (response.status_code, response.body()))
        image = base64.encode(response.body())
        cache.set("affirmation_image", image, ttl_seconds = TTL_SECONDS)
    return image

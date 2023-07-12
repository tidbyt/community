"""
Applet: SF Fog Today
Summary: Satellite fog info for SF
Description: Displays GOES-16 satellite fog image for San Francisco, from fog.today.
Author: Matt Broussard
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")

IMAGE_URL = "https://fog.today/current.jpg"
NATIVE_RES = (1600, 2048)
NATIVE_ORIGIN = (628, 675)
DISPLAY_SCALE = 0.5  # scale by half so that effective area is 128x64 in the original image

def main():
    image_src = load_image()
    if not image_src:
        return render.Root(
            child = render.WrappedText("Error loading fog.today :("),
        )

    return render.Root(
        child = render.Padding(
            child = render.Image(
                src = image_src,
                width = int(NATIVE_RES[0] * DISPLAY_SCALE),
                height = int(NATIVE_RES[1] * DISPLAY_SCALE),
            ),
            pad = (
                -int(NATIVE_ORIGIN[0] * DISPLAY_SCALE),
                -int(NATIVE_ORIGIN[1] * DISPLAY_SCALE),
                0,
                0,
            ),
        ),
    )

def load_image():
    image_src = cache.get(IMAGE_URL)
    if image_src != None:
        return image_src

    resp = http.get(IMAGE_URL)
    if resp.status_code != 200:
        return None

    image_src = resp.body()

    cache.set(IMAGE_URL, image_src, ttl_seconds = 60)
    return image_src

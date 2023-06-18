"""
Applet: Christchurch Bins
Summary: Show next bin collection
Description: Show the next bin collection colour (recycle vs garbage) and date.
Author: Tubo Shi
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CCC_BIN_URL = "https://ccc.govt.nz/services/rubbish-and-recycling/collections/getProperty?ID=%s"
RED_BIN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAdElEQVRIS2NkoDFgpLH5DIPOgv+k+phUH9DcApAHSLGEkVQfgC14K6NCMKSEn9wBqaGfBaR4m4EcH9DcAmIjDxRnZMfBf4b/Drgjj/EAONJGLRgNIngIYMvJo6kIJYEM1yAiWMpDigrCyuAqyKoPSDCfgQEAA7dnF4OsUrkAAAAASUVORK5CYII=")
YELLOW_BIN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAa0lEQVRIS2NkoDFgpLH5DIPOgv+k+phUH9DcApAHSLGEkVQfgC34/45wQDEKgdXQzwJSvM1Ajg9obgGxkQeKM7Lj4D/Dfwfcscd4ABxpoxaMBhE8BLDl5NFUhJJAhmsQEVHM06PCIewMJBUAuGBXFx4pJdgAAAAASUVORK5CYII=")

def future_collections(collections):
    # returns a list of (date, material) tuple from the future
    return [
        (collection["next_planned_date"], collection["material"])
        for collection in collections
        if (collection["out_of_date"] == "False")
    ]

def next_collection(collections):
    # filters out organic bin dates (green bins)
    futures = [collection for collection in future_collections(collections) if collection[1] != "Organic"]
    if futures:
        return futures[0]  # The first item is the next collection
    return None

def render_main(date, material):
    yellow = "#ffff00"
    red = "#ff0000"
    black = "#000"

    if material == "Recycle":
        bg_color = yellow
        text_color = black
        image = YELLOW_BIN
    elif material == "Garbage":
        bg_color = red
        text_color = black
        image = RED_BIN
    else:
        print("Wrong bin descriptor")
        return render_error("Invalid API response")

    return render.Box(
        color = bg_color,
        child = render.Column(children = [
            render.Box(render.Text(content = date, color = text_color), height = 12),
            render.Row([render.Box(render.Image(src = image), width = 28), render.Box(render.Text("%s" % material, color = text_color))]),
        ]),
    )

def render_error(message):
    return render.Root(render.Marquee(
        child = render.Text(message),
        width = 64,
        offset_start = 5,
        offset_end = 32,
    ))

def main(config):
    addr_code = config.str("address_code")

    if not addr_code:
        print("Address Code not provided")
        return render_error("Address not provided ...")

    resp = http.get(CCC_BIN_URL % addr_code, ttl_seconds = 43200)  # cache for 12 hours

    if resp.status_code != 200:
        print("API call failed")
        return render_error("API not available")

    r = resp.json()
    nc = next_collection(r["bins"]["collections"])

    return render.Root(render_main(*nc))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "address_code",
                name = "Adress Code",
                desc = "Used by the CCC website, can be found by inspecting the web API requests",
                icon = "key",
            ),
        ],
    )

"""
Applet: Shopify New Order
Summary: Display recent orders
Description: Display recent orders for your Shopify store.
Author: Shopify
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("encoding/json.star", "json")

# CONFIG
SHOPIFY_COUNTER_API_HOST = "https://www.shopcounter.app"
CACHE_TTL = 30

# COLORS
COLOR_LIME = "#D0F224"
COLOR_ALOE = "#4BFE85"
COLOR_JALAPENO = "#008060"
COLOR_KALE = "#054A49"
COLOR_CURRANT = "#1238BF"
COLOR_AGAVE = "#79DFFF"
COLOR_MANDARIN = "#ED6C31"
COLOR_DRAGONFRUIT = "#ED6BF8"
COLOR_BANANA = "#FCF3B0"
COLOR_WARNING = "#F0D504"
COLOR_BLACK = "#000"
COLOR_WHITE = "#FFF"

# FONTS
FONT_TOM_THUMB = "tom-thumb"
FONT_5_8 = "5x8"

# IMAGES
IMAGE_PICTURE_FRAME_BG = """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAIAAAAt/+nTAAAABGdBTUEAALGPC/xhBQAAADhlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAQKADAAQAAAABAAAAIAAAAAD8qxfHAAAA30lEQVRYCe1YuQ3CQBA8IwIKoAUqIKIm6qEmIiqgBcgJWWtPeHHgcTLyrjQn2fIzt5rnzpJ3eF8/rfLYO/nT415OxfN8Mc47O4y93xTSYITd9FGAjVoafuyNeV9CtTTEBT8JGINo7Xg7+EXa8+v/q9OXUFq6kJgEQIvIACVANhiWVwLQIjJACZANhuWVALSIDFACZINheSUALSIDlADZYFheCUCLyAAlQDYYlp93JWb//HD+5oBJQOwWbU5rmUCk2vdAfLQ8OcPb2EccvDsde10ZKK7hYKYbrAtYMyEn5gsmXC9Ai4wdvQAAAABJRU5ErkJggg==
"""
IMAGE_ALIEN = """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAUCAYAAAA9djs/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAElSURBVHgB7Zc7DsIwDIbdCnbEMTgBI8ycgEMwMSDBzCFYuQMzbHACZi4AYmNBlKaSJbc4NG0SV318UpU0bSP/tuMmAC0ngAoZjo8R9h+XaaW2iKKEU/G6MVOe116p7+QmJFCRs882wot7LkGYHVDiB6N34MMJShymOhVN79VzSSf8OADFqxY8ocQewk1qTN1nndIouNSPu6m2iqUQgiAoMI42LgPYL5ZJS8cbCUaURpkrgtiXygCvHncpwsU+gattVpPqiiUKv58nsL6BE3bzU9KWdQT9u1GbrWqA7k/BGbl69Uu1efMWsdV5BuThIhNsI5+HSNW1qQW1PyNwmxuu6pu86w1fe39Xxtdyh6gzWncGKPqdDp8HuQ4T/kXKdI0XnaPDgi+KKuPyj4rmRgAAAABJRU5ErkJggg==
"""
IMAGE_TRENDS_CONTAINER = """
iVBORw0KGgoAAAANSUhEUgAAAEAAAAALCAYAAADP9otxAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAABySURBVHgB7dWxDYAgFATQUxmEUSxJGMnGhjiRtVtgyQgygV8aoiZAz4eXEIqrLrkA0KVpMk7RKlE5RZvUt3HoCq4T0tvJxRuMeSsoGbRSPp5f8C5AzCE8wFh2AdyFhzBZfEADvuX3cSl35vpt5BbQte4BvoQ8HyaDvqgAAAAASUVORK5CYII=
"""
IMAGE_RECENT_ORDERS = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAARAQMAAADuYb6HAAAABlBMVEUAAABL/oXORWByAAAAAXRSTlMAQObYZgAAADxJREFUeAFjYGdgYjrAxPiAkfsqkwkHkyELs8YxJrYGpr8MTHwMTOxMjG+YmK4wMCkyMP7/wOTAwMj8EgD1PgqfQoKiPgAAAABJRU5ErkJggg==
"""
IMAGE_RECENT_SALES = """
iVBORw0KGgoAAAANSUhEUgAAABIAAAATCAYAAACdkl3yAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAADeSURBVHgBvVS7EcIwDBVOBmAEagagonB6SgZwxx0TZBU6BqCkTwoqBqANIzAAOSPlAidE/AF8eXfvknOkZz1ZDsAIMMgGaRmrL/JBU9JyMbG3S/7G4z6LFtRSgJKH1qSYEiIVBoU2A4yDwy6bcTHlSzidLaxM+3rGIGjp02LWcIsq1hLZkTH9miYxBYmQg6eCEguezu/Oiji8FVEy9qNjuVXehiezRkI1Hm8hd4s58j6mxteCr2vHBHeU33Ag6R7GDeSzwaFGS6FBiy5L6017lZYkNCS4/RwG/vwf/YQHqM7BNxQY+lYAAAAASUVORK5CYII=
"""

APP_ID = "shopify_new_orders"

def api_fetch(counter_id, request_config):
    cache_key = "{}/{}/{}".format(counter_id, APP_ID, base64.encode(json.encode(request_config)))
    cached_value = cache.get(cache_key)
    if cached_value != None:
        print("Hit! Displaying cached data.")
        api_response = json.decode(cached_value)
        return api_response
    else:
        print("Miss! Calling Counter API.")
        url = "{}/tidbyt/api/{}/{}".format(SHOPIFY_COUNTER_API_HOST, counter_id, APP_ID)
        rep = http.post(url, body = json.encode({"config": request_config}), headers = {"Content-Type": "application/json"})
        if rep.status_code != 200:
            print("Counter API request failed with status {}".format(rep.status_code))
            return None
        api_response = rep.json()
        cache.set(cache_key, json.encode(api_response), ttl_seconds = CACHE_TTL)
        return api_response

def error_view():
    return render.Root(
        child = render.Column(
            children = [
                render.Image(src = base64.decode(IMAGE_ALIEN)),
                render.Padding(
                    pad = (0, 2, 2, 0),
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(content = "We hit a snag. Please check your app.", color = COLOR_WARNING),
                    ),
                ),
            ],
        ),
    )

HEX_DIGITS = "0123456789ABCDEF"

def int_to_hex(decimal):
    hex = ""
    i = int(decimal)
    if i == 0:
        return "00"
    for k in range(0, 100):
        if i <= 0:
            break
        hex = HEX_DIGITS[i % 16] + hex
        i = i // 16
    if (len(hex) == 1):
        hex = "0" + hex
    return hex

def hex_to_normalized_rgb(hex):
    r = float(int(str(hex[0:2]), 16)) / 255.0
    g = float(int(str(hex[2:4]), 16)) / 255.0
    b = float(int(str(hex[4:6]), 16)) / 255.0
    return (r, g, b)

def rgb_to_hex(normalized_rgb):
    return ("{}{}{}").format(int_to_hex(normalized_rgb[0] * 255), int_to_hex(normalized_rgb[1] * 255), int_to_hex(normalized_rgb[2] * 255))

def lerp_gradient(c1, c2, steps):
    c1 = hex_to_normalized_rgb(c1)
    c2 = hex_to_normalized_rgb(c2)
    diff = (c2[0] - c1[0], c2[1] - c1[1], c2[2] - c1[2])
    return [rgb_to_hex((c1[0] + (diff[0] * (i / steps)), c1[1] + (diff[1] * (i / steps)), c1[2] + (diff[2] * (i / steps)))) for i in range(steps)]

def render_gradient(width, height, start_color, end_color):
    columns = []
    colors = lerp_gradient(start_color, end_color, width)
    for color in colors:
        columns.append(
            render.Box(
                color = "#{}".format(color),
                width = 1,
            ),
        )

    return render.Box(
        child = render.Row(
            children = columns,
        ),
        height = height,
    )

def main(config):
    counter_id = config.get("counterId")
    request_config = {}
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_config = api_response["config"]
    api_data = api_response["data"]
    orders = api_data["orders"]
    text_color = api_config.get("textColor")
    background_color = api_config.get("backgroundColor")
    logo = api_config.get("logo", IMAGE_RECENT_ORDERS)

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                render_header_row(base64.decode(logo), "new orders\this month", text_color, background_color),
                render.Box(
                    width = 64,
                    height = 1,
                    color = COLOR_WHITE,
                ),
                render.Column(
                    expanded = True,
                    children = [
                        render_marquee(orders),
                    ],
                ),
            ],
        ),
    )

def render_marquee(orders):
    order_views = []
    for order in orders:
        order_views.append(
            render.Padding(
                child = render.Text(
                    content = order["line_item_count"],
                    font = FONT_TOM_THUMB,
                    color = COLOR_WHITE,
                ),
                pad = (7, 0, 4, 0),
            ),
        )
        order_views.append(
            render.Text(
                content = order["current_total_price"],
                font = FONT_TOM_THUMB,
                color = COLOR_ALOE,
            ),
        )
    return render.Stack(
        children = [
            render_gradient(64, 32, "000000", "1238BF"),
            render.Box(
                child = render.Marquee(
                    width = 64,
                    offset_start = 8,
                    child = render.Row(
                        children = order_views,
                        expanded = True,
                    ),
                ),
                height = 10,
            ),
        ],
    )

def render_header_row(image, title, text_color, background_color):
    return render.Box(
        child = render.Row(
            children = [
                render.Box(
                    width = 20,
                    child = render.Image(
                        src = image,
                    ),
                ),
                render.WrappedText(
                    content = "new orders\nthis month",
                    font = FONT_TOM_THUMB,
                    align = "center",
                    color = text_color,
                ),
            ],
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
        ),
        height = 22,
        color = background_color,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "counterId",
                name = "Counter ID",
                desc = "Unique ID of the counter set up in the Counter app for Shopify",
                icon = "shopify",
            ),
            schema.Text(
                id = "textColor",
                name = "Text color",
                desc = "Color of the text used to display the information",
                icon = "palette",
                default = "#D0F224",
            ),
            schema.Text(
                id = "backgroundColor",
                name = "Background color",
                desc = "Color of the background behind the information",
                icon = "palette",
                default = "#054A49",
            ),
            schema.PhotoSelect(
                id = "logo",
                name = "Logo",
                desc = "Logo to use above the data",
                icon = "image",
            ),
        ],
    )

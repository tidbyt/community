"""
Applet: Shopify Orders
Summary: Show Shopify orders count
Description: Show your Shopify store orders count over a specific time period.
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

APP_ID = "shopify_orders"

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

def main(config):
    counter_id = config.get("counterId")
    relative_date = config.get("relativeDate")
    request_config = {
        "relativeDate": relative_date,
        "startDate": config.get("startDate"),
        "endDate": config.get("endDate"),
    }
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_config = api_response["config"]
    api_data = api_response["data"]
    value = api_data["orders"]
    start_date = api_data.get("startDate")
    end_date = api_data.get("endDate")

    if relative_date == "last_day":
        label = "orders last 24 hours"
    elif relative_date == "last_7_days":
        label = "orders last 7 days"
    elif relative_date == "last_30_days":
        label = "orders last 30 days"
    elif relative_date == "last_365_days":
        label = "orders last 365 days"
    else:
        label = "orders, {} - {}".format(start_date, end_date)

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(src = base64.decode(IMAGE_PICTURE_FRAME_BG)),
                render.Box(
                    padding = 5,
                    child = render.Column(
                        cross_align = "center",
                        children = [
                            render.WrappedText(
                                align = "center",
                                content = value,
                                color = COLOR_ALOE,
                                font = FONT_TOM_THUMB,
                            ),
                            render.WrappedText(
                                align = "center",
                                content = label,
                                font = FONT_TOM_THUMB,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

date_range_options = [
    schema.Option(
        display = "Past 24 hours",
        value = "last_day",
    ),
    schema.Option(
        display = "Past 7 days",
        value = "last_7_days",
    ),
    schema.Option(
        display = "Past 30 days",
        value = "last_30_days",
    ),
    schema.Option(
        display = "Past 365 days",
        value = "last_365_days",
    ),
    schema.Option(
        display = "Custom date range",
        value = "custom",
    ),
]

def date_range_custom_options(relativeDate):
    if relativeDate == "custom":
        return [
            schema.DateTime(
                id = "startDate",
                name = "Start Date",
                desc = "Start date for the orders data",
                icon = "gear",
            ),
            schema.DateTime(
                id = "endDate",
                name = "End Date",
                desc = "End date for the orders data",
                icon = "gear",
            ),
        ]
    else:
        return []

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
            schema.Dropdown(
                id = "relativeDate",
                name = "Date",
                desc = "The date range for the orders data",
                icon = "gear",
                default = date_range_options[0].value,
                options = date_range_options,
            ),
            schema.Generated(
                id = "generated",
                source = "relativeDate",
                handler = date_range_custom_options,
            ),
        ],
    )

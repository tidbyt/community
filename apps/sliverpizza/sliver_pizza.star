"""
Applet: Sliver Pizza
Summary: Sliver's Pizza of the Day
Description: See the Pizza of the Day at any Sliver Pizzeria location.
Author: Aaron Janse
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SLIVER_URL = "https://www.sliverpizzeria.com/pizza-of-the-day/{}/"

def main(config):
    location_code = config.str("location", DEFAULT_LOCATION)
    location_url = SLIVER_URL.format(location_code)

    rep = http.get(location_url, ttl_seconds = 3600)
    if rep.status_code != 200:
        fail("Failed to fetch pizza of the day: status %d", rep.status_code)

    body = html(rep.body())

    js_code = body.find("#codemine-calendar-js-js-extra").text()
    js_data = js_code.strip()[20:].split(";")[0]
    data = json.decode(js_data)

    today = time.now().format("2006-01-02")

    out = None
    for event in data["all_events"]:
        if event["start"] == today:
            out = event
            break

    if not out or out["title"] == "CLOSED":
        toppings = ["Closed", ""]
    else:
        toppings_txt = out["pizza_description"][0]
        toppings_txt = toppings_txt.replace("(Shitake, Chanterelle, Portabella, Cremini Mushrooms)", "")
        toppings = [topping.strip() for topping in toppings_txt.split(",")]

    img_url = html(out["post_image"]).find("img").attr("src")
    img_req = http.get(img_url, ttl_seconds = 86400)
    if "sliverlogo" in img_url.lower() or img_req.status_code != 200:
        text_color = "#fff"
        pizza_img = render.Box(
            width = 150,
            height = 150,
            color = "#000",
        )
    else:
        text_color = "#000"
        pizza_img = render.Image(
            src = img_req.body(),
            width = 150,
            height = 150,
        )

    shifted_pizza = render.Padding(
        pad = (-12, -40, 0, 0),
        child = pizza_img,
    )

    location_name = SLIVER_LOCATIONS[location_code]

    return render.Root(
        delay = 200,
        child = render.Stack(
            children = [
                shifted_pizza,
                render.Padding(
                    pad = (1, 2, 0, 0),
                    child = render.WrappedText(
                        content = location_name,
                        align = "right",
                        width = 62,
                        color = text_color,
                        font = "Dina_r400-6",
                    ),
                ),
                render.Padding(
                    pad = (0, 13, 0, 0),
                    child = render_topping(toppings[0], text_color),
                ),
                render.Padding(
                    pad = (0, 22, 0, 0),
                    child = render_topping(toppings[1], text_color),
                ),
            ],
        ),
    )

def render_topping(orig, text_color):
    return render.WrappedText(
        content = shorten_topping(orig),
        align = "right",
        width = 62,
        color = text_color,
    )

def shorten_topping(orig):
    """ Shortens multi-word topping names to a single word. """
    normalized = orig.lower()
    keywords = [
        "tomato",
        "asparagus",
        "mushroom",
        "spinach",
        "onion",
        "potato",
        "pasilla",
        "feta",
        "bell pepper",
    ]
    for keyword in keywords:
        if keyword in normalized:
            return keyword.title()
    return orig.title()

SLIVER_LOCATIONS = {
    "telegraph": "Telegraph",
    "shattuck": "Shattuck",
    "valdez": "Valdez",
    "moraga": "Lafayette",
    "antioch": "Montclair",
    "capitol": "Capitol",
}

DEFAULT_LOCATION = "telegraph"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "location",
                name = "Location",
                desc = "Which Sliver Pizzeria location's pizza to display.",
                icon = "locationDot",
                default = DEFAULT_LOCATION,
                options = [
                    schema.Option(display = name, value = code)
                    for (code, name) in SLIVER_LOCATIONS.items()
                ],
            ),
        ],
    )

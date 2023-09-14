"""
Applet: Braemar Screen
Summary: View dry bulk futures
Description: Allows you to see the top 3 dry bulk futures from Braemarscreen.
Author: Ali-Mahmood
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")

BRAEMAR_PRICES_URL = "https://api.braemarscreen.com/api/graphql"

BRAEMAR_QUERY = json.encode(
    {
        "query": "query HomepageMarkets { brokerSite { ticker { name products { name price prevClose } } }}",
    },
)

COUNTDOWN_HEIGHT = 25
FONT = "tom-thumb"
GREEN = "#008000"
RED = "#FF0000"
BLUE = "#0000FF"

# renders the index/tick name as a heading
def render_heading_name(tick):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            # There's no room to say where each bus is heading, so just give the
            # direction for the stop. That makes it long, so scroll it.
            render.Padding(
                pad = (1, 1, 1, 0),
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 50,
                    height = 6,
                    child = render.Text(
                        content = tick["name"],
                        font = FONT,
                    ),
                ),
            ),
        ],
    )

# renders the line to separate the header name to the values
def render_separator():
    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Box(
            height = 1,
            color = GREEN,
        ),
    )

def render_due(name, price, prevClose):
    change = float(price) - float(prevClose)

    change_color = GREEN

    if change > 0:
        change_color = GREEN
    else:
        change_color = RED

    return render.Row(
        expanded = True,
        children = [
            # Include an index to a) mimic the countdown timers at bus stops
            # and b) if I can work out how to scroll to show more than 3 for
            # particularly busy stops.
            render.WrappedText(
                content = str(name),
                width = 12,
                font = FONT,
            ),
            render.WrappedText(
                content = str(int(math.round(float(price)))),
                width = 20,
                color = BLUE,
                font = FONT,
            ),
            render.Row(
                main_align = "end",
                expanded = True,
                children = [
                    render.Text(
                        content = str(math.round(change)),
                        color = change_color,
                        font = FONT,
                    ),
                ],
            ),
        ],
    )

def render_values_section(products):
    return [
        # Show the values as columns
        render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Box(
                height = COUNTDOWN_HEIGHT,
                child = render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render_due(a["name"], a["price"], a["prevClose"])
                        for a in products
                    ],
                ),
            ),
        ),
    ]

# renders the product details in the section below the index/tick name
def render_products(tick):
    products = tick["products"]
    sections = []
    for i in range(0, len(products), 10):
        sections.extend(render_values_section(products[i:i + 10]))
    frames = []
    for s in sections:
        frames.extend([s] * 100)

    render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Marquee(
            height = 32,
            offset_start = 16,
            offset_end = 16,
            scroll_direction = "vertical",
            child = render.Column(
                children = frames,
            ),
        ),
    )

# renders a box for an index/tick thats passed in
def render_each_index(tick):
    return render.Box(
        render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                # Top part is the name of the index
                render_heading_name(tick),
                render_separator(),
                # Bottom part shows prices for each product
                render_products(tick),
            ],
        ),
    )

def main():
    rep = http.post(
        BRAEMAR_PRICES_URL,
        body = BRAEMAR_QUERY,
        ttl_seconds = 60,
        headers = {
            "content-type": "application/json",
        },
    )  # cache for 1 minute
    if rep.status_code != 200:
        fail("Braemar request failed with status %d", rep.status_code)
    tickers = rep.json()["data"]["brokerSite"]["ticker"]
    print(tickers)

    # for development purposes: check if result was served from cache or not
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Braemar API.")

    indexes = []
    for tick in tickers[0:3]:
        indexes.append(render_each_index(tick))

    return render.Root(
        max_age = 120,
        delay = 6000,
        child = render.Animation(
            children = indexes,
        ),
    )

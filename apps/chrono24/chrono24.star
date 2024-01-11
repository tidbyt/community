"""
Applet: Chrono24
Summary: Watch market performance
Description: Gives ability to show watch market performance over multiple durations as well as seeing brand performance.
Author: Chase Roossin
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_WHO = "world"
BASE_URL = "https://www.chrono24.com/api/priceindex/performance-chart.json?type=Market&period="
CONFIG_TIMEFRAME = "config-timeframe"
CONFIG_VIEW_TYPE = "config-view-type"
CONFIG_VIEW_TYPE_GRAPH = "graph"
CONFIG_VIEW_TYPE_INDEXES = "indexes"
CACHE_TTL = 3600  # 6 hour

def main(config):
    timeframe = config.str(CONFIG_TIMEFRAME, "_1month")
    viewtype = config.str(CONFIG_VIEW_TYPE, CONFIG_VIEW_TYPE_GRAPH)

    # Check for cached data
    cached_data = cache.get(timeframe)

    if cached_data != None:
        print("Hit! Displaying cached data.")
        data = json.decode(cached_data)
    else:
        print("Miss cache!")
        rep = http.get(BASE_URL + timeframe)

        # Ensure valid response
        if rep.status_code != 200:
            return render.Root(
                child = two_line("Ntwk Error", "Status: " + str(rep.status_code)),
            )

        data = rep.json()

        # Update cache
        cache.set(timeframe, json.encode(data), ttl_seconds = CACHE_TTL)

    if viewtype == CONFIG_VIEW_TYPE_GRAPH:
        return market_view_render(timeframe, data)
    else:
        return watch_indexes_render(data)

def market_view_render(timeframe, data):
    # Construct graph points
    price_points = []
    price_index_data = data["priceIndexData"]
    lowest_price = 0
    highest_price = 0
    first_price = 0
    last_price = 0

    for index, price_data in enumerate(price_index_data):
        value = price_data["y"]["mean"]["value"]

        # on first, set highest and lowest
        if index == 0:
            lowest_price = value
            highest_price = value
            first_price = value

        # Update highest/lowest price
        if value < lowest_price:
            lowest_price = value
        if value > highest_price:
            highest_price = value

        if index == len(price_index_data) - 1:
            last_price = value

        price_points.append((index, value))

    primary_color = "#0f0" if last_price > first_price else "f00"

    return render.Root(
        child = render.Column(
            children = [
                # First row, timeframe and dollar change
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Text(content = get_pretty_timeframe_title(timeframe)),
                        render.Text(content = str(make_two_decimal(last_price - first_price)), color = primary_color),
                    ],
                ),

                # Second row, current value and percent change
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Text(content = str(make_two_decimal(last_price))),
                        render.Text(content = str(make_two_decimal(((last_price - first_price) / first_price) * 100)) + "%", color = primary_color),
                    ],
                ),

                # Graph
                render.Plot(
                    data = price_points,
                    width = 66,
                    height = 15,
                    color = primary_color,
                    y_lim = (lowest_price, highest_price),
                    fill = True,
                ),
            ],
        ),
    )

def watch_indexes_render(data):
    # Take first 10 watches, eventually make configurable
    watches = data["indexComponents"][:10]

    # Generate the rows
    watch_rows = []
    for watch in watches:
        watch_rows.append(generate_watch_row(watch))

    return render.Root(
        child = render.Sequence(
            children = watch_rows,
        ),
    )

def generate_watch_row(watch):
    # TODO: ADD Images

    color = "f00" if watch["change"] < 0 else "0f0"

    return animation.Transformation(
        child = render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = watch["brandName"], color = "#636363"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(content = watch["productName"]),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = "Ref: " + watch["referenceNumber"], color = "#636363"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text(content = "$" + watch["price"], color = color),
                            render.Text(content = str(make_one_decimal(watch["change"] * 100)) + "%", color = color),
                        ],
                    ),
                ],
            ),
        ),
        duration = 50,
        delay = 0,
        keyframes = [],
    )

def two_line(line1, line2):
    return render.Box(
        width = 64,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(content = line1, font = "CG-pixel-4x5-mono"),
                render.Text(content = line2, font = "CG-pixel-4x5-mono", height = 10),
            ],
        ),
    )

def make_two_decimal(value):
    return int(value * 100) / 100.0

def make_one_decimal(value):
    return int(value * 10) / 10.0

def get_pretty_timeframe_title(value):
    titles = {
        "_1month": "1 mo",
        "_3months": "3 mo",
        "_6months": "6 mo",
        "_1year": "1 yr",
        "_3years": "3 yr",
        "max": "Max",
    }
    return titles.get(value, "Unknown")

def get_schema():
    timeframes = [
        schema.Option(display = "1 month", value = "_1month"),
        schema.Option(display = "3 months", value = "_3months"),
        schema.Option(display = "6 months", value = "_6months"),
        schema.Option(display = "1 year", value = "_1year"),
        schema.Option(display = "3 years", value = "_3years"),
        schema.Option(display = "Max", value = "max"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = CONFIG_VIEW_TYPE,
                name = "View type",
                desc = "Overall market performance or watch index",
                icon = "eye",
                default = "graph",
                options = [
                    schema.Option(display = "Market performance graph", value = CONFIG_VIEW_TYPE_GRAPH),
                    schema.Option(display = "Watch indexes", value = CONFIG_VIEW_TYPE_INDEXES),
                ],
            ),
            schema.Dropdown(
                id = CONFIG_TIMEFRAME,
                name = "Timeframe",
                desc = "The timeframe of the market performance",
                icon = "clock",
                default = "_1month",
                options = timeframes,
            ),
        ],
    )

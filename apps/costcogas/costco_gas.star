"""
Applet: Costco Gas
Summary: Costco Gas Display
Description: Displays gas prices from a selected Costco warehouse in the US.
Author: Dan Adam
"""
# Revised: 2022-09-15
# Thanks: Portions of the code were adapted from the sf_next_muni applet written by Martin Strauss
# Attribution: Gas Icon from "https://www.iconfinder.com/icons/111078/gas_icon", Costco Icon from "https://play-lh.googleusercontent.com/gqOziTbVWioRJtHh7OvfOq07NCTcAHKWBYPQKJOZqNcczpOz5hdrnQNY7i2OatJxmuY=w240-h480-rw"

load("cache.star", "cache")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("re.star", "re")
load("time.star", "time")
load("humanize.star", "humanize")

DEFAULT_LOCATION = """
{
    "lat": "37.7844",
    "lng": "-122.4080",
    "description": "San Francisco, CA, USA",
	"locality": "San Francisco",
	"timezone": "America/Los_Angeles"
}
"""

DEFAULT_CONFIG = {
    "warehouse": "1216",
    "timezone": "America/Los_Angeles",
    "price_colour": "white",
    "icon_display": "costco-icon",
    "time_format": "24-hours",
    "show_hours": False,
}

DUMMY_WAREHOUSE = [
    {
        "locationName": "Dummy Warehouse",
        "identifier": "0",
        "gasPrices": {
            "regular": "0.009",
            "premium": "0.009",
            "diesel": "0.009",
        },
        "gasStationHours": [
            {
                "title": "Mon-Fri. ",
                "code": "open",
                "time": "10:00am - 8:00pm",
            },
            {
                "title": "Sat. ",
                "code": "open",
                "time": "6:00am - 7:00pm",
            },
            {
                "title": "Sun. ",
                "code": "open",
                "time": "9:00am - 6:00pm",
            },
        ],
    },
]

ICONS = {
    "gas-icon": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAbZJREFUOE/t0z1oU1EUwPH/uSSFqlkcClG7CIo4SLGjU7eiZCzNF64OikheG3B3aZP3KnUr2CI0L+JaBz/wC3QRUYpT3RzEoLiYwaZJ7ilp2mRI0vcgHb3DXe65v3vuufcIRzyk4+XXz9CQBUTGDjnjHyIexdRb8g9jNEfvY+wqheyHgz1dMFd+gOitEAlv4aYvcKd0FsMWSA00gZd509rbBef8RyjXURxGdK0HrnEOI+9R+wcvG99bz5VmAB/YQZliKfOxD2gm8JKbfTN1ShVUtQPOr1+hKS8QOQb2CW52djjQ8b8AE/uHP8dNTw8Hzj++jOokqivAANCYSQrJz/2v7P9GOYnoD1SesR3JcZwT2MbPwSD6EuFVD6iMg9xEsaDbe3WzukQkuhgABnwctRUitfM0R/8i+gmJJoYHvcwpnLIFNjGR6f/g/iMctF5QM7cepV3DGsh3jL2KlW8gT3FTid6PHQrMxnH818AUUAeiCHmK6UIXdPwykAzyUH4Ri5+mWokjugx6EWSDavUuKzfqbdDxi605EOsGfMVNX+oX3wbnytew9jYiJhwq73BT9waD4ZRQUbv4FQMk4c+PYQAAAABJRU5ErkJggg=="),
    "costco-icon": base64.decode("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LcuY0xykwQQm0Lz+jWDbfkOWML8BSINTmVCz+jWCJYc+voqFLS1DKixkci0f2hUm7fC/z69kUAORDlcx4VY/2681itT6xCEfM5yaCqRDVQ1T4bNHz+3aBKGU7XHqra8sZjSDkBYXMl3q5o4bPmhA707bNsGWmrTevdtRP79m6ItTFrJomZZIjVmU0IYiPXpRQmuHFBlOCWk40qR8ISWcTkiV/SmhjELKXEUJowfS5mlKcGORPm9SAuuN9CmfSwloOtJo2xWUYPoglVospQQxBylV9TklgPOQVpXzKAUtLUNqlU2mFHIl0uwhSn41FUi1syl53YKU67KOklumJdKufAIlp/tQAgZQcmmHUtBmMSWrYSgRv6Zk0wmlosUsSgMjUUJOodTXAyXlScoW3kCJaTaFspneKDm7/5fytbdRig5cTtmoD0pTt2WU9T5ByfqfpRSehxK2ywyWuqUobZV/Zmm7EiXvsjqWrpoKCHadxlJ1C+QrF61jKcq0gGxS/VeWnvsgm9lrCkvMdyBbOuwTlpBhkIa6TmGp2AeSVbsXWQpGQnKqvHI50+5gSF57vsA0ewNS2HGTmVY/ggRz1Dim0NuQELo+sYbpciokpIp+k5kan0AiaXHum0yDcyHRNer9TA2TrPYVSNG2OnHYcibNzPtObAoxaf+rXl9L360ed/tPdoJY1P6cJ2bTL5mP/3pb370bQVyqPOSKP3+YYUxWzRh55/lHdmgEiV/ZHj/9zVNvLaU9a+ZOGvXgNf0O79AE4rsm7bqfMOCmR16aurCO4az5/P23XnnukdsGnnPyDzrvXAURERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGD/h9wuy2tt71boAAAAABJRU5ErkJggg=="),
}

PRICE_COLOURS = {
    "white": {
        "petrolColour": "#FFFFFF",
        "dieselColour": "#FFFFFF",
    },
    "red-green": {
        "petrolColour": "#ff0000",
        "dieselColour": "#00FF00",
    },
    "green-red": {
        "petrolColour": "#00FF00",
        "dieselColour": "#ff0000",
    },
}

DAY_MAP = {
    "Mon": "Mon-Fri. ",
    "Tue": "Mon-Fri. ",
    "Wed": "Mon-Fri. ",
    "Thu": "Mon-Fri. ",
    "Fri": "Mon-Fri. ",
    "Sat": "Sat. ",
    "Sun": "Sun. ",
}

TIME_FORMAT_MAP = {
    "24-hours": "15:04 ",
    "12-hours": "3:04pm",
}

API_HEADERS = {
    "Accept": "*/*",
    "User-Agent": "Tidbyt/1.0",
}

API_WAREHOUSE_SEARCH = "https://www.costco.com/AjaxWarehouseBrowseLookupView?numOfWarehouses=20&countryCode=US&hasGas=true&populateWarehouseDetails=false{}"
API_WAREHOUSE_DETAILS = "https://www.costco.com/AjaxWarehouseBrowseLookupView?numOfWarehouses=1&countryCode=US&hasGas=true&populateWarehouseDetails=true&warehouseNumber={}"

def get_schema():
    icons = [
        schema.Option(
            display = "Costco Logo",
            value = "costco-icon",
        ),
        schema.Option(
            display = "Gas Pump",
            value = "gas-icon",
        ),
    ]

    price_colours = [
        schema.Option(
            display = "White",
            value = "white",
        ),
        schema.Option(
            display = "Red Gas, Green Diesel",
            value = "red-green",
        ),
        schema.Option(
            display = "Green Gas, Red Diesel",
            value = "green-red",
        ),
    ]

    time_formats = [
        schema.Option(
            display = "24 Hour Clock",
            value = "24-hours",
        ),
        schema.Option(
            display = "12 Hour Clock",
            value = "12-hours",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "warehouse_by_loc",
                name = "Warehouse",
                desc = "A list of warehouses by location",
                icon = "locationDot",
                handler = get_warehouses,
            ),
            schema.Toggle(
                id = "show_hours",
                name = "Show Hours",
                desc = "Show open hours for the current day. If enabled, icon won't show.",
                icon = "businessTime",
                default = DEFAULT_CONFIG["show_hours"],
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "24 or 12 hour clock for hours display",
                icon = "clock",
                default = DEFAULT_CONFIG["time_format"],
                options = time_formats,
            ),
            schema.Dropdown(
                id = "icon_display",
                name = "Icon",
                desc = "Icon to display",
                icon = "icons",
                default = DEFAULT_CONFIG["icon_display"],
                options = icons,
            ),
            schema.Dropdown(
                id = "price_colour",
                name = "Price Colour",
                desc = "Colour scheme for price display",
                icon = "palette",
                default = DEFAULT_CONFIG["price_colour"],
                options = price_colours,
            ),
        ],
    )

def get_cached_data(url, ttl):
    cached_data = cache.get(url)

    if cached_data != None:
        response_data = json.decode(cached_data)
    else:
        http_data = http.get(url, headers = API_HEADERS)
        if http_data.status_code != 200:
            fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))
        response_data = [x for x in http_data.json() if type(x) == "dict"]
        cache.set(url, json.encode(response_data), ttl_seconds = ttl)

    return response_data

def get_warehouses(location):
    loc = json.decode(location)
    warehouses = get_cached_data(API_WAREHOUSE_SEARCH.format("&latitude=" + humanize.float("#.#", float(loc["lat"])) + "&longitude=" + humanize.float("#.#", float(loc["lng"]))), 86400)

    return [
        schema.Option(
            display = warehouse["locationName"] + " #" + warehouse["identifier"],
            value = warehouse["identifier"],
        )
        for warehouse in warehouses
    ]

def get_gas_prices(config):
    warehouse = DEFAULT_CONFIG["warehouse"]
    warehouse_cfg = config.get("warehouse_by_loc")
    if warehouse_cfg:
        warehouse = json.decode(warehouse_cfg)["value"]

    warehouse_data = get_cached_data(API_WAREHOUSE_DETAILS.format(warehouse), 3600)

    if type(warehouse_data) != "list" or len(warehouse_data) == 0:
        warehouse_data = DUMMY_WAREHOUSE

    gas_prices = {}

    gas_prices["warehouse_name"] = warehouse_data[0].get("locationName", "ERROR") + " #" + warehouse_data[0].get("identifier", "ERROR")
    gas_prices["regular"] = warehouse_data[0]["gasPrices"].get("regular", "")
    gas_prices["premium"] = warehouse_data[0]["gasPrices"].get("premium", "")
    gas_prices["diesel"] = warehouse_data[0]["gasPrices"].get("diesel", "")
    gas_prices["gasStationHours"] = warehouse_data[0].get("gasStationHours", [])

    return gas_prices

def get_gas_hours(raw_gas_hours, config):
    gas_render = []

    time_long = "2006-01-02 3:04pm"
    date_short = "2006-01-02"

    gas_hours = get_gas_hours_dictionary(raw_gas_hours)

    # We will use the user's device time zone with $tz variable as the user's device will likely correspond to the warehouse timezone
    timezone = config.get("$tz", DEFAULT_CONFIG["timezone"])

    current_time = time.now().in_location(timezone)
    current_day = current_time.format("Mon")
    current_date = current_time.format(date_short)

    hours_known = type(gas_hours.get(DAY_MAP[current_day], "")) == "dict"

    if hours_known:
        is_open = current_time >= time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["open"], time_long, timezone) and current_time < time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["closed"], time_long, timezone)
        if is_open:
            gas_render.append(
                render.Padding(
                    child = render.Text("OPEN", font = "tom-thumb", color = "#04AF45"),
                    pad = (18, 0, 0, 0),
                ),
            )
        else:
            gas_render.append(
                render.Padding(
                    child = render.Text("CLOSED", font = "tom-thumb", color = "#C90000"),
                    pad = (10, 0, 0, 0),
                ),
            )
        gas_render.append(
            render.Text(time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["open"], time_long, timezone).format(TIME_FORMAT_MAP[config.get("time_format", DEFAULT_CONFIG["time_format"])])[:-1], font = "tom-thumb"),
        )
        gas_render.append(
            render.Text(time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["closed"], time_long, timezone).format(TIME_FORMAT_MAP[config.get("time_format", DEFAULT_CONFIG["time_format"])])[:-1], font = "tom-thumb"),
        )
    else:
        gas_render.append(
            render.Padding(
                child = render.Text("Hours", font = "tom-thumb", color = "#C90000"),
                pad = (0, 0, 0, 0),
            ),
        )
        gas_render.append(
            render.Padding(
                child = render.Text("Unknown", font = "tom-thumb", color = "#C90000"),
                pad = (6, 0, 0, 0),
            ),
        )

    return gas_render

def get_gas_hours_dictionary(raw_gas_hours):
    regex_hours = r"(1?[0-9]:[0-5][0-9][ap]m) - (1?[0-9]:[0-5][0-9][ap]m)"
    regex_time = r"1?[0-9]:[0-5][0-9][ap]m"
    gas_hours = {}
    for hours in raw_gas_hours:
        if hours.get("title", "") != "" and hours.get("code", "") == "open" and re.search(regex_hours, hours.get("time", "")):
            gas_hours[hours["title"]] = {"open": re.findall(regex_time, hours["time"])[0], "closed": re.findall(regex_time, hours["time"])[1]}
    return gas_hours

def get_hours_or_icon(raw_gas_hours, config):
    render_children = []
    if config.bool("show_hours", DEFAULT_CONFIG["show_hours"]):
        render_children = get_gas_hours(raw_gas_hours, config)
    else:
        render_children.append(
            render.Padding(
                child = render.Image(ICONS[config.get("icon_display", DEFAULT_CONFIG["icon_display"])], width = 20, height = 20),
                pad = (5, 0, 0, 0),
            ),
        )

    return render_children

def format_gas_price(gas_price):
    regex = r"^[\d]+\.\d\d9$"
    price_check = re.search(regex, gas_price)

    if price_check != None:
        return gas_price[:-1]

    return gas_price

def get_display(gas_prices, config):
    labels = []
    prices = []

    if gas_prices.get("regular", "") != "":
        labels.append(
            render.Text("R: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["regular"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["petrolColour"]),
        )

    if gas_prices.get("premium", "") != "":
        labels.append(
            render.Text("P: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["premium"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["petrolColour"]),
        )

    if gas_prices.get("diesel", "") != "":
        labels.append(
            render.Text("D: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["diesel"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["dieselColour"]),
        )

    return labels, prices

def main(config):
    gas_prices = get_gas_prices(config)
    labels, prices = get_display(gas_prices, config)

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(gas_prices["warehouse_name"], color = "#0073A6"),
                ),
                render.Row(
                    children = [
                        render.Column(
                            children = labels,
                            cross_align = "start",
                        ),
                        render.Column(
                            children = prices,
                            cross_align = "end",
                        ),
                        render.Column(
                            children = get_hours_or_icon(gas_prices["gasStationHours"], config),
                            expanded = True,
                            main_align = "center",
                            cross_align = "end",
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                ),
            ],
        ),
    )

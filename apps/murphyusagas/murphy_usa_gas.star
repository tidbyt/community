"""
Applet: Murphy USA Gas
Summary: Murphy USA Gas Prices
Description: Display prices from selected Murphy USA station.
Author: jvivona
"""

# Thanks to Dan Adam for the Costco Gas app which this is based upon
# Attribution: Gas Icon from "https://www.iconfinder.com/icons/111078/gas_icon"

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": "33.95195",
    "lng": "-84.73133",
    "description": "San Francisco, CA, USA",
	"locality": "San Francisco",
	"timezone": "America/New_York"
}
"""

DEFAULT_CONFIG = {
    "station": "2242",
    "timezone": "America/New_York",
    "price_color": "white",
    "icon_display": "costco-icon",
    "time_format": "24-hours",
    "show_hours": False,
}

ICONS = {
    "gas-icon": base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAbZJREFUOE/t0z1oU1EUwPH/uSSFqlkcClG7CIo4SLGjU7eiZCzNF64OikheG3B3aZP3KnUr2CI0L+JaBz/wC3QRUYpT3RzEoLiYwaZJ7ilp2mRI0vcgHb3DXe65v3vuufcIRzyk4+XXz9CQBUTGDjnjHyIexdRb8g9jNEfvY+wqheyHgz1dMFd+gOitEAlv4aYvcKd0FsMWSA00gZd509rbBef8RyjXURxGdK0HrnEOI+9R+wcvG99bz5VmAB/YQZliKfOxD2gm8JKbfTN1ShVUtQPOr1+hKS8QOQb2CW52djjQ8b8AE/uHP8dNTw8Hzj++jOokqivAANCYSQrJz/2v7P9GOYnoD1SesR3JcZwT2MbPwSD6EuFVD6iMg9xEsaDbe3WzukQkuhgABnwctRUitfM0R/8i+gmJJoYHvcwpnLIFNjGR6f/g/iMctF5QM7cepV3DGsh3jL2KlW8gT3FTid6PHQrMxnH818AUUAeiCHmK6UIXdPwykAzyUH4Ri5+mWokjugx6EWSDavUuKzfqbdDxi605EOsGfMVNX+oX3wbnytew9jYiJhwq73BT9waD4ZRQUbv4FQMk4c+PYQAAAABJRU5ErkJggg==")
}

PRICE_COLORS = {
    "white": {
        "gasColor": "#FFFFFF",
        "dieselColor": "#FFFFFF",
    },
    "red-green": {
        "gasColor": "#ff0000",
        "dieselColor": "#00FF00",
    },
    "green-red": {
        "gasColor": "#00FF00",
        "dieselColor": "#ff0000",
    },
}

API_STATION_SEARCH = "https://service.murphydriverewards.com/api/store"
API_STATION_DETAILS = "https://service.murphydriverewards.com/api/store/detail/{}"
API_STATION_SEARCH_PAGESIZE = 10
API_STATION_SEARCH_RANGE = 20
API_STATION_CACHE_KEY = "stations&lat={}&lng={}"
API_STATION_LIST_TTL = 86400
API_STATION_DETAILS_TTL = 3600

DEBUG = True


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


def get_display(gas_prices, config):
    labels = []
    prices = []

    if gas_prices.get("regular", "") != "":
        labels.append(
            render.Text("R: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["regular"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_prices.get("premium", "") != "":
        labels.append(
            render.Text("P: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["premium"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_prices.get("diesel", "") != "":
        labels.append(
            render.Text("D: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["diesel"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["dieselColor"]),
        )

    return labels, prices

def main(config):

    gas_prices = get_gas_prices(config)

    debug(gas_prices["station"])
    debug(gas_prices["open"])
    debug(gas_prices["close"])
    debug(gas_prices["regular"])
    debug(gas_prices["premium"])
    debug(gas_prices["diesel"])

    return []

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


# #######################################################
# #####           Functions                        ######
# #######################################################
def debug(string):
    if DEBUG:
        print(string)

def get_schema():
    price_colors = [
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

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station_by_loc",
                name = "Station",
                desc = "A list of stations by location",
                icon = "locationDot",
                handler = get_stations,
            ),
            schema.Dropdown(
                id = "price_color",
                name = "Price Color",
                desc = "Color scheme for price display",
                icon = "palette",
                default = DEFAULT_CONFIG["price_color"],
                options = price_colors,
            ),
        ],
    )

def get_stations(location):

    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    lat = loc["lat"]
    lng = loc["lng"]
    station_list_cache_key = API_STATION_CACHE_KEY.format(lat,lng)
    #we need to consider caching the station data...  fix this!
    cached_stations = cache.get(station_list_cache_key)

    if cached_stations != None:
        debug("cache hit for stations")	
        stations = json.decode(cached_stations)
    else:
        http_response = http.post(url = API_STATION_SEARCH, json_body = {"pagesize": API_STATION_SEARCH_PAGESIZE, "range": API_STATION_SEARCH_RANGE, "latitude": lat, "longitude": lng })
        debug(" lat = {}  lng = {}".format(lat,lng))
        if http_response.status_code != 200:
            fail("Station list request failed with status {} and result {}".format(http_response.status_code, http_response.body()))
        stations = http_response.json()["data"]
		
    debug(stations)

    if stations["totalCount"] > 0:
        # stations rarely change - so cache for a day - but only if we have valid data
        cache.set(station_list_cache_key, json.encode(stations), 86400)
        return [
            schema.Option(
                display = station["address"] + " " + station["city"] + " " + station["state"],
                value = str(int(station["storeNumber"])),
            )
            for station in stations["stores"]
        ]
    else:
        debug("no stations found")
        return [
            schema.Option(
                display = "No Station within {} miles".format(API_STATION_SEARCH_RANGE),
                value = "0",
			)
        ]

def get_station_details(url):
    station_details = cache.get(url)

    if station_details == None:
        http_data = http.get(url)
        if http_data.status_code != 200:
            fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))
        station_details = http_data.body()
        cache.set(url, station_details, ttl_seconds = API_STATION_DETAILS_TTL)

    #debug(station_details)
    return json.decode(station_details)["data"]

def get_gas_prices(config):
    
    station_id = config.get("station_by_loc", DEFAULT_CONFIG["station"])
    station_data = get_station_details(API_STATION_DETAILS.format(station_id))
    debug(station_data)
    # determine what day today is in local time and get dayname in lowercase
    today_dow = time.now().in_location(config.get("$tz", DEFAULT_CONFIG["timezone"])).format("Monday").lower()
    debug(today_dow)

    gas_prices = {}

    gas_prices["station"] = "{} #{} - {} ({}, {})".format(station_data.get("chainName", "ERROR"), station_data.get("storeNumber", "ERROR"),station_data.get("address", ""),station_data.get("city", ""),station_data.get("state", ""))
    gas_prices["open"] = station_data[today_dow + "Open"][:-1].lower()
    gas_prices["close"] = station_data[today_dow + "Close"][:-1].lower()

    gas_prices["regular"] = ""
    gas_prices["premium"] = ""
    gas_prices["diesel"] = ""

    for price in station_data["gasPrices"]:
        if price["isPrimary"]:
            if price["fuelType"] == "Regular": gas_prices["regular"] = price["price"]
            elif price["fuelType"] == "Premium": gas_prices["premium"] = price["price"]
            elif price["fuelType"] == "Diesel": gas_prices["diesel"] = price["price"]

    return gas_prices
"""
Applet: Murphy USA Gas
Summary: Murphy USA Gas Prices
Description: Display prices from selected Murphy USA station.
Author: jvivona
"""

# Thanks to Dan Adam for the Costco Gas app which this is based upon

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# #######################################################
# #####           Demo / Test Data                 ######
# #######################################################
DEFAULT_LOCATION = """
{
    "lat": "33.6809",
    "lng": "-84.4171",
    "description": "Atlanta, GA, USA",
	"locality": "Atlanta",
	"timezone": "America/New_York"
}
"""

DEFAULT_CONFIG = {
    "station": "2796",
    "timezone": "America/New_York",
    "price_color": "white",
}

# #######################################################
# #####           Constants                        ######
# #######################################################
API_STATION_SEARCH = "https://service.murphydriverewards.com/api/store"
API_STATION_DETAILS = "https://service.murphydriverewards.com/api/store/detail/{}"
API_STATION_SEARCH_PAGESIZE = 10
API_STATION_SEARCH_RANGE = 20
API_STATION_CACHE_KEY = "stations&lat={}&lng={}"
API_STATION_LIST_TTL = 86400
API_STATION_DETAILS_TTL = 3600
DEBUG = False

# #######################################################
# #####           Where all the magic happens      ######
# #######################################################
def main(config):
    gas_data = get_gas_data(config)

    labels, prices = get_price_display(gas_data, config)

    return render.Root(
        max_age = 1800,
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(gas_data["station"], color = "#0073A6"),
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
                            children = get_hours_display(gas_data),
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
    lat = humanize.float("#.##", float(loc["lat"]))
    lng = humanize.float("#.##", float(loc["lng"]))
    station_list_cache_key = API_STATION_CACHE_KEY.format(lat, lng)

    #we need to consider caching the station data...  fix this!
    cached_stations = cache.get(station_list_cache_key)

    if cached_stations != None:
        stations = json.decode(cached_stations)
    else:
        http_response = http.post(url = API_STATION_SEARCH, json_body = {"pagesize": API_STATION_SEARCH_PAGESIZE, "range": API_STATION_SEARCH_RANGE, "latitude": lat, "longitude": lng})
        if http_response.status_code != 200:
            fail("Station list request failed with status {} and result {}".format(http_response.status_code, http_response.body()))
        stations = http_response.json()["data"]

    if stations["totalCount"] > 0:
        # stations rarely change - so cache for a day - but only if we have valid data
        cache.set(station_list_cache_key, json.encode(stations), 86400)
        return [
            schema.Option(
                display = station["address"] + " " + station["city"] + " " + station["state"],
                value = str(int(station["id"])),
            )
            for station in stations["stores"]
        ]
    else:
        return [
            schema.Option(
                display = "No Station within {} miles".format(API_STATION_SEARCH_RANGE),
                value = "0",
            ),
        ]

def get_station_details(url):
    station_details = cache.get(url)

    if station_details == None:
        http_data = http.get(url)
        if http_data.status_code != 200:
            fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))
        station_details = http_data.body()
        cache.set(url, station_details, ttl_seconds = API_STATION_DETAILS_TTL)

    return json.decode(station_details)["data"]

def get_gas_data(config):
    station_id = DEFAULT_CONFIG["station"]
    station_config = config.get("station_by_loc")
    if station_config:
        station_id = int(json.decode(station_config)["value"])

    station_data = get_station_details(API_STATION_DETAILS.format(station_id))

    # determine what day today is in local time and get dayname in lowercase
    today_dow = time.now().in_location(config.get("$tz", DEFAULT_CONFIG["timezone"])).format("Monday").lower()

    gas_data = {}

    gas_data["station"] = "{} #{} - {} ({}, {})".format(station_data.get("chainName", "ERROR"), station_data.get("storeNumber", "ERROR"), station_data.get("address", ""), station_data.get("city", ""), station_data.get("state", ""))
    gas_data["openText"] = station_data[today_dow + "Open"][:-1].lower()
    gas_data["closeText"] = station_data[today_dow + "Close"][:-1].lower()

    gas_data["isOpen"] = False

    # determine if we are open or closed - feed supplies data in UTC - so we don't need to do any localization
    currdatetime = time.now().in_location("UTC")
    for schedule in station_data["schedules"]:
        if time.parse_time(schedule["openTime"]) <= currdatetime:
            if time.parse_time(schedule["closeTime"]) > currdatetime:
                gas_data["isOpen"] = True

    gas_data["regular"] = ""
    gas_data["premium"] = ""
    gas_data["diesel"] = ""

    for price in station_data["gasPrices"]:
        if price["isPrimary"]:
            if price["fuelType"] == "Regular":
                gas_data["regular"] = price["price"]
            elif price["fuelType"] == "Premium":
                gas_data["premium"] = price["price"]
            elif price["fuelType"] == "Diesel":
                gas_data["diesel"] = price["price"]

    return gas_data

def get_price_display(gas_data, config):
    labels = []
    prices = []

    if gas_data.get("regular", "") != "":
        labels.append(
            render.Text("R: "),
        )
        prices.append(
            render.Text(str(gas_data["regular"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_data.get("premium", "") != "":
        labels.append(
            render.Text("P: "),
        )
        prices.append(
            render.Text(str(gas_data["premium"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["gasColor"]),
        )

    if gas_data.get("diesel", "") != "":
        labels.append(
            render.Text("D: "),
        )
        prices.append(
            render.Text(str(gas_data["diesel"]), color = PRICE_COLORS[config.get("price_color", DEFAULT_CONFIG["price_color"])]["dieselColor"]),
        )

    return labels, prices

def get_hours_display(gas_data):
    gas_render = []
    if gas_data["isOpen"]:
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

    gas_render.append(render.Text(gas_data["openText"], font = "tom-thumb"))
    gas_render.append(render.Text(gas_data["closeText"], font = "tom-thumb"))

    return gas_render

# #######################################################
# #####           Schema Option Values             ######
# #######################################################
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

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64

GAS_TYPES = {
    "e5": "Super95",
    "e10": "E10",
    "diesel": "Diesel",
}
RADIUS_OPTIONS = [2, 5, 10, 20, 25]

GAS_STATION_COLOR_MAP = {
    "aral": "#0099ff",
    "shell": "#ff0000",
    "esso": "#ffcc00",
    "totalenergies": "#ff6600",
    "greenline": "#81b445",
    "jet": "#f3bd4a",
    "hem": "#09fc53",
    "star": "#E30613",
    "orlen": "#E30613",
    "sb": "#FFD700",
    "sprint": "#821e17",
    "agip eni": "#F5D800",
    "agip": "#F5D800",
    "elan": "#FF0000",
    "allguth": "#D91E1E",
    "avia": "#D91E1E",
    "bavaria-petrol": "#57bc43",
    "bk": "#3A5FCD",
    "oil!": "#662b79",
    "hoyer": "#c53428",
    "nordoel": "#254893",
    "omv": "#346ebb",
    "tankcenter": "#FFD700",
    "bft": "#003399",
    "avex": "#FF0000",
    "mundorf tank": "#FF6600",
    # "m1"

    # demo
    "guttank": "#ff00ff",
    "bestgas": "#00ff00",
    "alal": "#0000ff",
}

def format_price(price):
    price_str = str(price)
    if "." in price_str:
        parts = price_str.split(".")
        if len(parts[1]) == 1:
            return price_str + "0"
        if len(parts[1]) >= 2:
            return parts[0] + "." + parts[1][:2]
    return price_str + ".00"

def format_text(text):
    return text.replace("ß", "ss").replace("ö", "oe").replace("ä", "ae").replace("ü", "ue").replace("Ö", "Oe").replace("Ä", "Ae").replace("Ü", "Ue")

def get_relevant_stations(stations):
    filtered = [s for s in stations if ("price" in s and s["price"])]
    sorted_l = sorted(filtered, key = lambda x: x["price"])
    relevants = sorted_l[:min(3, len(sorted_l))]
    out = []
    for r in relevants:
        title = ""
        color = "#FFFFFF"
        name_av = "brand" in r and r["brand"]
        if name_av:
            title += r["brand"] + " ("
            color = GAS_STATION_COLOR_MAP.get(r["brand"].lower(), "#FFFFFF")
        title += r["street"].title() + " " + r["houseNumber"]
        if name_av:
            title += ")"
        out.append([title, r["price"], color])
    return out

def main(config):
    selected_type = config.str("gas_type", GAS_TYPES.keys()[0])
    location_json = config.get("location")
    api_key = config.str("api_key")
    radius = config.str("radius")

    demo = not api_key or not location_json

    if demo:
        data = {
            "stations": [
                {
                    "brand": "GutTank",
                    "street": "Anne-Walter-Straße",
                    "houseNumber": "8",
                    "price": 1.109,
                },
                {
                    "brand": "BestGas",
                    "street": "Hauptstraße",
                    "houseNumber": "1",
                    "price": 1.1,
                },
                {
                    "brand": "Alal",
                    "street": "Johann-Georg-Halske-Straße",
                    "houseNumber": "1",
                    "price": 1.34,
                },
            ],
        }
    else:
        location = json.decode(location_json)

        url = "https://creativecommons.tankerkoenig.de/json/list.php?lat=" + location["lat"] + "&lng=" + location["lng"] + "&rad=" + str(radius) + "&sort=dist&type=" + selected_type + "&apikey=" + api_key
        resp = http.get(
            url,
            headers = {"accept": "application/json"},
            ttl_seconds = 300,
        )
        data = resp.json()
        if not "stations" in data:
            return render.Root(render.WrappedText(data["message"]))

    results = get_relevant_stations(data["stations"])
    return render.Root(
        render.Column(
            [
                render.Row(
                    [
                        render.Text(
                            GAS_TYPES[selected_type],
                        ),
                        render.Text("EUR"),
                    ],
                    expanded = True,
                    main_align = "space_between",
                ),
                render.Box(
                    width = TIDBYT_WIDTH,
                    height = 1,
                    color = "#ffffff",
                ),
                render.Column(
                    [
                        render.Padding(
                            render.Row(
                                [
                                    render.Marquee(
                                        render.Text(
                                            format_text(result[0]),
                                            font = "tom-thumb",
                                            color = result[2],
                                        ),
                                        scroll_direction = "horizontal",
                                        width = 44,
                                        delay = 50,
                                    ),
                                    render.Padding(
                                        render.Text(
                                            str(format_price(result[1])) + "€",
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                        pad = (3, 0, 0, 0),
                                    ),
                                ],
                                expanded = True,
                            ),
                            pad = 1,
                        )
                        for result in results
                    ],
                ),
            ],
        ),
    )

def get_schema():
    gas_type_options = [
        schema.Option(
            display = gas_type[1],
            value = gas_type[0],
        )
        for gas_type in GAS_TYPES.items()
    ]
    radius_options = [
        schema.Option(
            display = str(radius) + "km",
            value = str(radius),
        )
        for radius in RADIUS_OPTIONS
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "gas_type",
                name = "Gas Type",
                desc = "The type of gas you want to see prices for",
                icon = "gasPump",
                default = GAS_TYPES.keys()[0],
                options = gas_type_options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display nearby gas prices.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Tankerkönig API Key",
                desc = "API key for the Tankerkönig API (Request from creativecommons.tankerkoenig.de)",
                icon = "key",
            ),
            schema.Dropdown(
                id = "radius",
                name = "Search Radius",
                desc = "The radius in which to search for gas stations",
                icon = "circle",
                default = str(RADIUS_OPTIONS[1]),
                options = radius_options,
            ),
        ],
    )

def print_a_gas_station_map(api_key):
    T_LAT = "51.0504"
    T_LNG = "13.7373"

    url = "https://creativecommons.tankerkoenig.de/json/list.php?lat=" + T_LAT + "&lng=" + T_LNG + "&rad=25&sort=dist&type=all&apikey=" + api_key
    gas_stations = {}
    for station in http.get(url, headers = {"accept": "application/json"}).json()["stations"]:
        if "brand" in station:
            if station["brand"] not in gas_stations:
                gas_stations[station["brand"]] = 1
            else:
                gas_stations[station["brand"]] += 1
    print("\n".join([a[0] + " " + str(a[1]) for a in sorted(gas_stations.items(), key = lambda x: x[1], reverse = True)]))

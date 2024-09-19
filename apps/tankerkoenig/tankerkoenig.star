load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TIDBYT_HEIGHT = 32
TIDBYT_WIDTH = 64

GAS_TYPES = {
    "e5": "Super",
    "e10": "E10",
    "diesel": "Diesel",
}
RADIUS_OPTIONS = [2, 5, 10, 20, 25]

def format_text(text):
    return text.replace("ß", "ss")

def get_relevant_stations(stations):
    filtered = [s for s in stations if ("price" in s and s["price"])]
    sorted_l = sorted(filtered, key = lambda x: x["price"])
    return sorted_l[:min(3, len(sorted_l))]

def main(config):
    selected_type = config.str("gas_type")
    location_json = config.get("location")
    api_key = config.str("api_key")
    radius = config.str("radius")

    demo = not api_key or not location_json

    if demo:
        results = [
            ["GutTank - Anne-Walter-Straße 8", 1.109],
            ["BestGas - Hauptstraße 1", 1.1],
            ["Alal - Johann-Georg-Halske-Straße 1", 1.34],
        ]
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
        r_stations = get_relevant_stations(data["stations"])
        results = [[s["brand"] + " (" + s["street"] + " " + s["houseNumber"] + ")", s["price"]] for s in r_stations]
    return render.Root(
        render.Column(
            [
                render.Text(
                    GAS_TYPES[selected_type] + "-Preise",
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
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                        scroll_direction = "horizontal",
                                        width = 40,
                                    ),
                                    render.Padding(
                                        render.Text(
                                            str(result[1]) + "€",
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

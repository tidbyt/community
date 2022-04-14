"""
Applet: SF Next Muni
Summary: SF Muni arrival times
Description: Shows the predicted arrival times from NextBus for a given SF Muni stop.
Author: Martin Strauss
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOP = '{"value":"15728","display":"Castro Station Inbound"}'
PREDICTIONS_URL = "https://retro.umoiq.com/service/publicJSONFeed?command=predictions&a=sf-muni&stopId=%s&useShortTitles=true"
ROUTES_URL = "https://retro.umoiq.com/service/publicJSONFeed?command=routeList&a=sf-muni&useShortTitles=true"
STOPS_URL = "https://retro.umoiq.com/service/publicJSONFeed?command=routeConfig&a=sf-muni&r=%s&useShortTitles=true"

MUNI_COLORS = {
    "J": "#faa634",
    "K": "#569bbe",
    "L": "#92278f",
    "M": "#008752",
    "N": "#00539b",
    "T": "#d31245",
    "S": "#ffcc00",
}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop_code",
                name = "Bus Stop",
                desc = "A list of bus stops based on a location.",
                icon = "bus",
                handler = get_stops,
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show stop title",
                desc = "A toggle to show the stop title.",
                icon = "signHanging",
                default = False
            ),
            schema.Toggle(
                id = "compact_predictions",
                name = "Show compact predictions",
                desc = "A toggle to show shorter prediction text.",
                icon = "grid",
                default = False
            ),
            # TODO: service messages.
        ],
    )

def get_stops(location):
    loc = json.decode(location)

    raw_routes = fetch_cached(ROUTES_URL, 86400)
    routes = [route["tag"] for route in raw_routes["route"]]

    stops = []

    for route in routes:
        raw_stops = fetch_cached(STOPS_URL, 86400)
        stops.extend([json.decode(stop) for stop in raw_stops["route"]["stop"]])

    return [
        schema.Option(
            display = stop["title"],
            value = stop["stopId"],
        )
        for stop in sorted(stops, key = lambda stop: square_distance(loc["lat"], loc["lon"], stop["lat"], stop["lon"]))
    ]

def square_distance(lat1, lon1, lat2, lon2):
    return (lat2 - lat1) ^ 2 + (lon2 - lon1) ^ 2

def fetch_cached(url, ttl):
    cached = cache.get(url)
    if cached != None:
        return json.decode(cached)
    else:
        res = http.get(url)
        if res.status_code != 200:
            fail("NextBus request to %s failed with status %d", (url, res.status_code))
        data = res.json()
        cache.set(url, str(data), ttl_seconds = ttl)
        return data

def main(config):
    stopId = json.decode(config.get("stop_code", DEFAULT_STOP))["value"]
    routes = fetch_cached(PREDICTIONS_URL % stopId, 240)["predictions"]

    if type(routes) != "list":
        routes = [routes]

    prediction_map = {}

    for route in routes:
        if "routeTag" not in route or "direction" not in route:
            continue
        routeTag = route["routeTag"]

        destinations = route["direction"]
        if type(destinations) != "list":
            destinations = [destinations]
        for dest in destinations:
            if "title" not in dest or "prediction" not in dest:
                continue
            destTitle = dest["title"].replace("Inbound to ", "").replace("Outbound to ", "").replace(" Station", "")
            predictions = dest["prediction"]
            if type(predictions) != "list":
                predictions = [predictions]

            # Hack for KT interlining, until the Central Subway opens
            if routeTag == "KT":
                routeTag = "T" if "Inbound" in dest["title"] else "K"

            title = routeTag if config.bool("compact_predictions") else (routeTag, destTitle)
            minutes = [prediction["minutes"] for prediction in predictions if "minutes" in prediction]
            prediction_map[title] = sorted(minutes, key = int)

    output = sorted(prediction_map.items(), key = lambda kv: int(min(kv[1], key = int)))

    lines = 3

    if config.bool("show_title"):
        lines = lines - 1

    rows = []
    if config.bool("show_title"):
        title = json.decode(config.get("stop_code", DEFAULT_STOP))["display"]
        rows.append(
            render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(title)),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#FFF",
                    )
                ])
        )
    if config.bool("compact_predictions"):
        rows.extend(shortPredictions(output, lines))
    else:
        rows.extend(longRows(output[:lines]))

    return render.Root(
        child = render.Column(
            children = rows,
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        ),
    )

def calculateLength(predictions):
    return (7  # diameter of line circle
        + 4    # leading space
        + 4 * len(",".join(predictions[:2]))
        + 4)   # trailing space

def shortPredictions(output, lines):
    predictionLengths = [calculateLength(predictions) for (routeTag, predictions) in output]
    
    rows = []
    for row in range(lines):
        row = []
        cumulativeLength = 0
        for length in predictionLengths:
            cumulativeLength = cumulativeLength + length
            if (cumulativeLength > 64 or not output): break
            row.append(output.pop(0))
        rows.append(row)

    return [
        render.Box(
            padding = 2,
            child = render.Column(
                expanded = True,
                children = [
                    render.Row(
                        children = [
                            render.Row(
                                children = [
                                    render.Circle(
                                        child = render.Text(routeTag, font="tom-thumb"),
                                        diameter = 7,
                                        color = MUNI_COLORS[routeTag] if routeTag in MUNI_COLORS else "#000000",
                                    ),
                                    render.Text(" "),
                                    render.Text(",".join(predictions[:2]), font="tom-thumb"),
                                    render.Text(" "),
                                ],
                                main_align = "space_around",
                                cross_align = "center"
                            )
                            for (routeTag, predictions) in row
                        ],
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                    )
                    for row in rows
                ]
            )
        )
    ]

def longRows(output):
    return [
        render.Row(
            children = [
                render.Circle(
                    child = render.Text(routeTag),
                    diameter = 10,
                    color = MUNI_COLORS[routeTag] if routeTag in MUNI_COLORS else "#000000",
                ),
                render.Marquee(
                    child = render.Text(destination),
                    width = 40,
                ),
                render.Marquee(
                    child = render.Text((" " if len(predictions[0]) < 2 else "") + predictions[0]),
                    width = 10,
                ),
            ],
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        )
        for ((routeTag, destination), predictions) in output
    ]
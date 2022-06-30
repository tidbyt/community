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
load("time.star", "time")

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
    priorities = [
        schema.Option(
            display = "High",
            value = "High",
        ),
        schema.Option(
            display = "Normal",
            value = "Normal",
        ),
        schema.Option(
            display = "Low",
            value = "Low",
        ),
        schema.Option(
            display = "None",
            value = "none",
        ),
    ]

    formats = [
        schema.Option(
            display = "With destination",
            value = "long",
        ),
        schema.Option(
            display = "No destination",
            value = "medium",
        ),
        schema.Option(
            display = "Compact",
            value = "short",
        ),
    ]

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
                default = False,
            ),
            schema.Dropdown(
                id = "prediction_format",
                name = "Prediction format",
                desc = "Select the format of the prediction text.",
                icon = "grid",
                default = "long",
                options = formats,
            ),
            schema.Dropdown(
                id = "service_messages",
                name = "Show service messages",
                desc = "The lowest priority of service message to be displayed.",
                icon = "comment-exclamation",
                default = priorities[0].value,
                options = priorities,
            ),
            schema.Text(
                id = "minimum_time",
                name = "Minimum time to show",
                desc = "Don't show predictions nearer than this minimum.",
                icon = "clock",
                default = "0",
            ),
        ],
    )

def get_stops(location):
    loc = json.decode(location)

    (timestamp, raw_routes) = fetch_cached(ROUTES_URL, 86400)
    routes = [route["tag"] for route in raw_routes["route"]]

    stops = {}

    for route in routes:
        (timestamp, raw_stops) = fetch_cached((STOPS_URL % route), 86400)
        stops.update([(stop["stopId"], stop) for stop in raw_stops["route"]["stop"]])

    return [
        schema.Option(
            display = stop["title"],
            value = stop["stopId"],
        )
        for stop in sorted(stops.values(), key = lambda stop: square_distance(loc["lat"], loc["lng"], stop["lat"], stop["lon"]))
    ]

def square_distance(lat1, lon1, lat2, lon2):
    latitude_difference = int((float(lat2) - float(lat1)) * 10000)
    longitude_difference = int((float(lon2) - float(lon1)) * 10000)
    return latitude_difference * latitude_difference + longitude_difference * longitude_difference

def fetch_cached(url, ttl):
    cached = cache.get(url)
    timestamp = cache.get("timestamp::%s" % url)
    if cached and timestamp:
        return (int(timestamp), json.decode(cached))
    else:
        res = http.get(url)
        if res.status_code != 200:
            fail("NextBus request to %s failed with status %d", (url, res.status_code))
        data = res.json()
        timestamp = time.now().unix
        cache.set(url, str(data), ttl_seconds = ttl)
        cache.set(("timestamp::%s" % url), str(timestamp), ttl_seconds = ttl)
        return (timestamp, data)

def higher_priority_than(pri, threshold):
    return threshold == "Low" or pri == "High" or threshold == pri

def main(config):
    stop = json.decode(config.get("stop_code", DEFAULT_STOP))
    stopId = stop["value"]

    (data_timestamp, data) = fetch_cached(PREDICTIONS_URL % stopId, 240)
    routes = data["predictions"]
    data_age_seconds = time.now().unix - data_timestamp

    if type(routes) != "list":
        routes = [routes]

    minimum_time_string = config.str("minimum_time", "0")
    minimum_time = int(minimum_time_string) if minimum_time_string.isdigit() else 0
    prediction_map = {}
    messages = []

    for route in routes:
        if "routeTag" not in route or "direction" not in route:
            continue
        routeTag = route["routeTag"]

        if "message" in route:
            message = route["message"]
            if type(message) != "list":
                message = [message]
            for m in message:
                if m not in messages:
                    messages.append(m)

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

            title = routeTag if "short" == config.get("prediction_format") else (routeTag, destTitle)
            seconds = [int(prediction["seconds"]) - data_age_seconds for prediction in predictions if "seconds" in prediction]
            minutes = [int(time / 60) for time in seconds if int(time / 60) >= minimum_time]

            prediction_map[title] = [str(time) for time in sorted(minutes)]

    output = sorted(prediction_map.items(), key = lambda kv: int(min(kv[1], key = int))) if prediction_map.items() else []
    lowest_message_pri = config.get("service_messages")
    messages = [
        message["text"]
        for message in messages
        if higher_priority_than(message["priority"], lowest_message_pri)
    ]

    lines = 4
    height = 32

    if config.bool("show_title"):
        lines = lines - 1
        height = height - 9
    if messages:
        lines = lines - 1
        height = height - 8

    rows = []
    if config.bool("show_title"):
        title = stop["display"]
        rows.append(
            render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(title),
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#FFF",
                    ),
                ],
                main_align = "start",
            ),
        )

    predictionLines = []

    if "short" == config.get("prediction_format"):
        predictionLines = shortPredictions(output, messages, lines, config)
    else:
        predictionLines = longRows(output[:lines], config)

    rows.append(
        render.Box(
            height = height,
            padding = 0,
            child = render.Column(
                children = predictionLines,
                main_align = "space_evenly",
                expanded = True,
            ),
        ),
    )

    if messages:
        rows.append(
            render.Column(
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 1),
                        child = render.Box(
                            width = 64,
                            height = 1,
                            color = "#FFF",
                        ),
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text("      ".join(messages), font = "tom-thumb"),
                    ),
                ],
                main_align = "end",
            ),
        )

    return render.Root(
        child = render.Column(
            children = rows,
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
        ),
    )

def calculateLength(predictions):
    return (7 +  # diameter of line circle
            4 +  # leading space
            4 * len(",".join(predictions[:2])) +
            4)  # trailing space

def shortPredictions(output, messages, lines, config):
    predictionLengths = [calculateLength(predictions) for (routeTag, predictions) in output]

    rows = []
    for line in range(lines):
        row = []
        cumulativeLength = 0
        for length in predictionLengths:
            cumulativeLength = cumulativeLength + length
            if (cumulativeLength - 4 > 64 or not output):
                break
            row.append(output.pop(0))
        if (row):
            rows.append(row)

    padding = 2
    horizontalMargin = []

    if len(rows) == lines:
        padding = 0
        horizontalMargin = [render.Text(" ")]

    return [
        render.Box(
            padding = padding,
            child = render.Column(
                expanded = True,
                children = [
                    render.Row(
                        children = horizontalMargin + [
                            render.Row(
                                children = [
                                    render.Circle(
                                        child = render.Text(routeTag, font = "tom-thumb"),
                                        diameter = 7,
                                        color = MUNI_COLORS[routeTag] if routeTag in MUNI_COLORS else "#000000",
                                    ),
                                    render.Text(" "),
                                    render.Text(",".join(predictions[:2]), font = "tom-thumb"),
                                    render.Text(" "),
                                ],
                                main_align = "space_around",
                                cross_align = "center",
                            )
                            for (routeTag, predictions) in row
                        ] + horizontalMargin,
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                    )
                    for row in rows
                ],
            ),
        ),
    ]

def longRows(output, config):
    return [
        render.Row(
            children = getLongRow(routeTag, destination, predictions, config),
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        )
        for ((routeTag, destination), predictions) in output
    ]

def getLongRow(routeTag, destination, predictions, config):
    row = []
    if routeTag in MUNI_COLORS:
        row.append(
            render.Circle(
                child = render.Text(routeTag, font = "tom-thumb"),
                diameter = 7,
                color = MUNI_COLORS[routeTag],
            ),
        )
    else:
        row.append(
            render.Text(routeTag + " ", font = "tom-thumb"),
        )
    if "long" == config.get("prediction_format"):
        row.append(
            render.Marquee(
                child = render.Text(destination, font = "tom-thumb"),
                width = 40,
            ),
        )
        row.append(
            render.Marquee(
                child = render.Text((" " if len(predictions[0]) < 2 else "") + predictions[0], font = "tom-thumb"),
                width = 10,
            ),
        )
    else:
        row.append(
            render.Marquee(
                child = render.Text("%s min" % " & ".join([prediction for prediction in predictions[:2]]), font = "tom-thumb"),
                width = 50,
            ),
        )

    return row

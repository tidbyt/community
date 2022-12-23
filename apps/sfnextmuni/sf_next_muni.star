"""
Applet: SF Next Muni
Summary: SF Muni arrival times
Description: Shows the predicted arrival times from 511.org for a given SF Muni stop.
Author: Martin Strauss
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

DEFAULT_LOCATION = """
{
  "lat": "37.7844",
  "lng": "-122.4080",
	"description": "San Francisco, CA, USA",
	"locality": "San Francisco",
	"timezone": "America/Los_Angeles"
}
"""
DEFAULT_STOP = """
{
    "display":"Metro Powell Station/Outbound (#16995)",
    "value":"16995"
}
"""
PREDICTIONS_URL = "https://api.511.org/transit/StopMonitoring?format=json&api_key=%s&agency=SF&stopCode=%s"
ROUTES_URL = "https://api.511.org/transit/lines?format=json&api_key=%s&operator_id=SF"
STOPS_URL = "https://api.511.org/transit/stops?format=json&api_key=%s&operator_id=SF"
ALERTS_URL = "https://api.511.org/transit/servicealerts?format=json&api_key=%s&agency=SF"

API_KEY_SECRET = "AV6+xWcEQi9NDhqpC/pp2NupmNWFYTeBYuCVcXrkAb8agjj6sL6ZRfIvKDt7iPzpYJ5VE83c2R2cQt7Fn1luIqO04BoQXu9fadB3CYMvvqi56Z++YIkZm7hTol6xnnom3xszeArqfUf/TJXjgaobdX3fToZS8W8LuBB67LVAcsngq9/FP6Yshrj6"
API_KEY = secret.decrypt(API_KEY_SECRET)

# Colours for Muni Metro/Street Car lines
MUNI_COLORS = {
    "E": "#666666",
    "F": "#f0e68c",
    "J": "#faa634",
    "K": "#569bbe",
    "L": "#92278f",
    "M": "#008752",
    "N": "#00539b",
    "T": "#d31245",
    "S": "#ffcc00",
}

# Display the route letter in black text (#000000) inside the circle for these routes
MUNI_BLACK_TEXT = [
    "F",
    "S",
]

# Inbound stops on KT line that should display as K. If not listed stop will display as T
K_INBOUND_STOPS = [
    "17778",
    "15784",
    "15794",
    "15797",
    "15787",
    "15788",
    "15809",
    "15779",
    "15806",
    "17113",
    "17109",
    "16898",
]

# Outbound stops on KT line that should display as T. If not listed stop will display as K
T_OUTBOUND_STOPS = [
    "17398",
    "17399",
    "17400",
    "17347",
    "17343",
    "17345",
    "17401",
    "17402",
    "17403",
    "17404",
    "17352",
    "17353",
    "17354",
    "17355",
    "17356",
    "17357",
    "17358",
    "17166",
    "15237",
    "17145",
    "14510",
]

# Dictionary to define default config values when pixlet commands are run as get_schema() currently not referenced then
DEFAULT_CONFIG = {
    "route_filter": "all-routes",
    "prediction_format": "long",
}

def get_schema():
    formats = [
        schema.Option(
            display = "With destination",
            value = "xlong",
        ),
        schema.Option(
            display = "Short destination",
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
        schema.Option(
            display = "Two line w/destination",
            value = "two_line_dest",
        ),
        schema.Option(
            display = "Two line w/4 times",
            value = "two_line_four_times",
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
            schema.Dropdown(
                id = "route_filter",
                name = "Route Filter",
                desc = "Filter to only display one route",
                icon = "route",
                default = "all-routes",
                options = get_route_list(),
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
                icon = "borderAll",
                default = "long",
                options = formats,
            ),
            schema.Toggle(
                id = "agency_alerts",
                name = "Show agency-wide service alerts",
                desc = "Show service alerts targeted to all of SF Muni.",
                icon = "exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "route_alerts",
                name = "Show route-specific service alerts",
                desc = "Show service alerts targeted to the routes at the selected stop.",
                icon = "exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "stop_alerts",
                name = "Show stop-specific service alerts",
                desc = "Show service alerts targeted to the selected stop.",
                icon = "exclamation",
                default = False,
            ),
            schema.Text(
                id = "alert_languages",
                name = "Service alert langauges",
                desc = "Languages to show service alerts in, separated by commas.",
                icon = "flag",
                default = "en",
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
    if not API_KEY:
        return []

    loc = json.decode(location)

    stops = {}

    (timestamp, raw_stops) = fetch_cached(STOPS_URL % API_KEY, 86400)

    if "Contents" not in raw_stops:
        return []

    stops.update([(stop["id"], stop) for stop in raw_stops["Contents"]["dataObjects"]["ScheduledStopPoint"]])

    return [
        schema.Option(
            display = "%s (#%s)" % (stop["Name"], stop["id"]),
            value = stop["id"],
        )
        for stop in sorted(stops.values(), key = lambda stop: square_distance(loc["lat"], loc["lng"], stop["Location"]["Latitude"], stop["Location"]["Longitude"]))
    ]

# Function to get the available route list for route filter selection. Additionally adds 'all-routes' option to the beginning of the list
def get_route_list():
    if not API_KEY:
        return [
            schema.Option(
                display = "All Routes",
                value = "all-routes",
            ),
        ]

    (timestamp, routes) = fetch_cached(ROUTES_URL % API_KEY, 86400)

    route_list = [
        schema.Option(
            display = "%s %s" % (route["Id"], route["Name"]),
            value = route["Id"],
        )
        for route in routes
    ]
    route_list.insert(
        0,
        schema.Option(
            display = "All Routes",
            value = "all-routes",
        ),
    )
    return route_list

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
            print("511.org request to %s failed with status %d", (url, res.status_code))
            return (time.now().unix, {})

        # Trim off the UTF-8 byte-order mark
        body = res.body().lstrip("\ufeff")
        data = json.decode(body)
        timestamp = time.now().unix
        cache.set(url, body, ttl_seconds = ttl)
        cache.set(("timestamp::%s" % url), str(timestamp), ttl_seconds = ttl)
        return (timestamp, data)

def higher_priority_than(pri, threshold):
    return threshold == "Low" or pri == "High" or threshold == pri

def main(config):
    default_stops = get_stops(DEFAULT_LOCATION)
    default_stop = json.encode(default_stops[0]) if default_stops else DEFAULT_STOP
    stop = json.decode(config.get("stop_code", default_stop))
    stopId = stop["value"]

    api_key = API_KEY or config.get("dev_api_key")

    ## Fetch and parse predictions
    (stopTitle, routes, predictions) = getPredictions(api_key, config, stop)

    ## Fetch, parse and filter service messages
    messages = getMessages(api_key, config, routes, stopId)

    ## Render the title, predictions and messages
    if not stopTitle and not predictions and not messages:
        return []

    return renderOutput(stopTitle, predictions, messages, config)

def getPredictions(api_key, config, stop):
    stopId = stop["value"]
    stopTitle = stop["display"]
    (data_timestamp, data) = fetch_cached(PREDICTIONS_URL % (api_key, stopId), 240)

    service = data.get("ServiceDelivery", {})
    if not service or not service["Status"]:
        return (stopTitle, [], [])

    stopMonitoring = service["StopMonitoringDelivery"]
    monitoredVisits = stopMonitoring["MonitoredStopVisit"]

    route_filter = config.get("route_filter", DEFAULT_CONFIG["route_filter"])

    minimum_time_string = config.str("minimum_time", "0")
    minimum_time = int(minimum_time_string) if minimum_time_string.isdigit() else 0
    prediction_map = {}
    routes = []

    data_age_seconds = time.now().unix - data_timestamp

    for visit in monitoredVisits:
        if "MonitoredVehicleJourney" not in visit:
            continue
        vehicle = visit["MonitoredVehicleJourney"]

        routeTag = vehicle["LineRef"]
        if route_filter != "all-routes" and routeTag != route_filter:
            continue

        if routeTag not in routes:
            routes.append(routeTag)

        if "DestinationName" not in vehicle:
            continue
        destTitle = vehicle["DestinationName"].replace(" Station", "")

        if "MonitoredCall" not in vehicle:
            continue
        call = vehicle["MonitoredCall"]
        stopId = call["StopPointRef"]
        stopTitle = call["StopPointName"]

        # Hack for KT interlining, until the Central Subway opens. If stop is in override list, then route designation overriden. Else, use Inbound/Outbound direction to determine route letter
        if routeTag == "KT":
            kt_override_stops = {}
            for stop in K_INBOUND_STOPS:
                kt_override_stops[stop] = "K"
            for stop in T_OUTBOUND_STOPS:
                kt_override_stops[stop] = "T"
            routeTag = kt_override_stops.get(stopId, "T" if vehicle["DirectionRef"] == "IB" else "K")

        titleKey = routeTag if "short" == config.get("prediction_format") else (routeTag, destTitle)
        if titleKey not in prediction_map:
            prediction_map[titleKey] = []

        expectedArrivalTime = time.parse_time(call["ExpectedArrivalTime"])
        seconds = expectedArrivalTime.unix - time.now().unix
        minutes = int(seconds / 60)

        if minutes >= minimum_time:
            prediction_map[titleKey].append(minutes)

    output_map = {}
    for key in prediction_map:
        output_map[key] = [str(prediction) for prediction in sorted(prediction_map[key])]

    output = sorted(output_map.items(), key = lambda kv: int(min(kv[1], key = int))) if output_map.items() else []

    return (stopTitle, routes, output)

def getMessages(api_key, config, routes, stopId):
    (data_timestamp, data) = fetch_cached(ALERTS_URL % api_key, 240)

    # https://developers.google.com/transit/gtfs-realtime/reference#message-feedentity
    entities = data.get("Entities")

    messages = []

    if not entities:
        return messages

    for entry in entities:
        # https://developers.google.com/transit/gtfs-realtime/reference#message-alert
        alert = entry["Alert"]
        if not alert:
            continue

        languages = config.str("alert_languages", "en").split(",")
        translations = [translation["Text"] for translation in alert["HeaderText"]["Translations"] if translation["Language"] == "en"]

        if not translations:
            continue

        # https://developers.google.com/transit/gtfs-realtime/reference#message-entityselector
        informedAgencies = [entity["AgencyId"] for entity in alert["InformedEntities"] if "AgencyId" in entity]
        informedRoutes = [entity["RouteId"] for entity in alert["InformedEntities"] if "RouteId" in entity]
        informedStops = [entity["StopId"] for entity in alert["InformedEntities"] if "StopId" in entity]
        if ((config.bool("agency_alerts") and "SF" in informedAgencies) or
            (config.bool("route_alerts") and [route for route in informedRoutes if route in routes]) or
            (config.bool("stop_alerts") and stopId in informedStops)):
            messages.extend(translations)

    return messages

def renderOutput(stopTitle, output, messages, config):
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
        rows.append(
            render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(stopTitle),
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
                                        child = render.Text(routeTag, font = "tom-thumb", color = "#000000" if routeTag in MUNI_BLACK_TEXT else "#ffffff"),
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
    output = output[:2] if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] == "two_line" else output
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
                child = render.Text(routeTag, font = "tom-thumb" if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else "", color = "#000000" if routeTag in MUNI_BLACK_TEXT else "#ffffff"),
                diameter = 7 if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else 12,
                color = MUNI_COLORS[routeTag],
            ),
        )
    else:
        row.append(
            render.Text(
                routeTag + " ",
                font = "tom-thumb" if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else "",
            ),
        )
    if "xlong" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
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
    elif "long" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
        row.append(
            render.Marquee(
                child = render.Text(destination, font = "tom-thumb"),
                width = 30,
            ),
        )
        nextTwoPredictions = ",".join(predictions[:2])
        nextTwoPredictions = " " * (5 - len(nextTwoPredictions)) + nextTwoPredictions
        row.append(
            render.Marquee(
                child = render.Text(nextTwoPredictions, font = "tom-thumb"),
                width = 20,
            ),
        )
    elif "two_line" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8]:
        max_width = 50
        max_predictions = 4
        if "two_line_dest" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
            row.append(
                render.Marquee(
                    child = render.Text(destination),
                    width = 25,
                ),
            )
            max_width = max_width - 25
            max_predictions = 2

        row.append(
            render.Marquee(
                child = render.Text(",".join([prediction for prediction in predictions[:max_predictions]])),
                width = max_width,
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

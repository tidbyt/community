"""
Applet: New Jersey PATH
Summary: NJ Path real-time arrivals
Description: Displays real-time departures for a New Jersey PATH station.
Author: karmeleon
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PATH_URL = "https://path.api.razza.dev/v1/stations/{station}/realtime"

STATIONS = {
    "fourteenth_street": "14th Street",
    "twenty_third_street": "23rd Street",
    "thirty_third_street": "33rd Street",
    "christopher_street": "Christopher Street",
    "exchange_place": "Exchange Place",
    "grove_street": "Grove Street",
    "harrison": "Harrison",
    "hoboken": "Hoboken",
    "journal_square": "Journal Square",
    "newark": "Newark",
    "newport": "Newport",
    "ninth_street": "Ninth Street",
    "world_trade_center": "World Trade Center",
}

def get_arrival_text(arrival_times):
    offsets = []
    only_now = True
    for arrival_time in arrival_times:
        offset_time_mins = int((arrival_time - time.now()).minutes)
        if offset_time_mins == 0:
            offsets.append("now")
        else:
            offsets.append(str(offset_time_mins))
            only_now = False

    # we want to avoid displaying "now min"
    if only_now:
        # super unlikely, but technically possible to be "now, now"
        return ", ".join(offsets)
    else:
        # "now, 5 min" is okay
        return "{} min".format(", ".join(offsets))

def get_display_row(arrival):
    wait_time_text = get_arrival_text(arrival["arrivalTimes"])

    is_multicolor = len(arrival["lineColors"]) > 1

    if is_multicolor:
        circle_widget = render.Row(
            children = [
                render.Box(
                    width = 5,
                    height = 11,
                    child = render.Padding(
                        child = render.Circle(
                            color = arrival["lineColors"][0],
                            diameter = 11,
                        ),
                        pad = (6, 0, 0, 0),
                    ),
                ),
                # 11 is an odd number so we need something in the middle
                # this color is the midpoint between the colors in the only
                # path line with multiple colors.
                # would be cool to calculate this automatically but starlark
                # doesn't have any color or hex-printing libraries
                render.Box(
                    width = 1,
                    height = 11,
                    color = "#A6967E",
                ),
                render.Box(
                    width = 5,
                    height = 11,
                    child = render.Padding(
                        child = render.Circle(
                            color = arrival["lineColors"][1],
                            diameter = 11,
                        ),
                        pad = (0, 0, 6, 0),
                    ),
                ),
            ],
        )
    else:
        circle_widget = render.Circle(
            color = arrival["lineColors"][0],
            diameter = 11,
        )

    return render.Row(
        children = [
            render.Padding(
                child = circle_widget,
                pad = 2,
            ),
            render.Column(
                children = [
                    render.Marquee(
                        child = render.Text(arrival["friendlyRouteName"]),
                        width = 49,
                    ),
                    render.Text(
                        content = wait_time_text,
                        color = "#ffa500",
                        offset = 1,
                    ),
                ],
            ),
        ],
    )

def get_routes(api_response):
    routes = {}

    for arrival in api_response["upcomingTrains"]:
        route_key = "{}|{}".format(arrival["route"], arrival["direction"])
        arrival_time = time.parse_time(arrival["projectedArrival"])
        if route_key in routes:
            # we've already seen this route, just stick the arrival time into it
            routes[route_key]["arrivalTimes"].append(arrival_time)
        else:
            # we haven't seen this route yet, make a new entry for it
            routes[route_key] = {
                "friendlyRouteName": arrival["routeDisplayName"],
                "arrivalTimes": [arrival_time],
                "lineColors": arrival["lineColors"],
                "direction": arrival["direction"],
            }

    routes_ordered = list(routes.values())

    # sort the arrivals in chronological order
    for route in routes_ordered:
        route["arrivalTimes"] = sorted(route["arrivalTimes"])

    # sort the routes so the one with the soonest arrival is first
    routes_ordered = sorted(routes_ordered, key = lambda route: route["arrivalTimes"][0])
    return routes_ordered

def query_api(station):
    response = cache.get("station_{}".format(station))
    if response != None:
        return json.decode(response)

    path_url_for_station = PATH_URL.format(station = station)
    api_response = http.get(path_url_for_station)
    if api_response.status_code != 200:
        fail("Path api is sad :( url {} returned {}".format(path_url_for_station, api_response.status_code))
    response_json = api_response.json()

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set("station_{}".format(station), json.encode(response_json), ttl_seconds = 30)

    return response_json

def main(config):
    station = config.get("station") or "grove_street"
    desired_direction = config.get("direction") or "both"

    api_response = query_api(station)

    routes_ordered = get_routes(api_response)

    if desired_direction != "both":
        # filter out the trains going the other way
        routes_ordered = [route for route in routes_ordered if desired_direction == route["direction"]]

    num_routes_to_display = len(routes_ordered)

    if num_routes_to_display == 0:
        extra_text = ""
        if desired_direction != "both":
            extra_text = " toward {}".format("NY" if desired_direction == "TO_NY" else "NJ")
        text_content = "No scheduled PATH departures from {}{}.".format(STATIONS[station], extra_text)

        content = render.WrappedText(text_content, font = "tom-thumb")
    elif num_routes_to_display == 1:
        content = get_display_row(routes_ordered[0])
    else:
        content = render.Column(
            children = [
                get_display_row(routes_ordered[0]),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                get_display_row(routes_ordered[1]),
            ],
        )

    return render.Root(
        child = content,
        max_age = 60,
        delay = 100,
    )

def get_station_options():
    options = []
    for value, display in STATIONS.items():
        options.append(schema.Option(
            display = display,
            value = value,
        ))

    return options

def get_schema():
    station_options = get_station_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "The station to view arrivals for.",
                icon = "trainSubway",
                options = station_options,
                default = station_options[0].value,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "The direction to display arrivals for.",
                icon = "arrowsTurnToDots",
                options = [
                    schema.Option(
                        display = "Both",
                        value = "both",
                    ),
                    schema.Option(
                        display = "NY",
                        value = "TO_NY",
                    ),
                    schema.Option(
                        display = "NJ",
                        value = "TO_NJ",
                    ),
                ],
                default = "both",
            ),
        ],
    )

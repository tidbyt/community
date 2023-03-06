"""
Applet: SEPTA Transit
Summary: SEPTA transit departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL.
Author: radiocolin
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_BASE = "http://www3.septa.org/api"
API_ROUTES = API_BASE + "/Routes"
API_STOPS = API_BASE + "/Stops"
API_SCHEDULE = API_BASE + "/BusSchedules"
DEFAULT_ROUTE = "17"
DEFAULT_STOP = "10266"

def get_routes():
    r = http.get(API_ROUTES)
    routes = r.json()

    list_of_routes = []

    for i in routes:
        if i["route_type"] != "2":
            list_of_routes.append(
                schema.Option(
                    display = i["route_short_name"] + ": " + i["route_long_name"],
                    value = i["route_id"],
                ),
            )

    return list_of_routes

def get_route_name(route):
    r = http.get(API_ROUTES)
    routes = r.json()

    for i in routes:
        if i["route_id"] == route:
            return i["route_short_name"] + ": " + i["route_long_name"]

    return ""

def get_route_bg_color(route):
    r = http.get(API_ROUTES)
    routes = r.json()

    for i in routes:
        if i["route_id"] == route:
            return i["route_color"]

    return "#000"

def get_route_icon(route):
    r = http.get(API_ROUTES)
    routes = r.json()

    for i in routes:
        if i["route_id"] == route:
            if i["route_type"] == "0":
                return "trainTram"
            if i["route_type"] == "1":
                return "trainSubway"
            if i["route_type"] == "3":
                return "bus"

    return "question"

def get_route_text_color(route):
    r = http.get(API_ROUTES)
    routes = r.json()

    for i in routes:
        if i["route_id"] == route:
            return i["route_text_color"]

    return "#fff"

def get_stops(route):
    r = http.get(API_STOPS, params = {"req1": route})
    stops = r.json()

    list_of_stops = []

    for i in stops:
        list_of_stops.append(
            schema.Option(
                display = i["stopname"].replace("&amp;", "&") + " (" + i["stopid"] + ")",
                value = i["stopid"],
            ),
        )

    return list_of_stops

def get_schedule(route, stopid):
    print(route, stopid)
    r = http.get(API_SCHEDULE, params = {"req1": stopid, "req2": route})
    schedule = r.json()

    list_of_departures = []

    if schedule.get(route):
        for i in schedule.get(route):
            if len(list_of_departures) == 1 or len(list_of_departures) == 3:
                background = "#222"
                text = "#fff"
            else:
                background = "#000"
                text = "#ffc72c"
            item = render.Box(
                height = 6,
                width = 64,
                color = background,
                child = render.Row(
                    children = [
                        render.Box(
                            width = 25,
                            child = render.WrappedText(
                                i["date"],
                                font = "tom-thumb",
                                color = text,
                            ),
                        ),
                        render.Marquee(
                            child = render.Text(
                                i["DirectionDesc"],
                                font = "tom-thumb",
                                color = text,
                            ),
                            width = 39,
                        ),
                    ],
                ),
            )
            list_of_departures.append(item)

    return list_of_departures

def select_stop(route):
    return [
        schema.Dropdown(
            id = "stop",
            name = "Stop",
            desc = "Select a stop",
            icon = get_route_icon(route),
            default = DEFAULT_STOP,
            options = get_stops(route),
        ),
    ]

def main(config):
    route = config.str("route", DEFAULT_ROUTE)
    stop = config.str("stop", DEFAULT_STOP)

    schedule = get_schedule(route, stop)
    route_bg_color = get_route_bg_color(route)
    route_text_color = get_route_text_color(route)

    return render.Root(
        render.Column(
            children = [
                render.Column(
                    cross_align = "start",
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = route_bg_color),
                            render.Padding(pad = (1, 0, 0, 0), child = render.Text(route, font = "tom-thumb", color = route_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, 1), color = route_bg_color, child = render.Box(child = render.Column(children = schedule))),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "route",
                name = "Route",
                desc = "Select a route",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop",
                source = "route",
                handler = select_stop,
            ),
        ],
    )

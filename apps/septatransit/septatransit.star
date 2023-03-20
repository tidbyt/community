"""
Applet: SEPTA Transit
Summary: SEPTA transit departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "http://www3.septa.org/api"
API_ROUTES = API_BASE + "/Routes"
API_STOPS = API_BASE + "/Stops"
API_SCHEDULE = API_BASE + "/BusSchedules"
DEFAULT_ROUTE = "17"
DEFAULT_STOP = "10264"
DEFAULT_BANNER = ""

def call_routes_api():
    cache_string = cache.get("routes_api_response")
    routes = None
    if cache_string != None:
        routes = json.decode(cache_string)
    if routes == None:
        r = http.get(API_ROUTES)
        routes = r.json()
        cache.set("routes_api_response", json.encode(routes), ttl_seconds = 3600)
    sorted_routes = sort_routes(routes)
    return sorted_routes

def sort_routes(routes):
    numerical_routes = []
    non_numerical_routes = []

    for route in routes:
        if route["route_short_name"].isdigit():
            numerical_routes.append(route)
        else:
            non_numerical_routes.append(route)

    numerical_routes = sorted(numerical_routes, key = lambda x: int(x["route_short_name"]))
    return numerical_routes + non_numerical_routes

def get_routes():
    routes = call_routes_api()
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
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_short_name"] + ": " + i["route_long_name"]
    return ""

def get_route_bg_color(route):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_color"]
    return "#000"

def get_route_icon(route):
    routes = call_routes_api()
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
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_text_color"]
    return "#fff"

def get_stops(route):
    cache_string = cache.get(route + "_" + "stops_api_response")
    stops = None
    if cache_string != None:
        stops = json.decode(cache_string)
    if stops == None:
        r = http.get(API_STOPS, params = {"req1": route})
        stops = r.json()
        cache.set(route + "_" + "stops_api_response", json.encode(stops), ttl_seconds = 3600)

    list_of_stops = []

    for i in stops:
        list_of_stops.append(
            schema.Option(
                display = i["stopname"].replace("&amp;", "&") + " (" + i["stopid"] + ")",
                value = i["stopid"],
            ),
        )

    return list_of_stops

def pad_direction_desc(data):
    max_len = 0
    for item in data:
        desc_len = len(item["DirectionDesc"])
        if desc_len > max_len:
            max_len = desc_len

    for item in data:
        desc_len = len(item["DirectionDesc"])
        if desc_len < max_len:
            item["DirectionDesc"] += " " * (max_len - desc_len)

    return data

def call_schedule_api(route, stopid):
    cache_string = cache.get(route + "_" + stopid + "_" + "schedule_api_response")
    schedule = None
    if cache_string != None:
        schedule = json.decode(cache_string)
    if schedule == None:
        r = http.get(API_SCHEDULE, params = {"req1": stopid, "req2": route})
        schedule = r.json()
        parsed_time = time.parse_time(schedule.values()[0][0]["DateCalender"], "01/02/06 3:04 pm", "America/New_York")
        expiry = int((parsed_time - time.now()).seconds)
        if expiry < 0:  #this is because septa's API returns tomorrow's times with today's date if the last departure for the day has already happened
            expiry = 30
        cache.set(route + "_" + stopid + "_" + "schedule_api_response", json.encode(schedule), ttl_seconds = expiry)

    return schedule

def get_schedule(route, stopid):
    schedule = call_schedule_api(route, stopid)
    list_of_departures = []

    if schedule.get(route):
        routes_with_padding = pad_direction_desc(schedule.get(route))
        for i in routes_with_padding:
            if len(list_of_departures) % 2 == 1:
                background = "#222"
                text = "#fff"
            else:
                background = "#000"
                text = "#ffc72c"
            if len(i["date"]) == 5:
                time = " " + i["date"]
            else:
                time = i["date"]
            item = render.Box(
                height = 6,
                width = 64,
                color = background,
                child = render.Row(
                    cross_align = "right",
                    children = [
                        render.Box(
                            width = 25,
                            child = render.Text(
                                time,
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
                            offset_start = 20,
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
            desc = "Select a stop. If a single stop is served by two directions, the same name will be listed twice, with a different stop number for each direction.",
            icon = get_route_icon(route),
            default = DEFAULT_STOP,
            options = get_stops(route),
        ),
    ]

def main(config):
    route = config.str("route", DEFAULT_ROUTE)
    stop = config.str("stop", DEFAULT_STOP)
    user_text = config.str("banner", "")
    schedule = get_schedule(route, stop)
    route_bg_color = get_route_bg_color(route)
    route_text_color = get_route_text_color(route)

    if user_text == "":
        banner_text = route
    else:
        banner_text = user_text

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = route_bg_color),
                            render.Padding(pad = (1, 0, 0, 0), child = render.Text(banner_text, font = "tom-thumb", color = route_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, 2), color = route_bg_color, child = render.Column(children = schedule)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "banner",
                name = "Banner",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
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

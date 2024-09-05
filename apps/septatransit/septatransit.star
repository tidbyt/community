"""
Applet: SEPTA Transit
Summary: SEPTA Transit Departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL in and around Philadelphia.
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
    r = http.get(API_ROUTES, ttl_seconds = 604800)
    routes = r.json()
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
    r = http.get(API_STOPS, params = {"req1": route}, ttl_seconds = 604800)
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

def get_schedule(route, stopid, show_relative_times):
    schedule = call_schedule_api(route, stopid)
    list_of_departures = []
    if schedule.get(route):
        for i in schedule.get(route):
            departure_time = None
            if len(list_of_departures) % 2 == 1:
                background = "#222"
                text = "#fff"
            else:
                background = "#000"
                text = "#ffc72c"

            if show_relative_times:
                departure = time.parse_time(i["DateCalender"], "01/02/06 03:04 pm", "America/New_York")
                departure_time = str(int((departure - time.now()).seconds / 60)) + "m"
                if len(departure_time) == 2:
                    departure_time = "0" + departure_time
            if not show_relative_times:
                if len(i["date"]) == 5:
                    departure_time = " " + i["date"]
                else:
                    departure_time = i["date"]
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
                                departure_time,
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
                            offset_start = 40,
                            offset_end = 40,
                        ),
                    ],
                ),
            )
            list_of_departures.append(item)

    if len(list_of_departures) < 1:
        return [render.Box(
            height = 6,
            width = 64,
            color = "#000",
            child = render.Text("Select a stop"),
        )]
    else:
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
    show_relative_times = config.bool("show_relative_times", False)
    user_text = config.str("banner", "")
    schedule = get_schedule(route, stop, show_relative_times)
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    left_pad = 4

    if config.bool("use_custom_banner_color"):
        route_bg_color = config.str("custom_banner_color")
    else:
        route_bg_color = get_route_bg_color(route)

    if config.bool("use_custom_text_color"):
        route_text_color = config.str("custom_text_color")
    else:
        route_text_color = get_route_text_color(route)

    if user_text == "":
        banner_text = route
    else:
        banner_text = user_text

    if config.bool("show_time"):
        if int(now.format("15")) < 12:
            meridian = "a"
        else:
            meridian = "p"
        banner_text = now.format("3:04") + meridian + " " + banner_text
        if now.format("3") in ["10", "11", "12"]:
            left_pad = 0

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = route_bg_color),
                            render.Padding(pad = (left_pad, 0, 0, 0), child = render.Text(banner_text, font = "tom-thumb", color = route_text_color)),
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
                name = "Custom banner text",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
            schema.Toggle(
                id = "use_custom_banner_color",
                name = "Use custom banner color",
                desc = "Use a custom background color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_banner_color",
                name = "Custom banner color",
                desc = "A custom background color for the top banner.",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Toggle(
                id = "use_custom_text_color",
                name = "Use custom text color",
                desc = "Use a custom text color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_text_color",
                name = "Custom text color",
                desc = "A custom text color for the top banner.",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show time",
                desc = "Show the current time in the top banner.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_relative_times",
                name = "Show relative departure times",
                desc = "Show relative departure times.",
                icon = "clock",
                default = False,
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

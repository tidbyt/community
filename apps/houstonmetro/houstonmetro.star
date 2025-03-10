load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOP = "Ho414_4620_12308"
SUBSCRIPTION_KEY = "da271ffa89c74196b9c9e64efae57100"
METRO_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAAMCAYAAACNzvbFAAAAAXNSR0IArs4c6QAAAE5JREFUOE9jZKABYCRkpm/u5//Y1CxYb4hVq/CTO4x4DSXHQJBNOA0l10CchlJiIF6XEgprfPIY3qfUlRgupYaBtPc+tVwJdyk1DaSZ9wEBvjANhhbdqgAAAABJRU5ErkJggg==
""")

ROUTE_INFO_CACHE_KEY = "routeinfo"
ROUTE_INFO_CACHE_TTL = 604800  #1 Week

ARRIVALS_CACHE_KEY = "arrivals"
ARRIVALS_CACHE_TTL = 60  # 1 minute

def main(config):
    stop_id = config.get("station_id", DEFAULT_STOP)
    time_toggle = config.get("time", DEFAULT_STOP)

    render_elements = []
    if SUBSCRIPTION_KEY:
        endpoint = "https://api.ridemetro.org/data/Stops('" + stop_id + "')?subscription-key=" + SUBSCRIPTION_KEY
        response = http.get(endpoint, ttl_seconds = ROUTE_INFO_CACHE_TTL).body()

        stop_name = json.decode(response)["value"][0]["Name"]

        arrivals_endpoint = "https://api.ridemetro.org/data/Stops('" + stop_id + "')/Arrivals?subscription-key=" + SUBSCRIPTION_KEY
        response = http.get(arrivals_endpoint, ttl_seconds = ARRIVALS_CACHE_TTL).body()

        arrivals = json.decode(response)["value"]
        if not arrivals:
            render_elements.append(
                render.Row(
                    children = [
                        render.Box(
                            color = "#0000",
                            child = render.Text("No arrivals", color = "#f3ab3f"),
                        ),
                    ],
                ),
            )
        else:
            for i in range(0, 4):
                if i < len(arrivals):
                    route_number = arrivals[i]["RouteName"]
                    arrival_time = arrivals[i]["LocalArrivalTime"]
                    direction = arrivals[i]["DestinationName"]
                    arrival_time = time_string(arrival_time, time_toggle)
                    route_color = "004080"
                    render_element = render.Row(
                        children = [
                            render.Stack(children = [
                                render.Box(
                                    color = "#" + route_color,
                                    width = 30,
                                    height = 10,
                                ),
                                render.Box(
                                    color = "#0000",
                                    width = 30,
                                    height = 10,
                                    child = render.Text(route_number + " " + direction[0], color = "#000", font = "CG-pixel-4x5-mono"),
                                ),
                            ]),
                            render.Column(
                                children = [
                                    render.Text(" " + arrival_time, color = "#f3ab3f"),
                                ],
                            ),
                        ],
                        main_align = "center",
                        cross_align = "center",
                    )
                    render_elements.append(render_element)
    else:
        stop_name = "Houston Metro"
        render_elements.append(
            render.Row(
                children = [
                    render.Box(
                        color = "#0000",
                        child = render.Text("No API Key", color = "#f3ab3f"),
                    ),
                ],
            ),
        )

    #Create animation frames of the stop info
    animation_children = []
    if len(render_elements) == 1:
        frame_1 = render.Column(
            children = [
                render_elements[0],
            ],
        )
        for i in range(0, 160):
            animation_children.append(frame_1)
    if len(render_elements) == 2:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        for i in range(0, 160):
            animation_children.append(frame_1)
    if len(render_elements) == 3:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        frame_2 = render.Column(
            children = [
                render_elements[2],
            ],
        )
        for i in range(0, 160):
            if i <= 80:
                animation_children.append(frame_1)
            else:
                animation_children.append(frame_2)
    if len(render_elements) == 4:
        frame_1 = render.Column(
            children = [
                render_elements[0],
                render_elements[1],
            ],
        )
        frame_2 = render.Column(
            children = [
                render_elements[2],
                render_elements[3],
            ],
        )
        for i in range(0, 160):
            if i <= 80:
                animation_children.append(frame_1)
            else:
                animation_children.append(frame_2)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(
                            src = METRO_ICON,
                        ),
                        render.Marquee(
                            child =
                                render.Text(
                                    stop_name,
                                    font = "tb-8",
                                    height = 12,
                                ),
                            align = "center",
                            width = 45,
                            offset_start = 5,
                            offset_end = 32,
                        ),
                    ],
                ),
                render.Sequence(
                    children = [
                        render.Animation(
                            children = animation_children,
                        ),
                    ],
                ),
            ],
        ),
    )

def time_string(full_string, time_toggle):
    time_index = full_string.find("T")
    hours = full_string[time_index + 1:len(full_string) - 7]
    minutes = full_string[len(full_string) - 6:len(full_string) - 4]
    if time_toggle.lower() == "false" and int(hours) > 12:
        hours = int(hours) - 12
    return str(hours) + ":" + minutes

def truncate_location(full_string):
    decimal_index = full_string.find(".")
    return full_string[0:decimal_index + 3]

def get_stations(location):
    loc = json.decode(location)
    coordinates = truncate_location(str(loc["lat"])) + "|" + truncate_location(str(loc["lng"]))
    key = SUBSCRIPTION_KEY
    stops = []
    if key:
        location_endpoint = "https://houstonmetro.azure-api.net/data/GeoAreas('" + coordinates + "|.5')/Stops?subscription-key=" + SUBSCRIPTION_KEY
        response = http.get(location_endpoint, ttl_seconds = ROUTE_INFO_CACHE_TTL)

        if response.json()["value"]:
            for station in response.json()["value"]:
                stops.append(
                    schema.Option(
                        display = station["Name"],
                        value = station["StopId"],
                    ),
                )
    return stops

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station_id",
                name = "Bus/Train Station",
                desc = "A list of bus or train stations based on a location.",
                icon = "train",
                handler = get_stations,
            ),
            schema.Toggle(
                id = "time",
                name = "24-hour time",
                desc = "A toggle to display 24-hour time.",
                icon = "clock",
                default = False,
            ),
        ],
    )

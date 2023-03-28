load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_STOP = "Ho414_4620_12308"
SUBSCRIPTION_KEY = secret.decrypt("AV6+xWcEAT8EFKRWZcQqp3v/Vl4dIDmiVHqKDI9bXmDF7LrW9KONSxvItRWb11RLq4e2jcY0GZBhh+FLotzQS2V6S4BiUSKQytzBddyo+oiKBS3r/4i3w/feoUbD1d6RqAv0gq1b24Oq0SdcTFn9i7qlrPHMsQ3w+TssQuDnf+UHY4hx7aY=")
METRO_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAAMCAYAAACNzvbFAAAAAXNSR0IArs4c6QAAAE5JREFUOE9jZKABYCRkpm/u5//Y1CxYb4hVq/CTO4x4DSXHQJBNOA0l10CchlJiIF6XEgprfPIY3qfUlRgupYaBtPc+tVwJdyk1DaSZ9wEBvjANhhbdqgAAAABJRU5ErkJggg==
""")

ROUTE_INFO_CACHE_KEY = "routeinfo"
ROUTE_INFO_CACHE_TTL = 604800  #1 Week

ARRIVALS_CACHE_KEY = "arrivals"
ARRIVALS_CACHE_TTL = 60  # 1 minute

def main(config):
    stop_id = config.get("station_id", DEFAULT_STOP)

    key = SUBSCRIPTION_KEY or config.get("key", None)

    station_cache = cache.get(ROUTE_INFO_CACHE_KEY + stop_id)
    if station_cache:
        response = station_cache
    else:
        endpoint = "https://api.ridemetro.org/data/Stops('" + stop_id + "')?subscription-key=" + key
        response = http.get(endpoint)
        cache.set(ROUTE_INFO_CACHE_KEY + stop_id, response.body(), ROUTE_INFO_CACHE_TTL)
    stops = response.json()["value"]
    stop_name = response.json()["value"][0]["Name"]
    render_elements = []

    arrivals_cache = cache.get(ARRIVALS_CACHE_KEY + stop_id)
    if arrivals_cache:
        response = arrivals_cache
    else:
        arrivals_endpoint = "https://api.ridemetro.org/data/Stops('" + stop_id + "')/Arrivals?subscription-key=" + key
        response = http.get(arrivals_endpoint)
        cache.set(ARRIVALS_CACHE_KEY + stop_id, response.body(), ARRIVALS_CACHE_TTL)

    stops = response.json()["value"]
    if not stops:
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
            if i < len(stops):
                route_number = stops[i]["RouteName"]
                arrival_time = stops[i]["LocalArrivalTime"]
                arrival_time = time_string(arrival_time)
                route_color = "004080"
                render_element = render.Row(
                    children = [
                        render.Stack(children = [
                            render.Box(
                                color = "#" + route_color,
                                width = 22,
                                height = 10,
                            ),
                            render.Box(
                                color = "#0000",
                                width = 22,
                                height = 10,
                                child = render.Text(route_number, color = "#000", font = "CG-pixel-4x5-mono"),
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

def time_string(full_string):
    time_index = full_string.find("T")
    return full_string[time_index + 1:len(full_string) - 4]

def truncate_location(full_string):
    decimal_index = full_string.find(".")
    return full_string[0:decimal_index + 3]

def get_stations(location):
    loc = json.decode(location)
    coordinates = truncate_location(str(loc["lat"])) + "|" + truncate_location(str(loc["lng"]))
    key = SUBSCRIPTION_KEY or ""
    location_cache = cache.get(ROUTE_INFO_CACHE_KEY + coordinates)
    if location_cache:
        response = location_cache
    else:
        location_endpoint = "https://houstonmetro.azure-api.net/data/GeoAreas('" + coordinates + "|.5')/Stops?subscription-key=" + key
        response = http.get(location_endpoint)
        cache.set(ROUTE_INFO_CACHE_KEY + coordinates, response.body(), ROUTE_INFO_CACHE_TTL)
    stops = []
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
        ],
    )

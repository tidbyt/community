"""
Applet: ViP Abfahrten
Summary: Tram departures in Potsdam
Description: Shows departures of public transportation service in Potsdam, Germany.
Author: ChaosKid42
"""

load("bsoup.star", "bsoup")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

ORANGE = "#FFA500"
WHITE = "#FFFFFF"
RED = "#FF0000"
GREEN = "#0AE300"
FONT = "tom-thumb"
TTL_CACHE_LENGTH_SECONDS = 60

SWP_LOOKUP_URL = "https://www.swp-potsdam.de/internetservice/services/lookup/autocomplete/json?query={}"
SWP_PASSAGEINFO_URL = "https://www.swp-potsdam.de/internetservice/services/passageInfo/stopPassages/stop?mode=departure&stop={}"

def main(config):
    stop = config.str("stop", '{"value":"423"}')  # Default is Potsdam Hbf
    direction = config.str("direction", "")
    route = config.str("route", "")

    if len(stop) == 0:
        return render.Root(
            child = render.Box(
                child = render.WrappedText("No station selected"),
            ),
        )

    stop_id = json.decode(stop)["value"]

    queryString = SWP_PASSAGEINFO_URL.format(humanize.url_encode(stop_id))

    if len(direction) > 0 and direction != "all":
        queryString += "&direction={}".format(humanize.url_encode(direction))

    if len(route) > 0 and route != "0":
        queryString += "&routeId={}".format(humanize.url_encode(route))

    resp = http.get(queryString, ttl_seconds = TTL_CACHE_LENGTH_SECONDS)

    if resp.status_code != 200:
        fail("request to {} failed with status code: {} - {}".format(queryString, resp.status_code, resp.body()))

    stopName = resp.json()["stopName"]
    routes = process_routes(resp.json()["routes"])
    departures = process_departures(resp.json()["actual"], routes)
    return get_root_element(departures, stopName)

def process_routes(routes):
    result = dict()
    for route in routes:
        result[route["id"]] = route["name"]
    return result

def process_departures(departures, routes):
    result = list()
    for departure in departures:
        if departure["actualRelativeTime"] < 0:
            continue
        departure["direction"] = departure["direction"].replace(" ", "\u2022")
        departure["routeName"] = routes[departure["routeId"]]
        departure["timeText"] = str(math.floor(departure["actualRelativeTime"] / 60)) + "m"
        departure["timeColor"] = ORANGE if departure["actualRelativeTime"] < 300 else GREEN
        result.append(departure)
    return result

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "stop",
                name = "Stop",
                desc = "Train stop to watch.",
                icon = "train",
                handler = get_stops,
            ),
            schema.Generated(
                id = "generated",
                source = "stop",
                handler = more_options,
            ),
        ],
    )

def get_stops(pattern):
    found_stops = []

    resp = http.get(SWP_LOOKUP_URL.format(humanize.url_encode(pattern)), ttl_seconds = TTL_CACHE_LENGTH_SECONDS)
    if resp.status_code != 200:
        return found_stops

    stops_json = resp.json()
    if len(stops_json) < 2:
        return found_stops

    for stop in stops_json:
        if stop["type"] == "stop":
            option = schema.Option(
                display = bsoup.parseHtml(stop["name"]).contents()[1].get_text(),
                value = stop["id"],
            )
            found_stops.append(option)

    return found_stops

def more_options(stop):
    if stop:
        stop_id = json.decode(stop)["value"]
        direction_options = get_direction_options(stop_id)
        routes_options = get_routes_options(stop_id)
        return [
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Only show departures going this direction.",
                icon = "compass",
                default = direction_options[0].value,
                options = direction_options,
            ),
            schema.Dropdown(
                id = "route",
                name = "Route",
                desc = "Only show departures on this route.",
                icon = "compass",
                default = routes_options[0].value,
                options = routes_options,
            ),
        ]
    else:
        return []

def get_direction_options(stop_id):
    found_directions = list()
    resp = http.get(SWP_PASSAGEINFO_URL.format(humanize.url_encode(stop_id)), ttl_seconds = TTL_CACHE_LENGTH_SECONDS)
    if resp.status_code == 200:
        routes_json = resp.json()["routes"]
        for route in routes_json:
            directions_json = route["directions"]
            for direction in directions_json:
                if not direction in found_directions:
                    found_directions.append(direction)

    found_directions = sorted(found_directions)
    found_directions.insert(0, "all")
    direction_options = [
        schema.Option(
            display = direction,
            value = direction,
        )
        for direction in found_directions
    ]

    return direction_options

def get_routes_options(stop_id):
    routes_options = [
        schema.Option(
            display = "all",
            value = "0",
        ),
    ]
    resp = http.get(SWP_PASSAGEINFO_URL.format(humanize.url_encode(stop_id)), ttl_seconds = TTL_CACHE_LENGTH_SECONDS)
    if resp.status_code == 200:
        routes_json = resp.json()["routes"]
        for route in routes_json:
            routes_options.append(
                schema.Option(
                    display = route["name"],
                    value = route["id"],
                ),
            )
    return routes_options

# The following rendering code is mostly "borrowed" from https://github.com/tidbyt/community/blob/main/apps/berlintransit/berlin_transit.star

#RENDERING FUNCTIONS
MAX_DEPATURES_PER_FRAME = 4  #maximum number of departures to display per frame
FRAME_DURATION = 120  #duration of each frame in the animation

#Renders the root element for the app
#departures: the list of departures to render
#station_name: the name of the station to render
def get_root_element(departures, station_name):
    return render.Root(
        max_age = 120,
        delay = 25,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    child = render.Padding(
                        pad = (1, 1, 1, 0),
                        child = render.Column(
                            children = [
                                #Marquee to be safe - should be limited to 15 characters
                                render.Marquee(
                                    width = 62,
                                    align = "center",
                                    child = render.Text(
                                        content = station_name,
                                        font = FONT,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                render_departures(departures),
            ],
        ),
    )

#Renders the departures for a station. Rotates through sets of four rows at a time
#departures: the list of departures to render
def render_departures(departures):
    if len(departures) == 0:  #Show no
        return render.Box(
            width = 64,
            child = render.WrappedText(
                content = "No departures found",
                width = 62,
                align = "center",
                color = ORANGE,
                font = FONT,
            ),
        )

    frames = []
    for i in range(0, len(departures), MAX_DEPATURES_PER_FRAME):
        frame = render_departures_frame(departures[i:i + MAX_DEPATURES_PER_FRAME])
        frames.extend([frame] * FRAME_DURATION)
    return render.Animation(
        children = frames,
    )

#Add a a row of text for each departure
#departures: the list of departures to render
def render_departures_frame(departures):
    return render.Column(
        main_align = "space_evenly",
        expanded = True,
        children = [
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.WrappedText(
                            content = departure["routeName"],
                            color = RED,
                            font = FONT,
                            width = 16,
                            height = 6,
                            align = "left",
                        ),
                        render.WrappedText(
                            content = departure["direction"],
                            font = FONT,
                            width = 32,
                            height = 6,
                            align = "left",
                        ),
                        render.WrappedText(
                            content = departure["timeText"],
                            color = departure["timeColor"],
                            font = FONT,
                            width = 12,
                            height = 6,
                            align = "right",
                        ),
                    ],
                ),
            )
            for departure in departures
        ],
    )

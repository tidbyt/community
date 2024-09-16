"""
Applet: CTA Bus Tracker
Summary: CTA Bus arrival times
Description: View CTA Bus arrival times for the closest stop to your location.
Author: John Sylvain
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_LOCATION = """
{
	"lat": "41.969082",
	"lng": "-87.659828",
	"description": "Chicago, IL, USA",
	"locality": "Chicago",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/Chicago"
}
"""

DEFAULT_ROUTE = "36"

ENCRYPTED_API_KEY = "AV6+xWcEAmKCn23NmgtZCEM5GyvmBk8mOiDwqZHoN8MeNwBQU8TXhaKmoOy0quXZkYL5venMc80y9zvKGr3vabQ3y93W7F1PBT4FHp9INXOzakv4r+JViX9oJBzZOS7cuWfLSS7fFUixVVXRKUfcRdgz/8fzUoASfvqOyGhudA=="

def get_schema():
    options = get_bus_route_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "route",
                name = "Bus Route",
                desc = "The CTA Bus Route to get departure schedule for.",
                icon = "bus",
                default = options[0].value,
                options = options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Current location for closest bus stop.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide when no service",
                desc = "Hide when no service is scheduled for the selected route.",
                icon = "eye",
                default = True,
            ),
            # schema.Text(
            #     id = "dev_api_key",
            #     name = "CTA API Key",
            #     desc = "For local debugging",
            #     icon = "key",
            # ),
        ],
    )

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("dev_api_key")
    route = config.get("route", DEFAULT_ROUTE)
    hide = config.bool("hide", True)
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    directions = get_bus_route_directions(route, api_key) or []

    stops = [get_nearest_stop(route, direction["dir"], loc, api_key) for direction in directions]

    potential_arrivals = [get_arrivals(route, stop, api_key) for stop in stops]

    arrivals = []

    for arrival in potential_arrivals:
        if arrival != None:
            arrivals.append(arrival)

    if len(arrivals) == 2:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render_arrival(arrivals[0]),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                    render_arrival(arrivals[1]),
                ],
            ),
        )
    elif len(arrivals) == 1:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render_arrival(arrivals[0]),
                ],
            ),
        )
    elif hide:
        print("no arrival [hide]")
        return []
    else:
        print("no arrival [show]")
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render_no_arrival(route, api_key),
                ],
            ),
        )

######################
# Build Config options
######################
def get_bus_route_options():
    api_key = secret.decrypt(ENCRYPTED_API_KEY)

    if not api_key:
        return [
            schema.Option(
                display = "No Routes Available",
                value = "No Routes Available",
            ),
        ]

    routes = get_bus_routes(api_key)

    options = [
        schema.Option(
            display = route["route"] + " - " + route["name"],
            value = route["route"],
        )
        for route in routes
    ]
    return options

######################
# Utility methods
######################
def get_distance(lat1, lon1, lat2, lon2):
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    earth_radius = 6371.0

    dlon = lon2_rad - lon1_rad
    dlat = lat2_rad - lat1_rad
    a = math.sin(dlat / 2) * math.sin(dlat / 2) + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) * math.sin(dlon / 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = earth_radius * c

    return distance

######################
# API Calls
######################
def get_nearest_stop(route, direction, current_location, api_key):
    if not api_key:
        return None

    response = http.get(
        "https://ctabustracker.com/bustime/api/v2/getstops",
        params = {
            "key": api_key,
            "format": "json",
            "rt": route,
            "dir": direction,
        },
        ttl_seconds = 3600,
    )

    stops = response.json()["bustime-response"]["stops"]

    shortest_distance = 0.0
    nearest_stop = {}

    for stop in stops:
        distance_from_user_to_stop = get_distance(
            float(stop["lat"]),
            float(stop["lon"]),
            float(current_location["lat"]),
            float(current_location["lng"]),
        )
        if distance_from_user_to_stop < shortest_distance or shortest_distance == 0.0:
            shortest_distance = distance_from_user_to_stop
            nearest_stop = stop

    return nearest_stop

def build_route_arrival_time(arrival):
    time = arrival["prdctdn"]

    if time != "DUE" and time != "DLY":
        return time + "m"
    elif time == "DUE":
        return "Due"
    elif time == "DLY":
        return "Delay"
    else:
        return time

def get_arrivals(route, nearest_stop, api_key):
    full_route = get_bus_route(route, api_key)

    if not api_key:
        return None

    response = http.get(
        "https://ctabustracker.com/bustime/api/v2/getpredictions",
        ttl_seconds = 10,
        params = {
            "key": api_key,
            "format": "json",
            "rt": route,
            "stpid": nearest_stop["stpid"],
            "top": "2",
        },
    )

    arrivals = response.json()["bustime-response"]

    if "error" in arrivals:
        return None

    times = [build_route_arrival_time(arrival) for arrival in arrivals["prd"]]

    return {
        "destination": arrivals["prd"][0]["des"],
        "times": times,
        "route": arrivals["prd"][0]["rt"],
        "route_color": full_route["color"],
    }

def get_bus_route(route, api_key):
    routes = get_bus_routes(api_key)

    route_map = {}

    for rt in routes:
        route_map[rt["route"]] = rt

    return route_map[route]

def build_route(route):
    return {
        "route": route["rt"],
        "name": route["rtnm"],
        "color": route["rtclr"],
    }

def get_bus_routes(api_key):
    if not api_key:
        return None

    response = http.get(
        "https://ctabustracker.com/bustime/api/v2/getroutes",
        params = {
            "key": api_key,
            "format": "json",
        },
        ttl_seconds = 3600,
    )
    data = response.json()["bustime-response"]["routes"]
    routes = [build_route(route) for route in data]
    return routes

def get_bus_route_directions(route, api_key):
    if not api_key:
        return None

    response = http.get(
        "https://ctabustracker.com/bustime/api/v2/getdirections",
        params = {
            "rt": route,
            "key": api_key,
            "format": "json",
        },
        ttl_seconds = 3600,
    )
    data = response.json()["bustime-response"]["directions"]
    return data

######################
# Render methods
######################
def render_no_arrival(route, api_key):
    full_route = get_bus_route(route, api_key)

    background_color = render.Box(
        width = 22,
        height = 11,
        color = full_route["color"],
    )

    stack = render.Stack(
        children = [
            background_color,
            render.Box(
                color = "#0000",
                width = 22,
                height = 11,
                child = render.Text(full_route["route"], color = "#000", font = "CG-pixel-4x5-mono"),
            ),
        ],
    )

    column = render.Marquee(
        width = 40,
        child = render.Text("No service scheduled.", color = "#666", height = 7),
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )

def render_arrival(arrival):
    background_color = render.Box(
        width = 22,
        height = 11,
        color = arrival["route_color"],
    )
    destination_text = render.Marquee(
        width = 40,
        child = render.Text(arrival["destination"], font = "CG-pixel-3x5-mono", height = 7),
    )

    arrival_in_text = render.Marquee(
        width = 40,
        child = render.Text(", ".join(arrival["times"]), color = "#f3ab3f", font = "tb-8"),
    )

    stack = render.Stack(
        children = [
            background_color,
            render.Box(
                color = "#0000",
                width = 22,
                height = 11,
                child = render.Text(arrival["route"], color = "#000", font = "CG-pixel-4x5-mono"),
            ),
        ],
    )

    column = render.Column(
        children = [
            destination_text,
            arrival_in_text,
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )

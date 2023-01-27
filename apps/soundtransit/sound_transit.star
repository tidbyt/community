"""
Applet: Sound Transit
Summary: Seattle light rail times
Description: Shows upcoming arrivals at up to 2 different stations in Sound Transit's Link light rail system in Seattle.
Author: Jon Janzen
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# Some TidByt APIs require strings, but we want to use `None` values.
# ref `none_str_to_none_val`
NONE_STR = "__NONE__"

# The original author lived in Capitol Hill at the time of writing:
STATION1_DEFAULT = "1_99603"  # Capitol Hill N
STATION2_DEFAULT = "1_99610"  # Capitol Hill S

SHOULD_SCROLL_DEFAULT = True

OBA_API_KEY = "AV6+xWcEgoOwrT7F9D7wuFANkebxqNEplpDY8H1qAovw1nQ4D2b0y1LFhRFQmZWuwAln4X66KhxOpPoiAcBF20GbQGRb2c5VxFAJgvnfKwjfqemHQpz1vRnp5nGr3W6ay3e0i5KLYjRBLaV+w2dzylnZKfxHU5iynoKyAJ7k8lTblifTAC/BloDO"

def none_str_to_none_val(maybe_none_str):
    if maybe_none_str == NONE_STR:
        return None
    return maybe_none_str

now = time.now().unix

def get_api_token():
    # "TEST" API key seems to work, but only use this as fallback
    return secret.decrypt(OBA_API_KEY) or "TEST"

def get_stop_data(stop_id):
    cache_key = "stop:" + stop_id
    rep = cache.get(cache_key)
    if not rep:
        rep = http.get("https://api.pugetsound.onebusaway.org/api/where/schedule-for-stop/" + stop_id + ".json?key=" + get_api_token())
        if rep.status_code != 200:
            fail("Could not access OBA")
        rep = rep.body()
        cache.set(cache_key, rep)
    data = json.decode(rep)["data"]

    routes = {route["id"]: route for route in data["references"]["routes"]}

    result_data = []

    for route_schedule in data["entry"]["stopRouteSchedules"]:
        route = routes[route_schedule["routeId"]]

        for direction_schedule in route_schedule["stopRouteDirectionSchedules"]:
            next_stop_times = []
            for stop_time in direction_schedule["scheduleStopTimes"]:
                arrival_time_from_now = int((stop_time["arrivalTime"] / 1000 - now) / 60)

                if arrival_time_from_now < 0:
                    continue

                next_stop_times.append(str(arrival_time_from_now))

                if len(next_stop_times) >= 4:
                    break

            result_data.append(
                struct(
                    route = struct(
                        color = "#" + route["color"] if len(route["color"]) > 0 else "#000",
                        name = route["shortName"][0],
                    ),
                    headsign = direction_schedule["tripHeadsign"],
                    times = ",".join(next_stop_times),
                ),
            )

    return result_data

def show_stops(stop_id1, stop_id2, scroll_names):
    stop1_data = get_stop_data(stop_id1)
    stop2_data = get_stop_data(stop_id2) if stop_id2 != None else []

    max_length = 0
    route_count = 0

    if scroll_names:
        for stop in stop1_data + stop2_data:
            stop_len = len(stop.headsign)
            if stop_len > max_length:
                max_length = stop_len
    else:
        max_length = 9

    for stop in [stop1_data, stop2_data]:
        if len(stop) > route_count:
            route_count = len(stop)

    sequence_children = []

    for stop_data in [stop1_data, stop2_data]:
        stop_row = []
        for stop in stop_data:
            stop_headsign = stop.headsign
            for _ in range(max_length - len(stop.headsign)):
                stop_headsign += " "

            for _ in range(len(stop.headsign) - max_length):
                stop_headsign = stop_headsign.removesuffix(stop_headsign[-1])

            stop_row.append(render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Padding(
                        child = render.Circle(
                            color = stop.route.color,
                            diameter = 13,
                            child = render.Text(stop.route.name),
                        ),
                        pad = (1, 1, 0, 0),
                    ),
                    render.Padding(
                        child = render.Column(
                            children = [
                                render.Marquee(width = 64 - 16, child = render.Text(stop_headsign, font = "CG-pixel-4x5-mono")),
                                render.Text(stop.times, color = "#B84"),
                            ],
                        ),
                        pad = (1, 2, 0, 0),
                    ),
                ],
            ))

        if len(stop_row) < route_count and len(stop_row) >= 1:
            stop_row.append(stop_row[-1])

        sequence_children.append(render.Sequence(children = stop_row))

    return render.Column(children = [
        sequence_children[0],
        render.Box(color = "#444", height = 1),
        sequence_children[1],
    ])

def main(config):
    scroll_names = config.bool("scroll_names", SHOULD_SCROLL_DEFAULT)
    station1 = none_str_to_none_val(config.get("station1", STATION1_DEFAULT))
    station2 = none_str_to_none_val(config.get("station2", STATION2_DEFAULT))

    return render.Root(
        child = show_stops(station1, station2, scroll_names),
        delay = 0 if scroll_names else 5 * 1000,
    )

def stop_options_for_route(route_id):
    cache_key = "stations:" + route_id
    rep = cache.get(cache_key)
    if not rep:
        rep = http.get("https://api.pugetsound.onebusaway.org/api/where/stops-for-route/" + route_id + ".json?key=" + get_api_token())
        if rep.status_code != 200:
            fail("Could not access OBA")
        rep = rep.body()
        cache.set(cache_key, rep)
    data = json.decode(rep)["data"]

    def full_name(stop):
        return stop["name"] + " " + stop["direction"]

    stops = sorted(data["references"]["stops"], key = full_name)

    return [
        schema.Option(display = full_name(stop), value = stop["id"])
        for stop in stops
    ]

def light_rail_routes():
    cache_key = "routes"
    rep = cache.get(cache_key)
    if not rep:
        # "40" is Sound Transit, the light rail operator in the Puget Sound
        rep = http.get("https://api.pugetsound.onebusaway.org/api/where/routes-for-agency/40.json?key=" + get_api_token())
        if rep.status_code != 200:
            fail("Could not access OBA")
        rep = rep.body()
        cache.set(cache_key, rep)
    data = json.decode(rep)["data"]

    routes = []
    for route in data["list"]:
        # "0" = light rail, ref "route_type" here: https://developers.google.com/transit/gtfs/reference#routestxt
        if route["type"] == 0:
            routes.append(route)
    return routes

def all_station_options():
    stops = []
    for route in light_rail_routes():
        stops.extend(stop_options_for_route(route["id"]))

    return stops + [schema.Option(display = "None", value = NONE_STR)]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station1",
                name = "Top station",
                desc = "The first station to show",
                icon = "arrowDown",
                options = all_station_options(),
                default = STATION1_DEFAULT,
            ),
            schema.Dropdown(
                id = "station2",
                name = "Bottom station",
                desc = "The second station to show",
                icon = "arrowDown",
                options = all_station_options(),
                default = STATION2_DEFAULT,
            ),
            schema.Toggle(
                id = "scroll_names",
                name = "Scroll names",
                desc = "Scroll the stop names if they're too long to fit on screen",
                icon = "scissors",
                default = SHOULD_SCROLL_DEFAULT,
            ),
        ],
    )

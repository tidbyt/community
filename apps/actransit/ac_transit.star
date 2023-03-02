"""
Applet: AC Transit
Summary: Shows AC Transit bus times
Description: Shows bus departures times for AC Transit.
Author: wshue0
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

PREDICTIONS_URL = "https://api.actransit.org/transit/actrealtime/prediction"
DEFAULT_STOPID = "55652"
ENCRYPTED_API_KEY = "AV6+xWcEDY5Xci/kB/yzNYe8qYIkBe5mIA+4b1zr8VkqNbw2s3n4GXdztkwK9oZKJPGEZjmh9mOCfilqaL32hQiru6Vvm410hXK4oP7Sc0Jq7mglM7KZ3LBS26o8hCR+LqY/uafNPbJUUgiR/vSVeQASBnwtaIkQ7TkaG6pUno2bkkpfXns="
LIST_STOPS_URL = "https://api.actransit.org/transit/stops"
AC_TRANSIT_TIME_ZONE = "America/Los_Angeles"
AC_TRANSIT_TIME_LAYOUT = "20060102 15:04"

def main(config):
    # Initialize API token, bus stop, and max predictions number with fallbacks
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("api_key")

    stop_id = config.get("stop_id")
    if stop_id == None:
        stop_id = DEFAULT_STOPID
    else:
        stop_id = json.decode(stop_id)["value"]

    predictions_max = config.get("predictions_max")
    if predictions_max == None:
        predictions_max = 2
    else:
        predictions_max = json.decode(config.get("predictions_max"))

    # Call API to get predictions for the given stop
    data = get_times(stop_id, api_key)
    if "bustime-response" not in data or "prd" not in data["bustime-response"]:
        predictions = []
    else:
        predictions = data["bustime-response"]["prd"]

    num_predictions = len(predictions)
    bus_entries = {}

    # Create dictionary entry for each unique bus route
    # An entry contains a bus name (usually a number), route (a locale), and an array of departure times in minutes
    for i in range(0, num_predictions):
        diff = time_from_now(predictions[i]["prdtm"])
        bus = predictions[i]["rtdd"]
        route = predictions[i]["rtdir"]
        route_key = bus + route
        if not route_key in bus_entries:
            bus_entries[route_key] = {"bus": bus, "route": route, "departures": [diff]}
        else:
            bus_entries[route_key]["departures"].append(diff)

    # Limit to 4 entries
    bus_entries = sorted(bus_entries.values(), key = lambda x: x["bus"])[:4]

    num_routes = len(bus_entries)

    # Display "No Data" when no predictions are available
    if num_routes == 0:
        return render.Root(
            child = render.Box(
                child = render.Text("No Data", font = "6x13", color = "#fff"),
            ),
        )
        # Display a single entry that takes up the screen

    elif num_routes == 1:
        return render.Root(
            delay = 60,
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Row(
                            main_align = "start",
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Box(
                                    height = 16,
                                    width = 1,
                                ),
                                render.Box(
                                    height = 16,
                                    width = 16,
                                    child = render.Text(bus_entries[0]["bus"], color = "#fff"),
                                    color = "#006747",
                                ),
                                render.Box(
                                    height = 16,
                                    width = 1,
                                ),
                                render.Marquee(
                                    width = 64,
                                    align = "start",
                                    offset_start = 5,
                                    offset_end = 8,
                                    child = render.Text(bus_entries[0]["route"], font = "6x13"),
                                ),
                            ],
                        ),
                        render.Box(
                            height = 10,
                            width = 64,
                            child = render.Text(get_displayed_times(bus_entries[0]["departures"], predictions_max), color = "ffb033"),
                        ),
                    ],
                ),
            ),
        )
        # Display two bus entries that each take up half the screen

    elif num_routes == 2:
        entry1 = render.Box(
            width = 64,
            height = 16,
            child = render.Row(
                main_align = "start",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(
                        height = 16,
                        width = 1,
                    ),
                    render.Box(
                        height = 11,
                        width = 12,
                        child = render.Text(bus_entries[0]["bus"], color = "#fff"),
                        color = "#006747",
                    ),
                    render.Box(
                        height = 12,
                        width = 2,
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = 64,
                                align = "start",
                                offset_start = 5,
                                offset_end = 8,
                                child = render.Text(bus_entries[0]["route"]),
                            ),
                            render.Text(get_displayed_times(bus_entries[0]["departures"], predictions_max), font = "5x8", offset = 1, color = "FFB033"),
                        ],
                    ),
                ],
            ),
        )
        entry2 = render.Box(
            width = 64,
            height = 16,
            child = render.Row(
                main_align = "start",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(
                        height = 16,
                        width = 1,
                    ),
                    render.Box(
                        height = 11,
                        width = 12,
                        child = render.Text(bus_entries[1]["bus"], color = "#fff"),
                        color = "#006747",
                    ),
                    render.Box(
                        height = 12,
                        width = 2,
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = 64,
                                align = "start",
                                offset_start = 5,
                                offset_end = 8,
                                child = render.Text(bus_entries[1]["route"]),
                            ),
                            render.Text(get_displayed_times(bus_entries[1]["departures"], predictions_max), font = "5x8", offset = 1, color = "FFB033"),
                        ],
                    ),
                ],
            ),
        )
        return render.Root(
            delay = 120,
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        entry1,
                        render.Box(
                            height = 1,
                            width = 62,
                            color = "#fff",
                        ),
                        entry2,
                    ],
                ),
            ),
        )
        # Display 3-4 bus entries that are evenly-spaced vertically

    else:
        bus_rows = []
        for entry in bus_entries:
            bus = entry["bus"]
            route = entry["route"]
            departures = get_displayed_times(entry["departures"], predictions_max)
            bus_rows.append(
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 8,
                            width = 2,
                        ),
                        render.Box(
                            height = 6,
                            width = 12,
                            color = "#006747",
                            child = render.Text(bus),
                        ),
                        render.Box(
                            height = 8,
                            width = 2,
                        ),
                        render.Text(departures, color = "#ffb033"),
                    ],
                ),
            )

        return render.Root(
            delay = 100,
            child = render.Box(
                height = 32,
                width = 64,
                child = render.Column(
                    main_align = "space_between",
                    cross_align = "start",
                    expanded = True,
                    children = bus_rows,
                ),
            ),
        )

def distance(stop, location):
    # Distance metric for sorting stops
    return math.pow(stop["Latitude"] - float(location["lat"]), 2) + math.pow(stop["Longitude"] - float(location["lng"]), 2)

def time_from_now(ac_timestamp):
    # Calculates an ETA in minutes using the AC Transit timestamp
    now = time.now().in_location(AC_TRANSIT_TIME_ZONE)
    eta_time = time.parse_time(ac_timestamp, AC_TRANSIT_TIME_LAYOUT, AC_TRANSIT_TIME_ZONE)
    diff = eta_time - now
    return int(diff.minutes)

def get_displayed_times(times, predictions_max):
    # Transforms list of departures times in integers to a comma-delimited string
    # Additionally substitutes "0 min" with "now"
    sorted(times, lambda t: t)
    times = times[:predictions_max]
    if len(times) == 1 and times[0] == 0:
        return "now"
    times = [str(t) if t != 0 else "now" for t in times]
    return "%s min" % ",".join(times)

def get_stops(location):
    # Hits the AC Transit API to get a list of all stops and then returns the 20 nearest based on location
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or "390A953479513D55007D63462A08C068"
    loc = json.decode(location)

    res = http.get(
        LIST_STOPS_URL,
        params = {
            "token": api_key,
        },
    )
    if res.status_code != 200:
        fail("AC Transit request failed with status %d", res.status_code)

    stops = res.json()
    return [
        schema.Option(display = stop["Name"], value = str(int(stop["StopId"])))
        for stop in sorted(stops, key = lambda x: distance(x, loc))[:20]
    ]

def get_times(stop_id, api_key):
    # Hits AC Transit's prediction api if there are no cache hits
    cached = cache.get(stop_id)
    if cached:
        return json.decode(cached)
    rep = http.get(PREDICTIONS_URL, params = {"stpid": stop_id, "token": api_key})
    if rep.status_code != 200:
        fail("Predictions request failed with status ", rep.status_code)

    cache.set(stop_id, rep.body(), ttl_seconds = 20)

    return rep.json()

def get_schema():
    # The user selects a stop from a drop-down menu of the 20 closest stops sourced from AC Transit
    # The user also specifies a maximum number of departures times they want displayed per bus
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "predictions_max",
                name = "Departures",
                desc = "Choose number of departures displayed per bus",
                icon = "clock",
                default = "2",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                ],
            ),
            schema.LocationBased(
                id = "stop_id",
                name = "Bus Stop",
                desc = "Choose from the 20 nearest stops",
                icon = "bus",
                handler = get_stops,
            ),
        ],
    )

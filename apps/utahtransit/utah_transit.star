"""
Applet: Utah Transit
Summary: Live UTA departures
Description: Shows realtime UTA departures with scheduled fallback for configurable stops.
Author: andrew-bierman
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOPS = "salt-lake-central"
API_URL = "https://uta-tidbyt.abbierman101.workers.dev"
DEFAULT_COLOR = "#FFBF00"
FONT = "CG-pixel-3x5-mono"
MAX_DEPARTURES = 4

# The layout follows the established Seattle Transit Community App pattern:
# stop marquee, then compact route / headsign / time rows on a black canvas.
# https://github.com/tidbyt/community/tree/main/apps/seattletransit

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stops",
                name = "Stations or stops",
                desc = "Comma-separated station aliases or UTA stop codes",
                icon = "locationDot",
                default = DEFAULT_STOPS,
            ),
            schema.Text(
                id = "routes",
                name = "Routes",
                desc = "Optional comma-separated route numbers, such as 701,750",
                icon = "route",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Service type",
                desc = "Show rail, bus, or both",
                icon = "bus",
                default = "all",
                options = [
                    schema.Option(display = "Rail + bus", value = "all"),
                    schema.Option(display = "Rail only", value = "rail"),
                    schema.Option(display = "Bus only", value = "bus"),
                ],
            ),
            schema.Dropdown(
                id = "limit",
                name = "Departures",
                desc = "Maximum departures to show",
                icon = "clock",
                default = str(MAX_DEPARTURES),
                options = [
                    schema.Option(display = "2", value = "2"),
                    schema.Option(display = "3", value = "3"),
                    schema.Option(display = "4", value = "4"),
                ],
            ),
            schema.Toggle(
                id = "show_stop",
                name = "Show stop",
                desc = "Show the stop name in the header",
                icon = "signHanging",
                default = True,
            ),
        ],
    )

def fetch_data(config):
    mode_filter = config.str("mode", "all")

    params = {
        "stops": config.str("stops", DEFAULT_STOPS),
        "limit": config.str("limit", str(MAX_DEPARTURES)),
        "mode": mode_filter,
    }
    routes = config.str("routes", "").strip()
    if routes:
        params["routes"] = routes

    response = http.get(API_URL + "/departures", params = params, ttl_seconds = 20)
    if response.status_code != 200:
        print("UTA bridge returned HTTP %d" % response.status_code)
        return None
    return json.decode(response.body())

def compact_name(name):
    return name.replace(" Station", "").replace(" (Bay A)", "").replace(" (Bay B)", "").replace(" (Bay C)", "").replace(" (Bay D)", "")

def status_screen(title, detail):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(title, color = DEFAULT_COLOR, font = "5x8"),
                render.Marquee(
                    width = 60,
                    align = "center",
                    child = render.Text(detail, color = "#FFFFFF", font = FONT),
                ),
            ],
        ),
    )

def departure_row(departure):
    minutes = departure["minutes"]
    time_text = "due" if minutes <= 0 else "%dm" % minutes
    route = str(departure["route"])[:3]

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Box(
                width = 12,
                height = 5,
                color = departure.get("color", "#004a97"),
                child = render.Text(
                    route,
                    color = departure.get("textColor", "#ffffff"),
                    font = FONT,
                ),
            ),
            render.Marquee(
                width = 40,
                align = "center",
                child = render.Text(
                    compact_name(departure["destination"]),
                    color = DEFAULT_COLOR,
                    font = FONT,
                ),
            ),
            render.Marquee(
                width = 12,
                align = "end",
                child = render.Text(
                    time_text,
                    color = "#00FF00" if departure.get("realtime", False) else DEFAULT_COLOR,
                    font = FONT,
                ),
            ),
        ],
    )

def empty_departure_row():
    return render.Box(width = 64, height = 5)

def main(config):
    data = fetch_data(config)
    if data == None:
        return status_screen("UTA", "Departure service unavailable")

    departures = data.get("departures", [])
    if not departures:
        return status_screen("UTA", "No upcoming departures")

    rows = [render.Box(height = 1)]
    show_stop = config.bool("show_stop", True)
    if show_stop:
        stops = data.get("stops", [])
        stop_name = compact_name(stops[0]["name"]) if stops else "UTA"
        rows.append(
            render.Marquee(
                width = 64,
                align = "center",
                child = render.Text(stop_name, color = DEFAULT_COLOR, font = FONT),
            ),
        )
        rows.append(render.Box(height = 1))

    limit = int(config.str("limit", str(MAX_DEPARTURES)))
    visible = departures[:min(limit, MAX_DEPARTURES)]
    for departure in visible:
        rows.append(departure_row(departure))
        rows.append(render.Box(height = 1))

    for _ in range(MAX_DEPARTURES - len(visible)):
        rows.append(empty_departure_row())
        rows.append(render.Box(height = 1))

    return render.Root(
        max_age = 60,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                children = rows,
            ),
        ),
    )

"""
Applet: Flight Radar Feed
Summary: View FR24 Radar Feed
Description: View the flights tracked by a radar on Flightradar24.
Author: kinson
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

PLANE_ICON = base64.decode(
    """
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAAAXNSR0IArs4c6QAAANpJREFUKFNtkL9OwnAUhb9bIcRBFxYDhFljqgODkOCOYaPtAxBYbHwDZh/BMuID0DD4EjAQhzKxAombu4Fekh9/bANn/O495yRHwFIkBuUo2w+J+i5oAu6vkn940UK9SxQ4/w4E2x+ixMwCL8FBAL1/GyEKYe/JgHO6KxTZoDvDox8y7NVwxz8scjcQZxhX1iauOt1FqLXht1lC8nZDy88dvgOP+WoJYhGLoKpcnKkyDUluv36B/IEI0UfrxJIydN8/mayuzNMscNJJh5UODdnLa27bA4PTi6VLtlDpQKfUrwVNAAAAAElFTkSuQmCC
""",
)

API_URL = "https://data-cloud.flightradar24.com/zones/fcgi/feed.js?radar="

def get_data(url, radar_code):
    res = http.get(url + radar_code, ttl_seconds = 60)  # cache for 1 minute
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    json_res = res.json()

    flight_strings = []

    index = 0
    for _id, flight in json_res.items():
        index = index + 1
        if type(flight) == "string" or type(flight) == "int" or type(flight) == "float":
            continue

        callsign = flight[16]
        origin = flight[11]
        destination = flight[12]

        has_route = origin != "" and destination != ""
        has_callsign = callsign != ""
        if has_route or has_callsign:
            flight_strings.append(flight)

    return flight_strings

def render_flight_info_screen(info, radar, show_radar):
    flight_number = info[16] or "?"

    origin = info[11] or "?"
    destination = info[12] or "?"

    model = info[8] or "?"
    registration = info[9] or "?"

    speed = str(int(info[5])) or "?"
    alt = str(int(info[4])) or "?"

    callsign_row = [render.Text(content = flight_number, font = "CG-pixel-3x5-mono")]

    if show_radar:
        callsign_row.append(
            render.Padding(
                child = render.Text(
                    content = radar,
                    font = "CG-pixel-3x5-mono",
                    color = "#811",
                ),
                pad = (0, 0, 0, 0),
            ),
        )

    return render.Padding(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = callsign_row,
                ),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 0, 4, 0),
                            child = render.Image(src = PLANE_ICON),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(
                                content = origin + " -> " + destination,
                                color = "#1111ee",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = model, font = "tom-thumb"),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = registration, font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = speed, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "kts", font = "tom-thumb"),
                                ),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = alt, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "ft", font = "tom-thumb"),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
        pad = (1, 1, 0, 1),
    )

def render_list_of_flights(flights, radar, show_radar):
    if len(flights) > 0:
        return [render_flight_info_screen(f, radar, show_radar) for f in flights]
    else:
        return []

def main(config):
    radars = config.str("radars")

    if not radars:
        return []

    radar_array = radars.split(",")
    rendered_flights = []

    for radar in radar_array:
        flight_data = get_data(API_URL, radar)
        rendered_screens = render_list_of_flights(
            flight_data,
            radar,
            len(radar_array) > 1,
        )
        rendered_flights.extend(rendered_screens)

    if len(rendered_flights) == 0:
        return []

    return render.Root(
        delay = 3500,
        show_full_animation = True,
        child = render.Animation(children = rendered_flights),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "radars",
                name = "Radar IDs (e.g. T-KSFO10)",
                desc = "Separate multiple with a comma",
                icon = "satelliteDish",
            ),
        ],
    )

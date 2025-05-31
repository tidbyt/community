"""
Applet: PATH Times
Summary: NJ Path schedule
Description: Show real time NJ Path Train arrival times.
Author: DavidGoldman
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STATION = "NEW"
FONT = "tb-8"

STATIONS = {
    "NWK": "Newark",
    "HAR": "Harrison",
    "JSQ": "Journal Square",
    "GRV": "Grove Street",
    "NEW": "Newport",
    "EXP": "Exchange Place",
    "HOB": "Hoboken",
    "WTC": "World Trade Center",
    "CHR": "Christopher Street",
    "09S": "9th Street",
    "14S": "14th Street",
    "23S": "23rd Street",
    "33S": "33rd Street",
}

SHORT_STATION_NAMES = {
    "NWK": "Newark",
    "HAR": "Harrison",
    "JSQ": "Journal Sq",
    "GRV": "Grove St",
    "NEW": "Newport",
    "EXP": "Exchange Pl",
    "HOB": "Hoboken",
    "WTC": "World Trade Center",
    "CHR": "Christopher St",
    "09S": "9th St",
    "14S": "14th St",
    "23S": "23rd St",
    "33S": "33rd St",
}

ALL_DIRECTION = "all"

DIRECTIONS = {
    ALL_DIRECTION: "Both Directions",
    "ToNJ": "To NJ",
    "ToNY": "To NY",
    "WTC": "To WTC",
    "HOB": "To Hoboken",
    "NWK": "To Newark",
    "33S": "To 33rd Street",
    "JSQ": "To Journal Square",
}

def get_schema():
    stations = [schema.Option(display = STATIONS[x], value = x) for x in STATIONS]
    directions = [schema.Option(display = DIRECTIONS[x], value = x) for x in DIRECTIONS]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Select a station to view arrivals",
                icon = "trainSubway",
                default = DEFAULT_STATION,
                options = stations,
            ),
            schema.Dropdown(
                id = "direction_filter",
                name = "Direction Filter",
                desc = "Select a direction to filter trains or filter by the train's destination",
                icon = "locationArrow",
                default = ALL_DIRECTION,
                options = directions,
            ),
            schema.Toggle(
                id = "short_title",
                name = "Short Station Titles",
                desc = "Display a short version of the station names to try to prevent scrolling.",
                icon = "gear",
                default = True,
            ),
        ],
    )

def main(config):
    selected_station = config.get("station", DEFAULT_STATION)
    direction_filter = config.get("direction_filter", ALL_DIRECTION)
    short_title = config.bool("short_title", True)

    # Fetch PATH train data
    url = "https://panynj.gov/bin/portauthority/ridepath.json"
    response = http.get(url, ttl_seconds = 30)

    if response.status_code != 200:
        return render.Root(
            child = render.Text("Error fetching PATH data: HTTP {}".format(response.status_code)),
        )

    data = response.json()

    # Find the train data that the user cares about.
    train_info = []
    for station in data["results"]:
        station_name = station["consideredStation"]
        if station_name != selected_station:
            continue
        for destination in station["destinations"]:
            direction = destination["label"]
            for message in destination["messages"]:
                target = message["target"]
                if direction_filter != ALL_DIRECTION and direction_filter != direction and direction_filter != target:
                    continue
                arrival = message["arrivalTimeMessage"]
                if arrival == "0 min":
                    arrival = "now"
                train_info.append({
                    "station": station_name,
                    "destination": target,
                    "arrival": arrival,
                    "secondsToArrival": int(message["secondsToArrival"]),
                    "color": "#" + message["lineColor"],
                    "lastUpdated": message["lastUpdated"],
                    "direction": direction,
                    "headSign": message["headSign"],
                })
        break

    train_info = sorted(train_info, key = lambda x: x["secondsToArrival"])

    children = []

    first = True
    for train in train_info[:2]:
        head_sign = train["headSign"]
        dest = train["destination"]
        arrival = train["arrival"]

        # Use the shorthand to avoid scrolling if the name matches what we expect.
        if short_title and head_sign == STATIONS[dest]:
            label = render.Text(SHORT_STATION_NAMES[dest], font = FONT)
        else:
            label = render.Marquee(child = render.Text(head_sign, font = FONT), width = 49)

        if not first:
            children.append(render.Row([render.Box(height = 1, color = "#666")]))
        else:
            first = False
        row = render.Row([
            render.Padding(
                child = render.Circle(
                    color = (train["color"] or "").split(",")[0],
                    diameter = 11,
                ),
                pad = (2, 0, 2, 0),
            ),
            render.Column(
                children = [
                    label,
                    render.Text(arrival, font = FONT, color = "#ffa500", offset = 1),
                ],
                cross_align = "left",
            ),
        ], cross_align = "center")
        children.append(row)

    # If no trains found, show a message
    if not train_info:
        children.append(render.Text("No trains =/", font = FONT))

    return render.Root(
        child = render.Column(children),
    )

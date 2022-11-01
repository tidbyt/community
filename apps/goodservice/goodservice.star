"""
Applet: Goodservice
Summary: Goodservice NYC subway
Description: Projected New York City subway departure times, powered by goodservice.io.
Author: blahblahblah-
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("http.star", "http")
load("encoding/base64.star", "base64")

DEFAULT_STOP_ID = "M16"
DEFAULT_DIRECTION = "both"
GOOD_SERVICE_STOPS_URL_BASE = "https://goodservice.io/api/stops/"
GOOD_SERVICE_ROUTES_URL = "https://goodservice.io/api/routes/"

NAME_OVERRIDE = {
    "Grand Central-42 St": "Grand Cntrl",
    "Times Sq-42 St": "Times Sq",
    "Coney Island-Stillwell Av": "Coney Is",
    "South Ferry": "S Ferry",
}

STREET_ABBREVIATIONS = [
    "St",
    "Av",
    "Sq",
    "Blvd",
    "Rd",
    "Yards",
]

ABBREVIATIONS = {
    "World Trade Center": "WTC",
    "Center": "Ctr",
    "Metropolitan": "Metrop",
    "Blvd": "Bl",
    "Park": "Pk",
    "Beach": "Bch",
    "Rockaway": "Rckwy",
    "Channel": "Chnl",
    "Green": "Grn",
    "Broadway": "Bway",
    "Queensboro": "Q Boro",
    "Plaza": "Plz",
    "Whitehall": "Whthall",
}

DIAMONDS = {
    "#21ba45": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAACXBIWXMAAAsSAAALEgHS3X78AAAAf0lEQVQYlX2QwQ2AIAxFnyzACEYncAQueGZUz3pxBCcwcQQnwGCqAUT+hUDfS2kb7z1x+mUcgAlwu523uKYK4Aq04ZT7F45ALU86F9QPSEloutn+gXFOwCgZpgY+HaYAOzFrCXWnZD2mItxfCNw9YEV4wWR1BSEBEzgTjhwEuAAX3ToeSy69ZQAAAABJRU5ErkJggg==",
    "#a333c8": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAACXBIWXMAAAsSAAALEgHS3X78AAAAgUlEQVQYlWP8//8/AzJYYnLSgIGBYQMDA0NAzBnzC8hyTFgUHmBgYJAH0VA+pmIkhfxQIX50DUw4FDJg08C42PgELoXI4CMDA4MDE9Qz+BTCbNgAUhwA1YkPgOQDmKDB44BHA9gJIHVgD+LRAFeIEnRYNKAoRFGMpuEhukIGBgYGAL61OaAb+ZxMAAAAAElFTkSuQmCC",
    "#f2711c": "iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAYAAACprHcmAAAACXBIWXMAAAsSAAALEgHS3X78AAAAgElEQVQYlX2QYQ2AIBBGH/x3FtBZwQhGoIoGMYsRjGAFZwI1AA53OkDk+8Pg3ttxp6y1+DmHugUmwBTjtvg1nQBnoHGn3L+wB5byVMaC/gFJCeroqz/Qzw50WobJgU+HycFGzFxc3WhZT5cR7i847h4wI7xgsLqEEIABHAlrDAJc17Y5vym7CTIAAAAASUVORK5CYII=",
}

def main(config):
    routes_req = http.get(GOOD_SERVICE_ROUTES_URL)
    if routes_req.status_code != 200:
        fail("goodservice routes request failed with status %d", routes_req.status_code)

    stop_id = config.str("stop_id", DEFAULT_STOP_ID)
    stop_req = http.get(GOOD_SERVICE_STOPS_URL_BASE + stop_id)
    if stop_req.status_code != 200:
        fail("goodservice stop request failed with status %d", stop_req.status_code)

    stops_req = http.get(GOOD_SERVICE_STOPS_URL_BASE)
    if stops_req.status_code != 200:
        fail("goodservice stops request failed with status %d", stops_req.status_code)

    direction_config = config.str("direction", DEFAULT_DIRECTION)
    if direction_config == "both":
        directions = ["north", "south"]
    else:
        directions = [direction_config]

    ts = time.now().unix
    blocks = []

    for dir in directions:
        upcoming_routes = {
            "north": [],
            "south": [],
        }
        dir_data = stop_req.json()["upcoming_trips"].get(dir)
        if not dir_data:
            continue

        for trip in dir_data:
            matching_route = None
            for r in upcoming_routes[dir]:
                if r["route_id"] == trip["route_id"] and r["destination_stop"] == trip["destination_stop"]:
                    matching_route = r
                    break

            if matching_route:
                if len(matching_route["times"]) == 1:
                    matching_route["times"].append(trip["estimated_current_stop_arrival_time"])
                    matching_route["is_delayed"].append(trip["is_delayed"])
                else:
                    continue
            else:
                upcoming_routes[dir].append({"route_id": trip["route_id"], "destination_stop": trip["destination_stop"], "times": [trip["estimated_current_stop_arrival_time"]], "is_delayed": [trip["is_delayed"]]})

        for dir in directions:
            for r in upcoming_routes[dir]:
                if len(blocks) > 0:
                    if dir == "south" and r == upcoming_routes[dir][0]:
                        blocks.append(render.Box(width = 64, height = 1, color = "#aaa"))
                    else:
                        blocks.append(render.Box(width = 64, height = 1, color = "#333"))

                selected_route = routes_req.json()["routes"][r["route_id"]]
                route_color = selected_route["color"]
                text_color = selected_route["text_color"] if selected_route["text_color"] else "#fff"
                destination = None

                for s in stops_req.json()["stops"]:
                    if s["id"] == r["destination_stop"]:
                        destination = condense_name(s["name"])
                        break

                first_eta = (int(r["times"][0]) - ts) / 60
                first_train_is_delayed = r["is_delayed"][0]

                if first_train_is_delayed:
                    text = "delay"
                elif first_eta < 1:
                    text = "due"
                else:
                    text = str(int(first_eta))

                if len(r["times"]) == 1 and text != "due" and text != "delay":
                    text = text + " min"
                elif text != "delay":
                    second_eta = (int((r["times"][1]) - ts) / 60)
                    second_train_is_delayed = r["is_delayed"][1]
                    if second_train_is_delayed:
                        if first_eta < 1:
                            text = text + ", delay"
                        else:
                            text = text + " min, delay"
                    elif second_eta < 1:
                        text = text + ", due"
                    else:
                        text = text + ", " + str(int(second_eta)) + " min"

                if len(selected_route["name"]) > 1 and selected_route["name"][1] == "X":
                    bullet = render.Stack(
                        children = [
                            render.Image(
                                src = base64.decode(DIAMONDS[route_color]),
                            ),
                            render.Padding(
                                pad = (4, 2, 0, 0),
                                child = render.Text(
                                    content = selected_route["name"][0],
                                    color = text_color,
                                    height = 8,
                                ),
                            ),
                        ],
                    )
                else:
                    bullet = render.Circle(
                        color = route_color,
                        diameter = 11,
                        child = render.Box(
                            padding = 1,
                            height = 11,
                            width = 11,
                            child = render.Text(
                                content = selected_route["name"][0] if selected_route["name"] != "SIR" else "SI",
                                color = text_color,
                                height = 8,
                            ),
                        ),
                    )

                blocks.append(render.Padding(
                    pad = (0, 0, 0, 1),
                    child = render.Row(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 0, 1, 0),
                                child = bullet,
                            ),
                            render.Column(
                                children = [
                                    render.Text(destination),
                                    render.Text(content = text, font = "tom-thumb", color = "#f2711c"),
                                ],
                            ),
                        ],
                    ),
                ))

    if len(blocks) == 0:
        return []

    return render.Root(
        child = render.Marquee(
            height = 32,
            offset_start = 16,
            offset_end = 16,
            scroll_direction = "vertical",
            child = render.Column(
                children = blocks,
            ),
        ),
    )

def get_schema():
    stops_req = http.get(GOOD_SERVICE_STOPS_URL_BASE)
    if stops_req.status_code != 200:
        fail("goodservice stops request failed with status %d", stops_req.status_code)

    stops_options = []

    for s in stops_req.json()["stops"]:
        stop_name = s["name"].replace(" - ", "-") + " - " + s["secondary_name"] if s["secondary_name"] else s["name"].replace(" - ", "-")
        routes = sorted(s["routes"].keys())
        stops_options.append(
            schema.Option(
                display = stop_name + " (" + ", ".join(routes) + ")",
                value = s["id"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "stop_id",
                name = "Station",
                desc = "Station to show subway departures",
                icon = "trainSubway",
                default = "M16",
                options = stops_options,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Direction(s) of train depatures to be included",
                icon = "compass",
                default = "both",
                options = [
                    schema.Option(
                        display = "Both",
                        value = "both",
                    ),
                    schema.Option(
                        display = "Northbound",
                        value = "north",
                    ),
                    schema.Option(
                        display = "Southbound",
                        value = "south",
                    ),
                ],
            ),
        ],
    )

def condense_name(name):
    name = name.replace(" - ", "-")
    if len(name) < 11:
        return name

    if NAME_OVERRIDE.get(name):
        return NAME_OVERRIDE[name]

    if "-" in name:
        modified_name = name
        for abrv in STREET_ABBREVIATIONS:
            abbreviated_array = modified_name.split(abrv)
            modified_name = ""
            for a in abbreviated_array:
                modified_name = modified_name + a.strip()
        modified_name = modified_name.strip()
        if len(modified_name) < 11:
            return modified_name

    for key in ABBREVIATIONS:
        name = name.replace(key, ABBREVIATIONS[key])
    split_name = name.split("-")
    if len(split_name) > 1 and ("St" in split_name[1] or "Av" in split_name[1] or "Sq" in split_name[1] or "Bl" in split_name[1]) and (split_name[0] != "Far Rckwy"):
        if "Sts" in split_name[1]:
            return split_name[0] + " St"
        if "Avs" in split_name[1]:
            return split_name[0] + " Av"
        return split_name[1]
    return split_name[0]

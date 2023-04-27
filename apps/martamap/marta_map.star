"""
Applet: MARTA Map
Summary: Display MARTA trains
Description: Display real-time MARTA train locations.
Author: InTheDaylight14
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

TEXT_COLOR = "#aaaaaa"
DEFAULT_ORIENTATION_BOOL = False  #Default to horizontal
DEFAULT_ARRIVALS = True
DEFAULT_STATION = "Five Points"
DEFAULT_SCROLL = True
DEAFULT_DIRECTION = None

# FONT = "CG-pixel-3x5-mono"
FONT = "CG-pixel-4x5-mono"

def main(config):
    MARTA_API_URL = secret.decrypt("AV6+xWcEqpLr4r5xWHL+ENipBzxVuOwqPhBwALkpo2ySIP8LvhyYYjsLoSq484C+X+Q91GmnTkRZBVPcITGvJJRJxmomJAwy4ejsRATXKIMmJHQy29u3IXDATDXbDuMXDx2wLeQXtfpuwWf5qHNh5VLrnE3d3ZJTfP6mS9xBxo+CwffQNt3YGa3pkQTpI5ikAKotOr95vcBPQzw22E3yY7iMqjR72wsE8s730m9pLnFolxbNmyMKZ6DNh+XFqNiNNer02eodGjhvLRR74xk8A1Q72Q==")
    trains = get_trains(MARTA_API_URL)
    arrivals = config.bool("arrivals") or DEFAULT_ARRIVALS
    orientation_bool = config.bool("orientation") or DEFAULT_ORIENTATION_BOOL

    if orientation_bool:
        orientation = "vertical"
    else:
        orientation = "horizontal"

    train_plots = []

    #Invisible Marquee with long text to force all Marquees to pause ~10 sec...
    train_plots.append(
        render.Marquee(
            width = 30,
            child = render.Text("00000000000000000000000000000000000000000000000000000000000000000000000", color = "#000"),
        ),
    )

    if orientation == "horizontal" and arrivals:
        train_plots.append(render_arrivals(config))

    #Add track plots and five points station overlay
    train_plots.append(render_line(RED_LINE_POINTS, COLOR_MAP["RED"], orientation))
    train_plots.append(render_line(GOLD_LINE_POINTS, COLOR_MAP["GOLD"], orientation))
    train_plots.append(render_line(GREEN_LINE_POINTS, COLOR_MAP["GREEN"], orientation))
    train_plots.append(render_line(BLUE_LINE_POINTS, COLOR_MAP["BLUE"], orientation))
    train_plots.append(render_line(RED_LINE_FIVE_POINTS, COLOR_MAP["RED"], orientation))
    train_plots.append(render_line(GOLD_LINE_FIVE_POINTS, COLOR_MAP["GOLD"], orientation))

    #Add the train dots with real time data
    for train in trains.values():
        train_plots.append(render_train(train, orientation))

    #Output 1 row and all the appended children centered on screen
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.Stack(
                children = train_plots,
            )],
        ),
    )

def get_schema():
    station_options = get_station_list_options()
    direction_options = get_direction_list_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "orientation",
                name = "Vertical Orientation?",
                desc = "Show map in vertical orientation?",
                icon = "ellipsisVertical",
                default = False,
            ),
            schema.Toggle(
                id = "arrivals",
                name = "Show Station arrivals?",
                desc = "Show station arrival in the horrizontal orientation?",
                icon = "toggleOn",
                default = True,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll Arrival Head sign",
                desc = "Scroll the arrival head signs or static text?",
                icon = "toggleOn",
                default = True,
            ),
            schema.Dropdown(
                id = "station",
                name = "Stations",
                desc = "The color of text to be displayed.",
                icon = "trainSubway",
                default = station_options[17].value,
                options = station_options,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Filter Direction",
                desc = "Filter the arrivals to one cardinal direction.",
                icon = "compass",
                default = direction_options[0].value,
                options = direction_options,
            ),
        ],
    )

#return the coordinates based on the line
def get_location(train, orientation):
    line = train["LINE"]

    plot_point = None

    if line == "RED":
        plot_point = decode_coordinates(train["VEHICLELONGITUDE"], RED_LINE_MAP[orientation])
    elif line == "GOLD":
        plot_point = decode_coordinates(train["VEHICLELONGITUDE"], GOLD_LINE_MAP[orientation])
    elif line == "GREEN":
        plot_point = decode_coordinates(train["VEHICLELATITUDE"], GREEN_LINE_MAP[orientation])
    elif line == "BLUE":
        plot_point = decode_coordinates(train["VEHICLELATITUDE"], BLUE_LINE_MAP[orientation])

    return [plot_point, plot_point]

def decode_coordinates(coordinate, mapping):
    for value in reversed(mapping):
        if abs(float(coordinate)) < abs(value[0]):
            return (value[1], value[2])
    return (65, 65)

def get_trains(MARTA_API_URL):
    cached_trains = cache.get("cached_trains")
    if cached_trains != None:
        return json.decode(cached_trains)

    response = http.get(MARTA_API_URL)
    if response.status_code != 200:
        print("MARTA Train API request failed with status %d", response.status_code)
    all_trains = response.json()
    all_train_arrivals = all_trains["RailArrivals"]

    trains = {}
    for arrival in all_train_arrivals:
        if arrival["TRAIN_ID"] not in trains.keys():
            trains[arrival["TRAIN_ID"]] = arrival

    cache.set("cached_trains", json.encode(trains), ttl_seconds = 20)

    return trains

def render_line(points, color, orientation):
    if orientation == "vertical":
        return render.Plot(
            data = points[orientation],
            width = 64,
            height = 32,
            x_lim = (0, 63),
            y_lim = (0, 31),
            color = color,
        )
    else:
        return render.Plot(
            data = points[orientation],
            width = 30,
            height = 32,
            x_lim = (0, 29),
            y_lim = (0, 31),
            color = color,
        )

def render_train(train, orientation):
    location = get_location(train, orientation)

    color = "#ffffff"

    if orientation == "vertical":
        return render.Plot(
            data = location,
            width = 64,
            height = 32,
            x_lim = (0, 63),
            y_lim = (0, 31),
            color = color,
        )
    else:
        return render.Plot(
            data = location,
            width = 30,
            height = 32,
            x_lim = (0, 29),
            y_lim = (0, 31),
            color = color,
        )

def get_station_list_options():
    options = []
    for station in STATIONS_MAP.keys():
        options.append(
            schema.Option(
                display = station,
                value = station,
            ),
        )
    return options

def get_direction_list_options():
    options = []
    for direction in DIRECTION_MAP.keys():
        options.append(
            schema.Option(
                display = direction,
                value = direction,
            ),
        )
    return options

def arrival_template(config, color, time, head_sign):
    if len(time) < 2:
        time = "0" + time

    head_sign = HEAD_SIGN_MAP[head_sign]

    return render.Row(
        children = [
            #Line color
            render.Column(
                children = [
                    render.Box(width = 2, height = 1, color = "#000"),
                    render.Box(width = 1, height = 5, color = color),
                    render.Box(width = 2, height = 1, color = "#000"),
                ],
            ),  #Space between line color and time
            # render.Column(
            #     children = [
            #         render.Box(width = 1, height = 1, color = "#000"),
            #     ],
            # ),  #Arrival time
            render.Column(
                children = [
                    render.Box(width = 2, height = 1, color = "#000"),
                    render.Text(time + "", font = FONT, color = TEXT_COLOR),
                ],
            ),
            render.Column(
                children = [
                    render.Box(width = 2, height = 1, color = "#000"),
                    render.Box(width = 1, height = 5, color = color),
                    render.Box(width = 2, height = 1, color = "#000"),
                ],
            ),  #Space between time color and head sign marquee
            render.Column(
                children = [
                    render.Box(width = 1, height = 1, color = "#000"),
                ],
            ),  #Space head sign marquee
            render.Column(
                children = [
                    render.Box(width = 2, height = 1, color = "#000"),
                    render_headsign_text(config, head_sign),
                ],
            ),
        ],
    )

def render_headsign_text(config, head_sign):
    scroll = config.bool("scroll") or DEFAULT_SCROLL
    width = 29
    if scroll:
        return render.Marquee(
            width = width,
            child = render.Text(head_sign, font = FONT, color = TEXT_COLOR),
        )
    else:
        return render.Text(head_sign, font = FONT, color = TEXT_COLOR)

def render_arrivals(config):
    rendered_arrivals = []
    station_arrivals = get_arrivals(config)

    #Truncate list of arrivals to 4
    if len(station_arrivals) > 4:
        station_arrivals = station_arrivals[0:4]

    for arrival in station_arrivals:
        waiting_time = arrival["WAITING_TIME"]
        if waiting_time == "Arriving":
            waiting_time = "Ar "
        space = waiting_time.find(" ")  #WAITING_TIME format "4 min", find index of the space
        time = waiting_time[0:space]  #Get only the number from WAITING_TIME
        color = COLOR_MAP[arrival["LINE"]]
        destination = arrival["DESTINATION"]

        rendered_arrivals.append(
            arrival_template(config, color, time, destination),
        )

    #Space 3rd arrival further below blue line
    if len(rendered_arrivals) > 2:
        rendered_arrivals.insert(
            2,
            render.Box(height = 5, color = "#000"),
        )

    return render.Row(
        children = [
            render.Box(width = 20, height = 32, color = "#000"),
            render.Column(
                children = rendered_arrivals,
            ),
        ],
    )

def get_arrivals(config):
    cached_arrivals = cache.get("cached_arrivals")
    if cached_arrivals != None:
        return json.decode(cached_arrivals)

    station = STATIONS_MAP[config.get("station") or DEFAULT_STATION]
    direction = config.bool("direction") or DEAFULT_DIRECTION
    if direction != None:
        direction = DIRECTION_MAP[direction]

    response = http.get("https://api.marta.io/trains")
    if response.status_code != 200:
        fail("MARTA Train API request failed with status %d", response.status_code)
    all_arrivals = response.json()
    arrivals = []

    for arrival in all_arrivals:
        if direction == None:
            #Append the correct station arrivals
            if arrival["STATION"] == station:
                arrivals.append(arrival)

            #Append only 1 direction if selected in Schema
        elif arrival["STATION"] == station and arrival["DIRECTION"] == direction:
            arrivals.append(arrival)

    #Sort arrivals by shortest time to arrival
    arrivals = (sorted(arrivals, key = lambda d: int(d["WAITING_SECONDS"])))

    cache.set("cached_arrivals", json.encode(arrivals), ttl_seconds = 10)

    return arrivals

RED_LINE_POINTS = {
    "vertical": [
        (0, 13),
        (1, 14),
        (3, 14),
        (4, 13),
        (15, 13),
        (17, 11),
        (34, 11),
        (38, 7),
        (61, 7),
        (63, 9),
    ],
    "horizontal": [
        (10, 31),
        (11, 30),
        (11, 28),
        (10, 27),
        (10, 24),
        (9, 23),
        (9, 15),
        (6, 12),
        (6, 2),
        (8, 0),
    ],
}
GOLD_LINE_POINTS = {
    "vertical": [
        (6, 23),
        (17, 12),
        (34, 12),
        (38, 8),
        (61, 8),
        (63, 10),
    ],
    "horizontal": [
        (15, 28),
        (10, 23),
        (10, 15),
        (7, 12),
        (7, 2),
        (9, 0),
    ],
}
BLUE_LINE_POINTS = {
    "vertical": [
        (34, 0),
        (34, 31),
    ],
    "horizontal": [
        (0, 15),
        (27, 15),
    ],
}
GREEN_LINE_POINTS = {
    "vertical": [
        (31, 3),
        (33, 5),
        (33, 20),
    ],
    "horizontal": [
        (2, 18),
        (4, 16),
        (17, 16),
    ],
}

RED_LINE_FIVE_POINTS = {
    "vertical": [(34, 11), (34, 11)],
    "horizontal": [(9, 15), (9, 15)],
}

GOLD_LINE_FIVE_POINTS = {
    "vertical": [(33, 12), (33, 12)],
    "horizontal": [(10, 16), (10, 16)],
}

#RED and GOLD use longitude to estimate location on map
RED_LINE_MAP = {
    "vertical": [
        (34, 0, 13),
        (33.933, 1, 14),
        (33.9222, 2, 14),
        (33.9116, 3, 14),
        (33.9049, 4, 13),
        (33.8981, 5, 13),
        (33.8914, 6, 13),
        (33.8846, 7, 13),
        (33.8779, 8, 13),
        (33.8712, 9, 13),
        (33.8644, 10, 13),
        (33.8577, 11, 13),
        (33.851, 12, 13),
        (33.8442, 13, 13),
        (33.8375, 14, 13),
        (33.8307, 15, 13),
        (33.824, 16, 12),
        (33.8183, 17, 11),
        (33.8127, 18, 11),
        (33.807, 19, 11),
        (33.8013, 20, 11),
        (33.7957, 21, 11),
        (33.79, 22, 11),
        (33.7927, 23, 11),
        (33.7953, 24, 11),
        (33.782, 25, 11),
        (33.7773, 26, 11),
        (33.7726, 27, 11),
        (33.7701, 28, 11),
        (33.7676, 29, 11),
        (33.7631, 30, 11),
        (33.7586, 31, 11),
        (33.7566, 32, 11),
        (33.7545, 34, 11),
        (33.751, 35, 10),
        (33.7492, 36, 9),
        (33.7462, 37, 8),
        (33.7433, 38, 7),
        (33.7403, 39, 7),
        (33.7373, 40, 7),
        (33.7326, 41, 7),
        (33.728, 42, 7),
        (33.7233, 43, 7),
        (33.7186, 44, 7),
        (33.7144, 45, 7),
        (33.7103, 46, 7),
        (33.7061, 47, 7),
        (33.7019, 48, 7),
        (33.6972, 49, 7),
        (33.6926, 50, 7),
        (33.6879, 51, 7),
        (33.6833, 52, 7),
        (33.6786, 53, 7),
        (33.6751, 54, 7),
        (33.6716, 55, 7),
        (33.6681, 56, 7),
        (33.6645, 57, 7),
        (33.661, 58, 7),
        (33.6575, 59, 7),
        (33.654, 60, 7),
        (33.6506, 61, 7),
        (33.6472, 62, 8),
        (33.6438, 63, 9),
    ],
    "horizontal": [
        (34.0000, 10, 31),
        (33.933, 11, 30),
        (33.9222, 11, 29),
        (33.9116, 11, 28),
        (33.8824, 10, 27),
        (33.8678, 10, 26),
        (33.824, 10, 25),
        (33.824, 10, 24),
        (33.824, 9, 23),
        (33.807, 9, 22),
        (33.7899, 9, 21),
        (33.7818, 9, 20),
        (33.7700, 9, 19),
        (33.7671, 9, 18),
        (33.7586, 9, 17),
        (33.7544, 9, 15),
        (33.749, 8, 14),
        (33.7449, 7, 13),
        (33.7429, 6, 12),
        (33.7367, 6, 11),
        (33.7271, 6, 10),
        (33.7174, 6, 9),
        (33.7093, 6, 8),
        (33.7011, 6, 7),
        (33.6897, 6, 6),
        (33.6783, 6, 5),
        (33.6696, 6, 4),
        (33.6653, 6, 3),
        (33.6523, 6, 2),
        (33.6486, 7, 1),
        (33.6449, 8, 0),
    ],
}

GOLD_LINE_MAP = {
    "vertical": [
        (34, 6, 23),
        (33.8963, 7, 22),
        (33.8874, 8, 21),
        (33.8785, 9, 20),
        (33.8696, 10, 19),
        (33.8607, 11, 18),
        (33.8558, 12, 17),
        (33.8509, 13, 16),
        (33.846, 14, 15),
        (33.835, 15, 14),
        (33.824, 16, 13),
        (33.8183, 17, 12),
        (33.8127, 18, 12),
        (33.807, 19, 12),
        (33.8013, 20, 12),
        (33.7957, 21, 12),
        (33.79, 22, 12),
        (33.7927, 23, 12),
        (33.7953, 24, 12),
        (33.782, 25, 12),
        (33.7773, 26, 12),
        (33.7726, 27, 12),
        (33.7701, 28, 12),
        (33.7676, 29, 12),
        (33.7631, 30, 12),
        (33.7586, 31, 12),
        (33.7566, 32, 12),
        (33.7545, 33, 12),
        (33.751, 35, 11),
        (33.7492, 36, 10),
        (33.7462, 37, 9),
        (33.7433, 38, 8),
        (33.7403, 39, 8),
        (33.7373, 40, 8),
        (33.7326, 41, 8),
        (33.728, 42, 8),
        (33.7233, 43, 8),
        (33.7186, 44, 8),
        (33.7144, 45, 8),
        (33.7103, 46, 8),
        (33.7061, 47, 8),
        (33.7019, 48, 8),
        (33.6972, 49, 8),
        (33.6926, 50, 8),
        (33.6879, 51, 8),
        (33.6833, 52, 8),
        (33.6786, 53, 8),
        (33.6751, 54, 8),
        (33.6716, 55, 8),
        (33.6681, 56, 8),
        (33.6645, 57, 8),
        (33.661, 58, 8),
        (33.6575, 59, 8),
        (33.654, 60, 8),
        (33.6506, 61, 8),
        (33.6472, 62, 9),
        (33.6438, 63, 10),
    ],
    "horizontal": [
        (33.9042, 15, 28),
        (33.888, 14, 27),
        (33.861, 13, 26),
        (33.8459, 12, 25),
        (33.835, 11, 24),
        (33.824, 10, 23),
        (33.807, 10, 22),
        (33.7899, 10, 21),
        (33.7818, 10, 20),
        (33.7723, 10, 19),
        (33.7671, 10, 18),
        (33.7586, 10, 17),
        (33.7544, 10, 16),
        (33.749, 9, 14),
        (33.7449, 8, 13),
        (33.7429, 7, 12),
        (33.7367, 7, 11),
        (33.7271, 7, 10),
        (33.7174, 7, 9),
        (33.7093, 7, 8),
        (33.7011, 7, 7),
        (33.6897, 7, 6),
        (33.6783, 7, 5),
        (33.6696, 7, 4),
        (33.6653, 7, 3),
        (33.6523, 7, 2),
        (33.6486, 8, 1),
        (33.6449, 9, 0),
    ],
}

#GREEN and BLUE use latitude to estimate location on map
GREEN_LINE_MAP = {
    "vertical": [
        (-85, 31, 3),
        (-84.70905, 32, 4),
        (-84.4181, 33, 5),
        (-84.4115, 33, 6),
        (-84.4049, 33, 7),
        (-84.40105, 33, 8),
        (-84.3972, 33, 9),
        (-84.3947, 33, 10),
        (-84.3922, 33, 11),
        (-84.38965, 33, 12),
        (-84.3871, 33, 13),
        (-84.3816, 33, 14),
        (-84.3761, 33, 15),
        (-84.3687, 33, 16),
        (-84.3613, 33, 17),
        (-84.3539, 33, 18),
        (-84.3472, 33, 19),
        (-84.3405, 33, 20),
    ],
    "horizontal": [
        (-84.5000, 2, 18),
        (-84.4253, 3, 17),
        (-84.4115, 4, 16),
        (-84.4063, 5, 16),
        (-84.4011, 6, 16),
        (-84.3979, 7, 16),
        (-84.3947, 8, 16),
        (-84.3922, 9, 16),
        (-84.3871, 11, 16),
        (-84.3816, 12, 16),
        (-84.3761, 13, 16),
        (-84.365, 14, 16),
        (-84.3539, 15, 16),
        (-84.3472, 16, 16),
        (-84.3405, 17, 16),
    ],
}

BLUE_LINE_MAP = {
    "vertical": [
        (-85, 34, 0),
        (-84.4629, 34, 1),
        (-84.4547, 34, 2),
        (-84.4466, 34, 3),
        (-84.4324, 34, 4),
        (-84.4181, 34, 5),
        (-84.4115, 34, 6),
        (-84.4049, 34, 7),
        (-84.4011, 34, 8),
        (-84.3972, 34, 9),
        (-84.3947, 34, 10),
        (-84.3922, 34, 11),
        (-84.3897, 34, 12),
        (-84.3871, 34, 13),
        (-84.3816, 34, 14),
        (-84.3761, 34, 15),
        (-84.3687, 34, 16),
        (-84.3613, 34, 17),
        (-84.3539, 34, 18),
        (-84.3472, 34, 19),
        (-84.3405, 34, 20),
        (-84.3316, 34, 21),
        (-84.3227, 34, 22),
        (-84.3138, 34, 23),
        (-84.3048, 34, 24),
        (-84.2958, 34, 25),
        (-84.2897, 34, 26),
        (-84.2835, 34, 27),
        (-84.2719, 34, 28),
        (-84.2602, 34, 29),
        (-84.2551, 34, 30),
        (-84.25, 34, 31),
    ],
    "horizontal": [
        (-85.0000, 0, 15),
        (-84.4517, 1, 15),
        (-84.4324, 2, 15),
        (-84.422, 3, 15),
        (-84.4115, 4, 15),
        (-84.4063, 5, 15),
        (-84.4011, 6, 15),
        (-84.3979, 7, 15),
        (-84.3947, 8, 15),
        (-84.3922, 10, 15),
        (-84.3871, 11, 15),
        (-84.3816, 12, 15),
        (-84.3761, 13, 15),
        (-84.365, 14, 15),
        (-84.3539, 15, 15),
        (-84.3472, 16, 15),
        (-84.3405, 17, 15),
        (-84.3272, 18, 15),
        (-84.3138, 19, 15),
        (-84.3048, 20, 15),
        (-84.2958, 21, 15),
        (-84.2897, 22, 15),
        (-84.2835, 23, 15),
        (-84.2719, 24, 15),
        (-84.2602, 25, 15),
        (-84.2551, 26, 15),
        (-84.25, 27, 15),
        (-80.0, 27, 15),
    ],
}

COLOR_MAP = {
    "RED": "#CF212C",
    "GOLD": "#D4A82A",
    "GREEN": "#019E4A",
    "BLUE": "#0276B3",
}

STATIONS_MAP = {
    "Airport": "AIRPORT STATION",
    "Arts Center": "ARTS CENTER STATION",
    "Ashby": "ASHBY STATION",
    "Avondale": "AVONDALE STATION",
    "Bankhead": "BANKHEAD STATION",
    "Brookhaven / Oglethorpe": "BROOKHAVEN STATION",
    "Buckhead": "BUCKHEAD STATION",
    "Chamblee": "CHAMBLEE STATION",
    "Civic Center": "CIVIC CENTER STATION",
    "College Park": "COLLEGE PARK STATION",
    "Decatur": "DECATUR STATION",
    "GWCC/CNN Center": "OMNI DOME STATION",
    "Doraville": "DORAVILLE STATION",
    "Dunwoody": "DUNWOODY STATION",
    "East Lake": "EAST LAKE STATION",
    "East Point": "EAST POINT STATION",
    "Edgewood / Candler Park": "EDGEWOOD CANDLER PARK STATION",
    "Five Points": "FIVE POINTS STATION",
    "Garnett": "GARNETT STATION",
    "Georgia State": "GEORGIA STATE STATION",
    "Hamilton E. Holmes": "HAMILTON E HOLMES STATION",
    "Indian Creek": "INDIAN CREEK STATION",
    "Inman Park / Reynoldstown": "INMAN PARK STATION",
    "Kensington": "KENSINGTON STATION",
    "King Memorial": "KING MEMORIAL STATION",
    "Lakewood / Ft. McPherson": "LAKEWOOD STATION",
    "Lenox": "LENOX STATION",
    "Lindbergh Center": "LINDBERGH STATION",
    "Medical Center": "MEDICAL CENTER STATION",
    "Midtown": "MIDTOWN STATION",
    "North Ave": "NORTH AVE STATION",
    "North Springs": "NORTH SPRINGS STATION",
    "Oakland City": "OAKLAND CITY STATION",
    "Peachtree Center": "PEACHTREE CENTER STATION",
    "Sandy Springs": "SANDY SPRINGS STATION",
    "Vine City": "VINE CITY STATION",
    "West End": "WEST END STATION",
    "West Lake": "WEST LAKE STATION",
}

HEAD_SIGN_MAP = {
    "North Springs": "N SPRING ",
    "Doraville": "DORAVILLE",
    "Edgewood Candler Park": "EDGEWOOD ",
    "Bankhead": "BANKHEAD ",
    "Indian Creek": "IND CREEK",
    "Hamilton E Holmes": "HE HOLMES",
    "Airport": "AIRPORT  ",  #Padding so Marquee text is the same length and the scroll cleanly...
    "Lindbergh": "LINDBERGH",
}

DIRECTION_MAP = {
    "No Filter": None,
    "Northbound": "N",
    "Eastbound": "E",
    "Southbound": "S",
    "Westbounr": "W",
}

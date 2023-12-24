"""
Applet: Awair
Summary: Local Awair air data
Description: Get air quality data from Awair's local API.
Author: tabrindle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ip_address",
                name = "Public IP Address and port of Awair device",
                desc = "Your public IP address with port forwarding set up to your awair device",
                icon = "computer",
            ),
            schema.Toggle(
                id = "celsius",
                name = "Use Celsius?",
                desc = "Use Celsius instead of default Fahrenheit.",
                icon = "temperatureLow",
                default = False,
            ),
        ],
    )

def main(config):
    return render_display(config, fetch_data(config))

def fetch_data(config):
    ip_address = config.str("ip_address", "")
    if not ip_address:
        return {"error": "Displaying mock " + "data.           " + "Please configure" + "the API."}

    response = http.get("http://{}/air-data/latest".format(ip_address))
    if response.status_code != 200:
        return {"error": "status {}".format(response.status_code)}

    return json.decode(response.body())

def fetch_mock_data():
    return {
        "score": 77,
        "temp": 25,
        "humid": 77,
        "co2": 777,
        "pm25": 7,
        "voc": 777,
    }

def render_display(config, data):
    error = data.get("error")
    if error:
        return render_error(config, error)

    return render.Root(child = render_data(config, data))

def render_data(config, data):
    celsius = config.bool("celsius", False)

    if celsius:
        temperature = data["temp"]
    else:
        temperature = data["temp"] * 9 / 5 + 32

    table_width = 38
    return render.Box(
        padding = 0,
        child = render.Row(
            children = [
                render.Box(
                    height = 32,
                    width = table_width,
                    child = render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Column(
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Text(
                                            content = "Temp",
                                            font = "tb-8",
                                            color = get_color(data["temp"], TEMP_COLOR_MAP),
                                        ),
                                        render.Text(
                                            content = str(int(temperature)),
                                            font = "tb-8",
                                            color = get_color(data["temp"], TEMP_COLOR_MAP),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Text(
                                            content = "RH%",
                                            font = "tb-8",
                                            color = get_color(data["humid"], RH_COLOR_MAP),
                                        ),
                                        render.Text(
                                            content = str(int(data["humid"])),
                                            font = "tb-8",
                                            color = get_color(data["humid"], RH_COLOR_MAP),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Text(
                                                    content = "CO",
                                                    font = "tb-8",
                                                    color = get_color(data["co2"], CO2_COLOR_MAP),
                                                ),
                                                render.Text(
                                                    content = "2",
                                                    height = 8,
                                                    font = "CG-pixel-3x5-mono",
                                                    color = get_color(data["co2"], CO2_COLOR_MAP),
                                                ),
                                            ],
                                        ),
                                        render.Text(
                                            content = str(int(data["co2"])),
                                            font = "tb-8",
                                            color = get_color(data["co2"], CO2_COLOR_MAP),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Text(
                                                    content = "PM",
                                                    font = "tb-8",
                                                    color = get_color(data["pm25"], PM_COLOR_MAP),
                                                ),
                                                render.Text(
                                                    content = "2",
                                                    height = 7,
                                                    font = "CG-pixel-3x5-mono",
                                                    color = get_color(data["pm25"], PM_COLOR_MAP),
                                                ),
                                                render.Text(
                                                    content = ".",
                                                    height = 8,
                                                    font = "tb-8",
                                                    color = get_color(data["pm25"], PM_COLOR_MAP),
                                                ),
                                                render.Text(
                                                    content = "5",
                                                    height = 7,
                                                    font = "CG-pixel-3x5-mono",
                                                    color = get_color(data["pm25"], PM_COLOR_MAP),
                                                ),
                                            ],
                                        ),
                                        render.Text(
                                            content = str(int(data["pm25"])),
                                            font = "tb-8",
                                            color = get_color(data["pm25"], PM_COLOR_MAP),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ),
                render.Box(
                    height = 32,
                    width = 64 - table_width,
                    child = render.Column(
                        main_align = "center",
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(
                                        child = render.Circle(
                                            diameter = 20,
                                            color = get_color(
                                                data["score"],
                                                AWAIR_COLOR_MAP,
                                            ),
                                        ),
                                    ),
                                    render.Box(
                                        child = render.Text(
                                            content = str(int(data["score"])),
                                            font = "6x13",
                                            color = WHITE,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

# Renders a (possibly quite long) error message, splitting into 16-char lines.
def render_error(config, message):
    n_lines = len(message) // 16 + 1
    messages = []
    for _ in range(n_lines):
        messages.append(
            render.Text(
                content = message[:16],
                font = "tom-thumb",
                color = RED,
            ),
        )
        message = message[16:]

    return render.Root(
        delay = 3000,  # milliseconds to show each frame
        child = render.Animation(
            children = [
                render_data(config, fetch_mock_data()),
                render.Column(children = messages),
            ],
        ),
    )

GREEN = "#41b942"
YELLOW = "#fcd026"
YELLOW_ORANGE = "#fba905"
ORANGE = "f78703"
RED = "#e8333a"
WHITE = "#ffffff"

AWAIR_COLOR_MAP = [
    {"range": 80, "color": GREEN},
    {"range": 60, "color": YELLOW_ORANGE},
    {"range": 0, "color": RED},
]

RH_COLOR_MAP = [
    {"range": 80.5, "color": RED},
    {"range": 64.5, "color": ORANGE},
    {"range": 60.5, "color": YELLOW_ORANGE},
    {"range": 50.5, "color": YELLOW},
    {"range": 39.5, "color": GREEN},
    {"range": 34.5, "color": YELLOW},
    {"range": 19.5, "color": YELLOW_ORANGE},
    {"range": 14.5, "color": ORANGE},
    {"range": 0, "color": RED},
]

CO2_COLOR_MAP = [
    {"range": 2500.5, "color": RED},
    {"range": 1500.5, "color": ORANGE},
    {"range": 1000.5, "color": YELLOW_ORANGE},
    {"range": 600.5, "color": YELLOW},
    {"range": 400, "color": GREEN},
]

TEMP_COLOR_MAP = [
    {"range": 33.5, "color": RED},
    {"range": 31.5, "color": ORANGE},
    {"range": 26.5, "color": YELLOW_ORANGE},
    {"range": 25.5, "color": YELLOW},
    {"range": 17.5, "color": GREEN},
    {"range": 16.5, "color": YELLOW},
    {"range": 10.5, "color": YELLOW_ORANGE},
    {"range": 8.5, "color": ORANGE},
    {"range": 0, "color": RED},
]

PM_COLOR_MAP = [
    {"range": 75.5, "color": RED},
    {"range": 55.5, "color": ORANGE},
    {"range": 35.5, "color": YELLOW_ORANGE},
    {"range": 15.5, "color": YELLOW},
    {"range": 0, "color": GREEN},
]

def get_color(score, color_map):
    default = WHITE

    for item in color_map:
        if score >= item["range"]:
            return item["color"]

    return default

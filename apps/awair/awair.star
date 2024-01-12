"""
Applet: Awair
Summary: Awair air quality data
Description: Display air quality data for an Awair device.
Author: tabrindle, flavorjones
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CLOUD_API_TTL = 300  # 5 minutes, see README.md

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "celsius",
                name = "Use Celsius?",
                desc = "Use Celsius instead of default Fahrenheit.",
                icon = "temperatureLow",
                default = False,
            ),
            schema.Dropdown(
                id = "api_connection_type",
                name = "Awair API",
                desc = "The method used to fetch Awair data.",
                icon = "houseSignal",
                default = API_CONNECTION_TYPE_OPTIONS[0].value,
                options = API_CONNECTION_TYPE_OPTIONS,
            ),
            schema.Generated(
                id = "generated",
                source = "api_connection_type",
                handler = api_connection_options,
            ),
        ],
    )

API_CONNECTION_TYPE_OPTIONS = [
    schema.Option(display = "Awair Local API", value = "local"),
    schema.Option(display = "Awair Cloud API (Token)", value = "cloud_token"),
]

def api_connection_options(api_connection_type):
    if api_connection_type == "local":
        return [
            schema.Text(
                id = "ip_address",  # original schema's name for this field
                name = "Public IP address and port of Awair device",
                desc = "Requires a public IP address with port forwarding to an Awair device configured for Local API access.",
                icon = "computer",
            ),
        ]
    elif api_connection_type == "cloud_token":
        return [
            schema.Text(
                id = "bearer_token",
                name = "Access token for Awair Developer API",
                desc = "Your API access token from your Awair developer console at https://developer.getawair.com/.",
                icon = "key",
            ),
            schema.Text(
                id = "device_id",
                name = "Awair device id",
                desc = "The device's integer deviceID, see 'GET Devices' at https://developer.getawair.com/.",
                icon = "server",
            ),
            schema.Dropdown(
                id = "device_type",
                name = "Awair device type",
                desc = "The device's deviceType, see 'GET Devices' at https://developer.getawair.com/.",
                icon = "shapes",
                default = API_DEVICE_TYPE_OPTIONS[0].value,
                options = API_DEVICE_TYPE_OPTIONS,
            ),
        ]
    else:
        return []

API_DEVICE_TYPE_OPTIONS = [
    schema.Option(display = "awair-element", value = "awair-element"),
    schema.Option(display = "awair-r2", value = "awair-r2"),
]

def main(config):
    return render_display(config, fetch_data(config))

#
#  data fetching functions
#
def fetch_data(config):
    if config.str("api_connection_type") == "cloud_token":
        data = fetch_cloud_data_by_token(config)
        if "error" in data:
            return data

        sensors = data["data"][0]["sensors"]
        return {
            "temp": sensor_value(sensors, "temp"),
            "humid": sensor_value(sensors, "humid"),
            "co2": sensor_value(sensors, "co2"),
            "pm25": sensor_value(sensors, "pm25"),
            "voc": sensor_value(sensors, "voc"),
            "score": data["data"][0]["score"],
        }

    else:  # local API
        ip_address = config.str("ip_address", "")
        if not ip_address:
            return {
                "error": "Displaying mock " + "data.           " + "Please configure" + "the API.",
                "mock": True,
            }

        response = http.get("http://{}/air-data/latest".format(ip_address))
        if response.status_code != 200:
            return {"error": "status {}".format(response.status_code)}

        return json.decode(response.body())

def fetch_cloud_data_by_token(config):
    bearer_token = config.get("bearer_token")
    if not bearer_token:
        return {"error": "No token. Get one at developer.getawair.com"}

    device_id = config.get("device_id")
    if not device_id:
        return {"error": "No device ID. See how to look yours up at developer.getawair.com"}

    device_type = config.get("device_type")
    if not device_type:
        return {"error": "No device type. See how to look yours up at developer.getawair.com"}

    url = "https://developer-apis.awair.is/v1/users/self/devices/{}/{}/air-data/latest".format(
        device_type,
        device_id,
    )
    headers = {"authorization": "Bearer {}".format(bearer_token)}

    response = http.get(
        url = url,
        headers = headers,
        ttl_seconds = CLOUD_API_TTL,
    )
    if response.status_code != 200:
        data = response.json()
        data["error"] = "status {}".format(response.status_code)
        return data

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

def sensor_value(sensors, key):
    for sensor in sensors:
        if sensor["comp"] == key:
            return sensor["value"]
    return None

#
#  rendering functions
#
def render_display(config, data):
    error = data.get("error")
    if error:
        return render_error(config, data)

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
# To ensure we have a good screenshot in the app store, if data["mock"] is True, also render mock data.
def render_error(config, data):
    message = data.get("error")
    if data.get("message"):
        message += ": " + data["message"]

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

    children = []
    if data.get("mock"):
        children.append(render_data(config, fetch_mock_data()))

    children.append(render.Column(children = messages))

    return render.Root(
        delay = 3000,  # milliseconds to show each frame
        child = render.Animation(children = children),
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

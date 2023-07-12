"""
Applet: UV
Summary: UV index
Description: UV index for your location.
Author: j-esse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

REFRESH_RATE = 60 * 60  # 60 minutes in seconds
OPENWEATHERMAP_URL = "https://api.openweathermap.org/data/3.0/onecall"

uv_colors = [
    "#299501",
    "#299501",
    "#299501",
    "#f7e401",
    "#f7e401",
    "#f7e401",
    "#f95901",
    "#f95901",
    "#d90011",
    "#d90011",
    "#d90011",
    "#6c49cb",
]

def main(config):
    weather_data = get_weather_data(config)

    if weather_data == None:
        return []

    timezone = json.decode(config.get("location"))["timezone"]
    now = time.now().in_location(timezone)

    current_uv = weather_data["current"]["uvi"]
    current_dt = time.from_timestamp(math.floor(weather_data["current"]["dt"])).in_location(timezone)

    max_uv = current_uv

    next_hour_uv = None
    next_hour_dt = None

    for hour_weather in weather_data["hourly"]:
        hour_timestamp = time.from_timestamp(math.floor(hour_weather["dt"])).in_location(timezone)
        hour_uvi = hour_weather["uvi"]

        if hour_timestamp > now and hour_timestamp.day == now.day:
            if hour_uvi > max_uv:
                max_uv = hour_uvi

        if hour_timestamp > now and next_hour_uv == None:
            next_hour_uv = hour_uvi
            next_hour_dt = hour_timestamp

    # interpolate between last result and next hour
    if next_hour_uv != None and next_hour_dt != None:
        current_uv = current_uv + (next_hour_uv - current_uv) * (now - current_dt).seconds / (next_hour_dt - current_dt).seconds

    columns = [
        render_uv_circle_column("UV", current_uv),
    ]

    if math.round(current_uv) != math.round(max_uv):
        columns.append(render_uv_circle_column("Later", max_uv))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = columns,
        ),
    )

def render_uv_circle_column(title, uv_index):
    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Text(title),
            render_uv_circle(uv_index),
        ],
    )

def render_uv_circle(uv_index):
    uv_index_int = math.floor(math.round(uv_index))

    uv_color = uv_colors[11]
    if uv_index < 11:
        uv_color = uv_colors[uv_index_int]

    return render.Circle(
        color = uv_color,
        diameter = 22,
        child = render.Text(
            str(uv_index_int),
            color = "#000000",
            font = "10x20",
        ),
    )

def get_weather_data(config):
    api_key = config.get("api_key", None)
    location = config.get("location", None)

    if api_key == None:
        print("Config missing api_key")
        return None
    if location == None:
        print("Config missing location")
        return None

    location = json.decode(location)
    query = "%s?lat=%s&lon=%s&appid=%s" % (OPENWEATHERMAP_URL, location["lat"], location["lng"], api_key)

    res = http.get(url = query, ttl_seconds = REFRESH_RATE)

    if res.status_code != 200:
        print("Open Weather request failed with status %d", res.status_code)
        return None

    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Open Weather API Key",
                desc = "Enter API key",
                icon = "certificate",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display UV index",
            ),
        ],
    )

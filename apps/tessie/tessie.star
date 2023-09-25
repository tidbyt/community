"""
Applet: Tessie
Summary: Tessie API
Description: Shows information from the Tessie API.
Author: inderpal
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

API_KEY = ""
VIN = ""
TESSIE_URL = "https://api.tessie.com/"
TESLA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAABLAAAATgAQMAAADdYSl7AAAABlBMVEX////VAADegCSlAAADQElEQVR42u3bMQrDMBBE0b3/pZ3WKRYktNhD8qYWX68XqityhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFFcmqx4eFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhZXMqphhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWEls174JImFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhRXM6g6tPEmuXLbbwcLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCymHVwU5AXQ0LCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC+s3WF+5qQ4WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFlY8a+oJc6Wz8W0SCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwvrQdb96LWwE1BXw8LCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCSmbt7hzUlrGwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsF5ldbiBJhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFlaDG6thYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYf0xa3ZYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFgB+wA1ifV7T8t4hwAAAABJRU5ErkJggg==
""")
BATTERY_COLOR = "#ffffff"
LOW_BATTERY_COLOR = "#fff500"
EMPTY_BATTERY_COLOR = "#ff0000"

def main(config):
    display_name = "Tesla"
    battery_level = "Add Key"
    battery_range = "And Vin"
    battery_color = BATTERY_COLOR
    api_key = "Bearer: "
    api_key += config.str("api_key", API_KEY)
    vin = config.str("vin", VIN)
    url = "{}/{}/state".format(TESSIE_URL, vin)

    if config.str("vin", API_KEY) == "" or config.str("vin", VIN) == "":
        display_name = "Tesla"
        battery_level = "Add Key"
        battery_range = "And Vin"
    else:
        rep = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 240)
        if rep.status_code == 200:
            display_name = str(rep.json()["display_name"])
            battery_percentage = int(math.round(rep.json()["charge_state"]["battery_level"]))
            battery_level = str(battery_percentage) + "%"
            battery_range = str(int(math.round(rep.json()["charge_state"]["battery_range"]))) + "mi"

            if battery_percentage > 10 and battery_percentage < 21:
                battery_color = LOW_BATTERY_COLOR
            elif battery_percentage < 11:
                battery_color = EMPTY_BATTERY_COLOR
            else:
                battery_color = BATTERY_COLOR

        else:
            battery_level = "Code {}".format(rep.status_code)
            battery_range = ""

    return render_view(display_name, battery_level, battery_range, battery_color)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Tessie API Key",
                icon = "key",
            ),
            schema.Text(
                id = "vin",
                name = "VIN Number",
                desc = "Tesla VIN Number",
                icon = "car",
            ),
        ],
    )

def render_title(display_name):
    return render.Row(
        children = [
            render.Text(
                content = display_name,
                color = "#ff0000",
                font = "tom-thumb",
            ),
        ],
    )

def render_battery(battery_level, battery_color):
    return render.Row(
        children = [
            render.Text(
                content = battery_level,
                color = battery_color,
                font = "tom-thumb",
            ),
        ],
    )

def render_range(battery_range, battery_color):
    return render.Row(
        children = [
            render.Text(
                content = battery_range,
                color = battery_color,
                font = "tom-thumb",
            ),
        ],
    )

def render_label(stack_component):
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = TESLA_ICON, height = 17),
            stack_component,
        ],
    )

def render_stack(display_name, battery_level, battery_range, battery_color):
    return render.Column(
        children = [
            render_title(display_name),
            render_battery(battery_level, battery_color),
            render_range(battery_range, battery_color),
        ],
    )

def render_view(display_name, battery_level, battery_range, battery_color):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "left",
            children = [
                render_label(render_stack(display_name, battery_level, battery_range, battery_color)),
            ],
        ),
    )

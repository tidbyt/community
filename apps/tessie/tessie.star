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

def main(config):
    api_key = "Bearer: "
    api_key += config.str("api_key", API_KEY)
    vin = config.str("vin", VIN)
    url = "{}/{}/state".format(TESSIE_URL, vin)

    rep = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 240)

    if rep.status_code != 200:
        return render.Root(
            child = render.Text("Error {}!".format(rep.status_code)),
        )

    display_name = str(rep.json()["display_name"])
    battery_level = str(int(math.round(rep.json()["charge_state"]["battery_level"]))) + "%"
    battery_range = str(int(math.round(rep.json()["charge_state"]["battery_range"]))) + "mi"

    battery_component = render.Row(
        children = [
            render.Text(
                content = battery_level,
                font = "tom-thumb",
            ),
        ],
    )

    range_component = render.Row(
        children = [
            render.Text(
                content = battery_range,
                font = "tom-thumb",
            ),
        ],
    )

    stax = render.Column(
        children = [
            render.Text(
                content = display_name,
                color = "#ff0000",
                font = "tom-thumb",
            ),
            battery_component,
            range_component,
        ],
    )

    labelcomponent = None
    labelcomponent = render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = TESLA_ICON, height = 17),
            stax,
        ],
    )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "left",
            children = [
                labelcomponent,
            ],
        ),
    )

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
                icon = "key",
            ),
        ],
    )

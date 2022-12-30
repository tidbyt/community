"""
Applet: Hass Entity
Summary: Display Hass entity state
Description: Display an externaly accessible Home Assistant entity state or attribute.
Author: InTheDaylight14
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("http.star", "http")
load("cache.star", "cache")

STATIC_ENDPOINT = "/api/states"

def main(config):
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_ip",
                name = "Home Assistant http(s)://IP(:Port)",
                desc = "Home Assistant external IP address (and optional port).",
                icon = "key",
            ),
            schema.Text(
                id = "token",
                name = "Token",
                desc = "Home Assistant Long-Lived Access Token.",
                icon = "key",
            ),
            schema.Text(
                id = "entity_name",
                name = "Entity Name",
                desc = "Entity name ex. sensor.front_door",
                icon = "key",
            ),
            schema.Text(
                id = "attribute",
                name = "Attribute",
                desc = "Optionaly show the value of an attribute.",
                icon = "key",
            ),
            schema.Text(
                id = "friendly_name",
                name = "Friendly Name",
                desc = "Optionaly override the entity friently name.",
                icon = "key",
            ),
        ],
    )

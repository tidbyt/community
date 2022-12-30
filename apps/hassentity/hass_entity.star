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

def is_string_blank(string):
    return string == None or len(string) == 0

def get_entity_states(config):
    ha_ip = config.get("ha_ip", None)
    token = config.get("token", None)
    entity_name = config.get("entity_name", None)

    if is_string_blank(token) or is_string_blank(entity_name) or is_string_blank(ha_ip):
        return []

    full_token = "Bearer " + token
    full_url = ha_ip + STATES_URL + entity_name
    headers = {
        "Authorization": full_token,
        "content-type": "application/json",
    }

    res = http.get(
        url = full_url,
        headers = headers,
    )

    if res.status_code != 200:
        fail("HA Rest API request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    states = res.json()
    print(states)

    return states

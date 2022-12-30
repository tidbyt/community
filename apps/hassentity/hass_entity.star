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

STATIC_ENDPOINT = "/api/states/"

def main(config):
    entity_name = config.get("entity_name", None)
    attribute = config.get("attribute", None)

    if is_string_blank(entity_name):
        print("using sample data")
        states = SAMPLE_DATA
    else:
        states = get_entity_states(config)

    friendly_name = config.get("friendly_name", None)
    if is_string_blank(friendly_name):
        friendly_name = states["attributes"]["friendly_name"]

    if is_string_blank(attribute):
        state = states["state"]
    else:
        state = states["attributes"][attribute]

    if "unit_of_measurement" in states["attributes"].keys():
        state = state + states["attributes"]["unit_of_measurement"]

    icon = None
    if "icon" in states["attributes"].keys():
        icon = states["attributes"]["icon"]

    return render.Root(
        delay = 6000,
        child = render.Column(
            children = [
                render.WrappedText(
                    content = friendly_name,
                    color = "#ffffff",
                    linespacing = 0,
                    width = 64,
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = "#ffffff",
                ),
                render.Marquee(
                    height = 23,  # 32 - 8 (author line) - 1 (divider line)
                    offset_start = 10,
                    offset_end = 10,
                    child = render.WrappedText(
                        content = state,
                        width = 64,
                    ),
                    scroll_direction = "vertical",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_ip",
                name = "Home Assistant External Url",
                desc = "External HA Url (and optional port). Ex. https://abc.ui.nabu.casa or https://hass.mydomain:8123",
                icon = "link",
            ),
            schema.Text(
                id = "token",
                name = "Token",
                desc = "Home Assistant Long-Lived Access Token",
                icon = "key",
            ),
            schema.Text(
                id = "entity_name",
                name = "Entity Name",
                desc = "Entity name ex. 'sensor.front_door'",
                icon = "inputText",
            ),
            schema.Text(
                id = "attribute",
                name = "Attribute",
                desc = "Optionaly show the value of an attribute for the entity",
                icon = "inputText",
            ),
            schema.Text(
                id = "friendly_name",
                name = "Name Override",
                desc = "Optionaly override the entity friendly name",
                icon = "inputText",
            ),
        ],
    )

def is_string_blank(string):
    return string == None or len(string) == 0

# Retrieve entity state from Home Assistant, return json response
def get_entity_states(config):
    ha_ip = config.get("ha_ip", None)
    token = config.get("token", None)
    entity_name = config.get("entity_name", None)

    if is_string_blank(token) or is_string_blank(entity_name) or is_string_blank(ha_ip):
        return []

    full_token = "Bearer " + token
    full_url = ha_ip + STATIC_ENDPOINT + entity_name
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

SAMPLE_DATA = {
    "entity_id": "switch.front_door",
    "state": "off",
    "attributes": {
        "friendly_name": "Front Door",
    },
    "last_changed": "2020-12-30T04:00:00.000000+00:00",
    "last_updated": "2020-12-30T04:00:00.000000+00:00",
    "context": {
        "id": "ABCDEFG",
    },
}

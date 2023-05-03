"""
Applet: Hass Entity
Summary: Display Hass entity state
Description: Display an externally accessible Home Assistant entity state or attribute.
Author: InTheDaylight14
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATIC_ENDPOINT = "/api/states/"
DEFAULT_COLOR = "#aaaaaa"

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

    header_color = config.get("header_color", DEFAULT_COLOR)
    separator_color = config.get("separator_color", DEFAULT_COLOR)
    value_color = config.get("value_color", DEFAULT_COLOR)

    return render.Root(
        delay = 6000,
        child = render.Column(
            children = [
                render.WrappedText(
                    content = friendly_name,
                    color = header_color,
                    linespacing = 0,
                    width = 64,
                ),
                render.Box(
                    height = 1,
                    width = 64,
                    color = separator_color,
                ),
                render.Marquee(
                    height = 23,  # 32 - 8 (author line) - 1 (divider line)
                    offset_start = 10,
                    offset_end = 10,
                    child = render.WrappedText(
                        content = state,
                        width = 64,
                        color = value_color,
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
                id = "nabu_casa_url_key",
                name = "Nabu Casa Url Key",
                desc = "The random letters and numbers in your Nabu Casa URL. Ex. Input 'abc123' for this nabu casa url https://abc123.ui.nabu.casa",
                icon = "link",
            ),
            schema.Text(
                id = "token",
                name = "Long-Lived Token",
                desc = "Home Assistant Long-Lived Access Token. Profile -> Long-Lived Access Tokens -> Create Token",
                icon = "key",
            ),
            schema.Text(
                id = "entity_name",
                name = "Entity Name",
                desc = "Entity name ex. 'sensor.front_door'",
                icon = "textHeight",
            ),
            schema.Text(
                id = "attribute",
                name = "Attribute",
                desc = "Optionaly show the value of an attribute for the entity",
                icon = "textHeight",
            ),
            schema.Text(
                id = "friendly_name",
                name = "Name Override",
                desc = "Optionaly override the entity friendly name",
                icon = "textHeight",
            ),
            schema.Text(
                id = "header_color",
                name = "Header Color",
                desc = "Provide a hex code for the header color Ex. #ff00ff",
                icon = "palette",
            ),
            schema.Text(
                id = "separator_color",
                name = "Separator Color",
                desc = "Provide a hex code for the separator color Ex. #ff00ff",
                icon = "palette",
            ),
            schema.Text(
                id = "value_color",
                name = "Value Color",
                desc = "Provide a hex code for the value color Ex. #ff00ff",
                icon = "palette",
            ),
        ],
    )

def is_string_blank(string):
    return string == None or len(string) == 0

# Retrieve entity state from Home Assistant, return json response
def get_entity_states(config):
    nabu_casa_url_key = config.get("nabu_casa_url_key", None)
    token = config.get("token", None)
    entity_name = config.get("entity_name", None)

    if is_string_blank(token) or is_string_blank(entity_name) or is_string_blank(nabu_casa_url_key):
        return []

    chached_states = cache.get(token)

    if chached_states != None:
        print("Using cached state")
        return json.decode(chached_states)

    full_token = "Bearer " + token
    full_url = "https://" + nabu_casa_url_key + ".ui.nabu.casa" + STATIC_ENDPOINT + entity_name
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

    cache.set(token, json.encode(states), ttl_seconds = 6)

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

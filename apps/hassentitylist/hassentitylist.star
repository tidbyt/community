"""
Applet: HomeAssistant Entity List
Summary: Displays multiple HomeAssistant entities
Description: Displays multiple HomeAssistant entities (e.g. step counts)
Author: James Woglom
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("math.star", "math")

def main(config):
    children = add_children(config, "entity_1", "entity_2", "entity_3", "entity_4")

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def add_children(config, *childs):
    items = {}
    counts = {}
    for child in childs:
        n, entity = render_entity(child, config)
        if entity:
            items[child] = entity
            counts[child] = n
        else:
            items[child] = None
    
    children = []
    if config.bool("sort_entities"):
        for i in sorted(counts.items())[::-1]:
            children.append(items[i[0]])
    else:
        for child in childs:
            if items[child]:
                children.append(items[child])
    
    return children

def render_entity(entity_id, config):
    name = config.get(entity_id+"_name")
    fetch = fetch_entity(entity_id, config)
    if not fetch:
        return 0, None
    
    count = int(fetch["state"])
    return count, render.Row(
        main_align = "space_between",
        expanded = True,
        children=[
            render.Text(
                content=" " + name,
                font = "tb-8",
                color = "#f1f1f1",
            ),
            render.Text(
                content = num_format(fetch["state"]) + " ",
                font = "tb-8",
                color = get_color(count, config)
            ),
        ]
    )

def num_format(raw):
    num = raw + ""
    if len(num) > 3:
        return num[:-3]+","+num[-3:]
    return num

def get_color(count, config):
    if not config.get("target_value"):
        return "#ffffff"

    range = ["#AD1A1A", "#ad3a1a", "#ad721a", "#ada11a", "#92ad1a", "#37ad1a"]
    max_target = int(config.get("target_value"))
    if count >= max_target:
        return range[-1]
    
    i = int(((len(range) - 1) * count) / max_target)
    return range[i]

def fetch_entity(entity_id, config):
    if config.get(entity_id):
        rep = http.get(config.get("ha_url") + "/api/states/" + config.get(entity_id), ttl_seconds = 10, headers = {
            "Authorization": "Bearer " + config.get("ha_token")
        })
        if rep.status_code != 200:
            fail("%s request failed with status %d: %s" % (entity_id, rep.status_code, rep.body()))
        return rep.json()
    return None


def get_schema():
    entity_schema = []
    for i in ["1", "2", "3", "4"]:
        entity_schema += [
            schema.Text(
                id = "entity_" + i,
                name = "Entity ID " + i,
                desc = "Entity ID " + i + " (e.g. sensor.steps)",
                icon = "1"
            ),
            schema.Text(
                id = "entity_" + i + "_name",
                name = "Entity Name " + i,
                desc = "Entity Name " + i + " (e.g. My Steps)",
                icon = "1"
            ),
        ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "HomeAssistant URL",
                desc = "HomeAssistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "book"
            ),
            schema.Text(
                id = "ha_token",
                name = "HomeAssistant Token",
                desc = "HomeAssistant Token. Find in User Settings > Long-lived access tokens.",
                icon = "book"
            ),
            schema.Toggle(
                id = "sort_entities",
                name = "Sort entities",
                desc = "Sort entities by value (biggest value first). If not set, then entities will be shown in the order specified.",
                icon = "compress",
                default = False,
            ),
            schema.Text(
                id = "target_value",
                name = "Target value",
                desc = "Target value number. If set, then a red-to-green range will be used for values, with this number at the top of the range.",
                icon = "compress",
                default = ""
            ),
        ] + entity_schema,
    )
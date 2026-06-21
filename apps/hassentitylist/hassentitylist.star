"""
Applet: HASS Entity List
Summary: Displays multiple HomeAssistant entities
Description: Displays multiple HomeAssistant entities (e.g. step counts)
Author: James Woglom
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

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
    counts = []
    for child in childs:
        n, entity = render_entity(child, config)
        if entity:
            items[child] = entity
            counts.append([n, child])
        else:
            items[child] = None

    children = []
    if config.bool("sort_entities"):
        for i in sorted(counts)[::-1]:
            children.append(items[i[1]])
    else:
        for child in childs:
            if items[child]:
                children.append(items[child])

    return children

def render_entity(entity_id, config):
    name = config.get(entity_id + "_name")
    if not name:
        name = config.get(entity_id)
    fetch = fetch_entity(entity_id, config)
    if not fetch:
        return 0, None

    count = float(fetch["state"])
    unit = ""
    if config.bool("show_units") and "attributes" in fetch and "unit_of_measurement" in fetch["attributes"]:
        unit = fetch["attributes"]["unit_of_measurement"] + " "
    return count, render.Row(
        main_align = "space_between",
        expanded = True,
        children = [
            render.Text(
                content = " " + name,
                font = "tb-8",
                color = "#f1f1f1",
            ),
            render.Text(
                content = num_format(fetch["state"], config.get("decimal_places")) + " " + unit,
                font = "tb-8",
                color = get_color(count, config),
            ),
        ],
    )

def group_thousands(int_part):
    neg = int_part.startswith("-")
    digits = int_part[1:] if neg else int_part
    grouped = ""
    for i in range(len(digits)):
        if i > 0 and (len(digits) - i) % 3 == 0:
            grouped += ","
        grouped += digits[i]
    return ("-" + grouped) if neg else grouped

def num_format(raw, precision):
    num = raw + ""

    # Fixed precision: round and group thousands via humanize.
    if precision and precision.isdigit():
        places = int(precision)
        format = "#,###." + ("#" * places) if places > 0 else "#,###."
        return humanize.float(format, float(num))

    # Auto: keep the value as reported, only grouping the integer part so
    # decimals (e.g. "7.032") are no longer mangled into "7,.032".
    parts = num.split(".")
    parts[0] = group_thousands(parts[0])
    return ".".join(parts)

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
            "Authorization": "Bearer " + config.get("ha_token"),
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
                icon = "1",
            ),
            schema.Text(
                id = "entity_" + i + "_name",
                name = "Entity Name " + i,
                desc = "Entity Name " + i + " (e.g. My Steps)",
                icon = "1",
            ),
        ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "HomeAssistant URL",
                desc = "HomeAssistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "book",
            ),
            schema.Text(
                id = "ha_token",
                name = "HomeAssistant Token",
                desc = "HomeAssistant Token. Find in User Settings > Long-lived access tokens.",
                icon = "book",
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
                default = "",
            ),
            schema.Toggle(
                id = "show_units",
                name = "Show units",
                desc = "Show units for entities which have them.",
                icon = "eye",
                default = True,
            ),
            schema.Text(
                id = "decimal_places",
                name = "Decimal places",
                desc = "Number of decimal places to show. Leave blank to show the value as reported.",
                icon = "hashtag",
                default = "",
            ),
        ] + entity_schema,
    )

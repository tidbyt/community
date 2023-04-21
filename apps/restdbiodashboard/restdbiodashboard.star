"""
Applet: RestDbIoDashboard
Summary: Restdb.io dashboard
Description: Generic dashboard based on a restdb.io database.
Author: romerod
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TTL_ICONS = 216000

def render_fail(rep):
    return render.Root(render.Box(render.WrappedText("%s" % rep.status_code), color = "#AA0000"))

def get_col(text, subtext, coltext, colsubtext, icon):
    return render.Column(
        cross_align = "center",
        main_align = "space_evenly",
        expanded = True,
        children = [
            render.Image(src = icon, height = 15),
            render.Column(
                cross_align = "center",
                children = [
                    render.Text(text, color = coltext),
                    render.Text(subtext, color = colsubtext),
                ],
            ),
        ],
    )

def get_row(text, subtext, coltext, colsubtext, icon):
    return render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "left",
        children = [
            render.Padding(pad = (2, 0, 0, 0), child = render.Image(src = icon, height = 10, width = 10)),
            render.Padding(pad = (2, 1, 0, 0), child = render.Text(text, color = coltext)),
            render.Padding(pad = (2, 1, 0, 0), child = render.Text(subtext, color = colsubtext)),
        ],
    )

def main(config):
    icons = dict()

    db_name = config.get("db_name")

    if not db_name:
        return []

    db_name = "%s" % db_name
    api_key = "%s" % config.get("api_key")

    if config.bool("reset_icon_cache"):
        return reset_icon_cache(db_name, api_key)

    rep = http.get(
        "https://{}.restdb.io/rest/home?max=3&q={{%22visible%22:true}}&sort=order".format(db_name),
        headers = {
            "Accept": "application/json",
            "x-apikey": api_key,
        },
    )

    if rep.status_code != 200:
        print(rep.body())
        return render_fail(rep)

    items = json.decode(rep.body())

    icons_to_load = list()

    for item in items:
        icon_cache_key = "{}-icon-{}".format(db_name, item["icon"])
        icon = cache.get(icon_cache_key)
        if not icon:
            icons_to_load.insert(-1, item["icon"])
        else:
            icons.update([(item["icon"], icon)])

    if len(icons_to_load) > 0:
        fail = load_icons(icons_to_load, icons, db_name, api_key)
        if fail:
            return fail

    for name in icons:
        icon_cache_key = "{}-icon-{}".format(db_name, name)
        cache.set(icon_cache_key, icons[name], ttl_seconds = TTL_ICONS)

    if len(items) == 0:
        return []

    if config.bool("vertical"):
        rows = list()
        for item in items:
            rows.append(get_row(item["text"], item["subtext"], item["colortext"], item["colorsubtext"], base64.decode(icons.get(item["icon"]))))

        return render.Root(child =
                               render.Column(
                                   children = rows,
                                   main_align = "space_around",
                                   cross_align = "center",
                                   expanded = True,
                               ))

    columns = list()
    for item in items:
        columns.append(get_col(item["text"], item["subtext"], item["colortext"], item["colorsubtext"], base64.decode(icons.get(item["icon"]))))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            children = columns,
        ),
    )

def reset_icon_cache(db_name, api_key):
    load_icon_names = 'https://{}.restdb.io/rest/icons?&h={{"$fields":{{"name":1}}}}'
    load_icon_names = load_icon_names.format(db_name)

    rep = http.get(
        load_icon_names,
        headers = {
            "Accept": "application/json",
            "x-apikey": api_key,
        },
    )

    if rep.status_code != 200:
        print(rep.body())
        return render_fail(rep)

    for icon in json.decode(rep.body()):
        icon_cache_key = "{}-icon-{}".format(db_name, icon["name"])
        cache.set(icon_cache_key, "", ttl_seconds = TTL_ICONS)

    return render.Root(render.Box(render.WrappedText("icon cache reset"), color = "#FFA500"))

def load_icons(icons_to_load, icons, db_name, api_key):
    load_icon_url = 'https://{}.restdb.io/rest/icons?q={{"name":{{"$in":{}}}}}'
    load_icon_url = load_icon_url.format(db_name, json.encode(icons_to_load))

    rep = http.get(
        load_icon_url,
        headers = {
            "Accept": "application/json",
            "x-apikey": api_key,
        },
    )

    if rep.status_code != 200:
        print(rep.body())
        return render_fail(rep)

    print("loaded icons")

    for icon in json.decode(rep.body()):
        icons.update([(icon["name"], icon["data"])])

    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "db_name",
                name = "Database name",
                desc = "The name of the database on restdb.io",
                icon = "database",
            ),
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "The API key to access restdb.io (read only is enough)",
                icon = "user",
            ),
            schema.Toggle(
                id = "vertical",
                name = "Vertical layout?",
                desc = "Show lines instead of columns",
                icon = "gripLines",
                default = False,
            ),
            schema.Toggle(
                id = "reset_icon_cache",
                name = "Reset icon caching",
                desc = "If the script fails due to a badly encoded icon or you change want to change an image, use this to clear the cache",
                icon = "trash",
                default = False,
            ),
        ],
    )

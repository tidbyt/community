load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL_SECONDS = 60

nilWidget = render.Box(width = -1, height = -1)

def main(config):
    result = []
    pages = []

    if (config.str("data_api_url") == None):
        pages.append(wrap_error("CONFIG ERROR", "Atlas Data API URL not set"))

    if (config.str("api_key") == None):
        pages.append(wrap_error("CONFIG ERROR", "Atlas Data API Key not set."))

    if (config.str("datasource") == None):
        pages.append(wrap_error("CONFIG ERROR", "Datasource (Cluster name) not set."))

    if (config.str("database") == None):
        pages.append(wrap_error("CONFIG ERROR", "Database not set."))

    if (config.str("collection") == None):
        pages.append(wrap_error("CONFIG ERROR", "Collection not set."))

    if (config.str("topic") == None):
        pages.append(wrap_error("CONFIG ERROR", "Collection not set."))

    # if no pages / no errors - go grab some notifications
    if (len(pages) == 0):
        res_json = get_cacheable_data(
            config.str("data_api_url"),
            get_headers(config.str("api_key")),
            get_json_body(
                config.str("datasource"),
                config.str("database"),
                config.str("collection"),
                {"topic": config.get("topic", "homeassistant")},
                {"priority": 1, "create_ts": -1},
            ),
        )

        docs = res_json["documents"]

        for doc in docs:
            if (doc.get("page")):
                pages.append(doc["page"])

    if (len(pages) > 0):
        result = render.Root(
            child = render_child(wrap_pages(pages)),
            delay = (int(config.get("root_delay", "3")) * 1000),
            show_full_animation = config.bool("root_show_full_animation", True),
        )

    return result

def get_headers(api_key):
    return {
        "Content-Type": "application/json",
        "Access-Control-Request-Headers": "*",
        "api-key": api_key,
    }

def get_json_body(datasource, database, collection, filter, sort):
    return {
        "dataSource": datasource,
        "database": database,
        "collection": collection,
        "filter": filter,
        "sort": sort,
    }

def get_cacheable_data(url, headers, json_body, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return json.decode(base64.decode(data))

    res = http.post(
        url = url + "/action/find",
        headers = headers,
        json_body = json_body,
    )
    if res.status_code != 200:
        return {"documents": [{"page": wrap_error("API ERROR", str(res.status_code))}]}

    #        fail ("Atlas request failed with status %d", res.status_code)

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return json.decode(res.body())

def wrap_error(title = "No title", message = "No message"):
    return {
        "Column": {
            "children": [
                {
                    "Text": {
                        "content": title,
                        "color": "#ff0000",
                    },
                },
                {
                    "WrappedText": {
                        "content": message,
                        "color": "#ffffff",
                    },
                },
            ],
        },
    }

def wrap_pages(pages = []):
    return {
        "Column": {
            "children": [
                {
                    "Animation": {
                        "children": pages,
                    },
                },
            ],
        },
        "delay": 5000,
        "show_full_animation": True,
    }

def render_child(json):
    widget = json.keys()[0]
    params = json[widget]
    children = []
    child = nilWidget
    result = []
    pad = 0
    data = []
    x_lim = ()
    y_lim = ()

    if (params.get("children")):
        for child in params["children"]:
            children.append(render_child(child))

    if (params.get("child")):
        child = render_child(params["child"])

    if (params.get("pad")):
        if (type(params["pad"]) == "int"):
            pad = params["pad"]
        elif (type(params["pad"]) == "list"):
            pad = (params["pad"][0], params["pad"][1], params["pad"][2], params["pad"][3])

    if (params.get("data")):
        for datum in params["data"]:
            data.append((datum[0], datum[1]))

    if (params.get("x_lim")):
        x_lim = (params["x_lim"][0], params["x_lim"][1])

    if (params.get("y_lim")):
        y_lim = (params["y_lim"][0], params["y_lim"][1])

    if (widget == "Animation"):
        result = render.Animation(
            children = children,
        )
    elif (widget == "Box"):
        result = render.Box(
            child = child,
            width = params.setdefault("width", 0),
            height = params.setdefault("height", 0),
            padding = params.setdefault("padding", 0),
            color = params.setdefault("color", ""),
        )
    elif (widget == "Circle"):
        result = render.Circle(
            color = params.setdefault("color", "#000000"),
            diameter = params.setdefault("diameter", 0),
            child = child,
        )
    elif (widget == "Column"):
        result = render.Column(
            children = children,
            main_align = params.setdefault("main_align", ""),
            cross_align = params.setdefault("cross_align", ""),
            expanded = params.setdefault("expanded", False),
        )
    elif (widget == "Image"):
        result = render.Image(
            src = params.setdefault("src", ""),
            width = params.setdefault("width", 0),
            height = params.setdefault("height", 0),
            delay = params.setdefault("delay", 0),
        )
    elif (widget == "Marquee"):
        result = render.Marquee(
            child = child,
            width = params.setdefault("width", 0),
            height = params.setdefault("height", 0),
            offset_start = params.setdefault("offset_start", 0),
            offset_end = params.setdefault("offset_end", 0),
            scroll_direction = params.setdefault("scroll_direction", ""),
            align = params.setdefault("align", ""),
        )
    elif (widget == "Padding"):
        result = render.Padding(
            child = child,
            pad = pad,
            expanded = params.setdefault("expanded", False),
            color = params.setdefault("color", "#000000"),
        )
    elif (widget == "PieChart"):
        result = render.PieChart(
            colors = params.setdefault("colors", []),
            weights = params.setdefault("weights", []),
            diameter = params.setdefault("diameter", 0),
        )
    elif (widget == "Plot"):
        result = render.Plot(
            data = data,
            width = params.setdefault("width", 0),
            height = params.setdefault("height", 0),
            color = params.setdefault("color", ""),
            color_inverted = params.setdefault("color_inverted", ""),
            x_lim = x_lim,
            y_lim = y_lim,
            fill = params.setdefault("fill", False),
            chart_type = params.setdefault("chart_type", ""),
            fill_color = params.setdefault("fill_color", ""),
            fill_color_inverted = params.setdefault("fill_color", ""),
        )
    elif (widget == "Root"):
        result = render.Root(
            child = child,
            delay = params.setdefault("delay", 0),
            max_age = params.setdefault("max_age", 0),
            show_full_animation = params.setdefault("show_full_animation", False),
        )
    elif (widget == "Row"):
        result = render.Row(
            children = children,
            main_align = params.setdefault("main_align", ""),
            cross_align = params.setdefault("cross_align", ""),
            expanded = params.setdefault("expanded", False),
        )
    elif (widget == "Sequence"):
        result = render.Sequence(
            children = children,
        )
    elif (widget == "Stack"):
        result = render.Stack(
            children = children,
        )
    elif (widget == "Text"):
        result = render.Text(
            content = params.setdefault("content", "[Text] No content."),
            font = params.setdefault("font", ""),
            height = params.setdefault("height", 0),
            offset = params.setdefault("offset", 0),
            color = params.setdefault("color", ""),
        )
    elif (widget == "WrappedText"):
        result = render.WrappedText(
            content = params.setdefault("content", "[Text] No content."),
            font = params.setdefault("font", ""),
            height = params.setdefault("height", 0),
            width = params.setdefault("width", 0),
            linespacing = params.setdefault("linespacing", 0),
            color = params.setdefault("color", ""),
            align = params.setdefault("align", ""),
        )
    else:
        result = render.WrappedText(
            content = widget + " not found..",
            color = "#FF0000",
        )

    return result

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "data_api_url",
                name = "Data API URL:",
                desc = "The Atlas Data API URL.",
                icon = "database",
            ),
            schema.Text(
                id = "api_key",
                name = "Atlas API KEY:",
                desc = "The Atlas API Key for the Data API URL.",
                icon = "database",
            ),
            schema.Text(
                id = "datasource",
                name = "Cluster name:",
                desc = "The Atlas cluster name.",
                icon = "database",
            ),
            schema.Text(
                id = "database",
                name = "Database:",
                desc = "The database name.",
                icon = "database",
            ),
            schema.Text(
                id = "collection",
                name = "Collection:",
                desc = "The collection name.",
                icon = "database",
            ),
            schema.Text(
                id = "topic",
                name = "Topic:",
                desc = "The topic to subscribe to.",
                icon = "pencil",
            ),
            schema.Dropdown(
                id = "root_delay",
                name = "Rotation Speed",
                desc = "Amount of seconds each page is displayed.",
                icon = "gear",
                default = root_delay_options[0].value,
                options = root_delay_options,
            ),
            schema.Toggle(
                id = "root_show_full_animation",
                name = "Show full animation",
                desc = "Determines if the full animation is shown.",
                icon = "gear",
                default = True,
            ),
        ],
    )

root_delay_options = [
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

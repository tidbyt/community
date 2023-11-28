"""
Applet: Meraki Usage
Summary: Monitor Client Usage
Description: Monitor client usages for your Meraki network.
Author: UnBurn
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://api.meraki.com/api/v1"
KB_IN_GB = 1048576
KB_IN_MB = 1024

fake_clients = [
    {
        "description": "Workstation",
        "mac": "aa:bb:cc:dd",
        "usage": {
            "sent": 1232,
            "recv": 1230024,
            "total": 1223000,
        },
    },
    {
        "description": "Fake iPhone",
        "mac": "aa:bb:cc:dd",
        "usage": {
            "sent": 12332,
            "recv": 80222900,
            "total": 52213900,
        },
    },
    {
        "description": "Wireless Cam",
        "mac": "aa:bb:cc:dd",
        "usage": {
            "sent": 12922,
            "recv": 1223,
            "total": 19929000,
        },
    },
]

DOWNLOAD_ARROW = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAIklEQVQIW2NkAIH/QAgDjAyMjCQIImuFGoFHO8wyoCUgJgAfhAwFkW3nPQAAAABJRU5ErkJggg==")
UPLOAD_ARROW = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAKElEQVQIW2NkgAK+Oa/+f0oRYwRxwQRIACYJkmBEFoBJYFeJVTs2QQCKmhaal5lvLwAAAABJRU5ErkJggg==")

def get_usage_with_unit(num):
    val = math.round((num / (KB_IN_GB if num >= KB_IN_GB else KB_IN_MB)) * 100) / 100
    unit = ("GB" if num >= KB_IN_GB else "MB")
    return {
        "value": val,
        "unit": unit,
    }

def get_meraki_clients(api_key, network_id, timespan):
    if api_key == None or network_id == None:
        return fake_clients

    endpoint = "%s/networks/%s/clients" % (API_URL, network_id)
    params = {
        "timespan": timespan,
        "perPage": "1000",
    }

    clients_response = http.get(endpoint, headers = {"Authorization": "Bearer %s" % api_key}, params = params, ttl_seconds = 1800)
    if clients_response.status_code != 200:
        return fake_clients

    clients = clients_response.json()
    if "errors" in clients:
        return fake_clients
    return clients

def get_usage_data(clients):
    download = 0
    upload = 0
    for client in clients:
        usage = client["usage"]
        download += usage["recv"]
        upload += usage["sent"]
    return {
        "download": get_usage_with_unit(download),
        "upload": get_usage_with_unit(upload),
    }

def get_top_clients(clients):
    sorted_clients = sorted(clients, key = lambda c: c["usage"]["total"], reverse = True)
    clients_lengh = len(sorted_clients)
    return sorted_clients[0:min(3, clients_lengh)]

def render_increase_number(num, color):
    renders = []
    num_frames = 30
    increment = num / num_frames
    for i in range(num_frames):
        rendered_value = math.round((increment * i) * 100) / 100
        renders.append(render.Text(content = "%s" % (rendered_value), color = color, font = "tom-thumb"))
        if (i / num_frames) > .75:
            renders.append(render.Text(content = "%s" % (rendered_value), color = color, font = "tom-thumb"))
        if (i / num_frames) > .90:
            renders.append(render.Text(content = "%s" % (rendered_value), color = color, font = "tom-thumb"))
        if (i / num_frames) > .95:
            renders.append(render.Text(content = "%s" % (rendered_value), color = color, font = "tom-thumb"))

    for i in range(500):
        renders.append(render.Text(content = "%s" % num, color = color, font = "tom-thumb"))
    return renders

def main(config):
    api_key = config.get("api_key")
    network_id = config.get("network_id")
    timespan = config.get("timespan", "3600")
    clients = get_meraki_clients(api_key, network_id, timespan)
    usage_data = get_usage_data(clients)
    top_clients = get_top_clients(clients)

    top_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 8, color = "#74C465", child = render.Box(color = "#000000", width = 48, height = 6)),
            render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [render.Text("Meraki Usage", height = 7, font = "tom-thumb", color = "#ffffff")],
            ),
        ],
    )

    animated_download = render.Animation(
        children = render_increase_number(usage_data["download"]["value"], "#00ff00"),
    )
    animated_upload = render.Animation(
        children = render_increase_number(usage_data["upload"]["value"], "#0e9cea"),
    )

    download_render = render.Column(
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    animated_download,
                    render.Image(src = DOWNLOAD_ARROW, width = 5, height = 6),
                ],
            ),
            render.Padding(render.Text(usage_data["download"]["unit"], font = "tom-thumb"), pad = (0, 1, 0, 0)),
        ],
        cross_align = "center",
    )
    upload_render = render.Column(
        children = [
            render.Row(
                cross_align = "center",
                children = [animated_upload, render.Padding(render.Image(src = UPLOAD_ARROW, width = 5, height = 6), pad = (0, 0, 0, 2))],
            ),
            render.Text(usage_data["upload"]["unit"], font = "tom-thumb"),
        ],
        cross_align = "center",
    )

    data_row = render.Padding(
        child = render.Row(
            children = [
                download_render,
                upload_render,
            ],
            expanded = True,
            main_align = "space_around",
            cross_align = "end",
        ),
        pad = (0, 2, 0, 3),
    )

    top_clients_rendered = []
    rank_colors = ["#FFD700", "#c0c0c0", "#cd7f32"]
    rank_i = 0
    for client in top_clients:
        total_usage = client["usage"]["total"]
        usage_in_units = get_usage_with_unit(total_usage)
        name = client["description"] or client["mac"]
        top_clients_rendered.append(
            render.Text(
                content = "%s %s%s" % (name, usage_in_units["value"], usage_in_units["unit"]),
                font = "CG-pixel-3x5-mono",
                color = rank_colors[rank_i],
            ),
        )
        top_clients_rendered.append(
            render.Text(" | ", font = "CG-pixel-3x5-mono"),
        )
        rank_i += 1

    top_clients_rendered.pop()
    top_clients_row = render.Marquee(
        width = 64,
        offset_start = 64,
        child = render.Row(
            expanded = True,
            children = top_clients_rendered,
        ),
    )

    return render.Root(
        child = render.Column(
            children = [top_bar, data_row, top_clients_row],
        ),
    )

OPTIONS = [
    {
        "value": 1800,
        "label": "Last 30 minutes",
    },
    {
        "value": 3600,
        "label": "Last hour",
    },
    {
        "value": 6300,
        "label": "Last 2 hour",
    },
    {
        "value": 21600,
        "label": "Last 6 hour",
    },
    {
        "value": 43200,
        "label": "Last 12 hours",
    },
    {
        "value": 86400,
        "label": "Last day",
    },
    {
        "value": 172800,
        "label": "Last 2 day",
    },
    {
        "value": 604800,
        "label": "Last week",
    },
    {
        "value": 2592000,
        "label": "Last 30 days",
    },
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Cisco Meraki API key",
                desc = "Your API Key to access your data",
                icon = "key",
            ),
            schema.Text(
                id = "network_id",
                name = "Network ID",
                desc = "Network ID of network",
                icon = "wifi",
            ),
            schema.Dropdown(
                id = "timespan",
                name = "Timespan",
                desc = "Timespan for data",
                default = str(OPTIONS[1]["value"]),
                options = [
                    schema.Option(
                        display = opt["label"],
                        value = str(opt["value"]),
                    )
                    for opt in OPTIONS
                ],
                icon = "clock",
            ),
        ],
    )

"""
Applet: Indego
Summary: Indego bike share
Description: Shows available bikes and docks at an Indego station.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

indego_api_endpoint = "https://bts-status.bicycletransit.workers.dev/phl"
indego_green = "#93D500"
indego_blue = "#0082CA"
white = "#fff"
default_dock = "3162.0"
regular_bike = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAADQAAAADfLQUOAAAAhklEQVQ4Ec2SUQ6AIAxDwXhcj+N9wZF0qYUJ/GlCtpX2sQ9T+stX7lTsLO0DM6qGGMS9+ro5Mke6AXJHESEK52ucPSXvI4M4zLqbqXGgGgFh3fqRbjzojc0hPMaa9TrDh4r7A0JUYXxtEJkffQo0kB2AP1jtagoEYHVD/210gxlg14/FtmsFsqhKMWPbUYEAAAAASUVORK5CYII=")
electric_bike = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAADQAAAADfLQUOAAAApUlEQVQ4EcWS0Q3CMBBDU8QcrMSsrNRFSt/HqxyrhR8kLKW58zmOFXWMf+LxGhuLDO6dZ2niTLw+x6TDLLltx7LjzGvirlIkj1keumfTNSnycM/brOdTj5ErB16AGcgZ9ZFQoQLfKHlq+DSynt4wD2mYHHX2aDBqwN/4fIJGJlZLIpC99ek/pZGi7uFNqIb9a0LFnVA+U8IdkTvBlYFGpGszZz/d33D9cM8te9pUAAAAAElFTkSuQmCC")
bike_dock = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFKADAAQAAAABAAAADQAAAADfLQUOAAAAV0lEQVQ4EWNgoDlY+O8/AwgTAjjUMaLoQzconglVHqaYKHXoikCayRBjgllKLXrUQMpDknAYIsc0MhuH3RADYQphNA7FWIVheqA0C1ZF6IIwTeji9OADAPvYLVbN8V1pAAAAAElFTkSuQmCC")
regular_bike_gray = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAAZ0lEQVQ4jc2SQQ4AIQgDZeNf+6a+1j2ZEFcoetoem3aCYGt/EclBchyFo5L3ytAsnEHsFgpg2+0VkC+rJ/YoOCHrvnb+Z+LK4tUhpvdk4/tgtLNVEgjAAFj1e0igB1dy4fUU4DR/rRcn/VixMyJ6lgAAAABJRU5ErkJggg==")
electric_bike_gray = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAAcElEQVQ4jcVSWw6AMAgbxrv2TD3t9kWCyEOXGPmCAi2wjfGnkZwkp/qvGy2Bz1dxSdzhvuasCAFIpb69dkSSnUMyNQCiuPcjIq25NVkBS2SbsnUByPFkdU+mscUu+d2vEd2xnTCcoMDbR8ksuvsntgARZXkK5zt/IwAAAABJRU5ErkJggg==")
bike_dock_gray = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABQAAAANCAYAAACpUE5eAAAASElEQVQ4jWNgoDWYOXPm/5kzZ/4nVx0juiJkfnp6OiMDFkCUOmy2kSPGhM0FlIBRA+lgIHIMEpM+mZAVEqMBl4UwmoUUTQMCADmdMerNYrWMAAAAAElFTkSuQmCC")

def get_indego_data():
    r = http.get(indego_api_endpoint, ttl_seconds = 600)
    if r.status_code != 200:
        fail("GET %s failed with status %d: %s", r.status_code, r.body())
    return r.json()

def populate_schema():
    data = get_indego_data()
    sorted_features = sorted(data["features"], key = lambda f: f["properties"]["name"])
    result = []
    for feature in sorted_features:
        properties = feature["properties"]
        formatted_feature = schema.Option(display = properties["name"], value = str(properties["id"]))
        result.append(formatted_feature)
    return result

def get_dock_info(selected_dock):
    data = get_indego_data()
    r = {}
    for dock in data["features"]:
        if str(dock["properties"]["id"]) == selected_dock:
            r["name"] = dock["properties"]["name"]
            r["docksAvailable"] = int(dock["properties"]["docksAvailable"])
            r["classicBikesAvailable"] = int(dock["properties"]["classicBikesAvailable"])
            r["electricBikesAvailable"] = int(dock["properties"]["electricBikesAvailable"])
    return r

def main(config):
    selected_dock = config.str("dock", default_dock)
    dock_data = get_dock_info(selected_dock)

    if dock_data.get("classicBikesAvailable") > 0:
        regular_bike_color = "#FF9400"
        regular_bike_image = regular_bike
    else:
        regular_bike_color = "#999999"
        regular_bike_image = regular_bike_gray

    if dock_data.get("electricBikesAvailable") > 0:
        electric_bike_color = "#1EB100"
        electric_bike_image = electric_bike
    else:
        electric_bike_color = "#999999"
        electric_bike_image = electric_bike_gray

    if dock_data.get("docksAvailable") > 0:
        dock_color = "#00A1FE"
        dock_image = bike_dock
    else:
        dock_color = "#999999"
        dock_image = bike_dock_gray

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 7, width = 64, color = "#8C189A", child = render.Padding(pad = (0, 1, 0, 1), child = render.Marquee(width = 64, offset_start = 64, offset_end = 64, child = render.Text(dock_data["name"], font = "CG-pixel-4x5-mono")))),
                        ]),
                        render.Row(children = [
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = regular_bike_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["classicBikesAvailable"]), font = "Dina_r400-6", color = regular_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = electric_bike_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["electricBikesAvailable"]), font = "Dina_r400-6", color = electric_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = dock_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["docksAvailable"]), font = "Dina_r400-6", color = dock_color)),
                            ]),
                        ]),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "dock",
                name = "Dock",
                desc = "The dock to display data for.",
                icon = "bicycle",
                default = default_dock,
                options = populate_schema(),
            ),
        ],
    )

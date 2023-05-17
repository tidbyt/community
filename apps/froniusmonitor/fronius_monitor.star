"""
Applet: Fronius Monitor
Summary: PV system monitor
Description: Energy production and consumption monitor for your Fronius inverter.
Author: nchieng (& marcusb)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

URL = "http://{}/solar_api/v1/GetPowerFlowRealtimeData.fcgi"
CACHE_TTL = 60
DUMMY_DATA = {
    "Body": {
        "Data": {
            "Site": {
                "P_Grid": 144.20,
                "P_Load": 900.54,
                "P_PV": 756.34,
            },
        },
    },
}

SOLAR_PANEL = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAAQCAYAAAD52jQlAAAArElEQVQ4ja2T2xGFIAxETxyrcOhM
y7M0xzb2fjA4kYcPrvsFCSzhBExCZDLDAHwuxZ5ovEq+MfIaWkYSqt3ikdLmlkG38dcmx1U9v2h8
721mVeaNRgkwpjCzbytTWABO43i4VDMe44lYqlaS4sb5ttKWiu5faQoL+7ae5pLKd+4ntQVPlCMo
mHpmOcNWLGc7+ES+uFevmELJNcU8ugG+rRKOx9/XoKph40P8rR8wcGBXI4UlEQAAAABJRU5ErkJg
gg==
""")
SOLAR_PANEL_OFF = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABUAAAAQCAYAAAD52jQlAAAAd0lEQVQ4je2TwQrAIAxDo+y7e+iP
d5cJtY0iustgOWklsb4i8OsTKqxoZrZkLoX6r5FBRAAAqkrX7XIWXFmX3rijFDqTiEBVuz1D1bW+
yjKFBASJqX96ZDiqRbbVH5yyTKGrilxbzaOrwLtdAs+gdgdEAwcf4lg3XnREWPIOZLAAAAAASUVO
RK5CYII=
""")
GRID = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAt0lEQVQ4jYWQuxEDIQxEhcfFeIZm
HEEtTimHTmiBa4KYZC+xGKEToITR5+0KEYkAADIi54ycM6z+2wIkSEQUQnArg4cAQxJk+LouAgDn
nNPcULdcaq2Q/VrrPNN7BwDI1zIopTzvwMN6Ay2y2/A4oGsyf5lqiyil7N13OcPmHU4DMk/Rj/7v
+8E0wCJaoLWGFD1S9OB8wKcNJMiuE7z6swanlXcwg7puwlJAO8pDLWG5rlXfgv+4AXBeHhx5xCS7
AAAAAElFTkSuQmCC
""")
HOUSE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAb0lEQVQ4jcWQQQrAMAgE19KX9dL/
v2h7arDRFT1VCIHEGVYBUbxu+ntUCybnkgBPJDu83jsSBbckGUyC7yklOnYUaEkSWwlcPwHQPGxm
ls2fJQj9anmVAADOTlOVLhXsQJXuUB/d+l/w2UE1q/p7AIUnlBV3qmXkAAAAAElFTkSuQmCC
""")
DOTS_LTR = base64.decode("""
R0lGODlhCgAFAIABAA31VAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQJDwABACwAAAAACgAFAAAC
CYyPmWAc7pRMBQAh+QQJDwABACwAAAAACgAFAAACCIyPqWAcrmIsACH5BAkPAAEALAAAAAAKAAUA
AAIIjI+pAda8oioAOw==
""")
DOTS_RTL = base64.decode("""
R0lGODlhCgAFAIABAP/RGwAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQJDwABACwAAAAACgAFAAAC
CIyPqQHWvKIqACH5BAkPAAEALAAAAAAKAAUAAAIIjI+pYByuYiwAIfkECQ8AAQAsAAAAAAoABQAA
AgmMj5lgHO6UTAUAOw==
""")

def main(config):
    inverter_ip = config.str("inverter_ip")

    if inverter_ip and inverter_ip != "":
        url = URL.format(inverter_ip)
        data = cache.get(url)
        if not data:
            rep = http.get(url, params = {})
            if rep.status_code != 200:
                fail("Fronius API request failed with status {}".format(rep.status_code))
            data = rep.body()
            cache.set(url, data, ttl_seconds = CACHE_TTL)
        o = json.decode(data)
    else:
        o = DUMMY_DATA

    data = o["Body"]["Data"]["Site"]
    pv = data["P_PV"]
    power_load = data["P_Load"]
    grid = data["P_Grid"]

    points = []
    flows = []

    img = SOLAR_PANEL_OFF if pv == None or pv == 0 else SOLAR_PANEL
    points.append((img, pv))

    if pv and pv > 0:
        dir = 1
    else:
        dir = 0
    flows.append(dir)

    if power_load:
        points.append((HOUSE, abs(power_load)))

    if grid:
        points.append((GRID, abs(grid)))
        if grid > 0:
            dir = -1
        elif grid < 0:
            dir = 1
        else:
            dir = 0
        flows.append(dir)

    columns = []
    for p in points:
        img, power = p
        columns.append(
            render.Column(
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Image(src = img),
                    render.Text(
                        content = format_power(power),
                        height = 8,
                        font = "tb-8",
                        color = "#ffd11a",
                    ),
                    render.Text(
                        content = "kW",
                        height = 8,
                        font = "tb-8",
                        color = "#ffd11a",
                    ),
                ],
            ),
        )
    dots = [render.Box(width = 18)]
    for dir in flows:
        if dir:
            el = render.Image(src = DOTS_LTR if dir == 1 else DOTS_RTL)
        else:
            el = render.Box(width = 10)
        dots.append(
            render.Stack(children = [render.Box(width = 21), el]),
        )
    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = columns,
                ),
                render.Column(
                    children = [
                        render.Box(height = 8),
                        render.Row(expanded = True, children = dots),
                    ],
                ),
            ],
        ),
    )

def format_power(p):
    if p:
        # Converts W to kW
        return humanize.float("#,###.##", p / 1000)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "inverter_ip",
                name = "Inverter IP Address",
                desc = "Local IP Address of the Fronius inverter",
                icon = "ethernet",
                default = "",
            ),
        ],
    )

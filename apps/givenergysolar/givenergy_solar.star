"""
Applet: GivEnergy Solar
Summary: GivEnergy Solar Monitor
Description: Energy production and consumption monitor for your GivEnergy system.
Author: pelowj (based on the work of jweier & marcusb in Tesla Solar)
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

URL = "https://api.givenergy.cloud/v1/inverter/{}/system-data/latest"

IMG = ""

DUMMY_DATA = "{\"data\":{\"time\":\"2023-05-20T16:32:41Z\",\"solar\":{\"power\":1174,\"arrays\":[{\"array\":1,\"voltage\":361.6,\"current\":3.2,\"power\":1174},{\"array\":2,\"voltage\":21.6,\"current\":0,\"power\":0}]},\"grid\":{\"voltage\":232.1,\"current\":4.8,\"power\":381,\"frequency\":49.98},\"battery\":{\"percent\":100,\"power\":44,\"temperature\":30},\"inverter\":{\"temperature\":39.5,\"power\":1083,\"output_voltage\":229.3,\"output_frequency\":49.99,\"eps_power\":0},\"consumption\":702}}"

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
    print("-------Starting new update-------")

    inverter_sn = config.str("inverter_sn")
    api_key = config.str("api_key")
    error_in_http_calls = False
    error_details = {}
    o = ""
    unit = ""

    if api_key and inverter_sn:
        url = URL.format(inverter_sn)
        print("API Key: " + api_key)
        print("Inverter SN: " + inverter_sn)
        print("GivEnergy API URL: " + url)

        rep = http.get(url, headers = {"Authorization": "Bearer " + api_key, "Content-Type": "application/json", "Accept": "application/json"})

        if rep.status_code != 200:
            data = rep.body()
            o = json.decode(data)
            error_details = {"error_section": inverter_sn, "error": "Error: " + o["message"]}
            error_in_http_calls = True
            print(rep.status_code)
        else:
            unit = "kW"
            data = rep.body()
            o = json.decode(data)

    else:
        print("Using Dummy Data")
        o = json.decode(DUMMY_DATA)
        unit = "TEST"

    if error_in_http_calls == False:
        o = o["data"]

        points = []
        flows = []
        if o["solar"]["power"] > 10:
            IMG = SOLAR_PANEL
            dir = 1
        else:
            IMG = SOLAR_PANEL_OFF
            dir = 0
        points.append((IMG, o["solar"]["power"] / 1000))
        flows.append(dir)

        o["grid"]["power"] = o["grid"]["power"] * -1

        points.append((HOUSE, o["consumption"] / 1000))
        points.append((GRID, o["grid"]["power"] / 1000))

        if o["grid"]["power"] < -10:
            dir = 1
        elif o["grid"]["power"] > 10:
            dir = -1
        else:
            dir = 0

        flows.append(dir)

        columns = []
        for p in points:
            IMG, power = p
            columns.append(
                render.Column(
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Image(src = IMG),
                        render.Text(
                            content = format_power(power),
                            height = 8,
                            font = "tb-8",
                            color = "#ffd11a",
                        ),
                        render.Text(
                            content = unit,
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
    else:
        error_message = error_details["error_section"] + ". " + error_details["error"]
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text(error_message),
            ),
        )

def format_power(p):
    if p:
        return humanize.float("#,###.##", p)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "GivEnergy API Key",
                desc = "GivEnergy API Key, available from https://givenergy.cloud/account-settings/security",
                icon = "key",
            ),
            schema.Text(
                id = "inverter_sn",
                name = "Inverter Serial Number",
                desc = "Your inverter serial number, available from https://givenergy.cloud/inverter/",
                icon = "solarPanel",
            ),
        ],
    )

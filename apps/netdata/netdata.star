"""
Applet: Netdata
Summary: Shows CPU/Mem/Net/Uptime
Description: Shows your CPU and Memory Usage in %, Network UP/Down in Mbps, and Uptime in Days Hours Minutes.
Author: MrRobot245
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")
load("re.star", "re")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

FRAME_WIDTH = 64

def lightness(color, amount):
    hsl_color = rgb_to_hsl(*hex_to_rgb(color))
    hsl_color_list = list(hsl_color)
    hsl_color_list[2] = hsl_color_list[2] * amount
    hsl_color = tuple(hsl_color_list)
    return rgb_to_hex(*hsl_to_rgb(*hsl_color))

def rgb_to_hsl(r, g, b):
    r = float(r / 255)
    g = float(g / 255)
    b = float(b / 255)
    high = max(r, g, b)
    low = min(r, g, b)
    h, s, l = ((high + low) / 2,) * 3

    if high == low:
        h = 0.0
        s = 0.0
    else:
        d = high - low
        s = d / (2 - high - low) if l > 0.5 else d / (high + low)
        if high == r:
            h = (g - b) / d + (6 if g < b else 0)
        elif high == g:
            h = (b - r) / d + 2
        elif high == b:
            h = (r - g) / d + 4
        h /= 6

    return int(math.round(h * 360)), s, l

def hsl_to_rgb(h, s, l):
    def hue_to_rgb(p, q, t):
        if t < 0:
            t += 1
        if t > 1:
            t -= 1
        if t < 1 / 6:
            return p + (q - p) * 6 * t
        if t < 1 / 2:
            return q
        if t < 2 / 3:
            return p + (q - p) * (2 / 3 - t) * 6
        return p

    h = h / 360
    if s == 0:
        r, g, b = (l,) * 3  # achromatic
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1 / 3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3)

    return int(math.round(r * 255)), int(math.round(g * 255)), int(math.round(b * 255))

def hex_to_rgb(color):
    # Expand 4 digit hex to 7 digit hex
    if len(color) == 4:
        x = "([A-Fa-f0-9])"
        matches = re.match("#%s%s%s" % (x, x, x), color)
        rgb_hex_list = list(matches[0])
        rgb_hex_list.pop(0)
        for i in range(len(rgb_hex_list)):
            rgb_hex_list[i] = rgb_hex_list[i] + rgb_hex_list[i]
        color = "#" + "".join(rgb_hex_list)

    # Split hex into RGB
    x = "([A-Fa-f0-9]{2})"
    matches = re.match("#%s%s%s" % (x, x, x), color)
    rgb_hex_list = list(matches[0])
    rgb_hex_list.pop(0)
    for i in range(len(rgb_hex_list)):
        rgb_hex_list[i] = int(rgb_hex_list[i], 16)
    rgb = tuple(rgb_hex_list)

    return rgb

# Convert RGB tuple to hex
def rgb_to_hex(r, g, b):
    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

def main(config):
    if config.str("url") == None:
        return render.Root(
            child = render.WrappedText("Please enter the URL info!"),
        )
    else:
        rep = http.get(config.str("url") + "/api/v1/allmetrics?format=json")
        if rep.status_code != 200:
            fail("Netdata request failed with status:", rep.status_code)
        rep = rep.json()

        cpu = 100 - int(rep["system.cpu"]["dimensions"]["idle"]["value"])
        usedmem = int(rep["system.ram"]["dimensions"]["used"]["value"])
        totalmem = int(rep["system.ram"]["dimensions"]["free"]["value"]) + int(rep["system.ram"]["dimensions"]["used"]["value"]) + int(rep["system.ram"]["dimensions"]["cached"]["value"]) + int(rep["system.ram"]["dimensions"]["buffers"]["value"])
        ramusage = int(usedmem / totalmem * 100)
        netin = int((rep["system.net"]["dimensions"]["InOctets"]["value"]) / 1000)
        netout = int(((rep["system.net"]["dimensions"]["OutOctets"]["value"]) * -1) / 1000)
        uptime = int(rep["system.uptime"]["dimensions"]["uptime"]["value"])

        # days=(uptime/86400)
        # hours=(days/3600)
        # minutes=(hours/60)

        days = uptime // (24 * 3600)
        uptime = uptime % (24 * 3600)
        hours = int(uptime / 3600)
        uptime %= 3600
        minutes = uptime // 60
        uptime %= 60

        # print(cpu)
        # print(ramusage)
        # print(netin)
        # print(netout)
        # # print(uptime)
        # print(days)
        # print(hours)
        # print(minutes)

    state = {
        "cpu": cpu,
        "ramusage": ramusage,
        "netin": netin,
        "netout": netout,
        "days": days,
        "hours": hours,
        "minutes": minutes,
    }

    return render.Root(
        delay = 32,  # 30 fps
        child = render.Box(
            child = render.Animation(
                children = [
                    get_frame(state, fr, config, capanim((fr) * 3))
                    for fr in range(300)
                ],
            ),
        ),
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def render_progress_bar(state, label, percent, col1, col2, col3, animprogress):
    animpercent = easeOut(animprogress / 100) * percent

    col2orwhite = col2
    if percent >= 100:
        col2orwhite = col1

    label1color = lightness("#fff", animprogress / 100)

    label2align = "start"

    # label2color = col3
    label2color = lightness(col3, animprogress / 100)
    label3color = lightness("#fff", animprogress / 100)

    labelcomponent = None
    widthmax = FRAME_WIDTH - 1
    labelcomponent = render.Stack(
        children = [
            render.Text(
                content = label,
                color = label1color,
                font = "tom-thumb",
            ),
            render.Box(width = 2, height = 6),
        ],
    )
    widthmax -= 13

    progresswidth = max(1, int(widthmax * animpercent / 100))

    progressfill = None
    if animpercent > 0:
        progressfill = render.Row(
            main_align = "start",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(width = progresswidth, height = 7, color = col2),
                render.Box(width = 1, height = 7, color = col3),
            ],
        )

    label2component = None
    label2component = render.Stack(
        children = [
            render.Text(
                content = "{}%".format(int(percent * animprogress / 100)),
                color = label2color,
                font = "tom-thumb",
            ),
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            labelcomponent,
            render.Stack(
                children = [
                    render.Row(
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = widthmax, height = 7, color = col1),
                        ],
                    ),
                    progressfill,
                    render.Row(
                        main_align = label2align,
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = 1, height = 8),
                            label2component,
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            # render.Image(src=state["image"]),
                            # render.Box(width = 4, height = 8),
                        ],
                    ),
                ],
            ),
            render.Box(width = 1, height = 8),
        ],
    )

def capanim(input):
    return max(0, min(100, input))

def get_frame(state, fr, config, animprogress):
    children = []

    delay = 0
    color1 = "#0f0"
    color2 = "#ff00ff"
    color3 = "#ff0000"
    color4 = "#ffffff"
    day = "#FFFF00"
    hour = "#00FFFF"
    minute = "#FFA500"

    children.append(
        render_progress_bar(state, "CPU", state["cpu"], lightness(color4, 0.06), lightness(color4, 0.18), color4, capanim((fr - delay) * 3)),
    )
    children.append(
        render_progress_bar(state, "RAM", state["ramusage"], lightness(color2, 0.06), lightness(color2, 0.18), color2, capanim((fr - delay) * 3)),
    )
    children.append(
        render.Row(
            expanded = True,
            main_align = "start",
            children = [
                render.Text("Net ", font = "tom-thumb"),
                render.Box(width = 1, height = 1),
                render.Text("%s" % state["netin"], font = "tom-thumb", color = lightness(color1, animprogress / 100)),
                render.Text(" / ", font = "tom-thumb"),
                render.Text("%s" % state["netout"], font = "tom-thumb", color = lightness(color3, animprogress / 100)),
            ],
        ),
    )
    children.append(
        render.Row(
            expanded = True,
            main_align = "start",
            children = [
                render.Text("Up  ", font = "tom-thumb"),
                render.Box(width = 1, height = 1),
                render.Text("%s" % state["days"], font = "tom-thumb", color = lightness(day, animprogress / 100)),
                render.Text("D", font = "tom-thumb"),
                render.Text(" %s" % state["hours"], font = "tom-thumb", color = lightness(hour, animprogress / 100)),
                render.Text("H", font = "tom-thumb"),
                render.Text(" %s" % state["minutes"], font = "tom-thumb", color = lightness(minute, animprogress / 100)),
                render.Text("M", font = "tom-thumb"),
            ],
        ),
    )

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "url",
                name = "URL",
                desc = "URL for Netdata",
                icon = "arrowUpFromBracket",
            ),
        ],
    )

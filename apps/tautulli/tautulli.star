"""
Applet: Tautulli
Summary: Shows stream count, and bandwidth
Description: Shows your current sessions stream count, broken up into transcodes/direct steams as an option. Also shows total upload bandwidth in Mbps
Author: mrrobot245
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

Tautulli_Icon = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAAXNSR0IArs4c6QAAAXVJREFUOE+dk7tKA0EUhv+Z1RiLoCnsAks0hdEVjQoqRhG1thXs9A0svDyCFwTFQivfwcLKBCHWQhJzUVCD2AkBCw0psnvkDO66u4kEnOrM5fvnnPPPCPhGJDLTHeqp1fzrmjBjhULh2b0u3JP48Cj5If+8XMw5jBO0A8myYBFB0zTYAgpuB/KZ1NaLSmJxT4f8ERB/1ehP92qzgq4OwtJ+FEKqO2+FfSsRcToYn5xGvV73sJxyQv9C9i3kWXdg0zTxWL5Xm0PGmHOIRdPbFSwf9jf10oFBhGRyFifHR0hMTEFKCQZTDB5EIYTHGCX0C9u6RCgVc1hZiOF8/R2n12FcZsMtHWyGAXCN6Z0Ka6P6qWH1TG8NG4YxYJL2ZNd2kenFxvwH+taqaDQaCAaDbCUCgU7ks3cqtktwfOaG3ey+qhu4OZZl4aGUx2B8BBBCxTx47vhs58OWsYAU0vbRaxeREmx6YW6Bf71tl0AGwFwrEfen4P1vSSueYQes1/cAAAAASUVORK5CYII=
""")

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
    if config.str("url") == None or config.str("api") == None:
        return render.Root(
            child = render.WrappedText("Please enter the URL and API info!"),
        )
    else:
        taut_cache = cache.get("tautulli")
        if taut_cache != None:
            print("Hit! Displaying cached data.")
            rep = json.decode(taut_cache)
        else:
            print("Miss! Calling Tautulli API.")
            rep = http.get(config.str("url") + "/api/v2?apikey=" + config.str("api") + "&cmd=get_activity")
            if rep.status_code != 200:
                fail("Tautulli request failed with status %d", rep.status_code)
            rep = rep.json()
            cache.set("tautulli", json.encode(rep), ttl_seconds = 15)

        bandwidth = rep["response"]["data"]["total_bandwidth"]
        bandwidth = math.round((bandwidth / 1024) * 100) / 100
        users = rep["response"]["data"]["stream_count"]
        dp1 = rep["response"]["data"]["stream_count_direct_play"]
        dp2 = rep["response"]["data"]["stream_count_direct_stream"]
        dp = int(dp1 + dp2)
        tc = int(rep["response"]["data"]["stream_count_transcode"])

    state = {
        "bandwidth": bandwidth,
        "users": users,
        "dp": dp,
        "tc": tc,
    }

    return render.Root(
        # delay = 32,  # 30 fps
        child = render.Box(
            child = render.Animation(
                children = [
                    get_frame(state, fr, config, capanim((fr) * 4))
                    for fr in range(300)
                ],
            ),
        ),
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def capanim(input):
    return max(0, min(100, input))

def get_frame(state, fr, config, animprogress):
    children = []
    delay = 0

    if config.bool("streamstats") == False or config.bool("streamstats") == None:
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Image(src = Tautulli_Icon),
                    render.Text("Streams:"),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % state["users"], font = "", color = lightness("#e5a00d", animprogress / 100)),
                ],
            ),
        )
        children.append(
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("UL: "),
                    render.Box(width = 2, height = 1),
                    render.Text("%s" % state["bandwidth"], font = "", color = lightness("#e5a00d", animprogress / 100)),
                ],
            ),
        )

    else:
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Image(src = Tautulli_Icon),
                    render.Text("Streams:"),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % state["users"], font = "", color = lightness("#e5a00d", animprogress / 100)),
                ],
            ),
        )
        children.append(
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("UL: "),
                    render.Box(width = 2, height = 1),
                    render.Text("%s" % state["bandwidth"], font = "", color = lightness("#e5a00d", animprogress / 100)),
                ],
            ),
        )
        children.append(
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("DP:"),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % state["dp"], font = "", color = lightness("#e5a00d", animprogress / 100)),
                    render.Box(width = 15, height = 1),
                    render.Text("TC:"),
                    render.Box(width = 1, height = 1),
                    render.Text("%s" % state["tc"], font = "", color = lightness("#e5a00d", animprogress / 100)),
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
                id = "api",
                name = "API Key",
                desc = "API Key for Tautulli",
                icon = "arrowUpFromBracket",
            ),
            schema.Text(
                id = "url",
                name = "Tautulli URL",
                desc = "URL for Tautulli",
                icon = "brain",
            ),
            schema.Toggle(
                id = "streamstats",
                name = "Play stats",
                desc = "Display Direct Play+Transcode Status",
                icon = "codeFork",
                default = True,
            ),
        ],
    )

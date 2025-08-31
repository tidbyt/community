"""
Applet: Pentagon Pizza IX
Summary: Track Pentagon Pizza Index
Description: My index tracking pizza prices near the pentagon!
Author: eSoLu
"""

load("http.star", "http")
load("render.star", "render")

# ---- Hardcoded settings ----
ENDPOINT = "https://qsoybchuihyhdillvant.functions.supabase.co/ppi-public"

def fetch_json():
    r = http.get(ENDPOINT, ttl_seconds = 60)
    if r.status_code != 200:
        return None
    return r.json()

# Extract from: { current:{value,change_1h}, series_24h:[{ts,v},...] }
def extract(data):
    cur = 0
    d1h = 0
    d24h = 0
    series = []
    if type(data) == "dict":
        c = data.get("current")
        if type(c) == "dict":
            cur = c.get("value", 0) - 100
            d1h = c.get("change_1h", 0)
            d24h = c.get("change_24h", 0)
        s = data.get("series_24h")
        if type(s) == "list":
            # Sort the list of dicts by timestamp string (ISO8601 sorts correctly as string)
            sorted_series = sorted(s, key = lambda e: e["ts"])

            # Build (value, index) tuples after sorting
            series = [(i, entry["v"] - 100) for i, entry in enumerate(sorted_series)]
    return cur, d1h, d24h, series

ppi_up_color = "#f00"
ppi_down_color = "#0f0"
bg_color = "#000000"
up_arrow = "↑"
down_arrow = "↓"

def getArrow(val):
    if val > 0:
        return up_arrow, ppi_up_color
    elif val < 0:
        return down_arrow, ppi_down_color

    return "", ppi_down_color

def main():
    data = fetch_json()
    cur, d1h, d24h, series = extract(data)

    cur_arrow = ""
    d1_arrow = ""
    d24_arrow = ""
    cur_arrow_color = ""
    d1_arrow_color = ""
    d24_arrow_color = ""

    cur_arrow, cur_arrow_color = getArrow(cur)
    d1_arrow, d1_arrow_color = getArrow(d1h)
    d24_arrow, d24_arrow_color = getArrow(d24h)

    background = render.Box(color = bg_color)

    marqueeDisplay = render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "start",
        children = [
            render.Text("Pentagon Pizza Index: " + str(int(cur))),
            render.Text(cur_arrow, color = cur_arrow_color),
            render.Text(".....1H:" + str(d1h)),
            render.Text(d1_arrow, color = d1_arrow_color),
            render.Text(".....24H:" + str(d24h)),
            render.Text(d24_arrow, color = d24_arrow_color),
        ],
    )

    chart = render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Marquee(
                        width = 64,
                        height = 10,
                        child = marqueeDisplay,
                        offset_start = 5,
                        offset_end = 64,
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Box(color = bg_color, height = 1),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Plot(
                        series,
                        width = 64,
                        height = 22,
                        color = ppi_up_color,
                        y_lim = (-100, 50),
                        color_inverted = ppi_down_color,
                        fill = True,
                    ),
                ],
            ),
        ],
    )

    display = render.Stack(
        children = [
            background,
            chart,
        ],
    )

    return render.Root(
        display,
    )

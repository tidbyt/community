"""
Applet: Pentagon Pizza IX
Summary: Track Pentagon Pizza Index
Description: My index tracking pizza prices near the pentagon! Powered by BestTime http://besttime.app !
Author: eSoLu
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

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
up_arrow = "↑"
down_arrow = "↓"
bg_color = "#000000"
pizza_slice = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120"> <defs> <style> .crust { fill: #c68642; stroke: #000; stroke-width: 2; } .cheese { fill: #f7d774; stroke: #000; stroke-width: 2; } .pep { fill: #b33a3a; stroke: #b33a3a; stroke-width: 1; } </style> <clipPath id="sliceClip"> <polygon points="10,10 110,10 60,110"/> </clipPath> </defs> <polygon points="10,10 110,10 60,110" class="cheese"/> <rect x="10" y="5" width="100" height="10" rx="5" ry="5" class="crust"/> <g clip-path="url(#sliceClip)"> <!-- Left side --> <circle cx="25" cy="28" r="7" class="pep"/> <circle cx="35" cy="55" r="7" class="pep"/> <circle cx="40" cy="80" r="7" class="pep"/> <circle cx="95" cy="28" r="7" class="pep"/> <circle cx="75" cy="55" r="7" class="pep"/> <circle cx="65" cy="80" r="7" class="pep"/> <circle cx="50" cy="38" r="7" class="pep"/> <circle cx="60" cy="60" r="7" class="pep"/> <circle cx="55" cy="78" r="7" class="pep"/> <circle cx="60" cy="95" r="7" class="pep"/> <circle cx="70" cy="42" r="7" class="pep"/> <circle cx="80" cy="72" r="7" class="pep"/> </g> </svg>'
pizza_pie = "https://qsoybchuihyhdillvant.supabase.co/storage/v1/object/public/pizza/pizza.png"

def getArrow(val):
    if val > 0:
        return up_arrow, ppi_up_color
    elif val < 0:
        return down_arrow, ppi_down_color

    return "", ppi_down_color

def isPizzaClosed():
    now = time.now().in_location("America/New_York")

    return now.hour >= 0 and now.hour < 10

def noPizza():
    display = render.Stack(
        children = [
            render.Box(
                render.Image(http.get(pizza_pie).body(), height = 30, width = 30),
            ),
            render.Box(
                render.WrappedText("No Pizza!"),
            ),
        ],
    )

    return display

def buildPizzaRates():
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

    marqueeDisplay = render.Marquee(
        width = 64,
        height = 10,
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                render.Image(pizza_slice, height = 10, width = 10),
                render.Text("Pentagon Pizza Index: " + str(int(cur))),
                render.Text(cur_arrow, color = cur_arrow_color),
                render.Image(pizza_slice, height = 10, width = 10),
                render.Text("1H:" + str(d1h)),
                render.Text(d1_arrow, color = d1_arrow_color),
                render.Image(pizza_slice, height = 10, width = 10),
                render.Text("24H:" + str(d24h)),
                render.Text(d24_arrow, color = d24_arrow_color),
                render.Image(pizza_slice, height = 10, width = 10),
            ],
        ),
        offset_start = 64,
        offset_end = 64,
    )

    spacer = render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "start",
        children = [
            render.Box(color = bg_color, height = 2),
        ],
    )

    chartDisplay = render.Plot(
        series,
        width = 64,
        height = 21,
        color = ppi_up_color,
        y_lim = (-100, 100),
        color_inverted = ppi_down_color,
        fill = True,
    )

    display = render.Column(
        children = [
            marqueeDisplay,
            spacer,
            chartDisplay,
        ],
    )

    display = render.Column(
        children = [
            marqueeDisplay,
            spacer,
            chartDisplay,
        ],
    )

    return display

def main():
    if isPizzaClosed():
        display = noPizza()
    else:
        display = buildPizzaRates()

    return render.Root(
        display,
    )

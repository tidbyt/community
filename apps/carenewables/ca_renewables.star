"""
Applet: CA Renewables
Summary: Track CA's power grid
Description: See how California is using renewable energy in its power grid right now.
Author: @sloanesturz
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("humanize.star", "humanize")
load("encoding/csv.star", "csv")
load("schema.star", "schema")

FUEL_URL = "https://www.caiso.com/outlook/SP/fuelsource.csv"

GREEN_FUEL_TYPES = {
    "Solar": "#ffa300",
    "Wind": "#3b6e8f",
    "Geothermal": "#8f500d",
    "Biomass": "#8d8b00",
    "Biogas": "#b7b464",
    "Small hydro": "#89d1ca",
}

CACHE_KEY = "FUEL_USAGE_DATA"

def sum(l):
    total = 0
    for i in l:
        total += float(i)
    return total

def clean_percent(amount):
    if amount < 0.01:
        return humanize.float("#.##", amount * 100).lstrip("0")
    return humanize.float("#.", amount * 100)

def title(name, amount, color):
    return render.Row(children = [
        render.Text(name, color = color, font = "tom-thumb"),
        render.Text("%s%%" % clean_percent(amount), color = color, font = "tb-8"),
    ], expanded = True, main_align = "space_between", cross_align = "center")

# API returns a CSV with a title row, followed by data in 5-minute increments.
# Ex:
# Time,Solar,Wind,Geothermal,Biomass,Biogas,Small hydro,Coal,Nuclear,Natural Gas,Large Hydro,Batteries,Imports,Other
# 00:00,-4,3657,904,315,210,157,3,2244,10272,1816,84,6645,0
# 00:05,-4,3653,905,313,210,155,4,2244,10116,1756,322,6679,0
# ...
def get_raw_data():
    cached = cache.get(CACHE_KEY)
    if cached != None:
        data = cached
    else:
        rep = http.get(FUEL_URL)
        if rep.status_code != 200:
            fail("Request failed with status %d", rep.status_code)
        data = rep.body()
        cache.set(CACHE_KEY, data, ttl_seconds = 60 * 5)

    return data

# Turn the raw CSV into a useable data structure.
# Returns a 2-tuple
# (
#   map of fuel name -> [period-by-period array of supply MW],
#   [period-by-period array of total supply MW including non-renewables]
# )
def process_data(csv_body):
    data = csv.read_all(csv_body)
    header, rows = data[0], data[1:]
    indexes = {k: header.index(k) for k in GREEN_FUEL_TYPES}
    totals = [sum(row[1:]) for row in rows]
    segmented = {k: [float(row[indexes[k]]) for row in rows] for k in GREEN_FUEL_TYPES}

    return segmented, totals

# Sum the green values at each period
def get_green_total(segmented, periods):
    total = [0.0 for _ in range(periods)]
    for fuel_type in segmented.values():
        for i, value in enumerate(fuel_type):
            total[i] += value
    return total

# Make a plot that shows the % of `totals` represented by `values` at each period
def make_plot(values, totals, color):
    return render.Plot(
        data = [(x, y / t) for x, (y, t) in enumerate(zip(values, totals))],
        width = 64,
        height = 32,
        x_lim = (0, 24 * 60 // 5),
        y_lim = (0, 1.0),
        color = color,
        fill = True,
        fill_color = color,
    )

def main():
    raw_csv = get_raw_data()
    segmented, totals = process_data(raw_csv)

    baseline = get_green_total(segmented, len(totals))
    baseline_plot = make_plot(baseline, totals, "#84bd00")
    baseline_stack = render.Stack([
        baseline_plot,
        title("Clean", baseline[-1] / totals[-1], "#84bd00"),
    ])

    background_plot = make_plot(baseline, totals, "#ffffff")
    segmented_plots = [
        render.Stack([
            background_plot,
            make_plot(segmented[name], totals, color),
            title(name, segmented[name][-1] / totals[-1], color),
        ])
        for name, color in GREEN_FUEL_TYPES.items()
    ]

    return render.Root(delay = 10 * 1000, child = render.Animation(
        [baseline_stack] + segmented_plots,
    ))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

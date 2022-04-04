"""
Applet: US Yield Curve
Summary: Plots treasury rates
Description: Track changes to the yield curve over different US Treasury maturities.
Author: Rob Kimball
"""

load("http.star", "http")
load("math.star", "math")
load("time.star", "time")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")

DATEFMT = "2006-01-02T15:04:05"
DATA_LOCS = {
    3: "date",
    4: "1MONTH",
    5: "2MONTH",
    6: "3MONTH",
    7: "6MONTH",
    8: "1YEAR",
    9: "2YEAR",
    10: "3YEAR",
    11: "5YEAR",
    12: "7YEAR",
    13: "10YEAR",
    14: "20YEAR",
    15: "30YEAR",
}

# RGB Coefficients
COLOR_VECTORS = {
    "Red": (1.0, 0.1, 0.1),
    "Green": (0.1, 1.0, 0.1),
    "Blue": (0.1, 0.1, 1.0),
    "Yellow": (1.0, 1.0, 0.1),
    "Orange": (1.0, 0.66, 0.1),
    "Purple": (0.5, 0.1, 1.0),
    "Pink": (1.0, 0.1, 0.8),
    "Bloomberg": (0.98, 0.545, 0.117),
    "FactSet": (0.0, 0.682, 0.937),
    "Multi-color": (),
}

X_AXIS = {
    "1MONTH": 1.0,
    "2MONTH": 2.0,
    "3MONTH": 3.0,
    "6MONTH": 6.0,
    "1YEAR": 12.0,
    "2YEAR": 24.0,
    "3YEAR": 36.0,
    "5YEAR": 60.0,
    "7YEAR": 84.0,
    "10YEAR": 120.0,
    "20YEAR": 240.0,
    "30YEAR": 360.0,
}

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def rgb_to_hex(r, g, b):
    """Return 6-character hexadecimal color code from R/G/B values given as integers"""
    ret = ""
    for i in (r, g, b):
        this = "%X" % i
        if len(this) == 1:
            this = "0" + this
        ret = ret + this
    return ret

def piecewise_log(x):
    """Facilitates the rescaling of the x-axis to better emphasize the short end of the curve"""
    if x < 12:
        x = math.log(x) * 5
    else:
        x = x / 12 + 11
    return math.round(x)

def linear_scale(x):
    return x

def main(config):
    timezone = config.get("$tz", "America/New_York")
    year = time.now().in_location(timezone).year
    cache_id = "%s/%s" % ("us-yield-curve", year)
    color_choice = config.get("graph_color", "Blue")
    color_vector = COLOR_VECTORS[color_choice]

    scale_axis = {
        "linear": linear_scale,
        "piecewise-log": piecewise_log,
    }[config.get("x-axis", "linear")]

    dates = cache.get(cache_id)
    if not dates:
        url = "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/pages/xml?data=daily_treasury_yield_curve&field_tdr_date_value=%s" % year
        print("Getting latest data from treasury.gov, %s" % url)
        response = http.get(url)
        raw = response.body()
        xml = xpath.loads(raw)
        rows = xml.query_all("/feed/entry/content")
        dates = []
        min_yield, max_yield = 0.0, 0.0
        for entry in rows:
            items = entry.split("\n")
            this = {DATA_LOCS[i]: value for i, value in enumerate(items) if i in DATA_LOCS.keys()}
            yields = []
            for key in this.keys():
                if key != "date":
                    this[key] = float(this[key])
                    yields.append(this[key])
            max_yield = max(max_yield, max(yields))
            min_yield = min(min_yield, min(yields))
            dates.append(this)

        cache.set(cache_id, json.encode(dates), ttl_seconds = 60 * 60 * 12)
    else:
        print("Displaying cached data.")
        dates = json.decode(dates)

        # force all to float for plotting
        for i, d in enumerate(dates):
            for k, v in d.items():
                if k != "date":
                    dates[i][k] = float(v)
        min_yield, max_yield = 0.0, 0.0
        yields = [v for d in dates for k, v in d.items() if k != "date"]
        max_yield = max(max_yield, max(yields))
        min_yield = min(min_yield, min(yields))

    plots = []
    min_color = 15
    for i, entry in enumerate(dates):
        c = 255 * (math.pow(1.07, i) / math.pow(1.07, len(dates)))
        if color_choice == "Multi-color":
            rgb = (
                max(min_color, int(50 * ((len(dates) - i) / len(dates)))),
                max(min_color, int(255 * (0.5 - abs(0.5 - i / len(dates))))),
                max(min_color, int(c)),
            )
        else:
            c_r, c_g, c_b = color_vector
            rgb = (
                max(min_color, int(c * c_r)),
                max(min_color, int(c * c_g)),
                max(min_color, int(c * c_b)),
            )
        color = rgb_to_hex(*rgb)
        if i == len(dates) - 1:
            color = "fff"

        curve = [(scale_axis(X_AXIS[k]), entry.get(k, 0.0)) for k in X_AXIS.keys()]
        plots.append(render.Plot(
            data = curve,
            width = 64,
            height = 32,
            color = "#" + color,
            ylim = (min_yield - 0.25, max_yield + 0.25),
            fill = False,
        ))

    stats = {
        "US 10Y ": round(dates[-1]["10YEAR"], 3),
        "10Y-2Y ": round(dates[-1]["10YEAR"] - dates[-1]["2YEAR"], 3),
        "": time.parse_time(dates[-1]["date"], format = DATEFMT).in_location(timezone).format("Jan-02 3:04 PM"),
    }

    stat_table = []
    for title, value in stats.items():
        color = "#fb8b1e"
        if title == "":
            color = "#444"
        stat_table.append(
            render.Box(
                height = 6,
                child = render.Row(
                    expanded = True,
                    main_align = "end",
                    cross_align = "end",
                    children = [
                        render.Text(title, font = "CG-pixel-3x5-mono"),
                        render.Text(str(value), font = "CG-pixel-3x5-mono", color = color),
                    ],
                ),
            ),
        )

    plots.append(render.Column(
        expanded = True,
        main_align = "end",
        cross_align = "end",
        children = stat_table,
    ))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                render.Stack(
                    children = plots,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "x-axis",
                name = "X-Axis Unit",
                desc = "Adjust how yields are plotted along the axis.",
                icon = "pencilRuler",
                options = [
                    schema.Option(value = "linear", display = "Linear Scale"),
                    schema.Option(value = "piecewise-log", display = "Piecewise Logarithmic"),
                ],
                default = "linear",
            ),
            schema.Dropdown(
                id = "graph_color",
                name = "Color",
                desc = "Color of the historical curves.",
                icon = "paintBrush",
                options = [schema.Option(value = c, display = c) for c in COLOR_VECTORS.keys()],
                default = "Blue",
            ),
        ],
    )

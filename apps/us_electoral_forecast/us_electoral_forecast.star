"""
Applet: ElectoralForecast
Summary: 538 US Presidental forecast
Description: Shows US President electoral forecast from FiveThirtyEight.
Author: jwoglom
"""

load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JSON_URL = "https://projects.fivethirtyeight.com/2024-election-forecast/timeseries.json"

FONT = "tom-thumb"

PERIOD = "period"
DEFAULT_PERIOD = "30"

TYPE = "type"
DEFAULT_TYPE = "ec"

PARTY_COLORS = {
    "REP": "#eb4034",
    "DEM": "#1018eb",
    "BOTH_BG": "#757575",
    "DEM_BG": "#4b6de3",
    "REP_BG": "#f77272",
}

def main(config):
    period = config.get(PERIOD, DEFAULT_PERIOD)
    type = config.get(TYPE, DEFAULT_TYPE)

    url = JSON_URL
    results = http.get(url, ttl_seconds = 3600)
    if results.status_code != 200:
        return render.Root(
            child = render.WrappedText("Error loading"),
        )

    data = postprocess(results.json())

    latest_data = data[0][type]
    dem_leading_rep = latest_data["dem"]["median"] >= latest_data["rep"]["median"] if type != "winprob" else latest_data["dem"] >= latest_data["rep"]

    chart = draw_chart(data, type, int(period))

    def print_num(num):
        if type == "ec":
            return "%s EV" % int(num["median"])
        elif type == "pv":
            return "%s" % (math.round(10 * num["median"]) / 10) + "%"
        elif type == "winprob":
            return "%s" % (math.round(10 * num) / 10) + "%"
        return ""

    WIDTH = 26

    row = render.Stack(
        children = [
            render.Row(
                children = [
                    render.Box(
                        width = 63,
                        height = 32,
                        color = "#000",
                    ),
                    render.Box(
                        width = WIDTH,
                        height = 32,
                        # color = "#fff",
                        padding = 0,
                        child =
                            render.Column(
                                main_align = "start",
                                children = [
                                    render.Text("HARRIS", font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text(print_num(latest_data["dem"]), font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text(print_num(latest_data["rep"]), font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text("TRUMP", font = FONT, color = PARTY_COLORS["REP"]),
                                ] if dem_leading_rep else [
                                    render.Text("HARRIS", font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text(print_num(latest_data["rep"]), font = FONT, color = PARTY_COLORS["REP"]),
                                    render.Text(print_num(latest_data["dem"]), font = FONT, color = PARTY_COLORS["DEM"]),
                                    render.Text("TRUMP", font = FONT, color = PARTY_COLORS["DEM"]),
                                ],
                            ),
                    ),
                ],
            ),
            chart,
        ],
    )

    return render.Root(
        child = animation.Transformation(
            child = row,
            duration = 100,
            delay = 50,
            origin = animation.Origin(0, 0),
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(0, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(-1 * WIDTH, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-1 * WIDTH, 0)],
                ),
            ],
        ),
    )

def postprocess(results):
    days = []
    for day in results:
        final_result = day
        final_result["date_parsed"] = time.parse_time(final_result["date"], "2006-01-02")
        days.append(final_result)

    return days

def draw_chart(data, typ, days):
    averagesD, oldest, newest = get_averages(data, typ, "median", "dem", days)
    averagesR, oldest, newest = get_averages(data, typ, "median", "rep", days)

    lowerD, oldest, newest = get_averages(data, typ, "lower", "dem", days)
    lowerR, oldest, newest = get_averages(data, typ, "lower", "rep", days)

    upperD, oldest, newest = get_averages(data, typ, "upper", "dem", days)
    upperR, oldest, newest = get_averages(data, typ, "upper", "rep", days)

    lowerB = [(averagesD[i][0], max(lowerD[i][1], lowerR[i][1])) for i in range(len(averagesD))]
    upperB = [(averagesD[i][0], min(upperD[i][1], upperR[i][1])) for i in range(len(averagesD))]

    lowest = [(averagesD[i][0], min(lowerD[i][1], lowerR[i][1])) for i in range(len(averagesD))]
    uppest = [(averagesD[i][0], max(upperD[i][1], upperR[i][1])) for i in range(len(averagesD))]

    xlim = (oldest, newest)
    ylim = (40, 60)
    if typ == "ec":
        ylim = (150, 400)
    elif typ == "winprob":
        ylim = (35, 65)

    shades = [] + \
             draw_range(lowest, uppest, xlim, ylim, PARTY_COLORS["DEM_BG"], PARTY_COLORS["REP_BG"]) + \
             draw_range(lowerB, upperB, xlim, ylim, PARTY_COLORS["BOTH_BG"], PARTY_COLORS["REP_BG"])

    if typ == "winprob":
        shades = []

    return render.Stack(
        children = shades + [
            draw_series(lowest, xlim, ylim, "#000", fill = True),
            draw_series(averagesD, xlim, ylim, PARTY_COLORS["DEM"]),
            draw_series(averagesR, xlim, ylim, PARTY_COLORS["REP"]),
        ],
    )

def get_averages(data, typ, sub, party, days):
    now = time.now()
    today = time.time(year = now.year, month = now.month, day = now.day)
    series = sorted([((row["date_parsed"] - today) // (24 * time.hour), row) for row in data if row], reverse = True)

    newest_day = series[0][0]
    oldest_day = max(series[-1][0], -days)
    days = newest_day - oldest_day
    days_per_pixel = max(1, days // 32)
    newest = newest_day // days_per_pixel
    oldest = oldest_day // days_per_pixel

    def extract(poll):
        val = poll[typ][party]
        if type(val) == "dict":
            val = val[sub]
        return val

    polls_by_pixel = {}
    for day, poll in series:
        pixel = day // days_per_pixel
        if pixel in polls_by_pixel:
            polls_by_pixel[pixel].append(extract(poll))
            continue
        polls_by_pixel[pixel] = [extract(poll)]

    averages = [(pixel, sum(polls) / len(polls)) for pixel, polls in polls_by_pixel.items()]

    return averages, oldest, newest

def draw_series(averages, xlim, ylim, color, **kwargs):
    return render.Plot(
        data = averages,
        chart_type = "line",
        width = 64,
        height = 32,
        x_lim = xlim,
        y_lim = ylim,
        color = color,
        **kwargs
    )

def draw_range(lower, upper, xlim, ylim, color, othercolor = "#fff"):
    return [
        draw_series(upper, xlim, ylim, color, fill = True),
        draw_series(lower, xlim, ylim, othercolor, fill = True),
    ]

def pretty_fmt(txt):
    p = " ".join([i[0].upper() + i[1:] for i in txt.split("-")])
    p = p.replace(" General", "")
    return p

def draw_title():
    return render.Padding(
        pad = (0, 1),
        child = render.Marquee(
            width = 64,
            child = render.Row(
                children = [
                    render.Text(
                        content = "Electoral Forecast",
                        font = FONT,
                    ),
                ] * 3,
            ),
            offset_start = 8,
        ),
    )

def sum(list):
    total = 0
    for item in list:
        total += item
    return total

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = PERIOD,
                name = "Period",
                desc = "Show polls from the most recent",
                icon = "calendar",
                default = "30",
                options = [
                    schema.Option(
                        display = "One week",
                        value = "7",
                    ),
                    schema.Option(
                        display = "Two weeks",
                        value = "14",
                    ),
                    schema.Option(
                        display = "30 days",
                        value = "30",
                    ),
                    schema.Option(
                        display = "90 days",
                        value = "90",
                    ),
                    schema.Option(
                        display = "180 days",
                        value = "180",
                    ),
                ],
            ),
            schema.Dropdown(
                id = TYPE,
                name = "Type",
                desc = "Whether to show electoral college or popular vote",
                icon = "question",
                default = DEFAULT_TYPE,
                options = [
                    schema.Option(
                        display = "Electoral College",
                        value = "ec",
                    ),
                    schema.Option(
                        display = "Popular Vote",
                        value = "pv",
                    ),
                    schema.Option(
                        display = "Win Probability",
                        value = "winprob",
                    ),
                ],
            ),
        ],
    )

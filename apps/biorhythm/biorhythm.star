load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PHYSICAL_PERIOD = 23
EMOTIONAL_PERIOD = 28
INTELECTUAL_PERIOD = 33
N_PLOT = 19
N_POINT = 1
PHYSICAL_COLOR = "#ffffcc"
PHYSICAL_COLOR_BRIGHT = "#ffff00"
EMOTIONAL_COLOR = "#ff8080"
EMOTIONAL_COLOR_BRIGHT = "#ff0000"
INTELECTUAL_COLOR = "#8080ff"
INTELECTUAL_COLOR_BRIGHT = "#0000ff"
COL1 = 0
COL2 = 22
COL3 = 44
AMPL = 10.
PI2 = 6.2831853071795864769252867
BOX_TEXT_WIDTH = 21
BOX_TEXT_HEIGHT = 6
VIEWPORT_WIDTH = 64
PLOT_WIDTH = 21
PLOT_HEIGHT = 26

DEBUG = False

def main(config):
    return render.Root(
        child = draw_plot(config),
    )

def getPlotData(date_diff, period, x_offset, n_points):
    arr = []
    for x in range(0, n_points):
        arr.append((x + x_offset, math.floor(AMPL * AMPL * math.sin(PI2 * (date_diff + x) / period)) / AMPL))
    if DEBUG:
        print(arr)

    return arr

def dateDiff(d1, m1, y1, d2, m2, y2):
    m1 = math.mod((m1 + 9), 12)
    y1 = y1 - m1 / 10
    x1 = 365 * y1 + y1 / 4 - y1 / 100 + y1 / 400 + (m1 * 306 + 5) / 10 + (d1 - 1)
    m2 = math.mod((m2 + 9), 12)
    y2 = y2 - m2 / 10
    x2 = 365 * y2 + y2 / 4 - y2 / 100 + y2 / 400 + (m2 * 306 + 5) / 10 + (d2 - 1)

    return x2 - x1

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "BDay",
                name = "Birthdate",
                desc = "Enter your birthdate",
                icon = "calendar",
            ),
        ],
    )

def draw_plot(config):
    if DEBUG:
        print("DRAWING PLOT")

    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)

    default_date = humanize.time_format("yyyy-MM-ddT00:00:00Z", now)
    dt = config.get("BDay", default_date)
    byr = int(dt[:4])
    bmo = int(dt[5:7])
    bdy = int(dt[8:10])

    dD = dateDiff(bdy, bmo, byr, now.day, now.month, now.year)

    return render.Stack(
        children = [
            render.Column(
                main_align = "end",  # this controls position of children, end = bottom
                expanded = True,
                children = [
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(width = BOX_TEXT_WIDTH, height = BOX_TEXT_HEIGHT),
                                    render.Text(" -P-", font = "CG-pixel-3x5-mono"),
                                ],
                            ),
                            render.Stack(
                                children = [
                                    render.Box(width = BOX_TEXT_WIDTH, height = BOX_TEXT_HEIGHT),
                                    render.Text("  -E-", font = "CG-pixel-3x5-mono"),
                                ],
                            ),
                            render.Stack(
                                children = [
                                    render.Box(width = BOX_TEXT_WIDTH, height = BOX_TEXT_HEIGHT),
                                    render.Text("  -I-", font = "CG-pixel-3x5-mono"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
            render.Box(width = VIEWPORT_WIDTH, height = PLOT_HEIGHT),
            #PHYSICAL
            render.Plot(
                data = getPlotData(dD, PHYSICAL_PERIOD, COL1, N_PLOT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = PHYSICAL_COLOR,
                color_inverted = PHYSICAL_COLOR,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
            render.Plot(
                data = getPlotData(dD, PHYSICAL_PERIOD, COL1, N_POINT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = PHYSICAL_COLOR_BRIGHT,
                color_inverted = PHYSICAL_COLOR_BRIGHT,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
            #EMOTIONAL
            render.Plot(
                data = getPlotData(dD, EMOTIONAL_PERIOD, COL2, N_PLOT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = EMOTIONAL_COLOR,
                color_inverted = EMOTIONAL_COLOR,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
            render.Plot(
                data = getPlotData(dD, EMOTIONAL_PERIOD, COL2, N_POINT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = EMOTIONAL_COLOR_BRIGHT,
                color_inverted = EMOTIONAL_COLOR_BRIGHT,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
            #INTELECTUAL
            render.Plot(
                data = getPlotData(dD, INTELECTUAL_PERIOD, COL3, N_PLOT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = INTELECTUAL_COLOR,
                color_inverted = INTELECTUAL_COLOR,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
            render.Plot(
                data = getPlotData(dD, INTELECTUAL_PERIOD, COL3, N_POINT),
                width = PLOT_WIDTH,
                height = PLOT_HEIGHT,
                color = INTELECTUAL_COLOR_BRIGHT,
                color_inverted = INTELECTUAL_COLOR_BRIGHT,
                x_lim = (0, N_PLOT),
                y_lim = (-AMPL, AMPL),
                fill = False,
                chart_type = "scatter",
            ),
        ],
    )

"""
Applet: Date Progress
Summary: Shows date as percentages
Description: Shows todays date as colorful progressbars, you can show the progress of the current day, month and year.
Author: possan
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")

DEFAULT_TIMEZONE = "Europe/Stockholm"

P_LOCATION = "location"
P_SHOW_LABELS = "show_labels"
P_SHOW_VALUES = "show_values"
P_SHOW_DAY = "show_day"
P_SHOW_MONTH = "show_month"
P_SHOW_YEAR = "show_year"

FRAME_WIDTH = 64

def calc_day_progress(now):
    day_progress = 100 * ((now.hour * 60 * 60) + (now.minute * 60) + now.second) / (24 * 60 * 60)

    # print ('day progress:', day_progress)
    return day_progress

def calc_month_progress(now, timezone):
    firstdayofmonth = time.time(year = now.year, month = now.month, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    lastdayofmonth = time.time(year = now.year, month = now.month + 1, day = 0, hour = 23, minute = 59, second = 59, location = timezone)
    month_progress = 100 * (now.unix - firstdayofmonth.unix) / (lastdayofmonth.unix - firstdayofmonth.unix)

    # print ("first day of month", firstdayofmonth)
    # print ("last day of month", lastdayofmonth)
    # print ('month progress:', month_progress)
    return month_progress

def calc_year_progress(now, timezone):
    firstdayofyear = time.time(year = now.year, month = 1, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    lastdayofyear = time.time(year = now.year + 1, month = 1, day = 0, hour = 23, minute = 59, second = 59, location = timezone)
    year_progress = 100 * (now.unix - firstdayofyear.unix) / (lastdayofyear.unix - firstdayofyear.unix)

    # print ("first day of year", firstdayofyear)
    # print ("last day of year", lastdayofyear)
    # print ('year progress:', year_progress)
    return year_progress

def main(config):
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}
    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    now = config.get("time")
    now = (time.parse_time(now) if now else time.now()).in_location(timezone)

    day_progress = calc_day_progress(now)
    month_progress = calc_month_progress(now, timezone)
    year_progress = calc_year_progress(now, timezone)

    state = {
        "show_labels": config.bool(P_SHOW_LABELS, True),
        "show_values": config.bool(P_SHOW_VALUES, True),
        "show_day": config.bool(P_SHOW_DAY, True),
        "show_month": config.bool(P_SHOW_MONTH, True),
        "show_year": config.bool(P_SHOW_YEAR, True),
        "day_progress": day_progress,
        "month_progress": month_progress,
        "year_progress": year_progress,
    }

    return render.Root(
        delay = 32,  # 30 fps
        child = render.Box(
            child = render.Animation(
                children = [
                    get_frame(state, fr, config)
                    for fr in range(300)
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Toggle(
                id = P_SHOW_DAY,
                name = "Show day progress",
                desc = "Whether to show the progress of the current day",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = P_SHOW_MONTH,
                name = "Show month progress",
                desc = "Whether to show the progress of the current month.",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = P_SHOW_YEAR,
                name = "Show year progress",
                desc = "Whether to show the progress of the current year.",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = P_SHOW_LABELS,
                name = "Show labels",
                desc = "Whether to show labels next to the progress bars.",
                icon = "text",
                default = True,
            ),
            schema.Toggle(
                id = P_SHOW_VALUES,
                name = "Show percentages",
                desc = "Whether to show percentages next to the progress bars.",
                icon = "percentage",
                default = True,
            ),
        ],
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def render_progress_bar(state, label, percent, col1, col2, col3, animprogress):
    animpercent = easeOut(animprogress / 100) * percent

    col2orwhite = col2
    if percent >= 100:
        col2orwhite = col1

    label1color = "#fff"
    if animprogress < 40:
        label1color = "#aaa"
    if animprogress < 20:
        label1color = "#333"
    if animprogress < 2:
        label1color = "#111"

    label2align = "start"
    label2color = col3

    labelcomponent = None
    widthmax = FRAME_WIDTH - 1
    if state["show_labels"] == True:
        labelcomponent = render.Stack(
            children = [
                render.Text(
                    content = label,
                    color = label1color,
                    font = "tom-thumb",
                ),
                render.Box(width = 4, height = 6),
            ],
        )
        widthmax -= 4

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
    if state["show_values"] == True:
        label2component = render.Text(
            content = "{}%".format(int(percent * animprogress / 100)),
            color = label2color,
            font = "tom-thumb",
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
                        main_align = "end",
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
                ],
            ),
            render.Box(width = 1, height = 8),
        ],
    )

def capanim(input):
    return max(0, min(100, input))

COLORSCALE = {
    "default": [
        ["#200", "#600", "#f44"],
        ["#210", "#530", "#cc2"],
        ["#020", "#060", "#4f4"],
        ["#012", "#035", "#2cc"],
    ],
}

def get_frame(state, fr, config):
    children = []

    delay = 0
    if state["show_day"]:
        colorindex = 0
        color = COLORSCALE["default"][colorindex]
        children.append(
            render_progress_bar(state, "D", state["day_progress"], color[0], color[1], color[2], capanim((fr - delay) * 4)),
        )
        delay += 30

    if state["show_month"]:
        colorindex = 2
        color = COLORSCALE["default"][colorindex]
        children.append(
            render_progress_bar(state, "M", state["month_progress"], color[0], color[1], color[2], capanim((fr - delay) * 4)),
        )
        delay += 30

    if state["show_year"]:
        colorindex = 3
        color = COLORSCALE["default"][colorindex]
        children.append(
            render_progress_bar(state, "Y", state["year_progress"], color[0], color[1], color[2], capanim((fr - delay) * 4)),
        )

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
    )

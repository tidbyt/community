"""
Applet: Date Progress
Summary: Shows date as percentages
Description: Shows todays date as colorful progressbars, you can show the progress of the current day, month and year.
Author: possan
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Europe/Stockholm"

P_LOCATION = "location"
P_SHOW_LABELS = "show_labels"
P_SHOW_VALUES = "show_values"
P_SHOW_DAY = "show_day"
P_SHOW_MONTH = "show_month"
P_SHOW_YEAR = "show_year"
P_COLOR_YEAR = "#0ff"  # Cyan
P_COLOR_MONTH = "#0f0"  # Green
P_COLOR_DAY = "#f00"  # Red

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

def hsl_to_rgb(h, s, l):
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

def calc_day_progress(now):
    day_progress = 100 * ((now.hour * 60 * 60) + (now.minute * 60) + now.second) / (24 * 60 * 60)

    return day_progress

def calc_day_progress_custom(now, timezone, config):
    start_time = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        hour = int(config.str("start_hour", "0")),
        minute = int(config.str("start_minute", "0")),
        location = timezone,
    )
    end_time = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        hour = int(config.str("end_hour", "0")),
        minute = int(config.str("end_minute", "0")),
        location = timezone,
    )

    if now < start_time:  #if current time is less than start time then still technically in the previous day (can get values over 100 %)
        now += time.parse_duration("24h")

    if end_time <= start_time or end_time.hour == 0:  #move date to the next day for end time if the duration is negative
        end_time += time.parse_duration("24h")

    day_progress = 100 * (now - start_time) / (end_time - start_time)  #calculate percentage
    return day_progress

def calc_month_progress(now, timezone):
    firstdayofmonth = time.time(year = now.year, month = now.month, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    lastdayofmonth = time.time(year = now.year, month = now.month + 1, day = 0, hour = 23, minute = 59, second = 59, location = timezone)
    month_progress = 100 * (now.unix - firstdayofmonth.unix) / (lastdayofmonth.unix - firstdayofmonth.unix)

    return month_progress

def calc_year_progress(now, timezone):
    firstdayofyear = time.time(year = now.year, month = 1, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    lastdayofyear = time.time(year = now.year + 1, month = 1, day = 0, hour = 23, minute = 59, second = 59, location = timezone)
    year_progress = 100 * (now.unix - firstdayofyear.unix) / (lastdayofyear.unix - firstdayofyear.unix)

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

    if config.bool("custom_day"):
        day_progress = calc_day_progress_custom(now, timezone, config)
    else:
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
    colors = [
        schema.Option(display = "White", value = "#fff"),
        schema.Option(display = "Red", value = "#f00"),
        schema.Option(display = "Green", value = "#0f0"),
        schema.Option(display = "Blue", value = "#00f"),
        schema.Option(display = "Yellow", value = "#ff0"),
        schema.Option(display = "Cyan", value = "#0ff"),
        schema.Option(display = "Magenta", value = "#f0f"),
    ]

    hour = [schema.Option(display = str(x), value = str(x)) for x in range(24)]
    minute = [schema.Option(display = str(x), value = str(x)) for x in range(60)]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
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
                icon = "textSlash",
                default = True,
            ),
            schema.Toggle(
                id = P_SHOW_VALUES,
                name = "Show percentages",
                desc = "Whether to show percentages next to the progress bars.",
                icon = "percent",
                default = True,
            ),
            schema.Dropdown(
                id = "color_year",
                icon = "palette",
                name = "Year progress color",
                desc = "The color of the year progress bar.",
                options = colors,
                default = P_COLOR_YEAR,
            ),
            schema.Dropdown(
                id = "color_month",
                icon = "palette",
                name = "Month progress color",
                desc = "The color of the month progress bar.",
                options = colors,
                default = P_COLOR_MONTH,
            ),
            schema.Dropdown(
                id = "color_day",
                icon = "palette",
                name = "Day progress color",
                desc = "The color of the day progress bar.",
                options = colors,
                default = P_COLOR_DAY,
            ),
            schema.Toggle(
                id = "custom_day",
                name = "Custom Day progress interval",
                desc = "Use custom start and end times for day progress bar.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "start_hour",
                icon = "clock",
                name = "Day progress start time (hour)",
                desc = "The start time of the day progress bar (hour).",
                options = hour,
                default = "0",
            ),
            schema.Dropdown(
                id = "start_minute",
                icon = "clock",
                name = "Day progress start time (minute)",
                desc = "The start time of the day progress bar (minute).",
                options = minute,
                default = "0",
            ),
            schema.Dropdown(
                id = "end_hour",
                icon = "clock",
                name = "Day progress end time (hour)",
                desc = "The end time of the day progress bar (hour).",
                options = hour,
                default = "0",
            ),
            schema.Dropdown(
                id = "end_minute",
                icon = "clock",
                name = "Day progress end time (minute)",
                desc = "The end time of the day progress bar (minute).",
                options = minute,
                default = "0",
            ),
        ],
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def render_progress_bar(state, label, percent, col1, col2, col3, animprogress):
    animpercent = easeOut(animprogress / 100) * percent

    label1color = lightness("#fff", animprogress / 100)

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

def get_frame(state, fr, config):
    children = []

    delay = 0
    if state["show_day"]:
        color = config.get("color_day", P_COLOR_DAY)
        children.append(
            render_progress_bar(state, "D", state["day_progress"], lightness(color, 0.06), lightness(color, 0.18), color, capanim((fr - delay) * 4)),
        )
        delay += 30

    if state["show_month"]:
        color = config.get("color_month", P_COLOR_MONTH)
        children.append(
            render_progress_bar(state, "M", state["month_progress"], lightness(color, 0.06), lightness(color, 0.18), color, capanim((fr - delay) * 4)),
        )
        delay += 30

    if state["show_year"]:
        color = config.get("color_year", P_COLOR_YEAR)
        children.append(
            render_progress_bar(state, "Y", state["year_progress"], lightness(color, 0.06), lightness(color, 0.18), color, capanim((fr - delay) * 4)),
        )

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
    )

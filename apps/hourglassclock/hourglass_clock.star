"""
Applet: Hourglass Clock
Summary: Clock with hourglass
Description: Shows a clear digital clock beside an hourglass whose sand tracks progress through the current hour.
Author: Psauter417
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BACKGROUND = "#05070b"
PANEL = "#101722"
FRAME_DARK = "#74451d"
FRAME_LIGHT = "#d29342"
GLASS = "#31506a"
SAND = "#ffc857"
SAND_LIGHT = "#ffe29a"
TEXT = "#f3f6fa"
MUTED = "#8393a5"
FONT = "5x8"
SMALL = "CG-pixel-3x5-mono"

def _px(x, y, width, height, color):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = width, height = height, color = color),
    )

def _two(value):
    return "0" + str(value) if value < 10 else str(value)

def _clock_value(now, clock_format):
    hour = now.hour
    suffix = ""
    if clock_format != "24":
        suffix = "A" if hour < 12 else "P"
        hour = hour % 12
        if hour == 0:
            hour = 12
    return _two(hour) + ":" + _two(now.minute), suffix

def _hourglass(minute):
    parts = [
        _px(44, 2, 19, 2, FRAME_DARK),
        _px(46, 4, 15, 2, FRAME_LIGHT),
        _px(44, 28, 19, 2, FRAME_DARK),
        _px(46, 26, 15, 2, FRAME_LIGHT),
    ]

    # Glass outline: the upper chamber narrows to the neck and the lower
    # chamber widens toward the base.
    for row in range(10):
        inset = row // 2
        left = 47 + inset
        right = 59 - inset
        parts.append(_px(left, 6 + row, 1, 1, GLASS))
        parts.append(_px(right, 6 + row, 1, 1, GLASS))
        parts.append(_px(47 + inset, 25 - row, 1, 1, GLASS))
        parts.append(_px(59 - inset, 25 - row, 1, 1, GLASS))

    top_rows = ((59 - minute) * 8) // 59
    bottom_rows = (minute * 8) // 59

    for row in range(8):
        inset = row // 2
        width = 11 - (inset * 2)
        if row < top_rows:
            parts.append(_px(48 + inset, 7 + row, width, 1, SAND))

        bottom_width = 3 + (inset * 2)
        if row >= 8 - bottom_rows:
            parts.append(_px(52 - inset, 17 + row, bottom_width, 1, SAND))

    if minute > 0 and minute < 59:
        parts.append(_px(53, 15, 2, 2, SAND_LIGHT))

    return parts

def _frame(now, clock_format):
    value, suffix = _clock_value(now, clock_format)
    date_label = now.format("Mon").upper() + " " + _two(now.day)
    parts = [
        _px(1, 3, 40, 26, PANEL),
        _px(3, 5, 36, 16, BACKGROUND),
        render.Padding(
            pad = (6, 8, 0, 0),
            child = render.Text(content = value, font = FONT, color = TEXT),
        ),
        render.Padding(
            pad = (4, 23, 0, 0),
            child = render.Text(content = date_label, font = SMALL, color = MUTED),
        ),
        render.Padding(
            pad = (33, 11, 0, 0),
            child = render.Text(content = suffix, font = SMALL, color = SAND),
        ),
        _px(40, 5, 1, 22, FRAME_DARK),
    ]
    parts.extend(_hourglass(now.minute))
    return render.Box(width = 64, height = 32, color = BACKGROUND, child = render.Stack(children = parts))

def main(config):
    location = config.get("location")
    timezone = json.decode(location)["timezone"] if location else "America/Chicago"
    clock_format = config.get("clock_format") or "12"
    now = time.now().in_location(timezone)
    return render.Root(max_age = 60, child = _frame(now, clock_format))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Choose the clock's timezone",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "clock_format",
                name = "Clock format",
                desc = "Choose 12-hour or 24-hour time",
                icon = "clock",
                default = "12",
                options = [
                    schema.Option(display = "12-hour", value = "12"),
                    schema.Option(display = "24-hour", value = "24"),
                ],
            ),
        ],
    )

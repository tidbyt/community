"""
Applet: Shift Clock
Summary: Track time left in a shift
Description: Shows the current time, remaining shift time, and a progress bar for configurable daily work hours.
Author: Psauter417
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BACKGROUND = "#05080c"
PANEL = "#111a25"
TEXT = "#f5f7fa"
MUTED = "#7f91a5"
BLUE = "#49a7ff"
GREEN = "#55d98b"
AMBER = "#ffc857"
RED = "#ff6b63"
TRACK = "#263545"
FONT = "6x13"
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

def _minutes(value, fallback):
    parts = value.split(":")
    if len(parts) != 2:
        return fallback
    hour = int(parts[0])
    minute = int(parts[1])
    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
        return fallback
    return hour * 60 + minute

def _duration_label(minutes):
    hours = minutes // 60
    remainder = minutes % 60
    if hours == 0:
        return str(remainder) + "M"
    if remainder == 0:
        return str(hours) + "H"
    return str(hours) + "H " + str(remainder) + "M"

def _shift_status(current, start, end):
    if end > start:
        total = end - start
        if current < start:
            until_start = start - current
            if until_start <= 60:
                return "SHIFT IN " + _duration_label(until_start), 0, AMBER
            return "OFF DUTY", 0, MUTED
        if current >= end:
            return "SHIFT DONE", 56, GREEN
        elapsed = current - start
        remaining = end - current
        return "SHIFT " + _duration_label(remaining), (elapsed * 56) // total, BLUE

    # Overnight shifts cross midnight.
    total = (1440 - start) + end
    if current >= start:
        elapsed = current - start
        remaining = (1440 - current) + end
        return "SHIFT " + _duration_label(remaining), (elapsed * 56) // total, BLUE
    if current < end:
        elapsed = (1440 - start) + current
        remaining = end - current
        return "SHIFT " + _duration_label(remaining), (elapsed * 56) // total, BLUE
    until_start = start - current
    if until_start <= 60:
        return "SHIFT IN " + _duration_label(until_start), 0, AMBER
    return "OFF DUTY", 0, MUTED

def _frame(now, clock_format, shift_start, shift_end):
    value, suffix = _clock_value(now, clock_format)
    current = now.hour * 60 + now.minute
    start = _minutes(shift_start, 8 * 60)
    end = _minutes(shift_end, 17 * 60)
    status, progress, accent = _shift_status(current, start, end)
    progress_color = GREEN if status == "SHIFT DONE" else RED
    parts = [
        _px(1, 2, 62, 28, PANEL),
        render.Padding(
            pad = (4, 3, 0, 0),
            child = render.Text(content = value, font = FONT, color = TEXT),
        ),
        render.Padding(
            pad = (39, 9, 0, 0),
            child = render.Text(content = suffix, font = SMALL, color = accent),
        ),
        render.Padding(
            pad = (4, 18, 0, 0),
            child = render.Text(content = status, font = SMALL, color = accent),
        ),
        _px(4, 25, 56, 5, TRACK),
        _px(5, 26, 54, 3, BACKGROUND),
    ]
    if progress > 0:
        parts.append(_px(5, 26, progress - 2 if progress > 2 else 1, 3, progress_color))
    return render.Box(width = 64, height = 32, color = BACKGROUND, child = render.Stack(children = parts))

def main(config):
    location = config.get("location")
    timezone = json.decode(location)["timezone"] if location else "America/Chicago"
    clock_format = config.get("clock_format") or "12"
    shift_start = config.get("shift_start") or "08:00"
    shift_end = config.get("shift_end") or "17:00"
    now = time.now().in_location(timezone)
    return render.Root(max_age = 60, child = _frame(now, clock_format, shift_start, shift_end))

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
            schema.Text(
                id = "shift_start",
                name = "Shift start",
                desc = "Start time in 24-hour HH:MM format",
                icon = "clock",
                default = "08:00",
            ),
            schema.Text(
                id = "shift_end",
                name = "Shift end",
                desc = "End time in 24-hour HH:MM format",
                icon = "clock",
                default = "17:00",
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

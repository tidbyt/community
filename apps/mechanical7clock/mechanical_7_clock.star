"""
Applet: Mechanical 7 Clock
Summary: A brass mechanical clock
Description: Displays the time on a calm brass seven-segment mechanism, with segments engaging and disengaging as the digits change.
Author: Psauter417a
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BLACK = "#050403"
PANEL = "#120f0b"
SHADOW = "#34291c"
OFF = "#211b14"
BRASS = "#c9822f"
AMBER = "#ffb83e"
HOT = "#ffe09a"
STEEL = "#716657"
SMALL = "CG-pixel-3x5-mono"

DIGITS = {
    "0": [0, 1, 2, 3, 4, 5],
    "1": [1, 2],
    "2": [0, 1, 6, 4, 3],
    "3": [0, 1, 6, 2, 3],
    "4": [5, 6, 1, 2],
    "5": [0, 5, 6, 2, 3],
    "6": [0, 5, 6, 4, 2, 3],
    "7": [0, 1, 2],
    "8": [0, 1, 2, 3, 4, 5, 6],
    "9": [0, 1, 2, 3, 5, 6],
}

SEGMENTS = [
    (2, 1, 8, 2),
    (9, 3, 2, 7),
    (9, 13, 2, 7),
    (2, 20, 8, 2),
    (1, 13, 2, 7),
    (1, 3, 2, 7),
    (2, 10, 8, 2),
]

def _px(x, y, width, height, color):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = width, height = height, color = color),
    )

def _transition_digit(old_value, new_value, stage):
    old_active = DIGITS.get(old_value) or []
    new_active = DIGITS.get(new_value) or []
    parts = []
    for index in range(7):
        segment = SEGMENTS[index]
        parts.append(_px(segment[0] + 1, segment[1] + 1, segment[2], segment[3], SHADOW))
        was_on = index in old_active
        is_on = index in new_active
        color = OFF
        if was_on and is_on:
            color = AMBER
        elif was_on:
            color = AMBER if stage == 0 else BRASS if stage == 1 else SHADOW if stage == 2 else OFF
        elif is_on:
            color = OFF if stage <= 1 else SHADOW if stage == 2 else BRASS if stage == 3 else AMBER
        parts.append(_px(segment[0], segment[1], segment[2], segment[3], color))
    parts.append(_px(5, 5, 2, 2, STEEL))
    return render.Box(width = 12, height = 23, color = PANEL, child = render.Stack(children = parts))

def _colon():
    return render.Box(
        width = 3,
        height = 23,
        child = render.Stack(children = [
            _px(0, 7, 3, 3, HOT),
            _px(0, 15, 3, 3, HOT),
        ]),
    )

def _gear_strip(label):
    teeth = []
    for index in range(10):
        height = 3 if index % 2 == 0 else 1
        teeth.append(render.Box(width = 3, height = height, color = BRASS if height == 3 else STEEL))
        teeth.append(render.Box(width = 1, height = 3, color = BLACK))
    return render.Row(children = [
        render.Box(width = 3, height = 5),
        render.Row(children = teeth),
        render.Box(width = 3, height = 5),
        render.Text(content = label, font = SMALL, color = STEEL),
    ])

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
    return _two(hour) + _two(now.minute), suffix

def _frame(old_value, new_value, stage, suffix):
    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Column(children = [
            render.Box(
                width = 64,
                height = 25,
                color = PANEL,
                child = render.Row(
                    main_align = "center",
                    children = [
                        _transition_digit(old_value[0], new_value[0], stage),
                        render.Box(width = 1, height = 23),
                        _transition_digit(old_value[1], new_value[1], stage),
                        _colon(),
                        _transition_digit(old_value[2], new_value[2], stage),
                        render.Box(width = 1, height = 23),
                        _transition_digit(old_value[3], new_value[3], stage),
                    ],
                ),
            ),
            render.Box(width = 64, height = 7, child = _gear_strip(suffix)),
        ]),
    )

def main(config):
    location = config.get("location")
    timezone = json.decode(location)["timezone"] if location else "America/Chicago"
    clock_format = config.get("clock_format") or "12"
    now = time.now().in_location(timezone)
    previous = now - time.parse_duration("1m")
    old_value, _ = _clock_value(previous, clock_format)
    new_value, suffix = _clock_value(now, clock_format)
    frames = []
    for stage in range(5):
        frames.append(_frame(old_value, new_value, stage, suffix))
    for _hold in range(45):
        frames.append(_frame(new_value, new_value, 4, suffix))

    return render.Root(
        delay = 150,
        max_age = 180,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

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

"""
gradient-binary-clock — the time in binary-coded decimal (BCD).

Six columns of glowing "LED" dots, one per digit of HH:MM:SS. Each column
lights the bits that sum to its digit, read top (MSB) to bottom (LSB):

    H   H   M   M   S   S
        .       .       .   8
    .   .   .   .   .   .   4
    .   .   .   .   .   .   2
    .   .   .   .   .   .   1

Columns are bottom-aligned so the classic BCD "staircase" silhouette shows
(hours-tens needs 2 bits, minutes/seconds-tens 3, the ones digits 4). A
synthwave gradient sweeps pink -> cyan left to right; unlit bits glow faintly
in the same hue so the grid stays legible.

The seconds tick live: main() renders one frame per second across a full minute
(render.Animation, 1s/frame), so the display actually counts in binary and
loops seamlessly at the minute boundary.

    pixlet serve apps/gradientbinaryclock/gradient_binary_clock.star
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TZ = "America/New_York"  # the Tidbyt lives in Brooklyn

# bright (lit) color per column, sweeping pink -> magenta -> indigo -> cyan
LIT = ["#ff3b6b", "#ff5ea8", "#c264ff", "#7b6bff", "#3fa9ff", "#22e0d6"]

# faint same-hue glow for the off bits (kept very dark so lit dots dominate)
DIM = ["#3a1018", "#3a1526", "#2a153a", "#1a1633", "#122a3a", "#0b332f"]

CELL = 7  # px cell; holds a diameter-5 dot with a 1px margin all round
DOT = 5
ROWS = 4  # 8-4-2-1 bit rows
DAY = 86400  # seconds in a day, for rollover

# Tidbyt shows an app for ~15s, and pixlet caps a render at 15000ms (its
# --max_duration default). At 1s/frame that's 15 frames: the clock ticks live
# for the whole dwell, then the device moves on and re-renders fresh next time.
FRAMES = 15

def main(config):
    now = time.now().in_location(_timezone(config))
    military = config.bool("military", True)
    show_off = config.bool("show_off", True)

    # One frame per second starting at the current second, so the clock ticks in
    # real time. Increment in seconds-of-day and mod DAY so minute/hour/midnight
    # rollovers just work.
    base = now.hour * 3600 + now.minute * 60 + now.second
    frames = [
        _grid((base + i) % DAY, military, show_off)
        for i in range(FRAMES)
    ]

    return render.Root(
        delay = 1000,  # 1s per frame -> the seconds column advances once/second
        child = render.Animation(children = frames),
    )

def _grid(tod, military, show_off):
    hour = tod // 3600
    minute = (tod % 3600) // 60
    second = tod % 60

    if not military:
        hour = hour % 12
        if hour == 0:
            hour = 12

    # (digit value, number of significant bits) per BCD column
    columns = [
        (hour // 10, 2),
        (hour % 10, 4),
        (minute // 10, 3),
        (minute % 10, 4),
        (second // 10, 3),
        (second % 10, 4),
    ]

    return render.Box(
        child = render.Row(
            cross_align = "end",
            children = [
                _column(i, columns[i][0], columns[i][1], show_off)
                for i in range(6)
            ],
        ),
    )

def _timezone(config):
    loc = config.get("location")
    if loc:
        return json.decode(loc).get("timezone", DEFAULT_TZ)
    return config.get("tz", DEFAULT_TZ)

def _column(idx, value, nbits, show_off):
    cells = []

    # pad the top so every column bottom-aligns into the 4-row grid
    for _ in range(ROWS - nbits):
        cells.append(_cell(None))

    for i in range(nbits):
        on = (value >> (nbits - 1 - i)) & 1
        if on:
            cells.append(_cell(LIT[idx]))
        elif show_off:
            cells.append(_cell(DIM[idx]))
        else:
            cells.append(_cell(None))

    return render.Column(children = cells)

def _cell(color):
    if color == None:
        return render.Box(width = CELL, height = CELL)
    return render.Box(
        width = CELL,
        height = CELL,
        child = render.Circle(diameter = DOT, color = color),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location used to derive the timezone.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "military",
                name = "24-hour clock",
                desc = "Show hours 0-23 instead of 12-hour time.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "show_off",
                name = "Show off bits",
                desc = "Dimly light the unlit bits so the grid is visible.",
                icon = "lightbulb",
                default = True,
            ),
        ],
    )

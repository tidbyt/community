"""
Applet: Time Circuits

Summary: DeLorean Time Circuits

Description: A Back to the Future-inspired time circuit display showing a fixed destination time, the current local date and time, and a last departure time 30 years earlier.

Author: mattj320
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Deliberately simplified for a 64x32 Tidbyt:
# preserve the movie prop's structure, colors, black windows, plaques,
# indicator lights and proportions, while making the actual times the
# highest-priority readable elements.

PANEL = "#3b3b3b"
PANEL_DARK = "#292929"
SEPARATOR = "#101010"
LABEL_RED = "#8b180f"
WINDOW = "#020202"
PLAQUE = "#050505"
TITLE = "#e5e5e5"
RIVET = "#777777"
RIVET_HI = "#d0d0d0"

DEST_COLOR = "#ff4b13"
PRESENT_COLOR = "#39ff14"
LAST_COLOR = "#ffb000"

LAMP_ON = "#ffe451"
LAMP_OFF = "#48320d"

MONTHS = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
]

# Main readout glyphs: 3 wide x 5 tall.
# Digits are intentionally seven-segment-ish, while month letters
# stay readable at the same scale.
VALUE_GLYPHS = {
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "111", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
    "A": ["010", "101", "111", "101", "101"],
    "B": ["110", "101", "110", "101", "110"],
    "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"],
    "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"],
    "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "010"],
    "K": ["101", "101", "110", "101", "101"],
    "L": ["100", "100", "100", "100", "111"],
    "M": ["101", "111", "111", "101", "101"],
    "N": ["101", "111", "111", "111", "101"],
    "O": ["111", "101", "101", "101", "111"],
    "P": ["111", "101", "111", "100", "100"],
    "Q": ["111", "101", "101", "111", "001"],
    "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "111", "001", "110"],
    "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"],
    "W": ["101", "101", "111", "111", "101"],
    "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"],
    "Z": ["111", "001", "010", "100", "111"],
    " ": ["000", "000", "000", "000", "000"],
}

# Plaque glyphs: 3x3, compact enough to fit the movie's full row titles.
TITLE_GLYPHS = {
    "A": ["010", "111", "101"],
    "B": ["110", "111", "110"],
    "C": ["011", "100", "011"],
    "D": ["110", "101", "110"],
    "E": ["111", "110", "111"],
    "F": ["111", "110", "100"],
    "G": ["011", "101", "011"],
    "H": ["101", "111", "101"],
    "I": ["111", "010", "111"],
    "J": ["001", "101", "010"],
    "K": ["101", "110", "101"],
    "L": ["100", "100", "111"],
    "M": ["101", "111", "101"],
    "N": ["101", "111", "101"],
    "O": ["111", "101", "111"],
    "P": ["110", "111", "100"],
    "Q": ["111", "101", "011"],
    "R": ["110", "111", "101"],
    "S": ["011", "010", "110"],
    "T": ["111", "010", "010"],
    "U": ["101", "101", "111"],
    "V": ["101", "101", "010"],
    "W": ["101", "111", "101"],
    "X": ["101", "010", "101"],
    "Y": ["101", "010", "010"],
    "Z": ["111", "010", "111"],
    " ": ["0", "0", "0"],
}

def px(on, fg, bg):
    return render.Box(width = 1, height = 1, color = fg if on else bg)

def glyph(ch, table, fg, bg):
    pattern = table.get(ch, table[" "])
    rows = []
    for y in range(len(pattern)):
        row = []
        for x in range(len(pattern[y])):
            row.append(px(pattern[y][x] == "1", fg, bg))
        rows.append(render.Row(children = row))
    return render.Column(children = rows)

def value_text(text, color, gap = 0):
    children = []
    for i in range(len(text)):
        children.append(glyph(text[i], VALUE_GLYPHS, color, WINDOW))
        if gap > 0 and i < len(text) - 1:
            children.append(render.Box(width = gap, height = 5, color = WINDOW))
    return render.Row(children = children)

def title_text(text):
    children = []
    for i in range(len(text)):
        children.append(glyph(text[i], TITLE_GLYPHS, TITLE, PLAQUE))
        if i < len(text) - 1:
            children.append(spacer(1, 3, PLAQUE))
    return render.Row(children = children)

def spacer(width, height, color):
    return render.Box(width = width, height = height, color = color)

def tab_cell(width, tab_width):
    return render.Box(
        width = width,
        height = 2,
        color = PANEL,
        child = render.Box(width = tab_width, height = 2, color = LABEL_RED),
    )

def label_strip():
    # These thin red tabs are the 64x32 abstraction of the movie's
    # MONTH / DAY / YEAR / HOUR / MIN labels.
    return render.Row(
        children = [
            tab_cell(15, 11),  # MONTH
            spacer(1, 2, PANEL),
            tab_cell(9, 7),  # DAY
            spacer(1, 2, PANEL),
            tab_cell(13, 9),  # YEAR
            render.Box(width = 3, height = 2, color = PANEL_DARK),  # AM/PM block
            tab_cell(10, 8),  # HOUR
            spacer(1, 2, PANEL),  # colon column
            tab_cell(10, 7),  # MIN
        ],
    )

def lamp_column(is_am):
    # The movie uses stacked AM / PM lamps between YEAR and HOUR.
    return render.Box(
        width = 3,
        height = 5,
        color = PANEL_DARK,
        child = render.Column(
            children = [
                render.Box(width = 3, height = 1, color = LABEL_RED),
                render.Box(width = 1, height = 1, color = LAMP_ON if is_am else LAMP_OFF),
                render.Box(width = 3, height = 1, color = PANEL_DARK),
                render.Box(width = 1, height = 1, color = LAMP_OFF if is_am else LAMP_ON),
                render.Box(width = 3, height = 1, color = PANEL_DARK),
            ],
        ),
    )

def value_window(text, width, color, gap = 0):
    return render.Box(
        width = width,
        height = 5,
        color = WINDOW,
        child = value_text(text, color, gap),
    )

def colon_window(color):
    return render.Box(
        width = 1,
        height = 5,
        color = WINDOW,
        child = render.Column(
            children = [
                spacer(1, 1, WINDOW),
                spacer(1, 1, color),
                spacer(1, 1, WINDOW),
                spacer(1, 1, color),
                spacer(1, 1, WINDOW),
            ],
        ),
    )

def values(month, day, year, hour, minute, is_am, color):
    return render.Row(
        children = [
            value_window(month, 15, color, 1),
            spacer(1, 5, PANEL),
            value_window(two_digits(day), 9, color, 1),
            spacer(1, 5, PANEL),
            value_window(str(year), 13, color, 0),
            lamp_column(is_am),
            value_window(two_digits(hour), 10, color, 1),
            colon_window(color),
            value_window(two_digits(minute), 10, color, 1),
        ],
    )

def plaque(title):
    width = len(title) * 4 - 1
    if width < 20:
        width = 20
    return render.Box(
        width = 63,
        height = 3,
        color = PANEL,
        child = render.Box(
            width = width + 2,
            height = 3,
            color = PLAQUE,
            child = title_text(title),
        ),
    )

def rivet_column():
    return render.Column(
        children = [
            spacer(1, 1, RIVET),
            spacer(1, 1, RIVET_HI),
            spacer(1, 2, RIVET),
            spacer(1, 1, PANEL_DARK),
            spacer(1, 2, RIVET),
            spacer(1, 1, RIVET_HI),
            spacer(1, 2, RIVET),
        ],
    )

def panel(title, month, day, year, hour, minute, is_am, color):
    content = render.Column(
        children = [
            label_strip(),
            values(month, day, year, hour, minute, is_am, color),
            plaque(title),
        ],
    )
    return render.Row(children = [content, rivet_column()])

def separator():
    return render.Row(
        children = [
            spacer(63, 1, SEPARATOR),
            spacer(1, 1, RIVET),
        ],
    )

def two_digits(value):
    return ("0" + str(value)) if value < 10 else str(value)

def to_12_hour(hour):
    value = hour % 12
    return 12 if value == 0 else value

def main(config):
    timezone = "America/Chicago"
    location = config.get("location")
    if location:
        loc = json.decode(location)
        if loc.get("timezone"):
            timezone = loc["timezone"]

    now = time.now().in_location(timezone)

    year = int(now.format("2006"))
    month_number = int(now.format("1"))
    day = int(now.format("2"))
    hour_24 = int(now.format("15"))
    minute = int(now.format("04"))

    month = MONTHS[month_number - 1]
    hour = to_12_hour(hour_24)
    is_am = hour_24 < 12

    return render.Root(
        max_age = 60,
        child = render.Column(
            children = [
                panel(
                    "DESTINATION",
                    "OCT",
                    26,
                    1985,
                    1,
                    21,
                    True,
                    DEST_COLOR,
                ),
                separator(),
                panel(
                    "PRESENT TIME",
                    month,
                    day,
                    year,
                    hour,
                    minute,
                    is_am,
                    PRESENT_COLOR,
                ),
                separator(),
                panel(
                    "LAST DEPARTED",
                    month,
                    day,
                    year - 30,
                    hour,
                    minute,
                    is_am,
                    LAST_COLOR,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Sets the timezone for Present Time.",
                icon = "locationDot",
            ),
        ],
    )

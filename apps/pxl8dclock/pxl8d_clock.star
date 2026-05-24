"""
Applet: 24 Hour Big Clock
Author: PXL8D
Summary: Giant 24hr 7-segment clock
Description: A giant 24-hour clock with custom seven-segment digits. 14px digits built from 1x1 Pixlet Box widgets. Configurable color, background, and timezone. Pure pixel art — no fonts, no anti-aliasing, discrete LEDs.
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ═══════════════════════════════════════════════════════════════════
# GIANT 24HR CLOCK — 14x24 seven-segment digits, 1px Box grid.
# Layout: D1(14) + D2(14) + gap(2) + colon(3) + gap(3) + D3(14) + D4(14) = 64px
# ═══════════════════════════════════════════════════════════════════

COLORS = {
    "Amber": "#FFB000",
    "Cyan": "#00FFC8",
    "Green": "#00FF50",
    "Red": "#FF2828",
    "White": "#E0E0E0",
    "Magenta": "#FF0080",
    "Yellow": "#FFE600",
}

BG_COLORS = {
    "Dark": "#171717",
    "Black": "#000000",
    "Charcoal": "#222222",
    "Navy": "#0A0A2E",
    "Dark Green": "#0A1A0A",
}

# 14px-wide digit (cols 0-13), 30px tall. Segments are 3px thick.
# Layout scaled from 24px → 30px for full vertical canvas use.
# Digits centered vertically: 30px content in 32px canvas = 1px top/bottom.
SEGMENTS = {
    "a": [(r, c) for r in range(2, 6) for c in range(3, 12)],  # top horiz 9x4
    "b": [(r, c) for r in range(2, 15) for c in range(11, 14)],  # top-right vert 3x13
    "c": [(r, c) for r in range(15, 28) for c in range(11, 14)],  # bot-right vert 3x13
    "d": [(r, c) for r in range(27, 30) for c in range(3, 12)],  # bottom horiz 9x3
    "e": [(r, c) for r in range(15, 28) for c in range(1, 4)],  # bot-left vert 3x13
    "f": [(r, c) for r in range(2, 15) for c in range(1, 4)],  # top-left vert 3x13
    "g": [(r, c) for r in range(14, 18) for c in range(3, 12)],  # middle horiz 9x4
}

DIGIT_MAP = {
    0: "abcdef",
    1: "bc",
    2: "abdeg",
    3: "abcdg",
    4: "bcgf",
    5: "acdfg",
    6: "acdefg",
    7: "abc",
    8: "abcdefg",
    9: "abcdfg",
}

COLOR_OPTIONS = [schema.Option(display = k, value = v) for k, v in COLORS.items()]
BG_OPTIONS = [schema.Option(display = k, value = v) for k, v in BG_COLORS.items()]

TZ_OPTIONS = [
    schema.Option(display = "Local (auto)", value = "Local"),
    schema.Option(display = "US Eastern", value = "America/New_York"),
    schema.Option(display = "US Central", value = "America/Chicago"),
    schema.Option(display = "US Mountain", value = "America/Denver"),
    schema.Option(display = "US Pacific", value = "America/Los_Angeles"),
    schema.Option(display = "UTC", value = "UTC"),
    schema.Option(display = "Europe/London", value = "Europe/London"),
    schema.Option(display = "Europe/Berlin", value = "Europe/Berlin"),
    schema.Option(display = "Asia/Tokyo", value = "Asia/Tokyo"),
    schema.Option(display = "Australia/Sydney", value = "Australia/Sydney"),
]

def px(color):
    return render.Box(width = 1, height = 1, color = color)

def px_row(pixels):
    return render.Row(children = [px(p) for p in pixels])

def digit_widget(d, on_color, off_color):
    """Build a 14x30 digit as a Column of pixel Rows."""
    segs = DIGIT_MAP.get(d, "")
    grid = [[False] * 14 for _ in range(30)]
    for name in SEGMENTS:
        on = name in segs
        for r, c in SEGMENTS[name]:
            grid[r][c] = on

    rows = []
    for r in range(30):
        row_colors = [on_color if grid[r][c] else off_color for c in range(14)]
        rows.append(px_row(row_colors))
    return render.Column(children = rows)

def colon_widget(lit, on_color, off_color):
    """Two 3x3 dots stacked vertically, centered in 30px."""
    rows = []
    for r in range(30):
        on = lit and ((9 <= r and r <= 11) or (18 <= r and r <= 20))
        row_colors = [on_color if on else off_color for _ in range(3)]
        rows.append(px_row(row_colors))
    return render.Column(children = rows)

def spacer(w, h, off_color):
    return render.Box(width = w, height = h, color = off_color)

def clock_row(d1, d2, d3, d4, colon_lit, on_color, off_color):
    """Build the full 64x30 clock row, centered vertically in 32px canvas.

    Layout: D1(14) + D2(14) + gap(2) + colon(3) + gap(3) + D3(14) + D4(14) = 64px
    """
    return render.Row(
        cross_align = "center",
        children = [
            digit_widget(d1, on_color, off_color),
            digit_widget(d2, on_color, off_color),
            spacer(2, 30, off_color),
            colon_widget(colon_lit, on_color, off_color),
            spacer(3, 30, off_color),
            digit_widget(d3, on_color, off_color),
            digit_widget(d4, on_color, off_color),
        ],
    )

def main(config):
    on_color = config.get("color", "#FFB000")
    off_color = config.get("bg", "#171717")
    tz = config.get("timezone", "")

    if tz and tz != "Local":
        now = time.now().in_location(tz)
    else:
        now = time.now()

    hour = now.hour
    minute = now.minute

    d1 = hour // 10
    d2 = hour % 10
    d3 = minute // 10
    d4 = minute % 10

    return render.Root(
        delay = 1000,
        child = render.Animation(
            children = [
                clock_row(d1, d2, d3, d4, colon_lit = True, on_color = on_color, off_color = off_color),
                clock_row(d1, d2, d3, d4, colon_lit = False, on_color = on_color, off_color = off_color),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "The color of the clock digits.",
                icon = "palette",
                default = COLORS["Amber"],
                options = COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "bg",
                name = "Background",
                desc = "The background color.",
                icon = "paintbrush",
                default = BG_COLORS["Dark"],
                options = BG_OPTIONS,
            ),
            schema.Dropdown(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone to display.",
                icon = "globe",
                default = "Local",
                options = TZ_OPTIONS,
            ),
        ],
    )

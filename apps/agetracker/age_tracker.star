"""Age Tracker — your life in months on a 64x32 Tidbyt.

Draws one cell for every month from birth to age 82 (984 months), packed to fill
the whole 64x32 display instead of a small centered block. Cells are 2px wide and
1px tall, laid out 32 per row, so the grid spans the full 64px width and 31 of the
32px height (984 months = 30 full rows of 32 + a final row of 24). Every month
still gets exactly one cell.

The screen is animated: it starts as an all-white grid, then the months you have
already lived "turn blue" left-to-right, row by row (top row first, each row
filled left to right), completing over ~5 seconds. Months still ahead stay white
the whole time. After the lived months are filled, the grid holds before the
Tidbyt loops the animation.
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Layout -----------------------------------------------------------------
LIFESPAN_YEARS = 82
TOTAL_MONTHS = LIFESPAN_YEARS * 12  # 984
WIDTH = 64
HEIGHT = 32

# Cells are 2px wide x 1px tall, 32 per row. 32 cols * 2px == 64px (full width).
# 984 months span 31 rows (30 * 32 + 24), so the grid is 64x31 -- essentially the
# whole panel, with the last row holding the final 24 months.
COLS = 32
CELL_W = 2
CELL_H = 1
ROWS = (TOTAL_MONTHS + COLS - 1) // COLS  # 31
GRID_W = COLS * CELL_W  # 64
GRID_H = ROWS * CELL_H  # 31
# The grid is top-left aligned (origin y = 0); the 1px below the 31-row grid is
# left as background at the bottom of the panel.

# --- Defaults ---------------------------------------------------------------
DEFAULT_BIRTHDATE = "1990-01-01"
DEFAULT_LIVING_COLOR = "#3b82f6"
REMAINING_COLOR = "#ffffff"
BG_COLOR = "#000000"
DATE_FORMAT = "2006-01-02"

# --- Animation tuning -------------------------------------------------------
# The lived-month squares turn blue progressively over REVEAL_FRAMES steps at
# FRAME_DELAY_MS each (~5s). Frame 0 is the all-white grid, so the reveal uses
# REVEAL_FRAMES + 1 frames (0..REVEAL_FRAMES). HOLD_FRAMES extra copies of the
# finished grid keep it on screen before the loop restarts.
REVEAL_FRAMES = 30  # 30 * 166ms ~= 5.0s to fill all lived months
HOLD_FRAMES = 18  # 18 * 166ms ~= 3.0s hold on the completed grid
FRAME_DELAY_MS = 166

def months_lived(birthdate, now):
    """Whole months elapsed from birthdate to now, clamped to [0, TOTAL_MONTHS]."""
    months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month)

    # Subtract the current month if we haven't reached the birth day-of-month yet.
    if now.day < birthdate.day:
        months -= 1

    if months < 0:
        months = 0
    if months > TOTAL_MONTHS:
        months = TOTAL_MONTHS
    return months

def parse_birthdate(raw):
    """Parse a birthdate from config, tolerant of both input shapes.

    The mobile app's date picker (schema.DateTime) hands us an RFC-3339
    timestamp like "1990-01-01T00:00:00Z"; local `pixlet serve`/`render` and the
    legacy installation pass a plain "YYYY-MM-DD". Try the full timestamp first,
    then the date-only format, and finally fall back to the default so the screen
    always renders something.
    """
    raw = raw.strip()

    # time.parse_time raises (rather than returning None) on a mismatch, and
    # Starlark has no try/except, so pick the format by inspecting the string.
    # The mobile date picker (schema.DateTime) sends RFC-3339 with a "T"; local
    # serve/render and the legacy install send a plain "YYYY-MM-DD".
    if "T" in raw:
        return time.parse_time(raw)  # RFC-3339 (default format)
    if len(raw) >= 10 and raw[4] == "-" and raw[7] == "-":
        return time.parse_time(raw[:10], format = DATE_FORMAT)
    return time.parse_time(DEFAULT_BIRTHDATE, format = DATE_FORMAT)

def grid(filled, living_color):
    """Render the grid with the first `filled` months turned blue.

    Cells are laid out in chronological (row-major) order: index 0 is the
    top-left month, advancing left-to-right then top-to-bottom. The first
    `filled` cells are `living_color`; every remaining cell stays white. Because
    `filled` only ever counts up to the number of lived months, the blue front
    sweeps left-to-right, row by row, and unlived months are always white.
    """
    rows = []
    for r in range(ROWS):
        cells = []
        for c in range(COLS):
            index = r * COLS + c
            if index >= TOTAL_MONTHS:
                # Phantom cells past month 984 (the tail of the last row) stay
                # background so the grid ends cleanly.
                color = BG_COLOR
            elif index < filled:
                color = living_color
            else:
                color = REMAINING_COLOR
            cells.append(render.Box(width = CELL_W, height = CELL_H, color = color))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def frame(filled, living_color):
    # render.Stack pins every child at the top-left origin (0, 0), so the first
    # grid row sits flush against the top edge (y = 0) with no vertical
    # centering. The background Box fills the whole panel; the leftover 1px below
    # the 31-row grid shows at the bottom, not the top.
    return render.Stack(
        children = [
            render.Box(width = WIDTH, height = HEIGHT, color = BG_COLOR),
            grid(filled, living_color),
        ],
    )

def main(config):
    birthdate = parse_birthdate(config.str("birthdate", DEFAULT_BIRTHDATE))
    living_color = config.str("livingColor", DEFAULT_LIVING_COLOR)
    now = time.now()

    lived = months_lived(birthdate, now)

    # Frame 0 is the all-white grid; each subsequent frame turns more lived
    # months blue, left-to-right and row-by-row, until all `lived` are filled.
    frames = []
    for f in range(0, REVEAL_FRAMES + 1):
        filled = lived * f // REVEAL_FRAMES
        frames.append(frame(filled, living_color))

    # Hold on the finished grid before the device loops back to the start.
    finished = frame(lived, living_color)
    for _ in range(HOLD_FRAMES):
        frames.append(finished)

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "birthdate",
                name = "Birthdate",
                desc = "Pick your birthdate.",
                icon = "cakeCandles",
            ),
            schema.Color(
                id = "livingColor",
                name = "Lived color",
                desc = "Color for months you have already lived.",
                icon = "brush",
                default = DEFAULT_LIVING_COLOR,
                palette = [
                    "#3b82f6",
                    "#ef4444",
                    "#22c55e",
                    "#eab308",
                    "#a855f7",
                ],
            ),
        ],
    )

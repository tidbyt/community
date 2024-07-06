"""
Applet: Gradient Clock
Summary: Animated Gradient Clock
Description: Clock displayed over animated, colorful gradient background.
Author: tpatel12
"""

load("render.star", "render")
load("time.star", "time")

num_rows = 16
num_cols = 32
mapping = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

def hex_map(r, g, b, a = 15):
    if r < 0:
        r = 0
    if r > 15:
        r = 15
    if g < 0:
        g = 0
    if g > 15:
        g = 15
    if b < 0:
        b = 0
    if b > 15:
        b = 15

    r = int(r)
    g = int(g)
    b = int(b)

    if a != None:
        a = max(0, min(15, int(a)))

    return mapping[r] + mapping[g] + mapping[b] + mapping[a]

def render_time_text(now):
    return render.Box(
        color = "#0000",
        child = render.WrappedText(
            content = now.format("3:04"),
            font = "10x20",
            color = "#FFFFFF",
            align = "center",
        ),
    )

def get_rectangle(row, col, frame_num):
    frame_num *= 2
    period = 125
    if frame_num < period:
        alpha = frame_num - row - col

    elif frame_num < period * 2:
        alpha = 200 - (frame_num + row - col)

    elif frame_num < period * 3:
        alpha = -2 * period + frame_num - (num_rows - row) - (num_cols - col)

    else:
        alpha = 2 * period + 200 - (frame_num + (num_rows - row) - (num_rows - col))

    if (row + col) % 2 == 0:
        return render.Box(width = 2, height = 2, color = hex_map(15 - row - 1, row - 1, col - 1, alpha))
    else:
        return render.Box(width = 2, height = 2, color = hex_map(15 - row - 4, row - 4, col - 4, alpha))

def render_grid(frame_num):
    rows = []
    for grid_row in range(num_rows):
        rows.append(render.Row([get_rectangle(grid_row, grid_col, frame_num) for grid_col in range(num_cols)]))

    return render.Column(rows)

def render_frame(frame_num, now):
    return render.Stack(children = [render_grid(frame_num), render_time_text(now)])

def main(config):
    timezone = config.get("$tz", "America/New_York")
    now = time.now().in_location(timezone)

    frames = []

    NUM_FRAMES = 250
    frames = [render_frame(i, now) for i in range(NUM_FRAMES)]

    return render.Root(
        delay = 60,
        child = render.Animation(frames),
    )

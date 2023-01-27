"""
Applet: DVD Logo
Summary: Bouncing DVD Logo
Description: A screensaver from before the streaming era. Will it hit the corner this time?
Author: Mack Ward
"""

load("encoding/base64.star", "base64")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAME_WIDTH = 64
FRAME_HEIGHT = 32

IMAGE_WIDTH = 15
IMAGE_HEIGHT = 9

IMAGE = """iVBORw0KGgoAAAANSUhEUgAAAA8AAAAJCAYAAADtj3ZXAAAAQUlEQVQokWNgwA3+I2Fc8hgK/iPR//HwMWxhYMBuEDZDcSpCNwiX4VhdgK4AlxiKBnRMUB5fiBJyIUHnE6WQZJsBSnw7xZmNBscAAAAASUVORK5CYII="""

COLORS = [
    "#0ef",  # light blue
    "#f70",  # orange
    "#02f",  # dark blue
    "#fe0",  # yellow
    "#f20",  # red
    "#f08",  # pink
    "#b0f",  # purple
]

NUM_X_POSITIONS = FRAME_WIDTH - IMAGE_WIDTH
NUM_Y_POSITIONS = FRAME_HEIGHT - IMAGE_HEIGHT
NUM_STATES = NUM_X_POSITIONS * NUM_Y_POSITIONS * len(COLORS) * 2

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

def main():
    delay = 100 * time.millisecond
    frames_per_second = time.second / delay

    now = time.now().unix_nano / (1000 * 1000 * 1000)
    frames_since_epoch = int(now * frames_per_second)
    index = int(frames_since_epoch % NUM_STATES)

    app_cycle_speed = 30 * time.second
    num_frames = math.ceil(app_cycle_speed / delay)

    frames = [
        get_frame(get_state(i))
        for i in range(index, index + num_frames)
    ]

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(frames),
    )

def get_state(index):
    num_x_hits = index // NUM_X_POSITIONS
    vel_x = num_x_hits % 2 == 0 and 1 or -1

    num_y_hits = index // NUM_Y_POSITIONS
    vel_y = num_y_hits % 2 == 0 and 1 or -1

    num_x_states = NUM_X_POSITIONS * 2
    pos_x = index % num_x_states + 1
    if vel_x != 1:
        pos_x = num_x_states - pos_x

    num_y_states = NUM_Y_POSITIONS * 2
    pos_y = index % num_y_states + 1
    if vel_y != 1:
        pos_y = num_y_states - pos_y

    num_corner_hits = index // (NUM_X_POSITIONS * NUM_Y_POSITIONS)
    num_hits = num_x_hits + num_y_hits - num_corner_hits
    color = COLORS[num_hits % len(COLORS)]

    return struct(
        pos_x = pos_x,
        pos_y = pos_y,
        vel_x = vel_x,
        vel_y = vel_y,
        color = color,
    )

def get_frame(state):
    return render.Padding(
        pad = (state.pos_x, state.pos_y, 0, 0),
        child = render.Stack(
            children = [
                render.Box(
                    width = IMAGE_WIDTH,
                    height = IMAGE_HEIGHT,
                    color = state.color,
                ),
                render.Image(base64.decode(IMAGE)),
            ],
        ),
    )

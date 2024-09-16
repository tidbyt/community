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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

def main(config):
    delay = 100 * time.millisecond
    frames_per_second = time.second / delay

    image = render.Image(base64.decode(config.get("image", IMAGE)))

    now = time.now().unix_nano / (1000 * 1000 * 1000)
    frames_since_epoch = int(now * frames_per_second)
    num_states = image.size()[0] * image.size()[1] * len(COLORS) * 2
    index = int(frames_since_epoch % num_states)

    app_cycle_speed = 30 * time.second
    num_frames = math.ceil(app_cycle_speed / delay)

    frames = [
        get_frame(get_state(i, image), image)
        for i in range(index, index + num_frames)
    ]

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(frames),
    )

def get_state(index, image):
    num_x_positions = FRAME_WIDTH - image.size()[0]
    num_y_positions = FRAME_HEIGHT - image.size()[1]

    num_x_hits = index // num_x_positions
    vel_x = num_x_hits % 2 == 0 and 1 or -1

    num_y_hits = index // num_y_positions
    vel_y = num_y_hits % 2 == 0 and 1 or -1

    num_x_states = num_x_positions * 2
    pos_x = index % num_x_states + 1
    if vel_x != 1:
        pos_x = num_x_states - pos_x

    num_y_states = num_y_positions * 2
    pos_y = index % num_y_states + 1
    if vel_y != 1:
        pos_y = num_y_states - pos_y

    num_corner_hits = index // (num_x_positions * num_y_positions)
    num_hits = num_x_hits + num_y_hits - num_corner_hits
    color = COLORS[num_hits % len(COLORS)]

    return struct(
        pos_x = pos_x,
        pos_y = pos_y,
        vel_x = vel_x,
        vel_y = vel_y,
        color = color,
    )

def get_frame(state, image):
    return render.Padding(
        pad = (state.pos_x, state.pos_y, 0, 0),
        child = render.Stack(
            children = [
                render.Box(
                    width = image.size()[0],
                    height = image.size()[1],
                    color = state.color,
                ),
                image,
            ],
        ),
    )

"""
Applet: Game of Life Clock
Summary: Game of Life on a clock
Description: Plays Conway's Game of Life using the pixels of a clock display as the starting point (clock stays visible at all times).
Author: kevwoods
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32
X_RANGE = range(WIDTH)
Y_RANGE = range(HEIGHT)

# Relative coordinates of the eight neighbors that determine whether a cell lives or dies
NEIGHBORS = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

# A list with 11 elements (corresponding to digits 0-9, colon, and empty space)
# Each element is a 13 height x 8 width 0/1 array to display that character,
# using Markus Kuhn's 10x20 font
FONT_ARRAY = [[[0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0]], [[0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 1, 1, 1, 0, 0, 0], [0, 1, 1, 1, 1, 0, 0, 0], [1, 1, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1, 1]], [[0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 1, 1, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1, 1]], [[0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0]], [[0, 0, 0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 1, 1, 1, 0], [0, 0, 0, 1, 1, 1, 1, 0], [0, 0, 1, 1, 0, 1, 1, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 1, 1, 0], [1, 1, 1, 1, 1, 1, 1, 1], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 1, 1, 0]], [[1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 1, 1, 1, 0, 0], [1, 1, 1, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0]], [[0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 1, 1, 1, 0, 0], [1, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0]], [[1, 1, 1, 1, 1, 1, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 1, 1, 0, 0], [0, 0, 0, 0, 1, 1, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 1, 1, 0, 0, 0, 0], [0, 0, 1, 1, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0]], [[0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0]], [[0, 0, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 1], [0, 0, 1, 1, 1, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 0, 0, 0, 0, 0, 1, 1], [0, 1, 0, 0, 0, 0, 1, 1], [0, 1, 1, 0, 0, 1, 1, 0], [0, 0, 1, 1, 1, 1, 0, 0]], [[0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 0, 1, 1, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0]], [[0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0]]]

# Living cells with 2 or 3 living neighbors survive
SURVIVAL_RULE = [2, 3]

# Dead cells with 3 living neighbors come alive
BIRTH_RULE = [3]

# 180 frames in the animation seems to be the max to render fast enough on tidbyt servers.
# More like 300 frames seems ideal.
FRAMES = 120

# Placement of clock display elements
PADDING_TOP = 9
PADDING_LEFT = 8
CHAR_WIDTH = 10

# Default config parameters
DEFAULT_FAST = True
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_TWENTY_FOUR_HOUR = False

# background, live, dead, clock, overlap colors
DEFAULT_COLORS = ["#559", "#f60", "#000", "#fff", "#fb8"]

# Given a list of characters (the numbers to display on the clock), returns a 0/1 array of pixels.
def create_clock_array(chars):
    state = [[0 for _ in X_RANGE] for _ in Y_RANGE]
    for i, char in enumerate(chars):
        for y, row in enumerate(FONT_ARRAY[char]):
            for x, pixel in enumerate(row):
                state[PADDING_TOP + y][PADDING_LEFT + i * CHAR_WIDTH + x] += pixel
    return state

# Renders a single pixel at the point (x,y). 'pixel' must be
# a rendered 1x1 box of the appropriate color.
# These will be stacked to make the frames
def render_pixel(x, y, pixel):
    return render.Padding(pad = (x, y, 0, 0), child = pixel)

# Creates the initial state with given alive cells. For a point x,y, state[y][x] is a dictionary with:
# "alive" value -1/0/1 depending on whether (x,y) is dead / original background state / alive,
# "nbrs" a list of the neighbors of (x,y) (this list never changes),
# "nbr_count" a count of how many neighbors of (x,y) are alive
# Also renders the first frame of the animation by stacking pixels in game_display
def initial_state(alive, background_color, overlap_pixel):
    state = [[{"alive": 0} for x in X_RANGE] for y in Y_RANGE]
    game_display = [render.Box(color = background_color)]
    for x in X_RANGE:
        for y in Y_RANGE:
            if alive[y][x] == 1:
                state[y][x]["alive"] = 1
                game_display.append(render_pixel(x, y, overlap_pixel))
            state[y][x]["nbrs"] = []
            for dx, dy in NEIGHBORS:
                state[y][x]["nbrs"].append(((x + dx) % WIDTH, (y + dy) % HEIGHT))
    for x in X_RANGE:
        for y in Y_RANGE:
            state[y][x]["nbr_count"] = 0
            for nx, ny in state[y][x]["nbrs"]:
                state[y][x]["nbr_count"] += state[ny][nx]["alive"]
    return state, render.Stack(children = game_display)

# Updates the state of the game by one time step, and renders the next frame.
def update_state(state, frame, clock_array, live_pixel, dead_pixel, clock_pixel, overlap_pixel):
    # Compute which cells will die and live
    changed = [(x, y, state[y][x]["alive"]) for x in X_RANGE for y in Y_RANGE if ((state[y][x]["alive"] == 1 and state[y][x]["nbr_count"] not in SURVIVAL_RULE) or (state[y][x]["alive"] in [-1, 0] and state[y][x]["nbr_count"] in BIRTH_RULE))]

    game_display = [frame]

    # For the cells that die, change their status, and also their neighbors will now have one fewer living neighbor.
    # Same for cells that are born. Change color, based on whether it overlaps the clock.
    for x, y, a in changed:
        if a == 1:
            state[y][x]["alive"] = -1
            for nx, ny in state[y][x]["nbrs"]:
                state[ny][nx]["nbr_count"] -= 1
            if clock_array[y][x] == 1:
                game_display.append(render_pixel(x, y, clock_pixel))
            else:
                game_display.append(render_pixel(x, y, dead_pixel))
        else:
            state[y][x]["alive"] = 1
            for nx, ny in state[y][x]["nbrs"]:
                state[ny][nx]["nbr_count"] += 1
            if clock_array[y][x] == 1:
                game_display.append(render_pixel(x, y, overlap_pixel))
            else:
                game_display.append(render_pixel(x, y, live_pixel))

    return state, render.Stack(children = game_display)

def main(config):
    # Get colors from config, and create rendered pixels for all but background
    background_color = config.get("background", DEFAULT_COLORS[0])
    live_pixel = render.Box(width = 1, height = 1, color = config.get("live", DEFAULT_COLORS[1]))
    dead_pixel = render.Box(width = 1, height = 1, color = config.get("dead", DEFAULT_COLORS[2]))
    clock_pixel = render.Box(width = 1, height = 1, color = config.get("clock", DEFAULT_COLORS[3]))
    overlap_pixel = render.Box(width = 1, height = 1, color = config.get("overlap", DEFAULT_COLORS[4]))

    # Other configs from get_schema
    fast = config.bool("fast")
    twenty_four_hour = config.bool("24hour")

    # Gets time zone and gets hour and minutes
    location = config.get("location")
    location = json.decode(location) if location else {}
    timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))
    now = time.now().in_location(timezone)
    hour = now.hour
    if not twenty_four_hour and hour > 12:
        hour = hour - 12
    if not twenty_four_hour and hour == 0:
        hour = 12
    minute = now.minute

    # Creates 0/1 array for the clock (passing 10 corresponds to colon in FONT_ARRAY)
    clock_array = create_clock_array([hour // 10, hour % 10, 10, minute // 10, minute % 10])

    # Creates list of pixels in colon, for use in blinking (passing 11 corresponds to blank space)
    colon_array = create_clock_array([11, 11, 10, 11, 11])
    colon_pixels = [(x, y) for x in X_RANGE for y in Y_RANGE if colon_array[y][x] == 1]

    # Creates initial state and rendered frame for the
    # game of life based on the pixels in the clock array.
    # See comment before 'def initial_state()' for info about data type of state
    state, frame = initial_state(clock_array, background_color, overlap_pixel)

    # Fast animation will take 15 seconds, slow will take a minute.
    if fast:
        frames_per_sec = FRAMES // 15
    else:
        frames_per_sec = FRAMES // 60
    delay = 1000 // frames_per_sec

    # Now we build the frames of the animation, blinking colon if slow animation
    # After each frame, we will update the state of the game
    frames = []
    for i in range(FRAMES):
        # for the slow animation, the pixels in the colon will blink on/off every frame (every half second)
        if not fast and i % 2 == 1:
            frame_colon = [frame]
            for x, y in colon_pixels:
                if state[y][x]["alive"] == 1:
                    frame_colon.append(render_pixel(x, y, live_pixel))
                else:
                    frame_colon.append(render_pixel(x, y, dead_pixel))
            frames.append(render.Stack(children = frame_colon))
        else:
            frames.append(frame)
        state, frame = update_state(state, frame, clock_array, live_pixel, dead_pixel, clock_pixel, overlap_pixel)

    return render.Root(
        delay = delay,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "background",
                name = "Background Color",
                desc = "Color of the screen.",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "live",
                name = "Live Cell Color",
                desc = "Color of the live cells in the game.",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "dead",
                name = "Dead Cell Color",
                desc = "Color of the dead cells.",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "clock",
                name = "Clock Color",
                desc = "Color of the clock display.",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
            schema.Color(
                id = "overlap",
                name = "Overlap Color",
                desc = "Color of the live cells when overlapping the clock.",
                icon = "brush",
                default = DEFAULT_COLORS[4],
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "fast",
                name = "Fast animation",
                desc = "Fast animation lasts 15 seconds (at 4x speed) vs. 60 seconds",
                icon = "gaugeHigh",
                default = DEFAULT_FAST,
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 hour clock",
                desc = "Enable a 24 hour clock.",
                icon = "clock",
                default = DEFAULT_TWENTY_FOUR_HOUR,
            ),
        ],
    )

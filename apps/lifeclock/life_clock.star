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

# 180 frames in the animation seems a happy medium between a long
# enough game and short enough rendering time.
FRAMES = 180

# Placement of clock display elements
PADDING_TOP = 9
PADDING_LEFT = 8
CHAR_WIDTH = 10

# Default config parameters
DEFAULT_FAST = True
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_COLORS = ["#000", "#fff", "#f60", "#fb8"]
DEFAULT_TWENTY_FOUR_HOUR = False

# Given a string of characters (the numbers to display on the clock), returns a 0/1 array of pixels.
def create_clock_array(chars):
    state = [[0 for _ in X_RANGE] for _ in Y_RANGE]
    for i, char in enumerate(chars):
        for y, row in enumerate(FONT_ARRAY[char]):
            for x, pixel in enumerate(row):
                state[PADDING_TOP + y][PADDING_LEFT + i * CHAR_WIDTH + x] += pixel
    return (state)

# Creates the initial state with given alive cells. For a point x,y, state[y][x] is a dictionary with:
# "alive" value 0/1 depending on whether (x,y) is alive,
# "nbrs" a list of the neighbors of (x,y) (this list never changes),
# "nbr_count" a count of how many neighbors of (x,y) are alive
def initial_state(alive):
    state = [[{"alive": 0} for x in X_RANGE] for y in Y_RANGE]
    for x in X_RANGE:
        for y in Y_RANGE:
            if alive[y][x] == 1:
                state[y][x]["alive"] = 1
            state[y][x]["nbrs"] = []
            for dx, dy in NEIGHBORS:
                state[y][x]["nbrs"].append(((x + dx) % WIDTH, (y + dy) % HEIGHT))
    for x in X_RANGE:
        for y in Y_RANGE:
            state[y][x]["nbr_count"] = 0
            for nx, ny in state[y][x]["nbrs"]:
                state[y][x]["nbr_count"] += state[ny][nx]["alive"]
    return state

# Updates the state of the game by one time step.
def update_state(state):
    # Compute which cells will die and live
    died = [(x, y) for x in X_RANGE for y in Y_RANGE if state[y][x]["alive"] == 1 and state[y][x]["nbr_count"] not in SURVIVAL_RULE]
    born = [(x, y) for x in X_RANGE for y in Y_RANGE if state[y][x]["alive"] == 0 and state[y][x]["nbr_count"] in BIRTH_RULE]

    # for the cells that die, change their status, and also their neighbors will now have one fewer living neighbor
    for x, y in died:
        state[y][x]["alive"] = 0
        for nx, ny in state[y][x]["nbrs"]:
            state[ny][nx]["nbr_count"] -= 1

    # for the cells that are born, change their status, and also their neighbors will now have one more living neighbor
    for x, y in born:
        state[y][x]["alive"] = 1
        for nx, ny in state[y][x]["nbrs"]:
            state[ny][nx]["nbr_count"] += 1

    return state

# Renders a single pixel at the point (x,y). 'pixel' must be
# a rendered 1x1 box of the appropriate color.
# These will be stacked to make the frames
def render_pixel(x, y, pixel):
    return render.Padding(pad = (x, y, 0, 0), child = pixel)

# Renders the display of the clock, given a 0/1 array of the pixels,
# a rendered pixel of the appropriate color, and the background color
def render_clock(clock_array, clock_pixel, background_color):
    background = render.Box(color = background_color)
    foreground = render.Stack(children = [render_pixel(x, y, clock_pixel) for x in X_RANGE for y in Y_RANGE if clock_array[y][x] == 1])
    return render.Stack(children = [background, foreground])

# Returns one frame in the animation, given the rendered background clock,
# a 0/1 array for the clock's pixels, the state of the game, and
# a list of two rendered pixels of the appropriate colors for the game:
def render_frame(clock_rendered, clock_array, state, game_pixels):
    game_display = render.Stack(children = [render_pixel(x, y, game_pixels[clock_array[y][x]]) for x in X_RANGE for y in Y_RANGE if state[y][x]["alive"] == 1])
    return render.Stack(children = [clock_rendered, game_display])

def main(config):
    # Get colors from config, create a rendered pixel (1x1 box) for clock
    # and create a list of two rendered pixels for the game:
    # one for the live cell color against the background and
    # one for the live cell color against the clock
    background_color = config.get("color0", DEFAULT_COLORS[0])
    clock_pixel = render.Box(width = 1, height = 1, color = config.get("color1", DEFAULT_COLORS[1]))
    game_pixels = [
        render.Box(width = 1, height = 1, color = config.get("color2", DEFAULT_COLORS[2])),
        render.Box(width = 1, height = 1, color = config.get("color3", DEFAULT_COLORS[3])),
    ]

    # Other configs from get_schema
    fast = config.get("fast", DEFAULT_FAST)
    twenty_four_hour = config.get("24hour", DEFAULT_TWENTY_FOUR_HOUR)

    # Gets time zone and gets hour and minutes
    location = config.get("location")
    location = json.decode(location) if location else {}
    timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))
    now = time.now().in_location(timezone)
    hour = now.hour
    if not twenty_four_hour and hour > 12:
        hour = hour - 12
    minute = now.minute

    # Creates 0/1 arrays for the two clock displays that will alternate,
    # one with and one without colon
    # (passing 10 corresponds to colon and 11 to space in FONT_ARRAY)
    clock_arrayA = create_clock_array([hour // 10, hour % 10, 10, minute // 10, minute % 10])
    clock_arrayB = create_clock_array([hour // 10, hour % 10, 11, minute // 10, minute % 10])

    # Renders these two clocks
    clock_renderedA = render_clock(clock_arrayA, clock_pixel, background_color)
    clock_renderedB = render_clock(clock_arrayB, clock_pixel, background_color)

    # Creates initial state for the game of life based on the pixels
    # in the clock array. See comment before 'def initial_state()' for
    # info about data type of state
    state = initial_state(clock_arrayA)

    # Fast animation will take 15 seconds, slow will take a minute.
    if fast:
        frames_per_sec = FRAMES // 15
    else:
        frames_per_sec = FRAMES // 60
    delay = 1000 // frames_per_sec

    # Now we build the frames of the animation.
    # After each frame, we will update the state of the game
    # We alternate between displaying the colon for one second and
    # then hiding it for one second
    frames = []
    for i in range(FRAMES):
        if (i // frames_per_sec) % 2 == 0:
            frames.append(render_frame(clock_renderedA, clock_arrayA, state, game_pixels))
        else:
            frames.append(render_frame(clock_renderedB, clock_arrayB, state, game_pixels))
        state = update_state(state)

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
                id = "color0",
                name = "Background Color",
                desc = "Color of the screen.",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "color1",
                name = "Clock Color",
                desc = "Color of the clock display.",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "color2",
                name = "Live Cell Color",
                desc = "Color of the live cells against the background.",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "color3",
                name = "Overlap Color",
                desc = "Color of the live cells when overlapping the clock.",
                icon = "brush",
                default = DEFAULT_COLORS[3],
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

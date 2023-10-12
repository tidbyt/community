"""
Applet: Fireflies
Summary: Moving and flashing fireflies
Description: Display moving and flashing fireflies with or without the time
Author: J. Keybl

"""

load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = 64  # Tidbyt width
HEIGHT = 32  # Tidbyt height
HEIGHT_CLOCK = 26  # Height when clock is on

YELLOW = "#ffff00"  # Firefly palette color
GREEN = "#ADFF2F"  # Firefly palette color
ORANGE_RED = "#FF4500"  # Firefly palette color
BLUE = "#0000FF"  # Firefly palette color
VELOCITY = 0.33333  # Radial velocity of fireflies [pixels / frame]
N_FIREFLIES = 10  # Default number of fireflies
FIREFLY_X = 0  # Firefly x-position
FIREFLY_Y = 1  # Firefly y-position
FIREFLY_HUE = 2  # Firefly hue
FIREFLY_LIGHTNESS = 3  # Firefly lightness
FIREFLY_UPDOWN = 4  # Firefly lightness direction UP or DOWN
FIREFLY_DX = 5  # Firefly change (delta) in x per frame
FIREFLY_DY = 6  # Firefly change (delta) in y per frame
FIREFLY_OFF = 7  # When the lightness is decremented and goes below 0, firefly doesn't light up until the lightness reaches this value and subsequently gets incremented to above 0, but x-y positions still change during these frames

TEXT_FONT = "CG-pixel-3x5-mono"  # Text font name
FONT_HEIGHT = 5  # Font height
RIGHT_ALIGN = "right"  # Align type
LEFT_ALIGN = "left"
CENTER_ALIGN = "center"
TIMECOLOR = "#405678"  # Color of time text
DEFAULT_LOCATION = {
    # Default location for local time
    "lat": 38.8951,
    "lng": -77.0364,
    "locality": "Washington, D.C.",
    "timezone": "America/New_York",
}

PI = 3.1415926535897932384626  # pi
UP = 1  # Lightness direction - plus (get brighter)
DOWN = -1  # Lightness direction - minus (get dimmer)
SCALE = 10000  # Scale value for generating random numbers to a specific decimal place [10 -> 0.1, 100 -> 0.01, 1000 -> .001]
DELTA_LIGHTNESS = 10  # Change in lightness per frame
MAX_LIGHTNESS = 70  # Maximum lightness before dimming
DELAY = 175  # Delay between frames (milliseconds)
N_FRAMES = int(15 * 1000 / DELAY)  # Number of frames to equate to 15 seconds based on delay

def main(config):
    fireflies = []
    frames = []

    # Initialize variables from schema
    show_clock = config.bool("show_clock", False)
    color = config.str("color", YELLOW)
    hue, _, _ = hex_rgb_to_hsl(color)
    n_fireflies = int(config.get("n_fireflies", N_FIREFLIES))
    delta_lightness = int(config.get("glow", DELTA_LIGHTNESS))
    rnd_color = config.bool("rnd_color", False)
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]

    # Create initial fireflies
    for _ in range(n_fireflies):
        fireflies.append(create_firefly(hue, rnd_color, show_clock))

    # Draw frames
    for _ in range(N_FRAMES):
        # Draw fireflies into frame
        frames.append(render_frame(generate_screen(fireflies), show_clock, timezone))

        # Update fireflies
        fireflies = update_fireflies(fireflies, hue, rnd_color, show_clock, delta_lightness)

    return renderAnimation(frames)

# ****************************************
# Firefly functions
# ****************************************

def create_firefly(hue, rnd_color, show_clock):
    x = random.number(1, WIDTH - 1)
    y = random.number(1, HEIGHT - 1)
    for _ in range(0, 10):
        if (check_position(x, y, show_clock) == False):
            x = random.number(1, WIDTH - 1)
            y = random.number(1, HEIGHT - 1)
        else:
            break
    if rnd_color:
        hue, _, _ = hex_rgb_to_hsl(random_color())
    theta = (-1 + 2 * rnd(SCALE)) * PI  # Angular direction of motion
    r = VELOCITY * rnd(SCALE)  # Radial velocity of motion
    dx = r * math.cos(theta)  # Change in x-direction
    dy = r * math.sin(theta)  # Change in y-directions
    ud = DOWN if random.number(0, 1) == 0 else UP  # Multiplier for whether incrementing or decrementing lightness
    off = random.number(3, 10) * -10  # Negative value of lightness before changing to incrementing the lightness
    lightness = random.number(0, 140) - 70  # Randomly choose lightness between -70 and +70

    return [x, y, hue, lightness, ud, dx, dy, off]  # x-coordinate, y-coordinate, hue, lightness, up/down (1, -1), dx, dy, off

def update_fireflies(fireflies, hue, rnd_color, show_clock, delta_lightness):
    for s in range(len(fireflies)):
        fireflies[s][FIREFLY_X] = fireflies[s][FIREFLY_X] + fireflies[s][FIREFLY_DX]
        fireflies[s][FIREFLY_Y] = fireflies[s][FIREFLY_Y] + fireflies[s][FIREFLY_DY]
        test_result = check_position(fireflies[s][FIREFLY_X], fireflies[s][FIREFLY_Y], show_clock)
        if test_result and fireflies[s][FIREFLY_X] >= 0 and fireflies[s][FIREFLY_X] < WIDTH and fireflies[s][FIREFLY_Y] >= 0 and fireflies[s][FIREFLY_Y] < HEIGHT:
            if fireflies[s][FIREFLY_LIGHTNESS] >= MAX_LIGHTNESS:
                fireflies[s][FIREFLY_UPDOWN] = DOWN
            if fireflies[s][FIREFLY_LIGHTNESS] <= fireflies[s][FIREFLY_OFF]:
                fireflies[s][FIREFLY_UPDOWN] = UP
            fireflies[s][FIREFLY_LIGHTNESS] = int(fireflies[s][FIREFLY_LIGHTNESS] + fireflies[s][FIREFLY_UPDOWN] * delta_lightness)
        else:
            fireflies[s][FIREFLY_X], fireflies[s][FIREFLY_Y], fireflies[s][FIREFLY_HUE], fireflies[s][FIREFLY_LIGHTNESS], fireflies[s][FIREFLY_UPDOWN], fireflies[s][FIREFLY_DX], fireflies[s][FIREFLY_DY], fireflies[s][FIREFLY_OFF] = create_firefly(hue, rnd_color, show_clock)

    return fireflies

# ****************************************
# Helper functions
# ****************************************

def check_position(x, y, show_clock):
    # Check if firefly is behind visible clock - indicates that a new firefly needs to be created
    if show_clock == False:
        return True
    if y < 26:
        return True
    if x < 15:
        return True
    if x > 48:
        return True
    return False

def rnd(scale):
    # Generate random number between 0 and 1 with number of decimal places based on the scale value, e.g. 10 -> 1 decimal place, 100 -> 2 decimal places, 1000 -> 3 decimal places, etc.
    return random.number(0, scale) / scale

# ****************************************
# Color functions
# ****************************************

def random_color():
    # Generate a random hex color
    red = random.number(0, 255)
    green = random.number(0, 255)
    blue = random.number(0, 255)
    return ("#" + int_to_hex(red) + int_to_hex(green) + int_to_hex(blue))

def hex_rgb_to_hsl(hex_color):
    # Convert hex red, green blue values to hue, saturation, lightness values
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    hsl = rgb_to_hsl(r, g, b)
    return hsl

def hsl_to_hex_rgb(h, s, l):
    # Convert hue, saturation, lightness values to hex red, green blue values
    red, green, blue = hsl_to_rgb(h, s, l)
    return ("#" + int_to_hex(red) + int_to_hex(green) + int_to_hex(blue))

def rgb_to_hsl(r, g, b):
    # Convert red, green blue integer values to hue, saturation, lightness values
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max_color = max(r, g, b)
    min_color = min(r, g, b)

    # Calculate lightness
    lightness = (max_color + min_color) / 2.0

    if max_color == min_color:
        hue = 0
        saturation = 0
    else:
        delta = max_color - min_color

        # Calculate saturation
        if lightness < 0.5:
            saturation = delta / (max_color + min_color)
        else:
            saturation = delta / (2.0 - max_color - min_color)

        # Calculate hue
        if max_color == r:
            hue = (g - b) / delta
        elif max_color == g:
            hue = (b - r) / delta + 2
        else:
            hue = (r - g) / delta + 4
        hue *= 60
        hue = hue if hue > 0 else hue + 360

    return hue, saturation, lightness

def hsl_to_rgb(h, s, l):
    # Convert hue, saturation, lightness values to integer red, green blue values
    h = h % 360
    s = max(0, min(1, s))
    l = max(0, min(1, l))

    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2

    if h >= 0 and h < 60:
        r, g, b = c, x, 0
    elif h >= 60 and h < 120:
        r, g, b = x, c, 0
    elif h >= 120 and h < 180:
        r, g, b = 0, c, x
    elif h >= 180 and h < 240:
        r, g, b = 0, x, c
    elif h >= 240 and h < 300:
        r, g, b = x, 0, c
    else:
        r, g, b = c, 0, x

    r = int((r + m) * 255)
    g = int((g + m) * 255)
    b = int((b + m) * 255)

    return r, g, b

def int_to_hex(value):
    # Convert integer to hex string
    d = int(value / 16)
    r = value % 16
    p1 = str(d) if d < 10 else chr(55 + d)
    p2 = str(r) if r < 10 else chr(55 + r)
    hex_string = p1 + p2
    return hex_string

# ****************************************
# Tidbyt rendering functions
# ****************************************

def generate_screen(array):
    arr = [["#000000" for i in range(WIDTH)] for j in range(HEIGHT)]
    for list in array:
        if list[FIREFLY_LIGHTNESS] > 0:
            arr[int(list[FIREFLY_Y])][int(list[FIREFLY_X])] = hsl_to_hex_rgb(list[FIREFLY_HUE], 1., list[FIREFLY_LIGHTNESS] / 100)
    return arr

def render_frame(frame, show_clock, timezone):
    if show_clock:
        children = [
            render.Column(
                children = [render_row(row) for row in frame],
            ),
            render.Padding(
                pad = (0, HEIGHT_CLOCK, 0, 0),
                child = render.Box(
                    width = WIDTH,
                    height = FONT_HEIGHT,
                    child = render.WrappedText(
                        content = humanize.time_format("K:mm aa", time.now().in_location(timezone)),
                        font = TEXT_FONT,
                        color = TIMECOLOR,
                        align = CENTER_ALIGN,
                        width = WIDTH,
                    ),
                ),
            ),
        ]
    else:
        children = [
            render.Column(
                children = [render_row(row) for row in frame],
            ),
        ]
    return render.Stack(
        children = children,
    )

def render_row(row):
    return render.Row(children = [render_cell(cell) for cell in row])

def render_cell(cell):
    return render.Box(width = 1, height = 1, color = cell)

def renderAnimation(frames):
    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(
            children = frames,
        ),
    )

# ****************************************
# Schema function
# ****************************************

def get_schema():
    options_number = [
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = str(N_FIREFLIES),
            value = str(N_FIREFLIES),
        ),
        schema.Option(
            display = "15",
            value = "15",
        ),
        schema.Option(
            display = "20",
            value = "20",
        ),
    ]
    options_duration = [
        schema.Option(
            display = "Long",
            value = "5",
        ),
        schema.Option(
            display = "Regular",
            value = str(DELTA_LIGHTNESS),
        ),
        schema.Option(
            display = "Short",
            value = "15",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "n_fireflies",
                name = "Num Fireflies",
                desc = "Select number of fireflies.",
                icon = "arrowsToDot",
                default = options_number[1].value,
                options = options_number,
            ),
            schema.Dropdown(
                id = "glow",
                name = "Glow Duration",
                desc = "Select how long fireflies glow.",
                icon = "lightbulb",
                default = options_duration[1].value,
                options = options_duration,
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Select color of fireflies.",
                icon = "brush",
                default = YELLOW,
                palette = [
                    YELLOW,
                    GREEN,
                    ORANGE_RED,
                    BLUE,
                ],
            ),
            schema.Toggle(
                id = "rnd_color",
                name = "Random Colors",
                desc = "Enable random colors.",
                icon = "sliders",
                default = False,
            ),
            schema.Toggle(
                id = "show_clock",
                name = "Show Clock",
                desc = "Enable displaying time.",
                icon = "sliders",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for local time.",
            ),
        ],
    )

"""
Applet: FullyBinaryTime
Summary: A clock for nerds
Description: Clock using fully binary time. First divide the day into two 12 hour parts, then each of those into two 6 hour parts, then two 3 hour parts, and so on up to 16 bits of precision.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

HALF_DAY_NANOSECONDS = 43200000000000  # 12 * 60 * 60 * 1000000
REFRESH_MILLISECONDS = 100
APP_DURATION_MILLISECONDS = 15000  # Longest app can be shown

DEFAULT_LOCATION = {
    "lat": 40.7128,
    "lng": -74.0060,
    "locality": "New York, NY",
}
DEFAULT_TIMEZONE = "America/New_York"

CLOCK_BITS = 16  # Precision of clock
GRAPHICAL_ICON_SIZE = 4
GRAPHICAL_ROW_WIDTH = 4  # Assumed that graphical clock is square
GRAPHICAL_CLOCK_SIZE = (GRAPHICAL_ROW_WIDTH * (GRAPHICAL_ICON_SIZE + 1)) + 1
GRRAPHICAL_CLOCK_BORDER_SIZE = GRAPHICAL_CLOCK_SIZE + 2
GRAPHICAL_CLOCK_PADDING = 64 - GRRAPHICAL_CLOCK_BORDER_SIZE - 1

BLACK = "#000"
WHITE = "#fff"
RED = "#f00"

# Show each bit as either on or off.
def graphical_icon(levels, row, column):
    if levels[(row * GRAPHICAL_ROW_WIDTH) + column] == 1:
        colour = WHITE
    else:
        colour = BLACK

    return render.Box(
        height = GRAPHICAL_ICON_SIZE,
        width = GRAPHICAL_ICON_SIZE,
        color = colour,
    )

# Show a row of bits.
def graphical_row(levels, row_number):
    return render.Row(
        expanded = True,
        main_align = "space_around",
        children = [graphical_icon(levels, row_number, c) for c in range(0, GRAPHICAL_ROW_WIDTH)],
    )

# Top-right corner shows the time graphically.
def get_graphical_clockface(levels):
    return render.Padding(
        pad = (40, 1, 0, 0),
        child = render.Box(
            width = GRAPHICAL_CLOCK_SIZE + 2,
            height = GRAPHICAL_CLOCK_SIZE + 2,
            color = RED,
            padding = 1,
            child = render.Box(
                width = GRAPHICAL_CLOCK_SIZE,
                height = GRAPHICAL_CLOCK_SIZE,
                color = "#000",
                child = render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [graphical_row(levels, r) for r in range(0, GRAPHICAL_ROW_WIDTH)],
                ),
            ),
        ),
    )

# Most of the screen shows the time as text.
def get_text_clockface(levels):
    # Special formatting for the most important bits.
    if levels[0] == 1:
        first = "on"
    else:
        first = "off"
    if levels[1] == 1:
        second = "late"
    else:
        second = "early"
    if levels[2] == 1:
        third = "super"
    else:
        third = "sub"

    # Remainder as digits.
    rest = "".join(["%d" % level for level in levels[3:]])

    return render.Column(
        children = [
            render.Padding(pad = (1, 0, 0, 0), child = render.Text(first)),
            render.Padding(pad = (1, 0, 0, 0), child = render.Text(second)),
            render.Padding(pad = (1, 0, 0, 0), child = render.Text(third)),
            render.Text(rest),
        ],
    )

# Show the fully binary time in two different ways.
def make_frame(elapsed):
    # Convert elapsed time into fully binary time.
    levels = []
    numerator = elapsed.nanoseconds
    divisor = HALF_DAY_NANOSECONDS
    for _ in range(0, CLOCK_BITS):
        levels.append(numerator // divisor)
        numerator = math.mod(numerator, divisor)
        divisor /= 2

    return render.Stack(
        children = [
            get_text_clockface(levels),
            get_graphical_clockface(levels),
        ],
    )

# Pregenerate enough frames for the longest possible app cycle.
def make_animation(timezone):
    # Key input is how long has passed since the start of the day.
    now = time.now().in_location(timezone)
    midnight = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    elapsed = now - midnight

    frames = []
    for delta in range(0, APP_DURATION_MILLISECONDS, REFRESH_MILLISECONDS):
        new_elapsed = elapsed + (delta * time.millisecond)
        frames.append(make_frame(new_elapsed))
    return render.Animation(children = frames)

def main(config):
    # Determine timezone based on location
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))  # Use special timezone variable.

    # The smallest bit shown corresponds to a period of ~1.3 seconds, so we should update
    # the screen while the app is showing.
    return render.Root(
        max_age = 120,
        delay = REFRESH_MILLISECONDS,
        child = make_animation(timezone),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to show the time",
                icon = "locationDot",
            ),
        ],
    )

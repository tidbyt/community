"""
Federal Flag displays the United States flag on a flagpole.

The flag automatically moves to half-staff while a federal half-staff notice
is active. Users can choose between a slow wave and a still flag.
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STATUS_URL = "https://halfstaff.org/wp-json/halfstaff/v1/widget"
STATUS_CACHE_SECONDS = 900

DISPLAY_WIDTH = 64
DISPLAY_HEIGHT = 32

POLE = "#b8c3cf"
POLE_HIGHLIGHT = "#edf2f7"
GOLD = "#f6c445"
RED = "#b31942"
WHITE = "#ffffff"
BLUE = "#0a3161"

POLE_X = 18
FLAG_X = POLE_X + 2
FLAG_WIDTH = 27
FLAG_HEIGHT = 13
FULL_STAFF_Y = 3
HALF_STAFF_Y = 11

FRAME_DELAY_MS = 450
WAVE_OFFSETS = [0, 0, 1, 1, 0, 0, -1, -1]

def federal_half_staff_active():
    """Return True only when the status endpoint reports a federal notice."""
    response = http.get(STATUS_URL, ttl_seconds = STATUS_CACHE_SECONDS)
    if response.status_code != 200:
        print("Flag status request failed with status %s; displaying full-staff." % response.status_code)
        return False

    data = response.json()
    return data.get("type", "none") == "federal"

def flag_color(x, y):
    """Return the correct pixel color for a compact 30x13 U.S. flag."""
    if x < 12 and y < 7:
        # Alternating star dots suggest the field of 50 stars at this scale.
        if (y % 2 == 1 and x % 2 == 1) or (y % 2 == 0 and x % 4 == 2):
            return WHITE
        return BLUE

    if y % 2 == 0:
        return RED
    return WHITE

def flag_column(x):
    """Compress a flag column into vertical runs of the same color."""
    children = []
    run_color = flag_color(x, 0)
    run_height = 1

    for y in range(1, FLAG_HEIGHT):
        color = flag_color(x, y)
        if color == run_color:
            run_height += 1
        else:
            children.append(render.Box(width = 1, height = run_height, color = run_color))
            run_color = color
            run_height = 1

    children.append(render.Box(width = 1, height = run_height, color = run_color))
    return render.Column(children = children)

def wave_offset(x, frame):
    """Create a restrained wave that travels from the pole to the fly edge."""
    if frame == None:
        return 0

    phase = (x // 4 - frame) % len(WAVE_OFFSETS)
    amplitude = 0 if x < 3 else 1
    return WAVE_OFFSETS[phase] * amplitude

def scene(half_staff, frame = None):
    flag_y = HALF_STAFF_Y if half_staff else FULL_STAFF_Y
    flag_columns = []

    for x in range(FLAG_WIDTH):
        flag_columns.append(
            render.Padding(
                pad = (FLAG_X + x, flag_y + wave_offset(x, frame), 0, 0),
                child = flag_column(x),
            ),
        )

    return render.Stack(
        children = [
            render.Padding(
                pad = (POLE_X, 0, 0, 0),
                child = render.Box(width = 2, height = DISPLAY_HEIGHT, color = POLE),
            ),
            render.Padding(
                pad = (POLE_X, 0, 0, 0),
                child = render.Box(width = 1, height = DISPLAY_HEIGHT, color = POLE_HIGHLIGHT),
            ),
            render.Padding(
                pad = (POLE_X - 1, 0, 0, 0),
                child = render.Box(width = 4, height = 2, color = GOLD),
            ),
        ] + flag_columns,
    )

def main(config):
    half_staff = federal_half_staff_active()
    wave = config.bool("wave", True)

    if not wave:
        child = scene(half_staff)
    else:
        frames = []
        for frame in range(len(WAVE_OFFSETS)):
            frames.append(scene(half_staff, frame))
        child = render.Animation(children = frames)

    return render.Root(
        child = child,
        delay = FRAME_DELAY_MS,
        max_age = 1800,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "wave",
                name = "Wave flag",
                desc = "Animate the flag with a slow, gentle wave.",
                icon = "wind",
                default = True,
            ),
        ],
    )

"""
Applet: Days to St Pats
Summary: Counts days to St Patricks
Description: Count the days left until St. Patrick's Day while watching a rainbow get closer to its pot o' gold.
Author: oogashaka
"""

load("encoding/base64.star", "base64")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

DURATION = 15100
FRAME_DELAY = 100

GOLD_POT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAKpJREFUKFNjZEAC/z8x/L91Wxssom58lRFZDs4BKWK4wAeW+6Ehw8DBcQ3MZuRjAKsBE2BFIAU/tMCSIEUgNseNJxDFdp8YEQqRTYMqYDD4BLed8eZZbbBpuZXSDDvX7AJLuIe4gWkQH8QG0Yxubm5ghbt2QRShAzc3iCaw1SDFRCvEZirMtF27djEy/j/E9x/kK3QnICsCq4EFDSgM3VssUJy4s+YEA8znABBtUUte+5c/AAAAAElFTkSuQmCC")
GOLD_POT_WIDTH = 10
GOLD_POT_HEIGHT = 10

CLOVER = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAASNJREFUKFNtUl1OwzAM/pxW3GXd4ACTWAcSd2ASGw+72EQ7JMQhBkMgeIZm4iastDay00wUkZcmdvz9pYS4iAQgQAS6tQ9BtKR1Yel2etQGgOzxyjZEDj4vMdjM7DI5wE/KAGIERDLczlFNCmQPM5BLrcxNA3IEP72F9n1+o4Qkw6f5QVl1WmCwuTRaMGN3fofY93mhfAFdkZTTbLCi13DpUQ8IkCBJPYgQRs8LCDNcmuJ9vDIZv5dKDh5AMnq5hrQMlzhwy72L8VBNyhDd8evSkAHBx3iFbLvoSVEPzf4Lnxf3wfTJ2xJtXf+LqkWTYlr0Wagb2NfW+Ks7ovhpqZL7ppUvDmi8Mc7d2drQuekGDn+HcxpsiFdjI5IkTez1+bsxUT+kg40YKNjTrQAAAABJRU5ErkJggg==")
CLOVER_WIDTH = 12
CLOVER_HEIGHT = 12

RED = "#ff0000"
ORANGE = "#ff4500"
YELLOW = "#ffff00"
GREEN = "#008000"
BLUE = "#0000ff"
INDIGO = "#4b0082"
VIOLET = "#ee82ee"
RAINBOW_COLORS = [RED, ORANGE, YELLOW, GREEN, BLUE, INDIGO, VIOLET]
RAINBOW_MAX_HEIGHT = 10
RAINBOW_MAX_LENGTH = 64 - GOLD_POT_WIDTH

WAVE_SPEED = 3

def create_rainbow(width):
    # construct a rainbow of vertical beams
    rainbow = []
    l_pad = 0
    for i in range(width):
        t_pad = 32 - RAINBOW_MAX_HEIGHT
        beam = []
        for i in range(len(RAINBOW_COLORS) - 1):
            cell = {
                "color": RAINBOW_COLORS[i],
                "width": 1,
                "height": 1,
                "pos_x": l_pad,
                "pos_y": t_pad + i,
            }
            beam.append(cell)

        rainbow.append(beam)
        l_pad = l_pad + 1

    return rainbow

def render_rainbow(rainbow, wave, timestamp_ms):
    cells = []

    progress = math.ceil(timestamp_ms / DURATION * len(rainbow))

    wave_len = len(wave)
    wave_pos = int(timestamp_ms / FRAME_DELAY) % (wave_len - 1)

    for i in range(progress):
        beam = rainbow[i]

        for cell in beam:
            c_pad = (
                cell["pos_x"],
                cell["pos_y"] + wave[(wave_pos + i) % (wave_len - 1)],
                0,
                0,
            )
            cells.append(render.Padding(child = render.Box(width = cell["width"], height = cell["height"], color = cell["color"]), pad = c_pad))

    return render.Stack(children = cells)

def define_wave(amp):
    # create oscillation
    wave = list(range(amp + 1)) + list(range(amp - 1, -1, -1))

    # affect speed
    wave = [i for i in wave for _ in range(WAVE_SPEED)]

    return wave

def main(config):
    timezone = config.get("timezone") or "America/New_York"
    current_date = time.now().in_location(timezone)

    st_patricks_day = time.time(year = current_date.year, month = 3, day = 17, hour = 0, minute = 0, location = timezone)
    st_patricks_day_end = time.time(year = current_date.year, month = 3, day = 17, hour = 23, minute = 59, second = 59, location = timezone)

    # If St. Patrick's Day has already passed this year, calculate for the next year
    if current_date > st_patricks_day_end:
        st_patricks_day = time.time(year = current_date.year + 1, month = 3, day = 17, location = timezone)

    st_patricks_day_datestring = "March 17, " + str(st_patricks_day.year)

    diff = st_patricks_day - current_date

    # Calculate the difference in days
    days_until_st_patricks = math.ceil(diff.hours / 24)

    # create static elements
    clover = render.Padding(
        pad = (7, 1, 0, 0),
        child = render.Box(
            width = CLOVER_WIDTH,
            height = CLOVER_HEIGHT,
            child = render.Image(
                src = CLOVER,
            ),
        ),
    )

    days_until = render.Padding(
        pad = (20, 0, 0, 0),
        child = render.Box(
            width = 44,
            height = 10,
            child = render.Text(
                content = " %s" % humanize.plural(int(days_until_st_patricks), "day") if days_until_st_patricks > 0 else "Today",
                color = "#FFFFFF",
                height = 0,
                offset = 0,
            ),
        ),
    )

    st_pat_day = render.Padding(
        pad = (0, 12, 0, 0),
        child = render.Box(
            width = 64,
            height = 10,
            child = render.Text(
                #content = "March 17, 2024",
                content = st_patricks_day_datestring if days_until_st_patricks > 0 else "Happy St Pat's",
                color = "#00FF00",
                font = "CG-pixel-3x5-mono",
            ),
        ),
    )

    pot = render.Padding(
        pad = (54, 22, 0, 0),
        child = render.Box(
            width = GOLD_POT_WIDTH,
            height = GOLD_POT_HEIGHT,
            child = render.Image(
                src = GOLD_POT,
            ),
        ),
    )

    # create rainbow animation
    timestamp_ms = 0
    frame_count = int(DURATION / FRAME_DELAY)
    frames = []
    rainbow_length = math.floor((365 - days_until_st_patricks) / 365 * RAINBOW_MAX_LENGTH)
    rainbow = create_rainbow(rainbow_length)
    amp = RAINBOW_MAX_HEIGHT - len(RAINBOW_COLORS) + 1
    wave = define_wave(amp)

    for _ in range(frame_count):
        frame_stack = []
        frame_stack.append(clover)
        frame_stack.append(days_until)
        frame_stack.append(st_pat_day)
        frame_stack.append(render_rainbow(rainbow, wave, timestamp_ms))
        frame_stack.append(pot)
        frames.append(render.Stack(children = frame_stack))
        timestamp_ms += FRAME_DELAY

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Animation(frames),
    )

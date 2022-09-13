"""
Applet: Moon Phase
Summary: Shows current moon phase
Description: Shows phase of moon based on location.
Author: Chris Wyman
"""

# Moon Phase
#
# Copyright (c) 2022 Chris Wyman
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")

#
# Default location
#

DEFAULT_LOCATION = """
{
    "lat": 47.606,
    "lng": -122.332,
    "locality": "Seattle, WA, USA",
    "timezone": "America/Los_Angeles"
}
"""

#
# Time formats used in get_schema
#

TIME_FORMATS = {
    "None": None,
    "12 hour": ("3:04", "3 04", True),
    "24 hour": ("15:04", "15 04", False),
}

#
# moon image constants
#

MOONIMG_WIDTH = 32  # Width of moon image
MOONIMG_HEIGHT = 32  # Height of moon image

#
# background MOON_IMG constants
#

X_C = MOONIMG_WIDTH / 2.0 - 0.5  # X-center of MOON_IMG in pixel coordinates, - 0.5 so it's middle of the pixel
Y_C = MOONIMG_HEIGHT / 2.0 - 0.5  # Y-center of MOON_IMG in pixel coordinates, - 0.5 so it's middle of the pixel
R = (MOONIMG_HEIGHT - 2) / 2.0  # radius of MOON_IMG in pixel coordinates, HEIGHT - 2 because of the 1 pixel margin about disc (specific to MOON_IMG)

#
# moon cycle constants
#

LUNATION = 2551443  # lunar cycle in seconds (29 days 12 hours 44 minutes 3 seconds)
REF_NEWMOON = time.parse_time("30-Apr-2022 20:28:00", format = "02-Jan-2006 15:04:05").unix

#
# geometric/graphic constants
#

SHADOW_LEVEL = 0.15
FADE_LNG = math.pi / 6  # 30 degrees in moon longitude, but fade is non-linear (see comment in percent_illuminated())
FONT = "tom-thumb"
CLOCK_PADDING = 24  # y-offset of clock in pixels

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    tz = location.get("timezone")

    currtime = time.now("UTC")
    #currtime = time.parse_time("16-Sep-2022 20:17:00", format="02-Jan-2006 15:04:05")    # pick any date to debug/unit test

    currsecofmooncycle = (currtime.unix - REF_NEWMOON) % LUNATION

    moon_phase = (currsecofmooncycle / LUNATION) * 2 * math.pi
    #moon_phase = (currtime.unix % 60) / 60 * 2*math.pi    # debug/unit test with fake 60 second lunar cycle

    #print(moon_phase)

    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")

    disp_time = time.now().in_location(tz).format(time_format[0]) if time_format else None
    disp_time_blink = time.now().in_location(tz).format(time_format[1]) if time_format else None

    return render.Root(
        delay = 1000,
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "left",
            children = [
                render.Stack([
                    render.Image(src = MOON_IMG),
                    # Stack below is a dynamically generated shadow mask built one pixel at a time
                    render.Stack([
                        # Each child of Stack is a row of pixels
                        render.Row([
                            # Each Row is a 1 pixel tall stack at height "y"
                            render.Padding(
                                # This element represents the mask pixel at (x, y)
                                pad = (0, y, 0, 0),
                                child = render.Image(
                                    src = getmaskpixel(x, y, moon_phase, latitude),
                                ),
                            )
                            for x in range(MOONIMG_WIDTH)
                        ])
                        for y in range(MOONIMG_HEIGHT)
                    ]),
                ]),
                # optional clock below
                render.Animation(
                    children = [
                        render.Padding(
                            pad = (0, CLOCK_PADDING, 0, 0),
                            child = render.Stack(
                                children = [
                                    render.Padding(
                                        # render extra pixels to the right to push time closer to moon
                                        pad = (3, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#000",
                                        ),
                                    ),
                                    render.Padding(
                                        # faint shadow right
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        # faint shadow down
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        # medium shadow diagonal down-right
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#444",
                                        ),
                                    ),
                                    render.Text(
                                        # bright time
                                        content = disp_time,
                                        font = FONT,
                                        color = "#AAA",
                                    ),
                                ],
                            ),
                        ),
                        render.Padding(
                            pad = (0, CLOCK_PADDING, 0, 0),
                            child = render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (3, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#000",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#444",
                                        ),
                                    ),
                                    render.Text(
                                        content = disp_time_blink,
                                        font = FONT,
                                        color = "#AAA",
                                    ),
                                ],
                            ),
                        ) if blink_time else None,
                    ],
                ) if time_format else None,
            ],
        ),
    )

#######
#
# return specific mask 1x1 pixel image from array sorted by alpha percentage
#
#######
def getmaskpixel(x, y, phase, latitude):
    return mask_images[select_mask_image(percent_illuminated(x, y, phase, latitude))]

#######
#
# return percent illumination of moon image based on pixel coordinates, moon phase, and user's (earth) latitude
#
#######
def percent_illuminated(x, y, phase, latitude):
    # Offset x and y so that (0, 0) is center of moon
    x -= X_C
    y -= Y_C

    # Rotate x and y by latitude so that crescents look as at user's latitude
    # (crescents look vertical at poles, horizontal at equator)
    rot = math.pi / 2 - math.radians(latitude)
    xr = x * math.cos(rot) - y * math.sin(rot)
    yr = x * math.sin(rot) + y * math.cos(rot)

    lambda_0 = phase  # lambda_0 represents lunar longitude offset in orthographic projection onto plane, in this case treating lunar longitude as moon phase, where 0 is new, pi is full

    # following equations are simplified from the inverse functions in https://en.wikipedia.org/wiki/Orthographic_map_projection, specifically phi_0 = 0 (phi_0 representing latitude tilt of moon, so phi_0 = 0 represents equator-centric view, i.e., just the crescent/gibbous view of the longitude lines)
    rho = math.sqrt(xr * xr + yr * yr)
    c = math.asin(rho / R)
    moon_lng = lambda_0 + math.atan2(xr * math.sin(c), rho * math.cos(c))

    illum = 0.0  # default

    # logic: if moon_lng < 90 or > 270, it's fully in shadow (meaning start fade at 90/270, don't center fade around those angles)
    # reason: don't want time around new moon to have extended appearance of new moon, new moon should be as close to instantaneous as possible
    # reason #2: totally ok and desirable to have day or two around full moon to change fading around edges of moon and still look basically full - moon does this in real life

    # logic: within FADE_LNG, take 4th root of delta to determine brightness
    # reason: make line between light/shadow crisp, sharp at the dark side, soften the curve towards maximum brightness, no other reason than it looked good to me and made time near full moon look good shading-wise

    if (moon_lng < math.pi / 2 or moon_lng > 3 * math.pi / 2):
        illum = SHADOW_LEVEL
    elif (moon_lng - math.pi / 2 > 0 and moon_lng - math.pi / 2 <= FADE_LNG):
        illum = SHADOW_LEVEL + math.sqrt(math.sqrt(1 - SHADOW_LEVEL) * ((moon_lng - math.pi / 2) / FADE_LNG))
    elif (3 * math.pi / 2 - moon_lng > 0 and 3 * math.pi / 2 - moon_lng <= FADE_LNG):
        illum = SHADOW_LEVEL + math.sqrt(math.sqrt(1 - SHADOW_LEVEL) * ((3 * math.pi / 2 - moon_lng) / FADE_LNG))
    elif (moon_lng > math.pi / 2 + FADE_LNG or moon_lng < 3 * math.pi / 2 - FADE_LNG):
        illum = 1.0

    return illum

#######
#
# convert illumination percentage (0 <= illumination_percent <= 1) to index into mask_images array
#
#######
def select_mask_image(illumination_percent):
    val = min(15, math.floor(math.round(illumination_percent * 16)))
    return val

#######
#
# get_schema
#
#######
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the display of date/time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "None",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in TIME_FORMATS
                ],
            ),
            schema.Toggle(
                id = "blink_time",
                name = "Blinking Time Separator",
                desc = "Whether to blink the colon between hours and minutes.",
                icon = "asterisk",
                default = False,
            ),
        ],
    )

#######
#
# image data and array of images follows
#
#######

# Moon image is taken from NASA video at https://svs.gsfc.nasa.gov/4310, retouched by Chris Wyman
MOON_IMG = base64.decode("""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""")

BLACK_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBg+AcAAQMA/60lLy8AAAAASUVORK5CYII=""")
DARK01_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgeAEAAO0A6Rx+CV4AAAAASUVORK5CYII=""")
DARK02_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBguA0AAOAA3PnKAd4AAAAASUVORK5CYII=""")
DARK03_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgOAcAANMAz3LU0l0AAAAASUVORK5CYII=""")
DARK04_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBg2A8AAMQAwBTxXkMAAAAASUVORK5CYII=""")
DARK05_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBg2AQAALcAs+GNWA8AAAAASUVORK5CYII=""")
DARK06_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgWAoAAKoApiqyB0UAAAAASUVORK5CYII=""")
DARK07_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgmAEAAJ0AmRsqtiUAAAAASUVORK5CYII=""")
DARK08_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBg6AQAAI4Aij1Rq0oAAAAASUVORK5CYII=""")
DARK09_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgqAEAAIEAfQESbwIAAAAASUVORK5CYII=""")
DARK10_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgyAcAAHQAcJFDDXwAAAAASUVORK5CYII=""")
DARK11_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgSAIAAGcAY9NGKsoAAAAASUVORK5CYII=""")
DARK12_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgCAYAAFgAVJtWGgcAAAAASUVORK5CYII=""")
DARK13_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgMAUAADoANm6hnKYAAAAASUVORK5CYII=""")
DARK14_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdjYGBgEAcAABwAGAzCM6wAAAAASUVORK5CYII=""")
CLEAR_PIXEL = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAAtJREFUGFdjYAACAAAFAAGq1chRAAAAAElFTkSuQmCC""")

#######
#
# array of 1x1 pixel images from opaque black to transparent black in equal transparency jumps
#
#######
mask_images = [
    BLACK_PIXEL,
    DARK01_PIXEL,
    DARK02_PIXEL,
    DARK03_PIXEL,
    DARK04_PIXEL,
    DARK05_PIXEL,
    DARK06_PIXEL,
    DARK07_PIXEL,
    DARK08_PIXEL,
    DARK09_PIXEL,
    DARK10_PIXEL,
    DARK11_PIXEL,
    DARK12_PIXEL,
    DARK13_PIXEL,
    DARK14_PIXEL,
    CLEAR_PIXEL,
]

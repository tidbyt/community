"""
Applet: Day Night Map
Summary: Day & Night World Map
Description: A map of the Earth showing the day and the night. The map is based on Equirectangular (0°) by Tobias Jung (CC BY-SA 4.0).
Author: Henry So, Jr.
"""

# Day & Night World Map
# Version 1.1.0
#
# Copyright (c) 2022 Henry So, Jr.
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

# See comments in the code for further attribution

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = 64
HALF_W = WIDTH // 2
HEIGHT = 32
HALF_H = HEIGHT // 2
HDIV = 360 / WIDTH
HALF_HDIV = HDIV / 2
COEF = 360 / 365.24
DATE_H = 7

CHAR_W = 9
SEP_W = 3

def main(config):
    location = config.get("location")

    #print(location)
    location = json.decode(location) if location else {}
    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")
    show_date = config.bool("show_date")

    tz = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )

    tm = config.get("force_time")
    if tm:
        tm = time.parse_time(tm).in_location(tz)
    else:
        tm = time.now().in_location(tz)

    if config.bool("center_location"):
        map_offset = -round(float(location.get("lng", "0")) * HALF_W / 180)
    else:
        map_offset = 0

    #print(map_offset)

    formatted_date = tm.format("Mon 2 Jan 2006")
    date_shadow = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Text(
                content = formatted_date,
                font = "tom-thumb",
                color = "#000",
            ),
        ],
    )

    night_above, sunrise = sunrise_plot(tm)
    return render.Root(
        delay = 1000,
        child = render.Stack([
            render.Padding(
                pad = (map_offset, 0, 0, 0),
                child = render.Image(MAP),
            ),
            render.Padding(
                pad = (
                    map_offset + (-WIDTH if map_offset > 0 else WIDTH),
                    0,
                    0,
                    0,
                ),
                child = render.Image(MAP),
            ) if map_offset != 0 else None,
            render.Row([
                render.Padding(
                    pad = (0, y if night_above else 0, 0, 0),
                    child = render.Image(
                        src = PIXEL,
                        width = 1,
                        height = HEIGHT - y if night_above else y,
                    ),
                )
                for i in range(WIDTH)
                for y in [sunrise[(i - map_offset) % WIDTH]]
            ]),
            render.Column(
                main_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Animation([
                                render_time(tm, time_format[0]),
                                render_time(tm, time_format[1]) if blink_time else None,
                            ]),
                            render.Padding(
                                pad = (1, 9, 0, 0),
                                child = render.Image(AM_PM[tm.hour < 12]),
                            ) if time_format[2] else None,
                        ],
                    ),
                    render.Box(
                        width = WIDTH,
                        height = 3,
                    ) if show_date else None,
                ],
            ) if time_format else None,
            render.Padding(
                pad = (0, HEIGHT - DATE_H, 0, 0),
                child = render.Stack([
                    render.Padding(
                        pad = (-1, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (2, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 0, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 1, 0, 0),
                        child = render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = formatted_date,
                                    font = "tom-thumb",
                                    color = "#ff0",
                                ),
                            ],
                        ),
                    ),
                ]),
            ) if show_date else None,
        ]),
    )

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
            schema.Toggle(
                id = "center_location",
                name = "Center On Location",
                desc = "Whether to center the map on the location.",
                icon = "compress",
                default = False,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "omit",
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
            schema.Toggle(
                id = "show_date",
                name = "Date Overlay",
                desc = "Whether the date overlay should be shown.",
                icon = "calendarCheck",
                default = False,
            ),
        ],
    )

def sunrise_plot(tm):
    tm = tm.in_location("UTC")
    anchor = time.time(
        year = tm.year,
        month = 1,
        day = 1,
        location = "UTC",
    )
    days = int((tm - anchor).hours // 24)

    tan_dec = TAN_DEC[days]
    tau = 15 * (tm.hour + tm.minute / 60) - 180

    # Use the sunrise equation to compute the latitude
    # See https://en.wikipedia.org/wiki/Position_of_the_Sun
    def lat(lon):
        return atan(-cos(lon + tau) / tan_dec)

    return (
        tan_dec > 0,
        [
            HALF_H - round(lat(lon) * HALF_H / 90)
            #lat(lon)
            for lon in LONGITUDES
        ],
    )

def sin(degrees):
    return math.sin(math.radians(degrees))

def cos(degrees):
    return math.cos(math.radians(degrees))

def tan(degrees):
    return math.tan(math.radians(degrees))

def asin(x):
    return math.degrees(math.asin(x))

def atan(x):
    return math.degrees(math.atan(x))

def round(x):
    return int(math.round(x))

def render_time(tm, format):
    formatted_time = tm.format(format)
    offset = 5 - len(formatted_time)
    offset_pad = pad_of(offset)
    return render.Stack([
        render.Padding(
            pad = (pad_of(i + offset) - offset_pad, 0, 0, 0),
            child = render.Image(CHARS[c]),
        )
        for i, c in enumerate(formatted_time.elems())
        if c != " "
    ])

def pad_of(i):
    if i > 2:
        return (i - 1) * CHAR_W + SEP_W
    elif i > 0:
        return i * CHAR_W
    else:
        return 0

# Pre-compute the tangent to the declination of the sun
# See https://en.wikipedia.org/wiki/Position_of_the_Sun
TAN_DEC = [
    tan(asin(sin(-23.44) * cos(
        COEF * (d + 10) +
        (360 / math.pi * 0.0167 * sin(COEF * (d - 2))),
    )))
    for d in range(366)
]

LONGITUDES = [
    (x - HALF_W) * HDIV + HALF_HDIV
    for x in range(WIDTH)
]

DEFAULT_TIMEZONE = "America/New_York"

TIME_FORMATS = {
    "omit": None,
    "12-hour": ("3:04", "3 04", True),
    "24-hour": ("15:04", "15 04", False),
}

CHARS = {
    "0": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAACBJREFUCNdjYAxhYGBbycAgFeXAkMk2gSgMUgvSA9QLAKtLDWcg9zY2AAAA
AElFTkSuQmCC
"""),
    "1": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAAClJREFUCNdjYAhgYGBcwsDABsRSQJwJxKJLIGK4sOhSB4asVRMYREMdAFsh
C+/brVnSAAAAAElFTkSuQmCC
"""),
    "2": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADVJREFUCNdjYAxhYGBbycAgFeXAkMk2gUEEiBlgWMqBgSGTgYFxCQqXITPU
gSFr1QQG0VAHADcPCpvNILtaAAAAAElFTkSuQmCC
"""),
    "3": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADdJREFUCNdjEA11YMhaNYFBNGwCA4OUAwNDJgMD4xIGBraVQDoKyGebAMci
QJwJxFJAcbB8CAMAe1kLH6u//1EAAAAASUVORK5CYII=
"""),
    "4": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADBJREFUCNdjYBBhYGDIhGDGJRDMNhWIZzkwSEVBcKYUEAPprFUTGESBNIMU
FLMyAAAufAnmFFlNYwAAAABJRU5ErkJggg==
"""),
    "5": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADZJREFUCNdjEA11YMhaNYEhE0hnMjBAcAgDQ9ZKBgbRKAcGBrYJcCwCxJlA
LAUUZwPKM4YwAACW7wvBgXaX4AAAAABJRU5ErkJggg==
"""),
    "6": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADNJREFUCNdjYAhhYGBcycDANoWBQcqBgSGTAYiBYllAscwoB4ZMtgkYWAoo
zgaUZwxhAABkVQvi4c4RfwAAAABJRU5ErkJggg==
"""),
    "7": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAACpJREFUCNdjEA11YMhaNYFBNGwCAwMbEEs5QHAmAxgzLoFgtgmYmNGBAQBj
PAnf/Sy1fwAAAABJRU5ErkJggg==
"""),
    "8": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAACFJREFUCNdjYAxhYGBbycAgFeXAkMk2AY5BfGziyHJAvQCM7gyBEuAcCAAA
AABJRU5ErkJggg==
"""),
    "9": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQAgMAAABSEQbTAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAADVJREFUCNdjYAxhYGBbycAgFeXAkMk2AQNLhU1gYFs1gYERSDMA+QxSDgyM
mUDmEgYGxgAGAJsMDDArz8tGAAAAAElFTkSuQmCC
"""),
    ":": base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAQAgMAAABM2DZgAAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjYIACEYZMIBRBYQEBAB1sAfXTJxecAAAAAElFTkSuQmCC
"""),
}

AM_PM = {
    True: base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAHAgMAAABB3ES3AAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAACNJREFUCNdjYGVhYZCKlGRInZXJkDpzJkPWzEggLckg4MICAFINBmTAfA6Y
AAAAAElFTkSuQmCC
"""),
    False: base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAHAgMAAABB3ES3AAAACVBMVEUAAAAAAAD//wCu3yBfAAAA
AXRSTlMAQObYZgAAACNJREFUCNdjEGVhYciKlGRInZXJkDpzJpAdyZAqKckgwMICAFTtBcSrM+2h
AAAAAElFTkSuQmCC
"""),
}

PIXEL = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQI12NgaAAAAIMAgR+3QgAA
AAAASUVORK5CYII=
""")

# The following Base64-encoded image is a scaled-down version of
# Equirectangular (0°) by Tobias Jung
# found at https://map-projections.net/single-view/rectang-0:flat-stf
# This image released under the CC BY-SA 4.0 International license
MAP = base64.decode("""
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
b24ANQHYtpcAAAA4dEVYdGljYzpjb3B5cmlnaHQAQ29weXJpZ2h0IChjKSAxOTk4IEhld2xldHQt
UGFja2FyZCBDb21wYW55+Vd5NwAAACF0RVh0aWNjOmRlc2NyaXB0aW9uAHNSR0IgSUVDNjE5NjYt
Mi4xV63aRwAAACZ0RVh0aWNjOm1hbnVmYWN0dXJlcgBJRUMgaHR0cDovL3d3dy5pZWMuY2gcfwBM
AAAAN3RFWHRpY2M6bW9kZWwASUVDIDYxOTY2LTIuMSBEZWZhdWx0IFJHQiBjb2xvdXIgc3BhY2Ug
LSBzUkdCRFNIqQAAABJ0RVh0dGlmZjpDb21wcmVzc2lvbgA13jRpagAAACN0RVh0dGlmZjpYUmVz
b2x1dGlvbgA0NzU1NzQ2MjQvMTY3NzcyMTa325+eAAAAI3RFWHR0aWZmOllSZXNvbHV0aW9uADQ3
NTU3NDYyNC8xNjc3NzIxNou7fJYAAAAodEVYdHhtcDpDcmVhdGVEYXRlADIwMTctMTAtMDJUMTg6
NTc6NDMrMDE6MDBtx0PdAAAAHnRFWHR4bXA6Q3JlYXRvclRvb2wAUGhvdG9MaW5lMjAuMDIDkUSJ
AAAAKnRFWHR4bXA6TWV0YWRhdGFEYXRlADIwMTctMTAtMDJUMTg6NTc6NDMrMDE6MDDlnSxaAAAA
KHRFWHR4bXA6TW9kaWZ5RGF0ZQAyMDE3LTEwLTAyVDE4OjU3OjQzKzAxOjAw2Tl/5AAAAABJRU5E
rkJggg==
""")

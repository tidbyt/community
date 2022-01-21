"""
Applet: Day Night Map
Summary: Day & Night World Map
Description: A map of the Earth showing the day and the night. The map is based on Equirectangular (0°) by Tobias Jung (CC BY-SA 4.0).
Author: Henry So, Jr.
"""

# Day & Night World Map
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

load("time.star", "time")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

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
            render.Image(MAP),
            render.Row([
                render.Padding(
                    pad = (0, y if night_above else 0, 0, 0),
                    child = render.Image(
                        src = PIXEL,
                        width = 1,
                        height = HEIGHT - y if night_above else y,
                    ),
                )
                for y in sunrise
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
                icon = "place",
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
                icon = "calendarAll",
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
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAMAAACVQ462AAADAFBMVEUVbb4Wcbsua7ETc7crbasg
ca8ncbYkc7E7dUomdLMvc6wndbQycrIjd686c48+cpQpd6kpdrVAdH4qd7Y8c60ueaUzd7A8eXky
eqBAd6pdeENucV1BeqJceFpPfmA9gJtChk1cflVreldBhId4eUE/iWdLh1VhfoGCeVA/iJVWg4JN
haFUg6x4fH9MhbpgiFlhiGBjh2VciHZohmhuhlRbimxXjGZUj1FbjWJsg5x8gXpjhqNTjolXkVlh
j1dojlmDg3pYi7tfjY+BiGZyjWNljZNfk21fk3NnkmJukGRyj25ok2l6iaFkk31rknVll1N9i5Fk
lmtvlF1xlVNcm1yJiZJvlHF7k2Bmm2F0lIGUi39smmF4kK5wk69rmnVulah6lJGZjXaRkXGGmU6Q
koObkWeCmnB0nYB+mn+ekXRsoXB1n3CMmId1omeInV59n3GrkXeEm6KIn2h/o2eAo22ApGKDoX+v
lXt4ocetmX6rnG2gn3iNoLiWoJh+qn+en5atnXmqnYaRoq6dopKOqX1/sGS5nXGAsG6Ip7yVqnCm
oaCHr3ibqXiXqYmnpnKropWUqZedp4+gqXKKsHOeq2earG2Sr22Yq5Gqp5KWsWmerIfHoXiupa6n
qKuVrM3NoofAqIG4qoynrLfBp5OzrnvEqXmzr4KyrauqsaCps5vJq4myspDCr3qhu2ymuH+ysae1
tHmpuHnDrpK+sn+xuHynvHXTsIyzt6/Ns4Kut8W1trykwX62vHjKtJS7trW4uKm7uaLLt3+9uo/V
spa+vXzJt6aww3a5wYWxv9i9w3/buYnTu5PEwKvNwY7cvJa8w8vDyH3UwpjOxobFxMLaxIffwaTb
w5zRyoLRzHfIyNLWyZPnxpm8zebCzuLYzLnly6zozKTN0ejh0pPI1enS24HM1uTI1/Hk1K/m1Knk
16HS2eHS3OrW2/Hm3a/R3vPX3ubW4e/Q5Pfc4+zq5cDc5vXf5u/m5vDj6/Pu7fjv8NLo7/jz8PXs
9Pzv9Pf5+/j4/P/YfGYmAAAEiElEQVRIx6VVDVhTZRQejntvXLba12IykxIry/6gDJbyV0Q0IimK
BAPpz4RAogb9aCIkpFFSgG2oqREOI6MB8ROhNFQKJPoRU8pYsNYovTDGZZdrY6TfHbvjguN56uk8
z/bcc773e88573e+e3k4gIYAjkEHczxiDt8Owp0RLpQ3MwL4e39oeShpU1CL1bhvk/Q1LpEEuDIO
wZo9bvwKnC9BxZJOM2Ex9nVK7XEUcRDQDNOamj0tTMFvSR0EYrjytZDJjQd9cRK0fKWtWA6wR84Z
+vZdIXH0JmWSCxG8u61Nq/1Eq62qym3T1tR0M03whOiJnNWpa/PvSQ0veg8CtvC7k3DMk+4TAbA3
iNmeHxkcLk1+IHl9QVnZ6qL1ZSVlqcll+TtzqlKKq9q28IAAKdmJSV6KuebOV0Qx98OUn+ZqYd12
yfjAG9yI47HRabGRsavSNqdvzgwMjA4oSUlJTkWEtxQJxIwGbnbslb53yNfJBZEr3a6LuXkhq4sy
HA1OCEiUZ6veVypq22tLCzYHREZkrkr3F3sBBHcXckVcvKxefThaEOjv57XQmw2+kBWWmSVX9u4+
Ul1dDX8Hntit3l4fkZ4diUwJxCFQ9mxV/7wLuC/DUWdw5brrr12wOF4AFM/mnDh49PUVz7fuf7W1
vjQKA/MuOcaNGz5Xt4dF+/mz4yKAUng8d5MA4Lzy40+/k9e09rbfKj6ueaNB4f4y8GHnwF6H2D5p
z3x3sDAs9G4xZ0zu+/D0wK/IcEHrQFv//oG8xseTTq7w84l607Esnj2JGxtmjvJY//fHjg2PDfwN
TjUhtz95pqHwwVAff18/dNYkznfqeFSMAr7cSdB1duz0n2Ndf/W/uGH4FGxIqQBC34gMpjkwo4Xp
SyOMAjjmJOjp/enbs2d6mrp+FH6EwNPuAJgg9GEUpEMAhru8TAAsCI3/jL2dnjtUhzSFjY11itrf
7ddCBLD5UxPm4jKxVhySti1h2p0XIpNppGoh6ye6AfkMDWYzCJcsWhQiSwgWsYG0kLjCBg5giUfc
UrBUJpxq1EUFGTJZXGKGppT1d6iUVx3iAgSXBabg3lACL4bAw5mJpbo199FtWZo6nI13KFXbdwER
F4RmdmA3zKkBQK5OVNVlO1117+EGkedjnKNDio8099bCDKhrguXxKrnXtCupbL8LcI8elG+trPyg
WTFnBW9rjmu4fvkBwUyA9N3qyurmDnwugpb2P2ZFXIDAN4n2M+NxxGVf33lPYbN2I2AOi3BVAZp3
SUZsLgKAuWrhcvsG5F8RuNQA/IcKXBOI0f9FgOsoZ5AYNUyQplHKNjFpnSTMk1YrbbUNkZMXzPQ/
1smJeyHB1BfxwsgvNtM523nSTI0bxk2jdoZB2kaQIxQ5QtOGEVqvh987ymzUE9ZJmjJTFGk0MpM4
ylhnZ59OpzMaCR1BwAcYGTToDIOmIZo26WFAp4emMxh0RoIYIYwGg9lCmE3ElxDIs1jPW4fGLRRF
2yw2m81qIymKslhImqZo2kLZ4B9BmAmSgHtJkiIZgxx6M1yHSPoi8UIXcuqayvoAAAAASUVORK5C
YII=
""")

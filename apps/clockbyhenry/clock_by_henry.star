"""
Applet: Clock By Henry
Summary: Large Digit Time With Date
Description: Show the time with numbers you can see from across the room! Bonus date included.
Author: Henry So, Jr.
"""

# Big-Number Clock With Date
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

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

# parameters:
# location - the location for rendering
# use_12h - if 12-hour time should be used
# blink_time - if the time separator should blink
# day_start - when the day starts
# night_start - when the night starts
# season_theme - the base color set to use (index of SEASON_THEMES)
# d - the color for the time during the day
# n - the color for the time during the night
# s0d - the color for the date during season 0 in the day
# s1d - the color for the date during season 1 in the day
# s2d - the color for the date during season 2 in the day
# s3d - the color for the date during season 3 in the day
# s0n - the color for the date during season 0 in the night
# s1n - the color for the date during season 1 in the night
# s2n - the color for the date during season 2 in the night
# s3n - the color for the date during season 3 in the night
def main(config):
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}
    time_format = H12 if config.bool(P_USE_12H) else H24
    blink_time = config.bool(P_BLINK_TIME)

    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    now = config.get("time")
    now = (time.parse_time(now) if now else time.now()).in_location(timezone)
    now_date = now.format("Mon 2 Jan 2006")

    # this is a rough approximation
    # actual seasons vary by location and astronomy
    # we just treat this as close enough
    season = now.format("01-02")
    if season >= "03-20" and season < "06-21":
        season = 1
    elif season >= "06-21" and season < "09-23":
        season = 2
    elif season >= "09-23" and season < "12-21":
        season = 3
    else:
        season = 0

    coords = (
        (float(location["lat"]), float(location["lng"])) if location.get("lat") and location.get("lng") else None
    )

    day_start = config.bool(P_DAY_START) or DEFAULT_DAY_START
    if day_start == "sunrise" and coords:
        day_start = sunrise.sunrise(coords[0], coords[1], now)
        if day_start == None:
            if coords[0] > 0:
                day_start = "00:00" if season == 1 or season == 2 else "  :  "
            else:
                day_start = "00:00" if season == 3 or season == 0 else "  :  "
        else:
            day_start = day_start.in_location(timezone).format("15:04")
    elif not re.match(r"^\d\d:\d\d$", day_start):
        day_start = DEFAULT_DAY_START

    night_start = config.bool(P_NIGHT_START) or DEFAULT_NIGHT_START
    if night_start == "sunset" and coords:
        night_start = sunrise.sunset(coords[0], coords[1], now)
        if night_start == None:
            if coords[0] > 0:
                night_start = "24:00" if season == 1 or season == 2 else "00:00"
            else:
                night_start = "24:00" if season == 3 or season == 0 else "00:00"
        else:
            night_start = night_start.in_location(timezone).format("15:04")
    elif not re.match(r"^\d\d:\d\d$", night_start):
        night_start = DEFAULT_NIGHT_START

    phase = now.format("15:04")
    if phase >= day_start and phase < night_start:
        phase = "d"
    else:
        phase = "n"

    # get the base color set
    season_theme = SEASON_THEMES.get(
        config.get(P_SEASON_THEME),
        SEASON_THEMES[DEFAULT_SEASON_THEME],
    )

    time_color = color_of(config.get(phase), DEFAULT_TIME_COLOR[phase])
    date_color = color_of(
        config.get("s%d%s" % (season, phase)),
        season_theme[phase][season],
    )

    # generate the widget for the app
    return render.Root(
        delay = 1000,
        max_age = 120,
        child = render.Column(
            main_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = 0,
                            color = time_color,
                            child = render.Animation([
                                render.Row(
                                    children = [
                                        render.Image(DIGITS[char])
                                        for char in now.format(time_format[0]).elems()
                                    ],
                                ),
                                render.Row(
                                    children = [
                                        render.Image(DIGITS[char])
                                        for char in now.format(time_format[1]).elems()
                                    ],
                                ) if blink_time else None,
                            ]),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = 0,
                            child = render.Text(
                                content = now_date,
                                font = "tom-thumb",
                                color = date_color,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location for the display of date and time.",
                icon = "locationDot",
            ),
            #schema.Text(
            #    id = "d",
            #    name = "Time Color (Day)",
            #    desc = "The color to use for the time during the day.",
            #    icon = "brush",
            #),
            #schema.Text(
            #    id = "n",
            #    name = "Time Color (Night)",
            #    desc = "The color to use for the time during the night.",
            #    icon = "brush",
            #),
            schema.Toggle(
                id = P_USE_12H,
                name = "Use 12-hour Format",
                desc = "Whether to use 12-hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = P_BLINK_TIME,
                name = "Blinking Time Separator",
                desc = "Whether to blink the colon between hours and minutes.",
                icon = "asterisk",
                default = False,
            ),
            schema.Dropdown(
                id = P_DAY_START,
                name = "Daytime Start",
                desc = "When daytime starts.",
                icon = "sun",
                options = [
                    schema.Option(
                        display = v,
                        value = v,
                    )
                    for v in DAY_STARTS
                ],
                default = "06:00",
            ),
            schema.Dropdown(
                id = P_NIGHT_START,
                name = "Nighttime Start",
                desc = "When nighttime starts.",
                icon = "moon",
                options = [
                    schema.Option(
                        display = v,
                        value = v,
                    )
                    for v in NIGHT_STARTS
                ],
                default = "18:00",
            ),
            schema.Dropdown(
                id = P_SEASON_THEME,
                name = "Base Date Color Theme",
                desc = "The color theme for the date",
                icon = "calendar",
                options = [
                    schema.Option(
                        display = SEASON_THEMES[k]["description"],
                        value = k,
                    )
                    for k in SEASON_THEMES
                ],
                default = DEFAULT_SEASON_THEME,
            ),
            #] + [
            #    schema.Text(
            #        id = "s%d%s" % (s, p),
            #        name = "Date Color (%s, %s)" % (SEASON_DESC[s], PHASE_DESC[p]),
            #        desc = "The color to use for the date during %s in the %s" % (
            #            SEASON_DESC[s],
            #            PHASE_DESC[p],
            #        ),
            #        icon = "brush",
            #    )
            #    for s in range(4)
            #    for p in ["d", "n"]
        ],
    )

# Prefixes a color with a "#" if necessary
# color - the RGB color string
def color_of(color, default_color):
    if color:
        #print("parsing color: " + color)
        color = color.strip()
        if re.match(r"^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$", color):
            #print("hashless: " + color)
            return "#" + color
        elif re.match(r"^#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$", color):
            #print("hashed: " + color)
            return color

    # if all else fails...
    #print("default color: " + default_color);
    return default_color

P_LOCATION = "location"
P_USE_12H = "use_12h"
P_BLINK_TIME = "blink_time"
P_DAY_START = "day_start"
P_NIGHT_START = "night_start"
P_SEASON_THEME = "season_theme"

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_DAY_START = "06:00"
DEFAULT_NIGHT_START = "18:00"
DEFAULT_SEASON_THEME = "nh"

DEFAULT_TIME_COLOR = {
    "d": "#ffd",
    "n": "#900",
}

#SEASON_DESC = [
#    "Dec–Mar",
#    "Mar–Jun",
#    "Jun–Sep",
#    "Sep–Dec",
#]

#PHASE_DESC = {
#    "d": "Day",
#    "n": "Night",
#}

DAY_STARTS = [
    h + ":" + m
    for h in ["04", "05", "06", "07", "08"]
    for m in ["00", "30"]
] + [
    "sunrise",
]

NIGHT_STARTS = [
    h + ":" + m
    for h in ["16", "17", "18", "19", "20", "21"]
    for m in ["00", "30"]
] + [
    "sunset",
]

H12 = ("3:04", "3_04")
H24 = ("15:04", "15_04")

SEASON_WINTER_D = "#8cf"
SEASON_SPRING_D = "#2f2"
SEASON_SUMMER_D = "#ff0"
SEASON_AUTUMN_D = "#d60"
SEASON_WINTER_N = "#468"
SEASON_SPRING_N = "#080"
SEASON_SUMMER_N = "#880"
SEASON_AUTUMN_N = "#840"

# season 0 is Dec-Mar
# season 1 is Mar-Jun
# Season 2 is Jun-Sep
# Season 3 is Sep-Dec
SEASON_THEMES = {
    "nh": {
        "description": "4 Season, N. Hemi.",
        "d": [
            SEASON_WINTER_D,
            SEASON_SPRING_D,
            SEASON_SUMMER_D,
            SEASON_AUTUMN_D,
        ],
        "n": [
            SEASON_WINTER_N,
            SEASON_SPRING_N,
            SEASON_SUMMER_N,
            SEASON_AUTUMN_N,
        ],
    },
    "sh": {
        "description": "4 Season, S. Hemi.",
        "d": [
            SEASON_SUMMER_D,
            SEASON_AUTUMN_D,
            SEASON_WINTER_D,
            SEASON_SPRING_D,
        ],
        "n": [
            SEASON_SUMMER_N,
            SEASON_AUTUMN_N,
            SEASON_WINTER_N,
            SEASON_SPRING_N,
        ],
    },
    "wd-nh": {
        "description": "Wet-Dry, N. Hemi.",
        "d": [
            SEASON_WINTER_D,
            SEASON_SUMMER_D,
            SEASON_SUMMER_D,
            SEASON_WINTER_D,
        ],
        "n": [
            SEASON_WINTER_N,
            SEASON_SUMMER_N,
            SEASON_SUMMER_N,
            SEASON_WINTER_N,
        ],
    },
    "wd-sh": {
        "description": "Wet-Dry, S. Hemi.",
        "d": [
            SEASON_SUMMER_D,
            SEASON_WINTER_D,
            SEASON_WINTER_D,
            SEASON_SUMMER_D,
        ],
        "n": [
            SEASON_SUMMER_N,
            SEASON_WINTER_N,
            SEASON_WINTER_N,
            SEASON_SUMMER_N,
        ],
    },
}

DIGITS = {
    "0": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADZJREFUCNdjCA0NDWAIdRANYAhhYAxgCGAAogBWECHqEMDgIOogQC4BNgBiFMhQsPFgi0BWAgA+EBINLZKayAAAAABJRU5ErkJggg=="),
    "1": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAClJREFUCNdjCA0NDWAIDWEEEgEgwgFEMACJADDBAiJEgEQIWAl1CKCVACzyFrviSepFAAAAAElFTkSuQmCC"),
    "2": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEVJREFUCNdtzbENACEMA0CnSP/Fsw8jGAnvv8o7CKQvaE6OCweSCKERRBId4fT6GDK6MePAomfR9orcYobhIlWjeH7Uyw/6sBR9nwYNSwAAAABJRU5ErkJggg=="),
    "3": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAD9JREFUCNdlzKEBgDAMBdGrwGO6T9kggtt/FfgQBeZE8hLUQraioHNOdnR9cjsJHn1h8Dv74c6R7eLJyPsZbF3TmRSx6tdBGQAAAABJRU5ErkJggg=="),
    "4": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADNJREFUCNdjCA0NDWAIDWGAEQFwwgFOMIAIRhgRwgojAkRhhAOYYAACBBEaCtKBlQgNAAChxxM5EE3fuwAAAABJRU5ErkJggg=="),
    "5": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADdJREFUCNdjCA0NDWAIYGBAIVhDcRAMrCCCEaouNJRBAEg4YCdcQbKOoUB1DgxgAqxNFKQtNAAAyywUSY+7irwAAAAASUVORK5CYII="),
    "6": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEFJREFUCNdjCA0NDWAAIiDhACIYgEQII0iAFU6IAgkHMCHCCiRASiAEK4MAUMIBOxEAJlhB5oENZWAE2QE0AGQlAK5JEvS3wopyAAAAAElFTkSuQmCC"),
    "7": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADVJREFUCNdjCA0NDWBwYGAQQCJCQx1ABEMAMhHCiEIEsKIQDmBCFEYwgIlQKBECJhhhBMhKAMgsFcwfcB7aAAAAAElFTkSuQmCC"),
    "8": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADdJREFUCNdjCA0NDWAIZWANYAhhYAxgCGAAIgdWBgEGB1EHFAIkBpYFq0PTEcAK0oamA5c2kJUAs/wP2GwBpREAAAAASUVORK5CYII="),
    "9": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEJJREFUCNdtzSEOADAIA8Ai8DP8hycg1v9/ZYVlbuZISNOCZIGIwoYVanDdjBzWH8dS6EHTj7yoj3jsKfUmml7T5AEj0RKOJbpXOwAAAABJRU5ErkJggg=="),
    ":": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYAgMAAABLvA8OAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAABpJREFUCNdjCA1hQEMBIgwOLFAEZGMqwKYGANm5DGdVvFjRAAAAAElFTkSuQmCC"),
    "_": base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYAQMAAAAMHHXeAAAABlBMVEUAAAD///+l2Z/dAAAADElEQVQI12NgIA0AAAAwAAHHqoWOAAAAAElFTkSuQmCC"),
}

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

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("re.star", "re")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

# parameters:
# location - the location for rendering
# use_12h - if 12-hour time should be used
# blink_time - if the time separator should blink
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
    time_format = H12 if config.get(P_USE_12H) else H24
    blink_time = config.get(P_BLINK_TIME)

    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    now = time.now().in_location(timezone)
    now_date = now.format("Mon 2 Jan 2006")

    # this is a rough approximation
    # actual seasons vary by location and astronomy
    # we just treat this as close enough
    season = int(now.format("1-02").replace("-", ""))
    if season >= 320 and season < 621:
        season = 1
    elif season >= 621 and season < 923:
        season = 2
    elif season >= 923 and season < 1221:
        season = 3
    else:
        season = 0

    phase = int(now.format("15"))
    if phase >= 6 and phase < 18:
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
                icon = "place",
            ),
            schema.Text(
                id = "d",
                name = "Time Color (Day)",
                desc = "The color to use for the time during the day.",
                icon = "brush",
            ),
            schema.Text(
                id = "n",
                name = "Time Color (Night)",
                desc = "The color to use for the time during the night.",
                icon = "brush",
            ),
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
                id = P_SEASON_THEME,
                name = "Base Date Color Theme",
                desc = "The color theme for the date",
                icon = "calendar",
                options = [
                    schema.Option(
                        display = k,
                        value = SEASON_THEMES[k]["description"],
                    )
                    for k in SEASON_THEMES
                ],
                default = DEFAULT_SEASON_THEME,
            ),
        ] + [
            schema.Text(
                id = "s%d%s" % (s, p),
                name = "Date Color (%s, %s)" % (SEASON_DESC[s], PHASE_DESC[p]),
                desc = "The color to use for the date during %s in the %s" % (
                    SEASON_DESC[s],
                    PHASE_DESC[p],
                ),
                icon = "brush",
            )
            for s in range(4)
            for p in ["d", "n"]
        ],
    )

# Prefixes a color with a "#" if necessary
# color - the RGB color string
def color_of(color, default_color):
    if color:
        #print("parsing color: " + color)
        color = color.strip()
        result = PREDEFINED_COLORS.get(color.replace(" ", "").upper())
        if result:
            #print("predefined color: " + result)
            return result
        elif re.match("^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$", color):
            #print("hashless: " + color)
            return "#" + color
        elif re.match("^#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$", color):
            #print("hashed: " + color)
            return color

    # if all else fails...
    #print("default color: " + default_color);
    return default_color

P_LOCATION = "location"
P_USE_12H = "use_12h"
P_BLINK_TIME = "blink_time"
P_SEASON_THEME = "season_theme"

SEASON_DESC = [
    "Dec–Mar",
    "Mar–Jun",
    "Jun–Sep",
    "Sep–Dec",
]

PHASE_DESC = {
    "d": "Day",
    "n": "Night",
}

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_SEASON_THEME = "nh"

H12 = ("3:04", "3_04")
H24 = ("15:04", "15_04")

DEFAULT_TIME_COLOR = {
    "d": "#ffd",
    "n": "#900",
}

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

PREDEFINED_COLORS = {
    "ALICEBLUE": "#F0F8FF",
    "ANTIQUEWHITE": "#FAEBD7",
    "AQUA": "#00FFFF",
    "AQUAMARINE": "#7FFFD4",
    "AZURE": "#F0FFFF",
    "BEIGE": "#F5F5DC",
    "BISQUE": "#FFE4C4",
    "BLACK": "#000000",
    "BLANCHEDALMOND": "#FFEBCD",
    "BLUE": "#0000FF",
    "BLUEVIOLET": "#8A2BE2",
    "BROWN": "#A52A2A",
    "BURLYWOOD": "#DEB887",
    "CADETBLUE": "#5F9EA0",
    "CHARTREUSE": "#7FFF00",
    "CHOCOLATE": "#D2691E",
    "CORAL": "#FF7F50",
    "CORNFLOWERBLUE": "#6495ED",
    "CORNSILK": "#FFF8DC",
    "CRIMSON": "#DC143C",
    "CYAN": "#00FFFF",
    "DARKBLUE": "#00008B",
    "DARKCYAN": "#008B8B",
    "DARKGOLDENROD": "#B8860B",
    "DARKGRAY": "#A9A9A9",
    "DARKGREY": "#A9A9A9",
    "DARKGREEN": "#006400",
    "DARKKHAKI": "#BDB76B",
    "DARKMAGENTA": "#8B008B",
    "DARKOLIVEGREEN": "#556B2F",
    "DARKORANGE": "#FF8C00",
    "DARKORCHID": "#9932CC",
    "DARKRED": "#8B0000",
    "DARKSALMON": "#E9967A",
    "DARKSEAGREEN": "#8FBC8F",
    "DARKSLATEBLUE": "#483D8B",
    "DARKSLATEGRAY": "#2F4F4F",
    "DARKSLATEGREY": "#2F4F4F",
    "DARKTURQUOISE": "#00CED1",
    "DARKVIOLET": "#9400D3",
    "DEEPPINK": "#FF1493",
    "DEEPSKYBLUE": "#00BFFF",
    "DIMGRAY": "#696969",
    "DIMGREY": "#696969",
    "DODGERBLUE": "#1E90FF",
    "FIREBRICK": "#B22222",
    "FLORALWHITE": "#FFFAF0",
    "FORESTGREEN": "#228B22",
    "FUCHSIA": "#FF00FF",
    "GAINSBORO": "#DCDCDC",
    "GHOSTWHITE": "#F8F8FF",
    "GOLD": "#FFD700",
    "GOLDENROD": "#DAA520",
    "GRAY": "#808080",
    "GREY": "#808080",
    "GREEN": "#008000",
    "GREENYELLOW": "#ADFF2F",
    "HONEYDEW": "#F0FFF0",
    "HOTPINK": "#FF69B4",
    "INDIANRED": "#CD5C5C",
    "INDIGO": "#4B0082",
    "IVORY": "#FFFFF0",
    "KHAKI": "#F0E68C",
    "LAVENDER": "#E6E6FA",
    "LAVENDERBLUSH": "#FFF0F5",
    "LAWNGREEN": "#7CFC00",
    "LEMONCHIFFON": "#FFFACD",
    "LIGHTBLUE": "#ADD8E6",
    "LIGHTCORAL": "#F08080",
    "LIGHTCYAN": "#E0FFFF",
    "LIGHTGOLDENRODYELLOW": "#FAFAD2",
    "LIGHTGRAY": "#D3D3D3",
    "LIGHTGREY": "#D3D3D3",
    "LIGHTGREEN": "#90EE90",
    "LIGHTPINK": "#FFB6C1",
    "LIGHTSALMON": "#FFA07A",
    "LIGHTSEAGREEN": "#20B2AA",
    "LIGHTSKYBLUE": "#87CEFA",
    "LIGHTSLATEGRAY": "#778899",
    "LIGHTSLATEGREY": "#778899",
    "LIGHTSTEELBLUE": "#B0C4DE",
    "LIGHTYELLOW": "#FFFFE0",
    "LIME": "#00FF00",
    "LIMEGREEN": "#32CD32",
    "LINEN": "#FAF0E6",
    "MAGENTA": "#FF00FF",
    "MAROON": "#800000",
    "MEDIUMAQUAMARINE": "#66CDAA",
    "MEDIUMBLUE": "#0000CD",
    "MEDIUMORCHID": "#BA55D3",
    "MEDIUMPURPLE": "#9370DB",
    "MEDIUMSEAGREEN": "#3CB371",
    "MEDIUMSLATEBLUE": "#7B68EE",
    "MEDIUMSPRINGGREEN": "#00FA9A",
    "MEDIUMTURQUOISE": "#48D1CC",
    "MEDIUMVIOLETRED": "#C71585",
    "MIDNIGHTBLUE": "#191970",
    "MINTCREAM": "#F5FFFA",
    "MISTYROSE": "#FFE4E1",
    "MOCCASIN": "#FFE4B5",
    "NAVAJOWHITE": "#FFDEAD",
    "NAVY": "#000080",
    "OLDLACE": "#FDF5E6",
    "OLIVE": "#808000",
    "OLIVEDRAB": "#6B8E23",
    "ORANGE": "#FFA500",
    "ORANGERED": "#FF4500",
    "ORCHID": "#DA70D6",
    "PALEGOLDENROD": "#EEE8AA",
    "PALEGREEN": "#98FB98",
    "PALETURQUOISE": "#AFEEEE",
    "PALEVIOLETRED": "#DB7093",
    "PAPAYAWHIP": "#FFEFD5",
    "PEACHPUFF": "#FFDAB9",
    "PERU": "#CD853F",
    "PINK": "#FFC0CB",
    "PLUM": "#DDA0DD",
    "POWDERBLUE": "#B0E0E6",
    "PURPLE": "#800080",
    "REBECCAPURPLE": "#663399",
    "RED": "#FF0000",
    "ROSYBROWN": "#BC8F8F",
    "ROYALBLUE": "#4169E1",
    "SADDLEBROWN": "#8B4513",
    "SALMON": "#FA8072",
    "SANDYBROWN": "#F4A460",
    "SEAGREEN": "#2E8B57",
    "SEASHELL": "#FFF5EE",
    "SIENNA": "#A0522D",
    "SILVER": "#C0C0C0",
    "SKYBLUE": "#87CEEB",
    "SLATEBLUE": "#6A5ACD",
    "SLATEGRAY": "#708090",
    "SLATEGREY": "#708090",
    "SNOW": "#FFFAFA",
    "SPRINGGREEN": "#00FF7F",
    "STEELBLUE": "#4682B4",
    "TAN": "#D2B48C",
    "TEAL": "#008080",
    "THISTLE": "#D8BFD8",
    "TOMATO": "#FF6347",
    "TURQUOISE": "#40E0D0",
    "VIOLET": "#EE82EE",
    "WHEAT": "#F5DEB3",
    "WHITE": "#FFFFFF",
    "WHITESMOKE": "#F5F5F5",
    "YELLOW": "#FFFF00",
    "YELLOWGREEN": "#9ACD32",
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

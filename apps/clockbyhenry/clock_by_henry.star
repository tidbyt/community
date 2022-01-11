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

load('render.star', 'render')
load('time.star', 'time')
load('encoding/base64.star', 'base64')

DEFAULT_TIMEZONE = 'US/Eastern'

# parameters:
# timezone - the time zone for rendering
# season_color_set - the base color set to use (index of SEASON_COLOR_SETS)
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
    timezone = config.get('$tz', 'US/Eastern')
    now = time.now().in_location(timezone)
    now_time = now.format('15:04')
    now_time_blink = now_time.replace(':', '_')
    now_date = now.format('Mon 2 Jan 2006')

    # this is a rough approximation
    # actual seasons vary by location and astronomy
    # we just treat this as close enough
    season = int(now.format('1-02').replace('-', ''))
    if season >= 320 and season < 621:
        season = 1
    elif season >= 621 and season < 923:
        season = 2
    elif season >= 923 and season < 1221:
        season = 3
    else:
        season = 0

    phase = int(now.format('15'))
    if phase >= 6 and phase < 18:
        phase = 'd'
    else:
        phase = 'n'

    # get the base color set
    season_color_set = SEASON_COLOR_SETS[
        int(config.get('season_color_set') or '0') % len(SEASON_COLOR_SETS)
    ]

    time_color = color_of(config.get(phase) or DEFAULT_TIME_COLOR[phase])
    date_color = color_of(
        config.get('s%d%s' % (season, phase)) or
        season_color_set[phase][season]
    )

    # generate the widget for the app
    return render.Root(
        delay = 1000,
        child = render.Column(
            main_align = "center",
            children = [
                render.Stack(
                    children = [
                        render.Box(
                            width = 63,
                            height = 24,
                            color = time_color,
                        ),
                        render.Animation(
                            children = [
                                render.Row(
                                    children = [
                                        render.Image(DIGITS[char])
                                        for char in now_time.elems()
                                    ],
                                ),
                                render.Row(
                                    children = [
                                        render.Image(DIGITS[char])
                                        for char in now_time_blink.elems()
                                    ],
                                ),
                            ]
                        )
                    ],
                ),
                render.Box(
                    child = render.Text(
                        content = now_date,
                        font = "tom-thumb",
                        color = date_color,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return []

# Prefixes a color with a '#' if necessary
# color - the RGB color string
def color_of(color):
    return color if color.startswith('#') else ('#' + color)

DIGITS = {
    '0': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADZJREFUCNdjCA0NDWAIdRANYAhhYAxgCGAAogBWECHqEMDgIOogQC4BNgBiFMhQsPFgi0BWAgA+EBINLZKayAAAAABJRU5ErkJggg=='),
    '1': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAClJREFUCNdjCA0NDWAIDWEEEgEgwgFEMACJADDBAiJEgEQIWAl1CKCVACzyFrviSepFAAAAAElFTkSuQmCC'),
    '2': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEVJREFUCNdtzbENACEMA0CnSP/Fsw8jGAnvv8o7CKQvaE6OCweSCKERRBId4fT6GDK6MePAomfR9orcYobhIlWjeH7Uyw/6sBR9nwYNSwAAAABJRU5ErkJggg=='),
    '3': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAD9JREFUCNdlzKEBgDAMBdGrwGO6T9kggtt/FfgQBeZE8hLUQraioHNOdnR9cjsJHn1h8Dv74c6R7eLJyPsZbF3TmRSx6tdBGQAAAABJRU5ErkJggg=='),
    '4': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADNJREFUCNdjCA0NDWAIDWGAEQFwwgFOMIAIRhgRwgojAkRhhAOYYAACBBEaCtKBlQgNAAChxxM5EE3fuwAAAABJRU5ErkJggg=='),
    '5': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADdJREFUCNdjCA0NDWAIYGBAIVhDcRAMrCCCEaouNJRBAEg4YCdcQbKOoUB1DgxgAqxNFKQtNAAAyywUSY+7irwAAAAASUVORK5CYII='),
    '6': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEFJREFUCNdjCA0NDWAAIiDhACIYgEQII0iAFU6IAgkHMCHCCiRASiAEK4MAUMIBOxEAJlhB5oENZWAE2QE0AGQlAK5JEvS3wopyAAAAAElFTkSuQmCC'),
    '7': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADVJREFUCNdjCA0NDWBwYGAQQCJCQx1ABEMAMhHCiEIEsKIQDmBCFEYwgIlQKBECJhhhBMhKAMgsFcwfcB7aAAAAAElFTkSuQmCC'),
    '8': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAADdJREFUCNdjCA0NDWAIZWANYAhhYAxgCGAAIgdWBgEGB1EHFAIkBpYFq0PTEcAK0oamA5c2kJUAs/wP2GwBpREAAAAASUVORK5CYII='),
    '9': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAA4AAAAYAgMAAAC3qSTEAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAAEJJREFUCNdtzSEOADAIA8Ai8DP8hycg1v9/ZYVlbuZISNOCZIGIwoYVanDdjBzWH8dS6EHTj7yoj3jsKfUmml7T5AEj0RKOJbpXOwAAAABJRU5ErkJggg=='),
    ':': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYAgMAAABLvA8OAAAACVBMVEUAAAAAAAD///+D3c/SAAAAAXRSTlMAQObYZgAAABpJREFUCNdjCA1hQEMBIgwOLFAEZGMqwKYGANm5DGdVvFjRAAAAAElFTkSuQmCC'),
    '_': base64.decode('iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYAQMAAAAMHHXeAAAABlBMVEUAAAD///+l2Z/dAAAADElEQVQI12NgIA0AAAAwAAHHqoWOAAAAAElFTkSuQmCC'),
}

DEFAULT_TIME_COLOR = {
    'd': 'ffd',
    'n': '900',
}

SEASON_WINTER_D = '8cf'
SEASON_SPRING_D = '2f2'
SEASON_SUMMER_D = 'ff0'
SEASON_AUTUMN_D = 'd60'
SEASON_WINTER_N = '468'
SEASON_SPRING_N = '080'
SEASON_SUMMER_N = '880'
SEASON_AUTUMN_N = '840'

# season 0 is Dec-Mar
# season 1 is Mar-Jun
# Season 2 is Jun-Sep
# Season 3 is Sep-Dec
SEASON_COLOR_SETS = [
    {
        'd': [
            SEASON_WINTER_D,
            SEASON_SPRING_D,
            SEASON_SUMMER_D,
            SEASON_AUTUMN_D,
        ],
        'n': [
            SEASON_WINTER_N,
            SEASON_SPRING_N,
            SEASON_SUMMER_N,
            SEASON_AUTUMN_N,
        ],
    },
    {
        'd': [
            SEASON_SUMMER_D,
            SEASON_AUTUMN_D,
            SEASON_WINTER_D,
            SEASON_SPRING_D,
        ],
        'n': [
            SEASON_SUMMER_N,
            SEASON_AUTUMN_N,
            SEASON_WINTER_N,
            SEASON_SPRING_N,
        ],
    },
    {
        'd': [
            SEASON_WINTER_D,
            SEASON_SUMMER_D,
            SEASON_SUMMER_D,
            SEASON_WINTER_D,
        ],
        'n': [
            SEASON_WINTER_N,
            SEASON_SUMMER_N,
            SEASON_SUMMER_N,
            SEASON_WINTER_N,
        ],
    },
    {
        'd': [
            SEASON_SUMMER_D,
            SEASON_WINTER_D,
            SEASON_WINTER_D,
            SEASON_SUMMER_D,
        ],
        'n': [
            SEASON_SUMMER_N,
            SEASON_WINTER_N,
            SEASON_WINTER_N,
            SEASON_SUMMER_N,
        ],
    },
]

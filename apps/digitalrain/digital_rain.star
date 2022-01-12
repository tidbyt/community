"""
Applet: Digital Rain
Summary: Digital Rain à la Matrix
Description: Generates an animation loop of falling code similar to that from the Matrix movie. A new sequence every 30 minutes.
Author: Henry So, Jr.
"""

# Digital Rain à la The Matrix
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

# Via the configuration below, this app will show a different sequence every
# 30 minutes (see SEED_GRANULARITY)

load("time.star", "time")
load("render.star", "render")
load("encoding/base64.star", "base64")

# for column styles:
# 'speed' is the number of frames before the drop moves, so a lower number
# moves the drop faster
# 'drop_min' is the minimum size of a drop and its trail
# 'drop_variance' is the amount by which the drop's trail can be longer

FAST_COLUMN = {
    "speed": 1,
    "drop_min": 9,
    "drop_variance": 9,
}
NORMAL_COLUMN = {
    "speed": 2,
    "drop_min": 9,
    "drop_variance": 9,
}
SLOW_COLUMN = {
    "speed": 3,
    "drop_min": 7,
    "drop_variance": 5,
}

# this sets the relative frequency of different column types
COLUMN_STYLES = [
    FAST_COLUMN,
    FAST_COLUMN,
    FAST_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    SLOW_COLUMN,
    SLOW_COLUMN,
]
COLUMN_STYLE_COUNT = len(COLUMN_STYLES)

# this is variance in the position of the second drop in a given column
# relative to both drops being equidistant
SECOND_DROP_VARIANCE = 8

CHAR_W = 5
CHAR_H = 7

COLUMNS = 11
ROWS = 5

FRAMES = 72

# the amount of time before a new sequence is generated
SEED_GRANULARITY = 60 * 30  # 30 minutes

# config can take 'seed' (number) and 'color' (a key from COLOR_NAMES)
def main(config):
    # seed the pseudo-random number generator
    seed = config.get("seed")
    if seed:
        seed = int(seed)
    else:
        seed = int(time.now().unix) // SEED_GRANULARITY

    #print("seed = %d" % seed)

    # rand can't assign seed directly, so need to make this a mutable thing
    seed = [seed]

    # initialize the columns
    columns = [generate_column(seed) for i in range(COLUMNS)]

    # occasionally blow a column away
    if rand(seed, 25) == 0 and COLUMNS > 2:
        columns[rand(seed, COLUMNS - 2) + 1] = None

    # get the colors; do it this way so that setting the colors from the
    # config doesn't spoil the pseudo-random number sequence
    color_number = rand(seed, COLOR_COUNT)
    color_number = COLOR_NAMES.get(config.get("color")) or color_number
    colors = COLORS[color_number]

    # vary the x-offset and y-offset for more interesting variety
    xoffset = -rand(seed, CHAR_W)
    yoffset = -rand(seed, CHAR_H)

    # create the widget for the app
    return render.Root(
        delay = 30,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (xoffset, yoffset, 0, 0),
                child = render.Animation([
                    generate_frame(seed, columns, colors, f)
                    for f in range(72)
                ]),
            ),
        ),
    )

def get_schema():
    colors = [
        {"text": color, "value": color}
        for color in COLOR_NAMES
    ]
    return [
        {
            "type": "dropdown",
            "id": "color",
            "name": "Color",
            "icon": "brush",
            "description": "The color to use for the rain.",
            "options": colors,
            "default": "green",
        },
    ]

# Gets a pseudo-random number whose value is between 0 and max - 1
# seed - the random number seed container
# max - the (exclusive) max value desired
def rand(seed, max):
    seed[0] = (seed[0] * 1103515245 + 12345) & 0xffffffff
    return (seed[0] >> 16) % max

# Generates the initial state of a column
# seed - the random number seed container
def generate_column(seed):
    style = COLUMN_STYLES[rand(seed, COLUMN_STYLE_COUNT)]
    speed = style["speed"]
    drop_size = style["drop_min"] + rand(seed, style["drop_variance"])
    size = FRAMES // speed
    offset = rand(seed, size)

    second_drop = {
        "chars": [rand(seed, CHAR_SIZE) for i in range(ROWS)],
        "mutations": [0 for i in range(ROWS)],
        "offset": offset + ((size - SECOND_DROP_VARIANCE) // 2) +
                  rand(seed, SECOND_DROP_VARIANCE),
        "drop_size": style["drop_min"] + rand(seed, style["drop_variance"]),
    } if speed == 1 and rand(seed, 7) < 2 else None

    return {
        "speed": speed,
        "frame_offset": rand(seed, speed),
        "size": size,
        "chars": [rand(seed, CHAR_SIZE) for i in range(ROWS)],
        "mutations": [0 for i in range(ROWS)],
        "drop_size": drop_size,
        "offset": offset,
        "second_drop": second_drop,
    }

# Generates a given frame of the animation
# seed - the random number seed container
# columns - the list of column structures
# colors - the colors to use
# f - the frame number
def generate_frame(seed, columns, colors, f):
    frame_chars = [[None for c in range(COLUMNS)] for r in range(ROWS)]
    frame_colors = [["#000" for c in range(COLUMNS)] for r in range(ROWS)]
    for c in range(COLUMNS):
        for column in compute_column(seed, columns[c], f):
            chars = column["chars"]
            size = column["size"]
            drop_size = column["drop_size"]
            for i in range(ROWS):
                if chars[i]:
                    r = ROWS - i - 1
                    frame_chars[r][c] = chars[i][0]
                    loc = chars[i][1]
                    if loc == 0:
                        frame_colors[r][c] = "#fff"
                    else:
                        frame_colors[r][c] = colors[min(drop_size - loc, 5)]
    return render.Column([
        render.Row([
            render.Box(
                width = CHAR_W + 1,
                height = CHAR_H + 1,
                child = render_char(frame_chars[r][c], frame_colors[r][c]),
            )
            for c in range(COLUMNS)
        ])
        for r in range(ROWS)
    ])

# Computes a particular column (some columns have two drops)
# seed - the random number seed container
# column - the column structure
# f - the frame number
def compute_column(seed, column, f):
    if column:
        speed = column["speed"]
        f += column["frame_offset"]
        size = column["size"]
        do_mutate = (f % speed) == 0

        first_drop_column = compute_drop(
            seed,
            speed,
            size,
            column,
            f,
            do_mutate,
        )

        second_drop = column["second_drop"]
        if second_drop:
            second_drop_column = compute_drop(
                seed,
                speed,
                size,
                second_drop,
                f,
                do_mutate,
            )
            return [first_drop_column, second_drop_column]
        else:
            return [first_drop_column]
    else:
        return []

# Computes a particular "drop" of a given column
# seed - the random number seed container
# speed - the speed of the column
# size - the size of the column
# drop - the drop structure
# f - the frame number
# do_mutate - whether to perform a mutation
def compute_drop(seed, speed, size, drop, f, do_mutate):
    drop_size = drop["drop_size"]
    chars = drop["chars"]
    mutations = drop["mutations"]
    offset = drop["offset"]
    pos = (f // speed) + offset

    # prevent mutate when offset <= drop_size to prevent
    # flip-flops of visible characters when the animation loops

    if do_mutate and offset > drop_size:
        mutate_chars(seed, chars, mutations, pos, size, drop_size)

    return {
        "chars": chars_of(chars, pos, size, drop_size),
        "size": size,
        "drop_size": drop_size,
    }

# Mutates the visible characters randomly
# seed - the random number seed container
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def mutate_chars(seed, chars, mutations, pos, size, drop_size):
    for i in range(1, 6):
        mutate_char(
            seed,
            chars,
            mutations,
            -pos,
            size,
            drop_size - i,
            6 - i,
            30,
        )
    for n in range(1, drop_size - 5):
        mutate_char(seed, chars, mutations, -pos, size, n, 1, 50)

# Mutates a single character
# seed - the random number seed container
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# n - the index of the character within the drop
# numerator - the chance of mutation numerator
# denominator - the chance of mutation denominator
def mutate_char(seed, chars, mutations, pos, size, n, numerator, denominator):
    index = (pos + n) % size
    if (index < ROWS and
        rand(seed, denominator) < (numerator - mutations[index])):
        chars[index] = rand(seed, CHAR_SIZE)
        mutations[index] += 1

# Returns the on-screen characters
# chars - the character array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def chars_of(chars, pos, size, drop_size):
    result = [None for i in range(ROWS)]
    for i in range(drop_size):
        index = (-pos + i) % size
        if index < ROWS:
            result[index] = (chars[index], i)
    return result

# Returns the widget for a character
# index - the character index
# color - the character color
def render_char(index, color):
    if index == None:
        return render.Box(
            width = CHAR_W,
            height = CHAR_H,
        )
    else:
        return render.Box(
            color = color,
            width = CHAR_W,
            height = CHAR_H,
            child = render.Image(CHARS[index]),
        )

COLORS = [
    [p.replace("X", v) for v in ("2", "5", "8", "b", "d", "f")]
    for p in ("#00X", "#0X0", "#0XX", "#X00", "#X0X", "#XX0")
]
COLOR_COUNT = len(COLORS)
COLOR_NAMES = {
    "random": None,
    "blue": 0,
    "green": 1,
    "cyan": 2,
    "red": 3,
    "magenta": 4,
    "yellow": 5,
}

CHARS = [
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgCHRgEGRgcACTQHaoAwAfDwLvzPIL0wAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAADFBMVEUAAAAAAAAAAAD///81VxGE
AAAAAXRSTlMAQObYZgAAABRJREFUCNdjWNXAsAiMgADCWNUAAEiJBt3ss5NIAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjcHBgEGVgEGFgEGRgYGUAsR0cAA5eAVWMJE1LAAAAAElFTkSu
QmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABFJREFUCNdjCHRgcHRgCERBACjiA+h8ptgrAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjcHBgEGVgEHVgcHVgCHRgCHFgYGAAABwDApVqmM0tAAAAAElF
TkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjcHBgEGVgCGVgCHFgCHQAkQwMABzoAqSWsQZfAAAAAElFTkSu
QmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjCHFgCHBgcHFgEHFgAAIgl8EBACHtAtECSr3bAAAAAElFTkSu
QmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjYGBgCGVgcGBgEHUAIyDbAQAQMgHV+KXoWgAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjYGBgCGVgCHEAoUAwcnUAABtVAyXI2FklAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABFJREFUCNdjcHBgEGUAISQGABNxAdVsAbpSAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjcHBgEGUAIQYgw4HB1YEhwAEAFIECVVZ/E+8AAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgCHFgCHRgcAWTQHaoAwAqCAP6Ei7vBQAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgcHVgCHRgCAGTQHaoAwApYwPrEQfd2wAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgCHRgCIUhMBsAKs4EDG1DHUAAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjYGBgEHVgcHVgCHRgCHFgCAXyGQAYhAJVFpdtRwAAAABJRU5E
rkJggg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAA1JREFUCNdjCHRgwEAAKfID+KfhOFsAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjCHVgAAJRBwZBBwZHB4ZAB4YQBwAaXwLiej/h1QAAAABJRU5E
rkJggg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjYGBgCHQAEgyiQOTA4OrAEOAAAA/+AhG5p0bwAAAAAElFTkSu
QmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgAIJABygCglAHAB5UAt6wKddxAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjYGBgcHUAEgyODiDk4sDgygAAFJsCUQl5awMAAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgCHFgAAIRBxASZWBwZAAAG7QCKGqn9AMAAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgCHRgAIJABAMAH/8C2m6rxrwAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjYGBgCHFgYHBgcGVgcHVgCHQAcgEXRQLEz9hBjQAAAABJRU5E
rkJggg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgYHBgEEVCDAwAGxcCKtfnBAUAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgcHFgAAIg6QpGAQ4AIIoDOFS0udIAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgCGBgAJICDAyiDgyuIC4AHsACte2NCpYAAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgAAJRBxBydWBwdGAQYQAAGZsCWoTrZ38AAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjCHVgEGVgEAGSDgyuDgwBDgyhDgAb/wL+AYqMOgAAAABJRU5E
rkJggg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjCHVgYHBgEGVgEGRgcHUAoQAGABg7AlYvn2BMAAAAAElFTkSu
QmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgEGQAIVEHBlcwCnAAABgQAqeg/E0ZAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgAAIIGegAQiEMABrkAqFcHZMDAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgCHRgAIJABygKYQAAIloDLmKj9+0AAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABVJREFUCNdjCHVgcGBgAJIQxABiAwAjGAMqNKVR0QAAAABJRU5ErkJggg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgAAJRBwZBBwZXMBnCAAAY/wJmvhUtvgAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHRgAAJRBwZXBwYBBgYwFwAYGwINGpPaUAAAAABJRU5ErkJg
gg==
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgcIEhETASZQAAJE8C38UCgMgAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgCGUAgVAYYnAAABlWAipWNoNuAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHRgAAIgKcgARiAuABVvAZbFtVTQAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgAAJRBxBycWAIdGBwdQAAGoUC2qp8BI0AAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjCHVgcGBgEHVgCGBgYHVgCGFgYHQAABtdAlVkGr6fAAAAAElF
TkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjCHVgCHRgCHFgcHFgcGVgEGRgEGAAACS7AqVuxAJDAAAAAElF
TkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgEHVgEHFgEHRgcAWTIQwAHlYCuoGA9cEAAAAASUVORK5C
YII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgAIIQGAlEjA4AGpcCk0x0eXcAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgCHFgAAIRBwYXKBsAHu0CljuRPigAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABBJREFUCNdjYGBgEAUjJAYAA7EAVZ635RAAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgAAIIKerA4OrAEMAAABjAAlV0AcoGAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgEGWAIQcGVweGAAcAFIwCP1Iy+HYAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgAAJRIHIAIVcHhgAHABWnAmrKnOkTAAAAAElFTkSuQmCC
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABBJREFUCNdjCHVggCAggLEBJP8Df+eCbnEAAAAASUVORK5CYII=
"""),
    base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABJJREFUCNdjCHVgACIHJDLUAQApWAPq0aBWtQAAAABJRU5ErkJggg==
"""),
]
CHAR_SIZE = len(CHARS)

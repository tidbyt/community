"""
Applet: Digital Rain
Summary: Digital Rain à la Matrix
Description: Generates an animation loop of falling code similar to that from the Matrix movie. A new sequence every 30 minutes.
Author: Henry So, Jr.
"""

# Digital Rain à la The Matrix
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

# Via the configuration below, this app will show a different sequence every
# 30 minutes (see SEED_GRANULARITY)

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

WIDTH = 64
HEIGHT = 32

FRAMES = 72

# the amount of time before a new sequence is generated
SEED_GRANULARITY = 60 * 30  # 30 minutes

# in addition to the parameters in the schema, config can accept 'seed' for
# debugging issues with specific seeds
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

    # get the color; do it this way so that setting the color from the
    # config doesn't spoil the pseudo-random number sequence
    color_options = (
        [i for i in range(COLOR_COUNT)] +
        [rand(seed, COLOR_COUNT + 1) - 1, rand(seed, COLOR_COUNT)]
    )
    color_number = COLOR_NAMES.get(config.get("color"), COLOR_NAMES["random"])
    if color_number >= 0:
        color_number = color_options[color_number]

    char_size = CHAR_SIZES.get(config.get("char_size")) or CHAR_SIZES["normal"]

    # initialize the columns
    columns = [
        generate_column(seed, char_size, color_number)
        for i in range(char_size["columns"])
    ]

    # occasionally blow a column away
    if rand(seed, 25) == 0 and char_size["columns"] > 2:
        columns[rand(seed, char_size["columns"] - 2) + 1] = None

    # vary the x-offset and y-offset for more interesting variety
    xoffset = -rand(seed, max(char_size["w"], 2))
    yoffset = -rand(seed, max(char_size["h"], 2))
    #print("offset = %d, %d" % (xoffset, yoffset))

    # create the widget for the app
    return render.Root(
        delay = 30,
        child = render.Box(
            width = WIDTH,
            height = HEIGHT,
            child = render.Padding(
                pad = (xoffset, yoffset, 0, 0),
                child = render.Animation([
                    generate_frame(seed, char_size, columns, f)
                    for f in range(72)
                ]),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Color",
                icon = "brush",
                desc = "The color to use for the rain.",
                options = [
                    schema.Option(display = color, value = color)
                    for color in COLOR_NAMES
                ],
                default = "green",
            ),
            schema.Dropdown(
                id = "char_size",
                name = "Character Size",
                icon = "textHeight",
                desc = "The character size for the rain.",
                options = [
                    schema.Option(display = char_size, value = char_size)
                    for char_size in CHAR_SIZES
                ],
                default = "normal",
            ),
        ],
    )

# Gets a pseudo-random number whose value is between 0 and max - 1
# seed - the random number seed container
# max - the (exclusive) max value desired
def rand(seed, max):
    seed[0] = (seed[0] * 1103515245 + 12345) & 0xffffffff
    return (seed[0] >> 16) % max

# Generates the initial state of a column
# seed - the random number seed container
# char_size - the character size structure
# color_number - the color number
def generate_column(seed, char_size, color_number):
    style = COLUMN_STYLES[rand(seed, COLUMN_STYLE_COUNT)]
    speed = style["speed"]
    drop_size = style["drop_min"] + rand(seed, style["drop_variance"])
    size = FRAMES // speed
    offset = rand(seed, size)
    colors = colors_of(seed, color_number)

    second_drop = {
        "chars": [rand(seed, CHAR_COUNT) for i in range(char_size["rows"])],
        "mutations": [0 for i in range(char_size["rows"])],
        "offset": offset + ((size - SECOND_DROP_VARIANCE) // 2) +
                  rand(seed, SECOND_DROP_VARIANCE),
        "drop_size": style["drop_min"] + rand(seed, style["drop_variance"]),
        "colors": colors_of(seed, color_number),
    } if speed == 1 and rand(seed, 7) < 2 else None

    return {
        "speed": speed,
        "frame_offset": rand(seed, speed),
        "size": size,
        "chars": [rand(seed, CHAR_COUNT) for i in range(char_size["rows"])],
        "mutations": [0 for i in range(char_size["rows"])],
        "offset": offset,
        "drop_size": drop_size,
        "colors": colors,
        "second_drop": second_drop,
    }

# Returns the colors structure to use for the given the color_number
# seed - the random number seed container
# color_number - the color_number
def colors_of(seed, color_number):
    # always call rand to try to preserve the seed sequence
    color = rand(seed, COLOR_COUNT)
    if color_number >= 0:
        color = color_number
    return COLORS[color]

# Generates a given frame of the animation
# seed - the random number seed container
# char_size - the character size structure
# columns - the list of column structures
# f - the frame number
def generate_frame(seed, char_size, columns, f):
    frame_chars = [
        [None for c in range(char_size["columns"])]
        for r in range(char_size["rows"])
    ]
    frame_colors = [
        ["#000" for c in range(char_size["columns"])]
        for r in range(char_size["rows"])
    ]
    for c in range(char_size["columns"]):
        for column in compute_column(seed, char_size, columns[c], f):
            chars = column["chars"]
            drop_size = column["drop_size"]
            colors = column["colors"]
            for i in range(char_size["rows"]):
                if chars[i]:
                    r = char_size["rows"] - i - 1
                    frame_chars[r][c] = chars[i][0]
                    loc = chars[i][1]
                    if loc == 0:
                        frame_colors[r][c] = "#fff"
                    else:
                        frame_colors[r][c] = colors[min(drop_size - loc, 5)]
    return render.Column([
        render.Row([
            render.Box(
                width = char_size["w"] + 1,
                height = char_size["h"] + 1,
                child = render_char(
                    char_size,
                    frame_chars[r][c],
                    frame_colors[r][c],
                ),
            )
            for c in range(char_size["columns"])
        ])
        for r in range(char_size["rows"])
    ])

# Computes a particular column (some columns have two drops)
# seed - the random number seed container
# char_size - the character size structure
# column - the column structure
# f - the frame number
def compute_column(seed, char_size, column, f):
    if column:
        speed = column["speed"]
        f += column["frame_offset"]
        size = column["size"]
        do_mutate = (f % speed) == 0

        first_drop_column = compute_drop(
            seed,
            char_size,
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
                char_size,
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
# char_size - the character size structure
# speed - the speed of the column
# size - the size of the column
# drop - the drop structure
# f - the frame number
# do_mutate - whether to perform a mutation
def compute_drop(seed, char_size, speed, size, drop, f, do_mutate):
    drop_size = drop["drop_size"]
    chars = drop["chars"]
    mutations = drop["mutations"]
    offset = drop["offset"]
    pos = (f // speed) + offset

    # prevent mutate when offset <= drop_size to prevent
    # flip-flops of visible characters when the animation loops

    if do_mutate and offset > drop_size:
        mutate_chars(seed, char_size, chars, mutations, pos, size, drop_size)

    return {
        "chars": chars_of(char_size, chars, pos, size, drop_size),
        "size": size,
        "drop_size": drop_size,
        "colors": drop["colors"],
    }

# Mutates the visible characters randomly
# seed - the random number seed container
# char_size - the character size structure
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def mutate_chars(seed, char_size, chars, mutations, pos, size, drop_size):
    for i in range(1, 6):
        mutate_char(
            seed,
            char_size,
            chars,
            mutations,
            -pos,
            size,
            drop_size - i,
            6 - i,
            30,
        )
    for n in range(1, drop_size - 5):
        mutate_char(seed, char_size, chars, mutations, -pos, size, n, 1, 50)

# Mutates a single character
# seed - the random number seed container
# char_size - the character size structure
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# n - the index of the character within the drop
# numerator - the chance of mutation numerator
# denominator - the chance of mutation denominator
def mutate_char(
        seed,
        char_size,
        chars,
        mutations,
        pos,
        size,
        n,
        numerator,
        denominator):
    index = (pos + n) % size
    if (index < char_size["rows"] and
        rand(seed, denominator) < (numerator - mutations[index])):
        chars[index] = rand(seed, CHAR_COUNT)
        mutations[index] += 1

# Returns the on-screen characters
# char_size - the character size structure
# chars - the character array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def chars_of(char_size, chars, pos, size, drop_size):
    result = [None for i in range(char_size["rows"])]
    for i in range(drop_size):
        index = (-pos + i) % size
        if index < char_size["rows"]:
            result[index] = (chars[index], i)
    return result

# Returns the widget for a character
# char_size - the character size structure
# index - the character index
# color - the character color
def render_char(char_size, index, color):
    if index == None:
        return render.Box(
            width = char_size["w"],
            height = char_size["h"],
        )
    else:
        return render.Box(
            color = color,
            width = char_size["w"],
            height = char_size["h"],
            child = render.Image(char_size["chars"][index]),
        )

COLORS = [
    [p.replace("X", v) for v in ("2", "5", "8", "b", "d", "f")]
    for p in ("#00X", "#0X0", "#0XX", "#X00", "#X0X", "#XX0")
]
COLOR_COUNT = len(COLORS)
COLOR_NAMES = {
    "random": 6,
    "random-mono": 7,
    "blue": 0,
    "green": 1,
    "cyan": 2,
    "red": 3,
    "magenta": 4,
    "yellow": 5,
    "multicolor": -1,
}

CHAR_SIZES = {
    t[0]: {
        "w": t[1],
        "h": t[2],
        "columns": (WIDTH // (t[1] + 1)) + 1,
        "rows": (HEIGHT // (t[2] + 1)) + 1,
        "chars": [base64.decode(i) for i in t[3]],
    }
    for t in [
        ("normal", 5, 7, [
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgCHRgEGRgcACTQHaoAwAfDwLvzPIL0wAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAADFBMVEUAAAAAAAAAAAD///81VxGE
AAAAAXRSTlMAQObYZgAAABRJREFUCNdjWNXAsAiMgADCWNUAAEiJBt3ss5NIAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjcHBgEGVgEGFgEGRgYGUAsR0cAA5eAVWMJE1LAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABFJREFUCNdjCHRgcHRgCERBACjiA+h8ptgrAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjcHBgEGVgEHVgcHVgCHRgCHFgYGAAABwDApVqmM0tAAAAAElF
TkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjcHBgEGVgCGVgCHFgCHQAkQwMABzoAqSWsQZfAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjCHFgCHBgcHFgEHFgAAIgl8EBACHtAtECSr3bAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjYGBgCGVgcGBgEHUAIyDbAQAQMgHV+KXoWgAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjYGBgCGVgCHEAoUAwcnUAABtVAyXI2FklAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABFJREFUCNdjcHBgEGUAISQGABNxAdVsAbpSAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjcHBgEGUAIQYgw4HB1YEhwAEAFIECVVZ/E+8AAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgCHFgCHRgcAWTQHaoAwAqCAP6Ei7vBQAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgcHVgCHRgCAGTQHaoAwApYwPrEQfd2wAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgCHRgCIUhMBsAKs4EDG1DHUAAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjYGBgEHVgcHVgCHRgCHFgCAXyGQAYhAJVFpdtRwAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAA1JREFUCNdjCHRgwEAAKfID+KfhOFsAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjCHVgAAJRBwZBBwZHB4ZAB4YQBwAaXwLiej/h1QAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjYGBgCHQAEgyiQOTA4OrAEOAAAA/+AhG5p0bwAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgAIJABygCglAHAB5UAt6wKddxAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjYGBgcHUAEgyODiDk4sDgygAAFJsCUQl5awMAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgCHFgAAIRBxASZWBwZAAAG7QCKGqn9AMAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgCHRgAIJABAMAH/8C2m6rxrwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjYGBgCHFgYHBgcGVgcHVgCHQAcgEXRQLEz9hBjQAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgYHBgEEVCDAwAGxcCKtfnBAUAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgcHFgAAIg6QpGAQ4AIIoDOFS0udIAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgCGBgAJICDAyiDgyuIC4AHsACte2NCpYAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgAAJRBxBydWBwdGAQYQAAGZsCWoTrZ38AAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABtJREFUCNdjCHVgEGVgEAGSDgyuDgwBDgyhDgAb/wL+AYqMOgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABpJREFUCNdjCHVgYHBgEGVgEGRgcHUAoQAGABg7AlYvn2BMAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgEGQAIVEHBlcwCnAAABgQAqeg/E0ZAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgAAIIGegAQiEMABrkAqFcHZMDAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgCHRgAIJABygKYQAAIloDLmKj9+0AAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABVJREFUCNdjCHVgcGBgAJIQxABiAwAjGAMqNKVR0QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHVgAAJRBwZBBwZXMBnCAAAY/wJmvhUtvgAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABhJREFUCNdjCHRgAAJRBwZXBwYBBgYwFwAYGwINGpPaUAAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgcIEhETASZQAAJE8C38UCgMgAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHVgCGUAgVAYYnAAABlWAipWNoNuAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABRJREFUCNdjCHRgAAIgKcgARiAuABVvAZbFtVTQAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgAAJRBxBycWAIdGBwdQAAGoUC2qp8BI0AAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjCHVgcGBgEHVgCGBgYHVgCGFgYHQAABtdAlVkGr6fAAAAAElF
TkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAAB1JREFUCNdjCHVgCHRgCHFgcHFgcGVgEGRgEGAAACS7AqVuxAJDAAAAAElF
TkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABlJREFUCNdjCHVgEHVgEHFgEHRgcAWTIQwAHlYCuoGA9cEAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABNJREFUCNdjCHVgAIIQGAlEjA4AGpcCk0x0eXcAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgCHFgAAIRBwYXKBsAHu0CljuRPigAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABBJREFUCNdjYGBgEAUjJAYAA7EAVZ635RAAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgAAIIKerA4OrAEMAAABjAAlV0AcoGAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABZJREFUCNdjCHVgEGWAIQcGVweGAAcAFIwCP1Iy+HYAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABdJREFUCNdjCHVgAAJRIHIAIVcHhgAHABWnAmrKnOkTAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABBJREFUCNdjCHVggCAggLEBJP8Df+eCbnEAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAHAgMAAAC9yW99AAAACVBMVEUAAAAAAAD///+D3c/SAAAA
AXRSTlMAQObYZgAAABJJREFUCNdjCHVgACIHJDLUAQApWAPq0aBWtQAAAABJRU5ErkJggg==
""",
        ]),
        ("small", 4, 6, [
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAzSURB
VAjXY2T4z/CWgYFBmIXhFMMZBgYGE2YGCYYTDPcYPjAxQAELgy+DJAMDgwkjTDEAFhcJID3nfeQA
AAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAySURB
VAjXNcoxEYAwDADAT2qAO1wiqB5iAinMLGhIl/Lzh/bhTJRiONweb9pCm7jizwsRGwnuwTIyYQAA
AABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2ZYxXCbQYZhEgODA8MfhlMMWkwMjAyXGVYyvGdm+MnwnyGG4SwTgyBDOIMuw38GhjUMJgwG
DKsAbakNSUZPb74AAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAApSURB
VAjXY2b4yfCDIYphKxPDfYYdDMwMDEwM6gzpDH8YGJgYoACTAQAJVwYy4jJUVgAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2ZYxXCHQZKhj4HBjuE3ww+GCgaGQoadDP8Z/jMzrGVYw8DGIMfA8I/hPkMBw1lGBn0GZoYn
DDwAhw8Nv3tXll8AAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXBcGxEUAwFADQF19pgUxhiOxlCEOYwWkVegOocu5MoBPvhcUlm3unQyhJw2al2U3uzid7Pcko
VMMPds8NytJ4jyUAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2D4z/CeIZhhDxPDB4Y5DOcYWJgZ+Bk0GVgYVJkZbjJwMexjuMXCMJnhH8M1BmNGBlMGRoZH
DCsBYB8MoAjQqZwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcGxDUBQFADA835soFKrRek3BrKBKUVUWluIyHPXmLTSVZx6s73oHG4Di0/KEF6PLayqavwB
VCsMql7EGfIAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA5SURB
VAjXBcGxDYAgEADA49nASmewcCNC64zWNgYnoHINY4J3yYas8/rcKsOwOwKn2RpoJku4PAo/Qy0L
YoGIQ/YAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAySURB
VAjXY2ZYxXCHQZJhEgODHcNfhr8MdowMVQyCDAwM75kY4AAqxcCwisGQwZBhFQAjawpUoDCPGAAA
AABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2ZYxXCHQZJhEgODE8Nfhr8MdswMjAy/GE4wCLIwMDIwMzAw5DMyzGJgYkhmYGBiiGP4yKDH
cA4AKbMKSiTOhfwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAuSURB
VAjXPcpBFQAQFACwkUBZZyVkEkADnh7fiZ2XBLaSsXWLoxki+8JSzfTyBVJADI/pS11cAAAAAElF
TkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAuSURB
VAjXPcpBEQAQEADAHZ29lZBJAA3OKCDBebHv5Qgpi9AtSEOzi2+qQnr5ArS6EEtqW1adAAAAAElF
TkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAqSURB
VAjXRckxDQAwCACwMhH4V4EKlGCCHTv2NWlYgzxoTVjg8FHq1SAv5nwIC8A71YIAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAxSURB
VAjXBcG7EQAQFACwOLUx1DYyhiV12reJO58kKaoD3XRtwrA8nmUItmvqSUMWH4feDsU7sSFhAAAA
AElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2b4zyDC4MWwjYkBCohhAABoLgIhhifNLgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA5SURB
VAjXBcGxDYAgEADAe+MODmNl7Rw2duxIY0dixxbUYuAuFB+EzS50DsVrLE63zOpS/TA0yTMBMl4M
5Zbze1MAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcExDYAwEADAe0yQYIKNEQ0EBV3rCBOQDvWBjjpgKeld2DTMoXpwhsWBwq773eHSZSbJZ/UO
B8ALRe8RsOkAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2Q4zcDMwMDwl5EhiOEeAwODEjPDNYY/DEYMvUwMUACXYoQpBgD5QQjVqQH09gAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2RQZ3jPoMDwn4UhhOEcQzrDT2YGEYbNDC8YfjIwHGJgYJjJ8J+ZIYbhAwMPAz8Lwz8GWYY0
hjwAbjINH14TLnsAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA9SURB
VAjXBcGxDUBQFADAy8NEEqV1hI1MYAKV5q+g1IoNFBKF546ULndt9Zl1laKxe+il0RbCa7CESetw
/sVgD7OPDUzzAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcExFYAgFADA+48IEMEIJnE2AnEcDGAOO/hYbcBzdIa7MHzIyep0kxRN94fhQA2bF0t4XNgn
QpYLfXN+fU0AAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA+SURB
VAjXBcGxDYAgAACwElbfwRc8hzucjVcYF509wC+YHElYjBu2QRIUA5vD5Io+u1GNVq/FQzM7dboq
u39nBA+p0JM0KQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAySURB
VAjXLcGhFYAgAAXA+2C02y2OQHM6BnQfnmDxLh5DXHFoqs7ttazit5mGQuxO4QMEMQg1dFFD6wAA
AABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcGxDYAgAACwoqz6BhuDI4kfeYsPObNyg/ECoomjsQ0eN+Zo17CMJqfu5bCprij4FAarJGs/
S0ULyrCRTMIAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcGxEUAwFADQ9yNbuDOBQjZSWkfFWiawgFrhkov3Qve4RcblkAfF6DMlu6aq4dRtJKvXbPkB
YhMM4GlqX3sAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA3SURB
VAjXBcExEYAwEACwPCYYu2OgW1cc1EWV1QAjEooejnuSsLwQdlVA80m5OU3gVlyS7jEcPwkNCp78
syeOAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA6SURB
VAjXBcGxCYAwAATAI6O5QJbIBq5gk0WyjGAnKLiBhYWt8N5xiTiYxKYVH04ziyHCo6t24rZ6f9Pm
EdxrQdkkAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcHRDUAwFADAe3QHI/AhXUAi6adRWNEKmvTLMhLcheYRxjBYdDaKqiq93SWbOB0+b7K6zdIP
DjsKp6VnegwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA9SURB
VAjXBcGxEUAwFADQl6C0iCI6pe205rBFRlCkU1jCnTvV915yG/F0Lq9m731mycDmECJbVES2mhTn
D2TxDM4WrRuCAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA2SURB
VAjXJcYxDYAwFAXAe8lXgwFGZOChC24qpwZQw96kHbjp4gXi/lNOhVli4Iqlo7F8HscGnCMH6wV2
0PkAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA3SURB
VAjXBcGxEYAgEACw4I+AU1g7FncsQ8E0LuEYHoWF9ZsUaaGG03QRdrfHV6SBtiEkpFd3/EALC+VX
AN5aAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXNcaxEQAQEACwvLOfqUxnAq0V9CiQKmHqNtlQLcIGkieUn3ZzABuCB1Rr46baAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA5SURB
VAjXBcGxDYAgEADAe1yAjh1cwcrSXVjMYUho7aldABK9C92EUBzC4tR0X3K5bSRDNuDxqvYfIRML
KNc+0KwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA9SURB
VAjXBcGxFUAwFADAS6TSY5JUadXmsYkxLKCzgxFMkNJ7393gMWqOZNZ8MrtLiILbKbLNpFuT6lUs
PzdTC4H7AmJtAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA1SURB
VAjXBcG5DYAgAADAg1C7kAm9PbvCCsYtHEFbvrvg9+FIbhVXsgysqCk60eMUDLLpVTZd6A1DYp9k
1wAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAzSURB
VAjXBcFREYAgEAXAhbk+NLAXnyaygFVsQANHH7tNwFMuxFluxCLic5QXv94MdHMDa74Mn7+GMUkA
AAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA9SURB
VAjXBcExDYAwEADAKz8XAexVgT40sGMCC6xsTQgGWFBAnrtwqmZreB1uvdhdaOHRpG2QPmkpqhHT
D4DPDUbLv1dCAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA5SURB
VAjXBcGxCYAwEADA+3cBO90kndsEwWntBMkEFi4gktyF0wdhUQRsfl2fVI9LpsOtWVPz2s0DJVEL
/mD9QNkAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA8SURB
VAjXBcGxEUBAEADAPX+pUYQaBJ9rQqAV1ejCZ5qgDpmE3fC4faRdkyQ2h1KMLr3oVIvBGSav1fwD
HnQJuHQz61QAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXY2T4z/CKgYFBjImBgeEswwKGT0wMjxn4GR4znGJhuMmwkSGCYT0zAxeDDAMvw0YWhnsMegyp
DN8BYFcM65O4BjUAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA7SURB
VAjXBcFBDYAwAASwMgXoIKjABw5QgpDp2ZeE514LIUHB0XKLCJtoRhFN9U1Oj91adLMOl9dh+QHv
bxB0u4SzGgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA7SURB
VAjXBcExDYAwEADAa3kVzCQsDB1Z0IEKHOKApCLQQfrcFQ/CKE5VN4fd5LWGT0qDlC531WwWxw82
bgw7jqDeXQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA/SURB
VAjXBcGhGUBAGADQ57u/SAZRJGMYQrSRQSxggVtBUGRBOc57VNXpDpvPakx2rewJi95rCrNLURqD
5ND9x9gPPpu5cUUAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2TgYVBiYGC4x8Bgx/CX4S+DHTMDM8MvhmMM+5kY4AAqxQhTDAACJgmOn5fHKwAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA3SURB
VAjXJcaxDYAgEADAe3AcChJr56CzcStWYgLHsCYhFlx1YQCh7RwuE7LXaVmhSx6S26eoP7jCCBmE
Ljr3AAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAySURB
VAjXBcExEcAgEACw8IbwgBJWptqpKwwghIE/SFiua9Gk1MIBJ0DxFb80CN1WzQeE3Qz4O3ft/wAA
AABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAA3SURB
VAjXY2S4wPCbgYGBlZFBnMGcgYHhKAODHcNfhn8MEyGM/wz/mRiiGGZAGAkMPxj0Gc4DAEz6DjO+
SuuSAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAcSURB
VAjXY2T4z8DAwMDAwMQABSwMPWgijBhqAFgEApdrmiz8AAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAGCAQAAABOMPf+AAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXNcqxEQAQEACwcPrfxARMzzoKE1B9nRQPaI6F2VwbvZIUBqJk/s8vBjnYiH6NAAAAAElFTkSu
QmCC
""",
        ]),
        ("smaller", 3, 5, [
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAoSURB
VAjXY2D4w3CZ4Q8zgxbDboZ3LAwXGbYwMLIw6DP8Z9BngMgBALNhClhoZ2TcAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAoSURB
VAjXY2D4w3CZ4Q8TwweGxQwfmBmeMhxlOM/A8IahjOENA0QOAN0ZDOY1hDECAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2RoYbjIYMTAUMZwl8GCmUGG4TfDRyaGhwweDPJMDP4MFQx8AIhjB0DpxQ8rAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAmSURB
VAjXY2Y4z/CX4RgTw3eG3wwMTAwGDNIM/5gYGBgYGBigFACVswXZOwL3NAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RoYbjAoMvMYMgwh4GJgWEewx6G/4wMPxgWMRgwMoQzvGF4BwCDwgiri5ELcAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RoZLjMYMDE4MiwmuE9I8N/hv0Mj5kY/jHcYVBlZAhneMPwDgCjdgo4TldHxwAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2b4zyDE4MbEcIThGgMTM8NfBj2GJywM4gynGF4xMbxgeMngBQCPbgj3yibDQQAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2aIYDBg+M3EkMYgzSDAzCDGEMrgz8Twj8GE4TMLgyBDKIMuAGAHBZUeUohdAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2YIZdBj+MvMcJXBkIGRiYGB4RqDHBPDd4ZTDEHMDBYMQgyGAHA6BhcxkP4vAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RoYbjAYMDE8IFhKcMHJgZ+hhQGfiaGjwxzGD4yMQgwRDMIAACP7QeO7TptAgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RoYbjAYMDE8JphKcN7ZoZvDGcYTBgYahhuM/xlZpjO0MfAAACqEwl8QFxJngAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAoSURB
VAjXY2T4z/CK4T0Tw0+GzQyfmRj2MbAwmDAxODH8YTjDCJEDAMVpC1jM+4YWAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAoSURB
VAjXY2C4wfCS4T8Tw2eGzQw/GRn+MyxkEGNiOMPwh8GJASIHANCsC+VXqxxOAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAlSURB
VAjXBcGxEQAgCASwQMv+K1m7jN3fYUJcaevZstDiSCujPswaCY0PfFerAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2TQZNBn+MvA0M5wk+E/A8NjhokMjxkZ/jPcYljHyBDKwMxwEQCkKAm/YP7pfgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAYSURB
VAjXY2b4xvCfYScTAwMDAwMDVgoAVKQCutBcjboAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCXgYGZ4R2DDMM3JgZ9hr8MmUwMbgxnGRgYGf4zrGLgAgCR4AgKRTsTaAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2aIYGBgcGJiEGcQZBBlYnjPMJWBlYGhieEZwz8GhqsMaQwbAVJ5Brrg9sSfAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAoSURB
VAjXY2RYysDM8JeJ4RnDXIZnDAzfGKoYvjEzCDAcZnjHCJEDAKmlCeK+k1OeAAAAAElFTkSuQmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2QwYRBkkGBi4GcQZJBhYtBguM0QwMKgzPCBgZ2JgZUhgGEDADUXBBe32C2nAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2T4z/Ca4SMjQynDU4ZXzAyqDHYMHEwM4gyuDPwsDNwMCxg+AgCdiwedBTjXsQAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2D4w3CZ4Q8zwxeG6Qw3WBjCGT4xhDMzaDGcY2BjYhBk4GAQBAC3aggDuIcaKgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2aIZRBn4GdhkGT4zeDOwvCXwY3hBwPDXoYlDD8ZGf4zLGfgBQB1+ggz3LvhsgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAqSURB
VAjXBcGxEQAQEACwPFsotEqF0SxlORu4e0k4nlVdXWNLWYAwTPkBgoYGymIpXnsAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2S4w/CLgY2RwY3hGwMXC4MBwx8GSRYGaQY9BgcWBneGCQyfAHo6BsgeGF3BAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2T4x7CX4QUTwx+GFwwPmRm4GL4x3GZh+M4QzyDFyHCVYTLDGwDKZAsTJIAUCAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCXgYGZ4T2DHMNXBoYahu8M/5kYBBgmMjAwMXxk4GGIAACZWggYBm2GYgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2C4yPCf4RwzAx+DOsMGJgZGBnaGVEaG/QynGNxYGOwZfjOwAQCD1gcKkvyvKgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCHwZiZ4R2DFMMpJgYTBmkGDhYGKQZRhnBGhhsMExleAwB4pQbmobyYRAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2Q4x8DO8JOZgZnhMcMxFgZehhgGdiYGSYYnDFIsDB4MExjeAwB1wwbXHZL3ngAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAqSURB
VAjXBcE5AQAQAADA8wRRShWNTAKZ7RIYcBd0yJboJsV02JrNM9QPgMIIzQDPwc4AAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2D4w3CZ4Q8zwxeG6Qw3WBgCGd4zBDIxGDNIMhgzMXAyGDLEAwCxwAfjFJ0lvQAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAnSURB
VAjXY2S4znCWgZGF4RvDawZGRob/DAwMDCwMEyGUKAMDAwMAfwIFO4l/N4YAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCXgYGZ4R2DFMN3FgZTBmmGYCYGDobvDMyMDOcYbjGsBQCBKAeqQk4SuQAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2ZYxPCPoYKZ4SODJ8MfFgZnBk0GSRYGNYZFDCLMDAwMlxi4AYwdBp765XoIAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2S4w/CLgY2FYRfDawZRJobfDDwM/5kYXjCYMPxhYvjDoMvwBgCkmQnVBnVXigAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXY2T4z8DAcImZ4QfDXoZJLAzBDEwMj1kYTBkYGCQYGUIZGBj0AYn2Bi+44x7jAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAArSURB
VAjXBcGxEQAQEACw3JvEGDazjbnUmq/odO4kxUAP6cpA88JCLY5pf4wyCNq+jeHXAAAAAElFTkSu
QmCC
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCXgYGZ4T2DPMNXFgZzhnAGJkaG/QyHGRyZGL4xqDHYAACHoQdfB+594gAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2S4znCWgZGZQYrhK8N7JgZNhh8Mj5kZ1BhsGX4wM0gzPGDQBACT2ggzDscffgAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2D4w3CB4Q8Lw3+G8wxvmBm0GD4zPGFiuMHAw/CMheEdwzWG0wDTMAvqPMmRywAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2C4yPCf4T8zAx+DIsN1Job/DLsZFJgYuBg4GaQYGc4x3GJYCwCYkgg6oZFsyAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYysDIwMjC8IThDsNzJoZ7DM8Z3jIzHGcQYxBmZrjO8JghDgCV+AkWX8fyOAAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2T4z/Ca4SMjQynDU4ZXzAwqDAYMPIwMxxluMnxhZvjGcIzhGAC2vwqfpf6JqwAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAkSURB
VAjXY2ZQZ3Bh+MPAkM/wkyGfmeELwzmGI3DeB4bjDEcAnEwKIH/tZbwAAAAASUVORK5CYII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAApSURB
VAjXBcGxDQAQAACwCnG0N9zgJJPRKmYT2qBBMl2i7NkUwwm6an2BRgkk0LWqjgAAAABJRU5ErkJg
gg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAqSURB
VAjXBcExDQAgDACwZj8GEMiPpTmYlB1YwAa0tKdDIgPMMFybY6kPhTIHVhSLC+cAAAAASUVORK5C
YII=
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAsSURB
VAjXY2RYwfCXgZmZ4S2DPMMKBoZihv8Mz5gYeBmeMUgyMFxlSGPYCACWIAizgGvpbwAAAABJRU5E
rkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAgSURB
VAjXJcWxDQAABACwStzp/wdYGXRpWEgDob7+Fg5SLARQgyb80AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAQAAAAqeJ4pAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAnSURB
VAjXY2T4z8DAwMDM4MIwnYGDiYGHQZqBh4nhC8NThi+MEDkAW+YF66eyVIUAAAAASUVORK5CYII=
""",
        ]),
        ("tiny", 2, 3, [
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4ysDAzMDDcJWR4SgDAwAR7wJxpakatwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2S4zMDAzCDIcIWR4TIDAwAS8QKRPimLzgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToYnjDxPCFgYOJ4QcDDwAcJgN8QSddvgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2SYxaDMxKDEwMrEwMbAAAAKzwDwqlv94AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToZhBjYdBgMGJhuMOwEwAOFAKa+nOVPwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RYwPCakeEFwzFmBhmGswAfdQQodWBAJgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Y4yiDPzCDO8JGF4TXDXwAV4APfYpm2mwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2aoY+BkYVBgsGZheM/ADgAMdwHkKaMFcQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ZYxCDBwuDEwMHEcJFBEwAOjAIIazAzUAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToYmBgYWBhYGBh+MPAAAAKcAGUlhKA0AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToYGBkYnjMoMDEYMkgDAAPxQHeT1y8YwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2R4zXCfieEcAwsjw2uG+wAf4wRr03SbMgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2A4xfCaiYGF4RwTwx8GIwAcogO60Lk7/AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2R4zsDAyPCDgYGF4T0DAwAWhALVrNnhgwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2TIZLBkZDjDwMDCcI3hOAARrQMSUeTJpgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAARSURB
VAjXY2Q4xMDAxMAAJQAKFgDIxUBoLgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoZhBhYvjEoMvIsJfhCwATgwNsf/Q9qwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2QIZPjPwmDEIMvCoMkgDgASPAHpPTvulgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToZGBgYVBgYGBheMDAAAAK7wGTbt/MpgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RwZFBhYuBlUGVisGEQAwAHJQDvtVyrogAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4yHCXmUGa4TULgzgDAwAaOwLEA/ThAgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RYz8DAwnCVgYGF4RMDAwASuwKAwjkqYAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RIYXjHwiDJ4MjIcIbhCwAVPwNz5seEZQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYrBgYlBgcGBmkGX4CAANCwIvO8pMDAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2SYwfCfmUGZgZ2FwZxBHAAU+wIYqXUIEAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Z4wKDCzGDK8IeJgZGBBQAU5wJDAhndMQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYRBhYhBiCGZmsGJ4CgAL5gIjwBAWWQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4xsDCxHCHgZuJQZPhOQAS+gLHaXORdwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYlBiYmBmYGViUGD4DAAJ1QHFAqUX1gAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RYwsDExPCOQZOJQZThPQASOgLHtLy0uQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2SYyMDAwvCKgZmJIYRBCAAQHQHs1gfwqwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RYx8DAwvCIgYmJwZWBHQARGAHmckjhVgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2TYxXCHkeEJwy9mBlWGuwAhZQR8yuX0SAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYhBhYvjLYM/EoMVwBgASXgLO+6GemwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2TIYxBnYZBlUGRmUGI4AwAJyAG6xLDSkgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2TYxsDIwnCHgYmFQZCBCQAQxAGyLPy6iwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4yXCbieEXw10mhqcMfAAjlQR0cfyM6QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2QoYmBgYeBlYGNm4GBgAQAGxwCasrYHAgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYRBjYhBlMGNiEGT4CQAK+gH1lQ5zxAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RYwfCCieEdwzcmhicMPAAiqARqNrZImAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2R4xPCGheE0w2tmBnmGiwAi+wR9XYDRsgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2A4wvCamUGVQYiJQZHhOgAXEgLkr9J+uAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2ToZXjPxPCX4Q4TAx+DNwAfLwO0wqSpEQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4yHCPmUGW4SkTAyfDBwAa7gOhpyzDIAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2TIZmBgYWBjYGBh+MXAAAAI5wF1mFUpHgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2SYxPCPieERAxMLgwHDDwAbPgOkwPL0ZgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2Q4w/CPieEew18mhv8MPwEmVgWjo+5UogAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2RoYWBkYZBmsGNi4GJ4AgAKXQHUYVZI4AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2T4ycDAzKDCcIWR4ScDAwAV6QLwr/srNQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAQAAAAT4xYKAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAXSURB
VAjXY2S4w8DAwnCSgYGR4Q4DAwAUUwKIF5REwAAAAABJRU5ErkJggg==
""",
        ]),
        ("tinier", 1, 2, [
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYyMTAAAACkACkenaHKQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYz8TAAAACyACyiGwguQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CoYWJgAAAB/AB/S82UlAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DYysTADwAC7wDHyMUL9AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYw8TwEQADrQGgErOJZgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYw8TwEQADrQGgErOJZgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYxsRwEQADNQFqIDzqnAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CoZmLQAAACIACmZvC/NwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYwMSgAQACtADLYw0ohAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DoYmJgAAACNACNMkBU1wAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BoZWKQAwACPgCm8+UE/gAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2C4zMTAAAADWADWiXNr2QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2C4zMTAAAADWADWiXNr2QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2B4x8TAAAADxADxIpoPWgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYyMTAAAACkACkenaHKQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4wsTAAAADHADHupe8pAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYzMQgAwACdACygC7BEAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BIYWLwBAAB5QCwEFrqEQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYwcTAAAACbACbpNKYWgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CIYmIwAAABpACNL9SuDgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYzsTwEQADWQGLhTJC3AAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYy8TwCAADYgGCup7mFQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DIYWDYDgACbQEk+lkzOgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DYwMTwBQADwAGnixcx/wAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DoZGKQAgACSgCmmj8KlQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYz8TwAQADuAGiA7J4XgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYxMTAAgACmACpoSj4MwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4xMTAAAADFADFKZD1ugAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYxMTACwACYQCi0182jQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYxsQgAAACtAC57VZ4SQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DoYGIQAQACQACfm8POGwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYz8TABwAClgCwZfp8NgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4xMTwBQAECAG5GX2voAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYzsQgCAACeQCrqKwixgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DoYmJ4DQADHwF4godsFgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYxcTwCQADpgGfNB+yxgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2BYycTwHQADpwGjZMEX7wAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CoYmJ4AwAC4AFpSqN5vAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYx8QgAwACoAC9GETfsAAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYwcTwAQADXAGLX5ZNfQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4wcSwCQAD3gF96PkofwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4wsTwCAAD/gGp59DiSwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CoZmIQBgACCwCR8BHPrwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYwcTwEAADTQF8qSEyuwAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DIZGJgAAABsABsLYPg0QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DoYmLgBgACPwCYDYdWMgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2DYz8TwHQAD/wG5bhPhFgAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2CYwcSgAgACkAC/4nEb0QAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2C4wsTAAAADXADXMb8oAQAAAABJRU5ErkJggg==
""",
            """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAQAAAAziH6sAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAOSURB
VAjXY2A4wcTAAAADLADLrscp2gAAAABJRU5ErkJggg==
""",
        ]),
    ]
}
CHAR_COUNT = len(CHAR_SIZES["normal"]["chars"])

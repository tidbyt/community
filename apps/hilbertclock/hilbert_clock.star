"""
Applet: Hilbert Clock
Summary: Colorful Hilbert Curve
Description: Traces a Hilbert curve on the background of a clock. The colors of the pixels are based on various 3d, 2d, and 1d Hilbert curves through color space.
Author: kevwoods
"""

load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DELAY = 55  # milliseconds between frames
CHUNK = 11  # number of pixels in the curve plotted at once
# animation will run 32*64*DELAY/CHUNK seconds, and then pause on completion
# for remainder of the 15 second total time

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_TWENTY_FOUR_HOUR = False
DEFAULT_BLINK = True
DEFAULT_BACKGROUND_COLOR = "#999"
DEFAULT_DISPLAY_CLOCK = True

# Standard 2d Hilbert curve which goes between every point in 32x32 grid,
# starting at (0,0) and ending at (31,0),
# where each step is one unit in one direction.
HILBERT_32x32 = [(0, 0), (0, 1), (1, 1), (1, 0), (2, 0), (3, 0), (3, 1), (2, 1), (2, 2), (3, 2), (3, 3), (2, 3), (1, 3), (1, 2), (0, 2), (0, 3), (0, 4), (1, 4), (1, 5), (0, 5), (0, 6), (0, 7), (1, 7), (1, 6), (2, 6), (2, 7), (3, 7), (3, 6), (3, 5), (2, 5), (2, 4), (3, 4), (4, 4), (5, 4), (5, 5), (4, 5), (4, 6), (4, 7), (5, 7), (5, 6), (6, 6), (6, 7), (7, 7), (7, 6), (7, 5), (6, 5), (6, 4), (7, 4), (7, 3), (7, 2), (6, 2), (6, 3), (5, 3), (4, 3), (4, 2), (5, 2), (5, 1), (4, 1), (4, 0), (5, 0), (6, 0), (6, 1), (7, 1), (7, 0), (8, 0), (9, 0), (9, 1), (8, 1), (8, 2), (8, 3), (9, 3), (9, 2), (10, 2), (10, 3), (11, 3), (11, 2), (11, 1), (10, 1), (10, 0), (11, 0), (12, 0), (12, 1), (13, 1), (13, 0), (14, 0), (15, 0), (15, 1), (14, 1), (14, 2), (15, 2), (15, 3), (14, 3), (13, 3), (13, 2), (12, 2), (12, 3), (12, 4), (12, 5), (13, 5), (13, 4), (14, 4), (15, 4), (15, 5), (14, 5), (14, 6), (15, 6), (15, 7), (14, 7), (13, 7), (13, 6), (12, 6), (12, 7), (11, 7), (10, 7), (10, 6), (11, 6), (11, 5), (11, 4), (10, 4), (10, 5), (9, 5), (9, 4), (8, 4), (8, 5), (8, 6), (9, 6), (9, 7), (8, 7), (8, 8), (9, 8), (9, 9), (8, 9), (8, 10), (8, 11), (9, 11), (9, 10), (10, 10), (10, 11), (11, 11), (11, 10), (11, 9), (10, 9), (10, 8), (11, 8), (12, 8), (12, 9), (13, 9), (13, 8), (14, 8), (15, 8), (15, 9), (14, 9), (14, 10), (15, 10), (15, 11), (14, 11), (13, 11), (13, 10), (12, 10), (12, 11), (12, 12), (12, 13), (13, 13), (13, 12), (14, 12), (15, 12), (15, 13), (14, 13), (14, 14), (15, 14), (15, 15), (14, 15), (13, 15), (13, 14), (12, 14), (12, 15), (11, 15), (10, 15), (10, 14), (11, 14), (11, 13), (11, 12), (10, 12), (10, 13), (9, 13), (9, 12), (8, 12), (8, 13), (8, 14), (9, 14), (9, 15), (8, 15), (7, 15), (7, 14), (6, 14), (6, 15), (5, 15), (4, 15), (4, 14), (5, 14), (5, 13), (4, 13), (4, 12), (5, 12), (6, 12), (6, 13), (7, 13), (7, 12), (7, 11), (6, 11), (6, 10), (7, 10), (7, 9), (7, 8), (6, 8), (6, 9), (5, 9), (5, 8), (4, 8), (4, 9), (4, 10), (5, 10), (5, 11), (4, 11), (3, 11), (2, 11), (2, 10), (3, 10), (3, 9), (3, 8), (2, 8), (2, 9), (1, 9), (1, 8), (0, 8), (0, 9), (0, 10), (1, 10), (1, 11), (0, 11), (0, 12), (0, 13), (1, 13), (1, 12), (2, 12), (3, 12), (3, 13), (2, 13), (2, 14), (3, 14), (3, 15), (2, 15), (1, 15), (1, 14), (0, 14), (0, 15), (0, 16), (1, 16), (1, 17), (0, 17), (0, 18), (0, 19), (1, 19), (1, 18), (2, 18), (2, 19), (3, 19), (3, 18), (3, 17), (2, 17), (2, 16), (3, 16), (4, 16), (4, 17), (5, 17), (5, 16), (6, 16), (7, 16), (7, 17), (6, 17), (6, 18), (7, 18), (7, 19), (6, 19), (5, 19), (5, 18), (4, 18), (4, 19), (4, 20), (4, 21), (5, 21), (5, 20), (6, 20), (7, 20), (7, 21), (6, 21), (6, 22), (7, 22), (7, 23), (6, 23), (5, 23), (5, 22), (4, 22), (4, 23), (3, 23), (2, 23), (2, 22), (3, 22), (3, 21), (3, 20), (2, 20), (2, 21), (1, 21), (1, 20), (0, 20), (0, 21), (0, 22), (1, 22), (1, 23), (0, 23), (0, 24), (0, 25), (1, 25), (1, 24), (2, 24), (3, 24), (3, 25), (2, 25), (2, 26), (3, 26), (3, 27), (2, 27), (1, 27), (1, 26), (0, 26), (0, 27), (0, 28), (1, 28), (1, 29), (0, 29), (0, 30), (0, 31), (1, 31), (1, 30), (2, 30), (2, 31), (3, 31), (3, 30), (3, 29), (2, 29), (2, 28), (3, 28), (4, 28), (5, 28), (5, 29), (4, 29), (4, 30), (4, 31), (5, 31), (5, 30), (6, 30), (6, 31), (7, 31), (7, 30), (7, 29), (6, 29), (6, 28), (7, 28), (7, 27), (7, 26), (6, 26), (6, 27), (5, 27), (4, 27), (4, 26), (5, 26), (5, 25), (4, 25), (4, 24), (5, 24), (6, 24), (6, 25), (7, 25), (7, 24), (8, 24), (8, 25), (9, 25), (9, 24), (10, 24), (11, 24), (11, 25), (10, 25), (10, 26), (11, 26), (11, 27), (10, 27), (9, 27), (9, 26), (8, 26), (8, 27), (8, 28), (9, 28), (9, 29), (8, 29), (8, 30), (8, 31), (9, 31), (9, 30), (10, 30), (10, 31), (11, 31), (11, 30), (11, 29), (10, 29), (10, 28), (11, 28), (12, 28), (13, 28), (13, 29), (12, 29), (12, 30), (12, 31), (13, 31), (13, 30), (14, 30), (14, 31), (15, 31), (15, 30), (15, 29), (14, 29), (14, 28), (15, 28), (15, 27), (15, 26), (14, 26), (14, 27), (13, 27), (12, 27), (12, 26), (13, 26), (13, 25), (12, 25), (12, 24), (13, 24), (14, 24), (14, 25), (15, 25), (15, 24), (15, 23), (14, 23), (14, 22), (15, 22), (15, 21), (15, 20), (14, 20), (14, 21), (13, 21), (13, 20), (12, 20), (12, 21), (12, 22), (13, 22), (13, 23), (12, 23), (11, 23), (11, 22), (10, 22), (10, 23), (9, 23), (8, 23), (8, 22), (9, 22), (9, 21), (8, 21), (8, 20), (9, 20), (10, 20), (10, 21), (11, 21), (11, 20), (11, 19), (11, 18), (10, 18), (10, 19), (9, 19), (8, 19), (8, 18), (9, 18), (9, 17), (8, 17), (8, 16), (9, 16), (10, 16), (10, 17), (11, 17), (11, 16), (12, 16), (13, 16), (13, 17), (12, 17), (12, 18), (12, 19), (13, 19), (13, 18), (14, 18), (14, 19), (15, 19), (15, 18), (15, 17), (14, 17), (14, 16), (15, 16), (16, 16), (17, 16), (17, 17), (16, 17), (16, 18), (16, 19), (17, 19), (17, 18), (18, 18), (18, 19), (19, 19), (19, 18), (19, 17), (18, 17), (18, 16), (19, 16), (20, 16), (20, 17), (21, 17), (21, 16), (22, 16), (23, 16), (23, 17), (22, 17), (22, 18), (23, 18), (23, 19), (22, 19), (21, 19), (21, 18), (20, 18), (20, 19), (20, 20), (20, 21), (21, 21), (21, 20), (22, 20), (23, 20), (23, 21), (22, 21), (22, 22), (23, 22), (23, 23), (22, 23), (21, 23), (21, 22), (20, 22), (20, 23), (19, 23), (18, 23), (18, 22), (19, 22), (19, 21), (19, 20), (18, 20), (18, 21), (17, 21), (17, 20), (16, 20), (16, 21), (16, 22), (17, 22), (17, 23), (16, 23), (16, 24), (16, 25), (17, 25), (17, 24), (18, 24), (19, 24), (19, 25), (18, 25), (18, 26), (19, 26), (19, 27), (18, 27), (17, 27), (17, 26), (16, 26), (16, 27), (16, 28), (17, 28), (17, 29), (16, 29), (16, 30), (16, 31), (17, 31), (17, 30), (18, 30), (18, 31), (19, 31), (19, 30), (19, 29), (18, 29), (18, 28), (19, 28), (20, 28), (21, 28), (21, 29), (20, 29), (20, 30), (20, 31), (21, 31), (21, 30), (22, 30), (22, 31), (23, 31), (23, 30), (23, 29), (22, 29), (22, 28), (23, 28), (23, 27), (23, 26), (22, 26), (22, 27), (21, 27), (20, 27), (20, 26), (21, 26), (21, 25), (20, 25), (20, 24), (21, 24), (22, 24), (22, 25), (23, 25), (23, 24), (24, 24), (24, 25), (25, 25), (25, 24), (26, 24), (27, 24), (27, 25), (26, 25), (26, 26), (27, 26), (27, 27), (26, 27), (25, 27), (25, 26), (24, 26), (24, 27), (24, 28), (25, 28), (25, 29), (24, 29), (24, 30), (24, 31), (25, 31), (25, 30), (26, 30), (26, 31), (27, 31), (27, 30), (27, 29), (26, 29), (26, 28), (27, 28), (28, 28), (29, 28), (29, 29), (28, 29), (28, 30), (28, 31), (29, 31), (29, 30), (30, 30), (30, 31), (31, 31), (31, 30), (31, 29), (30, 29), (30, 28), (31, 28), (31, 27), (31, 26), (30, 26), (30, 27), (29, 27), (28, 27), (28, 26), (29, 26), (29, 25), (28, 25), (28, 24), (29, 24), (30, 24), (30, 25), (31, 25), (31, 24), (31, 23), (30, 23), (30, 22), (31, 22), (31, 21), (31, 20), (30, 20), (30, 21), (29, 21), (29, 20), (28, 20), (28, 21), (28, 22), (29, 22), (29, 23), (28, 23), (27, 23), (27, 22), (26, 22), (26, 23), (25, 23), (24, 23), (24, 22), (25, 22), (25, 21), (24, 21), (24, 20), (25, 20), (26, 20), (26, 21), (27, 21), (27, 20), (27, 19), (27, 18), (26, 18), (26, 19), (25, 19), (24, 19), (24, 18), (25, 18), (25, 17), (24, 17), (24, 16), (25, 16), (26, 16), (26, 17), (27, 17), (27, 16), (28, 16), (29, 16), (29, 17), (28, 17), (28, 18), (28, 19), (29, 19), (29, 18), (30, 18), (30, 19), (31, 19), (31, 18), (31, 17), (30, 17), (30, 16), (31, 16), (31, 15), (31, 14), (30, 14), (30, 15), (29, 15), (28, 15), (28, 14), (29, 14), (29, 13), (28, 13), (28, 12), (29, 12), (30, 12), (30, 13), (31, 13), (31, 12), (31, 11), (30, 11), (30, 10), (31, 10), (31, 9), (31, 8), (30, 8), (30, 9), (29, 9), (29, 8), (28, 8), (28, 9), (28, 10), (29, 10), (29, 11), (28, 11), (27, 11), (26, 11), (26, 10), (27, 10), (27, 9), (27, 8), (26, 8), (26, 9), (25, 9), (25, 8), (24, 8), (24, 9), (24, 10), (25, 10), (25, 11), (24, 11), (24, 12), (24, 13), (25, 13), (25, 12), (26, 12), (27, 12), (27, 13), (26, 13), (26, 14), (27, 14), (27, 15), (26, 15), (25, 15), (25, 14), (24, 14), (24, 15), (23, 15), (22, 15), (22, 14), (23, 14), (23, 13), (23, 12), (22, 12), (22, 13), (21, 13), (21, 12), (20, 12), (20, 13), (20, 14), (21, 14), (21, 15), (20, 15), (19, 15), (19, 14), (18, 14), (18, 15), (17, 15), (16, 15), (16, 14), (17, 14), (17, 13), (16, 13), (16, 12), (17, 12), (18, 12), (18, 13), (19, 13), (19, 12), (19, 11), (19, 10), (18, 10), (18, 11), (17, 11), (16, 11), (16, 10), (17, 10), (17, 9), (16, 9), (16, 8), (17, 8), (18, 8), (18, 9), (19, 9), (19, 8), (20, 8), (21, 8), (21, 9), (20, 9), (20, 10), (20, 11), (21, 11), (21, 10), (22, 10), (22, 11), (23, 11), (23, 10), (23, 9), (22, 9), (22, 8), (23, 8), (23, 7), (22, 7), (22, 6), (23, 6), (23, 5), (23, 4), (22, 4), (22, 5), (21, 5), (21, 4), (20, 4), (20, 5), (20, 6), (21, 6), (21, 7), (20, 7), (19, 7), (19, 6), (18, 6), (18, 7), (17, 7), (16, 7), (16, 6), (17, 6), (17, 5), (16, 5), (16, 4), (17, 4), (18, 4), (18, 5), (19, 5), (19, 4), (19, 3), (19, 2), (18, 2), (18, 3), (17, 3), (16, 3), (16, 2), (17, 2), (17, 1), (16, 1), (16, 0), (17, 0), (18, 0), (18, 1), (19, 1), (19, 0), (20, 0), (21, 0), (21, 1), (20, 1), (20, 2), (20, 3), (21, 3), (21, 2), (22, 2), (22, 3), (23, 3), (23, 2), (23, 1), (22, 1), (22, 0), (23, 0), (24, 0), (24, 1), (25, 1), (25, 0), (26, 0), (27, 0), (27, 1), (26, 1), (26, 2), (27, 2), (27, 3), (26, 3), (25, 3), (25, 2), (24, 2), (24, 3), (24, 4), (25, 4), (25, 5), (24, 5), (24, 6), (24, 7), (25, 7), (25, 6), (26, 6), (26, 7), (27, 7), (27, 6), (27, 5), (26, 5), (26, 4), (27, 4), (28, 4), (29, 4), (29, 5), (28, 5), (28, 6), (28, 7), (29, 7), (29, 6), (30, 6), (30, 7), (31, 7), (31, 6), (31, 5), (30, 5), (30, 4), (31, 4), (31, 3), (31, 2), (30, 2), (30, 3), (29, 3), (28, 3), (28, 2), (29, 2), (29, 1), (28, 1), (28, 0), (29, 0), (30, 0), (30, 1), (31, 1), (31, 0)]

# Standard 3d Hilbert curve which goes between every point in 4x4x4 grid,
# starting at (0,0,0) and ending at (3,0,0),
# where each step is one unit in one direction.
HILBERT_4x4x4 = [(0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1), (0, 1, 0), (0, 2, 0), (1, 2, 0), (1, 3, 0), (0, 3, 0), (0, 3, 1), (1, 3, 1), (1, 2, 1), (0, 2, 1), (0, 2, 2), (1, 2, 2), (1, 3, 2), (0, 3, 2), (0, 3, 3), (1, 3, 3), (1, 2, 3), (0, 2, 3), (0, 1, 3), (0, 0, 3), (0, 0, 2), (0, 1, 2), (1, 1, 2), (1, 0, 2), (1, 0, 3), (1, 1, 3), (2, 1, 3), (2, 0, 3), (2, 0, 2), (2, 1, 2), (3, 1, 2), (3, 0, 2), (3, 0, 3), (3, 1, 3), (3, 2, 3), (2, 2, 3), (2, 3, 3), (3, 3, 3), (3, 3, 2), (2, 3, 2), (2, 2, 2), (3, 2, 2), (3, 2, 1), (2, 2, 1), (2, 3, 1), (3, 3, 1), (3, 3, 0), (2, 3, 0), (2, 2, 0), (3, 2, 0), (3, 1, 0), (3, 1, 1), (2, 1, 1), (2, 1, 0), (2, 0, 0), (2, 0, 1), (3, 0, 1), (3, 0, 0)]

# Converts a positive integer into a hex string
def hex(c):
    answer = ""
    split = [c // 16, c % 16]
    for a in split:
        if a < 10:
            answer += str(a)
        elif a == 10:
            answer += "a"
        elif a == 11:
            answer += "b"
        elif a == 12:
            answer += "c"
        elif a == 13:
            answer += "d"
        elif a == 14:
            answer += "e"
        else:
            answer += "f"
    return answer

# Converts an rgb color, given as 3-tuple of floats in [0,1], into a hex color string
def rgb_to_hex(r, g, b):
    return "#" + hex(int(r * 255.99)) + hex(int(g * 255.99)) + hex(int(b * 255.99))

# Converts an hsv color, given as 3-tuple with h in [0,6) and s,v in [0,1], into
# an rgb color, given as 3-tuple of floats in [0,1]
def hsv_to_rgb(h, s, v):
    if s == 0:
        return (v, v, v)
    i = int(h * 6.0)
    f = h * 6.0 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    if i == 0:
        return (v, t, p)
    elif i == 1:
        return (q, v, p)
    elif i == 2:
        return (p, v, t)
    elif i == 3:
        return (p, q, v)
    elif i == 4:
        return (t, p, v)
    else:
        return (v, p, q)

# Converts hsl color to rgb, where both are 3-tuples of floats in [0,1]
def hsl_to_rgb(h, s, l):
    v = l + s * min(l, 1 - l)
    s = 0 if v == 0 else 2 - 2 * l / v
    return hsv_to_rgb(h, s, v)

# Converts YCbCr color to rgb, where both are 3-tuples of floats in [0,1]
def ycbcr_to_rgb(y, cb, cr):
    r = y + 1.40200 * (cr - 0.5)
    g = y - 0.34414 * (cb - 0.5) - 0.71414 * (cr - 0.5)
    b = y + 1.77200 * (cb - 0.5)
    return max(0, min(1, r)), max(0, min(1, g)), max(0, min(1, b))

# Gets the sequence of coordinates that the path will trace.
# It gives us a cycle that starts and ends in the same place,
# and picks a random starting point on the cycle
def get_points():
    points = [(31 - y, 31 - x) for x, y in HILBERT_32x32]
    points += [(63 - x, y) for x, y in points[::-1]]
    offset = random.number(0, 2047)
    return [points[(k + offset) % 2048] for k in range(2048)]

# Gets the colors of the points, using a Hilbert cycle through all of rgb space.
# Also returns clock color (set to be always black)
def get_colors_3d():
    # Create cycle on 8x8x8 grid
    colors_base = [(x, y, 3 - z) for x, y, z in HILBERT_4x4x4]
    colors_base += [(y + 4, x, z) for x, y, z in colors_base]
    colors_base += [(x, 7 - y, z) for x, y, z in colors_base[::-1]]
    colors_base += [(x, y, 7 - z) for x, y, z in colors_base[::-1]]
    colors = []

    # interpolates so that the 8**3 = 512 colors last through the 64*32=2048 points.
    for k in range(512):
        colors.append(colors_base[k])
        x1, y1, z1 = colors_base[k]
        x2, y2, z2 = colors_base[(k + 1) % 512]
        colors.append(((3 * x1 + x2) / 4, (3 * y1 + y2) / 4, (3 * z1 + z2) / 4))
        colors.append(((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2))
        colors.append(((x1 + 3 * x2) / 4, (y1 + 3 * y2) / 4, (z1 + 3 * z2) / 4))

    colors = [(x / 7, y / 7, z / 7) for x, y, z in colors]  # scale to [0,1]

    # picks random starting point on color cycle
    offset = random.number(0, 2047)
    colors = [colors[(k + offset) % 2048] for k in range(2048)]

    clock_color = "#000"  # black shows up best

    option = random.number(0, 5)  # randomly permutes red, green, and blue
    if option == 0:
        return [rgb_to_hex(x, y, z) for x, y, z in colors], clock_color
    elif option == 1:
        return [rgb_to_hex(x, z, y) for x, y, z in colors], clock_color
    elif option == 2:
        return [rgb_to_hex(y, x, z) for x, y, z in colors], clock_color
    elif option == 3:
        return [rgb_to_hex(y, z, x) for x, y, z in colors], clock_color
    elif option == 4:
        return [rgb_to_hex(z, x, y) for x, y, z in colors], clock_color
    else:
        return [rgb_to_hex(z, y, x) for x, y, z in colors], clock_color

# Gets the colors of the points, through various 2d Hilbert cycles in color space.
# Also returns clock color, which depends on type of color cycle
def get_colors_2d():
    # Creates cycle on 32x32 grid
    colors_base = [(15 - x, y) for x, y in HILBERT_32x32[:256]]
    colors_base += [(x, y + 16) for x, y in colors_base]
    colors_base += [(31 - x, y) for x, y in colors_base[::-1]]
    colors = []

    # interpolates so that the 32*32 = 1024 colors last through the 64*32=2048 points.
    for k in range(1024):
        colors.append(colors_base[k])
        x1, y1 = colors_base[k]
        x2, y2 = colors_base[(k + 1) % 1024]
        colors.append(((x1 + x2) / 2, (y1 + y2) / 2))
    colors = [(x / 31, y / 31) for x, y in colors]  # scale to [0,1]

    # picks random starting point on color cycle
    offset = random.number(0, 2047)
    colors = [colors[(k + offset) % 2048] for k in range(2048)]

    clock_color_fix_y = "#000"  # black usually shows up best

    # For color cycles that are all in one hue, use the opposite hue for the clock
    h = random.number(0, 255) / 256
    clock_color_fix_h = rgb_to_hex(*hsl_to_rgb((h + 0.5) % 1, 1, 0.5))

    option = random.number(0, 13)  # randomly pick a path style

    # Cycle through all colors of luminance 0.5 (luminance of the primary colors)
    if option == 0:
        return [rgb_to_hex(*ycbcr_to_rgb(0.5, x, y)) for x, y in colors], clock_color_fix_y
    elif option == 1:
        return [rgb_to_hex(*ycbcr_to_rgb(0.5, y, x)) for x, y in colors], clock_color_fix_y
    elif option == 2:  # Cycle through all colors where one of r, g, b is 0
        return [rgb_to_hex(0, x, y) for x, y in colors], "#f00"  # red best clock color
    elif option == 3:
        return [rgb_to_hex(0, y, x) for x, y in colors], "#f00"
    elif option == 4:
        return [rgb_to_hex(x, 0, y) for x, y in colors], "#0f0"
    elif option == 5:
        return [rgb_to_hex(y, 0, x) for x, y in colors], "#0f0"
    elif option == 6:
        return [rgb_to_hex(x, y, 0) for x, y in colors], "#00f"
    elif option == 7:
        return [rgb_to_hex(y, x, 0) for x, y in colors], "#00f"
    elif option in range(8, 11):  # Cycle through all colors of one hue
        return [rgb_to_hex(*hsl_to_rgb(h, x, y)) for x, y in colors], clock_color_fix_h
    else:
        return [rgb_to_hex(*hsl_to_rgb(h, y, x)) for x, y in colors], clock_color_fix_h

# Gets the colors of the points, using a 1d cycle through all hues
# fixing saturation at 1 and lightness 0.5 (like the primary colors have)
def get_colors_1d():
    colors = [x / 2048 for x in range(2048)]
    offset = random.number(0, 2047)
    colors = [colors[(k + offset) % 2048] for k in range(2048)]
    clock_color_0 = "#000"
    return [rgb_to_hex(*hsl_to_rgb(x, 1, 0.5)) for x in colors], clock_color_0

def main(config):
    # Get config information
    location = config.get("location")
    twenty_four_hour = config.get("24hour", DEFAULT_TWENTY_FOUR_HOUR)
    blink = config.get("blink", DEFAULT_BLINK)
    background_color = config.get("background", DEFAULT_BACKGROUND_COLOR)
    display_clock = config.get("display", DEFAULT_DISPLAY_CLOCK)

    # set time zone
    location = json.decode(location) if location else {}
    timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))
    now = time.now().in_location(timezone)

    # get the cycle of points and randomly get one of the options for color cycles
    points = get_points()
    option = random.number(0, 11)
    if option in range(0, 3):
        colors, clock_color = get_colors_3d()
    elif option in range(3, 10):
        colors, clock_color = get_colors_2d()
    else:
        colors, clock_color = get_colors_1d()

    # Sets up clock display, depending on config options, including blinking, if set
    if twenty_four_hour:
        clock_renderA = render.Box(child = render.Text(
            content = (now.format("15:04")),
            font = "10x20",
            color = clock_color,
        ))
        if blink:
            clock_renderB = render.Box(child = render.Text(
                content = (now.format("15 04")),
                font = "10x20",
                color = clock_color,
            ))
        else:
            clock_renderB = render.Box(child = render.Text(
                content = (now.format("15:04")),
                font = "10x20",
                color = clock_color,
            ))

    else:
        clock_renderA = render.Box(child = render.Text(
            content = (now.format("3:04")),
            font = "10x20",
            color = clock_color,
        ))
        if blink:
            clock_renderB = render.Box(child = render.Text(
                content = (now.format("3 04")),
                font = "10x20",
                color = clock_color,
            ))
        else:
            clock_renderB = render.Box(child = render.Text(
                content = (now.format("3:04")),
                font = "10x20",
                color = clock_color,
            ))

    frames = []
    frame = render.Box(color = background_color)

    for k in range(2048):
        if k % CHUNK == 0:  # When new frame in animation is actually made
            if display_clock:  # separator blinks every second if option is set
                if (k // CHUNK * DELAY // 1000) % 2 == 0:
                    frames.append(render.Stack(children = [frame, clock_renderA]))
                else:
                    frames.append(render.Stack(children = [frame, clock_renderB]))
            else:
                frames.append(frame)
        x, y = points[k]
        color = colors[k]
        frame = render.Stack(children = [frame, render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = color))])

    # After animation is finished, pauses in completed image
    # for the remainder of the 15 seconds
    for i in range(2048 // CHUNK + 1, 15000 // DELAY):
        if display_clock:
            if (i * DELAY // 1000) % 2 == 0:
                frames.append(render.Stack(children = [frame, clock_renderA]))
            else:
                frames.append(render.Stack(children = [frame, clock_renderB]))
        else:
            frames.append(frame)

    return render.Root(
        delay = DELAY,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "background",
                name = "Background Color",
                desc = "Background Color at start.",
                icon = "brush",
                default = DEFAULT_BACKGROUND_COLOR,
            ),
            schema.Toggle(
                id = "display",
                name = "Display Clock",
                desc = "Allow clock to be displayed.",
                icon = "clock",
                default = DEFAULT_DISPLAY_CLOCK,
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour clock",
                desc = "Enable a 24 hour clock.",
                icon = "clock",
                default = DEFAULT_TWENTY_FOUR_HOUR,
            ),
            schema.Toggle(
                id = "blink",
                name = "Blinking Seperator",
                desc = "Enables colon seperator blinking.",
                icon = "clock",
                default = DEFAULT_BLINK,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
        ],
    )

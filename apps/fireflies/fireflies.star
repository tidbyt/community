# Fireflies Applet
# Summary: Moving and flashing fireflies
# Description: Display moving and flashing fireflies with or without the time
# Author: J. Keybl

load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Tidbyt Constants
WIDTH, HEIGHT, HEIGHT_CLOCK = 64, 32, 26

# Colors
YELLOW, GREEN, ORANGE_RED, BLUE = "#FFFF00", "#ADFF2F", "#FF4500", "#0000FF"

# Firefly Properties
N_FIREFLIES, MAX_FIREFLIES, DELTA_LIGHTNESS, LIGHT_UP, MAX_LIGHTNESS = 10, 50, 14, 14, 70

# Animation Properties
DELAY = 250  # Delay between frames in milliseconds
DURATION_SECONDS = 15  # Total animation duration in seconds
N_FRAMES = DURATION_SECONDS * 1000 // DELAY  # Number of frames in the animation

# Time Settings
DEFAULT_LOCATION = {"lat": 38.8951, "lng": -77.0364, "locality": "Washington, D.C.", "timezone": "America/New_York"}

# Firefly Indices
# 0: x-position, 1: y-position, 2: hue, 3: lightness
FIREFLY_X, FIREFLY_Y, FIREFLY_HUE, FIREFLY_LIGHTNESS = range(4)

# Data Indices For Each Firefly
# 0: Offset for x location, 1: Offset for y location, 2: Period of the sinusoidal formulas representing the x and y coordinates
# 3: Semi-major axis value, 4: Semi-minor axis value, 5: Time offset within the elliptical period, 6: Ellipse rotation angle in degrees
# 7: Index offset for the lightness, 8: Index for lightness graph where y-values begin to increase from 0
# 9: Hue value (0 <= hue < 360 in degrees), 10: Determines if firefly ever turns off or not
DATA_X_OFFSET, DATA_Y_OFFSET, DATA_PERIOD, DATA_A, DATA_B, DATA_TIME_OFFSET, DATA_ROTATE, DATA_LIGHTNESS_OFFSET, DATA_I0, DATA_HUE, DATA_LIGHTNESS_ON_OFF = range(11)

# Display Text Properties
TEXT_FONT, FONT_HEIGHT, RIGHT_ALIGN, LEFT_ALIGN, CENTER_ALIGN, TIME_COLOR = "CG-pixel-3x5-mono", 5, "right", "left", "center", "#405678"

def main(config):
    show_clock = config.bool("show_clock", False)
    color = config.str("color", YELLOW)
    hue, _, _ = hex_rgb_to_hsl(color)
    n_fireflies = int(config.get("n_fireflies", MAX_FIREFLIES))
    set = int(config.get("set", 1))
    speed = int(config.get("speed", 1))
    delta_lightness = int(config.get("glow", DELTA_LIGHTNESS))
    rnd_color = config.bool("rnd_color", False)
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc["timezone"]

    fireflies = [[0, 0, 0, 0] for _ in range(MAX_FIREFLIES)]
    now = time.now().in_location(timezone)
    sec_since_midnight = seconds_since_midnight(now)
    if delta_lightness == 2:
        N_lightness = 70
    elif delta_lightness == 7:
        N_lightness = 35
    else:
        N_lightness = 16
    firefly_data = get_firefly_data(set)

    frames = []
    for t in range(N_FRAMES):
        update_fireflies(fireflies, firefly_data, n_fireflies, sec_since_midnight, t, hue, rnd_color, delta_lightness, N_lightness, show_clock, speed)
        frames.append(render_frame(generate_screen(fireflies), show_clock, timezone))

    return render_animation(frames)

def update_fireflies(fireflies, firefly_data, n_fireflies, sec_since_midnight, t, hue, rnd_color, delta_lightness, N_lightness, show_clock, speed):
    for f in range(n_fireflies):
        tt = sec_since_midnight + t * DELAY / 1000 + firefly_data[f][DATA_TIME_OFFSET]
        theta = 2 * 3.141592653589793 * tt / firefly_data[f][DATA_PERIOD] / speed
        x, y = calculate_position(firefly_data[f], theta)
        lightness = get_lightness(sec_since_midnight, t, firefly_data[f][DATA_LIGHTNESS_OFFSET], LIGHT_UP, delta_lightness, firefly_data[f][DATA_I0], N_lightness, firefly_data[f][DATA_LIGHTNESS_ON_OFF])

        fireflies[f][FIREFLY_X] = x
        fireflies[f][FIREFLY_Y] = y
        if check_position(x, y, show_clock):
            fireflies[f][FIREFLY_HUE] = firefly_data[f][DATA_HUE] if rnd_color else hue
            fireflies[f][FIREFLY_LIGHTNESS] = lightness
        else:
            fireflies[f][FIREFLY_LIGHTNESS] = 0

def calculate_position(data, theta):
    x = data[DATA_A] * math.cos(theta)
    y = data[DATA_B] * math.sin(theta)

    rotation_angle = data[DATA_ROTATE]
    if rotation_angle != 0.0:
        rotation_angle /= 1.57079633  # Equivalent to PI/2 - convert to radians
        cos_angle = math.cos(rotation_angle)
        sin_angle = math.sin(rotation_angle)
        x, y = x * cos_angle - y * sin_angle, x * sin_angle + y * cos_angle

    x += data[DATA_X_OFFSET]
    y += data[DATA_Y_OFFSET]

    return x % WIDTH, y % HEIGHT

def get_firefly_data(set_number):
    """Retrieve firefly data based on the selected set.
        0              1              2            3       4       5                 6            7                      8        9         10
        [DATA_X_OFFSET, DATA_Y_OFFSET, DATA_PERIOD, DATA_A, DATA_B, DATA_TIME_OFFSET, DATA_ROTATE, DATA_LIGHTNESS_OFFSET, DATA_I0, DATA_HUE, DATA_LIGHTNESS_ON_OFF]"""
    firefly_sets = {
        1: [
            [12, 29, 226.0, 27, 1, 2, 2.0, 5, 8, 28, 1],
            [10, 3, 210.0, 25, 1, 2, 45.0, 2, 7, 193, 1],
            [17, 16, 273.0, 19, 1, 3, 2.0, 2, 3, 26, 0],
            [63, 5, 129.0, 15, 1, 3, 27.0, 12, 18, 187, 1],
            [24, 14, 229.0, 26, 2, 4, 15.0, 14, 16, 131, 1],
            [20, 30, 200.0, 14, 2, 0, 17.0, 13, 17, 346, 1],
            [55, 10, 216.0, 20, 4, 4, 29.0, 11, 29, 145, 1],
            [18, 21, 262.0, 29, 4, 2, 35.0, 10, 26, 127, 1],
            [40, 30, 144.0, 17, 1, 7, 36.0, 8, 11, 299, 1],
            [14, 26, 114.0, 19, 3, 5, 43.0, 11, 10, 176, 0],
            [11, 16, 160.0, 14, 4, 2, 9.0, 2, 18, 84, 0],
            [23, 4, 108.0, 12, 1, 7, 42.0, 7, 12, 207, 1],
            [59, 26, 114.0, 13, 4, 6, 18.0, 12, 29, 100, 0],
            [63, 17, 179.0, 23, 2, 3, 13.0, 3, 10, 155, 0],
            [25, 4, 165.0, 26, 3, 5, 3.0, 8, 30, 271, 1],
            [47, 31, 252.0, 25, 3, 4, 35.0, 12, 12, 290, 1],
            [56, 13, 246.0, 16, 4, 5, 24.0, 6, 24, 321, 1],
            [30, 20, 250.0, 20, 4, 2, 3.0, 7, 7, 171, 0],
            [15, 5, 102.0, 29, 3, 0, 2.0, 4, 12, 121, 1],
            [48, 10, 246.0, 16, 3, 2, 0.0, 3, 3, 293, 1],
            [51, 11, 191.0, 24, 1, 5, 42.0, 7, 10, 192, 1],
            [37, 12, 178.0, 21, 1, 4, 23.0, 11, 19, 324, 0],
            [38, 20, 284.0, 28, 2, 0, 30.0, 2, 17, 129, 1],
            [48, 16, 287.0, 12, 4, 5, 30.0, 7, 10, 234, 1],
            [20, 2, 128.0, 23, 4, 1, 18.0, 11, 30, 344, 1],
            [10, 28, 170.0, 23, 1, 5, 8.0, 6, 13, 157, 0],
            [15, 13, 240.0, 23, 3, 1, 24.0, 14, 25, 229, 1],
            [13, 5, 207.0, 18, 2, 3, 31.0, 0, 20, 24, 0],
            [60, 20, 149.0, 19, 2, 7, 21.0, 7, 14, 145, 0],
            [7, 6, 147.0, 26, 2, 4, 1.0, 12, 4, 67, 1],
            [36, 15, 196.0, 28, 4, 1, 22.0, 9, 8, 170, 0],
            [3, 14, 121.0, 14, 3, 5, 12.0, 6, 1, 284, 1],
            [56, 0, 263.0, 13, 1, 3, 33.0, 2, 20, 263, 0],
            [27, 3, 281.0, 28, 3, 4, 11.0, 4, 19, 235, 0],
            [27, 14, 185.0, 12, 4, 0, 22.0, 7, 7, 151, 1],
            [29, 26, 229.0, 19, 3, 1, 26.0, 2, 10, 133, 1],
            [15, 31, 177.0, 19, 4, 7, 43.0, 7, 10, 327, 1],
            [46, 16, 117.0, 19, 2, 5, 0.0, 0, 15, 91, 1],
            [6, 23, 128.0, 14, 1, 3, 41.0, 13, 13, 23, 1],
            [63, 1, 186.0, 12, 3, 3, 4.0, 13, 7, 76, 1],
            [60, 8, 195.0, 17, 1, 6, 9.0, 12, 0, 262, 0],
            [7, 12, 191.0, 29, 4, 3, 8.0, 1, 28, 219, 1],
            [31, 8, 114.0, 23, 2, 6, 34.0, 14, 10, 76, 1],
            [47, 28, 210.0, 16, 3, 2, 7.0, 8, 19, 174, 1],
            [37, 9, 183.0, 21, 4, 6, 4.0, 4, 5, 276, 1],
            [26, 27, 295.0, 10, 4, 3, 20.0, 14, 20, 294, 1],
            [28, 7, 149.0, 27, 2, 7, 38.0, 4, 5, 285, 1],
            [33, 3, 216.0, 27, 3, 3, 6.0, 9, 17, 140, 0],
            [44, 11, 171.0, 21, 4, 6, 42.0, 13, 21, 246, 0],
            [1, 13, 105.0, 24, 1, 4, 11.0, 9, 0, 169, 1],
        ],
        2: [
            [0, 7, 100.0, 27, 2, 4, 37.0, 12, 10, 74, 0],
            [36, 15, 142.0, 18, 3, 7, 15.0, 12, 15, 257, 1],
            [10, 7, 139.0, 26, 2, 1, 19.0, 2, 26, 279, 0],
            [52, 15, 132.0, 26, 1, 0, 36.0, 7, 6, 67, 1],
            [61, 25, 123.0, 26, 4, 1, 12.0, 10, 22, 188, 0],
            [14, 6, 96.0, 20, 4, 3, 16.0, 4, 6, 301, 0],
            [34, 27, 107.0, 17, 4, 1, 39.0, 9, 12, 300, 1],
            [59, 8, 113.0, 17, 1, 0, 13.0, 4, 9, 177, 1],
            [31, 12, 78.0, 21, 4, 7, 42.0, 9, 11, 86, 1],
            [21, 11, 116.0, 12, 3, 3, 25.0, 2, 22, 331, 0],
            [23, 5, 106.0, 23, 1, 3, 27.0, 13, 15, 337, 0],
            [1, 15, 139.0, 22, 4, 5, 43.0, 6, 17, 262, 1],
            [9, 15, 132.0, 26, 4, 3, 45.0, 5, 27, 113, 0],
            [37, 22, 103.0, 18, 3, 0, 36.0, 4, 12, 205, 1],
            [32, 13, 51.0, 16, 3, 5, 9.0, 2, 16, 85, 0],
            [26, 27, 51.0, 17, 2, 2, 8.0, 13, 1, 272, 1],
            [19, 18, 73.0, 18, 1, 5, 15.0, 9, 19, 331, 0],
            [7, 21, 125.0, 12, 2, 6, 20.0, 3, 7, 38, 0],
            [45, 12, 52.0, 10, 3, 5, 3.0, 5, 7, 149, 1],
            [7, 21, 96.0, 23, 1, 3, 20.0, 13, 16, 161, 1],
            [16, 10, 141.0, 22, 4, 3, 19.0, 0, 9, 285, 0],
            [25, 12, 88.0, 27, 3, 0, 25.0, 0, 8, 232, 1],
            [2, 18, 144.0, 22, 3, 3, 14.0, 9, 15, 31, 0],
            [30, 23, 144.0, 13, 4, 5, 16.0, 14, 8, 348, 0],
            [21, 24, 77.0, 13, 3, 4, 31.0, 7, 27, 105, 0],
            [28, 26, 84.0, 16, 4, 4, 24.0, 0, 0, 336, 1],
            [15, 7, 111.0, 18, 2, 1, 15.0, 7, 0, 115, 1],
            [18, 11, 76.0, 28, 3, 2, 11.0, 8, 15, 57, 0],
            [11, 13, 116.0, 25, 2, 4, 36.0, 9, 16, 2, 1],
            [22, 15, 99.0, 18, 2, 3, 20.0, 13, 0, 229, 0],
            [2, 10, 144.0, 12, 2, 6, 36.0, 8, 6, 58, 1],
            [61, 19, 82.0, 24, 4, 0, 43.0, 12, 2, 161, 1],
            [55, 12, 150.0, 10, 1, 0, 16.0, 4, 18, 146, 0],
            [51, 19, 125.0, 29, 3, 5, 8.0, 6, 13, 156, 1],
            [39, 6, 116.0, 13, 3, 3, 45.0, 0, 2, 22, 1],
            [63, 9, 130.0, 11, 1, 0, 15.0, 8, 0, 313, 0],
            [55, 19, 60.0, 14, 2, 3, 30.0, 6, 1, 238, 1],
            [58, 17, 76.0, 10, 3, 0, 21.0, 0, 12, 299, 0],
            [31, 25, 117.0, 20, 1, 5, 7.0, 0, 8, 21, 0],
            [62, 23, 111.0, 25, 1, 0, 16.0, 4, 25, 323, 1],
            [36, 7, 119.0, 12, 4, 1, 44.0, 9, 16, 106, 0],
            [32, 14, 66.0, 14, 4, 6, 24.0, 8, 4, 20, 0],
            [59, 23, 144.0, 14, 3, 1, 20.0, 2, 17, 185, 1],
            [33, 13, 67.0, 17, 4, 3, 14.0, 14, 16, 214, 0],
            [41, 27, 51.0, 27, 1, 7, 31.0, 3, 9, 171, 1],
            [24, 20, 76.0, 24, 4, 0, 14.0, 13, 22, 180, 1],
            [56, 26, 77.0, 15, 4, 6, 13.0, 11, 11, 98, 0],
            [39, 17, 65.0, 12, 1, 2, 23.0, 1, 21, 143, 0],
            [19, 15, 104.0, 14, 4, 7, 28.0, 6, 3, 282, 0],
            [8, 5, 64.0, 16, 2, 6, 17.0, 14, 1, 281, 1],
        ],
        3: [
            [13, 21, 53.0, 22, 3, 1, 16.0, 14, 21, 19, 0],
            [0, 19, 132.0, 29, 4, 7, 43.0, 2, 26, 76, 1],
            [26, 9, 110.0, 26, 3, 6, 8.0, 14, 23, 317, 1],
            [34, 5, 77.0, 18, 1, 6, 31.0, 14, 15, 16, 1],
            [13, 10, 56.0, 16, 3, 7, 3.0, 12, 21, 48, 1],
            [63, 9, 84.0, 21, 1, 0, 10.0, 3, 11, 93, 1],
            [57, 5, 59.0, 18, 3, 0, 31.0, 12, 19, 286, 1],
            [59, 6, 131.0, 14, 4, 3, 1.0, 6, 29, 24, 1],
            [53, 23, 124.0, 17, 1, 4, 33.0, 13, 10, 357, 1],
            [11, 24, 63.0, 15, 2, 2, 37.0, 13, 9, 293, 1],
            [13, 6, 142.0, 26, 1, 3, 23.0, 12, 28, 34, 1],
            [31, 17, 80.0, 20, 1, 5, 31.0, 12, 4, 262, 0],
            [56, 21, 119.0, 15, 3, 5, 36.0, 2, 24, 183, 1],
            [28, 21, 142.0, 16, 1, 5, 10.0, 10, 3, 142, 1],
            [18, 22, 77.0, 22, 3, 6, 38.0, 2, 16, 140, 0],
            [2, 19, 126.0, 10, 1, 0, 6.0, 9, 20, 98, 1],
            [12, 13, 68.0, 14, 3, 0, 14.0, 5, 15, 125, 1],
            [61, 21, 62.0, 26, 1, 3, 19.0, 1, 21, 50, 0],
            [25, 19, 74.0, 18, 1, 5, 40.0, 13, 29, 152, 1],
            [12, 13, 86.0, 21, 2, 1, 22.0, 1, 25, 8, 1],
            [15, 22, 135.0, 25, 3, 3, 20.0, 3, 14, 59, 0],
            [9, 17, 73.0, 17, 2, 4, 18.0, 10, 22, 244, 1],
            [46, 19, 135.0, 23, 4, 5, 34.0, 14, 26, 316, 0],
            [26, 10, 112.0, 13, 1, 6, 10.0, 8, 27, 95, 0],
            [38, 9, 77.0, 22, 4, 0, 20.0, 6, 15, 77, 1],
            [34, 18, 107.0, 18, 3, 2, 32.0, 11, 3, 106, 1],
            [52, 21, 125.0, 24, 4, 4, 0.0, 3, 19, 162, 0],
            [55, 19, 54.0, 11, 1, 3, 33.0, 7, 18, 306, 1],
            [20, 24, 108.0, 24, 3, 4, 39.0, 13, 14, 105, 1],
            [50, 24, 78.0, 25, 4, 5, 22.0, 13, 12, 54, 1],
            [18, 17, 66.0, 22, 4, 4, 21.0, 3, 22, 245, 1],
            [58, 24, 95.0, 28, 1, 5, 22.0, 0, 25, 90, 0],
            [0, 17, 50.0, 12, 3, 0, 19.0, 12, 8, 16, 0],
            [3, 18, 101.0, 17, 1, 4, 44.0, 0, 28, 92, 0],
            [26, 8, 149.0, 12, 1, 6, 32.0, 9, 20, 109, 0],
            [62, 9, 144.0, 20, 3, 5, 7.0, 14, 21, 174, 0],
            [29, 21, 105.0, 16, 1, 3, 6.0, 0, 29, 222, 1],
            [63, 7, 98.0, 20, 3, 2, 10.0, 0, 23, 93, 0],
            [17, 23, 85.0, 14, 4, 3, 20.0, 7, 14, 147, 1],
            [41, 27, 138.0, 23, 4, 3, 29.0, 5, 18, 321, 0],
            [22, 7, 134.0, 25, 2, 2, 17.0, 14, 19, 187, 0],
            [52, 20, 95.0, 18, 3, 7, 0.0, 0, 17, 224, 0],
            [52, 27, 71.0, 17, 4, 4, 10.0, 6, 14, 206, 0],
            [53, 9, 62.0, 10, 1, 5, 41.0, 0, 12, 10, 1],
            [24, 16, 108.0, 10, 3, 3, 22.0, 7, 21, 327, 1],
            [40, 5, 119.0, 13, 2, 3, 45.0, 7, 30, 317, 0],
            [15, 10, 52.0, 24, 3, 1, 35.0, 13, 11, 279, 1],
            [39, 13, 135.0, 26, 4, 2, 30.0, 13, 2, 107, 0],
            [28, 17, 72.0, 15, 3, 7, 0.0, 1, 3, 349, 1],
        ],
        4: [
            [41, 14, 134.0, 10, 2, 6, 5.0, 9, 17, 200, 0],
            [33, 26, 90.0, 29, 2, 5, 8.0, 0, 0, 310, 1],
            [51, 17, 70.0, 19, 3, 2, 24.0, 5, 11, 52, 1],
            [21, 7, 118.0, 10, 2, 7, 20.0, 1, 3, 216, 1],
            [54, 21, 134.0, 16, 2, 2, 25.0, 2, 18, 192, 1],
            [20, 7, 148.0, 15, 4, 4, 0.0, 6, 22, 352, 1],
            [41, 24, 94.0, 10, 1, 2, 21.0, 0, 21, 269, 1],
            [45, 26, 94.0, 13, 4, 3, 11.0, 12, 21, 218, 1],
            [36, 9, 110.0, 16, 3, 3, 17.0, 0, 19, 174, 1],
            [42, 13, 110.0, 15, 2, 6, 39.0, 8, 6, 88, 0],
            [46, 18, 67.0, 11, 2, 0, 13.0, 13, 3, 304, 1],
            [47, 12, 109.0, 11, 2, 7, 43.0, 3, 11, 203, 0],
            [13, 5, 86.0, 17, 4, 6, 44.0, 7, 4, 214, 0],
            [39, 10, 131.0, 18, 4, 3, 45.0, 4, 5, 222, 0],
            [30, 18, 101.0, 22, 3, 4, 16.0, 1, 3, 106, 0],
            [60, 24, 68.0, 17, 3, 2, 16.0, 11, 10, 172, 1],
            [12, 5, 74.0, 21, 2, 5, 20.0, 1, 22, 5, 0],
            [8, 17, 128.0, 20, 2, 6, 18.0, 13, 25, 318, 0],
            [60, 27, 125.0, 12, 1, 7, 12.0, 3, 1, 236, 0],
            [46, 8, 123.0, 12, 4, 3, 44.0, 9, 14, 17, 0],
            [55, 12, 75.0, 27, 1, 4, 30.0, 10, 27, 248, 1],
            [38, 11, 76.0, 24, 1, 4, 25.0, 4, 8, 175, 1],
            [50, 15, 88.0, 24, 2, 6, 39.0, 1, 2, 275, 0],
            [8, 18, 71.0, 11, 3, 0, 39.0, 7, 19, 251, 1],
            [3, 10, 94.0, 28, 1, 7, 8.0, 13, 13, 70, 0],
            [58, 26, 150.0, 20, 4, 3, 37.0, 2, 25, 137, 1],
            [50, 16, 138.0, 21, 1, 6, 6.0, 1, 27, 298, 0],
            [52, 21, 99.0, 25, 2, 1, 34.0, 1, 6, 226, 0],
            [1, 12, 72.0, 26, 2, 4, 33.0, 12, 27, 166, 0],
            [60, 26, 80.0, 11, 4, 0, 36.0, 14, 11, 197, 1],
            [0, 21, 55.0, 20, 4, 6, 39.0, 8, 14, 86, 0],
            [40, 26, 60.0, 15, 2, 6, 39.0, 7, 9, 216, 1],
            [48, 26, 69.0, 23, 1, 0, 28.0, 14, 17, 74, 1],
            [52, 11, 80.0, 21, 1, 2, 8.0, 14, 22, 31, 0],
            [27, 18, 79.0, 23, 3, 4, 26.0, 14, 2, 355, 0],
            [37, 20, 111.0, 20, 2, 1, 37.0, 12, 11, 213, 1],
            [13, 12, 112.0, 18, 1, 0, 41.0, 4, 18, 26, 0],
            [36, 27, 83.0, 18, 1, 0, 16.0, 4, 15, 351, 1],
            [44, 17, 55.0, 15, 1, 1, 25.0, 7, 0, 357, 1],
            [56, 14, 85.0, 26, 2, 1, 12.0, 4, 13, 290, 0],
            [28, 22, 120.0, 20, 4, 0, 5.0, 12, 12, 186, 1],
            [41, 6, 66.0, 18, 4, 2, 39.0, 10, 20, 168, 0],
            [2, 13, 115.0, 15, 3, 6, 36.0, 10, 18, 79, 1],
            [24, 6, 124.0, 27, 4, 2, 41.0, 11, 24, 294, 1],
            [32, 27, 91.0, 26, 3, 6, 4.0, 2, 21, 139, 0],
            [45, 7, 55.0, 15, 4, 1, 25.0, 2, 18, 321, 1],
            [52, 20, 111.0, 12, 3, 3, 37.0, 0, 14, 209, 1],
            [25, 20, 100.0, 16, 2, 2, 7.0, 8, 0, 263, 1],
            [33, 16, 66.0, 22, 3, 4, 17.0, 12, 28, 139, 0],
            [12, 22, 86.0, 25, 2, 1, 8.0, 5, 7, 36, 1],
        ],
    }

    # Return the requested set or default to set 1 if the set number is invalid.
    return firefly_sets.get(set_number, firefly_sets[1])

def seconds_since_midnight(current_time):
    seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
    t_mod = (seconds + 14) // 15 * 15
    return t_mod

def calculate_index(sec_since_midnight, delta_lightness):
    return int(sec_since_midnight * 1000 / DELAY) % delta_lightness

def get_lightness(sec_since_midnight, t, idx_offset, delta_lightness_1, delta_lightness_2, i0, N_lightness, darkness):
    # Calculate the total lightness steps
    total_lightness_steps = MAX_LIGHTNESS * (1 / delta_lightness_1 + 1 / delta_lightness_2)
    N_lightness = i0 + int(total_lightness_steps)

    # Calculate the index
    idx = (calculate_index(sec_since_midnight, N_lightness) + t + idx_offset) % N_lightness

    # Define thresholds
    im = i0 + MAX_LIGHTNESS / delta_lightness_1
    iz = N_lightness
    if idx >= i0 and idx < im:
        return delta_lightness_1 * (idx - i0)
    elif idx >= im and idx < iz:
        return delta_lightness_2 * (i0 - idx) + MAX_LIGHTNESS * (1 + delta_lightness_2 / delta_lightness_1)
    else:
        return darkness * 5

def check_position(x, y, show_clock):
    if not show_clock or y < HEIGHT_CLOCK or x < 15 or x > 48:
        return True
    return False

def generate_screen(fireflies):
    arr = [["#000000" for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for firefly in fireflies:
        if firefly[FIREFLY_LIGHTNESS] > 0:
            arr[int(firefly[1])][int(firefly[0])] = hsl_to_hex_rgb(firefly[FIREFLY_HUE], 1.0, firefly[FIREFLY_LIGHTNESS] / 100)
    return arr

def render_frame(frame, show_clock, timezone):
    children = [render_column(frame)]
    if show_clock:
        children.append(render_clock(timezone))
    return render.Stack(children = children)

def render_column(frame):
    rows = []
    for row in frame:
        rows.append(render_row(row))
    return render.Column(children = rows)

def render_row(row):
    cells = []
    for cell in row:
        cells.append(render_cell(cell))
    return render.Row(children = cells)

def render_cell(cell):
    return render.Box(width = 1, height = 1, color = cell)

def render_clock(timezone):
    return render.Padding(
        pad = (0, HEIGHT_CLOCK, 0, 0),
        child = render.Box(
            width = WIDTH,
            height = FONT_HEIGHT,
            child = render.WrappedText(
                content = humanize.time_format("K:mm aa", time.now().in_location(timezone)),
                font = TEXT_FONT,
                color = TIME_COLOR,
                align = CENTER_ALIGN,
                width = WIDTH,
            ),
        ),
    )

def render_animation(frames):
    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def hex_rgb_to_hsl(hex_color):
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return rgb_to_hsl(r, g, b)

def hsl_to_hex_rgb(h, s, l):
    r, g, b = hsl_to_rgb(h, s, l)
    return "#" + int_to_hex(r) + int_to_hex(g) + int_to_hex(b)

def rgb_to_hsl(r, g, b):
    r /= 255.0
    g /= 255.0
    b /= 255.0
    max_color = max(r, g, b)
    min_color = min(r, g, b)
    l = (max_color + min_color) / 2.0
    if max_color == min_color:
        return 0, 0, l
    d = max_color - min_color
    s = d / (2.0 - max_color - min_color) if l > 0.5 else d / (max_color + min_color)
    if max_color == r:
        h = (g - b) / d + (6 if g < b else 0)
    elif max_color == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    h /= 6
    return h * 360, s, l

def hsl_to_rgb(h, s, l):
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2

    if h >= 0 and h < 60:
        r, g, b = c, x, 0
    elif h >= 60 and h < 120:
        r, g, b = x, c, 0
    elif h >= 120 and h < 180:
        r, g, b = 0, c, x
    elif h >= 180 and h < 240:
        r, g, b = 0, x, c
    elif h >= 240 and h < 300:
        r, g, b = x, 0, c
    elif h >= 300 and h < 360:
        r, g, b = c, 0, x
    else:
        r, g, b = 0, 0, 0  # Just in case h is outside the expected range
    return int((r + m) * 255), int((g + m) * 255), int((b + m) * 255)

def int_to_hex(value):
    hex_digits = "0123456789ABCDEF"
    return hex_digits[(value // 16) % 16] + hex_digits[value % 16]

def get_schema():
    options_number = [
        schema.Option(display = str(i), value = str(i))
        for i in range(5, MAX_FIREFLIES + 5, 5)
    ]
    options_duration = [
        schema.Option(display = "Long", value = "2"),
        schema.Option(display = "Regular", value = "7"),
        schema.Option(display = "Short", value = "14"),
    ]
    options_sets = [
        schema.Option(display = "1", value = "1"),
        schema.Option(display = "2", value = "2"),
        schema.Option(display = "3", value = "3"),
        schema.Option(display = "4", value = "4"),
    ]
    options_speed = [
        schema.Option(display = "Fast", value = "1"),
        schema.Option(display = "Normal", value = "2"),
        schema.Option(display = "Moderate", value = "4"),
        schema.Option(display = "Slow", value = "8"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "n_fireflies",
                name = "Num Fireflies",
                desc = "Select number of fireflies.",
                icon = "arrowsToDot",
                default = options_number[5].value,
                options = options_number,
            ),
            schema.Dropdown(
                id = "glow",
                name = "Glow Duration",
                desc = "Select how long fireflies glow.",
                icon = "lightbulb",
                default = options_duration[0].value,
                options = options_duration,
            ),
            schema.Dropdown(
                id = "set",
                name = "Firefly Set",
                desc = "Select the fireflies set.",
                icon = "dna",
                default = options_sets[0].value,
                options = options_sets,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Firefly Speed",
                desc = "Select the speed of fireflies.",
                icon = "jetFighter",
                default = options_speed[1].value,
                options = options_speed,
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Select color of fireflies.",
                icon = "brush",
                default = YELLOW,
                palette = [YELLOW, GREEN, ORANGE_RED, BLUE],
            ),
            schema.Toggle(
                id = "rnd_color",
                name = "Random Colors",
                desc = "Enable random colors for fireflies.",
                icon = "sliders",
                default = False,
            ),
            schema.Toggle(
                id = "show_clock",
                name = "Show Clock",
                desc = "Enable displaying current time.",
                icon = "sliders",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for local time.",
            ),
        ],
    )

# Possible additions
# - POI Nudging
# - Color Cycling
#
# Not going to do
# - Zoom animation; poor quality, high chance of time out
#
load("math.star", "math")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

START_TIME = time.now().unix  # Timestamp at start of app
POI_MAX_TIME = 3  # Go with best POI if max time elapse
ADAPTIVE_AA_MAX_TIME = 20  # Stop Adaptive AA if max time elapsed
NORMALIZE_MAX_TIME = 28  # Skip normalization if max time elapsed
CONTRAST_MAX_TIME = 29  # Skip contrast correction if max time elapsed
GAMMA_MAX_TIME = 29  # Skip gamma correction if max time elapsed

MIN_ITER = 150  # Minimum iterations
ZOOM_TO_ITER = 1.0  # 1.0 standard, less for faster calc, more for better accuracy
JULIA_ZOOM = 1.0  # 0.5 = low detail, but wide view; 2 = high detail, right up in da face
ESCAPE_THRESHOLD = 4.0  # 4.0 standard, less for faster calc, but worse accuracy
DISPLAY_WIDTH = 64  # Tidbyt is 64 pixels wide
DISPLAY_HEIGHT = 32  # Tidbyt is 32 pixels high
CTRX, CTRY = -0.75, 0  # Mandelbrot center
MINX, MINY, MAXX, MAXY = -2.5, -0.875, 1.0, 0.8753  # Bounds to use for mandelbrot set
BLACK_COLOR = "#000000"  # Shorthand for black color
MAX_INT = int(math.pow(2, 63)) - 2  # Not truly the max, but the largest that will work with math.random() and range()
BLACK_PIXEL = render.Box(width = 1, height = 1, color = BLACK_COLOR)  # Pregenerated 1x1 pixel black box
POI_GRID_X = 8  # When exploring POIs, divides area into XY grid
POI_GRID_Y = 4  # and checks random pixel in grid cell
POI_ZOOM = DISPLAY_WIDTH / POI_GRID_X  # This represents magnification of ...
POI_MAX_ZOOM = 10000  # Max magnification depth for POI search
BRIGHTNESS_MIN = 16  # For brightness normalization, don't bring channel below this

MAX_ADAPTIVE_PASSES = 32  # Max number of passes for adaptive AA
ADAPTIVE_AA_START_RADIUS = 0.5  # Adaptive AA oversamples this distance away from the pixel
ADAPTIVE_AA_INC_RADIUS = 0.01  # Adaptive AA increases the distance this amount per pass
ADAPTIVE_AA_START_ANGLE = 90  #random.number(0, 360) # Adaptive AA initial angle for oversample
ADAPTIVE_AA_INC_ANGLE = 137.5  # Adaptive AA changes the angle by this amount every pass

DEFAULT_BRIGHTNESS = True  # Adjusts for maximal brightness and also brings down darks to no lower than BRIGHTNESS_MIN
DEFAULT_CONTRAST = True  # Adjusts for maximal contrast
DEFAULT_JULIA = False  # True to display (whole) julia set [faster]; false to display (zoomed in) mandelbrot
DEFAULT_GAMMA = "1.0"  # Gamma correction, 1.0 = off; I did not find this to help much
DEFAULT_OVERSAMPLE = "2"  # Oversample style (1 or more)
DEFAULT_GRADIENT = "random"  # Color palette selection (random or named PREDEFINED_GRADIENT)
DEFAULT_ADAPTIVE_AA = True  # Additional AA passes as time allows

GRADIENT_SCALE_FACTOR = 1.55  # 1.55 = standard, less for more colors zoomed in, more for few colors zoomed in
RANDOM_GRADIENT_STEPS = 32  # Number of colors in a randomize gradient
PREDEFINED_GRADIENTS_NUM_CYCLES = 4  # Number of times to repeat the colors in the gradient
PREDEFINED_GRADIENTS = {
    "neon-rose": ((255, 0, 0), (255, 0, 255)),
    "spring-lime": ((0, 255, 0), (255, 255, 0)),
    "seafoam": ((0, 255, 0), (0, 255, 255)),
    "ocean-wave": ((0, 0, 255), (0, 255, 255)),
    "electric-violet": ((0, 0, 255), (255, 0, 255)),
    "autumn-glow": ((0, 255, 0), (255, 255, 0), (255, 165, 0)),
    "twilight": ((0, 255, 255), (0, 0, 255), (128, 0, 128)),
    "spectrum": ((255, 0, 0), (255, 127, 0), (255, 255, 0), (0, 255, 0), (0, 0, 255), (75, 0, 130), (148, 0, 211)),
    "lavender-fields": ((255, 182, 193), (230, 230, 250)),
    "midnight": ((0, 0, 128), (0, 0, 255), (75, 0, 130)),
    "arctic-sky": ((135, 206, 250), (0, 191, 255), (70, 130, 180)),
    "desert-sands": ((244, 164, 96), (210, 180, 140), (255, 228, 196)),
    "forest-dusk": ((34, 139, 34), (85, 107, 47), (139, 69, 19)),
    "solar-flare": ((255, 69, 0), (255, 140, 0), (255, 215, 0)),
    "iceberg": ((173, 216, 230), (224, 255, 255), (240, 248, 255)),
    "berry-blend": ((128, 0, 128), (153, 50, 204), (186, 85, 211)),
    "volcanic": ((105, 105, 105), (255, 69, 0), (139, 0, 0)),
    "red": ((80, 64, 0), (255, 0, 64)),
    "green": ((0, 80, 64), (64, 255, 0)),
    "blue": ((64, 0, 80), (0, 64, 255)),
    "grey": ((80, 80, 80), (255, 255, 255)),
}  # Predefined color gradients to select instead of using random colors

# This is the main main, no other mains are more main than this main
def main(config):
    seed = int(config.str("seed", time.now().unix))
    random.seed(seed)
    print("Using random seed:", seed)
    app = {"config": config}

    # Calculating oversampling parameters
    app["adaptive"] = config.bool("adaptive", DEFAULT_ADAPTIVE_AA)
    oversample_str = config.str("oversample", DEFAULT_OVERSAMPLE)
    if not is_int(oversample_str):
        return err("Unknown oversample value: %s" % oversample_str)
    app["oversample"] = int(oversample_str)
    print("Oversample:", oversample_str + "X", " ... AdaptiveAA:", ["disabled", "enabled"][int(app["adaptive"])])

    # Calculate internal map dimensions
    app["map_width"] = DISPLAY_WIDTH * app["oversample"]  # Pixels samples per row
    app["map_height"] = DISPLAY_HEIGHT * app["oversample"]  # Pixel samples per column
    app["max_pixel_x"] = app["map_width"] - 1  # Maximum sample for x
    app["max_pixel_y"] = app["map_height"] - 1  # Maximum sample for y

    # Generate a color gradient
    gradient_str = config.str("gradient", DEFAULT_GRADIENT)
    if gradient_str != "random" and gradient_str not in PREDEFINED_GRADIENTS:
        return err("Unrecognized gradient type: {}".format(gradient_str))
    print("Gradient selected:", gradient_str)
    app["gradient"] = generate_gradient(gradient_str)

    # Determine if we should normalize brightness
    app["brightness"] = config.bool("brightness", True)
    print("Brightness normalization", ["disabled", "enabled"][int(app["brightness"])])

    # Determine if we should perform contrast correction
    app["contrast"] = config.bool("contrast", True)
    print("Contrast correction", ["disabled", "enabled"][int(app["contrast"])])

    # Determine how much gamma correction
    gamma_str = config.str("gamma", DEFAULT_GAMMA)
    if is_float(gamma_str) and float(gamma_str) >= 1.0:
        app["gamma"] = float(gamma_str)
        print("Gamma correction", ["disabled", "enabled"][int(app["gamma"] < 1.0)])
    else:
        return err("Gamma must be a floating point number >= 1.0")

    if config.bool("julia", DEFAULT_JULIA):  # Is this a julia or mandelbrot fractal
        print("Julia set enabled")

    # Look for manual POI
    poi_x = config.str("x", None)
    poi_y = config.str("y", None)
    poi_zoom = config.str("zoom", None)
    poi_args_supplied = int(is_float(poi_x)) + int(is_float(poi_y)) + int(is_float(poi_zoom))
    if poi_args_supplied == 1 or poi_args_supplied == 2:
        return err("Must supply numbers for x+y+zoom to specify POI")

    # Determine what POI to zoom onto
    if poi_args_supplied == 0:
        # Choose a point of interest
        choose_poi(app)
    else:
        # One was given to us
        app["target"] = float(poi_x), float(poi_y)
        app["zoom_level"] = float(poi_zoom)
        app["max_iter"] = zoom_to_iter(app["zoom_level"])

    # After the POI is generated, an unknown number of rnd() calls were made
    # Reset the random seed so the results are otherwise predictable!
    random.seed(seed)

    # Slight changes for julia set
    app["c"] = None, None
    app["poi_zoom_level"] = app["zoom_level"]
    if config.bool("julia", DEFAULT_JULIA):
        app["c"] = app["target"]
        app["target"] = 0.0, 0.0
        app["zoom_level"] = JULIA_ZOOM
        app["max_iter"] = zoom_to_iter(JULIA_ZOOM)
    else:  # Mandelbrot
        print("Zoom Level:", app["zoom_level"])

    # Generate the animation with all frames
    frames = get_frames(app)

    # Generate root object
    root = render.Root(
        delay = 15000,
        child = render.Box(render.Animation(frames)),
    )

    # Profiling is fun
    print("Elapsed time:", time.now().unix - START_TIME)

    return root

# Ya know, it uh, normalizes ... the brightness
# Makes the darks darker and the brights brighter, to a tpoint
def normalize_brightness(map):
    # Determine low and high channel values
    lowest_channel = 255
    highest_channel = 0
    for index in range(len(map["data"])):
        channels = map["data"][index]["color"]
        for c in range(len(channels)):
            if channels[c] < lowest_channel:
                lowest_channel = channels[c]
            elif channels[c] > highest_channel:
                highest_channel = channels[c]

    if highest_channel == 0:
        print("Can't brighten pitch black nothingness")
        return

    # Determine adjustment. Don't force brightness below minimum amount.
    subtraction = 0
    if lowest_channel > BRIGHTNESS_MIN:
        subtraction = lowest_channel - BRIGHTNESS_MIN
    multiplier = (255.0 + subtraction) / highest_channel

    print("Normalizing brightness ... Lowest:", lowest_channel, "Highest:", highest_channel, "Subtract:", subtraction, "Mult:", multiplier)

    # Normalize data
    for index in range(len(map["data"])):
        channels = list(map["data"][index]["color"])
        for c in range(len(channels)):
            channels[c] = min(255, int(channels[c] * multiplier - subtraction))
        map["data"][index]["color"] = channels

# Apply gamma correction
def gamma_correction(map, amount):
    print("Applying gamma correction of", amount)

    for i in range(len(map["data"])):
        channels = list(map["data"][i]["color"])
        for c in range(len(channels)):
            channels[c] = min(255, int(math.pow(channels[c] / 255.0, 1 / amount) * 255))
        map["data"][i]["color"] = channels

# Apply contrast correction
def contrast_correction(map, min_scale = 0, max_scale = 255):
    print("Correcting contrast")

    # Separate the RGB channels
    reds = [record["color"][0] for record in map["data"]]
    greens = [record["color"][1] for record in map["data"]]
    blues = [record["color"][2] for record in map["data"]]

    # Find the min and max values for each channel
    min_r, max_r = min(reds), max(reds)
    min_g, max_g = min(greens), max(greens)
    min_b, max_b = min(blues), max(blues)

    # Avoid division by zero
    range_r = max_r - min_r if max_r != min_r else 1
    range_g = max_g - min_g if max_g != min_g else 1
    range_b = max_b - min_b if max_b != min_b else 1

    # Function to stretch one color channel
    def stretch_channel(value, min_val, range_val):
        return min(255, int(((value - min_val) * (max_scale - min_scale) / range_val) + min_scale))

    # Clamp function to keep colors within the original gradient
    def clamp_channel(value, original_min, original_max):
        return max(min(value, original_max), original_min)

    # Apply contrast stretching and clamp to original palette range
    for index in range(len(map["data"])):
        record = map["data"][index]
        record["color"] = (
            clamp_channel(stretch_channel(record["color"][0], min_r, range_r), min_r, max_r),
            clamp_channel(stretch_channel(record["color"][1], min_g, range_g), min_g, max_g),
            clamp_channel(stretch_channel(record["color"][2], min_b, range_b), min_b, max_b),
        )

# Renders one or more animation frames, suitable for sending to an Animation
# object. Well, it used to do multiple, now it just renders one.
def get_frames(app):
    print("Generating frame with max_iter:", app["max_iter"])

    # This was a loop for an animation, but the animation takes too long
    # to render on Tidbyt servers with any degree of quality
    frames = list()  # List to store frames of the animation
    map = render_fractal(app, app["target"][0], app["target"][1])
    map = apply_after_effects(app, map)
    tidbytMap = render_tidbyt(map)
    frames.append(tidbytMap)
    return frames

# Correct issues with brightness, contrast, and gamma
def apply_after_effects(app, map):
    brightness = app["brightness"]
    if not brightness or time.now().unix - START_TIME > NORMALIZE_MAX_TIME:
        return map
    normalize_brightness(map)

    contrast = app["contrast"]
    if not contrast or time.now().unix - START_TIME > CONTRAST_MAX_TIME:
        return map
    contrast_correction(map)

    gamma = app["gamma"]
    if gamma <= 1.0 or time.now().unix - START_TIME > GAMMA_MAX_TIME:
        return map
    gamma_correction(map, gamma)

    return map

# Returns a link to gart.nz, which you could use to look at the fractal online
def get_link(app):
    x = app["target"][0]
    y = app["target"][1]
    iter = app["max_iter"]
    zoom = app["poi_zoom_level"]

    # Julia set fix
    if app["c"] != (0.0, 0.0):
        x, y = app["c"][0], app["c"][1]

    return get_link_from(x, y, iter, zoom)

# Makes for easier debugging to compare results to an existing renderer
def get_link_from(x, y, iter, zoom):
    return "https://mandel.gart.nz/?Re={}&Im={}&iters={}&zoom={}&colourmap=5&maprotation=0&axes=0&smooth=0".format(
        x,
        y,
        iter,
        str(int(zoom * 600)),
    )

# Converts a "zoom level" to a maximum number of iterations.
# As you zoom in, you need more iterations to clearly render the boundary.
def zoom_to_iter(zoom):
    return int(MIN_ITER + max(0, zoom * ZOOM_TO_ITER))

# Chooses a respectable point of interest to render
def choose_poi(app):
    print("Determining point of interest")
    x, y, best, zoom = find_poi()

    # Make it our target
    print("Settled on POI:", x, y, "score:", best)
    app["target"] = x, y
    app["zoom_level"] = zoom
    app["max_iter"] = zoom_to_iter(zoom)

# Searches through many potential points of interest
def find_poi():
    end_time = START_TIME + POI_MAX_TIME
    bestx, besty, best_score, best_zoom = 0, 0, 0, 1
    search_areas = []
    search_areas.append((MINX, MINY, MAXX, MAXY, 1))

    for _ in range(MAX_INT):  # Woe, there be no while loops
        if time.now().unix > end_time:
            break
        if len(search_areas) == 0:
            break

        minx, miny, maxx, maxy, zoom = search_areas.pop()
        iter_limit = zoom_to_iter(zoom)

        # Grid up area
        cell_width = (maxx - minx) / POI_GRID_X
        cell_height = (maxy - miny) / POI_GRID_Y
        cell_width_half = cell_width / 2.0
        cell_height_half = cell_height / 2.0
        score = 0
        best_iter_in_grid = 0

        # Divide area into grid cells and evaluate each
        for y in range(POI_GRID_Y):
            if time.now().unix > end_time:
                break
            for x in range(POI_GRID_X):
                if time.now().unix > end_time:
                    break
                sampx = (rnd() - 0.5 + x) * cell_width + minx
                sampy = (rnd() - 0.5 + y) * cell_height + miny
                iter, _ = fractal_calc(sampx, sampy, iter_limit)
                if iter >= iter_limit:  # Did not escape
                    continue
                if zoom > POI_MAX_ZOOM:  # At max zoom level
                    continue

                new_min_x = sampx - cell_width_half
                new_min_y = sampy - cell_height_half
                new_max_x = sampx + cell_width_half
                new_max_y = sampy + cell_height_half
                new_zoom = zoom * POI_ZOOM
                score += iter

                # Only zoom in if we didn't find a better candidate in the grid
                if iter > best_iter_in_grid:
                    best_iter_in_grid = iter
                    search_areas.append((new_min_x, new_min_y, new_max_x, new_max_y, new_zoom))

        # Look at the combined score of all the grid cells
        # If this the best one so far, note it!
        if score > best_score:
            bestx, besty, best_score, best_zoom = (minx + maxx) / 2, (maxy + miny) / 2, score, zoom
            print("Found better POI:", bestx, besty, "score:", best_score, "zoom:", best_zoom)
            print(get_link_from(bestx, besty, iter_limit, best_zoom))

    # In theory this should stop shortly after hitting POI_MAX_TIME
    # But sometimes the Tidbyt servers throttle their apps
    # So I've gotta sprinkle this check everywhere
    if time.now().unix > end_time:
        print("Exceeded time limit for POI search:", (time.now().unix - START_TIME), "seconds")

    return bestx, besty, best_score, best_zoom

# Performs the fractal calculation on a single point
# Returns both the escape distance and the number of iterations
# (cannot exceed iter_limit)
def fractal_calc(x, y, iter_limit, cr = None, ci = None):
    # Determine initial values for Mandelbrot or Julia set
    zr, zi = (0.0, 0.0) if cr == None else (x, y)
    cr, ci = (x, y) if cr == None else (cr, ci)

    # Iteration loop
    for iteration in range(1, iter_limit + 1):
        # Compute squares
        zrsqr, zisqr = zr * zr, zi * zi

        # Escape condition
        if zrsqr + zisqr > ESCAPE_THRESHOLD:
            return iteration, zrsqr + zisqr

        # Update zr and zi using precomputed squares and existing terms
        zi = 2 * zr * zi + ci
        zr = zrsqr - zisqr + cr

    # Return if max iterations reached without escaping
    return iter_limit, zr * zr + zi * zi

# Converts an integer color channel to hexadecimal
def int_to_hex(n):
    if n > 255:
        fail("Can't convert value " + str(n) + " to hex digit")
    hex_digits = "0123456789ABCDEF"
    return hex_digits[n // 16] + hex_digits[n % 16]

# Convert RGB values to a hexadecimal color code
def rgb_to_hex(r, g, b):
    return "#" + int_to_hex(r) + int_to_hex(g) + int_to_hex(b)

# Converts a number of iterations until threshold escape to a color
def get_gradient_rgb(gradient, max_iter, iter):
    if iter >= max_iter or iter < 0:
        return (0, 0, 0) if iter == max_iter else fail("Bad iterations in get_gradient_rgb:", iter, "max:", max_iter)

    # Precompute values
    num_keyframes = len(gradient) - 1
    t = (math.pow(math.log(iter), GRADIENT_SCALE_FACTOR) / len(gradient)) % 1.0

    # Map t to the gradient keyframes
    frame_pos = t * num_keyframes
    lower_frame = int(frame_pos)
    upper_frame = lower_frame + 1 if lower_frame < num_keyframes else num_keyframes

    # Linear interpolation factor
    local_t = frame_pos - lower_frame

    # Linear interpolation (LERP) for RGB channels
    color_start = gradient[lower_frame]
    color_end = gradient[upper_frame]
    r = int(color_start[0] + local_t * (color_end[0] - color_start[0]))
    g = int(color_start[1] + local_t * (color_end[1] - color_start[1]))
    b = int(color_start[2] + local_t * (color_end[2] - color_start[2]))

    return (r, g, b)

# Blends RGB colors together
# Also converts from quantized values to full color spectrum
def blend_colors(*colors):
    tr, tg, tb = 0, 0, 0
    count = 0
    for i in range(0, len(colors)):
        r, g, b = colors[i]
        tr += r
        tg += g
        tb += b
        count += 1

    return (int(tr / count), int(tg / count), int(tb / count))

# Generates a random or predefined color gradient
def generate_gradient(pal_type):
    print("Generating color gradient")

    gradient = []
    color = list(random_color_tuple())

    # Random gradient
    if pal_type == "random":
        for _ in range(0, RANDOM_GRADIENT_STEPS):
            gradient.append(tuple(color))
            color = alter_color_rgb(color)
        return gradient

    # Predefined gradient
    colors = PREDEFINED_GRADIENTS[pal_type]
    for _ in range(PREDEFINED_GRADIENTS_NUM_CYCLES):
        for color in colors:
            gradient.append(color)

    return gradient

# At least one channel flipped, another randomized
def alter_color_rgb(color):
    flip_idx = random.number(0, 2)
    rnd_idx = (flip_idx + random.number(1, 2)) % 3
    keep_idx = 3 - flip_idx - rnd_idx
    new_color = [0, 0, 0]
    new_color[flip_idx] = 255 - color[flip_idx]
    new_color[rnd_idx] = random.number(0, 255)
    new_color[keep_idx] = color[keep_idx]
    return new_color

# Renders a line of a fractal. Used for boundry optimization.
# Returns the color used if they are all the same, otherwise False.
# If match_color is passed something other than False, then it will
# compare all colors against this value.
def generate_line_opt(map, max_iter, match_color, pix, iter_limit, gradient, cr, ci):
    # print("GenerateLineOpt! match_color:{}".format(match_color))

    # Determine whether the line is vertical or horizontal
    is_vertical = pix["x1"] == pix["x2"]
    if is_vertical:
        start, end = pix["y1"], pix["y2"]
    else:
        start, end = pix["x1"], pix["x2"]

    xp, yp = pix["x1"], pix["y1"]
    color = BLACK_COLOR
    for val in range(start, end + 1):
        if is_vertical:
            yp = val
        else:
            xp = val

        # Get the pixel iteration count
        color = generate_pixel(map, max_iter, xp, yp, iter_limit, gradient, cr, ci)

        # Initialize match_iter on first iteration
        if match_color == None:
            match_color = color

            # Bail early: Not all iterations along the line were identical
        elif match_color != color:
            return False

    # All iterations along the line were identical
    return color

# Copies an object and alters one field to a new value
def alt(obj, field, value):
    c = {}
    for k, v in obj.items():
        c[k] = v
    c[field] = value
    return c

# Generates a subsection of the fractal in map
def generate_fractal_area(map, max_iter, orig_pix, iter_limit, gradient, adaptive_aa, cr, ci):
    print("Generating fractal area")

    # Initialize the stack with the first region to process
    stack = [orig_pix]

    # We will dynamically increase the stack in the loop
    for _ in range(MAX_INT):  # Why no while loop, damn you starlark
        if len(stack) == 0:
            break

        # Pop the last item from the stack
        pix = stack.pop()

        # Determine some deltas
        dxp, dyp = int(pix["x2"] - pix["x1"]), int(pix["y2"] - pix["y1"])

        # print("Popped off stack:{}".format(pix))

        # OPTIMIZATION: A small box can be filled in with the same color if the corners are identical
        if dxp <= 6 and dyp <= 6:
            # print("Starting corner optimization check:{}".format(pix))
            color1 = generate_pixel(map, max_iter, pix["x1"], pix["y1"], iter_limit, gradient, cr, ci)
            color2 = generate_pixel(map, max_iter, pix["x2"], pix["y2"], iter_limit, gradient, cr, ci)
            if color1 == color2:
                color3 = generate_pixel(map, max_iter, pix["x1"], pix["y2"], iter_limit, gradient, cr, ci)
                if color2 == color3:
                    color4 = generate_pixel(map, max_iter, pix["x2"], pix["y1"], iter_limit, gradient, cr, ci)
                    if color3 == color4:
                        # print("Corner optimization at {}".format(pix))
                        flood_fill(map, pix, color1)
                        continue

        # OPTIMIZATION: A border with the same iterations can be filled with the same color
        # print("Starting boundary optimization check:{}".format(pix))
        color = generate_line_opt(map, max_iter, None, alt(pix, "y2", pix["y1"]), iter_limit, gradient, cr, ci)
        if color != False:
            color = generate_line_opt(map, max_iter, color, alt(pix, "y1", pix["y2"]), iter_limit, gradient, cr, ci)
        if color != False:
            color = generate_line_opt(map, max_iter, color, alt(pix, "x2", pix["x1"]), iter_limit, gradient, cr, ci)
        if color != False:
            color = generate_line_opt(map, max_iter, color, alt(pix, "x1", pix["x2"]), iter_limit, gradient, cr, ci)
        if color != False:
            # print("Boundary optimization at {}".format(pix))
            flood_fill(map, pix, color)
            continue

        # Perform vertical split
        if dyp >= 3 and dyp >= dxp:
            # print("Splitting vertically")
            splityp = int(dyp / 2)
            syp_above = splityp + pix["y1"]
            syp_below = syp_above + 1

            # Add sub-regions to the stack
            stack.extend([
                alt(pix, "y1", syp_below),
                alt(pix, "y2", syp_above),
            ])
            continue

        # Perform horizontal split
        if dxp >= 3 and dyp >= 3:
            # print("Splitting horizontally")
            splitxp = int(dxp / 2)
            sxp_left = splitxp + pix["x1"]
            sxp_right = sxp_left + 1

            # Add sub-regions to the stack
            stack.extend([
                alt(pix, "x1", sxp_right),
                alt(pix, "x2", sxp_left),
            ])
            continue

        # Generate all pixels for this area
        # print("Filling in at {}".format(pix))
        for offy in range(dyp + 1):
            for offx in range(dxp + 1):
                # Draw pixel
                xp = pix["x1"] + offx
                yp = pix["y1"] + offy
                generate_pixel(map, max_iter, xp, yp, iter_limit, gradient, cr, ci)

    # Add additional AA if we can
    if adaptive_aa:
        perform_adaptive_aa(map, max_iter, iter_limit, gradient, cr, ci)

# Performs as many passes of spiral AA as time allows
# Does this by spiraling around the pixel and averaging the samples
def perform_adaptive_aa(map, max_iter, iter_limit, gradient, cr, ci):
    print("Beginning adaptive AA")

    neighbors = [
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
    ]

    # Make a list of all points that are are not surrounded by the same neighbor
    points = []
    width = map["width"]
    height = map["height"]
    index = 0
    for data in map["data"]:
        color = data["color"]
        point = data["point"]
        for offset in neighbors:
            nx, ny = point["x"] + offset[0], point["y"] + offset[1]
            nindex = nx + ny * width
            if nx < 0 or nx >= width or ny < 0 or ny >= height or color != map["data"][nindex]["color"]:
                points.append(index)
                break # Skip next neighbor
        index += 1              
    print ("Culled {} points, performing AA on {} points".format(width*height-len(points), len(points)))

    # Perform passes now
    radius = ADAPTIVE_AA_START_RADIUS
    angle = ADAPTIVE_AA_START_ANGLE
    for n in range(MAX_ADAPTIVE_PASSES):
        elapsed = time.now().unix - START_TIME
        if elapsed > ADAPTIVE_AA_MAX_TIME:
            print("Adaptive AA stopping with elapsed time:", elapsed)
            break

        # Determine oversample offset
        spiralx = radius * math.cos(math.radians(angle)) * map["dxm"]
        spiraly = radius * math.sin(math.radians(angle)) * map["dym"]

        # Perform additional sample pass
        print("Adding more details! PASS", "#" + str(n + 1), " Elapsed:", elapsed, "Radius:", radius, "Angle:", angle)
        for record in [map["data"][index] for index in points]:
            generate_detail(record, max_iter, iter_limit, gradient, cr, ci, spiralx, spiraly)

        # Move offset around in a spiral
        radius += ADAPTIVE_AA_INC_RADIUS
        angle = math.mod(angle + ADAPTIVE_AA_INC_ANGLE, 360)

# Generates additional details for a set of specific regions using spiral AA
def generate_detail(record, max_iter, iter_limit, gradient, cr, ci, spiralx, spiraly):
    # Normal fractal calculation
    iter, _ = fractal_calc(record["set"]["x"] + spiralx, record["set"]["y"] + spiraly, iter_limit, cr, ci)
    if iter == iter_limit:
        iter = max_iter

    # Get color of new sample
    orig_color = record["color"]
    color = get_gradient_rgb(gradient, max_iter, iter)
    if orig_color == color:
        return

    # Blend in new oversample color 33% with existing color
    blend = blend_colors(orig_color, orig_color, color)
    record["color"] = blend

# Calculates color tuple for a point on the map and returns them
# Tries to gather the pixel data from the cache if available
def generate_pixel(map, max_iter, xp, yp, iter_limit, gradient, cr, ci):
    index = yp * map["width"] + xp
    record = map["data"][index]
    color = record["color"]
    if color != None:
        return color

    # Normal fractal calculation
    iter, _ = fractal_calc(record["set"]["x"], record["set"]["y"], iter_limit, cr, ci)
    if iter == iter_limit:
        iter = max_iter

    # Save generated pixel color in map
    color = get_gradient_rgb(gradient, max_iter, iter)
    record["color"] = color

    return color

# Fills a rectangular area with a single color tuple
def flood_fill(map, area, color):
    for y in range(area["y1"], area["y2"] + 1):
        row_index = y * map["width"]
        for x in range(area["x1"], area["x2"] + 1):
            map["data"][row_index + x]["color"] = color

# Creates a blank map object
def create_map(width, height):
    data = [{
        "color": None, 
        "set": None, 
        "terminal": False, 
        "point": None
    } for _ in range(width * height)]

    return {"data": data, "width": width, "height": height}

# Creates a fractal and downsamples it to the final display dimensions
def render_fractal(app, center_xm, center_ym):
    # Get some metrics
    app["center"] = (center_xm, center_ym)
    half_set_width = (MAXX - MINX) / app["zoom_level"] / 2.0
    half_set_height = (MAXY - MINY) / app["zoom_level"] / 2.0
    min_xm, min_ym = center_xm - half_set_width, center_ym - half_set_height
    dxm = (2 * half_set_width) / app["max_pixel_x"]
    dym = (2 * half_set_height) / app["max_pixel_y"]

    # Create the map
    map = create_map(app["map_width"], app["map_height"])
    app["map"] = map
    map["dxm"] = dxm  # Space between two sampled points in mandelbrot set
    map["dym"] = dym

    print("Caching mandelbrot coordinates with dm of", dxm, dym)
    ym = min_ym
    for yp in range(map["height"]):
        xm = min_xm
        for xp in range(map["width"]):
            record = map["data"][map["width"] * yp + xp]
            record["point"] = {"x": xp, "y": yp}
            record["set"] = {"x": xm, "y": ym}
            xm += dxm
        ym += dym

    # Generate the map
    pix = {"x1": 0, "y1": 0, "x2": app["max_pixel_x"], "y2": app["max_pixel_y"]}

    # print("Map at initialization: {}".format(map))
    generate_fractal_area(app["map"], app["max_iter"], pix, app["max_iter"], app["gradient"], app["adaptive"], *app["c"])

    # Downsample to the display size
    map = downsample(app["map"], DISPLAY_WIDTH)
    return map

# Downsample an oversampled map, to make it teensy weensy
def downsample(map, final_width):
    if map["width"] == final_width:
        return map

    # print("Downsampling", map["width"], map["height"], "to:", final_width)
    if len(map["data"]) != map["width"] * map["height"]:
        fail("Map size:", len(map["data"]), "does not match expected size:", map["width"], map["height"])

    src_height = len(map["data"]) // map["width"]  # Integer division
    oversample = int(map["width"] / final_width)  # Determine oversample amount
    final_height = int(src_height / oversample)  # Determine final height
    new_map = create_map(final_width, final_height)  # Create new map!

    # Downsample each pixel...
    data = map["data"]
    osy = 0
    for y in range(final_height):  # y
        osx = 0

        for x in range(final_width):  # x
            colors = []
            for offy in range(oversample):
                for offx in range(oversample):
                    if osx + offx < map["width"] and osy + offy < src_height:
                        color = data[(osy + offy) * map["width"] + osx + offx]["color"]
                        colors.append(color)

            if colors:
                color = blend_colors(*colors)
            else:
                color = data[osy * map["width"] + osx]["color"]  # Fallback color

            new_map["data"][y * final_width + x] = {"color": color}

            osx += oversample
        osy += oversample

    return new_map  # Returns map

# Converts an rgb color map to a Tidbyt Column made up of Rows made up of Boxes
def render_tidbyt(map):
    # Loop through each pixel in the display
    rows = list()
    color = 0
    index = 0

    if len(map["data"]) != DISPLAY_WIDTH * DISPLAY_HEIGHT:
        return err("Final map must be display size" + len(map["data"]), False)

    for _ in range(DISPLAY_HEIGHT):  # y
        row = list()
        next_color = ""
        run_length = 0

        for _ in range(DISPLAY_WIDTH):  # x
            color = rgb_to_hex(*map["data"][index]["color"])  # RGB Tuple to "#RRGGBB"
            index += 1

            # Add a 1x1 box with the appropriate color to the row
            if next_color == "":  # First color of row
                run_length = 1
                next_color = color
            elif color == next_color:  # Color run detected
                run_length += 1
            else:  # Color change
                add_box(row, run_length, next_color)
                run_length = 1
                next_color = color

        # Add the row to the grid
        add_box(row, run_length, color)  # Add last box for row
        rows.append(render.Row(children = row))

    return render.Column(
        children = rows,
    )

# Shorthand used in render_tidbyt
def add_box(row, run_length, color):
    if run_length == 1 and color == BLACK_PIXEL:
        row.append(BLACK_PIXEL)
    else:
        row.append(render.Box(width = run_length, height = 1, color = color))

# Generates a random color in RGB tuple format
def random_color_tuple():
    return (random.number(0, 255), random.number(0, 255), random.number(0, 255))

# Generates random floating point number from 0.0 to 1.0
def rnd():
    return float(random.number(0, MAX_INT)) / float(MAX_INT)

# Returns true if this strange should successfully cast to a float
def is_float(s):
    if s == None:
        return False
    float_regex = r"^[+-]?\d*\.?\d+([eE][+-]?\d+)?$"
    return bool(re.match(float_regex, s))

# Returns true if this strange should successfully cast to an int
def is_int(s):
    if s == None:
        return False
    int_regex = r"^[+-]?\d+$"
    return bool(re.match(int_regex, s))

# Returns the Tidbyt schemas for setting app options
def get_schema():
    gradient_options = [schema.Option(value = "random", display = "Randomized")]
    for g in PREDEFINED_GRADIENTS.keys():
        gradient_options.append(schema.Option(value = g, display = " ".join([word.capitalize() for word in g.split("-")])))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "oversample",
                name = "Oversample",
                desc = "Base oversampling",
                default = DEFAULT_OVERSAMPLE,
                options = [
                    schema.Option(value = "1", display = "None"),
                    schema.Option(value = "2", display = "2X AA (slower)"),
                    schema.Option(value = "4", display = "4X AA (imagine even slower)"),
                    schema.Option(value = "8", display = "8X AA (mandelbrots might time out)"),
                    schema.Option(value = "16", display = "16X AA (mandelbrots will time out)"),
                    schema.Option(value = "32", display = "32X AA (julia might time out too)"),
                ],
                icon = "borderNone",
            ),
            schema.Toggle(
                id = "adaptive",
                name = "Adaptive AA",
                desc = "Additional AA passes as time allows (Recommended)",
                default = DEFAULT_ADAPTIVE_AA,
                icon = "arrowUpRightDots",
            ),
            schema.Dropdown(
                id = "gradient",
                name = "Gradient",
                desc = "Color gradient",
                default = DEFAULT_GRADIENT,
                icon = "paintbrush",
                options = gradient_options,
            ),
            schema.Toggle(
                id = "julia",
                name = "Julia",
                desc = "Display a julia set (faster)",
                default = DEFAULT_JULIA,
                icon = "puzzlePiece",
            ),
            schema.Toggle(
                id = "brightness",
                name = "Normalize Brightness",
                desc = "Darker darks, lighter lights",
                default = DEFAULT_BRIGHTNESS,
                icon = "lightbulb",
            ),
            schema.Toggle(
                id = "contrast",
                name = "Contrast Stretch",
                desc = "Improves contrast",
                default = DEFAULT_CONTRAST,
                icon = "circleHalfStroke",
            ),
            schema.Text(
                id = "gamma",
                name = "Gamma Correction",
                desc = "Monitor gamma (1.0 = off)",
                default = DEFAULT_GAMMA,
                icon = "tv",
            ),
        ],
    )

# Instead of calling fail(), in some situations, we can display the error
# message right on the Tidbyt
def err(msg, include_root = True):
    print(msg)

    text = render.WrappedText(
        content = msg,
        width = 64,
        color = "#f00",
    )

    if include_root:
        return render.Root(text)

    return text

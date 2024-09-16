"""
Applet: Summer Countdown
Summary: Shows a countdown to summer
Description: Shows a countdown to the start or end of astronomical summer in your hemisphere.
Author: Andrew Knotts
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

COLOR_SKY = "#0077BB"
COLOR_GRASS = "#538F00"
COLOR_GRASS_DARK = "#3C6602"
COLOR_STEMS = "#41DD00"
COLOR_PETALS = "#FFD900"
COLOR_SEEDS = "#3D2A00"
COLOR_MESSAGE = "#FFFFFF"

# Pixel unit definitions:
GRASS_HEIGHT = 6
PETALS_WIDTH = 7
SEEDS_WIDTH = 3
FLOWER_MARGIN_LEFT = 2
STEM_CEILING = 10
ROOT_FLOOR = 30
TERRAIN_MIN_ELEVATION = 5
TERRAIN_MAX_ELEVATION_GAIN = 3
HUGE_FLOWER_MAX_DIAMETER = 112

# Timing
DURATION_MS = 16000
FPS = 6
FRAME_COUNT = int(DURATION_MS / 1000 * FPS)

# Images
PNG_DAYS_TO_AUTUMN = "iVBORw0KGgoAAAANSUhEUgAAADIAAAAgCAYAAABQISshAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA+ElEQVRYw+1X2w7DIAgV0i/bhy/Zh3VnLzMhBvFSx7qO81K1YMXDrSkFAoHAXwMC2rqcy6cmY+1Zk11qSOuw1rMcW/vKMZ+RVSKiUR3+5mEBIB86z2fdZfOMnV4mpIGnY4TeOGKoOyP5UCO3ml2rR29ENhA4GoNWsMksUvqjXKsFas2XNV3N11tyco2tjAEAuMMls2ktzXTW0qyVrPXk/09nklqNad423Wj3LpotNrT3fJVg/1lDSla2lW2CV092CUaIiBLmsta5XOoBSik9SxKGC542t5rFlm7Pd7SCWMqylw+vZrmsJTyjNPJLOqIr/xajewwE1uIFzaoomS4ColwAAAAASUVORK5CYII="
PNG_DAYS_TO_SUMMER = "iVBORw0KGgoAAAANSUhEUgAAADIAAAAgCAYAAABQISshAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA8ElEQVRYw+1XQQ7EIAisxP9/2b0sCTEMFa1WU+ZiNaNFGRCvKxAIBD6NIqCNy75sNY61JuI+upE7Y622/rbWld+0o1dTSsk7h940tpRS2Gju98olr4ydVk/IDW7nkfTHyEaXe4SN8pwqS6tlnocbCIzGIAo4qT1Nj3IM6bWXY8UEynSEssbU639CYsnWiXvzueSjg2jhWP/UVLFtiTJ8j9Qlw6wbfIZsCUlqtNhDB9HCKRVangmEFj0l2NnujIq23uJtVRlfc0iT0wn1C5SWZ/KbskPpN1uPGs0zKzZxZ4e86Vn+ZJE9GeiE53Ag8GX8AO7oQ80Ko6ugAAAAAElFTkSuQmCC"
FLOWER_STAGES_PNG = [
    "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",
]

# Reuse render.Box for efficiency gains
STEM_BOX = render.Box(width = 2, height = 1, color = COLOR_STEMS)
LEAF_BOX = render.Box(width = 1, height = 1, color = COLOR_STEMS)

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

SEASONS = {
    "northern": {
        "summer": {"day": 21, "month": 6},
        "autumn": {"day": 23, "month": 9},
    },
    "southern": {
        "summer": {"day": 22, "month": 12},
        "autumn": {"day": 21, "month": 3},
    },
}

def sum(sequence):
    total = 0
    for item in sequence:
        total += item
    return total

def random_shuffle(array):
    for i in range(len(array) - 1, 0, -1):
        j = random.number(0, i)
        swap = array[i]
        array[i] = array[j]
        array[j] = swap

def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

def get_day_of_year(month, day_of_month, year):
    # Given a month, day, and year return the index of that day within the year
    days_per_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if is_leap_year(year):
        days_per_month[1] += 1

    return sum(days_per_month[:month - 1]) + day_of_month

def get_days_until(month, day_of_month, year, time_now):
    # Return how many days until the provided date, if the date is in the future.
    # If the date is in the past return -1
    day_now = get_day_of_year(time_now.month, time_now.day, time_now.year)
    day_then = get_day_of_year(month, day_of_month, year)

    if time_now.year > year:
        return -1
    elif time_now.year == year:
        if day_then < day_now:
            return -1
        else:
            return day_then - day_now
    else:
        # Future year:
        full_year_days = 0
        for future_year in range(time_now.year + 1, year):
            full_year_days += get_day_of_year(12, 31, future_year)
        return (get_day_of_year(12, 31, year) - day_now) + day_then + full_year_days - (1 if is_leap_year(year) else 0)

def is_summer(time_now, hemisphere):
    summer_date = SEASONS[hemisphere]["summer"]
    autumn_date = SEASONS[hemisphere]["autumn"]
    today = get_day_of_year(time_now.month, time_now.day, time_now.year)
    summer_start = get_day_of_year(summer_date["month"], summer_date["day"], time_now.year)
    autumn_start = get_day_of_year(autumn_date["month"], autumn_date["day"], time_now.year)
    if hemisphere == "northern":
        return today >= summer_start and today < autumn_start
    else:
        # Southern hemisphere:
        return today >= summer_start or today < autumn_start

def build_terrain():
    # Return a render.Stack of the terrain, and a heightmap list of the terrain
    def sign_or_random(n = None):
        if n == None:
            return random.number(0, 1) * 2 - 1
        else:
            return n / abs(n)

    height_map = []
    height = random.number(0, TERRAIN_MAX_ELEVATION_GAIN * 10) / 10
    slope = random.number(2, 5) / 10
    if height == TERRAIN_MAX_ELEVATION_GAIN:
        slope *= -1
    elif height != 0:
        slope *= sign_or_random()

    height_map.append(height)
    local_min = random.number(0, max(0, int(height - 1)))
    local_max = random.number(min(int(height + 1), TERRAIN_MAX_ELEVATION_GAIN), TERRAIN_MAX_ELEVATION_GAIN)
    for i in range(63):
        height += slope
        reverse_direction = False
        if height > local_max:
            height -= abs(slope)
            reverse_direction = True
            local_min = random.number(0, max(0, int(height - 1)))
        elif height < local_min:
            height += abs(slope)
            reverse_direction = True
            local_max = random.number(min(int(height + 1), TERRAIN_MAX_ELEVATION_GAIN), TERRAIN_MAX_ELEVATION_GAIN)
        height_map.append(height)

        if reverse_direction:
            slope = random.number(2, 5) / 10 * -sign_or_random(slope)

    for i in range(len(height_map)):
        height_map[i] = int(height_map[i])
    peak = max(height_map)

    return render.Stack(children = [
        render.Padding(
            pad = (0, 32 - TERRAIN_MIN_ELEVATION - peak, 0, 0),
            child = render.Row(
                cross_align = "end",
                children = [
                    render.Box(width = 1, height = h + TERRAIN_MIN_ELEVATION, color = COLOR_GRASS)
                    for h in height_map
                ],
            ),
        ),
        render.Padding(
            pad = (0, 32 - TERRAIN_MIN_ELEVATION - peak + 3, 0, 0),
            child = render.Row(
                cross_align = "end",
                children = [
                    render.Box(width = 1, height = h + TERRAIN_MIN_ELEVATION - 3, color = COLOR_GRASS_DARK)
                    for h in height_map
                ],
            ),
        ),
    ]), height_map

def grow_flower(flower, stem_increment):
    # Simulate random growth of the provided flower by stem_increment steps
    # The flower grows taller by [stem_increment]px if it has not matured yet
    for _ in range(stem_increment):
        # Grow the stem
        pre_length = flower["stem_length"]
        if flower["stem_length"] < flower["stem_length_limit"]:
            flower["stem_length"] += 1

        # Only add new leaves if the stem grew taller
        if pre_length != flower["stem_length_limit"]:
            if len(flower["leaves"]) > 0:
                top_leaf = flower["leaves"][-1]
            else:
                # No leaves yet; reference a dummy leaf for now
                top_leaf = [2, 0, None]
            distance_from_prev_leaf = flower["stem_length"] - top_leaf[1]

            if distance_from_prev_leaf == 1 and top_leaf[2] != None:
                # Leaf creation odds start at 50/50 when the previous row has a leaf
                odds = 2
                if len(flower["leaves"]) >= 2 and flower["leaves"][-2][1] == flower["stem_length"] - 2:
                    # Lower the odds (reciprocal) if this would be the 3rd leaf in a row
                    odds = 6

                # Attach the leaf on the opposite side from the previous row's leaf
                if top_leaf[2].lower() == "l":
                    side = "r"
                else:
                    side = "l"

            else:
                # The previous row has no leaf; odds increase as the gap to the last leaf increases
                odds = max(1, 4 - distance_from_prev_leaf)
                if len(flower["leaves"]) > 0:
                    # Attach the leaf to a random side, favoring the side w/ less leaves
                    num_left_leaves = sum([1 for leaf in flower["leaves"] if leaf[2].lower() == "l"]) or 0
                    side = "r" if random.number(1, len(flower["leaves"])) > num_left_leaves else "l"
                else:
                    # No leaves yet; pick a random side
                    side = ("l", "r")[random.number(0, 1)]

            # Roll the odds for adding the new leaf:
            if random.number(1, odds) == 1:
                flower["leaves"].append([0, flower["stem_length"], side])

        # Grow each existing leaf
        for leaf in flower["leaves"]:
            leaf[0] = min(leaf[0] + 1 / 3, 2.0)

        # Grow the blossom if the stem is approaching maturity
        height_remaining = flower["stem_length_limit"] - flower["stem_length"]
        if height_remaining + 7 <= len(FLOWER_STAGES_PNG):
            flower["bloom_stage"] = min(len(FLOWER_STAGES_PNG) - 1, flower["bloom_stage"] + 0.667)

def draw_sunflower(flower):
    # Return the pixels of the stem, leaves and blossom as list of widgets
    widgets = []
    for stem_i in range(flower["stem_length"]):
        position = (flower["col"], flower["roots_row"] - stem_i, 0, 0)
        widgets.append(render.Padding(child = STEM_BOX, pad = position))

    for leaf in flower["leaves"]:
        row = flower["roots_row"] - leaf[1] + 1
        leaf_direction = -1 if leaf[2].lower() == "l" else 1
        col_center = flower["col"] if leaf[2].lower() == "l" else flower["col"] + 1
        if leaf[0] < 1:
            continue
        elif leaf[0] < 2:
            widgets.append(render.Padding(child = LEAF_BOX, pad = (col_center + leaf_direction, row, 0, 0)))
        else:
            widgets.append(render.Padding(child = LEAF_BOX, pad = (col_center + leaf_direction, row, 0, 0)))
            widgets.append(render.Padding(child = LEAF_BOX, pad = (col_center + leaf_direction * 2, row, 0, 0)))

    # Append the blossom:
    widgets.append(
        render.Padding(
            pad = (flower["col"] - 3, flower["roots_row"] - flower["stem_length"] - 4, 0, 0),
            child = render.Image(
                src = base64.decode(
                    FLOWER_STAGES_PNG[int(flower["bloom_stage"])],
                ),
            ),
        ),
    )

    return widgets

def spawn_sunflowers(heightmap):
    # Create 7 randomly positioned sunflowers
    flowers = []
    for f in range(7):
        col = FLOWER_MARGIN_LEFT + 9 * f + 2
        roots_row = random.number(31 - heightmap[col] - TERRAIN_MIN_ELEVATION, ROOT_FLOOR)

        max_growth = roots_row - STEM_CEILING
        min_growth = max_growth - 7

        # Make the middle flower the tallest so if finishes growing last
        if f == 3:
            min_growth = max_growth
            max_growth += 5

        flowers.append({
            "col": col,
            "roots_row": roots_row,
            "stem_length_limit": random.number(min_growth, max_growth),
            "leaves": [],  # [width from stem, height above ground, side 'l' or 'r'] for each leaf
            "stem_length": 1,
            "bloom_stage": 0,
        })

    return flowers

def build_seeds_list(width, left_padding):
    # Seeds as in actual sunflower seeds, not RNG seeds
    # Used for revealing the countdown message
    seeds = []
    cell = render.Box(height = 1, width = 1, color = COLOR_SEEDS)
    for i in range(width * 32):
        seeds.append(render.Padding(cell, pad = (i % width + left_padding, i // width, 0, 0)))
    random_shuffle(seeds)
    return seeds

def ripen_random_seeds(width, seeds_widget_list, ripen_percent):
    # Used for revealing the countdown message
    ripen_count = min(int(width * 32 * ripen_percent), len(seeds_widget_list))
    for _ in range(ripen_count):
        seeds_widget_list.pop()

def render_all_frames(frame_count, config):
    frames = []

    hemisphere = config.get("hemisphere", None)
    if hemisphere != None:
        # Handle legacy config option
        timezone = config.get("$tz", DEFAULT_TIMEZONE)
    else:
        location = json.decode(config.get("location", DEFAULT_LOCATION))
        timezone = location["timezone"]
        if float(location["lat"]) < 0:
            hemisphere = "southern"
        else:
            hemisphere = "northern"
    time_now = time.now().in_location(timezone)

    # Calculate days until summer and autumn
    summer_date = SEASONS[hemisphere]["summer"]
    autumn_date = SEASONS[hemisphere]["autumn"]
    days_until_summer = get_days_until(summer_date["month"], summer_date["day"], time_now.year, time_now)
    days_until_autumn = get_days_until(autumn_date["month"], autumn_date["day"], time_now.year, time_now)
    if days_until_summer < 1:
        days_until_summer = get_days_until(summer_date["month"], summer_date["day"], time_now.year + 1, time_now)
    if days_until_autumn < 1:
        days_until_autumn = get_days_until(autumn_date["month"], autumn_date["day"], time_now.year + 1, time_now)

    # Decide to show summer or autumn
    if is_summer(time_now, hemisphere):
        days_until = days_until_autumn
        countdown_png = PNG_DAYS_TO_AUTUMN
    else:
        days_until = days_until_summer
        countdown_png = PNG_DAYS_TO_SUMMER

    terrain, heightmap = build_terrain()
    flowers = spawn_sunflowers(heightmap)
    sky = render.Box(height = 32, width = 64, color = COLOR_SKY)
    all_flowers_matured_frame = None
    huge_flower_diameter = 8
    huge_flower_growth_done_frame = None
    huge_seed_widgets = build_seeds_list(50, 7)

    for i in range(frame_count):
        frame_stack = [
            sky,
            terrain,
        ]

        all_flowers_matured = True

        # Draw and simulate sunflower growth, but only if they're visible
        if huge_flower_growth_done_frame == None:
            for flower in flowers:
                all_flowers_matured = all_flowers_matured and flower["bloom_stage"] == len(FLOWER_STAGES_PNG) - 1
                frame_stack.extend(draw_sunflower(flower))
                grow_flower(flower, 2)

        if all_flowers_matured:
            # Flowers are done growing; start next phases
            if all_flowers_matured_frame == None:
                all_flowers_matured_frame = i

            if i >= all_flowers_matured_frame + 5:
                # Start expanding the huge flower blossom 1 frame after showing it
                huge_flower_diameter += int(huge_flower_diameter * 0.8)
                huge_flower_diameter = min(huge_flower_diameter, HUGE_FLOWER_MAX_DIAMETER)

            if i >= all_flowers_matured_frame + 4:
                # Show the huge flower blossom
                big_flower_row = flowers[3]["roots_row"] - flowers[3]["stem_length"] - max(4, int(huge_flower_diameter / 2))
                big_flower_row += int((16 - (flowers[3]["roots_row"] - flowers[3]["stem_length"])) * (huge_flower_diameter - 8) / HUGE_FLOWER_MAX_DIAMETER)
                big_flower_col = int(32 - huge_flower_diameter / 2)
                frame_stack.append(
                    render.Padding(
                        pad = (big_flower_col, big_flower_row, 0, 0),
                        child = render.Circle(
                            color = COLOR_PETALS,
                            diameter = huge_flower_diameter,
                            child = render.Circle(color = COLOR_SEEDS, diameter = int(huge_flower_diameter * 0.541)),
                        ),
                    ),
                )

            if huge_flower_growth_done_frame == None and huge_flower_diameter == HUGE_FLOWER_MAX_DIAMETER:
                huge_flower_growth_done_frame = i

        if huge_flower_growth_done_frame and i >= huge_flower_growth_done_frame + 4:
            # Display the countdown message:
            if 0 < days_until and days_until < 10:
                days_until_text = " " + str(days_until)
            else:
                days_until_text = str(days_until)

            # Set up widgets for 2 or 3 digit countdowns
            if len(days_until_text) > 2:
                font = "6x13"
                digits_pad = (8, 2, 0, 0)
                msg_pad = (7, 0, 0, 0)
                plural_cover_pad = (41, 6, 0, 0)
            else:
                font = "10x20"
                digits_pad = (6, -1, 0, 0)
                msg_pad = (7, 2, 0, 0)
                plural_cover_pad = (41, 8, 0, 0)

            # Show the digits and message
            frame_stack.append(
                render.Stack(children = [
                    render.Padding(
                        pad = digits_pad,
                        child = render.Text(
                            content = days_until_text,
                            font = font,
                            color = COLOR_MESSAGE,
                        ),
                    ),
                    render.Padding(
                        pad = msg_pad,
                        child = render.Image(src = base64.decode(countdown_png)),
                    ),
                ]),
            )

            # Cover up the "S" if days_until is singular
            if days_until == 1:
                frame_stack.append(
                    render.Padding(
                        pad = plural_cover_pad,
                        child = render.Box(height = 7, width = 4, color = COLOR_SEEDS),
                    ),
                )

            # Ripen sunflower seeds to reveal the countdown
            frame_stack.append(render.Stack(children = huge_seed_widgets))
            ripen_random_seeds(50, huge_seed_widgets, 0.2)

        frames.append(render.Stack(children = frame_stack))
    return frames

def main(config):
    frames = render_all_frames(FRAME_COUNT, config)
    return render.Root(
        child = render.Animation(children = frames),
        delay = int(1000 / FPS),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location to use for the seasonal calendar.",
                icon = "locationDot",
            ),
        ],
    )

"""
Applet: MTG Scry One
Summary: Scry a random card from MTG
Description: Scry a random card from Magic: The Gathering and displays its information.
Author: UnBurn
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

SCRYFALL_API = "https://api.scryfall.com/cards/random"

DEFAULT_TTL_TIME = 1800
MARQUEE_DELAY = 10

DEFAULT_IS_COMMANDER = False
DEFAULT_IS_PRICE_SHOWING = False
DEFAULT_CUSTOM_QUERY = ""

def hex_to_rgb(hex_color):
    hex_color_stripped = hex_color[1:]  # Remove '#'
    r = int(hex_color_stripped[0:2], 16)
    g = int(hex_color_stripped[2:4], 16)
    b = int(hex_color_stripped[4:6], 16)
    return (r, g, b)

# Helper function to convert an integer (0-255) to a two-digit hexadecimal string.
def to_hex_digit(value):
    HEX_CHARS = "0123456789abcdef"

    # Calculate the first hex digit (tens place)
    first_digit = HEX_CHARS[value // 16]

    # Calculate the second hex digit (ones place)
    second_digit = HEX_CHARS[value % 16]
    return first_digit + second_digit

# Function to convert an RGB tuple (R, G, B) back to a hex color string.
# Starlark's int() truncates. To round to the nearest integer, add 0.5 before converting to int.
# Color components are always non-negative, so this simple method works.
def rgb_to_hex(rgb_color):
    r = int(rgb_color[0] + 0.5)
    g = int(rgb_color[1] + 0.5)
    b = int(rgb_color[2] + 0.5)

    # Concatenate the hex digits obtained from the helper function
    return "#" + to_hex_digit(r) + to_hex_digit(g) + to_hex_digit(b)

# Helper function to interpolate 'num_additional_colors' between two given hex colors.
# This function will return ONLY the intermediate colors, not the start or end colors.
def _interpolate_two_colors(color_a, color_b, num_additional_colors):
    rgb_a = hex_to_rgb(color_a)
    rgb_b = hex_to_rgb(color_b)

    interpolated_colors = []

    # Loop from 1 to num_additional_colors (inclusive)
    # The factor is i / (num_additional_colors + 1) to get the correct equidistant points
    for i in range(1, num_additional_colors + 1):
        factor = float(i) / (num_additional_colors + 1)

        r = rgb_a[0] + factor * (rgb_b[0] - rgb_a[0])
        g = rgb_a[1] + factor * (rgb_b[1] - rgb_a[1])
        b = rgb_a[2] + factor * (rgb_b[2] - rgb_a[2])

        interpolated_colors.append(rgb_to_hex((r, g, b)))
    return interpolated_colors

# New main function to generate a gradient across multiple control points.
# source_colors: A list of hex color strings that serve as control points for the gradient.
# colors_per_segment: The number of additional equidistant colors to generate between each consecutive pair of source colors.
def generate_gradient_steps(source_colors, colors_per_segment):
    if len(source_colors) < 2:
        # If there are fewer than two source colors, no interpolation is possible.
        # Return the source colors as is.
        return source_colors

    gradient = []

    # Add the first source color to start the gradient.
    gradient.append(source_colors[0])

    # Iterate through the source colors, taking two at a time (current and next).
    for i in range(len(source_colors) - 1):
        current_color = source_colors[i]
        next_color = source_colors[i + 1]

        # Get the interpolated colors between the current and next source color.
        # Use the helper function _interpolate_two_colors.
        interpolated_segment = _interpolate_two_colors(current_color, next_color, colors_per_segment)

        # Add all interpolated colors for this segment to the gradient.
        # Starlark uses '+' for list concatenation.
        gradient = gradient + interpolated_segment

        # Add the next source color to the gradient.
        # This ensures all source colors are part of the final gradient.
        gradient.append(next_color)

    return gradient

def render_box_backgrounds(colors):
    if len(colors) == 0:
        return [render.Box(width = 64, height = 6, color = "#222222")]
    boxes = []
    width = 64 // len(colors)
    leftovers = 64 - (len(colors) * width)
    for idx, color in enumerate(colors):
        true_width = width + (1 if leftovers > 0 and idx % (len(colors) // leftovers) == 0 else 0)
        boxes.append(render.Box(width = true_width, height = 6, color = color))
    return boxes

def get_random_card(config):
    url = SCRYFALL_API
    is_commander = config.bool("is_commander", DEFAULT_IS_COMMANDER)
    custom_query = config.str("custom_query", DEFAULT_CUSTOM_QUERY).replace(" ", "%20")
    queries = []
    if is_commander:
        queries.append("is:commander")
    if custom_query != "":
        queries.append(custom_query)
    if len(queries) > 0:
        url = url + "?q="
        url = url + "%20".join(queries)

    card_json = http.get(url, ttl_seconds = int(config.get("time_frequency", "3600")))
    return card_json.json()

def get_card_image(config, image_url):
    return http.get(image_url, ttl_seconds = int(config.get("time_frequency", "3600"))).body()

def get_mana_colors(colors):
    ret = []
    for c in colors:
        if c == "W":
            ret.append("#A0A000")
        if c == "B":
            ret.append("#8F8F8F")
        if c == "R":
            ret.append("#A00000")
        if c == "G":
            ret.append("#00A000")
        if c == "U":
            ret.append("#0000A0")
    return ret

def pick_price(prices):
    if prices["usd"] != None:
        return prices["usd"]
    if prices["usd_foil"] != None:
        return prices["usd_foil"]
    if prices["usd_etched"] != None:
        return prices["usd_etched"]
    return None

def main(config):
    data = get_random_card(config)
    image = get_card_image(config, data["image_uris"]["art_crop"])
    description = data["oracle_text"]
    title = data["name"]
    price = pick_price(data["prices"])
    mana_colors = get_mana_colors(data["colors"])
    mana_color_len = len(mana_colors) if len(mana_colors) > 0 else 1
    colors = generate_gradient_steps(mana_colors, (64 // mana_color_len))
    top_bar = render.Stack(
        children = [
            render.Row(
                render_box_backgrounds(colors),
            ),
            render.Row(
                children = [
                    render.Marquee(
                        width = 64,
                        offset_start = 1,
                        delay = MARQUEE_DELAY,
                        child = render.Text(
                            title,
                            font = "tom-thumb",
                        ),
                    ),
                ],
            ),
        ],
    )

    body = render.Row(
        children = [
            render.Marquee(
                height = 25,
                delay = MARQUEE_DELAY,
                scroll_direction = "vertical",
                child = (
                    render.Column(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(src = image, width = 64, height = 25),
                                    render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = (0, 18, 0, 0),
                                                child = render.Box(color = "#000000", width = len(price) * 5, height = 7),
                                            ),
                                            render.Padding(
                                                pad = (0, 19, 0, 0),
                                                child = render.Text(
                                                    content = "$%s" % price,
                                                    font = "tom-thumb",
                                                ),
                                            ),
                                        ] if price != None and config.bool("is_price_showing", False) else [],
                                    ),
                                ],
                            ),
                            render.Padding(child = render.Box(width = 64, height = 1, color = "#fff"), pad = (0, 0, 0, 3)),
                            render.WrappedText(
                                content = description,
                                font = "tom-thumb",
                                color = "#FFFFFF",
                            ),
                        ],
                    )
                ),
            ),
        ],
    )

    return render.Root(
        show_full_animation = True,
        delay = 120,
        child = render.Column(
            children = [top_bar, render.Box(color = "#fff", width = 64, height = 1), body],
        ),
    )

def get_schema():
    time_options = [
        schema.Option(
            display = "Every time",
            value = "1",
        ),
        schema.Option(
            display = "Every 30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "Every hour",
            value = "3600",
        ),
        schema.Option(
            display = "Every 6 hours",
            value = "21600",
        ),
        schema.Option(
            display = "Every 12 hours",
            value = "43200",
        ),
        schema.Option(
            display = "Every day",
            value = "86400",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "is_commander",
                name = "Commanders Only",
                desc = "Only show commmanders",
                icon = "spaghettiMonsterFlying",
                default = DEFAULT_IS_COMMANDER,
            ),
            schema.Text(
                id = "custom_query",
                name = "Custom query",
                desc = "Use a custom query like you would in Scryfall",
                icon = "penToSquare",
                default = DEFAULT_CUSTOM_QUERY,
            ),
            schema.Toggle(
                id = "is_price_showing",
                name = "Show price",
                desc = "Show price in USD",
                icon = "dollarSign",
                default = DEFAULT_IS_PRICE_SHOWING,
            ),
            schema.Dropdown(
                id = "time_frequency",
                name = "Interval",
                desc = "How often to show a new card?",
                icon = "clock",
                default = str(DEFAULT_TTL_TIME),
                options = time_options,
            ),
        ],
    )

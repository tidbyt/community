"""
Applet: Random Numbers
Summary: Display random numbers
Description: Display random numbers.
Author: Kyle Bolstad
"""

load("animation.star", "animation")
load("humanize.star", "humanize")
load("math.star", "math")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_ALLOW_ZERO = True
DEFAULT_QUANTITY = 1
DEFAULT_CLAMP = True
DEFAULT_COLOR = "#fff"
DEFAULT_DURATION = 1
DEFAULT_DIGITS = 4
DEFAULT_FONT = "tb-8"
DEFAULT_SEPARATOR = ","
DEFAULT_SHOW_LEADING_ZERO = False
DEFAULT_SHOW_SEPARATOR = False
DEFAULT_SHOW_FULL_ANIMATION = True
MAX_DIGITS = 10

FRAMES_PER_SECOND = 30

FONTS = [
    "tb-8",
    "Dina_r400-6",
    "5x8",
    "6x13",
    "10x20",
    "tom-thumb",
    "CG-pixel-3x5-mono",
    "CG-pixel-4x5-mono",
]

SEPARATORS = [",", "."]

def main(config):
    MIN_DIGITS = 0 if config.bool("allow_zero", DEFAULT_ALLOW_ZERO) else 1

    digits = int(config.get("digits", DEFAULT_DIGITS) or MIN_DIGITS)
    if digits < MIN_DIGITS:
        digits = MIN_DIGITS
    if digits > MAX_DIGITS:
        digits = MAX_DIGITS

    start = int(math.pow(10, digits - 1) - 1) if config.bool("clamp", DEFAULT_CLAMP) else MIN_DIGITS
    end = int(math.pow(10, digits))

    show_separator = config.bool("show_separator", DEFAULT_SHOW_SEPARATOR)

    separator = config.get("separator", DEFAULT_SEPARATOR)

    show_leading_zero = config.bool("show_leading_zero", DEFAULT_SHOW_LEADING_ZERO)

    font = config.get("font", DEFAULT_FONT)

    color = config.get("color", DEFAULT_COLOR)

    quantity = DEFAULT_QUANTITY
    if config.get("quantity"):
        quantity = re.sub("\\D", "", config.get("quantity")) or DEFAULT_QUANTITY
    quantity = int(quantity)

    duration = DEFAULT_DURATION
    if config.get("duration"):
        duration = re.sub("[^0-9.]", "", config.get("duration")) or DEFAULT_DURATION
        duration = re.sub("^\\.", "0.", str(duration))
        duration = re.sub("\\.{2,}", ".", duration)
    duration = float(duration)

    random_numbers = []

    for _ in range(int(quantity)):
        random_numbers.append(random.number(start, end - 1))

    children = []

    for number in random_numbers:
        if show_separator:
            number = humanize.comma(number)
            if separator == ".":
                number = re.sub(",", ".", number)

        number = str(number)

        if show_leading_zero:
            zeros = max(digits - len(number), 0)
            number = "0" * zeros + number

        children.append(
            animation.Transformation(
                child = render.Box(
                    child = render.WrappedText(
                        content = number,
                        font = font,
                        color = color,
                    ),
                ),
                duration = int(duration * FRAMES_PER_SECOND),
                keyframes = [],
            ),
        )

    show_full_animation = config.bool("show_full_animation", DEFAULT_SHOW_FULL_ANIMATION)

    return render.Root(
        show_full_animation = show_full_animation,
        child = render.Sequence(
            children = children,
        ),
    )

def get_schema():
    digits = []
    fonts = []
    separators = []

    for digit in range(MAX_DIGITS):
        digits.append(schema.Option(display = "%d" % (digit + 1), value = "%d" % (digit + 1)))

    for font in FONTS:
        fonts.append(
            schema.Option(
                display = font,
                value = font,
            ),
        )

    for separator in SEPARATORS:
        separators.append(
            schema.Option(
                display = separator,
                value = separator,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "digits",
                name = "Number of digits",
                desc = "The maximum number of digits",
                icon = "ruler",
                default = str(DEFAULT_DIGITS),
                options = digits,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "The font",
                icon = "font",
                default = DEFAULT_FONT,
                options = fonts,
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "The text color",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Text(
                id = "quantity",
                name = "Quantity of Numbers",
                desc = "The quantity of random numbers to show",
                icon = "repeat",
                default = str(DEFAULT_QUANTITY),
            ),
            schema.Text(
                id = "duration",
                name = "Duration (in Seconds)",
                desc = "The number of seconds for each duration",
                icon = "clock",
                default = str(DEFAULT_DURATION),
            ),
            schema.Toggle(
                id = "clamp",
                name = "Clamp length",
                desc = "Clamp the length to the exact number of digits",
                icon = "toolbox",
                default = DEFAULT_CLAMP,
            ),
            schema.Toggle(
                id = "show_separator",
                name = "Show Separator",
                desc = "Show a separator",
                icon = "rectangleList",
                default = DEFAULT_SHOW_SEPARATOR,
            ),
            schema.Dropdown(
                id = "separator",
                name = "Separator",
                desc = "Use either a comma or a period as the separator",
                icon = "rectangleList",
                default = DEFAULT_SEPARATOR,
                options = separators,
            ),
            schema.Toggle(
                id = "allow_zero",
                name = "Allow Zero",
                desc = "Include zero as a possible number",
                icon = "circleCheck",
                default = DEFAULT_ALLOW_ZERO,
            ),
            schema.Toggle(
                id = "show_leading_zero",
                name = "Show Leading Zero",
                desc = "Show leading zero(es)",
                icon = "circleCheck",
                default = DEFAULT_SHOW_LEADING_ZERO,
            ),
            schema.Toggle(
                id = "show_full_animation",
                name = "Show Full Animation",
                desc = "Tell Tidbyt to finish the animation before cycling to another app",
                icon = "circleCheck",
                default = DEFAULT_SHOW_FULL_ANIMATION,
            ),
        ],
    )

"""
Applet: Coin Prices
Summary: Show coin price
Description: Show Current exchange rate for multiple coins.
Author: alan-oliv
"""

load("render.star", "render")
load("schema.star", "schema")
load("animation.star", "animation")

# Theme
TEXT_COLOR = "#EEEEEE"
HIGHLIGHT_TEXT_COLOR = "#FFFFFF"
BACKGROUND_COLOR = "#000000"
FLIP_BACKGROUND_COLOR = "#333333"
DISPLAY_FONT = "tom-thumb"

# Timings
FLIP_DIGIT_DURATION = 50
END_DURATION = 100000

def main(config):
    main_display = render.Box()
    return render.Root(child = main_display)




def flip_display(value):
    price_digits = list(str(value).elems())
    display_children = []

    for digit in price_digits:
        value = digit if digit != '.' else 10
        display_children.append(flip_digit(int(value)))

    display = render.Row(children=display_children)

    return display

def flip_digit(number):
    digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']
    digits_children = []

    for digit in list(digits):
        text = render.Text(digit,
            color = HIGHLIGHT_TEXT_COLOR,
            font = DISPLAY_FONT
        )
        digits_children.append(text)

    numbers_column = render.Column(children=digits_children)

    flip_box = render.Stack(
        children = [
            render.Box(
                child = render.Stack(
                    children=[
                        # Digit animation
                        animation.Transformation(
                            child = numbers_column,
                            duration = FLIP_DIGIT_DURATION,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Translate(0, 0)],
                                    curve = "ease_in_out",
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Translate(0, -6 * (number))],
                                ),
                            ],
                        ),
                        # End delay animation
                        animation.Transformation(
                            child = render.Box(),
                            duration = END_DURATION,
                            delay = 0,
                            keyframes = [],
                        ),
                    ]
                ),
                color = FLIP_BACKGROUND_COLOR,
                width=5,
                height=66,
                padding=1
            )
        ]
    )

    wrapper_box = render.Box(child=flip_box, height=7, width=5)

    return wrapper_box

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

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
BACKGROUND_COLOR = "#000000"
FLIP_BACKGROUND_COLOR = "#333333"

TEXT_COLOR = "#EEEEEE"
HIGHLIGHT_TEXT_COLOR = "#FFFFFF"
DARKER_TEXT_COLOR = "#757575"
POSITIVE_TEXT_COLOR = "#57ab5ab8"
NEGATIVE_TEXT_COLOR = "#f443365c"
DEFAULT_FONT = "tom-thumb"

POSITIVE_PLOT_BORDER = "#57ab5a"
NEGATIVE_PLOT_BORDER = "#f44336"
POSITIVE_PLOT_FILL = "#57ab5ab8"
NEGATIVE_PLOT_FILL = "#f4433670"

# Timings
FLIP_DIGIT_DURATION = 50
END_DURATION = 100000

# Easing
EASE_IN = "ease_in"
EASE_OUT = "ease_out"
EASE_IN_OUT = "ease_in_out"

def main(config):
    stack = render.Stack(
        children=[
          animate_history_chart(),
          animate_currency_info()
        ]
    )

    return render.Root(child = stack)

def currency_info():
    today_price = 1
    yesterday_price = 2

    fomatted_today_price = "{}".format(today_price);
    yesterday_today_variation = today_price - yesterday_price
    formatted_variation = str(yesterday_today_variation)[0:7]
    is_negative = str(yesterday_today_variation).find("-") > -1
    variation_text_color = POSITIVE_TEXT_COLOR if is_negative else NEGATIVE_TEXT_COLOR

    divider = render.Box(width=5, height=8)

    origin_currency = render.Row(
        children=[
            render.Text("1", color = TEXT_COLOR, font = DEFAULT_FONT),
            render.Text("USD", color = DARKER_TEXT_COLOR, font = DEFAULT_FONT),
        ]
    )

    target_currency = render.Row(
        main_align="end",
        cross_align="end",
        children=[
            flip_display(5.21),
            render.Box(width=1, height=8),
            render.Text("BRL", color = DARKER_TEXT_COLOR, font = DEFAULT_FONT)
        ]
    )

    currency_variation = render.Text(
        formatted_variation,
        font = DEFAULT_FONT,
        color = variation_text_color
    )

    return render.Row(
        expanded=True,
        main_align="space_between",
        cross_align="end",
            children=[
                divider,
                render.Column(
                    main_align="end",
                    cross_align="end",
                    children=[
                        origin_currency,
                        target_currency,
                        currency_variation
                    ]
                ),
            ]
        )

def animate_currency_info():
    return render.Stack(
            children = [
                # Currency price history animation
                animation.Transformation(
                    child = currency_info(),
                    duration = 20,
                    delay = 0,
                    origin=animation.Origin(0, 0),
                    keyframes = [
                         animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(-40, 6)],
                            curve=EASE_IN_OUT
                        ),
                         animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(-1, 6)],
                        ),
                    ],
                ),
                # End animation
                end_animation(),
            ]
        )

def history_chart():
    return render.Plot(
        data = [
            (0, 2),
            (1, 3),
            (2, 1),
            (3, -1),
            (4, 0)
        ],
        width = 26,
        height = 22,
        fill = True,
        color = POSITIVE_PLOT_BORDER,
        color_inverted = NEGATIVE_PLOT_BORDER,
        fill_color = POSITIVE_PLOT_FILL,
        fill_color_inverted = NEGATIVE_PLOT_FILL,
        x_lim = (0, 4),
        y_lim = (-1, 3),
    )

def animate_history_chart():
    return render.Stack(
            children = [
                # Currency price history animation
                animation.Transformation(
                    child = history_chart(),
                    duration = 20,
                    delay = 0,
                    origin=animation.Origin(0, 0),
                    keyframes = [
                         animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(-5, 5), animation.Scale(0, 1)],
                            curve=EASE_IN_OUT
                        ),
                         animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(2, 5), animation.Scale(1, 1)],
                        ),
                    ],
                ),
                # End animation
                end_animation(),
            ]
        )

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
        text = render.Text(
            digit,
            color = HIGHLIGHT_TEXT_COLOR,
            font = DEFAULT_FONT
        )
        digits_children.append(text)

    numbers_column = render.Column(
        children=
        digits_children
    )

    flip_box = render.Stack(
        children = [
            render.Box(
                child = render.Stack(
                    children=[
                        # Digit animation
                        animation.Transformation(
                            child = numbers_column,
                            duration = FLIP_DIGIT_DURATION,
                            delay = 18,
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
                        # End animation
                        end_animation(),
                    ]
                ),
                color = FLIP_BACKGROUND_COLOR,
                width=5,
                height=66,
                padding=1
            )
        ]
    )

    wrapper_box = render.Box(child=flip_box,
        height=7,
        width=5
    )

    return wrapper_box

def end_animation():
    return animation.Transformation(
        child = render.Box(),
        duration = END_DURATION,
        delay = 0,
        keyframes = [],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

"""
Applet: Dólar Blue
Summary: ARS to USD exchange rate
Description: View official and blue dollar exchange rates for USD to Argentine Peso (ARS).
Author: Connick Shields
"""

load("animation.star", "animation")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

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
CACHE_TTL = 300
FLIP_DIGIT_DURATION = 50
END_DURATION = 175

# Easing
EASE_IN = "ease_in"
EASE_OUT = "ease_out"
EASE_IN_OUT = "ease_in_out"

# Constants
API_URL = "https://api.bluelytics.com.ar/v2/evolution.json"
DAYS = 30

def main(config):
    # Load config settings from mobile app, or set default
    config_days = int(config.str("days", DAYS))

    api_url = "{api}?days={days}".format(
        api = API_URL,
        days = config_days * 2,
    )

    # Get data from API
    response = http.get(api_url, ttl_seconds = CACHE_TTL)
    if response.status_code != 200:
        fail("Request failed with status %d", response.status_code)
    json_response = response.json()

    blue_prices = []
    official_prices = []

    for price in list(json_response):
        if price["source"] == "Blue":
            blue_prices.append(price["value_sell"])
        else:
            official_prices.append(price["value_sell"])

    blue_stack = render.Stack(
        children = [
            # Render animated trend graph
            animate_history_chart(blue_prices),
            # Render exchange info with flip display animation
            animate_currency_info(blue_prices, "BLUE"),
        ],
    )

    official_stack = render.Stack(
        children = [
            # Render animated trend graph
            animate_history_chart(official_prices),
            # Render exchange info with flip display animation
            animate_currency_info(official_prices, "GOV"),
        ],
    )

    final_sequence = render.Sequence(
        children = [
            blue_stack,
            official_stack,
        ],
    )

    return render.Root(child = final_sequence)

def currency_info(prices, label):
    latest_price = prices[0]
    oldest_price = prices[len(prices) - 1]
    price_variation = latest_price - oldest_price

    is_negative = str(price_variation).find("-") > -1
    if is_negative:
        price_variation = str("%d" % price_variation)
        variation_text_color = NEGATIVE_TEXT_COLOR
    else:
        price_variation = "+" + str("%d" % price_variation)
        variation_text_color = POSITIVE_TEXT_COLOR

    divider = render.Box(width = 5, height = 8)

    type_label = render.Row(
        children = [
            render.Text(label, color = DARKER_TEXT_COLOR, font = DEFAULT_FONT),
        ],
    )

    value = render.Row(
        main_align = "end",
        cross_align = "end",
        children = [
            flip_display(latest_price),
        ],
    )

    variation = render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Text(
            str(price_variation),
            font = DEFAULT_FONT,
            color = variation_text_color,
        ),
    )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            divider,
            render.Column(
                main_align = "end",
                cross_align = "end",
                children = [
                    type_label,
                    value,
                    variation,
                ],
            ),
        ],
    )

def animate_currency_info(prices, label):
    return render.Stack(
        children = [
            # Create currency info animation (based on schema configs + api data)
            animation.Transformation(
                child = currency_info(prices, label),
                duration = 20,
                delay = 0,
                origin = animation.Origin(0, 0),
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(-40, 6)],
                        curve = EASE_IN_OUT,
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [animation.Translate(-1, 6)],
                    ),
                ],
            ),
            # End animation
            end_animation(),
        ],
    )

def history_chart(prices):
    # Always use oldest baseline value for comparison
    comparison_price = prices[len(prices) - 1]

    # Get the variation for trend line
    days_value_variation = [value - comparison_price for value in prices]
    price_history = reversed(days_value_variation)

    # Render trendy line (based on schema configs + api data)
    return render.Plot(
        data = enumerate(price_history),
        width = 40,
        height = 22,
        fill = True,
        color = POSITIVE_PLOT_BORDER,
        color_inverted = NEGATIVE_PLOT_BORDER,
        fill_color = POSITIVE_PLOT_FILL,
        fill_color_inverted = NEGATIVE_PLOT_FILL,
        x_lim = (0, len(price_history) - 1),
        y_lim = (min(days_value_variation), max(days_value_variation)),
    )

def animate_history_chart(prices):
    return render.Stack(
        children = [
            # Create trend line line animation
            animation.Transformation(
                child = history_chart(prices),
                duration = 20,
                delay = 0,
                origin = animation.Origin(0, 0),
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(-5, 5), animation.Scale(0, 1)],
                        curve = EASE_IN_OUT,
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [animation.Translate(2, 5), animation.Scale(1, 1)],
                    ),
                ],
            ),
            # End animation
            end_animation(),
        ],
    )

def flip_display(value):
    price_digits = list(str("%d" % value).elems())
    display_children = []

    for digit in price_digits:
        display_children.append(flip_digit(int(digit)))

    display = render.Row(children = display_children)

    return display

def flip_digit(number):
    digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    digits_children = []

    for digit in list(digits):
        text = render.Text(
            digit,
            color = HIGHLIGHT_TEXT_COLOR,
            font = DEFAULT_FONT,
        )
        digits_children.append(text)

    numbers_column = render.Column(
        children =
            digits_children,
    )

    flip_box = render.Stack(
        children = [
            render.Box(
                child = render.Stack(
                    children = [
                        # Digit flip animation
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
                    ],
                ),
                color = FLIP_BACKGROUND_COLOR,
                width = 5,
                height = 66,
                padding = 1,
            ),
        ],
    )

    wrapper_box = render.Box(
        child = flip_box,
        height = 7,
        width = 5,
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
    days_options = [
        schema.Option(
            display = "7 Days",
            value = "7",
        ),
        schema.Option(
            display = "14 Days",
            value = "14",
        ),
        schema.Option(
            display = "30 Days",
            value = "30",
        ),
        schema.Option(
            display = "60 Days",
            value = "60",
        ),
        schema.Option(
            display = "90 Days",
            value = "90",
        ),
    ]

    blue_dollar_fields = [
        schema.Dropdown(
            id = "days",
            name = "Days",
            desc = "Days of market history",
            icon = "calendar",
            default = days_options[0].value,
            options = days_options,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = blue_dollar_fields,
    )

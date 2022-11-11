"""
Applet: Coin Prices
Summary: Show coin price
Description: Show Current exchange rate for multiple coins.
Author: alan-oliv
"""

load("render.star", "render")
load("schema.star", "schema")
load("animation.star", "animation")
load("http.star", "http")
load("humanize.star", "humanize")
load("cache.star", "cache")
load("encoding/json.star", "json")

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
CACHE_TTL = 240
FLIP_DIGIT_DURATION = 50
END_DURATION = 500

# Easing
EASE_IN = "ease_in"
EASE_OUT = "ease_out"
EASE_IN_OUT = "ease_in_out"

# Constants
COINS = ["BRL", "USD", "EUR"]
API_URL = "https://economia.awesomeapi.com.br/json/daily"
DEFAULT_FROM_COIN = "USD"
DEFAULT_TO_COIN = "BRL"
DEFAULT_DECIMAL_POINTS = "2"
DEFAULT_BID_ASK = "bid"
DAYS = 5

def main(config):
    # Load config settings from mobile app, or set defaults
    from_coin = config.str("from_coin", DEFAULT_FROM_COIN)
    to_coin = config.str("to_coin", DEFAULT_TO_COIN)
    price_precision = config.str("price_precision", DEFAULT_DECIMAL_POINTS)
    bid_ask = config.str("bid_ask", DEFAULT_BID_ASK)

    # Validate chosen options
    if from_coin == to_coin:
        coins = list(COINS)
        coins.remove(from_coin)
        to_coin = coins[0]

    api_price_url = "{api}/{from_coin}-{to_coin}/{days}".format(
        api = API_URL,
        from_coin = from_coin,
        to_coin = to_coin,
        days = DAYS,
    )

    cache_key = "price_response_{from_coin}_{to_coin}".format(
        from_coin = from_coin,
        to_coin = to_coin,
    )

    # Get data from cache or API
    cached_price_response = cache.get(cache_key)
    if cached_price_response != None:
        # Cache Hit: Displays cached data
        json_response = json.decode(cached_price_response)
    else:
        # Cache Miss: Request api and set cache
        price_response = http.get(api_price_url)
        if price_response.status_code != 200:
            fail("Request failed with status %d", price_response.status_code)
        json_response = price_response.json()
        cache.set(cache_key, json.encode(json_response), ttl_seconds = CACHE_TTL)

    prices = []

    for price in list(json_response):
        prices.append(float(price[bid_ask]))

    stack = render.Stack(
        children = [
            # Render animated five days tendency line
            animate_history_chart(prices, price_precision),
            # Render currency info with flip display animation
            animate_currency_info(prices, from_coin, to_coin, price_precision),
        ],
    )

    return render.Root(child = stack)

def currency_info(prices, from_coin, to_coin, price_precision):
    latest_price = prices[0]
    yesterday_price = prices[1]
    yesterday_today_variation = latest_price - yesterday_price

    precision_format = "#."
    for point in range(int(price_precision)):
        precision_format = precision_format + "#"

    fomatted_latest_price = humanize.float(precision_format, latest_price)
    formatted_variation = humanize.float(precision_format, yesterday_today_variation)
    is_negative = str(yesterday_today_variation).find("-") > -1
    variation_text_color = NEGATIVE_TEXT_COLOR if is_negative else POSITIVE_TEXT_COLOR

    divider = render.Box(width = 5, height = 8)

    origin_currency = render.Row(
        children = [
            render.Text("1", color = TEXT_COLOR, font = DEFAULT_FONT),
            render.Text(from_coin, color = DARKER_TEXT_COLOR, font = DEFAULT_FONT),
        ],
    )

    target_currency = render.Row(
        main_align = "end",
        cross_align = "end",
        children = [
            flip_display(fomatted_latest_price),
            render.Box(width = 1, height = 8),
            render.Text(to_coin, color = DARKER_TEXT_COLOR, font = DEFAULT_FONT),
        ],
    )

    currency_variation = render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Text(
            formatted_variation,
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
                    origin_currency,
                    target_currency,
                    currency_variation,
                ],
            ),
        ],
    )

def animate_currency_info(prices, from_coin, to_coin, price_precision):
    return render.Stack(
        children = [
            # Create currency info animation (based on schema configs + api data)
            animation.Transformation(
                child = currency_info(prices, from_coin, to_coin, price_precision),
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
    # Always using yesterday bid/ask baseline value for comparison
    comparison_price = prices[1]

    # Get the variation for tendency line
    days_value_variation = [value - comparison_price for value in prices]
    price_history = reversed(days_value_variation)

    # Render five days tendency line (based on schema configs + api data)
    return render.Plot(
        data = enumerate(price_history),
        width = 26,
        height = 22,
        fill = True,
        color = POSITIVE_PLOT_BORDER,
        color_inverted = NEGATIVE_PLOT_BORDER,
        fill_color = POSITIVE_PLOT_FILL,
        fill_color_inverted = NEGATIVE_PLOT_FILL,
        x_lim = (0, 4),
        y_lim = (min(days_value_variation), max(days_value_variation)),
    )

def animate_history_chart(prices, price_precision):
    end_animation_scale = {
        "2": 1,
        "3": 0.85,
        "4": 0.65,
    }

    return render.Stack(
        children = [
            # Create five days tendency line animation
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
                        transforms = [animation.Translate(2, 5), animation.Scale(end_animation_scale[price_precision], 1)],
                    ),
                ],
            ),
            # End animation
            end_animation(),
        ],
    )

def flip_display(value):
    price_digits = list(str(value).elems())
    display_children = []

    for digit in price_digits:
        value = digit if digit != "." else 10
        display_children.append(flip_digit(int(value)))

    display = render.Row(children = display_children)

    return display

def flip_digit(number):
    digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."]
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
    coin_options = [
        schema.Option(
            display = "Brazilian Real",
            value = "BRL",
        ),
        schema.Option(
            display = "United States Dollar",
            value = "USD",
        ),
        schema.Option(
            display = "Euro",
            value = "EUR",
        ),
    ]

    points_options = [
        schema.Option(
            display = "Two",
            value = "2",
        ),
        schema.Option(
            display = "Three",
            value = "3",
        ),
        schema.Option(
            display = "Four",
            value = "4",
        ),
    ]

    exchange_spread_options = [
        schema.Option(
            display = "Bid",
            value = "bid",
        ),
        schema.Option(
            display = "Ask",
            value = "ask",
        ),
    ]

    coin_price_fields = [
        schema.Dropdown(
            id = "from_coin",
            name = "From",
            desc = "Coin exchange origin",
            icon = "coins",
            default = coin_options[1].value,
            options = coin_options,
        ),
        schema.Dropdown(
            id = "to_coin",
            name = "To",
            desc = "Coin exchange target",
            icon = "coins",
            default = coin_options[0].value,
            options = coin_options,
        ),
        schema.Dropdown(
            id = "price_precision",
            name = "Precision",
            desc = "Values decimal points desired",
            icon = "circleDot",
            default = points_options[0].value,
            options = points_options,
        ),
        schema.Dropdown(
            id = "bid_ask",
            name = "Exchange Spread",
            desc = "Bid or Ask price",
            icon = "moneyBill",
            default = exchange_spread_options[0].value,
            options = exchange_spread_options,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = coin_price_fields,
    )

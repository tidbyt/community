"""
Applet: Crypto Tracker
Summary: Tracks crypto price
Description: Displays crypto prices in USD over the last 24 hours.
Author: Ethan Fuerst (@ethanfuerst)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_SYMBOL = "BTC"
RED_RGB = "#FF0000"
GREEN_RGB = "#00FF00"
WHITE_RGB = "#FFFFFF"

PIN = """AV6+xWcEOd0lGviFmw+gUtFJ2kA3cYVXGBwOoi903QlfeNHQiMtnYEDpI4qB6SzMwHcuMxrBP08GK/5R3835Tmuzq+Hg8y6pIExIp/G5xLeAVBnpyYnjwdDhz1nw6+BAgnUEXIO9xW0q+99cZSeRPBw86W8s9w=="""

def display_symbol(crypto_symbol):
    "returns crypto symbol render"

    return render.Marquee(
        width = 34,
        child = render.Text(
            content = crypto_symbol,
            offset = 0,
        ),
        offset_start = 0,
        offset_end = 0,
    )

def display_price(current_price, tr_format_price):
    "returns crypto price render"

    if tr_format_price and current_price >= 1000.0:
        current_price = int(current_price)
    else:
        current_price = int(current_price * 100) / 100.0

    disp_text = humanize.comma(current_price)

    if len(disp_text.partition(".")[-1]) == 1:
        disp_text += "0"

    return render.Marquee(
        width = 34,
        child = render.Text(
            content = disp_text,
            offset = 1,
        ),
        offset_start = 1,
        offset_end = 0,
    )

def display_price_change(current_price, first_price, color, tr_format_pchange):
    "returns crypto price change render"

    price_change = current_price - first_price

    if tr_format_pchange and math.fabs(price_change) >= 10.0:
        disp_text = humanize.comma(int(price_change))
    else:
        disp_text = humanize.comma(int(price_change * 100) / 100.0)

    if len(disp_text.partition(".")[-1]) == 1:
        disp_text += "0"

    return render.Marquee(
        width = 30,
        child = render.Text(
            content = disp_text,
            color = color,
            offset = 0,
        ),
        offset_start = 0,
        offset_end = 0,
    )

def display_percentage_change(current_price, first_price, color, tr_format_percent):
    "returns crypto percentage change render"

    pct_change = ((current_price / first_price) - 1) * 100

    if tr_format_percent and math.fabs(pct_change) >= 1.0:
        disp_text = humanize.comma(int(pct_change))
    else:
        disp_text = humanize.comma(int(pct_change * 100) / 100.0)

    if len(disp_text.partition(".")[-1]) == 1:
        disp_text += "0"

    return render.Marquee(
        width = 30,
        child = render.Text(
            content = disp_text + "%",
            color = color,
            offset = 1,
        ),
        offset_start = 0,
        offset_end = 0,
    )

def display_chart(c_data, x_lim, y_lim):
    "returns crypto price chart render"

    return render.Plot(
        data = c_data,  # list of tuples
        width = 65,
        height = 16,
        color = GREEN_RGB,
        color_inverted = RED_RGB,
        x_lim = x_lim,  # (x_min, x_max)
        y_lim = y_lim,  # (y_min, y_max)
        fill = True,
    )

def main(config):
    symbol = config.str("symbol", DEFAULT_SYMBOL)
    tr_format_price = config.str("tr_format_price", False) == "true"
    tr_format_pchange = config.str("tr_format_pchange", False) == "true"
    tr_format_percent = config.str("tr_format_percent", False) == "true"
    interval = "15min"

    API_KEY = secret.decrypt(PIN) or config.get("dev_api_key")
    API_URL = "https://www.alphavantage.co/query?function=CRYPTO_INTRADAY&symbol={s}&market=USD&interval={i}&outputsize=full&apikey={a}".format(s = symbol, i = interval, a = API_KEY)

    cache_name = "{}_price_data".format(symbol)
    cached_data = cache.get(cache_name)
    if cached_data != None:
        print("Hit! Displaying cached data from Alphavantage.")
        r = json.decode(cached_data)
    else:
        print("Miss! Calling Alphavantage API.")
        rep = http.get(API_URL)
        r = rep.json()

        if rep.status_code != 200:
            print("Using cached data")
            r = json.decode(cached_data)
            print("Alphavantage API request failed with status %d, using cached data", rep.status_code)

        if list(r.keys()) == ["Note"]:
            print("Using cached data")
            r = json.decode(cached_data)
            print("Alphavantage API request failed with note %d, using cached data", r["Note"])

        if list(r.keys()) == ["Error Message"]:
            print("Using cached data")
            r = json.decode(cached_data)
            print("Alphavantage API request failed with error message %d, using cached data", r["Error Message"])

        cache.set(cache_name, json.encode(r), ttl_seconds = 60 * 15)

    timeseries = r["Time Series Crypto (15min)"]

    dates = [val for val in timeseries.keys()]

    y = [float(timeseries[date]["1. open"]) for date in sorted(dates)][-96:]
    first_val = y[0]
    y_transformed = [price - first_val for price in y]

    x = [float(i) for i in range(0, len(y) + 1)]

    chart_data = [(x_val, y_val) for x_val, y_val in zip(x, y_transformed)]

    x_lim = (0.0, float(len(y_transformed)))
    y_lim = (min(y_transformed), max(y_transformed))

    price_change = y[-1] - y[0]
    if price_change < 0.0:
        color = RED_RGB
    elif price_change > 0.0:
        color = GREEN_RGB
    else:
        color = WHITE_RGB

    return render.Root(
        delay = 75,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Padding(
                                    child = display_symbol(symbol),
                                    pad = (1, 0, 0, 0),
                                ),
                                render.Padding(
                                    child = display_price_change(y[-1], y[0], color, tr_format_pchange),
                                    pad = (1, 0, 0, 0),
                                ),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    child = display_price(y[-1], tr_format_price),
                                    pad = (1, 0, 0, 0),
                                ),
                                render.Padding(
                                    child = display_percentage_change(y[-1], y[0], color, tr_format_percent),
                                    pad = (1, 0, 0, 0),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        display_chart(chart_data, x_lim, y_lim),
                    ],
                    main_align = "center",
                ),
            ],
        ),
    )

def get_schema():
    crypto_options = [
        # API allows for 150 calls/minute so there is room to add more coins here
        # Before adding coins like DOGE that are worth less than 10 cents, need to add decimals to track changes under a cent
        # These are top 5 non-stable coins by market cap as of creation
        schema.Option(
            display = "Bitcoin",
            value = "BTC",
        ),
        schema.Option(
            display = "Ethereum",
            value = "ETH",
        ),
        schema.Option(
            display = "Binance Coin",
            value = "BNB",
        ),
        schema.Option(
            display = "Cardano",
            value = "ADA",
        ),
        schema.Option(
            display = "Solana",
            value = "SOL",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "symbol",
                name = "crypto symbol",
                desc = "Crypto symbol",
                icon = "user",
                default = crypto_options[0].value,
                options = crypto_options,
            ),
            schema.Toggle(
                id = "tr_format_price",
                name = "Use Truncated Price Format",
                desc = "Truncates cents from coin price when the price is >= $1,000.",
                icon = "dollarSign",
                default = False,
            ),
            schema.Toggle(
                id = "tr_format_pchange",
                name = "Use Truncated Price Change Format",
                desc = "Truncates cents from price change when absolute value of price change >= $10.",
                icon = "dollarSign",
                default = False,
            ),
            schema.Toggle(
                id = "tr_format_percent",
                name = "Use Truncated Percentage Change Format",
                desc = "Truncates decimals from percent change when absolute value of percent change is >= 1%.",
                icon = "dollarSign",
                default = False,
            ),
        ],
    )

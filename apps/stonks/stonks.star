"""
Applet: Stonks
Summary: Fetches stock data from polygon.io
Description: Shows stock price for given ticker and optionally portfolio value, see https://stonks.market to get started
Author: harrisonpage + tfarnon

v1.0
Released 15-Sep-2024.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# 30 minute cache
CACHE_TIME = 1800

# increase value to clear cache
VERSION = "v2"

DEFAULT_SYMBOL = "AAPL"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apikey",
                name = "Polygon.io API Key",
                desc = "Basic (free) API tier is fine",
                icon = "moneyBill",
            ),
            schema.Text(
                id = "symbol",
                name = "Symbol",
                desc = "e.g. GOOG, APPL, etc.",
                icon = "moneyBill",
            ),
            schema.Text(
                id = "portfolio",
                name = "Shares Owned",
                desc = "# of shares you own",
                icon = "dollarSign",
            ),
            schema.Color(
                id = "symbol_color",
                name = "Symbol Color",
                desc = "Color of ticker symbol",
                icon = "brush",
                default = "#00FF00",
            ),
            schema.Color(
                id = "price_color",
                name = "Price Color",
                desc = "Color of stock price",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Color(
                id = "portfolio_color",
                name = "Portfolio Color",
                desc = "Color of portfolio",
                icon = "brush",
                default = "#FF0000",
            ),
        ],
    )

def format_currency(amount):
    """Format currency for US"""
    str_amount = str(amount).split(".")
    dollars = str_amount[0]
    cents = str_amount[1] if len(str_amount) > 1 else "00"
    cents = (cents + "0")[:2]
    return "${}.{}".format(dollars, cents)

def get_stock_quote(url, symbol):
    """Fetch quote from polygon.io or cache"""
    cache_key = "stonks-{0}-{1}".format(symbol, VERSION)
    cached_data = cache.get(cache_key)
    if cached_data != None:
        cache_res = json.decode(cached_data)
        return cache_res
    res = http.get(url)
    if res.status_code != 200:
        return {"error": "polygon.io API failed with status " + res.status_code}
    payload = res.json()
    cache.set(cache_key, json.encode(payload), ttl_seconds = CACHE_TIME)
    return payload

def is_valid_float(value):
    # all these checks are nice to have when using pixlet
    if type(value) == "string":
        if value == "":
            return False
        allowed_chars = "0123456789."
        for i in range(len(value)):
            if value[i] not in allowed_chars:
                return False
        if value.count(".") > 1:
            return False
        if value == ".":
            return False
        value = float(value)
        if value < 0:
            return False
        return True
    return False

def main(config):
    symbol = config.get("symbol", DEFAULT_SYMBOL)

    # avoid error if field is blank or otherwise bogus
    raw_portfolio = config.get("portfolio", "")
    if not is_valid_float(raw_portfolio):
        portfolio = 0
    else:
        portfolio = float(raw_portfolio)

    # your polygon.io API key
    api_key = config.get("apikey", 0)
    if not api_key:
        return render.Root(
            child = render.Column(
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = "STONKS!",
                                font = "6x13",
                                color = "#FFFFFF",
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = "GET STARTED: HTTPS://STONKS.MARKET",
                                    font = "5x8",
                                    color = "#00FF00",
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        )

    # https://polygon.io/docs/stocks/get_v1_open-close__stocksticker___date
    url = "https://api.polygon.io/v2/aggs/ticker/" + symbol + "/prev?adjusted=true&apiKey=" + api_key

    payload = get_stock_quote(url, symbol)

    # render error inline
    if "error" in payload:
        return render.Root(
            child = render.Column(
                main_align = "space_around",
                cross_align = "center",
                children = render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = payload["error"],
                            font = "6x10",
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

    closing_price = float(payload["results"][0]["c"])
    price_formatted = format_currency(closing_price)

    font = "6x13"
    if portfolio:
        # make room for optional portfolio data
        font = "6x10"

    rows = [
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "{0}".format(symbol),
                    font = "6x13",
                    color = config.get("symbol_color", "#00FF00"),
                ),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = price_formatted,
                    font = font,
                    color = config.get("price_color", "#FFFFFF"),
                ),
            ],
        ),
    ]

    if portfolio:
        result = portfolio * closing_price
        integer_part = int(result)
        decimal_part = int((result - integer_part) * 100)
        content = format_currency(".".join([str(integer_part), str(decimal_part)]))
        font = "6x10"

        # eat the rich
        if len(content) > 10:
            font = "5x8"

        rows.append(
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = content,
                        font = font,
                        color = config.get("portfolio_color", "#FFFFFF"),
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            cross_align = "center",
            children = rows,
        ),
    )

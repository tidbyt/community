"""
Applet: BitcoinTicker
Summary: Price of Bitcoin
Description: Shows the price of Bitcoin. Choose to convert into USD, EUR, GBP, CNY, JPY, XAU (Gold) and many more.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_CURRENCY = "usd"
DEFAULT_PERIOD = "24h"
DEFAULT_SHOW_CURRENCY_ABBRIVIATION = True

COLOR_BITCOIN = "#ffa500"
COLOR_RED = "#f00"
COLOR_GREEN = "#0f0"
COLOR_DIMMED = "#fff9"

FONT = "tom-thumb"

def print_market_data(currency, period, show_currency_abriviation = DEFAULT_SHOW_CURRENCY_ABBRIVIATION):
    data = get_market_data()
    percentage = get_percentage(data["price_change_percentage_{}_in_currency".format(period)][currency])
    price = humanize.comma(int(data["current_price"][currency]))
    currency_abbriviation = currency.upper() if show_currency_abriviation else ""
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(
                        content = "Bitcoin",
                        font = FONT,
                        color = COLOR_BITCOIN,
                    ),
                    render.Text(
                        content = "{}%".format(percentage),
                        font = FONT,
                        color = COLOR_RED if percentage < 0 else COLOR_GREEN,
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Text(
                                content = price,
                                font = FONT,
                            ),
                            render.Text(
                                content = currency_abbriviation,
                                font = FONT,
                                color = COLOR_DIMMED,
                            ),
                        ],
                    ),
                    render.Text(
                        content = name_large_number(int(data["market_cap"][currency])),
                        font = FONT,
                    ),
                ],
            ),
        ],
    )

def print_market_chart(currency, period):
    data = get_market_chart(currency, period)
    return render.Plot(
        data = [(p[0], p[1]) for p in data],
        width = 64,
        height = 19,
        color = COLOR_GREEN,
        color_inverted = COLOR_RED,
        fill = True,
    )

def get_percentage(value):
    if (value < 1):
        return int(value * 100) / 100
    if (value < 10):
        return int(value * 10) / 10
    return int(value)

def get_market_data():
    url = "https://api.coingecko.com/api/v3/coins/bitcoin?developer_data=false&community_data=false&tickers=false&localization=false"
    return get_data(url)["market_data"]

def get_market_chart(currency, period):
    days = convert_period_to_days(period)
    url = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency={}&days={}&precision=0".format(currency, days)
    return get_data(url)["prices"]

def get_data(url, ttl_seconds = 60 * 5):
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Coingecko request failed with status %d", response.status_code)
    return response.json()

def convert_period_to_days(period):
    if period == "24h":
        return 1
    if period == "1y":
        return 365
    return period.replace("d", "")

def name_large_number(number):
    number_length = len(str(int(number)))
    if (number_length > 15):
        return "{}Q".format(int(number / 10e14))
    if (number_length > 12):
        return "{}T".format(int(number / 10e11))
    if (number_length > 9):
        return "{}B".format(int(number / 10e8))
    if (number_length > 6):
        return "{}M".format(int(number / 10e5))
    return int(number)

def main(config):
    currency = config.str("currency", DEFAULT_CURRENCY)
    period = config.str("period", DEFAULT_PERIOD)
    show_currency_abbriviation = config.bool("show_currency_abbriviation", DEFAULT_SHOW_CURRENCY_ABBRIVIATION)

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                print_market_data(currency, period, show_currency_abbriviation),
                print_market_chart(currency, period),
            ],
        ),
    )

def get_schema():
    currencies = ["usd", "aed", "ars", "aud", "bch", "bdt", "bhd", "bmd", "bnb", "brl", "btc", "cad", "chf", "clp", "cny", "czk", "dkk", "dot", "eos", "eth", "eur", "gbp", "hkd", "huf", "idr", "ils", "inr", "jpy", "krw", "kwd", "lkr", "ltc", "mmk", "mxn", "myr", "ngn", "nok", "nzd", "php", "pkr", "pln", "rub", "sar", "sek", "sgd", "thb", "try", "twd", "uah", "vef", "vnd", "xag", "xau", "xdr", "xlm", "xrp", "yfi", "zar", "bits", "link"]

    currency_options = []
    for c in currencies:
        currency_options.append(schema.Option(display = c.upper(), value = c))

    period_options = [
        schema.Option(display = "24 hours", value = "24h"),
        schema.Option(display = "1 week", value = "7d"),
        schema.Option(display = "2 weeks", value = "14d"),
        schema.Option(display = "1 month", value = "30d"),
        schema.Option(display = "2 months", value = "60d"),
        schema.Option(display = "200 days", value = "200d"),
        schema.Option(display = "1 year", value = "1y"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "currency",
                name = "Currency",
                desc = "Show price in this currency.",
                icon = "coins",
                default = currency_options[0].value,
                options = currency_options,
            ),
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "Show chart in this period.",
                icon = "calendar",
                default = period_options[0].value,
                options = period_options,
            ),
            schema.Toggle(
                id = "show_currency_abbriviation",
                name = "Show currency abbriviation?",
                desc = "Enable this option to show the currency abbriviation.",
                icon = "circle",
                default = True,
            ),
        ],
    )

"""
Applet: Stock Ticker
Summary: 3 stocks scrolling
Description: This is a simple stock ticker app, that will display a stock ticker for 3 stock symbols.  If you want more, spin up a second copy of the app to have more stocks tick.
Author: hollowmatt
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

STOCK_QUOTE_URL = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol="
SYMBOL_B64 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAIxJREFUOE
9jZGBg+M+ABl6UMqMLgfkS3X8xxBmRDYBpxKYQpBObPNwAkCQujdhcCFMLNgCf5u8f9jBwCrhg
OB2mB6cBII3oANkguAEvSpn/ozsd2VZcbFiYMJJiALawoI0BIJsIhQFeLyA7lawwIMkAbOmAmF
igXjqA5QVcqRFbSkRWS73MhBxwpGRnAGAwmUGS9KHUAAAAAElFTkSuQmCC
""")

def main(config):
    APIKEY = config.get("ALPHA_KEY", None)
    if APIKEY:
        ALPHA_KEY = "&apikey=" + APIKEY

        # do good stuff
        if (config.get("stock_1")):
            SYMBOLS = [
                config.get("stock_1", None),
                config.get("stock_2", None),
                config.get("stock_3", None),
            ]
        else:
            SYMBOLS = ["GOOGL", "AMZN", "WFC"]

        rate_cached = cache.get("sym_rate")
        if rate_cached != None:
            msg = int(rate_cached)
        else:
            msg = ""
            for a in SYMBOLS:
                full_url = STOCK_QUOTE_URL + a + ALPHA_KEY
                rep = http.get(full_url)
                if rep.status_code != 200:
                    fail("API request failed with status %d", rep.status_code)
                rate = rep.json()["Global Quote"]["05. price"]
                msg = msg + a + ": $" + str(rate[:-2]) + " ... "
            cache.set("sym_rate", msg, ttl_seconds = 240)
    else:
        # output error
        msg = "%s API key is required"
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = SYMBOL_B64),
                    render.Marquee(
                        width = 32,
                        child = render.Text(msg),
                        offset_start = 17,
                        offset_end = 32,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stock_1",
                name = "Stock Symbol 1",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "MSFT",
            ),
            schema.Text(
                id = "stock_2",
                name = "Stock Symbol 1",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "IBM",
            ),
            schema.Text(
                id = "stock_3",
                name = "Stock Symbol 1",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "PTON",
            ),
            schema.Text(
                id = "ALPHA_KEY",
                name = "Alpha Vantage API Key",
                desc = "API key for Alpha Vantage (https://www.alphavantage.co)",
                icon = "userGear",
                default = "",
            ),
        ],
    )

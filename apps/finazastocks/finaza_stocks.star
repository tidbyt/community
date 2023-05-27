"""
Applet: Finaza Stocks
Summary: Display Stock/ETF ticker
Description: Display Stock Ticker. No API Key Required. Configure upto 5 Symbols.
Author: suniltaneja
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#STOCK_QUOTE_URL = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol="
STOCK_QUOTE_URL = "https://www.finaza.io/api/v1/multiquote?symbols=AAPL,MSFT,GOOG,TSLA,NVDA,AMZN&key=tidbyt"
SYMBOL_B64 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAIxJREFUOE
9jZGBg+M+ABl6UMqMLgfkS3X8xxBmRDYBpxKYQpBObPNwAkCQujdhcCFMLNgCf5u8f9jBwCrhg
OB2mB6cBII3oANkguAEvSpn/ozsd2VZcbFiYMJJiALawoI0BIJsIhQFeLyA7lawwIMkAbOmAmF
igXjqA5QVcqRFbSkRWS73MhBxwpGRnAGAwmUGS9KHUAAAAAElFTkSuQmCC
""")

def main(config):
    APIKEY = config.get("FINAZA_API_KEY", None)
    if APIKEY:
        ALPHA_KEY = "&apikey=" + APIKEY
        print("%s %s" % ("Hello", "World"))

        # get working symbols
        if (config.get("stock_1")):
            SYMBOLS = [
                config.get("stock_1", None),
                config.get("stock_2", None),
                config.get("stock_3", None),
                config.get("stock_4", None),
                config.get("stock_5", None),
            ]
        else:
            SYMBOLS = ["GOOG", "AMZN", "MSFT", "TSLA", "NVDA", "AAPL"]

        rate_cached = cache.get("sym_rate")
        print(SYMBOLS)
        print(ALPHA_KEY)

        full_url = ""
        if rate_cached != None:
            print("rate_cached")
            msg = rate_cached
        else:
            msg = ""
            full_url = STOCK_QUOTE_URL
            print(full_url)
            rep = http.get(full_url)

            #print(rep.json())
            if rep.status_code != 200:
                fail("API request failed with status %d", rep.status_code)
            else:
                print(rep.json()["quotes"][0]["symbol"])
                for a in rep.json()["quotes"]:
                    msg = msg + a["symbol"] + ": $" + str(a["latestPrice"]) + " | "
                print(msg)
            cache.set("sym_rate", msg, ttl_seconds = 500)
    else:
        # output error
        msg = "%s API key is required"
        msg = "FINAZA"
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = SYMBOL_B64),
                    render.Marquee(
                        width = 64,
                        child = render.Text(msg, font = "6x13", color = "#fa0"),
                        offset_start = 0,
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
                default = "AAPL",
            ),
            schema.Text(
                id = "stock_3",
                name = "Stock Symbol 1",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "NVDA",
            ),
            schema.Text(
                id = "stock_4",
                name = "Stock Symbol 4",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "PTON",
            ),
            schema.Text(
                id = "stock_5",
                name = "Stock Symbol 5",
                desc = "Symbol for first stock",
                icon = "tag",
                default = "BRK.B",
            ),
            schema.Text(
                id = "FINAZA_API_KEY",
                name = "FINAZA API Key",
                desc = "API key for Finaza (https://www.finaza.io/)",
                icon = "userGear",
                default = "0GVN233FU035E1JR",
            ),
        ],
    )

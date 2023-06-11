"""
Applet: Finaza Stocks
Summary: Display Stocks and ETFs ticker on Tidbyt.
Description: Display Stock Ticker. No API Key Required. Configure upto 5 Symbols.
Author: Sunil Taneja
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STOCK_QUOTE_URL = "https://www.finaza.io/api/v1/multiquote?symbols=<symbols>&key=tidbyt"
SYMBOL_B64 = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAIxJREFUOE
9jZGBg+M+ABl6UMqMLgfkS3X8xxBmRDYBpxKYQpBObPNwAkCQujdhcCFMLNgCf5u8f9jBwCrhg
OB2mB6cBII3oANkguAEvSpn/ozsd2VZcbFiYMJJiALawoI0BIJsIhQFeLyA7lawwIMkAbOmAmF
igXjqA5QVcqRFbSkRWS73MhBxwpGRnAGAwmUGS9KHUAAAAAElFTkSuQmCC
""")

P_LOCATION = "location"
DEFAULT_TIMEZONE = "America/New_York"

def main(config):
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}

    timezone = location.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )
    now = config.get("time")
    now = (time.parse_time(now) if now else time.now()).in_location(timezone)

    #now_date = now.format("Mon 2 Jan 2006")
    now_date = now.format("2 Jan 2006")

    if True:
        print("%s %s" % ("Program", "Started.."))

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
            SYMBOLS = ["GOOG", "AMZN", "MSFT", "TSLA", "NVDA", "AAPL"]  # default symbols

        #rate_cached = cache.get("sym_rate")

        # remove any empty symbols
        SYMBOLS = [x for x in SYMBOLS if x != None]

        # convert python string list to comma separated string and remove last comma from string
        SYMBOLS = ",".join(SYMBOLS).rstrip(",")

        # replace <symbols> in URL with comma separated string
        STOCK_QUOTE_URL_FINAL = STOCK_QUOTE_URL.replace("<symbols>", SYMBOLS)

        print(SYMBOLS)

        msg = ""
        rep = http.get(STOCK_QUOTE_URL_FINAL, ttl_seconds = 500)

        #print(rep.json())
        if rep.status_code != 200:
            msg = "Please configure symbols in the applet settings."
            fail("API request failed with status %d", rep.status_code)
        else:
            for stock in rep.json()["quotes"]:
                msg = msg + stock["symbol"] + ":$" + str(stock["latestPrice"]) + " "
            msg = msg.rstrip(" ")
            print(msg)
    else:
        msg = "Please configure symbols in the applet settings."

    return render.Root(
        child = render.Box(
            render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            #render.Padding( child=render.Image(src = SYMBOL_B64),  pad = (1, 0, 2, 0)),
                            render.Padding(child = render.Circle(
                                color = "#0ff",
                                diameter = 14,
                                child = render.Circle(color = "#666", diameter = 10, child = render.Text("F")),
                            ), pad = (0, 0, 0, 0)),
                            render.Padding(
                                pad = (0, 0, 0, 0),
                                child = render.Text(
                                    content = now_date,
                                    font = "tom-thumb",
                                    color = "#0ff",
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                width = 64,
                                height = 64,
                                child = render.Text(msg, font = "6x13", color = "#fa0"),
                                offset_start = 10,
                                offset_end = 32,
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = P_LOCATION,
                name = "Location",
                desc = "Location for the display of date and time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "stock_1",
                name = "Stock Symbol 1",
                desc = "Symbol for stock",
                icon = "tag",
                default = "MSFT",
            ),
            schema.Text(
                id = "stock_2",
                name = "Stock Symbol 2",
                desc = "Symbol for stock",
                icon = "tag",
                default = "AAPL",
            ),
            schema.Text(
                id = "stock_3",
                name = "Stock Symbol 3",
                desc = "Symbol for stock",
                icon = "tag",
                default = "NVDA",
            ),
            schema.Text(
                id = "stock_4",
                name = "Stock Symbol 4",
                desc = "Symbol for stock",
                icon = "tag",
                default = "PTON",
            ),
            schema.Text(
                id = "stock_5",
                name = "Stock Symbol 5",
                desc = "Symbol for stock",
                icon = "tag",
                default = "BRK.B",
            ),
        ],
    )

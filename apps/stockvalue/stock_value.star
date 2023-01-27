"""
Applet: Stock Value
Summary: Portfolio value
Description: This app will allow you track the value of your portfolio for a single stock.
Author: gshipley
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

STOCK_PRICE_URL = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol="
DEFAULT_SHARES = 1
DEFAULT_SYMBOL = "IBM"

DOLLAR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAA
Cxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAGtSURBVDhPpZPNK4RRFMaf9y1KrCQLG2ZK
1iLZsrKTslXSZCRF+QOEtWLhY14S5Q9goaymLOxIliwmLCRLH0kKv3PvfTNDkjzT6T33POecue
fjRvqKFbUrVl6RevWuFmeLdIle1JsKGtepswV8JlhQjWq1hJZDSsguic4Jivi1kaAfWxbZ0JMm
Na1n9JDAgut0gFM7lindaEuzhJZjhnRNGsZnEZ9TPaovTSKtKUHukU5vCEg04KQc5uN9EztGoe
YTtByVbzonQ6Ju7jCPVoVsw+/AvzquoBFusgHfEbuGWc127RSJMpCHaA0EPvCd45txnMH7liw2
huhF9ipqfnO9qEZbxnmAFmY0qgtPAvO1GGJjrtKCnAfKI9Ixtlu+6zTuDnaVUhsD62ExxMbhWI
m8rvXiRjfB6YxEOa674slKWAmXSFs4fyJmsGOUkFcPpyN8mj0RYDHEWglFpN/NOUWiQXp/xaiK
dHwfvgvrjieB+VoMsTHtKGDKuiVJ0eq2cJh/sEWrR4a4iW2ph/fNhljw0yKtMgGTcnxbJMM/Vv
nnx2RzTsf762Mqx5+es/QBsMaX7pbQA0YAAAAASUVORK5CYII=
""")

def main(config):
    DEFAULT_API_KEY = secret.decrypt("AV6+xWcEoxaMY+yAVrWhOa/VWxu11stEvJIV+akY8ilogee67GPOhvO9HP360IQlHd5Aj9MTVP/NXllxHIV1AyD/KvgQU4vMpZ7YWpDhwhVjtISncPqnTsrzBBkrI1axvvI4yq77ZKTIbcdrsktXIoF1/w8Ckw==")

    price_cached = cache.get("price")

    if DEFAULT_API_KEY == None:
        DEFAULT_API_KEY = config.str("alphavantage", "demo")

    if price_cached != None:
        price = float(price_cached)
    else:
        rep = http.get(STOCK_PRICE_URL + config.str("symbol", DEFAULT_SYMBOL) + "&apikey=" + config.str("API_KEY", DEFAULT_API_KEY))

        if rep.status_code != 200:
            fail("Request failed with status %d", rep.status_code)
        price = rep.json()["Global Quote"]["05. price"]
        cache.set("price", str(float(price)), ttl_seconds = 43200)

    value = (float(price) * int(config.str("shares", DEFAULT_SHARES)))
    total = humanize.float("#,###.", value)

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = DOLLAR_ICON),
                    render.Text(total),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "symbol",
                name = "Symbol?",
                desc = "What stock symbol to track?",
                icon = "chartLine",
            ),
            schema.Text(
                id = "shares",
                name = "Number of shares",
                desc = "How many shares do you have?",
                icon = "hashtag",
            ),
            schema.Text(
                id = "alphavantage",
                name = "API KEY",
                desc = "API key for Alpha Vantage (https://www.alphavantage.co)",
                icon = "key",
            ),
        ],
    )

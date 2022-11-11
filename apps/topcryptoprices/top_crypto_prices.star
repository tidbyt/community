"""
Applet: Top Crypto Prices
Summary: Top Crypto USD Prices
Description: This app shows the latest prices (USD) and price changes for the top cryptocurrencies. It is a very simple app, but does exactly what I need and what I bought the Tidbyt for in the first place. Prices are updated through the free Coingecko API at a maximum rate of once per minute.
Author: playak

Version: 1.1
Date: 2022-11-09
Comments: Written to display the price info of top cryptocurrencies on a Tidbyt screen. We manually exclude stable coins and wrapped coins (so we only need one API call).
Copyright: © 2022 Jeroen Houttuin, Playak - jeroen@playak.com - https://playak.com
"""

# CONFIG
TTL = 60  # time to live for the API cache. Be nice to the free Coingecko API provider!
PEGGEDCOINS = " USDT USDC BUSD STETH DAI FRAX WBTC USDP GUSD TUSD CUSDC USDD CUSDT USDD PAXG XAUT "  # ignore pegged tokens
DEFAULTDELAY = "2000"
DEFAULTNUMCOINS = "5"
DEFAULTEXCLUDES = "SHIB BSV"  # SHIB because it messes up formatting and I cannot solve it. BSV for obvious reasons.
DEFAULTCURRENCY = "USD"
DEFAULTEXCLUDEPEGGED = True
DEFAULTSHOWCREDITS = False

# LOAD MODULES
load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("math.star", "math")
load("schema.star", "schema")

# INIT
credits = ["Data:Coingecko", "Code:Playak"]  # Credits required for using free Coingecko API
DEBUG = 0
COINCOLORS = {}  # define matching font colors for top coins
COINCOLORS["BTC"] = "#FF9900"
COINCOLORS["ETH"] = "#545B83"
COINCOLORS["XRP"] = "#7E8286"
COINCOLORS["BNB"] = "#F0BA0F"
COINCOLORS["DOGE"] = "#BBA033"
COINCOLORS["ADA"] = "#286FD4"
COINCOLORS["SOL"] = "#7C60EC"
COINCOLORS["MATIC"] = "#8247E5"
COINCOLORS["DOT"] = "#E6017A"
COINCOLORS["SHIB"] = "#FFA40B"
COINCOLORS["TRON"] = "#D3655E"
COINCOLORS["AVAX"] = "#E84142"
COINCOLORS["LTC"] = "#838383"
COINCOLORS["LINK"] = "#295ADA"
COINCOLORS["ETC"] = "#3AB539"
COINCOLORS["CRO"] = "#284A77"
COINCOLORS["XMR"] = "#F26922"
COINCOLORS["BCH"] = "#07C18E"
COINCOLORS["FLOW"] = "#00EF8B"
COINCOLORS["HT"] = "#38AD5A"
COINCOLORS["LUNC"] = "#F9D65D"
COINCOLORS["CHZ"] = "#AF0F2F"
COINCOLORS["APE"] = "#1556DF"
COINCOLORS["FTT"] = "#01A7C3"
COINCOLORS["SAND"] = "#FDFC07"
COINCOLORS["XTZ"] = "#2C7DF7"
COINCOLORS["MANA"] = "#D7D1C7"
COINCOLORS["AAVE"] = "#9968A9"
COINCOLORS["KCS"] = "#019CE2"
COINCOLORS["LDO"] = "#EA857E"
COINCOLORS["OMI"] = "#B5BBC1"
COINCOLORS["TKX"] = "#F69A4B"
COINCOLORS["AXS"] = "#9C588B"
COINCOLORS["1INCH"] = "#2E3D5E"
COINCOLORS["BSV"] = "#EAB300"
COINCOLORS["ELG"] = "#70BFFF"
COINCOLORS["BTT"] = "#663399"
COINCOLORS["MKR"] = "#18AB9C"
COINCOLORS["XEC"] = "#1160B5"
COINCOLORS["CAKE"] = "#D78D55"
COINCOLORS["OSMO"] = "#9B10CB"
COINCOLORS["GT"] = "#D35858"
COINCOLORS["BTSE"] = "#197AD3"
COINCOLORS["KLAY"] = "#5B534B"
COINCOLORS["ZEC"] = "#0290FF"

# MAIN
def main(config):
    currency = config.get("currency", "USD")
    API = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=" + currency + "&order=market_cap_desc&per_page=100"  # get more coins than needed, to compensate for excluded coins
    cachename = "cachedjson" + currency  # keep once cache per currency
    cachedjson = cache.get(cachename)
    if cachedjson != None:
        if DEBUG:
            print("Displaying cached coin market data.")
    else:
        if DEBUG:
            print("Cache needs refresh. Calling market data API.")
        resp = http.get(API)
        if resp.status_code != 200:
            fail("API request failed with status %d", resp.status_code)
        cachedjson = json.encode(resp.json())
        cache.set(cachename, cachedjson, ttl_seconds = TTL)
    COINS = []
    counter = 0
    BLACKLIST = " "  # start with a space
    if config.bool("excludepegged", DEFAULTEXCLUDEPEGGED):
        BLACKLIST += PEGGEDCOINS
    if len(config.get("excludes", DEFAULTEXCLUDES)) > 0:
        BLACKLIST += config.get("excludes", DEFAULTEXCLUDES)
    BLACKLIST += " "  # end with a space
    print(BLACKLIST)
    for coininfo in json.decode(cachedjson):
        if " " + coininfo["symbol"].upper() + " " not in BLACKLIST.upper() and counter < int(config.get("numcoins", DEFAULTNUMCOINS)):
            COINS.append({"rank": int(coininfo["market_cap_rank"]), "ticker": coininfo["symbol"].upper(), "price": coininfo["current_price"], "change": coininfo["price_change_percentage_24h"]})
            counter += 1
    if DEBUG > 1:
        print(COINS)
    coinlines = []
    for coininfo in COINS:
        coinlines.append(renderbox(coininfo))
    if config.bool("showcredits", DEFAULTSHOWCREDITS):
        coinlines.append(renderbox(credits, color = "#AEA"))
    if DEBUG > 1:
        print(coinlines)
    return render.Root(
        render.Animation(
            children = coinlines,
        ),
        delay = int(config.get("delay", DEFAULTDELAY)),
    )

# FUNCTIONS
def renderpercentage(p):
    color = "#888"
    if p > 0.1:
        color = "#07C18E"
    elif p < -0.1:
        color = "#FF5550"
    pabs = math.fabs(p)
    if pabs > 10:
        decimals = 1
    else:
        decimals = 2
    fact = math.pow(10, decimals)
    p = math.round(p * fact) / fact
    return render.Text(str(p) + "%", color = color)

def renderprice(p):
    decimals = -1
    if p >= 1000:
        p = int(p)
    else:
        p = toprecision(p, 4)
    pstr = str(p)
    if len(pstr) > 9:  # sometimes a really long and ugly price format gets through. truncate it. if BTC gets above 1B USD, I don't care about this tool anymore :)
        pstr = pstr[0:8]
    return render.Text(pstr)

def rendertext(msg, color = "#FFF"):
    return render.Text(msg, color)

def renderbox(coin, color = "#FFF"):
    if DEBUG:
        print(coin)
    if "price" in coin:  # coin["price"] is set. must be coin data
        children = [
            render.Text(coin["ticker"], color = coincolor(coin["ticker"]), font = "6x13"),
            renderprice(coin["price"]),
            renderpercentage(coin["change"]),
        ]
    else:  # must be some lines of text, ie the credits
        children = []
        for textline in coin:
            children.append(render.Text(textline, color = color, font = "tom-thumb"))
    toreturn = render.Box(
        render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = children,
        ),
        color = "#000",  # black background, to clean the rest of the screen
    )
    return toreturn

def toprecision(number, precision):  # get any number and show only the n most significant digits
    if number == 0:
        return 0
    exponent = math.floor(math.log(math.fabs(number) + 1, 10))
    significand = math.round((number / math.pow(10, exponent)) * math.pow(10, precision)) / math.pow(10, precision)
    return significand * math.pow(10, exponent)

def coincolor(ticker):
    toreturn = "#AAA"
    if ticker in COINCOLORS:
        toreturn = COINCOLORS[ticker]
    return toreturn

def get_schema():
    delayoptions = [
        schema.Option(
            display = "1 second",
            value = "1000",
        ),
        schema.Option(
            display = "2 seconds",
            value = "2000",
        ),
        schema.Option(
            display = "3 seconds",
            value = "3000",
        ),
        schema.Option(
            display = "5 seconds",
            value = "5000",
        ),
        schema.Option(
            display = "10 seconds",
            value = "10000",
        ),
    ]
    numcoinoptions = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "20",
            value = "20",
        ),
        schema.Option(
            display = "50",
            value = "50",
        ),
    ]
    currencyoptions = [
        schema.Option(
            display = "AUD",
            value = "AUD",
        ),
        schema.Option(
            display = "BRL",
            value = "BRL",
        ),
        schema.Option(
            display = "CAD",
            value = "CAD",
        ),
        schema.Option(
            display = "CHF",
            value = "CHF",
        ),
        schema.Option(
            display = "CNY",
            value = "CNY",
        ),
        schema.Option(
            display = "CZK",
            value = "CZK",
        ),
        schema.Option(
            display = "DKK",
            value = "DKK",
        ),
        schema.Option(
            display = "EUR",
            value = "EUR",
        ),
        schema.Option(
            display = "GBP",
            value = "GBP",
        ),
        schema.Option(
            display = "HUF",
            value = "HUF",
        ),
        schema.Option(
            display = "IDR",
            value = "IDR",
        ),
        schema.Option(
            display = "ILS",
            value = "ILS",
        ),
        schema.Option(
            display = "INR",
            value = "INR",
        ),
        schema.Option(
            display = "JPY",
            value = "JPY",
        ),
        schema.Option(
            display = "KRW",
            value = "KRW",
        ),
        schema.Option(
            display = "MXN",
            value = "MXN",
        ),
        schema.Option(
            display = "NOK",
            value = "NOK",
        ),
        schema.Option(
            display = "NZD",
            value = "NZD",
        ),
        schema.Option(
            display = "PLN",
            value = "PLN",
        ),
        schema.Option(
            display = "RUB",
            value = "RUB",
        ),
        schema.Option(
            display = "SEK",
            value = "SEK",
        ),
        schema.Option(
            display = "SGD",
            value = "SGD",
        ),
        schema.Option(
            display = "THB",
            value = "THB",
        ),
        schema.Option(
            display = "TRY",
            value = "TRY",
        ),
        schema.Option(
            display = "TWD",
            value = "TWD",
        ),
        schema.Option(
            display = "USD",
            value = "USD",
        ),
        schema.Option(
            display = "ZAR",
            value = "ZAR",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "currency",
                name = "Currency",
                desc = "Pricing Currency.",
                icon = "moneyBill",
                default = DEFAULTCURRENCY,
                options = currencyoptions,
            ),
            schema.Dropdown(
                id = "delay",
                name = "Speed",
                desc = "How long to display each coin.",
                icon = "gaugeHigh",
                default = DEFAULTDELAY,
                options = delayoptions,
            ),
            schema.Dropdown(
                id = "numcoins",
                name = "Number",
                desc = "Number of coins to display.",
                icon = "hashtag",
                default = DEFAULTNUMCOINS,
                options = numcoinoptions,
            ),
            schema.Text(
                id = "excludes",
                name = "Excludes",
                desc = "Space seperated list of coins to exclude.",
                icon = "eyeSlash",
                default = DEFAULTEXCLUDES,
            ),
            schema.Toggle(
                id = "excludepegged",
                name = "Exclude Pegged",
                desc = "Exclude stablecoins and wrapped coins.",
                icon = "scaleBalanced",
                default = DEFAULTEXCLUDEPEGGED,
            ),
            schema.Toggle(
                id = "showcredits",
                name = "Show Credits",
                desc = "Show credits on last slide.",
                icon = "copyright",
                default = DEFAULTSHOWCREDITS,
            ),
        ],
    )

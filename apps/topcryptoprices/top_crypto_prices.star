"""
Applet: Top Crypto Prices
Summary: Top Crypto USD Prices
Description: This app shows the latest prices (USD) and price changes for the top 10 cryptocurrencies. It is a very simple app, but does exactly what I need and what I bought the Tidbyt for in the first place. Prices are updated through the free Coingecko API at a maximum rate of once per minute.
Author: playak

Version: 1.0
Date: 2022-11-05
Comments: Written to display the price info of top cryptocurrencies on a Tidbyt screen. We manually exclude stable coins and wrapped coins (so we only need one API call).
Copyright: © 2022 Jeroen Houttuin, Playak - jeroen@playak.com - https://playak.com
"""
# CONFIG START
MAXCOINS = 10 # max number of coins to show
TTL = 60 # time to live for the API cache. Be nice to the free Coingecko API provider!
DELAY = 2500 # milliseconds for each coin page to stay on the screen
BLACKLIST = ",USDT,USDC,BUSD,STETH,DAI,WBTC,SHIB," # ignore pegged tokens
# CONFIG END

# LOAD MODULES
load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("math.star", "math")

# INIT
credits = ["Data:Coingecko", "Code:Playak"]
API = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=USD&order=market_cap_desc&per_page=" + str(2*MAXCOINS); # get more coins than needed, to compensate for blacklist
DEBUG = 0
COINCOLORS = {} # define matching font colors for top coins
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
COINCOLORS["FIL"] = "#0290FF"

# MAIN
def main():
    coins_cached = cache.get("coins_cached")
    if coins_cached != None:
        if DEBUG:
            print("Displaying cached coin market data.")
        COINS = json.decode(coins_cached)
    else:
        if DEBUG:
            print("Cache needs refresh. Calling market data API.")
        COINS = []
        resp = http.get(API)
        if DEBUG>1:
            print(json.indent(json.encode(resp.json())))
        if resp.status_code != 200:
            fail("API request failed with status %d", resp.status_code)
        counter = 0
        for coininfo in resp.json():
            if ","+coininfo["symbol"].upper()+"," not in BLACKLIST and counter<MAXCOINS:
                COINS.append({'rank': int(coininfo["market_cap_rank"]), 'ticker': coininfo["symbol"].upper(), "price": coininfo["current_price"], "change": coininfo["price_change_percentage_24h"]})
                counter += 1
        cache.set("coins_cached", json.encode(COINS), ttl_seconds=TTL)
    if DEBUG>1:
        print(COINS)
    coinlines = [];
    for coininfo in COINS:
        coinlines.append(renderbox(coininfo))
    coinlines.append(renderbox(credits, color="#444"))
    if DEBUG>1:
        print(coinlines)
    return render.Root(
        render.Animation(
            children=coinlines,
        ),
        delay=DELAY
    )

# FUNCTIONS
def renderpercentage(p):
    color = "#888"
    if p>0.1:
        color = "#07C18E"
    elif p<-0.1:
        color = "#FF5550"
    pabs = math.fabs(p)
    if pabs>10:
        decimals=1 
    else:
        decimals=2
    fact = math.pow(10, decimals)
    p = math.round(p*fact)/fact
    return render.Text(str(p) + "%", color=color)

def renderprice(p):
    decimals = -1
    if p>=1000:
        p = int(p)
    else:
        p = toprecision(p, 4)
    pstr = str(p)
    if len(pstr) > 9: # sometimes a really long and ugly price format gets through. truncate it. if BTC gets above 1B USD, I don't care about this tool anymore :)
        pstr = pstr[0:8]
    return render.Text(pstr)

def rendertext(msg, color="#FFF"):
    return render.Text(msg, color)

def renderbox(coin, color="#FFF"):
    if DEBUG: 
        print(coin)
    if "price" in coin: # coin["price"] is set. must be coin data
        children = [
        render.Text(coin["ticker"], color=coincolor(coin["ticker"]), font="6x13"),
        renderprice(coin["price"]),
        renderpercentage(coin["change"]),
        ]
    else: # must be some lines of text, ie the credits
        children = []
        for textline in coin:
            children.append(render.Text(textline, color=color, font="tom-thumb"))
    toreturn = render.Box(
        render.Column(
            expanded=True,
            main_align="space_evenly",
            cross_align="center",
            children=children,
        ),
        color="#000" # black background, to clean the rest of the screen
    )
    return toreturn

def toprecision(number, precision): # get any number and show only the n most significant digits
    if number == 0:
        return 0
    exponent = math.floor(math.log(math.fabs(number) + 1, 10))
    significand = math.round((number / math.pow(10, exponent)) * math.pow(10, precision)) / math.pow(10, precision)
    return significand * math.pow(10, exponent);

def coincolor(ticker):
    toreturn = "#AAA"
    if ticker in COINCOLORS:
        toreturn = COINCOLORS[ticker]
    return toreturn


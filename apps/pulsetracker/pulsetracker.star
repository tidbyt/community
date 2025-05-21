"""
Applet: Pulse Tracker
Summary: Pulse Tracker
Description: Displays Pulsechain token prices and price changes in USD over the last 24 hours.
Author: kmphua
Thanks: playak
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

# CONFIG
TTL = 60
DEFAULTTOKEN = "WPLS"
NO_DATA = "---"

# INIT
DEBUG = 1
COINCOLORS = {}  # define matching font colors for top coins
COINCOLORS["WPLS"] = "#0AF"
COINCOLORS["PLSX"] = "#F00"
COINCOLORS["INC"] = "#0F0"
COINCOLORS["HEX"] = "#F50"
COINCOLORS["EHEX"] = "#F50"
COINCOLORS["HELGO"] = "#F00"
COINCOLORS["PKTTN"] = "#F0F"
COINCOLORS["LOAN"] = "#F5F"
COINCOLORS["USDL"] = "#05F"
COINCOLORS["ICSA"] = "#0AF"
COINCOLORS["HDRN"] = "#05F"
COINCOLORS["B9"] = "#050"
COINCOLORS["PHUX"] = "#F00"
COINCOLORS["PHIAT"] = "#0AF"
COINCOLORS["PHAME"] = "#0AF"
COINCOLORS["MINT"] = "#0A0"
COINCOLORS["WATT"] = "#FFF"
COINCOLORS["9INCH"] = "#F00"
COINCOLORS["BBC"] = "#F00"
COINCOLORS["RBC"] = "#FA0"
COINCOLORS["CST"] = "#0FF"
COINCOLORS["SOIL"] = "#0FF"
COINCOLORS["SOLIDX"] = "#0FF"
COINCOLORS["BEAR"] = "#0FF"
COINCOLORS["MOST"] = "#0FF"
COINCOLORS["ATROPA"] = "#0FF"
COINCOLORS["SPARTA"] = "#0FF"
COINCOLORS["PUMP"] = "#0FF"
COINCOLORS["DOUBT"] = "#0FF"
COINCOLORS["BEST"] = "#0FF"
COINCOLORS["TRUMP"] = "#0FF"
COINCOLORS["UFO"] = "#0FF"

# MAIN
def main(config):
    token = config.get("token", "0x6753560538ECa67617A9Ce605178F788bE7E524E")  # Default PLS
    API = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/" + token
    price_data = get_json_from_cache_or_http(API, TTL)
    price = NO_DATA
    ticker = NO_DATA
    change = NO_DATA
    if price_data != None:
        price = "$" + price_data["pairs"][0]["priceUsd"]
        ticker = price_data["pairs"][0]["baseToken"]["symbol"]
        change = price_data["pairs"][0]["priceChange"]["h24"]
    coininfo = {"ticker": ticker, "price": price, "change": change}
    coinlines = renderbox(coininfo)
    return render.Root(
        coinlines,
    )

# FUNCTIONS

def get_json_from_cache_or_http(url, timeout):
    res = http.get(url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.json()

def format_float_string(float_value):
    # Round price to nearest whole number (used to decide how many decimal places to leave)
    float_value_integer = str(int(math.round(float(float_value))))

    # Trim and format price
    if len(float_value_integer) <= 1:
        float_value = str(int(math.round(float_value * 1000)))
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        float_value = (float_value[0:-3] + "." + float_value[-3:])
    elif len(float_value_integer) == 2:
        float_value = str(int(math.round(float_value * 1000)))
        float_value = (float_value[0:-3] + "." + float_value[-3:])
    elif len(float_value_integer) == 3:
        float_value = str(int(math.round(float_value * 100)))
        float_value = (float_value[0:-2] + "." + float_value[-2:])
    elif len(float_value_integer) == 4:
        float_value = str(int(math.round(float_value * 10)))
        float_value = (float_value[0:-1] + "." + float_value[-1:])
    elif len(float_value_integer) == 5:
        float_value = str(int(math.round(float_value)))
    elif len(float_value_integer) >= 6:
        float_value = str(int(math.round(float_value)))
    return float_value

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
            render.Text(coin["price"]),
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
    tokenoptions = [
        schema.Option(
            display = "PLS",
            value = "0x6753560538ECa67617A9Ce605178F788bE7E524E",
        ),
        schema.Option(
            display = "PLSX",
            value = "0x1b45b9148791d3a104184Cd5DFE5CE57193a3ee9",
        ),
        schema.Option(
            display = "INC",
            value = "0xf808Bb6265e9Ca27002c0A04562Bf50d4FE37EAA",
        ),
        schema.Option(
            display = "HEX",
            value = "0xf1F4ee610b2bAbB05C635F726eF8B0C568c8dc65",
        ),
        schema.Option(
            display = "EHEX",
            value = "0x1dA059091d5fe9F2d3781e0FdA238BB109FC6218",
        ),
        schema.Option(
            display = "HELGO",
            value = "0x2772Cb1AC353b4ae486f5baC196f20DcBd8A097F",
        ),
        schema.Option(
            display = "PKTTN",
            value = "0xF996eD564568a70280A284c12F5405a507CD1300",
        ),
        schema.Option(
            display = "LOAN",
            value = "0x6D69654390c70D9e8814B04c69a542632DC93161",
        ),
        schema.Option(
            display = "USDL",
            value = "0x27557d148293d1C8e8f8c5DEEAb93545B1Eb8410",
        ),
        schema.Option(
            display = "ICSA",
            value = "0xe5bb65e7a384D2671C96cfE1Ee9663F7B03a573e",
        ),
        schema.Option(
            display = "HDRN",
            value = "0xbaE2b1aC914255AbE40eBE308458D592A0A9F44b",
        ),
        schema.Option(
            display = "B9",
            value = "0x05c4CB83895D284525DcAB245631cE504740931B",
        ),
        schema.Option(
            display = "PHUX",
            value = "0x9A2F5B8DFE4AD4c3d7A3bf41240694f91aCC2c0d",
        ),
        schema.Option(
            display = "PHIAT",
            value = "0xfe75839c16a6516149D0F7B2208395F54A5e16e8",
        ),
        schema.Option(
            display = "PHAME",
            value = "0xF64602fd08245d1D27F7D9452814BEa1451BD502",
        ),
        schema.Option(
            display = "RBC",
            value = "0x27290772EA970e3D0A82583Ff5b00d4ee9C812A0",
        ),
        schema.Option(
            display = "MINT",
            value = "0x5F2D8624e6aBEA8F679a1095182f4bC84fe148e0",
        ),
        schema.Option(
            display = "WATT",
            value = "0x956f097E055Fa16Aad35c339E17ACcbF42782DE6",
        ),
        schema.Option(
            display = "9INCH",
            value = "0x1164daB36Cd7036668dDCBB430f7e0B15416EF0b",
        ),
        schema.Option(
            display = "BBC",
            value = "0x956f097E055Fa16Aad35c339E17ACcbF42782DE6",
        ),
        schema.Option(
            display = "CST",
            value = "0x284a7654B90D3c2e217B6da9fAc010e6C4b54610",
        ),
        schema.Option(
            display = "SOIL",
            value = "0xbd63FA573A120013804e51B46C56F9b3e490f53C",
        ),
        schema.Option(
            display = "SOLIDX",
            value = "0x8Da17Db850315A34532108f0f5458fc0401525f6",
        ),
        schema.Option(
            display = "BEAR",
            value = "0xd6c31bA0754C4383A41c0e9DF042C62b5e918f6d",
        ),
        schema.Option(
            display = "MOST",
            value = "0xe33a5AE21F93aceC5CfC0b7b0FDBB65A0f0Be5cC",
        ),
        schema.Option(
            display = "ATROPA",
            value = "0xCc78A0acDF847A2C1714D2A925bB4477df5d48a6",
        ),
        schema.Option(
            display = "SPARTA",
            value = "0x52347C33Cf6Ca8D2cfb864AEc5aA0184C8fd4c9b",
        ),
        schema.Option(
            display = "PUMP",
            value = "0xec4252e62C6dE3D655cA9Ce3AfC12E553ebBA274",
        ),
        schema.Option(
            display = "DOUBT",
            value = "0x6ba0876e30CcE2A9AfC4B82D8BD8A8349DF4Ca96",
        ),
        schema.Option(
            display = "BEST",
            value = "0x84601f4e914E00Dc40296Ac11CdD27926BE319f2",
        ),
        schema.Option(
            display = "TRUMP",
            value = "0x8cC6d99114Edd628249fAbc8a4d64F9A759a77Bf",
        ),
        schema.Option(
            display = "UFO",
            value = "0x456548A9B56eFBbD89Ca0309edd17a9E20b04018",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "token",
                name = "Token",
                desc = "Pulsechain token",
                icon = "moneyBill",
                default = tokenoptions[0].value,
                options = tokenoptions,
            ),
        ],
    )

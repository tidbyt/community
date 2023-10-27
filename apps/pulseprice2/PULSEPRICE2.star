"""
Applet: Pulse Price
Summary: Pulse Price
Description: Displays EHEX, PHEX and WBTC prices on Pulsechain
Author: kmphua
Thanks: aschober, bretep, codeakk, Poseidon
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")

PHEX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAsTAAAL
EwEAmpwYAAABG0lEQVQYlQXBPUsCYQDA8f+dz6WXr3cqZlpkkSCBBI2NITSI0NTi
B2jpOzT1CRqipYjmliKiJQiioWhoiYqIuDDMzJcwz7vTp99PkZUNeJw3qNkPuIko
6hTSmwBftqPkkkV0qyUQEtTbA/yjLNok9L9QlDTSqYelld9VCoF1RVZXy1jdE37N
bZr+OF7cxUsU+AmvIGdgLr/o26qo10THTmGQR/4to7kxDO0IpzuN3Uxh2yXBgrrD
Z7uENooRDn7z0V9i4KjMpo55aRWRzpggIw7RB0XG3XuS/SbpyCvP1hpDLuj72hjB
qiCuvxHqnOM19ghEwBT7xMQZ77UyunKHkbkSjDzImpeojRZtt05v0CMyfMIMpQnl
Nrlx+AeJZmcOHgyOkAAAAABJRU5ErkJggg==
""")
EHEX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAsTAAAL
EwEAmpwYAAABG0lEQVQYlQXBPUsCYQDA8f+dz6WXr3cqZlpkkSCBBI2NITSI0NTi
B2jpOzT1CRqipYjmliKiJQiioWhoiYqIuDDMzJcwz7vTp99PkZUNeJw3qNkPuIko
6hTSmwBftqPkkkV0qyUQEtTbA/yjLNok9L9QlDTSqYelld9VCoF1RVZXy1jdE37N
bZr+OF7cxUsU+AmvIGdgLr/o26qo10THTmGQR/4to7kxDO0IpzuN3Uxh2yXBgrrD
Z7uENooRDn7z0V9i4KjMpo55aRWRzpggIw7RB0XG3XuS/SbpyCvP1hpDLuj72hjB
qiCuvxHqnOM19ghEwBT7xMQZ77UyunKHkbkSjDzImpeojRZtt05v0CMyfMIMpQnl
Nrlx+AeJZmcOHgyOkAAAAABJRU5ErkJggg==
""")
INC_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAWJAAAF
iQFtaJ36AAABC0lEQVQYlT3Ku07CUACA4b/0ioA9saE5MSTA4mQURyZ8CQcfwUkX
Z+oLGB/AgcfQURdXXVwcLAmBg6GxEi5p0R4HE4dv+wytNbVLokWDPrvwr8oX0NJ1
UnN8G7WqSwalFd48Y1isEayBAo8K5ajGnXX0sbmRyvalAqlI4xaMEpokQMK5kTCw
9itLEeTOQxA7HaksIRVp/JfT2QyYcWztueNeYNcJ7M1LkLkifHWQqiSk4jBW8N7m
2ewbbtszfzo7Xii3TC3KZnFfXdPzRya1uUFtwalRGNsic7tx7nT93Omysg6Gk9xp
TnKHSeZeneV2hNYaDRffZkOvyic69a/1NHzSb+E0fhSfQmvNL6VjbO/VkT3+AAAA
AElFTkSuQmCC
""")

NO_DATA = "---------- "

DEXSCREENER_PHEX_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0xf1F4ee610b2bAbB05C635F726eF8B0C568c8dc65"
DEXSCREENER_EHEX_URL = "https://api.dexscreener.com/latest/dex/pairs/ethereum/0x69d91b94f0aaf8e8a2586909fa77a5c2c89818d5"
DEXSCREENER_INC_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0xe0e1F83A1C64Cf65C1a86D7f3445fc4F58f7Dcbf"

def main():
    # Get PHEX price
    PHEX_price_data = get_json_from_cache_or_http(DEXSCREENER_PHEX_URL, 600)
    PHEX_price = NO_DATA
    if PHEX_price_data != None:
        PHEX_price = "$" + PHEX_price_data["pairs"][0]["priceUsd"]

    # Get PHEX price
    EHEX_price_data = get_json_from_cache_or_http(DEXSCREENER_EHEX_URL, 600)
    EHEX_price = NO_DATA
    if EHEX_price_data != None:
        EHEX_price = "$" + EHEX_price_data["pairs"][0]["priceUsd"]

    # INC price
    inc_price_data = get_json_from_cache_or_http(DEXSCREENER_INC_URL, 600)
    inc_price = NO_DATA
    if inc_price_data != None:
        inc_price = "$" + inc_price_data["pairs"][0]["priceUsd"]

    # Setup display rows
    displayRows = []

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PHEX_ICON_SM),
                render.Text(PHEX_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = EHEX_ICON_SM),
                render.Text(EHEX_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = INC_ICON_SM),
                render.Text(inc_price),
            ],
        ),
    )

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = displayRows,
                ),
            ],
        ),
    )

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
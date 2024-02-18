"""
Applet: Pulse Price
Summary: Pulse Price
Description: Displays PLS, PLSX and INC prices on Pulsechain
Author: kmphua
Thanks: aschober, bretep, codeakk, Poseidon
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")

PLS_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAWJAAAF
iQFtaJ36AAABC0lEQVQYlT3Ku07CUACA4b/0ioA9saE5MSTA4mQURyZ8CQcfwUkX
Z+oLGB/AgcfQURdXXVwcLAmBg6GxEi5p0R4HE4dv+wytNbVLokWDPrvwr8oX0NJ1
UnN8G7WqSwalFd48Y1isEayBAo8K5ajGnXX0sbmRyvalAqlI4xaMEpokQMK5kTCw
9itLEeTOQxA7HaksIRVp/JfT2QyYcWztueNeYNcJ7M1LkLkifHWQqiSk4jBW8N7m
2ewbbtszfzo7Xii3TC3KZnFfXdPzRya1uUFtwalRGNsic7tx7nT93Omysg6Gk9xp
TnKHSeZeneV2hNYaDRffZkOvyic69a/1NHzSb+E0fhSfQmvNL6VjbO/VkT3+AAAA
AElFTkSuQmCC
""")
PLSX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAJCAYAAAAPU20uAAAACXBIWXMAAAWJAAAF
iQFtaJ36AAABLklEQVQYlT3KTSiDAQAG4Hd8tljL/qSV5KeWvoxYc6CViIOQ5mYO
kiaHTbIkcpCi2VKUA2scNKJxctFSDg67TVlJS+SgNdKW2k/bvteJ69Mj2xocawEg
e9HrX/1Bfw4ADNH1zUSHeln9lmnFU21jgJBLD3XGPZIwH7hNoKcgK26nu71uORZt
kzX5clWSUBW8Q6OdlV9r9+AGG+5WnCRR5rs8+QyLptWSrCJza9cNZ3VSjyKdixqv
s/sAIADAqbk98GjS5MPjWh9QKIpXpdkb744EACAJktDGXUegi/VR56HDPqP9c5BE
W3DeCjpKQmbu46K/zxMzdB3/h4GlBUGRmo6BU7SEHBM/cjFOiNJur81KEsLzSM6c
r86GlMkqnyaiPDs3N0cs799NYiKVBoBfQPqMHBohfUwAAAAASUVORK5CYII=
""")
INC_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAABEUlEQVQY012QP0vD
UBRHz315AUswwTgIUnBQnDI42LkiQgVdi1+g0NFNipMO0gpuTiq4tF9AqIs42EEQ
rFvBQQSRrqJRh/xB6/AaAl74LZfDGY6Q3ehoE6xl0JgpgD5S7wKIgfaKYA/A9nJQ
AyoECZD6UBld2qzhO9esUUGzjo4iapyw6MBP0xhH22Wwb0Dzzu7nA0/uNC4+LnO0
x2ZZURC3IAZizug6s/hvSyxwwEWY/SFtKUiACIjY4c5ymJjq8/hxyouXgwkK0kZu
LH/N4KtJCt4hATkYNxTS7kHSWcX53aJSuOI2eeb1u8R8bKCog+z3xnmqRZABqH95
7BB0gBwPJQ9e3QBKJnQGWvfI+SXAH33pUizRrvIoAAAAAElFTkSuQmCC
""")

NO_DATA = "---------- "

DEXSCREENER_PLS_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0x6753560538ECa67617A9Ce605178F788bE7E524E"
DEXSCREENER_PLSX_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0x1b45b9148791d3a104184Cd5DFE5CE57193a3ee9"
DEXSCREENER_INC_URL = "https://api.dexscreener.com/latest/dex/pairs/pulsechain/0xf808Bb6265e9Ca27002c0A04562Bf50d4FE37EAA"

def main():
    # Get PLS price
    pls_price_data = get_json_from_cache_or_http(DEXSCREENER_PLS_URL, 600)
    pls_price = NO_DATA
    if pls_price_data != None:
        pls_price = "$" + pls_price_data["pairs"][0]["priceUsd"]

    # Get PLS price
    plsx_price_data = get_json_from_cache_or_http(DEXSCREENER_PLSX_URL, 600)
    plsx_price = NO_DATA
    if plsx_price_data != None:
        plsx_price = "$" + plsx_price_data["pairs"][0]["priceUsd"]

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
                render.Image(src = PLS_ICON_SM),
                render.Text(pls_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLSX_ICON_SM),
                render.Text(plsx_price),
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

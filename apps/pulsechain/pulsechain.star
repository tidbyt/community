"""
Applet: PulseChain
Summary: Price of PLS and PLSX
Description: Display the price of PLS and PLSX. Choose between testnet and mainnet prices. After PulseChain mainnet launch, an update will be pushed to this app to display the correct mainnet price.
Author: bretep
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("schema.star", "schema")
load("secret.star", "secret")

POST_HEADERS = {
    "Content-Type": "application/json",
}

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

def main(config):
    PULSE_URL = secret.decrypt("AV6+xWcEe6LaPNQy2WZlXe8ehGcMsHJPvIdeF3uWJEpuuAEiLvUIdOibUy2HusTBxn7OR9L+1qznqDobB4u+W/RUQdj9VD0NAt1fzygc7uPSKNfxT8xFJXFZkGrUsaIL9JCBokBu/nUyw/ZUA+u75FEym6W3DtbO68ENkbTRzR+s7w132S6gcjj+ZGe56TLaYVEbW5W5WfoLy/V7fITaIQDmRn5TTytpzVht1pj/Sg==")
    PULSE_TESTNET_URL = secret.decrypt("AV6+xWcE67NQioJdT6Nmo5CneisfBb1HR71TIiA/ESaqZ3NvBjNRQkwxOpFeBs5nuoDQ/il0WfMzjaL2rPCPA9j1IrILwg3dO6dnbfrsIV6ySq744+Sr174EdV0y2mQmMt/IFz/yPKaB/Ho7G/fsKsVi8pSvBuK24dQ4OcU4+RM9DbPD3dp8MIe7xZnAqjzQcKb8KE1AgRU115tv4G4M0Ev9C3wES0mPVb3ScOauXQ==")
    PULSE_QUERY_ENC = secret.decrypt("AV6+xWcExlPG8s/gJhiyalBT2jnDyvSjXsCHo5BdO+Nz+CNbrBVvdtLwNxDM23c+nuQtZJBqDMFac0gszLX37XemSqfQB4FaNy0NUSj9cDzNKUfOdU7U7zFDJAOb97bbMSLG7rI+V+HoF2nSuapjUycmUYl1XJ/BiMNxzbmOECCR/T8qlivLxb7shiGJ1H9LSe+TwyP0EJv6FUZr3XnrdDSEX9GavnxWtQTB84Plsaduy/yHmYgzcqTr9P2Dm1Mu62wF5Dqq28fTJkD18OO7860I2LiySTpf7oqopNxjjd2pKgaD4ReC+/exrXKqrWqaEUXOEh/GYmE8ExMHjr4UrXfvby0R5eJkAiZBJgH4Ae/ZLcgcRctyd84rOpTMRw6OxcLzPpf2pcJfhCyAqbz9Lw+zGHwdm1mpCVpnZv/hNb0TC/xqGOmNt/gPvz7W4slWN4yLhX9WWJuX/S980TlJAyDnm3ECzSQcEtjGZqrKPqRb2M6ydudQv7pgsxXHV8VvGqxM4lE/85A5ZLmoiJuzVS5oxMVDZ+Po1IWGwedcJqId/g==")
    PULSE_QUERY = base64.decode(PULSE_QUERY_ENC)

    cached_pls = cache.get("pls_price")
    cached_plsx = cache.get("plsx_price")
    cached_testnet_pls = cache.get("pls_testnet_price")
    cached_testnet_plsx = cache.get("plsx_testnet_price")

    if cached_pls != None:
        print("Using cached data.")
        if config.bool("testnet"):
            display_pls_price = cached_testnet_pls
            display_plsx_price = cached_testnet_plsx
        else:
            display_pls_price = cached_pls
            display_plsx_price = cached_plsx
    else:
        print("Cache miss, updating price...")

        mainnetResponse = http.post(PULSE_URL, body = PULSE_QUERY, headers = POST_HEADERS)
        if mainnetResponse.status_code != 200:
            fail("Mainnet request failed with status %d", mainnetResponse.status_code)

        testnetResponse = http.post(PULSE_TESTNET_URL, body = PULSE_QUERY, headers = POST_HEADERS)
        if testnetResponse.status_code != 200:
            fail("Testnet request failed with status %d", testnetResponse.status_code)

        PLS = mainnetResponse.json()["data"]["pls"]["derivedUSD"]
        PLSX = mainnetResponse.json()["data"]["plsx"]["derivedUSD"]
        mainnet_pls = str("$%f" % float(PLS))
        mainnet_plsx = str("$%f" % float(PLSX))

        cache.set("pls_price", mainnet_pls, ttl_seconds = 30)
        cache.set("plsx_price", mainnet_plsx, ttl_seconds = 30)

        PLS_TESTNET = testnetResponse.json()["data"]["pls"]["derivedUSD"]
        PLSX_TESTNET = testnetResponse.json()["data"]["plsx"]["derivedUSD"]
        testnet_pls = str("$%f" % float(PLS_TESTNET))
        testnet_plsx = str("$%f" % float(PLSX_TESTNET))

        cache.set("pls_testnet_price", testnet_pls, ttl_seconds = 30)
        cache.set("plsx_testnet_price", testnet_plsx, ttl_seconds = 30)

        if config.bool("testnet"):
            display_pls_price = testnet_pls
            display_plsx_price = testnet_plsx
        else:
            display_pls_price = mainnet_pls
            display_plsx_price = mainnet_plsx

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Image(src = PLS_ICON_SM),
                                render.Text(display_pls_price),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Image(src = PLSX_ICON_SM),
                                render.Text(display_plsx_price),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "testnet",
                name = "Testnet",
                desc = "Turn on to see testnet tickers",
                icon = "flaskVial",
                default = False,
            ),
        ],
    )

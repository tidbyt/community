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
    PULSE_URL = secret.decrypt("AV6+xWcEwLL4pRoJwUrtaXE3CI9igLnERsQGHOaKT71Tx9ZK4KNzX7RnM44TUUH331nV7qC1HZyDQjWz5dRSOfhR+FygZJuuAA0U6lVtMJ0ec/LhP7g6njwRFMazQm5WKVzIEiiBZSu8j1cFt8p0nvnIX/YIzdkHD7oGmBeC4yJJS00Ff2mwdgk7thwyxzVASOxPhfqHx0wzF5+V9Hqt4TQKLNHrZraKaMvAlPNwYg==")
    PULSE_TESTNET_URL = secret.decrypt("AV6+xWcEZgIlJbik5keAYBYapZFttKMveUNXoc+U/ZmzjZqkhHu3c+gYZAFcOLIDCZOri+2mDZb+evfRS/vvvrkORXD/J/ccWmSgldILwc0lAPOeNv4Z0oaxWnCAdHSAFKbpMUSf5lUoztjRBM3Nhb9DoCoYV7cFK1CMqDYc+8M6MscgBof7c5E+91L4kAB+DLn4Vwd5ixFCgisNJNcqpGipSCgD0Lll5MI8lFPrkQ==")
    PULSE_QUERY_ENC = secret.decrypt("AV6+xWcELDwtAPQSjVEqygAqa9qzv4hjSCqBXUEk1usU3pv/jtFnEbSBEKP7/CodFUG51ngOaOX2EjQOuMFUpm7pUOZQadMPMy06/UvktK52nV5Lapp0Sl5HWf5UMq0K6nI5K2bdEreIGPkp8c7pH9zjoWJrwhEdSpEGqH7WWUWyn9C/FQwjyFvGo2hEU7AOJewscoceQrq8PJispbJ1s+xzFzlFsfu+Hv5OWgnys5vjKpk9ARkZPeRKScFLQWjML+iezJeT7o7eZbDEpYbhXBXReT//8f5GIqXLxaQcJdB4LpqVtQ+Q+hSFd/7mERgzhtCv7894vuxB0Nbkch/fkgpY9sLqx+fSlY8l9BYnkyVa/19Piv98iQCpLfVcv4srJRe9aVcQUK7kdUFA+p0bnXwUDohGIqX9ZIkPPYjjlx6rpCOmTNj2dpyh8wyWXM2nmA7DDEKghS407PkJ8aak+k8pygsFVhdTcCqYrdPxzxWBc1+xitBprVDhJKDDdoEocJcQe32Jd95+LunIZeqh1juhGnMsQXXovOQ45yslqzkoOg==")

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

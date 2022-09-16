"""
Applet: HEX Daily Stats
Summary: HEX Daily Stats
Description: Displays HEX price, Payout per T-Share and T-Share rate
Author: kmphua
Thanks: aschober, bretep, codeakk
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("math.star", "math")

COINGECKO_PRICE_URL = "https://api.coingecko.com/api/v3/coins/{}?localization=false&tickers=false&community_data=false&developer_data=false"

HEX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAsTAAAL
EwEAmpwYAAABG0lEQVQYlQXBPUsCYQDA8f+dz6WXr3cqZlpkkSCBBI2NITSI0NTi
B2jpOzT1CRqipYjmliKiJQiioWhoiYqIuDDMzJcwz7vTp99PkZUNeJw3qNkPuIko
6hTSmwBftqPkkkV0qyUQEtTbA/yjLNok9L9QlDTSqYelld9VCoF1RVZXy1jdE37N
bZr+OF7cxUsU+AmvIGdgLr/o26qo10THTmGQR/4to7kxDO0IpzuN3Uxh2yXBgrrD
Z7uENooRDn7z0V9i4KjMpo55aRWRzpggIw7RB0XG3XuS/SbpyCvP1hpDLuj72hjB
qiCuvxHqnOM19ghEwBT7xMQZ77UyunKHkbkSjDzImpeojRZtt05v0CMyfMIMpQnl
Nrlx+AeJZmcOHgyOkAAAAABJRU5ErkJggg==
""")

NO_DATA = "---------- "

HEX_SUBGRAPH_URL = "https://api.thegraph.com/subgraphs/name/codeakk/hex"
POST_HEADERS = {
    "Content-Type": "application/json",
}
DAILY_DATA_UPDATES_QUERY = "{\"query\": \"{ dailyDataUpdates(orderBy: timestamp orderDirection: desc first: 1) { payoutPerTShare } }\" }"
GLOBAL_INFOS_QUERY = "{\"query\": \"{ globalInfos(orderBy: timestamp orderDirection: desc first: 1)  { hexDay, shareRate } }\" }"

def main(config):
    # Get coin data for selected coin from CoinGecko
    coin_data = get_json_from_cache_or_http(COINGECKO_PRICE_URL.format("hex"), ttl_seconds = 600)

    # Check for catastrophic data failure (i.e. failed to get data from CoinGecko and no cache data is available to fall back on)
    if coin_data == None:
        display_error = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
                render.Text("CoinGecko API", font = "CG-pixel-3x5-mono"),
                render.Text("unvailable", font = "CG-pixel-3x5-mono"),
            ],
        )
        print("Error: No CoinGecko data available")
        return render.Root(
            child = render.Box(
                display_error,
            ),
        )

    hex_price = str("$%f" % float(coin_data["market_data"]["current_price"]["usd"]))

    # Get HEX daily data updates
    daily_data_updates_data = post_json_from_cache_or_http(HEX_SUBGRAPH_URL, body = DAILY_DATA_UPDATES_QUERY, headers = POST_HEADERS, cache_name = "dailyDataUpdates", ttl_seconds = 28800)

    payout_per_tshare = NO_DATA

    if daily_data_updates_data != None:
        payout_per_tshare = str("%g" % float(daily_data_updates_data["data"]["dailyDataUpdates"][0]["payoutPerTShare"]))

    # Get HEX global infos
    global_infos_data = post_json_from_cache_or_http(HEX_SUBGRAPH_URL, body = GLOBAL_INFOS_QUERY, headers = POST_HEADERS, cache_name = "globalInfos", ttl_seconds = 28800)

    share_rate = NO_DATA

    if global_infos_data != None:
        share_rate = str(int(global_infos_data["data"]["globalInfos"][0]["shareRate"]) / 10)

    # Setup display rows
    displayRows = []

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = HEX_ICON_SM),
                render.Text(hex_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("Payout"),
                render.Text(format_float_string(float(payout_per_tshare))),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("ShRt"),
                render.Text(share_rate),
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

def get_json_from_cache_or_http(url, ttl_seconds):
    cached_response = cache.get(url)

    if cached_response != None:
        print("Cache hit: {}".format(url))
        data = json.decode(cached_response)
    else:
        print("HTTP JSON Request: {}".format(url))
        http_response = http.get(url)
        if http_response.status_code != 200:
            fail("HTTP Request failed with status: {}".format(http_response.status_code))

        # Store http response in cache keyed off URL
        cache.set(url, json.encode(http_response.json()), ttl_seconds = ttl_seconds)
        data = http_response.json()

    return data

def post_json_from_cache_or_http(url, body, headers, cache_name, ttl_seconds):
    # Make cached url key unique by appending body query
    cached_response = cache.get(cache_name)

    if cached_response != None:
        print("Cache hit: {}".format(url))
        data = json.decode(cached_response)
    else:
        print("HTTP JSON Request: {}".format(url))
        http_response = http.post(url, body = body, headers = headers)

        if http_response.status_code != 200:
            fail("HTTP Request failed with status: {}".format(http_response.status_code))

        # Store http response in cache keyed off URL
        cache.set(cache_name, json.encode(http_response.json()), ttl_seconds = ttl_seconds)
        data = http_response.json()

    return data

def hasData(json):
    return "data" in json

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
        float_value = str(int(math.round(currency_price * 1000)))
        float_value = (float_value[0:-3] + "." + float_value[-3:])
    elif len(float_value_integer) == 3:
        currency_price = str(int(math.round(currency_price * 100)))
        currency_price = (float_value[0:-2] + "." + float_value[-2:])
    elif len(float_value_integer) == 4:
        float_value = str(int(math.round(currency_price * 10)))
        float_value = (float_value[0:-1] + "." + float_value[-1:])
    elif len(float_value_integer) == 5:
        float_value = str(int(math.round(float_value)))
    elif len(float_value_integer) >= 6:
        float_value = str(int(math.round(float_value)))

    return float_value

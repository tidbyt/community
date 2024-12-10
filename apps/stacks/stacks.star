"""
Applet: Stacks
Summary: Track the Stacks network
Description: Track the latest block (height and time) and prices (Sats/STX and USD/STX) for the Stacks network.
Author: obycode
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

COINMARKETCAP_BASE_URL = "https://pro-api.coinmarketcap.com/"
SATS_PER_STX_URL = "v2/cryptocurrency/quotes/latest?id=4847&convert_id=1"
STX_USD_URL = "v2/cryptocurrency/quotes/latest?id=4847"
HIRO_API_BASE_URL = "https://api.hiro.so/"
LATEST_BLOCK_URL = "extended/v2/blocks?limit=1"

STACKS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAD6ADAAQAAAABAAAADwAAAAAHNtsJAAAAuUlEQVQoFaWS0Q3CMAxEE8RcrMAnI3QEEANUZQRG4JMVuljRNXrVxQkChD9q++o7W45z6tjltCwRnh45R2zvAKTD0VHiIugim5qIfRLk4udnSgjsBEXi+TpUDM/VgAlXclX5Q5JjV7jqdhvvCQ+O1/gN2UekEC8xTORq2/rhBRS+8w35284SbBamznR3T+xTrO8clxaXFHPeuunsyp/ivy5sI6sLl9M7U40q4zQVV2QBMkRKVr5OAn8BFhJVltCgJdgAAAAASUVORK5CYII=
""")

def config_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "cmc_api_key",
                name = "CoinMarketCap API Key",
                desc = "Your CoinMarketCap API Key",
                icon = "key",
            ),
            schema.Text(
                id = "hiro_api_key",
                name = "Hiro API Key",
                desc = "Your Hiro API Key",
                icon = "key",
            ),
        ],
    )

SECRET_CMC_API_KEY = "AV6+xWcE9uI4r3ENOAcxw84jo9aQr4LElVNdysdkAidr9LMPSZxdM1LD80itNoBbfLzr6s9aBJ4r8YrpHFH68LHPrfx32xYxL1VraAy5Pr0r2KVRqngfsyFyhi/k7X4Diz3ElPe/bVPkTGpzncMZfAhWJTi/unfd/UEtbHjP5/LxPgBoWiU5+lkd"
SECRET_HIRO_API_KEY = "AV6+xWcEjCyemo3AeJSRT0w5V0CthVjLE0/wmiLLCe92ZqYoHo+6hQVodJOq4BVgv1qGmd+V7BnNkjZ0QHmsyt1aq0GtrQfP1O8/lLUtqmDgNYdqrFQPyO9Dv0qA/eJo2Ryfwh4sUH+G+GV+gjpKo4mqklCY1COckdNa4tCqFlc+Fx63o80="
DEFAULT_CMC_API_KEY = ""
DEFAULT_HIRO_API_KEY = ""

def main(config):
    # Setup CMC Headers
    cmc_api_key = secret.decrypt(SECRET_CMC_API_KEY) or config.get("cmc_api_key") or DEFAULT_CMC_API_KEY
    cmc_headers = {"X-CMC_PRO_API_KEY": cmc_api_key, "Accept": "application/json"}

    # Get Sats/STX rate
    rep = http.get(COINMARKETCAP_BASE_URL + SATS_PER_STX_URL, ttl_seconds = 60, headers = cmc_headers)
    if rep.status_code == 200:
        sats_stx_rate = int(math.round(rep.json()["data"]["4847"]["quote"]["1"]["price"] * 100000000))
    else:
        sats_stx_rate = "?"

    print("Sats/STX: %s" % sats_stx_rate)

    # Get USD/STX rate
    rep = http.get(COINMARKETCAP_BASE_URL + STX_USD_URL, ttl_seconds = 60, headers = cmc_headers)
    if rep.status_code == 200:
        val = str(int(math.round(rep.json()["data"]["4847"]["quote"]["USD"]["price"] * 100)))
        usd_stx_rate = val[0:-2] + "." + val[-2:]
    else:
        usd_stx_rate = "?"

    print("STX/USD: %s" % usd_stx_rate)

    # Setup Hiro Headers
    hiro_api_key = secret.decrypt(SECRET_HIRO_API_KEY) or config.get("hiro_api_key") or DEFAULT_HIRO_API_KEY
    hiro_headers = {"x-api-key": hiro_api_key, "Accept": "application/json"}

    # Get latest block info
    rep = http.get(HIRO_API_BASE_URL + LATEST_BLOCK_URL, ttl_seconds = 10, headers = hiro_headers)
    if rep.status_code == 200:
        block_height = int(rep.json()["results"][0]["height"])
        block_time_raw = int(rep.json()["results"][0]["block_time"])
        block_time = time.from_timestamp(block_time_raw)
        time_ago = humanize.time(block_time)
    else:
        block_height = "?"
        time_ago = "? seconds ago"

    print("Block Height: %s" % block_height)
    print("Time Ago: %s" % time_ago)

    # Layout
    return render.Root(
        child = render.Column(
            children =
                [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "space_evenly",
                        children = [
                            # Left: Stacks Info
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Image(
                                        src = STACKS_ICON,
                                        width = 16,
                                        height = 16,
                                    ),
                                    render.Text("%s" % block_height),
                                ],
                            ),
                            # Right: Sats and Dollar rates
                            render.Column(
                                main_align = "center",
                                children = [
                                    render.Row(
                                        cross_align = "center",
                                        children = [
                                            render.Text("B%s" % sats_stx_rate, color = "#FFD700"),
                                        ],
                                    ),
                                    render.Row(
                                        cross_align = "center",
                                        children = [
                                            render.Text("$%s" % usd_stx_rate, color = "#00FF00"),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text("%s" % time_ago),
                        offset_start = 5,
                        offset_end = 32,
                    ),
                ],
        ),
    )

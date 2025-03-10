"""
Applet: BtcMoscowTime
Summary: Shows satoshis per USD
Description: Shows how many satoshis for 1 USD.
Author: PMK (@pmk)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

BACKGROUND = base64.decode("""
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
""")

DEFAULT_SHOW_MSAT = False

def get_data(ttl_seconds = 60 * 5):
    url = "https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=sats"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Coingecko request failed with status %d", response.status_code)
    json = response.json()
    return json["tether"]["sats"]

def print_moscowtime(show_msat = DEFAULT_SHOW_MSAT):
    data = get_data()
    sats = str(int(data // 1))
    msat = str(int((data % 1) * 100)) if show_msat else 0

    moscowtime = [render.Text(sats)]
    if (msat != 0):
        moscowtime.append(
            render.Animation(
                children = [
                    render.Text(content = ".", color = "#fff"),
                    render.Text(content = ".", color = "#000"),
                ],
            ),
        )
        moscowtime.append(render.Text(msat))
    return moscowtime

def main(config):
    show_msat = config.bool("show_msat", DEFAULT_SHOW_MSAT)

    return render.Root(
        delay = 1000,
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND,
                    width = 64,
                    height = 32,
                ),
                render.Padding(
                    pad = (3, 5, 0, 0),
                    child = render.Row(
                        children = print_moscowtime(show_msat),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_msat",
                name = "Show msat",
                desc = "Show the decimal of a satoshi?",
                icon = "coins",
                default = DEFAULT_SHOW_MSAT,
            ),
        ],
    )

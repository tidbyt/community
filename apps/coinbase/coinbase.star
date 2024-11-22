"""
Applet: Coinbase
Summary: Coinbase Balance Tracker
Description: Displays your current Coinbase holdings and balances.
Author: harrywynn
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

COINBASE_LOGO = base64.decode("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")
COINBASE_CLIENT_SECRET = secret.decrypt("AV6+xWcEIOP/Rql2nyueyFjL9f51E2W1wDvcqtKyvXWRuSZwf7pNagbGLNridKAHG4Nw4oW2FZssbHNfsGwWAmSqXG3VN8oSvw0UY+4AB2LU3HMl5eEN9A139V08wU3/vOX7ouCUtHWwNkhHRngkQHqQiZSTK0KNOYTaIO9aeb7uzFwLdMdATDEQ2ypUjrvOt4l8UM1HIpXaIjn8T5bE+q7AYgaLww==")
COINBASE_CLIENT_ID = secret.decrypt("AV6+xWcEVIfI5lKs4wUCRh+CyWiA2VJ8Jngv8g/klexY7x7qR4KGIopsbZOIq/syABtfSToDA/nx5J8Mhy+XakIUjxESmr3V9fKOeymlJd7G/0VImVbAJYoZoTU2PMgzHcr7+HUV3SVUGrmZk62eMH5y77pWPb6MXIeLXAwTYFL6ZBk3NQCkP6EIN0dOP9h+ubvvBWMLE1U3Imc9ZdqxC4XPEQmPPg==")

def main(config):
    if config.get("token") == None:
        return render.Root(
            child = render.Text("Please login"),
        )

    AUTH_TOKEN = config.get("token")

    # load exchange rates
    rates = cache.get("coinbase.price.cache.%s" % hash.md5(AUTH_TOKEN))

    if rates != None:
        # cached rates
        rates = json.decode(rates)
    else:
        # get current exchange rates
        res = http.get("https://api.coinbase.com/v2/exchange-rates")

        if res.status_code != 200:
            return render.Root(
                child = render.Text("Rates unavailable!"),
            )
        else:
            # cache for 15 minutes
            rates = res.json()["data"]["rates"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("coinbase.price.cache.%s" % hash.md5(AUTH_TOKEN), json.encode(rates), ttl_seconds = 900)

    accounts = cache.get("coinbase.accounts.cache.%s" % hash.md5(AUTH_TOKEN))

    if accounts != None:
        # cached accounts
        accounts = json.decode(accounts)
    else:
        # load account balances
        res = http.get("https://coinbase.com/api/v3/brokerage/accounts?limit=250", headers = {
            "Authorization": "Bearer " + AUTH_TOKEN,
        })

        if res.status_code != 200:
            return render.Root(
                child = render.Text("Accounts unavailable!"),
            )
        else:
            # cache for 15 minutes
            accounts = res.json()["accounts"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("coinbase.accounts.cache.%s" % hash.md5(AUTH_TOKEN), json.encode(accounts), ttl_seconds = 900)

    if accounts == None:
        return render.Root(
            child = render.Text("Accounts unavailable!"),
        )

    # for display
    currencies = []
    balance = 0.0

    # match account balances to rates
    for x in accounts:
        available = float(x["available_balance"]["value"])

        # only count if we have a balance
        if available > 0.0:
            balance += float(x["available_balance"]["value"]) // float(rates[x["currency"]])
            currencies.append(x["currency"])

    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 3),
                            child = render.Text(
                                content = ("$" + humanize.ftoa(num = balance, digits = 2)),
                                font = "6x13",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = COINBASE_LOGO, width = 9),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Marquee(
                                width = 52,
                                align = "center",
                                child = render.Text(
                                    content = " | ".join(currencies),
                                    font = "tom-thumb",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def oauth_handler(params):
    params = json.decode(params)

    params["client_secret"] = COINBASE_CLIENT_SECRET or "fake-client-secret"

    res = http.post("https://api.coinbase.com/oauth/token", params = params)

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" % (res.status_code, res.body()))

    return res.json()["access_token"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "token",
                name = "Coinbase Account",
                desc = "",
                icon = "",
                handler = oauth_handler,
                client_id = COINBASE_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://www.coinbase.com/oauth/authorize",
                scopes = [
                    "wallet:accounts:read",
                ],
            ),
        ],
    )

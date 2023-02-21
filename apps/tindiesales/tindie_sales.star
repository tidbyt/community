"""
Applet: Tindie Sales
Summary: Shows Tindie sales numbers
Description: Tindie is an online marketplace for maker-made products. This app displays sales stats for your Tindie store.
Author: Joey Castillo
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# These are the values from Tindie's API documentation page.
# They are invalid, but at least they're canonically invalid.
# https://sf-tindie.zendesk.com/hc/en-us/articles/4401799283476-JSON-Orders-API
DEFAULT_USERNAME = "yourname"
DEFAULT_KEY = "XXXX"

# Default to sales this year.
DEFAULT_SINCE = "2022-01-01T00:00:00.0Z"

def main(config):
    products = None
    error = None
    cache_key = "products_%s" % hash.sha1(config.str("username", DEFAULT_USERNAME) +
                                          config.str("api_key", DEFAULT_KEY) +
                                          config.str("since", DEFAULT_SINCE))
    if cache.get(cache_key):
        # if we have cached product data, just use that.
        products = json.decode(cache.get(cache_key))
    elif config.str("username", DEFAULT_USERNAME) == DEFAULT_USERNAME or config.str("api_key", DEFAULT_KEY) == DEFAULT_KEY:
        # First, error out if the credentials are unset.
        error = "Tindie sales: Username or API key was invalid!"
    else:
        # User has entered their credentials, proceed to fetch data.
        products = {"shipped": 0, "unshipped": 0}
        since = time.parse_time(config.str("since", DEFAULT_SINCE))
        api_url = "https://www.tindie.com/api/v1/order/?format=json&limit=50&username=%s&api_key=%s" % (config.str("username", DEFAULT_USERNAME), config.str("api_key", DEFAULT_KEY))
        done = False

        for _ in range(int(1e10)):
            query = http.get(api_url)
            if query.status_code == 200:
                meta = query.json()["meta"]  # contains pagination link
                orders = query.json()["orders"]  # contains order data
                for order in orders:
                    date = time.parse_time(order["date"] + "Z")
                    if date < since:
                        # If this order predates the selected timeframe, stop parsing orders.
                        done = True
                        break
                    else:
                        items = 0
                        for item in order["items"]:
                            items += item["quantity"]
                        if order["shipped"]:
                            products["shipped"] += items
                        elif not order["refunded"]:
                            products["unshipped"] += items
                if meta["next"]:
                    # If the store has more than 50 orders in the target timeframe, fetch the next page.
                    api_url = "https://www.tindie.com%s" % meta["next"]
                else:
                    # Otherwise we're done here.
                    done = True
            else:
                # Credentials were invalid or something went wrong.
                error = "Tindie sales: Unable to fetch order data! (%d)" % query.status_code
                break
            if done:
                break
        if not error:
            cache.set(cache_key, json.encode(products), ttl_seconds = 1800)  # cache for a half hour

    if error:
        return render.Root(
            render.WrappedText(
                content = error,
                width = 64,
                color = "#fa0",
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Text("Tindie Sales", color = "#fff"),
                    render.Box(width = 64, height = 1, color = "#fff"),
                    render.Row(
                        children = [
                            render.Text("Unshipped:", color = "#f00"),
                            render.Text("%d" % products["unshipped"], color = "#f00"),
                        ],
                        expanded = True,
                        main_align = "space_between",
                    ),
                    render.Row(
                        children = [
                            render.Text("Shipped:", color = "#ff0"),
                            render.Text("%d" % products["shipped"], color = "#ff0"),
                        ],
                        expanded = True,
                        main_align = "space_between",
                    ),
                    render.Row(
                        children = [
                            render.Text("Total:", color = "#0f0"),
                            render.Text("%d" % (products["unshipped"] + products["shipped"]), color = "#0f0"),
                        ],
                        expanded = True,
                        main_align = "space_between",
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Tindie Username",
                desc = "Your seller account's username",
                icon = "user",
            ),
            schema.Text(
                id = "api_key",
                name = "Tindie API Key",
                desc = "Your seller account's API Key",
                icon = "key",
            ),
            schema.DateTime(
                id = "since",
                name = "Show Sales Since",
                desc = "Only count sales after this date",
                icon = "calendar",
            ),
        ],
    )

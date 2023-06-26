"""
Applet: WooCommerce Orders
Summary: Recent orders from your WooCommerce store
Description: Stats on your recent orders from your WooCommerce store.
Author: Jeremy Launder
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# CONFIG
WC_SHOP_URL = ""
WC_CONSUMER_KEY = ""
WC_CONSUMER_SECRET = ""
CACHE_TTL = 900 # 15 minutes

# COLORS
COLOR_WC_PURPLE_50 = "#7F54B3"
COLOR_WC_PURPLE_80 = "#3C2861"
COLOR_ERROR = "#FF0033"
COLOR_WARNING = "#F0D504"
COLOR_BLACK = "#000"
COLOR_WHITE = "#FFF"

# FONTS
FONT_TB8 = "tb-8"
FONT_6x13 = "6x13"
FONT_10x20 = "10x20"

# IMAGES
IMAGE_WOO_SQUARE_16X16 = """
UklGRpACAABXRUJQVlA4WAoAAAAgAAAADwAADwAASUNDUMgBAAAAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADZWUDggogAAAJACAJ0BKhAAEAABQCYlsAJ0OIAHKTdMngk0wLO8AP6JPwhphL110tdOSSPX2dkHK3oZdnfhjuMyMm+tNb+KWVLhTvEJYvzP3EmPguH2GojPUmvp3j86L5mRdNPL+sSkr6v6gYOnT/5g2xswwSpMkjSFNWjg/IFMe4utEr0rT/4Jtkcq/zv/GSrUtz5n7Ta9AE88CbxA3B6v3eupxI4bz+AAAA==
"""

APP_ID = "woocommerce_orders"

# def api_fetch(shop_url, consumer_key, consumer_secret):
#     cache_key = "{}/{}/{}".format(counter_id, APP_ID, base64.encode(json.encode(request_config)))
#     cached_value = cache.get(cache_key)
#     if cached_value != None:
#         print("Hit! Displaying cached data.")
#         api_response = json.decode(cached_value)
#         return api_response
#     else:
#         print("Miss! Calling Counter API.")
#         url = "{}/tidbyt/api/{}/{}".format(SHOPIFY_COUNTER_API_HOST, counter_id, APP_ID)
#         rep = http.post(url, body = json.encode({"config": request_config}), headers = {"Content-Type": "application/json"})
#         if rep.status_code != 200:
#             print("Counter API request failed with status {}".format(rep.status_code))
#             return None
#         api_response = rep.json()

#         # TODO: Determine if this cache call can be converted to the new HTTP cache.
#         cache.set(cache_key, json.encode(api_response), ttl_seconds = CACHE_TTL)
#         return api_response

# Error View
# Renders an error message
# -----------------------------------------------------------------------------------------
# message: A message to display as a rendered error
# Returns: A Pixlet root element
def error_view(message):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render.Padding(
                    pad = (0, 0, 0, 2),
                    child = render.Row(
                        main_align = "space_evenly",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Image(base64.decode(IMAGE_WOO_SQUARE_16X16)),
                            render.Marquee(
                                width = 48,
                                align = "center",
                                child = render.Text(
                                    content = "ERROR", 
                                    color = COLOR_ERROR
                                ),
                            ),
                        ]
                    )
                ),    
                render.Row(
                    main_align = "space_evenly",
                    children = [
                        render.Marquee(
                            width = 64,
                            align = "center",
                            offset_start = 32,
                            offset_end = 0,
                            child = render.Text(
                                content = message, 
                                color = COLOR_ERROR
                            ),
                        )
                    ]
                )				
            ],
        ),
    )

def main(config):
    shop_url = config.get("shopUrl", "https://courses.moderndirectseller.com")
    consumer_key = config.get("consumerKey", "ck_4b44d5747da4c0dfef509a1e9890f67d9042594a")
    consumer_secret = config.get("consumerSecret", "cs_cf5d00d2ea31a8ebec10cf28d6d149869d6ca0d1")
    # relative_date = config.get("relativeDate")
    # request_config = {
    #     "relativeDate": relative_date,
    #     "startDate": config.get("startDate"),
    #     "endDate": config.get("endDate"),
    # }
    # resp = http.get(shop_url.strip("/ ") + "/wp-json/wc/v3/orders", ttl_seconds = CACHE_TTL )
    url = shop_url.strip("/ ") + "/wp-json/wc/v3/orders"
    params = { 'status': "processing,completed", 'after': '2023-06-24T23:59:59-07:00' }
    resp = http.get(
        url,
        params = params,
        auth = (consumer_key, consumer_secret),
        ttl_seconds = CACHE_TTL 
    )

    if resp.status_code != 200:
        return error_view( 'Error connecting to your site. Check config and try again.' )

    # print(resp.json())
    orders = resp.json()

    if orders == []:
        return error_view( 'No orders found.' )

    num_orders = len(orders)

    if num_orders == 0:
        return error_view( 'No orders found.' )

    print('Number of orders = ' + str(len(orders)))
    
    for order in orders:
        print(int(order.get('id', 0)))
        # order_data = json.decode(order)
        
    # api_data = api_response["data"]
    # value = api_data["orders"]
    # start_date = api_data.get("startDate")
    # end_date = api_data.get("endDate")

    # if relative_date == "last_day":
    #     rendered_text = render_single_label("orders last 24 hours")
    # elif relative_date == "last_7_days":
    #     rendered_text = render_single_label("orders last 7 days")
    # elif relative_date == "last_30_days":
    #     rendered_text = render_single_label("orders last 30 days")
    # elif relative_date == "last_365_days":
    #     rendered_text = render_single_label("orders last 365 days")
    # else:
    #     rendered_text = render_double_label("{} to {}".format(start_date, end_date))

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render.Padding(
                    pad = (0, 0, 0, 2),
                    child = render.Row(
                        main_align = "space_evenly",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Image(base64.decode(IMAGE_WOO_SQUARE_16X16)),
                            render.Marquee(
                                width = 48,
                                align = "center",
                                child = render.Text(
                                    content = "# Orders", 
                                    color = COLOR_WC_PURPLE_50
                                ),
                            ),
                        ]
                    )
                ),    
                render.Row(
                    main_align = "space_evenly",
                    children = [
                        render.Marquee(
                            width = 64,
                            align = "center",
                            child = render.Text(
                                content = str(num_orders), 
                                color = COLOR_WC_PURPLE_50
                            ),
                        )
                    ]
                )
            ],
        ),
    )

def render_single_label(label):
    return render.WrappedText(
        align = "center",
        content = label,
        font = FONT_TB8,
    )

def render_double_label(label):
    return render.Column(
        cross_align = "center",
        children = [
            render.Text(
                content = "orders",
                font = FONT_TB8,
            ),
            render.Marquee(
                child = render.Row(
                    children = [
                        render.Text(
                            content = label,
                            font = FONT_TB8,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TB8,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TB8,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TB8,
                        ),
                    ],
                ),
                offset_start = 15,
                width = 50,
            ),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "shopUrl",
                name = "Shop URL",
                desc = "The URL of your WooCommerce website home page",
                icon = "link",
            ),
            schema.Text(
                id = "consumerKey",
                name = "Consumer Key",
                desc = "The consumer key for your WooCommerce API",
                icon = "key",
            ),
            schema.Text(
                id = "consumerSecret",
                name = "Consumer Secret",
                desc = "The consumer secret for your WooCommerce API",
                icon = "key",
            )
        ],
    )

"""
Applet: Shopify Chart
Summary: Display daily ecomm metrics
Description: Display daily Shopify metrics and charts for revenue, orders, or units.
Author: kcharwood
"""

load("render.star", "render")
load("cache.star", "cache")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("encoding/json.star", "json")
load("re.star", "re")
load("hash.star", "hash")

SHOPIFY_ICON_DATA = """
iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAABI1BMVEUAAACWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0iWv0idw1TP4qzi7s3O4aqfxVjS5LGz0XvN4ajS5LDP4quix16tzW+81ovT5LK10n/q8tr2+vD+/v3D25epymmcw1PZ6L3f7Mj8/fr////9/vyZwU251YanyWXX57mvznSqy2rp8tm204Dd6sPX5rmkyGGgxVn6/PbG3Jvq8tuxz3emyWTV5bb4+/K304K+147l79Hy9+imyWPG3Jz0+Oyqy2v2+e/3+vHo8divznP///6bwlCcwlKkx2DF3Jqvz3TC2pWy0HjY57zs8979/vvJ3qGqy2zS47Dm79P5+/Tf7MfI3qCx0HibwlGXv0nUrRiRAAAAEnRSTlMAInq75vu8IKn9IVzzdv51/HlGNAFfAAAAAWJLR0QrJLnkCAAAAAFvck5UAc+id5oAAAEiSURBVCjPdVLnWgJBDMw17jiQsjZU7ChqBHsBC6BS7Nh7ef+n8JKscvh9zJ/cztwm2UkABIZp2Y5jR0wDwnC9qNKIen6Hj8VVCPHYL9+XUF1IJPX/wvcPDA4Na4Xv+DpPZmR0LDuus1EdT74nJqemZ2Zzc/N88oI+pZ/8wuISEpYLdEwZYDJfFJawwoQJEY5ZxNW19Q0SNpmwwOa4hdtqZ7dEQpkJGxyOe7h/gDlOdciEo4UKVlVN6hxpgVPlEY9PVJ2Fhk5lUWhi6/RMnbNwcSnFud0qZq6uVVv6bRKTlge2sVK+uS2JUCTzDbHk7v7h8e+FT2IJuGJi4bn28vrWev/4/ApMdEO2E77DtgMkewyq92iDYXmpzjK4XXvip/+tzw/wsDO/5t4LZQAAAABJRU5ErkJggg==
"""
SHOPIFY_ICON_IMAGE = base64.decode(SHOPIFY_ICON_DATA)

ERROR_404 = "Error.404"
ERROR_401 = "Error.401"
ERROR_429 = "Error.429"
ERROR_UNKNOWN = "Error.Unknown"

def main(config):
    store_name = config.get("store_name")
    api_token = config.get("api_token")
    missing_parameter = None
    if not api_token:
        missing_parameter = "Missing API Token"
    elif not store_name:
        missing_parameter = "Missing Store Name"
    if missing_parameter:
        return error_view(missing_parameter)
    location = config.get("location") or None
    timezone = "America/New_York"
    if location:
        location = json.decode(location)
        timezone = location.get("timezone") or "America/New_York"
    current_time = time.now().in_location(timezone)
    start_of_day = time.time(year = current_time.year, month = current_time.month, day = current_time.day, location = timezone)
    utc_start_of_day = start_of_day.in_location("UTC").format("2006-01-02T15:04:05")
    print(start_of_day.format("2006-01-02T15:04:05Z07:00"))
    print(utc_start_of_day.format("2006-01-02T15:04:05Z07:00"))

    display_name = config.get("display_name") or store_name

    color_regex = r"#[0-9A-F]{3}"
    background_preference = re.findall(color_regex, config.get("background_color") or "")
    background_color = background_preference[0] if background_preference else "#000"

    foreground_preference = re.findall(color_regex, config.get("foreground_color") or "")
    foreground_color = foreground_preference[0] if foreground_preference else "#FFF"

    chart_color_preference = re.findall(color_regex, config.get("chart_color") or "")
    chart_color = chart_color_preference[0] if chart_color_preference else "#070"

    orders = get_orders(store_name = store_name, api_token = api_token, start_time = utc_start_of_day, since_id = None)
    if orders == ERROR_404:
        return error_view("Can't Find Store")
    elif orders == ERROR_401:
        return error_view("Unable to auth")
    elif orders == ERROR_429:
        return error_view("API Rate Limit")
    elif orders == ERROR_UNKNOWN:
        return error_view("Unknown Error")
    elif len(orders) == 0:
        return error_view("No Orders")

    metric = config.get("metric") or "revenue"
    metric_alignment = config.get("metric_alignment") or "center"
    title_font = config.get("title_font") or "5x8"
    title_alignment = config.get("title_alignment") or "center"
    show_chart = config.bool("show_chart")
    fill_chart = config.bool("fill_chart")
    metric_font = config.get("metric_font") or "5x8"
    excluded_skus = config.get("excluded_skus").split(",") if config.get("excluded_skus") else []
    content = "-"
    plot_data = None
    if metric == "revenue":
        order_total = get_total_from_orders(orders, excluded_skus = excluded_skus)
        plot_data = get_total_revenue_plot_data(orders, excluded_skus = excluded_skus, timezone = timezone)
        content = "${}".format(order_total)
    elif metric == "orders":
        content = "{} Orders".format(len(orders))
        plot_data = get_total_orders_plot_data(orders, excluded_skus = excluded_skus, timezone = timezone)
    elif metric == "units":
        content = "{} Units".format(get_total_units(orders, excluded_skus))
        plot_data = get_total_units_plot_data(orders, excluded_skus = excluded_skus, timezone = timezone)
    stack_children = []
    if plot_data and show_chart == True:
        stack_children.append(
            render.Plot(
                data = plot_data,
                width = 64,
                height = 32,
                color = chart_color,
                fill = fill_chart,
            ),
        )
    stack_children.append(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = title_alignment,
                            children = [
                                render.Text(font = title_font, color = foreground_color, content = display_name),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = metric_alignment,
                            children = [
                                render.Text(font = metric_font, color = foreground_color, content = content),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )
    return render.Root(
        render.Box(
            color = background_color,
            child = render.Stack(
                children = stack_children,
            ),
        ),
    )

def get_schema():
    metric_options = [
        schema.Option(
            display = "Revenue",
            value = "revenue",
        ),
        schema.Option(
            display = "Orders",
            value = "orders",
        ),
        schema.Option(
            display = "Units",
            value = "units",
        ),
    ]

    alignment_options = [
        schema.Option(
            display = "Left",
            value = "start",
        ),
        schema.Option(
            display = "Center",
            value = "center",
        ),
        schema.Option(
            display = "Right",
            value = "end",
        ),
    ]

    font_options = [
        schema.Option(
            display = "tb-8",
            value = "tb-8",
        ),
        schema.Option(
            display = "Dina_r400-6",
            value = "Dina_r400-6",
        ),
        schema.Option(
            display = "5x8",
            value = "5x8",
        ),
        schema.Option(
            display = "6x13",
            value = "6x13",
        ),
        schema.Option(
            display = "10x20",
            value = "10x20",
        ),
        schema.Option(
            display = "tom-thumb",
            value = "tom-thumb",
        ),
        schema.Option(
            display = "CG-pixel-3x5-mono",
            value = "CG-pixel-3x5-mono",
        ),
        schema.Option(
            display = "CG-pixel-4x5-mono",
            value = "CG-pixel-4x5-mono",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "store_name",
                name = "Shopify Store Name",
                desc = "The Shopify store name used for API access",
                icon = "store",
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API Token for your Shopify Private App",
                icon = "key",
            ),
            schema.Text(
                id = "display_name",
                name = "Company Name",
                desc = "The company name to display",
                icon = "signHanging",
            ),
            schema.Location(
                id = "location",
                name = "Store Location",
                desc = "The location timezone to use to calculate daily metrics.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "metric",
                name = "Metric",
                desc = "The ecomm metric to display",
                icon = "chartLine",
                default = metric_options[0].value,
                options = metric_options,
            ),
            schema.Dropdown(
                id = "title_font",
                name = "Title Font",
                desc = "The font to use to display the company name",
                icon = "font",
                default = font_options[0].value,
                options = font_options,
            ),
            schema.Dropdown(
                id = "title_alignment",
                name = "Title Alignment",
                desc = "The alignment of the company name",
                icon = "alignCenter",
                default = alignment_options[1].value,
                options = alignment_options,
            ),
            schema.Dropdown(
                id = "metric_font",
                name = "Metric Font",
                desc = "The font to use to display the selected metric",
                icon = "font",
                default = font_options[0].value,
                options = font_options,
            ),
            schema.Dropdown(
                id = "metric_alignment",
                name = "Metric Alignment",
                desc = "The alignment of the displayed metric",
                icon = "alignCenter",
                default = alignment_options[1].value,
                options = alignment_options,
            ),
            schema.Text(
                id = "excluded_skus",
                name = "Excluded SKUs",
                desc = "A comma delimited list of SKUs that should be excluded. Will match against partial skus.",
                icon = "ban",
            ),
            schema.Text(
                id = "background_color",
                name = "Background Color",
                desc = "The Background Color. Three Character RGB Hex Values (0-F) with leading # (ex: #000)",
                icon = "eyeDropper",
                default = "#000",
            ),
            schema.Text(
                id = "foreground_color",
                name = "Foreground Color",
                desc = "The Foreround Color for the Text. Three Character RGB Hex Values (0-F) with leading # (ex: #FFF)",
                icon = "eyeDropper",
                default = "#FFF",
            ),
            schema.Toggle(
                id = "show_chart",
                name = "Hourly Chart",
                desc = "Should show hourly chart",
                icon = "chartLine",
                default = True,
            ),
            schema.Toggle(
                id = "fill_chart",
                name = "Fill Chart",
                desc = "Should fill the Hourly Chart",
                icon = "fill",
                default = True,
            ),
            schema.Text(
                id = "chart_color",
                name = "Chart Color",
                desc = "The Color for the chart. Three Character RGB Hex Values (0-F) with leading # (ex: #070)",
                icon = "eyeDropper",
                default = "#070",
            ),
        ],
    )

def error_view(message):
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = SHOPIFY_ICON_IMAGE, width = 24, height = 24),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(font = "tb-8", align = "center", content = message.upper()),
                    ],
                ),
            ],
        ),
    )

def date_from_shopify_date(shopify_date):
    return time.parse_time(shopify_date, format = "2006-01-02T15:04:05Z07:00")

def get_total_revenue_plot_data(orders, excluded_skus, timezone):
    if len(orders) == 0:
        return None
    max_hour = date_from_shopify_date(orders[-1]["created_at"]).in_location(timezone).hour
    hourly_revenue = [0.0 for e in range(max_hour + 1)]
    for order in orders:
        order_date = date_from_shopify_date(order["created_at"]).in_location(timezone)
        order_hour = order_date.hour
        amount_to_exclude = 0.0
        for li in order["line_items"]:
            if should_line_item_be_excluded(li, excluded_skus):
                amount_to_exclude = ((float(li["price"]) - float(li["total_discount"])) * li["quantity"]) + amount_to_exclude
        hourly_revenue[order_hour] = hourly_revenue[order_hour] + (float(order["subtotal_price"]) - amount_to_exclude)
    hourly_revenue = [(idx, rev) for idx, rev in enumerate(hourly_revenue)]
    return hourly_revenue

def get_total_from_orders(orders, excluded_skus):
    # for order in orders:
    #     print("{}: {}".format(int(order["order_number"]), order["financial_status"]))
    total_price = 0.0
    for order in orders:
        excluded_line_item_price = 0.0
        for li in order["line_items"]:
            if should_line_item_be_excluded(li, excluded_skus):
                excluded_line_item_price = ((float(li["price"]) - float(li["total_discount"])) * li["quantity"]) + excluded_line_item_price
        total_price = total_price + (float(order["subtotal_price"]) - excluded_line_item_price)
    total_price = int(total_price)
    print("${} total line item price".format(total_price))
    return total_price

def get_line_items_from_orders(orders, excluded_skus):
    line_items = [li for li in flatten([o["line_items"] for o in orders]) if should_line_item_be_excluded(li, excluded_skus) == False]
    return line_items

def get_total_units(orders, excluded_skus):
    line_items = [li for li in flatten([o["line_items"] for o in orders]) if should_line_item_be_excluded(li, excluded_skus) == False]
    total = 0
    for li in line_items:
        total = total + li["quantity"]
    return int(total)

def get_total_units_plot_data(orders, excluded_skus, timezone):
    if len(orders) == 0:
        return None
    max_hour = date_from_shopify_date(orders[-1]["created_at"]).in_location(timezone).hour
    hourly_units = [0 for e in range(max_hour + 1)]
    for order in orders:
        order_date = date_from_shopify_date(order["created_at"]).in_location(timezone)
        order_hour = order_date.hour
        total_units = 0
        for li in order["line_items"]:
            if should_line_item_be_excluded(li, excluded_skus) == False:
                total_units = int(li["quantity"]) + total_units
        hourly_units[order_hour] = hourly_units[order_hour] + total_units
    hourly_units = [(idx, units) for idx, units in enumerate(hourly_units)]
    return hourly_units

def get_total_orders_plot_data(orders, excluded_skus, timezone):
    if len(orders) == 0:
        return None
    max_hour = date_from_shopify_date(orders[-1]["created_at"]).in_location(timezone).hour
    hourly_orders = [0 for e in range(max_hour + 1)]
    for order in orders:
        order_date = date_from_shopify_date(order["created_at"]).in_location(timezone)
        order_hour = order_date.hour
        if should_order_be_excluded(order, excluded_skus) == False:
            hourly_orders[order_hour] = hourly_orders[order_hour] + 1
    hourly_orders = [(idx, units) for idx, units in enumerate(hourly_orders)]
    return hourly_orders

def should_order_be_excluded(order, excluded_skus):
    lines = [li for li in order["line_items"] if should_line_item_be_excluded(li, excluded_skus) == False]
    return len(lines) == 0

def should_line_item_be_excluded(line_item, excluded_skus):
    if line_item["gift_card"]:
        return True
    excluded_skus = [es.lower().strip() for es in excluded_skus]
    sku = line_item["sku"].lower() if line_item.get("sku") else None
    if excluded_skus and sku:
        for ex_sku in excluded_skus:
            if ex_sku in sku:
                # print("{} is excluded".format(sku))
                return True

    # print("{} is not excluded".format(sku))

    return False

def cache_orders(orders, start_time, store_name, api_token):
    cache_key = get_cache_key(start_time, store_name, api_token)
    print("💾 caching orders with key {}".format(cache_key))
    json_orders = json.encode(orders)
    cache.set(cache_key, json_orders, ttl_seconds = 300)

def get_cached_orders(start_time, store_name, api_token):
    cache_key = get_cache_key(start_time, store_name, api_token)
    print("💾 Checking cache key {}".format(cache_key))
    raw_orders = cache.get(cache_key)
    if raw_orders:
        print("💾 Returning fetched orders from cache using key {}".format(cache_key))
        orders = json.decode(raw_orders)
        return orders
    else:
        return None

def get_cache_key(start_time, store_name, api_token):
    cache_key = "shopify_daily_chart_%s" % hash.sha1(start_time + store_name + api_token)
    return cache_key

def get_total_orders_count(store_name, api_token, start_time, since_id):
    parameters = {"limit": "250", "created_at_min": "{}Z".format(start_time), "status": "any"}
    if since_id:
        parameters["since_id"] = since_id
    else:
        parameters["since_id"] = "0"
    print("🕸 Fetching total order count {}".format(parameters))
    response = make_shopify_request(store_name = store_name, api_token = api_token, endpoint = "orders/count", parameters = parameters)
    if is_response_error(response):
        return response
    else:
        count = int(response["count"])
        print("Order Count {}".format(count))
        return count

def get_orders(store_name, api_token, start_time, since_id):
    orders = get_cached_orders(start_time, store_name, api_token)
    if orders:
        return orders
    print("Getting orders since {}".format(start_time))
    orders = []
    order_count = get_total_orders_count(store_name, api_token, start_time, since_id)
    if is_response_error(order_count):
        return order_count

    if order_count == 0:
        return []

    total_pages = int(order_count / 250) + 1
    since_id = None
    for current_page in range(total_pages):
        chunk = get_chunk_of_orders(store_name, api_token, start_time, since_id)
        if is_response_error(chunk):
            return chunk
        else:
            orders.extend(chunk)
            if len(chunk) == 0:
                break
            since_id = str(int(chunk[-1]["id"]))
            print("Setting since_id {}".format(since_id))

    orders = [o for o in orders if o["financial_status"] not in ["refunded", "voided"]]
    print("Fetched {} orders".format(len(orders)))
    if orders:
        cache_orders(orders, start_time, store_name, api_token)
    return orders

def get_chunk_of_orders(store_name, api_token, start_time, since_id):
    parameters = {"limit": "250", "created_at_min": "{}Z".format(start_time), "status": "any"}
    if since_id:
        parameters["since_id"] = since_id
        print("Using since_id {}".format(since_id))
    else:
        parameters["since_id"] = "0"
    print("🕸 Fetching orders... {}".format(parameters))
    response = make_shopify_request(store_name = store_name, api_token = api_token, endpoint = "orders", parameters = parameters)
    if is_response_error(response):
        return response
    else:
        orders = response["orders"]
        return orders

def flatten(xss):
    return [x for xs in xss for x in xs]

def make_shopify_request(store_name, api_token, endpoint, parameters):
    url = "https://{}.myshopify.com/admin/api/2022-04/{}.json".format(store_name, endpoint)
    headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}
    response = http.get(url = url, params = parameters, headers = headers)
    if response.status_code == 404:
        return ERROR_404
    elif response.status_code == 429:
        return ERROR_429
    elif response.status_code == 401:
        return ERROR_401
    elif response.status_code != 200:
        return ERROR_UNKNOWN
    return response.json()

def is_response_error(response):
    if response == ERROR_404 or response == ERROR_429 or response == ERROR_401 or response == ERROR_UNKNOWN:
        return True
    else:
        return False

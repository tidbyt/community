"""
Applet: Stripe Sales Spotlight
Summary: Showcase Stripe Sales
Description: Showcase the gross volume of sales. You can show data from today, the last 7 days, 4 weeks, 3 months, 12 months, month to date, quarter to date, year to date, or all time. Requires a Stripe API key.
Author: Seth Cottle
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STRIPE_API_BASE = "https://api.stripe.com/v1"
STRIPE_API_VERSION = "2024-06-20"
CACHE_TTL = 300  # 5 minutes
COLOR_ALOE = "#4BFE85"
COLOR_ORANGE = "#FFA500"
COLOR_STRIPE_BRAND = "#635BFF"
FONT_TOM_THUMB = "tom-thumb"
DEFAULT_STORE_NAME = "Stripe"
MAX_STORE_NAME_LENGTH = 10

def main(config):
    api_key = config.get("api_key")
    if not api_key:
        return error_view("API key not set")

    relative_date = config.get("relativeDate", "today")
    start_date, end_date = get_date_range(relative_date)

    sales_data = fetch_stripe_data(api_key, start_date, end_date)

    store_name = config.get("store_name", "").strip()
    if not store_name:
        store_name = DEFAULT_STORE_NAME

    return render_sales(sales_data, relative_date, store_name)

def fetch_stripe_data(api_key, start_date, end_date):
    cache_key = "stripe_sales_{}_{}".format(start_date, end_date)
    cached_data = cache.get(cache_key)
    if cached_data:
        return json.decode(cached_data)

    headers = {
        "Authorization": "Bearer " + api_key,
        "Stripe-Version": STRIPE_API_VERSION,
    }

    params = {
        "limit": "100",
    }

    if start_date != "all_time":
        params["created[gte]"] = start_date
        params["created[lte]"] = end_date

    url = STRIPE_API_BASE + "/charges"

    response = http.get(url, params = params, headers = headers)

    if response.status_code != 200:
        error_msg = response.body()[:500]
        return {"error": "Stripe API error ({}): {}".format(response.status_code, error_msg)}

    data = response.json()
    total_sales = 0
    for charge in data.get("data", []):
        if charge.get("status") == "succeeded":
            total_sales += charge.get("amount", 0)

    sales_data = {
        "sales": format_currency(total_sales / 100) if total_sales > 0 else "No Sales",
        "startDate": start_date,
        "endDate": end_date,
    }

    cache.set(cache_key, json.encode(sales_data), ttl_seconds = CACHE_TTL)
    return sales_data

def format_currency(amount):
    str_amount = str(amount).split(".")
    dollars = str_amount[0]
    cents = str_amount[1] if len(str_amount) > 1 else "00"
    cents = (cents + "0")[:2]
    return "${}.{}".format(dollars, cents)

def get_date_range(relative_date):
    now = time.now().in_location("UTC")
    if relative_date == "today":
        start = time.time(year = now.year, month = now.month, day = now.day, location = "UTC")
        end = now
    elif relative_date == "last_7_days":
        start = now - time.hour * 24 * 7
        end = now
    elif relative_date == "last_4_weeks":
        start = now - time.hour * 24 * 28
        end = now
    elif relative_date == "last_3_months":
        start = now - time.hour * 24 * 90
        end = now
    elif relative_date == "last_12_months":
        start = now - time.hour * 24 * 365
        end = now
    elif relative_date == "month_to_date":
        start = time.time(year = now.year, month = now.month, day = 1, location = "UTC")
        end = now
    elif relative_date == "quarter_to_date":
        quarter_start_month = ((now.month - 1) // 3) * 3 + 1
        start = time.time(year = now.year, month = quarter_start_month, day = 1, location = "UTC")
        end = now
    elif relative_date == "year_to_date":
        start = time.time(year = now.year, month = 1, day = 1, location = "UTC")
        end = now
    elif relative_date == "all_time":
        return "all_time", "all_time"
    else:
        start = now
        end = now

    return str(int(start.unix)), str(int(end.unix))

def render_sales(sales_data, relative_date, store_name):
    label_map = {
        "today": "Today",
        "last_7_days": "Last 7 days",
        "last_4_weeks": "Last 4 weeks",
        "last_3_months": "Last 3 months",
        "last_12_months": "Last 12 months",
        "month_to_date": "Month to date",
        "quarter_to_date": "Quarter to date",
        "year_to_date": "Year to date",
        "all_time": "All time",
    }
    label = label_map.get(relative_date, "Unknown")

    if "error" in sales_data:
        return error_view(sales_data["error"])

    truncated_store_name = store_name[:MAX_STORE_NAME_LENGTH]

    return render.Root(
        child = render.Box(
            padding = 1,
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Text(truncated_store_name, color = COLOR_STRIPE_BRAND, font = "tb-8"),
                    render.Text(
                        content = sales_data["sales"],
                        color = COLOR_ALOE if sales_data["sales"] != "No Sales" else COLOR_ORANGE,
                        font = "6x13",
                    ),
                    render.Text(
                        content = label,
                        font = FONT_TOM_THUMB,
                        color = "#FFF",
                    ),
                ],
            ),
        ),
    )

def error_view(message):
    return render.Root(
        child = render.Box(
            padding = 2,
            child = render.WrappedText(message, color = "#FF0000"),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Stripe API Key",
                desc = "Create a new secret key in the `Standard keys` section (https://dashboard.stripe.com/apikeys).",
                icon = "key",
            ),
            schema.Text(
                id = "store_name",
                name = "Store Name",
                desc = "Custom name to display instead of 'Stripe' (max 10 characters)",
                icon = "store",
                default = DEFAULT_STORE_NAME,
            ),
            schema.Dropdown(
                id = "relativeDate",
                name = "Date Range",
                desc = "The date range for the sales data",
                icon = "calendar",
                default = "today",
                options = [
                    schema.Option(display = "Today", value = "today"),
                    schema.Option(display = "Last 7 days", value = "last_7_days"),
                    schema.Option(display = "Last 4 weeks", value = "last_4_weeks"),
                    schema.Option(display = "Last 3 months", value = "last_3_months"),
                    schema.Option(display = "Last 12 months", value = "last_12_months"),
                    schema.Option(display = "Month to date", value = "month_to_date"),
                    schema.Option(display = "Quarter to date", value = "quarter_to_date"),
                    schema.Option(display = "Year to date", value = "year_to_date"),
                    schema.Option(display = "All time", value = "all_time"),
                ],
            ),
        ],
    )

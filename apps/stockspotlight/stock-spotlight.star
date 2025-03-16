"""
Applet: Stock Spotlight
Summary: Showcase 3 Stocks
Description: Showcase up to 3 of your favorite stocks using your own Finnhub API key (available from https://finnhub.io).
Author: Seth Cottle
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL = 60  # Cache for 1 minute
DISPLAY_TIME = 5  # Display each stock for 5 seconds
FINNHUB_GREEN = "#1DB954"

def main(config):
    api_key = config.get("api_key", "")
    if not api_key or len(api_key) < 10:  # Basic check for API key
        return render_config_screen("Please enter a valid Finnhub API key")

    stocks = [config.get("stock{}".format(i), "").upper() for i in range(1, 4) if config.get("stock{}".format(i))]
    if not stocks:
        return render_config_screen("Please enter at least one stock symbol")

    stock_data = get_stock_data(api_key, stocks)

    if not stock_data:
        return render_config_screen("Unable to fetch stock data. Please check your API key and internet connection.")

    return render.Root(
        child = render.Animation(
            children = [create_stock_display(data) for data in stock_data if data],
        ),
        delay = DISPLAY_TIME * 1000,
    )

def render_config_screen(message):
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = render.Text("FINNHUB", color = FINNHUB_GREEN, font = "6x13"),
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(message, color = FINNHUB_GREEN),
                        offset_start = 64,
                        offset_end = 64,
                    ),
                    render.Box(width = 64, height = 1),
                ],
            ),
        ),
    )

def get_stock_data(api_key, stocks):
    all_stock_data = []
    for symbol in stocks:
        if len(symbol) < 1 or len(symbol) > 5:  # Basic validation for stock symbol length
            continue
        stock_data = fetch_stock_data(api_key, symbol)
        if stock_data[4] == None:  # Only use valid data
            all_stock_data.append(stock_data)
    return all_stock_data

def fetch_stock_data(api_key, symbol):
    base_url = "https://finnhub.io/api/v1/quote"
    params = {
        "symbol": symbol,
        "token": api_key,
    }
    res = http.get(url = base_url, params = params, ttl_seconds = CACHE_TTL)

    if res.status_code == 403:
        print("Error: Access forbidden. Please check your API key and permissions.")
        return (symbol, 0, 0, 0, "API Error: Check key")
    elif res.status_code != 200:
        print("Error: HTTP status code", res.status_code)
        return (symbol, 0, 0, 0, "Error: HTTP {}".format(res.status_code))

    data = json.decode(res.body())

    if "c" not in data or not data["c"]:
        print("No data available for symbol:", symbol)
        return (symbol, 0, 0, 0, "No data")

    current_price = data["c"]
    prev_close = data["pc"]
    change = current_price - prev_close
    change_percent = (change / prev_close) * 100

    print("Data for {}: Price: {}, Change: {}, Change%: {}".format(symbol, current_price, change, change_percent))

    return (
        symbol,
        float(current_price),
        float(change),
        float(change_percent),
        None,
    )

def create_stock_display(stock_data):
    symbol, current_price, change, change_percent, error = stock_data

    if error:
        return render_config_screen(error)

    color = "#00ff00" if change >= 0 else "#ff0000"
    arrow = "▲" if change >= 0 else "▼"

    percent_text = ("-" if change < 0 else "") + format_number(abs(change_percent)) + "%"

    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(symbol, font = "6x13", color = "#ffffff"),
                        render.Text(arrow, font = "6x13", color = color),
                    ],
                ),
                render.Text("$" + format_number(current_price), font = "6x13"),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(percent_text, font = "5x8", color = color),
                    ],
                ),
            ],
        ),
    )

def format_number(num):
    rounded = int(num * 100 + 0.5) / 100.0
    str_num = str(rounded)
    if "." not in str_num:
        return str_num + ".00"
    whole, frac = str_num.split(".")
    if len(frac) == 1:
        return whole + "." + frac + "0"
    return whole + "." + frac[:2]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Finnhub API Key",
                desc = "API key for Finnhub (available from https://finnhub.io)",
                icon = "key",
            ),
            schema.Text(
                id = "stock1",
                name = "Stock Symbol 1",
                desc = "Enter Stock Symbol 1",
                icon = "chartLine",
            ),
            schema.Text(
                id = "stock2",
                name = "Stock Symbol 2",
                desc = "Enter Stock Symbol 2",
                icon = "chartLine",
            ),
            schema.Text(
                id = "stock3",
                name = "Stock Symbol 3",
                desc = "Enter Stock Symbol 3",
                icon = "chartLine",
            ),
        ],
    )

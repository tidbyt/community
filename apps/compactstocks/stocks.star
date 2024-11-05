"""
Applet: Compact Stocks
Summary: Compact stock ticker app
Description: A stock ticker app that shows the current prices & daily changes for 5 stocks of your choice.
Author: tobyxdd
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

APISTOCKS_HOST = "apistocks.p.rapidapi.com"
APISTOCKS_URL = "https://apistocks.p.rapidapi.com/intraday"

TTL_SECONDS = 3600

def fetch_data(symbol, api_key):
    rep = http.get(APISTOCKS_URL, headers = {
        "x-rapidapi-host": APISTOCKS_HOST,
        "x-rapidapi-key": api_key,
    }, params = {
        "symbol": symbol,
        "interval": "5min",
        "maxreturn": "144",  # Get last 12 hours of data
    }, ttl_seconds = TTL_SECONDS)
    if rep.status_code != 200:
        print("Stock API request failed with status %d" % rep.status_code)
        return None

    data = rep.json()
    if not data or "Results" not in data or len(data["Results"]) == 0:
        print("Invalid response from Stock API: %s" % data)
        return None

    return data

def calculate_last_day_percentage(data):
    results = data["Results"]

    last_date = results[-1]["Date"].split(" ")[0]
    previous_close = None
    for entry in reversed(results):
        if not entry["Date"].startswith(last_date):
            previous_close = entry["Close"]
            break

    # If we don't have a previous close, return 0.0.
    if previous_close == None:
        return 0.0

    last_close = results[-1]["Close"]
    move_percentage = ((last_close - previous_close) / previous_close) * 100

    return move_percentage

# Format the price to 2 decimal places and pad to 7 characters.
def format_price(close_price):
    price_value = int(close_price * 100 + 0.5) / 100.0
    price_parts = str(price_value).split(".")
    if len(price_parts) == 1:
        price_str = price_parts[0] + ".00"  # If there's no decimal part, add ".00"
    elif len(price_parts[1]) == 1:
        price_str = price_parts[0] + "." + price_parts[1] + "0"  # If there's only 1 decimal digit, add a 0
    else:
        price_str = price_parts[0] + "." + price_parts[1][:2]  # Limit to two decimal places

    # Pad the price to 7 characters for alignment
    if len(price_str) < 7:
        price_str = " " * (7 - len(price_str)) + price_str
    return price_str

# Format the percentage
def format_percentage(percentage):
    percentage_abs = abs(percentage)
    percentage_value = int(percentage_abs * 10 + 0.5) / 10.0
    if percentage_value >= 100:
        # Remove decimal for values >= 100
        percentage_str = str(int(percentage_value)) + "%"
    else:
        percentage_str = str(percentage_value) + "%"
    if len(percentage_str) < 5:
        percentage_str = " " * (5 - len(percentage_str)) + percentage_str
    return percentage_str

# Pad or truncate the symbol to a fixed width of 4 characters.
def pad_symbol(symbol):
    if len(symbol) < 4:
        return symbol + " " * (4 - len(symbol))
    return symbol[:4]

# Format the symbol, price, and percentage
def render_entry(symbol, color, close_price, percentage):
    symbol_padded = pad_symbol(symbol)
    price_str = format_price(close_price)
    percentage_str = format_percentage(percentage)
    percentage_color = "#f00" if percentage < 0 else "#0f0"

    # Create the symbol column
    symbol_column = render.Column(
        cross_align = "start",
        children = [
            render.Text(
                symbol_padded,
                font = "tom-thumb",
                color = color,
            ),
        ],
    )

    # Create the price column
    price_column = render.Column(
        cross_align = "end",
        children = [
            render.Text(
                price_str,
                font = "tom-thumb",
                color = "#fff",
            ),
        ],
    )

    # Create the percentage column
    percentage_column = render.Column(
        cross_align = "end",
        children = [
            render.Text(
                percentage_str,
                font = "tom-thumb",
                color = percentage_color,
            ),
        ],
    )

    # Create the main row with space between the columns
    return render.Row(
        main_align = "space_between",
        expanded = True,
        children = [
            symbol_column,
            price_column,
            percentage_column,
        ],
    )

def main(config):
    api_key = config.str("api_key")
    symbol_list = [
        (config.str("symbol1", "_EX1"), config.str("color1", "#fff")),
        (config.str("symbol2", "_EX2"), config.str("color2", "#fff")),
        (config.str("symbol3", "_EX1"), config.str("color3", "#fff")),
        (config.str("symbol4", "_EX2"), config.str("color4", "#fff")),
        (config.str("symbol5", "_EX1"), config.str("color5", "#fff")),
    ]
    render_children = []

    for se in symbol_list:
        symbol, color = se
        if not symbol.startswith("_EX"):
            if not api_key:
                return render.Root(
                    render.Box(
                        child = render.Text("No API key", color = "#f00"),
                    ),
                )

            data = fetch_data(symbol, api_key)
            if not data:
                return render.Root(
                    render.Box(
                        child = render.WrappedText("Failed to fetch %s" % symbol, color = "#f00"),
                    ),
                )
            symbol = data["Metadata"]["Symbol"]
            latest = data["Results"][-1]
            close_price = latest["Close"]
            percentage_change = calculate_last_day_percentage(data)
            render_children.append(
                render_entry(symbol, color, close_price, percentage_change),
            )
        else:
            # Example data
            render_children.append(render_entry("XMP1", "#8ff", 114.5, 1.4) if symbol == "_EX1" else render_entry("XM2", "#f8f", 33.8, -6.6))

    return render.Root(
        render.Column(
            children = render_children,
            main_align = "center",
            expanded = True,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "https://apistocks.com/ API key",
                icon = "key",
            ),
            schema.Text(
                id = "symbol1",
                name = "Symbol 1",
                desc = "The 1st stock symbol to display",
                icon = "arrowTrendUp",
            ),
            schema.Color(
                id = "color1",
                name = "Color 1",
                desc = "The color of the 1st stock symbol",
                icon = "palette",
                default = "#fff",
            ),
            schema.Text(
                id = "symbol2",
                name = "Symbol 2",
                desc = "The 2nd stock symbol to display",
                icon = "arrowTrendDown",
            ),
            schema.Color(
                id = "color2",
                name = "Color 2",
                desc = "The color of the 2nd stock symbol",
                icon = "palette",
                default = "#fff",
            ),
            schema.Text(
                id = "symbol3",
                name = "Symbol 3",
                desc = "The 3rd stock symbol to display",
                icon = "arrowTrendUp",
            ),
            schema.Color(
                id = "color3",
                name = "Color 3",
                desc = "The color of the 3rd stock symbol",
                icon = "palette",
                default = "#fff",
            ),
            schema.Text(
                id = "symbol4",
                name = "Symbol 4",
                desc = "The 4th stock symbol to display",
                icon = "arrowTrendDown",
            ),
            schema.Color(
                id = "color4",
                name = "Color 4",
                desc = "The color of the 4th stock symbol",
                icon = "palette",
                default = "#fff",
            ),
            schema.Text(
                id = "symbol5",
                name = "Symbol 5",
                desc = "The 5th stock symbol to display",
                icon = "arrowTrendUp",
            ),
            schema.Color(
                id = "color5",
                name = "Color 5",
                desc = "The color of the 5th stock symbol",
                icon = "palette",
                default = "#fff",
            ),
        ],
    )

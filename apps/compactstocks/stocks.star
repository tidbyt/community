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

def fetch_data(symbol, api_key):
    rep = http.get(APISTOCKS_URL, headers = {
        "x-rapidapi-host": APISTOCKS_HOST,
        "x-rapidapi-key": api_key,
    }, params = {
        "symbol": symbol,
        "interval": "5min",
        "maxreturn": "144",  # Get last 12 hours of data
    }, ttl_seconds = 3600)
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

def render_entry(symbol, color, close_price, percentage):
    percentage_abs = abs(percentage)
    return render.Marquee(
        width = 64,
        child = render.Row(
            children = [
                render.Text("%s " % (symbol), font = "tom-thumb", color = color),
                render.Text("%s " % (int(close_price * 100) / 100), font = "tom-thumb"),
                render.Text("%s%%" % (int(percentage_abs * 10) / 10), font = "tom-thumb", color = "#f00" if percentage < 0 else "#0f0"),
            ],
        ),
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
            render_children.append(render_entry(symbol, color, close_price, calculate_last_day_percentage(data)))
        else:
            # Example data
            render_children.append(render_entry("XMPL1", "#8ff", 114.5, 1.4) if symbol == "_EX1" else render_entry("XMPL2", "#f8f", 233.8, -6.6))

    return render.Root(
        render.Box(
            child = render.Column(children = render_children),
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

"""
Applet: Stock Ticker
Summary: 3 stocks scrolling
Description: This is a simple stock ticker app, that will display a stock ticker for 3 stock symbols.  If you want more, spin up a second copy of the app to have more stocks tick.
Author: hollowmatt
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
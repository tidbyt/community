"""
Applet: Top Cryptos
Summary: Top Cryptocurrency Prices
Description: The latest prices of the most important cryptocurrencies.
Author: playak
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

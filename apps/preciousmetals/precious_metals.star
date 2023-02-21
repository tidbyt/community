"""
Applet: Precious Metals
Summary: Quotes on precious metals
Description: Quotes for gold, platinum and silver.
Author: threeio
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

METALS_PRICE_URL = "https://api.metals.live/v1/spot"

IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAHhJREFUOE+1k7sNwDAIRPGojBB5DisjMGoiCiTCJyJGoXHhu2dOhgHNGk0/pABEvCyciJw+BLB5HtM1t84FFuIAmVloFvIAWDOLpXRHGpICWBTFYGAJIEI+LagM0Lm3IkT5XyPwZesX5MXWHGjI9iR+2Y//lqnaxQ21HFYRgy5eOgAAAABJRU5ErkJggg==""")

def main():
    rep = http.get(METALS_PRICE_URL)
    if rep.status_code != 200:
        fail("api.metals.live request failed with status %d", rep.status_code)

    print(rep.json())
    gold = rep.json()[0]["gold"]
    silver = rep.json()[1]["silver"]
    platinum = rep.json()[2]["platinum"]

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 14,
                        child = render.Image(src = IMAGE),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#C0C0C0", font = "tom-thumb", content = "Ag %s" % silver),
                            render.Text(height = 10, color = "#FFD700", font = "tom-thumb", content = "Au %s" % gold),
                            render.Text(height = 10, color = "#E5E4E2", font = "tom-thumb", content = "Pt %s" % platinum),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

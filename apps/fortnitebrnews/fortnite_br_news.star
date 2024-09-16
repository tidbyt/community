"""
Applet: Fortnite BR News
Summary: Displays Fortnite BR News
Description: Uses Fornite-API to scroll through news regarding Fortnite Battle Royale.
Author: Brian989-source
"""

load("http.star", "http")
load("render.star", "render")

FORTNITE_NEWS_URL = "https://fortnite-api.com/v2/news/br"

def main():
    rep = http.get(FORTNITE_NEWS_URL, ttl_seconds = 1200)

    if rep.status_code != 200:
        fail("Fortnite API request failed with status %d", rep.status_code)

    news_items = rep.json()["data"]["motds"]

    # Create a list of render.Column nodes, one for each news item
    news_columns = []
    for news_item in news_items:
        title_text = render.WrappedText(content = news_item["title"], width = 64, align = "center", color = "#BB8FCE", font = "CG-pixel-4x5-mono")
        body_text = render.WrappedText(content = news_item["body"], width = 64, font = "CG-pixel-3x5-mono", linespacing = 2, color = "#00FFFF", align = "left")

        # Add padding below and above the title
        title_with_padding = render.Padding(child = title_text, pad = (0, 10, 0, 6))

        news_columns.append(render.Column(children = [title_with_padding, body_text]))

    # Combine the news columns in a column layout
    news_layout = render.Column(children = news_columns)

    # Wrap the news layout in a Marquee widget to scroll them vertically
    news_marquee = render.Marquee(
        child = news_layout,
        scroll_direction = "vertical",
        height = 32,
        align = "center",
        width = 64,
    )

    # Add a stationary box with the "Fortnite BR News" text centered inside
    brnews_box = render.Box(
        width = 64,
        height = 7,
        color = "#FF0000",
        child = render.WrappedText(content = "Fortnite BR News", color = "#000000", align = "center", font = "CG-pixel-3x5-mono"),
    )

    # Combine the news box and the scrolling news marquee in a column layout
    brnews_layout = render.Column(children = [brnews_box, news_marquee])

    return render.Root(child = brnews_layout)

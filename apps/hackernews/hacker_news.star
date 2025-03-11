"""
Applet: Hacker News
Summary: Hacker News Top Stories
Description: See recent top stories submitted to Hacker News with info about upvotes and number of comments.
Author: Nick Comer
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

TOP_STORIES_DATA_ENDPOINT = "https://hn-top-tidbyt-prod.nkcmr.dev/top-stories.json"

YC_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAMAAAC67D+PAAAAY1BMVEX/ZgD/pGf/nVv/aAT/n17/
5NL/chT/ZQD/ZAD/aAP/wpn/t4f/bw7/wJb/ZwL/28P/38r/1Lf/49H/nl7/toX/o2X/0bL/eB//
mFP/bg3/lU7/28L/awj/qW//kkn/rXb/mlb8dFfCAAAATElEQVQI1zXKRxKAIBQD0KjAD/be2/1P
KaBmkXmTCQAhQIFLec+QUyWO7PRk6sPPsjTXUJnw4KpbRYTs45bLS/bFJzBLf0oc/YS1vh+u0gKf
2u13AAAAAABJRU5ErkJggg==
""")

def main():
    resp = http.get(TOP_STORIES_DATA_ENDPOINT)
    if resp.status_code != 200:
        fail("Data request failed with status %d", resp.status_code)

    stories = resp.json()["stories"]

    story_widgets = []
    for i in range(len(stories)):
        column_widgets = [
            render.WrappedText(stories[i]["title"], font = "5x8"),
            render.Box(width = 1, height = 2),  # padding
            render.Row(children = [
                render.Text("points:   ", font = "tom-thumb", color = "#ccc"),
                render.Text("%d" % (stories[i]["score"]), font = "tom-thumb", color = "#f60"),
            ]),
            render.Box(width = 1, height = 1),  # padding
            render.Row(children = [
                render.Text("comments: ", font = "tom-thumb", color = "#ccc"),
                render.Text("%d" % (stories[i]["descendants"]), font = "tom-thumb", color = "#f60"),
            ]),
        ]
        if i < (len(stories) - 1):
            column_widgets.extend([
                render.Box(height = 1, color = "#ccc"),
                render.Box(width = 1, height = 2),  # padding
            ])
        story_widgets.append(
            render.Column(
                children = column_widgets,
            ),
        )

    return render.Root(
        delay = 80,
        child = render.Column(
            children = [
                render.Box(width = 1, height = 1),  # padding
                render.Row(
                    main_align = "start",
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 1, height = 1),  # padding
                                render.Image(src = YC_ICON, width = 10, height = 10),
                                render.Box(width = 3, height = 1),  # padding
                                render.Column(
                                    children = [
                                        render.Box(width = 1, height = 3),  # padding
                                        render.Text("Hacker News", font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(width = 1, height = 1),  # padding
                render.Box(height = 1, color = "#ccc"),
                render.Box(width = 1, height = 1),  # padding
                render.Marquee(
                    scroll_direction = "vertical",
                    height = 18,
                    child = render.Column(
                        children = story_widgets,
                    ),
                ),
            ],
        ),
    )

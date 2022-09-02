"""
Applet: Blackout
Summary: Blackout tidbyt
Description: Black out Tidbyt during evenings (or whenever).
Author: mabroadfo1027
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")

def main():
    pulseList = []
    for i in range(0, 10):
        pulseList.append(render.Text(".", color = "#8B0000" if i % 10 == 0 else "#000000"))

    return render.Root(
        delay = 1000,
        child = render.Box(
            render.Column(
                main_align = "end",
                cross_align = "end",
                expanded = True,
                children = [render.Animation(children = pulseList)],
            ),
        ),
    )

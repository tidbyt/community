"""
Applet: Random Colors
Summary: Generates random color
Description: Generates random color and corresponding hex code.
Author: M0ntyP
"""

load("random.star", "random")
load("render.star", "render")

def main():
    COLORS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

    RANDOM1 = random.number(0, 15)
    RANDOM2 = random.number(0, 15)
    RANDOM3 = random.number(0, 15)
    RANDOM4 = random.number(0, 15)
    RANDOM5 = random.number(0, 15)
    RANDOM6 = random.number(0, 15)

    COLOR_STRING = "#" + COLORS[RANDOM1] + COLORS[RANDOM2] + COLORS[RANDOM3] + COLORS[RANDOM4] + COLORS[RANDOM5] + COLORS[RANDOM6]

    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [render.Box(width = 64, height = 24, color = COLOR_STRING)],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [render.Box(width = 64, height = 8, child = render.Text(content = COLOR_STRING, color = COLOR_STRING))],
                ),
            ],
        ),
    )

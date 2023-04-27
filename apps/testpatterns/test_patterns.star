"""
Applet: Test Patterns
Author: harrisonpage
Summary: Pretty test patterns
Description: Test patterns are as old as TV broadcasts.
"""

load("random.star", "random")
load("render.star", "render")

COLORS = [
    "#ffffff",
    "#ECF0F1",
    "#95A5A6",
    "#BDC3C7",
    "#333333",
    "#A4C400",
    "#60A917",
    "#008A00",
    "#00ABA9",
    "#1BA1E2",
    "#0050EF",
    "#6A00FF",
    "#AA00FF",
    "#F472D0",
    "#D80073",
    "#A20025",
    "#E51400",
    "#FA6800",
    "#F0A30A",
    "#E3C800",
    "#825A2C",
    "#6D8764",
    "#647687",
    "#76608A",
    "#A0522D",
]

def get_next_color():
    return COLORS[random.number(0, len(COLORS) - 1)]

def main():
    return render.Root(
        render.Row(
            expanded = True,
            children = [
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
                column(get_next_color()),
            ],
        ),
    )

def column(color):
    return render.Column([
        render.Row([
            render.Box(width = 8, height = 32, color = color),
        ]),
    ])

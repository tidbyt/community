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

def shuffle_colors(colors):
    colors_copy = colors[:]  # Make a copy of the colors list
    for i in range(len(colors_copy) - 1, 0, -1):
        j = random.number(0, i)
        colors_copy[i], colors_copy[j] = colors_copy[j], colors_copy[i]  # Swap
    return colors_copy

def main():
    colors = shuffle_colors(COLORS)[:8]
    return render.Root(
        render.Row(
            expanded = True,
            children = [
                column(colors[0]),
                column(colors[1]),
                column(colors[2]),
                column(colors[3]),
                column(colors[4]),
                column(colors[5]),
                column(colors[6]),
                column(colors[7]),
            ],
        ),
    )

def column(color):
    return render.Column([
        render.Row([
            render.Box(width = 8, height = 32, color = color),
        ]),
    ])

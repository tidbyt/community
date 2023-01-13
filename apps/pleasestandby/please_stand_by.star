"""
Applet: Please Stand By
Summary: Displays Please Stand By
Description: Displays Please Stand By message.
Author: Ethan Fuerst (@ethanfuerst)
"""

load("render.star", "render")
load("schema.star", "schema")

RED = "#FF3333"
ORANGE = "#FF9933"
YELLOW = "#FFFF33"
LIGHT_GREEN = "#99FF33"
GREEN = "#33FF33"
LIGHT_BLUE = "#33FFFF"
BLUE = "#3399FF"
PURPLE = "#3333FF"
VIOLET = "#9933FF"
PINK = "#FF33FF"
DARK_PINK = "#FF3399"
LIGHT_GREY = "#C0C0C0"
MID_GREY = "#404040"
DARK_GREY = "#808080"
BLACK = "#000000"
WHITE = "#FFFFFF"

def box_row():
    return render.Row(
        children = [
            render.Box(width = 8, height = 8, color = LIGHT_GREY),
            render.Box(width = 8, height = 8, color = YELLOW),
            render.Box(width = 8, height = 8, color = LIGHT_BLUE),
            render.Box(width = 8, height = 8, color = GREEN),
            render.Box(width = 8, height = 8, color = PINK),
            render.Box(width = 8, height = 8, color = RED),
            render.Box(width = 8, height = 8, color = BLUE),
            render.Box(width = 8, height = 8, color = DARK_PINK),
        ],
    )

def ani_image():
    return render.Column(
        children = [
            box_row(),
            render.Row(
                children = [
                    render.Box(width = 8, height = 8, color = LIGHT_GREY),
                    render.Stack(
                        children = [
                            render.Marquee(
                                width = 48,
                                child = render.Text(
                                    content = "PLEASE STAND BY",
                                ),
                                offset_start = 1,
                            ),
                        ],
                    ),
                    render.Box(width = 8, height = 8, color = DARK_PINK),
                ],
            ),
            box_row(),
            render.Row(
                children = [
                    render.Box(width = 8, height = 4, color = LIGHT_BLUE),
                    render.Box(width = 8, height = 4, color = BLACK),
                    render.Box(width = 8, height = 4, color = PINK),
                    render.Box(width = 8, height = 4, color = MID_GREY),
                    render.Box(width = 8, height = 4, color = LIGHT_BLUE),
                    render.Box(width = 8, height = 4, color = DARK_GREY),
                    render.Box(width = 8, height = 4, color = WHITE),
                    render.Box(width = 8, height = 4, color = RED),
                ],
            ),
            render.Row(
                children = [
                    render.Box(width = 9, height = 4, color = BLUE),
                    render.Box(width = 9, height = 4, color = WHITE),
                    render.Box(width = 10, height = 4, color = PURPLE),
                    render.Box(width = 10, height = 4, color = MID_GREY),
                    render.Box(width = 2, height = 4, color = BLACK),
                    render.Box(width = 2, height = 4, color = DARK_GREY),
                    render.Box(width = 4, height = 4, color = MID_GREY),
                    render.Box(width = 8, height = 4, color = DARK_GREY),
                    render.Box(width = 8, height = 4, color = ORANGE),
                    render.Box(width = 2, height = 4, color = LIGHT_GREY),
                ],
            ),
        ],
    )

def main():
    return render.Root(
        delay = 100,
        child = ani_image(),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

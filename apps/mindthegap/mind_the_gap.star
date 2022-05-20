"""
Applet: Mind The Gap
Summary: Advice for Londoners
Description: Important advice for Londoners to remember at all times.
Author: dinosaursrarr
"""

load("render.star", "render")
load("schema.star", "schema")

YELLOW = "#fc0"
GREY = "#333"
BLACK = "#000"
WHITE = "#fff"
MESSAGE = "MIND THE GAP"
TOAST_MESSAGE = "MIND THE    GAP"

def main(config):
    if config.bool("toast", False):
        message = TOAST_MESSAGE
    else:
        message = MESSAGE

    return render.Root(
        child = render.Box(
            height = 32,
            width = 64,
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Box(
                        height = 10,
                        width = 64,
                        color = BLACK,
                    ),
                    render.Box(
                        height = 2,
                        width = 64,
                        color = WHITE,
                    ),
                    render.Box(
                        height = 8,
                        width = 64,
                        color = GREY,
                        child = render.Text(
                            content = message,
                            color = YELLOW,
                        ),
                    ),
                    render.Box(
                        height = 2,
                        width = 64,
                        color = YELLOW,
                    ),
                    render.Box(
                        height = 20,
                        width = 64,
                        color = GREY,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # https://www.youtube.com/watch?v=yJ3yjjv-gRA
            schema.Toggle(
                id = "toast",
                name = "How about a funky one?",
                desc = "Leave quite a long gap between the words 'the' and 'gap'",
                icon = "arrowsLeftRightToLine",
                default = False,
            ),
        ],
    )

"""
Applet: Developer Excuse
Summary: Developer Excuse
Description: Developer Excuse app generates playful and imaginative excuses to bring a smile to developers facing coding hiccups and bugs.
Author: masonwongcs
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

EXCUSE_URL = "https://excuser-three.vercel.app/v1/excuse/developers/"
DEFAULT_COLOR = "#ffffff"
DEFAULT_DIRECTION = "horizontal"

def main(config):
    rep = http.get(EXCUSE_URL)
    if rep.status_code != 200:
        fail("Excuse request failed with status %d", rep.status_code)

    excuse = rep.json()[0]["excuse"]
    direction = config.get("direction", DEFAULT_DIRECTION)
    color = config.get("text_color", DEFAULT_COLOR)

    if (direction == "vertical"):
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            height = 32,
                            scroll_direction = "vertical",
                            child = render.WrappedText(
                                content = excuse,
                                width = 64,
                                color = color,
                            ),
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = excuse,
                                color = color,
                            ),
                        ),
                    ],
                ),
            ),
        )

def get_schema():
    directions = [
        schema.Option(display = "Horizontal", value = "horizontal"),
        schema.Option(display = "Vertical", value = "vertical"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "To set the color of the text.",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "direction",
                icon = "gear",
                name = "Direction",
                desc = "To control the direction of the marquee.",
                options = directions,
                default = DEFAULT_DIRECTION,
            ),
        ],
    )

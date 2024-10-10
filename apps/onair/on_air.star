"""
Applet: On Air
Summary: Displays On Air Sign
Description:  Displays 'On Air' Sign that you turn on or off.
Author: Robert Ison
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    display_type = config.get("display", display_options[0].value)
    outline_color = "#fff"
    text_color = "#fff"
    background_color = "#f00"

    display_items = []

    if display_type == "hide":
        return []
    elif display_type == "off":
        text_color = "#5b5c61"
        background_color = "#c80900"
        outline_color = "#5b5c61"

    display_items.append(render.Box(width = 64, height = 32, color = outline_color))
    display_items.append(add_padding_to_child_element(render.Box(width = 62, height = 30, color = background_color), 1, 1))
    display_items.append(add_padding_to_child_element(render.Text("ON", font = "10x20", color = text_color), 5, 7))
    display_items.append(add_padding_to_child_element(render.Text("AIR", font = "10x20", color = text_color), 28, 7))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

display_options = [
    schema.Option(
        display = "On Air",
        value = "on",
    ),
    schema.Option(
        display = "Not On Air",
        value = "off",
    ),
    schema.Option(
        display = "Hide",
        value = "hide",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "What do you want to display?",
                icon = "stopwatch",
                options = display_options,
                default = display_options[0].value,
            ),
        ],
    )

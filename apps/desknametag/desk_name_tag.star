"""
Applet: Desk Name Tag
Summary: Tell coworkers about you
Description: Displays basic employee information to coworkers.
Author: Brian Bell
"""

load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_NAME = "John Smith"
DEFAULT_LINE_ONE = "Technology"
DEFAULT_LINE_TWO = "Enterprise"
DEFAULT_TEXT_COLOR = "#FFFFFF"
DEFAULT_BACKGROUND_COLOR = "#00008B"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    line_one = config.str("line_one", DEFAULT_LINE_ONE)
    line_two = config.str("line_two", DEFAULT_LINE_TWO)
    text_color = config.str("text_color", DEFAULT_TEXT_COLOR)
    if re.findall("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", text_color) == ():
        text_color = DEFAULT_TEXT_COLOR
    background_color = config.str("background_color", DEFAULT_BACKGROUND_COLOR)
    if re.findall("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", background_color) == ():
        background_color = DEFAULT_BACKGROUND_COLOR

    return render.Root(
        delay = 150,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            color = background_color,
                            height = 15,
                            child = render.Marquee(
                                align = "center",
                                width = 64,
                                child = render.Text(
                                    content = name,
                                    font = "6x13",
                                    color = text_color,
                                ),
                            ),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (0, 0, 0, 1),
                    child = render.Marquee(
                        align = "center",
                        width = 64,
                        child = render.Text(content = line_one),
                    ),
                ),
                render.Box(
                    color = background_color,
                    height = 1,
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Marquee(
                        align = "center",
                        width = 64,
                        child = render.Text(
                            content = line_two,
                            font = "tom-thumb",
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Enter your name.",
                icon = "user",
            ),
            schema.Text(
                id = "line_one",
                name = "Tag Line One",
                desc = "Enter your message for line one.",
                icon = "briefcase",
            ),
            schema.Text(
                id = "line_two",
                name = "Tag Line Two",
                desc = "Enter your message for line two.",
                icon = "peopleArrowsLeftRight",
            ),
            schema.Text(
                id = "text_color",
                name = "Text Color (ex: #FFFFFF)",
                desc = "Enter a valid color hex code: #FFFFFF",
                icon = "paintbrush",
            ),
            schema.Text(
                id = "background_color",
                name = "Background Color (ex: #00008B)",
                desc = "Enter a valid color hex code: #00008B",
                icon = "fillDrip",
            ),
        ],
    )

"""
Applet: Desk Name Tag
Summary: Tell coworkers about you
Description: Displays basic employee information to coworkers.
Author: Brian Bell
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("re.star", "re")
load("schema.star", "schema")

DEFAULT_NAME = "John Smith"
DEFAULT_DEPARTMENT = "Technology"
DEFAULT_PRONOUNS = ""
DEFAULT_TEXT_COLOR = "#FFFFFF"
DEFAULT_BACKGROUND_COLOR = "#00008B"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    department = config.str("department", DEFAULT_DEPARTMENT)
    pronouns = config.str("pronouns", DEFAULT_PRONOUNS)
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
                        child = render.Text(content = department),
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
                            content = pronouns,
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
                id = "department",
                name = "Department",
                desc = "Enter your department.",
                icon = "briefcase",
            ),
            schema.Text(
                id = "pronouns",
                name = "Pronouns",
                desc = "Enter your pronouns.",
                icon = "peopleArrowsLeftRight",
            ),
            schema.Text(
                id = "text_color",
                name = "Text Color",
                desc = "Enter a valid hex string: #FFFFFF",
                icon = "paintbrush",
            ),
            schema.Text(
                id = "background_color",
                name = "Background Color",
                desc = "Enter a valid hex string: #00008B",
                icon = "fillDrip",
            ),
        ],
    )

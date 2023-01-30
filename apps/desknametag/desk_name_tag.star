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
DEFAULT_BACKGROUND_COLOR = "#0000FF"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    line_one = config.str("line_one", DEFAULT_LINE_ONE)
    line_two = config.str("line_two", DEFAULT_LINE_TWO)
    text_color = config.str("text_color", DEFAULT_TEXT_COLOR)
    custom_text_color = config.str("custom_text_color")
    background_color = config.str("background_color", DEFAULT_BACKGROUND_COLOR)
    custom_background_color = config.str("custom_background_color")

    if (custom_text_color != None):
        if (re.findall("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", custom_text_color)):
            text_color = custom_text_color
        elif (re.findall("^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", custom_text_color)):
            text_color = "#" + custom_text_color

    if (custom_background_color != None):
        if (re.findall("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", custom_background_color)):
            background_color = custom_background_color
        elif (re.findall("^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", custom_background_color)):
            background_color = "#" + custom_background_color

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
                        child = render.Text(
                            content = line_one,
                            color = text_color,
                        ),
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
                            color = text_color,
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    color_options = [
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Cyan",
            value = "#00FFFF",
        ),
        schema.Option(
            display = "Blue",
            value = "#0000FF",
        ),
        schema.Option(
            display = "Light Blue",
            value = "#ADD8E6",
        ),
        schema.Option(
            display = "Dark Blue",
            value = "#0000A0",
        ),
        schema.Option(
            display = "Purple",
            value = "#800080",
        ),
        schema.Option(
            display = "Yellow",
            value = "#FFFF00",
        ),
        schema.Option(
            display = "Lime",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Magenta",
            value = "#FF00FF",
        ),
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
        schema.Option(
            display = "Silver",
            value = "#C0C0C0",
        ),
        schema.Option(
            display = "Gray",
            value = "#808080",
        ),
        schema.Option(
            display = "Black",
            value = "#000000",
        ),
        schema.Option(
            display = "Orange",
            value = "#FFA500",
        ),
        schema.Option(
            display = "Brown",
            value = "#A52A2A",
        ),
        schema.Option(
            display = "Maroon",
            value = "#800000",
        ),
        schema.Option(
            display = "Green",
            value = "#008000",
        ),
        schema.Option(
            display = "Olive",
            value = "#808000",
        ),
    ]
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
                name = "Line One",
                desc = "Enter your message for line one.",
                icon = "1",
            ),
            schema.Text(
                id = "line_two",
                name = "Line Two",
                desc = "Enter your message for line two.",
                icon = "2",
            ),
            schema.Dropdown(
                id = "text_color",
                name = "Text Color",
                desc = "A selection of standard colors for text.",
                icon = "paintbrush",
                default = color_options[9].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "background_color",
                name = "Background Color",
                desc = "A selection of standard colors for the background.",
                icon = "fillDrip",
                default = color_options[2].value,
                options = color_options,
            ),
            schema.Text(
                id = "custom_text_color",
                name = "Custom Text Hex Color",
                desc = "Enter a valid color hex code: FFFFFF",
                icon = "hashtag",
            ),
            schema.Text(
                id = "custom_background_color",
                name = "Custom Background Hex Color",
                desc = "Enter a valid color hex code: 0000FF",
                icon = "hashtag",
            ),
        ],
    )

"""
Applet: Custom Status
Summary: Share a custom status
Description: Share a custom status with coworkers.
Author: Brian Bell
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_NAME = "Jane Smith"
DEFAULT_STATUS = "Focusing"
DEFAULT_COLOR = "#FFFF00"
DEFAULT_ICON = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAb0lEQVQYlYXOsQnCUBAG4C8khQMIGccJsoCNSFrLLCPWlklhJ7hDLDNIOovY
XOAhD3PNcT8fP8f2XDFtoQ4LHv/QJdBtDWoUP6gNdE/DD8bkPgYaUlRixgn7aO7xRJP7
5xwtC145UMZ+Y4cKhxz8Al5ZEuTs2wZwAAAAAElFTkSuQmCC
"""
DEFAULT_MESSAGE = "Until later"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    status = config.get("status", DEFAULT_STATUS)
    color = config.get("color", DEFAULT_COLOR)
    icon = base64.decode(config.get("icon", DEFAULT_ICON))
    message = config.get("message", DEFAULT_MESSAGE)
    animations = config.bool("animation", False)

    if not animations:
        return render.Root(
            child = render.Row(
                children = [
                    render.Box(
                        color = color,
                        width = 10,
                        child = render.Image(src = icon, width = 10),
                    ),
                    render.Padding(
                        pad = (1, 2, 0, 1),
                        child = render.Column(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Marquee(
                                    child = render.Text(
                                        content = name + " is",
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                                render.Marquee(
                                    child = render.Text(
                                        content = status.upper(),
                                        font = "6x13",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                                render.Marquee(
                                    child = render.Text(
                                        content = message,
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Stack(
                children = [
                    # Left side color indicator
                    animation.Transformation(
                        child = render.Box(
                            color = color,
                            width = 10,
                            child = render.Image(src = icon, width = 10),
                        ),
                        duration = 282,
                        delay = 0,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(-64, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.16,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.80,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-64, 0)],
                            ),
                        ],
                    ),
                    # Name row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = name + " is",
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 34)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.10,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.81,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 2)],
                            ),
                        ],
                    ),
                    # Status row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = status.upper(),
                                font = "6x13",
                            ),
                            offset_start = 0,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 42)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.17,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.83,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 10)],
                            ),
                        ],
                    ),
                    # Message row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = message,
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        wait_for_child = True,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 57)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.20,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.85,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 25)],
                            ),
                        ],
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

    icon_options = [
        schema.Option(
            display = "Check",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAb0lEQVQYlYXOsQnCUBAG4C8khQMIGccJsoCNSFrLLCPWlklhJ7hDLDNIOovY
XOAhD3PNcT8fP8f2XDFtoQ4LHv/QJdBtDWoUP6gNdE/DD8bkPgYaUlRixgn7aO7xRJP7
5xwtC145UMZ+Y4cKhxz8Al5ZEuTs2wZwAAAAAElFTkSuQmCC
""",
        ),
        schema.Option(
            display = "Clock",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAo0lEQVQYlW3QOQpCQRAE0Ic3cDmA4BX0AF7FTL5LoFfwJG6hNzAVTAyEL5gY
aeYBDFwCe/DzsaGha6qmpqf4VR85DtE5MqVa4oUpOmhjgidWSZThjXrgORYx14IbwB3j
gvseuwIehsat4AZHbAu4gWulvCw26MaO8EjEHaOSeIZzzL30dPpM7Y97NbhhOlj5RjFB
C03fXJ9Yl29nOOESfRKxwAds1CbJl+J/zQAAAABJRU5ErkJggg==
""",
        ),
        schema.Option(
            display = "Do Not Enter",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAh0lEQVQYlX3QOw7CQAyE4S8SFyCUlHApaioINAn3oQJulJRQQBluwKPAUdCK
MNLfjMdrr+m1Qo1LUGMt0QFP7DAPKjxw7EIFXpik3cijtoE2XhpSiXuGG6ZYYJmE9rHW
dfRlZsGg2lj83+iW/jP5j9A4atvOOPqcosIsKMM7pd0FGpyDRpwF3ljQIMhNRxrbAAAA
AElFTkSuQmCC
""",
        ),
        schema.Option(
            display = "Exclamation",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAC5J
REFUKFNjZICA/1AaF8XIiKQQxkZXDDIEq0KY6SiGYDNxABVS3zMETcQX5owAts8XC1By
gSIAAAAASUVORK5CYII=
""",
        ),
        schema.Option(
            display = "Heart",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAABGdBTUEAALGPC/xhBQAA
ACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAhGVYSWZN
TQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEAAABSASgAAwAA
AAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAEgAAAABAAAASAAAAAEAA6ABAAMAAAABAAEA
AKACAAQAAAABAAAACqADAAQAAAABAAAACgAAAADIQtX2AAAACXBIWXMAAAsTAAALEwEA
mpwYAAACyGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4
PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRm
OlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5
bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAg
ICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIK
ICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEu
MC8iPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjwvdGlmZjpZUmVzb2x1dGlv
bj4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9u
VW5pdD4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzI8L3RpZmY6WFJlc29sdXRp
b24+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+
CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj41MTwvZXhpZjpQaXhlbFhEaW1l
bnNpb24+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+MTwvZXhpZjpDb2xvclNwYWNl
PgogICAgICAgICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+NTE8L2V4aWY6UGl4ZWxZRGlt
ZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6
eG1wbWV0YT4KeEYU7AAAAJ9JREFUGBldjssRAVEURK8aNrJACBZSIAZlP4koSZEBUbCx
svWnz3u3y5Su6uk75/X7NFHVU0zloXypKCbKsXyWP7CRfMifq3Ijr+Vbsr2STuwSvDLZ
bT9z3nLlWwY0OcMQZa/3AaeE90yfRpodNceqU3j8zdzGBjpFrb4+iXJ3A2tFvA0tZZed
MOROlMcKzGWXFjSkQY3f12AmhJFZfAG1+zmHXh4LcAAAAABJRU5ErkJggg==
""",
        ),
        schema.Option(
            display = "House",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
        ),
        schema.Option(
            display = "Lightning",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRl
WElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEo
AAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAAAKAAAAAQAAAAoAAAABAAOgAQADAAAA
AQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAN/DoBQAAAAlwSFlzAAABigAA
AYoBM5cwWAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1s
bnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAg
PHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJk
Zi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIK
ICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEu
MC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9u
PgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0
YT4KGV7hBwAAAKxJREFUGBlVkDsSAUEURdunkAsE1iGTWAKpJUjYg4XMSowdyAViVQQS
gRJwTtebqZ5Xdeb9bk1335S6MYp2Qj5BHX0/crIYRrMg3+AHx5jl3SAa0w4UyBOmYJSa
VDFQ8I18ILehcg5XWLbTlHrUb1jBFi6ePYYzvGAGa/DPGzDu8MlV8dlTl8dXxa69qBd/
hFCxD2siP6axRSsUaI0WGe46HjqsQZM122jMz80fX+ggM6LWU28AAAAASUVORK5CYII=
""",
        ),
        schema.Option(
            display = "Music",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIRl
WElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEo
AAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAA
AQABAACgAgAEAAAAAQAAAAqgAwAEAAAAAQAAAAoAAAAAyELV9gAAAAlwSFlzAAALEwAA
CxMBAJqcGAAAAVlpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1s
bnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDYuMC4wIj4KICAg
PHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJk
Zi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIK
ICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEu
MC8iPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9u
PgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0
YT4KGV7hBwAAALVJREFUGBl1z60KAlEQhuFZUcRkFPEmxKyCoMHofZi8A6PJSzAJRpuw
CHsFJoPJIggGMdiEFX0/ObOc4gfPzuycYX8S+582R0NM0NBaogupYIQljnjjE7EyN8oM
8YH3d+a5lvyJdXrlhRMybNDE1p9Gb1Xc0MUZno4aLZbCRPUKLekt0scYRWp0KxyKidmc
3r9T1RbIw3CvQciO6osPzfxGNdMgpEVdI0VPsymeuGAAJf7J3+ALKM4qUdgEl/cAAAAA
SUVORK5CYII=
""",
        ),
        schema.Option(
            display = "Plane",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAALCAYAAABGbhwYAAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAvElEQVQYlWXQMUoDARCF4c/NWiaNKASRgI02WwRM2MLCYg/gAWz1FoqV18gB
UlhYZo+QHEDcckUsE7CNFs7Csjsw8M+8x/AY+lXjs7scdOYXJPhGhrIR0o4xwyv2uG0L
Scd4GKZ9cK9GWOEXpxgHl6FJcB/hP3AQ/BX8HvMDbPGEGywxjV7G7hHbFD+4wwQFFpGx
wA7X4ZFHzhnWOMExNpiHlg/8PxiecYQhrnCOM7yhbr+niuuXuAiuGvEP/lMlte6HL6QA
AAAASUVORK5CYII=
""",
        ),
        schema.Option(
            display = "Question",
            value = """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAt0lEQVQYlV3QP0pDYRAE8B9ptHiFghYBOw8gXsAD2EggRcADhPhio0fwBF4g
jeRPn2skpIiaImCnlXYpI7GZh+EtLDvLzH7MN/xXD+/p18xSrYb4RRtNnKGFLSaV6A47
HOMKH1jjAkW4Pnyjm6MFnvEUAdzgB75wUrPyEmGR/bMRsNsTDXCNc2xwCg0c4HZP2MQ0
XqGDQ4mg+gws8RZ8FO6+emWUeB5xmX5IPOOafyVWmGMW3K/IP3NkKS2ii0XRAAAAAElF
TkSuQmCC
""",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Enter the name you want to display.",
                icon = "user",
            ),
            schema.Text(
                id = "status",
                name = "Status",
                desc = "Enter a custom status.",
                icon = "font",
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Select a custom status color.",
                icon = "palette",
                default = color_options[1].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "icon",
                name = "Icon",
                desc = "Select a custom status icon.",
                icon = "icons",
                default = icon_options[6].value,
                options = icon_options,
            ),
            schema.Text(
                id = "message",
                name = "Message",
                desc = "Enter a custom status message.",
                icon = "font",
            ),
            schema.Toggle(
                id = "animation",
                name = "Show Animations",
                desc = "Turn on entry and exit animations.",
                icon = "arrowsRotate",
                default = False,
            ),
        ],
    )

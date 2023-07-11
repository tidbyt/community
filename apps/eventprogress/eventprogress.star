"""
Applet: Event Progress
Summary: Show the progress of an event
Description: Show the progress of an event by showing which segment is currently active and how long is left for each.
Author: Mike Toscano
"""

load("animation.star", "animation")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    active = {
        "1": config.bool("active1", False),
        "2": config.bool("active2", False),
        "3": config.bool("active3", False),
        "4": config.bool("active4", False),
        "5": config.bool("active5", False),
    }
    rows = [
        render.Row(
            expanded = True,  # Use as much horizontal space as possible
            main_align = "space_around",  # Controls horizontal alignment
            cross_align = "start",  # Controls vertical alignment
            children = [
                render.Box(width = 1, height = 9, color = "#000"),
                render.Text(content = config.str("title") or "", font = "tom-thumb"),
                render.Box(width = 1, height = 9, color = "#000"),
            ],
        ),
        render.Row(
            expanded = True,  # Use as much horizontal space as possible
            main_align = "space_around",  # Controls horizontal alignment
            cross_align = "center",  # Controls vertical alignment
            children = [
                render.Box(width = 1, height = 9, color = "#000"),
                render.Text(content = config.str("segment" + getHighestActiveSegment(active)) or "", font = "tom-thumb", color = "B0B0B1"),
                render.Box(width = 1, height = 9, color = "#000"),
            ],
        ),
        squares(int(config.str("numSegments", "1")), active, config.str("color", "#fff"), config.str("activeColor", "#000")),
    ]

    if int(getHighestActiveSegment(active)) > 0:
        rows.append(
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_around",  # Controls horizontal alignment
                cross_align = "end",  # Controls vertical alignment
                children = [
                    # render.Box(width=1, height=5, color="#000"),
                    animation.Transformation(
                        child = render.Box(width = 1, height = 5, color = config.str("progressColor", "#fff")),
                        duration = int(config.str("progressBarFrames", "690")),
                        delay = 0,
                        direction = "normal",
                        fill_mode = "forwards",
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Scale(0, 1)],
                                curve = "linear",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Scale(128, 1)],
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        rows.append(
            render.Box(width = 1, height = 5, color = "#000"),
        )

    return render.Root(
        show_full_animation = True,
        delay = 90,
        child = render.Box(
            child = render.Column(
                main_align = "end",
                # expanded = True,
                children = rows,
            ),
        ),
    )

def getHighestActiveSegment(active):
    segment = "0"
    for i in range(len(active)):
        if active[str(i + 1)]:
            segment = str(i + 1)

    return segment

def squares(numSegments, active, color, activeColor):
    squares = []
    pixelsTakenByBoxes = numSegments * (12 - numSegments)
    horizontalPixelsLeftToFill = 64 - pixelsTakenByBoxes
    widthPerLine = int(horizontalPixelsLeftToFill / numSegments / 2)

    # squares.append(
    #     render.Box(width=1, height=11, color="#000"),
    # )
    for i in range(numSegments):
        squares.append(
            render.Box(
                width = widthPerLine,
                height = 1,
                color = color,
            ),
        )
        if active[str(i + 1)]:
            squares.append(
                render.Box(
                    width = 12 - numSegments,
                    height = 12 - numSegments,
                    color = color,
                    child = render.Box(
                        width = 10 - numSegments,
                        height = 10 - numSegments,
                        color = activeColor,
                    ),
                ),
            )
        else:
            squares.append(
                render.Box(
                    width = 12 - numSegments,
                    height = 12 - numSegments,
                    color = color,
                ),
            )
    squares.append(
        render.Box(
            width = widthPerLine,
            height = 1,
            color = color,
        ),
    )
    squares.append(
        render.Box(width = 1, height = 11, color = "#000"),
    )
    return render.Row(
        expanded = True,  # Use as much horizontal space as possible
        main_align = "space_around",  # Controls horizontal alignment
        cross_align = "center",  # Controls vertical alignment
        children = squares,
    )

def more_options(numSegments):
    additionalOptions = []
    for i in range(int(numSegments)):
        additionalOptions.append(
            schema.Text(
                id = "segment" + str(i + 1),
                name = "Segment " + str(i + 1),
                desc = "Name of segment #" + str(i + 1),
                icon = "gear",
                default = "Edit settings",
            ),
        )

    for i in range(int(numSegments)):
        additionalOptions.append(
            schema.Toggle(
                id = "active" + str(i + 1),
                name = "Active " + str(i + 1),
                desc = "Toggle segment " + str(i + 1) + " active",
                icon = "check",
                default = False if i > 0 else True,
            ),
        )

    return additionalOptions

options = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title of the event",
                icon = "addressCard",
                default = "How to start:",
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Color of the segments",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Color(
                id = "activeColor",
                name = "Active Color",
                desc = "Color of the active segments",
                icon = "brush",
                default = "#FBFF7A",
            ),
            schema.Color(
                id = "progressColor",
                name = "Progress Bar Color",
                desc = "Color of the progress bar",
                icon = "brush",
                default = "#EEF485",
            ),
            schema.Text(
                id = "progressBarFrames",
                name = "Progress Bar Timing",
                desc = "Number of frames for the progress bar to reach 100%",
                icon = "clock",
                default = "690",
            ),
            schema.Dropdown(
                id = "numSegments",
                name = "Segments",
                desc = "Number of segments to display",
                icon = "gear",
                default = options[3].value,
                options = options,
            ),
            schema.Generated(
                id = "generated",
                source = "numSegments",
                handler = more_options,
            ),
        ],
    )

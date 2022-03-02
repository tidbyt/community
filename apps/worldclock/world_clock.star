"""
Applet: World Clock
Summary: Multi timezone clock
Description: Displays the time in up to three different locations.
Author: Elliot Bentley
"""

load("render.star", "render")
load("time.star", "time")
load("schema.star", "schema")

number_font = "tom-thumb"
font = "tom-thumb"

def main(config):
    if (config.get("location_1")):
        locations = [
            config.get("location_1"),
            config.get("location_2"),
            config.get("location_3"),
        ]
    else:
        locations = [
            {"timezone": "America/New_York", "locality": "New York"},
            {"timezone": "Europe/London", "locality": "London"},
            {"timezone": "America/Chicago", "locality": "Arkansas"},
        ]

    horizonal_rule = render.Box(
        height = 1,
        color = "#555",
    )

    rows = []

    i = 0
    for location in locations:
        i += 1

        timezone = location["timezone"]
        locality = config.get("location_%s" % i, location["locality"])

        now = time.now().in_location(timezone)

        row = render.Row(
            main_align = "start",
            children = [
                render.Box(
                    child = render.Padding(
                        pad = (0, 1, 0, 1),
                        child = render.Row(
                            children = [
                                render.Text(
                                    content = now.format("15"),
                                    font = number_font,
                                ),
                                render.Box(
                                    width = 2,
                                    child = render.Animation(
                                        children = [
                                            render.Text(
                                                content = ":",
                                                font = "CG-pixel-3x5-mono",
                                                color = "#777",
                                                offset = 0,
                                            ),
                                            render.Text(
                                                content = " ",
                                                font = "CG-pixel-3x5-mono",
                                            ),
                                        ],
                                    ),
                                ),
                                render.Text(
                                    content = now.format("04"),
                                    font = number_font,
                                ),
                            ],
                        ),
                    ),
                    width = 23,
                    height = 7,
                ),
                render.Box(
                    height = 7,
                    width = 42,
                    child = render.Marquee(
                        width = 42,
                        child = render.Text(
                            content = locality,
                            font = font,
                            color = "#bbb",
                            offset = -1,
                        ),
                    ),
                ),
            ],
        )
        rows.append(row)
        if (i < len(locations)):
            rows.append(horizonal_rule)

    return render.Root(
        delay = 500,
        child = render.Column(
            children = rows,
            main_align = "space_around",
            expanded = True,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location_1",
                name = "Location 1",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Text(
                id = "location_1_label",
                name = "Location 1 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Location(
                id = "location_2",
                name = "Location 2",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Text(
                id = "location_2_label",
                name = "Location 2 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
            schema.Location(
                id = "location_3",
                name = "Location 3",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Text(
                id = "location_3_label",
                name = "Location 3 label",
                desc = "Custom label (optional)",
                icon = "tag",
                default = "",
            ),
        ],
    )

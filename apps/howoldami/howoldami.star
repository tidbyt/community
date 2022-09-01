"""
Applet: How Old Am I
Summary: Calculates age
Description: Calculates age based on given date and time
Author: mabroadfo1027
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")

DEFAULT_BIRTH_DATE_TIME = "2001-01-01T12:00:00Z"
DEFAULT_TIME_ZONE = "US/Central"

def main(config):
    font = "CG-pixel-3x5-mono"

    birthdate = config.get("birthdate", DEFAULT_BIRTH_DATE_TIME)
    tz = config.get("$tz", DEFAULT_TIME_ZONE)

    sd = time.parse_time(birthdate).in_location(tz)

    elapsedDelta = time.now().in_location(tz) - sd

    seconds = elapsedDelta.seconds
    minutes = seconds / 60
    hours = minutes / 60
    days = hours / 24
    years = days / 365

    secondList = []
    minuteList = []
    hourList = []
    # Render 30 seconds

    minuteRolling = float(minutes)
    hourRolling = float(hours)
    for i in range(0, 30):
        secRolling = float(seconds + i)

        if secRolling % 60 == 0:
            minuteRolling += 1
            if minuteRolling % 60 == 0:
                hourRolling += 1

        secondList.append(render.Text("%d" % secRolling, font = font, color = "#ff0000"))
        minuteList.append(render.Text("%d" % minuteRolling, font = font, color = "#f2c57c"))
        hourList.append(render.Text("%d" % hourRolling, font = font, color = "#55ef67"))

    return render.Root(
        delay = 1000,
        child = render.Box(
            render.Column(
                main_align = "start",
                expanded = True,
                children = [
                    render.Row(cross_align = "center", expanded = True, main_align = "space_around", children = [render.Text("How Old Am I?")]),
                    render.Padding(
                        child = render.Row(
                            main_align = "space_between",
                            expanded = True,
                            children = [
                                render.Text("Secs:", font = font, color = "#ff0000"),
                                render.Animation(
                                    children = secondList,
                                ),
                            ],
                        ),
                        pad = (0, 0, 0, 1),
                    ),
                    render.Padding(
                        child = render.Row(
                            main_align = "space_between",
                            expanded = True,
                            children = [
                                render.Text("Mins:", font = font, color = "#f2c57c"),
                                render.Animation(
                                    children = minuteList,
                                ),
                            ],
                        ),
                        pad = (0, 0, 0, 1),
                    ),
                    render.Padding(
                        child = render.Row(
                            main_align = "space_between",
                            expanded = True,
                            children = [
                                render.Text("Hours:", font = font, color = "#55ef67"),
                                render.Animation(
                                    children = hourList,
                                ),
                            ],
                        ),
                        pad = (0, 0, 0, 1),
                    ),
                    render.Padding(
                        child = render.Row(
                            main_align = "space_between",
                            expanded = True,
                            children = [
                                render.Text("Days:", font = font, color = "#00a9aa"),
                                render.Text("%d" % float(days), font = font, color = "#00a9aa"),
                            ],
                        ),
                        pad = (0, 0, 0, 1),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "birthdate",
                name = "Birthdate",
                desc = "Birthdate/time",
                icon = "calendar",
            ),
        ],
    )

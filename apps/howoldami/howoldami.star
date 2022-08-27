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

DEFAULT_BIRTH_DATE = "2000-01-01"
DEFAULT_BIRTH_TIME = "13:00:00"

DEFAULT_TIME_ZONE = "US/Central"

def main(config):
    font = "CG-pixel-3x5-mono"

    startDate = config.str("birthdate", DEFAULT_BIRTH_DATE)
    startTime = config.str("birthtime", DEFAULT_BIRTH_TIME)
    startMS = "00"
    startDateTime = "%sT%s.%sZ" % (startDate, startTime, startMS)
    sd = time.parse_time(startDateTime)

    elapsedDelta = time.now().in_location(config.str("tz", DEFAULT_TIME_ZONE)) - sd

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
    options = [
        schema.Option(display = "US/Central", value = "US/Central"),
        schema.Option(display = "US/Eastern", value = "US/Eastern"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "birthdate",
                name = "Birthdate",
                desc = "Birthdate (format: 2020-01-01)",
                icon = "user",
            ),
            schema.Text(
                id = "birthtime",
                name = "Birthtime",
                desc = "Birthtime (format: 13:00:00)",
                icon = "user",
            ),
            schema.Dropdown(
                id = "tz",
                name = "TimeZone",
                desc = "Enter timezone",
                icon = "user",
                default = options[0].value,
                options = options,
            ),
        ],
    )

"""
Applet: Baby Age
Summary: Baby Age
Description: Simple app to display a baby's age
Author: helmc2
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_BIRTH_DATE_TIME = "2022-01-01T00:00:00Z"
DEFAULT_BABY_NAME = "Baby"
DEFAULT_TIMEZONE = "America/Chicago"

def main(config):
    birthdate = config.get("birthdate", DEFAULT_BIRTH_DATE_TIME)

    baby = config.get("name", DEFAULT_BABY_NAME)
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    current_time = time.now().in_location(timezone)
    birth_time = time.parse_time(birthdate).in_location(timezone)

    difference = current_time - birth_time

    # calculate the number of days
    days = math.floor(difference.hours / 24.0)

    # calculate the number of weeks
    weeks = math.floor(days / 7.0)

    # calculate the number of months
    months = current_time.month - birth_time.month
    months += (current_time.year - birth_time.year) * 12

    # only add the last month if its actually been a whole month
    if (current_time.day < birth_time.day and months > 0):
        months -= 1

    # Decide if days or weeks or months to display
    display_text = str(days) + " days"
    if (days > 30):
        display_text = str(weeks) + " weeks"

    if (weeks > 24):
        display_text = str(months) + " months"

    return render.Root(
        delay = 100,
        child = render.Box(
            render.Padding(
                child = render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render.Row(cross_align = "center", expanded = True, main_align = "space_around", children = [
                            render.Text(
                                content = baby,
                                font = "6x13",
                            ),
                        ]),
                        render.Row(cross_align = "center", expanded = True, main_align = "space_around", children = [
                            render.Text(
                                content = display_text,
                                font = "6x13",
                            ),
                        ]),
                    ],
                ),
                pad = (0, 2, 0, 0),
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
                desc = "Baby's Birthday and Time",
                icon = "calendar",
            ),
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Name of baby to display",
                icon = "heading",
            ),
        ],
    )

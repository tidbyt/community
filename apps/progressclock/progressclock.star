"""
Applet: Progress Clock
Summary: See the time & how much of the day has passed.
Description: See the time displayed & how much of the day has passed, as represented by a graph.
Author: Jeffery Bennett

v1.0 - Initial Tidbyt release
v1.1 - Fixed support for custom timezones
"""

load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

def main(config):
    # Get the timezone from the config, defaulting to America/Chicago
    timezone = config.get("$tz", "America/Chicago")

    # Get the current time in the specified timezone
    now = time.now().in_location(timezone)

    # For creating screenshots
    # mock_time = time.time(hour = 17, minute = 1, second = 1, year = current_time.year, month = current_time.month, day = current_time.day, location = timezone)

    # Calculate the total number of seconds
    elapsed_seconds = now.hour * 3600 + now.minute * 60 + now.second

    # Calculate the total number of seconds in a day
    total_seconds_in_day = 24 * 60 * 60

    # Map the elapsed time to a value between 0 and 1
    time_ratio = elapsed_seconds / total_seconds_in_day

    # Scale the time ratio to the width of the box
    box_width = math.floor(time_ratio * 64)

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = box_width,
                    height = 32,
                    color = "#cc0000",
                ),
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = now.format("3:04 PM"),
                                    font = "tb-8",
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

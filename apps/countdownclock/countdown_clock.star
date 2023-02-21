"""
Applet: Countdown Clock
Summary: Countdown to an event
Description: Display the days, hours, and minutes remaining to a specified event.
Author: CubsAaron
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

colorOpt = [
    schema.Option(
        display = "Red",
        value = "#FF0000",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FFFF00",
    ),
    schema.Option(
        display = "Green",
        value = "#008000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000FF",
    ),
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
]

def main(config):
    timezone = config.get("$tz", "America/Chicago")  # Utilize special timezone variable
    DEFAULT_TIME = time.now().in_location(timezone).format("2006-01-02T15:04:05Z07:00")

    future = time.parse_time(config.str("event_time", DEFAULT_TIME))
    dateDiff = future - time.now().in_location(timezone)
    days = math.floor(dateDiff.hours / 24)
    hours = math.floor(dateDiff.hours - days * 24)
    minutes = math.floor(dateDiff.minutes - (days * 24 * 60 + hours * 60))

    fadeList = []  # The list of the fading text near the bottom, or a static date if the event has passed
    dayString = "IS HERE!"  # The amount of days left, or a static message if the event has passed
    if (time.now() < future):
        # Create the lists that will make the fading text
        dayString = "{} {}".format(str(days), "Day" if days == 1 else "Days")
        fadeList = appendFadeList(fadeList, "{} {}".format(str(hours), "hour" if hours == 1 else "hours"), 30)
        fadeList = appendFadeList(fadeList, "{} {}".format(str(minutes), "minute" if minutes == 1 else "minutes"), 20)
    else:
        # Event date has already passed, so show the date of the event
        fadeList.append(render.Text(future.format("01-02-2006"), font = "CG-pixel-4x5-mono", color = "#888888"))

    # Create event text widget based on text length
    eventText = config.str("event", "Event")
    if len(eventText) < 14:
        eventWidget = render.Text(content = eventText, font = "5x8", color = config.str("eventColor", colorOpt[3].value))
    else:
        eventWidget = render.Marquee(
            child = render.Text(content = eventText, font = "5x8", color = config.str("eventColor", colorOpt[3].value)),
            width = 64,
        )

    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                eventWidget,
                render.Text(content = dayString, font = "6x13"),
                render.Box(width = 64, height = 1),
                render.Animation(
                    children = fadeList,
                ),
            ],
        ),
    )

# Create an fading animation
def appendFadeList(fadeList, text, cycles):
    for x in range(0, 10, 2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        fadeList.append(render.Text(text, font = "CG-pixel-4x5-mono", color = c))
    for x in range(cycles):
        fadeList.append(render.Text(text, font = "CG-pixel-4x5-mono", color = "#888888"))
    for x in range(8, 0, -2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        fadeList.append(render.Text(text, font = "CG-pixel-4x5-mono", color = c))
    return fadeList

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "event",
                name = "Event",
                desc = "The event text to display.",
                icon = "gear",
            ),
            schema.DateTime(
                id = "event_time",
                name = "Event Time",
                desc = "The time of the event.",
                icon = "gear",
            ),
            schema.Dropdown(
                id = "eventColor",
                name = "Text Color",
                desc = "The color of the event text.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
        ],
    )

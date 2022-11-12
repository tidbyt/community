"""
Applet: Countup Clock
Summary: Time since a event
Description: Display the days, hours, and minutes since a specified event.
Author: jvivona
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")

DEFAULT_TIMEZONE = "America/New_York"

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
    timezone = config.get("$tz", DEFAULT_TIMEZONE)  # Utilize special timezone variable

    displayhours = config.bool("display_hours", True)
    displayminutes = config.bool("display_minutes", True) if displayhours else False

    current_time = time.now().in_location(timezone)
    
    origin_time = time.parse_time(config.str("event_time", current_time.format("2006-01-02T15:04:05Z07:00")))
    print (current_time)
    print (origin_time)
    datediff = current_time - origin_time

    days = math.floor(datediff.hours // 24)
    hours = math.floor(datediff.hours - days * 24)
    minutes = math.floor(datediff.minutes - (days * 24 * 60 + hours * 60))
    event_title = config.str("event", "")
    daystring = "{} {}".format(str(days), "Day" if days == 1 else "Days")

    eventtitlewidget = render.Marquee(
        child = render.Text(content = event_title, font = "5x8", color = config.str("event_color", colorOpt[3].value)),
        width = 64,
        align = "center",
    )
    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                eventtitlewidget,
                render.Text(content = daystring, font = "6x13"),
                #render.Box(width = 64, height = 1),
                #render.Animation(
                #    children = fadeList,
                #),
            ],
        ),
    )

def get_title(eventtitle, displayhours, displayminutes):
    return


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "event",
                name = "Title",
                desc = "The title text to display.",
                icon = "heading",
            ),
            schema.DateTime(
                id = "event_time",
                name = "Start Date",
                desc = "The origin date and time of the event.",
                icon = "clock",
            ),
            schema.Dropdown(
                id = "event_color",
                name = "Text Color",
                desc = "The color of the title text.",
                icon = "brush",
                default = colorOpt[3].value,
                options = colorOpt,
            ),
            schema.Toggle(
                id = "display_hours",
                name = "Display hours",
                desc = "Display hours in countup?  If disabled, display minutes is also disabled.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "display_minutes",
                name = "Display minutes",
                desc = "Display minutes in countup?",
                icon = "clock",
                default = False,
            ),

        ],
    )

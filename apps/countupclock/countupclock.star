"""
Applet: Countup Clock
Summary: Time since a event
Description: Display the days, hours, and minutes since a specified event.
Author: jvivona
borrowed Fade In and Out technique and the math calculations from @CubsAaron countdown_clock
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")

DEFAULT_TIMEZONE = "America/New_York"
TITLE_FONT = "5x8"
DAYS_FONT = "6x13"
HOURS_FONT = "tb-8"
HOURS_COLOR = "#888888"

coloropt = [
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
    schema.Option(
        display = "Pink",
        value = "#FC46AA",
    ),
]

def main(config):
    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = get_render_children(config),
        ),
    )

def get_render_children(config):
    render_children = []
    displayhours = config.bool("display_hours", True)
    displayminutes = config.bool("display_minutes", True) if displayhours else False
    titlebelow = config.bool("title_below", False)
    current_time = time.now().in_location(config.get("$tz", DEFAULT_TIMEZONE))

    origin_time = time.parse_time(config.str("event_time", current_time.format("2006-01-02T15:04:05Z07:00")))
    datediff = current_time - origin_time

    # we are always going to display days - so we can calc in main - no horsepower lost
    days = math.floor(datediff.hours // 24)
    daystring = "{} {}".format(str(days), "Day" if days == 1 else "Days")

    render_children.append(render.Text(content = daystring, font = DAYS_FONT))

    if displayhours:
        render_children.append(get_hours_minutes(datediff, days, displayminutes))

    title_insert_index = len(render_children) if titlebelow else 0

    render_children.insert(title_insert_index, get_title(config.str("event", ""), config.str("event_color", coloropt[3].value), displayhours))

    return render_children

def get_title(eventtitle, titlecolor, displayhours):
    if displayhours:
        # since we are displaying hours - title needs to be marquee - text less than width will center on screen
        return render.Marquee(
            child = render.Text(content = eventtitle, font = TITLE_FONT, color = titlecolor),
            width = 64,
            align = "center",
        )
    else:
        # we can't put in any more than 2 lines of 5x8 - so force widget to be only 2 lines high and hide rest
        textheight = 8 if len(eventtitle) < 14 else 16
        return render.WrappedText(
            content = eventtitle,
            color = titlecolor,
            align = "center",
            font = TITLE_FONT,
            width = 64,
            height = textheight,
        )

def get_hours_minutes(datediff, days, displayminutes):
    # at a minimum we are displaying hours. we already calculated days in the caller - so just pass it in
    # if we are showing both hours and minutes - we need to the fade in and out, otherwise just show hours static
    hours = math.floor(datediff.hours - days * 24)
    hours_text = "{} {}".format(str(hours), "Hour" if hours == 1 else "Hours")

    if displayminutes:
        minutes = math.floor(datediff.minutes - (days * 24 * 60 + hours * 60))
        return render.Animation(
            children =
                createfadelist(hours_text, 30) +
                createfadelist("{} {}".format(str(minutes), "Minute" if minutes == 1 else "Minutes"), 30),
        )
    else:
        # just hours so put a single static line here
        return render.Row(
            children = [
                render.Text(hours_text, font = HOURS_FONT, color = HOURS_COLOR),
            ],
            main_align = "center",
            expanded = True,
        )

def createfadelist(text, cycles):
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    for x in range(0, 10, 2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = c))
    for x in range(cycles):
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = HOURS_COLOR))
    for x in range(8, 0, -2):
        c = "#" + str(x) + str(x) + str(x) + str(x) + str(x) + str(x)
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = c))
    return cycle_list

def show_minutes_option(display_hours):
    # need to do the string comparison here to make it consistent instead of converting to bool - its a whole thing
    if display_hours == "true":
        return [
            schema.Toggle(
                id = "display_minutes",
                name = "Display minutes",
                desc = "Display minutes in countup?",
                icon = "clock",
                default = False,
            ),
        ]
    else:
        return []

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
            schema.Toggle(
                id = "title_below",
                name = "Title at bottom?",
                desc = "Display title below the elapsed time?",
                icon = "arrowsUpDown",
                default = False,
            ),
            schema.DateTime(
                id = "event_time",
                name = "Start Date",
                desc = "The start date and time of the event.",
                icon = "clock",
            ),
            schema.Dropdown(
                id = "event_color",
                name = "Text Color",
                desc = "The color of the title text.",
                icon = "brush",
                default = coloropt[3].value,
                options = coloropt,
            ),
            schema.Toggle(
                id = "display_hours",
                name = "Display hours",
                desc = "Display hours in countup?  If disabled, display minutes is also disabled.",
                icon = "clock",
                default = True,
            ),
            schema.Generated(
                id = "generated",
                source = "display_hours",
                handler = show_minutes_option,
            ),
        ],
    )

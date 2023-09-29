"""
Applet: Cost Calculator
Summary: Show elapsed time and cost
Description: Show elapsed time and calculate a cost based on a given rate.
Author: rs7q5
"""
#cost_calculator.star
#Created 20230403 RIS
#Last Modified 20230510 RIS

load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_TITLE = "Title"
DEFAULT_RATE = "0.00"
DEFAULT_MULTIPLIER = "1.00"

DEFAULT_FONT = "CG-pixel-3x5-mono"
DEFAULT_TITLE_COLOR = "#008000"

def main(config):
    duration = get_duration(config)

    #calcuate cost
    rate = float(config.str("rate", DEFAULT_RATE))  #duration is per hour
    multiplier = float(config.str("multiplier", DEFAULT_MULTIPLIER))

    rate_str = "$" + humanize.float("#.##", rate * multiplier)

    if multiplier != 1:
        rate_str += " (x%s)" % humanize.float("#.##", multiplier)  #add multiplier to text

    cost = duration["value"] * rate * multiplier
    cost_str = "$" + humanize.float("#.##", cost)

    #create frame
    title_txt = render.Text(config.str("title", DEFAULT_TITLE), font = "tb-8", color = config.get("title_color", DEFAULT_TITLE_COLOR))

    #create labels and values
    label_vec = []
    for label in ["Time:", "Rate:", "Total:"]:
        label_vec.append(render.Text(label, font = DEFAULT_FONT))

    value_vec = []
    for value in [duration["text"], rate_str, cost_str]:
        value_vec.append(render.Marquee(width = 40, align = "end", child = render.Text(value, font = DEFAULT_FONT)))

    final_frame = render.Column(
        main_align = "space_between",
        expanded = True,
        children = [
            render.Marquee(title_txt, width = 64),
            render.Row(
                main_align = "space_between",
                expanded = True,
                children = [
                    render.Column(expanded = True, main_align = "space_between", children = label_vec),
                    render.Column(expanded = True, main_align = "space_between", cross_align = "end", children = value_vec),
                ],
            ),
        ],
    )
    return render.Root(
        delay = 100,
        show_full_animation = True,
        max_age = 120,
        child = final_frame,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "start_time",
                name = "Start Date",
                desc = "The start date and time.",
                icon = "clock",
            ),
            schema.Text(
                id = "rate",
                name = "Hourly rate",
                desc = "The rate to use for calculating the cost.",
                icon = "dollarSign",
                default = DEFAULT_RATE,
            ),
            schema.Text(
                id = "multiplier",
                name = "Rate multiplier",
                desc = "Add a multiplier to the rate.",
                icon = "xmark",
                default = DEFAULT_MULTIPLIER,
            ),
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title text.",
                icon = "heading",
                default = DEFAULT_TITLE,
            ),
            schema.Color(
                id = "title_color",
                name = "Title Color",
                desc = "The color of the title text.",
                icon = "brush",
                default = DEFAULT_TITLE_COLOR,
            ),
        ],
    )

############
#functions
def get_duration(config):
    #calculate duration
    current_time = time.now().in_location(config.get("$tz", DEFAULT_TIMEZONE))
    start_time = time.parse_time(config.str("start_time", current_time.format("2006-01-02T15:04:05Z07:00")))

    #get duration hours and minutes
    duration = current_time - start_time
    hours = math.floor(duration.hours)
    minutes = math.floor(duration.minutes - hours * 60)

    #format duration text
    if minutes < 10:
        duration_str = "%d:0%d" % (hours, minutes)
    else:
        duration_str = "%d:%d" % (hours, minutes)

    return {
        "value": (hours + minutes / 60),  #don't use just duration.hours to make math consistent
        "text": duration_str,
    }

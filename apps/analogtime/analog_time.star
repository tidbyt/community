"""
Applet: Analog Time
Summary: Show time analog style
Description: Shows the time on an analog style clock.
Author: rs7q5 (RIS)
"""

#analog_time.star
#Created 20220204 RIS
#Last Modified 20220224 RIS

load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("math.star", "math")
load("time.star", "time")

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def main(config):
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]

    now = time.now().in_location(timezone)
    now_txt = now.format("3:04")

    hour, minute = [int(x) for x in now_txt.split(":")]  #get integer values of the time

    #get angles
    theta = math.radians(hour * (360 // 12) + 0.5 * minute)  #angle for hour
    theta2 = math.radians(minute * (360 // 60))  #angle for minute

    #misc. settings for building the clock
    clock_r = 16.0  #half the height of the tidbyt
    ax_lims = (-clock_r, clock_r)
    hour_len = 10.0
    minute_len = 14.0

    hour_pt = (hour_len * math.sin(theta), hour_len * math.cos(theta))
    minute_pt = (minute_len * math.sin(theta2), minute_len * math.cos(theta2))

    hand_pts = [
        (hour_len * math.sin(theta), hour_len * math.cos(theta)),
        (0.0, 0.0),
        (minute_len * math.sin(theta2), minute_len * math.cos(theta2)),
    ]

    plot_hands = render.Plot(32, 32, hand_pts, ax_lims, ax_lims, color = "#fff")
    plot_hands2 = render.Padding(plot_hands, pad = (16, 0, 16, 0))

    #used this to see if coloring the hour hand was better
    plot_handsa = render.Plot(32, 32, [(0.0, 0.0), hour_pt], ax_lims, ax_lims, color = "#a00")
    plot_handsb = render.Plot(32, 32, [(0.0, 0.0), minute_pt], ax_lims, ax_lims, color = "#fff")
    plot_handsa2 = render.Padding(plot_handsa, pad = (16, 0, 16, 0))
    plot_handsb2 = render.Padding(plot_handsb, pad = (16, 0, 16, 0))

    #add all the parts together
    if config.bool("display_date"):
        plot_marks = [render.Text(now.format("01/02"), font = "tom-thumb")]  #add text
    else:
        plot_marks = []

    for x in range(0, 350, 30):
        x2 = math.radians(x)
        xpt = clock_r * math.sin(x2)
        ypt = clock_r * math.cos(x2)
        plot_marks_tmp = [(xpt, ypt), (xpt, ypt)]
        plot_marks.append(render.Padding(render.Plot(32, 32, plot_marks_tmp, ax_lims, ax_lims), pad = (16, 0, 16, 0)))

    #add hands
    plot_marks.append(plot_handsb2)
    plot_marks.append(plot_handsa2)
    plot_marks.append(render.Padding(render.Plot(32, 32, [(0.0, 0.0), (0.0, 0.0)], ax_lims, ax_lims, color = "#c8c8fa"), pad = (16, 0, 16, 0)))  #adds a mark over the center point of the hands clock

    return render.Root(
        delay = 100,  #speed up scroll text
        child = render.Stack(children = plot_marks),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
            ),
            schema.Toggle(
                id = "display_date",
                name = "Display Date",
                desc = "Whether to display the date too.",
                icon = "cog",
                default = False,
            ),
        ],
    )

######################################################
#functions
def pad_text(text):
    #format strings so they are all the same length (leads to better scrolling)
    if type(text) == "dict":
        max_len = max([len(x) for x in text.values()])  #length of each string

        #add padding to shorter titles
        for key, val in text.items():
            text_new = val + " " * (max_len - len(val))
            text[key] = text_new
    else:
        max_len = max([len(x) for x in text])  #length of each string

        #add padding to shorter titles
        for i, x in enumerate(text):
            text[i] = x + " " * (max_len - len(x))
    return text

######################################################

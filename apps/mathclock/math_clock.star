"""
Applet: Math Clock
Summary: Do math to find the time
Description: A clock that displays the current time using math.
Author: rs7q5
"""
#math_clock.star
#Created 20230129 RIS
#Last Modified 20230210 RIS

load("animation.star", "animation")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
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

FONT = "CG-pixel-4x5-mono"

def main(config):
    #get current time
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    now = time.now().in_location(timezone)

    #get information based on 12/24 hour time format
    hour = now.format("15") if config.bool("24hour_format") else now.format("3")
    ampm_txt = "" if config.bool("24hour_format") else now.format("PM")
    time_txt = now.format("15:04") if config.bool("24hour_format") else now.format("3:04 PM")

    #get equations
    hour_eqn = make_equation(int(hour))
    minute_eqn = make_equation(now.minute)

    #get the final time display based on options
    time_display = display_time(time_txt, config.str("display_opt", "visible"))

    return render.Root(
        delay = 500,
        max_age = 120,
        child = render.Column(
            main_align = "space_between",
            expanded = True,
            children = [
                render.Row(
                    children = [
                        render.Text(" hr:", font = "tom-thumb"),
                        render.Text(hour_eqn, font = FONT),
                    ],
                ),
                render.Row(
                    children = [
                        render.Text("min:", font = "tom-thumb"),
                        render.Text(minute_eqn, font = FONT),
                    ],
                ),
                render.Text(ampm_txt, font = FONT),
                render.Box(width = 64, height = 7, child = time_display),
            ],
        ),
    )

def get_schema():
    display_options = [
        schema.Option(
            display = "Visible (default)",
            value = "visible",
        ),
        schema.Option(
            display = "Hide",
            value = "hide",
        ),
        schema.Option(
            display = "Delay",
            value = "delay",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "24hour_format",
                name = "24 hour format?",
                desc = "Enable for 24-hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "display_opt",
                name = "Options for displaying the time.",
                desc = "",
                icon = "eyeSlash",
                default = display_options[0].value,
                options = display_options,
            ),
        ],
    )

############
#functions
def display_time(time_txt, display_opt):
    time_animation = render.Animation(
        children = [
            render.WrappedText(width = 64, align = "right", content = time_txt, font = FONT),
            render.WrappedText(width = 64, align = "right", content = time_txt.replace(":", " "), font = FONT),
        ],
    )
    if display_opt == "hide":
        return render.Box(width = 64, height = 7)
    elif display_opt == "delay":
        return animation.Transformation(
            child = time_animation,
            duration = 100,
            delay = 10,
            origin = animation.Origin(0.5, 0.5),
            fill_mode = "forwards",
            wait_for_child = True,
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Scale(0, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.01,
                    transforms = [animation.Scale(1, 1)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Scale(1, 1)],
                ),
            ],
        )
    else:
        return time_animation

def make_equation(number):
    # print(random.number(0,2))
    #code to create equations converted from arduino and can be found in this repo: https://github.com/ElliotTheGreek/ArduinoMathClock
    #note in arduino random(max) means a random number between 0 and max-1, while the random module here is min to max (inclusive)

    method = random.number(0, 1)  #0 = addition, 1= subtraction, 2 = multiplication
    r = random.number(0, 8) + 1  #+1 to avoid divide by zero
    methodString = ""
    leftNumber = 0
    if method == 0:
        leftNumber = number + r
    elif method == 1:
        leftNumber = number - r
    elif method == 2:
        leftNumber = number * r

    method2 = random.number(0, 2)  #0 = addition, 1= subtraction, 2 = multiplication
    r2 = random.number(0, 8) + 1  #+1 to avoid divide by zero
    leftSide = ""
    if method2 == 0:
        leftSide = str(leftNumber + r2) + "-" + str(r2)
    elif method2 == 1:
        leftSide = str(leftNumber - r2) + "+" + str(r2)
    elif method2 == 2:
        leftSide = str(leftNumber * r2) + "/" + str(r2)

    if method == 0:
        return leftSide + "-" + str(r)
    elif method == 1:
        return leftSide + "+" + str(r)
    elif method == 2:
        return leftSide + "/" + str(r)

    return methodString

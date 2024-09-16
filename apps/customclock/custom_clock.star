"""
Applet: Custom Clock
Summary: Clock with display options
Description: A clock that can be customized.
Author: rs7q5
"""
#Created 20230414 RIS
#Last modified 20230414 RIS

load("encoding/json.star", "json")
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
DEFAULT_FONT = "6x13"
DEFAULT_COLOR = "fff"

def main(config):
    #get time
    location_info = json.decode(config.get("location", DEFAULT_LOCATION))  #may need locality later, which is why do this in two steps
    timezone = location_info["timezone"]
    now = time.now().in_location(timezone)

    #display settings
    font = config.str("font", DEFAULT_FONT)
    time_color = config.get("time_color", DEFAULT_COLOR)
    location_color = config.get("location_color", DEFAULT_COLOR)

    #adjust clock time
    offset_direction = int(config.str("clock_mode", "0"))
    offset = config.str("offset", "0")

    if offset.isdigit():
        #shows normal time if offset is not an integer
        offset_final = int(offset) * offset_direction
        new_time = time.time(year = now.year, month = now.month, day = now.day, hour = now.hour, minute = now.minute + offset_final, location = timezone)
    else:
        new_time = now

    #format time (10x20 is too big for two lines, so can only do 24 hour format)
    time_text = new_time.format("15:04") if (config.bool("24hour_format", False) or font == "10x20") else new_time.format("3:04 PM")

    ###############################
    #create final frame

    #get blinking text
    if config.bool("blink", True):
        blink_vec = [render.Text(":", font = font, color = time_color)] * 5
        blink_vec.extend([render.Text(":", font = font, color = "#000")] * 5)
        blink_text = render.Animation(blink_vec)
    else:
        blink_text = render.Text(":", font = font, color = time_color)

    hour, minute_ampm = time_text.split(":")  #separate hour and minute/ampm

    #create final
    frame_tmp = render.Row(
        children = [
            render.Text(hour, font = font, color = time_color),  #hour
            blink_text,  #colon
            render.Text(minute_ampm, font = font, color = time_color),  #minute and am/pm
        ],
    )

    #add location
    if config.bool("location_text", False):
        font_tmp = "5x8" if font == "10x20" else font  #shrink location font to fit when time is 10x20 font
        final_frame = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                frame_tmp,
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(location_info["locality"], font = font_tmp, color = location_color),
                ),
            ],
        )
    else:
        final_frame = frame_tmp

    return render.Root(
        delay = 100,  #speed up scroll text
        max_age = 120,
        child = render.Box(width = 64, height = 32, child = final_frame),
    )

def get_schema():
    fonts = []
    for key, value in render.fonts.items():
        if key == "10x20":
            disp_text = "%s (24 hour only and location is in 5x8)" % key
        else:
            disp_text = key
        fonts.append(schema.Option(display = disp_text, value = value))

    clock_modes = [
        schema.Option(display = key, value = value)
        for key, value in {"Actual": "0", "Slow": "-1", "Fast": "1"}.items()
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationArrow",
            ),
            schema.Toggle(
                id = "location_text",
                name = "Display location",
                desc = "Display location.",
                icon = "locationDot",
                default = False,
            ),
            schema.Toggle(
                id = "24hour_format",
                name = "24 hour clock",
                desc = "Enable for 24-hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "clock_mode",
                name = "Clock mode",
                desc = "Choose clock mode.",
                icon = "clock",
                default = clock_modes[0].value,
                options = clock_modes,
            ),
            schema.Text(
                id = "offset",
                name = "Time offset (in minutes)",
                desc = "Offset time by specified amount.",
                icon = "plusMinus",
                default = "0",
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Change the font of the time.",
                icon = "font",
                default = DEFAULT_FONT,
                options = fonts,
            ),
            schema.Color(
                id = "time_color",
                name = "Time color",
                desc = "Change the color of the time.",
                icon = "brush",
                default = "fff",
            ),
            schema.Color(
                id = "location_color",
                name = "Location color",
                desc = "Change the color of the location.",
                icon = "brush",
                default = "fff",
            ),
            schema.Toggle(
                id = "blink",
                name = "Blinking separator",
                desc = "Blink the colon between hours and minutes.",
                icon = "gear",
                default = True,
            ),
        ],
    )

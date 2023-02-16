"""
Applet: Vertical Message
Summary: Display messages vertically
Description: Display a message vertically.
Author: rs7q5
"""

#vertical_message.star
#Created 20220221 RIS
#Last Modified 20230210 RIS

load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

COLOR_LIST = {
    "White": "#fff",
    "Red": "#a00",
    "Green": "#0a0",
    "Blue": "#00a",
    "Orange": "#D2691E",
}

DEFAULT_MSG = "A really long message that just keeps on going and going and going and going and never stops"

def main(config):
    if config.bool("hide_app", False):
        return []

    #get color
    if config.bool("color_logic", False):
        color_opt = config.str("color_select", "#fff")
    else:
        color_opt = config.str("color", "#fff")

    #validate color
    if validate_color(color_opt):
        msg_txt = config.str("msg", DEFAULT_MSG)
    else:
        msg_txt = "Invalid color specified!!!!"
        color_opt = "#fff"

    #set linespacing
    linespacing = config.str("linespacing", "0")
    if linespacing.isdigit():
        linespacing_final = int("-%s" % linespacing) if config.bool("negate_linespacing", False) else int(linespacing)
    else:
        linespacing_final = 0

    scroll_opt = config.str("speed", "100")
    return render.Root(
        delay = int(scroll_opt),  #speed up scroll text
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(
                content = msg_txt,
                width = 64,
                color = color_opt,
                font = config.str("font", "tb-8"),
                linespacing = linespacing_final,
                align = config.str("text_align", "left"),
            ),
            scroll_direction = "vertical",
        ),
    )

def get_schema():
    colors = [
        schema.Option(display = key, value = value)
        for key, value in COLOR_LIST.items()
    ]
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Normal (Default)", value = "100"),
        schema.Option(display = "Fast", value = "30"),
    ]
    fonts = [
        schema.Option(display = key, value = value)
        for key, value in render.fonts.items()
    ]
    align_opt = [
        schema.Option(display = "Left (Default)", value = "left"),
        schema.Option(display = "Center", value = "center"),
        schema.Option(display = "Right", value = "right"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "msg",
                name = "Message",
                desc = "A mesage to display.",
                icon = "gear",
                default = DEFAULT_MSG,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Change the font of the text.",
                icon = "font",
                default = "tb-8",
                options = fonts,
            ),
            schema.Dropdown(
                id = "text_align",
                name = "Text alignment",
                desc = "",
                icon = "gear",
                default = align_opt[0].value,
                options = align_opt,
            ),
            schema.Text(
                id = "linespacing",
                name = "Line Spacing",
                desc = "Adjust line spacing of text (integers only).",
                icon = "gear",
                default = "0",
            ),
            schema.Toggle(
                id = "negate_linespacing",
                name = "Negate line spacing?",
                desc = "",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Change color of text.",
                icon = "brush",
                default = colors[0].value,
                options = colors,
            ),
            schema.Toggle(
                id = "color_logic",
                name = "Use Custom Color?",
                desc = "",
                icon = "brush",
                default = False,
            ),
            schema.Text(
                id = "color_select",
                name = "Custom Color",
                desc = "Enter a color in #rgb, #rrggbb, #rgba, or #rrggbbaa format.",
                icon = "brush",
                default = "#fff",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change speed that text scrolls.",
                icon = "gear",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide message?",
                desc = "",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

def format_text(x, font):
    #formats color and font of text
    text_vec = []
    for i, xtmp in enumerate(x):
        if i % 2 == 0:
            ctmp = "#fff"
        else:
            ctmp = "#ff8c00"
        text_vec.append(render.WrappedText(xtmp, font = font, color = ctmp, linespacing = -1))
    return (text_vec)

def validate_color(x):
    #validates hex color
    #regex from https://stackoverflow.com/questions/1636350/how-to-identify-a-given-string-is-hex-color-format?noredirect=1&lq=1

    match = re.findall("^#[0-9a-fA-F]{8}$|#[0-9a-fA-F]{6}$|#[0-9a-fA-F]{4}$|#[0-9a-fA-F]{3}$", x)
    if len(match) == 1:
        return True
    else:
        return False

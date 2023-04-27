"""
Applet: Vertical Message
Summary: Display messages vertically
Description: Display a message vertically.
Author: rs7q5
"""

#vertical_message.star
#Created 20220221 RIS
#Last Modified 20230323 RIS

load("render.star", "render")
load("schema.star", "schema")

DEFAULT_MSG = "A really long message that just keeps on going and going and going and going and never stops"

def main(config):
    if config.bool("hide_app", False):
        return []

    #get color
    color_opt = config.str("color", "#fff")

    #get message
    msg_txt = config.str("msg", DEFAULT_MSG)

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
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Change color of text.",
                icon = "brush",
                default = "fff",
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

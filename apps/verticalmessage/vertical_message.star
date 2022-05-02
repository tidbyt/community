"""
Applet: Vertical Message
Summary: Display messages vertically
Description: Display a message vertically.
Author: rs7q5 (RIS)
"""

#vertical_message.star
#Created 20220221 RIS
#Last Modified 20220224 RIS

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
    msg_txt = config.str("msg", DEFAULT_MSG)
    color_opt = config.str("color", "#fff")
    scroll_opt = config.str("speed", "100")
    return render.Root(
        delay = int(scroll_opt),  #speed up scroll text
        child = render.Marquee(
            height = 32,
            child = render.WrappedText(content = msg_txt, width = 60, color = color_opt),
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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "msg",
                name = "Message",
                desc = "A mesage to display.",
                icon = "cog",
                default = DEFAULT_MSG,
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Change color of text.",
                icon = "brush",
                default = colors[0].value,
                options = colors,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change speed that text scrolls.",
                icon = "cog",
                default = scroll_speed[1].value,
                options = scroll_speed,
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

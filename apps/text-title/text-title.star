load("render.star", "render")

default_title = "TITLE"
default_font = "6x10"
default_color = "#00f"

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    color = config.get("color", "#ffffff")
    title = config.get("title", default_title)
    titlefont = config.get("titlefont", default_font)
    titlecolor = config.get("titlecolor", default_color)
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText(
                    content = title,
                    font = titlefont,
                    color = titlecolor,
                    align = "center",
                    linespacing = 0,
                ),
                render.Marquee(
                    width = 60,
                    offset_start = 59,
                    child = render.Text(
                        content = content,
                        font = font,
                        color = color,
                    ),
                ),
            ],
        ),
    )

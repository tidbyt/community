load("render.star", "render")

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    color = config.get("color", "#ffffff")
    return render.Root(
        child = render.WrappedText(
            content = content,
            font = font,
            color = color,
        ),
    )

"""
Applet: Random Cats
Summary: Shows pictures of cats
Description: Shows random pictures of cats/gifs of cats.
Author: mrrobot245
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")

def main(config):
    if (config.bool("gifs") == False):
        imgSrc = http.get("https://cataas.com/cat?height=32").body()
    else:
        imgSrc = http.get("https://cataas.com/cat/gif?height=32").body()

    children = []
    children.append(
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Image(
                    src = imgSrc,
                    # width = 65,
                    height = 32,
                ),
            ],
        ),
    )
    return render.Root(
        # delay = 60,
        child = render.Column(
            main_align = "space_between",
            cross_align = "center",
            children = children,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "gifs",
                name = "Animated Gifs",
                desc = "Show Animated Gifs",
                icon = "codeFork",
                default = True,
            ),
        ],
    )

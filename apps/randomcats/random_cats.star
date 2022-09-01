"""
Applet: Random Cats
Summary: Shows pictures of cats
Description: Shows random pictures of cats/gifs of cats from Cats as a Service (cataas.com).
Author: mrrobot245
"""

load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")

def main(config):
    rep_cache = cache.get("randomcats")
    if rep_cache != None:
        imgSrc = rep_cache
    else:
        if (config.bool("gifs") == False):
            imgSrc = http.get("https://cataas.com/cat?height=32").body()
        else:
            imgSrc = http.get("https://cataas.com/cat/gif?height=32").body()
        cache.set("randomcats", imgSrc, ttl_seconds = 20)

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

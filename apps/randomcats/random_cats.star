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
    if config.bool("gifs", True):
        url = "https://cataas.com/cat/gif?height=32"
    else:
        url = "https://cataas.com/cat?height=32"

    imgSrc = get_cached(url)

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

def get_cached(url, ttl_seconds = 20):
    data = cache.get(url)
    if data:
        return data

    res = http.get(url)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))

    data = res.body()
    cache.set(url, data, ttl_seconds = ttl_seconds)

    return data

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

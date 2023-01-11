"""
Applet: BGG Hotness
Summary: BoardGameGeek Hotness
Description: Shows the top items from BoardGameGeek's Board Game Hotness list.
Author: Henry So, Jr.
"""

# Board Game Hotness powered by BoardGameGeek
#
# Copyright (c) 2022 Henry So, Jr.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This app uses the BoardGameGeek XML API 2
# (https://boardgamegeek.com/wiki/page/BGG_XML_API2)
# to show BoardGameGeek's Board Game Hotness list

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

def main():
    now = time.now().unix

    data = cache.get(KEY)
    data = json.decode(data) if data else None

    if not data or (now - data["timestamp"]) > EXPIRY:
        print("Getting " + URL)
        content = http.get(URL)
        if content.status_code == 200:
            content = xpath.loads(content.body())
            content = {
                "timestamp": now,
                "list": [
                    {
                        "name": "%d. %s (%s)" % (
                            rank,
                            content.query(NAME_PATH_FMT % rank) or "{no name}",
                            content.query(YEAR_PATH_FMT % rank) or "????",
                        ),
                        "image_url": content.query(IMAGE_PATH_FMT % rank),
                    }
                    for rank in RANKS
                ],
            }

            loaded = {
                d["image_url"]: d["image"]
                for d in data["list"]
                if "image_url" in d and "image" in d
            } if data else {}

            for c in content["list"]:
                image_url = c["image_url"]
                if image_url:
                    image = loaded.get(image_url) or get_image(image_url)
                    if image:
                        c["image"] = image
            data = content

            cache.set(KEY, json.encode(data), TTL)
            #print(json.encode(data))

    if not data:
        # dummy data
        data = {
            "timestamp": now,
            "list": [
                {
                    "name": "Failed to retrieve the BoardGameGeek hotness",
                }
                for rank in RANKS
            ],
        }

    hotness = data["list"]

    for h in hotness:
        image = h.get("image")
        if image:
            h["image"] = base64.decode(image)

    hotness = [data_frame(i, h) for i, h in enumerate(hotness)]

    frames = []
    for i, h in enumerate(hotness):
        frames.extend([h] * PAUSE_F)
        frames.extend(scroll_frames(h, hotness[(i + 1) % COUNT]))

    return render.Root(
        delay = DELAY_MS,
        child = render.Animation(frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

def get_image(url):
    if url:
        print("Getting " + url)
        response = http.get(url)
        if response.status_code == 200:
            return base64.encode(response.body())

    return None

def data_frame(i, item):
    name = item.get("name", "")
    black_text = render.WrappedText(
        color = "#000",
        width = WIDTH,
        height = HEIGHT,
        content = name,
    )

    return render.Stack(
        [
            render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Image(
                        width = IM_W,
                        height = IM_H,
                        src = item["image"],
                    ),
                ],
            ) if item.get("image") else None,
        ] + [
            render.Padding(
                pad = p,
                child = black_text,
            )
            for p in SHADOW_PADDING
        ] + [
            render.WrappedText(
                color = COLORS[i],
                content = name,
            ),
        ],
    )

def scroll_frames(item, next_item):
    return [
        render.Padding(
            pad = (0, offset, 0, 0),
            child = render.Stack([
                item,
                render.Padding(
                    pad = (0, HEIGHT, 0, 0),
                    child = next_item,
                ),
            ]),
        )
        for offset in range(SCROLL_SIZE, SCROLL_LIMIT, SCROLL_SIZE)
    ]

URL = "http://boardgamegeek.com/xmlapi2/hot?type=boardgame"

NAME_PATH_FMT = "/items/item[@rank=%s]/name/@value"
YEAR_PATH_FMT = "/items/item[@rank=%s]/yearpublished/@value"
IMAGE_PATH_FMT = "/items/item[@rank=%s]/thumbnail/@value"

WIDTH = 64
HEIGHT = 32

IM_W = 32
IM_H = 32
IM_H_PAD = 32

COUNT = 5

DELAY_MS = 30
PAUSE_MS = 2000
PAUSE_F = PAUSE_MS // DELAY_MS
SCROLL_SIZE = -4
SCROLL_LIMIT = -HEIGHT - 1

RANKS = range(1, COUNT + 1)

SHADOW_PADDING = [
    (x, y, 0, 0)
    for x in [-1, 0, 1]
    for y in [-1, 0, 1]
    if x != 0 or y != 0
]

COLORS = [
    "#f44",
    "#bb0",
    "#3d3",
    "#3df",
    "#26f",
]

KEY = "hotness"
TTL = 48 * 60 * 60
EXPIRY = 3 * 60 * 60

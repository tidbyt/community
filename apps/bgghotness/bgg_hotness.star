"""
Applet: Geeky Hotness
Summary: Geeky Hotness
Description: Shows the top items from BoardGameGeek's Board Game Hotness list. Powered by BGG.
Author: Henry So, Jr.
"""

# Geeky Hotness - Powered by BGG
#
# Copyright (c) 2022, 2025 Henry So, Jr.
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
load("secret.star", "secret")
load("time.star", "time")
load("xpath.star", "xpath")

def main(config):
    now = time.now().unix

    data = cache.get(KEY)
    data = json.decode(data) if data else None

    if not data or (now - data["timestamp"]) > EXPIRY:
        print("Getting " + URL)
        api_key = API_KEY or config.get("api_key")
        content = http.get(URL, headers = {"Authorization": "Bearer %s" % api_key})
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

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
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
    logo_frame = render.Image(
        width = WIDTH,
        height = HEIGHT,
        src = LOGO,
    )

    frames = []
    for i, h in enumerate(hotness):
        frames.extend([h] * PAUSE_F)
        frames.extend(scroll_frames(h, hotness[i + 1] if i + 1 < COUNT else logo_frame))
    frames.extend([logo_frame] * (PAUSE_F // 2))

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
            render.Box(
                width = WIDTH,
                height = HEIGHT,
                color = "#000",
            ),
        ] + [
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

API_KEY = secret.decrypt("AV6+xWcE0BurBiQZCtCDKvsAFq3JxukpFlQ1DN1MmI2b6kjZWdQt9Cck6K9UR5Wr7fkOejqZLetAZYZPrCkUfqeWV+wfHop0zTUeast/u44OeDVZytLh/nV1cfdnoaVBxc4PBS5gQOqu1Os+j/FLEakxPW1fvtU7oMhDgbOjfnc4MjLmZq5rfgge")

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

LOGO = base64.decode("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")

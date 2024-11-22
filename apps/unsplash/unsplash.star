"""
Applet: Unsplash
Summary: Shows random photos
Description: Displays a random image from Unsplash.
Author: zephyern
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAIAAAAt/+nTAAAABGdBTUEAALGPC/xh
BQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAA
eGVYSWZNTQAqAAAACAAFARIAAwAAAAEAAQAAARoABQAAAAEAAABKARsABQAAAAEA
AABSASgAAwAAAAEAAgAAh2kABAAAAAEAAABaAAAAAAAAAAEAAAABAAAAAQAAAAEA
AqACAAQAAAABAAAAQKADAAQAAAABAAAAIAAAAABVO9gXAAAACXBIWXMAAAAnAAAA
JwEqCZFPAAACxmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4
bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAi
PgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkv
MDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJk
ZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRv
YmUuY29tL3RpZmYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDov
L25zLmFkb2JlLmNvbS9leGlmLzEuMC8iPgogICAgICAgICA8dGlmZjpZUmVzb2x1
dGlvbj4xPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0
aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpY
UmVzb2x1dGlvbj4xPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpP
cmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8ZXhpZjpQ
aXhlbFhEaW1lbnNpb24+NjQ8L2V4aWY6UGl4ZWxYRGltZW5zaW9uPgogICAgICAg
ICA8ZXhpZjpDb2xvclNwYWNlPjE8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAg
PGV4aWY6UGl4ZWxZRGltZW5zaW9uPjMyPC9leGlmOlBpeGVsWURpbWVuc2lvbj4K
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
AAAAAElFTkSuQmCC
""")

UNSPLASH_URL = "https://api.unsplash.com/photos/random"
UNSPLASH_ACCESS_KEY = secret.decrypt("AV6+xWcEouhNH5fsxoWNM3TM76UpnbST7Sn/0QRgPNaO9sC647frYR6kdexgwoKgKCTQr0ovkQF3SwJgivV39gCRkhzYAonlY272+8a8P6y/7Ya6cMHmvHM6FybM2k2opEoTnBcOdVzcZVq1ho0fU7KFv4L+g4kgyAVxIkGpFHrU7Tt2MxgifsNcipjt+h9kWg==")

def main(config):
    image = cache.get("image")
    if not image:
        image = DEFAULT_IMAGE
        key = UNSPLASH_ACCESS_KEY or config.get("dev_api_key")
        if key:
            print("Querying for image.")
            rep = http.get(
                UNSPLASH_URL,
                headers = {
                    "Accept-Version": "v1",
                    "Authorization": "Client-ID %s" % key,
                },
                params = {
                    "orientation": "landscape",
                },
            )

            if rep.status_code == 200:
                response = rep.json()
                thumb_url = response["urls"]["thumb"]
                image_rep = http.get(
                    thumb_url,
                    params = {
                        "fit": "crop",
                        "crop": "edges",
                        "w": "64",
                        "h": "32",
                        "fm": "png",
                    },
                )

                if image_rep.status_code == 200:
                    image = image_rep.body()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("image", image, ttl_seconds = 3600)

    return render.Root(
        child = render.Image(src = image),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

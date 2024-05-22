"""
Applet: Bible Verse
Summary: Bible verse every 3 minutes
Description: Displays new bible verse every 3 seconds from different bible translations.
Author: Blaise Sebagabo
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://bible-api.com/?random=verse&translation={}"

DEFAULT_TRANSLATION = "kjv"
DEFAULT_REFERENCE_COLOR = "#00FF00"

def main(config):
    translation = config.get("translation", DEFAULT_TRANSLATION)
    color = config.str("color", DEFAULT_REFERENCE_COLOR)
    response = http.get(API_URL.format(translation), ttl_seconds = 240)
    if response.status_code != 200:
        fail("Bible API request failed with status %d" % response.status_code)

    data = response.json()
    verse_text = data["verses"][0]["text"].strip()
    reference = data["reference"]
    if response.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Bible API.")
    return render.Root(
        delay = 100,
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = reference,
                    color = color,
                    font = "CG-pixel-3x5-mono",
                ),
                render.Marquee(
                    width = 64,
                    height = 32,
                    child = render.Text(
                        content = verse_text,
                        color = "#FFFFFF",
                        font = "tb-8",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Color",
                desc = "The color of the text reference.",
                icon = "brush",
                default = DEFAULT_REFERENCE_COLOR,
                palette = [
                    DEFAULT_REFERENCE_COLOR,
                    "#FF0000",
                    "#0000FF",
                    "#BFEDC4",
                    "#00FF00",
                    "#FF00FF",
                    "#00FFFF",
                    "#78DECC",
                    "#DBB5FF",
                ],
            ),
            schema.Dropdown(
                id = "translation",
                name = "Translation",
                desc = "The translation to use for the Bible verses.",
                icon = "book",
                default = DEFAULT_TRANSLATION,
                options = [
                    schema.Option("KJV", "kjv"),
                    schema.Option("ASV", "asv"),
                    schema.Option("WEB", "web"),
                    schema.Option("OEB-US", "oeb-us"),
                ],
            ),
        ],
    )

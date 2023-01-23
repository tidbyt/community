"""
Applet: Bored
Summary: Things to do when bored
Description: This app will suggest things you can do alone or with your friends if you are bored.
Author: Anders Heie
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("random.star", "random")

# Global defines
BORED_URL = "https://www.boredapi.com/api/activity"
DEFAULT_COLOR = "#FF00FF"
DEFAULT_FRIENDS = "random"
DEFAULT_FONT = "6x13"
DEFAULT_DIRECTION = "vertical"

def main(config):
    activity = cache.get("activity")
    if activity != None:
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Bored API.")

        friends = config.get("friends", "1")
        if friends == "random":
            friends = random.number(1, 5)

        # this may not work
        params = {
            "participants": str(friends),
        }
        print("params", params)
        rep = http.get(BORED_URL, params = params)
        if rep.status_code != 200:
            fail("Bored request failed with status %d", rep.status_code)
        activity = rep.json()["activity"]
        cache.set("activity", activity, ttl_seconds = 600)
        print(activity)

    color = config.get("color", DEFAULT_COLOR)
    font = config.get("font", DEFAULT_FONT)

    # and then this does some stuff...
    if config.get("direction", DEFAULT_DIRECTION) == "horizontal":
        child = render.Box(
            render.Marquee(
                width = 64,
                child = render.Text(activity, color = color, font = font),
                offset_start = 35,
                offset_end = 35,
            ),
        )
    else:
        # If we scroll vertically, we need smaller fonts to avoid long words being cut off at the sides
        if font != "tom-thumb" or font != "tb-8":
            font = "tb-8"

        child = render.Box(
            render.Marquee(
                height = 32,
                child = render.WrappedText(
                    content = activity,
                    color = color,
                    width = 64,
                    font = font,
                    align = "center",
                ),
                offset_start = 5,
                offset_end = 5,
                scroll_direction = "vertical",
            ),
        )

    return render.Root(
        child,
    )

def get_schema():
    color_options = [
        schema.Option(
            display = "Pink",
            value = "#FF94FF",
        ),
        schema.Option(
            display = "Mustard",
            value = "#FFD10D",
        ),
        schema.Option(
            display = "Blue",
            value = "#0000FF",
        ),
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Green",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Purple",
            value = "#FF00FF",
        ),
        schema.Option(
            display = "Cyan",
            value = "#00FFFF",
        ),
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
    ]

    friend_options = [
        schema.Option(
            display = "Just me",
            value = "1",
        ),
        schema.Option(
            display = "Me and a friend",
            value = "2",
        ),
        schema.Option(
            display = "Me and my friends",
            value = "5",
        ),
        schema.Option(
            display = "Random",
            value = "random",
        ),
    ]

    font_options = [
        schema.Option(
            display = "Tiny",
            value = "tom-thumb",
        ),
        schema.Option(
            display = "Small",
            value = "tb-8",
        ),
        schema.Option(
            display = "Medium (horizontal only)",
            value = "6x13",
        ),
        schema.Option(
            display = "Huge (Horizontal only)",
            value = "10x20",
        ),
    ]

    direction_options = [
        schema.Option(
            display = "Horizontal scroll",
            value = "horizontal",
        ),
        schema.Option(
            display = "Vertical scroll",
            value = "vertical",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "friends",
                name = "Friends",
                desc = "How many people are bored?",
                icon = "gear",
                default = friend_options[0].value,
                options = friend_options,
            ),
            schema.Dropdown(
                id = "color",
                name = "Text Color",
                desc = "The color of text to be displayed.",
                icon = "brush",
                default = color_options[0].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font size",
                desc = "Size of font",
                icon = "brush",
                default = font_options[0].value,
                options = font_options,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Scroll direction",
                desc = "Direction to scroll if text too long",
                icon = "brush",
                default = direction_options[0].value,
                options = direction_options,
            ),
        ],
    )

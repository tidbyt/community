"""
Applet: Bored
Summary: Things to do when bored
Description: This app will suggest things you can do alone or with your friends if you are bored.
Author: Anders Heie
"""

load("cache.star", "cache")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Global defines
BORED_URL = "https://www.boredapi.com/api/activity"
DEFAULT_COLOR = "#FF00FF"
DEFAULT_FRIENDS = "random"
DEFAULT_FONT = "6x13"
DEFAULT_DIRECTION = "vertical"

def main(config):
    # Create unique cache key based on config values.
    # The only one that really matters for now is the number of participants
    friends = config.get("friends", "1")

    # if a random is selected, randomize
    if friends == "random":
        friends = str(random.number(1, 5))

    cache_key = "bored_app_" + friends
    hasAPIData = True

    # Pre-analyze custom settings. If anything is there, we can use those
    # IF the API is not working, instead of throwing an error.

    custom_bored = []
    if config.get("personal1", "").strip() != "":
        custom_bored.insert(0, config.get("personal1", "").strip())
    if config.get("personal2", "").strip() != "":
        custom_bored.insert(0, config.get("personal2", "").strip())
    if config.get("personal3", "").strip() != "":
        custom_bored.insert(0, config.get("personal3", "").strip())
    if config.get("personal4", "").strip() != "":
        custom_bored.insert(0, config.get("personal4", "").strip())
    if config.get("personal5", "").strip() != "":
        custom_bored.insert(0, config.get("personal5", "").strip())
    if config.get("personal6", "").strip() != "":
        custom_bored.insert(0, config.get("personal6", "").strip())
    if config.get("personal7", "").strip() != "":
        custom_bored.insert(0, config.get("personal7", "").strip())
    if config.get("personal8", "").strip() != "":
        custom_bored.insert(0, config.get("personal8", "").strip())
    if config.get("personal9", "").strip() != "":
        custom_bored.insert(0, config.get("personal9", "").strip())
    if config.get("personal10", "").strip() != "":
        custom_bored.insert(0, config.get("personal10", "").strip())

    hasPersonalized = len(custom_bored) > 0
    print("Found personalized: " + str(len(custom_bored)))

    activity = cache.get(cache_key)
    if activity != None:
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Bored API.")

        # this may not work
        params = {
            "participants": friends,
        }

        print("params", params)
        rep = http.get(BORED_URL, params = params)
        if rep.status_code != 200:
            hasAPIData = False
            if hasPersonalized == False:
                fail("Bored request failed with status %d", rep.status_code)
        else:
            activity = rep.json()["activity"]
            cache.set(cache_key, activity, ttl_seconds = 600)
            print("API Activity suggestion: " + activity)

    color = config.get("color", DEFAULT_COLOR)
    font = config.get("font", DEFAULT_FONT)

    # Check personalized
    if (hasPersonalized == True):
        chance = int(config.get("personalized_chance", "5"))
        print("Chance: ", str(chance))
        print("Rando: " + str(random.number(1, 100)))
        print("Has API Data", str(hasAPIData))
        if hasAPIData == False or chance > random.number(0, 99):
            activity = custom_bored[random.number(0, len(custom_bored) - 1)]

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

        child = render.Marquee(
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
        )

    return render.Root(
        child,
        show_full_animation = bool(config.get("scroll", True)),
        delay = int(config.get("speed", 45)),
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

    speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
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
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Scrolling speed",
                icon = "gear",
                default = speed_options[1].value,
                options = speed_options,
            ),
            schema.Toggle(
                id = "scroll",
                name = "Try to finish?",
                desc = "Keep scrolling text even if it's longer than app-rotation time",
                icon = "user",
                default = True,
            ),
            schema.Text(
                id = "personalized_chance",
                name = "% Chance of showing",
                desc = "Number from 0-100 indicating the percentage chance that the custom things below are shown",
                icon = "user",
                default = "5",
            ),
            schema.Text(
                id = "personal1",
                name = "First thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal2",
                name = "Second thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal3",
                name = "Third thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal4",
                name = "Fourth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal5",
                name = "Fifth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal6",
                name = "Sixth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal7",
                name = "Seventh thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal8",
                name = "Eighth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal9",
                name = "Nineth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "personal10",
                name = "Tenth thing to do",
                desc = "Optional: Enter a thing to do",
                icon = "user",
                default = "",
            ),
        ],
    )

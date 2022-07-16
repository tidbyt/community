"""
Applet: Emoji Lingo
Summary: A random emoji, localized
Description: Displays a random emoji and its unique short text annotation from the Unicode Consortium in a given locale.
Author: Cedric Sam
"""

load("schema.star", "schema")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")

default_locale = "fr_CA"

EMOJI_LIST_URL = "https://emoji-lingo.s3.amazonaws.com/emoji-list-base64.json"
EMOJI_NAMES_URL = "https://emoji-lingo.s3.amazonaws.com/locale/%s.json"

def findCodeInList(code, emojiList):
    for item in emojiList:
        if item["code"] == code:
            return item

def main(config):
    # Try to find data from cache
    locale = config.str("locale")
    if locale == None:
        locale = default_locale
    emoji_base64 = cache.get("emoji_base64")
    emoji_names = cache.get("emoji_names_%s" % locale)
    if emoji_base64 != None:
        print("Using cache for emoji base64")
        EMOJI_LIST = json.decode(emoji_base64)
    else:
        print("Making request for emoji base64 to %s" % EMOJI_LIST_URL)
        rep = http.get(EMOJI_LIST_URL)
        if rep.status_code != 200:
            fail("couldn't get list of emojis with status %d" % rep.status_code)
        EMOJI_LIST = rep.json()
        cache.set("emoji_base64", rep.body(), ttl_seconds = 300)
    if emoji_names != None:
        print("Using cache for emoji names")
        EMOJI_NAMES = json.decode(emoji_names)
    else:
        print("Making request for emoji names to %s" % (EMOJI_NAMES_URL % locale))
        repNames = http.get(EMOJI_NAMES_URL % locale)
        if repNames.status_code != 200:
            fail("couldn't get list of emoji names with status %d" % repNames.status_code)
        EMOJI_NAMES = repNames.json()
        cache.set("emoji_names_%s" % locale, repNames.body(), ttl_seconds = 300)

    # Pick an emoji at random (hopefully a good one)
    RAND_INDEX = random.number(0, len(EMOJI_LIST))
    EMOJI_ICON = EMOJI_LIST[RAND_INDEX]
    decoded_emoji = base64.decode(EMOJI_ICON["base64"])
    nameItem = findCodeInList(EMOJI_ICON["code"], EMOJI_NAMES)

    if nameItem != None:
        shortName = nameItem["sn"]
    else:
        fail("Emoji has no name")
        shortName = "N/A"

    # Print some diagnostics...
    print(EMOJI_ICON)
    print(nameItem)

    # Do options

    # Small text or not
    if config.bool("small"):
        font_face = "tom-thumb"
    else:
        font_face = "tb-8"

    # Setup the images and marquee
    img = render.Image(
        width = 24,
        height = 24,
        src = decoded_emoji,
    )
    emoji_text_render = render.Text(
        shortName,
        font = font_face,
    )
    marquee_vertical = render.Marquee(
        width = 64,
        offset_start = 32,
        offset_end = 32,
        child = emoji_text_render,
        align = "center",
    )
    marquee_horizontal = render.Marquee(
        width = 36,
        offset_start = 18,
        offset_end = 18,
        child = emoji_text_render,
        align = "center",
    )
    contents_vertical = render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            img,
            marquee_vertical,
        ],
    )
    contents_horizontal = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            img,
            marquee_horizontal,
        ],
    )
    if config.str("textPosition") == "bottom":
        contents = contents_vertical
    elif config.str("textPosition") == "right":
        contents = contents_horizontal
    else:
        contents = contents_horizontal

    # On screen
    return render.Root(
        child = render.Box(
            contents,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "locale",
                name = "Locale",
                desc = "Local language to display the emoji short names in",
                icon = "language",
                default = default_locale,
                options = [
                    schema.Option(
                        display = "Canadian French",
                        value = "fr_CA",
                    ),
                    schema.Option(
                        display = "US English",
                        value = "en",
                    ),
                    schema.Option(
                        display = "UK English",
                        value = "en_GB",
                    ),
                    schema.Option(
                        display = "Danish",
                        value = "da",
                    ),
                    schema.Option(
                        display = "French",
                        value = "fr",
                    ),
                    schema.Option(
                        display = "German",
                        value = "de",
                    ),
                    schema.Option(
                        display = "Spanish",
                        value = "es",
                    ),
                    schema.Option(
                        display = "Mexican Spanish",
                        value = "es_MX",
                    ),
                    schema.Option(
                        display = "Finnish",
                        value = "fi",
                    ),
                    schema.Option(
                        display = "Irish",
                        value = "ga",
                    ),
                    schema.Option(
                        display = "Indonesian",
                        value = "id",
                    ),
                    schema.Option(
                        display = "Italian",
                        value = "it",
                    ),
                    schema.Option(
                        display = "Malay",
                        value = "ms",
                    ),
                    schema.Option(
                        display = "Dutch",
                        value = "nl",
                    ),
                    schema.Option(
                        display = "Norwegian",
                        value = "no",
                    ),
                    schema.Option(
                        display = "Portuguese",
                        value = "pt",
                    ),
                    schema.Option(
                        display = "European Portuguese",
                        value = "pt_PT",
                    ),
                    schema.Option(
                        display = "Swedish",
                        value = "sv",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "textPosition",
                name = "Text Position",
                desc = "Where the emoji short names will appear",
                icon = "arrowsUpDownLeftRight",
                default = "bottom",
                options = [
                    schema.Option(
                        display = "Right of",
                        value = "right",
                    ),
                    schema.Option(
                        display = "Under",
                        value = "bottom",
                    ),
                ],
            ),
            schema.Toggle(
                id = "small",
                name = "Display small text",
                desc = "A toggle to display smaller text.",
                icon = "compress",
                default = False,
            ),
        ],
    )

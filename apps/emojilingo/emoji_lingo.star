"""
Applet: Emoji Lingo
Summary: A random emoji, localized
Description: Displays a random emoji and its unique short text annotation from the Unicode Consortium in a given locale.
Author: Cedric Sam
"""

load("schema.star", "schema")
load("re.star", "re")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("encoding/csv.star", "csv")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

default_locale = "fr_CA"

EMOJI_LIST_URL = "https://emoji-lingo.s3.amazonaws.com/emoji-list.csv"
EMOJI_NAMES_URL = "https://emoji-lingo.s3.amazonaws.com/locale/%s.csv"
EMOJI_BASE64_URL = "https://emoji-lingo.s3.amazonaws.com/base64/%s.txt"

def findCodeInList(code, emojiList):
    for item in emojiList:
        if item["code"] == code:
            return item

def normalizeCode(code):
    return re.sub(r" +", "-", code)

def main(config):
    # Try to find data from cache
    locale = config.str("locale")
    if locale == None:
        locale = default_locale
    emoji_base64_list_cache = cache.get("emoji_base64_list")
    emoji_names_cache = cache.get("emoji_names_%s" % locale)
    if emoji_base64_list_cache != None:
        print("Using cache for emoji base64")
        emoji_list = csv.read_all(emoji_base64_list_cache, skip = 1)
    else:
        print("Making request for emoji with base64 list to %s" % EMOJI_LIST_URL)
        rep = http.get(EMOJI_LIST_URL)
        if rep.status_code != 200:
            fail("couldn't get list of emojis with status %d" % rep.status_code)
        emoji_list = csv.read_all(rep.body(), skip = 1)
        cache.set("emoji_base64_list", rep.body(), ttl_seconds = 7200)
    if emoji_names_cache != None:
        print("Using cache for emoji names")
        emoji_names = csv.read_all(emoji_names_cache, skip = 1)
    else:
        print("Making request for emoji names to %s" % (EMOJI_NAMES_URL % locale))
        rep_names = http.get(EMOJI_NAMES_URL % locale)
        if rep_names.status_code != 200:
            fail("couldn't get list of emoji names with status %d" % rep_names.status_code)
        emoji_names = csv.read_all(rep_names.body(), skip = 1)
        cache.set("emoji_names_%s" % locale, rep_names.body(), ttl_seconds = 7200)

    valid_emoji_base64_list = list()
    for code in emoji_list:
        valid_emoji_base64_list.append(code[1])

    valid_emoji_data = list()
    for emoji_name_data in emoji_names:
        normalized_emoji_unicode = normalizeCode(emoji_name_data[0])
        if (normalized_emoji_unicode in valid_emoji_base64_list):
            valid_emoji_data.append(emoji_name_data)

    # Pick an emoji at random (hopefully a good one)
    number_valid_emojis = len(valid_emoji_data)
    rand_index = random.number(0, number_valid_emojis)
    print("Picking from %d random emojis... random index was %d" % (number_valid_emojis, rand_index))
    name_item = valid_emoji_data[rand_index]

    # Get the base64 text file
    base64_url = EMOJI_BASE64_URL % normalizeCode(name_item[0])
    print("Making request for emoji base64 to %s" % base64_url)
    rep_base64 = http.get(base64_url)
    if rep_base64.status_code != 200:
        fail("couldn't get emoji text file with status %d" % rep_base64.status_code)
    random_emoji_base64 = rep_base64.body()
    decoded_emoji = base64.decode(random_emoji_base64)

    if name_item != None:
        shortName = name_item[1]
    else:
        fail("Emoji has no name")

    # Print some diagnostics...
    print(random_emoji_base64)
    print(name_item)

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

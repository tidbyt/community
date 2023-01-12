"""
Applet: Emoji Lingo
Summary: Random multilingual emojis
Description: Displays a random emoji and its unique short text annotation from the Unicode Consortium in a given language.
Author: Cedric Sam
"""

load("cache.star", "cache")
load("compress/gzip.star", "gzip")
load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

default_locale = "fr_CA"
default_vendor = "apple"

test_emoji = None

EMOJI_LIST_URL = "https://emoji-lingo.s3.amazonaws.com/emoji-list-%s.csv"
EMOJI_NAMES_URL = "https://emoji-lingo.s3.amazonaws.com/locale/%s.csv"
EMOJI_BASE64_URL = "https://emoji-lingo.s3.amazonaws.com/base64/%s/%s.txt"

def normalizeCode(code):
    return re.sub(r" +", "-", code)

def getEmojiList(vendor):
    emoji_base64_list_cache = cache.get("emoji_base64_list")
    if emoji_base64_list_cache != None:
        print("Using cache for emoji base64")
        return csv.read_all(emoji_base64_list_cache, skip = 1)

    # No cache found, try to get the file
    emoji_list_url_vendor = EMOJI_LIST_URL % vendor
    print("Making request for emoji with base64 list to %s" % emoji_list_url_vendor)
    rep = http.get(emoji_list_url_vendor)
    if rep.status_code != 200:
        fail("couldn't get list of emojis with status %d" % rep.status_code)
    rep_body_raw = rep.body()
    rep_body = str(gzip.decompress(rep_body_raw))  # the emoji list emoji is gzipped, despite url
    cache.set("emoji_base64_list", rep_body, ttl_seconds = 86400)  # caching 24 hours
    return csv.read_all(rep_body, skip = 1)

def getEmojiNames(locale):
    emoji_names_cache = cache.get("emoji_names_%s" % locale)
    if emoji_names_cache != None:
        print("Using cache for emoji names")
        return csv.read_all(emoji_names_cache, skip = 1)

    # No cache found, try to get the file
    print("Making request for emoji names to %s" % (EMOJI_NAMES_URL % locale))
    rep_names = http.get(EMOJI_NAMES_URL % locale)
    if rep_names.status_code != 200:
        fail("couldn't get list of emoji names with status %d" % rep_names.status_code)
    rep_names_body_raw = rep_names.body()
    rep_names_body = str(gzip.decompress(rep_names_body_raw))  # the names csv is gzipped, despite url
    cache.set("emoji_names_%s" % locale, rep_names_body, ttl_seconds = 86400)  # caching 24 hours
    return csv.read_all(rep_names_body, skip = 1)

def main(config):
    locale = config.str("locale")
    if locale == None:
        locale = default_locale
    vendor = config.str("vendor")
    if vendor == None:
        vendor = default_vendor
    print("Vendor: %s" % vendor)

    random_emoji_base64 = None

    # Try to find data from cache...
    # Also caching by vendor, since base64 would be different...
    # An emoji caches by its base64 in a given language, but it
    # may be possible it won’t have text in another (although
    # very unlikely it won’t find anything per ones picked)
    random_emoji_cache_name = "random_emoji-%s" % vendor
    random_emoji_csv_data_cached = cache.get(random_emoji_cache_name)
    name_item = None
    if random_emoji_csv_data_cached != None:
        print("Cache for random emoji is valid...")
        random_emoji_data_cached = csv.read_all(random_emoji_csv_data_cached, fields_per_record = 2)
        if len(random_emoji_data_cached) > 0:
            print("Random emoji cache contents: ", random_emoji_data_cached)
            random_emoji_cached = random_emoji_data_cached[0]
            emoji_names = getEmojiNames(locale)
            for item in emoji_names:
                if random_emoji_cached[0] == item[0]:
                    random_emoji_base64 = random_emoji_cached[1]
                    name_item = item
                    break

    # name_item not set, because not found on cache
    if name_item == None:
        # get emoji lists (emoji base64 and the names per locale)
        emoji_list = getEmojiList(vendor)
        emoji_names = getEmojiNames(locale)
        valid_emoji_base64_list = list()
        for code in emoji_list:
            valid_emoji_base64_list.append(code[1])

        valid_emoji_data = list()
        for emoji_name_data in emoji_names:
            normalized_emoji_unicode = normalizeCode(emoji_name_data[0])
            if (normalized_emoji_unicode in valid_emoji_base64_list):
                valid_emoji_data.append(emoji_name_data)

        # Clause for using a test emoji defined at top
        if test_emoji != None:
            test_emoji_code = None
            for code in emoji_list:
                if str(test_emoji) == code[0]:
                    test_emoji_code = code[1]
                    break
            if test_emoji_code != None:
                for emoji_name_data in emoji_names:
                    normalized_emoji_unicode = normalizeCode(emoji_name_data[0])
                    if normalized_emoji_unicode == test_emoji_code:
                        name_item = emoji_name_data
                        break

        # Pick an emoji at random (hopefully a good one)
        if name_item == None:
            number_valid_emojis = len(valid_emoji_data)
            rand_index = random.number(0, number_valid_emojis)
            print("Picking from %d random emojis... random index was %d" % (number_valid_emojis, rand_index))
            name_item = valid_emoji_data[rand_index]

        # Get the base64 text file
        base64_url = EMOJI_BASE64_URL % (vendor, normalizeCode(name_item[0]))
        print("Making request for emoji base64 to %s" % base64_url)
        rep_base64 = http.get(base64_url)
        if rep_base64.status_code != 200:
            fail("couldn't get emoji text file with status %d" % rep_base64.status_code)
        random_emoji_base64 = rep_base64.body()
        cache.set(
            "random_emoji-%s" % vendor,
            "%s,%s" % (name_item[0], random_emoji_base64),  # as a one-line CSV...
            ttl_seconds = 30,
        )  # caching 30 seconds

    if name_item != None:
        shortName = name_item[1]
    else:
        fail("Emoji has no name")

    # Print some diagaostics...
    print(random_emoji_base64)
    print(name_item)

    # Finally decode the emoji's base64
    decoded_emoji = base64.decode(random_emoji_base64)

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
        contents = contents_vertical

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
            # Names from: https://unicode-org.github.io/cldr-staging/charts/latest/summary/root.html
            # Only latin1 (ISO-8859-1) languages are supported
            schema.Dropdown(
                id = "locale",
                name = "Locale",
                desc = "Local language in which to display the emoji short names",
                icon = "language",
                default = default_locale,
                options = [
                    schema.Option(
                        display = "English",
                        value = "en",
                    ),
                    schema.Option(
                        display = "British English",
                        value = "en_GB",
                    ),
                    schema.Option(
                        display = "Australian English",
                        value = "en_AU",
                    ),
                    schema.Option(
                        display = "Afrikaans",
                        value = "af",
                    ),
                    schema.Option(
                        display = "Danish",
                        value = "da",
                    ),
                    schema.Option(
                        display = "Dutch",
                        value = "nl",
                    ),
                    schema.Option(
                        display = "Finnish",
                        value = "fi",
                    ),
                    schema.Option(
                        display = "Filipino",
                        value = "fil",
                    ),
                    schema.Option(
                        display = "French",
                        value = "fr",
                    ),
                    schema.Option(
                        display = "Canadian French",
                        value = "fr_CA",
                    ),
                    schema.Option(
                        display = "German",
                        value = "de",
                    ),
                    schema.Option(
                        display = "Hungarian",
                        value = "hu",
                    ),
                    schema.Option(
                        display = "Indonesian",
                        value = "id",
                    ),
                    schema.Option(
                        display = "Irish",
                        value = "ga",
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
                        display = "Spanish",
                        value = "es",
                    ),
                    schema.Option(
                        display = "Mexican Spanish",
                        value = "es_MX",
                    ),
                    schema.Option(
                        display = "Swahili",
                        value = "sw",
                    ),
                    schema.Option(
                        display = "Swedish",
                        value = "sv",
                    ),
                    schema.Option(
                        display = "Welsh",
                        value = "cy",
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
            schema.Dropdown(
                id = "vendor",
                name = "Emoji Style",
                desc = "Emoji as seen on a given platform",
                icon = "icons",
                default = default_vendor,
                options = [
                    schema.Option(
                        display = "Apple",
                        value = "apple",
                    ),
                    schema.Option(
                        display = "Google",
                        value = "google",
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

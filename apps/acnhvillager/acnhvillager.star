"""
Applet: AC:NH Villager
Summary: Random AC:NH villager
Description: See your favorite villagers from Animal Crossing New Horizons.
Author: colinscruggs
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL_SECONDS = 3600 * 24 * 7
ICON_WIDTH = 26
ICON_HEIGHT = 26

FONTS = ["CG-pixel-3x5-mono", "tb-8", "tom-thumb", "Dina_r400-6", "5x8"]
FONT_DEFAULT = FONTS[0]

FAIL_IMAGE = "aHR0cHM6Ly91cGxvYWQud2lraW1lZGlhLm9yZy93aWtpcGVkaWEvY29tbW9ucy90aHVtYi81LzU4L0FuaW1hbF9Dcm9zc2luZ19MZWFmLnBuZy81MDBweC1BbmltYWxfQ3Jvc3NpbmdfTGVhZi5wbmc="
FAIL_MESSAGE = "%s failed with status: %d"

ACNH_API_URL = "https://acnhapi.com/v1/villagers/"

def main(config):
    language = config.get("language") or "USen"
    name_key = "name-" + language
    catch_phrase_key = "catch-" + language

    # Fetch and cache villager data; pick one at random
    villager_data = get_villager_data()
    random_index = random.number(0, len(villager_data) - 1)
    _, villager = list(villager_data.items())[random_index]
    if len(villager) == 0:
        fail("Unable to find villager :c")

    # Set villager icon
    villager_icon = villager["icon_uri"]
    if villager_icon == None:
        villager_icon = get_villager_icon(base64.decode(FAIL_IMAGE))
    else:
        villager_icon = get_villager_icon(villager_icon)

    return render.Root(
        delay = 100,
        child =
            render.Padding(
                pad = (0, 2, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "space_around",
                        children = [
                            # Left column - Name and Icon
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_name(villager["name"][name_key]),
                                                font = FONT_DEFAULT,
                                                color = villager["bubble-color"],
                                            ),
                                        width = 28,
                                    ),
                                    render.Image(
                                        src = villager_icon,
                                        width = ICON_WIDTH,
                                        height = ICON_HEIGHT,
                                    ),
                                ],
                            ),
                            # Right column - Personality, Species, and Catch Phrase
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = villager["personality"],  # Shouldn't go over 6 characters
                                        font = FONT_DEFAULT,
                                        width = 28,
                                        align = "right",
                                    ),
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_species(villager["species"]),
                                                font = FONT_DEFAULT,
                                            ),
                                        width = 28,
                                        scroll_direction = "horizontal",
                                    ),
                                    render.Marquee(
                                        child =
                                            render.Text(
                                                content = get_villager_catch_phrase(villager["catch-translations"][catch_phrase_key]),
                                                font = FONT_DEFAULT,
                                                color = villager["text-color"],
                                            ),
                                        width = 28,
                                        scroll_direction = "horizontal",
                                    ),
                                ],
                            ),
                        ],
                    ),
            ),
    )

# Cache and encode villager data
def get_villager_data():
    villager_data_cached = cache.get("villager_data")
    villager_data = []

    if villager_data_cached != None:
        villager_data = json.decode(villager_data_cached)
    else:
        rep = http.get(ACNH_API_URL)
        if rep.status_code != 200:
            fail(FAIL_MESSAGE % (ACNH_API_URL, rep.status_code))
        villager_data = rep.json()
        cache.set("villager_data", json.encode(villager_data), ttl_seconds = CACHE_TTL_SECONDS)

    return villager_data

# Cache and encode villager icon
def get_villager_icon(url):
    key = base64.encode(url)
    villager_icon_cache = cache.get(key)

    if villager_icon_cache != None:
        return base64.decode(villager_icon_cache)

    res = http.get(url = url)
    if res.status_code != 200:
        fail(FAIL_MESSAGE % (url, res.status_code))

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)
    return res.body()

# Adds padding for villager names that are less than 7 characters
def get_villager_name(str):
    diff = 7 - len(str)
    if diff <= 0:
        return str
    elif diff == 1:
        return str + " "
    elif diff == 2:
        return " " + str + " "
    elif diff == 3:
        return " " + str + " "
    elif diff == 4:
        return "  " + str + "  "
    elif diff == 5:
        return "  " + str + "   "
    elif diff == 6:
        return "   " + str + "   "
    else:
        return str

# Adds quotes; left-padding added for catch phrases that are less than 5 characters
def get_villager_catch_phrase(str):
    padding_right = 5 - len(str)
    if padding_right > 0:
        return padding_right * " " + '"' + str + '"'
    else:
        return '"' + str + '"'

# Adds left-padding added for specifies that are less than 7 characters
def get_villager_species(str):
    padding_right = 7 - len(str)
    if padding_right > 0:
        return padding_right * " " + str
    else:
        return str

def get_schema():
    dialectOptions = [
        schema.Option(
            display = "English (US)",
            value = "USen",
        ),
        schema.Option(
            display = "Spanish (US)",
            value = "USes",
        ),
        schema.Option(
            display = "French",
            value = "EUfr",
        ),
        schema.Option(
            display = "Italian",
            value = "EUit",
        ),
        schema.Option(
            display = "German",
            value = "EUde",
        ),
        schema.Option(
            display = "Dutch",
            value = "EUnl",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "language",
                name = "Language",
                icon = "language",
                desc = "Select language",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
        ],
    )

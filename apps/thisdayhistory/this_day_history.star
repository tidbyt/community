"""
Applet: This Day History
Summary: Historical events today
Description: Display historical events from today including births and deaths (if selected).  Uses Wikipedia information.
Author: jvivona
"""

# 2025-apr-01 - change URL to wikipedia REST API instead of the FEED api.   more reliable apparently

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 25091
# NOTE: trying to determine if there's a widget display option available - but with all the text, I don't see a way at this time

TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#6666ff88"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_AREA_HEIGHT = 24

DEFAULT_TIMEZONE = "America/New_York"

# this data is barely going to change throughout the day - so let's cache for 12 hours (just in case) - each run will get a random item though - but we're saving on network traffic
CACHE_TTL_SECONDS = 43200
ENGLISH = "en"
SPANISH = "es"
GERMAN = "de"
BIRTHS = "births"
DEATHS = "deaths"
EVENTS = "events"

OPTBIRTHS = "inch_births"
OPTDEATHS = "incl_deaths"
OPTDISPLANG = "displayLanguage"

# in the old days - we would actually assign resource numbers to phrases, then look up the correct resource number in the appropriate language resource table.  There's not enough here to do that
# at this time.   this is a decent compromise for now.
# Wikipedia supports about 10 languages for the "This Day in History" feed - some of them we could never display on a device - may be able to add a couple more with the correct localization info

LANG = {
    "es": {
        "Today in History": "Hoy en Historia",
        "Include Births": "Incluir Nacimientos",
        "Include random person who was born on this day.": "Incluir una persona al azar que nació en este día",
        "Include Deaths": "Incluir Defunciones",
        "Include random person who died on this day.": "Incluir una persona al azar que falleció en este día",
        "b": "n. ",
        "d": "f. ",
        "Wikipedia error": "Error {} de Wikipedia",
    },
    "en": {
        "Today in History": "Today in History",
        "Include Births": "Include Births",
        "Include random person who was born on this day.": "Include random person who was born on this day.",
        "Include Deaths": "Include Deaths",
        "Include random person who died on this day.": "Include random person who died on this day.",
        "b": "b. ",
        "d": "d. ",
        "Wikipedia error": "Wikipedia {} error.",
    },
    "de": {
        "Today in History": "Geschichte heute",
        "Include Births": "Mit Geburtstagen",
        "Include random person who was born on this day.": "Eine zufällige Person, die am heutigen Tag geboren wurde, einbeziehen.",
        "Include Deaths": "Mit Todestagen",
        "Include random person who died on this day.": "Eine zufällige Person, die am heutigen Tag gestorben ist, einbeziehen.",
        "b": "g. ",
        "d": "t. ",
        "Wikipedia error": "Fehler {} von Wikipedia.",
    },
}

def main(config):
    language = config.get(OPTDISPLANG, ENGLISH)
    rc, json_data = getData(language, config.get("$tz", DEFAULT_TIMEZONE))

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Text("{}".format(LANG[language]["Today in History"]), color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children =
                                getItems(json_data, config.bool(OPTBIRTHS, True), config.bool(OPTDEATHS, True), language),
                        ),
                ) if rc == 0 else render.WrappedText(json_data, font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR),
            ],
        ),
    )

def getItems(json_data, incl_births, incl_deaths, language):
    this_day = []

    # get event
    this_day = displayItem(json_data[EVENTS], EVENTS, language)

    # get birth
    if incl_births:
        this_day += displayItem(json_data[BIRTHS], BIRTHS, language)

    # get death
    if incl_deaths:
        this_day += displayItem(json_data[DEATHS], DEATHS, language)

    return this_day

def displayItem(json_data, type, language):
    item = []
    prefix = ""

    item_len = len(json_data)

    if (item_len > 0):
        item_number = getRandomItem(item_len)
        if type == BIRTHS:
            prefix = LANG[language]["b"]
        elif type == DEATHS:
            prefix = LANG[language]["d"]
        item.append(render.Text("{}{}".format(prefix, int(json_data[item_number]["year"])), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
        item.append(render.WrappedText(json_data[item_number]["text"], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR))
        item.append(render.Box(width = 64, height = 3, color = SPACER_COLOR))

    return item

def getRandomItem(length):
    return random.number(0, length - 1)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = OPTDISPLANG,
                name = "English / Español / Deutsch",
                desc = "",
                icon = "hashtag",
                default = ENGLISH,
                options = [
                    schema.Option(
                        display = "English",
                        value = ENGLISH,
                    ),
                    schema.Option(
                        display = "Español",
                        value = SPANISH,
                    ),
                    schema.Option(
                        display = "Deutsch",
                        value = GERMAN,
                    ),
                ],
            ),
            schema.Generated(
                id = "generated",
                source = OPTDISPLANG,
                handler = includeOptions,
            ),
        ],
    )

def includeOptions(language):
    return [
        schema.Toggle(
            id = OPTBIRTHS,
            name = LANG[language]["Include Births"],
            desc = LANG[language]["Include random person who was born on this day."],
            icon = "baby",
            default = True,
        ),
        schema.Toggle(
            id = OPTDEATHS,
            name = LANG[language]["Include Deaths"],
            desc = LANG[language]["Include random person who died on this day."],
            icon = "bookSkull",
            default = True,
        ),
    ]

def getData(language, timezone):
    # go get the data
    # this is the old feed URL which is broken as of 2025-mar-28 - they are working on a fix.  switch to REST API for future.  leaving this in there - just in case
    # url = "https://api.wikimedia.org/feed/v1/wikipedia/{}/onthisday/all/".format(language) + time.now().in_location(timezone).format("1/2")
    url = "https://{}.wikipedia.org/api/rest_v1/feed/onthisday/all/".format(language) + time.now().in_location(timezone).format("01/02")
    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return -1, LANG[language]["Wikipedia error"].format(str(response.status_code))
    else:
        json_data = response.json()

    return 0, json_data

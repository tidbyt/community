"""
Applet: This Day History
Summary: Historical events today
Description: Display historical events from today including births and deaths (if selected).  Uses Wikipedia information.
Author: jvivona
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#0000ff"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_AREA_HEIGHT = 24

DEFAULT_TIMEZONE = "America/New_York"

# this data is barely going to change throughout the data - so let's cache for 12 hours (just in case) - each run will get a random item though - but we're saving on network traffic
CACHE_TTL_SECONDS = 43200
ENGLISH = "en"

# in the old days - we would actually assign resource numbers to phrases, then look up the correct resource number in the appropriate language resource table.  There's not enough here to do that
# at this time.   But....  there are better ways to do this.  leave as TODO: for joe v

ES = {
    "Today in History": "Hoy en Historia",
    "Include Births": "Incluir Nacimientos",
    "Include random person who was born on this day.": "Incluir una persona al azar que nació en este día",
    "Include Deaths": "Incluir Defunciones",
    "Include random person who died on this day.": "Incluir una persona al azar que falleció en este día",
    "b": "n. ",
    "d": "f. ",
}

def main(config):
    rc, json_data = getData(config)

    language = config.get("displayLanguage", ENGLISH)

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
                    child = render.Text("{}".format("Today in History" if language == ENGLISH else ES["Today in History"]), color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children =
                                getItems(json_data, config, language),
                        ),
                ) if rc == 0 else render.WrappedText(json_data, font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR),
            ],
        ),
    )

def getItems(json_data, config, language):
    this_day = []

    # get event
    this_day = displayItem(json_data["events"], "events", language)

    # get birth
    if config.bool("incl_births", True):
        this_day += displayItem(json_data["births"], "births", language)

    # get death
    if config.bool("incl_deaths", True):
        this_day += displayItem(json_data["deaths"], "deaths", language)

    return this_day

def displayItem(json_data, type, language):
    item = []
    prefix = ""

    item_len = len(json_data)

    if (item_len > 0):
        item_number = getRandomItem(item_len)
        if type == "births":
            prefix = "b. " if language == ENGLISH else ES["b"]
        elif type == "deaths":
            prefix = "d. " if language == ENGLISH else ES["d"]
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
                id = "displayLanguage",
                name = "English / Español",
                desc = "",
                icon = "hashtag",
                default = ENGLISH,
                options = [
                    schema.Option(
                        display = "English",
                        value = "en",
                    ),
                    schema.Option(
                        display = "Español",
                        value = "es",
                    ),
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "displayLanguage",
                handler = includeOptions,
            ),
        ],
    )

def includeOptions(language):
    if language == ENGLISH:
        return [
            schema.Toggle(
                id = "incl_births",
                name = "Include Births",
                desc = "Include random person who was born on this day.",
                icon = "baby",
                default = True,
            ),
            schema.Toggle(
                id = "incl_deaths",
                name = "Include Deaths",
                desc = "Include random person who died on this day.",
                icon = "bookSkull",
                default = True,
            ),
        ]
    else:
        return [
            schema.Toggle(
                id = "incl_births",
                name = ES["Include Births"],
                desc = ES["Include random person who was born on this day."],
                icon = "baby",
                default = True,
            ),
            schema.Toggle(
                id = "incl_deaths",
                name = ES["Include Deaths"],
                desc = ES["Include random person who died on this day."],
                icon = "bookSkull",
                default = True,
            ),
        ]

def getData(config):
    # go get the data
    url = "https://api.wikimedia.org/feed/v1/wikipedia/{}/onthisday/all/".format(config.get("displayLanguage", ENGLISH)) + time.now().in_location(config.get("$tz", DEFAULT_TIMEZONE)).format("1/2")
    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return -1, "wikipedia error " + str(response.status_code)
    else:
        json_data = response.json()

    return 0, json_data

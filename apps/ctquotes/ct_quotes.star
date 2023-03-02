"""
Applet: CT Quotes
Summary: Quotes from Chrono Trigger
Description: Displays random quotes and animations from the classic RPG Chrono Trigger.
Author: Jessica Chappell
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

QUOTE_FILE_VERSION = 1

# For debugging / development / adding new quotes, download the quotes file
# from github, then just use `python3 -m http.server 8088` from the path you
# saved it to serve the quote file locally, then use this instead of the github link.
# QUOTE_FILE = "http://127.0.0.1:8088/quotes_v{}.json".format(str(QUOTE_FILE_VERSION))
QUOTE_FILE = "https://raw.githubusercontent.com/jchappell82/ct-quotes-tidbyt/main/quotes_v{}.json".format(str(QUOTE_FILE_VERSION))
BG_COLOR = "#222"
QUOTE_CACHE_KEY = "ct_quote_data_v{}".format(str(QUOTE_FILE_VERSION))
CACHE_TTL = 86400

# Set these two variables to override the character and/or quote index
# for easy debugging.
DEBUG_CHARACTER = ""
DEBUG_INDEX = None

def load_quotes():
    """Load the quote file from cache or from github."""

    quotes = cache.get("ct_quote_data")

    if not quotes:
        req = http.get(QUOTE_FILE)
        if req.status_code != 200:
            print("Request failed: " + str(req.status_code))
            return {}

        quotes = req.body()
        cache.set(QUOTE_CACHE_KEY, quotes, ttl_seconds = CACHE_TTL)

    return json.decode(quotes)

def get_random_quote(quote_data):
    """Choose and return a quote by flattening the quote data and
    choosing a random entry.
    """
    char_quotes = []

    # If debug is set, pick from those.
    if DEBUG_CHARACTER:
        print("Debug character override: " + DEBUG_CHARACTER)
        char_quotes = quote_data["characters"].get(DEBUG_CHARACTER)
    else:
        # Flatten into a single list to choose randomly from.
        for _, quotes in quote_data.get("characters", {}).items():
            for quote in quotes:
                char_quotes.append(quote)

    idx = random.number(0, len(char_quotes) - 1)
    print("random index {}".format(idx))
    if DEBUG_INDEX != None:
        print("Debug quote index override: " + str(DEBUG_INDEX))
        idx = DEBUG_INDEX
    rand_quote = char_quotes[idx]

    return rand_quote

def main(config):
    random.seed(time.now().unix // 15)
    quote_data = load_quotes()
    anim_speed = 150
    if quote_data:
        current_quote = get_random_quote(quote_data)
        img = current_quote["image"]
        children = [
            render.Image(src = base64.decode(img)),
            render.Marquee(
                height = 32,
                align = "center",
                offset_start = 15,
                offset_end = 32,
                child = render.WrappedText(
                    content = current_quote["text"],
                    align = current_quote.get("align", "left"),
                    width = current_quote.get("text_width", 45),
                    font = current_quote.get("font", "tb-8"),
                ),
                scroll_direction = "vertical",
            ),
        ]
        anim_speed = current_quote["speed"]
    else:
        children = [
            render.Marquee(
                height = 32,
                align = "left",
                child = render.WrappedText(
                    content = "Bummer! Unable to load quote data for version " + str(QUOTE_FILE_VERSION),
                    align = "left",
                    width = 45,
                ),
                scroll_direction = "vertical",
            ),
        ]
    img_position = config.get("img_position", "random")
    print("Img pos is {}".format(img_position))
    if img_position == "random":
        if random.number(0, 1):
            children = reversed(children)
    elif img_position == "right":
        children = reversed(children)

    return render.Root(
        child = render.Box(
            color = BG_COLOR,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
        delay = anim_speed,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "img_position",
                name = "Image Position",
                desc = "Where to display the image relative to the quote",
                icon = "rightLeft",
                default = "random",
                options = [
                    schema.Option(
                        display = "Random",
                        value = "random",
                    ),
                    schema.Option(
                        display = "Left",
                        value = "left",
                    ),
                    schema.Option(
                        display = "Right",
                        value = "right",
                    ),
                ],
            ),
        ],
    )

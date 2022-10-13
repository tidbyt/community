"""
Applet: NES Quotes
Summary: Random NES quotes
Description: Displays random quotes from Nintendo Entertainment System games.
Author: Mark McIntyre
"""

load("render.star", "render")
load("random.star", "random")
load("schema.star", "schema")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/base64.star", "base64")

CSV_ENDPOINT = "https://gist.githubusercontent.com/markmcintyre/b39cf560d7e66bc0b987f809ca4a568f/raw/nes-quotes.csv"
GAME_COL = 0
QUOTE_COL = 1
SPRITE_COL = 2
BG_COLOR = "#333"
ANIMATION_SPEED = 200
CACHE_TTL = 604800

# CREATE SLUG
# -----------
def slug(str):
    result = ""

    for c in str.lower().elems():
        if c.isalnum():
            result += c
        elif c == " ":
            result += "-"

    return c

# GET DATA
# --------
def get_data():
    # Check our cache
    nes_quotes = cache.get("nes_quotes")

    # If we don't have a cached version, fetch the data now
    if nes_quotes == None:
        request = http.get(CSV_ENDPOINT)
        if request.status_code != 200:
            print("Unexpected status code: " + request.status_code)
            return []

        nes_quotes = request.body()
        cache.set("nes_quotes", nes_quotes, ttl_seconds = CACHE_TTL)

    # Return our quotes, except for the header line
    return csv.read_all(nes_quotes, skip = 1)

# GET LIST OF GAMES
# -----------------
def get_games(data):
    result = []

    for index in range(0, len(data)):
        game = data[index][GAME_COL]
        if not game in result:
            result.append(game)

    return result

# FILTER_DATA
# -----------
def filter_data(config, data):
    result = []
    for index in range(0, len(data)):
        gameid = slug(data[index][GAME_COL])

        if config.bool(gameid, True):
            result.append(data[index])

    return result

# MAIN
# ----
def main(config):
    nes_quotes = filter_data(config, get_data())
    sprite_position = config.str("sprite_position", "random")

    # If there are no quotes, skip rendering
    if len(nes_quotes) <= 0:
        return []

    # Randomly grab a quote and layout its sprite and quote as wrapped text
    index = random.number(0, len(nes_quotes) - 1)
    children = [
        render.Image(src = base64.decode(nes_quotes[index][SPRITE_COL])),
        render.Marquee(
            height = 32,
            align = "center",
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(
                content = nes_quotes[index][QUOTE_COL],
                align = "center",
                width = 45,
            ),
            scroll_direction = "vertical",
        ),
    ]

    # If the user prefers the image on the right, or if the position is random, swap the order
    if sprite_position == "right" or (sprite_position == "random" and random.number(0, 1)):
        children = reversed(children)

    # Render our quote with a 200ms animation rate
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
        delay = ANIMATION_SPEED,
    )

# SCHEMA
# ------
def get_schema():
    games = get_games(get_data())

    fields = [
        schema.Dropdown(
            id = "sprite_position",
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
    ]

    for index in range(0, len(games)):
        fields.append(
            schema.Toggle(
                id = slug(games[index]),
                name = games[index],
                desc = "Show quotes from " + games[index],
                icon = "gamepad",
                default = True,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

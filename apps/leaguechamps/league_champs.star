"""
Applet: League Champs
Summary: Display league characters
Description: Shows league of legends champsions and their subtitle.
Author: xl0lli
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/csv.star", "csv")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL = 604800
CSV_ENDPOINT = "https://gist.githubusercontent.com/xl0lli/bc6755ee77e52a9dcd481e75c95c74b6/raw/ac2c83cc874b2dbbe8f9449a8cef1df4ff8bedb4/league_champ_data"
ANITMATION_SPEED = 200

def main(config):
    random.seed(time.now().unix // 15)
    sprite_position = config.str("sprite_position", "random")

    #open csv file
    league_champs = filter_data(config, get_data())

    #choose random line for number of champions
    index = random.number(0, len(league_champs) - 1)

    children = [
        render.Image(src = base64.decode(league_champs[index][1]), width = 24, height = 32),
        render.Marquee(
            height = 32,
            width = 40,
            align = "center",
            offset_start = 0,
            offset_end = 64,
            child = render.WrappedText(
                content = league_champs[index][2].upper(),
                align = "center",
                width = 40,
                font = "5x8",
                color = "#fd4",
            ),
            scroll_direction = "vertical",
        ),
    ]

    # If the user prefers the image on the right, or if the position is random, swap the order
    if sprite_position == "right" or (sprite_position == "random" and random.number(0, 1)):
        children = reversed(children)

    return render.Root(
        child = render.Box(
            #color = "#444",
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
        delay = ANITMATION_SPEED,
    )

def get_data():
    # Check our cache
    league_champs = cache.get("league_champs")

    # If we don't have a cached version, fetch the data now
    if league_champs == None:
        request = http.get(CSV_ENDPOINT)
        if request.status_code != 200:
            print("Unexpected status code: " + request.status_code)
            return []

        league_champs = request.body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("league_champs", league_champs, ttl_seconds = CACHE_TTL)

    # Return our quotes, except for the header line
    return csv.read_all(league_champs, skip = 1)

# SCHEMA
# ------
def get_schema():
    champs = get_champs(get_data())

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

    for index in range(0, len(champs)):
        fields.append(
            schema.Toggle(
                id = champs[index],
                name = champs[index],
                desc = "Show champion " + champs[index],
                icon = "gamepad",
                default = True,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

# FILTER_DATA
# -----------
def filter_data(config, data):
    result = []
    for index in range(0, len(data)):
        champ = data[index][0]

        if config.bool(champ, True):
            result.append(data[index])

    return result

def get_champs(data):
    result = []

    for index in range(0, len(data)):
        champ = data[index][0]
        if not champ in result:
            result.append(champ)

    return result

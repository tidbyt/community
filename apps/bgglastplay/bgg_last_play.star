"""
Applet: BGG Last Play
Summary: Days since last bgg play
Description: Counts up the number of days since the last time the given user has recorded a game play on Board Game Geek.
Author: DanDobrick
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

EXAMPLE_USERNAME = "zefquaavius"  # User named from the API docs, luckily has lots of recent plays
BGG_PLAYS_API_URL = "https://boardgamegeek.com/xmlapi2/plays?username={}"
BGG_THING_API_URL = "https://boardgamegeek.com/xmlapi2/thing?id={}"
DEFAULT_TIMEZONE = "America/New_York"
DEMO_GAME_ID = 13
DEMO_GAME_NAME = "Catan"
HTTP_CACHE_TTL = 3 * 60 * 60  # 3 hours
# Used for fetching game images, which are cached for longer
HTTP_CACHE_TTL_LONG = 72 * 60 * 60  # 72 hours

def main(config):
    bgg_username = config.str("bgg_username")

    if (bgg_username == None or bgg_username == ""):
        return demo(config)

    last_play_data = get_last_play_data(bgg_username)
    last_play_date = last_play_data.query("//plays/play/@date")

    if last_play_date == None:
        return render.Root(child = error_message())
    else:
        last_play_id = last_play_data.query("//plays/play/item/@objectid")
        last_play_game = last_play_data.query("//plays/play/item/@name")
        game_image = get_image(last_play_id)

        if game_image == None:
            game_image = ""

        return render_main(config, game_image, last_play_date, last_play_game)

def get_last_play_data(bgg_username):
    encoded_username = humanize.url_encode(bgg_username)
    resp = http.get(BGG_PLAYS_API_URL.format(encoded_username), ttl_seconds = HTTP_CACHE_TTL)

    if resp.status_code == 200:
        return xpath.loads(resp.body())
    else:
        return None

def get_image(game_id):
    if game_id == None:
        game_id = DEMO_GAME_ID

    resp = http.get(BGG_THING_API_URL.format(game_id), ttl_seconds = HTTP_CACHE_TTL_LONG)

    if resp.status_code == 200:
        xml_content = xpath.loads(resp.body())
        image_url = xml_content.query("//item/image")

        response = http.get(image_url, ttl_seconds = HTTP_CACHE_TTL_LONG)
        return response.body()
    else:
        return None

def num_days_since(last_play_date, timezone):
    current_time = time.now().in_location(timezone)
    parsed_last_play = time.parse_time(last_play_date, format = "2006-01-02")
    date_diff = current_time - parsed_last_play

    return math.floor(date_diff.hours // 24)

def build_days_since_str(last_play_date, timezone):
    if last_play_date == None:
        return "No plays found"
    else:
        days_since = num_days_since(last_play_date, timezone)

        if days_since == 1:
            return "1 day since"
        else:
            return "{} days since".format(days_since)

def build_last_play(config, last_play_date, last_play_game):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    label_choice = config.get("label")
    days_since_str = build_days_since_str(last_play_date, timezone)

    children = [
        render.Box(
            color = "#0000FF00",
            height = 1,
        ),
    ]

    if label_choice == "last_play_label":
        children.append(
            render.Padding(
                pad = (1, 1, 5, 0),
                color = "#00000099",
                child = render.WrappedText("Last Play:"),
            ),
        )
    elif label_choice == "days_since_last_play":
        children.append(
            render.Padding(
                pad = (1, 1, 1, 0),
                color = "#00000099",
                child = render.WrappedText(days_since_str),
            ),
        )

    children.append(
        render.Padding(
            pad = (1, 1, 0, 0),
            color = "#00000099",
            child = render.WrappedText(last_play_game),
        ),
    )

    return children

def render_main(config, game_image, last_play_date, last_play_game):
    return render.Root(
        child = render.Stack(
            children = [
                render.Image(
                    height = 35,
                    width = 35,
                    src = game_image,
                ),
                render.Box(
                    color = "#00FF0000",
                    child = render.Padding(
                        pad = (0, 0, 0, 0),
                        color = "#FF000000",
                        child = render.Column(
                            cross_align = "end",
                            main_align = "start",
                            expanded = False,
                            children = build_last_play(config, last_play_date, last_play_game),
                        ),
                    ),
                ),
            ],
        ),
    )

def demo(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    yesterday_long = time.now().in_location(timezone) - time.parse_duration("86400s")
    yesterday = yesterday_long.format("2006-01-02")
    game_image = get_image(DEMO_GAME_ID)

    return render_main(config, game_image, yesterday, DEMO_GAME_NAME)

def error_message():
    return render.WrappedText(content = "Error fetching data", align = "center", font = "5x8", color = "#FF0000")

def get_schema():
    label_options = [
        schema.Option(
            display = "None",
            value = "none",
        ),
        schema.Option(
            display = "Days since last play",
            value = "days_since_last_play",
        ),
        schema.Option(
            display = "\"Last Play:\"",
            value = "last_play_label",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bgg_username",
                name = "BoardGameGeek username",
                desc = "BoardGameGeek username to use for fetching last play date",
                icon = "user",
            ),
            schema.Dropdown(
                id = "label",
                name = "Label",
                desc = "Label to display above the game name",
                default = label_options[0].value,
                icon = "tag",
                options = label_options,
            ),
        ],
    )

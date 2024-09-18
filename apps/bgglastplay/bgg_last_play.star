"""
Applet: BGG Last Play
Summary: Days since last bgg play
Description: Counts up the number of days since the last time the given user has recorded a game play on Board Game Geek.
Author: DanDobrick
"""

load("http.star", "http")
load("xpath.star", "xpath")
load("humanize.star", "humanize")
load("time.star", "time")
load("math.star", "math")
load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

EXAMPLE_USERNAME = "zefquaavius"  # User named from the API docs, luckily has lots of recent plays
BGG_PLAYS_API_URL = "https://boardgamegeek.com/xmlapi2/plays?username={}"
DEFAULT_TIMEZONE = "America/New_York"
HTTP_CACHE_TTL = 3 * 60 * 60  # 3 hours

def main(config):
    bgg_username = config.str("bgg_username", EXAMPLE_USERNAME)
    last_play_date = get_last_play_date(bgg_username)
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Days Since Last Play",
                            font = "5x8",
                            color = "#FFA500",
                            width = 64,
                            align = "center",
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    children = last_play_date_children(last_play_date, timezone),
                ),
            ],
        ),
    )

def get_last_play_date(bgg_username):
    encoded_username = humanize.url_encode(bgg_username)
    resp = http.get(BGG_PLAYS_API_URL.format(encoded_username), ttl_seconds = HTTP_CACHE_TTL)

    if resp.status_code == 200:
        xml_content = xpath.loads(resp.body())

        return xml_content.query("//plays/play/@date")
    else:
        return None

def num_days_since(last_play_date, timezone):
    current_time = time.now().in_location(timezone)
    parsed_last_play = time.parse_time(last_play_date, format = "2006-01-02")
    date_diff = current_time - parsed_last_play

    return math.floor(date_diff.hours // 24)

def last_play_date_children(last_play_date, timezone):
    if last_play_date == None:
        font = "5x8"

        return [render.WrappedText(content = "No Plays found", font = font)]
    else:
        days_since_last_play = num_days_since(last_play_date, timezone)
        font = "6x13" if days_since_last_play < 100 else "5x8"
        return [render.Text(str(days_since_last_play), font = font)]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bgg_username",
                name = "BoardGameGeek username",
                desc = "BoardGameGeek username to use for fetching last play date",
                icon = "user",
            ),
        ],
    )

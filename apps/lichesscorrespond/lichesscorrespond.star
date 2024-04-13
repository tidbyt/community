"""
Applet: LichessCorrespond
Summary: Shows correspondence games
Description: Shows active correspondence games currently waiting on you for a move.
Author: Denton-L
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SAMPLE_RESPONSE = """
{
  "nowPlaying": [
    {
      "gameId": "rCRw1AuO",
      "fullId": "rCRw1AuOvonq",
      "color": "black",
      "fen": "r1bqkbnr/pppp2pp/2n1pp2/8/8/3PP3/PPPB1PPP/RN1QKBNR w KQkq - 2 4",
      "hasMoved": false,
      "isMyTurn": true,
      "lastMove": "b8c6",
      "opponent": {
        "id": "philippe",
        "rating": 1790,
        "username": "Philippe"
      },
      "perf": "correspondence",
      "rated": false,
      "secondsLeft": 1209600,
      "source": "friend",
      "speed": "correspondence",
      "variant": {
        "key": "standard",
        "name": "Standard"
      }
    }
  ]
}
"""

LICHESS_HOST = "https://lichess.org"
TTL_SECONDS = 60

WIDTH = 64

WARNING_SECONDS_LEFT = 60 * 60 * 6
CRITICAL_SECONDS_LEFT = 60 * 60 * 1

BIG_FONT = "tb-8"
BIG_FONT_HEIGHT = 8

SMALL_FONT = "tom-thumb"
SMALL_FONT_WIDTH = 4

def render_row(game, config):
    opponent = "%s (%s)" % (game["opponent"]["username"], int(game["opponent"]["rating"]))

    seconds_left = int(game["secondsLeft"])

    move_deadline = config.now + time.second * seconds_left
    remaining_time = humanize.relative_time(config.now, move_deadline)

    time_color = "#FFFFFF"
    if config.critical_minutes and seconds_left < config.critical_minutes * 60:
        time_color = "#FF0000"
    elif config.warning_minutes and seconds_left < config.warning_minutes * 60:
        time_color = "#FFFF00"

    return render.Column([
        render.Marquee(render.Text(opponent, font = SMALL_FONT), width = WIDTH),
        render.Text(remaining_time, font = SMALL_FONT, color = time_color),
    ])

def safe_int(s):
    if not s:
        return None

    for i in range(len(s)):
        if s[i] in "0123456789":
            continue
        if i == 0 and s[i] == "-":
            continue
        return None

    return int(s)

def main(config):
    token = config.get("token")
    render_config = struct(
        now = time.now(),
        warning_minutes = safe_int(config.get("warning_minutes")),
        critical_minutes = safe_int(config.get("critical_minutes")),
    )

    data = json.decode(SAMPLE_RESPONSE)
    if token:
        res = http.get(
            LICHESS_HOST + "/api/account/playing",
            headers = {
                "Authorization": "Bearer " + token,
            },
            ttl_seconds = TTL_SECONDS,
        )
        if res.status_code != 200:
            return []
        data = res.json()

    now_playing = data["nowPlaying"]

    my_turn_correspondence = [
        game
        for game in now_playing
        if game["speed"] == "correspondence" and game["isMyTurn"]
    ]

    if not my_turn_correspondence:
        return []

    return render.Root(
        render.Column(
            [render.Box(render.Text("Lichess Games", font = BIG_FONT), width = WIDTH, height = BIG_FONT_HEIGHT)] +
            [render_row(game, render_config) for game in my_turn_correspondence],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # this should be OAuth2 but pixlet isn't currently capable:
            # https://github.com/tidbyt/pixlet/issues/991
            schema.Text(
                id = "token",
                name = "Lichess Token",
                desc = "Navigate to https://lichess.org/account/oauth/token/create?description=Tidbyt+Lichess+Correspond, generate a token and paste it here.",
                icon = "key",
            ),
            schema.Text(
                id = "warning_minutes",
                name = "Minutes Remaining Warning",
                desc = "Minutes remaining before displaying time in a warning color (leave blank to disable this)",
                default = "360",
                icon = "exclamation",
            ),
            schema.Text(
                id = "critical_minutes",
                name = "Minutes Remaining Critical",
                desc = "Minutes remaining before displaying time in a critical color (leave blank to disable this)",
                default = "60",
                icon = "xmark",
            ),
        ],
    )

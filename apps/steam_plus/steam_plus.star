"""
Applet: Steam Plus
Summary: Show Steam user status
Description: Shows Steam user avatar, name, status, and currently playing.
Author: Mike Toscano
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

STEAM_LOGO_PATH = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/7a48ed11-13b2-44e3-a982-8d763d500a3e/db6u02a-edde930a-c504-4284-a0ce-bc88e4ba15b2.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzdhNDhlZDExLTEzYjItNDRlMy1hOTgyLThkNzYzZDUwMGEzZVwvZGI2dTAyYS1lZGRlOTMwYS1jNTA0LTQyODQtYTBjZS1iYzg4ZTRiYTE1YjIucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.bH5kQSIO2Fp1YhXcwTgqQCG-n0HADfWmtPIdqxaF_ZI"
STATUS = ["Offline", "Online", "Busy", "Away"]
STATUS_COLOR = ["#59707B", "#0a0", "#F67407", "#FFD100"]

STEAM_LOGO = http.get(STEAM_LOGO_PATH).body()

def main(config):
    #
    api_key = secret.decrypt("AV6+xWcEJR5qELPaYxK0mTVpgPRRvSvB55VTzrvxgmXi94p9HmJxDHFeJWyTr3yrfegS9hGmu4kS/3Eqx75URHFhvScaAJG9azvs9LAHcu/xNt7bXRzgUKYksXtpw/90gD+hOqtEX9hsOnJ+obsMN6UayvQ28PAkIwLU7dIC0AlmnxrMVI0=") or config.get("dev_api_key") or ""

    STEAM_API_ENDPOINT = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" + api_key + "&steamids="
    STEAM_GAMES_ENDPOINT = "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=" + api_key + "&steamid="

    resp = http.get(STEAM_API_ENDPOINT + config.str("id", "") or "76561197998958802", ttl_seconds = 180)

    players = {}
    if resp.status_code == 200:
        players = resp.json()["response"]["players"]

    username = "Cannot find the specified user"
    avatar = STEAM_LOGO
    currently_playing_logo = STEAM_LOGO
    currently_playing = ""
    status = ""
    persona_state = 0

    user = {}
    if len(players) > 0:
        user = players[0]

        username = user["personaname"]

        currently_playing = user["gameextrainfo"] if "gameextrainfo" in user else config.str("offlineStatus", "Just Chilling") or "Just Chilling"
        avatar = http.get(user["avatarfull"], ttl_seconds = 600).body()
        status = STATUS[int(user["personastate"])]
        currently_playing_game_id = user["gameid"] if "gameid" in user else ""
        currently_playing_logo = http.get(STEAM_LOGO_PATH).body()
        persona_state = int(user["personastate"])
        user_games = {}

        user_games_resp = http.get(STEAM_GAMES_ENDPOINT + config.str("id", "") + "&include_appinfo=true&format=json", ttl_seconds = 180)

        if user_games_resp.status_code == 200:
            user_games = user_games_resp.json()["response"]["games"]

        for game in user_games:
            if len(currently_playing_game_id) > 0 and int(game["appid"]) == int(currently_playing_game_id):
                currently_playing_logo = http.get("https://media.steampowered.com/steamcommunity/public/images/apps/" + currently_playing_game_id + "/" + game["img_icon_url"] + ".jpg").body()
                break

    return render.Root(
        delay = 90,
        child = render.Box(
            height = 32,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "center",  # Controls vertical alignment
                        children = player_icon_row(config.bool("playerIconRight", False), avatar, username, status, persona_state),
                    ),
                    render.Row(
                        expanded = True,  # Use as much horizontal space as possible
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "end",  # Controls vertical alignment
                        children = game_icon_row(config.bool("gameIconRight", False), currently_playing_logo, currently_playing),
                    ),
                ],
            ),
        ),
    )

def game_icon_row(image_right, currently_playing_logo, currently_playing):
    iconView = render.Image(
        src = currently_playing_logo,
        width = 16,
        height = 15,
    )

    views = [
        # render.Text(content=currently_playing, font="tb-8", height=16, offset=4),
        render.Marquee(
            width = 48,
            child = render.Text(content = " " + currently_playing, font = "tb-8", height = 16, offset = 4),
            offset_start = 0,
            offset_end = 0,
            align = "end" if image_right else "start",
        ),
    ]

    if image_right:
        views.append(iconView)
    else:
        views.insert(0, iconView)

    return views

def player_icon_row(image_right, avatar, username, status, persona_state):
    iconView = render.Image(
        src = avatar,
        width = 16,
        height = 16,
    )

    views = [
        render.Column(
            children = [
                render.Marquee(
                    width = 48,
                    height = 8,
                    child = render.Text(content = username, font = "tb-8"),
                    offset_start = 0,
                    offset_end = 0,
                    align = "end" if image_right else "start",
                ),
                render.Marquee(
                    child = render.Text(content = status, font = "tb-8", color = STATUS_COLOR[persona_state]),
                    offset_start = 0,
                    offset_end = 0,
                    width = 48,
                    height = 8,
                    align = "end" if image_right else "start",
                ),
            ],
        ),
    ]

    if image_right:
        views.append(iconView)
    else:
        views.insert(0, iconView)

    return views

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "id",
                name = "Steam ID",
                desc = "17 digit Steam ID",
                icon = "user",
                default = "76561197998958802",  # Mike's account ID
            ),
            schema.Text(
                id = "offlineStatus",
                name = "Offline Status",
                desc = "Message displayed when you are offline",
                icon = "comment",
            ),
            schema.Toggle(
                id = "playerIconRight",
                name = "Player icon right",
                desc = "Show the player icon on the right side",
                icon = "rightToBracket",
            ),
            schema.Toggle(
                id = "gameIconRight",
                name = "Game icon right",
                desc = "Show the game icon on the right side",
                icon = "rightToBracket",
            ),
        ],
    )

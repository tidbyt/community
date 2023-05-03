"""
Applet: Steam
Summary: Steam Now Playing
Description: Displays the game that the specified user is currently playing, or the most recent games if currently not in-game.
Author: Jeremy Tavener
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

CACHE_TTL_SECONDS = 300
API_BASE_URL = "http://api.steampowered.com/"
API_PLAYER_SUMMARIES = API_BASE_URL + "ISteamUser/GetPlayerSummaries/v0002"
API_RECENTLY_PLAYED_GAMES = API_BASE_URL + "IPlayerService/GetRecentlyPlayedGames/v0001"
API_OWNED_GAMES = API_BASE_URL + "IPlayerService/GetOwnedGames/v0001"

def main(config):
    steam_id = config.get("steam_id", None)
    api_key = secret.decrypt("""
        AV6+xWcE9acn7G/Amrp+rzPaSppKSmwWdVBJklcT6q63X9wG8UFn0ma1U9oCtmwjzVyZFF1JzzpLre2K
        mVuRNN+Lk7UICOvuChgDC6pstPv9ecAHFGu9h9C7kc3ntBcbUARJIVWXZVH2ji+PtIis/jekWarIgISt
        qukjL49KF/GT3BtMwJ4=
        """) or config.get("dev_api_key")

    if steam_id == None or api_key == None:
        return do_render(DEMO_DATA["player_name"], DEMO_DATA["main_icon"], DEMO_DATA["game_string"])

    # Is the user currently playing a game?
    # Note - this will only return if their profile is set to show this information publically
    resp = http.get(API_PLAYER_SUMMARIES, params = {"key": api_key, "steamids": steam_id})

    if resp.status_code != 200:
        return display_failure("Failed to get the current player summary with code {}".format(resp.status_code))

    if len(resp.json()["response"]["players"]) != 1:
        return display_failure("Failed to find player with SteamID {}".format(steam_id))

    if resp.json()["response"]["players"][0]["communityvisibilitystate"] != 3:
        return display_failure("Profile is not public, can't get current game")

    player_name = resp.json()["response"]["players"][0]["personaname"]

    if "gameextrainfo" in resp.json()["response"]["players"][0].keys():
        game_string = "Now Playing: " + resp.json()["response"]["players"][0]["gameextrainfo"]
        current_game_id = resp.json()["response"]["players"][0]["gameid"]

        key = steam_id + "_" + current_game_id
        steam_game_icon_cached = cache.get(key)

        if steam_game_icon_cached != None:
            main_icon = base64.decode(steam_game_icon_cached)
        else:
            # Grab the game Icon - this is groooooosss
            json_blob = json.encode({"steamid": steam_id, "include_appinfo": True, "appids_filter": [current_game_id]})

            resp = http.get(API_OWNED_GAMES, params = {"key": api_key, "input_json": str(json_blob)})

            if resp.status_code != 200:
                return display_failure("Failed to get the current game icon with code {}".format(resp.status_code))

            if resp.json()["response"]["game_count"] == 1:
                game_icon_hash = resp.json()["response"]["games"][0]["img_icon_url"]
                game_icon_url = "http://media.steampowered.com/steamcommunity/public/images/apps/" + str(current_game_id) + "/" + game_icon_hash + ".jpg"
                main_icon = http.get(game_icon_url).body()
                icon_encoded = base64.encode(main_icon)
                cache.set(key, icon_encoded, ttl_seconds = CACHE_TTL_SECONDS)
            else:
                main_icon = STEAM_ICON

    else:
        # There's no current game - get a list of previously played to display.
        resp = http.get(API_RECENTLY_PLAYED_GAMES, params = {"key": api_key, "steamid": steam_id})

        game_string = ""

        # Just display a blank string if we can't find the game list.
        if resp.status_code == 200:
            if (resp.json()["response"]["total_count"] > 0):
                for game in resp.json()["response"]["games"]:
                    game_string = game_string + "   " + game["name"]

        main_icon = STEAM_ICON

    return do_render(player_name, main_icon, game_string)

def do_render(player_name, main_icon, game_string):
    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            child = render.Image(
                                src = main_icon,
                                height = 20,
                                width = 20,
                            ),
                            width = 20,
                            height = 20,
                            padding = 2,
                        ),
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = player_name,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(
                        content = game_string,
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "steam_id",
                name = "Steam ID",
                desc = "Your 17 digit Steam ID (use https://steamid.xyz/ if you're unsure)",
                icon = "user",
            ),
        ],
    )

def display_failure(msg):
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

STEAM_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AA
AdTAAAOpgAAA6mAAAF3CculE8AAACl1BMVEUIGTYJGjUKGjQLGzQOHjYMHDUKGjYIGTcHGTgGGDohMU4MHToIGjoHGToJGD4rO1
kKHD4HGT4PIUQ9a5UUSXwbV4k0ZpAVTX4UUYQUWIsWXpAoZZMUVogTXI8TWIsTXpEUY5UVaZsXbZ8Ta50TaJoTYpUUHywPHS4QH
C8PGy4NGi0KFSUMGjMCESoIGTUACSkFFzkACCsEFjcAAB4CFD0AEDoAADEDFUP///8UMWWGm7YTPXIAAAAWU4kAPngUVYgHV4wT
X5MKZ5sTbqAEhbkQfrARgLITgbMTgLITjr8QHC8NGzIMGzILGjIIFy8BESoADSYAESkIGTUHGTUGFzQAEC8AAB8ACCcVJkEAEjA
AASAFGDkFFzoEFzkAETQAACI/T2jv8vT8/P75+/tveo4AAicHGT0HGT4EFjwABS8SJEb///+Xnq6Pl6eDjJ9LWXMAASoGGEEHGU
IBEz0AACVncovLzti3vMnx8/Wgpbe9ws0AAC0ADDwBE0MGF0YFFkUACDkAACzW2OG8wc6ttMPx8vSgprjBxNAAADBTYYIAFEYAA
DQABjwACT9vfJdwepaEjaeDjaVWY4UACD0JHk7+/v+Ll68TLV4ACEM5Tnj7+fn39vh7iKMAD0YGHlIPKFnx8ve6w9O/yNXb3ucx
S3gBH1cAFE0GJFsRLmLM1uCIm7Xh5euVp78AIVwAG1YDLWUNNmoROm8TPXEALmgyX4vd4+u1xNWFnrkAKWQAM2wNQncSRnoUSHs
USXwAN3IyaZW4x9iovNClus1Rf6UAQHgPToITUoUUU4YUVIcUVYgAUYknbJtXjbE0dKAAUIYLWY4RXZETX5ITYJMTYZQFZZsAYp
gEZJoNaZ4RbqATb6ETcKISgbMTgrSzuH3PAAAASnRSTlMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABuc6
OecHZ6ezs6enh0dmprm5ujmnJodHZ6ezs6enhuc6OicHWEsZ/kAAAABYktHRDigB6XWAAAAB3RJTUUH5gEEFRcyaXJYVQAAARtJ
REFUGNMBEAHv/gAAAQIDJicoSkopKisEBQYHAAgHCSxLS0xNTk9QUS0KCwwADQ4uUlJTVFVWV1hZWi8PEAARMFtcXF1eX2BhYmN
kZTESADJmZmdmaGlqa2xtbmtvcDMANHFycnJzdHV2d2t4eXp7NQA2fH1+f4CBgoOEa4WGh4g3AImKi4yNe45ra4+QkWuSk5QAa5
WWl5iZa2tra5qbnJ2enwA4a2troKGia2ujpKWmp6g5ADqpa2tra6qrrK2ur7CxsjsAPLO0tWtrtre4ubq7vL28PQATPr6/wMHCw
8TFxsfIyT8UABUWQMrLzM3Oz9DR0tNBFxgAGRobQtTV1tfY2draQxwdHgAfICEiREVG29xHSEkjJCUf8a5tU2W6fcMAAAAldEVY
dGRhdGU6Y3JlYXRlADIwMjItMDEtMDRUMjE6MjM6NDkrMDA6MDC/bjduAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIyLTAxLTA0VDI
xOjIzOjQ5KzAwOjAwzjOP0gAAAABJRU5ErkJggg==
""")

DEMO_DATA = {
    "player_name": "Demo Player",
    "game_string": "Farcry 5   Goldeneye 007   Half-Life 2   Halo Infinite",
    "main_icon": STEAM_ICON,
}

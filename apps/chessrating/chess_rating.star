"""
Applet: Chess Rating
Summary: Ratings from Chess.com
Description: Show your Rapid, Blitz and Bullet Ratings from Chess.com.
Author: NickAlvesX
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

# Get player ID profile
def get_player_profile(username):
    profile_url = "https://api.chess.com/pub/player/{}/stats".format(username)
    req = http.get(profile_url)
    if req.status_code != 200:
        return False

    results = req.json()
    if results:
        return results
    else:
        return False

def main(config):
    username = config.get("username", "")
    profile_json = get_player_profile(username)

    rapid = 0
    blitz = 0
    bullet = 0

    if profile_json != False:
        rapid = profile_json["chess_rapid"]["last"]["rating"]
        blitz = profile_json["chess_blitz"]["last"]["rating"]
        bullet = profile_json["chess_bullet"]["last"]["rating"]

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Text("Rapid: %d" % rapid),
                render.Text("Blitz: %d" % blitz),
                render.Text("Bullet: %d" % bullet),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Chess.com Username to use",
                icon = "user",
            ),
        ],
    )

"""
Applet: Chess Rating
Summary: Ratings from Chess.com
Description: Show your Rapid, Blitz and Bullet Ratings from Chess.com.
Author: NickAlvesX
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

BLITZ_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAMAAADz0U65AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAnFBMVEX/vwD/xgD/eQD/xAD/zgD/1QD/wQD//wD/wAD/ygD/xwD/AAD/zAD/zQD/2AAAAAD/yQD/yAD/xgD/zgD/zwD/zwD/yQD/zQD/0wD/0gD/ywD/0QD/0gD/ywD/nQD/ygD/0gD/0gD/zwD/xgD/yAD/zQD/0wD/1AD/zwD/zQD/0gD/zgD/zwD/tQD/wAD/xwD/xwD/1AD/1QD///99XzLLAAAAMXRSTlMAAAAAAAAAAAAAAAAAAAAAAAAHVWlrPTjr0TWQ20IBI9zloR0YZObxWTfmcX0DBk4N2rmr0QAAAAFiS0dEMzfVfF4AAAAHdElNRQfmCgcCOxj39NEnAAAAS0lEQVQI1wXBBQKAIAAEsEMsMLC7u+v/j3MDiOcHYSSBynHyppkCVcu/oqx0sLr52q7nYMM4zYtBYFrrFmiUQrf34+REANf9OK4QP7yMBYpT4g9NAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTEwLTA3VDAyOjU5OjE5KzAwOjAwDn4bzwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0xMC0wN1QwMjo1OToxOSswMDowMH8jo3MAAAAASUVORK5CYII=""")
BULLET_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAABmJLR0QA/wD/AP+gvaeTAAAAx0lEQVQYlW3OsU7CYBiF4ff7E1uNxIUuXR1MTJy8A3e4AAevoFfQ2Yk7cGTApYPGwRAuwqQMBlJMiAEJiWkDCv2j2H4uMEA42zlneWBPNMLZt9OKT2tpcj3WYaj6ct4HkM15H5/duAeV5lfek7rxxRP3Ry57hwYginBKbDNdds1vaeVxNdSPIn8GMKqYsUc3GYxWqgXFH2Sfap8W7wGAEaFEuKOgfHsl/54xPz7hIrhiugVstAlvH+jswjfIKuADR+tugQmQ/QPsF0oFvSVUsAAAAABJRU5ErkJggg==""")
RAPID_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAABmJLR0QA/wD/AP+gvaeTAAAA+0lEQVQYlT3PP0sCYQDA4d97f7ykjkQKi46gCxpchDoatOB0Sb9AX6FvII63Rh/ImhQMG8QGl0IQFbIihCJNvdfzriVan+0RAK5X0zJWqqJrXABIf3XbeRtf1718IFyvpp0d7taz6WTu5GADgObTmPZw0bjvjgpaxkpVsulkrnS8DUBv+Ep6R2CsJc4nP35Z0VVRdGwTgM/vKd3BiCPbwrFNDCNWVIRQwiiKABBCIOUSuQwI/0zxfXnX7k8BSJjrlNxTZvMFj/0JCxlU1bhz+RBFekHKcH8zrjCXIa3ejObzV6M1eL8S/829rXJMU4sA/iqqdl4+bupePvgF8exkafjOZFYAAAAASUVORK5CYII=""")

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

    horizontal_divider = render.Box(height = 1, color = "#555")

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
                render.Row(
                    children = [
                        render.Image(src = BLITZ_ICON),
                        render.Text(content = "Blitz: %d" % blitz, color = "#FFD502"),
                    ],
                ),
                horizontal_divider,
                render.Row(
                    children = [
                        render.Image(BULLET_ICON),
                        render.Text(content = "Bullet: %d" % bullet, color = "#8EB900"),
                    ],
                ),
                horizontal_divider,
                render.Row(
                    children = [
                        render.Padding(
                            child = render.Image(
                                src = RAPID_ICON,
                                width = 6,
                                height = 6,
                            ),
                            pad = 1,
                        ),
                        render.Text(content = "Rapid: %d" % rapid, color = "#AEC3DD"),
                    ],
                ),
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

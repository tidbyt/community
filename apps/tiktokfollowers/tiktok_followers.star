"""
Applet: TikTok Followers
Summary: TikTok follower counter
Description: Shows the follower count for a configured public TikTok account.
Author: elclaudioabierto
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

TIKTOK_PINK = "#FE2C55"
TIKTOK_CYAN = "#25F4EE"
BACKGROUND = "#080808"

def _compact_count(value):
    count = int(value)
    if count >= 1000000000:
        return _scaled_count(count, 1000000000, "B")
    if count >= 1000000:
        return _scaled_count(count, 1000000, "M")
    if count >= 1000:
        return _scaled_count(count, 1000, "K")
    return str(count)

def _scaled_count(count, divisor, suffix):
    whole = count // divisor
    decimal = (count % divisor) * 10 // divisor
    if decimal == 0:
        return "%d%s" % (whole, suffix)
    return "%d.%d%s" % (whole, decimal, suffix)

def _value_after(body, marker, delimiter):
    pieces = body.split(marker, 1)
    if len(pieces) != 2:
        return None
    return pieces[1].split(delimiter, 1)[0]

def _fetch_profile(username):
    response = http.get(
        "https://www.tiktok.com/@" + username,
        headers = {
            "Accept-Language": "en-US,en;q=0.9",
            "User-Agent": "Mozilla/5.0 (compatible; Tidbyt TikTok Followers)",
        },
        ttl_seconds = 3600,
    )
    if response.status_code != 200:
        print("TikTok returned HTTP %d for @%s" % (response.status_code, username))
        return None

    body = response.body()
    count = _value_after(body, '"statsV2":{"followerCount":"', '"')
    if count == None:
        count = _value_after(body, '"stats":{"followerCount":', ",")
    if count == None:
        print("Could not find followerCount for @%s" % username)
        return None
    return int(count)

def _error_screen(username):
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = BACKGROUND,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("TIKTOK", font = "CG-pixel-3x5-mono", color = TIKTOK_PINK),
                    render.Text("NO DATA", font = "tom-thumb", color = "#FFFFFF"),
                    render.Text(("@" + username)[:20], font = "tom-thumb", color = "#B8B8B8"),
                ],
            ),
        ),
    )

def main(config):
    username = config.str("username", "tiktok").strip().lstrip("@")
    follower_count = _fetch_profile(username)
    if follower_count == None:
        return _error_screen(username)

    count = _compact_count(follower_count)
    shown_username = "@" + username

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = BACKGROUND,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Row(
                        main_align = "center",
                        children = [
                            render.Text("♪", font = "tom-thumb", color = TIKTOK_CYAN),
                            render.Text(" TIKTOK", font = "CG-pixel-3x5-mono", color = TIKTOK_PINK),
                        ],
                    ),
                    render.Text(count, font = "6x13", color = "#FFFFFF"),
                    render.Text(shown_username[:20], font = "tom-thumb", color = "#B8B8B8"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "TikTok username",
                desc = "Username without the @ symbol.",
                icon = "at",
                default = "tiktok",
            ),
        ],
    )

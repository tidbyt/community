"""
Applet: Subreddit
Summary: Subreddit post
Description: Display the #1 post of a subreddit.
Author: Petros Fytilis
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SCREEN_WIDTH = 64
STATUS_OK = 200
MAX_DURATION_SECONDS = 60
CACHE_TTL_SECONDS = 300
DEFAULT_SUBREDDIT = "games"

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

REDDIT_API_URL_TEMPLATE = "https://www.reddit.com/r/{}/hot.json?limit=1"

REDDIT_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv
8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAMXSURBVEhLpVVLSJRRGP2nzEdBT9/GWCQaOaRoOfbwMT
4WalhtCixQsxaJRBD0UFpEUBblQiOK2gQpLQxdlFDRohJcRNGiRYsei1pJRS96gHA65793xn/G0UV9c
OD+3//d839z7vnuOAzMjvmozlqGEwXp6A9kuDjOtXJ6F39PBHGSScm4HcwFGlcBNZlAyIOKFcxluO+G
y/xwfPNm7jeITuzNy+ImklZzcyVRRbIwypcAuzcCRQnAOgcoJA5UoSUtKYrDYvrhXAk7rCdBLKGwNZU
dZyMSf34Db1+Z9fdJnPGneEkFs3A7nY1U2LAIuHYWGBwActhpRTrw5aMhVhQ7aFmTGUNMTd2fH0uq5/
KlQEkK4CfZ189AnZ8fWWjy1Wxm6BKwIwBsXu5yOInJ08QjOihpuonFRQtMd8Jakh1sAm70AXcGTWd9x
4BDO4HAPGC9R+sg9SeHDt0S82UTtQ0uBlorgaePgPNHgJMdhmiuuN7Lun3AsydA13bTjLqWFWvoSYSo
VxmJ/zca8ihhKkLyeTcNj6o0o128uDtkF54Yu2UXMbG/nu4xA+VcKaKFpK+0vdlvK2yc7gTSqd/RPTb
BuHzK5DpqbcLG4zGjNbkGOKEk5smKWKfaXGirbDwfpyPomPF7NsF4/dK4JPaXdDWbc+J0usQ9kkKj6g
5Ajq36h2gP0VU6r0xIXqc2mw+6D+RbWefDO1tpo/cw8P6NfWD8+AZ0t9kHT8ia8j25ZAhjt/BwbNEFs
9JW2ngxQakolzYGfEApZbg/bF/a2FVqZkActK443QEZDdIR0lldy+i6Ez5N2l1zxNSUmTr5V3vJoWGz
A+LAl8QuvCOtzvPZYec24OGoGeVw/PoJTDwwTilgjXQNj38Dr1FeDxFioT2fB1dnC8KFuiaLE42NJIW
gc5A15QBvLS+wVnKE+SLEwsXS1dHkMxAnb0kvcK+Xi4h6QHsBO5cs0nzWDxB6p5pGP9qiOw1jRoKaJ5
sD1QfCf00iEbRWrikXI/xr0vnE4yDiJi0SUEef9+Sn4WpxDjT+Wsv7js+11Cxw8Bdaz42o7/df2gAAA
ABJRU5ErkJggg==
""")

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    subreddit = (config.get("subreddit") or DEFAULT_SUBREDDIT).strip()
    is_24h_format = config.bool("is_24h_format", False)

    return render.Root(
        max_age = MAX_DURATION_SECONDS,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        _render_reddit_icon(),
                        render.Column(
                            main_align = "space_evenly",
                            cross_align = "end",
                            children = [
                                _render_clock(timezone, is_24h_format),
                                _render_subreddit(_hyphenate_subreddit(subreddit)),
                            ],
                        ),
                    ],
                ),
                _render_post_title(subreddit),
            ],
        ),
    )

def _hyphenate_subreddit(subreddit):
    label = "/r/" + subreddit

    if len(label) > 10:
        label = label[0:10] + "- " + label[10:]
    if len(label) > 22:
        label = label[0:22] + "- " + label[22:]
    if len(label) > 34:
        label = label[0:31] + "..."

    return label

def _render_reddit_icon():
    return render.Image(src = REDDIT_ICON)

def _render_clock(timezone, is_24h_format):
    now = time.now().in_location(timezone)
    clock_format = "15:04" if is_24h_format else "3:04 PM"
    return render.Animation(
        children =
            [
                render.Text(
                    content = now.format(clock_format if i < 10 else clock_format.replace(":", " ")),
                    font = "tom-thumb",
                )
                for i in range(20)
            ],
    )

def _render_subreddit(subreddit):
    nb_lines = len(subreddit.split())
    height = min(3, nb_lines) * 6
    return render.WrappedText(
        content = subreddit,
        color = "#ff3518",
        font = "tom-thumb",
        height = height,
    )

def _render_post_title(subreddit):
    post_title = _fetch_post_title(subreddit)
    return render.Marquee(
        child = render.Text(
            content = post_title,
            font = "tb-8",
        ),
        offset_start = SCREEN_WIDTH,
        offset_end = SCREEN_WIDTH,
        width = SCREEN_WIDTH,
    )

def _fetch_post_title(subreddit):
    post_title_cached = cache.get(subreddit)
    if post_title_cached != None:
        print("Hit! Displaying cached data for <{}>.".format(subreddit))
        return post_title_cached
    else:
        print("Miss! Calling Reddit API for <{}>.".format(subreddit))
        rep = http.get(
            REDDIT_API_URL_TEMPLATE.format(subreddit),
            headers = {"User-agent": "PostmanRuntime/7.28.4"},
        )
        if rep.status_code != STATUS_OK:
            print("Reddit request failed with status {}.".format(rep.status_code))
            return "Could not retrieve Reddit data"
        post_title = _parse_post_title(rep.json())
        cache.set(subreddit, post_title, ttl_seconds = CACHE_TTL_SECONDS)
        return post_title

def _parse_post_title(json):
    if json["data"] and json["data"]["children"] and len(json["data"]["children"]) > 0:
        post = json["data"]["children"][-1]
        if post["data"] and post["data"]["title"]:
            return post["data"]["title"]
    return "No post was found"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "subreddit",
                name = "Subreddit",
                desc = "Subreddit for which to display post .",
                icon = "reddit",
                default = DEFAULT_SUBREDDIT,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24h_format",
                name = "24-hour clock",
                desc = "Enable 24-hour clock.",
                icon = "clock",
                default = False,
            ),
        ],
    )

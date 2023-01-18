"""
Applet: Last.fm
Summary: Show Last.fm's Now Playing
Description: An app to display whatever song you're currently scrobbling to your Last.fm profile.
Author: mattygroch
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("schema.star", "schema")
load("secret.star", "secret")

LAST_FM_URL = "http://ws.audioscrobbler.com/2.0/"
MUSIC_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAAvElEQVQoU9VS2xHCMAyLh4PCPFymKPu0sJyRnMc5r+O76UfkRJJrxxImS0JQFQmiAPgEWBUBdgDsWcSrXk/uicPbKyYeXYBowJjGtP3u7/AAHA1we7oUmlTGhA21hvkjS4MDhCeJJjHQrE+OtuQ1LPWECae5v5ZBbcaqB1NC7kGt23fMN3FJoIAZ7zHi7XfTU8izYmDiFaEYFGEf25h0z2buTtBwSgnMzvLqVBdRT3A19xOVJv0fYZyz9uQHBxtRB3iCYQ0AAAAASUVORK5CYII=
""")
TTL = 10

def get_track_info(username, api_key):
    r = http.get(
        url = LAST_FM_URL,
        params = {
            "method": "user.getrecenttracks",
            "limit": "1",
            "user": username,
            "api_key": api_key,
            "format": "json",
        },
    )
    if username == "":
        errormsg = {"name": "Supply a", "artist": {"#text": "username!"}}
        return errormsg
    if r.status_code != 200:
        errormsg = {"name": "Error with", "artist": {"#text": "API call!"}}
        return errormsg
    if len(r.json()["recenttracks"]["track"]) == 0:
        errormsg = {"name": "User missing", "artist": {"#text": "play history."}}
        return errormsg
    track = r.json()["recenttracks"]["track"][0]
    if track.get("@attr") != None:
        return track
    else:
        blank = {"name": "", "artist": {"#text": ""}}
        return blank

def now_playing(username, track, artist):
    if track == "" or artist == "":
        return not_playing(username)
    else:
        return render.Root(
            delay = 100,
            child = render.Padding(
                pad = 1,
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Image(src = MUSIC_ICON),
                                render.Marquee(
                                    width = 55,
                                    child = render.Text(
                                        content = str(username),
                                        font = "tom-thumb",
                                        color = "#c0c0c0",
                                    ),
                                ),
                            ],
                            main_align = "center",
                            cross_align = "center",
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text("%s" % track),
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "%s" % artist,
                                color = "#b90000",
                            ),
                        ),
                    ],
                ),
            ),
        )

def not_playing(username):
    return render.Root(
        delay = 100,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = MUSIC_ICON),
                        render.Text(
                            content = str(username),
                            font = "tom-thumb",
                            color = "#adadad",
                        ),
                    ],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text("  Nothing"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(
                        content = "   playing!",
                        color = "#b90000",
                    ),
                ),
            ],
        ),
    )

def main(config):
    user_name = config.get("user_name") or "mattygroch"
    api_key = secret.decrypt("AV6+xWcExvwh78xt0TOTqj5VhxD1vPIEvRmhQ3w5ilgAJCeLstfj2nlXQ9E7XTIlyNP39NpEW2biH5hRZJZsJYLKdLujhTLPMhALjgSA463JP1HhDBme6vUOM9//MRb+GG/2Dp9TXaL/Lq3/dMvk1oCcHieorAxsGe4eURsp+Vxo5TzA1SE=") or config.get("dev_api_key")

    cached_song_title = cache.get("name-%s" % user_name)
    cached_artist_name = cache.get("artist-%s" % user_name)

    if cached_song_title != None or cached_artist_name != None:
        print("Data cached.")
        song_title = cached_song_title
        artist_name = cached_artist_name
    else:
        info = get_track_info(user_name, api_key)
        print("Data stale, calling new data.")
        song_title = info.get("name")
        artist_name = info.get("artist").get("#text")
        cache.set("name-%s" % user_name, song_title, ttl_seconds = TTL)
        cache.set("artist-%s" % user_name, artist_name, ttl_seconds = TTL)

    return now_playing(user_name, song_title, artist_name)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_name",
                name = "User Name",
                desc = "The user name to look up on Last.fm.",
                icon = "user",
            ),
            schema.Text(
                id = "dev_api_key",
                name = "API Key for Last.fm",
                desc = "Supply your own API key.",
                icon = "key",
            ),
        ],
    )

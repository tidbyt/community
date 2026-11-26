"""
Applet: ListenBrainz
Summary: ListenBrainz Now Playing
Description: Shows the track, artist and album art currently playing for any ListenBrainz user. When nothing is playing, the app renders nothing and is hidden from rotation.
Author: theli-ua
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LB_API = "https://api.listenbrainz.org/1"
CAA_RELEASE_URL = "https://coverartarchive.org/release/%s/front-250"
CAA_GROUP_URL = "https://coverartarchive.org/release-group/%s/front-250"
MB_SEARCH_URL = "https://musicbrainz.org/ws/2/recording/"

HEADERS = {
    "User-Agent": "TidbytListenBrainz/1.0 (https://github.com/theli-ua/tidbyt-listenbrainz)",
}

TRACK_FONT = "tom-thumb"
SMALL_FONT = "CG-pixel-3x5-mono"

TRACK_COLOR = "#FFFFFF"
ARTIST_COLOR = "#00FFFF"
ALBUM_COLOR = "#888888"

# Cover art and MB lookups rarely change; cache for a week.
ART_TTL = 604800

# Playing-now is transient; keep short so idle hiding reacts quickly.
PLAYING_TTL = 60

def main(config):
    username = config.str("username", "")
    if username == "":
        # Community check + fresh installs render without config; show
        # setup instructions instead of returning empty.
        return render_setup_hint()
    username = username.strip()

    if username.lower() == "demo":
        return render_track(demo_track(), demo_art())

    track = fetch_playing(username)
    if track == None:
        # Nothing playing (or API error): return empty list so Tidbyt
        # skips/hides this app from rotation until music resumes.
        return []

    return render_track(track, fetch_art(track))

def render_setup_hint():
    return render.Root(
        child = render.Padding(
            pad = (2, 2, 2, 2),
            child = render.WrappedText(
                content = "Set your ListenBrainz username in app settings. Use demo for a preview.",
                font = TRACK_FONT,
                color = TRACK_COLOR,
                width = 60,
            ),
        ),
    )

def fetch_playing(username):
    rep = http.get(
        "%s/user/%s/playing-now" % (LB_API, username),
        headers = HEADERS,
        ttl_seconds = PLAYING_TTL,
    )
    if rep.status_code != 200:
        print("ListenBrainz API returned HTTP %d for %s" % (rep.status_code, username))
        return None

    payload = rep.json().get("payload", {})
    listens = payload.get("listens", [])
    if len(listens) == 0 or not payload.get("playing_now", True):
        return None

    return listens[0].get("track_metadata", {})

def fetch_art(track):
    # 1. Release MBID straight from the scrobble payload.
    release_mbid = get_release_mbid(track)
    if release_mbid != "":
        art = fetch_caa(CAA_RELEASE_URL % release_mbid)
        if art != None:
            return art

    # 2. Scrobbler gave no MBID: resolve release-group via MusicBrainz
    #    search, then fetch its cover art.
    rg_mbid = mb_release_group(track)
    if rg_mbid != "":
        art = fetch_caa(CAA_GROUP_URL % rg_mbid)
        if art != None:
            return art

    return None

def fetch_caa(url):
    rep = http.get(url, headers = HEADERS, ttl_seconds = ART_TTL)
    if rep.status_code != 200:
        print("cover art not found: %s" % url)
        return None

    art = rep.body()
    if len(art) == 0:
        return None
    return art

def mb_release_group(track):
    artist = track.get("artist_name", "")
    release = track.get("release_name", "")
    if artist == "" or release == "":
        return ""

    query = 'release:"%s" AND artist:"%s"' % (release, artist)
    rep = http.get(
        MB_SEARCH_URL,
        params = {
            "query": query,
            "fmt": "json",
            "limit": "1",
        },
        headers = HEADERS,
        ttl_seconds = ART_TTL,
    )
    if rep.status_code != 200:
        print("MusicBrainz search returned HTTP %d" % rep.status_code)
        return ""

    recordings = rep.json().get("recordings", [])
    if len(recordings) == 0:
        return ""

    releases = recordings[0].get("releases", [])
    if len(releases) == 0:
        return ""

    return releases[0].get("release-group", {}).get("id", "")

def get_release_mbid(track):
    addl = track.get("additional_info", {})
    return addl.get("release_mbid", "")

def render_track(track, art):
    title = track.get("track_name", "")
    artist = track.get("artist_name", "")
    album = track.get("release_name", "")

    if art != None:
        art_widget = render.Image(src = art, width = 32, height = 32)
    else:
        art_widget = render.Box(
            color = "#222222",
            width = 32,
            height = 32,
            child = render.Padding(
                pad = (11, 11, 0, 0),
                child = render.Text(
                    content = ">",
                    font = TRACK_FONT,
                    color = "#444444",
                ),
            ),
        )

    children = [
        render.WrappedText(
            content = title,
            width = 30,
            font = TRACK_FONT,
            color = TRACK_COLOR,
        ),
        render.WrappedText(
            content = artist,
            width = 30,
            font = SMALL_FONT,
            color = ARTIST_COLOR,
        ),
    ]
    if album != "":
        # Single line to keep the column within 32px height;
        # long names clip at the right edge.
        children.append(
            render.Text(
                content = album,
                font = SMALL_FONT,
                color = ALBUM_COLOR,
            ),
        )

    return render.Root(
        child = render.Row(
            children = [
                art_widget,
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Column(
                        expanded = True,
                        children = children,
                    ),
                ),
            ],
        ),
    )

def demo_track():
    return {
        "track_name": "Karma Police",
        "artist_name": "Radiohead",
        "release_name": "OK Computer",
        "additional_info": {
            "release_mbid": "de3726da-05b8-4c1a-a19d-1bf53b7889ea",
        },
    }

def demo_art():
    return fetch_caa(CAA_RELEASE_URL % demo_track()["additional_info"]["release_mbid"])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "ListenBrainz Username",
                desc = "The ListenBrainz user whose now playing track to display. Use demo for a preview.",
                icon = "user",
                default = "demo",
            ),
        ],
    )

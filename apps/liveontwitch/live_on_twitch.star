"""
Applet: Live on Twitch
Summary: See who's live on Twitch
Description: This app fetches and displays the streamers you follow who are live.
Author: daltonclaybrook
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

TWITCH_CLIENT_ID = "t7n82ips6t16w5hmf27abea5ypqa2a"
TWITCH_CLIENT_SECRET = secret.decrypt("AV6+xWcE4zoYtbnfh1xYGcfdSy1k/kSwPwpeatGr6j0bExssUbv1zjVIpjsLNTQY5NHLzP2i4wKP2YVlXw0xsiLpTp3SdwSQ62KJuiN1qIcoLtdls9E9uhyU2xwZogvtEyJT+pc0MB4fCT3wJ8gfSmIKm+NTdWF/EHwbbI3PsqnDYA3K")
NO_DATA_IN_CACHE = ""

# If a streamer went live less than 2 minutes ago, show them in an isolated widget. Otherwise, show the full list.
RECENTLY_LIVE_THRESHOLD = 120

TWITCH_PURPLE = "#a970ff"
WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"

def main(config):
    refresh_token = config.get("auth")
    if refresh_token == None:
        return render_message("Login to Twitch")

    user_id = get_current_user_id(refresh_token)
    if user_id == None:
        return render_message("Failed to fetch user")

    followed_streams = get_followed_streams(refresh_token, user_id)
    if followed_streams == None:
        return render_message("Failed to fetch followed streams")

    # Don't show the app at all if no one is live
    if len(followed_streams) == 0:
        return []

    (stream, seconds_since_start) = most_recently_live_stream(followed_streams)
    if stream != None and (seconds_since_start <= RECENTLY_LIVE_THRESHOLD or len(followed_streams) == 1):
        return render_recently_live(stream)
    else:
        return render_stream_list(followed_streams)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Twitch",
                desc = "Connect your Twitch account",
                icon = "twitch",
                handler = oauth_handler,
                client_id = TWITCH_CLIENT_ID,
                authorization_endpoint = "https://id.twitch.tv/oauth2/authorize",
                scopes = [
                    "user:read:follows",
                ],
            ),
        ],
    )

# Render a message instead of displaying streamers
def render_message(message):
    return render.Root(
        delay = 200,
        child = render.Box(
            child = render.Marquee(
                width = 64,
                offset_start = 20,
                child = render.Text(message),
            ),
        ),
    )

# Render the provided streamer in a special "recently live" widget
def render_recently_live(stream):
    return render.Root(
        delay = 100,
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(
                        color = RED,
                        pad = 1,
                        child = render.Padding(
                            color = BLACK,
                            pad = (1, 2, 1, 2),
                            child = render.Row(
                                cross_align = "center",
                                children = [
                                    render.Padding(
                                        pad = (1, 0, 2, 0),
                                        child = render.Circle(
                                            color = RED,
                                            diameter = 6,
                                        ),
                                    ),
                                    render.Marquee(
                                        width = 49,
                                        offset_start = 24,
                                        align = "center",
                                        child = render.Text(
                                            content = stream["user_name"],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                    render.Text(
                        content = "Live on Twitch",
                        font = "tom-thumb",
                        color = TWITCH_PURPLE,
                    ),
                ],
            ),
        ),
    )

# Render the provided list of live streamers
def render_stream_list(followed_streams):
    streamer_widgets = [
        render.Text(
            color = WHITE if index % 2 == 0 else TWITCH_PURPLE,
            content = followed_streams[index]["user_name"],
        )
        for index in range(len(followed_streams))
    ]
    column_widgets = [
        render.Padding(
            pad = 1,
            color = RED,
            child = render.Padding(
                pad = (1, 1, 3, 0),
                color = BLACK,
                child = render.Text(
                    content = "Live on Twitch",
                    font = "tom-thumb",
                ),
            ),
        ),
        render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Marquee(
                height = 21,
                scroll_direction = "vertical",
                offset_start = 6,
                child = render.Column(
                    children = streamer_widgets,
                ),
            ),
        ),
    ]
    return render.Root(
        delay = 200,
        child = render.Padding(
            pad = 1,
            child = render.Column(
                children = column_widgets,
            ),
        ),
    )

# Given a list of streams, returns the stream that went live most recently
def most_recently_live_stream(followed_streams):
    shortest_delta = None
    recent_stream = None
    now = time.now()
    for stream in followed_streams:
        started_at = time.parse_time(stream["started_at"])
        delta = (now - started_at).seconds
        if shortest_delta == None or delta < shortest_delta:
            shortest_delta = delta
            recent_stream = stream
    return (recent_stream, shortest_delta)

# The OAuth2 handler function provided to `schema.OAuth2`
def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://id.twitch.tv/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_encoding = "application/x-www-form-urlencoded",
        form_body = dict(
            params,
            client_secret = TWITCH_CLIENT_SECRET,
        ),
    )

    if res.status_code != 200:
        fail("auth failed with status %d: %s", res.status_code, res.body())

    token = res.json()
    refresh_token = token["refresh_token"]
    access_token = token["access_token"]
    expires_in = token["expires_in"]
    cache.set(refresh_token, access_token, ttl_seconds = int(expires_in))
    return refresh_token

# Retrieve an access token from cache, or fetch one from the Twitch API
def get_access_token(refresh_token, force_refresh = False):
    access_token = cache.get(refresh_token)
    if access_token != None and access_token != NO_DATA_IN_CACHE and force_refresh == False:
        # Return early if we have a cached access token
        print("Found cached access token")
        return access_token

    print("Fetching new access token...")
    params = {
        "client_id": TWITCH_CLIENT_ID,
        "client_secret": TWITCH_CLIENT_SECRET,
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    }
    res = http.post(
        url = "https://id.twitch.tv/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_encoding = "application/x-www-form-urlencoded",
        form_body = params,
    )

    if res.status_code != 200:
        fail("auth refresh failed with status %d: %s", res.status_code, res.body())

    token = res.json()
    access_token = token["access_token"]
    expires_in = token["expires_in"]
    cache.set(refresh_token, access_token, ttl_seconds = int(expires_in))
    return access_token

# Clear the access token from cache by setting it to an empty string
def clear_access_token(refresh_token):
    cache.set(refresh_token, NO_DATA_IN_CACHE, ttl_seconds = 30)

# Fetch the logged-in user's ID on Twitch
def get_current_user_id(refresh_token):
    access_token = get_access_token(refresh_token)
    res = http.get(
        url = "https://api.twitch.tv/helix/users",
        headers = {
            "Client-Id": TWITCH_CLIENT_ID,
            "Authorization": "Bearer %s" % access_token,
        },
    )
    if res.status_code == 200:
        return res.json()["data"][0]["id"]
    else:
        clear_access_token(refresh_token)
        return None

# Fetch the provided user's list of followers
def get_followed_streams(refresh_token, user_id):
    access_token = get_access_token(refresh_token)
    res = http.get(
        url = "https://api.twitch.tv/helix/streams/followed",
        headers = {
            "Client-Id": TWITCH_CLIENT_ID,
            "Authorization": "Bearer %s" % access_token,
        },
        params = {
            "user_id": user_id,
        },
    )
    if res.status_code == 200:
        return res.json()["data"]
    else:
        clear_access_token(refresh_token)
        return None

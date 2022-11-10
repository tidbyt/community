"""
Applet: Spotify Status
Summary: Now Playing
Description: Links to Spotiy API to show currently playing.
Author: Kaitlyn Musial
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("secret.star", "secret")
load("cache.star", "cache")
load("random.star", "random")

TIDBYT_OAUTH_CALLBACK_URL = "http%3A%2F%2Flocalhost%3A8080%2Foauth-callback"  # registered http://localhost:8080/oauth-callback as redirect_uri at Spotify

SPOTIFY_CLIENT_ID = "b223b434dfdf46ca89f600471b131bf5"
SPOTIFY_OAUTH_URL = "https://accounts.spotify.com/authorize"
SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
HEADER = "application/x-www-form-urlencoded"
SCOPES = "user-read-playback-state user-read-currently-playing user-read-playback-position"

AUTH_FULL_TOKEN = base64.encode(SPOTIFY_CLIENT_ID + ":" + secret.decrypt("AV6+xWcEsiy29RAydKeefD/bYuFIn3MvGVrfEA/HMxwQIcXKfCBL6NE7fBuy+T0uOvTmfba3O51MfSIU+G16W0FcIjwCbQyOy95BNkADivyuZHrFpn/SYZfiY/wrZbvcd7HzbKHgEXvdCZzCZcTERBZgaFMyIq08XmWNSUIOONoyoqQom6A="))

SPOTIFY_SRC_IMG = http.get("https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Spotify_icon.svg/991px-Spotify_icon.svg.png").body()

def main(config):
    user_id = generateUser()  # USE THIS TO GET CODES
    USER_AUTH = user_id + "_auth"
    USER_REFRESH = user_id + "_refresh"
    first_token = config.get("auth")
    if first_token:
        cache.set(USER_AUTH, first_token.split("||")[0])
        cache.set(USER_REFRESH, first_token.split("||")[1])
        REFRESH = cache.get(USER_REFRESH)

        #token.update([("auth",first_token.split("||")[0]),("refresh", first_token.split("||")[1])])
        user_data = getProfile(cache.get(USER_AUTH), REFRESH, USER_AUTH)
        playback_info = getPlayback(cache.get(USER_REFRESH), REFRESH, USER_AUTH)

        if user_data:
            if playback_info == "Not Playing":
                album = " "
                artist = playback_info
                song = " "
            else:
                album = playback_info["item"]["album"]["name"]
                artist = playback_info["item"]["artists"][0]["name"]
                song = playback_info["item"]["name"]
            user = "Now Playing"  # user_data["display_name"]
        else:
            user = "Something went wrong"
            album = " "
            artist = "Authorizing..."
            song = " "

    else:
        user = " "
        album = " "
        artist = "Authorizing..."
        song = " "

    return render.Root(
        child = render.Padding(
            pad = 1,
            child = render.Column(
                main_align = "space_evenly",
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 1),
                        child = render.Row(
                            main_align = "space_evenly",
                            children = [
                                render.Image(src = SPOTIFY_SRC_IMG, width = 8),
                                render.Marquee(
                                    width = 64,
                                    #align = "center",
                                    child = render.Text(" " + user),
                                ),
                            ],
                        ),
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.WrappedText(content = album, font = "tom-thumb"),
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.WrappedText(content = artist, font = "tom-thumb"),
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.WrappedText(content = song, font = "5x8"),
                    ),
                ],
            ),
        ),
    )

def oauth_handler(params):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
        "Authorization": "Basic " + AUTH_FULL_TOKEN,
    }
    params = json.decode(params)
    body = (
        "grant_type=authorization_code" +
        "&code=" + params["code"] +
        "&client_id=" + params["client_id"] +
        "&redirect_uri=" + params["redirect_uri"]
    )

    response = http.post(
        url = SPOTIFY_TOKEN_URL,
        headers = headers,
        body = body,
    )

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    access_token = token_params["access_token"]
    refresh_token = token_params["refresh_token"]

    #cache.set("auth", access_token, ttl_seconds=5)
    #cache.set("refresh", refresh_token, ttl_seconds=5)

    return access_token + "||" + refresh_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Spotify",
                desc = "Connect your Spotify account.",
                icon = "github",
                handler = oauth_handler,
                client_id = SPOTIFY_CLIENT_ID,
                authorization_endpoint = SPOTIFY_OAUTH_URL,
                scopes = [
                    "user-read-playback-state",
                    "user-read-currently-playing",
                    "user-read-playback-position",
                ],
            ),
        ],
    )

def getProfile(access, refresh, user_auth):
    headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer " + access,
    }

    response = http.get(
        url = "https://api.spotify.com/v1/me",
        headers = headers,
    )

    if response.status_code != 200:
        if response.status_code == 401:
            print("USER - GOT NEW TOKEN")
            cache.set(user_auth, getNewToken(refresh), ttl_seconds = 5)
            return getProfile(cache.get(user_auth), refresh)
        else:
            fail("token request failed with status code: %d - %s" %
                 (response.status_code, response.body()))

    resp_json = response.json()

    return resp_json

def getPlayback(access, refresh, user_auth):
    headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer " + access,
    }

    response = http.get(
        url = "https://api.spotify.com/v1/me/player/currently-playing",
        headers = headers,
    )

    if response.status_code != 200:
        if response.status_code == 401:
            print("PLAYBACK - GOT NEW TOKEN")
            cache.set(user_auth, getNewToken(refresh), ttl_seconds = 5)
            return getProfile(cache.get(user_auth), refresh)
        if response.status_code == 204:
            return "Not Playing"
        else:
            fail("token request failed with status code: %d - %s" %
                 (response.status_code, response.body()))

    resp_json = response.json()

    return resp_json

def getNewToken(refresh):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
        "Authorization": "Basic " + AUTH_FULL_TOKEN,
    }
    body = (
        "grant_type=refresh_token" +
        "&refresh_token=" + refresh
    )

    response = http.post(
        url = SPOTIFY_TOKEN_URL,
        headers = headers,
        body = body,
    )

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    access_token = token_params["access_token"]

    return access_token

def generateUser():
    user_id = str(random.number(1000000, 9999999))
    if cache.get(user_id) != None:
        return generateUser()
    else:
        cache.set(user_id, "AssignedNewUser")
        return user_id

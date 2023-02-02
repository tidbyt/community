"""
Applet: XBOX Gamerscore
Summary: Show your Gamerscore
Description: Show your Gamerscore from XBOX Live.
Author: Nick Penree
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

## Constants

DEFAULT_SHOW_AVATAR = False
DEFAULT_SHOW_GAMERTAG = False
DEFAULT_TEXT_SIZE = "normal"
SMALL_TEXT_SIZE = "small"
DEFAULT_USE_ANIMATED_VERSION = False

XBOX_LIVE_CLIENT_ID = "12f593c5-93bb-4801-80c3-1968300d2cae"
XBOX_LIVE_CLIENT_SCOPES = ["XboxLive.signin", "XboxLive.offline_access"]
XBOX_LIVE_CLIENT_SECRET = secret.decrypt("""
AV6+xWcE0EMWDnotDEY+N0sgA3+oh4zBFjCKjY41F3TvM/gFRfrl5a514/UoL2wfAJWP5XxZ9Hz9rrH
TCnqFFdPPTu4GT58QOmCTlGG88nTXrT4y3faO4lEN7ke1/Ns7fUl+u27044ulsBo3lL2fYgK1VYb51So
hzhdFrYp8KSYuTj4WQqpEa/hnbQ==
""")

PREVIEW_PROFILE = dict(
    gamer_tag = "TidbytUser",
    gamer_score = "80085",
    avatar_url = "https://assets.website-files.com/5e83e105296ec10c70a99eac/5f04b6fffef2f0b21590ac24_favicon.png",
)
## Widgets

def GamerTag(gamer_tag = None, text_size = DEFAULT_TEXT_SIZE):
    is_small = (text_size == SMALL_TEXT_SIZE)
    widget = render.Text(
        color = "#045904",
        content = gamer_tag,
        font = "tom-thumb" if is_small else "tb-8",
    )
    scroll_len = 15 if is_small else 12
    if len(gamer_tag) > scroll_len:
        widget = render.Marquee(
            width = 64,
            child = widget,
        )
    return widget if gamer_tag else None

def Avatar(avatar_url = None):
    return render.Image(
        src = http.get(avatar_url).body(),
        height = 14,
        width = 14,
    ) if avatar_url else None

def GamerScore(score = None, text_size = DEFAULT_TEXT_SIZE, avatar_url = None):
    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Padding(
                pad = (2, 2, 2, 2),
                child = render.Circle(
                    color = "#fff",
                    diameter = 11,
                    child = render.Text(
                        content = "G",
                        color = "#000",
                        font = "Dina_r400-6",
                    ),
                ) if not avatar_url else Avatar(avatar_url),
            ),
            render.Text(
                content = score,
                font = "tb-8" if text_size == SMALL_TEXT_SIZE else "6x13",
            ),
        ],
    ) if score else None

def AnimatedScore(score = None, text_size = DEFAULT_TEXT_SIZE):
    if not score:
        return None

    frames = []

    # intro animation
    for i in range(82):
        frames.append(
            render.Box(
                child = render.Stack(
                    children = [
                        render.Image(
                            src = INTRO,
                            width = 64,
                        ),
                    ],
                ),
            ),
        )

    for i in range(120):
        off = i % 2 == 0
        color = "#000"
        if off:
            color = "#111"

        frames.append(
            render.Box(
                child = render.Stack(
                    children = [
                        render.Box(
                            child = render.Image(
                                src = BG,
                                width = 64,
                            ),
                        ),
                        render.Padding(
                            pad = (13, 11, 0, 1),
                            child = render.Text(
                                content = "G",
                                color = color,
                                font = "Dina_r400-6",
                            ),
                        ),
                        render.Box(
                            child = render.Padding(
                                pad = (9, 0, 0, 0),
                                child = render.Text(
                                    content = score,
                                    font = "tb-8" if text_size == SMALL_TEXT_SIZE else "Dina_r400-6",
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        )

    return render.Root(
        child = render.Animation(children = frames),
    )

## Helpers

def get_access_token(refresh_token):
    access_token = cache.get(refresh_token)
    if access_token:
        return access_token
    res = http.post(
        url = "https://login.live.com/oauth20_token.srf",
        form_body = {
            "client_id": XBOX_LIVE_CLIENT_ID,
            "refresh_token": refresh_token,
            # "client_secret": XBOX_LIVE_CLIENT_SECRET,
            "grant_type": "refresh_token",
            "redirect_uri": cache.get("redirect_uri") or "https://pixlet.penr.ee/oauth-callback",
        },
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("access token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    ttl = int(token_params["expires_in"]) - 30

    cache.set(refresh_token, access_token, ttl_seconds = ttl)
    return access_token

def get_profile(config):
    refresh_token = config.get("auth")

    if not refresh_token:
        return PREVIEW_PROFILE

    access_token = cache.get(refresh_token)

    if not access_token:
        access_token = get_access_token(refresh_token)

    if not access_token:
        return None

    cached_profile = cache.get("%s|profile" % access_token)

    if cached_profile:
        profile = json.decode(cached_profile)
        return profile

    user_token = exchange_access_token_for_user_token(access_token)

    if not user_token:
        return None

    xsts = exchange_user_token_for_xsts_token(user_token)

    if not xsts:
        return None

    profile = get_xbox_live_profile(xsts)

    if profile:
        cache.set("%s|profile" % access_token, json.encode(profile), ttl_seconds = 300)

    return profile

def exchange_access_token_for_user_token(access_token):
    if not access_token:
        return None
    res = http.post(
        url = "https://user.auth.xboxlive.com/user/authenticate",
        headers = {
            "x-xbl-contract-version": "1",
            "accept": "application/json",
        },
        json_body = {
            "Properties": {
                "AuthMethod": "RPS",
                "SiteName": "user.auth.xboxlive.com",
                "RpsTicket": "d=%s" % access_token,
            },
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT",
        },
    )

    if res.status_code != 200:
        fail("user token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    return token_params["Token"]

def exchange_user_token_for_xsts_token(user_token, sandbox_id = "RETAIL"):
    if not user_token:
        return None
    res = http.post(
        url = "https://xsts.auth.xboxlive.com/xsts/authorize",
        headers = {
            "x-xbl-contract-version": "1",
            "accept": "application/json",
        },
        json_body = {
            "RelyingParty": "http://xboxlive.com",
            "TokenType": "JWT",
            "Properties": {
                "UserTokens": [user_token],
                "SandboxId": sandbox_id,
            },
        },
    )

    if res.status_code != 200:
        fail("user token (xsts) request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()

    if not "DisplayClaims" in token_params:
        return None
    elif not "xui" in token_params["DisplayClaims"]:
        return None
    elif len(token_params["DisplayClaims"]["xui"]) < 1:
        return None
    display_claim = token_params["DisplayClaims"]["xui"][0]
    return dict(
        xuid = display_claim["xid"],
        gamer_tag = display_claim["gtg"],
        user_hash = display_claim["uhs"],
        xsts_token = token_params["Token"],
        expires_on = time.parse_time(token_params["NotAfter"]),
    )

def get_profile_setting(profile, key):
    settings = profile["settings"] or []
    for setting in settings:
        if setting["id"] == key:
            return setting["value"]
    return None

def get_xbox_live_profile(xsts):
    xuid = xsts["xuid"]
    if not xuid:
        return None
    res = http.post(
        url = "https://profile.xboxlive.com/users/batch/profile/settings",
        headers = {
            "x-xbl-contract-version": "2",
            "accept": "application/json",
            "authorization": "XBL3.0 x=%s;%s" % (xsts["user_hash"], xsts["xsts_token"]),
        },
        json_body = {
            "userIds": [xuid],
            "settings": [
                "GameDisplayPicRaw",
                "Gamerscore",
                "Gamertag",
            ],
        },
    )

    if res.status_code != 200:
        fail("get profile request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    body = res.json()
    profile = body["profileUsers"][0] if len(body["profileUsers"]) > 0 else None
    return dict(
        gamer_tag = get_profile_setting(profile, "Gamertag"),
        avatar_url = get_profile_setting(profile, "GameDisplayPicRaw"),
        gamer_score = get_profile_setting(profile, "Gamerscore"),
    ) if profile else None

## Handlers

def oauth_handler(params):
    params = json.decode(params)
    params["scope"] = " ".join(XBOX_LIVE_CLIENT_SCOPES)
    res = http.post(
        url = "https://login.live.com/oauth20_token.srf",
        headers = {
            "accept": "application/json",
        },
        form_body = params,
        form_encoding = "application/x-www-form-urlencoded",
    )

    # Caching this here to use in the refresh token request
    if params["redirect_uri"]:
        cache.set("redirect_uri", params["redirect_uri"])

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    refresh_token = token_params["refresh_token"]
    ttl = int(token_params["expires_in"]) - 30

    cache.set(refresh_token, access_token, ttl)
    return refresh_token

## Applet

def main(config):
    show_avatar = config.bool("show_avatar", DEFAULT_SHOW_AVATAR)
    show_gamertag = config.bool("show_gamertag", DEFAULT_SHOW_GAMERTAG)
    text_size = config.get("text_size", DEFAULT_TEXT_SIZE)
    use_animated_version = config.bool("use_animated_version", DEFAULT_USE_ANIMATED_VERSION)

    profile = get_profile(config)

    if use_animated_version:
        return AnimatedScore(
            score = profile["gamer_score"],
            text_size = text_size,
        ) if profile else []

    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    GamerScore(
                        score = profile["gamer_score"],
                        text_size = text_size,
                        avatar_url = profile["avatar_url"] if show_avatar else None,
                    ),
                    GamerTag(
                        gamer_tag = profile["gamer_tag"],
                        text_size = text_size,
                    ) if show_gamertag else None,
                ],
            ),
        ),
    ) if profile else []

## Schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "XBOX Live",
                desc = "Connect your XBOX Live account.",
                icon = "xbox",
                handler = oauth_handler,
                client_id = XBOX_LIVE_CLIENT_ID,
                authorization_endpoint = "https://login.live.com/oauth20_authorize.srf",
                scopes = XBOX_LIVE_CLIENT_SCOPES,
            ),
            schema.Toggle(
                id = "use_animated_version",
                name = "Show animation",
                desc = "Show an XBOX inspired animation instead of a number.",
                icon = "circleNotch",
                default = DEFAULT_USE_ANIMATED_VERSION,
            ),
            schema.Toggle(
                id = "show_avatar",
                name = "Show Avatar",
                desc = "Show your avatar",
                icon = "image",
                default = DEFAULT_SHOW_AVATAR,
            ),
            schema.Toggle(
                id = "show_gamertag",
                name = "Show Gamertag",
                desc = "Show your gamertag",
                icon = "idBadge",
                default = DEFAULT_SHOW_GAMERTAG,
            ),
            schema.Dropdown(
                id = "text_size",
                name = "Text Size",
                desc = "Set your preferred text size",
                icon = "textHeight",
                options = [
                    schema.Option(
                        display = "Smaller",
                        value = SMALL_TEXT_SIZE,
                    ),
                    schema.Option(
                        display = "Normal",
                        value = DEFAULT_TEXT_SIZE,
                    ),
                ],
                default = DEFAULT_TEXT_SIZE,
            ),
        ],
    )

INTRO = base64.decode("""
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
""")

BG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAASCAYAAADrL9giAAAAAXNSR0IArs4c6QAAAGhlWElmTU0AKgAA
AAgABAEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEoAAMAAAABAAIAAIdpAAQAAAABAAAAPgAAAAAAA6AB
AAMAAAABAAEAAKACAAQAAAABAAAAQKADAAQAAAABAAAAEgAAAACGfVsgAAACC2lUWHRYTUw6Y29tLmFk
b2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1Q
IENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkv
MDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgog
ICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAg
ICAgIDx0aWZmOkNvbXByZXNzaW9uPjE8L3RpZmY6Q29tcHJlc3Npb24+CiAgICAgICAgIDx0aWZmOk9y
aWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgICAgIDx0aWZmOlBob3RvbWV0cmljSW50
ZXJwcmV0YXRpb24+MjwvdGlmZjpQaG90b21ldHJpY0ludGVycHJldGF0aW9uPgogICAgICAgICA8dGlm
ZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICA8L3JkZjpEZXNjcmlw
dGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K7U2YxAAABYBJREFUWAnll11sVFUQx2c/alsK
qAsIQiEgEj4qvsi2+ABoNDExgSeD4IM8+IS8EDERlEJiMUYxRk3UR4MxaBRfMGiVaEETYyl+YAigCEZJ
QZAU5KPY0t3r/ObeuXu33V3kmUnvOfPxnzkzc87eeypyg1PqeutftmVZcPnKRem9dEpO9B8x93+DjDQN
FONQ/YWMSBCEcipaAhne9TE6gkXwIJmR4z0G0ChOUtWYLsik0TNl3JjxkmsaJ7s270pGGbZSufi/gRve
2RDsOdwl+/p6yiMkJJpgxReiaoo6w7KKraSDrwjGeWIggg3Z0JYGoMpIH8aJnCKTOXicqCv5qQtkxm3T
ZfvTH7jFYJWGawJwWvXaqqD7eLcc7T9aFqMhVRB2fzil+jUsBZI4O8bhSPOoHjmjgumV963UZqUUF6A3
nOIJjR1fVceNoLEQNv0zvClKQ64+J0vmLJaP1u8AUZUIXZO2frw1+PXkL3HxzfXN8vqyV+WH9fvl+01H
5Ju1e2Vd2zqhGU6jMspTBNFZnocmUBxJF1TA7sVnlM+mJajTWXlOQgosTeTBF7KYIRa8NQg9DeGxpuus
1DfYJwf++EnaP3wmVJh25JAdqSrXHDv5W3zs75u4WDpWdkh+Xl5ziXa++U65Z/YCaZ2Tlye2L5dLV9Ny
uT4tTVKQfuXjHSRBT8WaoAIF+UlhWfTZlARDVBzZdDIMMw3FJyblvcnoPD68rnf83O/S/fOPSFUJ95p0
4MQBs7PD7Y+2S1vLwlLxkWc2m5WlC5fKxgdfjmPRhDhZcuYhQTsFiRklzTF7NMNTqDbD9CraKQBnjYxw
6CEV7cHPn+i0HOk9JJvebQdRkWo2YM3bTwb+0nt45iOSn9VaMQhKa0LrUhld5+c1gpIQ5Ek6z0wxJOrp
+U8CHSfDqU7T5MChQs8SzB4bHHzCBRV0avAv6T3fGwoVxpoNuDRwOXaZO3mu1NfXx3Il5vZbJ8q8MW3l
JooiMVtJGXiTI70XjQ7ihEBWnA0hz2+extA0igcGDxPBcDO9MeFAuL8vnE1oytmaDcimR77hy92vIVl+
UYIUao/6JBP2EF44Rm+aV0MciJ8EjYB4kdIATkPsa5YRTYi0FaeaDWioa4idDp88LAMDA7FciTl17rQc
uthdMnmh1ghV+wwCG4/tIophhM0L9zhAaAJfCpyteNX5nMSBVaKXE8aOD4UKY80GvLn6rVRrLm9unx7b
IT1H91UIEaqKQUE6939mXwE08c3Qi1BdWX6uTyp9J5NN4dgPJ74UZG4NjQK5r8E9uMiUhskyedKE4RFi
uWYDQC2atdjAXHg2vPesfL6/U09caQGMQ0ND0tnTKZu/eMqwDFeKiZ8PeH3smktBnjxAQiGzVZDX60tU
y9DuC8RVH8/HfSxQOLRMmy8dy1/yqAlLyFY1JJEPPHd/sOf016a6e9RdsvqhNdI2O68vxUbp++esfNKz
S9749sX4VmhX4iFtAC8rCvA3NzyXHhJlZU+YplCEN4F7ADb0HPlKBHygoCdB7TwWV5XwEd1x83RZce9K
ef7xjpLSjdFc1ZDE8R3dfXB3fCHC5je/qldhjjFF+MxKnpyvym83PiiqpAno8LFm6eBYVZcRsQcVbHGV
JzYNjPC5m3Iyf0qLfPlCV6Qp846FmsYYpcyW9zuCroNfyXdnuuKdTtrhw50ncw1LEew8xCq+85gpEoKH
SNw+bY5XGXwlMogOxLiqAzgrXuWowUtmLJLmCdNk29ptVYKUAl8TUIKG3GOvrAhO69v+Qv8FOTN4Vs4X
/9R3QCBjC5P0yxRWFvCJiiiT+JQW9ZKf1hcBc5LQFYoF/R8pM8KWxCV51kjib2kcK1NzU6WpcYzs3Ljz
uutKxr6h+P8AnpgDxnsFw/0AAAAASUVORK5CYII=
""")

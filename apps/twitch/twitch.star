"""
Applet: Twitch
Summary: Display stats for Twitch
Description: Display stats for a Twitch username.
Author: Nicholas Penree
"""

load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("humanize.star", "humanize")
load("http.star", "http")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")

TWITCH_CLIENT_ID = "h25bh1ddh0f5xcddgxgxhna399677y"

TWITCH_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAAAuxJREFUeF7tnVtu
6zAMRKPNdT1dStfTzaXo4+KmKWEPpZFFJ6e/pShljsixLQNuF/Hv7eV6FUMJu1wur++t9QghDwJITl6A
5PSaHg2Q6RLnJgBITq/p0VYg+IWflwooNHWAAMSvQLGMVAhAiilQbDlyheAX68hFkBpAALJOgWIzUyEA
KaZAseVQIQAppkCx5VAhACmmQLHlLKmQ13f5ULKYXPFy3l58J9kAMSAHiEFEZwqAONU05AKIQURnilMB
UQ38epJXvFrwatXTA2mttesiggBx9hZDLoDciLiyMv4tAyCGXe1McSogqoFHAi2yhDQrgKQlmzsAIHP1
TWd/WiAVDDyi9bRA1K0bCaT4kXNc2RvDFabuFLYXJEB+35v8KaZeYXvHAUQAsudBzsoCiABkz4MAsqOQ
0i7Uqx4lF0AAsle0X/+3nqlzlSVpvhkEkBt5elsdpo6pa6VIy9J02oqiZdGy4v2h9G8ue5MVSMtKChaE
07JoWbQsTD1QgEcnPDqRDAYP2fCQ6BE+R7jSvpoXFAG4n41HJ6L+e4dUShqAKCodGAOQY8XefYseIAcC
UaYCiKLSpJijxY9+xukve51sAJJ8juQUX31yPPMSlwrZIUqFUCF/tkgZD1HakfMQS5nvM8Z5F67MCZAd
lQCyIRAVotTYTczIEa4yFUAUlQCSVGk7/CE9RLl8jWQ52i9K34co20xtWQD5UbOKhwAEIEqBSzGn95Az
V8NDeghANgpvhYcABCCSF/QG4SG9yk0aZwUyssbedlfhZm7kd9+PBYhTTUMugBhEdKYAiFNNQy6AGER0
pjgVkEcz8Ol36iM7RbnKAsiIwsmxAPkWjJaV3DizwwEyW+Fk/rJAnsEvTmXqAPmPa8nHie9NHSAASXb7
OeGhh0RT8UlvPwD5A/cA8YuvGngUF371kQrxQ6JC/JoOZQTIkHz+wUNA8JVxICqA+5nkLwfjKzlIAMnp
NT0aINMlzk0wHUhuOUT3KvABWOWLknJ2OW8AAAAASUVORK5CYII=
""")

def get_from_twitch_api(path, params, access_token):
    res = http.get(
        url = "https://api.twitch.tv/helix%s" % path,
        params = params,
        headers = {
            "Authorization": "Bearer %s" % access_token,
            "Client-Id": TWITCH_CLIENT_ID,
        },
    )
    return res.json() if res.status_code == 200 else None

def get_twitch_followers(user_id, access_token):
    res = get_from_twitch_api(
        path = "/users/follows",
        params = {
            "to_id": user_id,
        },
        access_token = access_token,
    )
    return res["total"] if res and res["total"] != None else 0

def get_twitch_subscribers(user_id, access_token):
    res = get_from_twitch_api(
        path = "/subscriptions",
        params = {
            "broadcaster_id": user_id,
            "first": "1",
        },
        access_token = access_token,
    )
    return res["total"] if res else None

def get_twitch_user(username, access_token):
    res = get_from_twitch_api(
        path = "/users",
        params = {
            "login": username,
        },
        access_token = access_token,
    )
    print(res)
    if res and res["data"] and len(res["data"]) > 0:
        return res["data"][0]
    return None

def main(config):
    refresh_token = config.get("auth")
    username = config.get("username", "ninja")
    display_mode = config.get("display_mode", "subscribers")
    show_username = config.bool("show_username", "True")
    image_size = 16

    if refresh_token:
        access_token = get_token(refresh_token = refresh_token)
        user = get_twitch_user(
            username = username,
            access_token = access_token,
        )

        # print(user)
        if user == None:
            return []

        display_name = user["display_name"] if user["display_name"] else username

        if display_mode == "followers":
            followers = get_twitch_followers(
                access_token = access_token,
                user_id = user["id"],
            )
            if followers != None:
                msg = "%s %s" % (humanize.comma(followers), display_mode)
                if not show_username:
                    msg = humanize.comma(followers)
                    display_name = display_mode
            else:
                msg = "Check username"
        elif display_mode == "subscribers":
            subscribers = get_twitch_subscribers(
                access_token = access_token,
                user_id = user["id"],
            )

            if subscribers != None:
                msg = "%s subs" % humanize.comma(subscribers)
                if not show_username:
                    msg = humanize.comma(subscribers)
                    display_name = display_mode
            else:
                msg = "Check username"
                display_name = "Are you %s? You can only view your own subscriber count." % display_name
                show_username = True
        else:
            print("done")
            return []

        print(msg)
    else:
        msg = "Launch Tidbyt app"
        display_name = "Login to Twitch using the Tidbyt app on your phone"
        show_username = True

    username_child = render.Text(
        color = "#3c3c3c" if show_username else "#ffffff",
        content = display_name,
    )

    if len(display_name) > 12:
        username_child = render.Marquee(
            width = 64,
            child = username_child,
        )


    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(TWITCH_ICON, height = image_size, width = image_size),
                            render.WrappedText(msg, font = "tb-8" if show_username or len(msg) > 7 else "6x13"),
                        ],
                    ),
                    username_child,
                ],
            ),
        ),
    )

def get_token(params = None, refresh_token = None):
    has_refresh_token = (refresh_token != None)

    # if we have a refresh token try to get a cached access token and return quickly
    if has_refresh_token:
        access_token = cache.get(refresh_token)
        if access_token != None:
            return access_token

    # if params is a string, assume it is json and decode it
    if type(params) == "string":
        params = json.decode(params)
    elif params == None and has_refresh_token:
        params = dict(
            client_id = TWITCH_CLIENT_ID,
            grant_type = "refresh_token",
            refresh_token = refresh_token,
        )

    # get a new token
    res = http.post(
        url = "https://id.twitch.tv/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = TWITCH_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    if not has_refresh_token:
        refresh_token = token_params["refresh_token"]

    # cache the access token so it can be reteived using the refresh token
    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token if has_refresh_token else refresh_token

def get_schema():
    display_modes = [
        schema.Option(value = "followers", display = "Followers"),
        schema.Option(value = "subscribers", display = "Subscribers"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Twitch",
                desc = "Connect your Twitch account.",
                icon = "twitch",
                handler = get_token,
                client_id = TWITCH_CLIENT_ID,
                authorization_endpoint = "https://id.twitch.tv/oauth2/authorize",
                scopes = [
                    "user:read:follows",
                    "user:read:subscriptions",
                    "channel:read:subscriptions",
                ],
            ),
            schema.Text(
                id = "username",
                icon = "user",
                name = "Username",
                desc = "The Twitch username to display stats for.",
                default = "ninja",
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display",
                desc = "Choose what stat to show.",
                icon = "barsProgress",
                options = display_modes,
                default = display_modes[0].value,
            ),
            schema.Toggle(
                id = "show_username",
                name = "Show username",
                desc = "Whether to show the username below the stat.",
                icon = "eye",
                default = True,
            ),
        ],
    )

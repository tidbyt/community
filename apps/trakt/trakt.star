"""
Applet: Trakt
Summary: Trakt info on your Tidbyt
Description: Show your Trakt now watching, most recently watched, and stats, on your Tidbyt.
Author: cbattlegear
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/json.star", "json")

OAUTH2_CLIENT_ID = "ad910eb639274f2ceba923147987603df76855dc5b44c33604934582c11be44f"
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEPPga5YWsxjwU7OgkZ5fBn5KA9oa97da3gPsHYhGo7Up/sVwk+Dvcle6VgBQEQw/MyB7IqMcE8wh2ulL0apzEaWM4T2gOhbz+XLtU2zgdjG2q9AfE6pOkejK9SFcBhnJQZxgO0aNs2zcefLJOXnwi0DgnT5BYIQeKQRa/oYHcOyyee4JBoBHTszVv5mELDn22gjwSdohtvPadddhDfcLZrw==")

def main(config):
    token = config.get("auth")
    msg = "Unauthorized"
    if(token):
        res = http.get(
            url = "https://api.trakt.tv/users/me",
            headers = {
                "Content-Type": "application/json",
                "trakt-api-version": "2",
                "trakt-api-key": OAUTH2_CLIENT_ID,
                "Authorization": "Bearer " + token,
            }
        )
        current_user = res.json()
        msg = current_user["username"]


    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

def oauth_handler(params):
    # deserialize oauth2 parameters, see example above.
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://api.trakt.tv/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        json_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
        ),
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Trakt",
                desc = "Connect your Trakt account.",
                icon = "forward-fast",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID,
                authorization_endpoint = "https://trakt.tv/oauth/authorize",
                scopes = [
                    "public",
                ]
            ),
        ],
    )

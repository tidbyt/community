"""
Applet: OAuth2 Example
Summary: OAuth2 example app
Description: An OAuth2 example app.
Author: Mark
"""

load("http.star", "http")
load("cache.star", "cache")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/json.star", "json")

OAUTH2_CLIENT_SECRET = secret.decrypt("your-client-secret")

def main(config):
    refresh_token = config.get("auth")
    if not refresh_token:
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text("Unauthenticated"),
            ),
        )

    token = get_access_token(refresh_token)
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text("Authenticated"),
        ),
    )

def get_access_token(refresh_token):
    access_token = cache.get(refresh_token)
    if access_token:
        return access_token

    # Make HTTP request for new token.

    return "new-access-token"

def oauth_handler(params):
    # Make HTTP request to exchange parameters and client secret for an access token
    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    ttl = token_params["expires_in"]

    # cache the current access token, using the refresh token as the key.
    # the refresh token is what will be stored as the value for the auth config field.
    cache.set(refresh_token, access_token, ttl_seconds = int(ttl - 30))

    return refresh_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "GitHub",
                desc = "Connect your GitHub account.",
                icon = "github",
                handler = oauth_handler,
                client_id = "your-client-id",
                authorization_endpoint = "https://github.com/login/oauth/authorize",
                scopes = [
                    "read:user",
                ],
            ),
        ],
    )

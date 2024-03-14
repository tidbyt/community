"""
Applet: Updown.io
Summary: Simple website monitoring
Description: Updown.io checks your website's status by periodically sending an HTTP request to the URL of your choice and notifies you when your website is not responding correctly.
Author: jcarbaugh
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

ENCRYPTED_SALT = "AV6+xWcE9TSREL/cItw8d27I4uv2XsWMNf4y8zxIos6RXx2x0cFblymnW4uXVxPwnGnIEU/rR3sCVS0JGbxqlQC0flvFu/F6EpnGMEP7ippTCbhuQP9bvAMOHlu427aeoVekR+YhwQ40+T6yoKotytMMNO+YzH4f"

LOGO_UP_IMG = base64.decode("""R0lGODdhIgAIAKIAAAAAAF9XTwCHUQDkNv/x6P///wAAAAAAACH5BAkAAAYALAAAAAAiAAgAAAM0CLrc/jCS6MabJJCpdv+ZVwkCCGBnimmauljwgs4u5qFKbClayJ2Z1KmFgpV2jh9lyWw2EwA7""")
LOGO_DOWN_IMG = base64.decode("""R0lGODdhIgAIAKIAAAAAAP8ATX4lU19XT//x6P///wAAAAAAACH5BAkAAAYALAAAAAAiAAgAAAM0CLrc/jCS6MKbZJCpdv+ZVwkCCGBnimmauljwgs4u5qFKbClayJ2Z1KmFgpV2jh9lyWw2EwA7""")

def main(config):
    api_key = config.str("api_key")
    check_token = config.str("check_token")

    if not api_key or not check_token:
        mock_data = {
            "alias": "demo.example.com",
            "metrics": {
                "timings": {
                    "total": 123,
                },
            },
        }
        return render_up_screen(mock_data)

    # Some notes about cache_key:
    # 1. We combine api_key and check_token to prevent people from fetching other people's checks.
    # 2. We hash the cache_key so the api_key and check_token aren't stored in plaintext in the cache.
    # 3. We add a secret salt just for the fun of it.
    salt = secret.decrypt(ENCRYPTED_SALT) or ""
    cache_key = "check-{}".format(hash.sha256(salt + api_key + check_token))

    data = cache.get(cache_key)
    if data:
        data = json.decode(data)
    else:
        headers = {"X-API-KEY": api_key}
        resp = http.get("https://updown.io/api/checks/" + check_token + "?metrics=1", headers = headers)
        data = resp.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, json.encode(data), 60 * 5)

    if data["down"]:
        return render_down_screen(data)
    else:
        return render_up_screen(data)

def render_alias_widget(alias):
    alias_widget = render.Text(alias, font = "6x13")
    if len(alias) > 10:
        alias_widget = render.Marquee(
            width = 64,
            child = alias_widget,
        )
    return alias_widget

def render_down_screen(data):
    down_since = 0
    if data["down_since"]:
        down_since = int((time.now() - time.parse_time(data["down_since"])).minutes)

    alias = data["alias"] or data["url"]
    alias_widget = render_alias_widget(alias)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            height = 8,
                            child = render.Image(LOGO_DOWN_IMG),
                        ),
                    ],
                ),
                render.Box(
                    height = 17,
                    child = alias_widget,
                ),
                render.Row(
                    children = [
                        render.Box(
                            child = render.Text(
                                "DOWN {} MINS".format(down_since),
                                font = "CG-pixel-3x5-mono",
                                color = "#fff",
                            ),
                            height = 7,
                            width = 64,
                            color = "#900",
                        ),
                    ],
                ),
            ],
        ),
    )

def render_up_screen(data):
    total_duration = data["metrics"]["timings"]["total"]
    timing_bg = "#222" if total_duration < 500 else "#950"

    alias = data["alias"] or data["url"]
    alias_widget = render_alias_widget(alias)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            height = 8,
                            child = render.Image(LOGO_UP_IMG),
                        ),
                    ],
                ),
                render.Box(
                    height = 17,
                    child = alias_widget,
                ),
                render.Row(
                    children = [
                        render.Box(
                            child = render.Text(
                                "UP",
                                font = "CG-pixel-3x5-mono",
                                color = "#cfc",
                            ),
                            height = 7,
                            width = 32,
                            color = "#161",
                        ),
                        render.Box(
                            child = render.Text(
                                "{} ms".format(int(total_duration)),
                                font = "CG-pixel-3x5-mono",
                                color = "#ccc",
                            ),
                            color = timing_bg,
                            width = 32,
                            height = 7,
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Read-only API key",
                icon = "key",
            ),
            schema.Text(
                id = "check_token",
                name = "Check Token",
                desc = "The check unique token",
                icon = "check",
            ),
        ],
    )

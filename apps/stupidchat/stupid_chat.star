"""
Applet: Stupid Chat
Summary: Tidbyt Messaging
Description: Send messages to your Tidbyt via https://stupid.chat or an API.
Author: harrisonpage
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

VERSION = "1.0.0"

def get_config(config, key, default):
    value = config.get(key)
    if not value:
        value = default
    return value

def main(config):
    token = get_config(config, "token", "WELCOME")
    client_id = get_config(config, "client_id", "XXX")
    response = http.get(
        "https://api.stupid.chat/v1/" + token + "?client_id=" + client_id + "&format=base64&version=" + VERSION,
        headers = {"User-Agent": "stupid.chat/" + VERSION},
    )
    if response.status_code != 200:
        fail("failed with status %d", response.status_code)
    cooked = response.json()

    if cooked["upload"]:
        return render.Root(
            render.Image(
                src = base64.decode(cooked["image"]),
                width = 64,
                height = 32,
            ),
        )

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    color = "#" + cooked["bgcolor"],
                    child = render.Marquee(
                        offset_start = 32,
                        offset_end = 32,
                        width = 64,
                        height = 32,
                        scroll_direction = cooked["direction"],
                        child = render.Column(
                            children = [
                                render.WrappedText(
                                    content = cooked["message"],
                                    color = "#" + cooked["color"],
                                    font = cooked["font"],
                                    align = cooked["align"],
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "Secret token",
                desc = "Visit https://stupid.chat to get started",
                icon = "eye",
                default = "",
            ),
        ],
    )

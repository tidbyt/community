"""
Applet: Stupid Chat
Summary: Tidbyt chat between friends
Description: Allow friends and family to send messages and images to your Tidbyt.
Author: harrisonpage
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

VERSION = "1.0.0"

def get_config(config, key, default):
    value = config.get(key)
    if not value:
        value = default
    return value

def main(config):
    # get your token at https://stupid.chat
    token = get_config(config, "token", "WELCOME")

    # for internal use only
    client_id = get_config(config, "client_id", "DEFAULT")

    url = "https://api.stupid.chat/v1/" + token + "?client_id=" + client_id + "&format=base64&version=" + VERSION
    response = http.get(url, headers = {"User-Agent": "stupid.chat/" + VERSION})

    if response.status_code != 200:
        # sensible defaults for an error message
        cooked = {
            "direction": "vertical",
            "message": "Stupid Chat is Stupid: HTTP error " + str(response.status_code),
            "color": "00FF00",
            "align": "center",
            "bgcolor": "000000",
            "font": "6x13",
        }
        if response.status_code == 502:
            cooked["message"] = "stupid.chat is stupid"
    else:
        cooked = response.json()

    if "upload" in cooked and cooked["upload"]:
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

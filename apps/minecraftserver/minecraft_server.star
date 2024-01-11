"""
Applet: Minecraft Server
Summary: Minecraft Server Activity
Description: View Minecraft Server Activity and icon.
Author: Michael Blades
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    minecraftURL = config.get("server", "mc.azitoth.com")

    apiURL = "".join(["https://api.mcsrvstat.us/2/", minecraftURL])
    result = http.get(apiURL, ttl_seconds = 300)
    if result.status_code != 200:
        fail("Minecraft API request failed with status %d", result.status_code)
    result_json = result.json()
    onlinePlayers = result_json["players"]["online"] if "players" in result_json else 0
    maxPlayers = result_json["players"]["max"] if "players" in result_json else 0
    motd = result_json["motd"]["clean"][0] if len(result_json["motd"]["clean"]) > 0 else ""
    motd2 = result_json["motd"]["clean"][1] if len(result_json["motd"]["clean"]) > 1 else ""

    iconURL = result_json["icon"].split(",")[1] if "icon" in result_json else "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"

    serverIcon = base64.decode(iconURL)

    return render.Root(
        child = render.Box(
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = serverIcon, width = 25, height = 25),
                    render.Column(
                        children = [
                            render.Marquee(
                                width = 40,
                                child = render.Text(
                                    "%d Online" % onlinePlayers,
                                ),
                            ),
                            render.Marquee(
                                width = 40,
                                child = render.Text("%d Max" % maxPlayers),
                            ),
                            render.Marquee(
                                width = 64,
                                child = render.Text("%s" % motd),
                            ),
                            render.Marquee(
                                width = 64,
                                child = render.Text("%s" % motd2),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server",
                name = "Server URL",
                desc = "URL or IP of Minecraft Server",
                icon = "server",
            ),
        ],
    )

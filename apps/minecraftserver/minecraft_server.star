"""
Applet: Minecraft Server
Summary: Minecraft Server Activity
Description: View Minecraft Server Activity and icon.
Author: Michael Blades
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("schema.star", "schema")

def main(config):
    minecraftURL = config.get("server", "mc.azitoth.com")
    apiURL = "".join(["https://api.mcsrvstat.us/2/", minecraftURL])
    rep = http.get(apiURL)
    if rep.status_code != 200:
        fail("Minecraft API request failed with status %d", rep.status_code)

    onlinePlayers = rep.json()["players"]["online"]
    maxPlayers = rep.json()["players"]["max"]
    motd = rep.json()["motd"]["clean"][0]
    motd2 = rep.json()["motd"]["clean"][1]
    iconURL = rep.json()["icon"].split(",")[1]
    serverIcon = base64.decode("""%s""" % iconURL)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = serverIcon, width = 25, height = 25),
                        render.Column(
                            children = [
                                render.Marquee(
                                    width = 40,
                                    child = render.Text("%d Online" % onlinePlayers),
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
            ],
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

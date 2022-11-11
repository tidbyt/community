"""
Applet: MCServerStatus
Summary: See MC server player count
Description: Track the player count on any MC server!
Author: jakeva
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

def main(config):
    rate_cached = cache.get("mc_rate")

    if rate_cached != None:
        rate = int(rate_cached)

    minecraft_edition = config.get("minecraft_edition") or 0
    server_ip = config.get("server_ip") or "mc.hypixel.net"
    server_port = config.get("server_port") or None

    print(minecraft_edition)

    req = http.get("https://api.mcsrvstat.us/" + ("bedrock/" if minecraft_edition else "") + "2/" + server_ip + (":" + server_port if server_port else ""))

    if req.status_code != 200:
        fail("API request failed with status %d", req.status_code)

    data = req.json()

    # Check if the server is online, if so, get the server icon and player count.
    if data["online"]:
        # Get Server Icon
        if "icon" in data:
            icon = base64.decode(data.get("icon").replace("data:image/png;base64,", ""))
        else:
            icon = base64.decode("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")

        # Get Player Count
        text = str(int(data["players"]["online"]))

        # Cache results
        cache.set("mc_rate", str(int(text)), ttl_seconds = 240)
    else:  # If server is offline/can't be reached, return offline icon and message.
        icon = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAQAAAAEABAMAAACuXLVVAAAAElBMVEUAAADsKRrZKx3/EgDFLSHPLB/LFG4eAAAAAXRSTlMAQObYZgAAAN1JREFUeNrtzrENwzAMRcGskBWyQlbwCt5/FTdmY0MgYLOQwHulAH3eR5IkadS/OAAAAAAAAIB1APHhW1zsAgAAAAAAAMwL+J09k4+77sUdAAAAAAAAgPkB+1kVBAAAAAAAAGA9QLyPIAAAAAAAAAB9ABkEAAAAAAAAoA8ggwAAAAAAAAD0AWQQAAAAAAAAgD6ADAIAAAAAAADQB5BBAAAAAAAAAPoAMggAAAAAAADAeoBqCAAAAAAAAMD8gBvkZdlhAAAAAAAAgHkB0VZc7AIAAAAAAACsA5AkSW06ABAwGnlAZiojAAAAAElFTkSuQmCC")
        text = "Offline"

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = icon, width = 15, height = 15),
                    render.Text(text),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Java",
            value = "0",
        ),
        schema.Option(
            display = "Bedrock",
            value = "1",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "minecraft_edition",
                name = "Minecraft Edition",
                desc = "The Minecraft edition (Java or Bedrock) of the server you want to monitor.",
                icon = "wrench",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "server_ip",
                name = "Server IP",
                desc = "The IP of the Minecraft server you want to monitor.",
                icon = "computer",
            ),
            schema.Text(
                id = "server_port",
                name = "Server Port",
                desc = "The port of the Minecraft server you want to monitor.",
                icon = "gear",
            ),
        ],
    )

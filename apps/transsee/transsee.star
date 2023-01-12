"""
Applet: TransSee
Summary: Realtime transit prediction
Description: Provides real-time transit predictions based on actual travel times for over 150 agencies. Requires paid premium. See transsee.ca/tidbyt for usage information
Author: doconno@gmail.com
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    if config.str("id") == None:
        # Show example image by default when no TransSee Premium Id entered
        return render.Root(render.Column(children = [
            render.Row(children = [
                render.Box(width = 17, height = 8, color = "#6CBE45", child = render.Text(content = "B54", color = "#FFFFFF")),
                render.Text(content = "→7-9,→22-27"),
            ]),
            render.Marquee(width = 64, child = render.Text("See transsee.ca/tidbyt for usage")),
        ]))
    else:
        rep = http.get("https://www.transsee.ca/bitmap?premium=%s" % config.str("id"))
        if rep.status_code == 200:
            col = []
            jsonarray = rep.json()
            for json in jsonarray:
                col.append(render.Row(
                    children = [
                        render.Box(width = 17, height = 8, color = json["routeColour"], child = render.Text(content = json["routeName"], color = json["textColour"])),
                        render.Text(content = json["pred"]),
                    ],
                ))
                if len(jsonarray) <= 2:
                    if config.bool("scroll"):
                        col.append(render.Marquee(width = 64, child = render.Text(json["dest"])))
                    else:
                        col.append(render.Text(json["dest"]))

            return render.Root(render.Column(children = col))
        else:
            # Return [] to remove from cycle when no stops activated
            return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "id",
                name = "TransSee Premium Id",
                desc = "In premium email or transsee.ca/tidbyt",
                icon = "hashtag",
            ),
            schema.Toggle(
                id = "scroll",
                name = "Scroll destination",
                desc = "Horizontally scroll the destination when it doesn't fit.",
                icon = "leftRight",
                default = True,
            ),
        ],
    )

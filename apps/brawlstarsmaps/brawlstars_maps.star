"""
Applet: BrawlStars Maps
Summary: Current Brawl Stars maps
Description: Shows a random map from the current maps available in the game Brawl Stars Powered by Brawlify.
Author: Lucas Farah
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(ctx):
    random.seed(time.now().unix // 15)
    resp = http.get("https://api.brawlapi.com/v1/events")
    if resp.status_code != 200:
        return render.Text("Error fetching maps", ctx)

    data = resp.json()
    maps = data["active"]  # Replace 'maps' with the correct property name according to the API response structure

    if len(maps) == 0:
        return render.Text("No maps found", ctx)

    num = random.number(0, len(maps) - 1)
    random_map = maps[num]
    map_name = random_map["map"]["name"]  # Replace 'name' with the correct property name according to the API response structure
    map_image_url = random_map["map"]["imageUrl"]  # Replace 'imageUrl' with the correct property name according to the API response structure

    map_info = map_name

    gameModeId = random_map["slot"]["id"]
    gameResp = http.get("https://api.brawlapi.com/v1/gamemodes/%d" % gameModeId)
    gameURL = gameResp.json()["imageUrl"]
    gameImage = http.get(gameURL).body()

    imageResp = http.get(map_image_url)

    map_image = imageResp.body()

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = map_image, width = 20, height = 40),
                    render.Column(
                        children = [
                            render.Image(src = gameImage, width = 10, height = 10),
                            render.WrappedText(map_info),
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
        ],
    )

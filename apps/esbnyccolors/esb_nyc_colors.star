"""
Applet: ESB NYC Colors
Summary: Empire State Bld Colors
Description: Shows today's colors of the Empire State Building.
Author: sklose
"""

load("http.star", "http")
load("render.star", "render")

def main():
    rep = http.get("https://lzxe5agehadtlh2kaecrlk62c40dimdp.lambda-url.us-east-1.on.aws/", ttl_seconds = 3600)
    if rep.status_code != 200:
        fail("request failed with status %d", rep.status_code)

    json = rep.json()
    description = json["description"]
    color1 = json["colors"][0]
    color2 = json["colors"][0]
    color3 = json["colors"][0]

    if len(json["colors"]) > 1:
        color2 = json["colors"][1]
        color3 = json["colors"][1]

    if len(json["colors"]) > 2:
        color3 = json["colors"][2]

    colorMap = {
        "blue": "#00f",
        "red": "#f00",
        "green": "#0f0",
        "white": "#fff",
        "yellow": "#ff9",
        "purple": "#808",
        "pink": "#f0b",
        "orange": "#fa0",
        "brown": "#a22",
        "gold": "#fd0",
        "teal": "#088",
    }

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 128,
                    child = render.Text(
                        content = description,
                        font = "Dina_r400-6",
                    ),
                ),
                render.Box(
                    color = colorMap[color1],
                    child = render.Box(
                        width = 40,
                        height = 16,
                        color = colorMap[color2],
                        child = render.Box(
                            width = 20,
                            height = 8,
                            color = colorMap[color3],
                        ),
                    ),
                ),
            ],
        ),
    )

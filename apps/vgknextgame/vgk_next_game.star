"""
Applet: VGK Next Game
Summary: Shows next VGK Game
Description: Shows the date of the next Vegas Golden Knights game.
Author: theimpossibleleap
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

timestamp = time.now().format("2006-01-02")

vgkNextGameWeek = "https://api-web.nhle.com/v1/club-schedule/VGK/week/" + timestamp

def main():
    response = http.get(vgkNextGameWeek.format(ttl_seconds = 3600))

    d = response.json()

    if response.status_code != 200:
        fail("Server request failed with status %d", response.status_code)

    if len(d["games"]) == 0:
        nextStartDate = "> 1 week"
        nextHomeTeam = ""
        nextAwayTeam = ""
        at = "Go Knights"
    else:
        nextStartDate = d["games"][0]["gameDate"]
        nextHomeTeam = d["games"][0]["homeTeam"]["abbrev"]
        nextAwayTeam = d["games"][0]["awayTeam"]["abbrev"]
        at = " @ "

    img = base64.decode("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")

    return render.Root(
        render.Box(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(img),
                    render.Column(
                        children = [
                            render.Box(
                                child = render.Column(
                                    children = [
                                        render.Text(content = " Next Game:", font = "tom-thumb", color = "B4975A"),
                                        render.Text(content = " " + nextStartDate, font = "tom-thumb"),
                                        render.Text(content = " " + nextAwayTeam + at + nextHomeTeam, font = "tom-thumb"),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

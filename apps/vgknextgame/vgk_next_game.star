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
        nextStartDate = nextStartDate.split("-")
        year = nextStartDate.pop(0)
        nextStartDate.append(year)
        nextStartDate = "-".join(nextStartDate)

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
                                        render.Text(content = "NEXT GAME:", font = "tom-thumb", color = "B4975A"),
                                        render.Text(content = "" + nextStartDate, font = "tom-thumb"),
                                        render.Text(content = "" + nextAwayTeam + at + nextHomeTeam, font = "tom-thumb"),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

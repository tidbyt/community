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

DEFAULT_TIMEZONE = "US/Pacific"

def main(config):
    device_tz = config.get("$tz", DEFAULT_TIMEZONE)

    def convertTime(utcTimestamp):
        t = time.parse_time(utcTimestamp)
        pst = t.in_location(device_tz)
        pst.format("2006-01-02T15:04:05Z07:00")

        return pst.format("3:04PM")

    response = http.get(vgkNextGameWeek.format(ttl_seconds = 3600))

    d = response.json()

    if response.status_code != 200:
        fail("Server request failed with status %d", response.status_code)

    if len(d["games"]) == 0:
        nextStartDate = "> 1 week"
        nextStartTime = ""
        nextHomeTeam = ""
        nextAwayTeam = ""
        at = "Go Knights"
    else:
        nextStartDate = d["games"][0]["gameDate"]
        nextStartTime = convertTime(d["games"][0]["startTimeUTC"])

        nextStartDate = nextStartDate.split("-")
        year = nextStartDate.pop(0)[2:4]
        nextStartDate.append(year)
        nextStartDate = "-".join(nextStartDate)

        nextHomeTeam = d["games"][0]["homeTeam"]["abbrev"]
        nextAwayTeam = d["games"][0]["awayTeam"]["abbrev"]
        at = " @ "

    img = base64.decode("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")

    return render.Root(
        delay = 500,
        child = render.Box(
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
                                        render.Text(content = "NEXT GAME:", font = "tom-thumb", color = "C8102E"),
                                        render.Text(content = "" + nextAwayTeam + at + nextHomeTeam, font = "tom-thumb", color = "B4975A"),
                                        render.Text(content = "" + nextStartDate, font = "tom-thumb"),
                                        render.Animation(
                                            children = [
                                                render.Text(content = "" + nextStartTime, font = "tom-thumb"),
                                                render.Text(content = "" + nextStartTime.replace(":", " "), font = "tom-thumb"),
                                            ],
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

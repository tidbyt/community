"""
Applet: PGA Tour
Summary: Shows PGA Leaderboard
Description: This app displays the leaderboard for the current PGA Tour event, taken from ESPN data feed. The leaderboard will show the first 24 players. Players currently on course are shown in different shades of yellow - going from dark yellow for those players just starting to white for those who have completed their rounds. Players who have not started are shown in green.
Author: M0ntyP

Note - can easily make LPGA, European Tour or Korn Ferry versions if there is enough interest.

Big shoutout to LunchBox8484 for the NHL Standings app where this is heavily borrowed/stolen from
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")
load("math.star", "math")
load("encoding/json.star", "json")

API = "https://site.web.api.espn.com/apis/v2/scoreboard/header?sport=golf&league=pga"
CACHE_TTL_SECS = 60

def main():
    renderCategory = []

    CacheData = get_cachable_data(API, CACHE_TTL_SECS)
    leaderboard = json.decode(CacheData)

    mainFont = "CG-pixel-3x5-mono"
    Title = leaderboard["sports"][0]["leagues"][0]["name"]
    TournamentName = leaderboard["sports"][0]["leagues"][0]["events"][0]["name"]
    Location = leaderboard["sports"][0]["leagues"][0]["events"][0]["location"]
    StartDate = leaderboard["sports"][0]["leagues"][0]["events"][0]["date"]
    EndDate = leaderboard["sports"][0]["leagues"][0]["events"][0]["endDate"]
    RoundNumber = leaderboard["sports"][0]["leagues"][0]["events"][0]["fullStatus"]["period"]

    StartDateFormat = time.parse_time(StartDate, format = "2006-01-02T15:04:00Z")
    EndDateFormat = time.parse_time(EndDate, format = "2006-01-02T15:04:00Z")
    StartDate = StartDateFormat.format("Jan 2")
    EndDate = EndDateFormat.format("Jan 2")

    if (leaderboard):
        stage1 = leaderboard["sports"][0]["leagues"][0]["events"][0]["status"]

        # In progress or completed tournament
        if stage1 == "in" or stage1 == "post":
            for i, s in enumerate(leaderboard["sports"][0]["leagues"][0]["events"]):
                entries = s["competitors"]
                stage = s["fullStatus"]["type"]["detail"]
                state = s["fullStatus"]["type"]["state"]

                # shortening status messages
                stage = stage.replace("Final", "F")
                stage = stage.replace("Round 1", "R1")
                stage = stage.replace("Round 2", "R2")
                stage = stage.replace("Round 3", "R3")
                stage = stage.replace("Round 4", "R4")
                stage = stage.replace(" - In Progress", "")
                stage = stage.replace(" - Suspended", "")
                stage = stage.replace(" - Play Complete", "")

                if entries:
                    # how many players per page?
                    entriesToDisplay = 4

                    # len(entries)-1 = 24 and divides into 4 nicely
                    for x in range(0, len(entries) - 1, entriesToDisplay):
                        renderCategory.extend([
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = get_player(x, entries, entriesToDisplay, 28, TournamentName, 5, stage, state),
                                    ),
                                ],
                            ),
                        ])

            return render.Root(
                # seconds per cycle
                delay = int(2500),
                child = render.Animation(children = renderCategory),
            )

            # if there is no live tournament, show what event is coming up next
        elif stage1 == "pre":
            return render.Root(
                child = render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 5, color = "#0039A6", child = render.Text(content = Title, color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 12, color = "#000", child = render.Text(content = "Next event...", color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Marquee(width = 64, height = 12, child = render.Text(content = TournamentName + " - " + Location, color = "#FFF", font = mainFont)),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 10, color = "#000", child = render.Text(content = StartDate + " - " + EndDate, color = "#FFF", font = mainFont)),
                            ],
                        ),
                    ],
                ),
            )

def get_player(x, s, entriesToDisplay, colHeight, Title, topcolHeight, stage, state):
    # keep first 10 chars of the tournament name, then remove any extra " " at the end
    Title = Title[:10]
    Title = Title.rstrip()
    mainFont = "CG-pixel-3x5-mono"
    output = []

    topColumn = [render.Box(width = 64, height = topcolHeight, color = "#0039A6", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = topcolHeight, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)
    containerHeight = int(colHeight / 4)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            playerName = s[i + x]["lastName"]
            score = s[i + x]["score"]
            displayScore = str(score)

            # check if they've played at least 1 hole this round
            if (s[i + x]["status"]["thru"]) > 0:
                HolesCompleted = s[i + x]["status"]["thru"]
            else:
                HolesCompleted = 0

            # check if the entire round has been completed
            # once round is complete, "thru" resets to 0 so it can make it look like players have not started their round
            if state == "post":
                HolesCompleted = 18

            # Players who have completed their round are shown in white, in progress rounds are in yellow which slowly transitions to white as the round progresses.
            # This is the best thing I can think of at the moment as there is not enough room to fit the hole number on the screen as well as name & score
            # Maybe nested animations to show score then hole number in that box, not recommended according to the doco though
            playerFontColor = get_player_font_color(HolesCompleted)

            # if tournament is over, show winner in blue
            if (i + x) == 0 and stage == "F":
                playerFontColor = "#68f"

            player = render.Row(
                children = [
                    render.Box(
                        height = 7,
                        width = (52, 32)[0],
                        child = render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Marquee(
                                width = (52, 32)[0],
                                child = render.Text(
                                    content = playerName,
                                    color = playerFontColor,
                                    font = mainFont,
                                    offset = 0,
                                ),
                            ),
                        ),
                    ),
                    render.Box(
                        height = 7,
                        width = (12, 32)[0],
                        child = render.Text(
                            content = displayScore,
                            color = playerFontColor,
                            font = mainFont,
                            offset = 0,
                        ),
                    ),
                ],
            )
            output.extend([player])
    return output

def get_player_font_color(HolesCompleted):
    if HolesCompleted == 18:
        playerFontColor = "#fff"
    elif HolesCompleted == 17:
        playerFontColor = "#ffa"
    elif HolesCompleted == 16:
        playerFontColor = "#ff5"
    elif HolesCompleted == 14 or HolesCompleted == 15:
        playerFontColor = "#ff0"
    elif HolesCompleted == 12 or HolesCompleted == 13:
        playerFontColor = "#fe0"
    elif HolesCompleted == 10 or HolesCompleted == 11:
        playerFontColor = "#fd0"
    elif HolesCompleted == 8 or HolesCompleted == 9:
        playerFontColor = "#fc0"
    elif HolesCompleted == 6 or HolesCompleted == 7:
        playerFontColor = "#fb0"
    elif HolesCompleted == 4 or HolesCompleted == 5:
        playerFontColor = "#fa0"
    elif HolesCompleted == 2 or HolesCompleted == 3:
        playerFontColor = "#f90"
    elif HolesCompleted == 1:
        playerFontColor = "#f80"
    elif HolesCompleted == 0:
        playerFontColor = "#4ec9b0"
    return playerFontColor

def get_cachable_data(url, timeout):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        #print("Using cached data")
        return base64.decode(data)

    res = http.get(url = url)

    #print("Getting new data")
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)

    return res.body()

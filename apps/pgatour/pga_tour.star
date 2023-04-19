"""
Applet: PGA Tour
Summary: Shows PGA Leaderboard
Description: This app displays the leaderboard for the current PGA Tour event. You can show the opposite field event if there is one. 
Author: M0ntyP

Note - can easily make LPGA, European Tour or Korn Ferry versions if there is enough interest.

Big shoutout to LunchBox8484 for the NHL Standings app where this is heavily borrowed/stolen from

v1.1 
Added rotation speed options and slight formatting change to tournament title (removed "The")

v1.2 
Added ability to show opposite field events, for the 4 times a year this happens

v1.2b 
Bug fix - when there are multiple events on (opposite field events) the app is showing both leaderboards under the 1 tournament heading
This has been fixed

v2.0 - Major update
Added ability to show how many holes the player has completed or tee time if not started. Shade of yellow font color function still in place as well
Added different colors for title bar during majors
Formatting changes
Code re-arrange & clean up and hopefully more efficient!

v2.1
Fix - Colors for majors not working, fixed!
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://site.web.api.espn.com/apis/v2/scoreboard/header?sport=golf&league=pga"

CACHE_TTL_SECS = 60
DEFAULT_TIMEZONE = "Australia/Adelaide"

def main(config):
    renderCategory = []
    i = 0
    mainFont = "CG-pixel-3x5-mono"

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    RotationSpeed = config.get("speed", "3")
    OppField = config.bool("OppFieldToggle")

    CacheData = get_cachable_data(API, CACHE_TTL_SECS)
    leaderboard = json.decode(CacheData)

    Title = leaderboard["sports"][0]["leagues"][0]["shortName"]

    # Check if there is an opposite field event, happens 4 times a season
    # Get the ID of the first event listed in the API
    TournamentID = leaderboard["sports"][0]["leagues"][0]["events"][0]["id"]
    i = OppositeFieldCheck(TournamentID)

    # if user wants to see opposite event
    if i == 1 and OppField == True:
        i = 0

    # Check if its a major and show a different color in the title bar
    TitleColor = getMajorColor(TournamentID)

    TournamentName = leaderboard["sports"][0]["leagues"][0]["events"][i]["name"]

    if (leaderboard):
        # where the tournament is at - pre, in progress, post
        status = leaderboard["sports"][0]["leagues"][0]["events"][i]["status"]

        # if in progress or completed tournament
        if status == "in" or status == "post":
            entries = leaderboard["sports"][0]["leagues"][0]["events"][i]["competitors"]
            stage = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["detail"]
            state = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["state"]

            # shortening status messages
            stage = stage.replace("Final", "F")
            stage = stage.replace("Round 1", "R1")
            stage = stage.replace("Round 2", "R2")
            stage = stage.replace("Round 3", "R3")
            stage = stage.replace("Round 4", "R4")
            stage = stage.replace(" - In Progress", "")
            stage = stage.replace(" - Suspended", "")
            stage = stage.replace(" - Play Complete", "")
            stage = stage.replace(" - Playoff", "PO")
            stage = stage.replace("Playoff - Play Complete", "PO")

            if entries:
                if stage != "F":
                    # len(entries)-1 = 24 and divides into 4 nicely
                    for x in range(0, len(entries) - 1, 4):
                        renderCategory.extend([
                            render.Column(
                                children = [
                                    render.Column(
                                        getPlayerScore(x, entries, TournamentName, TitleColor, stage, state),
                                    ),
                                ],
                            ),
                            render.Column(
                                children = [
                                    render.Column(
                                        children = getPlayerProgress(x, entries, TournamentName, TitleColor, stage, state, timezone),
                                    ),
                                ],
                            ),
                        ])

                elif stage == "F":
                    # len(entries)-1 = 24 and divides into 4 nicely
                    for x in range(0, len(entries) - 1, 4):
                        renderCategory.extend([
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = getPlayerScore(x, entries, TournamentName, TitleColor, stage, state),
                                    ),
                                ],
                            ),
                        ])

            return render.Root(
                show_full_animation = True,
                delay = int(RotationSpeed) * 1000,
                child = render.Animation(children = renderCategory),
            )

        elif status == "pre":
            # Tournament hasn't started yet
            # Get details for the tournament
            Location = leaderboard["sports"][0]["leagues"][0]["events"][i]["location"]
            StartDate = leaderboard["sports"][0]["leagues"][0]["events"][i]["date"]
            EndDate = leaderboard["sports"][0]["leagues"][0]["events"][i]["endDate"]
            StartDateFormat = time.parse_time(StartDate, format = "2006-01-02T15:04:00Z")
            EndDateFormat = time.parse_time(EndDate, format = "2006-01-02T15:04:00Z")
            StartDate = StartDateFormat.format("Jan 2")
            EndDate = EndDateFormat.format("Jan 2")

            # show what event is coming up next
            return render.Root(
                show_full_animation = True,
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

    return []

def getPlayerScore(x, s, Title, TitleColor, stage, state):
    # Build the 4 rows out with player names & scores

    # Remove "The" or "THE" if its in the title, but not for "The Open", its a major so we treat it with respect...and it will fit anyway
    if Title.startswith("The") or Title.startswith("THE"):
        if Title != "The Open":
            Title = Title.replace("The ", "")
            Title = Title.replace("THE ", "")

    # keep first 10 chars of the tournament name, then remove any extra " " at the end
    Title = Title[:10]
    Title = Title.rstrip()

    mainFont = "CG-pixel-3x5-mono"
    output = []

    topColumn = [render.Box(width = 64, height = 5, color = TitleColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)

    for i in range(0, 4):
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
            playerFontColor = getPlayerFontColor(HolesCompleted)

            # if tournament is over, show winner in blue
            if (i + x) == 0 and stage == "F":
                playerFontColor = "#68f"

            player = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        main_align = "start",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = playerName[:12],
                                    color = playerFontColor,
                                    font = mainFont,
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (0, 1, 0, 1),
                                child = render.Text(
                                    content = displayScore,
                                    color = playerFontColor,
                                    font = mainFont,
                                ),
                            ),
                        ],
                    ),
                ],
            )

            output.extend([player])

    return output

def getPlayerProgress(x, s, Title, TitleColor, stage, state, timezone):
    # Build the 4 rows out with player names & how many holes completed or tee times

    # Remove "The" or "THE" if its in the title, but not for "The Open", its a major so we treat it with respect...and it will fit anyway
    if Title.startswith("The") or Title.startswith("THE"):
        if Title != "The Open":
            Title = Title.replace("The ", "")
            Title = Title.replace("THE ", "")

    # keep first 10 chars of the tournament name, then remove any extra " " at the end
    Title = Title[:10]
    Title = Title.rstrip()

    mainFont = "CG-pixel-3x5-mono"
    output = []

    topColumn = [render.Box(width = 64, height = 5, color = TitleColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)

    for i in range(0, 4):
        ProgressStr = ""
        if i + x < len(s):
            playerName = s[i + x]["lastName"]
            playerState = s[i + x]["status"]["state"]

            # check if they've played at least 1 hole this round
            if (s[i + x]["status"]["thru"]) > 0:
                HolesCompleted = s[i + x]["status"]["thru"]
            else:
                HolesCompleted = 0

            # check if the entire round has been completed
            # once round is complete for all players, "thru" resets to 0 so it can make it look like players have not started their round
            if state == "post":
                HolesCompleted = 18

            # if the player hasn't started their round, show their tee time in your local time
            if playerState == "pre":
                TeeTime = s[i + x]["status"]["teeTime"]
                TeeTimeFormat = time.parse_time(TeeTime, format = "2006-01-02T15:04Z").in_location(timezone)
                TeeTime = TeeTimeFormat.format("15:04")
                ProgressStr = TeeTime

            # if the player's round is underway, show how many completed holes
            if playerState == "in" or playerState == "post":
                ProgressStr = str(HolesCompleted)

            # if the player's round is completed, show "F"
            if playerState == "post":
                ProgressStr = "F"

            # Players who have completed their round are shown in white, in progress rounds are in yellow which slowly transitions to white as the round progresses.
            playerFontColor = getPlayerFontColor(HolesCompleted)

            # show condensed player names (down to 10 due to potential tee time being shown, so need more room) and how many holes they've played
            player = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        main_align = "start",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = playerName[:10],
                                    color = playerFontColor,
                                    font = mainFont,
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (0, 1, 0, 1),
                                child = render.Text(
                                    content = ProgressStr,
                                    color = playerFontColor,
                                    font = mainFont,
                                ),
                            ),
                        ],
                    ),
                ],
            )

            output.extend([player])
    return output

def getPlayerFontColor(HolesCompleted):
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
    else:
        playerFontColor = ""

    return playerFontColor

def getMajorColor(ID):
    # check if its a major and if so show different title bar color
    # and if not, show the default PGA color
    TitleColor = "#0039A6"
    if ID == "401465508":  # Masters
        TitleColor = "#006747"
    elif ID == "401465523":  # US PGA
        TitleColor = "#00205b"
    elif ID == "401465533":  # US Open
        TitleColor = "#003865"
    elif ID == "401465539":  # The Open
        TitleColor = "#1a1c3c"
    else:
        TitleColor = "#0039A6"
    return TitleColor

def OppositeFieldCheck(ID):
    # check if the first tournament listed in the ESPN API is an opposite field event, one of the four below
    # and if it is, go to the second event in the API
    i = 0
    if ID == "401465525":  # Puerto Rico Open
        i = 1
    elif ID == "401465529":  # Puntacana
        i = 1
    elif ID == "401465538":  # Barbasol
        i = 1
    elif ID == "401465540":  # Barracuda
        i = 1
    else:
        i = 0
    return i

RotationOptions = [
    schema.Option(
        display = "2 seconds",
        value = "2",
    ),
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each page is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
            schema.Toggle(
                id = "OppFieldToggle",
                name = "Show Opposite Field event",
                desc = "Show the opposite event",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

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

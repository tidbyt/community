"""
Applet: PGA Tour
Summary: Shows PGA Leaderboard
Description: This app displays the leaderboard for the current PGA Tour event. You can show the opposite field event if there is one. 
Author: M0ntyP

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

v2.1a
Updated caching function

v2.2
Added better playoff handling

v2.3 
Give user a choice of single color for the in progress rounds or use the color gradient option. Single color is the default
Now showing scores for completed rounds rather than "F" 
Removed tournament name formatting from both player/score related functions - should add efficiency?
Added function to revise some tournament names to make them more readable and/or fit the width of the Tidbyt better

v2.3.1
Fixed bug regarding opposite field events

v2.4
Changed tee times feature to only display them when the leader's time is less than 12hrs away, and then show everyone's tee time. Previously it was showing a mix of round scores and tee times, which didnt look right

v2.5
Updated Tournament IDs for 2024 Season

v2.6
Added handling for players with non-standard characters in their surname and also distinguish between players with same surname
Using dictionary list for shortened Tournament Names
Using dictionary list for colors in Majors (and The Players tournament)

v2.6.1
Updated PLAYER_MAPPING 

v2.6.2
Updated PLAYER_MAPPING
Allowed extra char in Tournament Name

v2.6.3
Updated Player Name Mapping logic to stop partial ID matches

v2.7
Bug fix - During play, the completed round scores were showing the previous round's score

v2.8
Fixed situation that when play is suspended, "state" value = "post" (round is complete) and does not show in progress scores for the suspended round,
Also, updated title bar to show that play is suspended 

v2.9
Updated Tournament IDs for 2025 Season

v2.9.1
Updated PLAYER_MAPPING

v2.9.2
Updated ID for The Players

v2.9.3
Updated PLAYER_MAPPING
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://site.web.api.espn.com/apis/v2/scoreboard/header?sport=golf&league=pga"
API2 = "https://site.api.espn.com/apis/site/v2/sports/golf/pga/scoreboard"

CACHE_TTL_SECS = 60
DEFAULT_TIMEZONE = "Australia/Adelaide"
THE_EXCEPTIONS = ["401703489", "401703521"]  # The Sentry and The Open

# List will be a work in progress
PLAYER_MAPPING = """
{
    "11250": "N.Hojgaard",
    "11253": "R.Hojgaard",
    "4375972": "Aberg",
    "9469": "Bjork",
    "4602673": "T.Kim",
    "7081": "S.W.Kim",
    "4698579": "S.H.Kim",
    "4410932": "M.W.Lee",
    "7083": "K.H.Lee",
    "4585548": "Valimaki",
    "8974": "M.Kim",
    "4382434": "Norgaard"
}
"""

TOURNAMENT_MAPPING = """
{
    "401703491": "The AmEx",
    "401703492": "Farmers Ins",
    "401703493": "AT&T Pro-Am",
    "401703495": "Genesis Inv",
    "401703498": "Arnold Palm",
    "401703500": "The Players",
    "401703507": "Zurich Clas",
    "401703506": "Puntacana",
    "401703508": "The CJ Cup",
    "401703501": "Valspar",
    "401703502": "Houston Opn",
    "401703503": "Texas Open",
    "401703504": "The Masters",
    "401703505": "Heritage",
    "401703514": "Canadian Op",
    "401703513": "Memorial",
    "401703511": "PGA Champ",
    "401465538": "Barbasol",
    "401703519": "Scottish",
    "401703524": "Wyndham",
    "401703525": "FedEx St.J",
    "401703530": "BMW Champ",
    "401558309": "Q-School",
    "401703520": "ISCO Champ",
    "401703522": "Barracuda",
    "401703531": "TOUR CHAMP"
}
"""

MAJOR_MAPPING = """
{
    "401703500": "#003360",
    "401703504": "#006747",
    "401703511": "#00205B",
    "401703515": "#003865",
    "401703521": "#1A1C3C"
}
"""

def main(config):
    renderCategory = []
    i = 0
    mainFont = "CG-pixel-3x5-mono"

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    RotationSpeed = config.get("speed", "3")
    OppField = config.bool("OppFieldToggle")
    ColorGradient = config.get("ColorGradient", "False")

    CacheData = get_cachable_data(API, CACHE_TTL_SECS)
    SecCacheData = get_cachable_data(API2, CACHE_TTL_SECS)
    leaderboard = json.decode(CacheData)
    leaderboard2 = json.decode(SecCacheData)

    PlayerMapping = json.decode(PLAYER_MAPPING)
    TournMapping = json.decode(TOURNAMENT_MAPPING)
    MajorMapping = json.decode(MAJOR_MAPPING)

    Title = leaderboard["sports"][0]["leagues"][0]["shortName"]

    # Check if there is an opposite field event
    # Get the ID of the first event listed in the API
    FirstTournamentID = leaderboard["sports"][0]["leagues"][0]["events"][0]["id"]

    # check if user wants to see opp field
    if OppField == True:
        i = OppositeFieldCheck(FirstTournamentID)

    # Get Tournament Name and ID
    TournamentName = leaderboard["sports"][0]["leagues"][0]["events"][i]["name"]
    PreTournamentName = TournamentName
    TournamentID = leaderboard["sports"][0]["leagues"][0]["events"][i]["id"]

    # Check if its a major (or The Players) and show a different color in the title bar
    if TournamentID in MAJOR_MAPPING:
        TitleColor = MajorMapping[TournamentID]
    else:
        TitleColor = "#0039A6"

    # Make the tournament name more readable
    if TournamentID not in THE_EXCEPTIONS:
        TournamentName = TournamentName.replace("The ", "")
        TournamentName = TournamentName.replace("THE ", "")

    if TournamentID in TOURNAMENT_MAPPING:
        TournamentName = TournMapping[TournamentID]
    else:
        TournamentName = TournamentName[:11]
        TournamentName = TournamentName.rstrip()

    if (leaderboard):
        # where the tournament is at - pre, in progress, post
        status = leaderboard["sports"][0]["leagues"][0]["events"][i]["status"]

        # if in progress or completed tournament
        if status == "in" or status == "post":
            entries = leaderboard["sports"][0]["leagues"][0]["events"][i]["competitors"]
            entries2 = leaderboard2["events"][i]["competitions"][0]["competitors"]
            stage = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["detail"]
            state = leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["state"]

            # Noted situation that when play is suspended, "state" value = "post" (round is complete) and does not show in progress scores for the suspended round
            if leaderboard["sports"][0]["leagues"][0]["events"][i]["fullStatus"]["type"]["name"] == "STATUS_SUSPENDED":
                state = "in"
                ProgressTitle = "PLAY SUSP"
            else:
                ProgressTitle = TournamentName

            # shortening status messages
            stage = stage.replace("Final", "F")
            stage = stage.replace("Round 1", "R1")
            stage = stage.replace("Round 2", "R2")
            stage = stage.replace("Round 3", "R3")
            stage = stage.replace("Round 4", "R4")
            stage = stage.replace("Playoff - Play Complete", "PO")
            stage = stage.replace(" - In Progress", "")
            stage = stage.replace(" - Suspended", "")
            stage = stage.replace(" - Play Complete", "")
            stage = stage.replace(" - Playoff", "PO")

            if entries:
                if stage != "F":
                    # len(entries)-1 = 24 and divides into 4 nicely
                    for x in range(0, len(entries) - 1, 4):
                        renderCategory.extend([
                            render.Column(
                                children = [
                                    render.Column(
                                        getPlayerScore(x, entries, TournamentName, TitleColor, ColorGradient, stage, state, PlayerMapping),
                                    ),
                                ],
                            ),
                            render.Column(
                                children = [
                                    render.Column(
                                        children = getPlayerProgress(x, entries, entries2, ProgressTitle, TitleColor, ColorGradient, stage, state, timezone, PlayerMapping),
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
                                        children = getPlayerScore(x, entries, TournamentName, TitleColor, ColorGradient, stage, state, PlayerMapping),
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
                                render.Marquee(width = 64, height = 12, child = render.Text(content = PreTournamentName + " - " + Location, color = "#FFF", font = mainFont)),
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

def getPlayerScore(x, s, Title, TitleColor, ColorGradient, stage, state, Mapping):
    # Build the 4 rows out with player names & scores

    mainFont = "CG-pixel-3x5-mono"
    output = []

    topColumn = [render.Box(width = 64, height = 5, color = TitleColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)

    for i in range(0, 4):
        if i + x < len(s):
            playerID = s[i + x]["id"]

            # Check for certain player IDs and outputs an altername name if needed
            if playerID in Mapping:
                playerName = Mapping[playerID]

            else:
                playerName = s[i + x]["lastName"][:12]

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
            playerFontColor = getPlayerFontColor(HolesCompleted, ColorGradient)

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
                                    content = playerName,
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

def getPlayerProgress(x, s, t, Title, TitleColor, ColorGradient, stage, state, timezone, Mapping):
    # Build the 4 rows out with player names & how many holes completed or tee times

    mainFont = "CG-pixel-3x5-mono"
    output = []
    ShowTeeTimes = False
    #Mapping = json.decode(PLAYER_MAPPING)

    topColumn = [render.Box(width = 64, height = 5, color = TitleColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = 5, child = render.Text(content = Title + " - " + stage, color = "#fff", font = mainFont)),
    ]))]

    output.extend(topColumn)

    LeaderTeeTime = s[0]["status"]["teeTime"]
    LeaderTeeTimeFormat = time.parse_time(LeaderTeeTime, format = "2006-01-02T15:04Z").in_location(timezone)
    TimeDiff = LeaderTeeTimeFormat - time.now()

    #print(TimeDiff)
    if TimeDiff.hours < 12:
        ShowTeeTimes = True

    for i in range(0, 4):
        ProgressStr = ""
        if i + x < len(s):
            playerState = s[i + x]["status"]["state"]
            playerID = s[i + x]["id"]

            # Check for certain player IDs and outputs an altername name if needed
            if playerID in Mapping:
                playerName = Mapping[playerID]
            else:
                playerName = s[i + x]["lastName"][:12]

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
            # also check its not a playoff
            # Only show tee times if its less than 12hrs until the leader tees off
            if playerState == "pre":
                if s[i + x]["status"]["playoff"] != True:
                    if ShowTeeTimes == True:
                        TeeTime = s[i + x]["status"]["teeTime"]
                        TeeTimeFormat = time.parse_time(TeeTime, format = "2006-01-02T15:04Z").in_location(timezone)
                        TeeTime = TeeTimeFormat.format("15:04")
                        ProgressStr = TeeTime
                    else:
                        RoundNumber = len(t[0]["linescores"]) - 2
                        for i in range(0, len(t), 1):
                            if playerID == t[i]["id"]:
                                RoundScore = t[i]["linescores"][RoundNumber]["value"]
                                ProgressStr = str(int(RoundScore))

                else:
                    ProgressStr = "PO"

            # if the player's round is underway, show how many completed holes
            # also check its not a playoff
            if playerState == "in":
                if s[i + x]["status"]["playoff"] != True:
                    ProgressStr = str(HolesCompleted)
                else:
                    ProgressStr = "PO"

            # if the player's round is completed, show their score
            if playerState == "post":
                for i in range(0, len(t), 1):
                    if playerID == t[i]["id"]:
                        CompletedRound = len(t[i]["linescores"]) - 2

                        RoundScore = t[i]["linescores"][CompletedRound]["value"]
                        ProgressStr = str(int(RoundScore))

            # If ColorGradient is selected...
            # Players who have completed their round are shown in white, in progress rounds are in dark yellow/orange which slowly transitions to white as the round progresses.
            # Otherwise in progress is a single shade of yellow
            playerFontColor = getPlayerFontColor(HolesCompleted, ColorGradient)

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

def getPlayerFontColor(HolesCompleted, ColorGradient):
    playerFontColor = ""

    if ColorGradient == "False":
        if HolesCompleted == 18:
            playerFontColor = "#fff"
        elif HolesCompleted == 0:
            playerFontColor = "#4ec9b0"
        else:
            playerFontColor = "#ff0"

    elif ColorGradient == "True":
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

def OppositeFieldCheck(ID):
    # check the ID of the event, and if its a tournament with an opposite field go to the second event in the API
    i = 0
    if ID == "401703509":  # Truist -> Myrtle Beach
        i = 1
    elif ID == "401703521":  # The Open -> Barracuda
        i = 1
    elif ID == "401703519":  # Scottish Open -> ISCO Champ
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

ColorGradientOptions = [
    schema.Option(
        display = "Color Gradient",
        value = "True",
    ),
    schema.Option(
        display = "Single Color",
        value = "False",
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
            schema.Dropdown(
                id = "ColorGradient",
                name = "Show in progress round as ...",
                desc = "How to show in progress rounds",
                icon = "gear",
                default = ColorGradientOptions[1].value,
                options = ColorGradientOptions,
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
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

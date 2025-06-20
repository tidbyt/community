"""
Applet: WTA Tennis
Summary: Shows WTA scores
Description: Display tennis scores from a tournament chosen in the dropdown. Shows live matches and if selected, any match completed in the past 24 hours.
Author: M0ntyP

v1.1
Used "post" state for completed matches, this will capture both Final and Retired
Added handling for when no tournaments are on

v1.2
Show city name instead of official tournament title once the tournament starts, except for Slams
Added handling for walkovers
Extended player surname field by 2 chars

v1.2b
Update title bar color to distinguish between WTA & ATP apps

v1.3
Sometimes the data feed will still show matches as "In Progress" after they have completed. Have added a 24hr limit so that if the start date is > 24 hrs ago then don't list the match

v1.4
Updated caching function
Current server now indicated in green

v1.4.1
Fixed bug which appears when player who is serving is not being provided by data feed. Code now checks if that data is present before showing it, or not 

v1.5
Added handling for "scheduled" matches which are actually in progress
Updated logic that finds player who is serving
Certain API fields of ESPN data feed showing that the French Open is over? Changed the way an "in progress" tournament is determined using start and end dates

v1.6
ESPN changed the structure of the API so had to reflect those changes in the app
Added feature to show scheduled matches, enable with toggle switch. Will show date & time of scheduled match in Tidbyt's timezone
Added GroupingsID variable, as sometimes mens & womens results are listed in the API

v1.7
Updated determination for completed match, using "description" and not "state"
Now adding suspended matches in the In Progress list
Suspended matches shown in blue
Scheduled matches now in order of play - earliest to latest

v1.7.1
Bug fix - Retired matches were not being captured after changing completed match determination to description

v1.8
Changed purple background color on the title bar, made it darker purple
WTA 1000 events will have gold color font for the tournament title/city

v1.9
Added new feature to show who won each set (for completed & in progress matches) rather than having all of the match winner's sets in yellow. Makes it easier to see the flow of the match
Updated scheduled matches to only show if both players are listed, prevents blanks
Updated checks for walkover matches

v1.10
Updated box sizes to show "WO" for walkovers
Final of tournament now indicated for scheduled, completed and in progress final
Found bug that was showing incorrect winner for matches where there was a retirement during a set

v1.10.1
Incorrect event ID listed for Indian Wells in WTA 1000 list

v1.11
Only show players if both names are listed in the scheduled match, prevents blank rows from appearing

v1.12
Updated for 2025 season
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SLAM_LIST = ["154-2025", "188-2025", "172-2025", "189-2025"]
WTA1000_LIST = ["256-2025", "25-2025", "713-2025", "411-2025", "413-2025", "414-2025", "421-2025", "718-2025", "959-2025", "382-2025"]
DEFAULT_TIMEZONE = "Australia/Adelaide"
WTA_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/wta/scoreboard"

def main(config):
    now = time.now()
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    RotationSpeed = config.get("speed", "3")

    # hold 1 min cache for live scores
    CacheData = get_cachable_data(WTA_SCORES_URL, 60)
    WTA_JSON = json.decode(CacheData)

    Display1 = []
    InProgressMatchList = []
    CompletedMatchList = []
    ScheduledMatchList = []
    InProgress = 0
    diffTournEnd = 0
    diffTournStart = 0
    GroupingsID = 0

    TestID = "718-2024"
    SelectedTourneyID = config.get("TournamentList", TestID)
    ShowCompleted = config.get("CompletedOn", "true")
    ShowScheduled = config.get("ScheduledOn", "false")
    Number_Events = len(WTA_JSON["events"])
    EventIndex = 0
    #print(SelectedTourneyID)

    # Find the number of "In Progress" matches for the selected tournament
    for x in range(0, Number_Events, 1):
        if SelectedTourneyID == WTA_JSON["events"][x]["id"]:
            # Capture the index of the particular event, we'll need this later on
            EventIndex = x

            # Get start & end date/time of the tournament
            EndDate = WTA_JSON["events"][x]["endDate"]
            StartDate = WTA_JSON["events"][x]["date"]
            EndDate = time.parse_time(EndDate, format = "2006-01-02T15:04Z")
            StartDate = time.parse_time(StartDate, format = "2006-01-02T15:04Z")
            diffTournEnd = EndDate - now
            diffTournStart = StartDate - now

            # check if we are between the start & end date of the tournament
            if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                # Sometimes results for both ATP & WTA will be listed, so check if the first "groupings" is Mens Singles
                # and if so, Womens Singles will be next (GroupingsID = 1)
                if WTA_JSON["events"][x]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                    GroupingsID = 1
                TotalMatches = len(WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"])

                for y in range(0, TotalMatches, 1):
                    # if the match is "In Progress" and its a singles match, lets add it to the list of in progress matches
                    # And the "In Progress" match started < 24 hrs ago , sometimes the data feed will still show matches as "In Progress" after they have completed
                    # Adding a 24hr limit will remove them out of the list
                    if WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["status"]["type"]["description"] == "In Progress":
                        MatchTime = WTA_JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][y]["date"]
                        MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                        diffMatch = MatchTime - now

                        if diffMatch.hours > -24:
                            InProgressMatchList.append(y)
                            InProgress = InProgress + 1

                    if WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["status"]["type"]["description"] == "Suspended":
                        MatchTime = WTA_JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][y]["date"]
                        MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                        diffMatch = MatchTime - now

                        if diffMatch.hours > -24:
                            InProgressMatchList.append(y)
                            InProgress = InProgress + 1

                    # Another gotcha with the ESPN data feed, some in progress matches are still listed as "Scheduled"
                    # So check if there is a score listed and if so, add it to the list
                    if WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["status"]["type"]["description"] == "Scheduled":
                        if "linescores" in WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["competitors"][0]:
                            MatchTime = WTA_JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][y]["date"]
                            MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                            diffMatch = MatchTime - now

                            if diffMatch.hours > -24:
                                InProgressMatchList.append(y)
                                InProgress = InProgress + 1

            else:
                Display1.extend([
                    render.Column(
                        children = [
                            render.Column(
                                children = notStarted(EventIndex, WTA_JSON),
                            ),
                        ],
                    ),
                ])

    if len(InProgressMatchList) > 0:
        for a in range(0, len(InProgressMatchList), 2):
            # lint being a pain, so...
            a = a
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = getLiveScores(SelectedTourneyID, EventIndex, InProgressMatchList, WTA_JSON),
                        ),
                    ],
                ),
            ])
    else:
        Display1.extend([
            render.Column(
                children = [
                    render.Column(
                        children = getLiveScores(SelectedTourneyID, EventIndex, [], WTA_JSON),
                    ),
                ],
            ),
        ])

    if ShowCompleted == "true":
        # Find the number of matches completed in the past 24 hours and add the match index to a list
        for x in range(0, Number_Events, 1):
            if SelectedTourneyID == WTA_JSON["events"][x]["id"]:
                EventIndex = x

                # check if we are between the start & end date of the tournament
                if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                    if WTA_JSON["events"][x]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                        GroupingsID = 1
                    for y in range(0, len(WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"]), 1):
                        MatchState = WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["status"]["type"]["description"]

                        # if the match is completed and the start time of the match was < 24 hrs ago, lets add it to the list of completed matches
                        if MatchState == "Final" or MatchState == "Retired" or MatchState == "Walkover":
                            MatchTime = WTA_JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][y]["date"]
                            MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                            diff = MatchTime - now
                            if diff.hours > -24:
                                CompletedMatchList.append(y)

        # If there are more than 2 matches completed in past 24hrs, then we'll need to show them across multiple screens
        if len(CompletedMatchList) > 0:
            for b in range(0, len(CompletedMatchList), 2):
                # lint being a pain, so...
                b = b
                Display1.extend([
                    render.Column(
                        children = [
                            render.Column(
                                children = getCompletedMatches(SelectedTourneyID, EventIndex, CompletedMatchList, WTA_JSON),
                            ),
                        ],
                    ),
                ])
        else:
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = getCompletedMatches(SelectedTourneyID, EventIndex, [], WTA_JSON),
                        ),
                    ],
                ),
            ])

    if ShowScheduled == "true":
        # Find the number of matches scheduled for the next 24 hours and add the match index to a list
        for x in range(0, Number_Events, 1):
            if SelectedTourneyID == WTA_JSON["events"][x]["id"]:
                EventIndex = x

                # check if we are between the start & end date of the tournament
                if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                    if WTA_JSON["events"][x]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                        GroupingsID = 1
                    for y in range(0, len(WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"]), 1):
                        # if the match is scheduled ("pre") and the start time of the match is scheduled for next 12 hrs, add it to the list of scheduled matches
                        if WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["status"]["type"]["state"] == "pre":
                            P1Name = WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["competitors"][0]["athlete"]["shortName"]
                            P2Name = WTA_JSON["events"][x]["groupings"][GroupingsID]["competitions"][y]["competitors"][1]["athlete"]["shortName"]

                            if P1Name != "TBD" and P2Name != "TBD":
                                MatchTime = WTA_JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][y]["date"]
                                MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                                diff = MatchTime - now
                                if diff.hours < 12:
                                    ScheduledMatchList.insert(0, y)
                                else:
                                    break
                            else:
                                continue

        # if there are more than 2 matches completed in past 24hrs, then we'll need to show them across multiple screens
        if len(ScheduledMatchList) > 0:
            for b in range(0, len(ScheduledMatchList), 2):
                # lint being a pain, so...
                b = b
                Display1.extend([
                    render.Column(
                        children = [
                            render.Column(
                                children = getScheduledMatches(SelectedTourneyID, EventIndex, ScheduledMatchList, WTA_JSON, timezone),
                            ),
                        ],
                    ),
                ])
        else:
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = getScheduledMatches(SelectedTourneyID, EventIndex, [], WTA_JSON, timezone),
                        ),
                    ],
                ),
            ])

    return render.Root(
        show_full_animation = True,
        delay = int(RotationSpeed) * 1000,
        child = render.Animation(children = Display1),
    )

def getLiveScores(SelectedTourneyID, EventIndex, InProgressMatchList, JSON):
    # Lists for rendering
    Display = []
    Scores = []
    GroupingsID = 0
    InProgressNum = len(InProgressMatchList)

    Player1NameColor = "#fff"
    Player2NameColor = "#fff"
    displayfont = "CG-pixel-3x5-mono"
    LoopMax = 0

    # If its not a slam...
    # Get the city of the tournament, everything up to the comma (format is City, Country)
    # This is usually how the tournaments are referred to, so use this in the title bar
    if SelectedTourneyID not in SLAM_LIST:
        # Also check we have matches listed, have seen 2 entries for same event/tournament
        if len(JSON["events"][EventIndex]["groupings"]) > 0:
            TourneyLocation = JSON["events"][EventIndex]["groupings"][0]["competitions"][0]["venue"]["fullName"]
            CommaIndex = TourneyLocation.index(",")
            TourneyCity = TourneyLocation[:CommaIndex]
        else:
            # It is a slam so use the tournament name
            TourneyCity = JSON["events"][EventIndex]["name"]
    else:
        # It is a slam so use the tournament name
        TourneyCity = JSON["events"][EventIndex]["name"]

    TitleBarColor = titleBar(SelectedTourneyID)
    TitleFontColor = titleFont(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = TitleFontColor, font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    for y in range(0, len(InProgressMatchList), 1):
        # lint being a pain, so...
        y = y

        Player1SetScoreList = []
        Player2SetScoreList = []
        Player1SetWinnerList = []
        Player2SetWinnerList = []

        SetScores1 = []
        SetScores2 = []
        MasterSetScores1 = []
        MasterSetScores2 = []

        # LoopMax is maximum number of times to loop around, which is 2 (2 matches)
        if LoopMax > 1:
            break
        else:
            LoopMax = LoopMax + 1
            Player1NameColor = "#fff"
            Player2NameColor = "#fff"

            if JSON["events"][EventIndex]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                GroupingsID = 1

            # pop the index from the list and go straight to that match
            x = InProgressMatchList.pop()

            Player1_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player2_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

            # See if the server details are been captured and display them if they are there
            if "possession" in JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]:
                if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["possession"] == True:
                    Player1NameColor = "#01AF50"
                elif JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["possession"] == False:
                    Player2NameColor = "#01AF50"

            # if a match is suspended show players in blue
            if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["status"]["type"]["description"] == "Suspended":
                Player1NameColor = "#6aaeeb"
                Player2NameColor = "#6aaeeb"

            Number_Sets = len(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"])

            for z in range(0, Number_Sets, 1):
                Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["linescores"][z]["value"])
                Player1SetScoreList.insert(0, Player1SetScore)
                Player2SetScoreList.insert(0, Player2SetScore)

                # if a set is complete, it will have a winner, else it must be an in progress set, therefore no winner (False)
                if "winner" in JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"][z]:
                    Player1SetWinner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"][z]["winner"]
                    Player2SetWinner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["linescores"][z]["winner"]
                    Player1SetWinnerList.insert(0, Player1SetWinner)
                    Player2SetWinnerList.insert(0, Player2SetWinner)
                else:
                    Player1SetWinnerList.insert(0, False)
                    Player2SetWinnerList.insert(0, False)

                Player1SetColor = "#fff"
                Player2SetColor = "#fff"
                P1Score = Player1SetScoreList.pop()
                P2Score = Player2SetScoreList.pop()

                P1SetWinner = Player1SetWinnerList.pop()
                P2SetWinner = Player2SetWinnerList.pop()

                if P1SetWinner == True:
                    Player1SetColor = "ff0"
                elif P2SetWinner == True:
                    Player2SetColor = "ff0"

                SetScores1 = [
                    render.Box(
                        width = 4,
                        height = 5,
                        child = render.Text(
                            content = P1Score,
                            color = Player1SetColor,
                            font = displayfont,
                        ),
                    ),
                ]

                SetScores2 = [
                    render.Box(
                        width = 4,
                        height = 5,
                        child = render.Text(
                            content = P2Score,
                            color = Player2SetColor,
                            font = displayfont,
                        ),
                    ),
                ]

                MasterSetScores1.extend(SetScores1)
                MasterSetScores2.extend(SetScores2)

            Scores = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player1_Name[3:15],
                                        color = Player1NameColor,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = MasterSetScores1,
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player2_Name[3:15],
                                        color = Player2NameColor,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = MasterSetScores2,
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 2),
                    ],
                ),
            ]
            Display.extend(Scores)
            if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["round"]["displayName"] == "Final":
                Final = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Row(
                                main_align = "start",
                                children = [
                                    render.Padding(
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = "FINAL",
                                            color = "#fff",
                                            font = displayfont,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ]
                Display.extend(Final)

    if InProgressNum == 0:
        NoMatches = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 8, child = render.Text(content = "No Matches", color = "#fff", font = displayfont)),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "in progress", color = "#fff", font = displayfont)),
                ],
            ),
        ]
        Display.extend(NoMatches)

    return Display

def getCompletedMatches(SelectedTourneyID, EventIndex, CompletedMatchList, JSON):
    # Lists for rendering
    Display = []
    Scores = []

    displayfont = "CG-pixel-3x5-mono"
    LoopMax = 0
    GroupingsID = 0
    Completed = len(CompletedMatchList)

    # If its not a slam...
    # Get the city of the tournament, everything up to the comma (format is City, Country)
    # This is usually how the tournaments are referred to, so use this in the title bar
    if SelectedTourneyID not in SLAM_LIST:
        # Also check we have matches listed, have seen 2 entries for same event/tournament
        if len(JSON["events"][EventIndex]["groupings"]) > 0:
            TourneyLocation = JSON["events"][EventIndex]["groupings"][0]["competitions"][0]["venue"]["fullName"]
            CommaIndex = TourneyLocation.index(",")
            TourneyCity = TourneyLocation[:CommaIndex]
        else:
            # It is a slam so use the tournament name
            TourneyCity = JSON["events"][EventIndex]["name"]

    else:
        # Use proper event name for slam
        TourneyCity = JSON["events"][EventIndex]["name"]

    TitleBarColor = titleBar(SelectedTourneyID)
    TitleFontColor = titleFont(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = TitleFontColor, font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    # loop through the list of completed matches
    for y in range(0, len(CompletedMatchList), 1):
        # lint being a pain, so...
        y = y

        Player1SetScoreList = []
        Player2SetScoreList = []
        Player1SetWinnerList = []
        Player2SetWinnerList = []
        P1SetWinner = False
        P2SetWinner = False

        SetScores1 = []
        SetScores2 = []
        MasterSetScores1 = []
        MasterSetScores2 = []

        # LoopMax is maximum number of times to loop around, which is 2 (2 matches per cycle)
        if LoopMax > 1:
            break
        else:
            LoopMax = LoopMax + 1
            Player1Color = "#fff"
            Player2Color = "#fff"

            # pop the index from the list and go straight to that match
            x = CompletedMatchList.pop()

            if JSON["events"][EventIndex]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                GroupingsID = 1

            Player1_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player2_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

            # display the match winner in yellow, however sometimes both are false even when the match is completed
            Player1_Winner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["winner"]
            Player2_Winner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["winner"]

            if (Player1_Winner):
                Player1Color = "#ff0"
            elif (Player2_Winner):
                Player2Color = "#ff0"

            # if its not a walkover
            if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["status"]["type"]["description"] != "Walkover":
                Number_Sets = len(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"])

                for z in range(0, Number_Sets, 1):
                    Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                    Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

                    Player1SetWinner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["linescores"][z]["winner"]
                    Player2SetWinner = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["linescores"][z]["winner"]

                    Player1SetScoreList.insert(0, Player1SetScore)
                    Player2SetScoreList.insert(0, Player2SetScore)
                    Player1SetWinnerList.insert(0, Player1SetWinner)
                    Player2SetWinnerList.insert(0, Player2SetWinner)

                    Player1SetColor = "#fff"
                    Player2SetColor = "#fff"
                    P1Score = Player1SetScoreList.pop()
                    P2Score = Player2SetScoreList.pop()
                    P1SetWinner = Player1SetWinnerList.pop()
                    P2SetWinner = Player2SetWinnerList.pop()

                    # indicate the set winner in yellow, if no set winner (in the case of retirement) then both scores are white
                    if P1SetWinner == True:
                        Player1SetColor = "ff0"
                    elif P2SetWinner == True:
                        Player2SetColor = "ff0"

                    SetScores1 = [
                        render.Box(
                            width = 4,
                            height = 5,
                            child = render.Text(
                                content = P1Score,
                                color = Player1SetColor,
                                font = displayfont,
                            ),
                        ),
                    ]

                    SetScores2 = [
                        render.Box(
                            width = 4,
                            height = 5,
                            child = render.Text(
                                content = P2Score,
                                color = Player2SetColor,
                                font = displayfont,
                            ),
                        ),
                    ]

                    MasterSetScores1.extend(SetScores1)
                    MasterSetScores2.extend(SetScores2)

                # ESPN not updating the match winner field lately, so I'll work it out myself
                # Whoever won the last set is the winner
                if Player1_Winner == False and Player2_Winner == False:
                    if (P1SetWinner):
                        Player1Color = "#ff0"
                    else:
                        Player2Color = "#ff0"

            else:
                # it is a walkover, indicate that in the set score field
                if (Player1_Winner):
                    MasterSetScores1 = [
                        render.Box(
                            width = 10,
                            height = 5,
                            child = render.Text(
                                content = "WO",
                                color = "#ff0",
                                font = displayfont,
                            ),
                        ),
                    ]

                    MasterSetScores2 = [
                        render.Box(
                            width = 4,
                            height = 5,
                            child = render.Text(
                                content = "",
                                color = "#ff0",
                                font = displayfont,
                            ),
                        ),
                    ]
                elif (Player2_Winner):
                    MasterSetScores2 = [
                        render.Box(
                            width = 10,
                            height = 5,
                            child = render.Text(
                                content = "WO",
                                color = "#ff0",
                                font = displayfont,
                            ),
                        ),
                    ]
                    MasterSetScores1 = [
                        render.Box(
                            width = 4,
                            height = 5,
                            child = render.Text(
                                content = "",
                                color = "#ff0",
                                font = displayfont,
                            ),
                        ),
                    ]

            # Render the names and set scores, with a spacer in between matches
            Scores = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player1_Name[3:15],
                                        color = Player1Color,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = MasterSetScores1,
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player2_Name[3:15],
                                        color = Player2Color,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = MasterSetScores2,
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 2),
                    ],
                ),
            ]
            Display.extend(Scores)
            if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["round"]["displayName"] == "Final":
                Final = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Row(
                                main_align = "start",
                                children = [
                                    render.Padding(
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = "FINAL",
                                            color = "#fff",
                                            font = displayfont,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ]
                Display.extend(Final)

    if Completed == 0:
        NoMatches = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 4),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "No recent", color = "#fff", font = displayfont)),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "completed", color = "#fff", font = displayfont)),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "matches", color = "#fff", font = displayfont)),
                ],
            ),
        ]
        Display.extend(NoMatches)
    return Display

def notStarted(EventIndex, JSON):
    Display = []

    TourneyName = JSON["events"][EventIndex]["name"]
    Title = [render.Box(width = 64, height = 5, color = "#203764", child = render.Text(content = TourneyName[:16], color = "#FFF", font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    NoMatches = [
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Box(width = 64, height = 6),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Box(width = 64, height = 8, child = render.Text(content = "Tournament", color = "#fff", font = "CG-pixel-3x5-mono")),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Box(width = 64, height = 6, child = render.Text(content = "Not started", color = "#fff", font = "CG-pixel-3x5-mono")),
            ],
        ),
    ]
    Display.extend(NoMatches)

    return Display

def getScheduledMatches(SelectedTourneyID, EventIndex, ScheduledMatchList, JSON, timezone):
    SurnameLen = 13

    Display = []
    Scores = []
    GroupingsID = 0

    displayfont = "CG-pixel-3x5-mono"
    LoopMax = 0
    Scheduled = len(ScheduledMatchList)

    # If its not a slam...
    # Get the city of the tournament, everything up to the comma (format is City, Country)
    # This is usually how the tournaments are referred to, so use this in the title bar
    # if tournament hasn't started yet (using our 10 field test), the city information cannot be gathered so we'll default to the official title
    if SelectedTourneyID not in SLAM_LIST:
        TourneyLocation = JSON["events"][EventIndex]["groupings"][0]["competitions"][0]["venue"]["fullName"]
        CommaIndex = TourneyLocation.index(",")
        TourneyCity = TourneyLocation[:CommaIndex]

    else:
        # Use proper event name for slam
        TourneyCity = JSON["events"][EventIndex]["name"]

    TitleBarColor = titleBar(SelectedTourneyID)
    TitleFontColor = titleFont(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = TitleFontColor, font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    # loop through the list of completed matches
    for y in range(0, len(ScheduledMatchList), 1):
        # lint being a pain, so...
        y = y

        # LoopMax is maximum number of times to loop around, which is 2 (2 matches per cycle)
        if LoopMax > 1:
            break
        else:
            LoopMax = LoopMax + 1
            Player1Color = "#fff"
            Player2Color = "#fff"
            DateTimeColor = "#fff"

            # pop the index from the list and go straight to that match
            x = ScheduledMatchList.pop()

            if JSON["events"][EventIndex]["groupings"][0]["grouping"]["slug"] == "mens-singles":
                GroupingsID = 1

            # check that we have players before displaying them or display blank line
            if "athlete" in JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]:
                Player1_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            else:
                Player1_Name = ""
            if "athlete" in JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]:
                Player2_Name = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["competitors"][1]["athlete"]["shortName"]
            else:
                Player2_Name = ""

            # get date & time of match
            APIDate = JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["date"]
            ParsedDate = time.parse_time(APIDate, format = "2006-01-02T15:04Z").in_location(timezone)
            now = time.now().in_location(timezone)

            # if its scheduled for today, just show the time
            if ParsedDate.format("2/1") != now.format("2/1"):
                Date = ParsedDate.format("2/1")
            else:
                Date = ""

            Time = ParsedDate.format("15:04")

            # Render the names and set scores, with a spacer in between matches
            Scores = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player1_Name[3:SurnameLen],
                                        color = Player1Color,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = [
                                render.Padding(
                                    pad = (0, 1, 1, 0),
                                    child = render.Text(
                                        content = Date,
                                        color = DateTimeColor,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Row(
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (1, 1, 0, 0),
                                    child = render.Text(
                                        content = Player2_Name[3:SurnameLen],
                                        color = Player2Color,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            children = [
                                render.Padding(
                                    pad = (0, 1, 1, 0),
                                    child = render.Text(
                                        content = Time,
                                        color = DateTimeColor,
                                        font = displayfont,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Box(width = 64, height = 2),
                    ],
                ),
            ]
            Display.extend(Scores)

            if JSON["events"][EventIndex]["groupings"][GroupingsID]["competitions"][x]["round"]["displayName"] == "Final":
                Final = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Row(
                                main_align = "start",
                                children = [
                                    render.Padding(
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = "FINAL",
                                            color = "#fff",
                                            font = displayfont,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ]
                Display.extend(Final)

    if Scheduled == 0:
        NoMatches = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 4),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "No upcoming", color = "#fff", font = displayfont)),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "scheduled", color = "#fff", font = displayfont)),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Box(width = 64, height = 6, child = render.Text(content = "matches", color = "#fff", font = displayfont)),
                ],
            ),
        ]
        Display.extend(NoMatches)
    return Display

def get_schema():
    TOURNEY_CACHE = 10800  # 3hrs
    WTA_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/wta/scoreboard"
    CacheData = get_cachable_data(WTA_SCORES_URL, TOURNEY_CACHE)
    WTA_JSON = json.decode(CacheData)

    Number_Events = len(WTA_JSON["events"])

    Events = []
    EventsID = []
    TournamentOptions = []
    ActualEvents = 0

    now = time.now()

    # Only show "In Progress" tournaments
    for x in range(0, Number_Events, 1):
        EndDate = WTA_JSON["events"][x]["endDate"]
        StartDate = WTA_JSON["events"][x]["date"]
        EndDate = time.parse_time(EndDate, format = "2006-01-02T15:04Z")
        StartDate = time.parse_time(StartDate, format = "2006-01-02T15:04Z")
        diffTournEnd = EndDate - now
        diffTournStart = StartDate - now

        if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
            if len(WTA_JSON["events"][x]["groupings"]) > 0:
                Event_Name = WTA_JSON["events"][x]["name"]
                Event_ID = WTA_JSON["events"][x]["id"]
                Events.append(Event_Name)
                EventsID.append(Event_ID)
                ActualEvents = ActualEvents + 1

    if ActualEvents != 0:
        for y in range(0, ActualEvents, 1):
            # lint being a pain, so...
            y = y
            EventName = Events.pop(0)
            EventID = EventsID.pop(0)

            Value = schema.Option(
                display = EventName,
                value = EventID,
            )

            TournamentOptions.append(Value)

        # if there are no tournaments on then put that in the dropdown
    else:
        Value = schema.Option(
            display = "No active events",
            value = "1",
        )

        TournamentOptions.append(Value)

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "TournamentList",
                name = "Tournament",
                desc = "Choose the tournament",
                icon = "gear",
                default = TournamentOptions[0].value,
                options = TournamentOptions,
            ),
            schema.Toggle(
                id = "CompletedOn",
                name = "Completed Matches",
                desc = "Also show matches completed in past 24 hours",
                icon = "toggleOn",
                default = True,
            ),
            schema.Toggle(
                id = "ScheduledOn",
                name = "Scheduled Matches",
                desc = "Also show matches scheduled for next 12 hours",
                icon = "toggleOn",
                default = False,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each page is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
        ],
    )

def titleBar(SelectedTourneyID):
    if SelectedTourneyID == "154-2025":  # AO
        titleColor = "#0091d2"
    elif SelectedTourneyID == "188-2025":  # Wimbledon
        titleColor = "#006633"
    elif SelectedTourneyID == "172-2025":  # French Open
        titleColor = "#c84e1e"
    elif SelectedTourneyID == "189-2025":  # US Open
        titleColor = "#022686"
    else:
        titleColor = "#430166"
    return titleColor

def titleFont(SelectedTourneyID):
    if SelectedTourneyID in WTA1000_LIST:
        titleFontColor = "#d1b358"
    else:
        titleFontColor = "#FFF"
    return titleFontColor

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

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

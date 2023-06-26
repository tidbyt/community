"""
Applet: ATP Tennis
Summary: Shows ATP scores
Description: Display tennis scores from a tournament chosen in the dropdown. Shows live matches and if selected, any match completed in the past 24 hours.
Author: M0ntyP

v1.1
Used "post" state for completed matches, this will capture both Final and Retired
Added handling for when no tournaments are on

v1.2
Show city name instead of official tournament title once the tournament starts, except for Slams
Added handling for walkovers
Extended player surname field by 2 chars for Best of 3 sets tournaments

v1.3
Sometimes the data feed will still show matches as "In Progress" after they have completed. Have added a 24hr limit so that if the start date is > 24 hrs ago then don't list the match

v1.3a
Updated caching function

v1.4
Current server now indicated in green

v1.4.1
Fixed bug which appears when player who is serving is not being provided by data feed. Code now checks if that data is present before showing it, or not 

v1.5
Added handling for "scheduled" matches which are actually in progress
Updated logic that finds player who is serving
Certain API fields of ESPN data feed showing that the French Open is over? Changed the way an "in progress" tournament is determined using start and end dates
Removed timezone - not required

v1.6
ESPN changed the structure of the API so had to reflect those changes in the app
Added feature to show scheduled matches, enable with toggle switch. Will show date & time of scheduled match in Tidbyt's timezone

v1.6.1
Bug fix - the API lookup for a "scheduled" match which is actually in progress was incorrect
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SLAM_LIST = ["154-2023", "188-2023", "172-2023", "189-2023"]
DEFAULT_TIMEZONE = "Australia/Adelaide"
ATP_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/atp/scoreboard"

def main(config):
    now = time.now()
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    RotationSpeed = config.get("speed", "3")

    # hold 1 min cache for live scores
    CacheData = get_cachable_data(ATP_SCORES_URL, 60)
    ATP_JSON = json.decode(CacheData)

    Display1 = []
    InProgressMatchList = []
    CompletedMatchList = []
    ScheduledMatchList = []
    InProgress = 0
    diffTournEnd = 0
    diffTournStart = 0

    TestID = "414-2023"
    SelectedTourneyID = config.get("TournamentList", TestID)
    ShowCompleted = config.get("CompletedOn", "true")
    ShowScheduled = config.get("ScheduledOn", "false")
    Number_Events = len(ATP_JSON["events"])
    EventIndex = 0

    # Find the number of "In Progress" matches for the selected tournament
    for x in range(0, Number_Events, 1):
        if SelectedTourneyID == ATP_JSON["events"][x]["id"]:
            # Capture the index of the particular event, we'll need this later on
            EventIndex = x

            # Get start & end date/time of the tournament
            EndDate = ATP_JSON["events"][x]["endDate"]
            StartDate = ATP_JSON["events"][x]["date"]
            EndDate = time.parse_time(EndDate, format = "2006-01-02T15:04Z")
            StartDate = time.parse_time(StartDate, format = "2006-01-02T15:04Z")
            diffTournEnd = EndDate - now
            diffTournStart = StartDate - now

            # check if we are between the start & end date of the tournament
            if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                TotalMatches = len(ATP_JSON["events"][x]["groupings"][0]["competitions"])

                for y in range(0, TotalMatches, 1):
                    # if the match is "In Progress" and its a singles match, lets add it to the list of in progress matches
                    # And the "In Progress" match started < 24 hrs ago , sometimes the data feed will still show matches as "In Progress" after they have completed
                    # Adding a 24hr limit will remove them out of the list
                    if ATP_JSON["events"][x]["groupings"][0]["competitions"][y]["status"]["type"]["description"] == "In Progress":
                        MatchTime = ATP_JSON["events"][EventIndex]["groupings"][0]["competitions"][y]["date"]
                        MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                        diffMatch = MatchTime - now

                        if diffMatch.hours > -24:
                            InProgressMatchList.append(y)
                            InProgress = InProgress + 1

                    # Another gotcha with the ESPN data feed, some in progress matches are still listed as "Scheduled"
                    # So check if there is a score listed and if so, add it to the in progress list
                    if ATP_JSON["events"][x]["groupings"][0]["competitions"][y]["status"]["type"]["description"] == "Scheduled":
                        if "linescores" in ATP_JSON["events"][x]["groupings"][0]["competitions"][y]["competitors"][0]:
                            MatchTime = ATP_JSON["events"][EventIndex]["groupings"][0]["competitions"][y]["date"]
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
                                children = notStarted(EventIndex, ATP_JSON),
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
                            children = getLiveScores(SelectedTourneyID, EventIndex, InProgressMatchList, ATP_JSON),
                        ),
                    ],
                ),
            ])
    else:
        Display1.extend([
            render.Column(
                children = [
                    render.Column(
                        children = getLiveScores(SelectedTourneyID, EventIndex, [], ATP_JSON),
                    ),
                ],
            ),
        ])

    if ShowCompleted == "true":
        # Find the number of matches completed in the past 24 hours and add the match index to a list
        for x in range(0, Number_Events, 1):
            if SelectedTourneyID == ATP_JSON["events"][x]["id"]:
                EventIndex = x

                # check if we are between the start & end date of the tournament
                if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                    for y in range(0, len(ATP_JSON["events"][x]["groupings"][0]["competitions"]), 1):
                        # if the match is completed ("post") and the start time of the match was < 24 hrs ago, lets add it to the list of completed matches
                        if ATP_JSON["events"][x]["groupings"][0]["competitions"][y]["status"]["type"]["state"] == "post":
                            MatchTime = ATP_JSON["events"][EventIndex]["groupings"][0]["competitions"][y]["date"]
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
                                children = getCompletedMatches(SelectedTourneyID, EventIndex, CompletedMatchList, ATP_JSON),
                            ),
                        ],
                    ),
                ])
        else:
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = getCompletedMatches(SelectedTourneyID, EventIndex, [], ATP_JSON),
                        ),
                    ],
                ),
            ])

    if ShowScheduled == "true":
        # Find the number of matches scheduled for the next 24 hours and add the match index to a list
        for x in range(0, Number_Events, 1):
            if SelectedTourneyID == ATP_JSON["events"][x]["id"]:
                EventIndex = x

                # check if we are between the start & end date of the tournament
                if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
                    for y in range(0, len(ATP_JSON["events"][x]["groupings"][0]["competitions"]), 1):
                        # if the match is scheduled ("pre") and the start time of the match is scheduled for next 12 hrs, add it to the list of scheduled matches
                        if ATP_JSON["events"][x]["groupings"][0]["competitions"][y]["status"]["type"]["state"] == "pre":
                            MatchTime = ATP_JSON["events"][EventIndex]["groupings"][0]["competitions"][y]["date"]
                            MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                            diff = MatchTime - now
                            if diff.hours < 12:
                                ScheduledMatchList.append(y)

        # if there are more than 2 matches completed in past 24hrs, then we'll need to show them across multiple screens
        if len(ScheduledMatchList) > 0:
            for b in range(0, len(ScheduledMatchList), 2):
                # lint being a pain, so...
                b = b
                Display1.extend([
                    render.Column(
                        children = [
                            render.Column(
                                children = getScheduledMatches(SelectedTourneyID, EventIndex, ScheduledMatchList, ATP_JSON, timezone),
                            ),
                        ],
                    ),
                ])
        else:
            Display1.extend([
                render.Column(
                    children = [
                        render.Column(
                            children = getScheduledMatches(SelectedTourneyID, EventIndex, [], ATP_JSON, timezone),
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
    InProgressNum = len(InProgressMatchList)

    Player1Color = "#fff"
    Player2Color = "#fff"
    displayfont = "CG-pixel-3x5-mono"
    LoopMax = 0

    # If its not a slam...
    # Get the city of the tournament, everything up to the comma (format is City, Country)
    # This is usually how the tournaments are referred to, so use this in the title bar
    # if tournament hasn't started yet (using our 10 field test), the city information cannot be gathered so we'll default to the official title
    if SelectedTourneyID not in SLAM_LIST:
        TourneyLocation = JSON["events"][EventIndex]["groupings"][0]["competitions"][0]["venue"]["fullName"]
        CommaIndex = TourneyLocation.index(",")
        TourneyCity = TourneyLocation[:CommaIndex]

        # Due to Best of 3 format in non-slams we can allow for 15 chars in a player's surname
        SurnameLen = 15
    else:
        # It is a slam so use the tournament name
        TourneyCity = JSON["events"][EventIndex]["name"]

        # Due to Best of 5 format in slams we can allow for 13 chars in a player's surname
        SurnameLen = 13

    TitleBarColor = titleBar(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = "#FFF", font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    for y in range(0, len(InProgressMatchList), 1):
        # lint being a pain, so...
        y = y

        # LoopMax is maximum number of times to loop around, which is 2 (2 matches)
        if LoopMax > 1:
            break
        else:
            LoopMax = LoopMax + 1
            Player1Color = "#fff"
            Player2Color = "#fff"

            # pop the index from the list and go straight to that match
            x = InProgressMatchList.pop()

            Player1_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player2_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

            # See if the server details are been captured and display them if they are there
            if "possession" in JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]:
                if JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["possession"] == True:
                    Player1Color = "#01AF50"
                elif JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["possession"] == False:
                    Player2Color = "#01AF50"

            Number_Sets = len(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["linescores"])
            Player1_Sets = ""
            Player2_Sets = ""

            for z in range(0, Number_Sets, 1):
                Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

                Player1_Sets = Player1_Sets + Player1SetScore
                Player2_Sets = Player2_Sets + Player2SetScore

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
                                        content = Player1_Sets,
                                        color = Player1Color,
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
                                        content = Player2_Sets,
                                        color = Player2Color,
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
    Completed = len(CompletedMatchList)

    # If its not a slam...
    # Get the city of the tournament, everything up to the comma (format is City, Country)
    # This is usually how the tournaments are referred to, so use this in the title bar
    # if tournament hasn't started yet (using our 10 field test), the city information cannot be gathered so we'll default to the official title
    if SelectedTourneyID not in SLAM_LIST:
        TourneyLocation = JSON["events"][EventIndex]["groupings"][0]["competitions"][0]["venue"]["fullName"]
        CommaIndex = TourneyLocation.index(",")
        TourneyCity = TourneyLocation[:CommaIndex]

        # 15 chars in surname when not a slam
        SurnameLen = 15
    else:
        # Use proper event name for slam
        TourneyCity = JSON["events"][EventIndex]["name"]

        # 13 chars in surname when it is a slam
        SurnameLen = 13

    TitleBarColor = titleBar(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = "#FFF", font = "CG-pixel-3x5-mono"))]
    Display.extend(Title)

    # loop through the list of completed matches
    for y in range(0, len(CompletedMatchList), 1):
        # lint being a pain, so...
        y = y

        # LoopMax is maximum number of times to loop around, which is 2 (2 matches per cycle)
        if LoopMax > 1:
            break
        else:
            LoopMax = LoopMax + 1
            Player1Color = "#fff"
            Player2Color = "#fff"

            # pop the index from the list and go straight to that match
            x = CompletedMatchList.pop()

            Player1_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player2_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

            # display the match winner in yellow, however sometimes both are false even when the match is completed
            Player1_Winner = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["winner"]
            Player2_Winner = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["winner"]

            if (Player1_Winner):
                Player1Color = "#ff0"
            elif (Player2_Winner):
                Player2Color = "#ff0"

            Player1_Sets = ""
            Player2_Sets = ""

            # if its not a walkover
            if JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["status"]["type"]["description"] != "Walkover":
                Number_Sets = len(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["linescores"])

                for z in range(0, Number_Sets, 1):
                    Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                    Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

                    Player1_Sets = Player1_Sets + Player1SetScore
                    Player2_Sets = Player2_Sets + Player2SetScore
            else:
                # it is a walkover, indicate that in the set score field
                if (Player1_Winner):
                    Player1_Sets = "WO"
                    Player2_Sets = ""
                elif (Player2_Winner):
                    Player1_Sets = ""
                    Player2_Sets = "WO"

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
                                        content = Player1_Sets,
                                        color = Player1Color,
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
                                        content = Player2_Sets,
                                        color = Player2Color,
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

def getScheduledMatches(SelectedTourneyID, EventIndex, ScheduledMatchList, JSON, timezone):
    SurnameLen = 13

    Display = []
    Scores = []

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
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyCity, color = "#FFF", font = "CG-pixel-3x5-mono"))]
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

            # check that we have players before displaying them or display blank line
            if "athlete" in JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]:
                Player1_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            else:
                Player1_Name = ""
            if "athlete" in JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]:
                Player2_Name = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["competitors"][1]["athlete"]["shortName"]
            else:
                Player2_Name = ""

            # get date & time of match
            APIDate = JSON["events"][EventIndex]["groupings"][0]["competitions"][x]["date"]
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

def get_schema():
    TOURNEY_CACHE = 10800  # 3hrs
    ATP_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/atp/scoreboard"
    CacheData = get_cachable_data(ATP_SCORES_URL, TOURNEY_CACHE)
    ATP_JSON = json.decode(CacheData)

    Number_Events = len(ATP_JSON["events"])

    Events = []
    EventsID = []
    TournamentOptions = []
    ActualEvents = 0

    now = time.now()

    # Only show "In Progress" tournaments
    for x in range(0, Number_Events, 1):
        EndDate = ATP_JSON["events"][x]["endDate"]
        StartDate = ATP_JSON["events"][x]["date"]
        EndDate = time.parse_time(EndDate, format = "2006-01-02T15:04Z")
        StartDate = time.parse_time(StartDate, format = "2006-01-02T15:04Z")
        diffTournEnd = EndDate - now
        diffTournStart = StartDate - now
        if diffTournStart.hours < 0 and diffTournEnd.hours > 0:
            Event_Name = ATP_JSON["events"][x]["name"]
            Event_ID = ATP_JSON["events"][x]["id"]
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
    if SelectedTourneyID == "154-2023":  # AO
        titleColor = "#0091d2"
    elif SelectedTourneyID == "188-2023":  # Wimbledon
        titleColor = "#006633"
    elif SelectedTourneyID == "172-2023":  # French Open
        titleColor = "#c84e1e"
    elif SelectedTourneyID == "189-2023":  # US Open
        titleColor = "#022686"
    else:
        titleColor = "#203764"
    return titleColor

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

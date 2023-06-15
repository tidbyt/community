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

v1.5.1 - In progress version
Removed timezone - not required
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SLAM_LIST = ["154-2023", "188-2023", "172-2023", "189-2023"]

def main(config):
    now = time.now()
    RotationSpeed = config.get("speed", "3")

    # hold 1 min cache for live scores
    WTA_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/wta/scoreboard"
    CacheData = get_cachable_data(WTA_SCORES_URL, 60)
    WTA_JSON = json.decode(CacheData)

    Display1 = []
    InProgressMatchList = []
    CompletedMatchList = []
    InProgress = 0
    diffTournEnd = 0
    diffTournStart = 0

    TestID = "254-2023"
    SelectedTourneyID = config.get("TournamentList", TestID)
    ShowCompleted = config.get("CompletedOn", "true")
    Number_Events = len(WTA_JSON["events"])
    EventIndex = 0

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
                for y in range(0, len(WTA_JSON["events"][x]["competitions"]), 1):
                    # if the match is "In Progress" and its a singles match, lets add it to the list of in progress matches
                    # And the "In Progress" match started < 24 hrs ago , sometimes the data feed will still show matches as "In Progress" after they have completed
                    # Adding a 24hr limit will remove them out of the list
                    if WTA_JSON["events"][x]["competitions"][y]["status"]["type"]["description"] == "In Progress":
                        if WTA_JSON["events"][x]["competitions"][y]["competitors"][0]["type"] == "athlete":
                            MatchTime = WTA_JSON["events"][EventIndex]["competitions"][y]["date"]
                            MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                            diff = MatchTime - now
                            if diff.hours > -24:
                                InProgressMatchList.append(y)
                                InProgress = InProgress + 1

                    # Another gotcha with the ESPN data feed, some in progress matches are still listed as "Scheduled"
                    # So check if there is a score listed and if so, add it to the list
                    if WTA_JSON["events"][x]["competitions"][y]["status"]["type"]["description"] == "Scheduled":
                        if "linescores" in WTA_JSON["events"][x]["competitions"][y]["competitors"][0]:
                            if WTA_JSON["events"][x]["competitions"][y]["competitors"][0]["type"] == "athlete":
                                MatchTime = WTA_JSON["events"][EventIndex]["competitions"][y]["date"]
                                MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z")
                                diff = MatchTime - now
                                if diff.hours > -24:
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
                    for y in range(0, len(WTA_JSON["events"][x]["competitions"]), 1):
                        # if the match is completed ("post") and its a singles match ("athlete") and the start time of the match was < 24 hrs ago, lets add it to the list of completed matches
                        if WTA_JSON["events"][x]["competitions"][y]["status"]["type"]["state"] == "post":
                            if WTA_JSON["events"][x]["competitions"][y]["competitors"][0]["type"] == "athlete":
                                MatchTime = WTA_JSON["events"][EventIndex]["competitions"][y]["date"]
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
        if len(JSON["events"][EventIndex]) == 10:
            TourneyLocation = JSON["events"][EventIndex]["competitions"][0]["venue"]["address"]["summary"]
            CommaIndex = TourneyLocation.index(",")
            TourneyCity = TourneyLocation[:CommaIndex]
        else:
            TourneyCity = JSON["events"][EventIndex]["name"]
    else:
        # It is a slam so use the tournament name
        TourneyCity = JSON["events"][EventIndex]["name"]

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

            Player1_Name = JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player1_ID = JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["id"]
            Player2_Name = JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["athlete"]["shortName"]
            Player2_ID = JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["id"]

            # See if the server details are been captured and then display them if they are there
            if "situation" in JSON["events"][EventIndex]["competitions"][x]:
                if "server" in JSON["events"][EventIndex]["competitions"][x]["situation"]:
                    Server = JSON["events"][EventIndex]["competitions"][x]["situation"]["server"]["$ref"]
                    Server = Server[70:]
                    Server = Server.removesuffix("?lang=en&region=us")

                    if Server == Player1_ID:
                        Player1Color = "#01AF50"
                    elif Server == Player2_ID:
                        Player2Color = "#01AF50"

            Number_Sets = len(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"])
            Player1_Sets = ""
            Player2_Sets = ""

            for z in range(0, Number_Sets, 1):
                Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

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
                                        content = Player1_Name[3:15],
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
                                        content = Player2_Name[3:15],
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
        if len(JSON["events"][EventIndex]) == 10:
            TourneyLocation = JSON["events"][EventIndex]["competitions"][0]["venue"]["address"]["summary"]
            CommaIndex = TourneyLocation.index(",")
            TourneyCity = TourneyLocation[:CommaIndex]
        else:
            TourneyCity = JSON["events"][EventIndex]["name"]
    else:
        # Use proper event name for slam
        TourneyCity = JSON["events"][EventIndex]["name"]

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

            # check if its a singles match
            # if (JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["type"] == "athlete"):
            Player1_Name = JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["athlete"]["shortName"]
            Player2_Name = JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

            # display the match winner in yellow, however sometimes both are false even when the match is completed
            Player1_Winner = JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["winner"]
            Player2_Winner = JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["winner"]

            if (Player1_Winner):
                Player1Color = "#ff0"
            elif (Player2_Winner):
                Player2Color = "#ff0"

            Player1_Sets = ""
            Player2_Sets = ""

            # if its not a walkover
            if JSON["events"][EventIndex]["competitions"][x]["status"]["type"]["description"] != "Walkover":
                Number_Sets = len(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"])

                for z in range(0, Number_Sets, 1):
                    Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                    Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

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
                                        content = Player1_Name[3:15],
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
                                        content = Player2_Name[3:15],
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
    WTA_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/wta/scoreboard"
    CacheData = get_cachable_data(WTA_SCORES_URL, 120)
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
                name = "Tourney",
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
        titleColor = "#7915ff"
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

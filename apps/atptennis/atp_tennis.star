"""
Applet: ATP Tennis
Summary: Shows ATP scores
Description: Display tennis scores from a tournament chosen in the dropdown. Shows live matches and if selected, any match completed in the past 24 hours.
Author: M0ntyP

Note:
ESPN sometimes shows completed matches as stil being "In Progress" well after they have been completed so those matches will continue to appear as in progress matches. 

v1.1
Used "post" state for completed matches, this will capture both Final and Retired
Added handling for when no tournaments are on

"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Australia/Adelaide"

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    RotationSpeed = config.get("speed", "3")

    # hold 1 min cache for live scores
    ATP_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/atp/scoreboard"
    CacheData = get_cachable_data(ATP_SCORES_URL, 60)
    ATP_JSON = json.decode(CacheData)

    Display1 = []
    InProgressMatchList = []
    CompletedMatchList = []
    InProgress = 0

    TestID = "713-2023"
    SelectedTourneyID = config.get("TournamentList", TestID)
    ShowCompleted = config.get("CompletedOn", "true")
    Number_Events = len(ATP_JSON["events"])
    EventIndex = 0

    # Find the number of "In Progress" matches for the selected tournament
    for x in range(0, Number_Events, 1):
        if SelectedTourneyID == ATP_JSON["events"][x]["id"]:
            # Capture the index of the particular event, we'll need this later on
            EventIndex = x

            # if there are 10 items, this means we have matches
            # if != 10 then call function that says tournament has not started yet
            if len(ATP_JSON["events"][x]) == 10:
                for y in range(0, len(ATP_JSON["events"][x]["competitions"]), 1):
                    # if the match is "In Progress" and its a singles match, lets add it to the list of in progress matches
                    if ATP_JSON["events"][x]["competitions"][y]["status"]["type"]["description"] == "In Progress":
                        if ATP_JSON["events"][x]["competitions"][y]["competitors"][0]["type"] == "athlete":
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
                if len(ATP_JSON["events"][x]) == 10:
                    for y in range(0, len(ATP_JSON["events"][x]["competitions"]), 1):
                        # if the match is completed ("post") and its a singles match ("athlete") and the start time of the match was < 24 hrs ago, lets add it to the list of completed matches
                        if ATP_JSON["events"][x]["competitions"][y]["status"]["type"]["state"] == "post":
                            if ATP_JSON["events"][x]["competitions"][y]["competitors"][0]["type"] == "athlete":
                                MatchTime = ATP_JSON["events"][EventIndex]["competitions"][y]["date"]
                                MatchTime = time.parse_time(MatchTime, format = "2006-01-02T15:04Z").in_location(timezone)
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

    TourneyName = JSON["events"][EventIndex]["name"]
    TitleBarColor = titleBar(SelectedTourneyID)

    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyName[:16], color = "#FFF", font = "CG-pixel-3x5-mono"))]
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
            Player2_Name = JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["athlete"]["shortName"]

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
                                        content = Player1_Name[3:13],
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
                                        content = Player2_Name[3:13],
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

    TourneyName = JSON["events"][EventIndex]["name"]
    TitleBarColor = titleBar(SelectedTourneyID)
    Title = [render.Box(width = 64, height = 5, color = TitleBarColor, child = render.Text(content = TourneyName[:16], color = "#FFF", font = "CG-pixel-3x5-mono"))]
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

            Number_Sets = len(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"])
            Player1_Sets = ""
            Player2_Sets = ""

            for z in range(0, Number_Sets, 1):
                Player1SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][0]["linescores"][z]["value"])
                Player2SetScore = humanize.ftoa(JSON["events"][EventIndex]["competitions"][x]["competitors"][1]["linescores"][z]["value"])

                Player1_Sets = Player1_Sets + Player1SetScore
                Player2_Sets = Player2_Sets + Player2SetScore

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
                                        content = Player1_Name[3:13],
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
                                        content = Player2_Name[3:13],
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
    ATP_SCORES_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/atp/scoreboard"
    CacheData = get_cachable_data(ATP_SCORES_URL, 120)
    ATP_JSON = json.decode(CacheData)

    Number_Events = len(ATP_JSON["events"])

    Events = []
    EventsID = []
    TournamentOptions = []
    ActualEvents = 0

    # Only show "In Progress" tournaments
    for x in range(0, Number_Events, 1):
        if ATP_JSON["events"][x]["status"]["type"]["state"] == "in":
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
    key = base64.encode(url)
    data = cache.get(key)
    if data != None:
        # print("Using cached data")
        return base64.decode(data)

    res = http.get(url = url)

    #print("Getting new data")
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)
    return res.body()

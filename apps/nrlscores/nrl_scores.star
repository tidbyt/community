"""
Applet: NRL Scores
Summary: Shows NRL scores
Description: Shows scores for the Australian Rugby League competition (NRL).
Author: M0ntyP

v1.0
First release

v1.1
Updated abbreviations
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MATCHES_URL = "https://www.nrl.com/draw//data?competition=111"
LADDER_URL = "https://www.nrl.com/ladder//data?competition=111"
LADDER_CACHE = 3600 * 8  # 8 hrs
MATCH_CACHE = 600  # 10 min
LIVE_CACHE = 30  # 30 secs
DEFAULT_TIMEZONE = "Australia/Adelaide"
DEFAULT_TEAM = "500011"

def main(config):
    RotationSpeed = config.get("speed", "3")
    ViewSelection = config.get("View", "Live")
    TeamListSelection = config.get("TeamList", DEFAULT_TEAM)
    UpcomingSelection = config.get("Upcoming", "Record")

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    renderDisplay = []

    MatchData = get_cachable_data(MATCHES_URL, MATCH_CACHE)
    MatchesJSON = json.decode(MatchData)
    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    RoundNumber = MatchesJSON["fixtures"][0]["roundTitle"]
    RoundNumber = RoundNumber[6:]

    LIVE_URL = MATCHES_URL + "&round=" + RoundNumber
    LiveData = get_cachable_data(LIVE_URL, LIVE_CACHE)
    LiveJSON = json.decode(LiveData)

    Fixtures = len(MatchesJSON["fixtures"])
    ScoreFont = "CG-pixel-4x5-mono"
    ScoreWidth = 40

    if ViewSelection == "All":
        for z in range(0, Fixtures, 1):
            GameState = MatchesJSON["fixtures"][z]["matchState"]
            MatchMode = MatchesJSON["fixtures"][z]["matchMode"]
            HomeScore = ""
            AwayScore = ""
            HomeTeam = MatchesJSON["fixtures"][z]["homeTeam"]["nickName"]
            HomeTeamID = MatchesJSON["fixtures"][z]["homeTeam"]["teamId"]
            AwayTeam = MatchesJSON["fixtures"][z]["awayTeam"]["nickName"]
            AwayTeamID = MatchesJSON["fixtures"][z]["awayTeam"]["teamId"]

            if MatchMode == "Live":
                HomeScore = LiveJSON["fixtures"][z]["homeTeam"]["score"]
                AwayScore = LiveJSON["fixtures"][z]["awayTeam"]["score"]
                GameState = LiveJSON["fixtures"][z]["clock"]["gameTime"]
                ScoreFont = "Dina_r400-6"
                ScoreWidth = 50

            if GameState == "FullTime":
                HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["score"]
                AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["score"]
                GameState = "Full Time"
                ScoreFont = "Dina_r400-6"
                ScoreWidth = 50

            if GameState == "Upcoming":
                ScoreWidth = 40
                ScoreFont = "CG-pixel-4x5-mono"
                if UpcomingSelection == "Record":
                    HomeScore = getRecord(HomeTeam, LadderJSON)
                    AwayScore = getRecord(AwayTeam, LadderJSON)

                elif UpcomingSelection == "Ladder":
                    HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["teamPosition"]
                    AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["teamPosition"]

                elif UpcomingSelection == "Odds":
                    HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["odds"]
                    AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["odds"]

                KickOff = MatchesJSON["fixtures"][z]["clock"]["kickOffTimeLong"]
                convertedTime = time.parse_time(KickOff, format = "2006-01-02T15:04:00Z").in_location(timezone)
                if convertedTime.format("2/1") != now.format("2/1"):
                    GameState = convertedTime.format("2/1 3:04PM")
                else:
                    GameState = convertedTime.format("3:04 PM")

            home_team_bkg = getTeamBkgColour(HomeTeamID)
            away_team_bkg = getTeamBkgColour(AwayTeamID)
            home_team_abb = getTeamAbb(HomeTeamID)
            away_team_abb = getTeamAbb(AwayTeamID)

            renderDisplay.extend([
                render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "start",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = [
                                        #Home Team
                                        render.Box(width = 64, height = 13, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                            render.Box(width = 25, height = 12, child = render.Text(content = home_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                            render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(HomeScore), color = "#FFF", font = ScoreFont)),
                                        ])),
                                        #Away Team
                                        render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                            render.Box(width = 25, height = 12, child = render.Text(content = away_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                            render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(AwayScore), color = "#FFF", font = ScoreFont)),
                                        ])),
                                        #Game time
                                        render.Box(width = 64, height = 6, color = "#000", child = render.Text(GameState, font = "CG-pixel-4x5-mono")),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ])

    if ViewSelection == "Live":
        Found = False

        HomeTeamID = ""
        AwayTeamID = ""
        HomeScore = ""
        AwayScore = ""
        GameState = ""

        for z in range(0, Fixtures, 1):
            GameState = LiveJSON["fixtures"][z]["matchState"]
            MatchMode = LiveJSON["fixtures"][z]["matchMode"]
            HomeTeam = LiveJSON["fixtures"][z]["homeTeam"]["nickName"]
            HomeTeamID = LiveJSON["fixtures"][z]["homeTeam"]["teamId"]
            AwayTeam = LiveJSON["fixtures"][z]["awayTeam"]["nickName"]
            AwayTeamID = LiveJSON["fixtures"][z]["awayTeam"]["teamId"]
            HomeScore = ""
            AwayScore = ""

            if MatchMode == "Post":
                continue

            if MatchMode == "Live":
                HomeScore = LiveJSON["fixtures"][z]["homeTeam"]["score"]
                AwayScore = LiveJSON["fixtures"][z]["awayTeam"]["score"]
                GameState = LiveJSON["fixtures"][z]["clock"]["gameTime"]
                ScoreFont = "Dina_r400-6"
                ScoreWidth = 50
                Found = True
                break

            if GameState == "Upcoming":
                ScoreWidth = 40
                ScoreFont = "CG-pixel-4x5-mono"
                Found = True
                if UpcomingSelection == "Record":
                    HomeScore = getRecord(HomeTeam, LadderJSON)
                    AwayScore = getRecord(AwayTeam, LadderJSON)
                elif UpcomingSelection == "Ladder":
                    HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["teamPosition"]
                    AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["teamPosition"]
                elif UpcomingSelection == "Odds":
                    HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["odds"]
                    AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["odds"]
                KickOff = LiveJSON["fixtures"][z]["clock"]["kickOffTimeLong"]
                convertedTime = time.parse_time(KickOff, format = "2006-01-02T15:04:00Z").in_location(timezone)
                if convertedTime.format("2/1") != now.format("2/1"):
                    GameState = convertedTime.format("2/1 3:04PM")
                else:
                    GameState = convertedTime.format("3:04 PM")
                break

        # must be the last game of the round, so stay on that game
        if Found == False:
            HomeScore = LiveJSON["fixtures"][Fixtures - 1]["homeTeam"]["score"]
            AwayScore = LiveJSON["fixtures"][Fixtures - 1]["awayTeam"]["score"]
            GameState = "Full Time"
            ScoreFont = "Dina_r400-6"
            ScoreWidth = 50

        home_team_bkg = getTeamBkgColour(HomeTeamID)
        away_team_bkg = getTeamBkgColour(AwayTeamID)
        home_team_abb = getTeamAbb(HomeTeamID)
        away_team_abb = getTeamAbb(AwayTeamID)

        renderDisplay.extend([
            render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = [
                                    #Home Team
                                    render.Box(width = 64, height = 13, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                        render.Box(width = 25, height = 12, child = render.Text(content = home_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                        render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(HomeScore), color = "#FFF", font = ScoreFont)),
                                    ])),
                                    #Away Team
                                    render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                        render.Box(width = 25, height = 12, child = render.Text(content = away_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                        render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(AwayScore), color = "#FFF", font = ScoreFont)),
                                    ])),
                                    #Game time
                                    render.Box(width = 64, height = 6, color = "#000", child = render.Text(GameState, font = "CG-pixel-4x5-mono")),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ])

    if ViewSelection == "Team":
        Found = False
        HomeScore = ""
        AwayScore = ""

        for z in range(0, Fixtures, 1):
            HomeTeamID = MatchesJSON["fixtures"][z]["homeTeam"]["teamId"]
            AwayTeamID = MatchesJSON["fixtures"][z]["awayTeam"]["teamId"]

            if HomeTeamID == int(TeamListSelection) or AwayTeamID == int(TeamListSelection):
                GameState = MatchesJSON["fixtures"][z]["matchState"]
                MatchMode = MatchesJSON["fixtures"][z]["matchMode"]
                HomeTeam = MatchesJSON["fixtures"][z]["homeTeam"]["nickName"]
                AwayTeam = MatchesJSON["fixtures"][z]["awayTeam"]["nickName"]

                if MatchMode == "Live":
                    HomeScore = LiveJSON["fixtures"][z]["homeTeam"]["score"]
                    AwayScore = LiveJSON["fixtures"][z]["awayTeam"]["score"]
                    GameState = LiveJSON["fixtures"][z]["clock"]["gameTime"]
                    ScoreFont = "Dina_r400-6"
                    ScoreWidth = 50

                if GameState == "FullTime":
                    HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["score"]
                    AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["score"]
                    GameState = "Full Time"
                    ScoreFont = "Dina_r400-6"
                    ScoreWidth = 50

                if GameState == "Upcoming":
                    ScoreWidth = 40
                    ScoreFont = "CG-pixel-4x5-mono"
                    if UpcomingSelection == "Record":
                        HomeScore = getRecord(HomeTeam, LadderJSON)
                        AwayScore = getRecord(AwayTeam, LadderJSON)
                    elif UpcomingSelection == "Ladder":
                        HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["teamPosition"]
                        AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["teamPosition"]
                    elif UpcomingSelection == "Odds":
                        HomeScore = MatchesJSON["fixtures"][z]["homeTeam"]["odds"]
                        AwayScore = MatchesJSON["fixtures"][z]["awayTeam"]["odds"]
                    KickOff = MatchesJSON["fixtures"][z]["clock"]["kickOffTimeLong"]
                    convertedTime = time.parse_time(KickOff, format = "2006-01-02T15:04:00Z").in_location(timezone)
                    if convertedTime.format("2/1") != now.format("2/1"):
                        GameState = convertedTime.format("2/1 3:04PM")
                    else:
                        GameState = convertedTime.format("3:04 PM")

                home_team_bkg = getTeamBkgColour(HomeTeamID)
                away_team_bkg = getTeamBkgColour(AwayTeamID)
                home_team_abb = getTeamAbb(HomeTeamID)
                away_team_abb = getTeamAbb(AwayTeamID)

                renderDisplay.extend([
                    render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = [
                                            #Home Team
                                            render.Box(width = 64, height = 13, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                render.Box(width = 25, height = 12, child = render.Text(content = home_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                                render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(HomeScore), color = "#FFF", font = ScoreFont)),
                                            ])),
                                            #Away Team
                                            render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                render.Box(width = 25, height = 12, child = render.Text(content = away_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                                render.Box(width = ScoreWidth, height = 12, child = render.Text(content = str(AwayScore), color = "#FFF", font = ScoreFont)),
                                            ])),
                                            #Game time
                                            render.Box(width = 64, height = 6, color = "#000", child = render.Text(GameState, font = "CG-pixel-4x5-mono")),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ])
                Found = True
                break

        # Team must be playing a bye
        if Found == False:
            for z in range(0, len(MatchesJSON["byes"]), 1):
                Team = MatchesJSON["byes"][z]["teamNickName"]
                SelectedTeamName = getTeamName(int(TeamListSelection))

                if SelectedTeamName == Team:
                    home_team_bkg = getTeamBkgColour(int(TeamListSelection))
                    home_team_abb = getTeamAbb(int(TeamListSelection))
                    away_team_abb = "BYE"
                    away_team_bkg = "#000"
                    HomeScore = ""
                    AwayScore = ""
                    GameState = ""

                    renderDisplay.extend([
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                #Home Team
                                                render.Box(width = 64, height = 13, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                    render.Box(width = 25, height = 12, child = render.Text(content = home_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                                    render.Box(width = 40, height = 12, child = render.Text(content = str(HomeScore), color = "#FFF")),
                                                ])),
                                                #Away Team
                                                render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                    render.Box(width = 25, height = 12, child = render.Text(content = away_team_abb, color = "#FFF", font = "Dina_r400-6")),
                                                    render.Box(width = 40, height = 12, child = render.Text(content = str(AwayScore), color = "#FFF")),
                                                ])),
                                                #Game time
                                                render.Box(width = 64, height = 6, color = "#000", child = render.Text(GameState, font = "CG-pixel-4x5-mono")),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ])

    return render.Root(
        show_full_animation = True,
        delay = int(RotationSpeed) * 1000,
        child = render.Column(
            children = [
                render.Animation(
                    children = renderDisplay,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each score is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
            schema.Dropdown(
                id = "View",
                name = "Matches to show",
                desc = "What to display",
                icon = "gear",
                default = ViewingOptions[0].value,
                options = ViewingOptions,
            ),
            schema.Dropdown(
                id = "Upcoming",
                name = "Upcoming",
                desc = "What to display",
                icon = "gear",
                default = UpcomingOptions[0].value,
                options = UpcomingOptions,
            ),
            schema.Generated(
                id = "generated",
                source = "View",
                handler = MoreOptions,
            ),
        ],
    )

def MoreOptions(View):
    if View == "Team":
        return [
            schema.Dropdown(
                id = "TeamList",
                name = "Teams",
                desc = "Choose your team",
                icon = "football",
                default = TeamOptions[0].value,
                options = TeamOptions,
            ),
        ]
    else:
        return None

def getRecord(Team, JSON):
    Win = ""
    Draw = ""
    Loss = ""

    for x in range(0, 17, 1):
        if Team == JSON["positions"][x]["teamNickname"]:
            Win = JSON["positions"][x]["stats"]["wins"]
            Draw = JSON["positions"][x]["stats"]["drawn"]
            Loss = JSON["positions"][x]["stats"]["lost"]
            break

    Record = str(Win) + "-" + str(Draw) + "-" + str(Loss)

    return Record

def getTeamBkgColour(team_id):
    if team_id == 500011:  #Broncos
        return ("#620036")
    elif team_id == 500010:  #Bulldogs
        return ("#00519f")
    elif team_id == 500012:  #Cowboys
        return ("#012a5a")
    elif team_id == 500723:  #Dolphins
        return ("#da1119")
    elif team_id == 500022:  #Dragons
        return ("#db221a")
    elif team_id == 500031:  #Eels
        return ("#006baf")
    elif team_id == 500003:  #Knights
        return ("#0050a0")
    elif team_id == 500014:  #Panthers
        return ("#2a2e2e")
    elif team_id == 500005:  #Rabbitohs
        return ("#007845")
    elif team_id == 500013:  #Raiders
        return ("#90c348")
    elif team_id == 500001:  #Roosters
        return ("#0b2c58")
    elif team_id == 500002:  #Sea Eagles
        return ("#620036")
    elif team_id == 500028:  #Sharks
        return ("#00a4d1")
    elif team_id == 500021:  #Storm
        return ("#562a89")
    elif team_id == 500004:  #Titans
        return ("#094870")
    elif team_id == 500032:  #Warriors
        return ("#151e6b")
    elif team_id == 500023:  #Tigers
        return ("#ef6d10")
    elif team_id == 500146:  # NSW
        return ("#5faddf")
    elif team_id == 500147:  # QLD
        return ("#83003f")

    return None

def getTeamAbb(team_id):
    if team_id == 500011:  #Broncos
        return ("BRI")
    elif team_id == 500010:  #Bulldogs
        return ("CBY")
    elif team_id == 500012:  #Cowboys
        return ("NQL")
    elif team_id == 500723:  #Dolphins
        return ("DOL")
    elif team_id == 500022:  #Dragons
        return ("SGI")
    elif team_id == 500031:  #Eels
        return ("PAR")
    elif team_id == 500003:  #Knights
        return ("NEW")
    elif team_id == 500014:  #Panthers
        return ("PEN")
    elif team_id == 500005:  #Rabbitohs
        return ("SOU")
    elif team_id == 500013:  #Raiders
        return ("CAN")
    elif team_id == 500001:  #Roosters
        return ("SYD")
    elif team_id == 500002:  #Sea Eagles
        return ("MAN")
    elif team_id == 500028:  #Sharks
        return ("CRO")
    elif team_id == 500021:  #Storm
        return ("MEL")
    elif team_id == 500004:  #Titans
        return ("GLD")
    elif team_id == 500032:  #Warriors
        return ("WAR")
    elif team_id == 500023:  #Tigers
        return ("WST")

    return None

def getTeamName(team_id):
    if team_id == 500011:  #Broncos
        return ("Broncos")
    elif team_id == 500010:  #Bulldogs
        return ("Bulldogs")
    elif team_id == 500012:  #Cowboys
        return ("Cowboys")
    elif team_id == 500723:  #Dolphins
        return ("Dolphins")
    elif team_id == 500022:  #Dragons
        return ("Dragons")
    elif team_id == 500031:  #Eels
        return ("Eels")
    elif team_id == 500003:  #Knights
        return ("Knights")
    elif team_id == 500014:  #Panthers
        return ("Panthers")
    elif team_id == 500005:  #Rabbitohs
        return ("Rabbitohs")
    elif team_id == 500013:  #Raiders
        return ("Raiders")
    elif team_id == 500001:  #Roosters
        return ("Roosters")
    elif team_id == 500002:  #Sea Eagles
        return ("Sea Eagles")
    elif team_id == 500028:  #Sharks
        return ("Sharks")
    elif team_id == 500021:  #Storm
        return ("Storm")
    elif team_id == 500004:  #Titans
        return ("Titans")
    elif team_id == 500032:  #Warriors
        return ("Warriors")
    elif team_id == 500023:  #Tigers
        return ("Wests Tigers")
    elif team_id == 500146:  # NSW
        return ("Blues")
    elif team_id == 500147:  # QLD
        return ("Maroons")
    return None

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

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

ViewingOptions = [
    schema.Option(
        display = "All matches",
        value = "All",
    ),
    schema.Option(
        display = "Live matches",
        value = "Live",
    ),
    schema.Option(
        display = "Specific Team",
        value = "Team",
    ),
]

UpcomingOptions = [
    schema.Option(
        display = "W-D-L Record",
        value = "Record",
    ),
    schema.Option(
        display = "Ladder Position",
        value = "Ladder",
    ),
    schema.Option(
        display = "Match Odds",
        value = "Odds",
    ),
]

TeamOptions = [
    schema.Option(
        display = "Brisbane Broncos",
        value = "500011",
    ),
    schema.Option(
        display = "Canterbury Bulldogs",
        value = "500010",
    ),
    schema.Option(
        display = "FNQ Cowboys",
        value = "500012",
    ),
    schema.Option(
        display = "Redcliffe Dolphins",
        value = "500723",
    ),
    schema.Option(
        display = "St George Dragons",
        value = "500022",
    ),
    schema.Option(
        display = "Parramatta Eels",
        value = "500031",
    ),
    schema.Option(
        display = "Newcastle Knights",
        value = "500003",
    ),
    schema.Option(
        display = "Penrith Panthers",
        value = "500014",
    ),
    schema.Option(
        display = "South Sydney Rabbitohs",
        value = "500005",
    ),
    schema.Option(
        display = "Canberra Raiders",
        value = "500013",
    ),
    schema.Option(
        display = "Sydney City Roosters",
        value = "500001",
    ),
    schema.Option(
        display = "Manly Sea Eagles",
        value = "500002",
    ),
    schema.Option(
        display = "Cronulla Sharks",
        value = "500028",
    ),
    schema.Option(
        display = "Melbourne Storm",
        value = "500021",
    ),
    schema.Option(
        display = "Gold Coast Titans",
        value = "500004",
    ),
    schema.Option(
        display = "NZ Warriors",
        value = "500032",
    ),
    schema.Option(
        display = "Wests Tigers",
        value = "500023",
    ),
]

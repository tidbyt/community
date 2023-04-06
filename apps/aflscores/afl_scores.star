"""
Applet: AFL Scores
Summary: Shows AFL Scores
Description: Shows AFL (Australian Football League) scores. Option to show all matches for the round or focus on one team
Author: M0ntyP

v1.1 - Moved game time for live game up 1 whole pixel
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Australia/Adelaide"
DEFAULT_TEAM = "10"  # Geelong

MATCHES_URL = "https://aflapi.afl.com.au/afl/v2/matches?competitionId=1&compSeasonId=52"
LADDER_URL = "https://aflapi.afl.com.au/afl/v2/compseasons/52/ladders"
ROUND_URL = "https://aflapi.afl.com.au/afl/v2/matches?competitionId=1&compSeasonId=52&roundNumber="
TEAM_SUFFIX = "&teamId="

MATCH_CACHE = 86400
LADDER_CACHE = 86400
ROUND_CACHE = 60
LIVE_CACHE = 30

# Pre-season - Competition=2&CompSeason=53
# Regular - competitionId=1&compSeasonId=52

def main(config):
    RotationSpeed = config.get("speed", "3")
    AllMatchesBool = config.bool("AllMatches", True)
    TeamListSelection = config.get("TeamList", DEFAULT_TEAM)

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    # Lets initialize!
    renderCategory = []
    CURRENT_ROUND_URL = ""
    HomeWins = ""
    HomeDraws = ""
    HomeLosses = ""
    AwayWins = ""
    AwayDraws = ""
    AwayLosses = ""

    # cache specific all match data and ladder data for 24hrs
    # MatchesJSON is just to get the current round number
    # LadderJSON is just to get standings for teams yet to play
    MatchData = get_cachable_data(MATCHES_URL, MATCH_CACHE)
    MatchesJSON = json.decode(MatchData)
    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    # Get the Current Round, according to the API
    CurrentRound = str(MatchesJSON["matches"][0]["compSeason"]["currentRoundNumber"])

    if AllMatchesBool == True:
        CURRENT_ROUND_URL = ROUND_URL + CurrentRound
    elif AllMatchesBool == False:
        CURRENT_ROUND_URL = ROUND_URL + CurrentRound + TEAM_SUFFIX + TeamListSelection

    # Cache match info for 1 min
    RoundData = get_cachable_data(CURRENT_ROUND_URL, ROUND_CACHE)
    CurrentRoundJSON = json.decode(RoundData)

    # Use the Squiggle API for live games, cache  data for 30 secs
    SQUIGGLE_URL = "https://api.squiggle.com.au/?q=games;round=" + CurrentRound + ";complete=!100"
    LiveData = get_cachable_data(SQUIGGLE_URL, LIVE_CACHE)
    LiveJSON = json.decode(LiveData)

    GamesThisRound = len(CurrentRoundJSON["matches"])
    IncompleteMatches = len(LiveJSON["games"])

    for x in range(0, GamesThisRound, 1):
        status = CurrentRoundJSON["matches"][x]["status"]
        gametime = CurrentRoundJSON["matches"][x]["utcStartTime"]

        HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
        HomeTeamName = CurrentRoundJSON["matches"][x]["home"]["team"]["name"]
        AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]
        AwayTeamName = CurrentRoundJSON["matches"][x]["away"]["team"]["name"]

        home_team_abb = getTeamAbbFromID(HomeTeam)
        away_team_abb = getTeamAbbFromID(AwayTeam)

        home_team_font = getTeamFontColour(HomeTeam)
        home_team_bkg = getTeamBkgColour(HomeTeam)

        away_team_font = getTeamFontColour(AwayTeam)
        away_team_bkg = getTeamBkgColour(AwayTeam)

        # if the game hasnt started yet, show the time of first bounce corrected for local time. API provides UTC time
        if status == "SCHEDULED" or status == "UNCONFIRMED_TEAMS" or status == "CONFIRMED_TEAMS":
            convertedTime = time.parse_time(gametime, format = "2006-01-02T15:04:00.000+0000").in_location(timezone)

            if convertedTime.format("2/1") != now.format("2/1"):
                gametime = convertedTime.format("2/1 3:04PM")
            else:
                gametime = convertedTime.format("3:04 PM")

            # show the win-draw-loss record for teams
            for y in range(0, 18, 1):
                if HomeTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                    HomeWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                    HomeLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                    HomeDraws = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"])
                if AwayTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                    AwayWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                    AwayLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                    AwayDraws = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"])

            HomeRecord = HomeWins + "-" + HomeDraws + "-" + HomeLosses
            AwayRecord = AwayWins + "-" + AwayDraws + "-" + AwayLosses

            # Render on the screen
            renderCategory.extend([
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
                                        #Draw the box and row, then
                                        render.Box(
                                            width = 64,
                                            height = 13,
                                            color = home_team_bkg,
                                            child =
                                                render.Row(expanded = True, main_align = "space_between", cross_align = "right", children = [
                                                    render.Row(
                                                        children = [
                                                            render.Padding(
                                                                pad = (1, 0, 1, 1),
                                                                child = render.Text(content = home_team_abb, color = home_team_font, font = "Dina_r400-6"),
                                                            ),
                                                        ],
                                                    ),
                                                    render.Row(
                                                        children = [
                                                            render.Padding(
                                                                pad = (1, 3, 1, 0),
                                                                child = render.Text(content = HomeRecord, color = home_team_font, font = "CG-pixel-4x5-mono"),
                                                            ),
                                                        ],
                                                    ),
                                                ]),
                                        ),
                                        render.Box(
                                            width = 64,
                                            height = 13,
                                            color = away_team_bkg,
                                            child =
                                                render.Row(expanded = True, main_align = "space_between", cross_align = "right", children = [
                                                    render.Row(
                                                        children = [
                                                            render.Padding(
                                                                pad = (1, 0, 1, 1),
                                                                child = render.Text(content = away_team_abb, color = away_team_font, font = "Dina_r400-6"),
                                                            ),
                                                        ],
                                                    ),
                                                    render.Row(
                                                        children = [
                                                            render.Padding(
                                                                pad = (1, 3, 1, 0),
                                                                child = render.Text(content = AwayRecord, color = away_team_font, font = "CG-pixel-4x5-mono"),
                                                            ),
                                                        ],
                                                    ),
                                                ]),
                                        ),
                                        #Game time
                                        render.Box(width = 64, height = 6, color = "#000", child = render.Text(gametime, font = "CG-pixel-4x5-mono")),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ])

        # We have a live game!
        if status == "LIVE":
            # get home team name (first 5 chars) and go to Squiggle for incomplete games that round
            # loop through matches until home team matches hteam or ateam
            for y in range(0, IncompleteMatches, 1):
                SquiggleHome = LiveJSON["games"][y]["hteam"]

                if HomeTeamName[:5] == SquiggleHome[:5] or AwayTeamName[:5] == SquiggleHome[:5]:
                    HomeScore = str(LiveJSON["games"][y]["hscore"])
                    HomeGoals = str(LiveJSON["games"][y]["hgoals"])
                    HomeBehinds = str(LiveJSON["games"][y]["hbehinds"])

                    AwayScore = str(LiveJSON["games"][y]["ascore"])
                    AwayGoals = str(LiveJSON["games"][y]["agoals"])
                    AwayBehinds = str(LiveJSON["games"][y]["abehinds"])

                    gametime = str(LiveJSON["games"][y]["timestr"])

                    # Render on the screen
                    renderCategory.extend([
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
                                                #Draw the box and row, then
                                                render.Box(width = 64, height = 12, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                    render.Box(width = 20, height = 12, child = render.Text(content = home_team_abb, color = home_team_font)),
                                                    render.Box(width = 12, height = 12, child = render.Text(content = HomeGoals, color = home_team_font)),
                                                    render.Box(width = 12, height = 12, child = render.Text(content = HomeBehinds, color = home_team_font)),
                                                    render.Box(width = 20, height = 12, child = render.Text(content = HomeScore, color = home_team_font)),
                                                ])),
                                                #Away Team
                                                render.Box(width = 64, height = 12, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                                    render.Box(width = 20, height = 12, child = render.Text(content = away_team_abb, color = away_team_font)),
                                                    render.Box(width = 12, height = 12, child = render.Text(content = AwayGoals, color = away_team_font)),
                                                    render.Box(width = 12, height = 12, child = render.Text(content = AwayBehinds, color = away_team_font)),
                                                    render.Box(width = 20, height = 12, child = render.Text(content = AwayScore, color = away_team_font)),
                                                ])),
                                                #Game time
                                                render.Box(width = 64, height = 8, color = "#000", child = render.Text(gametime, font = "CG-pixel-3x5-mono")),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ])
                    break

        # if the game is complete, show the status and get the scores
        if status == "CONCLUDED" or status == "POSTGAME":
            gametime = "FULL TIME"

            HomeScore = str(CurrentRoundJSON["matches"][x]["home"]["score"]["totalScore"])
            HomeGoals = str(CurrentRoundJSON["matches"][x]["home"]["score"]["goals"])
            HomeBehinds = str(CurrentRoundJSON["matches"][x]["home"]["score"]["behinds"])

            AwayScore = str(CurrentRoundJSON["matches"][x]["away"]["score"]["totalScore"])
            AwayGoals = str(CurrentRoundJSON["matches"][x]["away"]["score"]["goals"])
            AwayBehinds = str(CurrentRoundJSON["matches"][x]["away"]["score"]["behinds"])

            # Render on the screen
            renderCategory.extend([
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
                                        #Draw the box and row, then
                                        render.Box(width = 64, height = 12, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                            render.Box(width = 20, height = 10, child = render.Text(content = home_team_abb, color = home_team_font)),
                                            render.Box(width = 12, height = 10, child = render.Text(content = HomeGoals, color = home_team_font)),
                                            render.Box(width = 12, height = 10, child = render.Text(content = HomeBehinds, color = home_team_font)),
                                            render.Box(width = 18, height = 10, child = render.Text(content = HomeScore, color = home_team_font)),
                                        ])),
                                        #Away Team
                                        render.Box(width = 64, height = 12, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                            render.Box(width = 20, height = 10, child = render.Text(content = away_team_abb, color = away_team_font)),
                                            render.Box(width = 12, height = 10, child = render.Text(content = AwayGoals, color = away_team_font)),
                                            render.Box(width = 12, height = 10, child = render.Text(content = AwayBehinds, color = away_team_font)),
                                            render.Box(width = 18, height = 10, child = render.Text(content = AwayScore, color = away_team_font)),
                                        ])),
                                        #Game time
                                        render.Box(width = 64, height = 8, color = "#000", child = render.Text(gametime, font = "CG-pixel-3x5-mono")),
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
                    children = renderCategory,
                ),
            ],
        ),
    )

def getTeamAbbFromID(team_id):
    if team_id == 1:  #ADE
        return ("ADE")
    elif team_id == 2:  #BRI
        return ("BRI")
    elif team_id == 5:  #CAR
        return ("CAR")
    elif team_id == 3:  #COL
        return ("COL")
    elif team_id == 12:  #ESS
        return ("ESS")
    elif team_id == 14:  #FRE
        return ("FRE")
    elif team_id == 10:  #GEE
        return ("GEE")
    elif team_id == 4:  #GCS
        return ("GCS")
    elif team_id == 15:  #GWS
        return ("GWS")
    elif team_id == 9:  #HAW
        return ("HAW")
    elif team_id == 17:  #MEL
        return ("MEL")
    elif team_id == 6:  #NOR
        return ("NOR")
    elif team_id == 7:  #POR
        return ("PTA")
    elif team_id == 16:  #RIC
        return ("RIC")
    elif team_id == 11:  #STK
        return ("STK")
    elif team_id == 13:  #SYD
        return ("SYD")
    elif team_id == 18:  #WCE
        return ("WCE")
    elif team_id == 8:  #WBD
        return ("WBD")
    return None

def getTeamFontColour(team_id):
    if team_id == 1:  #ADE
        return ("#FFD200")
    elif team_id == 2:  #BRI
        return ("#EDBF5E")
    elif team_id == 5:  #CAR
        return ("#fff")
    elif team_id == 3:  #COL
        return ("#fff")
    elif team_id == 12:  #ESS
        return ("#f00")
    elif team_id == 14:  #FRE
        return ("#fff")
    elif team_id == 10:  #GEE
        return ("#fff")
    elif team_id == 4:  #GCS
        return ("#df3")
    elif team_id == 15:  #GWS
        return ("#FF7900")
    elif team_id == 9:  #HAW
        return ("#E4AE04")
    elif team_id == 17:  #MEL
        return ("#DE0316")
    elif team_id == 6:  #NOR
        return ("#fff")
    elif team_id == 7:  #POR
        return ("#008AAB")
    elif team_id == 16:  #RIC
        return ("#df3")
    elif team_id == 11:  #STK
        return ("#fff")
    elif team_id == 13:  #SYD
        return ("#fff")
    elif team_id == 18:  #WCE
        return ("#F2AB00")
    elif team_id == 8:  #WBD
        return ("#DE0316")
    return None

def getTeamBkgColour(team_id):
    if team_id == 1:  #ADE
        return ("#00437F")
    elif team_id == 2:  #BRI
        return ("#69003D")
    elif team_id == 5:  #CAR
        return ("#001B2A")
    elif team_id == 3:  #COL
        return ("#000")
    elif team_id == 12:  #ESS
        return ("#000")
    elif team_id == 14:  #FRE
        return ("#2E194B")
    elif team_id == 10:  #GEE
        return ("#001F3D")
    elif team_id == 4:  #GCS
        return ("#E02112")
    elif team_id == 15:  #GWS
        return ("#000")
    elif team_id == 9:  #HAW
        return ("#492718")
    elif team_id == 17:  #MEL
        return ("#061A33")
    elif team_id == 6:  #NOR
        return ("#003690")
    elif team_id == 7:  #POR
        return ("#000")
    elif team_id == 16:  #RIC
        return ("#000")
    elif team_id == 11:  #STK
        return ("#f00")
    elif team_id == 13:  #SYD
        return ("#f00")
    elif team_id == 18:  #WCE
        return ("#002B79")
    elif team_id == 8:  #WBD
        return ("#0039A6")
    return None

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
            schema.Toggle(
                id = "AllMatches",
                name = "All Matches",
                desc = "Display all matches or choose your team",
                icon = "toggleOn",
                default = True,
            ),
            schema.Generated(
                id = "generated",
                source = "AllMatches",
                handler = MoreOptions,
            ),
        ],
    )

def MoreOptions(AllMatches):
    if AllMatches == "false":
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
    elif AllMatches == "true":
        return None
    else:
        return None

def get_cachable_data(url, timeout):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        #print("CACHED")
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)

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

TeamOptions = [
    schema.Option(
        display = "Adelaide",
        value = "1",
    ),
    schema.Option(
        display = "Brisbane",
        value = "2",
    ),
    schema.Option(
        display = "Carlton",
        value = "5",
    ),
    schema.Option(
        display = "Collingwood",
        value = "3",
    ),
    schema.Option(
        display = "Essendon",
        value = "12",
    ),
    schema.Option(
        display = "Fremantle",
        value = "14",
    ),
    schema.Option(
        display = "Geelong",
        value = "10",
    ),
    schema.Option(
        display = "Gold Coast",
        value = "4",
    ),
    schema.Option(
        display = "Greater Western Sydney",
        value = "15",
    ),
    schema.Option(
        display = "Hawthorn",
        value = "9",
    ),
    schema.Option(
        display = "Melbourne",
        value = "17",
    ),
    schema.Option(
        display = "North Melbourne",
        value = "6",
    ),
    schema.Option(
        display = "Port Adelaide",
        value = "7",
    ),
    schema.Option(
        display = "Richmond",
        value = "16",
    ),
    schema.Option(
        display = "St Kilda",
        value = "11",
    ),
    schema.Option(
        display = "Sydney",
        value = "13",
    ),
    schema.Option(
        display = "West Coast",
        value = "18",
    ),
    schema.Option(
        display = "Western Bulldogs",
        value = "8",
    ),
]

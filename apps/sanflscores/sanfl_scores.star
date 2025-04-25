"""
Applet: SANFL Scores
Summary: Shows SANFL Scores
Description: Shows football scores for the SANFL.
Author: M0ntyP

v1.0
First version!

v1.0.1
Fixed team record bug

v1.1
Using logic to work out when the next round starts rather that relying on the data from Ladder API

v1.2
Reduced match cache time for the weekend. We need check more often when the games are about to start
Added leading zero for when seconds on game clock is <10
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

DEFAULT_TIMEZONE = "Australia/Adelaide"

MATCHES_URL = "https://api3.sanflstats.com/fixtures/2025/sanfl"
LADDER_URL = "https://api3.sanflstats.com/ladder/2025/sanfl"

LIVE_CACHE = 30
LADDER_CACHE = 86400  #24 hours

def main(config):
    # Lets initialize!
    renderDisplay = []

    HomeWins = ""
    HomeDraws = ""
    HomeLosses = ""
    AwayWins = ""
    AwayDraws = ""
    AwayLosses = ""
    HomeFound = 0
    AwayFound = 0
    MATCH_CACHE = 43200  #12 hours
    RotationSpeed = 5

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    DayofWeek = now.format("Mon")

    # if its the weekend, lets reduce the cache and check for updates more often
    # And there is 1 Thursday game this year, 24th April
    if DayofWeek == "Fri" or DayofWeek == "Sat" or DayofWeek == "Sun":
        MATCH_CACHE = 120
    if now.month == 4 and now.day == 24:
        MATCH_CACHE = 120

    MatchData = get_cachable_data(MATCHES_URL, MATCH_CACHE)
    MatchesJSON = json.decode(MatchData)
    AllMatches = MatchesJSON["matches"]

    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    CurrentRound = int(LadderJSON["currentRound"])
    NextRound = int(CurrentRound) + 1

    for x in range(0, len(AllMatches), 1):
        # The data in Ladder API does not update "Current Round" quickly enough so we need to look ahead
        # If we are < 48hrs from the first match of the next round, then we'll say the next round is the current
        if int(MatchesJSON["matches"][x]["roundNumber"]) == NextRound:
            StartTime = MatchesJSON["matches"][x]["localStartTime"]
            ConvertedTime = time.parse_time(StartTime, format = "2006-01-02T15:04:05-07:00").in_location(timezone)
            TimetoStart = ConvertedTime - now

            if TimetoStart.hours < 48:
                CurrentRound = NextRound
            break

    for y in range(0, len(AllMatches), 1):
        # break out if we've gone too far
        if int(MatchesJSON["matches"][y]["roundNumber"]) > CurrentRound:
            break

        if int(MatchesJSON["matches"][y]["roundNumber"]) == CurrentRound:
            Status = MatchesJSON["matches"][y]["matchStatus"]

            HomeTeam = MatchesJSON["matches"][y]["homeSquadId"]
            AwayTeam = MatchesJSON["matches"][y]["awaySquadId"]
            HomeTeam = int(HomeTeam)
            AwayTeam = int(AwayTeam)
            HomeRecord = ""
            AwayRecord = ""

            HomeTeamAbb = getTeamAbbFromID(HomeTeam)
            AwayTeamAbb = getTeamAbbFromID(AwayTeam)
            HomeTeamFont = getTeamFontColour(HomeTeam)
            HomeTeamBkg = getTeamBkgColour(HomeTeam)
            AwayTeamFont = getTeamFontColour(AwayTeam)
            AwayTeamBkg = getTeamBkgColour(AwayTeam)

            if Status == "scheduled":
                StartTime = MatchesJSON["matches"][y]["localStartTime"]
                ConvertedTime = time.parse_time(StartTime, format = "2006-01-02T15:04:05-07:00").in_location(timezone)

                if ConvertedTime.format("2/1") != now.format("2/1"):
                    StartTime = ConvertedTime.format("2/1 3:04PM")
                else:
                    StartTime = ConvertedTime.format("3:04 PM")

                HomeFound = 0
                AwayFound = 0

                # if not finals, show team records
                if int(LadderJSON["round"]) < 20:
                    for y in range(0, 10, 1):
                        if str(HomeTeam) == str(LadderJSON["ladder"][y]["squadId"]):
                            HomeWins = str(LadderJSON["ladder"][y]["won"])
                            HomeLosses = str(LadderJSON["ladder"][y]["lost"])
                            HomeDraws = str(LadderJSON["ladder"][y]["drawn"])
                            HomeFound = 1
                        if str(AwayTeam) == str(LadderJSON["ladder"][y]["squadId"]):
                            AwayWins = str(LadderJSON["ladder"][y]["won"])
                            AwayLosses = str(LadderJSON["ladder"][y]["lost"])
                            AwayDraws = str(LadderJSON["ladder"][y]["drawn"])
                            AwayFound = 1

                        # both teams found, lets break out
                        if HomeFound + AwayFound == 2:
                            break

                    if HomeDraws == "0":
                        HomeRecord = HomeWins + "-" + HomeLosses
                    else:
                        HomeRecord = HomeWins + "-" + str(HomeDraws) + "-" + HomeLosses

                    if AwayDraws == "0":
                        AwayRecord = AwayWins + "-" + AwayLosses
                    else:
                        AwayRecord = AwayWins + "-" + str(AwayDraws) + "-" + AwayLosses

                else:
                    HomeRecord = ""
                    AwayRecord = ""

                SchedOutput = showScheduledGame(HomeRecord, AwayRecord, HomeTeamAbb, AwayTeamAbb, HomeTeamFont, AwayTeamFont, HomeTeamBkg, AwayTeamBkg, StartTime)
                renderDisplay.extend(SchedOutput)

            # We have a live game!
            if Status == "playing":
                MatchID = MatchesJSON["matches"][y]["matchId"]
                LIVE_MATCH_URL = "https://api3.sanflstats.com/fixture/" + MatchID
                MatchData = get_cachable_data(LIVE_MATCH_URL, LIVE_CACHE)
                LiveMatch = json.decode(MatchData)
                LiveOutput = showGame(LiveMatch)
                renderDisplay.extend(LiveOutput)

            # if the game is complete, show the status and get the scores
            if Status == "complete":
                CompletedMatch = MatchesJSON["matches"][y]

                # Render on the screen
                CompOutput = showGame(CompletedMatch)
                renderDisplay.extend(CompOutput)

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

def showGame(CurrentMatch):
    renderDisplay = []

    # get details for each team in the match
    HomeTeam = int(CurrentMatch["homeSquadId"])
    AwayTeam = int(CurrentMatch["awaySquadId"])

    home_team_abb = getTeamAbbFromID(HomeTeam)
    away_team_abb = getTeamAbbFromID(AwayTeam)

    home_team_font = getTeamFontColour(HomeTeam)
    home_team_bkg = getTeamBkgColour(HomeTeam)

    away_team_font = getTeamFontColour(AwayTeam)
    away_team_bkg = getTeamBkgColour(AwayTeam)

    HomeScore = CurrentMatch["homeSquadScore"]
    HomeGoals = CurrentMatch["homeSquadGoals"]
    HomeBehinds = CurrentMatch["homeSquadBehinds"]

    AwayScore = CurrentMatch["awaySquadScore"]
    AwayGoals = CurrentMatch["awaySquadGoals"]
    AwayBehinds = CurrentMatch["awaySquadBehinds"]

    if CurrentMatch["currentTime"] == "FT":
        gametime = "FULL TIME"
    elif CurrentMatch["currentTime"] == "HT":
        gametime = "HALF TIME"
    elif CurrentMatch["currentTime"] == "QT":
        gametime = "QTR TIME"
    elif CurrentMatch["currentTime"] == "3QT":
        gametime = "3QTR TIME"
    else:
        TotalSeconds = int(CurrentMatch["periodSeconds"])
        Secs = int(math.mod(TotalSeconds, 60))
        if Secs < 10:
            Secs = "0" + str(Secs)
        Mins = int(int(CurrentMatch["periodSeconds"]) / 60)
        gametime = CurrentMatch["currentTime"] + " " + str(Mins) + ":" + str(Secs)

    # Render on the screen
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
                                    render.Box(width = 20, height = 12, child = render.Text(content = home_team_abb, color = home_team_font, font = "Dina_r400-6")),
                                    render.Box(width = 12, height = 12, child = render.Text(content = HomeGoals, color = home_team_font)),
                                    render.Box(width = 12, height = 12, child = render.Text(content = HomeBehinds, color = home_team_font)),
                                    render.Box(width = 20, height = 12, child = render.Text(content = HomeScore, color = home_team_font)),
                                ])),
                                #Away Team
                                render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                    render.Box(width = 20, height = 12, child = render.Text(content = away_team_abb, color = away_team_font, font = "Dina_r400-6")),
                                    render.Box(width = 12, height = 12, child = render.Text(content = AwayGoals, color = away_team_font)),
                                    render.Box(width = 12, height = 12, child = render.Text(content = AwayBehinds, color = away_team_font)),
                                    render.Box(width = 20, height = 12, child = render.Text(content = AwayScore, color = away_team_font)),
                                ])),
                                #Game time
                                render.Box(width = 64, height = 6, color = "#000", child = render.Text(gametime, font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    ])

    return renderDisplay

def showScheduledGame(HomeRecord, AwayRecord, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg, starttime):
    renderDisplay = []

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
                                render.Box(
                                    width = 64,
                                    height = 13,
                                    color = home_team_bkg,
                                    child = render.Row(expanded = True, main_align = "space_between", cross_align = "right", children = [
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
                                    child = render.Row(expanded = True, main_align = "space_between", cross_align = "right", children = [
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
                                render.Box(width = 64, height = 6, color = "#000", child = render.Text(starttime, font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    ])

    return renderDisplay

def getTeamAbbFromID(team_id):
    if team_id == 7314:  #ADE
        return ("ADE")
    elif team_id == 1040:  #STH
        return ("STH")
    elif team_id == 1039:  #PTA
        return ("PRT")
    elif team_id == 1042:  #WST
        return ("WST")
    elif team_id == 1038:  #NRW
        return ("NWD")
    elif team_id == 1036:  #GLE
        return ("GLG")
    elif team_id == 1037:  #NTH
        return ("NTH")
    elif team_id == 1043:  #WWT
        return ("WWT")
    elif team_id == 1035:  #CEN
        return ("CEN")
    elif team_id == 1041:  #SRT
        return ("SRT")
    return ("NONE")

def getTeamFontColour(team_id):
    if team_id == 7314:  #ADE
        return ("#FFD200")
    elif team_id == 1040:  #STH
        return ("#fff")
    elif team_id == 1039:  #PTA
        return ("#fff")
    elif team_id == 1042:  #WST
        return ("#f00")
    elif team_id == 1038:  #NRW
        return ("#DE0316")
    elif team_id == 1036:  #GLE
        return ("#df3")
    elif team_id == 1037:  #NTH
        return ("#fff")
    elif team_id == 1043:  #WWT
        return ("#F2AB00")
    elif team_id == 1035:  #CEN
        return ("#DE0316")
    elif team_id == 1041:  #SRT
        return ("#599ed6")
    return ("#fff")

def getTeamBkgColour(team_id):
    if team_id == 7314:  #ADE
        return ("#0a2240")
    elif team_id == 1040:  #STH
        return ("#001B2A")
    elif team_id == 1039:  #PTA
        return ("#000")
    elif team_id == 1042:  #WST
        return ("#000")
    elif team_id == 1038:  #NRW
        return ("#061A33")
    elif team_id == 1036:  #GLE
        return ("#000")
    elif team_id == 1037:  #NTH
        return ("#f00")
    elif team_id == 1043:  #WWT
        return ("#002B79")
    elif team_id == 1035:  #CEN
        return ("#0039A6")
    elif team_id == 1041:  #SRT
        return ("#00285d")
    return ("#fff")

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

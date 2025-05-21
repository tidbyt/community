"""
Applet: AFL Scores
Summary: Shows AFL Scores
Description: Shows AFL (Australian Football League) scores. Option to show all matches for the round or focus on one team
Author: M0ntyP

v1.1 - Published 6/4/23
Moved game time for live game up 1 whole pixel
 
v1.2 - Published 15/5/23
Updated caching function 
Handling for no data from API before or during live games, which can occur at times
Slight appearance changes for live and post match displays

v1.2.1 - Published 23/5/23
Bug fix - live games for GWS not working due to mismatch in team name for 2 different data APIs

v2.0 - Published
Updated dropdown -> user can now select to show all matches, live matches or select a specific team 
Live matches option will show next scheduled if there are no live matches in progress
Fixed post game scenario where the official AFL API has game as being live, where Squiggle API had the game as complete leading to a blank display on the Tidbyt
Added handling for bye weeks for when specific team is selected
Added functions for showing scheduled, completed and live games to reduce code and add efficieny (maybe? hopefully)
Changed background color for Adelaide Crows

v2.1 
Removed W-D-L data during pre-game display for finals matches

v2.1a
Removed W-D-L data during pre-game display for finals matches, when "Live Games" and "Specific Team" is selected

v2.2
Updated for 2024 season

v2.3
Making the draw field dynamic in team records - it will only appear if the team has had a draw

v2.4
Reduced MATCH_CACHE from 24hrs to 6hrs as it wasn't refreshing the data quickly enough. Particularly when there is a quick turnaround between one round ending and another starting

v2.4.1
Bug fix - needed to convert draws to string value for team records

v2.5
Updated for 2025 season

v2.5.1
Handling for Western Bulldogs being referred to as original name of Footscray for their 100th anniversary
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Australia/Adelaide"
DEFAULT_TEAM = "10"  # Geelong #gocats

MATCHES_URL = "https://aflapi.afl.com.au/afl/v2/matches?competitionId=1&compSeasonId=73"
LADDER_URL = "https://aflapi.afl.com.au/afl/v2/compseasons/73/ladders"
ROUND_URL = "https://aflapi.afl.com.au/afl/v2/matches?competitionId=1&compSeasonId=73&roundNumber="
TEAM_SUFFIX = "&teamId="

SQUIGGLE_PREFIX = "https://api.squiggle.com.au/?q=games;round="
INCOMPLETE_SUFFIX = ";complete=!100"
COMPLETE_SUFFIX = ";complete=100"
YEAR_SUFFIX = ";year=2025"

MATCH_CACHE = 21600
LADDER_CACHE = 86400
ROUND_CACHE = 60
LIVE_CACHE = 30

def main(config):
    RotationSpeed = config.get("speed", "3")
    ViewSelection = config.get("View", "All")
    TeamListSelection = config.get("TeamList", DEFAULT_TEAM)

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    # Lets initialize!
    renderDisplay = []
    CURRENT_ROUND_URL = ""
    HomeWins = ""
    HomeDraws = ""
    HomeLosses = ""
    AwayWins = ""
    AwayDraws = ""
    AwayLosses = ""
    convertedTime = ""
    z = 0

    # cache specific all match data and ladder data for 24hrs
    # MatchesJSON is just to get the current round number
    # LadderJSON is just to get standings for teams yet to play
    MatchData = get_cachable_data(MATCHES_URL, MATCH_CACHE)
    MatchesJSON = json.decode(MatchData)
    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    # Get the Current Round, according to the API
    CurrentRound = str(MatchesJSON["matches"][0]["compSeason"]["currentRoundNumber"])

    if ViewSelection == "All" or ViewSelection == "Live":
        CURRENT_ROUND_URL = ROUND_URL + CurrentRound
    elif ViewSelection == "Team":
        CURRENT_ROUND_URL = ROUND_URL + CurrentRound + TEAM_SUFFIX + TeamListSelection

    # Cache match info for 1 min
    RoundData = get_cachable_data(CURRENT_ROUND_URL, ROUND_CACHE)
    CurrentRoundJSON = json.decode(RoundData)

    # Use the Squiggle API for live games, cache data for 30 secs
    SQUIGGLE_URL = SQUIGGLE_PREFIX + CurrentRound + INCOMPLETE_SUFFIX

    LiveData = get_cachable_data(SQUIGGLE_URL, LIVE_CACHE)
    LiveJSON = json.decode(LiveData)

    GamesThisRound = len(CurrentRoundJSON["matches"])
    IncompleteMatches = len(LiveJSON["games"])

    if ViewSelection == "All":
        for x in range(0, GamesThisRound, 1):
            status = CurrentRoundJSON["matches"][x]["status"]

            # if the game hasnt started yet, show the time of first bounce corrected for local time. API provides UTC time
            if status == "SCHEDULED" or status == "UNCONFIRMED_TEAMS" or status == "CONFIRMED_TEAMS":
                starttime = CurrentRoundJSON["matches"][x]["utcStartTime"]
                convertedTime = time.parse_time(starttime, format = "2006-01-02T15:04:00.000+0000").in_location(timezone)

                HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
                AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]

                home_team_abb = getTeamAbbFromID(HomeTeam)
                away_team_abb = getTeamAbbFromID(AwayTeam)

                home_team_font = getTeamFontColour(HomeTeam)
                home_team_bkg = getTeamBkgColour(HomeTeam)

                away_team_font = getTeamFontColour(AwayTeam)
                away_team_bkg = getTeamBkgColour(AwayTeam)

                if convertedTime.format("2/1") != now.format("2/1"):
                    starttime = convertedTime.format("2/1 3:04PM")
                else:
                    starttime = convertedTime.format("3:04 PM")

                HomeFound = 0
                AwayFound = 0

                # if not finals, show team records
                if MatchesJSON["matches"][0]["compSeason"]["currentRoundNumber"] < 25:
                    for y in range(0, 18, 1):
                        if HomeTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                            HomeWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                            HomeLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                            HomeDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                            HomeFound = 1
                        if AwayTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                            AwayWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                            AwayLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                            AwayDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                            AwayFound = 1

                        # both teams found, lets break out
                        if HomeFound + AwayFound == 2:
                            break

                    if HomeDraws == 0:
                        HomeRecord = HomeWins + "-" + HomeLosses
                    else:
                        HomeRecord = HomeWins + "-" + str(HomeDraws) + "-" + HomeLosses

                    if AwayDraws == 0:
                        AwayRecord = AwayWins + "-" + AwayLosses
                    else:
                        AwayRecord = AwayWins + "-" + str(AwayDraws) + "-" + AwayLosses

                else:
                    HomeRecord = ""
                    AwayRecord = ""

                # Render on the screen
                SchedOutput = showScheduledGame(HomeRecord, AwayRecord, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg, starttime)
                renderDisplay.extend(SchedOutput)

            # We have a live game!
            if status == "LIVE":
                LiveOutput = showLiveGame(CurrentRoundJSON, LiveJSON, IncompleteMatches, x)
                renderDisplay.extend(LiveOutput)

            # if the game is complete, show the status and get the scores
            if status == "CONCLUDED" or status == "POSTGAME":
                HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
                AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]

                home_team_abb = getTeamAbbFromID(HomeTeam)
                away_team_abb = getTeamAbbFromID(AwayTeam)

                home_team_font = getTeamFontColour(HomeTeam)
                home_team_bkg = getTeamBkgColour(HomeTeam)

                away_team_font = getTeamFontColour(AwayTeam)
                away_team_bkg = getTeamBkgColour(AwayTeam)

                # Render on the screen
                CompOutput = showCompletedGame(CurrentRoundJSON, x, False, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg)
                renderDisplay.extend(CompOutput)

    elif ViewSelection == "Live":
        LiveCount = 0

        for x in range(0, GamesThisRound, 1):
            status = CurrentRoundJSON["matches"][x]["status"]

            #print(status)
            if status == "LIVE":
                LiveOutput = showLiveGame(CurrentRoundJSON, LiveJSON, IncompleteMatches, x)
                renderDisplay.extend(LiveOutput)
                LiveCount = LiveCount + 1

            # keep the scores up until status is CONCLUDED
            if status == "POSTGAME":
                HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
                AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]

                home_team_abb = getTeamAbbFromID(HomeTeam)
                away_team_abb = getTeamAbbFromID(AwayTeam)

                home_team_font = getTeamFontColour(HomeTeam)
                home_team_bkg = getTeamBkgColour(HomeTeam)

                away_team_font = getTeamFontColour(AwayTeam)
                away_team_bkg = getTeamBkgColour(AwayTeam)

                CompOutput = showCompletedGame(CurrentRoundJSON, x, False, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg)
                renderDisplay.extend(CompOutput)
                LiveCount = LiveCount + 1

        # And if there are no live games or just completed games, just show the next scheduled
        if LiveCount == 0:
            NextSched = False

            for z in range(0, GamesThisRound, 1):
                status = CurrentRoundJSON["matches"][z]["status"]

                if status == "SCHEDULED" or status == "UNCONFIRMED_TEAMS" or status == "CONFIRMED_TEAMS":
                    HomeTeam = CurrentRoundJSON["matches"][z]["home"]["team"]["id"]
                    AwayTeam = CurrentRoundJSON["matches"][z]["away"]["team"]["id"]

                    home_team_abb = getTeamAbbFromID(HomeTeam)
                    away_team_abb = getTeamAbbFromID(AwayTeam)

                    home_team_font = getTeamFontColour(HomeTeam)
                    home_team_bkg = getTeamBkgColour(HomeTeam)

                    away_team_font = getTeamFontColour(AwayTeam)
                    away_team_bkg = getTeamBkgColour(AwayTeam)

                    starttime = CurrentRoundJSON["matches"][z]["utcStartTime"]
                    convertedTime = time.parse_time(starttime, format = "2006-01-02T15:04:00.000+0000").in_location(timezone)

                    if convertedTime.format("2/1") != now.format("2/1"):
                        starttime = convertedTime.format("2/1 3:04PM")
                    else:
                        starttime = convertedTime.format("3:04 PM")

                    HomeFound = 0
                    AwayFound = 0

                    # if not finals, show W-D-L
                    if MatchesJSON["matches"][0]["compSeason"]["currentRoundNumber"] < 25:
                        # show the win-draw-loss record for teams
                        for y in range(0, 18, 1):
                            if HomeTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                                HomeWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                                HomeLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                                HomeDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                                HomeFound = 1
                            if AwayTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                                AwayWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                                AwayLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                                AwayDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                                AwayFound = 1

                            # We found both teams, so break out
                            if HomeFound + AwayFound == 2:
                                break

                        if HomeDraws == 0:
                            HomeRecord = HomeWins + "-" + HomeLosses
                        else:
                            HomeRecord = HomeWins + "-" + str(HomeDraws) + "-" + HomeLosses

                        if AwayDraws == 0:
                            AwayRecord = AwayWins + "-" + AwayLosses
                        else:
                            AwayRecord = AwayWins + "-" + str(AwayDraws) + "-" + AwayLosses

                    else:
                        HomeRecord = ""
                        AwayRecord = ""

                    # Render on the screen
                    SchedOutput = showScheduledGame(HomeRecord, AwayRecord, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg, starttime)
                    renderDisplay.extend(SchedOutput)

                    # we found the next scheduled, so break out
                    NextSched = True
                    break

            # no more scheduled games this round, show the score from the final game
            if NextSched == False:
                HomeTeam = CurrentRoundJSON["matches"][z]["home"]["team"]["id"]
                AwayTeam = CurrentRoundJSON["matches"][z]["away"]["team"]["id"]

                home_team_abb = getTeamAbbFromID(HomeTeam)
                away_team_abb = getTeamAbbFromID(AwayTeam)

                home_team_font = getTeamFontColour(HomeTeam)
                home_team_bkg = getTeamBkgColour(HomeTeam)

                away_team_font = getTeamFontColour(AwayTeam)
                away_team_bkg = getTeamBkgColour(AwayTeam)

                x = GamesThisRound - 1
                CompOutput = showCompletedGame(CurrentRoundJSON, x, False, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg)
                renderDisplay.extend(CompOutput)

    elif ViewSelection == "Team":
        x = 0

        # if the selected team is having a bye week
        if len(CurrentRoundJSON["matches"]) == 0:
            home_team_abb = getTeamAbbFromID(int(TeamListSelection))
            home_team_font = getTeamFontColour(int(TeamListSelection))
            home_team_bkg = getTeamBkgColour(int(TeamListSelection))
            away_team_abb = "BYE"
            away_team_font = "#fff"
            away_team_bkg = "#000"

            for y in range(0, 18, 1):
                if int(TeamListSelection) == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                    HomeWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                    HomeLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                    HomeDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                    break

            if HomeDraws == 0:
                HomeRecord = HomeWins + "-" + HomeLosses
            else:
                HomeRecord = HomeWins + "-" + str(HomeDraws) + "-" + HomeLosses

            AwayRecord = ""
            starttime = ""

            SchedOutput = showScheduledGame(HomeRecord, AwayRecord, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg, starttime)
            renderDisplay.extend(SchedOutput)

        else:
            status = CurrentRoundJSON["matches"][x]["status"]

            HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
            AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]

            home_team_abb = getTeamAbbFromID(HomeTeam)
            away_team_abb = getTeamAbbFromID(AwayTeam)

            home_team_font = getTeamFontColour(HomeTeam)
            home_team_bkg = getTeamBkgColour(HomeTeam)

            away_team_font = getTeamFontColour(AwayTeam)
            away_team_bkg = getTeamBkgColour(AwayTeam)

            # if the game hasnt started yet, show the time of first bounce corrected for local time. API provides UTC time
            if status == "SCHEDULED" or status == "UNCONFIRMED_TEAMS" or status == "CONFIRMED_TEAMS":
                starttime = CurrentRoundJSON["matches"][x]["utcStartTime"]
                convertedTime = time.parse_time(starttime, format = "2006-01-02T15:04:00.000+0000").in_location(timezone)

                if convertedTime.format("2/1") != now.format("2/1"):
                    starttime = convertedTime.format("2/1 3:04PM")
                else:
                    starttime = convertedTime.format("3:04 PM")

                HomeFound = 0
                AwayFound = 0

                # if not finals, show W-D-L
                if MatchesJSON["matches"][0]["compSeason"]["currentRoundNumber"] < 25:
                    # show the win-draw-loss record for teams
                    for y in range(0, 18, 1):
                        if HomeTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                            HomeWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                            HomeLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                            HomeDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                            HomeFound = 1
                        if AwayTeam == LadderJSON["ladders"][0]["entries"][y]["team"]["id"]:
                            AwayWins = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["wins"])
                            AwayLosses = str(LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["losses"])
                            AwayDraws = LadderJSON["ladders"][0]["entries"][y]["thisSeasonRecord"]["winLossRecord"]["draws"]
                            AwayFound = 1

                        # We found both teams, so break out
                        if HomeFound + AwayFound == 2:
                            break

                    if HomeDraws == 0:
                        HomeRecord = HomeWins + "-" + HomeLosses
                    else:
                        HomeRecord = HomeWins + "-" + str(HomeDraws) + "-" + HomeLosses

                    if AwayDraws == 0:
                        AwayRecord = AwayWins + "-" + AwayLosses
                    else:
                        AwayRecord = AwayWins + "-" + str(AwayDraws) + "-" + AwayLosses

                else:
                    HomeRecord = ""
                    AwayRecord = ""

                # Render on the screen
                SchedOutput = showScheduledGame(HomeRecord, AwayRecord, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg, starttime)
                renderDisplay.extend(SchedOutput)

            # We have a live game!
            if status == "LIVE":
                #print("LIVE")
                LiveOutput = showLiveGame(CurrentRoundJSON, LiveJSON, IncompleteMatches, x)
                renderDisplay.extend(LiveOutput)

            # if the game is complete, show the status and get the scores
            if status == "CONCLUDED" or status == "POSTGAME":
                CompOutput = showCompletedGame(CurrentRoundJSON, x, False, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg)
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

def showLiveGame(CurrentRoundJSON, LiveJSON, IncompleteMatches, x):
    renderDisplay = []

    # get start time for the match in question
    starttime = CurrentRoundJSON["matches"][x]["utcStartTime"]
    convertedTime = time.parse_time(starttime, format = "2006-01-02T15:04:00.000+0000")

    # get details for each team in the match
    HomeTeam = CurrentRoundJSON["matches"][x]["home"]["team"]["id"]
    HomeTeamName = CurrentRoundJSON["matches"][x]["home"]["team"]["name"]
    AwayTeam = CurrentRoundJSON["matches"][x]["away"]["team"]["id"]
    AwayTeamName = CurrentRoundJSON["matches"][x]["away"]["team"]["name"]

    # get the abbreviated name, font and background colors for each team
    home_team_abb = getTeamAbbFromID(HomeTeam)
    away_team_abb = getTeamAbbFromID(AwayTeam)

    home_team_font = getTeamFontColour(HomeTeam)
    home_team_bkg = getTeamBkgColour(HomeTeam)

    away_team_font = getTeamFontColour(AwayTeam)
    away_team_bkg = getTeamBkgColour(AwayTeam)

    # variable initialised, this will be used to see if we found a live match or not
    LiveMatch = False

    # get home team name (first 5 chars) and go to Squiggle for incomplete games that round
    # loop through matches until we find a match
    for y in range(0, IncompleteMatches, 1):
        SquiggleHome = LiveJSON["games"][y]["hteam"]
        # print(SquiggleHome)
        # print(HomeTeamName)
        # print(AwayTeamName)

        # GWS needs some fixing to work for the next condition
        # Western Bulldogs being referred to as Footscray by AFL website for their 100th year anniversary
        # Added Indigenous names for teams
        if SquiggleHome == "Greater Western Sydney":
            SquiggleHome = "GWS Giants"
        if HomeTeamName == "Footscray":
            HomeTeamName = "Western Bulldogs"

        if HomeTeamName == "Waalitj Marawar":
            HomeTeamName = "West Coast"
        if HomeTeamName == "Euro-Yroke":
            HomeTeamName = "St Kilda"
        if HomeTeamName == "Kuwarna":
            HomeTeamName = "Adelaide"
        if HomeTeamName == "Yartapuulti":
            HomeTeamName = "Port Adelaide"
        if HomeTeamName == "Walyalup":
            HomeTeamName = "Fremantle"
        if HomeTeamName == "Narrm":
            HomeTeamName = "Melbourne"

        # if we find a match, get the score summary
        # and set LiveMatch to true, we found one!
        if HomeTeamName[:5] == SquiggleHome[:5] or AwayTeamName[:5] == SquiggleHome[:5]:
            LiveMatch = True
            HomeScore = str(LiveJSON["games"][y]["hscore"])
            HomeGoals = str(LiveJSON["games"][y]["hgoals"])
            HomeBehinds = str(LiveJSON["games"][y]["hbehinds"])

            AwayScore = str(LiveJSON["games"][y]["ascore"])
            AwayGoals = str(LiveJSON["games"][y]["agoals"])
            AwayBehinds = str(LiveJSON["games"][y]["abehinds"])

            gametime = str(LiveJSON["games"][y]["timestr"])
            #print(gametime)

            # if the Squiggle API isn't showing data yet, usually just before game start
            if HomeGoals == "None":
                HomeGoals = "0"
            if AwayGoals == "None":
                AwayGoals = "0"
            if AwayBehinds == "None":
                AwayBehinds = "0"
            if HomeBehinds == "None":
                HomeBehinds = "0"
            if gametime == "None":
                # if its 3 mins past starting time and we have no data then there's a problem
                # otherwise the game is just about to start
                timediff = time.now() - convertedTime
                if timediff.minutes > 3:
                    gametime = "NO DATA"
                else:
                    gametime = "GAME STARTING"

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
            break

    # if game is still classified as "LIVE" with AFL API but Squiggle API says its complete (LiveMatch is False). This situation can occur for a few mins post game
    # So lets look at completed games for the round in Squiggle, match the team we're looking at and pass info to the showCompletedGame function
    if LiveMatch == False:
        CurrentRound = str(CurrentRoundJSON["matches"][0]["compSeason"]["currentRoundNumber"])
        SQUIGGLE_URL = SQUIGGLE_PREFIX + CurrentRound + COMPLETE_SUFFIX + YEAR_SUFFIX
        CompletedData = get_cachable_data(SQUIGGLE_URL, LIVE_CACHE)
        CompletedJSON = json.decode(CompletedData)
        CompletedMatches = len(CompletedJSON["games"])

        # loop through the completed matches until we find our team
        for q in range(0, CompletedMatches, 1):
            SquiggleHome = CompletedJSON["games"][q]["hteam"]

            # GWS needs some fixing to work for the next condition
            if SquiggleHome == "Greater Western Sydney":
                SquiggleHome = "GWS Giants"
            if HomeTeamName == "Footscray":
                HomeTeamName = "Western Bulldogs"

            if HomeTeamName == "Waalitj Marawar":
                HomeTeamName = "West Coast"
            if HomeTeamName == "Euro-Yroke":
                HomeTeamName = "St Kilda"
            if HomeTeamName == "Kuwarna":
                HomeTeamName = "Adelaide"
            if HomeTeamName == "Yartapuulti":
                HomeTeamName = "Port Adelaide"
            if HomeTeamName == "Walyalup":
                HomeTeamName = "Fremantle"
            if HomeTeamName == "Narrm":
                HomeTeamName = "Melbourne"

            if HomeTeamName[:5] == SquiggleHome[:5] or AwayTeamName[:5] == SquiggleHome[:5]:
                CompOutput = showCompletedGame(CompletedJSON, q, True, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg)
                renderDisplay.extend(CompOutput)

                # once found, break out
                break

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

def showCompletedGame(MatchJSON, x, justComplete, home_team_abb, away_team_abb, home_team_font, away_team_font, home_team_bkg, away_team_bkg):
    renderDisplay = []
    gametime = "FULL TIME"

    # False for AFL API, True for Squiggle API
    if justComplete == False:
        HomeScore = str(MatchJSON["matches"][x]["home"]["score"]["totalScore"])
        HomeGoals = str(MatchJSON["matches"][x]["home"]["score"]["goals"])
        HomeBehinds = str(MatchJSON["matches"][x]["home"]["score"]["behinds"])

        AwayScore = str(MatchJSON["matches"][x]["away"]["score"]["totalScore"])
        AwayGoals = str(MatchJSON["matches"][x]["away"]["score"]["goals"])
        AwayBehinds = str(MatchJSON["matches"][x]["away"]["score"]["behinds"])

    else:
        HomeScore = str(MatchJSON["games"][x]["hscore"])
        HomeGoals = str(MatchJSON["games"][x]["hgoals"])
        HomeBehinds = str(MatchJSON["games"][x]["hbehinds"])

        AwayScore = str(MatchJSON["games"][x]["ascore"])
        AwayGoals = str(MatchJSON["games"][x]["agoals"])
        AwayBehinds = str(MatchJSON["games"][x]["abehinds"])

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
                                #Draw the box and row, then
                                render.Box(width = 64, height = 13, color = home_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                    render.Box(width = 20, height = 10, child = render.Text(content = home_team_abb, color = home_team_font, font = "Dina_r400-6")),
                                    render.Box(width = 12, height = 10, child = render.Text(content = HomeGoals, color = home_team_font)),
                                    render.Box(width = 12, height = 10, child = render.Text(content = HomeBehinds, color = home_team_font)),
                                    render.Box(width = 18, height = 10, child = render.Text(content = HomeScore, color = home_team_font)),
                                ])),
                                #Away Team
                                render.Box(width = 64, height = 13, color = away_team_bkg, child = render.Row(expanded = True, main_align = "start", cross_align = "right", children = [
                                    render.Box(width = 20, height = 10, child = render.Text(content = away_team_abb, color = away_team_font, font = "Dina_r400-6")),
                                    render.Box(width = 12, height = 10, child = render.Text(content = AwayGoals, color = away_team_font)),
                                    render.Box(width = 12, height = 10, child = render.Text(content = AwayBehinds, color = away_team_font)),
                                    render.Box(width = 18, height = 10, child = render.Text(content = AwayScore, color = away_team_font)),
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
        return ("#0a2240")
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
            schema.Dropdown(
                id = "View",
                name = "Matches to show",
                desc = "What to display",
                icon = "gear",
                default = ViewingOptions[0].value,
                options = ViewingOptions,
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
                default = TeamOptions[6].value,
                options = TeamOptions,
            ),
        ]
    else:
        return None

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

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

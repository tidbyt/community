"""
Applet: Test Cricket
Summary: Scoreboard for test match cricket
Description: This app takes the selected team and displays the current match situation - showing overall team score, batsmen scores, the day & session, remaining overs left in the day, the lead or deficit, partnership & current bowler's figures. If a match for the selected team has just completed, it will show the match result or if there is an upcoming match it will show the scheduled start time of the match, in the users timezone. If there is nothing coming up in the next day or so, it will no show that there are no matches scheduled.
Author: M0ntyP

v1.0 - Original app published

v1.1
Team score formatting when total is < 10 and < 100 so it lines up with batsmen scores properly
Using "mobile" names for batsmen & bowlers with names longer than 10 chars
Status message updates - removed last bowler bowling figures from the long breaks
Combined "scheduled" and "pre" match states 
Added Zimbabwe, Afghanistan and Ireland as teams you can select

v1.2
- Added Team Innings to scoreboard
- Show 'need' not 'trail' in the 4th innings
- Only use mobileName if it exists

Future ideas
- Remove "Rem Overs" if all out
- Update Description?
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LiveGames_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/matches/current?lang=en&latest=true"
DEFAULT_TIMEZONE = "Australia/Adelaide"
DEFAULT_TEAM = "2"  # Australia
MATCH_CACHE = 60
ALL_MATCH_CACHE = 2 * 3600  # 2 hours

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    # Cache the "current match" data for 2 hours
    AllMatchData = get_cachable_data(LiveGames_URL, ALL_MATCH_CACHE)
    LiveGames_JSON = json.decode(AllMatchData)

    Matches = LiveGames_JSON["matches"]

    SelectedTeam = config.get("TeamList", DEFAULT_TEAM)
    SelectedTeam = int(SelectedTeam)

    # Initialising variables to satisfy lint
    Playing = False
    MatchID = 0
    LastOut_Name = ""
    LastOut_Runs = 0
    Status2 = ""
    Status2Color = ""
    Status5 = ""
    Status5Color = ""
    Team1_2_Wkts = 0
    Team1_2_Runs = 0
    Team2_2_Wkts = 0
    Team2_2_Runs = 0

    # scroll through the live & recent games to find if your team is currently playing and its a "test" match
    # Note that "test" can also include tour matches
    for x in range(0, len(Matches), 1):
        if Matches[x]["teams"][0]["team"]["id"] == SelectedTeam:
            if Matches[x]["format"] == "TEST":
                MatchID = Matches[x]["objectId"]
                Playing = True
                break
        elif Matches[x]["teams"][1]["team"]["id"] == SelectedTeam:
            if Matches[x]["format"] == "TEST":
                MatchID = Matches[x]["objectId"]
                Playing = True
                break
        else:
            Playing = False

    if Playing == True:
        MatchID = str(MatchID)
        Match_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/match/details?lang=en&seriesId=" + MatchID + "&matchId=" + MatchID + "&latest=true"
        #print(Match_URL)

        # cache specific match data for 1 minute
        MatchData = get_cachable_data(Match_URL, MATCH_CACHE)
        Match_JSON = json.decode(MatchData)

        # If there is a live game
        if Match_JSON["match"]["state"] == "LIVE":
            # What innings of the match is it ?
            Innings = int(Match_JSON["match"]["liveInning"]) - 1

            # What's the score
            Wickets = Match_JSON["scorecard"]["innings"][Innings]["wickets"]
            Runs = Match_JSON["scorecard"]["innings"][Innings]["runs"]

            # What inning for the batting side
            if Innings == 0 or Innings == 1:
                TeamInn = "1st"
            else:
                TeamInn = "2nd"

            # In front or behind? And how much?
            Lead_or_Trail = Match_JSON["scorecard"]["innings"][Innings]["lead"]

            if Lead_or_Trail < 0:
                trail = True
            else:
                trail = False

            # if 4th innings of the match, show what they need to win
            if Innings == 3:
                Lead_or_Trail = Lead_or_Trail + 1

            Lead_or_Trail = math.fabs(Lead_or_Trail)
            Lead_or_Trail = humanize.ftoa(Lead_or_Trail)

            if trail == False:
                Lead = " lead " + Lead_or_Trail
            else:
                Lead = " trail " + Lead_or_Trail

            # if 4th innings of the match, show what they need to win
            if Innings == 3:
                Lead = " need " + Lead_or_Trail

            # How many overs bowled in this innings
            #Overs = Match_JSON["scorecard"]["innings"][Innings]["overs"]
            #Overs = str(Overs)

            # How many overs left in the day
            RemOvers = Match_JSON["match"]["liveOversPending"]
            RemOvers = str(RemOvers)

            # Get match status - are we playing (live), drinks, lunch, tea or stumps
            Status = Match_JSON["match"]["status"]
            StatusColor = "#fff"

            ### Batting ###
            BattingTeam = Match_JSON["scorecard"]["innings"][Innings]["team"]["abbreviation"]

            # Get the font color for the batting side
            BattingTeamID = Match_JSON["scorecard"]["innings"][Innings]["team"]["id"]
            BattingTeamID = int(BattingTeamID)
            BattingTeamColor = getTeamFontColor(BattingTeamID)

            # On strike batsman details
            Batsman1 = Match_JSON["livePerformance"]["batsmen"][0]["player"]["fieldingName"]
            if len(Batsman1) > 11:
                if len(Match_JSON["livePerformance"]["batsmen"][0]["player"]["mobileName"]) > 1:
                    Batsman1 = Match_JSON["livePerformance"]["batsmen"][0]["player"]["mobileName"]
            Batsman1_Runs = Match_JSON["livePerformance"]["batsmen"][0]["runs"]

            # Partnership details
            PartnershipNum = len(Match_JSON["scorecard"]["innings"][Innings]["inningPartnerships"]) - 1
            if PartnershipNum > -1:
                CurrentPartnership = Match_JSON["scorecard"]["innings"][Innings]["inningPartnerships"][PartnershipNum]["runs"]
                CurrentPartnership = str(CurrentPartnership)
            else:
                CurrentPartnership = "N/A"

            # Last out
            WicketsInt = int(Wickets)
            if WicketsInt > 0:
                LastOut_Name = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["player"]["fieldingName"]
                if len(LastOut_Name) > 11:
                    if len(Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["player"]["mobileName"]) > 1:
                        LastOut_Name = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["player"]["mobileName"]

                LastOut_Runs = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["runs"]

            # check if there is a second batsmen out there, this applies at fall of wicket & end of innings
            Batsmen = len(Match_JSON["livePerformance"]["batsmen"])

            if Batsmen == 2:
                Batsman2 = Match_JSON["livePerformance"]["batsmen"][1]["player"]["fieldingName"]
                if len(Batsman2) > 11:
                    if len(Match_JSON["livePerformance"]["batsmen"][1]["player"]["mobileName"]) > 1:
                        Batsman2 = Match_JSON["livePerformance"]["batsmen"][1]["player"]["mobileName"]
                Batsman2_Runs = Match_JSON["livePerformance"]["batsmen"][1]["runs"]
                Batsman2_Runs_Str = str(Batsman2_Runs)

                # little bit of formatting/spacing
                if Batsman2_Runs < 100:
                    if Batsman2_Runs > 9:
                        Batsman2_Runs_Str = " " + Batsman2_Runs_Str

                if Batsman2_Runs < 10:
                    Batsman2_Runs_Str = "  " + Batsman2_Runs_Str

                BatsmanColor = "#fff"
                Batsman2Color = "#fff"

                IsOut = False

                # else show who was out, in red
            else:
                IsOut = True

                Batsman2 = LastOut_Name
                Batsman2_Runs_Str = str(LastOut_Runs)

                # little bit of formatting/spacing
                if LastOut_Runs < 100:
                    if LastOut_Runs > 9:
                        Batsman2_Runs_Str = " " + Batsman2_Runs_Str
                if LastOut_Runs < 10:
                    Batsman2_Runs_Str = "  " + Batsman2_Runs_Str

                BatsmanColor = "#fff"
                Batsman2Color = "#f00"

            # Bowler details
            CurrentBowler = Match_JSON["livePerformance"]["bowlers"][0]["player"]["fieldingName"]
            if len(CurrentBowler) > 10:
                CurrentBowler = Match_JSON["livePerformance"]["bowlers"][0]["player"]["mobileName"]
            CurrentBowler_Wkts = Match_JSON["livePerformance"]["bowlers"][0]["wickets"]
            CurrentBowler_Runs = Match_JSON["livePerformance"]["bowlers"][0]["conceded"]

            BowlingTeamID = Match_JSON["livePerformance"]["bowlers"][0]["player"]["countryTeamId"]
            BowlingTeamColor = getTeamFontColor(BowlingTeamID)

            CurrentBowler_Wkts = str(CurrentBowler_Wkts)
            CurrentBowler_Runs = str(CurrentBowler_Runs)
            Wickets = str(Wickets)
            Runs = str(Runs)

            if WicketsInt > 0:
                LastOut_Runs = str(LastOut_Runs)

            Batsman1_Runs_Str = str(Batsman1_Runs)

            # little bit of formatting/spacing
            if Batsman1_Runs < 100:
                if Batsman1_Runs > 9:
                    Batsman1_Runs_Str = " " + Batsman1_Runs_Str
            if Batsman1_Runs < 10:
                Batsman1_Runs_Str = "  " + Batsman1_Runs_Str

            ## Status row ##
            TheDay = Match_JSON["match"]["liveDay"]
            TheDay = str(TheDay)
            TheSess = Match_JSON["match"]["liveSession"]
            TheSess = str(TheSess)

            # display the day number, or if a wicket has fallen, show that instead as the "status"
            if Batsmen == 2:
                Status2 = "Rem Overs: " + RemOvers
                Status2Color = "#fff"
                Status5 = CurrentBowler + " " + CurrentBowler_Wkts + "/" + CurrentBowler_Runs
                Status5Color = BowlingTeamColor

                # if there is play, show the session and day, otherwise show the break - eg lunch, tea, stumps or drinks
                # added other options her as well
                # Stumps, Lunch & tea - should be Stumps, Stumps, Trail, Partnership, Stumps
                if Status == "Live":
                    TheSess = "Sess " + TheSess
                    TheDay = "Day " + TheDay
                    Status = TheSess + " - " + TheDay
                    Status5 = CurrentBowler + " " + CurrentBowler_Wkts + "/" + CurrentBowler_Runs
                elif Status == "Stumps" or Status == "Lunch" or Status == "Tea" or Status == "Drinks":
                    Status = Status + " - Day " + TheDay
                    Status2 = Status
                    Status5 = Status
                    Status5Color = "#fff"
                elif Status == "Innings break":
                    Status = Status
                elif Status == "Match delayed by rain":
                    Status = "Rain Delay"
                elif Status == "Match delayed by bad light":
                    Status = "Bad Light delay"
                elif Status == "Match delayed - wet outfield":
                    Status = "Wet outfield"

            elif Batsmen == 1:
                # if someone is just out, show a wicket has fallen
                # could also be a break, eg lunch taken early & if so show that
                if Status == "Live":
                    Status = "WICKET!"
                    StatusColor = "#f00"
                    Status2 = "Rem Overs: " + RemOvers
                    Status5 = CurrentBowler + " " + CurrentBowler_Wkts + "/" + CurrentBowler_Runs
                    Status5Color = "#f00"
                elif Status == "Stumps" or Status == "Lunch" or Status == "Tea" or Status == "Drinks":
                    Status = Status + " - Day " + TheDay
                    Status2 = Status
                    Status5 = Status
                    StatusColor = "#fff"
                    Status2Color = "#fff"
                    Status5Color = "#fff"
                elif Status == "Match delayed by rain":
                    Status = "Rain Delay"
                    Status2 = "Rem Overs: " + RemOvers
                    Status5 = Status
                    Status5Color = "#fff"
                elif Status == "Innings break":
                    Status = Status
                    Status2 = Status
                    Status5 = Status
                    Status5Color = "#fff"
                elif Status == "Match delayed by bad light":
                    Status = "Bad Light delay"
                    Status2 = "Rem Overs: " + RemOvers
                    Status5 = Status
                    Status5Color = "#fff"
                elif Status == "Match delayed - wet outfield":
                    Status = "Wet outfield"
                    Status2 = "Rem Overs: " + RemOvers
                    Status5 = Status
                    Status5Color = "#fff"

            Status3 = BattingTeam + Lead
            Status3Color = "#fff"
            Status4 = "Part'ship: " + CurrentPartnership
            Status4Color = BattingTeamColor
            #Status5 = CurrentBowler + " " + CurrentBowler_Wkts + "/" + CurrentBowler_Runs

            if IsOut == True and Wickets != "10":
                StatusColor = "#f00"
                Status2Color = "#f00"
                Status3Color = "#f00"
                Status4Color = "#f00"
                Status5Color = "#f00"
            if Wickets == "10":
                StatusColor = "#fff"
                Status2Color = "#fff"
                Status3Color = "#fff"

            return render.Root(
                delay = int(3000),
                child = render.Animation(
                    children = [
                        render.Column(
                            children = [
                                TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs),
                                BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                                BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                                StatusRow(Status, StatusColor),
                            ],
                        ),
                        render.Column(
                            children = [
                                TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs),
                                BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                                BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                                StatusRow(Status2, Status2Color),
                            ],
                        ),
                        render.Column(
                            children = [
                                TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs),
                                BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                                BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                                StatusRow(Status3, Status3Color),
                            ],
                        ),
                        render.Column(
                            children = [
                                TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs),
                                BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                                BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                                StatusRow(Status4, Status4Color),
                            ],
                        ),
                        render.Column(
                            children = [
                                TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs),
                                BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                                BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                                StatusRow(Status5, Status5Color),
                            ],
                        ),
                    ],
                ),
            )

        elif Match_JSON["match"]["state"] == "POST" or Match_JSON["match"]["state"] == "FINISHED":
            # Match completed
            Title = Match_JSON["match"]["title"]
            Result = Match_JSON["match"]["statusText"]
            winnerTeamId = Match_JSON["match"]["winnerTeamId"]

            TotalMatchInngs = len(Match_JSON["scorecard"]["innings"])

            Inns1_Runs = Match_JSON["scorecard"]["innings"][0]["runs"]
            Inns1_Wkts = Match_JSON["scorecard"]["innings"][0]["wickets"]
            Inns1_TeamID = Match_JSON["scorecard"]["innings"][0]["team"]["id"]
            Inns1_Abbr = Match_JSON["scorecard"]["innings"][0]["team"]["abbreviation"]

            Inns2_Runs = Match_JSON["scorecard"]["innings"][1]["runs"]
            Inns2_Wkts = Match_JSON["scorecard"]["innings"][1]["wickets"]
            Inns2_TeamID = Match_JSON["scorecard"]["innings"][1]["team"]["id"]
            Inns2_Abbr = Match_JSON["scorecard"]["innings"][1]["team"]["abbreviation"]

            if TotalMatchInngs == 3:
                Inns3_Runs = Match_JSON["scorecard"]["innings"][2]["runs"]
                Inns3_Wkts = Match_JSON["scorecard"]["innings"][2]["wickets"]
                Inns3_TeamID = Match_JSON["scorecard"]["innings"][2]["team"]["id"]

                # Team batting third is the same as first inns team
                if Inns3_TeamID == Inns1_TeamID:
                    Team1_2_Wkts = Inns3_Wkts
                    Team1_2_Runs = Inns3_Runs
                    Team2_2_Wkts = None
                    Team2_2_Runs = None

                # Team batting third is the same as second inns team, eg follow-on
                if Inns3_TeamID == Inns2_TeamID:
                    Team2_2_Wkts = Inns3_Wkts
                    Team2_2_Runs = Inns3_Runs
                    Team1_2_Wkts = None
                    Team1_2_Runs = None

            elif TotalMatchInngs == 4:
                Inns3_Runs = Match_JSON["scorecard"]["innings"][2]["runs"]
                Inns3_Wkts = Match_JSON["scorecard"]["innings"][2]["wickets"]
                Inns3_TeamID = Match_JSON["scorecard"]["innings"][2]["team"]["id"]

                Inns4_Runs = Match_JSON["scorecard"]["innings"][3]["runs"]
                Inns4_Wkts = Match_JSON["scorecard"]["innings"][3]["wickets"]
                Inns4_TeamID = Match_JSON["scorecard"]["innings"][3]["team"]["id"]

                # Team batting third is the same as first inns team
                if Inns3_TeamID == Inns1_TeamID:
                    Team1_2_Wkts = Inns3_Wkts
                    Team1_2_Runs = Inns3_Runs

                # Team batting third is the same as second inns team, eg follow-on
                if Inns3_TeamID == Inns2_TeamID:
                    Team2_2_Wkts = Inns3_Wkts
                    Team2_2_Runs = Inns3_Runs

                # Team batting fourth is the same as second inns team
                if Inns4_TeamID == Inns2_TeamID:
                    Team2_2_Wkts = Inns4_Wkts
                    Team2_2_Runs = Inns4_Runs

                # Team batting fourth is the same as first inns team
                if Inns4_TeamID == Inns1_TeamID:
                    Team1_2_Wkts = Inns4_Wkts
                    Team1_2_Runs = Inns4_Runs

            Inns1Color = getTeamFontColor(Inns1_TeamID)
            Inns2Color = getTeamFontColor(Inns2_TeamID)
            WinnerColor = getTeamFontColor(winnerTeamId)

            # if match is a draw
            if WinnerColor == None:
                WinnerColor = "#fff"

            return render.Root(
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 64, height = 6, child = render.Text(content = Title, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        FinalTeamScore(Inns1_Abbr, Inns1Color, Inns1_Wkts, Inns1_Runs, Team1_2_Wkts, Team1_2_Runs),
                        FinalTeamScore(Inns2_Abbr, Inns2Color, Inns2_Wkts, Inns2_Runs, Team2_2_Wkts, Team2_2_Runs),
                        render.Row(
                            children = [
                                render.Box(width = 64, height = 10, child = render.Marquee(width = 64, height = 10, child = render.Text(content = Result, color = WinnerColor, font = "CG-pixel-3x5-mono"))),
                            ],
                        ),
                    ],
                ),
            )

        elif Match_JSON["match"]["state"] == "SCHEDULED" or Match_JSON["match"]["state"] == "PRE":
            # Else game is coming up
            Team1_Name = Match_JSON["match"]["teams"][0]["team"]["name"]
            Team2_Name = Match_JSON["match"]["teams"][1]["team"]["name"]

            Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
            Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]
            Team1_Color = getTeamFontColor(Team1_ID)
            Team2_Color = getTeamFontColor(Team2_ID)

            # Get the time of the game in the user's timezone
            StartTime = Match_JSON["match"]["startTime"]

            MyTime = time.parse_time(StartTime, format = "2006-01-02T15:04:00.000Z").in_location(timezone)
            Time = MyTime.format("15:04")
            Date = MyTime.format("Jan 2")

            return render.Root(
                child = render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 8, child = render.Text(content = Team1_Name, color = Team1_Color, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 8, child = render.Text(content = "v", color = "#FFF", font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 8, child = render.Text(content = Team2_Name, color = Team2_Color, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Box(width = 64, height = 8, child = render.Text(content = Date + " - " + Time, color = "#FFF", font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                    ],
                ),
            )

        # No live games or recent games
    elif Playing == False:
        Name = getTeamDisplayName(SelectedTeam)
        Color = getTeamFontColor(SelectedTeam)

        return render.Root(
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 12, child = render.Text(content = Name, color = Color, font = "CG-pixel-3x5-mono")),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 8, child = render.Text(content = "No games", color = "#FFF", font = "CG-pixel-3x5-mono")),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 6, child = render.Text(content = "scheduled", color = "#FFF", font = "CG-pixel-3x5-mono")),
                        ],
                    ),
                ],
            ),
        )

    # should never get here but lint wanted it
    return None

def TeamScore(BattingTeam, BattingTeamColor, TeamInn, Wickets, Runs):
    # if all out
    if Wickets != "10":
        Wickets = Wickets + "/"
    else:
        Wickets = "  "

    # formatting for Runs
    if len(Runs) == 1:
        Wickets = "  " + Wickets
    if len(Runs) == 2:
        Wickets = " " + Wickets

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 40, height = 8, child = render.Padding(
                        pad = (2, 1, 0, 0),
                        child = render.Marquee(
                            width = 40,
                            child = render.Text(content = BattingTeam + " " + TeamInn, color = BattingTeamColor, font = "CG-pixel-4x5-mono", offset = 0),
                        ),
                    )),
                    render.Box(width = 24, height = 8, child = render.Text(content = Wickets + Runs, color = BattingTeamColor, font = "CG-pixel-3x5-mono")),
                ],
            ),
        ],
    )

def FinalTeamScore(BattingTeam, BattingTeamColor, Wickets1, Runs1, Wickets2, Runs2):
    CommaOn = True

    if Wickets1 == 10:
        Output = str(Runs1)
    else:
        Output = str(Wickets1) + "/" + str(Runs1)

    if Wickets2 == 10:
        Output2 = str(Runs2)
    elif Wickets2 == None:
        Output2 = ""
        CommaOn = False
    else:
        Output2 = str(Wickets2) + "/" + str(Runs2)

    if CommaOn == True:
        Comma = ","
    else:
        Comma = ""

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 16, height = 8, child = render.Padding(
                        pad = (5, 0, 0, 0),
                        child = render.Marquee(
                            width = 20,
                            child = render.Text(content = BattingTeam, color = BattingTeamColor, font = "CG-pixel-3x5-mono", offset = 0),
                        ),
                    )),
                    render.Box(width = 48, height = 8, child = render.Padding(
                        pad = (0, 0, 0, 0),
                        child = render.Text(content = Output + Comma + Output2, color = BattingTeamColor, font = "CG-pixel-3x5-mono"),
                    )),
                ],
            ),
        ],
    )

def BatsmanScore(Batsman, Runs, BatsmanColor):
    return render.Row(
        children = [
            render.Box(width = 50, height = 8, child = render.Padding(
                pad = (2, 1, 0, 0),
                child = render.Marquee(
                    width = 50,
                    child = render.Text(content = Batsman, color = BatsmanColor, font = "CG-pixel-3x5-mono", offset = 0),
                ),
            )),
            render.Box(width = 14, height = 8, child = render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Marquee(
                    width = 14,
                    child = render.Text(content = Runs, color = BatsmanColor, font = "CG-pixel-3x5-mono", offset = 0),
                ),
            )),
        ],
    )

def StatusRow(StatusMsg, StatusColor):
    #print(StatusMsg)
    return render.Row(
        children = [
            render.Box(width = 64, height = 8, child = render.Text(content = StatusMsg, color = StatusColor, font = "CG-pixel-3x5-mono")),
        ],
    )

TeamOptions = [
    schema.Option(
        display = "England",
        value = "1",
    ),
    schema.Option(
        display = "Australia",
        value = "2",
    ),
    schema.Option(
        display = "South Africa",
        value = "3",
    ),
    schema.Option(
        display = "West Indies",
        value = "4",
    ),
    schema.Option(
        display = "New Zealand",
        value = "5",
    ),
    schema.Option(
        display = "India",
        value = "6",
    ),
    schema.Option(
        display = "Pakistan",
        value = "7",
    ),
    schema.Option(
        display = "Sri Lanka",
        value = "8",
    ),
    schema.Option(
        display = "Zimbabwe",
        value = "9",
    ),
    schema.Option(
        display = "Ireland",
        value = "29",
    ),
    schema.Option(
        display = "Afghanistan",
        value = "40",
    ),
]

def getTeamFontColor(teamID):
    if teamID == 2:  # Australia
        return ("#ffdd00")
    elif teamID == 3:  # South Africa
        return ("#04822B")
    elif teamID == 7:  # Pakistan
        return ("#04822B")
    elif teamID == 5:  # New Zealand
        return ("#fff")
    elif teamID == 1:  # England
        return ("#fff")
    elif teamID == 6:  # India
        return ("#137dd2")
    elif teamID == 8:  # Sri Lanka
        return ("#203d89")
    elif teamID == 4:  # West Indies
        return ("#790d1a")
    elif teamID == 9:  # Zimbabwe
        return ("#40575a")
    elif teamID == 29:  # Ireland
        return ("#59d657")
    elif teamID == 40:  # Afghanistan
        return ("#fff")
    else:  # For any other team
        return ("#fff")

def getTeamDisplayName(teamID):
    if teamID == 2:  # Australia
        return ("Australia")
    elif teamID == 3:  # South Africa
        return ("South Africa")
    elif teamID == 7:  # Pakistan
        return ("Pakistan")
    elif teamID == 5:  # New Zealand
        return ("New Zealand")
    elif teamID == 1:  # England
        return ("England")
    elif teamID == 6:  # India
        return ("India")
    elif teamID == 8:  # Sri Lanka
        return ("Sri Lanka")
    elif teamID == 4:  # West Indies
        return ("West Indies")
    elif teamID == 9:  # Zimbabwe
        return ("Zimbabwe")
    elif teamID == 29:  # Ireland
        return ("Ireland")
    elif teamID == 40:  # Afghanistan
        return ("Afghanistan")
    else:
        return ("")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "TeamList",
                name = "Team",
                desc = "Choose your team",
                icon = "gear",
                default = TeamOptions[1].value,
                options = TeamOptions,
            ),
        ],
    )

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

load("render.star", "render")
load("http.star", "http")
load("humanize.star", "humanize")
load("time.star", "time")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("math.star", "math")

"""
Applet: BBL Cricket
Summary: Displays scores for the selected BBL team
Description: This app takes the selected team and displays the current match situation - showing overall team score, batsmen scores, lead/deficit, overs bowled, run rate and required run rate for the team batting second. If a match for the selected team has just completed, it will show the match result or if there is an upcoming match it will show the teams win-loss record and the scheduled start time of the match, in the users timezone. If there is nothing coming up in the next day or so (as determined by the Cricinfo API), it will no show that there are no matches scheduled.
Author: M0ntyP 
"""

LiveGames_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/matches/current?lang=en&latest=true"
Standings_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/series/standings?lang=en&seriesId=1324623"
DEFAULT_TEAM = "4848"

DEFAULT_LOCATION = """ 
{
    "description": "Adelaide, SA, Australia",
    "locality": "Adelaide",
    "timezone": "Australia/Adelaide"
}
"""

def main(config):
    SelectedTeam = config.get("TeamList", DEFAULT_TEAM)
    SelectedTeam = int(SelectedTeam)

    Standings_JSON = http.get(Standings_URL).json()
    LiveGames_JSON = http.get(LiveGames_URL).json()
    Matches = LiveGames_JSON["matches"]

    # scroll through the live & recent games to find if your team is listed
    for x in range(0, len(Matches), 1):
        if Matches[x]["teams"][0]["team"]["id"] == SelectedTeam:
            MatchID = Matches[x]["objectId"]
            Playing = True
            break
        elif Matches[x]["teams"][1]["team"]["id"] == SelectedTeam:
            MatchID = Matches[x]["objectId"]
            Playing = True
            break
        else:
            Playing = False

    if Playing == True:
        MatchID = humanize.ftoa(MatchID)
        Match_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/match/details?lang=en&seriesId=" + MatchID + "&matchId=" + MatchID + "&latest=true"

        Match_JSON = http.get(Match_URL).json()

        # If there is a live game on
        if Match_JSON["match"]["state"] == "LIVE":
            # What innings is it ?
            Innings = len(Match_JSON["scorecard"]["innings"]) - 1

            # What's the score
            Wickets = Match_JSON["scorecard"]["innings"][Innings]["wickets"]
            Runs = Match_JSON["scorecard"]["innings"][Innings]["runs"]

            # In front or behind? And how much?
            Trail = Match_JSON["scorecard"]["innings"][Innings]["lead"]

            if Trail < 0:
                trail_bool = True
            else:
                trail_bool = False

            Trail = math.fabs(Trail) + 1
            Trail = humanize.ftoa(Trail)

            TrailBy = " need " + Trail

            # How many overs bowled
            Overs = Match_JSON["scorecard"]["innings"][Innings]["overs"]
            Overs = str(Overs)

            # How many overs left
            RemOvers = Match_JSON["match"]["liveOversPending"]
            RemOvers = str(RemOvers)

            # Batting details
            BattingTeamID = Match_JSON["supportInfo"]["inning"]["team"]["id"]
            BattingTeamID = int(BattingTeamID)
            BattingTeamColor = getTeamFontColor(BattingTeamID)

            # On strike batsman
            Batsman1 = Match_JSON["livePerformance"]["batsmen"][0]["player"]["fieldingName"]
            Batsman1_Runs = Match_JSON["livePerformance"]["batsmen"][0]["runs"]
            Batsman1_Runs_Str = humanize.ftoa(Batsman1_Runs)

            # Last out
            WicketsInt = int(Wickets)
            if WicketsInt > 0:
                LastOut_Name = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["player"]["fieldingName"]
                LastOut_Runs = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["runs"]

            # check if there is a second batsmen out there, this applies at fall of wicket & end of innings
            Batsmen = len(Match_JSON["livePerformance"]["batsmen"])

            if Batsmen == 2:
                Batsman2 = Match_JSON["livePerformance"]["batsmen"][1]["player"]["fieldingName"]
                Batsman2_Runs = Match_JSON["livePerformance"]["batsmen"][1]["runs"]
                Batsman2_Runs_Str = humanize.ftoa(Batsman2_Runs)

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
                Batsman2_Runs_Str = humanize.ftoa(LastOut_Runs)

                # little bit of formatting/spacing
                if LastOut_Runs < 100:
                    if LastOut_Runs > 9:
                        Batsman2_Runs_Str = " " + Batsman2_Runs_Str
                if LastOut_Runs < 10:
                    Batsman2_Runs_Str = "  " + Batsman2_Runs_Str

                BatsmanColor = "#fff"
                Batsman2Color = "#f00"

            Wickets = humanize.ftoa(Wickets)
            Runs = humanize.ftoa(Runs)

            if WicketsInt > 0:
                LastOut_Runs = humanize.ftoa(LastOut_Runs)

            # little bit of formatting/spacing
            if Batsman1_Runs < 100:
                if Batsman1_Runs > 9:
                    Batsman1_Runs_Str = " " + Batsman1_Runs_Str
            if Batsman1_Runs < 10:
                Batsman1_Runs_Str = "  " + Batsman1_Runs_Str

            BattingTeam = Match_JSON["scorecard"]["innings"][Innings]["team"]["name"]
            BattingTeamAbbr = Match_JSON["scorecard"]["innings"][Innings]["team"]["abbreviation"]
            CRR = str(Match_JSON["supportInfo"]["liveInfo"]["currentRunRate"])
            RRR = str(Match_JSON["supportInfo"]["liveInfo"]["requiredRunrate"])
            ProjScore = humanize.ftoa(Match_JSON["match"]["liveInningPredictions"]["score"])

            # ProjScore can be null at the very start of the match
            if ProjScore == None:
                ProjScore = 0

            T20_Innings = Match_JSON["match"]["liveInning"]

            MatchStatus = str(Match_JSON["match"]["status"])

            T20_StatusColor = "#fff"

            # what to show on the status bar, depending on state of game, team batting first or second & fall of wicket
            if T20_Innings == 1:
                if MatchStatus == "Live":
                    T20_Status1 = "1st Inns - " + MatchStatus
                    T20_Status4 = "Proj Score: " + ProjScore
                elif MatchStatus == "Innings break":
                    T20_Status1 = MatchStatus
                    T20_Status4 = MatchStatus
                elif MatchStatus == "Match delayed by rain":
                    MatchStatus = "Rain Delay"
                    T20_Status1 = MatchStatus
                else:
                    T20_Status1 = MatchStatus
                T20_Status2 = "Overs: " + Overs
                T20_Status3 = "Run Rate: " + CRR
                # 2nd Innings underway

            else:
                T20_Status1 = BattingTeamAbbr + TrailBy
                T20_Status2 = "Overs: " + Overs
                T20_Status3 = "Run Rate: " + CRR
                T20_Status4 = "Req Rate: " + RRR

            # Wicket has fallen
            if IsOut == True:
                # Team batting first
                if T20_Innings == 1:
                    T20_Status1 = "WICKET!"
                    T20_Status2 = "WICKET!"
                    T20_Status3 = "Overs: " + Overs
                    T20_Status4 = "Proj Score: " + ProjScore
                    # Team batting second, still want to show how far behind and req RR

                else:
                    T20_Status1 = "WICKET!"
                    T20_Status2 = BattingTeamAbbr + TrailBy
                    T20_Status3 = "Overs: " + Overs
                    T20_Status4 = "Req Rate: " + RRR
                T20_StatusColor = "#f00"

            renderScreens = [
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status1, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status2, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status3, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status4, T20_StatusColor),
                    ],
                ),
            ]

            return render.Root(
                delay = int(4000),
                child = render.Animation(children = renderScreens),
            )

            # Game has completed
        elif Match_JSON["match"]["stage"] == "FINISHED":
            # check if 2 innings were started
            if len(Match_JSON["scorecardSummary"]["innings"]) == 2:
                Team1_Abbr = Match_JSON["scorecardSummary"]["innings"][0]["team"]["name"]
                Team2_Abbr = Match_JSON["scorecardSummary"]["innings"][1]["team"]["name"]
                Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
                Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]

                Team1_Wkts = Match_JSON["scorecardSummary"]["innings"][0]["wickets"]
                Team1_Runs = Match_JSON["scorecardSummary"]["innings"][0]["runs"]

                Team2_Wkts = Match_JSON["scorecardSummary"]["innings"][1]["wickets"]
                Team2_Runs = Match_JSON["scorecardSummary"]["innings"][1]["runs"]

                Team1_Wkts_Str = humanize.ftoa(Team1_Wkts)
                Team1_Runs_Str = humanize.ftoa(Team1_Runs)
                Team2_Wkts_Str = humanize.ftoa(Team2_Wkts)
                Team2_Runs_Str = humanize.ftoa(Team2_Runs)

                if Team1_Wkts != 10:
                    Score1 = Team1_Wkts_Str + "/" + Team1_Runs_Str
                else:
                    Score1 = Team1_Runs_Str

                if Team2_Wkts != 10:
                    Score2 = Team2_Wkts_Str + "/" + Team2_Runs_Str
                else:
                    Score2 = Team2_Runs_Str

                Team1_Color = getTeamFontColor(Team1_ID)
                Team2_Color = getTeamFontColor(Team2_ID)

                WinnerID = Match_JSON["match"]["winnerTeamId"]

                if WinnerID == Team1_ID:
                    WinnerColor = Team1_Color
                else:
                    WinnerColor = Team2_Color

                Result = Match_JSON["match"]["statusText"]

                # only 1 innings got started, eg washout
            else:
                Team1_Abbr = Match_JSON["scorecardSummary"]["innings"][0]["team"]["name"]
                Team2_Abbr = Match_JSON["match"]["teams"][1]["team"]["name"]
                Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
                Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]

                Team1_Wkts = Match_JSON["scorecardSummary"]["innings"][0]["wickets"]
                Team1_Runs = Match_JSON["scorecardSummary"]["innings"][0]["runs"]

                Score2 = ""

                Team1_Wkts_Str = humanize.ftoa(Team1_Wkts)
                Team1_Runs_Str = humanize.ftoa(Team1_Runs)

                if Team1_Wkts != 10:
                    Score1 = Team1_Wkts_Str + "/" + Team1_Runs_Str
                else:
                    Score1 = Team1_Runs_Str

                Team1_Color = getTeamFontColor(Team1_ID)
                Team2_Color = getTeamFontColor(Team2_ID)

                Result = Match_JSON["match"]["statusText"]
                WinnerColor = "#fff"

            return render.Root(
                child = render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 44, height = 10, child = render.Padding(
                                    pad = (2, 1, 0, 0),
                                    child = render.Marquee(
                                        width = 44,
                                        child = render.Text(content = Team1_Abbr, color = Team1_Color, font = "CG-pixel-3x5-mono", offset = 0),
                                    ),
                                )),
                                render.Box(width = 20, height = 10, child = render.Text(content = Score1, color = Team1_Color, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Box(width = 44, height = 14, child = render.Padding(
                                    pad = (2, 1, 0, 0),
                                    child = render.Marquee(
                                        width = 44,
                                        child = render.Text(content = Team2_Abbr, color = Team2_Color, font = "CG-pixel-3x5-mono", offset = 0),
                                    ),
                                )),
                                render.Box(width = 20, height = 14, child = render.Text(content = Score2, color = Team2_Color, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Marquee(width = 64, height = 10, child = render.Text(content = Result, color = WinnerColor, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                    ],
                ),
            )

            # Game just finished
        elif Match_JSON["match"]["state"] == "POST":
            # What innings is it ?
            Innings = len(Match_JSON["scorecard"]["innings"]) - 1

            # What's the score
            Wickets = Match_JSON["scorecard"]["innings"][Innings]["wickets"]
            Runs = Match_JSON["scorecard"]["innings"][Innings]["runs"]

            Trail = Match_JSON["scorecard"]["innings"][Innings]["lead"]

            if Trail < 0:
                trail_bool = True
            else:
                trail_bool = False

            # How many overs bowled in this innings
            Overs = Match_JSON["scorecard"]["innings"][Innings]["overs"]
            Overs = str(Overs)

            # Batting #
            BattingTeam = Match_JSON["scorecard"]["innings"][Innings]["team"]["abbreviation"]
            BattingTeamID = Match_JSON["supportInfo"]["inning"]["team"]["id"]
            BattingTeamID = int(BattingTeamID)
            BattingTeamColor = getTeamFontColor(BattingTeamID)

            # On strike batsman
            Batsman1 = Match_JSON["livePerformance"]["batsmen"][0]["player"]["fieldingName"]
            Batsman1_Runs = Match_JSON["livePerformance"]["batsmen"][0]["runs"]
            Batsman1_Runs_Str = humanize.ftoa(Batsman1_Runs)

            Wickets = humanize.ftoa(Wickets)
            Runs = humanize.ftoa(Runs)

            # Last out
            WicketsInt = int(Wickets)
            if WicketsInt > 0:
                LastOut_Name = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["player"]["fieldingName"]
                LastOut_Runs = Match_JSON["scorecard"]["innings"][Innings]["inningWickets"][WicketsInt - 1]["runs"]

            # check if there is a second batsmen out there, this applies at fall of wicket & end of innings
            Batsmen = len(Match_JSON["livePerformance"]["batsmen"])

            if Batsmen == 2:
                Batsman2 = Match_JSON["livePerformance"]["batsmen"][1]["player"]["fieldingName"]
                Batsman2_Runs = Match_JSON["livePerformance"]["batsmen"][1]["runs"]
                Batsman2_Runs_Str = humanize.ftoa(Batsman2_Runs)

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
                Batsman2_Runs_Str = humanize.ftoa(LastOut_Runs)

                # little bit of formatting/spacing
                if LastOut_Runs < 100:
                    if LastOut_Runs > 9:
                        Batsman2_Runs_Str = " " + Batsman2_Runs_Str
                if LastOut_Runs < 10:
                    Batsman2_Runs_Str = "  " + Batsman2_Runs_Str

                BatsmanColor = "#fff"
                Batsman2Color = "#f00"

            # little bit of formatting/spacing
            if Batsman1_Runs < 100:
                if Batsman1_Runs > 9:
                    Batsman1_Runs_Str = " " + Batsman1_Runs_Str
            if Batsman1_Runs < 10:
                Batsman1_Runs_Str = "  " + Batsman1_Runs_Str

            BattingTeam = Match_JSON["scorecard"]["innings"][Innings]["team"]["name"]

            MOM = Match_JSON["supportInfo"]["playersOfTheMatch"][0]["player"]["fieldingName"]
            MOM_TeamID = Match_JSON["supportInfo"]["mostValuedPlayerOfTheMatch"]["team"]["id"]
            MOM_TeamColor = getTeamFontColor(MOM_TeamID)
            WinnerID = Match_JSON["match"]["winnerTeamId"]
            WinnerColor = getTeamFontColor(WinnerID)

            BestBat = Match_JSON["bestPerformance"]["batsmen"][0]["player"]["fieldingName"]
            BestRuns = Match_JSON["bestPerformance"]["batsmen"][0]["runs"]
            BestBowl = Match_JSON["bestPerformance"]["bowlers"][0]["player"]["fieldingName"]
            BestBowlRuns = Match_JSON["bestPerformance"]["bowlers"][0]["conceded"]
            BestBowlWickets = Match_JSON["bestPerformance"]["bowlers"][0]["wickets"]

            BestRuns = humanize.ftoa(BestRuns)
            BestBowlRuns = humanize.ftoa(BestBowlRuns)
            BestBowlWickets = humanize.ftoa(BestBowlWickets)

            # if team batting 2nd is still behind then team batting first won, else the opposite
            if trail_bool == True:
                Winner = Match_JSON["scorecard"]["innings"][0]["team"]["name"]
            else:
                Winner = Match_JSON["scorecard"]["innings"][1]["team"]["name"]

            T20_Status1 = Winner + " WIN!"
            T20_Status1Color = WinnerColor
            T20_Status2 = BestBat + " " + BestRuns
            T20_Status2Color = "#fff"
            T20_Status3 = BestBowl + " " + BestBowlWickets + "/" + BestBowlRuns
            T20_Status3Color = "#fff"
            T20_Status4 = "MOM: " + MOM
            T20_Status4Color = MOM_TeamColor

            renderScreens = [
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status1, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status2, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status3, T20_StatusColor),
                    ],
                ),
                render.Column(
                    children = [
                        TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs),
                        BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                        BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                        StatusRow(T20_Status4, T20_StatusColor),
                    ],
                ),
            ]

            return render.Root(
                delay = int(4000),
                child = render.Animation(children = renderScreens),
            )

            # Game is coming up
        elif Match_JSON["match"]["stage"] == "SCHEDULED" or "PRE":
            # Who is playing who
            Team1_Name = Match_JSON["match"]["teams"][0]["team"]["name"]
            Team2_Name = Match_JSON["match"]["teams"][1]["team"]["name"]
            Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
            Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]

            Team1_Color = getTeamFontColor(Team1_ID)
            Team2_Color = getTeamFontColor(Team2_ID)

            # Get the time of the game in the user's timezone
            StartTime = Match_JSON["match"]["startTime"]
            ParseTime = time.parse_time(StartTime, format = "2006-01-02T15:04:00.000Z")
            MatchTimezone = Match_JSON["match"]["ground"]["town"]["timezone"]

            location = DEFAULT_LOCATION
            loc = json.decode(location)
            timezone = loc["timezone"]

            MyTime = time.parse_time(StartTime, format = "2006-01-02T15:04:00.000Z").in_location(timezone)
            Time = MyTime.format("15:04")
            Date = MyTime.format("Jan 2")

            Standings_JSON = http.get(Standings_URL).json()
            Ladder = Standings_JSON["content"]["standings"]["groups"][0]["teamStats"]

            # Team1 Record
            for x in range(0, len(Ladder), 1):
                if Ladder[x]["teamInfo"]["id"] == Team1_ID:
                    Won1 = humanize.ftoa(Ladder[x]["matchesWon"])
                    Lost1 = humanize.ftoa(Ladder[x]["matchesLost"])
                    NR1 = humanize.ftoa(Ladder[x]["matchesNoResult"])

            # Team2 Record
            for x in range(0, len(Ladder), 1):
                if Ladder[x]["teamInfo"]["id"] == Team2_ID:
                    Won2 = humanize.ftoa(Ladder[x]["matchesWon"])
                    Lost2 = humanize.ftoa(Ladder[x]["matchesLost"])
                    NR2 = humanize.ftoa(Ladder[x]["matchesNoResult"])

            return render.Root(
                child = render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 44, height = 12, child = render.Padding(
                                    pad = (2, 1, 0, 0),
                                    child = render.Marquee(
                                        width = 44,
                                        child = render.Text(content = Team1_Name, color = Team1_Color, font = "CG-pixel-3x5-mono", offset = 0),
                                    ),
                                )),
                                render.Box(width = 20, height = 12, child = render.Text(content = Won1 + "-" + Lost1 + "-" + NR1, color = Team1_Color, font = "CG-pixel-3x5-mono")),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Box(width = 44, height = 12, child = render.Padding(
                                    pad = (2, 1, 0, 0),
                                    child = render.Marquee(
                                        width = 44,
                                        child = render.Text(content = Team2_Name, color = Team2_Color, font = "CG-pixel-3x5-mono", offset = 0),
                                    ),
                                )),
                                render.Box(width = 20, height = 12, child = render.Text(content = Won2 + "-" + Lost2 + "-" + NR2, color = Team2_Color, font = "CG-pixel-3x5-mono")),
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
    else:
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
                            render.Box(width = 64, height = 6, child = render.Text(content = "No games", color = "#FFF", font = "CG-pixel-3x5-mono")),
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

def TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 42, height = 8, child = render.Padding(
                        pad = (2, 1, 0, 0),
                        child = render.Marquee(
                            width = 42,
                            child = render.Text(content = BattingTeam, color = BattingTeamColor, font = "CG-pixel-3x5-mono", offset = 0),
                        ),
                    )),
                    render.Box(width = 22, height = 8, child = render.Text(content = Wickets + "/" + Runs, color = BattingTeamColor, font = "CG-pixel-3x5-mono")),
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
    return render.Row(
        children = [
            render.Box(width = 64, height = 8, child = render.Text(content = StatusMsg, color = StatusColor, font = "CG-pixel-3x5-mono")),
        ],
    )

TeamOptions = [
    schema.Option(
        display = "Adelaide Strikers",
        value = "4843",
    ),
    schema.Option(
        display = "Brisbane Heat",
        value = "4844",
    ),
    schema.Option(
        display = "Hobart Hurricanes",
        value = "4845",
    ),
    schema.Option(
        display = "Perth Scorchers",
        value = "4846",
    ),
    schema.Option(
        display = "Melboure Renegades",
        value = "4847",
    ),
    schema.Option(
        display = "Melboure Stars",
        value = "4848",
    ),
    schema.Option(
        display = "Sydney Sixers",
        value = "4849",
    ),
    schema.Option(
        display = "Sydney Thunder",
        value = "4850",
    ),
]

def getTeamFontColor(teamID):
    if teamID == 4843:  #Strikers
        return ("#35AEE0")
    elif teamID == 4844:  #Heat
        return ("#00B3C4")
    elif teamID == 4845:  #Hurricanes
        return ("#5F259F")
    elif teamID == 4846:  #Scorchers
        return ("#FE9900")
    elif teamID == 4847:  #Renegades
        return ("#BC2335")
    elif teamID == 4848:  #Stars
        return ("#00B140")
    elif teamID == 4849:  #Sixers
        return ("#EF359C")
    elif teamID == 4850:  #Thunder
        return ("#9FFC39")
    return None

def getTeamDisplayName(teamID):
    if teamID == 4843:  #Strikers
        return ("Strikers")
    elif teamID == 4844:  #Heat
        return ("Heat")
    elif teamID == 4845:  #Hurricanes
        return ("Hurricanes")
    elif teamID == 4846:  #Scorchers
        return ("Scorchers")
    elif teamID == 4847:  #Renegades
        return ("Renegades")
    elif teamID == 4848:  #Stars
        return ("Stars")
    elif teamID == 4849:  #Sixers
        return ("Sixers")
    elif teamID == 4850:  #Thunder
        return ("Thunder")
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "TeamList",
                name = "Team",
                desc = "Choose your team",
                icon = "gear",
                default = TeamOptions[0].value,
                options = TeamOptions,
            ),
        ],
    )

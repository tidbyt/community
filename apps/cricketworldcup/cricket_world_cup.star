"""
Applet: CWC Cricket
Summary: Displays scores for CWC
Description: Shows live scores for the selected Cricket World Cup team. Also can show post game details or upcoming match information.
Author: jatinrampal, M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LiveGames_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/series/home?lang=en&seriesId=1367856"
Standings_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/series/standings?lang=en&seriesId=1367856"

DEFAULT_TEAM = "1"
DEFAULT_TIMEZONE = "America/New_York"
MATCH_CACHE = 60
ALL_MATCH_CACHE = 8 * 3600  # 8 hours
STANDINGS_CACHE = 8 * 3600  # 8 hours

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    SelectedTeam = config.get("TeamList", DEFAULT_TEAM)
    SelectedTeam = int(SelectedTeam)

    # Cache the Cricinfo list of WC matches for 2 hours, could possibly be even longer
    # We'll pull the specific match data from this call so its not important to keep it up to date
    AllMatchData = get_cachable_data(LiveGames_URL, ALL_MATCH_CACHE)
    LiveGames_JSON = json.decode(AllMatchData)

    Matches = LiveGames_JSON["content"]["recentFixtures"]
    RecentMatches = LiveGames_JSON["content"]["recentResults"]

    MatchID = None

    # look through recently completed matches and if its less than 24 hrs since the last completed match, show the details
    # else show the next match coming up

    for x in range(0, len(RecentMatches), 1):
        if RecentMatches[x]["teams"][0]["team"]["id"] == SelectedTeam or RecentMatches[x]["teams"][1]["team"]["id"] == SelectedTeam:
            StartTime = RecentMatches[x]["startTime"]
            MatchTime = time.parse_time(StartTime, format = "2006-01-02T15:04:00.000Z").in_location(timezone)
            TimeDiff = MatchTime - now

            if TimeDiff.hours < -24:
                break
            else:
                MatchID = RecentMatches[x]["objectId"]
                break

    if MatchID == None:
        for x in range(0, len(Matches), 1):
            if Matches[x]["teams"][0]["team"]["id"] == SelectedTeam or Matches[x]["teams"][1]["team"]["id"] == SelectedTeam:
                MatchID = Matches[x]["objectId"]
                break

    LastOut_Runs = 0
    LastOut_Name = ""
    ODI_Status4 = ""

    MatchID = str(MatchID)
    Match_URL = "https://hs-consumer-api.espncricinfo.com/v1/pages/match/details?lang=en&seriesId=1367856&matchId=" + MatchID + "&latest=true"

    #print(Match_URL)
    # cache specific match data for 1 minute
    MatchData = get_cachable_data(Match_URL, MATCH_CACHE)
    Match_JSON = json.decode(MatchData)

    # If there is a live game on
    if Match_JSON["match"]["state"] == "LIVE":
        # What innings is it ?
        Innings = len(Match_JSON["scorecard"]["innings"]) - 1

        # What's the score
        Wickets = Match_JSON["scorecard"]["innings"][Innings]["wickets"]
        Runs = Match_JSON["scorecard"]["innings"][Innings]["runs"]

        # In front or behind? And how much?
        Trail = Match_JSON["scorecard"]["innings"][Innings]["lead"]

        Trail = math.fabs(Trail) + 1
        Trail = humanize.float("#.", Trail)
        Trail = str(Trail)

        TrailBy = " need " + Trail

        # How many overs bowled
        Overs = Match_JSON["scorecard"]["innings"][Innings]["overs"]
        Overs = str(Overs)

        # How many overs left
        RemOvers = Match_JSON["match"]["liveOversPending"]
        RemOvers = str(RemOvers)

        # Batting details
        #BattingTeamID = Match_JSON["supportInfo"]["inning"]["team"]["id"]
        BattingTeamID = Match_JSON["scorecard"]["innings"][Innings]["team"]["id"]
        BattingTeamID = int(BattingTeamID)
        BattingTeamColor = getTeamColor(BattingTeamID)

        # On strike batsman
        Batsman1 = Match_JSON["livePerformance"]["batsmen"][0]["player"]["fieldingName"]
        Batsman1_Runs = Match_JSON["livePerformance"]["batsmen"][0]["runs"]
        Batsman1_Runs_Str = str(Batsman1_Runs)

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

        Wickets = str(Wickets)
        Runs = str(Runs)

        if WicketsInt > 0:
            LastOut_Runs = str(LastOut_Runs)

        # little bit of formatting/spacing
        if Batsman1_Runs < 100:
            if Batsman1_Runs > 9:
                Batsman1_Runs_Str = " " + Batsman1_Runs_Str
        if Batsman1_Runs < 10:
            Batsman1_Runs_Str = "  " + Batsman1_Runs_Str

        #BattingTeam = Match_JSON["scorecard"]["innings"][Innings]["team"]["name"]
        BattingTeamAbbr = Match_JSON["scorecard"]["innings"][Innings]["team"]["abbreviation"]
        CRR = str(Match_JSON["supportInfo"]["liveInfo"]["currentRunRate"])
        RRR = str(Match_JSON["supportInfo"]["liveInfo"]["requiredRunrate"])

        # Formatting to include trailing zeros on the strings
        # Doing it this way as value from API can be either float or int
        if len(RRR) == 1:
            RRR = RRR + ".00"
        if len(RRR) == 3:
            RRR = RRR + "0"
        if len(CRR) == 1:
            CRR = CRR + ".00"
        if len(CRR) == 3:
            CRR = CRR + "0"

        # If Predictions aren't working
        if Match_JSON["match"]["liveInningPredictions"] != None:
            ProjScore = str(Match_JSON["match"]["liveInningPredictions"]["score"])
        else:
            ProjScore = "N/A"

        # ProjScore can be null at the very start of the match
        if ProjScore == None:
            ProjScore = "N/A"

        ODI_Innings = Match_JSON["match"]["liveInning"]
        MatchStatus = str(Match_JSON["match"]["status"])
        ODI_StatusColor = "#fff"

        # what to show on the status bar, depending on state of game, team batting first or second & fall of wicket
        if ODI_Innings == 1:
            if MatchStatus == "Live":
                ODI_Status1 = "1st Inns - " + MatchStatus
                ODI_Status4 = "Proj Score: " + ProjScore
            elif MatchStatus == "Innings break":
                ODI_Status1 = MatchStatus
                ODI_Status4 = MatchStatus
            elif MatchStatus == "Match delayed by rain":
                MatchStatus = "Rain Delay"
                ODI_Status1 = MatchStatus
            else:
                ODI_Status1 = MatchStatus

            ODI_Status2 = "Overs: " + Overs
            ODI_Status3 = "Run Rate: " + CRR

            # 2nd Innings underway
        else:
            ODI_Status1 = BattingTeamAbbr + TrailBy
            ODI_Status2 = "Overs: " + Overs
            ODI_Status3 = "Run Rate: " + CRR
            ODI_Status4 = "Req Rate: " + RRR
            if MatchStatus == "Match delayed by rain":
                MatchStatus = "Rain Delay"
                ODI_Status3 = MatchStatus

        # Wicket has fallen but not the end of the inngs
        if IsOut == True and Wickets != "10":
            # Team batting first
            if ODI_Innings == 1:
                ODI_Status1 = "WICKET!"
                ODI_Status2 = "WICKET!"
                ODI_Status3 = "Overs: " + Overs
                ODI_Status4 = "Proj Score: " + ProjScore

                # Team batting second, still want to show how far behind and req RR
            else:
                ODI_Status1 = "WICKET!"
                ODI_Status2 = BattingTeamAbbr + TrailBy
                ODI_Status3 = "Overs: " + Overs
                ODI_Status4 = "Req Rate: " + RRR
            ODI_StatusColor = "#f00"

        renderScreens = [
            render.Column(
                children = [
                    TeamScore(BattingTeamAbbr, BattingTeamColor, Wickets, Runs),
                    BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                    BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                    StatusRow(ODI_Status1, ODI_StatusColor),
                ],
            ),
            render.Column(
                children = [
                    TeamScore(BattingTeamAbbr, BattingTeamColor, Wickets, Runs),
                    BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                    BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                    StatusRow(ODI_Status2, ODI_StatusColor),
                ],
            ),
            render.Column(
                children = [
                    TeamScore(BattingTeamAbbr, BattingTeamColor, Wickets, Runs),
                    BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                    BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                    StatusRow(ODI_Status3, ODI_StatusColor),
                ],
            ),
            render.Column(
                children = [
                    TeamScore(BattingTeamAbbr, BattingTeamColor, Wickets, Runs),
                    BatsmanScore(Batsman1, Batsman1_Runs_Str, BatsmanColor),
                    BatsmanScore(Batsman2, Batsman2_Runs_Str, Batsman2Color),
                    StatusRow(ODI_Status4, ODI_StatusColor),
                ],
            ),
        ]

        return render.Root(
            delay = 3750,
            child = render.Animation(children = renderScreens),
        )

    elif Match_JSON["match"]["state"] == "FINISHED" or Match_JSON["match"]["state"] == "POST":
        # Game has completed
        # check if 2 innings were started

        if len(Match_JSON["scorecardSummary"]["innings"]) == 2:
            Team1_Abbr = Match_JSON["scorecardSummary"]["innings"][0]["team"]["abbreviation"]
            Team2_Abbr = Match_JSON["scorecardSummary"]["innings"][1]["team"]["abbreviation"]
            Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
            Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]

            Team1_Wkts = Match_JSON["scorecardSummary"]["innings"][0]["wickets"]
            Team1_Runs = Match_JSON["scorecardSummary"]["innings"][0]["runs"]

            Team2_Wkts = Match_JSON["scorecardSummary"]["innings"][1]["wickets"]
            Team2_Runs = Match_JSON["scorecardSummary"]["innings"][1]["runs"]

            Team1_Wkts_Str = str(Team1_Wkts)
            Team1_Runs_Str = str(Team1_Runs)
            Team2_Wkts_Str = str(Team2_Wkts)
            Team2_Runs_Str = str(Team2_Runs)

            if Team1_Wkts != 10:
                Score1 = Team1_Wkts_Str + "/" + Team1_Runs_Str
            else:
                Score1 = Team1_Runs_Str

            if Team2_Wkts != 10:
                Score2 = Team2_Wkts_Str + "/" + Team2_Runs_Str
            else:
                Score2 = Team2_Runs_Str

            Team1_Color = getTeamColor(Team1_ID)
            Team2_Color = getTeamColor(Team2_ID)

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

            Team1_Wkts_Str = str(Team1_Wkts)
            Team1_Runs_Str = str(Team1_Runs)

            if Team1_Wkts != 10:
                Score1 = Team1_Wkts_Str + "/" + Team1_Runs_Str
            else:
                Score1 = Team1_Runs_Str

            Team1_Color = getTeamColor(Team1_ID)
            Team2_Color = getTeamColor(Team2_ID)

            Result = Match_JSON["match"]["statusText"]
            WinnerColor = "#fff"

        return render.Root(
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Row(
                        children = [
                            render.Box(width = 39, height = 12, child = render.Padding(
                                pad = (7, 0, 0, 0),
                                child = render.Marquee(
                                    width = 44,
                                    child = render.Text(
                                        content = Team1_Abbr,
                                        color = Team1_Color,
                                        font = "Dina_r400-6",
                                        offset = 0,
                                    ),
                                ),
                            )),
                            render.Box(width = 25, height = 12, child = render.Padding(
                                pad = (0, 0, 0, 0),
                                child = render.Text(content = Score1, color = Team1_Color, font = "CG-pixel-4x5-mono"),
                            )),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 39, height = 12, child = render.Padding(
                                pad = (7, 0, 0, 0),
                                child = render.Marquee(
                                    width = 44,
                                    child = render.Text(
                                        content = Team2_Abbr,
                                        color = Team2_Color,
                                        font = "Dina_r400-6",
                                        offset = 0,
                                    ),
                                ),
                            )),
                            render.Box(width = 25, height = 12, child = render.Padding(
                                pad = (0, 0, 0, 0),
                                child = render.Text(content = Score2, color = Team2_Color, font = "CG-pixel-4x5-mono"),
                            )),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 8, child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    content = Result,
                                    color = WinnerColor,
                                    font = "CG-pixel-4x5-mono",
                                ),
                            )),
                        ],
                    ),
                ],
            ),
        )

    elif Match_JSON["match"]["state"] == "SCHEDULED" or Match_JSON["match"]["state"] == "PRE":
        # Game is coming up
        # cache the standings data for 6hrs
        StandingsData = get_cachable_data(Standings_URL, STANDINGS_CACHE)
        Standings_JSON = json.decode(StandingsData)
        Ladder = ""

        # Who is playing who
        Team1_Name = Match_JSON["match"]["teams"][0]["team"]["abbreviation"]
        Team2_Name = Match_JSON["match"]["teams"][1]["team"]["abbreviation"]
        Team1_ID = Match_JSON["match"]["teams"][0]["team"]["id"]
        Team2_ID = Match_JSON["match"]["teams"][1]["team"]["id"]
        #Title = Match_JSON["match"]["title"]

        Team1_Color = getTeamColor(Team1_ID)
        Team2_Color = getTeamColor(Team2_ID)

        # Get the time of the game in the user's timezone
        StartTime = Match_JSON["match"]["startTime"]

        MyTime = time.parse_time(StartTime, format = "2006-01-02T15:04:00.000Z").in_location(timezone)
        Time = MyTime.format("15:04")
        Date = MyTime.format("Jan 2")

        Ladder = Standings_JSON["content"]["standings"]["groups"][0]["teamStats"]

        # Team1 Record
        Won1 = ""
        Lost1 = ""
        NR1 = ""
        for x in range(0, len(Ladder), 1):
            if Ladder[x]["teamInfo"]["id"] == Team1_ID:
                #print("HI")
                Won1 = humanize.ftoa(float(Ladder[x]["matchesWon"]))
                Lost1 = humanize.ftoa(float(Ladder[x]["matchesLost"]))
                NR1 = humanize.ftoa(float(Ladder[x]["matchesNoResult"]))

        # Team2 Record
        Won2 = ""
        Lost2 = ""
        NR2 = ""
        for x in range(0, len(Ladder), 1):
            if Ladder[x]["teamInfo"]["id"] == Team2_ID:
                Won2 = humanize.ftoa(float(Ladder[x]["matchesWon"]))
                Lost2 = humanize.ftoa(float(Ladder[x]["matchesLost"]))
                NR2 = humanize.ftoa(float(Ladder[x]["matchesNoResult"]))

        return render.Root(
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Row(
                        children = [
                            render.Box(width = 40, height = 12, child = render.Padding(
                                pad = (2, 1, 0, 1),
                                child = render.Marquee(
                                    width = 40,
                                    child = render.Text(
                                        content = Team1_Name,
                                        color = Team1_Color,
                                        font = "Dina_r400-6",
                                        offset = 0,
                                    ),
                                ),
                            )),
                            render.Box(
                                width = 24,
                                height = 12,
                                child = render.Text(
                                    content = Won1 + "-" + Lost1 + "-" + NR1,
                                    color = Team1_Color,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 40, height = 12, child = render.Padding(
                                pad = (2, 1, 0, 1),
                                child = render.Marquee(
                                    width = 40,
                                    child = render.Text(
                                        content = Team2_Name,
                                        color = Team2_Color,
                                        font = "Dina_r400-6",
                                        offset = 0,
                                    ),
                                ),
                            )),
                            render.Box(
                                width = 24,
                                height = 12,
                                child = render.Text(
                                    content = Won2 + "-" + Lost2 + "-" + NR2,
                                    color = Team2_Color,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Box(width = 64, height = 8, child = render.Text(
                                content = Date + " - " + Time,
                                color = "#FFF",
                                font = "CG-pixel-3x5-mono",
                            )),
                        ],
                    ),
                ],
            ),
        )

    # should never get here but lint wanted it
    return None

def TeamScore(BattingTeam, BattingTeamColor, Wickets, Runs):
    # if all out
    if Wickets != "10":
        Wickets = Wickets + "/"
    else:
        Wickets = ""

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 44, height = 8, child = render.Padding(
                        pad = (2, 1, 1, 1),
                        child = render.Marquee(
                            width = 44,
                            child = render.Text(
                                content = BattingTeam,
                                color = BattingTeamColor,
                                font = "CG-pixel-3x5-mono",
                                offset = 0,
                            ),
                        ),
                    )),
                    render.Box(width = 20, height = 8, child = render.Text(
                        content = Wickets + Runs,
                        color = BattingTeamColor,
                        font = "CG-pixel-3x5-mono",
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
    return render.Row(
        children = [
            render.Box(
                width = 64,
                height = 8,
                child = render.Text(content = StatusMsg, color = StatusColor, font = "CG-pixel-3x5-mono"),
            ),
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
        display = "Afghanistan",
        value = "40",
    ),
    schema.Option(
        display = "Bangladesh",
        value = "25",
    ),
    schema.Option(
        display = "Netherlands",
        value = "15",
    ),
]

def getTeamColor(teamID):
    if teamID == 2:  # Australia
        return ("#ffdd00")
    elif teamID == 3:  # South Africa
        return ("#04822B")
    elif teamID == 7:  # Pakistan
        return ("#04822B")
    elif teamID == 5:  # New Zealand
        return ("#fff")
    elif teamID == 1:  # England
        return ("#2B57AC")
    elif teamID == 6:  # India
        return ("#137dd2")
    elif teamID == 8:  # Sri Lanka
        return ("#203d89")
    elif teamID == 25:  # Bangladesh
        return ("#006A4E")
    elif teamID == 15:  # Netherlands
        return ("#F36C21")
    elif teamID == 40:  # Afghanistan
        return ("#fff")
    else:  # For any other team
        return ("#fff")

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

def get_cachable_data(url, timeout):
    # Use http.get() with ttl_seconds to leverage built-in cache
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

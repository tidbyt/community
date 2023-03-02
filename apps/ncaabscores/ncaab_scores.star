"""
Applet: NCAAF Scores
Summary: Displays NCAA Football scores
Description: Displays live and upcoming NCAA Football scores from a data feed.
Author: LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 60
DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""
LEAGUE_DISPLAY = "NCAAB"
LEAGUE_DISPLAY_OFFSET = 6
SPORT = "baseball"
LEAGUE = "college-baseball"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/scoreboard"
SHORTENED_WORDS = """
{
    " PM": "P",
    " AM": "A",
    " Wins": "",
    " wins": "",
    " Win": "",
    " win": "",
    " Leads": "",
    " lead": "",
    " Leads": "",
    " lead": "",
    " Series": "",
    " series": "",
    " Tied": "",
    " tied": "",
    " of": "",
    " - ": " ",
    " / ": " ",
    "Postponed": "PPD",
    "Bottom": "Bot",
    "Middle": "Mid"
}
"""
ALT_COLOR = """
{
    "SYR" : "#000E54",
    "LSU" : "#461D7C",
    "WAKE" : "#000000",
    "UVA" : "#232D4B",
    "WESTV" : "#002855",
    "CIN" : "#E00122",
    "WYO" : "#492F24",
    "SMU" : "#0033A0",
    "IOWA" : "#FFCD00",
    "PUR" : "#000000",
    "USC" : "#990000",
    "ARMY" : "#000000",
    "USM" : "#000000",
    "TOL" : "#15397F",
    "EIU" : "#004B83",
    "UNLV" : "#cf0a2c",
    "MRSH" : "#000000",
    "UNC" : "#13294B",
    "COLO" : "#000000",
    "IOWA" : "#000000",
    "RICE" : "#00205B",
    "RUTG" : "#CC0033"
}
"""
ALT_LOGO = """
{
    "WYO" : "https://i.ibb.co/Czv9k7H/wyoming-cowboys.png",
    "IOWA" : "https://storage.googleapis.com/hawkeyesports-com/2021/02/cf540990-logo.png",
    "DUQ" : "https://b.fssta.com/uploads/application/college/team-logos/Duquesne-alternate.vresize.50.50.medium.1.png",
    "UNC" : "https://b.fssta.com/uploads/application/college/team-logos/NorthCarolina-alternate.vresize.50.50.medium.1.png",
    "DUKE" : "https://b.fssta.com/uploads/application/college/team-logos/Duke-alternate.vresize.50.50.medium.1.png",
    "TEM" : "https://b.fssta.com/uploads/application/college/team-logos/Temple.vresize.50.50.medium.1.png",
    "CLEM" : "https://b.fssta.com/uploads/application/college/team-logos/Clemson-alternate.vresize.50.50.medium.1.png",
    "LSU" : "https://b.fssta.com/uploads/application/college/team-logos/LSU-alternate.vresize.50.50.medium.1.png",
    "WESTV" : "https://b.fssta.com/uploads/application/college/team-logos/WestVirginia-alternate.vresize.50.50.medium.1.png",
    "PITT" : "https://b.fssta.com/uploads/application/college/team-logos/Pittsburgh-alternate.vresize.50.50.medium.1.png",
    "UVA" : "https://b.fssta.com/uploads/application/college/team-logos/Virginia.vresize.50.50.medium.1.png",
    "RUTG" : "https://b.fssta.com/uploads/application/college/team-logos/Rutgers-alternate.vresize.50.50.medium.1.png",
    "CIN" : "https://b.fssta.com/uploads/application/college/team-logos/Cincinnati-alternate.vresize.50.50.medium.1.png",
    "ARK" : "https://b.fssta.com/uploads/application/college/team-logos/Arkansas-alternate.vresize.50.50.medium.1.png",
    "HOU" : "https://b.fssta.com/uploads/application/college/team-logos/Houston-alternate.vresize.50.50.medium.1.png",
    "UNT" : "https://b.fssta.com/uploads/application/college/team-logos/NorthTexas-alternate.vresize.50.50.medium.1.png",
    "TCU" : "https://b.fssta.com/uploads/application/college/team-logos/TCU-alternate.vresize.50.50.medium.1.png",
    "OU" : "https://b.fssta.com/uploads/application/college/team-logos/Oklahoma-alternate.vresize.50.50.medium.1.png",
    "TEX" : "https://b.fssta.com/uploads/application/college/team-logos/Texas-alternate.vresize.50.50.medium.1.png",
    "KANSA" : "https://b.fssta.com/uploads/application/college/team-logos/KansasState-alternate.vresize.50.50.medium.1.png",
    "ILL" : "https://b.fssta.com/uploads/application/college/team-logos/Illinois-alternate.vresize.50.50.medium.1.png",
    "NEB" : "https://b.fssta.com/uploads/application/college/team-logos/Nebraska-alternate.vresize.50.50.medium.1.png",
    "NU" : "https://b.fssta.com/uploads/application/college/team-logos/Northwestern-alternate.vresize.50.50.medium.1.png",
    "MICHI" : "https://b.fssta.com/uploads/application/college/team-logos/MichiganState-alternate.vresize.50.50.medium.1.png",
    "WISC" : "https://b.fssta.com/uploads/application/college/team-logos/Wisconsin-alternate.vresize.50.50.medium.1.png",
    "IU" : "https://b.fssta.com/uploads/application/college/team-logos/Indiana-alternate.vresize.50.50.medium.0.png",
    "MINN" : "https://b.fssta.com/uploads/application/college/team-logos/Minnesota-alternate.vresize.50.50.medium.0.png",
    "MD" : "https://b.fssta.com/uploads/application/college/team-logos/Maryland-alternate.vresize.50.50.medium.0.png",
    "ND" : "https://b.fssta.com/uploads/application/college/team-logos/NotreDame-alternate.vresize.50.50.medium.0.png",
    "AAMU" : "https://b.fssta.com/uploads/application/college/team-logos/AlabamaA&M-alternate.vresize.50.50.medium.0.png",
    "USC" : "https://b.fssta.com/uploads/application/college/team-logos/USC-alternate.vresize.50.50.medium.0.png",
    "RICE" : "https://b.fssta.com/uploads/application/college/team-logos/Rice-alternate.vresize.50.50.medium.0.png",
    "NEV" : "https://b.fssta.com/uploads/application/college/team-logos/Nevada-alternate.vresize.50.50.medium.0.png",
    "USU" : "https://b.fssta.com/uploads/application/college/team-logos/UtahState-alternate.vresize.50.50.medium.0.png",
    "ARMY" : "https://b.fssta.com/uploads/application/college/team-logos/Army.vresize.50.50.medium.0.png",
    "TENN" : "https://b.fssta.com/uploads/application/college/team-logos/Tennessee-alternate.vresize.50.50.medium.0.png",
    "CMU" : "https://b.fssta.com/uploads/application/college/team-logos/CentralMichigan-alternate.vresize.50.50.medium.0.png",
    "TOL" : "https://b.fssta.com/uploads/application/college/team-logos/Toledo-alternate.vresize.50.50.medium.0.png",
    "EMU" : "https://b.fssta.com/uploads/application/college/team-logos/EasternMichigan-alternate.vresize.50.50.medium.0.png",
    "EKU" : "https://b.fssta.com/uploads/application/college/team-logos/EasternKentucky-alternate.vresize.50.50.medium.0.png",
    "UCLA" : "https://b.fssta.com/uploads/application/college/team-logos/UCLA-alternate.vresize.50.50.medium.0.png",
    "KENTU" : "https://b.fssta.com/uploads/application/college/team-logos/Kentucky-alternate.vresize.50.50.medium.0.png",
    "WASHI" : "https://b.fssta.com/uploads/application/college/team-logos/Washington-alternate.vresize.50.50.medium.0.png",
    "UNLV" : "https://b.fssta.com/uploads/application/college/team-logos/UNLV-alternate.vresize.50.50.medium.0.png",
    "AFA" : "https://b.fssta.com/uploads/application/college/team-logos/AirForce-alternate.vresize.50.50.medium.1.png",
    "NAU" : "https://b.fssta.com/uploads/application/college/team-logos/NorthernArizona-alternate.vresize.50.50.medium.0.png",
    "ORE" : "https://b.fssta.com/uploads/application/college/team-logos/Oregon-alternate.vresize.50.50.medium.0.png",
    "UCD" : "https://b.fssta.com/uploads/application/college/team-logos/UCDavis-alternate.vresize.50.50.medium.0.png",
    "CAL" : "https://b.fssta.com/uploads/application/college/team-logos/California-alternate.vresize.50.50.medium.0.png",
    "COLG" : "https://b.fssta.com/uploads/application/college/team-logos/Colgate-alternate.vresize.50.50.medium.0.png",
    "STAN" : "https://b.fssta.com/uploads/application/college/team-logos/Stanford.vresize.50.50.medium.0.png",
    "WSU" : "https://b.fssta.com/uploads/application/college/team-logos/WashingtonState-alternate.vresize.50.50.medium.0.png",
    "SDSU" : "https://b.fssta.com/uploads/application/college/team-logos/SanDiegoState.vresize.50.50.medium.0.png",
    "SHSU" : "https://b.fssta.com/uploads/application/college/team-logos/SamHoustonState-alternate.vresize.50.50.medium.0.png",
    "AUB" : "https://b.fssta.com/uploads/application/college/team-logos/Auburn-alternate.vresize.50.50.medium.0.png",
    "NORF" : "https://b.fssta.com/uploads/application/college/team-logos/NorfolkState.vresize.50.50.medium.0.png",
    "UNC" : "https://b.fssta.com/uploads/application/college/team-logos/NorthCarolina.vresize.50.50.medium.0.png",
    "BAY" : "https://b.fssta.com/uploads/application/college/team-logos/Baylor-alternate.vresize.50.50.medium.0.png",
    "ALA" : "https://b.fssta.com/uploads/application/college/team-logos/Alabama-alternate.vresize.50.50.medium.0.png",
    "NORTH" : "https://b.fssta.com/uploads/application/college/team-logos/Northwestern-alternate.vresize.50.50.medium.0.png"
}
"""
MAGNIFY_LOGO = """
{
    "WESTV" : 12,
    "RUTG" : 12,
    "DUKE" : 12,
    "UNT" : 14,
    "HOU" : 14,
    "USF" : 14,
    "OU" : 14,
    "KANSA" : 14,
    "NEB" : 12,
    "ILL" : 14,
    "ND" : 14,
    "UTS" : 18,
    "USU" : 14,
    "TENN" : 14,
    "EMU" : 14,
    "ORE" : 14,
    "ASU" : 24,
    "COLG" : 14,
    "AUB" : 14,
    "SHSU" : 14,
    "UTAH" : 14,
    "UGA" : 18,
    "M-OH" : 14,
    "VT" : 18,
    "NORF" : 14,
    "WYO" : 12,
    "BAY" : 12,
    "PITT" : 14,
    "COLO" : 14,
    "IOWA" : 12,
    "PSU" : 14
}
"""
ODDS_NAME = """
{
}
"""

def main(config):
    renderCategory = []
    selectedTeam = config.get("selectedTeam", "all")
    showRanking = config.bool("displayRanking")
    displayType = config.get("displayType", "colors")
    pregameDisplay = config.get("pregameDisplay", "record")
    displayTop = config.get("displayTop", "league")
    timeColor = config.get("displayTimeColor", "#FFA500")
    rotationSpeed = config.get("rotationSpeed", "5")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    datePast = now - time.parse_duration("%dh" % 1 * 24)
    dateFuture = now + time.parse_duration("%dh" % 6 * 24)
    league = {LEAGUE: API + "?limit=300" + (selectedTeam == "all" and " " or "&dates=" + datePast.format("20060102") + "-" + dateFuture.format("20060102"))}
    scores = get_scores(league, selectedTeam)
    if len(scores) > 0:
        for i, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]
            home = competition["competitors"][0]["team"]["abbreviation"]
            away = competition["competitors"][1]["team"]["abbreviation"]
            homeTeamName = competition["competitors"][0]["team"]["shortDisplayName"]
            awayTeamName = competition["competitors"][1]["team"]["shortDisplayName"]
            homeColorCheck = competition["competitors"][0]["team"].get("color", "NO")
            if homeColorCheck == "NO":
                homePrimaryColor = "000000"
            else:
                homePrimaryColor = competition["competitors"][0]["team"]["color"]

            awayColorCheck = competition["competitors"][1]["team"].get("color", "NO")
            if awayColorCheck == "NO":
                awayPrimaryColor = "000000"
            else:
                awayPrimaryColor = competition["competitors"][1]["team"]["color"]

            homeColor = get_background_color(home, displayType, homePrimaryColor)
            awayColor = get_background_color(away, displayType, awayPrimaryColor)

            homeLogoCheck = competition["competitors"][0]["team"].get("logo", "NO")
            if homeLogoCheck == "NO":
                homeLogoURL = "https://i.ibb.co/5LMp8T1/transparent.png"
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logo"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logo", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = "https://i.ibb.co/5LMp8T1/transparent.png"
            else:
                awayLogoURL = competition["competitors"][1]["team"]["logo"]

            homeRankCheck = competition["competitors"][0].get("curatedRank", "NO")
            if homeRankCheck == "NO":
                homeRank = 99
            else:
                homeRank = competition["competitors"][0]["curatedRank"]["current"]

            awayRankCheck = competition["competitors"][1].get("curatedRank", "NO")
            if awayRankCheck == "NO":
                awayRank = 99
            else:
                awayRank = competition["competitors"][1]["curatedRank"]["current"]

            homeLogo = get_logoType(home, homeLogoURL)
            awayLogo = get_logoType(away, awayLogoURL)
            homeLogoSize = get_logoSize(home)
            awayLogoSize = get_logoSize(away)
            homeScore = ""
            awayScore = ""
            gameTime = ""
            homeScoreColor = "#fff"
            awayScoreColor = "#fff"
            teamFont = "Dina_r400-6"
            scoreFont = "Dina_r400-6"

            if gameStatus == "pre":
                gameTime = s["date"]
                scoreFont = "CG-pixel-3x5-mono"
                convertedTime = time.parse_time(gameTime, format = "2006-01-02T15:04Z").in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    gameTime = convertedTime.format("Jan 2")
                else:
                    gameTime = convertedTime.format("3:04 PM")
                if pregameDisplay == "odds":
                    checkOdds = competition.get("odds", "NO")
                    if checkOdds != "NO":
                        checkOU = competition["odds"][0].get("overUnder", "NO")
                        if checkOdds != "NO":
                            theOdds = competition["odds"][0]["details"]
                            if checkOU == "NO":
                                theOU = ""
                            else:
                                theOU = competition["odds"][0]["overUnder"]
                            homeScore = get_odds(theOdds, str(theOU), home, "home")
                            awayScore = get_odds(theOdds, str(theOU), away, "away")
                    else:
                        homeScore = ""
                        awayScore = ""
                elif pregameDisplay == "record":
                    checkSeries = competition.get("series", "NO")
                    if checkSeries == "NO":
                        homeCompetitor = competition["competitors"][0]
                        homecheckRecord = homeCompetitor.get("records", "NO")
                        awayCompetitor = competition["competitors"][1]
                        awaycheckRecord = awayCompetitor.get("records", "NO")
                        if homecheckRecord == "NO":
                            homeScore = "0-0"
                        else:
                            homeScore = competition["competitors"][0]["records"][0]["summary"]
                        if awaycheckRecord == "NO":
                            awayScore = "0-0"
                        else:
                            awayScore = competition["competitors"][1]["records"][0]["summary"]
                    else:
                        homeScore = str(competition["series"]["competitors"][0]["wins"]) + "-" + str(competition["series"]["competitors"][1]["wins"])
                        awayScore = str(competition["series"]["competitors"][1]["wins"]) + "-" + str(competition["series"]["competitors"][0]["wins"])

                else:
                    homeScore = ""
                    awayScore = ""

            if gameStatus == "in":
                gameTime = s["status"]["type"]["shortDetail"]
                homeScore = competition["competitors"][0]["score"]
                homeScoreColor = "#fff"
                awayScore = competition["competitors"][1]["score"]
                awayScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = s["status"]["type"]["shortDetail"]
                gameName = s["status"]["type"]["name"]
                checkSeries = competition.get("series", "NO")
                checkNotes = len(competition["notes"])
                if checkSeries != "NO":
                    seriesSummary = competition["series"]["summary"]
                    gameTime = seriesSummary.replace("series ", "")
                if checkNotes > 0 and checkSeries == "NO":
                    gameHeadline = competition["notes"][0]["headline"]
                    if gameHeadline.find(" - ") > 0:
                        gameNoteArray = gameHeadline.split(" - ")
                        gameTime = str(gameNoteArray[1]) + " / " + gameTime
                if gameName == "STATUS_POSTPONED":
                    homeScore = ""
                    awayScore = ""
                    gameTime = "Postponed"
                else:
                    homeScore = competition["competitors"][0]["score"]
                    awayScore = competition["competitors"][1]["score"]
                    if (int(homeScore) > int(awayScore)):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayScore) > int(homeScore)):
                        homeScoreColor = "#fffc"
                        awayScoreColor = "#ff0"
                    else:
                        homeScoreColor = "#fff"
                        awayScoreColor = "#fff"

            if displayType == "retro":
                retroTextColor = "#ffe065"
                retroBorderColor = "#000"
                retroFont = "CG-pixel-3x5-mono"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, retroTextColor, retroBorderColor, displayType, gameTime, timeColor),
                                ),
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 12, child = render.Text(content = get_team_name(awayTeamName), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 12, child = render.Text(content = get_record(awayScore), color = retroTextColor, font = retroFont)),
                                        ])),
                                        render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 12, child = render.Text(content = get_team_name(homeTeamName), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 12, child = render.Text(content = get_record(homeScore), color = retroTextColor, font = retroFont)),
                                        ])),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "stadium":
                textColor = "#fff"
                backgroundColor = "#0f3027"
                borderColor = "#345252"
                textFont = "tb-8"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "center",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 12, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 1, height = 10, color = borderColor),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = away[:4].upper(), color = awayScoreColor, font = textFont))),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = get_record(awayScore), color = awayScoreColor, font = scoreFont))),
                                            render.Box(width = 1, height = 10, color = borderColor),
                                        ])),
                                        render.Box(width = 64, height = 1, color = borderColor),
                                        render.Box(width = 64, height = 10, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 1, height = 10, color = borderColor),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = home[:4].upper(), color = homeScoreColor, font = textFont))),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = get_record(homeScore), color = homeScoreColor, font = scoreFont))),
                                            render.Box(width = 1, height = 10, color = borderColor),
                                        ])),
                                    ],
                                ),
                                render.Box(width = 64, height = 1, color = borderColor),
                            ],
                        ),
                    ],
                )

            elif displayType == "horizontal":
                textColor = "#fff"
                backgroundColor = "#000"
                borderColor = "#000"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Box(width = 32, height = 24, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 24, child = render.Image(awayLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 16),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = awayScore, color = awayScoreColor, font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                                render.Box(width = 32, height = 24, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 24, child = render.Image(homeLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 16),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = homeScore, color = homeScoreColor, font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "logos":
                textColor = "#fff"
                backgroundColor = "#000"
                borderColor = "#000"
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(awayLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = awayScore, color = awayScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(homeLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = homeScore, color = homeScoreColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "black":
                textColor = "#fff"
                backgroundColor = "#000"
                borderColor = "#000"
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(
                                                    expanded = True,
                                                    main_align = "start",
                                                    cross_align = "center",
                                                    children = get_logo_column(showRanking, away, awayLogo, awayLogoSize, awayRank, awayScoreColor, textFont, awayScore, scoreFont),
                                                )),
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(
                                                    expanded = True,
                                                    main_align = "start",
                                                    cross_align = "center",
                                                    children = get_logo_column(showRanking, home, homeLogo, homeLogoSize, homeRank, homeScoreColor, textFont, homeScore, scoreFont),
                                                )),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            else:
                textColor = "#fff"
                backgroundColor = "#000"
                borderColor = "#000"
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_date_column(displayTop, now, i, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = awayColor, child = render.Row(
                                                    expanded = True,
                                                    main_align = "start",
                                                    cross_align = "center",
                                                    children = get_logo_column(showRanking, away, awayLogo, awayLogoSize, awayRank, awayScoreColor, textFont, awayScore, scoreFont),
                                                )),
                                                render.Box(width = 64, height = 12, color = homeColor, child = render.Row(
                                                    expanded = True,
                                                    main_align = "start",
                                                    cross_align = "center",
                                                    children = get_logo_column(showRanking, home, homeLogo, homeLogoSize, homeRank, homeScoreColor, textFont, homeScore, scoreFont),
                                                )),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

        return render.Root(
            delay = int(rotationSpeed) * 1000,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Animation(
                        children = renderCategory,
                    ),
                ],
            ),
        )
    else:
        return []

teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "all",
    ),
    schema.Option(
        display = "Abilene Christian",
        value = "315",
    ),
    schema.Option(
        display = "Air Force",
        value = "155",
    ),
    schema.Option(
        display = "Akron",
        value = "316",
    ),
    schema.Option(
        display = "Alabama",
        value = "148",
    ),
    schema.Option(
        display = "Alabama A&M",
        value = "317",
    ),
    schema.Option(
        display = "Alabama State",
        value = "318",
    ),
    schema.Option(
        display = "Albany",
        value = "154",
    ),
    schema.Option(
        display = "Alcorn State",
        value = "260",
    ),
    schema.Option(
        display = "Alma College",
        value = "821",
    ),
    schema.Option(
        display = "American University",
        value = "319",
    ),
    schema.Option(
        display = "Anderson (IN)",
        value = "822",
    ),
    schema.Option(
        display = "Appalachian State",
        value = "271",
    ),
    schema.Option(
        display = "Arizona",
        value = "60",
    ),
    schema.Option(
        display = "Arizona State",
        value = "59",
    ),
    schema.Option(
        display = "Arkansas",
        value = "58",
    ),
    schema.Option(
        display = "Arkansas State",
        value = "320",
    ),
    schema.Option(
        display = "Arkansas-Pine Bluff",
        value = "321",
    ),
    schema.Option(
        display = "Army",
        value = "151",
    ),
    schema.Option(
        display = "Auburn",
        value = "55",
    ),
    schema.Option(
        display = "Austin Peay",
        value = "156",
    ),
    schema.Option(
        display = "BYU",
        value = "127",
    ),
    schema.Option(
        display = "Bacone College",
        value = "823",
    ),
    schema.Option(
        display = "Baker University",
        value = "824",
    ),
    schema.Option(
        display = "Ball State",
        value = "157",
    ),
    schema.Option(
        display = "Barry",
        value = "825",
    ),
    schema.Option(
        display = "Baylor",
        value = "121",
    ),
    schema.Option(
        display = "Bellarmine",
        value = "1143",
    ),
    schema.Option(
        display = "Belmont",
        value = "262",
    ),
    schema.Option(
        display = "Bethany College",
        value = "826",
    ),
    schema.Option(
        display = "Bethune-Cookman",
        value = "158",
    ),
    schema.Option(
        display = "Binghamton",
        value = "292",
    ),
    schema.Option(
        display = "Birmingham Southern",
        value = "56",
    ),
    schema.Option(
        display = "Boise State",
        value = "322",
    ),
    schema.Option(
        display = "Boston College",
        value = "86",
    ),
    schema.Option(
        display = "Boston University",
        value = "323",
    ),
    schema.Option(
        display = "Bowling Green",
        value = "106",
    ),
    schema.Option(
        display = "Bradley",
        value = "324",
    ),
    schema.Option(
        display = "Brown",
        value = "116",
    ),
    schema.Option(
        display = "Bryant",
        value = "299",
    ),
    schema.Option(
        display = "Bucknell",
        value = "313",
    ),
    schema.Option(
        display = "Buffalo",
        value = "325",
    ),
    schema.Option(
        display = "Butler",
        value = "326",
    ),
    schema.Option(
        display = "Cal Poly",
        value = "61",
    ),
    schema.Option(
        display = "Cal Poly-Pomona",
        value = "827",
    ),
    schema.Option(
        display = "Cal State Bakersfield",
        value = "327",
    ),
    schema.Option(
        display = "Cal State Fullerton",
        value = "165",
    ),
    schema.Option(
        display = "Cal State Northridge",
        value = "185",
    ),
    schema.Option(
        display = "California",
        value = "65",
    ),
    schema.Option(
        display = "California Baptist",
        value = "1105",
    ),
    schema.Option(
        display = "Campbell",
        value = "293",
    ),
    schema.Option(
        display = "Canisius",
        value = "298",
    ),
    schema.Option(
        display = "Centenary",
        value = "828",
    ),
    schema.Option(
        display = "Central Arkansas",
        value = "306",
    ),
    schema.Option(
        display = "Central Connecticut",
        value = "159",
    ),
    schema.Option(
        display = "Central Michigan",
        value = "328",
    ),
    schema.Option(
        display = "Central Missouri State",
        value = "829",
    ),
    schema.Option(
        display = "Charleston",
        value = "118",
    ),
    schema.Option(
        display = "Charleston Southern",
        value = "329",
    ),
    schema.Option(
        display = "Charlotte",
        value = "180",
    ),
    schema.Option(
        display = "Chattanooga",
        value = "330",
    ),
    schema.Option(
        display = "Chicago State",
        value = "331",
    ),
    schema.Option(
        display = "Cincinnati",
        value = "161",
    ),
    schema.Option(
        display = "Clemson",
        value = "117",
    ),
    schema.Option(
        display = "Cleveland State",
        value = "332",
    ),
    schema.Option(
        display = "Coastal Carolina",
        value = "146",
    ),
    schema.Option(
        display = "Coe College",
        value = "1248",
    ),
    schema.Option(
        display = "Colgate",
        value = "333",
    ),
    schema.Option(
        display = "Colorado",
        value = "334",
    ),
    schema.Option(
        display = "Colorado State",
        value = "335",
    ),
    schema.Option(
        display = "Columbia",
        value = "284",
    ),
    schema.Option(
        display = "Concordia St Paul",
        value = "1067",
    ),
    schema.Option(
        display = "Coppin State",
        value = "162",
    ),
    schema.Option(
        display = "Cornell",
        value = "336",
    ),
    schema.Option(
        display = "Creighton",
        value = "98",
    ),
    schema.Option(
        display = "Dallas Baptist",
        value = "263",
    ),
    schema.Option(
        display = "Dartmouth",
        value = "100",
    ),
    schema.Option(
        display = "Davidson",
        value = "337",
    ),
    schema.Option(
        display = "Dayton",
        value = "338",
    ),
    schema.Option(
        display = "DePaul",
        value = "342",
    ),
    schema.Option(
        display = "Delaware",
        value = "339",
    ),
    schema.Option(
        display = "Delaware State",
        value = "340",
    ),
    schema.Option(
        display = "Denver",
        value = "341",
    ),
    schema.Option(
        display = "Detroit Mercy",
        value = "343",
    ),
    schema.Option(
        display = "Drake",
        value = "344",
    ),
    schema.Option(
        display = "Drexel",
        value = "345",
    ),
    schema.Option(
        display = "Duke",
        value = "93",
    ),
    schema.Option(
        display = "Duquesne",
        value = "346",
    ),
    schema.Option(
        display = "East Carolina",
        value = "94",
    ),
    schema.Option(
        display = "East Tennessee State",
        value = "304",
    ),
    schema.Option(
        display = "Eastern Illinois",
        value = "347",
    ),
    schema.Option(
        display = "Eastern Kentucky",
        value = "348",
    ),
    schema.Option(
        display = "Eastern Michigan",
        value = "349",
    ),
    schema.Option(
        display = "Eastern Washington",
        value = "350",
    ),
    schema.Option(
        display = "Elon",
        value = "303",
    ),
    schema.Option(
        display = "Emporia State",
        value = "830",
    ),
    schema.Option(
        display = "Evansville",
        value = "149",
    ),
    schema.Option(
        display = "Fairfield",
        value = "351",
    ),
    schema.Option(
        display = "Fairleigh Dickinson",
        value = "352",
    ),
    schema.Option(
        display = "Florida",
        value = "75",
    ),
    schema.Option(
        display = "Florida A&M",
        value = "353",
    ),
    schema.Option(
        display = "Florida Atlantic",
        value = "163",
    ),
    schema.Option(
        display = "Florida Gulf Coast",
        value = "291",
    ),
    schema.Option(
        display = "Florida International",
        value = "164",
    ),
    schema.Option(
        display = "Florida State",
        value = "72",
    ),
    schema.Option(
        display = "Fordham",
        value = "354",
    ),
    schema.Option(
        display = "Francis Marion",
        value = "831",
    ),
    schema.Option(
        display = "Fresno State",
        value = "137",
    ),
    schema.Option(
        display = "Furman",
        value = "355",
    ),
    schema.Option(
        display = "Gardner-Webb",
        value = "356",
    ),
    schema.Option(
        display = "George Mason",
        value = "166",
    ),
    schema.Option(
        display = "George Washington",
        value = "71",
    ),
    schema.Option(
        display = "Georgetown",
        value = "357",
    ),
    schema.Option(
        display = "Georgia",
        value = "78",
    ),
    schema.Option(
        display = "Georgia Southern",
        value = "138",
    ),
    schema.Option(
        display = "Georgia State",
        value = "358",
    ),
    schema.Option(
        display = "Georgia Tech",
        value = "77",
    ),
    schema.Option(
        display = "Gonzaga",
        value = "287",
    ),
    schema.Option(
        display = "Grambling",
        value = "359",
    ),
    schema.Option(
        display = "Grand Canyon",
        value = "360",
    ),
    schema.Option(
        display = "Grand View",
        value = "1190",
    ),
    schema.Option(
        display = "Green Bay",
        value = "361",
    ),
    schema.Option(
        display = "Hampton",
        value = "362",
    ),
    schema.Option(
        display = "Hartford",
        value = "70",
    ),
    schema.Option(
        display = "Harvard",
        value = "363",
    ),
    schema.Option(
        display = "Hawai'i",
        value = "79",
    ),
    schema.Option(
        display = "Hawaii Pacific",
        value = "832",
    ),
    schema.Option(
        display = "Hawaii-Hilo",
        value = "847",
    ),
    schema.Option(
        display = "High Point",
        value = "364",
    ),
    schema.Option(
        display = "Hofstra",
        value = "365",
    ),
    schema.Option(
        display = "Holy Cross",
        value = "366",
    ),
    schema.Option(
        display = "Houston",
        value = "124",
    ),
    schema.Option(
        display = "Houston Christian",
        value = "367",
    ),
    schema.Option(
        display = "Howard",
        value = "368",
    ),
    schema.Option(
        display = "IUPUI",
        value = "375",
    ),
    schema.Option(
        display = "Idaho",
        value = "369",
    ),
    schema.Option(
        display = "Idaho State",
        value = "370",
    ),
    schema.Option(
        display = "Illinois",
        value = "153",
    ),
    schema.Option(
        display = "Illinois State",
        value = "288",
    ),
    schema.Option(
        display = "Incarnate Word",
        value = "371",
    ),
    schema.Option(
        display = "Indiana",
        value = "294",
    ),
    schema.Option(
        display = "Indiana State",
        value = "308",
    ),
    schema.Option(
        display = "Iona",
        value = "372",
    ),
    schema.Option(
        display = "Iowa",
        value = "167",
    ),
    schema.Option(
        display = "Iowa State",
        value = "373",
    ),
    schema.Option(
        display = "Jackson State",
        value = "285",
    ),
    schema.Option(
        display = "Jacksonville",
        value = "139",
    ),
    schema.Option(
        display = "Jacksonville State",
        value = "73",
    ),
    schema.Option(
        display = "James Madison",
        value = "129",
    ),
    schema.Option(
        display = "Kansas",
        value = "168",
    ),
    schema.Option(
        display = "Kansas City",
        value = "451",
    ),
    schema.Option(
        display = "Kansas State",
        value = "264",
    ),
    schema.Option(
        display = "Kennesaw State",
        value = "307",
    ),
    schema.Option(
        display = "Kent State",
        value = "169",
    ),
    schema.Option(
        display = "Kentucky",
        value = "82",
    ),
    schema.Option(
        display = "LSU",
        value = "85",
    ),
    schema.Option(
        display = "La Salle",
        value = "376",
    ),
    schema.Option(
        display = "Lafayette",
        value = "145",
    ),
    schema.Option(
        display = "Lamar",
        value = "170",
    ),
    schema.Option(
        display = "Le Moyne",
        value = "171",
    ),
    schema.Option(
        display = "Lehigh",
        value = "377",
    ),
    schema.Option(
        display = "Lenoir-Rhyne",
        value = "833",
    ),
    schema.Option(
        display = "Liberty",
        value = "172",
    ),
    schema.Option(
        display = "Lincoln",
        value = "834",
    ),
    schema.Option(
        display = "Lindenwood",
        value = "926",
    ),
    schema.Option(
        display = "Linfield",
        value = "1247",
    ),
    schema.Option(
        display = "Lipscomb",
        value = "378",
    ),
    schema.Option(
        display = "Little Rock",
        value = "261",
    ),
    schema.Option(
        display = "Long Beach State",
        value = "141",
    ),
    schema.Option(
        display = "Long Island University",
        value = "379",
    ),
    schema.Option(
        display = "Longwood",
        value = "380",
    ),
    schema.Option(
        display = "Loras College",
        value = "1189",
    ),
    schema.Option(
        display = "Louisiana",
        value = "144",
    ),
    schema.Option(
        display = "Louisiana College",
        value = "835",
    ),
    schema.Option(
        display = "Louisiana Tech",
        value = "173",
    ),
    schema.Option(
        display = "Louisville",
        value = "83",
    ),
    schema.Option(
        display = "Loyola Chicago",
        value = "381",
    ),
    schema.Option(
        display = "Loyola Maryland",
        value = "382",
    ),
    schema.Option(
        display = "Loyola Marymount",
        value = "174",
    ),
    schema.Option(
        display = "Lubbock Christian",
        value = "836",
    ),
    schema.Option(
        display = "Maine",
        value = "259",
    ),
    schema.Option(
        display = "Manhattan",
        value = "265",
    ),
    schema.Option(
        display = "Marist",
        value = "175",
    ),
    schema.Option(
        display = "Marquette",
        value = "383",
    ),
    schema.Option(
        display = "Marshall",
        value = "384",
    ),
    schema.Option(
        display = "Maryland",
        value = "87",
    ),
    schema.Option(
        display = "Maryland-Eastern Shore",
        value = "385",
    ),
    schema.Option(
        display = "McNeese",
        value = "387",
    ),
    schema.Option(
        display = "Memphis",
        value = "119",
    ),
    schema.Option(
        display = "Mercer",
        value = "295",
    ),
    schema.Option(
        display = "Merrimack",
        value = "1148",
    ),
    schema.Option(
        display = "Miami",
        value = "176",
    ),
    schema.Option(
        display = "Miami (OH)",
        value = "107",
    ),
    schema.Option(
        display = "Michigan",
        value = "89",
    ),
    schema.Option(
        display = "Michigan State",
        value = "88",
    ),
    schema.Option(
        display = "Mid-America Christian U",
        value = "837",
    ),
    schema.Option(
        display = "Middle Tennessee",
        value = "177",
    ),
    schema.Option(
        display = "Milwaukee",
        value = "135",
    ),
    schema.Option(
        display = "Minnesota",
        value = "90",
    ),
    schema.Option(
        display = "Mississippi State",
        value = "150",
    ),
    schema.Option(
        display = "Mississippi Valley State",
        value = "388",
    ),
    schema.Option(
        display = "Missouri",
        value = "91",
    ),
    schema.Option(
        display = "Missouri State",
        value = "197",
    ),
    schema.Option(
        display = "Monmouth",
        value = "178",
    ),
    schema.Option(
        display = "Montana",
        value = "389",
    ),
    schema.Option(
        display = "Montana State",
        value = "390",
    ),
    schema.Option(
        display = "Morehead State",
        value = "391",
    ),
    schema.Option(
        display = "Morgan State",
        value = "392",
    ),
    schema.Option(
        display = "Mount St. Mary's",
        value = "393",
    ),
    schema.Option(
        display = "Murray State",
        value = "394",
    ),
    schema.Option(
        display = "NC State",
        value = "95",
    ),
    schema.Option(
        display = "NJIT",
        value = "395",
    ),
    schema.Option(
        display = "NY Institute of Technology",
        value = "838",
    ),
    schema.Option(
        display = "Navy",
        value = "179",
    ),
    schema.Option(
        display = "Nebraska",
        value = "99",
    ),
    schema.Option(
        display = "Nebraska-Kearney",
        value = "849",
    ),
    schema.Option(
        display = "Nevada",
        value = "183",
    ),
    schema.Option(
        display = "New Hampshire",
        value = "397",
    ),
    schema.Option(
        display = "New Mexico",
        value = "104",
    ),
    schema.Option(
        display = "New Mexico State",
        value = "103",
    ),
    schema.Option(
        display = "New Orleans",
        value = "184",
    ),
    schema.Option(
        display = "Niagara",
        value = "398",
    ),
    schema.Option(
        display = "Nicholls",
        value = "399",
    ),
    schema.Option(
        display = "Norfolk State",
        value = "400",
    ),
    schema.Option(
        display = "North Alabama",
        value = "1103",
    ),
    schema.Option(
        display = "North Carolina",
        value = "96",
    ),
    schema.Option(
        display = "North Carolina A&T",
        value = "401",
    ),
    schema.Option(
        display = "North Carolina Central",
        value = "402",
    ),
    schema.Option(
        display = "North Dakota",
        value = "403",
    ),
    schema.Option(
        display = "North Dakota State",
        value = "310",
    ),
    schema.Option(
        display = "North Florida",
        value = "296",
    ),
    schema.Option(
        display = "North Georgia",
        value = "839",
    ),
    schema.Option(
        display = "North Texas",
        value = "404",
    ),
    schema.Option(
        display = "Northeastern",
        value = "405",
    ),
    schema.Option(
        display = "Northern Arizona",
        value = "406",
    ),
    schema.Option(
        display = "Northern Colorado",
        value = "407",
    ),
    schema.Option(
        display = "Northern Illinois",
        value = "408",
    ),
    schema.Option(
        display = "Northern Iowa",
        value = "409",
    ),
    schema.Option(
        display = "Northern Kentucky",
        value = "410",
    ),
    schema.Option(
        display = "Northwestern",
        value = "411",
    ),
    schema.Option(
        display = "Northwestern (IA)",
        value = "840",
    ),
    schema.Option(
        display = "Northwestern State",
        value = "186",
    ),
    schema.Option(
        display = "Notre Dame",
        value = "81",
    ),
    schema.Option(
        display = "Oakland",
        value = "412",
    ),
    schema.Option(
        display = "Ohio",
        value = "109",
    ),
    schema.Option(
        display = "Ohio State",
        value = "108",
    ),
    schema.Option(
        display = "Oklahoma",
        value = "112",
    ),
    schema.Option(
        display = "Oklahoma State",
        value = "110",
    ),
    schema.Option(
        display = "Old Dominion",
        value = "140",
    ),
    schema.Option(
        display = "Ole Miss",
        value = "92",
    ),
    schema.Option(
        display = "Omaha",
        value = "396",
    ),
    schema.Option(
        display = "Oral Roberts",
        value = "111",
    ),
    schema.Option(
        display = "Oregon",
        value = "273",
    ),
    schema.Option(
        display = "Oregon State",
        value = "113",
    ),
    schema.Option(
        display = "Pacific",
        value = "413",
    ),
    schema.Option(
        display = "Penn State",
        value = "414",
    ),
    schema.Option(
        display = "Pennsylvania",
        value = "415",
    ),
    schema.Option(
        display = "Pepperdine",
        value = "187",
    ),
    schema.Option(
        display = "Pittsburgh",
        value = "115",
    ),
    schema.Option(
        display = "Portland",
        value = "416",
    ),
    schema.Option(
        display = "Portland State",
        value = "417",
    ),
    schema.Option(
        display = "Prairie View A&M",
        value = "188",
    ),
    schema.Option(
        display = "Presbyterian",
        value = "418",
    ),
    schema.Option(
        display = "Princeton",
        value = "101",
    ),
    schema.Option(
        display = "Providence",
        value = "419",
    ),
    schema.Option(
        display = "Purdue",
        value = "189",
    ),
    schema.Option(
        display = "Purdue Fort Wayne",
        value = "374",
    ),
    schema.Option(
        display = "Queens University",
        value = "1238",
    ),
    schema.Option(
        display = "Quinnipiac",
        value = "420",
    ),
    schema.Option(
        display = "Radford",
        value = "421",
    ),
    schema.Option(
        display = "Rhode Island",
        value = "422",
    ),
    schema.Option(
        display = "Rice",
        value = "122",
    ),
    schema.Option(
        display = "Richmond",
        value = "130",
    ),
    schema.Option(
        display = "Rider",
        value = "423",
    ),
    schema.Option(
        display = "Robert Morris",
        value = "424",
    ),
    schema.Option(
        display = "Rutgers",
        value = "102",
    ),
    schema.Option(
        display = "SE Louisiana",
        value = "309",
    ),
    schema.Option(
        display = "SIU Edwardsville",
        value = "429",
    ),
    schema.Option(
        display = "SMU",
        value = "433",
    ),
    schema.Option(
        display = "Sacramento State",
        value = "314",
    ),
    schema.Option(
        display = "Sacred Heart",
        value = "266",
    ),
    schema.Option(
        display = "Saint Joseph's",
        value = "425",
    ),
    schema.Option(
        display = "Saint Louis",
        value = "300",
    ),
    schema.Option(
        display = "Saint Mary's",
        value = "426",
    ),
    schema.Option(
        display = "Saint Peter's",
        value = "437",
    ),
    schema.Option(
        display = "Salisbury University",
        value = "841",
    ),
    schema.Option(
        display = "Sam Houston",
        value = "190",
    ),
    schema.Option(
        display = "Samford",
        value = "274",
    ),
    schema.Option(
        display = "San Diego",
        value = "143",
    ),
    schema.Option(
        display = "San Diego State",
        value = "62",
    ),
    schema.Option(
        display = "San Francisco",
        value = "267",
    ),
    schema.Option(
        display = "San Jose State",
        value = "63",
    ),
    schema.Option(
        display = "Santa Clara",
        value = "427",
    ),
    schema.Option(
        display = "Savannah State",
        value = "286",
    ),
    schema.Option(
        display = "Seattle U",
        value = "428",
    ),
    schema.Option(
        display = "Seton Hall",
        value = "268",
    ),
    schema.Option(
        display = "Siena",
        value = "311",
    ),
    schema.Option(
        display = "South Alabama",
        value = "57",
    ),
    schema.Option(
        display = "South Carolina",
        value = "193",
    ),
    schema.Option(
        display = "South Carolina State",
        value = "430",
    ),
    schema.Option(
        display = "South Carolina Upstate",
        value = "453",
    ),
    schema.Option(
        display = "South Dakota",
        value = "431",
    ),
    schema.Option(
        display = "South Dakota State",
        value = "301",
    ),
    schema.Option(
        display = "South Florida",
        value = "76",
    ),
    schema.Option(
        display = "Southeast Missouri State",
        value = "191",
    ),
    schema.Option(
        display = "Southern",
        value = "194",
    ),
    schema.Option(
        display = "Southern Illinois",
        value = "432",
    ),
    schema.Option(
        display = "Southern Indiana",
        value = "1246",
    ),
    schema.Option(
        display = "Southern Miss",
        value = "192",
    ),
    schema.Option(
        display = "Southern Utah",
        value = "434",
    ),
    schema.Option(
        display = "Southwestern Oklahoma",
        value = "842",
    ),
    schema.Option(
        display = "St. Bonaventure",
        value = "105",
    ),
    schema.Option(
        display = "St. Francis (BKN)",
        value = "435",
    ),
    schema.Option(
        display = "St. Francis (PA)",
        value = "436",
    ),
    schema.Option(
        display = "St. Gregory",
        value = "843",
    ),
    schema.Option(
        display = "St. John's",
        value = "195",
    ),
    schema.Option(
        display = "St. Martin's",
        value = "844",
    ),
    schema.Option(
        display = "St. Thomas - Minnesota",
        value = "850",
    ),
    schema.Option(
        display = "Stanford",
        value = "64",
    ),
    schema.Option(
        display = "Stephen F. Austin",
        value = "438",
    ),
    schema.Option(
        display = "Stetson",
        value = "74",
    ),
    schema.Option(
        display = "Stonehill",
        value = "1245",
    ),
    schema.Option(
        display = "Stony Brook",
        value = "196",
    ),
    schema.Option(
        display = "Syracuse",
        value = "439",
    ),
    schema.Option(
        display = "TBD",
        value = "1153",
    ),
    schema.Option(
        display = "TBD",
        value = "1154",
    ),
    schema.Option(
        display = "TCU",
        value = "198",
    ),
    schema.Option(
        display = "Tabor College",
        value = "845",
    ),
    schema.Option(
        display = "Tarleton",
        value = "1145",
    ),
    schema.Option(
        display = "Temple",
        value = "114",
    ),
    schema.Option(
        display = "Tennessee",
        value = "199",
    ),
    schema.Option(
        display = "Tennessee State",
        value = "440",
    ),
    schema.Option(
        display = "Tennessee Tech",
        value = "441",
    ),
    schema.Option(
        display = "Texas",
        value = "126",
    ),
    schema.Option(
        display = "Texas A&M",
        value = "123",
    ),
    schema.Option(
        display = "Texas A&M-Corpus Christi",
        value = "443",
    ),
    schema.Option(
        display = "Texas Lutheran",
        value = "846",
    ),
    schema.Option(
        display = "Texas Southern",
        value = "200",
    ),
    schema.Option(
        display = "Texas State",
        value = "147",
    ),
    schema.Option(
        display = "Texas Tech",
        value = "201",
    ),
    schema.Option(
        display = "Texas-Pan American",
        value = "444",
    ),
    schema.Option(
        display = "The Citadel",
        value = "202",
    ),
    schema.Option(
        display = "Toledo",
        value = "445",
    ),
    schema.Option(
        display = "Towson",
        value = "305",
    ),
    schema.Option(
        display = "Troy",
        value = "269",
    ),
    schema.Option(
        display = "Tulane",
        value = "203",
    ),
    schema.Option(
        display = "Tulsa",
        value = "446",
    ),
    schema.Option(
        display = "UAB",
        value = "447",
    ),
    schema.Option(
        display = "UC Davis",
        value = "448",
    ),
    schema.Option(
        display = "UC Irvine",
        value = "142",
    ),
    schema.Option(
        display = "UC Riverside",
        value = "67",
    ),
    schema.Option(
        display = "UC San Diego",
        value = "1147",
    ),
    schema.Option(
        display = "UC Santa Barbara",
        value = "290",
    ),
    schema.Option(
        display = "UCF",
        value = "160",
    ),
    schema.Option(
        display = "UCLA",
        value = "66",
    ),
    schema.Option(
        display = "UConn",
        value = "69",
    ),
    schema.Option(
        display = "UIC",
        value = "80",
    ),
    schema.Option(
        display = "UL Monroe",
        value = "272",
    ),
    schema.Option(
        display = "UMBC",
        value = "450",
    ),
    schema.Option(
        display = "UMass",
        value = "386",
    ),
    schema.Option(
        display = "UMass Lowell",
        value = "449",
    ),
    schema.Option(
        display = "UNC Asheville",
        value = "452",
    ),
    schema.Option(
        display = "UNC Greensboro",
        value = "181",
    ),
    schema.Option(
        display = "UNC Wilmington",
        value = "152",
    ),
    schema.Option(
        display = "UNLV",
        value = "182",
    ),
    schema.Option(
        display = "USC",
        value = "68",
    ),
    schema.Option(
        display = "UT Arlington",
        value = "125",
    ),
    schema.Option(
        display = "UT Martin",
        value = "442",
    ),
    schema.Option(
        display = "UT Rio Grande Valley",
        value = "932",
    ),
    schema.Option(
        display = "UTEP",
        value = "456",
    ),
    schema.Option(
        display = "UTSA",
        value = "297",
    ),
    schema.Option(
        display = "Upper Iowa",
        value = "1239",
    ),
    schema.Option(
        display = "Utah",
        value = "128",
    ),
    schema.Option(
        display = "Utah State",
        value = "454",
    ),
    schema.Option(
        display = "Utah Tech",
        value = "1146",
    ),
    schema.Option(
        display = "Utah Valley",
        value = "455",
    ),
    schema.Option(
        display = "VCU",
        value = "204",
    ),
    schema.Option(
        display = "VMI",
        value = "459",
    ),
    schema.Option(
        display = "Valdosta State",
        value = "851",
    ),
    schema.Option(
        display = "Valparaiso",
        value = "302",
    ),
    schema.Option(
        display = "Vanderbilt",
        value = "120",
    ),
    schema.Option(
        display = "Vermont",
        value = "457",
    ),
    schema.Option(
        display = "Villanova",
        value = "458",
    ),
    schema.Option(
        display = "Virginia",
        value = "131",
    ),
    schema.Option(
        display = "Virginia Tech",
        value = "132",
    ),
    schema.Option(
        display = "Wagner",
        value = "460",
    ),
    schema.Option(
        display = "Wake Forest",
        value = "97",
    ),
    schema.Option(
        display = "Washington",
        value = "133",
    ),
    schema.Option(
        display = "Washington State",
        value = "134",
    ),
    schema.Option(
        display = "Wayne State (NE)",
        value = "852",
    ),
    schema.Option(
        display = "Weber State",
        value = "461",
    ),
    schema.Option(
        display = "West Virginia",
        value = "136",
    ),
    schema.Option(
        display = "Western Carolina",
        value = "205",
    ),
    schema.Option(
        display = "Western Illinois",
        value = "462",
    ),
    schema.Option(
        display = "Western Kentucky",
        value = "84",
    ),
    schema.Option(
        display = "Western Michigan",
        value = "463",
    ),
    schema.Option(
        display = "Wichita State",
        value = "206",
    ),
    schema.Option(
        display = "William & Mary",
        value = "289",
    ),
    schema.Option(
        display = "William Woods",
        value = "853",
    ),
    schema.Option(
        display = "Winthrop",
        value = "207",
    ),
    schema.Option(
        display = "Wisconsin",
        value = "464",
    ),
    schema.Option(
        display = "Wofford",
        value = "208",
    ),
    schema.Option(
        display = "Wright State",
        value = "270",
    ),
    schema.Option(
        display = "Wyoming",
        value = "465",
    ),
    schema.Option(
        display = "Xavier",
        value = "312",
    ),
    schema.Option(
        display = "Yale",
        value = "466",
    ),
    schema.Option(
        display = "Youngstown State",
        value = "209",
    ),
]

rotationOptions = [
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
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

displayOptions = [
    schema.Option(
        display = "Team Colors",
        value = "colors",
    ),
    schema.Option(
        display = "Black",
        value = "black",
    ),
    schema.Option(
        display = "Logos",
        value = "logos",
    ),
    schema.Option(
        display = "Horizontal",
        value = "horizontal",
    ),
    schema.Option(
        display = "Stadium",
        value = "stadium",
    ),
    schema.Option(
        display = "Retro",
        value = "retro",
    ),
]

pregameOptions = [
    schema.Option(
        display = "Team Record",
        value = "record",
    ),
    schema.Option(
        display = "Gambling Odds",
        value = "odds",
    ),
    schema.Option(
        display = "Nothing",
        value = "nothing",
    ),
]

displayTopOptions = [
    schema.Option(
        display = "League Name",
        value = "league",
    ),
    schema.Option(
        display = "Current Time",
        value = "time",
    ),
    schema.Option(
        display = "Game Info Only",
        value = "gameinfo",
    ),
]

colorOptions = [
    schema.Option(
        display = "White",
        value = "#FFF",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FF0",
    ),
    schema.Option(
        display = "Red",
        value = "#F00",
    ),
    schema.Option(
        display = "Blue",
        value = "#00F",
    ),
    schema.Option(
        display = "Green",
        value = "#0F0",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "selectedTeam",
                name = "Team Focus",
                desc = "Only show scores for selected team.",
                icon = "gear",
                default = teamOptions[0].value,
                options = teamOptions,
            ),
            schema.Toggle(
                id = "displayRanking",
                name = "Show Top 25 Rank",
                desc = "A toggle to display the top 25 ranking.",
                icon = "trophy",
                default = True,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gear",
                default = rotationOptions[2].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "gear",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
            schema.Dropdown(
                id = "pregameDisplay",
                name = "Pre-Game",
                desc = "What to display in the score area if the game hasn't started.",
                icon = "gear",
                default = pregameOptions[0].value,
                options = pregameOptions,
            ),
            schema.Dropdown(
                id = "displayTop",
                name = "Top Display",
                desc = "A toggle of what to display on the top shelf.",
                icon = "gear",
                default = displayTopOptions[0].value,
                options = displayTopOptions,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Top Display Color",
                desc = "Select which color you want the top display to be.",
                icon = "gear",
                default = colorOptions[5].value,
                options = colorOptions,
            ),
        ],
    )

def get_scores(urls, team):
    allscores = []
    gameCount = 0
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        if team != "all" and team != "":
            newScores = []
            for _, s in enumerate(allscores):
                home = s["competitions"][0]["competitors"][0]["team"]["id"]
                away = s["competitions"][0]["competitors"][1]["team"]["id"]
                gameStatus = s["status"]["type"]["state"]
                if (home == team or away == team) and gameStatus == "post":
                    newScores.append(s)
                elif (home == team or away == team) and gameCount == 0:
                    if gameStatus == "in":
                        newScores.clear()
                    newScores.append(s)
                    gameCount = gameCount + 1
            allscores = newScores
        all([i, allscores])
    return allscores

def empty_scores(allscores):
    for _ in range(0, int(len(allscores))):
        allscores.pop()
    return allscores

def get_odds(theOdds, theOU, team, homeaway):
    theOddsarray = theOdds.split(" ")
    usealtname = json.decode(ODDS_NAME)
    usealt = usealtname.get(team, "NO")
    if usealt == "NO":
        team = team
    else:
        team = usealtname[team]
    if theOdds == "EVEN" and homeaway == "home":
        theOddsscore = "EVEN"
    elif theOddsarray[0] == team:
        theOddsarray = theOdds.split(" ")
        theOddsscore = theOddsarray[1]
    else:
        theOddsscore = theOU
    return theOddsscore

def get_detail(gamedate):
    finddash = gamedate.find("-")
    if finddash > 0:
        gameTimearray = gamedate.split(" - ")
        gameTimeval = gameTimearray[1]
    else:
        gameTimeval = gamedate
    return gameTimeval

def get_team_name(name):
    if len(name) > 9:
        theName = name[:8] + "_"
    else:
        theName = name
    return theName.upper()

def get_record(record):
    if len(record) > 6:
        theRecord = record[:5] + "_"
    else:
        theRecord = record
    return theRecord

def get_background_color(team, displayType, color):
    altcolors = json.decode(ALT_COLOR)
    usealt = altcolors.get(team, "NO")
    if displayType == "black" or displayType == "retro":
        color = "#222"
    elif usealt != "NO":
        color = altcolors[team]
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#222"
    return color

def get_logoType(team, logo):
    usealtlogo = json.decode(ALT_LOGO)
    usealt = usealtlogo.get(team, "NO")
    if usealt != "NO":
        logo = get_cachable_data(usealt, 36000)
    else:
        logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
        logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
        logo = get_cachable_data(logo + "&h=50&w=50")
    return logo

def get_logoSize(team):
    usealtsize = json.decode(MAGNIFY_LOGO)
    usealt = usealtsize.get(team, "NO")
    if usealt != "NO":
        logosize = int(usealtsize[team])
    else:
        logosize = int(16)
    return logosize

def get_date_column(displayTop, now, scoreNumber, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor):
    if displayTop == "gameinfo":
        dateTimeColumn = [
            render.Box(width = 64, height = 8, child = render.Stack(children = [
                render.Box(width = 64, height = 8, color = displayType == "stadium" and borderColor or "#000"),
                render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                    render.Text(color = displayType == "retro" and textColor or timeColor, content = gameTime, font = "CG-pixel-3x5-mono"),
                ])),
            ])),
        ]
    else:
        timeBox = 20
        statusBox = 44
        if displayTop == "league":
            theTime = LEAGUE_DISPLAY
            timeBox += LEAGUE_DISPLAY_OFFSET
            statusBox -= LEAGUE_DISPLAY_OFFSET
        else:
            now = now + time.parse_duration("%ds" % int(scoreNumber) * int(rotationSpeed))
            theTime = now.format("3:04")
            if len(str(theTime)) > 4:
                timeBox += 4
                statusBox -= 4
        dateTimeColumn = [
            render.Box(width = timeBox, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Box(width = 1, height = 8),
                render.Text(color = displayType == "retro" and textColor or timeColor, content = theTime, font = "tb-8"),
            ])),
            render.Box(width = statusBox, height = 8, child = render.Stack(children = [
                render.Box(width = statusBox, height = 8, color = displayType == "stadium" and borderColor or "#000"),
                render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                    render.Text(color = textColor, content = get_shortened_display(gameTime), font = "CG-pixel-3x5-mono"),
                ])),
            ])),
        ]
    return dateTimeColumn

def get_shortened_display(text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    words = json.decode(SHORTENED_WORDS)
    for _, s in enumerate(words):
        text = text.replace(s, words[s])
    return text

def get_logo_column(showRanking, team, Logo, LogoSize, Rank, ScoreColor, textFont, Score, scoreFont):
    if showRanking and Rank > 0 and Rank < 26:
        if Rank < 10:
            rankSize = 4
        else:
            rankSize = 8
        gameTimeColumn = [
            render.Stack(children = [
                render.Box(width = 16, height = 12, child = render.Image(Logo, width = LogoSize, height = LogoSize)),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    cross_align = "start",
                    children = [
                        render.Row(children = [
                            render.Box(width = 1, height = 5, color = "#000b"),
                            render.Box(width = rankSize, height = 5, color = "#000b", child = render.Text(str(Rank), color = ScoreColor, font = "CG-pixel-3x5-mono")),
                        ]),
                    ],
                ),
            ]),
            render.Box(width = 24, height = 12, child = render.Text(content = team[:4], color = ScoreColor, font = textFont)),
            render.Box(width = 24, height = 12, child = render.Text(content = get_record(Score), color = ScoreColor, font = scoreFont)),
        ]
    else:
        gameTimeColumn = [
            render.Box(width = 16, height = 12, child = render.Image(Logo, width = LogoSize, height = LogoSize)),
            render.Box(width = 24, height = 12, child = render.Text(content = team[:4], color = ScoreColor, font = textFont)),
            render.Box(width = 24, height = 12, child = render.Text(content = get_record(Score), color = ScoreColor, font = scoreFont)),
        ]
    return gameTimeColumn

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()

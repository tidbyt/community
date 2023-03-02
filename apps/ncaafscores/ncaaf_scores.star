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
LEAGUE_DISPLAY = "NCAAF"
LEAGUE_DISPLAY_OFFSET = 6
SPORT = "football"
LEAGUE = "college-football"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/scoreboard"
SHORTENED_WORDS = """
{
    " PM": "P",
    " AM": "A",
    " - ": " ",
    " / ": " ",
    " of": "",
    "Postponed": "PPD",
    "Overtime": "OT",
    "1st Half": "1H",
    "2nd Half": "2H",
    "1st Quarter": "Q1",
    "2nd Quarter": "Q2",
    "3rd Quarter": "Q3",
    "4th Quarter": "Q4"
}
"""
ALT_COLOR = """
{
    "SYR" : "#000E54",
    "LSU" : "#461D7C",
    "WAKE" : "#000000",
    "UVA" : "#232D4B",
    "WVU" : "#002855",
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
    "HP": "#330072"
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
    "WVU" : "https://b.fssta.com/uploads/application/college/team-logos/WestVirginia-alternate.vresize.50.50.medium.1.png",
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
    "KSU" : "https://b.fssta.com/uploads/application/college/team-logos/KansasState-alternate.vresize.50.50.medium.1.png",
    "ILL" : "https://b.fssta.com/uploads/application/college/team-logos/Illinois-alternate.vresize.50.50.medium.1.png",
    "NEB" : "https://b.fssta.com/uploads/application/college/team-logos/Nebraska-alternate.vresize.50.50.medium.1.png",
    "NU" : "https://b.fssta.com/uploads/application/college/team-logos/Northwestern-alternate.vresize.50.50.medium.1.png",
    "MSU" : "https://b.fssta.com/uploads/application/college/team-logos/MichiganState-alternate.vresize.50.50.medium.1.png",
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
    "UK" : "https://b.fssta.com/uploads/application/college/team-logos/Kentucky-alternate.vresize.50.50.medium.0.png",
    "WASH" : "https://b.fssta.com/uploads/application/college/team-logos/Washington-alternate.vresize.50.50.medium.0.png",
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
    "TLSA": "https://b.fssta.com/uploads/application/college/team-logos/Tulsa-alternate.vresize.50.50.medium.0.png",
    "HP": "https://b.fssta.com/uploads/application/college/team-logos/HighPoint.vresize.50.50.medium.0.png"
}
"""
MAGNIFY_LOGO = """
{
    "WVU" : 12,
    "RUTG" : 12,
    "DUKE" : 12,
    "UNT" : 14,
    "HOU" : 14,
    "USF" : 14,
    "OU" : 14,
    "KSU" : 14,
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
    "KSU" : "KANSASST",
    "OKST" : "OKLAST",
    "MSU" : "MICHIGANST",
    "UL" : "ULLAFAYTTE",
    "ORST" : "OREGONST",
    "MSST" : "MISSSTATE"
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
    conferenceType = config.get("conferenceType", "0")
    if conferenceType == "0":
        apiURL = API + "?limit=300"
    else:
        apiURL = API + "?limit=300&groups=" + conferenceType
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    datePast = now - time.parse_duration("%dh" % 1 * 24)
    dateFuture = now + time.parse_duration("%dh" % 6 * 24)
    league = {LEAGUE: apiURL + (selectedTeam == "all" and " " or "&dates=" + datePast.format("20060102") + "-" + dateFuture.format("20060102"))}
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
                        checkRecord = homeCompetitor.get("records", "NO")
                        if checkRecord == "NO":
                            homeScore = "0-0"
                            awayScore = "0-0"
                        else:
                            homeScore = competition["competitors"][0]["records"][0]["summary"]
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

conferenceOptions = [
    schema.Option(
        display = "Top 25",
        value = "0",
    ),
    schema.Option(
        display = "FBS (I-A)",
        value = "80",
    ),
    schema.Option(
        display = "ACC",
        value = "1",
    ),
    schema.Option(
        display = "American",
        value = "151",
    ),
    schema.Option(
        display = "Big 12",
        value = "4",
    ),
    schema.Option(
        display = "Big Ten",
        value = "5",
    ),
    schema.Option(
        display = "C-USA",
        value = "12",
    ),
    schema.Option(
        display = "FBS Indep.",
        value = "18",
    ),
    schema.Option(
        display = "MAC",
        value = "15",
    ),
    schema.Option(
        display = "Mountain West",
        value = "17",
    ),
    schema.Option(
        display = "Pac-12",
        value = "9",
    ),
    schema.Option(
        display = "SEC",
        value = "8",
    ),
    schema.Option(
        display = "Sun Belt",
        value = "37",
    ),
    schema.Option(
        display = "FCS (I-AA)",
        value = "81",
    ),
    schema.Option(
        display = "ASUN",
        value = "176",
    ),
    schema.Option(
        display = "Big Sky",
        value = "20",
    ),
    schema.Option(
        display = "Big South",
        value = "40",
    ),
    schema.Option(
        display = "CAA",
        value = "48",
    ),
    schema.Option(
        display = "Ivy",
        value = "22",
    ),
    schema.Option(
        display = "MEAC",
        value = "24",
    ),
    schema.Option(
        display = "MVFC",
        value = "21",
    ),
    schema.Option(
        display = "NEC",
        value = "25",
    ),
    schema.Option(
        display = "OVC",
        value = "26",
    ),
    schema.Option(
        display = "Patriot",
        value = "27",
    ),
    schema.Option(
        display = "Pioneer",
        value = "28",
    ),
    schema.Option(
        display = "SWAC",
        value = "31",
    ),
    schema.Option(
        display = "Southern",
        value = "29",
    ),
    schema.Option(
        display = "Southland",
        value = "30",
    ),
    schema.Option(
        display = "WAC",
        value = "16",
    ),
    schema.Option(
        display = "Div II/III",
        value = "35",
    ),
]
teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "all",
    ),
    schema.Option(
        display = "Abilene Christian Wildcats",
        value = "2000",
    ),
    schema.Option(
        display = "Adams State Grizzlies",
        value = "2001",
    ),
    schema.Option(
        display = "Adrian Bulldogs",
        value = "2003",
    ),
    schema.Option(
        display = "Air Force Falcons",
        value = "2005",
    ),
    schema.Option(
        display = "Akron Zips",
        value = "2006",
    ),
    schema.Option(
        display = "Alabama A&M Bulldogs",
        value = "2010",
    ),
    schema.Option(
        display = "Alabama Crimson Tide",
        value = "333",
    ),
    schema.Option(
        display = "Alabama State Hornets",
        value = "2011",
    ),
    schema.Option(
        display = "Albany Great Danes",
        value = "399",
    ),
    schema.Option(
        display = "Albany State Golden Rams",
        value = "2013",
    ),
    schema.Option(
        display = "Albion Britons",
        value = "2790",
    ),
    schema.Option(
        display = "Albright Lions",
        value = "2015",
    ),
    schema.Option(
        display = "Alcorn State Braves",
        value = "2016",
    ),
    schema.Option(
        display = "Alderson Broaddus Battlers",
        value = "2017",
    ),
    schema.Option(
        display = "Alfred Saxons",
        value = "365",
    ),
    schema.Option(
        display = "Alfred State College Pioneers",
        value = "3162",
    ),
    schema.Option(
        display = "Allegheny Gators",
        value = "2018",
    ),
    schema.Option(
        display = "Alma College Scots",
        value = "2800",
    ),
    schema.Option(
        display = "American",
        value = "3193",
    ),
    schema.Option(
        display = "American International Yellow Jackets",
        value = "2022",
    ),
    schema.Option(
        display = "Amherst College Mammoths",
        value = "7",
    ),
    schema.Option(
        display = "Anderson (IN) Ravens",
        value = "2023",
    ),
    schema.Option(
        display = "Angelo State Rams",
        value = "2025",
    ),
    schema.Option(
        display = "Anna Maria College Amcats",
        value = "15",
    ),
    schema.Option(
        display = "Appalachian State Mountaineers",
        value = "2026",
    ),
    schema.Option(
        display = "Apprentice School Builders",
        value = "3111",
    ),
    schema.Option(
        display = "Arizona Christian Firestorm",
        value = "108358",
    ),
    schema.Option(
        display = "Arizona State Sun Devils",
        value = "9",
    ),
    schema.Option(
        display = "Arizona Wildcats",
        value = "12",
    ),
    schema.Option(
        display = "Arkansas Razorbacks",
        value = "8",
    ),
    schema.Option(
        display = "Arkansas State Red Wolves",
        value = "2032",
    ),
    schema.Option(
        display = "Arkansas Tech Wonder Boys",
        value = "2033",
    ),
    schema.Option(
        display = "Arkansas-Monticello Boll Weevils",
        value = "2028",
    ),
    schema.Option(
        display = "Arkansas-Pine Bluff Golden Lions",
        value = "2029",
    ),
    schema.Option(
        display = "Army Black Knights",
        value = "349",
    ),
    schema.Option(
        display = "Ashland Eagles",
        value = "308",
    ),
    schema.Option(
        display = "Assumption Greyhounds",
        value = "2038",
    ),
    schema.Option(
        display = "Auburn Tigers",
        value = "2",
    ),
    schema.Option(
        display = "Augsburg University Auggies",
        value = "124",
    ),
    schema.Option(
        display = "Augustana College (IL) Vikings",
        value = "2042",
    ),
    schema.Option(
        display = "Augustana University (SD) Vikings",
        value = "2043",
    ),
    schema.Option(
        display = "Aurora Spartans",
        value = "2044",
    ),
    schema.Option(
        display = "Austin College 'Roos",
        value = "2045",
    ),
    schema.Option(
        display = "Austin Peay Governors",
        value = "2046",
    ),
    schema.Option(
        display = "Ave Maria Gyrenes",
        value = "3178",
    ),
    schema.Option(
        display = "Averett Cougars",
        value = "2047",
    ),
    schema.Option(
        display = "Avila College Eagles",
        value = "2048",
    ),
    schema.Option(
        display = "Azusa Pacific Cougars",
        value = "2049",
    ),
    schema.Option(
        display = "BYU Cougars",
        value = "252",
    ),
    schema.Option(
        display = "Bacone College Warriors",
        value = "487",
    ),
    schema.Option(
        display = "Baker University Wildcats",
        value = "488",
    ),
    schema.Option(
        display = "Baldwin Wallace Yellow Jackets",
        value = "188",
    ),
    schema.Option(
        display = "Ball State Cardinals",
        value = "2050",
    ),
    schema.Option(
        display = "Bates College Bobcats",
        value = "121",
    ),
    schema.Option(
        display = "Baylor Bears",
        value = "239",
    ),
    schema.Option(
        display = "Belhaven University Blazers",
        value = "2056",
    ),
    schema.Option(
        display = "Beloit College Buccaneers",
        value = "266",
    ),
    schema.Option(
        display = "Bemidji State Beavers",
        value = "132",
    ),
    schema.Option(
        display = "Benedict College Tigers",
        value = "490",
    ),
    schema.Option(
        display = "Benedictine Ravens",
        value = "16111",
    ),
    schema.Option(
        display = "Benedictine University (IL) Eagles",
        value = "2283",
    ),
    schema.Option(
        display = "Bentley Falcons",
        value = "2060",
    ),
    schema.Option(
        display = "Berry College Vikings",
        value = "2757",
    ),
    schema.Option(
        display = "Bethany (KS) Swedes",
        value = "492",
    ),
    schema.Option(
        display = "Bethany (WV) Bison",
        value = "2062",
    ),
    schema.Option(
        display = "Bethel (TN) Wildcats",
        value = "2064",
    ),
    schema.Option(
        display = "Bethel University  Minnesota Royals",
        value = "2802",
    ),
    schema.Option(
        display = "Bethune-Cookman Wildcats",
        value = "2065",
    ),
    schema.Option(
        display = "Birmingham-Southern Panthers",
        value = "3",
    ),
    schema.Option(
        display = "Black Hills State Yellow Jackets",
        value = "2069",
    ),
    schema.Option(
        display = "Blackburn Beavers",
        value = "2070",
    ),
    schema.Option(
        display = "Bloomsburg Huskies",
        value = "2071",
    ),
    schema.Option(
        display = "Bluefield College Rams",
        value = "495",
    ),
    schema.Option(
        display = "Bluffton Beavers",
        value = "2074",
    ),
    schema.Option(
        display = "Boise State Broncos",
        value = "68",
    ),
    schema.Option(
        display = "Boston College Eagles",
        value = "103",
    ),
    schema.Option(
        display = "Bowdoin Polar Bears",
        value = "340",
    ),
    schema.Option(
        display = "Bowie State Bulldogs",
        value = "2075",
    ),
    schema.Option(
        display = "Bowling Green Falcons",
        value = "189",
    ),
    schema.Option(
        display = "Brevard College Tornados",
        value = "2913",
    ),
    schema.Option(
        display = "Bridgewater College (VA) Eagles",
        value = "2079",
    ),
    schema.Option(
        display = "Bridgewater State (MA) Bears",
        value = "18",
    ),
    schema.Option(
        display = "British Columbia Thunderbirds",
        value = "2080",
    ),
    schema.Option(
        display = "Brockport Golden Eagles",
        value = "2781",
    ),
    schema.Option(
        display = "Brown Bears",
        value = "225",
    ),
    schema.Option(
        display = "Bryant Bulldogs",
        value = "2803",
    ),
    schema.Option(
        display = "Bucknell Bison",
        value = "2083",
    ),
    schema.Option(
        display = "Buena Vista Beavers",
        value = "63",
    ),
    schema.Option(
        display = "Buffalo Bulls",
        value = "2084",
    ),
    schema.Option(
        display = "Buffalo State Bengals",
        value = "2085",
    ),
    schema.Option(
        display = "Butler Bulldogs",
        value = "2086",
    ),
    schema.Option(
        display = "Cal Poly Mustangs",
        value = "13",
    ),
    schema.Option(
        display = "California (PA) Vulcans",
        value = "2858",
    ),
    schema.Option(
        display = "California Golden Bears",
        value = "25",
    ),
    schema.Option(
        display = "California Lutheran Kingsmen",
        value = "2094",
    ),
    schema.Option(
        display = "Campbell Fighting Camels",
        value = "2097",
    ),
    schema.Option(
        display = "Capital University Crusaders",
        value = "424",
    ),
    schema.Option(
        display = "Carleton College Knights",
        value = "2101",
    ),
    schema.Option(
        display = "Carnegie Mellon Tartans",
        value = "2102",
    ),
    schema.Option(
        display = "Carroll (WI) Pioneers",
        value = "32",
    ),
    schema.Option(
        display = "Carson-Newman College Eagles",
        value = "2105",
    ),
    schema.Option(
        display = "Carthage College Firebirds",
        value = "2106",
    ),
    schema.Option(
        display = "Case Western Reserve Spartans",
        value = "2963",
    ),
    schema.Option(
        display = "Castleton Spartans",
        value = "293",
    ),
    schema.Option(
        display = "Catawba College Indians",
        value = "2107",
    ),
    schema.Option(
        display = "Catholic University DC Cardinals",
        value = "2108",
    ),
    schema.Option(
        display = "Central Arkansas Bears",
        value = "2110",
    ),
    schema.Option(
        display = "Central College Dutch",
        value = "2964",
    ),
    schema.Option(
        display = "Central Connecticut Blue Devils",
        value = "2115",
    ),
    schema.Option(
        display = "Central Methodist Eagles",
        value = "2860",
    ),
    schema.Option(
        display = "Central Michigan Chippewas",
        value = "2117",
    ),
    schema.Option(
        display = "Central Missouri Mules",
        value = "2118",
    ),
    schema.Option(
        display = "Central Oklahoma Bronchos",
        value = "2122",
    ),
    schema.Option(
        display = "Central State (OH) Marauders",
        value = "2119",
    ),
    schema.Option(
        display = "Central Washington Wildcats",
        value = "2120",
    ),
    schema.Option(
        display = "Centre College Colonels",
        value = "2121",
    ),
    schema.Option(
        display = "Chadron State Eagles",
        value = "2123",
    ),
    schema.Option(
        display = "Chapman University Panthers",
        value = "411",
    ),
    schema.Option(
        display = "Charleston (WV) Golden Eagles",
        value = "2128",
    ),
    schema.Option(
        display = "Charleston Southern Buccaneers",
        value = "2127",
    ),
    schema.Option(
        display = "Charlotte 49ers",
        value = "2429",
    ),
    schema.Option(
        display = "Chattanooga Mocs",
        value = "236",
    ),
    schema.Option(
        display = "Cheyney Wolves",
        value = "2129",
    ),
    schema.Option(
        display = "Chicago Maroons",
        value = "80",
    ),
    schema.Option(
        display = "Chowan Hawks",
        value = "2804",
    ),
    schema.Option(
        display = "Christopher Newport Captains",
        value = "3112",
    ),
    schema.Option(
        display = "Cincinnati Bearcats",
        value = "2132",
    ),
    schema.Option(
        display = "Claremont Mudd Scripps College Stags",
        value = "17",
    ),
    schema.Option(
        display = "Clarion Golden Eagles",
        value = "2134",
    ),
    schema.Option(
        display = "Clark Atlanta Panthers",
        value = "2805",
    ),
    schema.Option(
        display = "Clemson Tigers",
        value = "228",
    ),
    schema.Option(
        display = "Coast Guard Bears",
        value = "2557",
    ),
    schema.Option(
        display = "Coastal Carolina Chanticleers",
        value = "324",
    ),
    schema.Option(
        display = "Coe College Kohawks",
        value = "2141",
    ),
    schema.Option(
        display = "Colby College White Mules",
        value = "33",
    ),
    schema.Option(
        display = "Colgate Raiders",
        value = "2142",
    ),
    schema.Option(
        display = "College of Faith - Charlotte Saints",
        value = "3253",
    ),
    schema.Option(
        display = "College of Faith Warriors",
        value = "3211",
    ),
    schema.Option(
        display = "College of Idaho Yotes",
        value = "108382",
    ),
    schema.Option(
        display = "Colorado Buffaloes",
        value = "38",
    ),
    schema.Option(
        display = "Colorado College Tigers",
        value = "2144",
    ),
    schema.Option(
        display = "Colorado Mesa Mavericks",
        value = "11",
    ),
    schema.Option(
        display = "Colorado School of Mines Orediggers",
        value = "2146",
    ),
    schema.Option(
        display = "Colorado State Rams",
        value = "36",
    ),
    schema.Option(
        display = "Colorado State-Pueblo Thunderwolves",
        value = "2570",
    ),
    schema.Option(
        display = "Columbia Lions",
        value = "171",
    ),
    schema.Option(
        display = "Concord Mountain Lions",
        value = "2148",
    ),
    schema.Option(
        display = "Concordia (AL) Hornets",
        value = "3099",
    ),
    schema.Option(
        display = "Concordia (WI) Falcons",
        value = "409",
    ),
    schema.Option(
        display = "Concordia College (MI) Cardinals",
        value = "2985",
    ),
    schema.Option(
        display = "Concordia Moorhead Cobbers",
        value = "2152",
    ),
    schema.Option(
        display = "Concordia University St Paul Cobbers",
        value = "3066",
    ),
    schema.Option(
        display = "Concordia-Chicago Cougars",
        value = "2151",
    ),
    schema.Option(
        display = "Cornell Big Red",
        value = "172",
    ),
    schema.Option(
        display = "Cornell College (IA) Rams",
        value = "2155",
    ),
    schema.Option(
        display = "Crown Polars",
        value = "509",
    ),
    schema.Option(
        display = "Culver-Stockton Wildcats",
        value = "510",
    ),
    schema.Option(
        display = "Cumberland Bulldogs",
        value = "2161",
    ),
    schema.Option(
        display = "Cumberland College Indians",
        value = "511",
    ),
    schema.Option(
        display = "Curry College Colonels",
        value = "40",
    ),
    schema.Option(
        display = "Dakota State Trojans",
        value = "512",
    ),
    schema.Option(
        display = "Dakota Wesleyan Tigers",
        value = "513",
    ),
    schema.Option(
        display = "Dartmouth Big Green",
        value = "159",
    ),
    schema.Option(
        display = "Davidson Wildcats",
        value = "2166",
    ),
    schema.Option(
        display = "Dayton Flyers",
        value = "2168",
    ),
    schema.Option(
        display = "DePauw Tigers",
        value = "83",
    ),
    schema.Option(
        display = "Defiance Yellow Jackets",
        value = "190",
    ),
    schema.Option(
        display = "Delaware Blue Hens",
        value = "48",
    ),
    schema.Option(
        display = "Delaware State Hornets",
        value = "2169",
    ),
    schema.Option(
        display = "Delaware Valley Aggies",
        value = "2808",
    ),
    schema.Option(
        display = "Delta State Statesmen",
        value = "2170",
    ),
    schema.Option(
        display = "Denison Big Red",
        value = "2171",
    ),
    schema.Option(
        display = "Dickinson Red Devils",
        value = "2175",
    ),
    schema.Option(
        display = "Dickinson State Blue Hawks",
        value = "316",
    ),
    schema.Option(
        display = "Drake Bulldogs",
        value = "2181",
    ),
    schema.Option(
        display = "Dubuque Spartans",
        value = "49",
    ),
    schema.Option(
        display = "Duke Blue Devils",
        value = "150",
    ),
    schema.Option(
        display = "Duquesne Dukes",
        value = "2184",
    ),
    schema.Option(
        display = "East All-Stars",
        value = "3146",
    ),
    schema.Option(
        display = "East Carolina Pirates",
        value = "151",
    ),
    schema.Option(
        display = "East Central Tigers",
        value = "2191",
    ),
    schema.Option(
        display = "East Stroudsburg Warriors",
        value = "2188",
    ),
    schema.Option(
        display = "East Tennessee State Buccaneers",
        value = "2193",
    ),
    schema.Option(
        display = "East Texas Baptist Tigers",
        value = "2194",
    ),
    schema.Option(
        display = "Eastern Illinois Panthers",
        value = "2197",
    ),
    schema.Option(
        display = "Eastern Kentucky Colonels",
        value = "2198",
    ),
    schema.Option(
        display = "Eastern Michigan Eagles",
        value = "2199",
    ),
    schema.Option(
        display = "Eastern New Mexico Greyhounds",
        value = "2201",
    ),
    schema.Option(
        display = "Eastern Oregon Mountaineers",
        value = "2202",
    ),
    schema.Option(
        display = "Eastern Washington Eagles",
        value = "331",
    ),
    schema.Option(
        display = "Edinboro Fighting Scots",
        value = "2205",
    ),
    schema.Option(
        display = "Edward Waters College Fla Tigers",
        value = "2206",
    ),
    schema.Option(
        display = "Elizabeth City State Vikings",
        value = "2207",
    ),
    schema.Option(
        display = "Elmhurst Blue Jays",
        value = "72",
    ),
    schema.Option(
        display = "Elon Phoenix",
        value = "2210",
    ),
    schema.Option(
        display = "Emory & Henry College Wasps",
        value = "2213",
    ),
    schema.Option(
        display = "Emporia State Hornets",
        value = "2214",
    ),
    schema.Option(
        display = "Endicott College Gulls",
        value = "452",
    ),
    schema.Option(
        display = "Erie Community College Kats",
        value = "3236",
    ),
    schema.Option(
        display = "Eureka College Red Devils",
        value = "101",
    ),
    schema.Option(
        display = "Evangel Crusaders",
        value = "2865",
    ),
    schema.Option(
        display = "FDU-Florham Devils",
        value = "2221",
    ),
    schema.Option(
        display = "Fairmont State Falcons",
        value = "2986",
    ),
    schema.Option(
        display = "Faulkner Eagles",
        value = "2219",
    ),
    schema.Option(
        display = "Fayetteville State Broncos",
        value = "2220",
    ),
    schema.Option(
        display = "Ferris State Bulldogs",
        value = "2222",
    ),
    schema.Option(
        display = "Ferrum Panthers",
        value = "366",
    ),
    schema.Option(
        display = "Findlay Oilers",
        value = "2224",
    ),
    schema.Option(
        display = "Fitchburg State Falcons",
        value = "114",
    ),
    schema.Option(
        display = "Florida A&M Rattlers",
        value = "50",
    ),
    schema.Option(
        display = "Florida Atlantic Owls",
        value = "2226",
    ),
    schema.Option(
        display = "Florida Gators",
        value = "57",
    ),
    schema.Option(
        display = "Florida International Panthers",
        value = "2229",
    ),
    schema.Option(
        display = "Florida State Seminoles",
        value = "52",
    ),
    schema.Option(
        display = "Fordham Rams",
        value = "2230",
    ),
    schema.Option(
        display = "Fort Hays State Tigers",
        value = "2231",
    ),
    schema.Option(
        display = "Fort Lewis Skyhawks",
        value = "2237",
    ),
    schema.Option(
        display = "Fort Valley State Wildcats",
        value = "2232",
    ),
    schema.Option(
        display = "Framingham State Rams",
        value = "2967",
    ),
    schema.Option(
        display = "Franklin & Marshall Diplomats",
        value = "2234",
    ),
    schema.Option(
        display = "Franklin Grizzlies",
        value = "2233",
    ),
    schema.Option(
        display = "Fresno State Bulldogs",
        value = "278",
    ),
    schema.Option(
        display = "Frostburg State Bobcats",
        value = "341",
    ),
    schema.Option(
        display = "Furman Paladins",
        value = "231",
    ),
    schema.Option(
        display = "GAFFNEY Saints",
        value = "2336",
    ),
    schema.Option(
        display = "Gallaudet Bison",
        value = "417",
    ),
    schema.Option(
        display = "Gannon Golden Knights",
        value = "367",
    ),
    schema.Option(
        display = "Gardner-Webb Bulldogs",
        value = "2241",
    ),
    schema.Option(
        display = "Geneva College Golden Tornadoes",
        value = "2242",
    ),
    schema.Option(
        display = "George Fox University Bruins",
        value = "415",
    ),
    schema.Option(
        display = "George Mason Patriots",
        value = "2244",
    ),
    schema.Option(
        display = "Georgetown Hoyas",
        value = "46",
    ),
    schema.Option(
        display = "Georgia Bulldogs",
        value = "61",
    ),
    schema.Option(
        display = "Georgia Southern Eagles",
        value = "290",
    ),
    schema.Option(
        display = "Georgia State Panthers",
        value = "2247",
    ),
    schema.Option(
        display = "Georgia Tech Yellow Jackets",
        value = "59",
    ),
    schema.Option(
        display = "Gettysburg Bullets",
        value = "2248",
    ),
    schema.Option(
        display = "Glenville State Pioneers",
        value = "2249",
    ),
    schema.Option(
        display = "Graceland University Yellowjackets",
        value = "530",
    ),
    schema.Option(
        display = "Grambling Tigers",
        value = "2755",
    ),
    schema.Option(
        display = "Grand Valley State Lakers",
        value = "125",
    ),
    schema.Option(
        display = "Grand View Vikings",
        value = "2254",
    ),
    schema.Option(
        display = "Greeneville Pioneers",
        value = "2839",
    ),
    schema.Option(
        display = "Greensboro College Pride",
        value = "2256",
    ),
    schema.Option(
        display = "Greenville Panthers",
        value = "2257",
    ),
    schema.Option(
        display = "Grinnell Pioneers",
        value = "65",
    ),
    schema.Option(
        display = "Grove City College Wolverines",
        value = "146",
    ),
    schema.Option(
        display = "Guilford Quakers",
        value = "2258",
    ),
    schema.Option(
        display = "Gustavus Adolphus College Golden Gusties",
        value = "2968",
    ),
    schema.Option(
        display = "Hamilton Continentals",
        value = "348",
    ),
    schema.Option(
        display = "Hamline University Pipers",
        value = "162",
    ),
    schema.Option(
        display = "Hampden Sydney Tigers",
        value = "297",
    ),
    schema.Option(
        display = "Hampton Pirates",
        value = "2261",
    ),
    schema.Option(
        display = "Hanover Panthers",
        value = "2262",
    ),
    schema.Option(
        display = "Hardin-Simmons Cowboys",
        value = "2810",
    ),
    schema.Option(
        display = "Harding University Bisons",
        value = "2264",
    ),
    schema.Option(
        display = "Hartwick Hawks",
        value = "173",
    ),
    schema.Option(
        display = "Harvard Crimson",
        value = "108",
    ),
    schema.Option(
        display = "Haskell Indian Nations Jayhawks",
        value = "535",
    ),
    schema.Option(
        display = "Hawai'i Rainbow Warriors",
        value = "62",
    ),
    schema.Option(
        display = "Heidelberg Student Princes",
        value = "191",
    ),
    schema.Option(
        display = "Henderson State Reddies",
        value = "2271",
    ),
    schema.Option(
        display = "Hendrix College Warriors",
        value = "418",
    ),
    schema.Option(
        display = "Hillsdale Chargers",
        value = "2273",
    ),
    schema.Option(
        display = "Hiram College Terriers",
        value = "2274",
    ),
    schema.Option(
        display = "Hobart Statesmen",
        value = "174",
    ),
    schema.Option(
        display = "Holland College Hurricanes",
        value = "108354",
    ),
    schema.Option(
        display = "Holy Cross Crusaders",
        value = "107",
    ),
    schema.Option(
        display = "Hope Flying Dutchmen",
        value = "2812",
    ),
    schema.Option(
        display = "Houston Christian Huskies",
        value = "2277",
    ),
    schema.Option(
        display = "Houston Cougars",
        value = "248",
    ),
    schema.Option(
        display = "Howard Bison",
        value = "47",
    ),
    schema.Option(
        display = "Howard Payne Yellow Jackets",
        value = "2758",
    ),
    schema.Option(
        display = "Huntingdon Hawks",
        value = "2938",
    ),
    schema.Option(
        display = "Husson Eagles",
        value = "2280",
    ),
    schema.Option(
        display = "Idaho State Bengals",
        value = "304",
    ),
    schema.Option(
        display = "Idaho Vandals",
        value = "70",
    ),
    schema.Option(
        display = "Illinois College Blueboys",
        value = "2286",
    ),
    schema.Option(
        display = "Illinois Fighting Illini",
        value = "356",
    ),
    schema.Option(
        display = "Illinois State Redbirds",
        value = "2287",
    ),
    schema.Option(
        display = "Illinois Wesleyan Titans",
        value = "306",
    ),
    schema.Option(
        display = "Incarnate Word Cardinals",
        value = "2916",
    ),
    schema.Option(
        display = "Indiana (PA) Crimson Hawks",
        value = "2291",
    ),
    schema.Option(
        display = "Indiana Hoosiers",
        value = "84",
    ),
    schema.Option(
        display = "Indiana State Sycamores",
        value = "282",
    ),
    schema.Option(
        display = "Indianapolis Greyhounds",
        value = "2292",
    ),
    schema.Option(
        display = "Iowa Hawkeyes",
        value = "2294",
    ),
    schema.Option(
        display = "Iowa State Cyclones",
        value = "66",
    ),
    schema.Option(
        display = "Iowa Wesleyan Tigers",
        value = "2295",
    ),
    schema.Option(
        display = "Ithaca Bombers",
        value = "175",
    ),
    schema.Option(
        display = "Jackson State Tigers",
        value = "2296",
    ),
    schema.Option(
        display = "Jacksonville State Gamecocks",
        value = "55",
    ),
    schema.Option(
        display = "James Madison Dukes",
        value = "256",
    ),
    schema.Option(
        display = "Jamestown Jimmies",
        value = "2939",
    ),
    schema.Option(
        display = "John Carroll Blue Streaks",
        value = "2302",
    ),
    schema.Option(
        display = "Johns Hopkins Blue Jays",
        value = "118",
    ),
    schema.Option(
        display = "Johnson C Smith Golden Bulls",
        value = "2304",
    ),
    schema.Option(
        display = "Juniata College Eagles",
        value = "246",
    ),
    schema.Option(
        display = "Kalamazoo Hornets",
        value = "126",
    ),
    schema.Option(
        display = "Kansas Jayhawks",
        value = "2305",
    ),
    schema.Option(
        display = "Kansas State Wildcats",
        value = "2306",
    ),
    schema.Option(
        display = "Kansas Wesleyan University Coyotes",
        value = "547",
    ),
    schema.Option(
        display = "Kean University Cougars",
        value = "2871",
    ),
    schema.Option(
        display = "Kennesaw State Owls",
        value = "338",
    ),
    schema.Option(
        display = "Kent State Golden Flashes",
        value = "2309",
    ),
    schema.Option(
        display = "Kentucky Christian Knights",
        value = "3077",
    ),
    schema.Option(
        display = "Kentucky State Thorobreds",
        value = "2310",
    ),
    schema.Option(
        display = "Kentucky Wesleyan Panthers",
        value = "2316",
    ),
    schema.Option(
        display = "Kentucky Wildcats",
        value = "96",
    ),
    schema.Option(
        display = "Kenyon Lords",
        value = "352",
    ),
    schema.Option(
        display = "King's College (PA) Monarchs",
        value = "247",
    ),
    schema.Option(
        display = "Knox College Prairie Fire",
        value = "255",
    ),
    schema.Option(
        display = "Kutztown Golden Bears",
        value = "2315",
    ),
    schema.Option(
        display = "LSU Tigers",
        value = "99",
    ),
    schema.Option(
        display = "La Verne Leopards",
        value = "2318",
    ),
    schema.Option(
        display = "LaGrange College Panthers",
        value = "548",
    ),
    schema.Option(
        display = "Lafayette Leopards",
        value = "322",
    ),
    schema.Option(
        display = "Lake Erie College Storm",
        value = "437",
    ),
    schema.Option(
        display = "Lake Forest Foresters",
        value = "262",
    ),
    schema.Option(
        display = "Lamar Cardinals",
        value = "2320",
    ),
    schema.Option(
        display = "Lambuth Eagles",
        value = "2321",
    ),
    schema.Option(
        display = "Lane Dragons",
        value = "2323",
    ),
    schema.Option(
        display = "Langston Lions",
        value = "2324",
    ),
    schema.Option(
        display = "Lawrence Vikings",
        value = "268",
    ),
    schema.Option(
        display = "Lebanon Valley Flying Dutchmen",
        value = "388",
    ),
    schema.Option(
        display = "Lehigh Mountain Hawks",
        value = "2329",
    ),
    schema.Option(
        display = "Lenoir-Rhyne University Bears",
        value = "2331",
    ),
    schema.Option(
        display = "Lewis & Clark Pioneers",
        value = "2333",
    ),
    schema.Option(
        display = "Liberty Flames",
        value = "2335",
    ),
    schema.Option(
        display = "Lincoln (MO) Blue Tigers",
        value = "2876",
    ),
    schema.Option(
        display = "Lincoln (PA) Lions",
        value = "2339",
    ),
    schema.Option(
        display = "Lindenwood Belleville Lynx",
        value = "3209",
    ),
    schema.Option(
        display = "Lindenwood Lions",
        value = "2815",
    ),
    schema.Option(
        display = "Lindsey Wilson College Blue Raiders",
        value = "2877",
    ),
    schema.Option(
        display = "Linfield Wildcats",
        value = "203",
    ),
    schema.Option(
        display = "Livingstone Blue Bears",
        value = "2940",
    ),
    schema.Option(
        display = "Lock Haven Bald Eagles",
        value = "209",
    ),
    schema.Option(
        display = "Long Island University Sharks",
        value = "112358",
    ),
    schema.Option(
        display = "Loras College Duhawks",
        value = "263",
    ),
    schema.Option(
        display = "Louisiana Christian University Wildcats",
        value = "2347",
    ),
    schema.Option(
        display = "Louisiana Ragin' Cajuns",
        value = "309",
    ),
    schema.Option(
        display = "Louisiana Tech Bulldogs",
        value = "2348",
    ),
    schema.Option(
        display = "Louisville Cardinals",
        value = "97",
    ),
    schema.Option(
        display = "Luther Norse",
        value = "67",
    ),
    schema.Option(
        display = "Lycoming Warriors",
        value = "2354",
    ),
    schema.Option(
        display = "MIT Engineers",
        value = "109",
    ),
    schema.Option(
        display = "Macalester College-Minnesota Scots",
        value = "2359",
    ),
    schema.Option(
        display = "Maine Black Bears",
        value = "311",
    ),
    schema.Option(
        display = "Manchester Spartans",
        value = "2362",
    ),
    schema.Option(
        display = "Manitoba Bisons",
        value = "2770",
    ),
    schema.Option(
        display = "Mansfield Mountaineers",
        value = "2365",
    ),
    schema.Option(
        display = "Marian Knights",
        value = "2366",
    ),
    schema.Option(
        display = "Marietta Pioneers",
        value = "317",
    ),
    schema.Option(
        display = "Marist Red Foxes",
        value = "2368",
    ),
    schema.Option(
        display = "Maritime College Privateers",
        value = "2951",
    ),
    schema.Option(
        display = "Mars Hill Mountain Lions",
        value = "2369",
    ),
    schema.Option(
        display = "Marshall Thundering Herd",
        value = "276",
    ),
    schema.Option(
        display = "Martin Luther College Knights",
        value = "446",
    ),
    schema.Option(
        display = "Mary Hardin-Baylor Crusaders",
        value = "2371",
    ),
    schema.Option(
        display = "Maryland Terrapins",
        value = "120",
    ),
    schema.Option(
        display = "Maryville College Scots",
        value = "2373",
    ),
    schema.Option(
        display = "Mass Maritime Buccaneers",
        value = "110",
    ),
    schema.Option(
        display = "Mayville State Comets",
        value = "561",
    ),
    schema.Option(
        display = "McDaniel College Green Terror",
        value = "2700",
    ),
    schema.Option(
        display = "McMurry War Hawks",
        value = "241",
    ),
    schema.Option(
        display = "McNeese Cowboys",
        value = "2377",
    ),
    schema.Option(
        display = "Memphis Tigers",
        value = "235",
    ),
    schema.Option(
        display = "Menlo College Oaks",
        value = "2381",
    ),
    schema.Option(
        display = "Mercer Bears",
        value = "2382",
    ),
    schema.Option(
        display = "Merchant Marine Mariners",
        value = "2383",
    ),
    schema.Option(
        display = "Mercyhurst Lakers",
        value = "2385",
    ),
    schema.Option(
        display = "Merrimack Warriors",
        value = "2771",
    ),
    schema.Option(
        display = "Methodist Monarchs",
        value = "291",
    ),
    schema.Option(
        display = "Miami (OH) RedHawks",
        value = "193",
    ),
    schema.Option(
        display = "Miami Hurricanes",
        value = "2390",
    ),
    schema.Option(
        display = "Michigan State Spartans",
        value = "127",
    ),
    schema.Option(
        display = "Michigan Tech Huskies",
        value = "2392",
    ),
    schema.Option(
        display = "Michigan Wolverines",
        value = "130",
    ),
    schema.Option(
        display = "Middle Tennessee Blue Raiders",
        value = "2393",
    ),
    schema.Option(
        display = "Middlebury Panthers",
        value = "2394",
    ),
    schema.Option(
        display = "Midland University Warriors",
        value = "565",
    ),
    schema.Option(
        display = "Midwestern State Mustangs",
        value = "2395",
    ),
    schema.Option(
        display = "Miles College Golden Bears",
        value = "2396",
    ),
    schema.Option(
        display = "Millersville University Marauders",
        value = "210",
    ),
    schema.Option(
        display = "Millikin Big Blue",
        value = "74",
    ),
    schema.Option(
        display = "Millsaps Majors",
        value = "2398",
    ),
    schema.Option(
        display = "Minnesota Duluth Bulldogs",
        value = "134",
    ),
    schema.Option(
        display = "Minnesota Golden Gophers",
        value = "135",
    ),
    schema.Option(
        display = "Minnesota St Mavericks",
        value = "2364",
    ),
    schema.Option(
        display = "Minnesota St-Moorhead Dragons",
        value = "2817",
    ),
    schema.Option(
        display = "Minnesota-Morris Cougars",
        value = "2399",
    ),
    schema.Option(
        display = "Minot State Beavers",
        value = "568",
    ),
    schema.Option(
        display = "Misericordia Cougars",
        value = "2969",
    ),
    schema.Option(
        display = "Mississippi College Choctaws",
        value = "2401",
    ),
    schema.Option(
        display = "Mississippi State Bulldogs",
        value = "344",
    ),
    schema.Option(
        display = "Mississippi Valley State Delta Devils",
        value = "2400",
    ),
    schema.Option(
        display = "Missouri Baptist Spartans",
        value = "2880",
    ),
    schema.Option(
        display = "Missouri S&T Miners",
        value = "2402",
    ),
    schema.Option(
        display = "Missouri Southern State Lions",
        value = "2403",
    ),
    schema.Option(
        display = "Missouri State Bears",
        value = "2623",
    ),
    schema.Option(
        display = "Missouri Tigers",
        value = "142",
    ),
    schema.Option(
        display = "Missouri Western Griffons",
        value = "137",
    ),
    schema.Option(
        display = "Monmouth (IL) Fighting Scots",
        value = "2919",
    ),
    schema.Option(
        display = "Monmouth Hawks",
        value = "2405",
    ),
    schema.Option(
        display = "Montana Grizzlies",
        value = "149",
    ),
    schema.Option(
        display = "Montana State Bobcats",
        value = "147",
    ),
    schema.Option(
        display = "Montana-Western Bulldogs",
        value = "2701",
    ),
    schema.Option(
        display = "Montclair State Red Hawks",
        value = "2818",
    ),
    schema.Option(
        display = "Monterrey Tech Rams",
        value = "3100",
    ),
    schema.Option(
        display = "Moravian Greyhounds",
        value = "323",
    ),
    schema.Option(
        display = "Morehead State Eagles",
        value = "2413",
    ),
    schema.Option(
        display = "Morehouse College Maroon Tigers",
        value = "60",
    ),
    schema.Option(
        display = "Morgan State Bears",
        value = "2415",
    ),
    schema.Option(
        display = "Morningside Chiefs",
        value = "2416",
    ),
    schema.Option(
        display = "Mount Ida College Mustangs",
        value = "481",
    ),
    schema.Option(
        display = "Mount St. Joseph Lions",
        value = "2419",
    ),
    schema.Option(
        display = "Mount Union Raiders",
        value = "426",
    ),
    schema.Option(
        display = "Muhlenberg Mules",
        value = "2422",
    ),
    schema.Option(
        display = "Murray State Racers",
        value = "93",
    ),
    schema.Option(
        display = "Muskingum Fighting Muskies",
        value = "332",
    ),
    schema.Option(
        display = "NC State Wolfpack",
        value = "152",
    ),
    schema.Option(
        display = "NC Wesleyan Battling Bishops",
        value = "286",
    ),
    schema.Option(
        display = "NORTH All-Stars",
        value = "3145",
    ),
    schema.Option(
        display = "NORTH FLORIDA STARS",
        value = "3197",
    ),
    schema.Option(
        display = "National",
        value = "3194",
    ),
    schema.Option(
        display = "Navy Midshipmen",
        value = "2426",
    ),
    schema.Option(
        display = "Nebraska Cornhuskers",
        value = "158",
    ),
    schema.Option(
        display = "Nebraska-Kearney Lopers",
        value = "2438",
    ),
    schema.Option(
        display = "Nevada Wolf Pack",
        value = "2440",
    ),
    schema.Option(
        display = "New Hampshire Wildcats",
        value = "160",
    ),
    schema.Option(
        display = "New Haven Chargers",
        value = "2441",
    ),
    schema.Option(
        display = "New Mexico Highlands Cowboys",
        value = "2424",
    ),
    schema.Option(
        display = "New Mexico Lobos",
        value = "167",
    ),
    schema.Option(
        display = "New Mexico State Aggies",
        value = "166",
    ),
    schema.Option(
        display = "Newberry Wolves",
        value = "2444",
    ),
    schema.Option(
        display = "Nicholls Colonels",
        value = "2447",
    ),
    schema.Option(
        display = "Nichols Bison",
        value = "2884",
    ),
    schema.Option(
        display = "Norfolk State Spartans",
        value = "2450",
    ),
    schema.Option(
        display = "North Alabama Lions",
        value = "2453",
    ),
    schema.Option(
        display = "North Carolina A&T Aggies",
        value = "2448",
    ),
    schema.Option(
        display = "North Carolina Central Eagles",
        value = "2428",
    ),
    schema.Option(
        display = "North Carolina Pembroke Braves",
        value = "2882",
    ),
    schema.Option(
        display = "North Carolina Tar Heels",
        value = "153",
    ),
    schema.Option(
        display = "North Central Cardinals",
        value = "3071",
    ),
    schema.Option(
        display = "North Dakota Fighting Hawks",
        value = "155",
    ),
    schema.Option(
        display = "North Dakota State Bison",
        value = "2449",
    ),
    schema.Option(
        display = "North Greenville Crusaders",
        value = "2822",
    ),
    schema.Option(
        display = "North Park Vikings",
        value = "75",
    ),
    schema.Option(
        display = "North Texas Mean Green",
        value = "249",
    ),
    schema.Option(
        display = "Northeastern State RiverHawks",
        value = "196",
    ),
    schema.Option(
        display = "Northern Arizona Lumberjacks",
        value = "2464",
    ),
    schema.Option(
        display = "Northern Colorado Bears",
        value = "2458",
    ),
    schema.Option(
        display = "Northern Illinois Huskies",
        value = "2459",
    ),
    schema.Option(
        display = "Northern Iowa Panthers",
        value = "2460",
    ),
    schema.Option(
        display = "Northern Michigan Wildcats",
        value = "128",
    ),
    schema.Option(
        display = "Northern State Wolves",
        value = "425",
    ),
    schema.Option(
        display = "Northwest Missouri State Bearcats",
        value = "138",
    ),
    schema.Option(
        display = "Northwestern Oklahoma State Rangers",
        value = "2823",
    ),
    schema.Option(
        display = "Northwestern State Demons",
        value = "2466",
    ),
    schema.Option(
        display = "Northwestern Wildcats",
        value = "77",
    ),
    schema.Option(
        display = "Northwood University Timberwolves",
        value = "2886",
    ),
    schema.Option(
        display = "Norwich Cadets",
        value = "2467",
    ),
    schema.Option(
        display = "Notre Dame College Falcons",
        value = "587",
    ),
    schema.Option(
        display = "Notre Dame Fighting Irish",
        value = "87",
    ),
    schema.Option(
        display = "Oberlin Yeomen",
        value = "391",
    ),
    schema.Option(
        display = "Occidental Tigers",
        value = "2475",
    ),
    schema.Option(
        display = "Ohio Bobcats",
        value = "195",
    ),
    schema.Option(
        display = "Ohio Midwestern College Rams",
        value = "108398",
    ),
    schema.Option(
        display = "Ohio Northern Polar Bears",
        value = "427",
    ),
    schema.Option(
        display = "Ohio State Buckeyes",
        value = "194",
    ),
    schema.Option(
        display = "Ohio State Newark Titans",
        value = "3161",
    ),
    schema.Option(
        display = "Ohio Wesleyan Battling Bishops",
        value = "2980",
    ),
    schema.Option(
        display = "Oklahoma Baptist Bison",
        value = "319",
    ),
    schema.Option(
        display = "Oklahoma Panhandle State Aggies",
        value = "2824",
    ),
    schema.Option(
        display = "Oklahoma Sooners",
        value = "201",
    ),
    schema.Option(
        display = "Oklahoma State Cowboys",
        value = "197",
    ),
    schema.Option(
        display = "Old Dominion Monarchs",
        value = "295",
    ),
    schema.Option(
        display = "Ole Miss Rebels",
        value = "145",
    ),
    schema.Option(
        display = "Olivet College Comets",
        value = "354",
    ),
    schema.Option(
        display = "Omaha Mavericks",
        value = "2437",
    ),
    schema.Option(
        display = "Oregon Ducks",
        value = "2483",
    ),
    schema.Option(
        display = "Oregon State Beavers",
        value = "204",
    ),
    schema.Option(
        display = "Otterbein Cardinals",
        value = "359",
    ),
    schema.Option(
        display = "Ouachita Baptist Tigers",
        value = "2888",
    ),
    schema.Option(
        display = "Pace University Setters",
        value = "2487",
    ),
    schema.Option(
        display = "Pacific (OR) Boxers",
        value = "205",
    ),
    schema.Option(
        display = "Pacific Lutheran Lutes",
        value = "2486",
    ),
    schema.Option(
        display = "Penn State Nittany Lions",
        value = "213",
    ),
    schema.Option(
        display = "Pennsylvania Quakers",
        value = "219",
    ),
    schema.Option(
        display = "Pikeville Bears",
        value = "95",
    ),
    schema.Option(
        display = "Pittsburg State Gorillas",
        value = "90",
    ),
    schema.Option(
        display = "Pittsburgh Panthers",
        value = "221",
    ),
    schema.Option(
        display = "Plymouth State College Panthers",
        value = "2972",
    ),
    schema.Option(
        display = "Point University Point",
        value = "3179",
    ),
    schema.Option(
        display = "Pomona-Pitzer Colleges Sagehens",
        value = "2923",
    ),
    schema.Option(
        display = "Portland State Vikings",
        value = "2502",
    ),
    schema.Option(
        display = "Prairie View A&M Panthers",
        value = "2504",
    ),
    schema.Option(
        display = "Presbyterian Blue Hose",
        value = "2506",
    ),
    schema.Option(
        display = "Presentation College Saints",
        value = "597",
    ),
    schema.Option(
        display = "Princeton Tigers",
        value = "163",
    ),
    schema.Option(
        display = "Principia College Panthers",
        value = "363",
    ),
    schema.Option(
        display = "Puget Sound Loggers",
        value = "2508",
    ),
    schema.Option(
        display = "Purdue Boilermakers",
        value = "2509",
    ),
    schema.Option(
        display = "Quincy Hawks",
        value = "2825",
    ),
    schema.Option(
        display = "Randolph-Macon College Yellow Jackets",
        value = "2516",
    ),
    schema.Option(
        display = "Redlands Bulldogs",
        value = "29",
    ),
    schema.Option(
        display = "Reinhardt Eagles",
        value = "2890",
    ),
    schema.Option(
        display = "Rensselaer Engineers",
        value = "2528",
    ),
    schema.Option(
        display = "Rhode Island Rams",
        value = "227",
    ),
    schema.Option(
        display = "Rhodes College Lynx",
        value = "2519",
    ),
    schema.Option(
        display = "Rice Owls",
        value = "242",
    ),
    schema.Option(
        display = "Richmond Spiders",
        value = "257",
    ),
    schema.Option(
        display = "Ripon Red Hawks",
        value = "2891",
    ),
    schema.Option(
        display = "Robert Morris (IL) Eagles",
        value = "599",
    ),
    schema.Option(
        display = "Robert Morris Colonials",
        value = "2523",
    ),
    schema.Option(
        display = "Rochester Yellow Jackets",
        value = "184",
    ),
    schema.Option(
        display = "Rockford University Regents",
        value = "2524",
    ),
    schema.Option(
        display = "Rose-Hulman Fightin' Engineers",
        value = "86",
    ),
    schema.Option(
        display = "Rowan Profs",
        value = "2827",
    ),
    schema.Option(
        display = "Rutgers Scarlet Knights",
        value = "164",
    ),
    schema.Option(
        display = "SE Louisiana Lions",
        value = "2545",
    ),
    schema.Option(
        display = "SMU Mustangs",
        value = "2567",
    ),
    schema.Option(
        display = "SOUTH All-Stars",
        value = "3144",
    ),
    schema.Option(
        display = "SOUTH FLORIDA STARS",
        value = "3198",
    ),
    schema.Option(
        display = "SUNY Cortland Red Dragons",
        value = "2782",
    ),
    schema.Option(
        display = "SUNY Morrisville Mustangs",
        value = "3110",
    ),
    schema.Option(
        display = "Sacramento State Hornets",
        value = "16",
    ),
    schema.Option(
        display = "Sacred Heart Pioneers",
        value = "2529",
    ),
    schema.Option(
        display = "Saginaw Valley Cardinals",
        value = "129",
    ),
    schema.Option(
        display = "Salisbury University Sea Gulls",
        value = "2532",
    ),
    schema.Option(
        display = "Salve Regina University Seahawks",
        value = "2776",
    ),
    schema.Option(
        display = "Sam Houston Bearkats",
        value = "2534",
    ),
    schema.Option(
        display = "Samford Bulldogs",
        value = "2535",
    ),
    schema.Option(
        display = "San Diego State Aztecs",
        value = "21",
    ),
    schema.Option(
        display = "San Diego Toreros",
        value = "301",
    ),
    schema.Option(
        display = "San José State Spartans",
        value = "23",
    ),
    schema.Option(
        display = "Savannah State Tigers",
        value = "2542",
    ),
    schema.Option(
        display = "Seton Hill Griffins",
        value = "611",
    ),
    schema.Option(
        display = "Sewanee Univ. of the South Tigers",
        value = "2553",
    ),
    schema.Option(
        display = "Shaw Bears",
        value = "2551",
    ),
    schema.Option(
        display = "Shenandoah University Hornets",
        value = "2828",
    ),
    schema.Option(
        display = "Shepherd Rams",
        value = "2974",
    ),
    schema.Option(
        display = "Shepherd Tech Eagles",
        value = "3181",
    ),
    schema.Option(
        display = "Shippensburg Raiders",
        value = "2559",
    ),
    schema.Option(
        display = "Shorter Hawks",
        value = "2560",
    ),
    schema.Option(
        display = "Siena Heights Saints",
        value = "2562",
    ),
    schema.Option(
        display = "Simon Fraser Red Leafs",
        value = "2829",
    ),
    schema.Option(
        display = "Simpson College Storm",
        value = "2564",
    ),
    schema.Option(
        display = "Slippery Rock The Rock",
        value = "215",
    ),
    schema.Option(
        display = "South Alabama Jaguars",
        value = "6",
    ),
    schema.Option(
        display = "South Carolina Gamecocks",
        value = "2579",
    ),
    schema.Option(
        display = "South Carolina State Bulldogs",
        value = "2569",
    ),
    schema.Option(
        display = "South Dakota Coyotes",
        value = "233",
    ),
    schema.Option(
        display = "South Dakota Mines Hardrockers",
        value = "613",
    ),
    schema.Option(
        display = "South Dakota State Jackrabbits",
        value = "2571",
    ),
    schema.Option(
        display = "South Florida Bulls",
        value = "58",
    ),
    schema.Option(
        display = "Southeast Missouri State Redhawks",
        value = "2546",
    ),
    schema.Option(
        display = "Southeastern Oklahoma Savage Storm",
        value = "199",
    ),
    schema.Option(
        display = "Southeastern University Fire",
        value = "267",
    ),
    schema.Option(
        display = "Southern Arkansas Muleriders",
        value = "2568",
    ),
    schema.Option(
        display = "Southern Connecticut State Owls",
        value = "2583",
    ),
    schema.Option(
        display = "Southern Illinois Salukis",
        value = "79",
    ),
    schema.Option(
        display = "Southern Jaguars",
        value = "2582",
    ),
    schema.Option(
        display = "Southern Miss Golden Eagles",
        value = "2572",
    ),
    schema.Option(
        display = "Southern Nazarene Crimson Storm",
        value = "200",
    ),
    schema.Option(
        display = "Southern Oregon Raiders",
        value = "2584",
    ),
    schema.Option(
        display = "Southern Utah Thunderbirds",
        value = "253",
    ),
    schema.Option(
        display = "Southern Virginia Knights",
        value = "2896",
    ),
    schema.Option(
        display = "Southwest Baptist Bearcats",
        value = "2586",
    ),
    schema.Option(
        display = "Southwest Minnesota State Mustangs",
        value = "2587",
    ),
    schema.Option(
        display = "Southwestern Assemblies of God Lions",
        value = "2904",
    ),
    schema.Option(
        display = "Southwestern College Moundbuilders",
        value = "616",
    ),
    schema.Option(
        display = "Southwestern Oklahoma Bulldogs",
        value = "2927",
    ),
    schema.Option(
        display = "Southwestern University Pirates",
        value = "2588",
    ),
    schema.Option(
        display = "Springfield College Pride",
        value = "81",
    ),
    schema.Option(
        display = "St Johns University At Minnesota Johnnies",
        value = "2600",
    ),
    schema.Option(
        display = "St. Ambrose Fighting Bees",
        value = "2591",
    ),
    schema.Option(
        display = "St. Anselm Hawks",
        value = "2830",
    ),
    schema.Option(
        display = "St. Augustine's Falcons",
        value = "395",
    ),
    schema.Option(
        display = "St. Francis (IL) Fighting Saints",
        value = "2595",
    ),
    schema.Option(
        display = "St. Francis (IN) Cougars",
        value = "2831",
    ),
    schema.Option(
        display = "St. Francis (PA) Red Flash",
        value = "2598",
    ),
    schema.Option(
        display = "St. John Fisher College Cardinals",
        value = "374",
    ),
    schema.Option(
        display = "St. Joseph's (IN) Pumas",
        value = "2601",
    ),
    schema.Option(
        display = "St. Lawrence Saints",
        value = "2779",
    ),
    schema.Option(
        display = "St. Norbert College Green Knights",
        value = "2832",
    ),
    schema.Option(
        display = "St. Olaf College Oles",
        value = "133",
    ),
    schema.Option(
        display = "St. Paul's College Tigers",
        value = "2611",
    ),
    schema.Option(
        display = "St. Peter's Peacocks",
        value = "2612",
    ),
    schema.Option(
        display = "St. Scholastica Saints",
        value = "375",
    ),
    schema.Option(
        display = "St. Thomas - Minnesota Tommies",
        value = "2900",
    ),
    schema.Option(
        display = "St. Vincent College Bearcats",
        value = "2614",
    ),
    schema.Option(
        display = "St. Xavier (IL) Cougars",
        value = "2615",
    ),
    schema.Option(
        display = "Stanford Cardinal",
        value = "24",
    ),
    schema.Option(
        display = "Stephen F. Austin Lumberjacks",
        value = "2617",
    ),
    schema.Option(
        display = "Sterling College Warriors",
        value = "618",
    ),
    schema.Option(
        display = "Stetson Hatters",
        value = "56",
    ),
    schema.Option(
        display = "Stevenson University Mustangs",
        value = "471",
    ),
    schema.Option(
        display = "Stonehill Skyhawks",
        value = "284",
    ),
    schema.Option(
        display = "Stony Brook Seawolves",
        value = "2619",
    ),
    schema.Option(
        display = "Sul Ross State University Lobos",
        value = "2834",
    ),
    schema.Option(
        display = "Susquehanna River Hawks",
        value = "216",
    ),
    schema.Option(
        display = "Syracuse Orange",
        value = "183",
    ),
    schema.Option(
        display = "TCU Horned Frogs",
        value = "2628",
    ),
    schema.Option(
        display = "Tarleton Texans",
        value = "2627",
    ),
    schema.Option(
        display = "Taylor Trojans",
        value = "620",
    ),
    schema.Option(
        display = "Temple Owls",
        value = "218",
    ),
    schema.Option(
        display = "Tennessee State Tigers",
        value = "2634",
    ),
    schema.Option(
        display = "Tennessee Tech Golden Eagles",
        value = "2635",
    ),
    schema.Option(
        display = "Tennessee Volunteers",
        value = "2633",
    ),
    schema.Option(
        display = "Texas A&M Aggies",
        value = "245",
    ),
    schema.Option(
        display = "Texas A&M-Commerce Lions",
        value = "2837",
    ),
    schema.Option(
        display = "Texas A&M-Kingsville Javelinas",
        value = "2658",
    ),
    schema.Option(
        display = "Texas College Steers",
        value = "2637",
    ),
    schema.Option(
        display = "Texas Longhorns",
        value = "251",
    ),
    schema.Option(
        display = "Texas Lutheran Bulldogs",
        value = "2639",
    ),
    schema.Option(
        display = "Texas Southern Tigers",
        value = "2640",
    ),
    schema.Option(
        display = "Texas State Bobcats",
        value = "326",
    ),
    schema.Option(
        display = "Texas Tech Red Raiders",
        value = "2641",
    ),
    schema.Option(
        display = "The Citadel Bulldogs",
        value = "2643",
    ),
    schema.Option(
        display = "The College of New Jersey Lions",
        value = "2442",
    ),
    schema.Option(
        display = "Thiel College Tomcats",
        value = "2644",
    ),
    schema.Option(
        display = "Thomas More College Saints",
        value = "2646",
    ),
    schema.Option(
        display = "Tiffin University Dragons",
        value = "625",
    ),
    schema.Option(
        display = "Tiffin University Dragons",
        value = "2838",
    ),
    schema.Option(
        display = "Toledo Rockets",
        value = "2649",
    ),
    schema.Option(
        display = "Towson Tigers",
        value = "119",
    ),
    schema.Option(
        display = "Trine University Thunder",
        value = "2651",
    ),
    schema.Option(
        display = "Trinity (IL) Trojans",
        value = "2652",
    ),
    schema.Option(
        display = "Trinity Bible Lions",
        value = "3214",
    ),
    schema.Option(
        display = "Trinity College (CT) Bantams",
        value = "2977",
    ),
    schema.Option(
        display = "Trinity University (TX) Tigers",
        value = "386",
    ),
    schema.Option(
        display = "Troy Trojans",
        value = "2653",
    ),
    schema.Option(
        display = "Truman State Bulldogs",
        value = "2654",
    ),
    schema.Option(
        display = "Tufts University Jumbos",
        value = "112",
    ),
    schema.Option(
        display = "Tulane Green Wave",
        value = "2655",
    ),
    schema.Option(
        display = "Tulsa Golden Hurricane",
        value = "202",
    ),
    schema.Option(
        display = "Tuskegee Golden Tigers",
        value = "2657",
    ),
    schema.Option(
        display = "UAB Blazers",
        value = "5",
    ),
    schema.Option(
        display = "UC Davis Aggies",
        value = "302",
    ),
    schema.Option(
        display = "UCF Knights",
        value = "2116",
    ),
    schema.Option(
        display = "UCLA Bruins",
        value = "26",
    ),
    schema.Option(
        display = "UConn Huskies",
        value = "41",
    ),
    schema.Option(
        display = "UL Monroe Warhawks",
        value = "2433",
    ),
    schema.Option(
        display = "UMass Dartmouth Corsairs",
        value = "379",
    ),
    schema.Option(
        display = "UMass Lowell River Hawks",
        value = "2349",
    ),
    schema.Option(
        display = "UMass Minutemen",
        value = "113",
    ),
    schema.Option(
        display = "UNLV Rebels",
        value = "2439",
    ),
    schema.Option(
        display = "USC Trojans",
        value = "30",
    ),
    schema.Option(
        display = "UT Martin Skyhawks",
        value = "2630",
    ),
    schema.Option(
        display = "UTEP Miners",
        value = "2638",
    ),
    schema.Option(
        display = "UTSA Roadrunners",
        value = "2636",
    ),
    schema.Option(
        display = "Union Dutchmen",
        value = "237",
    ),
    schema.Option(
        display = "Univ. of Northwestern-St. Paul Eagles",
        value = "583",
    ),
    schema.Option(
        display = "University of Faith Glory Eagles",
        value = "3254",
    ),
    schema.Option(
        display = "University of Mary Marauders",
        value = "559",
    ),
    schema.Option(
        display = "Upper Iowa Peacocks",
        value = "389",
    ),
    schema.Option(
        display = "Ursinus College Bears",
        value = "2667",
    ),
    schema.Option(
        display = "Utah State Aggies",
        value = "328",
    ),
    schema.Option(
        display = "Utah Tech Trailblazers",
        value = "3101",
    ),
    schema.Option(
        display = "Utah Utes",
        value = "254",
    ),
    schema.Option(
        display = "Utica College Pioneers",
        value = "390",
    ),
    schema.Option(
        display = "VMI Keydets",
        value = "2678",
    ),
    schema.Option(
        display = "Valdosta State Blazers",
        value = "2673",
    ),
    schema.Option(
        display = "Valley City State Vikings",
        value = "628",
    ),
    schema.Option(
        display = "Valparaiso Beacons",
        value = "2674",
    ),
    schema.Option(
        display = "Vanderbilt Commodores",
        value = "238",
    ),
    schema.Option(
        display = "Villanova Wildcats",
        value = "222",
    ),
    schema.Option(
        display = "Virginia Cavaliers",
        value = "258",
    ),
    schema.Option(
        display = "Virginia Lynchburg Dragons",
        value = "2355",
    ),
    schema.Option(
        display = "Virginia State Trojans",
        value = "330",
    ),
    schema.Option(
        display = "Virginia Tech Hokies",
        value = "259",
    ),
    schema.Option(
        display = "Virginia Union Panthers",
        value = "2676",
    ),
    schema.Option(
        display = "Virginia-Wise Cavaliers",
        value = "2842",
    ),
    schema.Option(
        display = "Wabash College Little Giants",
        value = "89",
    ),
    schema.Option(
        display = "Wagner Seahawks",
        value = "2681",
    ),
    schema.Option(
        display = "Wake Forest Demon Deacons",
        value = "154",
    ),
    schema.Option(
        display = "Waldorf Warriors",
        value = "3080",
    ),
    schema.Option(
        display = "Walsh Cavaliers",
        value = "2682",
    ),
    schema.Option(
        display = "Warner Royals",
        value = "2683",
    ),
    schema.Option(
        display = "Wartburg College Knights",
        value = "2685",
    ),
    schema.Option(
        display = "Washburn Ichabods",
        value = "2687",
    ),
    schema.Option(
        display = "Washington & Jefferson Presidents",
        value = "2686",
    ),
    schema.Option(
        display = "Washington & Lee University Generals",
        value = "2688",
    ),
    schema.Option(
        display = "Washington Huskies",
        value = "264",
    ),
    schema.Option(
        display = "Washington State Cougars",
        value = "265",
    ),
    schema.Option(
        display = "Washington-Missouri Bears",
        value = "143",
    ),
    schema.Option(
        display = "Wayland Baptist Pioneers",
        value = "630",
    ),
    schema.Option(
        display = "Wayne State (MI) Warriors",
        value = "131",
    ),
    schema.Option(
        display = "Wayne State (NE) Wildcats",
        value = "2844",
    ),
    schema.Option(
        display = "Waynesburg University Yellow Jackets",
        value = "2845",
    ),
    schema.Option(
        display = "Webber International Warriors",
        value = "2691",
    ),
    schema.Option(
        display = "Weber State Wildcats",
        value = "2692",
    ),
    schema.Option(
        display = "Wesleyan University Cardinals",
        value = "336",
    ),
    schema.Option(
        display = "West Alabama Tigers",
        value = "2695",
    ),
    schema.Option(
        display = "West All-Stars",
        value = "3147",
    ),
    schema.Option(
        display = "West Chester Golden Rams",
        value = "223",
    ),
    schema.Option(
        display = "West Georgia Wolves",
        value = "2698",
    ),
    schema.Option(
        display = "West Liberty Hilltoppers",
        value = "2699",
    ),
    schema.Option(
        display = "West Texas A&M Buffaloes",
        value = "2704",
    ),
    schema.Option(
        display = "West Virginia Mountaineers",
        value = "277",
    ),
    schema.Option(
        display = "West Virginia State Yellow Jackets",
        value = "2707",
    ),
    schema.Option(
        display = "West Virginia Tech Golden Bears",
        value = "2706",
    ),
    schema.Option(
        display = "West Virginia Wesleyan Bobcats",
        value = "455",
    ),
    schema.Option(
        display = "Western Carolina Catamounts",
        value = "2717",
    ),
    schema.Option(
        display = "Western Colorado Mountaineers",
        value = "2714",
    ),
    schema.Option(
        display = "Western Connecticut State Colonials",
        value = "2843",
    ),
    schema.Option(
        display = "Western Illinois Leathernecks",
        value = "2710",
    ),
    schema.Option(
        display = "Western Kentucky Hilltoppers",
        value = "98",
    ),
    schema.Option(
        display = "Western Michigan Broncos",
        value = "2711",
    ),
    schema.Option(
        display = "Western New England Golden Bears",
        value = "2702",
    ),
    schema.Option(
        display = "Western New Mexico Mustangs",
        value = "2703",
    ),
    schema.Option(
        display = "Western Oregon Wolves",
        value = "2848",
    ),
    schema.Option(
        display = "Western Washington Vikings",
        value = "2847",
    ),
    schema.Option(
        display = "Westfield State Owls",
        value = "2909",
    ),
    schema.Option(
        display = "Westminster College (MO) Blue Jays",
        value = "433",
    ),
    schema.Option(
        display = "Westminster College (PA) Titans",
        value = "2849",
    ),
    schema.Option(
        display = "Wheaton College Illinois Thunder",
        value = "396",
    ),
    schema.Option(
        display = "Whittier College Poets",
        value = "2850",
    ),
    schema.Option(
        display = "Whitworth Pirates",
        value = "2721",
    ),
    schema.Option(
        display = "Widener University Pride",
        value = "2725",
    ),
    schema.Option(
        display = "Wilkes Colonels",
        value = "398",
    ),
    schema.Option(
        display = "Willamette Bearcats",
        value = "2930",
    ),
    schema.Option(
        display = "William & Mary Tribe",
        value = "2729",
    ),
    schema.Option(
        display = "William Jewell College Cardinals",
        value = "2911",
    ),
    schema.Option(
        display = "William Paterson Bears",
        value = "2970",
    ),
    schema.Option(
        display = "William Penn Statesmen",
        value = "2912",
    ),
    schema.Option(
        display = "Williams College Ephs",
        value = "2731",
    ),
    schema.Option(
        display = "Williamson Trade Mechanics",
        value = "3130",
    ),
    schema.Option(
        display = "Wilmington College Fightin' Quakers",
        value = "2733",
    ),
    schema.Option(
        display = "Wingate Bulldogs",
        value = "351",
    ),
    schema.Option(
        display = "Winona State Warriors",
        value = "2851",
    ),
    schema.Option(
        display = "Winston-Salem Rams",
        value = "2736",
    ),
    schema.Option(
        display = "Wisconsin Badgers",
        value = "275",
    ),
    schema.Option(
        display = "Wisconsin Lutheran Warriors",
        value = "2741",
    ),
    schema.Option(
        display = "Wisconsin-Eau Claire Blugolds",
        value = "2738",
    ),
    schema.Option(
        display = "Wisconsin-La Crosse Eagles",
        value = "2740",
    ),
    schema.Option(
        display = "Wisconsin-Oshkosh Titans",
        value = "271",
    ),
    schema.Option(
        display = "Wisconsin-Platteville Pioneers",
        value = "272",
    ),
    schema.Option(
        display = "Wisconsin-River Falls Falcons",
        value = "2723",
    ),
    schema.Option(
        display = "Wisconsin-Stevens Point Pointers",
        value = "2743",
    ),
    schema.Option(
        display = "Wisconsin-Stout Blue Devils",
        value = "2744",
    ),
    schema.Option(
        display = "Wisconsin-Whitewater Warhawks",
        value = "2745",
    ),
    schema.Option(
        display = "Wittenberg University Tigers",
        value = "2746",
    ),
    schema.Option(
        display = "Wofford Terriers",
        value = "2747",
    ),
    schema.Option(
        display = "Wooster Fighting Scots",
        value = "2748",
    ),
    schema.Option(
        display = "Worcester Polytechnic Engineers",
        value = "2749",
    ),
    schema.Option(
        display = "Worcester State College Lancers",
        value = "402",
    ),
    schema.Option(
        display = "Wright State Raiders",
        value = "2750",
    ),
    schema.Option(
        display = "Wyoming Cowboys",
        value = "2751",
    ),
    schema.Option(
        display = "Yale Bulldogs",
        value = "43",
    ),
    schema.Option(
        display = "Youngstown State Penguins",
        value = "2754",
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
            schema.Dropdown(
                id = "conferenceType",
                name = "Conference",
                desc = "Which conference to display.",
                icon = "gear",
                default = conferenceOptions[0].value,
                options = conferenceOptions,
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

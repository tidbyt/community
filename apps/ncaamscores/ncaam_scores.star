"""
Applet: NCAAM Scores
Summary: Displays NCAA Mens Basketball scores
Description: Displays live and upcoming NCAA Basketball scores from a data feed.
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
LEAGUE_DISPLAY = "NCAAM"
LEAGUE_DISPLAY_OFFSET = 7
SPORT = "basketball"
LEAGUE = "mens-college-basketball"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/scoreboard"
SHORTENED_WORDS = """
{
    " PM": "P",
    " AM": "A",
    " Wins": "",
    " Leads": "",
    " Series": "",
    " - ": " ",
    " / ": " ",
    " of": "",
    "Postponed": "PPD",
    "Overtime": "OT",
    "1st Half": "1H",
    "2nd Half": "2H"
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
                        checkhomeRecord = homeCompetitor.get("records", "NO")
                        awayCompetitor = competition["competitors"][1]
                        checkawayRecord = awayCompetitor.get("records", "NO")
                        if checkhomeRecord == "NO":
                            homeScore = ""
                        else:
                            homeScore = competition["competitors"][0]["records"][0]["summary"]
                        if checkawayRecord == "NO":
                            awayScore = ""
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

conferenceOptions = [
    schema.Option(
        display = "Top 25",
        value = "0",
    ),
    schema.Option(
        display = "Division I",
        value = "50",
    ),
    schema.Option(
        display = "A 10",
        value = "3",
    ),
    schema.Option(
        display = "ACC",
        value = "2",
    ),
    schema.Option(
        display = "ASUN",
        value = "46",
    ),
    schema.Option(
        display = "Am. East",
        value = "1",
    ),
    schema.Option(
        display = "American",
        value = "62",
    ),
    schema.Option(
        display = "Big 12",
        value = "8",
    ),
    schema.Option(
        display = "Big East",
        value = "4",
    ),
    schema.Option(
        display = "Big Sky",
        value = "5",
    ),
    schema.Option(
        display = "Big South",
        value = "6",
    ),
    schema.Option(
        display = "Big Ten",
        value = "7",
    ),
    schema.Option(
        display = "Big West",
        value = "9",
    ),
    schema.Option(
        display = "C-USA",
        value = "11",
    ),
    schema.Option(
        display = "CAA",
        value = "10",
    ),
    schema.Option(
        display = "Horizon",
        value = "45",
    ),
    schema.Option(
        display = "Indep.",
        value = "43",
    ),
    schema.Option(
        display = "Ivy",
        value = "12",
    ),
    schema.Option(
        display = "MAAC",
        value = "13",
    ),
    schema.Option(
        display = "MAC",
        value = "14",
    ),
    schema.Option(
        display = "MEAC",
        value = "16",
    ),
    schema.Option(
        display = "MVC",
        value = "18",
    ),
    schema.Option(
        display = "Mountain West",
        value = "44",
    ),
    schema.Option(
        display = "NEC",
        value = "19",
    ),
    schema.Option(
        display = "OVC",
        value = "20",
    ),
    schema.Option(
        display = "Pac-12",
        value = "21",
    ),
    schema.Option(
        display = "Patriot",
        value = "22",
    ),
    schema.Option(
        display = "SEC",
        value = "23",
    ),
    schema.Option(
        display = "SWAC",
        value = "26",
    ),
    schema.Option(
        display = "Southern",
        value = "24",
    ),
    schema.Option(
        display = "Southland",
        value = "25",
    ),
    schema.Option(
        display = "Summit",
        value = "49",
    ),
    schema.Option(
        display = "Sun Belt",
        value = "27",
    ),
    schema.Option(
        display = "WAC",
        value = "30",
    ),
    schema.Option(
        display = "WCC",
        value = "29",
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
        display = "Alcorn State Braves",
        value = "2016",
    ),
    schema.Option(
        display = "American University Eagles",
        value = "44",
    ),
    schema.Option(
        display = "Appalachian State Mountaineers",
        value = "2026",
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
        display = "Arkansas-Pine Bluff Golden Lions",
        value = "2029",
    ),
    schema.Option(
        display = "Army Black Knights",
        value = "349",
    ),
    schema.Option(
        display = "Auburn Tigers",
        value = "2",
    ),
    schema.Option(
        display = "Austin Peay Governors",
        value = "2046",
    ),
    schema.Option(
        display = "BYU Cougars",
        value = "252",
    ),
    schema.Option(
        display = "Ball State Cardinals",
        value = "2050",
    ),
    schema.Option(
        display = "Baylor Bears",
        value = "239",
    ),
    schema.Option(
        display = "Bellarmine Knights",
        value = "91",
    ),
    schema.Option(
        display = "Belmont Bruins",
        value = "2057",
    ),
    schema.Option(
        display = "Bethune-Cookman Wildcats",
        value = "2065",
    ),
    schema.Option(
        display = "Binghamton Bearcats",
        value = "2066",
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
        display = "Boston University Terriers",
        value = "104",
    ),
    schema.Option(
        display = "Bowling Green Falcons",
        value = "189",
    ),
    schema.Option(
        display = "Bradley Braves",
        value = "71",
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
        display = "Buffalo Bulls",
        value = "2084",
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
        display = "Cal State Bakersfield Roadrunners",
        value = "2934",
    ),
    schema.Option(
        display = "Cal State Fullerton Titans",
        value = "2239",
    ),
    schema.Option(
        display = "Cal State Northridge Matadors",
        value = "2463",
    ),
    schema.Option(
        display = "California Baptist Lancers",
        value = "2856",
    ),
    schema.Option(
        display = "California Golden Bears",
        value = "25",
    ),
    schema.Option(
        display = "Campbell Fighting Camels",
        value = "2097",
    ),
    schema.Option(
        display = "Canisius Golden Griffins",
        value = "2099",
    ),
    schema.Option(
        display = "Central Arkansas Bears",
        value = "2110",
    ),
    schema.Option(
        display = "Central Connecticut Blue Devils",
        value = "2115",
    ),
    schema.Option(
        display = "Central Michigan Chippewas",
        value = "2117",
    ),
    schema.Option(
        display = "Charleston Cougars",
        value = "232",
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
        display = "Chicago State Cougars",
        value = "2130",
    ),
    schema.Option(
        display = "Cincinnati Bearcats",
        value = "2132",
    ),
    schema.Option(
        display = "Clemson Tigers",
        value = "228",
    ),
    schema.Option(
        display = "Cleveland State Vikings",
        value = "325",
    ),
    schema.Option(
        display = "Coastal Carolina Chanticleers",
        value = "324",
    ),
    schema.Option(
        display = "Colgate Raiders",
        value = "2142",
    ),
    schema.Option(
        display = "Colorado Buffaloes",
        value = "38",
    ),
    schema.Option(
        display = "Colorado State Rams",
        value = "36",
    ),
    schema.Option(
        display = "Columbia Lions",
        value = "171",
    ),
    schema.Option(
        display = "Coppin State Eagles",
        value = "2154",
    ),
    schema.Option(
        display = "Cornell Big Red",
        value = "172",
    ),
    schema.Option(
        display = "Creighton Bluejays",
        value = "156",
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
        display = "DePaul Blue Demons",
        value = "305",
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
        display = "Denver Pioneers",
        value = "2172",
    ),
    schema.Option(
        display = "Detroit Mercy Titans",
        value = "2174",
    ),
    schema.Option(
        display = "Drake Bulldogs",
        value = "2181",
    ),
    schema.Option(
        display = "Drexel Dragons",
        value = "2182",
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
        display = "East Carolina Pirates",
        value = "151",
    ),
    schema.Option(
        display = "East Tennessee State Buccaneers",
        value = "2193",
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
        display = "Eastern Washington Eagles",
        value = "331",
    ),
    schema.Option(
        display = "Elon Phoenix",
        value = "2210",
    ),
    schema.Option(
        display = "Evansville Purple Aces",
        value = "339",
    ),
    schema.Option(
        display = "Fairfield Stags",
        value = "2217",
    ),
    schema.Option(
        display = "Fairleigh Dickinson Knights",
        value = "161",
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
        display = "Florida Gulf Coast Eagles",
        value = "526",
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
        display = "Fresno State Bulldogs",
        value = "278",
    ),
    schema.Option(
        display = "Furman Paladins",
        value = "231",
    ),
    schema.Option(
        display = "Gardner-Webb Runnin' Bulldogs",
        value = "2241",
    ),
    schema.Option(
        display = "George Mason Patriots",
        value = "2244",
    ),
    schema.Option(
        display = "George Washington Colonials",
        value = "45",
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
        display = "Gonzaga Bulldogs",
        value = "2250",
    ),
    schema.Option(
        display = "Grambling Tigers",
        value = "2755",
    ),
    schema.Option(
        display = "Grand Canyon Lopes",
        value = "2253",
    ),
    schema.Option(
        display = "Green Bay Phoenix",
        value = "2739",
    ),
    schema.Option(
        display = "Hampton Pirates",
        value = "2261",
    ),
    schema.Option(
        display = "Hartford Hawks",
        value = "42",
    ),
    schema.Option(
        display = "Harvard Crimson",
        value = "108",
    ),
    schema.Option(
        display = "Hawai'i Rainbow Warriors",
        value = "62",
    ),
    schema.Option(
        display = "High Point Panthers",
        value = "2272",
    ),
    schema.Option(
        display = "Hofstra Pride",
        value = "2275",
    ),
    schema.Option(
        display = "Holy Cross Crusaders",
        value = "107",
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
        display = "IUPUI Jaguars",
        value = "85",
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
        display = "Illinois Fighting Illini",
        value = "356",
    ),
    schema.Option(
        display = "Illinois State Redbirds",
        value = "2287",
    ),
    schema.Option(
        display = "Incarnate Word Cardinals",
        value = "2916",
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
        display = "Iona Gaels",
        value = "314",
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
        display = "Jackson State Tigers",
        value = "2296",
    ),
    schema.Option(
        display = "Jacksonville Dolphins",
        value = "294",
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
        display = "Kansas City Roos",
        value = "140",
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
        display = "Kennesaw State Owls",
        value = "338",
    ),
    schema.Option(
        display = "Kent State Golden Flashes",
        value = "2309",
    ),
    schema.Option(
        display = "Kentucky Wildcats",
        value = "96",
    ),
    schema.Option(
        display = "LSU Tigers",
        value = "99",
    ),
    schema.Option(
        display = "La Salle Explorers",
        value = "2325",
    ),
    schema.Option(
        display = "Lafayette Leopards",
        value = "322",
    ),
    schema.Option(
        display = "Lamar Cardinals",
        value = "2320",
    ),
    schema.Option(
        display = "Lehigh Mountain Hawks",
        value = "2329",
    ),
    schema.Option(
        display = "Liberty Flames",
        value = "2335",
    ),
    schema.Option(
        display = "Lipscomb Bisons",
        value = "288",
    ),
    schema.Option(
        display = "Little Rock Trojans",
        value = "2031",
    ),
    schema.Option(
        display = "Long Beach State Beach",
        value = "299",
    ),
    schema.Option(
        display = "Long Island University Sharks",
        value = "112358",
    ),
    schema.Option(
        display = "Longwood Lancers",
        value = "2344",
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
        display = "Loyola Chicago Ramblers",
        value = "2350",
    ),
    schema.Option(
        display = "Loyola Maryland Greyhounds",
        value = "2352",
    ),
    schema.Option(
        display = "Loyola Marymount Lions",
        value = "2351",
    ),
    schema.Option(
        display = "Maine Black Bears",
        value = "311",
    ),
    schema.Option(
        display = "Manhattan Jaspers",
        value = "2363",
    ),
    schema.Option(
        display = "Marist Red Foxes",
        value = "2368",
    ),
    schema.Option(
        display = "Marquette Golden Eagles",
        value = "269",
    ),
    schema.Option(
        display = "Marshall Thundering Herd",
        value = "276",
    ),
    schema.Option(
        display = "Maryland Terrapins",
        value = "120",
    ),
    schema.Option(
        display = "Maryland-Eastern Shore Hawks",
        value = "2379",
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
        display = "Mercer Bears",
        value = "2382",
    ),
    schema.Option(
        display = "Merrimack Warriors",
        value = "2771",
    ),
    schema.Option(
        display = "Miami (OH) Redhawks",
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
        display = "Michigan Wolverines",
        value = "130",
    ),
    schema.Option(
        display = "Middle Tennessee Blue Raiders",
        value = "2393",
    ),
    schema.Option(
        display = "Milwaukee Panthers",
        value = "270",
    ),
    schema.Option(
        display = "Minnesota Golden Gophers",
        value = "135",
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
        display = "Missouri State Bears",
        value = "2623",
    ),
    schema.Option(
        display = "Missouri Tigers",
        value = "142",
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
        display = "Morehead State Eagles",
        value = "2413",
    ),
    schema.Option(
        display = "Morgan State Bears",
        value = "2415",
    ),
    schema.Option(
        display = "Mount St. Mary's Mountaineers",
        value = "116",
    ),
    schema.Option(
        display = "Murray State Racers",
        value = "93",
    ),
    schema.Option(
        display = "NC State Wolfpack",
        value = "152",
    ),
    schema.Option(
        display = "NJIT Highlanders",
        value = "2885",
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
        display = "Nevada Wolf Pack",
        value = "2440",
    ),
    schema.Option(
        display = "New Hampshire Wildcats",
        value = "160",
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
        display = "New Orleans Privateers",
        value = "2443",
    ),
    schema.Option(
        display = "Niagara Purple Eagles",
        value = "315",
    ),
    schema.Option(
        display = "Nicholls Colonels",
        value = "2447",
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
        display = "North Carolina Tar Heels",
        value = "153",
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
        display = "North Florida Ospreys",
        value = "2454",
    ),
    schema.Option(
        display = "North Texas Mean Green",
        value = "249",
    ),
    schema.Option(
        display = "Northeastern Huskies",
        value = "111",
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
        display = "Northern Kentucky Norse",
        value = "94",
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
        display = "Notre Dame Fighting Irish",
        value = "87",
    ),
    schema.Option(
        display = "Oakland Golden Grizzlies",
        value = "2473",
    ),
    schema.Option(
        display = "Ohio Bobcats",
        value = "195",
    ),
    schema.Option(
        display = "Ohio State Buckeyes",
        value = "194",
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
        display = "Omaha Mavericks",
        value = "2437",
    ),
    schema.Option(
        display = "Oral Roberts Golden Eagles",
        value = "198",
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
        display = "Pacific Tigers",
        value = "279",
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
        display = "Pepperdine Waves",
        value = "2492",
    ),
    schema.Option(
        display = "Pittsburgh Panthers",
        value = "221",
    ),
    schema.Option(
        display = "Portland Pilots",
        value = "2501",
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
        display = "Princeton Tigers",
        value = "163",
    ),
    schema.Option(
        display = "Providence Friars",
        value = "2507",
    ),
    schema.Option(
        display = "Purdue Boilermakers",
        value = "2509",
    ),
    schema.Option(
        display = "Purdue Fort Wayne Mastodons",
        value = "2870",
    ),
    schema.Option(
        display = "Quinnipiac Bobcats",
        value = "2514",
    ),
    schema.Option(
        display = "Radford Highlanders",
        value = "2515",
    ),
    schema.Option(
        display = "Rhode Island Rams",
        value = "227",
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
        display = "Rider Broncs",
        value = "2520",
    ),
    schema.Option(
        display = "Robert Morris Colonials",
        value = "2523",
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
        display = "SIU Edwardsville Cougars",
        value = "2565",
    ),
    schema.Option(
        display = "SMU Mustangs",
        value = "2567",
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
        display = "Saint Joseph's Hawks",
        value = "2603",
    ),
    schema.Option(
        display = "Saint Louis Billikens",
        value = "139",
    ),
    schema.Option(
        display = "Saint Mary's Gaels",
        value = "2608",
    ),
    schema.Option(
        display = "Saint Peter's Peacocks",
        value = "2612",
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
        display = "San Francisco Dons",
        value = "2539",
    ),
    schema.Option(
        display = "San José State Spartans",
        value = "23",
    ),
    schema.Option(
        display = "Santa Clara Broncos",
        value = "2541",
    ),
    schema.Option(
        display = "Seattle U Redhawks",
        value = "2547",
    ),
    schema.Option(
        display = "Seton Hall Pirates",
        value = "2550",
    ),
    schema.Option(
        display = "Siena Saints",
        value = "2561",
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
        display = "South Carolina Upstate Spartans",
        value = "2908",
    ),
    schema.Option(
        display = "South Dakota Coyotes",
        value = "233",
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
        display = "Southern Utah Thunderbirds",
        value = "253",
    ),
    schema.Option(
        display = "St. Bonaventure Bonnies",
        value = "179",
    ),
    schema.Option(
        display = "St. Francis (PA) Red Flash",
        value = "2598",
    ),
    schema.Option(
        display = "St. Francis Brooklyn Terriers",
        value = "2597",
    ),
    schema.Option(
        display = "St. John's Red Storm",
        value = "2599",
    ),
    schema.Option(
        display = "St. Thomas - Minnesota Tommies",
        value = "2900",
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
        display = "Stetson Hatters",
        value = "56",
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
        display = "Texas A&M-Corpus Christi Islanders",
        value = "357",
    ),
    schema.Option(
        display = "Texas Longhorns",
        value = "251",
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
        display = "Toledo Rockets",
        value = "2649",
    ),
    schema.Option(
        display = "Towson Tigers",
        value = "119",
    ),
    schema.Option(
        display = "Troy Trojans",
        value = "2653",
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
        display = "UAB Blazers",
        value = "5",
    ),
    schema.Option(
        display = "UC Davis Aggies",
        value = "302",
    ),
    schema.Option(
        display = "UC Irvine Anteaters",
        value = "300",
    ),
    schema.Option(
        display = "UC Riverside Highlanders",
        value = "27",
    ),
    schema.Option(
        display = "UC San Diego Tritons",
        value = "28",
    ),
    schema.Option(
        display = "UC Santa Barbara Gauchos",
        value = "2540",
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
        display = "UIC Flames",
        value = "82",
    ),
    schema.Option(
        display = "UL Monroe Warhawks",
        value = "2433",
    ),
    schema.Option(
        display = "UMBC Retrievers",
        value = "2378",
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
        display = "UNC Asheville Bulldogs",
        value = "2427",
    ),
    schema.Option(
        display = "UNC Greensboro Spartans",
        value = "2430",
    ),
    schema.Option(
        display = "UNC Wilmington Seahawks",
        value = "350",
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
        display = "UT Arlington Mavericks",
        value = "250",
    ),
    schema.Option(
        display = "UT Martin Skyhawks",
        value = "2630",
    ),
    schema.Option(
        display = "UT Rio Grande Valley Vaqueros",
        value = "292",
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
        display = "Utah Valley Wolverines",
        value = "3084",
    ),
    schema.Option(
        display = "VCU Rams",
        value = "2670",
    ),
    schema.Option(
        display = "VMI Keydets",
        value = "2678",
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
        display = "Vermont Catamounts",
        value = "261",
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
        display = "Virginia Tech Hokies",
        value = "259",
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
        display = "Washington Huskies",
        value = "264",
    ),
    schema.Option(
        display = "Washington State Cougars",
        value = "265",
    ),
    schema.Option(
        display = "Weber State Wildcats",
        value = "2692",
    ),
    schema.Option(
        display = "West Virginia Mountaineers",
        value = "277",
    ),
    schema.Option(
        display = "Western Carolina Catamounts",
        value = "2717",
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
        display = "Wichita State Shockers",
        value = "2724",
    ),
    schema.Option(
        display = "William & Mary Tribe",
        value = "2729",
    ),
    schema.Option(
        display = "Winthrop Eagles",
        value = "2737",
    ),
    schema.Option(
        display = "Wisconsin Badgers",
        value = "275",
    ),
    schema.Option(
        display = "Wofford Terriers",
        value = "2747",
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
        display = "Xavier Musketeers",
        value = "2752",
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

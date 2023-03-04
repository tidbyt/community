"""
Applet: NCAA Softball Scores
Summary: Displays NCAA Softball scores
Description: Displays live and upcoming NCAA Softball scores from a data feed.
Author: LunchBox8484
"""

load("animation.star", "animation")
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
LEAGUE_DISPLAY = "CSOFT"
LEAGUE_DISPLAY_OFFSET = 4
SPORT = "baseball"
LEAGUE = "college-softball"
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
    "MICH" : "https://b.fssta.com/uploads/application/college/team-logos/Michigan.vresize.50.50.medium.1.png",
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
    "NU" : "https://b.fssta.com/uploads/application/college/team-logos/Northwestern-alternate.vresize.50.50.medium.0.png",
    "LBSU" : "https://b.fssta.com/uploads/application/college/team-logos/LongBeachState.vresize.50.50.medium.0.png"
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
STYLE_ATTRIBUTES = """
{
    "retro": {
        "textColor": "#ffe065",
        "backgroundColor": "#222222",
        "borderColor": "#222222",
        "textFont": "CG-pixel-3x5-mono"
    },
    "stadium": {
        "textColor": "#ffffff",
        "backgroundColor": "#0f3027",
        "borderColor": "#345252",
        "textFont": "tb-8"
    },
    "horizontal": {
        "textColor": "#ffffff",
        "backgroundColor": "#000000",
        "borderColor": "#000000",
        "textFont": "Dina_r400-6"
    },
    "logos": {
        "textColor": "#fff",
        "backgroundColor": "#000000",
        "borderColor": "#000000",
        "textFont": "Dina_r400-6"
    },
    "black": {
        "textColor": "#fff",
        "backgroundColor": "#000000",
        "borderColor": "#000000",
        "textFont": "Dina_r400-6"
    },
    "colors": {
        "textColor": "#fff",
        "backgroundColor": "#000000",
        "borderColor": "#000000",
        "textFont": "Dina_r400-6"
    }
}
"""

### FUNCTIONS ###

def main(config):
    renderCategory = []

    showRanking = config.bool("displayRanking", True)
    selectedTeam = config.get("selectedTeam", "all")
    displayType = config.get("displayType", "colors")
    displayTop = config.get("displayTop", "league")
    pregameDisplay = config.get("pregameDisplay", "record")
    timeColor = config.get("displayTimeColor", "#FFA500")
    rotationSpeed = config.get("rotationSpeed", "10")
    location = config.get("location", DEFAULT_LOCATION)
    showAnimations = config.bool("showAnimations", True)

    shortenedWords = json.decode(SHORTENED_WORDS)
    altColors = json.decode(ALT_COLOR)
    altLogos = json.decode(ALT_LOGO)
    magnifyLogo = json.decode(MAGNIFY_LOGO)
    styleAttributes = json.decode(STYLE_ATTRIBUTES)
    loc = json.decode(location)

    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    datePast = now - time.parse_duration("%dh" % 1 * 24)
    dateFuture = now + time.parse_duration("%dh" % 6 * 24)
    league = {LEAGUE: API + "?limit=300" + (selectedTeam == "all" and " " or "&dates=" + datePast.format("20060102") + "-" + dateFuture.format("20060102"))}
    scores = get_scores(league, selectedTeam)

    if len(scores) > 0:
        animationDuration = int(rotationSpeed) * 20
        delayDuration = int(animationDuration * float(.75 / (int(rotationSpeed) * 2)))
        animationPercentage1 = float(.75 / (int(rotationSpeed) * 2))
        animationPercentage2 = float(1 - float(.75 / (int(rotationSpeed) * 2)))
        logoKeyframes = []
        homeBarKeyframes = []
        awayBarKeyframes = []
        scoreKeyframes = []
        teamKeyframes = []
        screenKeyframes = []

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

            homeColor = get_background_color(altColors, home, displayType, homePrimaryColor)
            awayColor = get_background_color(altColors, away, displayType, awayPrimaryColor)

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

            homeLogo = get_logoType(altLogos, home, homeLogoURL)
            awayLogo = get_logoType(altLogos, away, awayLogoURL)
            homeLogoSize = get_logoSize(magnifyLogo, home)
            awayLogoSize = get_logoSize(magnifyLogo, away)
            homeScore = ""
            awayScore = ""
            gameTime = ""
            homeScoreColor = "#fff"
            awayScoreColor = "#fff"
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
                if checkSeries != "NO":
                    seriesSummary = competition["series"]["summary"]
                    gameTime = seriesSummary.replace("series ", "")
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
                teamKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 0, 12)

                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Column(
                                                children = [
                                                    render.Column(
                                                        children = [
                                                            render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                animation.Transformation(
                                                                    child = render.Box(width = 40, height = 12, color = styleAttributes[displayType]["borderColor"], child = render.Text(content = get_team_name(awayTeamName), color = styleAttributes[displayType]["textColor"], font = styleAttributes[displayType]["textFont"])),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 40,
                                                                    height = 12,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 26, height = 12, color = styleAttributes[displayType]["borderColor"], child = render.Text(content = get_record(awayScore), color = styleAttributes[displayType]["textColor"], font = styleAttributes[displayType]["textFont"])),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 26,
                                                                    height = 12,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                            ]),
                                                            render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                animation.Transformation(
                                                                    child = render.Box(width = 40, height = 12, color = styleAttributes[displayType]["borderColor"], child = render.Text(content = get_team_name(homeTeamName), color = styleAttributes[displayType]["textColor"], font = styleAttributes[displayType]["textFont"])),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 40,
                                                                    height = 12,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 26, height = 12, color = styleAttributes[displayType]["borderColor"], child = render.Text(content = get_record(homeScore), color = styleAttributes[displayType]["textColor"], font = styleAttributes[displayType]["textFont"])),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 26,
                                                                    height = 12,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                            ]),
                                                        ],
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

            elif displayType == "stadium":
                teamKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 0, 12)

                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Column(
                                                children = [
                                                    render.Column(
                                                        children = [
                                                            render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 29, height = 10, child = render.Box(width = 29, height = 10, color = styleAttributes[displayType]["backgroundColor"], child = render.Text(content = away[:4].upper(), color = awayScoreColor, font = styleAttributes[displayType]["textFont"]))),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 29,
                                                                    height = 10,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 29, height = 10, child = render.Box(width = 29, height = 10, color = styleAttributes[displayType]["backgroundColor"], child = render.Text(content = get_record(awayScore), color = awayScoreColor, font = scoreFont))),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 29,
                                                                    height = 10,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                            ]),
                                                            render.Box(width = 64, height = 2, color = styleAttributes[displayType]["borderColor"]),
                                                            render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 29, height = 10, child = render.Box(width = 29, height = 10, color = styleAttributes[displayType]["backgroundColor"], child = render.Text(content = home[:4].upper(), color = homeScoreColor, font = styleAttributes[displayType]["textFont"]))),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 29,
                                                                    height = 10,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                                animation.Transformation(
                                                                    child = render.Box(width = 29, height = 10, child = render.Box(width = 29, height = 10, color = styleAttributes[displayType]["backgroundColor"], child = render.Text(content = get_record(homeScore), color = homeScoreColor, font = scoreFont))),
                                                                    duration = animationDuration - delayDuration,
                                                                    delay = delayDuration,
                                                                    width = 29,
                                                                    height = 10,
                                                                    keyframes = teamKeyframes,
                                                                ),
                                                                render.Box(width = 2, height = 10, color = styleAttributes[displayType]["borderColor"]),
                                                            ]),
                                                        ],
                                                    ),
                                                    render.Box(width = 64, height = 1, color = styleAttributes[displayType]["borderColor"]),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

            elif displayType == "horizontal":
                homeBarKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 64, 0)
                awayBarKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, -64, 0)
                logoKeyframes = []
                scoreKeyframes = []
                nameKeyframes = []

                if showAnimations == True:
                    logoKeyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Scale(0.001, 0.001)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = animationPercentage1,
                            transforms = [animation.Scale(1, 1)],
                            curve = "ease_in_out",
                        ),
                    ]
                    nameKeyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -17)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = animationPercentage1,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                    ]
                    scoreKeyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 17)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = animationPercentage1,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                    ]

                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        children = [
                                            animation.Transformation(
                                                child =
                                                    render.Box(
                                                        width = 32,
                                                        height = 24,
                                                        color = "#0a0",
                                                        child = render.Row(
                                                            expanded = True,
                                                            main_align = "start",
                                                            cross_align = "center",
                                                            children = [
                                                                render.Box(width = 32, height = 24, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                        render.Stack(children = [
                                                                            animation.Transformation(
                                                                                child = render.Box(width = 32, height = 24, child = render.Image(awayLogo, width = 32, height = 32)),
                                                                                duration = animationDuration - delayDuration,
                                                                                delay = delayDuration,
                                                                                origin = animation.Origin(0.5, 0.5),
                                                                                width = 32,
                                                                                height = 24,
                                                                                keyframes = logoKeyframes,
                                                                            ),
                                                                            animation.Transformation(
                                                                                child =
                                                                                    render.Box(width = 32, height = 24, color = awayColor + "aa"),
                                                                                duration = animationDuration - delayDuration * 2,
                                                                                delay = delayDuration * 2,
                                                                                origin = animation.Origin(0.5, 0.5),
                                                                                width = 32,
                                                                                height = 8,
                                                                                keyframes = logoKeyframes,
                                                                            ),
                                                                            render.Column(
                                                                                main_align = "center",
                                                                                cross_align = "center",
                                                                                children = get_horizontal_logo_box(away[:4], awayScore, awayScoreColor, scoreFont, animationDuration, delayDuration, nameKeyframes, scoreKeyframes),
                                                                            ),
                                                                        ]),
                                                                    ]),
                                                                ])),
                                                            ],
                                                        ),
                                                    ),
                                                duration = animationDuration,
                                                width = 32,
                                                height = 24,
                                                keyframes = awayBarKeyframes,
                                            ),
                                            animation.Transformation(
                                                child =
                                                    render.Box(
                                                        width = 32,
                                                        height = 24,
                                                        color = "#0a0",
                                                        child = render.Row(
                                                            expanded = True,
                                                            main_align = "start",
                                                            cross_align = "center",
                                                            children = [
                                                                render.Box(width = 32, height = 24, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                        render.Stack(children = [
                                                                            animation.Transformation(
                                                                                child = render.Box(width = 32, height = 24, child = render.Image(homeLogo, width = 32, height = 32)),
                                                                                duration = animationDuration - delayDuration,
                                                                                delay = delayDuration,
                                                                                origin = animation.Origin(0.5, 0.5),
                                                                                width = 32,
                                                                                height = 24,
                                                                                keyframes = logoKeyframes,
                                                                            ),
                                                                            animation.Transformation(
                                                                                child =
                                                                                    render.Box(width = 32, height = 24, color = homeColor + "aa"),
                                                                                duration = animationDuration - delayDuration * 2,
                                                                                delay = delayDuration * 2,
                                                                                origin = animation.Origin(0.5, 0.5),
                                                                                width = 32,
                                                                                height = 8,
                                                                                keyframes = logoKeyframes,
                                                                            ),
                                                                            render.Column(
                                                                                main_align = "center",
                                                                                cross_align = "center",
                                                                                children = get_horizontal_logo_box(home[:4], homeScore, homeScoreColor, scoreFont, animationDuration, delayDuration, nameKeyframes, scoreKeyframes),
                                                                            ),
                                                                        ]),
                                                                    ]),
                                                                ])),
                                                            ],
                                                        ),
                                                    ),
                                                duration = animationDuration,
                                                width = 32,
                                                height = 24,
                                                keyframes = homeBarKeyframes,
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

            elif displayType == "logos":
                homeBarKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 64, 0)
                awayBarKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, -64, 0)
                logoKeyframes = []
                scoreKeyframes = []

                if showAnimations == True:
                    logoKeyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Scale(0.001, 0.001)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = animationPercentage1,
                            transforms = [animation.Scale(1, 1)],
                            curve = "ease_in_out",
                        ),
                    ]
                    scoreKeyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(34, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = animationPercentage1,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                    ]

                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Column(
                                                children = [
                                                    render.Column(
                                                        children = [
                                                            animation.Transformation(
                                                                child =
                                                                    render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                        animation.Transformation(
                                                                            child = render.Image(awayLogo, width = 30, height = 30),
                                                                            duration = animationDuration - delayDuration,
                                                                            delay = delayDuration,
                                                                            origin = animation.Origin(0.5, 0.5),
                                                                            width = 30,
                                                                            height = 30,
                                                                            keyframes = logoKeyframes,
                                                                        ),
                                                                        animation.Transformation(
                                                                            child = render.Box(width = 34, height = 12, child = render.Text(content = awayScore, color = awayScoreColor, font = scoreFont)),
                                                                            duration = animationDuration - delayDuration * 2,
                                                                            delay = delayDuration * 2,
                                                                            width = 34,
                                                                            height = 12,
                                                                            keyframes = scoreKeyframes,
                                                                        ),
                                                                    ])),
                                                                duration = animationDuration,
                                                                width = 64,
                                                                height = 12,
                                                                keyframes = awayBarKeyframes,
                                                            ),
                                                            animation.Transformation(
                                                                child =
                                                                    render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                        animation.Transformation(
                                                                            child = render.Image(homeLogo, width = 30, height = 30),
                                                                            duration = animationDuration - delayDuration,
                                                                            delay = delayDuration,
                                                                            origin = animation.Origin(0.5, 0.5),
                                                                            width = 30,
                                                                            height = 30,
                                                                            keyframes = logoKeyframes,
                                                                        ),
                                                                        animation.Transformation(
                                                                            child = render.Box(width = 34, height = 12, child = render.Text(content = homeScore, color = homeScoreColor, font = scoreFont)),
                                                                            duration = animationDuration - delayDuration * 2,
                                                                            delay = delayDuration * 2,
                                                                            width = 34,
                                                                            height = 12,
                                                                            keyframes = scoreKeyframes,
                                                                        ),
                                                                    ])),
                                                                duration = animationDuration,
                                                                width = 64,
                                                                height = 24,
                                                                keyframes = homeBarKeyframes,
                                                            ),
                                                        ],
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

            elif displayType == "black":
                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Column(
                                                children = [
                                                    get_team_bar(showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, away, "away", awayLogo, "#222222", awayScoreColor, awayLogoSize, awayScore, showRanking, awayRank, styleAttributes[displayType]["textFont"], scoreFont),
                                                    get_team_bar(showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, home, "home", homeLogo, "#222222", homeScoreColor, homeLogoSize, homeScore, showRanking, homeRank, styleAttributes[displayType]["textFont"], scoreFont),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

            else:
                renderCategory.extend(
                    [
                        animation.Transformation(
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = get_date_column(displayTop, shortenedWords, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Column(
                                                children = [
                                                    get_team_bar(showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, away, "away", awayLogo, awayColor, awayScoreColor, awayLogoSize, awayScore, showRanking, awayRank, styleAttributes[displayType]["textFont"], scoreFont),
                                                    get_team_bar(showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, home, "home", homeLogo, homeColor, homeScoreColor, homeLogoSize, homeScore, showRanking, homeRank, styleAttributes[displayType]["textFont"], scoreFont),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                            duration = animationDuration,
                            width = 64,
                            height = 32,
                            keyframes = screenKeyframes,
                        ),
                    ],
                )

        if showAnimations == True:
            return render.Root(
                show_full_animation = True,
                child =
                    render.Stack(children = [
                        render.Box(width = 64, height = 32, color = styleAttributes[displayType]["borderColor"]),
                        render.Sequence(
                            children = renderCategory,
                        ),
                    ]),
            )
        else:
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

def get_odds(theOdds, theOU, team, homeaway):
    theOddsarray = theOdds.split(" ")
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

def get_record_animation(teamScore, teamScoreColor, scoreFont, animationDuration, delayDuration, scoreKeyframes):
    if len(teamScore) == 7:
        scoreBoxWidth = 30
        scoreBoxOffset = 2
    elif len(teamScore) > 7:
        scoreBoxWidth = 32
        scoreBoxOffset = 4
    else:
        scoreBoxWidth = 24
        scoreBoxOffset = 0

    record = animation.Transformation(
        child = render.Box(width = 24, height = 12, child = animation.Transformation(
            child = render.Box(width = scoreBoxWidth, height = 12, child = render.Text(content = teamScore[:8], color = teamScoreColor, font = scoreFont)),
            duration = animationDuration - delayDuration * 4,
            delay = delayDuration * 4,
            width = scoreBoxWidth,
            height = 12,
            direction = "alternate",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(scoreBoxOffset, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(scoreBoxOffset, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.35,
                    transforms = [animation.Translate(0 - scoreBoxOffset, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.65,
                    transforms = [animation.Translate(0 - scoreBoxOffset, 0)],
                ),
                animation.Keyframe(
                    percentage = 0.75,
                    transforms = [animation.Translate(scoreBoxOffset, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(scoreBoxOffset, 0)],
                ),
            ],
        )),
        duration = animationDuration - delayDuration * 2,
        delay = delayDuration * 2,
        width = 24,
        height = 12,
        wait_for_child = False,
        keyframes = scoreKeyframes,
    )
    return record

def get_background_color(altcolors, team, displayType, color):
    usealt = altcolors.get(team, "NO")
    if displayType == "black" or displayType == "retro":
        color = "#222222"
    elif usealt != "NO":
        color = altcolors[team]
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#222222"
    return color

def get_logoType(usealtlogo, team, logo):
    usealt = usealtlogo.get(team, "NO")
    if usealt != "NO":
        logo = get_cachable_data(usealt, 604800)
    else:
        logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
        logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=")
        logo = get_cachable_data(logo + "&h=50&w=50", 604800)
    return logo

def get_logoSize(usealtsize, team):
    usealt = usealtsize.get(team, "NO")
    if usealt != "NO":
        logosize = int(usealtsize[team])
    else:
        logosize = int(16)
    return logosize

def get_date_column(displayTop, shortenedWords, now, scoreNumber, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor):
    if displayTop == "gameinfo":
        dateTimeColumn = [
            animation.Transformation(
                child = render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                    render.Text(color = displayType == "retro" and textColor or timeColor, content = gameTime, font = "CG-pixel-3x5-mono"),
                ])),
                duration = animationDuration - delayDuration * 2,
                delay = delayDuration * 2,
                width = 64,
                height = 8,
                keyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 0, -8),
            ),
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
            animation.Transformation(
                child = render.Box(width = timeBox, height = 8, child = render.Stack(children = [
                    render.Box(width = timeBox, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                        render.Box(width = 1, height = 8),
                        render.Text(color = displayType == "retro" and textColor or timeColor, content = theTime, font = "tb-8"),
                    ])),
                ])),
                duration = 1,
                width = timeBox,
                height = 8,
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Scale(0, 0)],
                    ),
                    animation.Keyframe(
                        percentage = 0.01,
                        transforms = [animation.Scale(1, 1)],
                    ),
                ],
            ),
            animation.Transformation(
                child = render.Box(width = statusBox, height = 8, child = render.Stack(children = [
                    render.Box(width = statusBox, height = 8, color = borderColor),
                    render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                        render.Text(color = textColor, content = get_shortened_display(shortenedWords, gameTime), font = "CG-pixel-3x5-mono"),
                    ])),
                ])),
                duration = animationDuration - delayDuration * 2,
                delay = delayDuration * 2,
                width = statusBox,
                height = 8,
                wait_for_child = False,
                keyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, 0, -8),
            ),
        ]
    return dateTimeColumn

def get_team_bar(showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, team, teamHomeAway, teamLogo, teamColor, teamScoreColor, teamLogoSize, teamScore, showRanking, teamRank, textFont, scoreFont):
    rankSize = 0
    barKeyframes = []
    logoKeyframes = []
    teamKeyframes = []
    scoreKeyframes = []
    barKeyframes = get_animation(showAnimations, animationPercentage1, animationPercentage2, teamHomeAway == "home" and -64 or 64, 0)

    if showAnimations == True:
        logoKeyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Scale(0.001, 0.001)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = animationPercentage1,
                transforms = [animation.Scale(1, 1)],
                curve = "ease_in_out",
            ),
        ]
        teamKeyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(0, 12)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = animationPercentage1,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
        ]
        scoreKeyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(24, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = animationPercentage1,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
        ]

    if showRanking and teamRank > 0 and teamRank < 26:
        if teamRank < 10:
            rankSize = 4
        else:
            rankSize = 8

    if showRanking and teamRank < 26:
        imageArea = render.Stack(children = [
            render.Box(width = 16, height = 12, child = render.Image(teamLogo, width = teamLogoSize, height = teamLogoSize)),
            render.Column(
                expanded = True,
                main_align = "end",
                cross_align = "start",
                children = [
                    render.Row(children = [
                        render.Box(width = 1, height = 5, color = "#000b"),
                        render.Box(width = rankSize, height = 5, color = "#000b", child = render.Text(str(teamRank), color = teamScoreColor, font = "CG-pixel-3x5-mono")),
                    ]),
                ],
            ),
        ])
    else:
        imageArea = render.Box(width = 16, height = 12, child = render.Image(teamLogo, width = teamLogoSize, height = teamLogoSize))

    teamBar = animation.Transformation(
        child =
            render.Box(width = 64, height = 12, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                animation.Transformation(
                    child = imageArea,
                    duration = animationDuration - delayDuration,
                    delay = delayDuration,
                    width = 16,
                    height = 12,
                    keyframes = logoKeyframes,
                ),
                animation.Transformation(
                    child = render.Box(width = 24, height = 12, child = render.Text(content = team[:4], color = teamScoreColor, font = textFont)),
                    duration = animationDuration - delayDuration,
                    delay = delayDuration,
                    width = 24,
                    height = 12,
                    keyframes = teamKeyframes,
                ),
                get_record_animation(teamScore, teamScoreColor, scoreFont, animationDuration, delayDuration, scoreKeyframes),
            ])),
        duration = animationDuration,
        width = 64,
        height = 12,
        keyframes = barKeyframes,
    )
    return teamBar

def get_horizontal_logo_box(team, teamScore, teamScoreColor, scoreFont, animationDuration, delayDuration, nameKeyframes, scoreKeyframes):
    teamBar = []

    if teamScore != "":
        teamBar.extend([
            render.Box(width = 32, height = 4),
        ])

    teamBar.extend(
        [animation.Transformation(
            child = render.Box(width = 32, height = teamScore != "" and 8 or 24, child = render.Text(content = team, color = teamScoreColor, font = "Dina_r400-6")),
            duration = animationDuration - delayDuration * 2,
            delay = delayDuration * 2,
            origin = animation.Origin(0.5, 0.5),
            width = 32,
            height = teamScore != "" and 8 or 24,
            keyframes = nameKeyframes,
        )],
    )

    if teamScore != "":
        teamBar.extend(
            [animation.Transformation(
                child =
                    render.Box(width = 32, height = 8, child = render.Text(content = teamScore, color = teamScoreColor, font = scoreFont)),
                duration = animationDuration - delayDuration * 2,
                delay = delayDuration * 2,
                origin = animation.Origin(0.5, 0.5),
                width = 32,
                height = 8,
                keyframes = scoreKeyframes,
            )],
        )
        teamBar.extend([
            render.Box(width = 32, height = 4),
        ])
    return teamBar

def get_shortened_display(words, text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    for _, s in enumerate(words):
        text = text.replace(s, words[s])
    return text

def get_animation(showAnimations, animationPercentage1, animationPercentage2, x, y):
    if showAnimations == True:
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(x, y)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = animationPercentage1,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = animationPercentage2,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(x, y)],
                curve = "ease_in_out",
            ),
        ]
    else:
        keyframes = []
    return keyframes

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
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gear",
                default = rotationOptions[7].value,
                options = rotationOptions,
            ),
            schema.Toggle(
                id = "showAnimations",
                name = "Animations",
                desc = "A toggle to show animations between games.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "displayRanking",
                name = "Show Rank",
                desc = "A toggle to display the top 25 ranking.",
                icon = "gear",
                default = True,
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
                id = "displayType",
                name = "Display Style",
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

### SCHEMA OPTIONS ###

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

teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "all",
    ),
    schema.Option(
        display = "Abilene Christian",
        value = "669",
    ),
    schema.Option(
        display = "Air Force",
        value = "567",
    ),
    schema.Option(
        display = "Akron",
        value = "670",
    ),
    schema.Option(
        display = "Alabama",
        value = "560",
    ),
    schema.Option(
        display = "Alabama A&M",
        value = "671",
    ),
    schema.Option(
        display = "Alabama State",
        value = "672",
    ),
    schema.Option(
        display = "Alabama-Huntsville",
        value = "860",
    ),
    schema.Option(
        display = "Albany",
        value = "566",
    ),
    schema.Option(
        display = "Albany State (GA)",
        value = "861",
    ),
    schema.Option(
        display = "Alcorn State",
        value = "623",
    ),
    schema.Option(
        display = "American University",
        value = "673",
    ),
    schema.Option(
        display = "Appalachian State",
        value = "634",
    ),
    schema.Option(
        display = "Arizona",
        value = "472",
    ),
    schema.Option(
        display = "Arizona State",
        value = "471",
    ),
    schema.Option(
        display = "Arkansas",
        value = "470",
    ),
    schema.Option(
        display = "Arkansas State",
        value = "674",
    ),
    schema.Option(
        display = "Arkansas-Pine Bluff",
        value = "675",
    ),
    schema.Option(
        display = "Army",
        value = "563",
    ),
    schema.Option(
        display = "Ashford",
        value = "862",
    ),
    schema.Option(
        display = "Auburn",
        value = "467",
    ),
    schema.Option(
        display = "Austin Peay",
        value = "568",
    ),
    schema.Option(
        display = "Austin State",
        value = "863",
    ),
    schema.Option(
        display = "BYU",
        value = "539",
    ),
    schema.Option(
        display = "Bacone College",
        value = "854",
    ),
    schema.Option(
        display = "Ball State",
        value = "569",
    ),
    schema.Option(
        display = "Baylor",
        value = "533",
    ),
    schema.Option(
        display = "Belhaven University",
        value = "864",
    ),
    schema.Option(
        display = "Bellarmine",
        value = "1150",
    ),
    schema.Option(
        display = "Belmont",
        value = "625",
    ),
    schema.Option(
        display = "Benedict College",
        value = "865",
    ),
    schema.Option(
        display = "Bethel (TN)",
        value = "866",
    ),
    schema.Option(
        display = "Bethune-Cookman",
        value = "570",
    ),
    schema.Option(
        display = "Binghamton",
        value = "646",
    ),
    schema.Option(
        display = "Birmingham Southern",
        value = "468",
    ),
    schema.Option(
        display = "Boise State",
        value = "676",
    ),
    schema.Option(
        display = "Boston College",
        value = "498",
    ),
    schema.Option(
        display = "Boston University",
        value = "677",
    ),
    schema.Option(
        display = "Bowling Green",
        value = "518",
    ),
    schema.Option(
        display = "Bradley",
        value = "678",
    ),
    schema.Option(
        display = "Brewton Parker College",
        value = "867",
    ),
    schema.Option(
        display = "Brown",
        value = "528",
    ),
    schema.Option(
        display = "Bryant",
        value = "653",
    ),
    schema.Option(
        display = "Bucknell",
        value = "667",
    ),
    schema.Option(
        display = "Buffalo",
        value = "679",
    ),
    schema.Option(
        display = "Butler",
        value = "680",
    ),
    schema.Option(
        display = "Cabrini College",
        value = "868",
    ),
    schema.Option(
        display = "Cal Poly",
        value = "473",
    ),
    schema.Option(
        display = "Cal State Bakersfield",
        value = "681",
    ),
    schema.Option(
        display = "Cal State Fullerton",
        value = "577",
    ),
    schema.Option(
        display = "Cal State Northridge",
        value = "597",
    ),
    schema.Option(
        display = "California",
        value = "477",
    ),
    schema.Option(
        display = "California Baptist",
        value = "1104",
    ),
    schema.Option(
        display = "Campbell",
        value = "647",
    ),
    schema.Option(
        display = "Campbellsville",
        value = "869",
    ),
    schema.Option(
        display = "Canisius",
        value = "652",
    ),
    schema.Option(
        display = "Case Western Reserve",
        value = "870",
    ),
    schema.Option(
        display = "Centenary",
        value = "855",
    ),
    schema.Option(
        display = "Central Arkansas",
        value = "660",
    ),
    schema.Option(
        display = "Central Baptist",
        value = "871",
    ),
    schema.Option(
        display = "Central Connecticut",
        value = "571",
    ),
    schema.Option(
        display = "Central Methodist",
        value = "872",
    ),
    schema.Option(
        display = "Central Michigan",
        value = "682",
    ),
    schema.Option(
        display = "Centre",
        value = "873",
    ),
    schema.Option(
        display = "Charleston",
        value = "530",
    ),
    schema.Option(
        display = "Charleston Southern",
        value = "683",
    ),
    schema.Option(
        display = "Charlotte",
        value = "592",
    ),
    schema.Option(
        display = "Chattanooga",
        value = "684",
    ),
    schema.Option(
        display = "Chicago State",
        value = "685",
    ),
    schema.Option(
        display = "Christian Brothers",
        value = "874",
    ),
    schema.Option(
        display = "Cincinnati",
        value = "573",
    ),
    schema.Option(
        display = "Claflin",
        value = "875",
    ),
    schema.Option(
        display = "Clark Atlanta",
        value = "876",
    ),
    schema.Option(
        display = "Clemson",
        value = "529",
    ),
    schema.Option(
        display = "Clemson",
        value = "1140",
    ),
    schema.Option(
        display = "Cleveland State",
        value = "686",
    ),
    schema.Option(
        display = "Coastal Carolina",
        value = "558",
    ),
    schema.Option(
        display = "Colgate",
        value = "687",
    ),
    schema.Option(
        display = "Colorado",
        value = "688",
    ),
    schema.Option(
        display = "Colorado School of Mines",
        value = "1193",
    ),
    schema.Option(
        display = "Colorado State",
        value = "689",
    ),
    schema.Option(
        display = "Colorado-Colorado Springs",
        value = "877",
    ),
    schema.Option(
        display = "Columbia",
        value = "638",
    ),
    schema.Option(
        display = "Columbia College",
        value = "878",
    ),
    schema.Option(
        display = "Copiah-Lincoln CC",
        value = "879",
    ),
    schema.Option(
        display = "Coppin State",
        value = "574",
    ),
    schema.Option(
        display = "Corban",
        value = "1194",
    ),
    schema.Option(
        display = "Cornell",
        value = "690",
    ),
    schema.Option(
        display = "Creighton",
        value = "510",
    ),
    schema.Option(
        display = "Dallas Baptist",
        value = "626",
    ),
    schema.Option(
        display = "Dartmouth",
        value = "512",
    ),
    schema.Option(
        display = "Davidson",
        value = "691",
    ),
    schema.Option(
        display = "Dayton",
        value = "692",
    ),
    schema.Option(
        display = "DePaul",
        value = "696",
    ),
    schema.Option(
        display = "Delaware",
        value = "693",
    ),
    schema.Option(
        display = "Delaware State",
        value = "694",
    ),
    schema.Option(
        display = "Delta State",
        value = "880",
    ),
    schema.Option(
        display = "Denver",
        value = "695",
    ),
    schema.Option(
        display = "Detroit Mercy",
        value = "697",
    ),
    schema.Option(
        display = "Drake",
        value = "698",
    ),
    schema.Option(
        display = "Drexel",
        value = "699",
    ),
    schema.Option(
        display = "Duke",
        value = "505",
    ),
    schema.Option(
        display = "Duquesne",
        value = "700",
    ),
    schema.Option(
        display = "East Carolina",
        value = "506",
    ),
    schema.Option(
        display = "East Tennessee State",
        value = "658",
    ),
    schema.Option(
        display = "Eastern Illinois",
        value = "701",
    ),
    schema.Option(
        display = "Eastern Kentucky",
        value = "702",
    ),
    schema.Option(
        display = "Eastern Michigan",
        value = "703",
    ),
    schema.Option(
        display = "Eastern Washington",
        value = "704",
    ),
    schema.Option(
        display = "Elizabeth City State",
        value = "882",
    ),
    schema.Option(
        display = "Elon",
        value = "657",
    ),
    schema.Option(
        display = "Evansville",
        value = "561",
    ),
    schema.Option(
        display = "Fairfield",
        value = "705",
    ),
    schema.Option(
        display = "Fairleigh Dickinson",
        value = "706",
    ),
    schema.Option(
        display = "Florida",
        value = "487",
    ),
    schema.Option(
        display = "Florida A&M",
        value = "707",
    ),
    schema.Option(
        display = "Florida Atlantic",
        value = "575",
    ),
    schema.Option(
        display = "Florida Gulf Coast",
        value = "645",
    ),
    schema.Option(
        display = "Florida International",
        value = "576",
    ),
    schema.Option(
        display = "Florida State",
        value = "484",
    ),
    schema.Option(
        display = "Fordham",
        value = "708",
    ),
    schema.Option(
        display = "Fresno State",
        value = "549",
    ),
    schema.Option(
        display = "Furman",
        value = "709",
    ),
    schema.Option(
        display = "Gardner-Webb",
        value = "710",
    ),
    schema.Option(
        display = "George Mason",
        value = "578",
    ),
    schema.Option(
        display = "George Washington",
        value = "483",
    ),
    schema.Option(
        display = "Georgetown",
        value = "711",
    ),
    schema.Option(
        display = "Georgia",
        value = "490",
    ),
    schema.Option(
        display = "Georgia Southern",
        value = "550",
    ),
    schema.Option(
        display = "Georgia State",
        value = "712",
    ),
    schema.Option(
        display = "Georgia Tech",
        value = "489",
    ),
    schema.Option(
        display = "Goldey-Beacom Colleg",
        value = "883",
    ),
    schema.Option(
        display = "Gonzaga",
        value = "641",
    ),
    schema.Option(
        display = "Grambling",
        value = "713",
    ),
    schema.Option(
        display = "Grand Canyon",
        value = "714",
    ),
    schema.Option(
        display = "Green Bay",
        value = "715",
    ),
    schema.Option(
        display = "Hampton",
        value = "716",
    ),
    schema.Option(
        display = "Hartford",
        value = "482",
    ),
    schema.Option(
        display = "Harvard",
        value = "717",
    ),
    schema.Option(
        display = "Hawai'i",
        value = "491",
    ),
    schema.Option(
        display = "High Point",
        value = "718",
    ),
    schema.Option(
        display = "Hofstra",
        value = "719",
    ),
    schema.Option(
        display = "Holy Cross",
        value = "720",
    ),
    schema.Option(
        display = "Houston",
        value = "536",
    ),
    schema.Option(
        display = "Houston Christian",
        value = "721",
    ),
    schema.Option(
        display = "Houston-Victoria",
        value = "884",
    ),
    schema.Option(
        display = "Howard",
        value = "722",
    ),
    schema.Option(
        display = "Huston-Tillotson",
        value = "885",
    ),
    schema.Option(
        display = "IUPUI",
        value = "729",
    ),
    schema.Option(
        display = "Idaho",
        value = "723",
    ),
    schema.Option(
        display = "Idaho State",
        value = "724",
    ),
    schema.Option(
        display = "Illinois",
        value = "565",
    ),
    schema.Option(
        display = "Illinois State",
        value = "642",
    ),
    schema.Option(
        display = "Incarnate Word",
        value = "725",
    ),
    schema.Option(
        display = "Indiana",
        value = "648",
    ),
    schema.Option(
        display = "Indiana State",
        value = "662",
    ),
    schema.Option(
        display = "Iona",
        value = "726",
    ),
    schema.Option(
        display = "Iowa",
        value = "579",
    ),
    schema.Option(
        display = "Iowa State",
        value = "727",
    ),
    schema.Option(
        display = "Ithaca",
        value = "886",
    ),
    schema.Option(
        display = "Jackson State",
        value = "639",
    ),
    schema.Option(
        display = "Jacksonville",
        value = "551",
    ),
    schema.Option(
        display = "Jacksonville State",
        value = "485",
    ),
    schema.Option(
        display = "James Madison",
        value = "541",
    ),
    schema.Option(
        display = "Kansas",
        value = "580",
    ),
    schema.Option(
        display = "Kansas City",
        value = "805",
    ),
    schema.Option(
        display = "Kansas State",
        value = "627",
    ),
    schema.Option(
        display = "Kennesaw State",
        value = "661",
    ),
    schema.Option(
        display = "Kent State",
        value = "581",
    ),
    schema.Option(
        display = "Kentucky",
        value = "494",
    ),
    schema.Option(
        display = "Kentucky State",
        value = "887",
    ),
    schema.Option(
        display = "LSU",
        value = "497",
    ),
    schema.Option(
        display = "LSU Alexandria",
        value = "890",
    ),
    schema.Option(
        display = "La Salle",
        value = "730",
    ),
    schema.Option(
        display = "Lafayette",
        value = "557",
    ),
    schema.Option(
        display = "Lamar",
        value = "582",
    ),
    schema.Option(
        display = "Lander",
        value = "888",
    ),
    schema.Option(
        display = "Langston",
        value = "889",
    ),
    schema.Option(
        display = "Le Moyne",
        value = "583",
    ),
    schema.Option(
        display = "Lehigh",
        value = "731",
    ),
    schema.Option(
        display = "Liberty",
        value = "584",
    ),
    schema.Option(
        display = "Lindenwood",
        value = "1240",
    ),
    schema.Option(
        display = "Lipscomb",
        value = "732",
    ),
    schema.Option(
        display = "Little Rock",
        value = "624",
    ),
    schema.Option(
        display = "Long Beach State",
        value = "553",
    ),
    schema.Option(
        display = "Long Island University",
        value = "733",
    ),
    schema.Option(
        display = "Longwood",
        value = "734",
    ),
    schema.Option(
        display = "Louisiana",
        value = "556",
    ),
    schema.Option(
        display = "Louisiana College",
        value = "856",
    ),
    schema.Option(
        display = "Louisiana Tech",
        value = "585",
    ),
    schema.Option(
        display = "Louisville",
        value = "495",
    ),
    schema.Option(
        display = "Loyola Chicago",
        value = "735",
    ),
    schema.Option(
        display = "Loyola Maryland",
        value = "736",
    ),
    schema.Option(
        display = "Loyola Marymount",
        value = "586",
    ),
    schema.Option(
        display = "Maine",
        value = "622",
    ),
    schema.Option(
        display = "Manhattan",
        value = "628",
    ),
    schema.Option(
        display = "Marist",
        value = "587",
    ),
    schema.Option(
        display = "Marquette",
        value = "737",
    ),
    schema.Option(
        display = "Marshall",
        value = "738",
    ),
    schema.Option(
        display = "Maryland",
        value = "499",
    ),
    schema.Option(
        display = "Maryland-Eastern Shore",
        value = "739",
    ),
    schema.Option(
        display = "Massachusetts College",
        value = "891",
    ),
    schema.Option(
        display = "McNeese",
        value = "741",
    ),
    schema.Option(
        display = "Memphis",
        value = "531",
    ),
    schema.Option(
        display = "Mercer",
        value = "649",
    ),
    schema.Option(
        display = "Merrimack",
        value = "1141",
    ),
    schema.Option(
        display = "Miami (FL)",
        value = "588",
    ),
    schema.Option(
        display = "Miami (OH)",
        value = "519",
    ),
    schema.Option(
        display = "Michigan",
        value = "501",
    ),
    schema.Option(
        display = "Michigan State",
        value = "500",
    ),
    schema.Option(
        display = "Middle Tennessee",
        value = "589",
    ),
    schema.Option(
        display = "Midwestern State",
        value = "892",
    ),
    schema.Option(
        display = "Miles",
        value = "893",
    ),
    schema.Option(
        display = "Milwaukee",
        value = "547",
    ),
    schema.Option(
        display = "Minnesota",
        value = "502",
    ),
    schema.Option(
        display = "Minnesota State-Mankato",
        value = "894",
    ),
    schema.Option(
        display = "Mississippi State",
        value = "562",
    ),
    schema.Option(
        display = "Mississippi Valley State",
        value = "742",
    ),
    schema.Option(
        display = "Missouri",
        value = "503",
    ),
    schema.Option(
        display = "Missouri S & T",
        value = "895",
    ),
    schema.Option(
        display = "Missouri State",
        value = "609",
    ),
    schema.Option(
        display = "Missouri Western",
        value = "896",
    ),
    schema.Option(
        display = "Monmouth",
        value = "590",
    ),
    schema.Option(
        display = "Montana",
        value = "743",
    ),
    schema.Option(
        display = "Montana State",
        value = "744",
    ),
    schema.Option(
        display = "Morehead State",
        value = "745",
    ),
    schema.Option(
        display = "Morgan State",
        value = "746",
    ),
    schema.Option(
        display = "Mount St. Mary's",
        value = "747",
    ),
    schema.Option(
        display = "Murray State",
        value = "748",
    ),
    schema.Option(
        display = "NC State",
        value = "507",
    ),
    schema.Option(
        display = "NJIT",
        value = "749",
    ),
    schema.Option(
        display = "Navy",
        value = "591",
    ),
    schema.Option(
        display = "Nebraska",
        value = "511",
    ),
    schema.Option(
        display = "Nebraska-Kearney",
        value = "857",
    ),
    schema.Option(
        display = "Nevada",
        value = "595",
    ),
    schema.Option(
        display = "New Hampshire",
        value = "751",
    ),
    schema.Option(
        display = "New Mexico",
        value = "516",
    ),
    schema.Option(
        display = "New Mexico State",
        value = "515",
    ),
    schema.Option(
        display = "New Orleans",
        value = "596",
    ),
    schema.Option(
        display = "Niagara",
        value = "752",
    ),
    schema.Option(
        display = "Nicholls",
        value = "753",
    ),
    schema.Option(
        display = "Norfolk State",
        value = "754",
    ),
    schema.Option(
        display = "North Alabama",
        value = "1106",
    ),
    schema.Option(
        display = "North Carolina",
        value = "508",
    ),
    schema.Option(
        display = "North Carolina A&T",
        value = "755",
    ),
    schema.Option(
        display = "North Carolina Central",
        value = "756",
    ),
    schema.Option(
        display = "North Dakota",
        value = "757",
    ),
    schema.Option(
        display = "North Dakota State",
        value = "664",
    ),
    schema.Option(
        display = "North Florida",
        value = "650",
    ),
    schema.Option(
        display = "North Texas",
        value = "758",
    ),
    schema.Option(
        display = "Northeastern",
        value = "759",
    ),
    schema.Option(
        display = "Northern Arizona",
        value = "760",
    ),
    schema.Option(
        display = "Northern Colorado",
        value = "761",
    ),
    schema.Option(
        display = "Northern Illinois",
        value = "762",
    ),
    schema.Option(
        display = "Northern Iowa",
        value = "763",
    ),
    schema.Option(
        display = "Northern Kentucky",
        value = "764",
    ),
    schema.Option(
        display = "Northwestern",
        value = "765",
    ),
    schema.Option(
        display = "Northwestern State",
        value = "598",
    ),
    schema.Option(
        display = "Notre Dame",
        value = "493",
    ),
    schema.Option(
        display = "Oakland",
        value = "766",
    ),
    schema.Option(
        display = "Ohio",
        value = "521",
    ),
    schema.Option(
        display = "Ohio State",
        value = "520",
    ),
    schema.Option(
        display = "Oklahoma",
        value = "524",
    ),
    schema.Option(
        display = "Oklahoma Baptist",
        value = "898",
    ),
    schema.Option(
        display = "Oklahoma Christian U",
        value = "899",
    ),
    schema.Option(
        display = "Oklahoma City",
        value = "900",
    ),
    schema.Option(
        display = "Oklahoma State",
        value = "522",
    ),
    schema.Option(
        display = "Old Dominion",
        value = "552",
    ),
    schema.Option(
        display = "Ole Miss",
        value = "504",
    ),
    schema.Option(
        display = "Omaha",
        value = "750",
    ),
    schema.Option(
        display = "Oral Roberts",
        value = "523",
    ),
    schema.Option(
        display = "Oregon",
        value = "636",
    ),
    schema.Option(
        display = "Oregon State",
        value = "525",
    ),
    schema.Option(
        display = "Ouachita Baptist",
        value = "901",
    ),
    schema.Option(
        display = "Our Lady of the Lake",
        value = "902",
    ),
    schema.Option(
        display = "Pacific",
        value = "767",
    ),
    schema.Option(
        display = "Penn State",
        value = "768",
    ),
    schema.Option(
        display = "Pennsylvania",
        value = "769",
    ),
    schema.Option(
        display = "Pepperdine",
        value = "599",
    ),
    schema.Option(
        display = "Peru State College",
        value = "903",
    ),
    schema.Option(
        display = "Pittsburgh",
        value = "527",
    ),
    schema.Option(
        display = "Portland",
        value = "770",
    ),
    schema.Option(
        display = "Portland State",
        value = "771",
    ),
    schema.Option(
        display = "Prairie View A&M",
        value = "600",
    ),
    schema.Option(
        display = "Presbyterian",
        value = "772",
    ),
    schema.Option(
        display = "Princeton",
        value = "513",
    ),
    schema.Option(
        display = "Providence",
        value = "773",
    ),
    schema.Option(
        display = "Purdue",
        value = "601",
    ),
    schema.Option(
        display = "Purdue Fort Wayne",
        value = "728",
    ),
    schema.Option(
        display = "Quinnipiac",
        value = "774",
    ),
    schema.Option(
        display = "Radford",
        value = "775",
    ),
    schema.Option(
        display = "Rhode Island",
        value = "776",
    ),
    schema.Option(
        display = "Rice",
        value = "534",
    ),
    schema.Option(
        display = "Richmond",
        value = "542",
    ),
    schema.Option(
        display = "Rider",
        value = "777",
    ),
    schema.Option(
        display = "Robert Morris",
        value = "778",
    ),
    schema.Option(
        display = "Rutgers",
        value = "514",
    ),
    schema.Option(
        display = "SE Louisiana",
        value = "663",
    ),
    schema.Option(
        display = "SIU Carbondale",
        value = "908",
    ),
    schema.Option(
        display = "SIU Edwardsville",
        value = "783",
    ),
    schema.Option(
        display = "SMU",
        value = "787",
    ),
    schema.Option(
        display = "Sacramento State",
        value = "668",
    ),
    schema.Option(
        display = "Sacred Heart",
        value = "629",
    ),
    schema.Option(
        display = "Saint Joseph's",
        value = "779",
    ),
    schema.Option(
        display = "Saint Louis",
        value = "654",
    ),
    schema.Option(
        display = "Saint Mary's",
        value = "780",
    ),
    schema.Option(
        display = "Saint Peter's",
        value = "791",
    ),
    schema.Option(
        display = "Salem State",
        value = "904",
    ),
    schema.Option(
        display = "Sam Houston",
        value = "602",
    ),
    schema.Option(
        display = "Samford",
        value = "637",
    ),
    schema.Option(
        display = "San Diego",
        value = "555",
    ),
    schema.Option(
        display = "San Diego State",
        value = "474",
    ),
    schema.Option(
        display = "San Francisco",
        value = "630",
    ),
    schema.Option(
        display = "San José State",
        value = "475",
    ),
    schema.Option(
        display = "Santa Clara",
        value = "781",
    ),
    schema.Option(
        display = "Savannah State",
        value = "640",
    ),
    schema.Option(
        display = "Seattle U",
        value = "782",
    ),
    schema.Option(
        display = "Seton Hall",
        value = "631",
    ),
    schema.Option(
        display = "Shawnee State",
        value = "1192",
    ),
    schema.Option(
        display = "Siena",
        value = "665",
    ),
    schema.Option(
        display = "Simon Fraser",
        value = "905",
    ),
    schema.Option(
        display = "Simpson University",
        value = "906",
    ),
    schema.Option(
        display = "Sioux Falls",
        value = "907",
    ),
    schema.Option(
        display = "South Alabama",
        value = "469",
    ),
    schema.Option(
        display = "South Carolina",
        value = "605",
    ),
    schema.Option(
        display = "South Carolina State",
        value = "784",
    ),
    schema.Option(
        display = "South Carolina Upstate",
        value = "807",
    ),
    schema.Option(
        display = "South Dakota",
        value = "785",
    ),
    schema.Option(
        display = "South Dakota State",
        value = "655",
    ),
    schema.Option(
        display = "South Florida",
        value = "488",
    ),
    schema.Option(
        display = "Southeast Missouri State",
        value = "603",
    ),
    schema.Option(
        display = "Southeastern",
        value = "909",
    ),
    schema.Option(
        display = "Southern",
        value = "606",
    ),
    schema.Option(
        display = "Southern Illinois",
        value = "786",
    ),
    schema.Option(
        display = "Southern Miss",
        value = "604",
    ),
    schema.Option(
        display = "Southern Utah",
        value = "788",
    ),
    schema.Option(
        display = "Spartanburg Methodist",
        value = "910",
    ),
    schema.Option(
        display = "Spring Hill",
        value = "911",
    ),
    schema.Option(
        display = "St. Bonaventure",
        value = "517",
    ),
    schema.Option(
        display = "St. Francis (PA)",
        value = "790",
    ),
    schema.Option(
        display = "St. Francis Brooklyn",
        value = "789",
    ),
    schema.Option(
        display = "St. Gregory",
        value = "859",
    ),
    schema.Option(
        display = "St. John's",
        value = "607",
    ),
    schema.Option(
        display = "St. Mary's (TX)",
        value = "912",
    ),
    schema.Option(
        display = "St. Thomas-Minnesota",
        value = "1188",
    ),
    schema.Option(
        display = "Stanford",
        value = "476",
    ),
    schema.Option(
        display = "Stephen F. Austin",
        value = "792",
    ),
    schema.Option(
        display = "Stetson",
        value = "486",
    ),
    schema.Option(
        display = "Stillman",
        value = "913",
    ),
    schema.Option(
        display = "Stonehill",
        value = "1241",
    ),
    schema.Option(
        display = "Stony Brook",
        value = "608",
    ),
    schema.Option(
        display = "Syracuse",
        value = "793",
    ),
    schema.Option(
        display = "TBD",
        value = "1196",
    ),
    schema.Option(
        display = "TCU",
        value = "610",
    ),
    schema.Option(
        display = "TX Woman's Univ",
        value = "917",
    ),
    schema.Option(
        display = "Tarleton",
        value = "1149",
    ),
    schema.Option(
        display = "Team USA",
        value = "914",
    ),
    schema.Option(
        display = "Temple",
        value = "526",
    ),
    schema.Option(
        display = "Tennessee",
        value = "611",
    ),
    schema.Option(
        display = "Tennessee State",
        value = "794",
    ),
    schema.Option(
        display = "Tennessee Tech",
        value = "795",
    ),
    schema.Option(
        display = "Texas",
        value = "538",
    ),
    schema.Option(
        display = "Texas A&M",
        value = "535",
    ),
    schema.Option(
        display = "Texas A&M-Commerce",
        value = "1237",
    ),
    schema.Option(
        display = "Texas A&M-Corpus Christi",
        value = "797",
    ),
    schema.Option(
        display = "Texas College",
        value = "915",
    ),
    schema.Option(
        display = "Texas Southern",
        value = "612",
    ),
    schema.Option(
        display = "Texas State",
        value = "559",
    ),
    schema.Option(
        display = "Texas Tech",
        value = "613",
    ),
    schema.Option(
        display = "Texas-Pan American",
        value = "798",
    ),
    schema.Option(
        display = "The Citadel",
        value = "614",
    ),
    schema.Option(
        display = "Toledo",
        value = "799",
    ),
    schema.Option(
        display = "Towson",
        value = "659",
    ),
    schema.Option(
        display = "Trevecca Nazarene",
        value = "916",
    ),
    schema.Option(
        display = "Troy",
        value = "632",
    ),
    schema.Option(
        display = "Tulane",
        value = "615",
    ),
    schema.Option(
        display = "Tulsa",
        value = "800",
    ),
    schema.Option(
        display = "UAB",
        value = "801",
    ),
    schema.Option(
        display = "UC Davis",
        value = "802",
    ),
    schema.Option(
        display = "UC Irvine",
        value = "554",
    ),
    schema.Option(
        display = "UC Riverside",
        value = "479",
    ),
    schema.Option(
        display = "UC San Diego",
        value = "1155",
    ),
    schema.Option(
        display = "UC Santa Barbara",
        value = "644",
    ),
    schema.Option(
        display = "UCF",
        value = "572",
    ),
    schema.Option(
        display = "UCLA",
        value = "478",
    ),
    schema.Option(
        display = "UConn",
        value = "481",
    ),
    schema.Option(
        display = "UIC",
        value = "492",
    ),
    schema.Option(
        display = "UL Monroe",
        value = "635",
    ),
    schema.Option(
        display = "UMBC",
        value = "804",
    ),
    schema.Option(
        display = "UMass",
        value = "740",
    ),
    schema.Option(
        display = "UMass Lowell",
        value = "803",
    ),
    schema.Option(
        display = "UNC Asheville",
        value = "806",
    ),
    schema.Option(
        display = "UNC Greensboro",
        value = "593",
    ),
    schema.Option(
        display = "UNC Wilmington",
        value = "564",
    ),
    schema.Option(
        display = "UNLV",
        value = "594",
    ),
    schema.Option(
        display = "USC",
        value = "480",
    ),
    schema.Option(
        display = "UT Arlington",
        value = "537",
    ),
    schema.Option(
        display = "UT Martin",
        value = "796",
    ),
    schema.Option(
        display = "UTEP",
        value = "810",
    ),
    schema.Option(
        display = "UTSA",
        value = "651",
    ),
    schema.Option(
        display = "University of Great Falls",
        value = "918",
    ),
    schema.Option(
        display = "Utah",
        value = "540",
    ),
    schema.Option(
        display = "Utah State",
        value = "808",
    ),
    schema.Option(
        display = "Utah Tech",
        value = "881",
    ),
    schema.Option(
        display = "Utah Valley",
        value = "809",
    ),
    schema.Option(
        display = "Valparaiso",
        value = "656",
    ),
    schema.Option(
        display = "Vanderbilt",
        value = "532",
    ),
    schema.Option(
        display = "Vermont",
        value = "811",
    ),
    schema.Option(
        display = "Villanova",
        value = "812",
    ),
    schema.Option(
        display = "Virginia",
        value = "543",
    ),
    schema.Option(
        display = "Virginia Commonwealth",
        value = "616",
    ),
    schema.Option(
        display = "Virginia Military",
        value = "813",
    ),
    schema.Option(
        display = "Virginia Tech",
        value = "544",
    ),
    schema.Option(
        display = "Virginia Union",
        value = "919",
    ),
    schema.Option(
        display = "Wagner",
        value = "814",
    ),
    schema.Option(
        display = "Wake Forest",
        value = "509",
    ),
    schema.Option(
        display = "Washington",
        value = "545",
    ),
    schema.Option(
        display = "Washington State",
        value = "546",
    ),
    schema.Option(
        display = "Weber State",
        value = "815",
    ),
    schema.Option(
        display = "West Virginia",
        value = "548",
    ),
    schema.Option(
        display = "Western Carolina",
        value = "617",
    ),
    schema.Option(
        display = "Western Illinois",
        value = "816",
    ),
    schema.Option(
        display = "Western Kentucky",
        value = "496",
    ),
    schema.Option(
        display = "Western Michigan",
        value = "817",
    ),
    schema.Option(
        display = "Wichita State",
        value = "618",
    ),
    schema.Option(
        display = "William & Mary",
        value = "643",
    ),
    schema.Option(
        display = "William Carey",
        value = "920",
    ),
    schema.Option(
        display = "William Penn",
        value = "921",
    ),
    schema.Option(
        display = "Winston-Salem",
        value = "922",
    ),
    schema.Option(
        display = "Winthrop",
        value = "619",
    ),
    schema.Option(
        display = "Wisc. River Falls",
        value = "923",
    ),
    schema.Option(
        display = "Wisconsin",
        value = "818",
    ),
    schema.Option(
        display = "Wofford",
        value = "620",
    ),
    schema.Option(
        display = "Wright State",
        value = "633",
    ),
    schema.Option(
        display = "Wyoming",
        value = "819",
    ),
    schema.Option(
        display = "Xavier",
        value = "666",
    ),
    schema.Option(
        display = "Yale",
        value = "820",
    ),
    schema.Option(
        display = "Youngstown State",
        value = "621",
    ),
]

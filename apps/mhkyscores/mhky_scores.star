"""
Applet: MHKY Scores
Summary: Displays Men's College Hockey scores
Description: Displays live and upcoming NCAA Hockey scores from a data feed.
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
LEAGUE_DISPLAY = "MHKY"
LEAGUE_DISPLAY_OFFSET = 3
SPORT = "hockey"
LEAGUE = "mens-college-hockey"
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
    " - ": " ",
    " / ": " ",
    " of": "",
    "Postponed": "PPD",
    "1st Period": "P1",
    "2nd Period": "P2",
    "3rd Period": "P3"
}
"""
ALT_COLOR = """
{
    "AFA": "#004a7b",
    "AIC": "#000000",
    "AKFB": "#1E59AE",
    "ARMY": "#000000",
    "ASU": "#8C1D40",
    "BC": "#98002E",
    "BENT": "#000000",
    "BGSU": "#FE5000",
    "BRWN": "#4E3629",
    "BST": "#004D44",
    "BU": "#CC0000",
    "CAN": "#0C2340",
    "CLAR": "#0D433B",
    "COLC": "#000000",
    "COLG": "#821019",
    "CONN": "#000E2F",
    "COR": "#B31B1B",
    "DART": "#046A38",
    "DEN": "#8B2332",
    "FRST": "#BA0C2F",
    "HARV": "#A41034",
    "HC": "#602D89",
    "LIN": "#231F20",
    "LIU": "#69B3E7",
    "LSS": "#324EA9",
    "M-OH": "#B61E2E",
    "MASS": "#971B2F",
    "ME": "#003263",
    "MERC": "#1A554B",
    "MICH": "#00274C",
    "MINN": "#7A0019",
    "MNST": "#683B7A",
    "MRMK": "#0B335E",
    "MSU": "#18453B",
    "MTU": "#7a0019",
    "ND": "#0C2340",
    "NE": "#D41B2C",
    "NIA": "#582C83",
    "NMI": "#1E513D",
    "OMA": "#D71920",
    "OSU": "#BB0000",
    "PRIN": "#FF671F",
    "PROV": "#000000",
    "PSU": "#041E42",
    "QUIN": "#0A2240",
    "RIT": "#F76902",
    "RPI": "#232020",
    "SCSU": "#CD1041",
    "SHU": "#CE1141",
    "STA": "#002A5B",
    "STMN": "#512773",
    "STONEHILL": "#2F2975",
    "UAA": "#1E513D",
    "UMD": "#7a0019",
    "UML": "#003DA5",
    "UND": "#0A5640",
    "UNH": "#041E42",
    "UNNY": "#791328",
    "USL": "#654134",
    "UVM": "#005710",
    "WISC": "#C5050C",
    "WMU": "#6C4023",
    "YALE": "#00356B"
}
"""
ALT_LOGO = """
{
	"AFA": "https://b.fssta.com/uploads/application/college/team-logos/AirForce-alternate.png",
	"COLG": "https://b.fssta.com/uploads/application/college/team-logos/Colgate-alternate.png",
	"MINN" : "https://b.fssta.com/uploads/application/college/team-logos/Minnesota-alternate.vresize.50.50.medium.0.png",
	"MSU" : "https://b.fssta.com/uploads/application/college/team-logos/MichiganState-alternate.vresize.50.50.medium.1.png",
    "WISC" : "https://b.fssta.com/uploads/application/college/team-logos/Wisconsin-alternate.vresize.50.50.medium.1.png"
}
"""
MAGNIFY_LOGO = """
{
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
    rotationSpeed = config.get("rotationSpeed", "7")
    location = config.get("location", DEFAULT_LOCATION)
    showAnimations = config.bool("showAnimations", True)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    datePast = now - time.parse_duration("%dh" % 1 * 24)
    dateFuture = now + time.parse_duration("%dh" % 6 * 24)
    league = {LEAGUE: API + "?limit=300" + (selectedTeam == "all" and " " or "&dates=" + datePast.format("20060102") + "-" + dateFuture.format("20060102"))}
    scores = get_scores(league, selectedTeam)

    if len(scores) > 0:
        animationDuration = int(rotationSpeed) * 20
        delayDuration = int(animationDuration * float(1 / (int(rotationSpeed) * 2)))
        animationPercentage1 = float(1 / (int(rotationSpeed) * 2))
        animationPercentage2 = float(1 - float(1 / (int(rotationSpeed) * 2)))
        logoKeyframes = []
        homeBarKeyframes = []
        awayBarKeyframes = []
        scoreKeyframes = []
        teamKeyframes = []
        screenKeyframes = []
        styleAttributes = json.decode(STYLE_ATTRIBUTES)

        for i, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]
            home = competition["competitors"][0]["team"]["abbreviation"]
            away = competition["competitors"][1]["team"]["abbreviation"]
            homeTeamName = competition["competitors"][0]["team"]["abbreviation"]
            awayTeamName = competition["competitors"][1]["team"]["abbreviation"]
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
                            homeScore = "0-0-0"
                        else:
                            homeScore = competition["competitors"][0]["records"][0]["summary"]
                        if awaycheckRecord == "NO":
                            awayScore = "0-0-0"
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
                    homeWinner = competition["competitors"][0]["winner"]
                    awayScore = competition["competitors"][1]["score"]
                    awayWinner = competition["competitors"][1]["winner"]
                    if (int(homeScore) > int(awayScore) or homeWinner == True):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayScore) > int(homeScore) or awayWinner == True):
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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
                                        children = get_date_column(displayTop, now, i, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, styleAttributes[displayType]["textColor"], styleAttributes[displayType]["borderColor"], displayType, gameTime, timeColor),
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

def get_background_color(team, displayType, color):
    altcolors = json.decode(ALT_COLOR)
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

def get_date_column(displayTop, now, scoreNumber, showAnimations, animationDuration, animationPercentage1, animationPercentage2, delayDuration, rotationSpeed, textColor, borderColor, displayType, gameTime, timeColor):
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
                        render.Text(color = textColor, content = get_shortened_display(gameTime), font = "CG-pixel-3x5-mono"),
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

def get_shortened_display(text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    words = json.decode(SHORTENED_WORDS)
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
        display = "Air Force",
        value = "2005",
    ),
    schema.Option(
        display = "Alaska",
        value = "298",
    ),
    schema.Option(
        display = "American International",
        value = "2022",
    ),
    schema.Option(
        display = "Arizona State",
        value = "9",
    ),
    schema.Option(
        display = "Army",
        value = "349",
    ),
    schema.Option(
        display = "Bemidji State",
        value = "132",
    ),
    schema.Option(
        display = "Bentley",
        value = "2060",
    ),
    schema.Option(
        display = "Boston College",
        value = "103",
    ),
    schema.Option(
        display = "Boston University",
        value = "104",
    ),
    schema.Option(
        display = "Bowling Green",
        value = "189",
    ),
    schema.Option(
        display = "Brown",
        value = "225",
    ),
    schema.Option(
        display = "Canisius",
        value = "2099",
    ),
    schema.Option(
        display = "Clarkson",
        value = "2137",
    ),
    schema.Option(
        display = "Colgate",
        value = "2142",
    ),
    schema.Option(
        display = "Colorado College",
        value = "2144",
    ),
    schema.Option(
        display = "Cornell",
        value = "172",
    ),
    schema.Option(
        display = "Dartmouth",
        value = "159",
    ),
    schema.Option(
        display = "Denver",
        value = "2172",
    ),
    schema.Option(
        display = "Ferris State",
        value = "2222",
    ),
    schema.Option(
        display = "Franklin Pierce",
        value = "126790",
    ),
    schema.Option(
        display = "Harvard",
        value = "108",
    ),
    schema.Option(
        display = "Holy Cross",
        value = "107",
    ),
    schema.Option(
        display = "Lake Superior State",
        value = "285",
    ),
    schema.Option(
        display = "Lindenwood",
        value = "2815",
    ),
    schema.Option(
        display = "Long Island University",
        value = "110133",
    ),
    schema.Option(
        display = "Maine",
        value = "311",
    ),
    schema.Option(
        display = "Mercyhurst",
        value = "2385",
    ),
    schema.Option(
        display = "Merrimack",
        value = "2771",
    ),
    schema.Option(
        display = "Miami (OH)",
        value = "193",
    ),
    schema.Option(
        display = "Michigan State",
        value = "127",
    ),
    schema.Option(
        display = "Michigan Tech",
        value = "2392",
    ),
    schema.Option(
        display = "Michigan",
        value = "130",
    ),
    schema.Option(
        display = "Minnesota Duluth",
        value = "134",
    ),
    schema.Option(
        display = "Minnesota State",
        value = "2364",
    ),
    schema.Option(
        display = "Minnesota",
        value = "135",
    ),
    schema.Option(
        display = "New Hampshire",
        value = "160",
    ),
    schema.Option(
        display = "Niagara",
        value = "315",
    ),
    schema.Option(
        display = "North Dakota",
        value = "155",
    ),
    schema.Option(
        display = "Northeastern",
        value = "111",
    ),
    schema.Option(
        display = "Northern Michigan",
        value = "128",
    ),
    schema.Option(
        display = "Notre Dame",
        value = "87",
    ),
    schema.Option(
        display = "Ohio State",
        value = "194",
    ),
    schema.Option(
        display = "Omaha",
        value = "2437",
    ),
    schema.Option(
        display = "Penn State",
        value = "213",
    ),
    schema.Option(
        display = "Princeton",
        value = "163",
    ),
    schema.Option(
        display = "Providence",
        value = "2507",
    ),
    schema.Option(
        display = "Quinnipiac",
        value = "2514",
    ),
    schema.Option(
        display = "Rensselaer",
        value = "2528",
    ),
    schema.Option(
        display = "Rochester",
        value = "178",
    ),
    schema.Option(
        display = "Sacred Heart",
        value = "2529",
    ),
    schema.Option(
        display = "St. Cloud State",
        value = "2594",
    ),
    schema.Option(
        display = "St. Lawrence",
        value = "2779",
    ),
    schema.Option(
        display = "St. Thomas - Minnesota",
        value = "2900",
    ),
    schema.Option(
        display = "Stonehill",
        value = "284",
    ),
    schema.Option(
        display = "UConn",
        value = "41",
    ),
    schema.Option(
        display = "UMass Lowell",
        value = "2349",
    ),
    schema.Option(
        display = "UMass",
        value = "113",
    ),
    schema.Option(
        display = "Union",
        value = "2785",
    ),
    schema.Option(
        display = "Vermont",
        value = "261",
    ),
    schema.Option(
        display = "Western Michigan",
        value = "2711",
    ),
    schema.Option(
        display = "Wisconsin",
        value = "275",
    ),
    schema.Option(
        display = "Yale",
        value = "43",
    ),
]

"""
Applet: MHKY Scores
Summary: Displays Men's College Hockey scores
Description: Displays live and upcoming NCAA Hockey scores from a data feed.
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
            elif competition["competitors"][0]["team"]["logo"] == "":
                homeLogoURL = "https://i.ibb.co/5LMp8T1/transparent.png"
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logo"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logo", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = "https://i.ibb.co/5LMp8T1/transparent.png"
            elif competition["competitors"][1]["team"]["logo"] == "":
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
                checkNotes = competition.get("notes", "NO")
                if checkSeries != "NO":
                    seriesSummary = competition["series"]["summary"]
                    gameTime = seriesSummary.replace("series ", "")
                if checkNotes != "NO" and checkSeries == "NO":
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
        logo = logo.replace("500/", "500-dark/")
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

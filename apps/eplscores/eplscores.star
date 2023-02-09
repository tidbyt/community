"""
Applet: EPL Scores
Summary: Displays EPL scores
Description: Displays live and upcoming EPL scores from a data feed.
Author: mabroadfo1027
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
LEAGUE_DISPLAY = "EPL"
LEAGUE_DISPLAY_OFFSET = -4
SPORT = "soccer"
LEAGUE = "eng.1"
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
    "Postponed": "PPD",
    "1st Half": "1H",
    "2nd Half": "2H"
}
"""
ALT_COLOR = """
{
}
"""
ALT_LOGO = """
{
}
"""
MAGNIFY_LOGO = """
{
    "BOU": 13,
    "ARS": 13,
    "AVA": 13,
    "AVL": 13,
    "BRE": 13,
    "BRH": 13,
    "CHE": 13,
    "CRY": 13,
    "EVE": 13,
    "FUL": 13,
    "LEE": 13,
    "LEI": 13,
    "LIV": 13,
    "MCI": 13,
    "MUN": 13,
    "NEW": 13,
    "NTG": 13,
    "SOU": 13,
    "TOT": 13,
    "WHU": 13,
    "WLV": 13
}
"""

def main(config):
    renderCategory = []
    league = {LEAGUE: API}
    instanceNumber = int(config.get("instanceNumber", 1))
    totalInstances = int(config.get("instancesCount", 1))
    selectedTeam = config.get("selectedTeam", "all")
    scores = get_scores(league, instanceNumber, totalInstances, selectedTeam)
    if len(scores) > 0:
        displayType = config.get("displayType", "colors")
        displayTop = config.get("displayTop", "time")
        pregameDisplay = config.get("pregameDisplay", "record")
        timeColor = config.get("displayTimeColor", "#FFF")
        rotationSpeed = 15 / len(scores)
        location = config.get("location", DEFAULT_LOCATION)
        loc = json.decode(location)
        timezone = loc["timezone"]
        now = time.now().in_location(timezone)

        for _, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]
            homeCompetitor = competition["competitors"][0]
            awayCompetitor = competition["competitors"][1]
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
                        theOdds = competition["odds"][1]
                        checkHomeOdds = theOdds.get("homeTeamOdds", "NO")
                        checkAwayOdds = theOdds.get("awayTeamOdds", "NO")
                        if checkHomeOdds != "NO" and checkAwayOdds != "NO":
                            homeScore = get_odds(float(competition["odds"][1]["homeTeamOdds"]["moneyLine"]))
                            awayScore = get_odds(float(competition["odds"][1]["awayTeamOdds"]["moneyLine"]))
                        else:
                            homeScore = ""
                            awayScore = ""
                elif pregameDisplay == "record":
                    checkSeries = competition.get("series", "NO")
                    checkRecord = homeCompetitor.get("records", "NO")
                    if checkRecord == "NO":
                        homeScore = "0-0-0"
                        awayScore = "0-0-0"
                    else:
                        homeScore = competition["competitors"][0]["records"][0]["summary"]
                        awayScore = competition["competitors"][1]["records"][0]["summary"]
                elif pregameDisplay == "form":
                    checkHomeForm = homeCompetitor.get("form", "NO")
                    checkAwayForm = awayCompetitor.get("form", "NO")
                    if checkHomeForm == "NO" or checkAwayForm == "NO":
                        homeScore = ""
                        awayScore = ""
                    else:
                        homeScore = competition["competitors"][0]["form"]
                        awayScore = competition["competitors"][1]["form"]

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
                                    children = get_date_column(displayTop, now, retroTextColor, retroBorderColor, displayType, gameTime, timeColor),
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
                                    children = get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 12, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 1, height = 10, color = borderColor),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = away[:3].upper(), color = awayScoreColor, font = textFont))),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = get_record(awayScore), color = awayScoreColor, font = scoreFont))),
                                            render.Box(width = 1, height = 10, color = borderColor),
                                        ])),
                                        render.Box(width = 64, height = 1, color = borderColor),
                                        render.Box(width = 64, height = 10, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 1, height = 10, color = borderColor),
                                            render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = backgroundColor, child = render.Text(content = home[:3].upper(), color = homeScoreColor, font = textFont))),
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
                                    children = get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor),
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
                                    children = get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor),
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
                                    children = get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(awayLogo, width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = away[:3], color = awayScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(awayScore), color = awayScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(homeLogo, width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = home[:3], color = homeScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(homeScore), color = homeScoreColor, font = scoreFont)),
                                                ])),
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
                                    children = get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor),
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(awayLogo, width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = away[:3], color = awayScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(awayScore), color = awayScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(homeLogo, width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = home[:3], color = homeScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(homeScore), color = homeScoreColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

        return render.Root(
            delay = int(rotationSpeed * 1000),
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
        display = "AFC Bournemouth",
        value = "BOU",
    ),
    schema.Option(
        display = "Arsenal",
        value = "ARS",
    ),
    schema.Option(
        display = "Aston Villa",
        value = "AVL",
    ),
    schema.Option(
        display = "Brentford",
        value = "BRE",
    ),
    schema.Option(
        display = "Brighton & Hove Albion",
        value = "BHA",
    ),
    schema.Option(
        display = "Chelsea",
        value = "CHE",
    ),
    schema.Option(
        display = "Crystal Palace",
        value = "CRY",
    ),
    schema.Option(
        display = "Everton",
        value = "EVE",
    ),
    schema.Option(
        display = "Fulham",
        value = "FUL",
    ),
    schema.Option(
        display = "Leeds United",
        value = "LEE",
    ),
    schema.Option(
        display = "Leicester City",
        value = "LEI",
    ),
    schema.Option(
        display = "Liverpool",
        value = "LIV",
    ),
    schema.Option(
        display = "Manchester City",
        value = "MNC",
    ),
    schema.Option(
        display = "Manchester United",
        value = "MAN",
    ),
    schema.Option(
        display = "Newcastle United",
        value = "NEW",
    ),
    schema.Option(
        display = "Nottingham Forest",
        value = "NFO",
    ),
    schema.Option(
        display = "Southampton",
        value = "SOU",
    ),
    schema.Option(
        display = "Tottenham Hotspur",
        value = "TOT",
    ),
    schema.Option(
        display = "West Ham United",
        value = "WHU",
    ),
    schema.Option(
        display = "Wolverhampton Wanderers",
        value = "WOL",
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

instancesCounts = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
    schema.Option(
        display = "6",
        value = "6",
    ),
    schema.Option(
        display = "7",
        value = "7",
    ),
    schema.Option(
        display = "8",
        value = "8",
    ),
]

instanceNumbers = [
    schema.Option(
        display = "First",
        value = "1",
    ),
    schema.Option(
        display = "Second",
        value = "2",
    ),
    schema.Option(
        display = "Third",
        value = "3",
    ),
    schema.Option(
        display = "Fourth",
        value = "4",
    ),
    schema.Option(
        display = "Fifth",
        value = "5",
    ),
    schema.Option(
        display = "Sixth",
        value = "6",
    ),
    schema.Option(
        display = "Seventh",
        value = "7",
    ),
    schema.Option(
        display = "Eighth",
        value = "8",
    ),
]

pregameOptions = [
    schema.Option(
        display = "Team Record",
        value = "record",
    ),
    schema.Option(
        display = "Form",
        value = "form",
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
                icon = "desktop",
                default = teamOptions[0].value,
                options = teamOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "desktop",
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
            schema.Dropdown(
                id = "instancesCount",
                name = "Total Instances of App",
                desc = "This determines which set of scores to display based on the 'Scores to Display' setting.",
                icon = "clock",
                default = instancesCounts[0].value,
                options = instancesCounts,
            ),
            schema.Dropdown(
                id = "instanceNumber",
                name = "App Instance Number",
                desc = "Select which instance of the app this is.",
                icon = "clock",
                default = instanceNumbers[0].value,
                options = instanceNumbers,
            ),
        ],
    )

def get_scores(urls, instanceNumber, totalInstances, team):
    allscores = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        if team != "all" and team != "":
            newScores = []
            for _, s in enumerate(allscores):
                home = s["competitions"][0]["competitors"][0]["team"]["abbreviation"]
                away = s["competitions"][0]["competitors"][1]["team"]["abbreviation"]
                if home == team or away == team:
                    newScores.append(s)
            allscores = newScores
        all([i, allscores])
    if instanceNumber > totalInstances:
        for i in range(0, int(len(allscores))):
            allscores.pop()
        return allscores
    else:
        thescores = [allscores[(i * len(allscores)) // totalInstances:((i + 1) * len(allscores)) // totalInstances] for i in range(totalInstances)]
        return thescores[instanceNumber - 1]

def get_odds(theOdds):
    if theOdds > 0:
        theOdds = "+" + str(int(theOdds))
    else:
        theOdds = str(int(theOdds))
    return str(theOdds)

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

def get_date_column(displayTop, now, textColor, borderColor, displayType, gameTime, timeColor):
    timeBox = 20
    statusBox = 44
    if displayTop == "league":
        theTime = LEAGUE_DISPLAY
        timeBox += LEAGUE_DISPLAY_OFFSET
        statusBox -= LEAGUE_DISPLAY_OFFSET
    else:
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
            render.Box(width = statusBox, height = 8, color = displayType == "stadium" and borderColor or "#111"),
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

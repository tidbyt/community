"""
Applet: NHL Scores
Summary: Displays NHL scores
Description: Displays live and upcoming NHL scores from a data feed.
Author: cmarkham20
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
SPORT = "hockey"
LEAGUE = "nhl"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/scoreboard"
ALT_COLOR = """
{
    "NSH": "#041E42",
    "BUF": "#003087"
}
"""
ALT_LOGO = """
{
}
"""
MAGNIFY_LOGO = """
{
    "ANA": 18,
    "ARI": 18,
    "CAR": 18,
    "CBJ": 18,
    "DAL": 18,
    "DET": 18,
    "MIN": 18,
    "NSH": 18,
    "SJ": 18,
    "SEA": 18,
    "TOR": 18
}
"""

def main(config):
    renderCategory = []
    league = {LEAGUE: API}
    scores = get_scores(league)
    cycleSpeed = int(config.get("cycleSpeed", 15))
    displayType = config.get("displayType", "colors")
    logoType = config.get("logoType", "primary")
    showDateTime = config.bool("displayDateTime")
    pregameDisplay = config.get("pregameDisplay", "record")
    rotationSpeed = cycleSpeed / len(scores)
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)

    for i, s in enumerate(scores):
        gameStatus = s["status"]["type"]["state"]
        competition = s["competitions"][0]
        home = competition["competitors"][0]["team"]["abbreviation"]
        away = competition["competitors"][1]["team"]["abbreviation"]
        homeTeamName = competition["competitors"][0]["team"]["shortDisplayName"]
        awayTeamName = competition["competitors"][1]["team"]["shortDisplayName"]
        homePrimaryColor = competition["competitors"][0]["team"]["color"]
        awayPrimaryColor = competition["competitors"][1]["team"]["color"]
        homeAltColor = competition["competitors"][0]["team"]["alternateColor"]
        awayAltColor = competition["competitors"][1]["team"]["alternateColor"]
        homeColor = get_background_color(home, displayType, homePrimaryColor, homeAltColor)
        awayColor = get_background_color(away, displayType, awayPrimaryColor, awayAltColor)
        homeLogoURL = competition["competitors"][0]["team"]["logo"]
        awayLogoURL = competition["competitors"][1]["team"]["logo"]
        homeLogo = get_logoType(home, homeLogoURL)
        awayLogo = get_logoType(away, awayLogoURL)
        homeLogoSize = get_logoSize(home)
        awayLogoSize = get_logoSize(away)
        teamFont = "Dina_r400-6"
        scoreFont = "Dina_r400-6"

        if gameStatus == "pre":
            gameDateTime = s["status"]["type"]["shortDetail"]
            gameTime = s["date"]
            convertedTime = time.parse_time(gameTime, format = "2006-01-02T15:04Z").in_location(timezone)
            if convertedTime.format("1/2") != now.format("1/2"):
                gameTime = convertedTime.format("1/2 - 3:04 PM")
            else:
                gameTime = convertedTime.format("3:04 PM")
            gameTime = convertedTime.format("3:04 PM")
            homeScoreColor = "#fff"
            awayScoreColor = "#fff"
            scoreFont = "CG-pixel-3x5-mono"
            if pregameDisplay == "odds":
                checkOdds = competition.get("odds", "NO")
                checkOU = competition["odds"][0].get("overUnder", "NO")
                if checkOdds != "NO":
                    theOdds = competition["odds"][0]["details"]
                    if checkOU == "NO":
                        theOU = ""
                    else:
                        theOU = competition["odds"][0]["overUnder"]
                    homeScore = get_odds(theOdds, str(theOU), home, "home")
                    awayScore = get_odds(theOdds, str(theOU), away, "away")
            elif pregameDisplay == "record":
                homeScore = competition["competitors"][0]["records"][0]["summary"]
                awayScore = competition["competitors"][1]["records"][0]["summary"]

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
            if gameTime == "Postponed":
                homeScore = ""
                awayScore = ""
            else:
                homeScore = competition["competitors"][0]["score"]
                awayScore = competition["competitors"][1]["score"]
                if (int(homeScore) > int(awayScore)):
                    homeScoreColor = "#ff0"
                    awayScoreColor = "#fff"
                elif (int(awayScore) > int(homeScore)):
                    homeScoreColor = "#fff"
                    awayScoreColor = "#ff0"
                else:
                    homeScoreColor = "#fff"
                    awayScoreColor = "#fff"

        if displayType == "retro":
            retroTextColor = "#ffe065"
            retroBackgroundColor = "#000"
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
                                children = get_date_column(showDateTime, now, retroTextColor, retroBackgroundColor, retroBorderColor),
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
                            render.Stack(
                                children = get_gametime_column(showDateTime, gameTime, retroTextColor, retroBackgroundColor, retroBorderColor),
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
                                children = get_date_column(showDateTime, now, textColor, backgroundColor, borderColor),
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
                            render.Stack(
                                children = get_gametime_column(showDateTime, gameTime, textColor, backgroundColor, borderColor),
                            ),
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
                                children = get_date_column(showDateTime, now, textColor, backgroundColor, borderColor),
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
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = get_gametime_column(showDateTime, gameTime, textColor, backgroundColor, borderColor),
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
                                children = get_date_column(showDateTime, now, textColor, backgroundColor, borderColor),
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
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = get_gametime_column(showDateTime, gameTime, textColor, backgroundColor, borderColor),
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
                                children = get_date_column(showDateTime, now, textColor, backgroundColor, borderColor),
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
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = get_gametime_column(showDateTime, gameTime, textColor, backgroundColor, borderColor),
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
                                children = get_date_column(showDateTime, now, textColor, backgroundColor, borderColor),
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
                            render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "start",
                                children = get_gametime_column(showDateTime, gameTime, textColor, backgroundColor, borderColor),
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

cycleSpeeds = [
    schema.Option(
        display = "60 seconds",
        value = "60",
    ),
    schema.Option(
        display = "30 seconds",
        value = "30",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "place",
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
                icon = "cog",
                default = pregameOptions[0].value,
                options = pregameOptions,
            ),
            schema.Toggle(
                id = "displayDateTime",
                name = "Current Date/Time",
                desc = "A toggle to display the current date/time rather than game time/status.",
                icon = "calendar",
                default = False,
            ),
            schema.Dropdown(
                id = "cycleSpeed",
                name = "Cycle Speed",
                desc = "If this value is greater than your Tidbyt's App cycle speed, you may not see all the scores.",
                icon = "clock",
                default = cycleSpeeds[2].value,
                options = cycleSpeeds,
            ),
        ],
    )

def get_scores(urls):
    allscores = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        all([i, allscores])
        print(all)

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

def get_background_color(team, displayType, color, altColor):
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

def get_date_column(display, now, textColor, backgroundColor, borderColor):
    if display:
        dateTimeColumn = [
            render.Box(width = 32, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                render.Box(width = 1, height = 8),
                render.Text(color = textColor, content = now.format("3:04"), font = "tb-8"),
            ])),
            render.Box(width = 32, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                render.Text(color = textColor, content = now.format("Jan").upper() + now.format(" 2"), font = "tb-8"),
            ])),
        ]
    else:
        dateTimeColumn = []
    return dateTimeColumn

def get_gametime_column(display, gameTime, textColor, backgroundColor, borderColor):
    if display:
        gameTimeColumn = []
    else:
        gameTimeColumn = [
            render.Stack(
                children = [
                    render.Column(
                        children = [
                            render.Box(width = 64, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                render.Box(width = 1, height = 8, color = borderColor),
                                render.Box(width = 62, height = 8, child = render.Box(width = 60, height = 7, color = backgroundColor, child = render.Text(content = gameTime, color = textColor, font = "CG-pixel-3x5-mono"))),
                                render.Box(width = 1, height = 8, color = borderColor),
                            ])),
                        ],
                    ),
                ],
            ),
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

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()

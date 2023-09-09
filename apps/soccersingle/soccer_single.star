"""
Applet: Soccer Single
Summary: Soccer Single Team
Description: Show upcoming / current / future game for a single soccer team regardless of the league / tournament they are playing in - one app tracks the team everywhere.
Author: jvivona
"""
# 20230812 added display of penalty kick score if applicable
#          toned down colors when display team colors - you couldn't see winner score if team color was also yellow
# 20230829 fixed PK score - in a different place for single match results..   Not enough testing :-)

# Tons of thanks to @whyamihere/@rs7q5 for the API assistance - couldn't have gotten here without you
# and thanks to @dinotash/@dinosaursrarr for making me think deep thoughts about connected schema fields
# and of course - the original author of a bunch of this display code is @Lunchbox8484

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23241

CACHE_TTL_SECONDS = 60

# this is for when we are handling 2 stage cache - leave this here
#CACHE2_ADD_TTL_SECONDS = 86400

DEFAULT_TIMEZONE = "America/New_York"
MISSING_LOGO = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png?src=soccermens"
DEFAULT_TEAM = "203"
API = "https://site.api.espn.com/apis/site/v2/sports/soccer/%s/teams/%s"
TEAM_SEARCH_API = "https://tidbyt.apis.ajcomputers.com/soccer/api/search/%s"
DEFAULT_TEAM_DISPLAY = "visitor"  # default to Visitor first, then Home - US order
DEFAULT_DISPLAY_SPEED = "2000"

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

def main(config):
    renderCategory = []

    # we already need now value in multiple places - so just go ahead and get it and use it
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    if config.get("teamid"):
        teamid = json.decode(config.get("teamid"))["value"]
    else:
        teamid = DEFAULT_TEAM

    league = API % ("all", str(teamid))
    teamdata = get_scores(league)
    scores = teamdata["nextEvent"]

    if len(scores) > 0:
        leagueAbbr = scores[0]["league"]["abbreviation"][0:6]
        leagueSlug = scores[0]["league"]["slug"]
        displayType = config.get("displayType", "colors")

        #logoType = config.get("logoType", "primary")
        timeColor = config.get("displayTimeColor", "#FFF")

        rotationSpeed = int(config.get("displaySpeed", DEFAULT_DISPLAY_SPEED))

        for _, s in enumerate(scores):
            gameStatus = s["competitions"][0]["status"]["type"]["state"]
            competition = s["competitions"][0]
            home = competition["competitors"][0]["team"]["abbreviation"]
            away = competition["competitors"][1]["team"]["abbreviation"]
            homeTeamName = competition["competitors"][0]["team"]["shortDisplayName"]
            awayTeamName = competition["competitors"][1]["team"]["shortDisplayName"]

            homeColorCheck = json.decode(get_cachable_data(API % ("all", str(competition["competitors"][0]["id"]))))["team"]["color"]
            if homeColorCheck == "NO":
                homePrimaryColor = "000000"
            else:
                homePrimaryColor = homeColorCheck

            awayColorCheck = json.decode(get_cachable_data(API % ("all", str(competition["competitors"][1]["id"]))))["team"]["color"]
            if awayColorCheck == "NO":
                awayPrimaryColor = "000000"
            else:
                awayPrimaryColor = awayColorCheck
            homeColor = get_background_color(displayType, homePrimaryColor)
            awayColor = get_background_color(displayType, awayPrimaryColor)

            homeLogoCheck = competition["competitors"][0]["team"].get("logos", "NO")
            if homeLogoCheck == "NO":
                homeLogoURL = MISSING_LOGO
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logos"][0]["href"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logos", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = MISSING_LOGO
            else:
                awayLogoURL = competition["competitors"][1]["team"]["logos"][0]["href"]
            homeLogo = get_logoType(homeLogoURL if homeLogoURL != "" else MISSING_LOGO)
            awayLogo = get_logoType(awayLogoURL if awayLogoURL != "" else MISSING_LOGO)
            homeLogoSize = get_logoSize()
            awayLogoSize = get_logoSize()
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
                    # check to see if the game is today or not.   If not today, show date + time
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameDate = convertedTime.format("Jan 2 ")
                    else:
                        gameDate = convertedTime.format("2 Jan ")
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04PM")[:-1]
                    gameTime = gameDate + gameTimeFmt
                else:
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04PM")[:-1]
                    gameTime = gameTimeFmt

                # need to get the legaue the game is being played in, then go query the "other" team's record can't use ALL here becuase they may have another game before this One
                # we're just going to get them both
                homeData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][0]["id"]))))
                awayData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][1]["id"]))))

                checkHomeTeamRecord = homeData["team"]["record"].get("items", "NO")
                if checkHomeTeamRecord == "NO":
                    homeScore = ""
                else:
                    homeScore = checkHomeTeamRecord[0]["summary"]

                checkAwayTeamRecord = awayData["team"]["record"].get("items", "NO")
                if checkAwayTeamRecord == "NO":
                    awayScore = ""
                else:
                    awayScore = checkAwayTeamRecord[0]["summary"]

            if gameStatus == "in":
                gameTime = competition["status"]["type"]["shortDetail"]
                homeScore = competition["competitors"][0]["score"]["displayValue"]
                homeScoreColor = "#fff"
                awayScore = competition["competitors"][1]["score"]["displayValue"]
                awayScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = competition["status"]["type"]["shortDetail"]
                gameDate = competition["date"]
                convertedTime = time.parse_time(gameDate, format = "2006-01-02T15:04Z").in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    # check to see if the game is today or not.   If not today, show date
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameTime = convertedTime.format("1/2 ") + gameTime
                    else:
                        gameTime = convertedTime.format("2 Jan ") + gameTime
                gameName = competition["status"]["type"]["name"]

                if gameName == "STATUS_POSTPONED":
                    scoreFont = "CG-pixel-3x5-mono"

                    #if game is PPD - show records instead of blanks
                    homeScore = competition["competitors"][0]["records"][0]["summary"]
                    awayScore = competition["competitors"][1]["records"][0]["summary"]
                    gameTime = "Postponed"
                else:
                    homeScore = competition["competitors"][0]["score"]["displayValue"]
                    awayScore = competition["competitors"][1]["score"]["displayValue"]
                    if (int(homeScore) > int(awayScore)):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayScore) > int(homeScore)):
                        homeScoreColor = "#fffc"
                        awayScoreColor = "#ff0"
                    else:
                        homeScoreColor = "#fff"
                        awayScoreColor = "#fff"

                # if FT-Pens - get penalty shootout score & append to score
                if gameName == "STATUS_FINAL_PEN":
                    scoreFont = "CG-pixel-3x5-mono"
                    homeShootoutScore = competition["competitors"][0]["score"]["shootoutScore"]
                    awayShootoutScore = competition["competitors"][1]["score"]["shootoutScore"]
                    homeScore = "%s (%s)" % (homeScore, str(int(homeShootoutScore)))
                    awayScore = "%s (%s)" % (awayScore, str(int(awayShootoutScore)))
                    if (int(homeShootoutScore) > int(awayShootoutScore)):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayShootoutScore) > int(homeShootoutScore)):
                        homeScoreColor = "#fffc"
                        awayScoreColor = "#ff0"
                    else:
                        homeScoreColor = "#fff"
                        awayScoreColor = "#fff"

            # settle needed values into dict
            homeInfo = dict(abbreviation = home[:3], color = homeColor, teamname = homeTeamName, score = homeScore, logo = homeLogo, logosize = homeLogoSize, scorecolor = homeScoreColor)
            awayInfo = dict(abbreviation = away[:3], color = awayColor, teamname = awayTeamName, score = awayScore, logo = awayLogo, logosize = awayLogoSize, scorecolor = awayScoreColor)

            # determine which team to show first - thanks for @jesushairdo for this new option / way to display - stop being us centric always
            if config.get("team_sequence", DEFAULT_TEAM_DISPLAY) == "home":
                matchInfo = [homeInfo, awayInfo]
            else:
                matchInfo = [awayInfo, homeInfo]

            if displayType == "retro":
                retroTextColor = "#ffe065"
                retroFont = "CG-pixel-3x5-mono"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 13, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 13, child = render.Text(content = get_team_name(matchInfo[0]["teamname"]), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = retroTextColor, font = retroFont)),
                                        ])),
                                        render.Box(width = 64, height = 13, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 13, child = render.Text(content = get_team_name(matchInfo[1]["teamname"]), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = retroTextColor, font = retroFont)),
                                        ])),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "horizontal":
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
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Box(width = 32, height = 26, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 26, child = render.Image(matchInfo[0]["logo"], width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 17),
                                                                render.Box(width = 32, height = 10, color = "#000a", child = render.Text(content = matchInfo[0]["score"], color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                                render.Box(width = 32, height = 26, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 26, child = render.Image(matchInfo[1]["logo"], width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 17),
                                                                render.Box(width = 32, height = 10, color = "#000a", child = render.Text(content = matchInfo[1]["score"], color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "logos":
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(matchInfo[0]["logo"], width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = matchInfo[0]["score"], color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(matchInfo[1]["logo"], width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = matchInfo[1]["score"], color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "black":
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 13, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 15, child = render.Image(matchInfo[0]["logo"], width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[0]["abbreviation"], color = matchInfo[0]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 13, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 15, child = render.Image(matchInfo[1]["logo"], width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[1]["abbreviation"], color = matchInfo[1]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            else:
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 13, color = matchInfo[0]["color"] + "77", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 17, child = render.Image(matchInfo[0]["logo"], width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[0]["abbreviation"], color = matchInfo[0]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 13, color = matchInfo[1]["color"] + "77", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 17, child = render.Image(matchInfo[1]["logo"], width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[1]["abbreviation"], color = matchInfo[1]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

        return render.Root(
            delay = rotationSpeed,
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
        display = "Horizontal",
        value = "horizontal",
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
        display = "Nothing",
        value = "nothing",
    ),
]

displayFirstOptions = [
    schema.Option(
        display = "Away Team",
        value = "visitor",
    ),
    schema.Option(
        display = "Home Team",
        value = "home",
    ),
]

displaySpeeds = [
    schema.Option(
        display = "1 second (fast)",
        value = "1000",
    ),
    schema.Option(
        display = "1.5 seconds",
        value = "1500",
    ),
    schema.Option(
        display = "2 seconds (medium)",
        value = "2000",
    ),
    schema.Option(
        display = "2.5 seconds",
        value = "2500",
    ),
    schema.Option(
        display = "3 seconds (slow)",
        value = "3000",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "teamid",
                name = "Team Name to search for",
                desc = "Team Name to search for",
                icon = "futbol",
                handler = search_teams,
            ),
            schema.Dropdown(
                id = "team_sequence",
                name = "Display which team first?",
                desc = "Home First or Away First ",
                icon = "arrowsRotate",
                default = displayFirstOptions[0].value,
                options = displayFirstOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "desktop",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
            schema.Color(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "palette",
                default = "#FFF",
            ),

            #schema.Dropdown(
            #    id = "displaySpeed",
            #    name = "Time to display each score",
            #    desc = "Display time for each score",
            #    icon = "stopwatch",
            #    default = "2000",
            #    options = displaySpeeds,
            #),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format (default is Intl).",
                icon = "calendarDays",
                default = False,
            ),
        ],
    )

def search_teams(team_text):
    if len(team_text) > 3:
        result = http.get(TEAM_SEARCH_API % team_text).body()
        if len(result) > 0:
            return [schema.Option(value = s["id"], display = "%s" % s["displayName"]) for s in json.decode(result)]

    return []

def get_scores(urls):
    allscores = []

    #for i, s in urls.items():
    data = get_cachable_data(urls)
    decodedata = json.decode(data)
    allscores.extend(decodedata["team"])

    #all([i, allscores])
    all(allscores)
    return decodedata["team"]

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

def get_background_color(displayType, color):
    if displayType == "black" or displayType == "retro":
        color = "#222"
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#222222"
    return color

def get_logoType(logo):
    logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
    logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
    logo = get_cachable_data(logo + "&h=50&w=50")
    return logo

def get_logoSize():
    logosize = int(16)
    return logosize

def get_date_column(display, now, textColor, borderColor, displayType, gameTime, timeColor):
    if display:
        theTime = now.format("3:04")
        if len(str(theTime)) > 4:
            timeBox = 24
            statusBox = 40
        else:
            timeBox = 20
            statusBox = 44
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
    else:
        dateTimeColumn = []
    return dateTimeColumn

def get_shortened_display(text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    words = json.decode(SHORTENED_WORDS)
    for _, s in enumerate(words):
        text = text.replace(s, words[s])
    return text

def get_gametime_column(gameTime, textColor, leagueAbbr):
    # I swear - this is the only way...

    gameTimeColumn = [
        render.WrappedText(width = 25, height = 6, content = leagueAbbr, linespacing = 1, font = "CG-pixel-3x5-mono", color = textColor, align = "center"),
        render.WrappedText(width = 39, height = 6, content = gameTime, linespacing = 1, font = "CG-pixel-3x5-mono", color = textColor, align = "right"),
    ]
    return gameTimeColumn

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

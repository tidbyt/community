"""
Applet: SoccerMens
Summary: Displays men's soccer scores for various leages and tournaments
Description: Displays live and upcoming soccer scores from a data feed.   Heavily taken from the other sports score apps - @LunchBox8484 is the original.
Author: jvivona. Modified by jesushairdo
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 60
DEFAULT_TIMEZONE = "America/New_York"
SPORT = "soccer"

MISSING_LOGO = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png?src=soccermens"

DEFAULT_LEAGUE = "ger.1"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/"

DEFAULT_DISPLAY_ORDER = "home"

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
    selectedLeague = config.get("leagueOptions", DEFAULT_LEAGUE)

    # obtain the selected display order
    selectedDisplayOrder = config.get("displayOrder", DEFAULT_DISPLAY_ORDER)
    if selectedDisplayOrder == "home":
        firstTeamIndex = 0
        secondTeamIndex = 1
    else:
        firstTeamIndex = 1
        secondTeamIndex = 0

    # we already need now value in multiple places - so just go ahead and get it and use it
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    now = time.now()

    # calculate start and end date if we are set to use range of days
    date_range_search = ""
    if config.bool("day_range", False):
        back_time = now - time.parse_duration("%dh" % (int(config.get("days_back", 1)) * 24))
        fwd_time = now + time.parse_duration("%dh" % (int(config.get("days_forward", 1)) * 24))
        date_range_search = "?dates=%s-%s" % (back_time.format("20060102"), (fwd_time.format("20060102")))

    league = {API: API + selectedLeague + "/scoreboard" + date_range_search}
    instanceNumber = int(config.get("instanceNumber", 1))
    totalInstances = int(config.get("instancesCount", 1))
    scores = get_scores(league, instanceNumber, totalInstances)

    if len(scores) > 0:
        displayType = config.get("displayType", "colors")

        #logoType = config.get("logoType", "primary")
        timeColor = config.get("displayTimeColor", "#FFF")
        rotationSpeed = 15 // len(scores)

        for _, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]

            firstTeamCompetitor = competition["competitors"][firstTeamIndex]
            secondTeamCompetitor = competition["competitors"][secondTeamIndex]
            firstTeam = competition["competitors"][firstTeamIndex]["team"]["abbreviation"]
            secondTeam = competition["competitors"][secondTeamIndex]["team"]["abbreviation"]

            firstTeamName = competition["competitors"][firstTeamIndex]["team"]["shortDisplayName"]
            secondTeamName = competition["competitors"][secondTeamIndex]["team"]["shortDisplayName"]

            firstTeamColorCheck = competition["competitors"][firstTeamIndex]["team"].get("color", "NO")
            if firstTeamColorCheck == "NO":
                firstTeamPrimaryColor = "000000"
            else:
                firstTeamPrimaryColor = competition["competitors"][firstTeamIndex]["team"]["color"]

            secondTeamColorCheck = competition["competitors"][secondTeamIndex]["team"].get("color", "NO")

            if secondTeamColorCheck == "NO":
                secondTeamPrimaryColor = "000000"
            else:
                secondTeamPrimaryColor = competition["competitors"][secondTeamIndex]["team"]["color"]

            firstTeamColor = get_background_color(displayType, firstTeamPrimaryColor)
            secondTeamColor = get_background_color(displayType, secondTeamPrimaryColor)

            firstTeamLogoCheck = competition["competitors"][firstTeamIndex]["team"].get("logo", "NO")

            if firstTeamLogoCheck == "NO":
                firstTeamLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                firstTeamLogoURL = competition["competitors"][firstTeamIndex]["team"]["logo"]

            secondTeamLogoCheck = competition["competitors"][secondTeamIndex]["team"].get("logo", "NO")

            if secondTeamLogoCheck == "NO":
                secondTeamLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                secondTeamLogoURL = competition["competitors"][secondTeamIndex]["team"]["logo"]

            firstTeamLogo = get_logoType(firstTeamLogoURL if firstTeamLogoURL != "" else MISSING_LOGO)
            secondTeamLogo = get_logoType(secondTeamLogoURL if secondTeamLogoURL != "" else MISSING_LOGO)
            firstTeamLogoSize = get_logoSize()
            secondTeamLogoSize = get_logoSize()
            firstTeamScore = ""
            secondTeamScore = ""
            gameTime = ""
            firstTeamScoreColor = "#fff"
            secondTeamScoreColor = "#fff"
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
                        gameDate = convertedTime.format("1/2 ")
                    else:
                        gameDate = convertedTime.format("2 Jan ")
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04 PM")
                    gameTime = gameDate + gameTimeFmt
                else:
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04 PM")
                    gameTime = gameTimeFmt
                checkSeries = competition.get("series", "NO")
                checkRecord = firstTeamCompetitor.get("records", "NO")
                if checkRecord == "NO":
                    firstTeamScore = "0-0-0"
                    secondTeamScore = "0-0-0"
                else:
                    firstTeamScore = competition["competitors"][firstTeamIndex]["records"][0]["summary"]
                    secondTeamScore = competition["competitors"][secondTeamIndex]["records"][0]["summary"]

            if gameStatus == "in":
                gameTime = s["status"]["type"]["shortDetail"]
                firstTeamScore = competition["competitors"][firstTeamIndex]["score"]
                firstTeamScoreColor = "#fff"
                secondTeamScore = competition["competitors"][secondTeamIndex]["score"]
                secondTeamScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = s["status"]["type"]["shortDetail"]
                gameDate = s["date"]
                convertedTime = time.parse_time(gameDate, format = "2006-01-02T15:04Z")
                if convertedTime.format("1/2") != now.format("1/2"):
                    # check to see if the game is today or not.   If not today, show date
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameTime = convertedTime.format("1/2 ") + gameTime
                    else:
                        gameTime = convertedTime.format("2 Jan ") + gameTime
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
                    firstTeamScore = ""
                    secondTeamScore = ""
                    gameTime = "Postponed"
                else:
                    firstTeamScore = competition["competitors"][firstTeamIndex]["score"]
                    secondTeamScore = competition["competitors"][secondTeamIndex]["score"]
                    if (int(firstTeamScore) > int(secondTeamScore)):
                        firstTeamScoreColor = "#ff0"
                        secondTeamScoreColor = "#fffc"
                    elif (int(secondTeamScore) > int(firstTeamScore)):
                        firstTeamScoreColor = "#fffc"
                        secondTeamScoreColor = "#ff0"
                    else:
                        firstTeamScoreColor = "#fff"
                        secondTeamScoreColor = "#fff"

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
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 12, color = firstTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 12, child = render.Text(content = get_team_name(firstTeamName), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 12, child = render.Text(content = get_record(firstTeamScore), color = retroTextColor, font = retroFont)),
                                        ])),
                                        render.Box(width = 64, height = 12, color = secondTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 12, child = render.Text(content = get_team_name(secondTeamName), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 12, child = render.Text(content = get_record(secondTeamScore), color = retroTextColor, font = retroFont)),
                                        ])),
                                    ],
                                ),
                                render.Stack(
                                    children = get_gametime_column(False, gameTime, timeColor, retroBackgroundColor, retroBorderColor),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "horizontal":
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
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Box(width = 32, height = 24, color = firstTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 24, child = render.Image(firstTeamLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 16),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = firstTeamScore, color = firstTeamScoreColor, font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                                render.Box(width = 32, height = 24, color = secondTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 24, child = render.Image(secondTeamLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 16),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = secondTeamScore, color = secondTeamScoreColor, font = scoreFont)),
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
                                    children = get_gametime_column(False, gameTime, timeColor, backgroundColor, borderColor),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "logos":
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = firstTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(firstTeamLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = firstTeamScore, color = firstTeamScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = secondTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(secondTeamLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = secondTeamScore, color = secondTeamScoreColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_gametime_column(False, gameTime, timeColor, backgroundColor, borderColor),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "black":
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(firstTeamLogo, width = firstTeamLogoSize, height = firstTeamLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = firstTeam[:3], color = firstTeamScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(firstTeamScore), color = firstTeamScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(secondTeamLogo, width = secondTeamLogoSize, height = secondTeamLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = secondTeam[:3], color = secondTeamScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(secondTeamScore), color = secondTeamScoreColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_gametime_column(False, gameTime, timeColor, backgroundColor, borderColor),
                                ),
                            ],
                        ),
                    ],
                )

            else:
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
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = firstTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(firstTeamLogo, width = firstTeamLogoSize, height = firstTeamLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = firstTeam[:3], color = firstTeamScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(firstTeamScore), color = firstTeamScoreColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = secondTeamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 16, child = render.Image(secondTeamLogo, width = secondTeamLogoSize, height = secondTeamLogoSize)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = secondTeam[:3], color = secondTeamScoreColor, font = textFont)),
                                                    render.Box(width = 24, height = 12, child = render.Text(content = get_record(secondTeamScore), color = secondTeamScoreColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = get_gametime_column(False, gameTime, timeColor, backgroundColor, borderColor),
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

leagueOptions = [
    schema.Option(
        display = "Dutch Eredivisie",
        value = "ned.1",
    ),
    schema.Option(
        display = "English Carabo Cup",
        value = "eng.league_cup",
    ),
    schema.Option(
        display = "English FA Cup",
        value = "eng.fa",
    ),
    schema.Option(
        display = "English League Championship",
        value = "eng.2",
    ),
    schema.Option(
        display = "English League One",
        value = "eng.3",
    ),
    schema.Option(
        display = "English League Two",
        value = "eng.4",
    ),
    schema.Option(
        display = "English National League",
        value = "eng.5",
    ),
    schema.Option(
        display = "English Premier League",
        value = "eng.1",
    ),
    schema.Option(
        display = "French Ligue 1",
        value = "fra.1",
    ),
    schema.Option(
        display = "FIFA World Cup",
        value = "fifa.world",
    ),
    schema.Option(
        display = "German Bundesliga",
        value = "ger.1",
    ),
    schema.Option(
        display = "Italian Serie A",
        value = "ita.1",
    ),
    schema.Option(
        display = "Mexican Liga BBVA MX",
        value = "mex.1",
    ),
    schema.Option(
        display = "Scottish Premiership",
        value = "sco.1",
    ),
    schema.Option(
        display = "Spanish LaLiga",
        value = "esp.1",
    ),
    schema.Option(
        display = "UEFA Champions League",
        value = "uefa.champions",
    ),
    schema.Option(
        display = "UEFA Europa League",
        value = "uefa.europa",
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
        display = "Horizontal",
        value = "horizontal",
    ),
    schema.Option(
        display = "Retro",
        value = "retro",
    ),
]

displayTeamOrderOptions = [
    schema.Option(
        display = "Home Team First",
        value = "home",
    ),
    schema.Option(
        display = "Away Team First",
        value = "away",
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
        display = "Nothing",
        value = "nothing",
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
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
    schema.Option(
        display = "Pink",
        value = "#FC46AA",
    ),
]

daysOptions = [
    schema.Option(
        display = "0",
        value = "0",
    ),
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
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "leagueOptions",
                name = "League / Tournament",
                desc = "League or Tournament ",
                icon = "futbol",
                default = leagueOptions[0].value,
                options = leagueOptions,
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
                id = "displayOrder",
                name = "Team Display Order",
                desc = "Select which team you want to show first",
                icon = "desktop",
                default = displayTeamOrderOptions[0].value,
                options = displayTeamOrderOptions,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "palette",
                default = colorOptions[0].value,
                options = colorOptions,
            ),
            schema.Dropdown(
                id = "instancesCount",
                name = "Total Instances of App",
                desc = "Total Instance Count (# of times you have added this app to your Tidbyt).",
                icon = "list",
                default = instancesCounts[0].value,
                options = instancesCounts,
            ),
            schema.Dropdown(
                id = "instanceNumber",
                name = "App Instance Number",
                desc = "Select which instance of the app this is.",
                icon = "hashtag",
                default = instanceNumbers[0].value,
                options = instanceNumbers,
            ),
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
            schema.Toggle(
                id = "day_range",
                name = "Enable range of days",
                desc = "Enable showing scores in a range of days",
                icon = "rightLeft",
                default = False,
            ),
            schema.Generated(
                id = "generated",
                source = "day_range",
                handler = show_day_range,
            ),
        ],
    )

def show_day_range(day_range):
    # need to do the string comparison here to make it consistent instead of converting to bool - its a whole thing
    if day_range == "true":
        return [
            schema.Dropdown(
                id = "days_back",
                name = "# of days back to show",
                desc = "Get only data from Today +/- 1 Day",
                icon = "arrowLeft",
                default = "1",
                options = daysOptions,
            ),
            schema.Dropdown(
                id = "days_forward",
                name = "# of days forward to show",
                desc = "Number of days forward to search for scores",
                icon = "arrowRight",
                default = "1",
                options = daysOptions,
            ),
        ]
    else:
        return []

def get_scores(urls, instanceNumber, totalInstances):
    allscores = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        all([i, allscores])

    #scoresLengthPerInstance = allScoresLength / totalInstances
    if instanceNumber > totalInstances:
        for i in range(0, int(len(allscores))):
            allscores.pop()
        return allscores
    else:
        thescores = [allscores[(i * len(allscores)) // totalInstances:((i + 1) * len(allscores)) // totalInstances] for i in range(totalInstances)]
        return thescores[instanceNumber - 1]

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
        color = "#222"
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

def get_cachable_data(url):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, res.body(), CACHE_TTL_SECONDS)

    return res.body()

"""
Applet: SoccerWomens
Summary: Displays women's soccer scores for various leages and tournaments
Description: Displays live and upcoming soccer scores from a data feed.   Heavily taken from the other sports score apps - @LunchBox8484 is the original.
Author: jvivona
"""
# thanks to @jesushairdo for the new option to be able to show home or away team first.  Let's be more international :-)
# 20230812 added display of penalty kick score if applicable
#          toned down colors when display team colors - you couldn't see winner score if team color was also yellow
# 20230816 changed list of tournaments to get dynamically instead of having to do a PR each time I add one
# 20230906 found bug in ESPN API where some teams don't have abbreviation - added code to check for it and display value + indiicator

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 23249

CACHE_TTL_SECONDS = 60
DEFAULT_TIMEZONE = "America/New_York"
SPORT = "soccer"

MISSING_LOGO = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png?src=soccerwomens"

DEFAULT_LEAGUE = "eng.w.1"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/"

ABBR_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/soccerwomens/league_abbr.json"
COMPS_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/soccerwomens/comps.json"
COMPS_TTL = 86400  # increase this to 24 hours after dev - we're not making changes that often

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
    LEAGUE_ABBR = json.decode(http.get(url = ABBR_URL, ttl_seconds = COMPS_TTL).body())
    renderCategory = []
    selectedLeague = config.get("leagueOptions", DEFAULT_LEAGUE)
    leagueAbbr = LEAGUE_ABBR[selectedLeague][0:6]

    # we already need now value in multiple places - so just go ahead and get it and use it
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    # calculate start and end date if we are set to use range of days
    date_range_search = ""
    if config.bool("day_range", False):
        back_time = now - time.parse_duration("%dh" % (int(config.get("days_back", 1)) * 24))
        fwd_time = now + time.parse_duration("%dh" % (int(config.get("days_forward", 1)) * 24))
        date_range_search = "?dates=%s-%s" % (back_time.format("20060102"), (fwd_time.format("20060102")))
    elif selectedLeague == "aus.w.1":
        # fix for feed - Aus Women's league - by default shows no scheduled matches - have to force a date range, if you have not already selected one
        back_time = now - time.parse_duration("%dh" % (0 * 24))
        fwd_time = now + time.parse_duration("%dh" % (6 * 24))
        date_range_search = "?dates=%s-%s" % (back_time.format("20060102"), (fwd_time.format("20060102")))

    league = {API: API + selectedLeague + "/scoreboard" + date_range_search}

    scores = get_scores(league)

    if len(scores) > 0:
        displayType = config.get("displayType", "colors")

        #logoType = config.get("logoType", "primary")
        timeColor = config.get("displayTimeColor", "#FFF")

        rotationSpeed = int(config.get("displaySpeed", DEFAULT_DISPLAY_SPEED))

        for _, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]
            homeCompetitor = competition["competitors"][0]
            home = competition["competitors"][0]["team"].get("abbreviation", competition["competitors"][0]["team"]["name"][0:2].upper() + "*")
            away = competition["competitors"][1]["team"].get("abbreviation", competition["competitors"][1]["team"]["name"][0:2].upper() + "*")
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

            homeColor = get_background_color(displayType, homePrimaryColor)
            awayColor = get_background_color(displayType, awayPrimaryColor)

            homeLogoCheck = competition["competitors"][0]["team"].get("logo", "NO")
            if homeLogoCheck == "NO":
                homeLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logo"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logo", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                awayLogoURL = competition["competitors"][1]["team"]["logo"]
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
                checkSeries = competition.get("series", "NO")
                checkRecord = homeCompetitor.get("records", "NO")
                if checkRecord == "NO":
                    homeScore = ""
                    awayScore = ""
                else:
                    homeScore = competition["competitors"][0]["records"][0]["summary"]
                    awayScore = competition["competitors"][1]["records"][0]["summary"]

            if gameStatus == "in":
                gameTime = s["status"]["type"]["shortDetail"]
                homeScore = competition["competitors"][0]["score"]
                homeScoreColor = "#fff"
                awayScore = competition["competitors"][1]["score"]
                awayScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = s["status"]["type"]["shortDetail"]
                gameDate = s["date"]
                convertedTime = time.parse_time(gameDate, format = "2006-01-02T15:04Z").in_location(timezone)
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
                    seriesNote = competition["notes"][0]["headline"].split(" - ")[0]
                    gameTime = seriesNote
                if checkNotes > 0 and checkSeries == "NO":
                    gameHeadline = competition["notes"][0]["headline"]
                    if gameHeadline.find(" - ") > 0:
                        gameNoteArray = gameHeadline.split(" - ")
                        gameTime = str(gameNoteArray[1]) + " / " + gameTime
                if gameName == "STATUS_POSTPONED":
                    scoreFont = "CG-pixel-3x5-mono"

                    #if game is PPD - show records instead of blanks
                    homeScore = competition["competitors"][0]["records"][0]["summary"]
                    awayScore = competition["competitors"][1]["records"][0]["summary"]
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

                # if FT-Pens - get penalty shootout score & append to score
                if gameName == "STATUS_FINAL_PEN":
                    scoreFont = "CG-pixel-3x5-mono"
                    homeShootoutScore = competition["competitors"][0]["shootoutScore"]
                    awayShootoutScore = competition["competitors"][1]["shootoutScore"]
                    homeScore = "%s (%s)" % (homeScore, homeShootoutScore)
                    awayScore = "%s (%s)" % (awayScore, awayShootoutScore)
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
    http_response = http.get(url = COMPS_URL, ttl_seconds = COMPS_TTL)
    if http_response.status_code != 200:
        fail("Comp list request failed with status {} and result {}".format(http_response.status_code, http_response.body()))
    comps = json.decode(http_response.body())
    comp_options = []

    if len(comps) > 0:
        for comp in comps:
            comp_options.append(
                schema.Option(
                    display = comp["display"],
                    value = comp["value"],
                ),
            )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "leagueOptions",
                name = "League / Tournament",
                desc = "League or Tournament ",
                icon = "futbol",
                default = comp_options[0].value,
                options = comp_options,
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
            schema.Dropdown(
                id = "displaySpeed",
                name = "Time to display each score",
                desc = "Display time for each score",
                icon = "stopwatch",
                default = "2000",
                options = displaySpeeds,
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
                desc = "Number of days back to search for scores",
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

def get_scores(urls):
    allscores = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        all([i, allscores])

    return allscores

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

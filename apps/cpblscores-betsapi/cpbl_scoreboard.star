"""
Applet: CPBL Scoreboard
Summary: Display CPBL scores
Description: Display CPBL game status and scores
Author: yuping917
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 60
DEFAULT_LOCATION = """
{
    "lat": "25.105497",
    "lng": "121.597366",
    "description": "Taipei, TW",
    "locality": "Taipei",
    
    "timezone": "Asia/Taipei"
}
"""

LEAGUE_DISPLAY = "CPBL"
LEAGUE_DISPLAY_OFFSET = -3

nextByTeam = "https://api.b365api.com/v3/events/upcoming?sport_id=16&token=key&league_id=11235&team_id="
nextByleague = "https://api.b365api.com/v3/events/upcoming?sport_id=16&token=key&league_id=11235"
lastByTeam = "https://api.b365api.com/v3/events/ended?sport_id=16&token=key&league_id=11235&team_id="
lastByleague = "https://api.b365api.com/v3/events/ended?sport_id=16&token=key&league_id=11235"

TEAM_LOGO = """
{
    "315045": "https://r2.thesportsdb.com/images/media/team/badge/ljv5o51655923122.png",
    "329121": "https://r2.thesportsdb.com/images/media/team/badge/kk0rch1655923103.png",
    "224095": "https://r2.thesportsdb.com/images/media/team/badge/kehxfy1655923111.png",
    "230422": "https://r2.thesportsdb.com/images/media/team/badge/nbtugc1655923087.png",
    "229259": "https://r2.thesportsdb.com/images/media/team/badge/aj83wn1655923095.png",
    "836779": "https://r2.thesportsdb.com/images/media/team/badge/gx1dgl1680852780.png"
}
"""

GAME_STATUS = """
{
    "0": "Upcoming",
    "1": "Live",
    "2": "Err",
    "3": "Final",
    "4": "Postponed",
    "7": "Cancel",
    "10": "Suspend"
}
"""

def main(config):
    renderCategory = []
    selectedTeam = config.get("selectedTeam", "11235")
    displayType = "horizontal"
    displayTop = config.get("displayTop", "time")
    apikey = config.get("apikey", "")
    if apikey == "":
        return render_error("Missing BetsAPI token")
    timeColor = config.get("displayTimeColor", "#FFA500")
    rotationSpeed = config.get("rotationSpeed", "4")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    iMax = 6
    url = nextByleague
    if selectedTeam == "11235":
        url = lastByleague.replace("key", apikey)
        iMax = 6
    elif selectedTeam != "11235":
        url = lastByTeam.replace("key", apikey) + selectedTeam
        iMax = 3
    scores = get_scores(url)
    scoreFont = "CG-pixel-3x5-mono"
    textColor = "#fff"
    borderColor = "#000"
    awayColor = "#000"
    homeColor = "#000"
    if len(scores) > 0:
        for i, s in enumerate(scores):
            if i >= iMax:
                break
            gameStatus = get_gamestatus(s["time_status"])
            gameTime = s["time"]
            homeId = s["away"]["id"]
            awayId = s["home"]["id"]
            convertedTime = time.from_timestamp(int(gameTime)).in_location(timezone)
            if convertedTime.format("1/2") != now.format("1/2"):
                gameTime = convertedTime.format("Jan 2 Mon")
            else:
                gameTime = "Today"
            if gameStatus != "Final":
                if gameStatus == "Err":
                    continue
                awayScore = "0"
                homeScore = "0"
                gameTime = gameStatus
            else:
                awayScore = s["scores"]["run"]["home"]
                homeScore = s["scores"]["run"]["away"]
                gameTime = gameTime
            awayScoreColor = "#fff"
            homeScoreColor = "#fff"
            if int(homeScore) > int(awayScore):
                homeScoreColor = "#D1D117"
            elif int(homeScore) < int(awayScore):
                awayScoreColor = "#D1D117"
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
                                                        render.Box(width = 32, height = 24, child = render.Image(get_cachable_data(get_logo(awayId)), width = 32, height = 32)),
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
                                                        render.Box(width = 32, height = 24, child = render.Image(get_cachable_data(get_logo(homeId)), width = 32, height = 32)),
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
    if len(text) < 16:
        return text
    else:
        return "FINAL"

def get_scores(url):
    allscores = []
    data = get_cachable_data(url)
    decodedata = json.decode(data)
    allscores.extend(decodedata["results"])
    return allscores

teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "11235",
    ),
    schema.Option(
        display = "Wei Chuan Dragons",
        value = "315045",
    ),
    schema.Option(
        display = "Rakuten Monkeys",
        value = "329121",
    ),
    schema.Option(
        display = "Uni-President Lions",
        value = "224095",
    ),
    schema.Option(
        display = "CTBC Brothers",
        value = "230422",
    ),
    schema.Option(
        display = "Fubon Guardians",
        value = "229259",
    ),
    schema.Option(
        display = "TSG Hawks",
        value = "836779",
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

displayTopOptions = [
    schema.Option(
        display = "League Name",
        value = "league",
    ),
    schema.Option(
        display = "Clock & Game Info",
        value = "time",
    ),
    schema.Option(
        display = "Game Info Only",
        value = "gameinfo",
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
                desc = "Only show games for selected team.",
                icon = "baseballBatBall",
                default = teamOptions[0].value,
                options = teamOptions,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gauge",
                default = rotationOptions[1].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "displayTop",
                name = "Top Display",
                desc = "A toggle of what to display on the top shelf.",
                icon = "clock",
                default = displayTopOptions[1].value,
                options = displayTopOptions,
            ),
            schema.Color(
                id = "displayTimeColor",
                name = "Top Display Color",
                desc = "Select which color you want the top display to be.",
                icon = "brush",
                default = "#EDECDE",
                palette = [
                    "#7AB0FF",
                    "#BFEDC4",
                    "#78DECC",
                    "#DBB5FF",
                ],
            ),
            schema.Text(
                id = "apikey",
                name = "API Key",
                desc = "Enter your BetsAPI token",
                icon = "key",
            ),
        ],
    )

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    return res.body()

def get_logo(team):
    usealtlogo = json.decode(TEAM_LOGO)
    logo = usealtlogo.get(team, "NOLOGO")
    return logo

def get_gamestatus(status):
    gamestatus = json.decode(GAME_STATUS)
    sta = gamestatus.get(status, "EXC")
    return sta

def render_error(error):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(error, font = "tom-thumb"),
        ),
    )

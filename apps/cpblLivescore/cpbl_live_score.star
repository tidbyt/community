"""
Applet: CPBL Live Score
Summary: Display CPBL live scores
Description: Display CPBL live scores & upcoming games. (Require BetsAPI token).
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

url_live = "https://api.b365api.com/v3/events/inplay?sport_id=16&token=key&league_id=11235"
url_upcoming = "https://api.b365api.com/v3/events/upcoming?sport_id=16&token=key&league_id=11235"

TEAM_LOGO = """
{
    "315045": "https://assets.b365api.com/images/t2/b/267/534472.png",
    "230422": "https://assets.b365api.com/images/t2/b/90/180564.png",
    "836779": "https://r2.thesportsdb.com/images/media/team/badge/gx1dgl1680852780.png",
    "329121": "https://assets.b365api.com/images/wp/o/8d4b8b442ce550b84187f6a388dd08e5.png",
    "229259": "https://assets.b365api.com/images/wp/o/dec78d508fac27062963e766d6fd4323.png",
    "224095": "https://assets.b365api.com/images/wp/o/5631bccbd611a4c52edac4e5ea940f1f.png"
}
"""

TEAM_COLOR = """
{
    "315045": "#fdfbf3",
    "230422": "#0e2240",
    "836779": "#074539",
    "329121": "#4b1d18",
    "229259": "#002255",
    "224095": "#df6b00"
}
"""

TEAM_FONTCOLOR = """
{
    "315045": "#9b030b",
    "230422": "#fff",
    "836779": "#fff",
    "329121": "#fff",
    "229259": "#fff",
    "224095": "#fff"
}
"""

GAME_STATUS = """
{
    "0": "Upcoming",
    "1": "Live",
    "2": "Err",
    "3": "End",
    "4": "Postponed",
    "7": "Cancel",
    "10": "Suspend"
}
"""

TEAM_LOCATION = """
{
    "315045": "TPE",
    "230422": "TXG",
    "836779": "KHH",
    "329121": "TYN",
    "229259": "TPH",
    "224095": "TNN"
}
"""

TEAM_SHORTNAME = """
{
    "315045": "DRAGON",
    "230422": "BROTHER",
    "836779": "HAWKS",
    "329121": "RAKUTEN",
    "229259": "FUBON",
    "224095": "UNI-LION"
}
"""

def main(config):
    renderCategory = []
    selectedTeam = config.get("selectedTeam", "11235")
    displayTop = config.get("displayTop", "time")
    displayType = "Other"
    apikey = config.get("apikey", "")
    upcoming_games = 15
    url_bestAPI_live = url_live.replace("key", apikey)
    url_bestAPI_upcoming = url_upcoming.replace("key", apikey)
    if selectedTeam != "11235":
        url_bestAPI_upcoming = url_bestAPI_upcoming + "&team_id=" + selectedTeam
        upcoming_games = 5
    timeColor = config.get("displayTimeColor", "#FFA500")
    rotationSpeed = config.get("rotationSpeed", "5")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    if apikey != "":
        scores = get_scores(url_bestAPI_live)
    else:
        scores = ""
    scoreFont = "CG-pixel-3x5-mono"
    textColor = "#fff"
    borderColor = "#000"
    awayColor = "#000"
    homeColor = "#000"
    if len(scores) > 0:
        for i, s in enumerate(scores):
            gameStatus = get_gamestatus(s["time_status"])
            homeId = s["away"]["id"]
            homeLocation = get_teamlocation(homeId)
            homeScore = s["scores"]["run"]["away"]
            homeColor = get_teamcolor(homeId)
            awayId = s["home"]["id"]
            awayLocation = get_teamlocation(awayId)
            awayScore = s["scores"]["run"]["home"]
            awayColor = get_teamcolor(awayId)
            gameTime = s["time"]
            currentInning = 0
            if gameStatus == "Live":
                liveinning = "Live"
                for x in range(12):
                    if x == 0:
                        continue
                    tempVal = s["scores"].get(str(x), "FALSE")
                    if tempVal != "FALSE":
                        xhomeScore = s["scores"][str(x)]["home"]
                        xawayScore = s["scores"][str(x)]["away"]
                        if xhomeScore != "":
                            if xawayScore == "":
                                currentInning = x
                                liveinning = "TOP " + str(currentInning) + get_inningStr(currentInning)
                                break
                            else:
                                if x == 9:
                                    TBCheck = s["scores"].get(str(10), "FALSE")
                                    if TBCheck == "FALSE":
                                        currentInning = x
                                        liveinning = "BOT " + str(currentInning) + get_inningStr(currentInning)
                                        break
                                continue
                        elif xhomeScore == "":
                            if x == 1:
                                currentInning = x
                                liveinning = "TOP " + str(currentInning) + get_inningStr(currentInning)
                                break
                            else:
                                currentInning = x - 1
                                liveinning = "BOT " + str(currentInning) + get_inningStr(currentInning)
                                break
                    elif tempVal == "FALSE":
                        if x - 1 > 9:
                            liveinning = "TB"
                            break
                        else:
                            break
                gameTime = liveinning
            else:
                convertedTime = time.from_timestamp(int(gameTime)).in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    gameTime = convertedTime.format("Jan 2")
                else:
                    gameTime = convertedTime.format("3:04 PM")
            awayScoreColor = get_teamfontcolor(awayId)
            homeScoreColor = get_teamfontcolor(homeId)
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
                                                render.Box(width = 22, height = 12, child = render.Image(get_cachable_data(get_logo(awayId)), width = 16, height = 16)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = awayLocation, color = awayScoreColor, font = "Dina_r400-6")),
                                                render.Box(width = 24, height = 12, child = render.Text(content = awayScore, color = awayScoreColor, font = scoreFont)),
                                            ])),
                                            render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Box(width = 22, height = 12, child = render.Image(get_cachable_data(get_logo(homeId)), width = 16, height = 16)),
                                                render.Box(width = 24, height = 12, child = render.Text(content = homeLocation, color = homeScoreColor, font = "Dina_r400-6")),
                                                render.Box(width = 24, height = 12, child = render.Text(content = homeScore, color = homeScoreColor, font = scoreFont)),
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
    elif len(scores) == 0:
        if apikey != "":
            games = get_scores(url_bestAPI_upcoming)
            if len(games) > 0:
                for i, s in enumerate(games):
                    if i >= int(upcoming_games):
                        break
                    gameStatus = get_gamestatus(s["time_status"])
                    gameTime = s["time"]
                    convertedTime = time.from_timestamp(int(gameTime)).in_location(timezone)
                    homeId = s["home"]["id"]
                    awayId = s["away"]["id"]
                    if convertedTime.format("1/2") != now.format("1/2"):
                        gameTime = convertedTime.format("Jan 2 Mon")
                    else:
                        gameTime = convertedTime.format("3:04 PM")
                        homeId = s["away"]["id"]
                        awayId = s["home"]["id"]
                    homeLocation = get_teamlocation(homeId)
                    homeColor = get_teamcolor(homeId)
                    awayLocation = get_teamlocation(awayId)
                    awayColor = get_teamcolor(awayId)
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
                                                        render.Box(width = 16, height = 12, child = render.Image(get_cachable_data(get_logo(awayId)), width = 16, height = 16)),
                                                        render.Box(width = 48, height = 12, child = render.Text(content = get_teamshortname(awayId), color = get_teamfontcolor(awayId), font = "Dina_r400-6")),
                                                    ])),
                                                    render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Box(width = 16, height = 12, child = render.Image(get_cachable_data(get_logo(homeId)), width = 16, height = 16)),
                                                        render.Box(width = 48, height = 12, child = render.Text(content = get_teamshortname(homeId), color = get_teamfontcolor(homeId), font = "Dina_r400-6")),
                                                    ])),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    )
        elif apikey == "":
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
                                children = get_api_require_column(),
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

def get_api_require_column():
    dateTimeColumn = [
        render.Box(width = 64, height = 5, child = render.Stack(children = [
            render.Box(width = 64, height = 5, color = "#000"),
            render.Box(width = 64, height = 5, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = "#fff", content = "Require BetsAPI token.", font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]
    return dateTimeColumn

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
    if len(text) < 20:
        return text
    else:
        return "UPCOMING"

def get_scores(urls):
    allscores = []
    data = get_cachable_data(urls)
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
                desc = "Show selected team's upcoming games.",
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
                default = "#E9F4F6",
                palette = [
                    "#7AB0FF",
                    "#BFEDC4",
                    "#78DECC",
                    "#DBB5FF",
                ],
            ),
            schema.Text(
                id = "apikey",
                name = "API Token",
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

def get_teamcolor(team):
    usealtcolor = json.decode(TEAM_COLOR)
    color = usealtcolor.get(team, "#fff")
    return color

def get_teamfontcolor(team):
    usealtcolor = json.decode(TEAM_FONTCOLOR)
    color = usealtcolor.get(team, "#fff")
    return color

def get_teamlocation(team):
    usealtlocation = json.decode(TEAM_LOCATION)
    location = usealtlocation.get(team, "NO")
    return location

def get_teamshortname(team):
    usealtshort = json.decode(TEAM_SHORTNAME)
    sName = usealtshort.get(team, "NO")
    return sName

def get_gamestatus(status):
    gamestatus = json.decode(GAME_STATUS)
    sta = gamestatus.get(status, "NO")
    return sta

def get_inningStr(x):
    if x == 1:
        intStr = "st"
    elif x == 2:
        intStr = "nd"
    elif x == 3:
        intStr = "rd"
    else:
        intStr = "th"
    return intStr

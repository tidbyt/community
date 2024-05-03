"""
Applet: CPBL Scores
Summary: CPBL scores and schedule
Description: Display CPBL scores and schedule, require theSportDB API key .
Author: yuping917
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
    "lat": "25.105497",
    "lng": "121.597366",
    "description": "Taipei, TW",
    "locality": "Taipei",
    
    "timezone": "Asia/Taipei"
}
"""

LEAGUE_DISPLAY = "CPBL"
LEAGUE_DISPLAY_OFFSET = -3

nextFiveByTeam = "https://www.thesportsdb.com/api/v1/json/key/eventsnext.php?id="
nextFiveteenByleague = "https://www.thesportsdb.com/api/v1/json/key/eventsnextleague.php?id=5111"
lastFiveByTeam = "https://www.thesportsdb.com/api/v1/json/3/eventslast.php?id="
lastFiveteenByleague = "https://www.thesportsdb.com/api/v1/json/key/eventspastleague.php?id=5111"

TEAM_LOGO = """
{
    "144302": "https://www.thesportsdb.com/images/media/team/badge/ljv5o51655923122.png",
    "144300": "https://www.thesportsdb.com/images/media/team/badge/kk0rch1655923103.png",
    "144301": "https://www.thesportsdb.com/images/media/team/badge/kehxfy1655923111.png",
    "144298": "https://www.thesportsdb.com/images/media/team/badge/nbtugc1655923087.png",
    "144299": "https://www.thesportsdb.com/images/media/team/badge/aj83wn1655923095.png",
    "147333": "https://www.thesportsdb.com/images/media/team/badge/gx1dgl1680852780.png"
}
"""

def main(config):
    renderCategory = []
    SportDB_URL = []
    selectedTeam = config.get("selectedTeam", "144302")
    displayType = "horizontal"
    displayTop = config.get("displayTop", "time")
    databaseType = config.get("databaseType", "past")
    apikey = config.get("apikey", "3")
    timeColor = config.get("displayTimeColor", "#FFA500")
    rotationSpeed = config.get("rotationSpeed", "5")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    aUrl = ""
    bUrl = ""
    FTMax = 5
    NSMax = 5
    if selectedTeam == "5111":
        if databaseType == "both":
            aUrl = lastFiveteenByleague.replace("key", apikey)
            bUrl = nextFiveteenByleague.replace("key", apikey)
            FTMax = 5
            NSMax = 5
        elif databaseType == "past":
            aUrl = lastFiveteenByleague.replace("key", apikey)
            bUrl = ""
            FTMax = 5
            NSMax = 0
        elif databaseType == "feature":
            aUrl = nextFiveteenByleague.replace("key", apikey)
            bUrl = ""
            FTMax = 0
            NSMax = 10
    elif selectedTeam != "5111":
        if databaseType == "both":
            aUrl = lastFiveByTeam.replace("key", apikey) + selectedTeam
            bUrl = nextFiveByTeam.replace("key", apikey) + selectedTeam
            FTMax = 5
            NSMax = 5
        elif databaseType == "past":
            aUrl = lastFiveByTeam.replace("key", apikey) + selectedTeam
            bUrl = ""
            FTMax = 5
            NSMax = 0
        elif databaseType == "feature":
            aUrl = nextFiveByTeam.replace("key", apikey) + selectedTeam
            bUrl = ""
            FTMax = 0
            NSMax = 5

    SportDB_URL = [aUrl, bUrl]
    scores = get_scores(SportDB_URL, selectedTeam, databaseType)
    scoreFont = "CG-pixel-3x5-mono"
    textColor = "#fff"
    borderColor = "#000"
    awayColor = "#000"
    homeColor = "#000"
    FTcount = 0
    NScount = 0
    if len(scores) > 0:
        for i, s in enumerate(scores):
            gameStatus = s.get("strStatus")
            if gameStatus == "FT":
                FTcount = FTcount + 1
                if FTcount > FTMax:
                    continue
            elif gameStatus == "NS":
                NScount = NScount + 1
                if NScount > NSMax:
                    continue
            gameTime = s.get("strTimestamp")
            convertedTime = time.parse_time(gameTime.replace(":00+00:00", "Z"), format = "2006-01-02T15:04Z").in_location(timezone)
            if convertedTime.format("1/2") != now.format("1/2"):
                gameTime = convertedTime.format("Jan 2")
            else:
                gameTime = convertedTime.format("3:04 PM")
            if gameStatus != "FT":
                awayScore = ""
                homeScore = ""
            else:
                awayScore = s.get("intAwayScore")
                homeScore = s.get("intHomeScore")
            awayScoreColor = "#fff"
            homeScoreColor = "#fff"
            if homeScore > awayScore:
                homeScoreColor = "#D1D117"
            elif homeScore < awayScore:
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
                                                        render.Box(width = 32, height = 24, child = render.Image(get_cachable_data(get_logo(s.get("idAwayTeam"))), width = 32, height = 32)),
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
                                                        render.Box(width = 32, height = 24, child = render.Image(get_cachable_data(get_logo(s.get("idHomeTeam"))), width = 32, height = 32)),
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
    if len(text) < 8:
        return text
    else:
        return "FINAL"

def get_scores(urls, selectedTeam, databaseType):
    allscores = []
    data = get_cachable_data(urls[0])
    decodedata = json.decode(data)
    if selectedTeam != "5111":
        if databaseType != "feature":
            allscores.extend(decodedata["results"])
        else:
            allscores.extend(decodedata["events"])
    elif selectedTeam == "5111":
        allscores.extend(decodedata["events"])
    if urls[1] != "":
        data = get_cachable_data(urls[1])
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
    return allscores

teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "5111",
    ),
    schema.Option(
        display = "Wei Chuan Dragons",
        value = "144302",
    ),
    schema.Option(
        display = "Rakuten Monkeys",
        value = "144300",
    ),
    schema.Option(
        display = "Uni-President Lions",
        value = "144301",
    ),
    schema.Option(
        display = "CTBC Brothers",
        value = "144298",
    ),
    schema.Option(
        display = "Fubon Guardians",
        value = "144299",
    ),
    schema.Option(
        display = "TSG Hawks",
        value = "147333",
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

databaseTypeOptions = [
    schema.Option(
        display = "Past 5 games & feature 5 games",
        value = "both",
    ),
    schema.Option(
        display = "Past 5 games",
        value = "past",
    ),
    schema.Option(
        display = "Feature 5 games for specify team or 10 League games",
        value = "feature",
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
                default = teamOptions[1].value,
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
                id = "databaseType",
                name = "Game Info",
                desc = "Select past or feature game info you want to show.",
                icon = "calendar",
                default = "past",
                options = databaseTypeOptions,
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
                default = "#ffff00",
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
                desc = "Enter your theSportDB API key",
                icon = "key",
            ),
        ],
    )

def get_cachable_data(url):
    key = base64.encode(url)
    data = cache.get(key)
    if data != None:
        return base64.decode(data)
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    return res.body()

def get_logo(team):
    usealtlogo = json.decode(TEAM_LOGO)
    logo = usealtlogo.get(team, "NO")
    return logo

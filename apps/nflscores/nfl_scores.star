"""
Applet: NFL Scores
Summary: Displays NFL scores
Description: Displays live and upcoming NFL scores from a data feed.
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
SPORT = "football"
LEAGUE = "nfl"
USE_ALT_COLOR = """
{
    "LAC": "#1281c4"
}
"""
USE_ALT_LOGO = """
{
}
"""

def main(config):
    leagues = {
        LEAGUE: "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/scoreboard",
    }
    scores = get_scores(leagues)
    renderCategory = []
    mainspeed = 15 / len(scores)
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    now_date = now.format("2 JAN 2006")
    day = now.format("MONDAY")
    display_type = config.get("display_type", "colors")
    logo_type = config.get("logo_type", "primary")

    for i, s in enumerate(scores):
        oddscheck = s["competitions"][0].get("odds", "NO")
        if oddscheck == "NO":
            showodds = "no"
        else:
            showodds = "yes"

        game = s["name"]
        gamestatus = s["status"]["type"]["state"]

        home = s["competitions"][0]["competitors"][0]["team"]["abbreviation"]
        homeTeamName = s["competitions"][0]["competitors"][0]["team"]["shortDisplayName"]
        homeid = s["competitions"][0]["competitors"][0]["team"]["id"]
        homeColor = get_background_color(home, display_type, s["competitions"][0]["competitors"][0]["team"]["color"], s["competitions"][0]["competitors"][0]["team"]["alternateColor"])
        homeLogo_url = s["competitions"][0]["competitors"][0]["team"]["logo"]
        homelogo = get_logo_type(home, homeLogo_url)
        homescore = ""
        homescorefont = "Dina_r400-6"
        homepossesionbox = ""

        away = s["competitions"][0]["competitors"][1]["team"]["abbreviation"]
        awayTeamName = s["competitions"][0]["competitors"][1]["team"]["shortDisplayName"]
        awayid = s["competitions"][0]["competitors"][1]["team"]["id"]
        awayColor = get_background_color(away, display_type, s["competitions"][0]["competitors"][1]["team"]["color"], s["competitions"][0]["competitors"][1]["team"]["alternateColor"])
        awayLogo_url = s["competitions"][0]["competitors"][1]["team"]["logo"]
        awaylogo = get_logo_type(away, awayLogo_url)
        awayscore = ""
        awayscorefont = "Dina_r400-6"
        awaypossesionbox = ""

        if gamestatus == "pre":
            gamedatetime = s["status"]["type"]["shortDetail"]
            theodds = ""
            theou = ""
            homeodds = ""
            awayodds = ""
            gametimearray = ""

            if showodds == "yes" and config.bool("show_odds"):
                theodds = s["competitions"][0]["odds"][0]["details"]
                oucheck = s["competitions"][0]["odds"][0].get("overUnder", "NO")
                if oucheck == "NO":
                    theou = ""
                else:
                    theou = s["competitions"][0]["odds"][0]["overUnder"]
                homescorefont = "CG-pixel-3x5-mono"
                awayscorefont = "CG-pixel-3x5-mono"
                homeodds = get_odds(theodds, str(theou), home)
                awayodds = get_odds(theodds, str(theou), away)
                homescore = homeodds
                awayscore = awayodds

            gametime = get_detail(gamedatetime)
            homescorecolor = "#fff"
            awayscorecolor = "#fff"

        if gamestatus == "in":
            gametime = s["status"]["type"]["shortDetail"]
            homescore = s["competitions"][0]["competitors"][0]["score"]
            homescorecolor = "#fff"
            awayscore = s["competitions"][0]["competitors"][1]["score"]
            awayscorecolor = "#fff"

        if gamestatus == "post":
            gametime = s["status"]["type"]["shortDetail"]
            homescore = s["competitions"][0]["competitors"][0]["score"]
            awayscore = s["competitions"][0]["competitors"][1]["score"]
            if (int(homescore) > int(awayscore)):
                homescorecolor = "#ff0"
                awayscorecolor = "#fff"
            elif (int(awayscore) > int(homescore)):
                homescorecolor = "#fff"
                awayscorecolor = "#ff0"
            else:
                homescorecolor = "#fff"
                awayscorecolor = "#fff"

        if display_type == "retro":
            retroTextColor = "#ffe065"

            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = [
                                    render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Box(width = 44, height = 12, child = render.Text(content = awayTeamName[:9].upper(), color = retroTextColor, font = "CG-pixel-3x5-mono")),
                                        render.Box(width = 20, height = 12, child = render.Text(content = awayscore, color = retroTextColor, font = "CG-pixel-3x5-mono")),
                                    ])),
                                    render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Box(width = 44, height = 12, child = render.Text(content = homeTeamName[:9].upper(), color = retroTextColor, font = "CG-pixel-3x5-mono")),
                                        render.Box(width = 20, height = 12, child = render.Text(content = homescore, color = retroTextColor, font = "CG-pixel-3x5-mono")),
                                    ])),
                                ],
                            ),
                            render.Stack(
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Box(width = 64, height = 7, color = "#000", child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = [render.Text(content = gametime, color = retroTextColor, font = "CG-pixel-3x5-mono")])),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        elif display_type == "stadium":
            stadiumTextColor = "#fff"
            stadiumBackgroundColor = "#345252"
            stadiumBorderColor = "#0f3027"

            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = [
                                    render.Box(width = 64, height = 12, color = stadiumBorderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Box(width = 1, height = 10, color = stadiumBorderColor),
                                        render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = stadiumBackgroundColor, child = render.Text(content = away[:3].upper(), color = awayscorecolor, font = "tb-8"))),
                                        render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = stadiumBackgroundColor, child = render.Text(content = awayscore, color = awayscorecolor, font = "tb-8"))),
                                        render.Box(width = 1, height = 10, color = stadiumBorderColor),
                                    ])),
                                    render.Box(width = 64, height = 1, color = stadiumBorderColor),
                                    render.Box(width = 64, height = 10, color = stadiumBorderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Box(width = 1, height = 10, color = stadiumBorderColor),
                                        render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = stadiumBackgroundColor, child = render.Text(content = home[:3].upper(), color = homescorecolor, font = "tb-8"))),
                                        render.Box(width = 31, height = 10, child = render.Box(width = 29, height = 10, color = stadiumBackgroundColor, child = render.Text(content = homescore, color = homescorecolor, font = "tb-8"))),
                                        render.Box(width = 1, height = 10, color = stadiumBorderColor),
                                    ])),
                                ],
                            ),
                            render.Box(width = 64, height = 1, color = stadiumBorderColor),
                            render.Column(
                                children = [
                                    render.Box(width = 64, height = 9, color = stadiumBorderColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Box(width = 1, height = 9, color = stadiumBorderColor),
                                        render.Box(width = 62, height = 9, child = render.Box(width = 60, height = 7, color = stadiumBackgroundColor, child = render.Text(content = gametime, color = stadiumTextColor, font = "CG-pixel-3x5-mono"))),
                                        render.Box(width = 1, height = 9, color = stadiumBorderColor),
                                    ])),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        elif display_type == "horizontal":
            if config.bool("show_time"):
                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "space_between",
                                            cross_align = "start",
                                            children = [
                                                render.Box(width = 32, height = 8, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 1, height = 8),
                                                    render.Text(content = now.format("3:04"), font = "tb-8"),
                                                ])),
                                                render.Box(width = 32, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                                                    render.Text(content = now.format("Jan").upper() + now.format(" 2"), font = "tb-8"),
                                                ])),
                                            ],
                                        ),
                                        render.Row(
                                            children = [
                                                render.Stack(children = [
                                                    render.Box(width = 32, height = 25, color = awayColor),
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Image(awaylogo, width = 13, height = 13),
                                                        #render.Box(width=32, height=12, child = render.Text(content=away[:3], color=awayscorecolor, font="Dina_r400-6")),
                                                        render.Box(width = 32, height = 12, child = render.Text(content = awayscore, color = awayscorecolor, font = awayscorefont)),
                                                    ]),
                                                ]),
                                                render.Stack(children = [
                                                    render.Box(width = 32, height = 25, color = homeColor),
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Image(homelogo, width = 13, height = 13),
                                                        #render.Box(width=32, height=12, child = render.Text(content=home[:3], color=homescorecolor, font="Dina_r400-6")),
                                                        render.Box(width = 32, height = 12, child = render.Text(content = homescore, color = homescorecolor, font = homescorefont)),
                                                    ]),
                                                ]),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            else:
                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    children = [
                                        render.Box(width = 32, height = 25, color = awayColor, child = render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Image(awaylogo, width = 15, height = 15),
                                            render.Box(width = 20, height = 10, child = render.Text(content = awayscore, color = awayscorecolor, font = awayscorefont)),
                                        ])),
                                        render.Box(width = 32, height = 25, color = homeColor, child = render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Image(homelogo, width = 15, height = 15),
                                            render.Box(width = 32, height = 10, child = render.Text(content = homescore, color = homescorecolor, font = homescorefont)),
                                        ])),
                                    ],
                                ),
                                render.Stack(
                                    children = [
                                        render.Stack(
                                            children = [
                                                render.Box(width = 64, height = 7, color = "#000", child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = [render.Text(content = gametime, font = "CG-pixel-3x5-mono")])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

        elif config.bool("show_time"):
            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "start",
                                        children = [
                                            render.Box(width = 32, height = 8, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Box(width = 1, height = 8),
                                                render.Text(content = now.format("3:04"), font = "tb-8"),
                                            ])),
                                            render.Box(width = 32, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                                                render.Text(content = now.format("Jan").upper() + now.format(" 2"), font = "tb-8"),
                                            ])),
                                        ],
                                    ),
                                    render.Column(
                                        children = [
                                            render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Image(awaylogo, width = 16, height = 16),
                                                render.Box(width = 26, height = 12, child = render.Text(content = away[:3], color = awayscorecolor, font = "Dina_r400-6")),
                                                render.Box(width = 22, height = 12, child = render.Text(content = awayscore, color = awayscorecolor, font = awayscorefont)),
                                            ])),
                                            render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                render.Image(homelogo, width = 16, height = 16),
                                                render.Box(width = 26, height = 12, child = render.Text(content = home[:3], color = homescorecolor, font = "Dina_r400-6")),
                                                render.Box(width = 22, height = 12, child = render.Text(content = homescore, color = homescorecolor, font = homescorefont)),
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
            renderCategory.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = [
                                    render.Box(width = 64, height = 12, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Image(awaylogo, width = 16, height = 16),
                                        render.Box(width = 26, height = 12, child = render.Text(content = away[:3], color = awayscorecolor, font = "Dina_r400-6")),
                                        render.Box(width = 22, height = 12, child = render.Text(content = awayscore, color = awayscorecolor, font = awayscorefont)),
                                    ])),
                                    render.Box(width = 64, height = 12, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                        render.Image(homelogo, width = 16, height = 16),
                                        render.Box(width = 26, height = 12, child = render.Text(content = home[:3], color = homescorecolor, font = "Dina_r400-6")),
                                        render.Box(width = 22, height = 12, child = render.Text(content = homescore, color = homescorecolor, font = homescorefont)),
                                    ])),
                                ],
                            ),
                            render.Stack(
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Box(width = 64, height = 7, color = "#000", child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = [render.Text(content = gametime, font = "CG-pixel-3x5-mono")])),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            )

    return render.Root(
        delay = int(mainspeed * 1000),
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
                id = "display_type",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "numbers",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
            schema.Toggle(
                id = "show_time",
                name = "Current Date/Time",
                desc = "A toggle to display the current date/time (not available in Retro).",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_odds",
                name = "Gambling Odds",
                desc = "A toggle to display gambling odds for games that haven't started.",
                icon = "dice",
                default = True,
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

def get_odds(theodds, theou, team):
    theoddsarray = theodds.split(" ")
    if theoddsarray[0] == team or theodds == "EVEN":
        if theodds == "EVEN":
            theoddsscore = ""
        else:
            theoddsscore = theoddsarray[1]
    else:
        theoddsscore = theou
    return theoddsscore

def get_detail(gamedate):
    finddash = gamedate.find("-")
    if finddash > 0:
        gametimearray = gamedate.split(" - ")
        gametimeval = gametimearray[1]
    else:
        gametimeval = gamedate
    return gametimeval

def get_background_color(team, displayType, color, altColor):
    altcolors = json.decode(USE_ALT_COLOR)
    usealt = altcolors.get(team, "NO")
    if displayType == "black" or displayType == "retro":
        color = "#111"
    elif usealt != "NO":
        color = altcolors[team]
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#111"
    return color

def get_logo_type(team, logo):
    usealtlogo = json.decode(USE_ALT_LOGO)
    usealt = usealtlogo.get(team, "NO")
    if usealt != "NO":
        logo = get_cachable_data(usealt, 36000)
    else:
        logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
        logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
        logo = get_cachable_data(logo + "&h=36&w=36")
    return logo

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

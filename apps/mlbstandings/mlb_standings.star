"""
Applet: MLB Standings
Summary: Displays MLB standings
Description: Displays live and upcoming MLB standings from a data feed.
Author: LunchBox8484
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 300
LOGO_CACHE_TTL_SECONDS = 36000
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
LEAGUE_DISPLAY = "MLB"
LEAGUE_DISPLAY_OFFSET = -3
SPORT = "baseball"
LEAGUE = "mlb"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
COLOR_DICT = {
    "ARI": "aa182c",
    "ATL": "0c2340",
    "BAL": "df4601",
    "BOS": "0d2b56",
    "CHC": "0e3386",
    "CHW": "000000",
    "CIN": "c6011f",
    "CLE": "002b5c",
    "COL": "33006f",
    "DET": "002d5c",
    "HOU": "002d62",
    "KC": "004687",
    "LAA": "ba0021",
    "LAD": "005a9c",
    "MIA": "00a3e0",
    "MIL": "13294b",
    "MIN": "031f40",
    "NYM": "002d72",
    "NYY": "132448",
    "ATH": "006241",
    "PHI": "e81828",
    "PIT": "111111",
    "SD": "3e2312",
    "SF": "222222",
    "SEA": "005c5c",
    "STL": "be0a14",
    "TB": "092c5c",
    "TEX": "003278",
    "TOR": "134a8e",
    "WSH": "ab0003",
}
ALT_LOGO = {
    "PHI": "https://b.fssta.com/uploads/application/mlb/team-logos/Phillies-alternate.png",
    "DET": "https://b.fssta.com/uploads/application/mlb/team-logos/Tigers-alternate.png",
    "CIN": "https://b.fssta.com/uploads/application/mlb/team-logos/Reds-alternate.png",
    "CLE": "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cle.png",
    "STL": "https://b.fssta.com/uploads/application/mlb/team-logos/Cardinals-alternate.png",
    "MIL": "https://b.fssta.com/uploads/application/mlb/team-logos/Brewers.png",
}

MAIN_FONT = "CG-pixel-3x5-mono"

def main(config):
    renderCategory = []
    rotationSpeed = config.get("rotationSpeed", "5")
    divisionType = config.get("divisionType", "al")
    teamsToShow = int(config.get("teamsOptions", "3"))
    displayTop = config.get("displayTop", "league")
    timeColor = config.get("displayTimeColor", "#FFA500")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    if divisionType == "al":
        league = {"aleast": API + "?group=1", "alcentral": API + "?group=2", "alwest": API + "?group=3"}
    elif divisionType == "nl":
        league = {"nleast": API + "?group=4", "nlcentral": API + "?group=5", "nlwest": API + "?group=6"}
    elif divisionType == "0":
        apiURL = API
        league = {LEAGUE: apiURL}
    else:
        apiURL = API + "?group=" + divisionType
        league = {LEAGUE: apiURL}

    standings = get_standings(league)

    if (standings):
        for i, s in enumerate(standings):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                divisionName = s["shortName"]
                divisionName = divisionName.replace(" Cent", " Central")

                # ESPN API does not guarantee order
                # we sort by games behind to get the standings correct
                entries = sorted(entries, get_games_behind)

                for x in range(0, len(entries), entriesToDisplay):
                    renderCategory.extend(
                        [
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = get_team(x, entries, entriesToDisplay, i, now, rotationSpeed, timeColor, divisionName, displayTop),
                                    ),
                                ],
                            ),
                        ],
                    )

        return render.Root(
            delay = int(rotationSpeed) * 1000,
            show_full_animation = True,
            child = render.Animation(children = renderCategory),
        )
    else:
        return []

def get_games_behind(entry):
    for stat in entry.get("stats"):
        if stat.get("name") == "gamesBehind":
            return stat.get("value")
    return 0  # will never get here, but need a return value

divisionOptions = [
    schema.Option(
        display = "AL",
        value = "al",
    ),
    schema.Option(
        display = "AL East",
        value = "1",
    ),
    schema.Option(
        display = "AL Central",
        value = "2",
    ),
    schema.Option(
        display = "AL West",
        value = "3",
    ),
    schema.Option(
        display = "NL",
        value = "nl",
    ),
    schema.Option(
        display = "NL East",
        value = "4",
    ),
    schema.Option(
        display = "NL Central",
        value = "5",
    ),
    schema.Option(
        display = "NL West",
        value = "6",
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

teamsOptions = [
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
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
        display = "League Name Only",
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
                id = "divisionType",
                name = "Division",
                desc = "Which division to display.",
                icon = "gear",
                default = divisionOptions[0].value,
                options = divisionOptions,
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
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
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

def get_standings(urls):
    allstandings = []
    for _, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allstandings.append(decodedata)
    return allstandings

def get_team(x, s, entriesToDisplay, i, now, rotationSpeed, timeColor, divisionName, displayTop):
    output = []
    if displayTop == "gameinfo":
        topColumn = [
            render.Box(width = 64, height = 8, child = render.Stack(children = [
                render.Box(width = 64, height = 8, color = "#000"),
                render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                    render.Text(color = timeColor, content = divisionName, font = MAIN_FONT),
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
            now = now + time.parse_duration("%ds" % int(i) * int(rotationSpeed))
            theTime = now.format("3:04")
            if len(str(theTime)) > 4:
                timeBox += 4
                statusBox -= 4
        topColumn = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    render.Box(width = timeBox, height = 8, color = "#000", child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                        render.Box(width = 1, height = 8),
                        render.Text(color = timeColor, content = theTime, font = "tb-8"),
                    ])),
                    render.Box(width = statusBox, height = 8, color = "#000", child = render.Stack(children = [
                        render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                            render.Text(color = "#FFF", content = divisionName, font = MAIN_FONT),
                        ])),
                    ])),
                ],
            ),
        ]

    output.extend(topColumn)
    containerHeight = int(24 / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            # initialize stat variables
            team_games_back = ""
            team_record = ""

            # get team info
            teamName = s[i + x]["team"]["abbreviation"]
            teamColor = COLOR_DICT.get(teamName)
            teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][1]["href"])
            stats = s[i + x]["stats"]
            for stat in stats:
                if stat.get("name") == "overall":
                    team_record = stat.get("displayValue")
                if stat.get("name") == "gamesBehind":
                    team_games_back = stat.get("displayValue")

                # if we have populated everything then break to stop going through stats
                if team_record != "" and team_games_back != "":
                    break

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = 8, height = containerHeight, child = render.Image(teamLogo, width = 10, height = 10)),
                        render.Box(width = 14, height = containerHeight, child = render.Text(content = teamName[:3], color = "#fff", font = MAIN_FONT)),
                        render.Box(width = 26, height = containerHeight, child = render.Text(content = team_record, color = "#fff", font = MAIN_FONT)),
                        render.Box(width = 16, height = containerHeight, child = render.Text(content = team_games_back, color = "#fff", font = MAIN_FONT)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output

def get_logoType(team, logo):
    usealt = ALT_LOGO.get(team)
    if usealt != None:
        logo = get_cachable_data(usealt, LOGO_CACHE_TTL_SECONDS)
    else:
        logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
        logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
        logo = get_cachable_data(logo + "&h=50&w=50", LOGO_CACHE_TTL_SECONDS)
    return logo

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    return res.body()

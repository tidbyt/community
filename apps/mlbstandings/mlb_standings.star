"""
Applet: MLB Standings
Summary: Displays MLB standings
Description: Displays live and upcoming MLB standings from a data feed.
Author: LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 300
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
ALT_COLOR = """
{
    "HOU": "#002D62",
    "WSH": "#AB0003",
    "PIT": "#111111"
}
"""
ALT_LOGO = """
{
    "PHI": "https://b.fssta.com/uploads/application/mlb/team-logos/Phillies-alternate.png",
    "DET": "https://b.fssta.com/uploads/application/mlb/team-logos/Tigers-alternate.png",
    "CIN": "https://b.fssta.com/uploads/application/mlb/team-logos/Reds-alternate.png",
    "CLE": "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/cle.png",
    "STL": "https://b.fssta.com/uploads/application/mlb/team-logos/Cardinals-alternate.png",
    "MIL": "https://b.fssta.com/uploads/application/mlb/team-logos/Brewers.png"
}
"""

def main(config):
    renderCategory = []
    divisionType = config.get("divisionType", "0")
    teamsToShow = int(config.get("teamsOptions", "3"))
    displayTop = config.get("displayTop", "time")
    timeColor = config.get("displayTimeColor", "#FFF")
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
    cycleOptions = int(config.get("cycleOptions", 1))

    if (standings):
        cycleCount = 0
        for _, s in enumerate(standings):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                divisionName = s["shortName"]
                divisionName = divisionName.replace(" Cent", " Central")
                stats = entries[0]["stats"]

                statNumber = 0
                for j, k in enumerate(stats):
                    if k["name"] == "gamesBehind":
                        statNumber = j
                entries = sorted(entries, key = lambda e: e["stats"][statNumber]["value"])

                for x in range(0, len(entries), entriesToDisplay):
                    cycleCount = cycleCount + 1
                    renderCategory.extend(
                        [
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = get_team(x, entries, entriesToDisplay, now, timeColor, divisionName, displayTop),
                                    ),
                                ],
                            ),
                        ],
                    )

        return render.Root(
            delay = int(15000 / cycleOptions / cycleCount),
            child = render.Animation(children = renderCategory),
        )
    else:
        return []

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

cycleOptions = [
    schema.Option(
        display = "Once",
        value = "1",
    ),
    schema.Option(
        display = "Twice",
        value = "2",
    ),
    schema.Option(
        display = "Three",
        value = "3",
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
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "cycleOptions",
                name = "Cycle Times",
                desc = "How many times should it cycle through?",
                icon = "gear",
                default = cycleOptions[1].value,
                options = cycleOptions,
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

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    teamcolor = get_background_color(team["abbreviation"], team["color"])
    return teamcolor

def get_team(x, s, entriesToDisplay, now, timeColor, divisionName, displayTop):
    output = []

    teamGB = ""
    teamLosses = ""
    teamWins = ""

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
                render.Box(width = statusBox, height = 8, color = "#111", child = render.Stack(children = [
                    render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                        render.Text(color = "#FFF", content = divisionName, font = "CG-pixel-3x5-mono"),
                    ])),
                ])),
            ],
        ),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont = "CG-pixel-3x5-mono"
            teamID = s[i + x]["team"]["id"]
            teamName = s[i + x]["team"]["abbreviation"]
            teamColor = get_team_color(teamID)
            teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][1]["href"])
            stats = s[i + x]["stats"]
            for _, k in enumerate(stats):
                if k["name"] == "wins":
                    teamWins = k["displayValue"]
                if k["name"] == "losses":
                    teamLosses = k["displayValue"]
                if k["name"] == "gamesBehind":
                    teamGB = k["displayValue"]
            teamRecord = teamWins + "-" + teamLosses

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = 8, height = containerHeight, child = render.Image(teamLogo, width = 10, height = 10)),
                        render.Box(width = 14, height = containerHeight, child = render.Text(content = teamName[:3], color = "#fff", font = mainFont)),
                        render.Box(width = 26, height = containerHeight, child = render.Text(content = teamRecord, color = "#fff", font = mainFont)),
                        render.Box(width = 16, height = containerHeight, child = render.Text(content = teamGB, color = "#fff", font = mainFont)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output

def get_background_color(team, color):
    altcolors = json.decode(ALT_COLOR)
    usealt = altcolors.get(team, "NO")
    if usealt != "NO":
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

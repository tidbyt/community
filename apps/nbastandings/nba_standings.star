"""
Applet: NBA Standings
Summary: Displays NBA standings
Description: Displays live and upcoming NBA standings from a data feed.
Author: LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("math.star", "math")

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
SPORT = "basketball"
LEAGUE = "nba"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
ALT_COLOR = """
{
    "OKC": "#007AC1",
    "DEN": "#0E2240",
    "PHI": "#006BB6"
}
"""
ALT_LOGO = """
{
    "HOU": "https://b.fssta.com/uploads/application/nba/team-logos/Rockets-alternate.png",
    "PHI": "https://b.fssta.com/uploads/application/nba/team-logos/76ers.png"
}
"""
MAGNIFY_LOGO = """
{
    "BOS": 18,
    "BKN": 18,
    "CHA": 18,
    "CLE": 22,
    "DEN": 14,
    "HOU": 20,
    "LAL": 18,
    "MIL": 20,
    "NO": 26,
    "NY": 20,
    "OKC": 26,
    "ORL": 18,
    "PHX": 18,
    "PHI": 14,
    "SA": 18,
    "TOR": 14,
    "WSH": 14
}
"""

def main(config):
    renderCategory = []
    divisionType = config.get("divisionType", "0")
    teamsToShow = int(config.get("teamsOptions", "3"))
    showDateTime = config.bool("displayDateTime")
    timeColor = config.get("displayTimeColor", "#FFF")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    apiURL = API + "?group=" + divisionType
    league = {LEAGUE: apiURL}

    standings = get_standings(league)
    mainFont = "CG-pixel-3x5-mono"
    renderFinal = []
    cycleOptions = int(config.get("cycleOptions", 1))
    overallCycleCount = 0

    if (standings):
        cycleCount = 0
        for i, s in enumerate(standings[0]["children"]):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                divisionName = s["name"].replace(" Division", "").replace(" Conference", "")
                stats = entries[0]["stats"]

                for j, k in enumerate(stats):
                    if k["name"] == "gamesBehind":
                        statNumber = j
                    if k["name"] == "winPercent":
                        statNumber2 = j

                entries = sorted(entries, key = lambda e: (e["stats"][statNumber]["value"], float(e["stats"][statNumber2]["value"])), reverse = False)

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
                                        children = get_team(x, entries, entriesToDisplay, showDateTime and 24 or 28, now, timeColor, divisionName, showDateTime, showDateTime and 8 or 5),
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
        display = "Eastern Conference",
        value = "5",
    ),
    schema.Option(
        display = "Western Conference",
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
                default = cycleOptions[0].value,
                options = cycleOptions,
            ),
            schema.Toggle(
                id = "displayDateTime",
                name = "Current Time",
                desc = "A toggle to display the Current Time rather than game time/status.",
                icon = "calendar",
                default = False,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "gear",
                default = colorOptions[0].value,
                options = colorOptions,
            ),
        ],
    )

def get_standings(urls):
    allstandings = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allstandings.append(decodedata)
    return allstandings

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    teamcolor = get_background_color(team["abbreviation"], "color", team["color"], team["alternateColor"])
    return teamcolor

def get_team(x, s, entriesToDisplay, colHeight, now, timeColor, divisionName, showDateTime, topcolHeight):
    output = []
    if showDateTime:
        theTime = now.format("3:04")
        if len(str(theTime)) > 4:
            timeBox = 24
            statusBox = 40
        else:
            timeBox = 20
            statusBox = 44
        topColumn = [
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [
                    render.Box(width = timeBox, height = topcolHeight, color = "#000", child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                        render.Box(width = 1, height = topcolHeight),
                        render.Text(color = timeColor, content = theTime, font = "tb-8"),
                    ])),
                    render.Box(width = statusBox, height = topcolHeight, color = "#111", child = render.Stack(children = [
                        render.Box(width = statusBox, height = topcolHeight, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                            render.Text(color = "#FFF", content = divisionName.replace("Metropolitan", "Metro"), font = "CG-pixel-3x5-mono"),
                        ])),
                    ])),
                ],
            ),
        ]
    else:
        topColumn = [render.Box(width = 64, height = topcolHeight, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
            render.Box(width = 64, height = topcolHeight, child = render.Text(content = divisionName, color = "#ff0", font = "CG-pixel-3x5-mono")),
        ]))]

    output.extend(topColumn)
    containerHeight = int(colHeight / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont = "CG-pixel-3x5-mono"
            teamID = s[i + x]["team"]["id"]
            teamName = s[i + x]["team"]["abbreviation"]
            teamColor = get_team_color(teamID)
            teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][1]["href"])
            stats = s[i + x]["stats"]
            for j, k in enumerate(stats):
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

def get_background_color(team, displayType, color, altColor):
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

    cache.set(key, base64.encode(res.body()), ttl_seconds = CACHE_TTL_SECONDS)

    return res.body()

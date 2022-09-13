"""
Applet: NFL Standings
Summary: Displays NFL standings
Description: Displays live and upcoming NFL standings from a data feed.
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
SPORT = "football"
LEAGUE = "nfl"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
ALT_COLOR = """
{
    "LAC": "#1281c4",
    "LAR": "#003594",
    "NO": "#000000",
    "SEA": "#002244",
    "TB": "#34302B",
    "TEN": "#0C2340"
}
"""
ALT_LOGO = """
{
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
    if divisionType == "afc":
        league = {"afceast": API + "?group=4", "afcnorth": API + "?group=12", "afcsouth": API + "?group=13", "afcwest": API + "?group=6"}
    elif divisionType == "nfc":
        league = {"nfceast": API + "?group=1", "nfcnorth": API + "?group=10", "nfcsouth": API + "?group=11", "nfcwest": API + "?group=3"}
    elif divisionType == "0":
        apiURL = API
        league = {LEAGUE: apiURL}
    else:
        apiURL = API + "?group=" + divisionType
        league = {LEAGUE: apiURL}

    standings = get_standings(league)
    mainFont = "CG-pixel-3x5-mono"
    renderFinal = []
    cycleOptions = int(config.get("cycleOptions", 1))
    overallCycleCount = 0

    if (standings):
        cycleCount = 0
        for i, s in enumerate(standings):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                divisionName = s["name"]

                entries = sorted(entries, key = lambda e: e["stats"][4]["value"])

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
        display = "AFC",
        value = "afc",
    ),
    schema.Option(
        display = "AFC East",
        value = "4",
    ),
    schema.Option(
        display = "AFC North",
        value = "12",
    ),
    schema.Option(
        display = "AFC South",
        value = "13",
    ),
    schema.Option(
        display = "AFC West",
        value = "6",
    ),
    schema.Option(
        display = "NFC",
        value = "nfc",
    ),
    schema.Option(
        display = "NFC East",
        value = "1",
    ),
    schema.Option(
        display = "NFC North",
        value = "10",
    ),
    schema.Option(
        display = "NFC South",
        value = "11",
    ),
    schema.Option(
        display = "NFC West",
        value = "3",
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
        display = "4",
        value = "4",
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
                            render.Text(color = "#FFF", content = divisionName, font = "CG-pixel-3x5-mono"),
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
            teamWins = s[i + x]["stats"][1]["displayValue"]
            teamLosses = s[i + x]["stats"][2]["displayValue"]
            teamTies = s[i + x]["stats"][5]["displayValue"]
            teamRecord = teamWins + "-" + teamLosses
            if int(teamTies) > 0:
                teamRecord = teamRecord + "-" + teamTies
            teamGB = s[i + x]["stats"][4]["displayValue"]

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

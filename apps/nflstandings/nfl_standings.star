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
LEAGUE_DISPLAY = "NFL"
LEAGUE_DISPLAY_OFFSET = -4
SPORT = "football"
LEAGUE = "nfl"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
ALT_COLOR = """
{
    "LAC": "#1281c4",
    "LAR": "#003594",
    "MIA": "#008E97",
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
    rotationSpeed = config.get("rotationSpeed", "5")
    divisionType = config.get("divisionType", "afc")
    teamsToShow = int(config.get("teamsOptions", "4"))
    displayTop = config.get("displayTop", "league")
    timeColor = config.get("displayTimeColor", "#FFA500")
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

    if (standings):
        for i, s in enumerate(standings):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                divisionName = s["name"]
                sortOrder = {}

                for j, _ in enumerate(entries):
                    stats = entries[j]["stats"]
                    for l, m in enumerate(stats):
                        if m["name"] == "gamesBehind":
                            sortOrder[entries[j]["team"]["id"]] = stats[l]["value"]
                sortOrder = {k: v for k, v in sorted(sortOrder.items(), key = lambda item: item[1])}
                keysList = list(sortOrder.keys())
                entries = sorted(entries, key = lambda e: keysList.index(e["team"]["id"]))

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
        display = "4",
        value = "4",
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

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    teamcolor = get_background_color(team["abbreviation"], team["color"])
    return teamcolor

def get_team(x, s, entriesToDisplay, i, now, rotationSpeed, timeColor, divisionName, displayTop):
    output = []
    teamTies = ""
    teamWins = ""
    teamLosses = ""
    teamGB = ""

    if displayTop == "gameinfo":
        topColumn = [
            render.Box(width = 64, height = 8, child = render.Stack(children = [
                render.Box(width = 64, height = 8, color = "#000"),
                render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                    render.Text(color = timeColor, content = divisionName, font = "CG-pixel-3x5-mono"),
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
                if k["name"] == "ties":
                    teamTies = k["displayValue"]
                if k["name"] == "gamesBehind":
                    teamGB = k["displayValue"]
            if int(teamTies) > 0:
                teamRecord = teamWins + "-" + teamLosses + "-" + teamTies
            else:
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

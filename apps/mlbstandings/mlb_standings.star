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
load("math.star", "math")

CACHE_TTL_SECONDS = 300
SPORT = "baseball"
LEAGUE = "mlb"
API = "https://site.api.espn.com/apis/v2/sports/" + SPORT + "/" + LEAGUE + "/standings"
ALT_COLOR = """
{
    "HOU": "#002D62",
    "WSH": "#AB0003",
    "PIT": "#000000"
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
    if divisionType == "0":
        apiURL = API
    else:
        apiURL = API + "?group=" + divisionType
    league = {LEAGUE: apiURL}
    standings = get_standings(league)
    entries = standings["standings"]["entries"]
    mainFont = "CG-pixel-3x5-mono"
    if entries:
        divisionName = standings["shortName"]
        divisionName = divisionName.replace(" ", "")
        cycleOptions = int(config.get("cycleOptions", 1))
        cycleCount = 0
        entriesToDisplay = teamsToShow

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
                                children = get_team(x, entries, entriesToDisplay),
                            ),
                        ],
                    ),
                ],
            )

        return render.Root(
            delay = int(15000 / cycleOptions / cycleCount),
            child = render.Column(
                children = [
                    render.Box(width = 64, height = 6, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = 24, height = 6, child = render.Text(content = divisionName, color = "#ff0", font = mainFont)),
                        render.Box(width = 22, height = 6, child = render.Text(content = "W-L", color = "#ff0", font = mainFont)),
                        render.Box(width = 20, height = 6, child = render.Text(content = "GB", color = "#ff0", font = mainFont)),
                    ])),
                    render.Animation(
                        children = renderCategory,
                    ),
                ],
            ),
        )
    else:
        return []

divisionOptions = [
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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "divisionType",
                name = "Division",
                desc = "Which division to display.",
                icon = "cog",
                default = divisionOptions[0].value,
                options = divisionOptions,
            ),
            schema.Dropdown(
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once.",
                icon = "cog",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "cycleOptions",
                name = "Cycle Times",
                desc = "How many times should it cycle through?",
                icon = "cog",
                default = cycleOptions[1].value,
                options = cycleOptions,
            ),
        ],
    )

def get_standings(urls):
    allstandings = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
    return decodedata

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid)
    decodedata = json.decode(data)
    team = decodedata["team"]
    teamcolor = get_background_color(team["abbreviation"], "color", team["color"], team["alternateColor"])
    return teamcolor

def get_team(x, s, entriesToDisplay):
    output = []
    containerHeight = int(27 / entriesToDisplay)
    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont = "CG-pixel-3x5-mono"
            teamID = s[i + x]["team"]["id"]
            teamName = s[i + x]["team"]["abbreviation"]
            teamColor = get_team_color(teamID)
            teamLogo = get_logoType(teamName, s[i + x]["team"]["logos"][1]["href"])
            teamWins = s[i + x]["stats"][1]["displayValue"]
            teamLosses = s[i + x]["stats"][2]["displayValue"]
            teamRecord = teamWins + "-" + teamLosses
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
    if displayType == "black" or displayType == "retro":
        color = "#222"
    elif usealt != "NO":
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

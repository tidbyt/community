"""
Applet: Soccer Tables
Summary: Displays standings from various top leagues around Europe and the world.
Description: Displays league tables from soccer leagues, showing team abbreviation, record in W-D-L format and points total. Choose your league and choose if you want to display the team color or just white text on black
Author: MontyP, with huge thanks and shoutout to LunchBox8484 as this is largely inspired/borrowed from their NHL Standings app

v1.1
Added rotation speed option

v1.2
Added MLS to selection of leagues to choose from
Updated cache function

v1.3
Added NWSL to selection of leagues to choose from

v2
Added ability to show rank, pts and goal difference rather than W-D-L record, this is now the default option
Teams in positions for European qualification, league promotion, playoffs or relegation are colored differently to make them stand out
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL_SECONDS = 300

SPORT = "soccer"
LEAGUE = "eng.1"
DEFAULT_LEAGUE = "eng.1"
API = "https://site.api.espn.com/apis/v2/sports/soccer/"

ALT_COLOR = """
{
}
"""

def main(config):
    renderCategory = []
    teamsToShow = 4

    RotationSpeed = config.get("speed", "3")
    selectedLeague = config.get("LeagueOptions", DEFAULT_LEAGUE)
    selectedColor = config.get("ColorOptions", "black")
    selectedDisplay = config.get("DisplayOptions", "Rank")
    league2 = {API: API + selectedLeague + "/standings"}

    standings = get_standings(league2)
    statNumber = 0

    if (standings):
        cycleCount = 0
        for _, s in enumerate(standings[0]["children"]):
            entries = s["standings"]["entries"]

            if entries:
                entriesToDisplay = teamsToShow
                LeagueName = getLeagueName(selectedLeague)
                if selectedLeague == "usa.1":
                    LeagueName = LeagueName + " - " + s["abbreviation"]
                stats = entries[0]["stats"]

                for j, k in enumerate(stats):
                    if k["name"] == "points":
                        statNumber = j

                entries = sorted(entries, key = lambda e: e["stats"][statNumber]["value"], reverse = True)

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
                                        children = get_team(x, entries, entriesToDisplay, 25, LeagueName, 8, selectedColor, selectedDisplay),
                                    ),
                                ],
                            ),
                        ],
                    )
        return render.Root(
            show_full_animation = True,
            delay = int(RotationSpeed) * 1000,
            child = render.Animation(children = renderCategory),
        )
    else:
        return []

LeagueOptions = [
    schema.Option(
        display = "English Premier League",
        value = "eng.1",
    ),
    schema.Option(
        display = "English Championship",
        value = "eng.2",
    ),
    schema.Option(
        display = "English League One",
        value = "eng.3",
    ),
    schema.Option(
        display = "English League Two",
        value = "eng.4",
    ),
    schema.Option(
        display = "Italian Serie A",
        value = "ita.1",
    ),
    schema.Option(
        display = "Spanish LaLiga",
        value = "esp.1",
    ),
    schema.Option(
        display = "German Bundesliga",
        value = "ger.1",
    ),
    schema.Option(
        display = "French Ligue 1",
        value = "fra.1",
    ),
    schema.Option(
        display = "Dutch Eredivisie",
        value = "ned.1",
    ),
    schema.Option(
        display = "Scottish Premiership",
        value = "sco.1",
    ),
    schema.Option(
        display = "Primeira Liga",
        value = "por.1",
    ),
    schema.Option(
        display = "Belgian Pro League",
        value = "bel.1",
    ),
    schema.Option(
        display = "Major League Soccer",
        value = "usa.1",
    ),
    schema.Option(
        display = "Mexican Liga BBVA MX",
        value = "mex.1",
    ),
    schema.Option(
        display = "Australian A-League",
        value = "aus.1",
    ),
    schema.Option(
        display = "National Womens Soccer League",
        value = "usa.nwsl",
    ),
]

ColorOptions = [
    schema.Option(
        display = "Black",
        value = "black",
    ),
    schema.Option(
        display = "Color",
        value = "color",
    ),
]

DisplayOptions = [
    schema.Option(
        display = "W-D-L Record",
        value = "WDL",
    ),
    schema.Option(
        display = "Rank, Pts & Goal Diff",
        value = "Rank",
    ),
]

RotationOptions = [
    schema.Option(
        display = "2 seconds",
        value = "2",
    ),
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
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "DisplayOptions",
                name = "Display",
                desc = "What do you want to see?",
                icon = "gear",
                default = DisplayOptions[0].value,
                options = DisplayOptions,
            ),
            schema.Dropdown(
                id = "LeagueOptions",
                name = "League",
                desc = "Which league do you want to display?",
                icon = "gear",
                default = LeagueOptions[0].value,
                options = LeagueOptions,
            ),
            schema.Dropdown(
                id = "ColorOptions",
                name = "Display",
                desc = "Color or Black?",
                icon = "gear",
                default = ColorOptions[0].value,
                options = ColorOptions,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each page is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
        ],
    )

def get_standings(urls):
    allstandings = []
    for _, s in urls.items():
        data = get_cachable_data(s, CACHE_TTL_SECONDS)
        decodedata = json.decode(data)
        allstandings.append(decodedata)
    return allstandings

def get_team_color(teamid):
    data = get_cachable_data("https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/" + LEAGUE + "/teams/" + teamid, CACHE_TTL_SECONDS)
    decodedata = json.decode(data)
    team = decodedata["team"]
    teamcolor = get_background_color(team["abbreviation"], team["color"])
    return teamcolor

def get_team(x, s, entriesToDisplay, colHeight, LeagueName, topcolHeight, selectedColor, selectedDisplay):
    output = []

    teamRecord = ""
    teamWins = ""
    teamLosses = ""
    teamDraws = ""
    teamPoints = ""
    teamGD = ""

    topColumn = [render.Box(width = 64, height = topcolHeight, color = "#000", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
        render.Box(width = 64, height = topcolHeight, child = render.Text(content = LeagueName, color = "#ff0", font = "CG-pixel-3x5-mono")),
    ]))]

    output.extend(topColumn)

    containerHeight = int(colHeight / entriesToDisplay)

    for i in range(0, entriesToDisplay):
        if i + x < len(s):
            mainFont1 = "CG-pixel-3x5-mono"
            mainFont = "CG-pixel-3x5-mono"
            teamID = s[i + x]["team"]["id"]
            teamName = s[i + x]["team"]["abbreviation"]
            teamColor = "#000"
            teamRank = i + x + 1
            rankColor = "#fff"

            if selectedColor == "color":
                teamColor = get_team_color(teamID)
            elif selectedColor == "black":
                rankColor = getRankColor(teamRank, LeagueName)

            stats = s[i + x]["stats"]
            for _, k in enumerate(stats):
                if k["name"] == "wins":
                    teamWins = k["displayValue"]
                if k["name"] == "losses":
                    teamLosses = k["displayValue"]
                if k["name"] == "ties":
                    teamDraws = k["displayValue"]
                if k["name"] == "points":
                    teamPoints = k["displayValue"]

                #if k["name"] == "gamesPlayed":
                #    teamPlayed = k["displayValue"]
                if k["name"] == "pointDifferential":
                    teamGD = k["displayValue"]

            teamRecord = teamWins + "-" + teamDraws + "-" + teamLosses

            if selectedDisplay == "Rank":
                team = render.Column(
                    children = [
                        render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                            render.Box(width = 10, height = containerHeight, child = render.Text(content = str(teamRank), color = rankColor, font = mainFont1)),
                            render.Box(width = 24, height = containerHeight, child = render.Text(content = teamName[:3], color = rankColor, font = mainFont)),
                            render.Box(width = 16, height = containerHeight, child = render.Text(content = teamPoints, color = rankColor, font = mainFont)),
                            render.Box(width = 14, height = containerHeight, child = render.Text(content = teamGD, color = rankColor, font = mainFont)),
                        ])),
                    ],
                )
                output.extend([team])

            elif selectedDisplay == "WDL":
                team = render.Column(
                    children = [
                        render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                            render.Box(width = 14, height = containerHeight, child = render.Text(content = teamName[:3], color = rankColor, font = mainFont)),
                            render.Box(width = 42, height = containerHeight, child = render.Text(content = teamRecord, color = rankColor, font = mainFont1)),
                            render.Box(width = 8, height = containerHeight, child = render.Text(content = teamPoints, color = rankColor, font = mainFont)),
                        ])),
                    ],
                )
                output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])
    return output

def getRankColor(teamRank, LeagueName):
    if LeagueName == "EPL":
        if teamRank < 5:
            rankColor = "#5ff55f"
        elif teamRank == 5:
            rankColor = "#4093e6"
        elif teamRank > 17:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"
    elif LeagueName == "Championship":
        if teamRank < 3:
            rankColor = "#5ff55f"
        elif teamRank < 7:
            rankColor = "#4093e6"
        elif teamRank > 21:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"
    elif LeagueName == "League One":
        if teamRank < 3:
            rankColor = "#5ff55f"
        elif teamRank < 7:
            rankColor = "#4093e6"
        elif teamRank > 20:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"
    elif LeagueName == "League Two":
        if teamRank < 4:
            rankColor = "#5ff55f"
        elif teamRank < 8:
            rankColor = "#4093e6"
        elif teamRank > 22:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"
    elif LeagueName == "Serie A":
        if teamRank < 5:
            rankColor = "#5ff55f"
        elif teamRank < 6:
            rankColor = "#4093e6"
        elif teamRank < 7:
            rankColor = "#fcfc6d"
        elif teamRank > 17:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"
    elif LeagueName == "La Liga":
        if teamRank < 5:
            rankColor = "#5ff55f"
        elif teamRank < 6:
            rankColor = "#4093e6"
        elif teamRank < 7:
            rankColor = "#fcfc6d"
        elif teamRank > 17:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName == "Ligue 1":
        if teamRank < 5:
            rankColor = "#5ff55f"
        elif teamRank < 6:
            rankColor = "#4093e6"
        elif teamRank < 7:
            rankColor = "#fcfc6d"
        elif teamRank > 15:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName == "Bundesliga":
        if teamRank < 5:
            rankColor = "#5ff55f"
        elif teamRank < 6:
            rankColor = "#4093e6"
        elif teamRank < 7:
            rankColor = "#fcfc6d"
        elif teamRank > 15:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName == "SPL":
        if teamRank < 3:
            rankColor = "#5ff55f"
        elif teamRank < 4:
            rankColor = "#4093e6"
        elif teamRank < 5:
            rankColor = "#fcfc6d"
        elif teamRank > 10:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName == "Eredivisie":
        if teamRank < 4:
            rankColor = "#5ff55f"
        elif teamRank < 5:
            rankColor = "#4093e6"
        elif teamRank < 9:
            rankColor = "#fcfc6d"
        elif teamRank > 15:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName == "Primeira Liga":
        if teamRank < 3:
            rankColor = "#5ff55f"
        elif teamRank < 4:
            rankColor = "#4093e6"
        elif teamRank < 5:
            rankColor = "#fcfc6d"
        elif teamRank > 15:
            rankColor = "#f75252"
        else:
            rankColor = "#fff"

    elif LeagueName.startswith("MLS"):
        if teamRank < 8:
            rankColor = "#5ff55f"
        elif teamRank < 10:
            rankColor = "#4093e6"
        else:
            rankColor = "#fff"

    elif LeagueName == "A-League":
        if teamRank < 7:
            rankColor = "#5ff55f"
        else:
            rankColor = "#fff"

    else:
        rankColor = "#fff"

    return rankColor

def getLeagueName(selectedLeague):
    if selectedLeague == "eng.1":
        return ("EPL")
    elif selectedLeague == "eng.2":
        return ("Championship")
    elif selectedLeague == "eng.3":
        return ("League One")
    elif selectedLeague == "eng.4":
        return ("League Two")
    elif selectedLeague == "ita.1":
        return ("Serie A")
    elif selectedLeague == "esp.1":
        return ("La Liga")
    elif selectedLeague == "fra.1":
        return ("Ligue 1")
    elif selectedLeague == "ger.1":
        return ("Bundesliga")
    elif selectedLeague == "sco.1":
        return ("SPL")
    elif selectedLeague == "ned.1":
        return ("Eredivisie")
    elif selectedLeague == "por.1":
        return ("Primeira Liga")
    elif selectedLeague == "bel.1":
        return ("Belgian Div 1")
    elif selectedLeague == "usa.1":
        return ("MLS")
    elif selectedLeague == "mex.1":
        return ("Liga MX")
    elif selectedLeague == "aus.1":
        return ("A-League")
    elif selectedLeague == "usa.nwsl":
        return ("NWSL")
    return None

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

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

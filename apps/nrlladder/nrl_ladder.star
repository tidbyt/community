"""
Applet: NRL Ladder
Summary: Shows NRL Ladder
Description: Shows NRL Ladder.
Author: M0ntyP

v1.0 
First release

v1.1
Updated abbreviations
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LADDER_URL = "https://www.nrl.com/ladder//data?competition=111"
LADDER_CACHE = 600

def main(config):
    RotationSpeed = config.get("speed", "3")
    renderCategory = []

    # 4.5 pages of 4 teams
    teamsToShow = 4

    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    for x in range(0, 17, teamsToShow):
        renderCategory.extend(
            [
                render.Column(
                    expanded = True,
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Column(
                            children = get_screen(x, LadderJSON),
                        ),
                    ],
                ),
            ],
        )

    return render.Root(
        show_full_animation = True,
        delay = int(RotationSpeed) * 1000,
        child = render.Animation(
            children = renderCategory,
        ),
    )

def get_screen(x, LadderJSON):
    output = []
    s = LadderJSON["positions"]
    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = "#000",
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = "NRL", color = "#ff0", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]
    output.extend(heading)

    for i in range(0, 4):
        if i + x < len(s):
            TeamName = s[i + x]["teamNickname"]
            TeamPts = str(s[i + x]["stats"]["points"])
            TeamDiff = str(s[i + x]["stats"]["points difference"])

            TeamBkg = getTeamBkgColour(TeamName)
            TeamAbbr = getTeamAbbr(TeamName)
            TeamFont = "#fff"

            team = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 7,
                        color = TeamBkg,
                        child =
                            render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    render.Box(
                                        width = 20,
                                        height = 5,
                                        child = render.Text(content = TeamAbbr, color = TeamFont, font = "CG-pixel-3x5-mono"),
                                    ),
                                    render.Box(
                                        width = 24,
                                        height = 5,
                                        child = render.Text(content = TeamPts, color = TeamFont, font = "CG-pixel-3x5-mono"),
                                    ),
                                    render.Box(
                                        width = 20,
                                        height = 5,
                                        child = render.Text(content = TeamDiff, color = TeamFont, font = "CG-pixel-3x5-mono"),
                                    ),
                                ],
                            ),
                    ),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = 7, color = "#111")])])

    return output

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each score is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
        ],
    )

def getTeamAbbr(team_name):
    if team_name == "Broncos":  #Broncos
        return ("BRI")
    elif team_name == "Bulldogs":  #Bulldogs
        return ("CBY")
    elif team_name == "Cowboys":  #Cowboys
        return ("NQL")
    elif team_name == "Dolphins":  #Dolphins
        return ("DOL")
    elif team_name == "Dragons":  #Dragons
        return ("SGI")
    elif team_name == "Eels":  #Eels
        return ("PAR")
    elif team_name == "Knights":  #Knights
        return ("NEW")
    elif team_name == "Panthers":  #Panthers
        return ("PEN")
    elif team_name == "Rabbitohs":  #Rabbitohs
        return ("SOU")
    elif team_name == "Raiders":  #Raiders
        return ("CAN")
    elif team_name == "Roosters":  #Roosters
        return ("SYD")
    elif team_name == "Sea Eagles":  #Sea Eagles
        return ("MAN")
    elif team_name == "Sharks":  #Sharks
        return ("CRO")
    elif team_name == "Storm":  #Storm
        return ("MEL")
    elif team_name == "Titans":  #Titans
        return ("GLD")
    elif team_name == "Warriors":  #Warriors
        return ("WAR")
    elif team_name == "Wests Tigers":  #Tigers
        return ("WST")
    return None

def getTeamBkgColour(team_name):
    if team_name == "Broncos":  #Broncos
        return ("#620036")
    elif team_name == "Bulldogs":  #Bulldogs
        return ("#00519f")
    elif team_name == "Cowboys":  #Cowboys
        return ("#012a5a")
    elif team_name == "Dolphins":  #Dolphins
        return ("#da1119")
    elif team_name == "Dragons":  #Dragons
        return ("#db221a")
    elif team_name == "Eels":  #Eels
        return ("#006baf")
    elif team_name == "Knights":  #Knights
        return ("#0050a0")
    elif team_name == "Panthers":  #Panthers
        return ("#2a2e2e")
    elif team_name == "Rabbitohs":  #Rabbitohs
        return ("#007845")
    elif team_name == "Raiders":  #Raiders
        return ("#90c348")
    elif team_name == "Roosters":  #Roosters
        return ("#0b2c58")
    elif team_name == "Sea Eagles":  #Sea Eagles
        return ("#620036")
    elif team_name == "Sharks":  #Sharks
        return ("#00a4d1")
    elif team_name == "Storm":  #Storm
        return ("#562a89")
    elif team_name == "Titans":  #Titans
        return ("#094870")
    elif team_name == "Warriors":  #Warriors
        return ("#151e6b")
    elif team_name == "Wests Tigers":  #Tigers
        return ("#ef6d10")

    return None

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

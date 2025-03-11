"""
Applet: AFL Ladder
Summary: Shows the AFL Ladder
Description: Shows the AFL (Australian Football League) Ladder.
Author: M0ntyP 

v1.1
Reduced cache from 1hr to 10mins, just so the ladder updates quicker after a match has finished
Moved to 4 teams per cycle instead of 3, so you can work out the top 4 and top 8 easier

v1.1a
Updated caching function

v1.2
Updated for 2024 season

v1.3
Updated for 2025 season
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LADDER_URL = "https://aflapi.afl.com.au/afl/v2/compseasons/73/ladders"
LADDER_CACHE = 600

def main(config):
    RotationSpeed = config.get("speed", "3")
    renderCategory = []

    # 4.5 pages of 4 teams
    teamsToShow = 4

    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    for x in range(0, 18, teamsToShow):
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
    s = LadderJSON["ladders"][0]["entries"]
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
                        child = render.Text(content = "AFL", color = "#ff0", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]
    output.extend(heading)

    for i in range(0, 4):
        if i + x < len(s):
            TeamID = s[i + x]["team"]["id"]
            TeamAbbr = LadderJSON["ladders"][0]["entries"][i + x]["team"]["abbreviation"]

            TeamPts = str(LadderJSON["ladders"][0]["entries"][i + x]["thisSeasonRecord"]["aggregatePoints"])
            TeamPct = str(LadderJSON["ladders"][0]["entries"][i + x]["thisSeasonRecord"]["percentage"]) + "%"

            TeamFont = getTeamFontColour(TeamID)
            TeamBkg = getTeamBkgColour(TeamID)

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
                                        width = 18,
                                        height = 5,
                                        child = render.Text(content = TeamPts, color = TeamFont, font = "CG-pixel-3x5-mono"),
                                    ),
                                    render.Box(
                                        width = 30,
                                        height = 5,
                                        child = render.Text(content = TeamPct, color = TeamFont, font = "CG-pixel-3x5-mono"),
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

def getTeamAbbFromID(team_id):
    if team_id == 1:  #ADE
        return ("ADE")
    elif team_id == 2:  #BRI
        return ("BRI")
    elif team_id == 5:  #CAR
        return ("CAR")
    elif team_id == 3:  #COL
        return ("COL")
    elif team_id == 12:  #ESS
        return ("ESS")
    elif team_id == 14:  #FRE
        return ("FRE")
    elif team_id == 10:  #GEE
        return ("GEE")
    elif team_id == 4:  #GCS
        return ("GC")
    elif team_id == 15:  #GWS
        return ("GWS")
    elif team_id == 9:  #HAW
        return ("HAW")
    elif team_id == 17:  #MEL
        return ("MEL")
    elif team_id == 6:  #NOR
        return ("NM")
    elif team_id == 7:  #POR
        return ("PA")
    elif team_id == 16:  #RIC
        return ("RIC")
    elif team_id == 11:  #STK
        return ("STK")
    elif team_id == 13:  #SYD
        return ("SYD")
    elif team_id == 18:  #WCE
        return ("WC")
    elif team_id == 8:  #WBD
        return ("WB")
    return None

def getTeamFontColour(team_id):
    if team_id == 1:  #ADE
        return ("#FFD200")
    elif team_id == 2:  #BRI
        return ("#EDBF5E")
    elif team_id == 5:  #CAR
        return ("#fff")
    elif team_id == 3:  #COL
        return ("#fff")
    elif team_id == 12:  #ESS
        return ("#f00")
    elif team_id == 14:  #FRE
        return ("#fff")
    elif team_id == 10:  #GEE
        return ("#fff")
    elif team_id == 4:  #GCS
        return ("#df3")
    elif team_id == 15:  #GWS
        return ("#FF7900")
    elif team_id == 9:  #HAW
        return ("#E4AE04")
    elif team_id == 17:  #MEL
        return ("#DE0316")
    elif team_id == 6:  #NOR
        return ("#fff")
    elif team_id == 7:  #POR
        return ("#008AAB")
    elif team_id == 16:  #RIC
        return ("#df3")
    elif team_id == 11:  #STK
        return ("#fff")
    elif team_id == 13:  #SYD
        return ("#fff")
    elif team_id == 18:  #WCE
        return ("#F2AB00")
    elif team_id == 8:  #WBD
        return ("#DE0316")
    return None

def getTeamBkgColour(team_id):
    if team_id == 1:  #ADE
        return ("#00437F")
    elif team_id == 2:  #BRI
        return ("#69003D")
    elif team_id == 5:  #CAR
        return ("#001B2A")
    elif team_id == 3:  #COL
        return ("#000")
    elif team_id == 12:  #ESS
        return ("#000")
    elif team_id == 14:  #FRE
        return ("#2E194B")
    elif team_id == 10:  #GEE
        return ("#001F3D")
    elif team_id == 4:  #GCS
        return ("#E02112")
    elif team_id == 15:  #GWS
        return ("#000")
    elif team_id == 9:  #HAW
        return ("#492718")
    elif team_id == 17:  #MEL
        return ("#061A33")
    elif team_id == 6:  #NOR
        return ("#003690")
    elif team_id == 7:  #POR
        return ("#000")
    elif team_id == 16:  #RIC
        return ("#000")
    elif team_id == 11:  #STK
        return ("#f00")
    elif team_id == 13:  #SYD
        return ("#f00")
    elif team_id == 18:  #WCE
        return ("#002B79")
    elif team_id == 8:  #WBD
        return ("#0039A6")
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

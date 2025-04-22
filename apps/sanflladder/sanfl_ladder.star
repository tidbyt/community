"""
Applet: SANFL Ladder
Summary: Shows the SANFL Ladder
Description: Shows the SANFL Ladder.
Author: M0ntyP 

v1.0
First version!

v1.1
Updated API URL and reduced cache
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

LADDER_URL = "https://api3.sanflstats.com/ladder/2025/sanfl"
DEFAULT_TIMEZONE = "Australia/Adelaide"

def main(config):
    RotationSpeed = config.get("speed", "3")
    renderCategory = []
    LADDER_CACHE = 43200  #12 hours

    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    DayofWeek = now.format("Mon")

    # 2.5 pages of 4 teams
    teamsToShow = 4

    if DayofWeek == "Fri" or DayofWeek == "Sat" or DayofWeek == "Sun":
        LADDER_CACHE = 3600

    LadderData = get_cachable_data(LADDER_URL, LADDER_CACHE)
    LadderJSON = json.decode(LadderData)

    for x in range(0, 9, teamsToShow):
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
    s = LadderJSON["ladder"]
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
                        child = render.Text(content = "SANFL", color = "#ff0", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]
    output.extend(heading)

    for i in range(0, 4):
        if i + x < len(s):
            TeamID = int(s[i + x]["squadId"])
            TeamPts = str(LadderJSON["ladder"][i + x]["points"])
            TeamPct = str(LadderJSON["ladder"][i + x]["percentage"]) + "%"

            TeamAbbr = getTeamAbbFromID(TeamID)
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
    if team_id == 7314:  #ADE
        return ("ADE")
    elif team_id == 1040:  #STH
        return ("STH")
    elif team_id == 1039:  #PTA
        return ("PRT")
    elif team_id == 1042:  #WST
        return ("WST")
    elif team_id == 1038:  #NRW
        return ("NWD")
    elif team_id == 1036:  #GLE
        return ("GLG")
    elif team_id == 1037:  #NTH
        return ("NTH")
    elif team_id == 1043:  #WWT
        return ("WWT")
    elif team_id == 1035:  #CEN
        return ("CEN")
    elif team_id == 1041:  #SRT
        return ("SRT")
    return ("NONE")

def getTeamFontColour(team_id):
    if team_id == 7314:  #ADE
        return ("#FFD200")
    elif team_id == 1040:  #STH
        return ("#fff")
    elif team_id == 1039:  #PTA
        return ("#fff")
    elif team_id == 1042:  #WST
        return ("#f00")
    elif team_id == 1038:  #NRW
        return ("#DE0316")
    elif team_id == 1036:  #GLE
        return ("#df3")
    elif team_id == 1037:  #NTH
        return ("#fff")
    elif team_id == 1043:  #WWT
        return ("#F2AB00")
    elif team_id == 1035:  #CEN
        return ("#DE0316")
    elif team_id == 1041:  #SRT
        return ("#599ed6")
    return ("#fff")

def getTeamBkgColour(team_id):
    if team_id == 7314:  #ADE
        return ("#0a2240")
    elif team_id == 1040:  #STH
        return ("#001B2A")
    elif team_id == 1039:  #PTA
        return ("#000")
    elif team_id == 1042:  #WST
        return ("#000")
    elif team_id == 1038:  #NRW
        return ("#061A33")
    elif team_id == 1036:  #GLE
        return ("#000")
    elif team_id == 1037:  #NTH
        return ("#f00")
    elif team_id == 1043:  #WWT
        return ("#002B79")
    elif team_id == 1035:  #CEN
        return ("#0039A6")
    elif team_id == 1041:  #SRT
        return ("#00285d")
    return ("#fff")

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

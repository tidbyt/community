"""
Applet: Tennis Rankings
Summary: Shows ATP/WTA Top 20
Description: Displays either ATP or WTA Top 20 with options for position change and total points.
Author: M0ntyP

v1.1
Updated caching function and changed title bar color for WTA

v1.2 
Added date to title bar so you can see when the rankings were last updated

v1.2.1
Reduced cache TTL from 6hrs to 1hr as it was taking too long to update
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_RANKING_URL = "https://site.api.espn.com/apis/site/v2/sports/tennis/"
RANKING_CACHE = 14400  # 4hrs

def main(config):
    RotationSpeed = config.get("speed", "3")
    Selection = config.get("league", "atp")
    ShowPts = config.bool("ShowPtsToggle", True)
    ShowChange = config.bool("ShowChangeToggle", True)
    renderScreen = []

    RANKING_URL = BASE_RANKING_URL + Selection + "/rankings"
    RankingData = get_cachable_data(RANKING_URL, RANKING_CACHE)
    RankingJSON = json.decode(RankingData)

    if ShowPts == True:
        if ShowChange == True:
            for x in range(0, 20, 4):
                renderScreen.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screen(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screenPoints(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screenTrend(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                    ],
                )
        elif ShowChange == False:
            for x in range(0, 20, 4):
                renderScreen.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screen(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screenPoints(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                    ],
                )
    elif ShowPts == False:
        if ShowChange == True:
            for x in range(0, 20, 4):
                renderScreen.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screen(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screenTrend(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                    ],
                )
        elif ShowChange == False:
            for x in range(0, 20, 4):
                renderScreen.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = get_screen(x, RankingJSON, Selection),
                                ),
                            ],
                        ),
                    ],
                )

    return render.Root(
        show_full_animation = True,
        delay = int(RotationSpeed) * 1000,
        child = render.Animation(
            children = renderScreen,
        ),
    )

def get_screen(x, RankingJSON, Selection):
    output = []

    if Selection == "wta":
        TitleBarColor = "#7915ff"
    else:
        TitleBarColor = "#203764"

    UpdateDate = RankingJSON["rankings"][0]["update"]
    FormatDate = time.parse_time(UpdateDate, format = "2006-01-02T15:04Z")
    FormatDate = FormatDate.format("02/01")

    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = TitleBarColor,
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = Selection + " TOP 20 " + FormatDate, color = "#fff", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]

    output.extend(heading)

    for i in range(0, 4):
        if i + x < 20:
            Name = RankingJSON["rankings"][0]["ranks"][i + x]["athlete"]["lastName"]
            Rank = RankingJSON["rankings"][0]["ranks"][i + x]["current"]

            Player = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        main_align = "start",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = str(Rank) + "." + Name,
                                    color = "#fff",
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                ],
            )

            output.extend([Player])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = 7, color = "#111")])])

    return output

def get_screenPoints(x, RankingJSON, Selection):
    output = []

    if Selection == "wta":
        TitleBarColor = "#7915ff"
    else:
        TitleBarColor = "#203764"

    UpdateDate = RankingJSON["rankings"][0]["update"]
    FormatDate = time.parse_time(UpdateDate, format = "2006-01-02T15:04Z")
    FormatDate = FormatDate.format("02/01")

    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = TitleBarColor,
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = Selection + " TOP 20 " + FormatDate, color = "#fff", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]

    output.extend(heading)

    for i in range(0, 4):
        if i + x < 20:
            Name = RankingJSON["rankings"][0]["ranks"][i + x]["athlete"]["lastName"]
            Rank = RankingJSON["rankings"][0]["ranks"][i + x]["current"]
            Points = humanize.ftoa(RankingJSON["rankings"][0]["ranks"][i + x]["points"])

            Player = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        main_align = "start",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = str(Rank) + "." + Name[:7],
                                    color = "#fff",
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = Points,
                                    color = "#fff",
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                ],
            )

            output.extend([Player])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = 7, color = "#111")])])

    return output

def get_screenTrend(x, RankingJSON, Selection):
    #print(Selection)
    output = []
    if Selection == "wta":
        TitleBarColor = "#7915ff"
    else:
        TitleBarColor = "#203764"

    TrendColor = "#fff"

    UpdateDate = RankingJSON["rankings"][0]["update"]
    FormatDate = time.parse_time(UpdateDate, format = "2006-01-02T15:04Z")
    FormatDate = FormatDate.format("02/01")

    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = TitleBarColor,
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = Selection + " TOP 20 " + FormatDate, color = "#fff", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]

    output.extend(heading)

    for i in range(0, 4):
        if i + x < 20:
            Name = RankingJSON["rankings"][0]["ranks"][i + x]["athlete"]["lastName"]
            Rank = RankingJSON["rankings"][0]["ranks"][i + x]["current"]

            Trend = RankingJSON["rankings"][0]["ranks"][i + x]["trend"]
            if len(Trend) > 1:
                if Trend.startswith("+"):
                    TrendColor = "#03FF46"
                elif Trend.startswith("-"):
                    TrendColor = "#f00"
            else:
                TrendColor = "#fff"

            Player = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        main_align = "start",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = str(Rank) + "." + Name[:10],
                                    color = "#fff",
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        children = [
                            render.Padding(
                                pad = (1, 1, 0, 1),
                                child = render.Text(
                                    content = Trend,
                                    color = TrendColor,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                ],
            )

            output.extend([Player])
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
                id = "league",
                name = "Association",
                desc = "ATP or WTA ?",
                icon = "gear",
                default = AssocationOptions[0].value,
                options = AssocationOptions,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Rotation Speed",
                desc = "How many seconds each score is displayed",
                icon = "gear",
                default = RotationOptions[1].value,
                options = RotationOptions,
            ),
            schema.Toggle(
                id = "ShowPtsToggle",
                name = "Points",
                desc = "Show ranking points",
                icon = "toggleOn",
                default = False,
            ),
            schema.Toggle(
                id = "ShowChangeToggle",
                name = "Show position change",
                desc = "Show change in position from previous week",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

AssocationOptions = [
    schema.Option(
        display = "ATP",
        value = "atp",
    ),
    schema.Option(
        display = "WTA",
        value = "wta",
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

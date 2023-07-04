"""
Applet: FedEx Cup
Summary: Shows FedEx Cup standings
Description: Shows the standings for the PGA Tour's FedEx Cup.
Author: M0ntyP

v1.0
First release
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

STANDINGS_URL = "https://www.pgatour.com/_next/data/pgatour-prod-1.19.5/en/fedexcup.json?tab=official-standings.html"
DEFAULT_TIMEZONE = "America/New_York"

def main():
    STANDINGS_CACHE = 86400  # 24hrs is default

    Day = time.now().in_location(DEFAULT_TIMEZONE)
    Day = Day.format("Monday")

    # if its Sunday or Monday on the East Coast of US then we check for updates every hour, otherwise check once a day
    if Day == "Sunday" or Day == "Monday":
        STANDINGS_CACHE = 3600

    FedExData = get_cachable_data(STANDINGS_URL, STANDINGS_CACHE)
    FedExJSON = json.decode(FedExData)
    player_list = FedExJSON["pageProps"]["tourCupDetails"]["officialPlayers"]

    renderScreen = []

    for x in range(0, 30, 4):
        renderScreen.extend(
            [
                render.Column(
                    expanded = True,
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Column(
                            children = get_screenTrend(x, player_list),
                        ),
                    ],
                ),
            ],
        )

    return render.Root(
        show_full_animation = True,
        delay = int(2) * 1000,
        child = render.Animation(
            children = renderScreen,
        ),
    )

def get_screen(x, player_list):
    output = []

    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = "#0039A6",
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = "FEDEX CUP", color = "#fff", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]

    output.extend(heading)

    for i in range(0, 4):
        # need to skip over 10
        if i + x >= 10:
            i = i + 1

        if i + x < 31:
            Name = player_list[i + x]["lastName"]
            Rank = player_list[i + x]["thisWeekRank"]
            PrevRank = player_list[i + x]["previousWeekRank"]

            print(Rank, Name)
            intRank = int(Rank)
            intPrevRank = int(PrevRank)

            diff = intPrevRank - intRank
            print(diff)

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
                                    content = Rank + "." + Name,
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

def get_screenTrend(x, player_list):
    output = []

    TrendColor = "#fff"

    heading = [
        render.Box(
            width = 64,
            height = 5,
            color = "#0039A6",
            child = render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(
                        width = 64,
                        height = 5,
                        child = render.Text(content = "FEDEX CUP", color = "#fff", font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        ),
    ]
    output.extend(heading)

    for i in range(0, 4):
        # need to skip over 10
        if i + x >= 10:
            i = i + 1

        if i + x < 31:
            Name = player_list[i + x]["lastName"]
            Rank = player_list[i + x]["thisWeekRank"]
            PrevRank = player_list[i + x]["previousWeekRank"]
            intRank = int(Rank)
            intPrevRank = int(PrevRank)

            diff = intPrevRank - intRank

            if diff > 0:
                TrendColor = "#03FF46"
            elif diff < 0:
                TrendColor = "#f00"
            else:
                diff = "-"
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
                                    content = str(diff),
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

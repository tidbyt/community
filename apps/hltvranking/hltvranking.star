load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

RANKING_URL = "https://www.hltv.org/mobile/ranking"
HTTP_HEADERS = { "User-Agent": "tidbyt" }

def make_team_row(team, rank):
    team_name = team["teamName"]
    players = team["players"]
    if team_name == "Bad News Eagles":
        team_name = "BNE"
    elif team_name == "Eternal Fire":
        team_name = "EF"
    elif team_name == "Evil Geniuses":
        team_name = "EG"
    elif team_name == "Movistar Riders":
        team_name = "Riders"
    elif team_name == "Natus Vincere":
        team_name = "NaVi"
    elif team_name == "Ninjas in Pyjamas":
        team_name = "NiP"

    flags = {}
    for player in players:
        flag = player["flagUrl"]
        if flag in flags:
            flags[flag] += 1
        else:
            flags[flag] = 1
        pass

    max_flag_url = ""
    max_count = 0

    for flag, count in flags.items():
        temp_max = max(max_count, count)
        if temp_max > max_count:
            max_count = temp_max
            max_flag_url = flag

    # TODO: Handle regions
    if len(flags) == 5 or max_count < 3:
        max_flag_url = "https://www.hltv.org/img/static/flags/30x20/WORLD.gif"

    flag = http.get(max_flag_url, headers=HTTP_HEADERS).body()

    return render.Row(
        children=[
            render.Text(rank + "-", font="CG-pixel-3x5-mono", height=6, offset=1),
            render.Image(flag, height=5),
            render.Text(" " + team_name, font="CG-pixel-3x5-mono", height=6, offset=1),
        ]
    )

def main():
    res = http.get(RANKING_URL, headers=HTTP_HEADERS)
    if res.status_code != 200:
        fail("HLTV request failed with status ", res.status_code)

    teams = res.json()["teams"]

    return render.Root(
        child=render.Column(
            children=[
                render.Marquee(
                    child=render.Text("HLTV World Ranking", color="#2b6ea4"),
                    width=64
                ),
                make_team_row(teams[0], "1"),
                make_team_row(teams[1], "2"),
                make_team_row(teams[2], "3"),
                make_team_row(teams[3], "4"),
            ]
        )
    )
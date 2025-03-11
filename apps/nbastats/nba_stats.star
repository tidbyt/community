"""
Applet: NBA Stats
Summary: NBA Stat Leaders
Description: Displays the current NBA leaders in PPG, RPG, APG, BPG and SPG.
Author: Emmett Myers
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

def main():
    season_str = get_current_season()
    nba_leaders_url = "https://stats.nba.com/stats/leagueleaders?ActiveFlag=&LeagueID=00&PerMode=PerGame&Scope=S&Season=" + season_str + "&SeasonType=Regular+Season&StatCategory="

    ranks = [fetch_player_data(nba_leaders_url, i) for i in range(15)]

    return render.Root(
        delay = 1000,
        child = render.Row(
            children = [
                render.Animation(
                    children = ranks,
                ),
            ],
        ),
    )

def get_current_season():
    current_time = time.now()
    year = current_time.year
    month = current_time.month
    season_start = year if month >= 10 else year - 1
    return str(season_start) + "-" + str(year)[2:4]

def fetch_player_data(base_url, index):
    stat_name, stat_url, stat_index, rank = get_stat_info(index)
    stats = http.get(base_url + stat_url).json()["resultSet"]["rowSet"]

    full_name = stats[rank][2].split()
    name = full_name[0][0] + ". " + full_name[-1]

    player = {
        "name": name,
        "team": stats[rank][4],
        "stat_name": stat_name,
        "stat": stats[rank][stat_index],
    }

    return player_column(player, rank)

def get_stat_info(i):
    stats = [
        ("PPG", "PTS", -2),
        ("RPG", "REB", -7),
        ("APG", "AST", -6),
        ("SPG", "STL", -5),
        ("BPG", "BLK", -4),
    ]
    stat_name, stat_url, stat_index = stats[i // 3]
    return stat_name, stat_url, stat_index, i % 3

def player_column(player, rank):
    return render.Column(
        children = [
            render.Stack(
                children = [
                    render.Box(
                        width = 65,
                        height = 8,
                        color = "#424242",
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(" NBA", color = "#ff5c5c"),
                            render.Text(player["stat_name"] + " Ranks", color = "#5e7eff"),
                        ],
                    ),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(" " + str(1 + rank) + ") ", color = "#fce060"),
                    render.Text(player["name"]),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "end",
                cross_align = "center",
                children = [
                    render.Text(player["team"]),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "end",
                cross_align = "center",
                children = [
                    render.Text(str(player["stat"]) + " " + player["stat_name"]),
                ],
            ),
        ],
    )

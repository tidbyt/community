"""
Applet: FPL Tracker
Summary: FPL standings and scores
Description: Display standings and scores for a Fantasy Premier League (Soccer) team.
Author: DoubleGremlin181
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    team_id = config.str("team_id", None)

    if not team_id:
        return render_error("Enter Team ID")

    summary_url = "https://fantasy.premierleague.com/api/entry/{}/".format(team_id)
    history_url = "https://fantasy.premierleague.com/api/entry/{}/history/".format(team_id)

    s_data = get_data(summary_url)
    h_data = get_data(history_url)

    if not s_data or "detail" in s_data:
        return render_error("Invalid Team ID")

    # Fetch current game week
    gw = s_data["current_event"]

    if not gw:
        return render_error("Awating season start")

    gw = int(gw)
    team_name = s_data["name"]
    gw_points = int(s_data["summary_event_points"])
    rank = int(s_data["summary_overall_rank"])
    rank_change_dir = 0

    if gw > 1:
        prev_rank = int([gw_h["overall_rank"] for gw_h in h_data["current"] if gw_h["event"] == gw - 1][0])
        if prev_rank < rank:
            rank_change_dir = -1
        elif prev_rank > rank:
            rank_change_dir = 1

    return render_stats(team_name, gw, gw_points, rank, rank_change_dir)

def get_data(url):
    res = http.get(url, ttl_seconds = 3600)  # cache for 1 hour
    if res.status_code != 200:
        return None
    return res.json()

def render_error(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("Fantasy Premier League"),
                    offset_start = 5,
                    offset_end = 5,
                    height = 8,
                ),
                render.Box(width = 64, height = 1, color = "#00ff85"),
                render.Box(width = 64, height = 1, color = "#38003c"),
                render.Row(
                    children = [
                        render.WrappedText(message),
                    ],
                ),
            ],
        ),
    )

def render_stats(team_name, gw, gw_points, rank, rank_change_dir):
    rank_change_obj = render.Text("  -", color = "#808080")
    if rank_change_dir == 1:
        rank_change_obj = render.Text("  ↑", color = "#00FF00")
    elif rank_change_dir == -1:
        rank_change_obj = render.Text("  ↓", color = "#FF0000")

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(team_name),
                    offset_start = 5,
                    offset_end = 5,
                    height = 8,
                ),
                render.Box(width = 64, height = 1, color = "#00ff85"),
                render.Box(width = 64, height = 1, color = "#38003c"),
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Text(" GW{}:".format(gw)),
                                render.Text("{} pts ".format(gw_points)),
                            ],
                            expanded = True,
                            main_align = "space_between",
                        ),
                        render.Row(
                            children = [
                                rank_change_obj,
                                render.Text("{} ".format(humanize.comma(rank))),
                            ],
                            expanded = True,
                            main_align = "space_between",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_around",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team_id",
                name = "Team ID",
                desc = "Team ID to track",
                icon = "user",
            ),
        ],
    )

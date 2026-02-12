"""
Applet: NBA Top 8 
Summary: Top NBA teams
Description: Top 8 NBA teams in each conference.
Author: adamh0903
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

STANDINGS_URL = "https://site.web.api.espn.com/apis/v2/sports/basketball/nba/standings"

FAVORITE_TEAM = "ORL"

EAST_COLOR = "#1D428A"   # Blue
WEST_COLOR = "#C8102E"   # Red
PLAYOFF_COLOR = "#00FF00"
GB_COLOR = "#AAAAAA"


def stat_value(stats, name):
    for s in stats:
        if s["name"] == name:
            return s["value"]
    return 0


def fetch_standings():
    res = http.get(STANDINGS_URL)
    data = res.json()

    east = []
    west = []

    for group in data["children"]:
        group_name = group["name"].lower()

        for e in group["standings"]["entries"]:
            team = e["team"]["abbreviation"]
            wins = int(stat_value(e["stats"], "wins"))
            losses = int(stat_value(e["stats"], "losses"))
            gb = str(stat_value(e["stats"], "gamesBehind"))

            if "east" in group_name:
                east.append((team, wins, losses, gb))
            elif "west" in group_name:
                west.append((team, wins, losses, gb))

    return east[:8], west[:8]


def build_page(title, teams, start_index, color):
    rows = [
        render.Text("NBA " + title, color=color),
        render.Text(""),
    ]

    rank = start_index + 1

    for t in teams[start_index:start_index+4]:
        team, wins, losses, gb = t

        if rank <= 4:
            line = str(rank) + " " + team + " " + str(wins) + "-" + str(losses)
            rows.append(render.Text(line, color=PLAYOFF_COLOR))
        else:
            line = str(rank) + " " + team + " " + str(wins) + "-" + str(losses)
            rows.append(render.Text(line))

        rows.append(render.Text("GB: " + gb, color=GB_COLOR))

        rank += 1

    return render.Root(
        child=render.Column(children=rows)
    )


def build_favorite_slide(east, west):
    combined = east + west

    for t in combined:
        team, wins, losses, gb = t

        if team == FAVORITE_TEAM:
            return render.Root(
                child=render.Column(children=[
                    render.Text("YOUR TEAM", color="#FFD700"),
                    render.Text(""),
                    render.Text(team, color="#FFFFFF"),
                    render.Text("Record: " + str(wins) + "-" + str(losses)),
                    render.Text("GB: " + gb, color=GB_COLOR),
                ])
            )

    return None


def main(config):
    east, west = fetch_standings()

    slides = [
        build_page("EAST", east, 0, EAST_COLOR),
        build_page("EAST", east, 4, EAST_COLOR),
        build_page("WEST", west, 0, WEST_COLOR),
        build_page("WEST", west, 4, WEST_COLOR),
    ]

    fav_slide = build_favorite_slide(east, west)
    if fav_slide:
        slides.append(fav_slide)

    return slides


app_schema = schema.Schema(version="1")


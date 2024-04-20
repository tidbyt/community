"""
Applet: Simple Scoreboard
Summary: Simple Team Scoreboard
Description: A simple display for keeping score for various home games like Cornhole, Bocce, Shuffleboard, etc.
Author: Blkhwks19
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    team1_txt = "%s" % config.str("team1_score", "0")
    team1_col = "%s" % config.str("team1_color", "#0000FF")
    team1_child = render.Text(content = team1_txt, color = team1_col, font = "10x20")

    team2_txt = "%s" % config.str("team2_score", "0")
    team2_col = "%s" % config.str("team2_color", "#FF0000")
    team2_child = render.Text(content = team2_txt, color = team2_col, font = "10x20")

    if config.bool("show_round"):
        round_txt = "%s" % config.str("round_text", "1")
    else:
        round_txt = ""
    round_col = "%s" % config.str("round_color", "#FFFFFF")
    round_child = render.Text(content = round_txt, color = round_col, font = "CG-pixel-3x5-mono")

    children = [team1_child, round_child, team2_child]

    return render.Root(
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team1_score",
                name = "Team 1 Score",
                desc = "Score for Team 1",
                icon = "iCursor",
                default = "0",
            ),
            schema.Color(
                id = "team1_color",
                name = "Team 1 Color",
                desc = "Color for Team 1 score",
                icon = "palette",
                default = "#0000FF",
                palette = [
                    "#0000FF",
                    "#FF0000",
                    "#FFFF00",
                    "#00FF00",
                    "#FFAA00",
                    "#00FFFF",
                    "#FF00FF",
                    "#FFFFFF",
                ],
            ),
            schema.Text(
                id = "team2_score",
                name = "Team 2 Score",
                desc = "Score for Team 2",
                icon = "iCursor",
                default = "0",
            ),
            schema.Color(
                id = "team2_color",
                name = "Team 2 Color",
                desc = "Color for Team 2 score",
                icon = "palette",
                default = "#FF0000",
                palette = [
                    "#0000FF",
                    "#FF0000",
                    "#FFFF00",
                    "#00FF00",
                    "#FFAA00",
                    "#00FFFF",
                    "#FF00FF",
                    "#FFFFFF",
                ],
            ),
            schema.Toggle(
                id = "show_round",
                name = "Show Round?",
                desc = "A toggle to show round number",
                icon = "clock",
                default = False,
            ),
            schema.Text(
                id = "round_text",
                name = "Round Text",
                desc = "Text to indicate round or frame",
                icon = "iCursor",
                default = "1",
            ),
            schema.Color(
                id = "round_color",
                name = "Round Color",
                desc = "Color for Round text",
                icon = "palette",
                default = "#FFFFFF",
                palette = [
                    "#0000FF",
                    "#FF0000",
                    "#FFFF00",
                    "#00FF00",
                    "#FFAA00",
                    "#00FFFF",
                    "#FF00FF",
                    "#FFFFFF",
                ],
            ),
        ],
    )

"""
Applet: NflDivStandings
Summary: Show NFL division standings
Description: Displays NFL division standings for your favorite division.
Author: Jake Manske
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("animation.star", "animation")

STANDINGS_URL = "https://site.api.espn.com/apis/v2/sports/football/nfl/standings"
LOGO_TTL_SECONDS = 86400
STANDINGS_TTL_SECONDS = 300

def main(config):
    division_id = config.get("division") or "10"
    standings = get_standings(division_id)
    return render.Root(
        child = render.Row(
            children = [
                render_team_card(standings[0]),
                render_team_card(standings[1]),
                render_team_card(standings[2]),
                render_team_card(standings[3]),
            ]
        )
    )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(offset, 0)],
        curve = "ease_in_out",
    )

def get_standings(division_id):
    query_params = {
        "group": division_id
    }
    response = http.get(STANDINGS_URL, params = query_params, ttl_seconds = STANDINGS_TTL_SECONDS)

    standings = []
    for team in response.json().get("standings").get("entries"):
        standings.append(parse_team(team.get("team"), team.get("stats")))
    return standings

def render_logo(team, logo_width):
    return render.Image(
        src = http.get(team.Logo, ttl_seconds = LOGO_TTL_SECONDS).body(),
        width = logo_width
    )

def render_team_card(team):
    logo_width = 32
    return render.Box(
        height = 32,
        width = 59,
        color = "#FFFFFF",
        child = render.Row(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render_logo(team, logo_width),
                render.Column(
                    main_align = "space_evenly",
                    cross_align = "end",
                    expanded = True,
                    children = [
                        render.Text(
                            content = "lol"
                        )
                    ]
                ),
            ],
        ),
    )

def parse_team(team_raw, stats_raw):
    abbrev = team_raw.get("abbreviation")
    logo_url = team_raw.get("logos")[0].get("href")
    record = "-"
    for stat in stats_raw:
        name = stat.get("name")
        if name == "overall":
            record = stat.get("displayValue")
    return struct(Abbreviation = abbrev, Logo = logo_url, Record = record)

def get_schema():
    options = [
        schema.Option(
            display = "AFC East",
            value = "4",
        ),
        schema.Option(
            display = "AFC North",
            value = "12",
        ),
        schema.Option(
            display = "AFC South",
            value = "13",
        ),
        schema.Option(
            display = "AFC West",
            value = "6",
        ),
        schema.Option(
            display = "NFC East",
            value = "1",
        ),
        schema.Option(
            display = "NFC North",
            value = "10",
        ),
        schema.Option(
            display = "NFC South",
            value = "11",
        ),
        schema.Option(
            display = "NFC West",
            value = "3",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "division",
                name = "Division",
                desc = "The division to display standings for.",
                icon = "footballBall",
                default = "10",
                options = options
            )
        ],
    )

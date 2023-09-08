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
        delay = 80,
        show_full_animation = True,
        child = render.Row(
            children = [
                render.Box(
                    width = 5,
                    height = 32
                ),
                animation.Transformation(
                    duration = 180,
                    width = 236,
                    keyframes = [
                        build_keyframe(0, 0.0),
                        build_keyframe(-59, 0.33),
                        build_keyframe(-118, 0.66),
                        build_keyframe(-177, 1.0)
                    ],
                    child = render_division_standings(standings),
                    wait_for_child = True,
                ),
            ],
        ),
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

def render_division_standings(standings):
    cards = []
    for team in standings:
        cards.append(render_team_card(team))
    return render.Row(
        children = cards
    )

def render_team_card(team):
    colors = COLOR_MAP[team.Id]
    logo_width = 59
    return render.Box(
        height = 32,
        width = 59,
        color = colors.BackgroundColor,
        child = render.Row(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render.Padding(
                    pad = (0,-15,0,0),
                    child = render_logo(team, logo_width),
                ),
                render.Column(
                    main_align = "space_evenly",
                    cross_align = "end",
                    expanded = True,
                    children = [
                        render.Text(
                            content = team.Record,
                            color = colors.ForegroundColor
                        ),
                        render.Text(
                            content = str(team.Id),
                            color = colors.ForegroundColor
                        )
                    ]
                ),
            ],
        ),
    )

def parse_team(team_raw, stats_raw):
    abbrev = team_raw.get("abbreviation")
    # just take the first logo
    logo_url = team_raw.get("logos")[0].get("href")
    id = int(team_raw.get("id"))
    record = "-"
    for stat in stats_raw:
        name = stat.get("name")
        if name == "overall":
            record = stat.get("displayValue")
    return struct(Id = id, Abbreviation = abbrev, Logo = logo_url, Record = record)

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

def team_colors(fg, bg):
    return struct(ForegroundColor = fg, BackgroundColor = bg)
COLOR_MAP = {
    # ATL
    1: team_colors("#A71930", "#000000"),
    # BUF
    2: team_colors("#FFFFFF", "#00338D"),
    # CHI
    3: team_colors("#C83803", "#0B162A"),
    # CIN
    4: team_colors("#FB4F14", "#000000"),
    # CLE
    5: team_colors("#FF3C00", "#311D00"),
    # DAL
    6: team_colors("#869397", "#041E42"),
    # DEN
    7: team_colors("#FB4F14", "#002244"),
    # DET
    8: team_colors("#B0B7BC", "#0076B6"),
    # GB
    9: team_colors("#FFB612", "#203731"),
    # TEN
    10: team_colors("#4B92DB", "#0C2340"),
    # IND
    11: team_colors("#FFFFFF", "#002C5F"),
    # KC
    12: team_colors("#FFB81C", "#E31837"),
    # OAK
    13: team_colors("#A5ACAF", "#000000"),
    # LAR
    14: team_colors("#FFA300", "#003594"),
    # MIA
    15: team_colors("#FC4C02", "#008E97"),
    # MIN
    16: team_colors("#FFC62F", "#4F2683"),
    # NE
    17: team_colors("#B0B7BC", "#002244"),
    # NO
    18: team_colors("#D3BC8D", "#000000"),
    # NYG
    19: team_colors("#A71930", "#0B2265"),
    # NYJ
    20: team_colors("#FFFFFF", "#125740"),
    # PHI 
    21: team_colors("#ACC0C6", "#004C54"),
    # ARI
    22: team_colors("#97233F", "#000000"),
    # PIT
    23: team_colors("#FFB612", "#101820"),
    # LAC
    24: team_colors("#FFC20E", "#0080C6"),
    # SF
    25: team_colors("#B3995D", "#AA0000"),
    # SEA
    26: team_colors("#A5ACAF", "#002244"),
    # TB
    27: team_colors("#D50A0A", "#0A0A08"),
    # WAS
    28: team_colors("#FFB612", "#5A1414"),
    # CAR
    29: team_colors("#0085CA", "#101820"),
    # JAX
    30: team_colors("#006778", "#101820"),
    # BAL
    33: team_colors("#241773", "#000000"),
    # HOU
    34: team_colors("#A71930", "#03202F"),
}
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WHITE = "#fff"
BLACK = "#000"

SCHEDULE_URL = "https://statsapi.mlb.com/api/v1/schedule"
LIVE_URL = "https://statsapi.mlb.com/api/v1.1/game/%d/feed/live"

def text_at(value, x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Text(
            content = value,
            font = "tb-8",
            color = WHITE,
        ),
    )

# ---------------------------------------------------------
# 7x7 FULL ROUND OUT DOT
# ---------------------------------------------------------

def out_dot(x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 7,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 7,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 7,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
            ],
        ),
    )

# ---------------------------------------------------------
# BLACK COVER FOR AN OUT DOT
# ---------------------------------------------------------

def blank_out_dot(x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Circle(
            diameter = 7,
            color = BLACK,
        ),
    )

# ---------------------------------------------------------
# CRISP UP ARROW
# ---------------------------------------------------------

def up_arrow(x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 2,
                    color = WHITE,
                ),
            ],
        ),
    )

# ---------------------------------------------------------
# DOWN ARROW
# ---------------------------------------------------------

def down_arrow(x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    width = 5,
                    height = 2,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),
            ],
        ),
    )

# ---------------------------------------------------------
# 7x7 OUTLINED DIAMOND
# ---------------------------------------------------------

def base_diamond(x, y):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Column(
            cross_align = "center",
            children = [

                # Top point
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),

                # Upper sides
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 3,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 5,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),

                # Widest row
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 7,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),

                # Lower sides
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 5,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 3,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = WHITE,
                        ),
                    ],
                ),

                # Bottom point
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),
            ],
        ),
    )

# ---------------------------------------------------------
# FILLED BASE INTERIOR
#
# This is added ON TOP of the existing hollow diamond
# only when a runner occupies that base.
# ---------------------------------------------------------

def base_fill(x, y):
    return render.Padding(
        pad = (x + 1, y + 1, 0, 0),
        child = render.Column(
            cross_align = "center",
            children = [
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 7,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 5,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 3,
                    height = 1,
                    color = WHITE,
                ),
                render.Box(
                    width = 1,
                    height = 1,
                    color = WHITE,
                ),
            ],
        ),
    )

# ---------------------------------------------------------
# TEAM ABBREVIATIONS
# ---------------------------------------------------------

def team_abbr(team):
    name = team.get("name", "")

    if name == "Arizona Diamondbacks":
        return "AZ"

    if name == "Atlanta Braves":
        return "ATL"

    if name == "Baltimore Orioles":
        return "BAL"

    if name == "Boston Red Sox":
        return "BOS"

    if name == "Chicago Cubs":
        return "CHC"

    if name == "Chicago White Sox":
        return "CWS"

    if name == "Cincinnati Reds":
        return "CIN"

    if name == "Cleveland Guardians":
        return "CLE"

    if name == "Colorado Rockies":
        return "COL"

    if name == "Detroit Tigers":
        return "DET"

    if name == "Houston Astros":
        return "HOU"

    if name == "Kansas City Royals":
        return "KC"

    if name == "Los Angeles Angels":
        return "LAA"

    if name == "Los Angeles Dodgers":
        return "LAD"

    if name == "Miami Marlins":
        return "MIA"

    if name == "Milwaukee Brewers":
        return "MIL"

    if name == "Minnesota Twins":
        return "MIN"

    if name == "New York Mets":
        return "NYM"

    if name == "New York Yankees":
        return "NYY"

    if name == "Philadelphia Phillies":
        return "PHI"

    if name == "Pittsburgh Pirates":
        return "PIT"

    if name == "San Diego Padres":
        return "SD"

    if name == "San Francisco Giants":
        return "SF"

    if name == "Seattle Mariners":
        return "SEA"

    if name == "St. Louis Cardinals":
        return "STL"

    if name == "Tampa Bay Rays":
        return "TB"

    if name == "Texas Rangers":
        return "TEX"

    if name == "Toronto Blue Jays":
        return "TOR"

    if name == "Washington Nationals":
        return "WSH"

    if name == "Athletics":
        return "ATH"

    return name[:3].upper()

# ---------------------------------------------------------
# GET TODAY'S GAME
#
# Live game gets priority.
# If there is no live game, use the first scheduled game.
# ---------------------------------------------------------

def get_game(selected_team):
    today = time.now().format("2006-01-02")

    params = {
        "sportId": "1",
        "date": today,
        "gameTypes": "R",
    }

    team_ids = {
        "ARI": 109,
        "ATL": 144,
        "BAL": 110,
        "BOS": 111,
        "CHC": 112,
        "CWS": 145,
        "CIN": 113,
        "CLE": 114,
        "COL": 115,
        "DET": 116,
        "HOU": 117,
        "KC": 118,
        "LAA": 108,
        "LAD": 119,
        "MIA": 146,
        "MIL": 158,
        "MIN": 142,
        "NYM": 121,
        "NYY": 147,
        "OAK": 133,
        "PHI": 143,
        "PIT": 134,
        "SD": 135,
        "SF": 137,
        "SEA": 136,
        "STL": 138,
        "TB": 139,
        "TEX": 140,
        "TOR": 141,
        "WSH": 120,
    }

    if selected_team != "AUTO" and selected_team in team_ids:
        params["teamId"] = "%d" % team_ids[selected_team]

    response = http.get(
        SCHEDULE_URL,
        params = params,
        ttl_seconds = 20,
    )

    if response.status_code != 200:
        return None

    data = response.json()
    scheduled_game = None

    for day in data.get("dates", []):
        for game in day.get("games", []):
            state = game.get(
                "status",
                {},
            ).get(
                "abstractGameState",
                "",
            )

            if state == "Live":
                return game

            if (
                state == "Preview" and
                scheduled_game == None
            ):
                scheduled_game = game

    return scheduled_game

# ---------------------------------------------------------
# GET GAME BY MLB GAMEPK
# ---------------------------------------------------------
# Used by CHOOSE GAME mode.
# The live-feed endpoint contains the team/status data needed
# to build the same game structure used by the scoreboard.
# ---------------------------------------------------------

def get_game_by_pk(game_pk):
    response = http.get(
        LIVE_URL % int(game_pk),
        ttl_seconds = 5,
    )

    if response.status_code != 200:
        return None

    data = response.json()
    game_data = data.get("gameData", {})
    live_data = data.get("liveData", {})

    teams = game_data.get("teams", {})
    linescore = live_data.get("linescore", {})
    line_teams = linescore.get("teams", {})

    away_team = teams.get("away", {})
    home_team = teams.get("home", {})
    away_line = line_teams.get("away", {})
    home_line = line_teams.get("home", {})

    status = game_data.get("status", {})

    return {
        "gamePk": int(game_pk),
        "gameDate": game_data.get("datetime", {}).get("dateTime", ""),
        "status": status,
        "teams": {
            "away": {
                "team": away_team,
                "score": away_line.get("runs", 0),
            },
            "home": {
                "team": home_team,
                "score": home_line.get("runs", 0),
            },
        },
    }

# ---------------------------------------------------------
# GET LIVE FEED
# ---------------------------------------------------------

def get_live_feed(game_pk):
    response = http.get(
        LIVE_URL % game_pk,
        ttl_seconds = 5,
    )

    if response.status_code != 200:
        return None

    return response.json()

# ---------------------------------------------------------
# MAIN 64x32 REFERENCE + LIVE DATA
# ---------------------------------------------------------

def main(config):
    selected_team = config.get("team", "AUTO")

    if selected_team == None or selected_team == "":
        selected_team = "AUTO"

    # -----------------------------------------------------
    # Get game
    # -----------------------------------------------------

    selected_mode = config.get("mode", "AUTO")

    if selected_mode == "GAME":
        game_pk_text = config.get("game_pk", "")

        if game_pk_text == None or game_pk_text == "":
            return render.Root(
                child = render.Text(
                    content = "ENTER GAME ID",
                    font = "tb-8",
                    color = WHITE,
                ),
            )

        game = get_game_by_pk(int(game_pk_text))
    else:
        game = get_game(selected_team)

    if game == None:
        return render.Root(
            child = render.Text(
                content = "MLB ERROR",
                font = "tb-8",
                color = WHITE,
            ),
        )

    # -----------------------------------------------------
    # Default values
    # -----------------------------------------------------

    away_team = team_abbr(
        game["teams"]["away"]["team"],
    )

    home_team = team_abbr(
        game["teams"]["home"]["team"],
    )

    away_score = game["teams"]["away"].get(
        "score",
        0,
    )

    home_score = game["teams"]["home"].get(
        "score",
        0,
    )

    inning_text = ""

    balls = 0
    strikes = 0
    outs = 0

    inning_state = ""

    first_occupied = False
    second_occupied = False
    third_occupied = False

    # -----------------------------------------------------
    # Get live information
    # -----------------------------------------------------

    state = game.get(
        "status",
        {},
    ).get(
        "abstractGameState",
        "",
    )

    if state == "Live":
        feed = get_live_feed(
            game["gamePk"],
        )

        if feed != None:
            linescore = (
                feed
                    .get("liveData", {})
                    .get("linescore", {})
            )

            inning = linescore.get(
                "currentInning",
            )

            inning_state = linescore.get(
                "inningState",
                "",
            )

            if inning != None:
                inning_text = "%d" % inning

            balls = linescore.get(
                "balls",
                0,
            )

            strikes = linescore.get(
                "strikes",
                0,
            )

            outs = linescore.get(
                "outs",
                0,
            )

            offense = linescore.get(
                "offense",
                {},
            )

            first_occupied = (
                offense.get("first") != None
            )

            second_occupied = (
                offense.get("second") != None
            )

            third_occupied = (
                offense.get("third") != None
            )

    count_text = "%d-%d" % (
        balls,
        strikes,
    )

    # -----------------------------------------------------
    # FINAL 64x32 LAYOUT
    #
    # Original coordinates are preserved.
    # -----------------------------------------------------

    children = [

        # =========================================
        # ORIGINAL TEAMS + SCORES
        # =========================================
        text_at(
            "COL 0",
            1,
            0,
        ),
        text_at(
            "WAS 2",
            1,
            8,
        ),

        # =========================================
        # ORIGINAL BASES
        # =========================================

        # Second Base — top
        base_diamond(
            44,
            1,
        ),

        # Third Base — left
        base_diamond(
            36,
            10,
        ),

        # First Base — right
        base_diamond(
            52,
            10,
        ),

        # Home Plate — bottom
        base_diamond(
            44,
            19,
        ),

        # =========================================
        # ORIGINAL INNING ARROW + NUMBER
        # =========================================
        up_arrow(
            16,
            20,
        ),
        text_at(
            "1",
            22,
            20,
        ),

        # =========================================
        # ORIGINAL THREE OUT DOTS
        # =========================================
        out_dot(
            27,
            2,
        ),
        out_dot(
            27,
            10,
        ),
        out_dot(
            27,
            18,
        ),

        # =========================================
        # ORIGINAL COUNT
        # =========================================
        text_at(
            "2-1",
            1,
            20,
        ),

        # =================================================
        # LIVE DATA OVERLAY
        #
        # These black boxes cover only the old hardcoded
        # values. The original layout coordinates stay the
        # same.
        # =================================================

        # Away team / score
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Box(
                width = 25,
                height = 8,
                color = BLACK,
            ),
        ),
        text_at(
            "%s %d" % (
                away_team,
                away_score,
            ),
            1,
            0,
        ),

        # Home team / score
        render.Padding(
            pad = (0, 8, 0, 0),
            child = render.Box(
                width = 25,
                height = 8,
                color = BLACK,
            ),
        ),
        text_at(
            "%s %d" % (
                home_team,
                home_score,
            ),
            1,
            8,
        ),

        # Count
        render.Padding(
            pad = (0, 20, 0, 0),
            child = render.Box(
                width = 15,
                height = 12,
                color = BLACK,
            ),
        ),
        text_at(
            count_text,
            1,
            20,
        ),

        # Inning number
        render.Padding(
            pad = (21, 20, 0, 0),
            child = render.Box(
                width = 7,
                height = 12,
                color = BLACK,
            ),
        ),
        text_at(
            inning_text,
            22,
            20,
        ),

        # Arrow cover
        render.Padding(
            pad = (15, 20, 0, 0),
            child = render.Box(
                width = 7,
                height = 8,
                color = BLACK,
            ),
        ),

        # Correct arrow
        (
            up_arrow(16, 22) if inning_state == "Top" else down_arrow(16, 22) if inning_state == "Bottom" else render.Box(
                width = 1,
                height = 1,
            )
        ),

        # =========================================
        # LIVE OUT INDICATORS
        # =========================================
        blank_out_dot(
            27,
            2,
        ),
        blank_out_dot(
            27,
            10,
        ),
        blank_out_dot(
            27,
            18,
        ),

        # Turn the first N indicators back on.
        (
            out_dot(27, 2) if outs >= 1 else render.Box(width = 1, height = 1)
        ),
        (
            out_dot(27, 10) if outs >= 2 else render.Box(width = 1, height = 1)
        ),
        (
            out_dot(27, 18) if outs >= 3 else render.Box(width = 1, height = 1)
        ),

        # =========================================
        # LIVE BASE OCCUPANCY
        # =========================================

        # Second base
        (
            base_fill(44, 1) if second_occupied else render.Box(width = 1, height = 1)
        ),

        # Third base
        (
            base_fill(36, 10) if third_occupied else render.Box(width = 1, height = 1)
        ),

        # First base
        (
            base_fill(52, 10) if first_occupied else render.Box(width = 1, height = 1)
        ),
    ]

    return render.Root(
        child = render.Stack(
            children = children,
        ),
    )

# ---------------------------------------------------------
# DYNAMIC GAME SELECTION
# ---------------------------------------------------------
# When CHOOSE GAME is selected, this builds a dropdown from
# every regular-season MLB game scheduled for today.
# The selected value is the MLB gamePk.
# ---------------------------------------------------------

def get_game_options(mode):
    if mode != "GAME":
        return []

    today = time.now().format("2006-01-02")

    response = http.get(
        SCHEDULE_URL,
        params = {
            "sportId": "1",
            "date": today,
            "gameTypes": "R",
        },
        ttl_seconds = 20,
    )

    if response.status_code != 200:
        return []

    data = response.json()
    options = []

    for day in data.get("dates", []):
        for game in day.get("games", []):
            away = game.get("teams", {}).get("away", {}).get("team", {})
            home = game.get("teams", {}).get("home", {}).get("team", {})
            status = game.get("status", {})

            away_name = team_abbr(away)
            home_name = team_abbr(home)

            state = status.get("abstractGameState", "")
            detail = status.get("detailedState", "")

            if state == "Final":
                status_text = "FINAL"
            elif state == "Live":
                status_text = "LIVE"
            elif detail:
                status_text = detail
            else:
                status_text = "SCHEDULED"

            label = "%s @ %s — %s" % (
                away_name,
                home_name,
                status_text,
            )

            options.append(
                schema.Option(
                    display = label,
                    value = "%d" % game.get("gamePk", 0),
                ),
            )

    return options

# ---------------------------------------------------------
# TIDBYT APP SETTINGS
# ---------------------------------------------------------

def get_schema():
    mode_options = [
        schema.Option(display = "AUTO", value = "AUTO"),
        schema.Option(display = "CHOOSE TEAM", value = "TEAM"),
        schema.Option(display = "CHOOSE GAME", value = "GAME"),
    ]

    team_options = [
        schema.Option(display = "Arizona Diamondbacks", value = "ARI"),
        schema.Option(display = "Atlanta Braves", value = "ATL"),
        schema.Option(display = "Baltimore Orioles", value = "BAL"),
        schema.Option(display = "Boston Red Sox", value = "BOS"),
        schema.Option(display = "Chicago Cubs", value = "CHC"),
        schema.Option(display = "Chicago White Sox", value = "CWS"),
        schema.Option(display = "Cincinnati Reds", value = "CIN"),
        schema.Option(display = "Cleveland Guardians", value = "CLE"),
        schema.Option(display = "Colorado Rockies", value = "COL"),
        schema.Option(display = "Detroit Tigers", value = "DET"),
        schema.Option(display = "Houston Astros", value = "HOU"),
        schema.Option(display = "Kansas City Royals", value = "KC"),
        schema.Option(display = "Los Angeles Angels", value = "LAA"),
        schema.Option(display = "Los Angeles Dodgers", value = "LAD"),
        schema.Option(display = "Miami Marlins", value = "MIA"),
        schema.Option(display = "Milwaukee Brewers", value = "MIL"),
        schema.Option(display = "Minnesota Twins", value = "MIN"),
        schema.Option(display = "New York Mets", value = "NYM"),
        schema.Option(display = "New York Yankees", value = "NYY"),
        schema.Option(display = "Oakland Athletics", value = "OAK"),
        schema.Option(display = "Philadelphia Phillies", value = "PHI"),
        schema.Option(display = "Pittsburgh Pirates", value = "PIT"),
        schema.Option(display = "San Diego Padres", value = "SD"),
        schema.Option(display = "San Francisco Giants", value = "SF"),
        schema.Option(display = "Seattle Mariners", value = "SEA"),
        schema.Option(display = "St. Louis Cardinals", value = "STL"),
        schema.Option(display = "Tampa Bay Rays", value = "TB"),
        schema.Option(display = "Texas Rangers", value = "TEX"),
        schema.Option(display = "Toronto Blue Jays", value = "TOR"),
        schema.Option(display = "Washington Nationals", value = "WSH"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "Choose how the scoreboard selects a game.",
                icon = "baseball",
                default = "AUTO",
                options = mode_options,
            ),
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "Used by CHOOSE TEAM mode.",
                icon = "baseball",
                default = "NYM",
                options = team_options,
            ),
            schema.Generated(
                id = "game_pk",
                source = "mode",
                handler = get_game_options,
            ),
        ],
    )

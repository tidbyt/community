"""
Applet: MLB Next Games
Summary: Next 3 games of your team
Description: Shows upcoming 3 games of the next week for your favorite team!
Author: Anthony Rocchio
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE = "https://statsapi.mlb.com/api/v1/schedule"
GAMES_TO_DISPLAY = 3
FONT = "CG-pixel-3x5-mono"
IMAGE_BASE = "https://a.espncdn.com/i/teamlogos/mlb/500/scoreboard/"
IMAGE_BASE_DARK = "https://a.espncdn.com/i/teamlogos/mlb/500-dark/scoreboard/"

TEAMS = [
    {"name": "Angels", "id": 108, "nick": "LAA", "image": "%slaa.png" % IMAGE_BASE},
    {"name": "Astros", "id": 117, "nick": "HOU", "image": "%shou.png" % IMAGE_BASE},
    {"name": "Athletics", "id": 133, "nick": "ATH", "image": "%soak.png" % IMAGE_BASE_DARK},
    {"name": "Blue Jays", "id": 141, "nick": "TOR", "image": "%stor.png" % IMAGE_BASE},
    {"name": "Braves", "id": 144, "nick": "ATL", "image": "%satl.png" % IMAGE_BASE},
    {"name": "Brewers", "id": 158, "nick": "MIL", "image": "%smil.png" % IMAGE_BASE},
    {"name": "Cardinals", "id": 138, "nick": "STL", "image": "%sstl.png" % IMAGE_BASE_DARK},
    {"name": "Cubs", "id": 112, "nick": "CHC", "image": "%schc.png" % IMAGE_BASE},
    {"name": "Diamondbacks", "id": 109, "nick": "ARI", "image": "%sari.png" % IMAGE_BASE},
    {"name": "Dodgers", "id": 119, "nick": "LAD", "image": "%slad.png" % IMAGE_BASE_DARK},
    {"name": "Giants", "id": 137, "nick": "SF", "image": "%ssf.png" % IMAGE_BASE},
    {"name": "Guardians", "id": 114, "nick": "CLE", "image": "%scle.png" % IMAGE_BASE},
    {"name": "Mariners", "id": 136, "nick": "SEA", "image": "%ssea.png" % IMAGE_BASE},
    {"name": "Marlins", "id": 146, "nick": "MIA", "image": "%smia.png" % IMAGE_BASE},
    {"name": "Mets", "id": 121, "nick": "NYM", "image": "%snym.png" % IMAGE_BASE},
    {"name": "Nationals", "id": 120, "nick": "WSH", "image": "%swsh.png" % IMAGE_BASE},
    {"name": "Orioles", "id": 110, "nick": "BAL", "image": "%sbal.png" % IMAGE_BASE},
    {"name": "Padres", "id": 135, "nick": "SD", "image": "%ssd.png" % IMAGE_BASE_DARK},
    {"name": "Phillies", "id": 143, "nick": "PHI", "image": "%sphi.png" % IMAGE_BASE},
    {"name": "Pirates", "id": 134, "nick": "PIT", "image": "%spit.png" % IMAGE_BASE_DARK},
    {"name": "Rangers", "id": 140, "nick": "TEX", "image": "%stex.png" % IMAGE_BASE},
    {"name": "Rays", "id": 139, "nick": "TB", "image": "%stb.png" % IMAGE_BASE},
    {"name": "Red Sox", "id": 111, "nick": "BOS", "image": "%sbos.png" % IMAGE_BASE},
    {"name": "Reds", "id": 113, "nick": "CIN", "image": "%scin.png" % IMAGE_BASE},
    {"name": "Rockies", "id": 115, "nick": "COL", "image": "%scol.png" % IMAGE_BASE},
    {"name": "Royals", "id": 118, "nick": "KC", "image": "%skc.png" % IMAGE_BASE_DARK},
    {"name": "Tigers", "id": 116, "nick": "DET", "image": "%sdet.png" % IMAGE_BASE},
    {"name": "Twins", "id": 142, "nick": "MIN", "image": "%smin.png" % IMAGE_BASE_DARK},
    {"name": "White Sox", "id": 145, "nick": "CHW", "image": "%schw.png" % IMAGE_BASE_DARK},
    {"name": "Yankees", "id": 147, "nick": "NYY", "image": "%snyy.png" % IMAGE_BASE_DARK},
]

def generate_url_parameters(team, timezone):
    """ Return URL parameters for calling the schedule API 
    Start and End dates are a week apart to ensure up to 3 games are pulled
    """

    team_id = [x["id"] for x in TEAMS if x["name"] == team][0]

    now = time.now().in_location(timezone)
    start_date = now.format("2006-01-02")
    end_date = (now + time.parse_duration("168h")).format("2006-01-02")

    return "?sportId=1&teamId=%s&startDate=%s&endDate=%s" % (team_id, start_date, end_date)

def get_schedule(url):
    """ Query the schedule API, return the json if successful
    otherwise return a blank string for error processing
    """

    res = http.get(url, ttl_seconds = 3600)
    if res.status_code != 200:
        return ""
    return res.json()

def get_date_info(game_day, timezone):
    """ Takes a days game (or games if a doubleheader) and processes and returns as a list """

    games = []  # needs to be a list in case of double header

    for game in game_day["games"]:
        gametime_local = time.parse_time(x = game["gameDate"]).in_location(timezone)
        games.append({
            "date": gametime_local,
            "home_team": {
                "id": game["teams"]["home"]["team"]["id"],
                "name": game["teams"]["home"]["team"]["name"],
            },
            "away_team": {
                "id": game["teams"]["away"]["team"]["id"],
                "name": game["teams"]["away"]["team"]["name"],
            },
        })
    return games

def get_opponent(game, selected_team):
    """ Finds the opponent of the team the user selected by taking the game and finding the other team """

    team_id = [x["id"] for x in TEAMS if x["name"] == selected_team][0]
    if game["home_team"]["id"] == team_id:
        return game["away_team"]["id"]
    return game["home_team"]["id"]

def get_team_logo(id):
    """ Finds a team's logo or returns blank if there's an error """

    url = [x["image"] for x in TEAMS if x["id"] == id][0]
    res = http.get(url, ttl_seconds = 86400)
    if res.status_code != 200:
        return ""
    return res.body()

def create_game_display(game_date, opponent_nickname, logo):
    """ Takes game information and creates a displayable Column """

    if logo == "":
        logo_img = render.Box(width = 12, height = 12, color = "#000")
    else:
        logo_img = render.Image(width = 12, height = 12, src = logo)

    return render.Column(
        main_align = "space_around",
        cross_align = "center",
        expanded = True,
        children = [
            render.Text(content = game_date.format("Mon"), color = "#FFF", font = FONT),
            render.Text(content = game_date.format("3:04"), color = "#FFF", font = FONT),
            logo_img,
            render.Text(content = opponent_nickname, color = "#FFF", font = FONT),
        ],
    )

def main(config):
    team = config.get("team", "Angels")
    timezone = config.get("$tz") or "America/New_York"

    url_params = generate_url_parameters(team, timezone)
    schedule = get_schedule(BASE + url_params)

    games_processed = 0
    game_cols = []

    if schedule == "":  # error occurred while calling API
        game_cols.append(render.WrappedText(content = "Error getting schedule", color = "#FFF", linespacing = 3))
    elif len(schedule["dates"]) == 0:  # no games in time period searched
        return []
    else:
        for game_day in schedule["dates"]:
            todays_games = get_date_info(game_day, timezone)

            for tg in todays_games:
                games_processed += 1
                if games_processed > GAMES_TO_DISPLAY:
                    break
                opponent_id = get_opponent(tg, team)

                opponent_nicknames = [x["nick"] for x in TEAMS if x["id"] == opponent_id]

                if len(opponent_nicknames) > 0:
                    opponent_nickname = opponent_nicknames[0]
                    logo = get_team_logo(opponent_id)
                else:
                    opponent_nickname = "TBD"
                    logo = ""

                game_cols.append(create_game_display(tg["date"], opponent_nickname, logo))

            if games_processed > GAMES_TO_DISPLAY:
                break

    return render.Root(
        delay = 500,
        child = render.Row(
            main_align = "space_around",
            expanded = True,
            children = game_cols,
        ),
    )

def get_schema():
    options = []
    for team in TEAMS:
        options.append(
            schema.Option(
                display = team["name"],
                value = team["name"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team Name",
                desc = "Select your team.",
                icon = "baseball",
                default = options[0].value,
                options = options,
            ),
        ],
    )

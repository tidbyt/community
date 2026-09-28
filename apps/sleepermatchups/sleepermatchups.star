"""
Applet: Sleeper Matchups
Summary: Live fantasy scoreboard
Description: Display two configurable Sleeper fantasy football matchups with full-screen live scores, projections, win percentages, and adjustable rotation speed.
Author: lrella4597
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API = "https://api.sleeper.app/v1"
DEFAULT_USERNAME = ""
DEFAULT_LEAGUE_ONE = ""
DEFAULT_LEAGUE_TWO = ""
BG = "#000000"
WHITE = "#f7f8fa"
MINE = "#12e5b5"
THEIRS = "#ff174f"
MUTED = "#aeb7c4"
FINAL = "#bec3ca"
PANEL = "#050f1c"
MINE_PANEL = "#052622"
THEIRS_PANEL = "#2d0a14"
ESPN_SCOREBOARD = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
TEAM_ALIASES = {"JAC": "JAX", "WAS": "WSH", "LA": "LAR"}

def get_json(path):
    response = http.get(API + path)
    if response.status_code != 200:
        return None
    return response.json()

def get_url_json(url):
    response = http.get(url)
    if response.status_code != 200:
        return None
    return response.json()

def cached_json(key, path, ttl):
    saved = cache.get(key)
    if saved != None:
        return json.decode(saved)
    value = get_json(path)
    if value != None:
        cache.set(key, json.encode(value), ttl_seconds = ttl)
    return value

def clean_name(value):
    if not value:
        return "TEAM"
    first = str(value).upper().split(" ")[0]
    output = ""
    for index in range(len(first)):
        character = first[index]
        if character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
            output += character
    return (output or "TEAM")[:5]

def team_name(roster, users):
    owner = roster.get("owner_id")
    for user in users:
        if user.get("user_id") == owner:
            metadata = user.get("metadata") or {}
            return metadata.get("team_name") or user.get("display_name") or "TEAM"
    return "TEAM"

def team_record(roster):
    settings = roster.get("settings") or {}
    return "%d-%d" % (int(settings.get("wins") or 0), int(settings.get("losses") or 0))

def rounded_score(value):
    return str(int(float(value or 0) + 0.5))

def clamp(value, minimum, maximum):
    return min(maximum, max(minimum, value))

def projection_field(scoring):
    receptions = float((scoring or {}).get("rec") or 0)
    if receptions >= 0.75:
        return "pts_ppr"
    if receptions >= 0.25:
        return "pts_half_ppr"
    return "pts_std"

def final_teams(scoreboard):
    output = {}
    for event in (scoreboard or {}).get("events") or []:
        status = event.get("status") or {}
        completed = ((status.get("type") or {}).get("completed") == True)
        for competition in event.get("competitions") or []:
            for competitor in competition.get("competitors") or []:
                abbreviation = str(((competitor.get("team") or {}).get("abbreviation") or "")).upper()
                if abbreviation:
                    output[abbreviation] = completed
    return output

def lineup_projection(matchup, projections, players, scoring, teams_final):
    field = projection_field(scoring)
    total = 0.0
    all_final = True
    starters = matchup.get("starters") or []
    players_points = matchup.get("players_points") or {}
    if not starters:
        return [0, False]
    for player_id in starters:
        player_id = str(player_id)
        actual = float(players_points.get(player_id) or 0)
        player_projection = projections.get(player_id) or {}
        player = players.get(player_id) or {}
        projected = float(player_projection.get(field) or 0)
        team = str(player_projection.get("team") or player.get("team") or player_id).upper()
        team = TEAM_ALIASES.get(team) or team
        is_final = teams_final.get(team) == True
        if not is_final:
            all_final = False
        total += actual if is_final else max(actual, projected)
    return [int(total + 0.5), all_final]

def win_percent(mine_score, mine_projection, their_score, their_projection):
    if mine_projection == mine_score and their_projection == their_score:
        return 99 if mine_score > their_score else 1 if mine_score < their_score else 50
    return clamp(50 + int((mine_projection - their_projection) * 2), 1, 99)

def matchup_for_league(user_id, league_id, week, projections, players, teams_final):
    if not league_id:
        return None
    league = cached_json("league:" + league_id, "/league/" + league_id, 21600)
    rosters = cached_json("rosters:" + league_id, "/league/" + league_id + "/rosters", 900)
    users = cached_json("users:" + league_id, "/league/" + league_id + "/users", 21600)
    matchups = get_json("/league/" + league_id + "/matchups/" + str(week))
    if not league or not rosters or not users or not matchups:
        return None

    mine = None
    for roster in rosters:
        if roster.get("owner_id") == user_id or user_id in (roster.get("co_owners") or []):
            mine = roster
    if mine == None:
        return None

    my_matchup = None
    for item in matchups:
        if int(item.get("roster_id") or 0) == int(mine.get("roster_id") or 0):
            my_matchup = item
    if my_matchup == None or my_matchup.get("matchup_id") == None:
        return None

    opponent_matchup = None
    for item in matchups:
        if item.get("matchup_id") == my_matchup.get("matchup_id") and int(item.get("roster_id") or 0) != int(mine.get("roster_id") or 0):
            opponent_matchup = item
    if opponent_matchup == None:
        return None

    opponent = None
    for roster in rosters:
        if int(roster.get("roster_id") or 0) == int(opponent_matchup.get("roster_id") or 0):
            opponent = roster
    if opponent == None:
        return None

    scoring = league.get("scoring_settings") or {}
    my_projection = lineup_projection(my_matchup, projections, players, scoring, teams_final)
    their_projection = lineup_projection(opponent_matchup, projections, players, scoring, teams_final)
    my_score = int(float(my_matchup.get("points") or 0) + 0.5)
    their_score = int(float(opponent_matchup.get("points") or 0) + 0.5)
    mine_win = win_percent(my_score, my_projection[0], their_score, their_projection[0])

    return {
        "league": str(league.get("name") or "SLEEPER")[:12].upper(),
        "mine": clean_name(team_name(mine, users)),
        "theirs": clean_name(team_name(opponent, users)),
        "mine_score": str(my_score),
        "their_score": str(their_score),
        "mine_projection": "-" if my_projection[1] else "P" + str(my_projection[0]),
        "their_projection": "-" if their_projection[1] else "P" + str(their_projection[0]),
        "mine_final": my_projection[1],
        "their_final": their_projection[1],
        "mine_win": mine_win,
        "their_win": 100 - mine_win,
    }

def matchup_frame(item, mine_color, their_color):
    mine_width = clamp((64 * item["mine_win"]) // 100, 1, 63)
    names = render.Row(children = [
        render.Box(width = 32, height = 7, color = MINE_PANEL, child = render.Text(content = item["mine"], font = "tb-8", color = WHITE, height = 7)),
        render.Box(width = 32, height = 7, color = THEIRS_PANEL, child = render.Text(content = item["theirs"], font = "tb-8", color = WHITE, height = 7)),
    ])
    scores = render.Row(children = [
        render.Box(width = 31, height = 7, color = PANEL, child = render.Text(content = item["mine_score"], font = "tb-8", color = FINAL if item["mine_final"] else WHITE, height = 7)),
        render.Box(width = 2, height = 1, color = MUTED),
        render.Box(width = 31, height = 7, color = PANEL, child = render.Text(content = item["their_score"], font = "tb-8", color = FINAL if item["their_final"] else WHITE, height = 7)),
    ])
    projections = render.Row(children = [
        render.Box(width = 31, height = 5, color = PANEL, child = render.Text(content = item["mine_projection"], font = "tom-thumb", color = MUTED, height = 5)),
        render.Box(width = 2, height = 5, color = PANEL),
        render.Box(width = 31, height = 5, color = PANEL, child = render.Text(content = item["their_projection"], font = "tom-thumb", color = MUTED, height = 5)),
    ])
    chances = render.Row(children = [
        render.Box(width = 31, height = 5, color = PANEL, child = render.Text(content = str(item["mine_win"]) + "%", font = "tom-thumb", color = mine_color, height = 5)),
        render.Box(width = 2, height = 5, color = PANEL),
        render.Box(width = 31, height = 5, color = PANEL, child = render.Text(content = str(item["their_win"]) + "%", font = "tom-thumb", color = their_color, height = 5)),
    ])
    progress = render.Row(children = [
        render.Box(width = mine_width, height = 2, color = mine_color),
        render.Box(width = 64 - mine_width, height = 2, color = their_color),
    ])
    return render.Box(width = 64, height = 32, color = PANEL, child = render.Column(
        cross_align = "center",
        children = [
            names,
            render.Box(width = 64, height = 1, color = PANEL),
            scores,
            render.Box(width = 64, height = 2, color = PANEL),
            projections,
            render.Box(width = 64, height = 1, color = PANEL),
            chances,
            render.Box(width = 64, height = 2, color = PANEL),
            progress,
        ],
    ))

def error_frame(message):
    return render.Box(width = 64, height = 32, color = PANEL, child = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(content = "SLEEPER", color = MINE),
            render.Text(content = message, font = "tb-8", color = WHITE),
            render.Text(content = "CHECK SETTINGS", color = MUTED),
        ],
    ))

def main(config):
    username = config.get("username", DEFAULT_USERNAME)
    league_one = config.get("league_one", DEFAULT_LEAGUE_ONE)
    league_two = config.get("league_two", DEFAULT_LEAGUE_TWO)
    rotation_speed = int(config.get("rotation_speed", "20"))
    mine_color = config.get("mine_color", MINE)
    their_color = config.get("their_color", THEIRS)

    if not username:
        demo = {
            "mine": "MINE",
            "theirs": "OPP",
            "mine_score": "101",
            "their_score": "98",
            "mine_projection": "P112",
            "their_projection": "P105",
            "mine_final": False,
            "their_final": False,
            "mine_win": 64,
            "their_win": 36,
        }
        return render.Root(child = matchup_frame(demo, mine_color, their_color))

    state = get_json("/state/nfl")
    user = cached_json("user:" + username, "/user/" + username, 21600)
    if not state or not user:
        return render.Root(child = error_frame("USER NOT FOUND"))

    week = int(state.get("week") or 1)
    season = str(state.get("league_season") or state.get("season") or "")
    season_type = "post" if str(state.get("season_type") or "regular").lower() in ["post", "postseason"] else "regular"
    projections = get_json("/projections/nfl/" + season_type + "/" + season + "/" + str(week)) or {}

    # Sleeper recommends caching its bulk player map for at least one day.
    players = cached_json("players:nfl", "/players/nfl", 86400) or {}
    espn_season_type = "3" if season_type == "post" else "2"
    scoreboard = get_url_json(ESPN_SCOREBOARD + "?dates=" + season + "&seasontype=" + espn_season_type + "&week=" + str(week)) or {}
    teams_final = final_teams(scoreboard)
    user_id = user.get("user_id")
    frames = []
    for league_id in [league_one, league_two]:
        item = matchup_for_league(user_id, league_id, week, projections, players, teams_final)
        if item != None:
            frames.append(matchup_frame(item, mine_color, their_color))
    if not frames:
        frames = [error_frame("NO MATCHUP")]

    return render.Root(
        delay = rotation_speed * 1000,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def league_options(username):
    user = cached_json("schema-user:" + username, "/user/" + username, 21600)
    if not user:
        return []
    state = get_json("/state/nfl")
    season = str((state or {}).get("league_season") or "")
    leagues = get_json("/user/" + user["user_id"] + "/leagues/nfl/" + season) or []
    output = []
    for league in leagues:
        output.append(schema.Option(display = league["name"], value = league["league_id"]))
    return output

def first_league(username):
    options = league_options(username)
    if not options:
        return []
    return [schema.Dropdown(
        id = "league_one",
        name = "First League",
        desc = "Choose the first matchup",
        icon = "football",
        options = options,
        default = options[0].value,
    )]

def second_league(username):
    options = league_options(username)
    if not options:
        return []
    return [schema.Dropdown(
        id = "league_two",
        name = "Second League",
        desc = "Choose the second matchup",
        icon = "football",
        options = options,
        default = options[0].value,
    )]

ROTATION_OPTIONS = [
    schema.Option(display = "10 seconds", value = "10"),
    schema.Option(display = "15 seconds", value = "15"),
    schema.Option(display = "20 seconds", value = "20"),
    schema.Option(display = "30 seconds", value = "30"),
]

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(
            id = "username",
            name = "Sleeper Username",
            desc = "Enter your Sleeper username",
            icon = "user",
            default = DEFAULT_USERNAME,
        ),
        schema.Generated(id = "first_league_picker", source = "username", handler = first_league),
        schema.Generated(id = "second_league_picker", source = "username", handler = second_league),
        schema.Dropdown(
            id = "rotation_speed",
            name = "Rotation Speed",
            desc = "Seconds per matchup",
            icon = "clock",
            default = "20",
            options = ROTATION_OPTIONS,
        ),
        schema.Color(
            id = "mine_color",
            name = "My Score Color",
            desc = "Color for your team",
            icon = "brush",
            default = MINE,
        ),
        schema.Color(
            id = "their_color",
            name = "Opponent Color",
            desc = "Color for the opponent",
            icon = "brush",
            default = THEIRS,
        ),
    ])

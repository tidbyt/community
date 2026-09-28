"""
Applet: Sleeper Matchups
Summary: Two live fantasy scores
Description: Display two configurable head-to-head Sleeper fantasy football matchups with live scores and adjustable rotation speed.
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

def get_json(path):
    response = http.get(API + path)
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
    return (output or "TEAM")[:4]

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

def matchup_for_league(user_id, league_id, week):
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

    return {
        "league": str(league.get("name") or "SLEEPER")[:12].upper(),
        "mine": clean_name(team_name(mine, users)),
        "theirs": clean_name(team_name(opponent, users)),
        "mine_score": rounded_score(my_matchup.get("points")),
        "their_score": rounded_score(opponent_matchup.get("points")),
        "mine_record": team_record(mine),
        "their_record": team_record(opponent),
        "week": "W" + str(week),
    }

def matchup_frame(item, mine_color, their_color):
    names = render.Box(width = 58, height = 7, child = render.Row(children = [
        render.Box(width = 29, height = 7, child = render.Text(content = item["mine"], font = "tb-8", color = WHITE, height = 7)),
        render.Box(width = 29, height = 7, child = render.Text(content = item["theirs"], font = "tb-8", color = WHITE, height = 7)),
    ]))
    scores = render.Box(width = 58, height = 13, child = render.Row(children = [
        render.Box(width = 25, height = 13, child = render.Text(content = item["mine_score"], font = "6x13", color = mine_color, height = 13)),
        render.Box(width = 8, height = 13, child = render.Text(content = item["week"], font = "tom-thumb", color = MUTED)),
        render.Box(width = 25, height = 13, child = render.Text(content = item["their_score"], font = "6x13", color = their_color, height = 13)),
    ]))
    records = render.Box(width = 58, height = 5, child = render.Row(children = [
        render.Box(width = 29, height = 5, child = render.Text(content = item["mine_record"], color = mine_color)),
        render.Box(width = 29, height = 5, child = render.Text(content = item["their_record"], color = their_color)),
    ]))
    league = render.Box(width = 58, height = 5, child = render.Text(content = item["league"], color = MUTED))
    return render.Box(width = 64, height = 32, color = BG, padding = 1, child = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [names, scores, records, league],
    ))

def error_frame(message):
    return render.Box(width = 64, height = 32, color = BG, child = render.Column(
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
            "league": "DEMO LEAGUE",
            "mine": "MINE",
            "theirs": "OPP",
            "mine_score": "101",
            "their_score": "98",
            "mine_record": "2-1",
            "their_record": "1-2",
            "week": "W3",
        }
        return render.Root(child = matchup_frame(demo, mine_color, their_color))

    state = get_json("/state/nfl")
    user = cached_json("user:" + username, "/user/" + username, 21600)
    if not state or not user:
        return render.Root(child = error_frame("USER NOT FOUND"))

    week = int(state.get("week") or 1)
    user_id = user.get("user_id")
    frames = []
    for league_id in [league_one, league_two]:
        item = matchup_for_league(user_id, league_id, week)
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

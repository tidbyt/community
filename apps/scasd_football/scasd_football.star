"""
Applet: SCASD Football
Summary: SCASD Football Score
Description: SCASD PA LIVE SCORING.
Author: pahsfootball
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")

# --- CONFIGURATION ---
MY_TEAM_ABV = "SCA" 
DATA_URL = "https://pahsfootball-d35c2-default-rtdb.firebaseio.com/games.json"
# ---------------------

def main(config):
    # 1. Fetch data
    rep = http.get(DATA_URL, ttl_seconds=60)
    
    if rep.status_code != 200:
        return fail("HTTP Error: " + str(rep.status_code))
    
    # 2. Parse JSON safely
    data = rep.json()
    
    if data == None:
        return render_standby("NO DATA FOUND")

    # 3. Normalize Data (Handle List vs Dict)
    games_list = []
    
    if type(data) == "dict":
        games_list = data.values()
    elif type(data) == "list":
        games_list = data
    else:
        return fail("INVALID DATA TYPE")

    # 4. Find Active Game
    display_game = None
    
    # Priority: LIVE > HALF > PREGAME > FINAL > UPCOMING
    for game in games_list:
        if not game or type(game) != "dict": continue
        status = str(get_value_robust(game, ["status", "Status"], "UPCOMING")).upper()
        if status in ["PREGAME", "HALF", "LIVE"]:
            display_game = game
            break
            
    # Loop 2: If nothing active, just show the first valid game
    if not display_game and len(games_list) > 0:
        for game in games_list:
            if game and type(game) == "dict":
                display_game = game
                break

    if not display_game: 
        return render_standby("NO GAMES")

    # 5. Extract Data safely
    home_text = get_value_robust(display_game, ["habv", "HABV", "home", "Home", "Team1"], "HOME")
    away_text = get_value_robust(display_game, ["aabv", "AABV", "away", "Away", "Team2"], "AWAY")
    message_text = str(get_value_robust(display_game, ["message", "Message", "msg"], "")).upper()
    
    # Colors (Sanitized to prevent crashes)
    h1 = sanitize_color(get_value_robust(display_game, ["color1", "Color1", "HomeColor"], "#333333"))
    a1 = sanitize_color(get_value_robust(display_game, ["awayc1", "AwayC1", "AwayColor"], "#ffffff"))
    h2 = sanitize_color(get_value_robust(display_game, ["color2", "Color2", "HomeSecondary"], "#ffffff"))
    a2 = sanitize_color(get_value_robust(display_game, ["awayc2", "AwayC2", "AwaySecondary"], "#000000"))
    
    # Scores
    raw_home = str(get_value_robust(display_game, ["homescore", "homeScore", "HomeScore"], "0"))
    raw_away = str(get_value_robust(display_game, ["awayscore", "awayScore", "AwayScore"], "0"))
    
    home_score_str = clean_score(raw_home)
    away_score_str = clean_score(raw_away)
    
    # Game State
    status = str(get_value_robust(display_game, ["status", "Status"], "LIVE")).upper()
    clock = str(get_value_robust(display_game, ["clock", "Clock", "time", "Time"], "00:00")).upper()
    quarter = str(get_value_robust(display_game, ["quarter", "Quarter"], "1")).upper()
    if quarter.endswith(".0"): quarter = quarter[:-2]

    # 6. Fireworks Logic
    show_fireworks = False
    
    h_int = int(home_score_str) if home_score_str.isdigit() else 0
    a_int = int(away_score_str) if away_score_str.isdigit() else 0
    
    my_score = -1
    if str(home_text).upper() == MY_TEAM_ABV: my_score = h_int
    elif str(away_text).upper() == MY_TEAM_ABV: my_score = a_int
    
    if my_score > 0:
        cached_score = cache.get("my_team_last_score")
        if cached_score != None:
            if my_score > int(cached_score):
                show_fireworks = True
        cache.set("my_team_last_score", str(my_score), ttl_seconds=86400)

    # 7. Build Widgets
    scoreboard_widget = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # TOP ROW (Teams)
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Box(width=26, height=10, color=h1, child=render.Text(content=truncate(home_text), color=h2, font="tb-8")),
                    render.Text(content="vs", color="#666", font="tom-thumb"),
                    render.Box(width=26, height=10, color=a1, child=render.Text(content=truncate(away_text), color=a2, font="tb-8")),
                ],
            ),
            # MIDDLE ROW (Scores)
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(content=home_score_str, font="6x13", color="#ffffff"),
                    render.Box(width=1, height=10, color="#333"),
                    render.Text(content=away_score_str, font="6x13", color="#ffffff"),
                ],
            ),
            # BOTTOM ROW (Status/Message)
            render_status_bar(status, clock, quarter, message_text)
        ]
    )

    if show_fireworks:
        return render.Root(
            delay = 100, 
            child = render_fireworks_sequence(scoreboard_widget, h1) 
        )
    else:
        return render.Root(child = scoreboard_widget)

# --- HELPERS ---

def get_value_robust(game, keys, default):
    if not game: return default
    for key in keys:
        val = game.get(key)
        if val != None: return val
    return default

def clean_score(s):
    if s.endswith(".0"): s = s[:-2]
    return s.upper()

def truncate(name):
    if not name: return "??"
    name = str(name)
    if len(name) > 4: return name[:4].upper()
    return name.upper()

def sanitize_color(c):
    if not c: return "#888888"
    c = str(c).lower().strip() # Remove spaces
    
    # Handle the specific error found
    if c == "#n/a" or c == "n/a" or c == "#N/A": return "#888888"
    
    if c == "transparent": return "#222"
    
    # Must start with # and be length 4 (#FFF) or 7 (#FFFFFF)
    if c.startswith("#"):
        if len(c) == 4 or len(c) == 7:
            return c
            
    # Fallback for anything else (named colors, weird formats)
    return "#888888" 

def render_status_bar(status, clock, quarter, message):
    if message and len(message) > 0:
        child = None
        if len(message) < 16:
            child = render.Row(
                expanded=True, main_align="center", cross_align="center",
                children=[render.Text(content=message, font="CG-pixel-3x5-mono", color="#ffff00")]
            )
        else:
            child = render.Marquee(
                width=64,
                child=render.Text(content=message, font="CG-pixel-3x5-mono", color="#ffff00")
            )
        return render.Box(width=64, height=8, color="#222", child=child)

    content = ""
    color = "#fff"
    
    if status == "FINAL":
        content = "FINAL"
        color = "#ff4444"
    elif status == "HALF":
        content = "HALFTIME"
        color = "#ffff00"
    elif status == "PREGAME":
        content = "PREGAME"
        color = "#00ff00"
    else:
        content = "Q" + quarter + " " + clock
    
    return render.Box(
        width=64, height=8, color="#222",
        child=render.Padding(
            pad=(0,1,0,0),
            child=render.Text(content=content, font="CG-pixel-3x5-mono", color=color)
        )
    )

def render_standby(msg):
    return render.Root(
        child = render.Box(
            child = render.Text(msg, font="tb-8", color="#facc15")
        )
    )

def fail(msg):
    return render.Root(
        child=render.WrappedText(content=msg, color="#ff0000")
    )

def render_fireworks_sequence(final_widget, team_color):
    frames = []
    frames.append(render.Box(width=64, height=32, color="#000", child=render.Box(width=2, height=2, color="#fff")))
    frames.append(render.Box(width=64, height=32, color="#000", child=render.Text("SCORE!", font="tb-8", color=team_color)))
    for _ in range(30):
        frames.append(final_widget)
    return render.Animation(children=frames)

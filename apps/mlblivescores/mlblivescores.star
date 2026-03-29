load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")

TEAMS = {
    "108": "LAA", "109": "ARI", "110": "BAL", "111": "BOS",
    "112": "CHC", "113": "CIN", "114": "CLE", "115": "COL",
    "116": "DET", "117": "HOU", "118": "KC",  "119": "LAD",
    "120": "WSH", "121": "NYM", "133": "OAK", "134": "PIT",
    "135": "SD",  "136": "SEA", "137": "SF",  "138": "STL",
    "139": "TB",  "140": "TEX", "141": "TOR", "142": "MIN",
    "143": "PHI", "144": "ATL", "145": "CWS", "146": "MIA",
    "147": "NYY", "158": "MIL",
}

TEAM_NAMES = {
    "108": "Angels",    "109": "D-backs",   "110": "Orioles",
    "111": "Red Sox",   "112": "Cubs",      "113": "Reds",
    "114": "Guardians", "115": "Rockies",   "116": "Tigers",
    "117": "Astros",    "118": "Royals",    "119": "Dodgers",
    "120": "Nationals", "121": "Mets",      "133": "Athletics",
    "134": "Pirates",   "135": "Padres",    "136": "Mariners",
    "137": "Giants",    "138": "Cardinals", "139": "Rays",
    "140": "Rangers",   "141": "Blue Jays", "142": "Twins",
    "143": "Phillies",  "144": "Braves",    "145": "White Sox",
    "146": "Marlins",   "147": "Yankees",   "158": "Brewers",
}

MLB_SCHEDULE_URL = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=%s&date=%s&hydrate=team,linescore,flags,liveLookin,person,probablePitcher,lineups"
MLB_LIVE_URL = "https://statsapi.mlb.com/api/v1.1/game/%s/feed/live"
MLB_BOXSCORE_URL = "https://statsapi.mlb.com/api/v1/game/%s/boxscore"

COLOR_WHITE  = "#FFFFFF"
COLOR_YELLOW = "#FFD700"
COLOR_ORANGE = "#FF5910"
COLOR_GRAY   = "#888888"
COLOR_DIM    = "#444444"
COLOR_BLACK  = "#000000"
COLOR_CYAN   = "#00FFFF"
COLOR_GREEN  = "#00FF00"
COLOR_RED    = "#FF4444"
COLOR_BALL   = "#00CC00"
COLOR_STRIKE = "#FF4444"

def get_today():
    now = time.now().in_location("America/New_York")
    return now.format("2006-01-02")

def truncate(s, n):
    if len(s) > n:
        return s[:n]
    return s

def pad_right(s, n):
    for _ in range(n - len(s)):
        s = s + " "
    return s

def safe_get(d, *keys):
    cur = d
    for k in keys:
        if cur == None:
            return None
        if type(cur) == "dict":
            cur = cur.get(k)
        elif type(cur) == "list":
            if type(k) == "int" and k < len(cur):
                cur = cur[k]
            else:
                return None
        else:
            return None
    return cur

def last_name(full):
    if full == None or full == "":
        return ""
    parts = full.split(" ")
    if len(parts) > 1:
        return parts[-1]
    return full

def format_game_time(game_time_utc):
    if game_time_utc == "" or game_time_utc == None:
        return "TBD"
    t = time.parse_time(game_time_utc)
    eastern = t.in_location("America/New_York")
    return eastern.format("3:04 PM")

def fetch_todays_game(team_id):
    cache_key = "mlb_game_" + str(team_id)
    cached = cache.get(cache_key)
    if cached != None:
        return cached
    today = get_today()
    url = MLB_SCHEDULE_URL % (team_id, today)
    resp = http.get(url, ttl_seconds=60)
    if resp.status_code != 200:
        return None
    data = resp.json()
    dates = safe_get(data, "dates")
    if dates == None or len(dates) == 0:
        return None
    games = safe_get(dates, 0, "games")
    if games == None or len(games) == 0:
        return None
    game_pk = str(safe_get(games, 0, "gamePk"))
    if game_pk == "None" or game_pk == "":
        return None
    cache.set(cache_key, game_pk, ttl_seconds=3600)
    return game_pk

def fetch_live(game_pk):
    resp = http.get(MLB_LIVE_URL % game_pk, ttl_seconds=10)
    if resp.status_code != 200:
        return None
    return resp.json()

def fetch_boxscore(game_pk):
    resp = http.get(MLB_BOXSCORE_URL % game_pk, ttl_seconds=30)
    if resp.status_code != 200:
        return None
    return resp.json()

def parse_all(data, box):
    g = {}
    g["status_code"] = safe_get(data, "gameData", "status", "abstractGameCode") or "P"
    g["detailed"]    = safe_get(data, "gameData", "status", "detailedState") or ""
    g["is_delayed"]  = "Delay" in g["detailed"] or "Suspended" in g["detailed"]
    g["away_abbr"] = safe_get(data, "gameData", "teams", "away", "abbreviation") or "AWY"
    g["home_abbr"] = safe_get(data, "gameData", "teams", "home", "abbreviation") or "HME"
    g["game_time_utc"] = safe_get(data, "gameData", "datetime", "dateTime") or ""
    g["game_time"]     = format_game_time(g["game_time_utc"])
    away_prob = safe_get(data, "gameData", "probablePitchers", "away", "fullName") or ""
    home_prob = safe_get(data, "gameData", "probablePitchers", "home", "fullName") or ""
    g["away_probable"] = truncate(last_name(away_prob), 9)
    g["home_probable"] = truncate(last_name(home_prob), 9)
    ls = safe_get(data, "liveData", "linescore") or {}
    g["away_score"] = safe_get(ls, "teams", "away", "runs")   or 0
    g["home_score"] = safe_get(ls, "teams", "home", "runs")   or 0
    g["away_hits"]  = safe_get(ls, "teams", "away", "hits")   or 0
    g["home_hits"]  = safe_get(ls, "teams", "home", "hits")   or 0
    g["away_err"]   = safe_get(ls, "teams", "away", "errors") or 0
    g["home_err"]   = safe_get(ls, "teams", "home", "errors") or 0
    g["inning"]      = safe_get(ls, "currentInning") or 0
    g["inning_half"] = safe_get(ls, "inningHalf")    or "Top"
    g["outs"]        = safe_get(ls, "outs")          or 0
    offense = safe_get(ls, "offense") or {}
    g["base1"] = 1 if offense.get("first")  != None else 0
    g["base2"] = 1 if offense.get("second") != None else 0
    g["base3"] = 1 if offense.get("third")  != None else 0
    current_play = safe_get(data, "liveData", "plays", "currentPlay") or {}
    count = safe_get(current_play, "count") or {}
    g["balls"]   = count.get("balls")   or 0
    g["strikes"] = count.get("strikes") or 0
    matchup = safe_get(current_play, "matchup") or {}
    g["pitcher"]   = truncate(last_name(safe_get(matchup, "pitcher", "fullName") or ""), 10)
    g["batter"]    = truncate(last_name(safe_get(matchup, "batter",  "fullName") or ""), 10)
    g["last_play"] = safe_get(current_play, "result", "description") or ""
    decisions = safe_get(data, "liveData", "decisions") or {}
    g["winner_pitcher"] = last_name(safe_get(decisions, "winner", "fullName") or "")
    g["loser_pitcher"]  = last_name(safe_get(decisions, "loser",  "fullName") or "")
    g["save_pitcher"]   = last_name(safe_get(decisions, "save",   "fullName") or "")
    g["top_batters"] = []
    if box != None:
        away_batters = safe_get(box, "teams", "away", "batters") or []
        home_batters = safe_get(box, "teams", "home", "batters") or []
        away_players = safe_get(box, "teams", "away", "players") or {}
        home_players = safe_get(box, "teams", "home", "players") or {}
        stars = []
        for pid in away_batters + home_batters:
            key = "ID" + str(pid)
            p = away_players.get(key) or home_players.get(key)
            if p == None:
                continue
            name  = last_name(safe_get(p, "person", "fullName") or "")
            stats = safe_get(p, "stats", "batting") or {}
            hits  = stats.get("hits")     or 0
            hr    = stats.get("homeRuns") or 0
            rbi   = stats.get("rbi")      or 0
            ab    = stats.get("atBats")   or 0
            if ab == 0:
                continue
            parts = []
            if hr > 0:
                parts.append(str(hr) + "HR")
            if hits > 0:
                parts.append(str(hits) + "H")
            if rbi > 0:
                parts.append(str(rbi) + "RBI")
            if len(parts) > 0 and (hr > 0 or hits >= 2 or rbi >= 2):
                stars.append(name + " " + "/".join(parts))
        g["top_batters"] = stars[:4]
    all_plays = safe_get(data, "liveData", "plays", "allPlays") or []
    highlights = []
    for play in all_plays:
        event = safe_get(play, "result", "event") or ""
        desc  = safe_get(play, "result", "description") or ""
        if event == "Home Run":
            highlights.append("HR: " + truncate(desc, 30))
        elif event == "Double" or event == "Triple":
            if "score" in desc.lower() or "rbi" in desc.lower():
                highlights.append(event[:2] + ": " + truncate(desc, 28))
        elif event == "Strikeout":
            outs_val = safe_get(play, "count", "outs") or 0
            if outs_val == 3 and safe_get(play, "about", "isComplete") == True:
                highlights.append("K: " + truncate(desc, 30))
    g["highlights"] = highlights
    away_lu = safe_get(data, "gameData", "lineups", "awayPlayers") or []
    home_lu = safe_get(data, "gameData", "lineups", "homePlayers") or []
    g["away_lineup"] = [truncate(last_name(safe_get(p, "fullName") or ""), 11) for p in away_lu[:9]]
    g["home_lineup"] = [truncate(last_name(safe_get(p, "fullName") or ""), 11) for p in home_lu[:9]]
    return g

def make_dot(filled, color_on, size=3):
    return render.Box(width=size, height=size, color=color_on if filled else COLOR_DIM)

def dot_row(values, color_on, size=3, gap=1):
    children = []
    for i, v in enumerate(values):
        if i > 0:
            children.append(render.Box(width=gap, height=size, color=COLOR_BLACK))
        children.append(make_dot(v == 1, color_on, size))
    return render.Row(children=children)

def render_pregame(g, my_color):
    matchup   = "%s @ %s  %s" % (g["away_abbr"], g["home_abbr"], g["game_time"])
    prob_line = "SP: %s / %s" % (g["away_probable"], g["home_probable"])
    away_lu = " ".join(g["away_lineup"]) if len(g["away_lineup"]) > 0 else ""
    home_lu = " ".join(g["home_lineup"]) if len(g["home_lineup"]) > 0 else ""
    lineup_text = ""
    if away_lu != "":
        lineup_text = g["away_abbr"] + ": " + away_lu
    if home_lu != "":
        sep = "   " if lineup_text != "" else ""
        lineup_text = lineup_text + sep + g["home_abbr"] + ": " + home_lu
    if lineup_text == "":
        lineup_text = "Lineups TBA"
    return render.Root(
        delay=50,
        child=render.Column(
            expanded=True, main_align="start", cross_align="start",
            children=[
                render.Text(content=matchup,    color=COLOR_WHITE, font="CG-pixel-3x5-mono"),
                render.Box(height=1),
                render.Text(content=prob_line,  color=COLOR_CYAN,  font="CG-pixel-3x5-mono"),
                render.Box(height=1),
                render.Text(content="Game Day!", color=my_color,   font="CG-pixel-3x5-mono"),
                render.Box(height=2),
                render.Marquee(width=64, child=render.Text(content=lineup_text, color=COLOR_GRAY, font="CG-pixel-3x5-mono"), offset_start=64, offset_end=0),
            ],
        ),
    )

def render_live(g, my_color, is_home):
    away_color = my_color if not is_home else COLOR_WHITE
    home_color = my_color if is_home     else COLOR_WHITE
    score_row = render.Row(children=[
        render.Text(content="%s %s" % (g["away_abbr"], str(g["away_score"])), color=away_color, font="CG-pixel-3x5-mono"),
        render.Text(content="  ", color=COLOR_WHITE, font="CG-pixel-3x5-mono"),
        render.Text(content="%s %s" % (g["home_abbr"], str(g["home_score"])), color=home_color, font="CG-pixel-3x5-mono"),
    ])
    arrow = "v" if g["inning_half"] == "Bottom" else "^"
    dly   = " DLY" if g["is_delayed"] else ""
    inning_row = render.Text(content="%s %s%s" % (arrow, str(g["inning"]), dly), color=COLOR_CYAN, font="CG-pixel-3x5-mono")
    outs_vals = [1 if i < g["outs"] else 0 for i in range(3)]
    ob_row = render.Row(children=[
        dot_row(outs_vals, COLOR_WHITE),
        render.Box(width=3, height=3, color=COLOR_BLACK),
        make_dot(g["base1"] == 1, my_color),
        render.Box(width=1, height=3, color=COLOR_BLACK),
        make_dot(g["base2"] == 1, my_color),
        render.Box(width=1, height=3, color=COLOR_BLACK),
        make_dot(g["base3"] == 1, my_color),
        render.Box(width=3, height=3, color=COLOR_BLACK),
        dot_row([1 if i < g["balls"] else 0 for i in range(4)], COLOR_BALL, size=2, gap=1),
        render.Box(width=2, height=3, color=COLOR_BLACK),
        dot_row([1 if i < g["strikes"] else 0 for i in range(3)], COLOR_STRIKE, size=2, gap=1),
    ])
    matchup_row = render.Text(content="P:%s B:%s" % (truncate(g["pitcher"], 7), truncate(g["batter"], 7)), color=COLOR_GRAY, font="CG-pixel-3x5-mono")
    last_play = g["last_play"] if g["last_play"] != "" else "Waiting..."
    scroll_row = render.Marquee(width=64, child=render.Text(content="Last: " + last_play, color=COLOR_WHITE, font="CG-pixel-3x5-mono"), offset_start=64, offset_end=0)
    return render.Root(
        delay=50,
        child=render.Column(
            expanded=True, main_align="start", cross_align="start",
            children=[score_row, render.Box(height=1), inning_row, render.Box(height=1), ob_row, render.Box(height=1), matchup_row, render.Box(height=1), scroll_row],
        ),
    )

def render_final(g, my_color, is_home):
    away_color   = my_color if not is_home else COLOR_WHITE
    home_color   = my_color if is_home     else COLOR_WHITE
    my_score     = g["home_score"] if is_home else g["away_score"]
    opp_score    = g["away_score"] if is_home else g["home_score"]
    won          = my_score > opp_score
    result_color = COLOR_GREEN if won else COLOR_RED
    result_word  = "W" if won else "L"
    header_row = render.Row(children=[
        render.Text(content="FINAL ", color=COLOR_YELLOW, font="CG-pixel-3x5-mono"),
        render.Text(content="%s %s" % (g["away_abbr"], str(g["away_score"])), color=away_color, font="CG-pixel-3x5-mono"),
        render.Text(content="  ", color=COLOR_WHITE, font="CG-pixel-3x5-mono"),
        render.Text(content="%s %s" % (g["home_abbr"], str(g["home_score"])), color=home_color, font="CG-pixel-3x5-mono"),
        render.Text(content=" " + result_word, color=result_color, font="CG-pixel-3x5-mono"),
    ])
    rhe_label = render.Text(content="    R  H  E", color=COLOR_GRAY, font="CG-pixel-3x5-mono")
    away_rhe  = render.Text(content="%s %s  %s  %s" % (pad_right(g["away_abbr"],3), pad_right(str(g["away_score"]),2), pad_right(str(g["away_hits"]),2), str(g["away_err"])), color=away_color, font="CG-pixel-3x5-mono")
    home_rhe  = render.Text(content="%s %s  %s  %s" % (pad_right(g["home_abbr"],3), pad_right(str(g["home_score"]),2), pad_right(str(g["home_hits"]),2), str(g["home_err"])), color=home_color, font="CG-pixel-3x5-mono")
    parts = []
    if g["winner_pitcher"] != "":
        pitch_str = "W: " + g["winner_pitcher"] + "  L: " + g["loser_pitcher"]
        if g["save_pitcher"] != "":
            pitch_str = pitch_str + "  SV: " + g["save_pitcher"]
        parts.append(pitch_str)
    if len(g["top_batters"]) > 0:
        parts.append("Stars: " + "  ".join(g["top_batters"]))
    for hl in g["highlights"][:5]:
        parts.append(hl)
    if len(parts) == 0:
        parts = ["Game over"]
    scroll_row = render.Marquee(width=64, child=render.Text(content="   |   ".join(parts), color=COLOR_YELLOW, font="CG-pixel-3x5-mono"), offset_start=64, offset_end=0)
    return render.Root(
        delay=50,
        child=render.Column(
            expanded=True, main_align="start", cross_align="start",
            children=[header_row, render.Box(height=1), rhe_label, away_rhe, home_rhe, render.Box(height=1), scroll_row],
        ),
    )

def render_no_game(abbr, my_color):
    return render.Root(
        child=render.Column(
            expanded=True, main_align="center", cross_align="center",
            children=[
                render.Text(content=abbr, color=my_color, font="6x13"),
                render.Box(height=2),
                render.Text(content="No game today", color=COLOR_GRAY, font="CG-pixel-3x5-mono"),
            ],
        ),
    )

def render_loading(abbr, my_color):
    return render.Root(
        child=render.Column(
            expanded=True, main_align="center", cross_align="center",
            children=[
                render.Text(content=abbr, color=my_color, font="6x13"),
                render.Box(height=2),
                render.Text(content="Loading...", color=COLOR_GRAY, font="CG-pixel-3x5-mono"),
            ],
        ),
    )

def get_schema():
    options = []
    for tid, abbr in TEAMS.items():
        name = TEAM_NAMES.get(tid, abbr)
        options.append(schema.Option(display=abbr + " — " + name, value=tid))
    return schema.Schema(
        version="1",
        fields=[
            schema.Dropdown(
                id="team_id",
                name="Team",
                desc="Select your MLB team",
                icon="baseball",
                default="121",
                options=options,
            ),
        ],
    )

def main(config):
    team_id  = config.get("team_id") or "121"
    abbr     = TEAMS.get(team_id, "NYM")
    my_color = COLOR_ORANGE

    game_pk = fetch_todays_game(team_id)
    if game_pk == None:
        return render_no_game(abbr, my_color)

    data = fetch_live(game_pk)
    if data == None:
        return render_loading(abbr, my_color)

    box = fetch_boxscore(game_pk)
    g   = parse_all(data, box)

    home_id = str(safe_get(data, "gameData", "teams", "home", "id") or "")
    is_home = home_id == team_id

    status = g["status_code"]
    if status == "P":
        return render_pregame(g, my_color)
    elif status == "F":
        return render_final(g, my_color, is_home)
    else:
        return render_live(g, my_color, is_home)

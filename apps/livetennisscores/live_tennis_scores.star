"""
Applet: Live Tennis
Summary: Live tennis point scores
Description: Live point-by-point tennis scores across ATP, WTA, Challenger and ITF tours. Shows sets, games, current points, tiebreaks and the current server for every live match. Requires a free Live Tennis API key.
Author: bensynapse

v1.0
Initial version. Rotates through the live matches (one match per page) with a
tour-coloured tournament header, per-player rows (server dot, sets won, games
in the current set, current point), tiebreak highlighting, a completed-set
summary line, and explicit no-key / no-match / API-error states.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# ---------------------------------------------------------------------------
# API + caching
#
# The Live Tennis API free tier allows 1,000 requests/day. Tidbyt renders
# server-side far more often than that, so we must never fetch on every
# render. http.get(ttl_seconds = ...) uses Pixlet's built-in HTTP cache
# (keyed on URL + headers), which is the caching mechanism the Tidbyt docs
# recommend over the cache module. With a 120s TTL a given key/tour
# combination performs at most 86400 / 120 = 720 upstream requests per day,
# comfortably inside the 1,000/day free quota, while still being fresh
# enough for point-by-point scores (a tennis point plus the rest between
# points runs ~30-45s).
# ---------------------------------------------------------------------------
API_BASE = "https://api.livetennisapi.com/api/public/v1"
CACHE_TTL_SECONDS = 120
MATCH_LIMIT = 8

FREE_KEY_URL = "livetennisapi.com/subscribe/free"

# CG-pixel-3x5-mono keeps the numeric columns aligned; tom-thumb is the
# narrowest legible proportional font, which buys us room for player names.
NUM_FONT = "CG-pixel-3x5-mono"
NAME_FONT = "tom-thumb"

# Both fonts advance 4px per character, so 64px is exactly 16 characters and
# the name column (64px less the 4px serving dot and the 22px score block) is
# 9. Measured with `pixlet render`, not assumed.
NAME_CHARS = 9
LINE_CHARS = 16

COLOR_HEADER_FG = "#e6ffe6"
COLOR_ROUND = "#cfe4cf"
COLOR_NAME = "#ffffff"
COLOR_NAME_DIM = "#9a9a9a"
COLOR_RANK = "#7f8c8d"
COLOR_SERVER_DOT = "#00c853"
COLOR_SETS = "#ffffff"
COLOR_GAMES = "#5aa9f0"
COLOR_POINTS = "#ffd400"
COLOR_TIEBREAK = "#ff8c00"
COLOR_MUTED = "#8c8c8c"
COLOR_LIVE = "#ff3b3b"
COLOR_ERROR = "#ff5555"

# Header background doubles as the tour indicator, which costs zero pixels.
TOUR_BG = {
    "atp": "#123a6b",
    "wta": "#5c1250",
    "challenger": "#6b3a12",
    "itf": "#3a3a3a",
}
DEFAULT_HEADER_BG = "#0a3d1e"

# Tokens stripped when shortening a tournament name to fit 64px.
TOUR_TOKENS = ["atp", "wta", "itf", "challenger", "masters", "tour"]

# "No live match" subtitles, each kept inside the 16-character line width.
SCOPE_LABEL = {
    "all": "across all tours",
    "atp": "on the ATP tour",
    "wta": "on the WTA tour",
    "challenger": "on Challengers",
    "itf": "on ITF events",
}

def main(config):
    api_key = config.str("api_key", "").strip()
    if not api_key:
        return render.Root(child = missing_key_screen())

    speed = config.str("speed", "3")
    show_rank = config.bool("show_rank", False)
    tour = config.str("tour", "all")

    url = base_url(config) + "/matches?status=live&limit=%d" % MATCH_LIMIT
    if tour != "all":
        url += "&tour=" + tour

    res = http.get(
        url = url,
        headers = {"x-api-key": api_key},
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    if res.status_code == 401:
        return render.Root(child = message_screen(
            "BAD KEY",
            ["Key was rejected", "Check it in the", "app settings"],
            COLOR_ERROR,
        ))
    if res.status_code == 429:
        return render.Root(child = message_screen(
            "OVER QUOTA",
            ["Your API key hit", "its rate limit", "Retrying soon"],
            COLOR_TIEBREAK,
        ))
    if res.status_code != 200:
        return render.Root(child = message_screen(
            "API ERROR",
            ["Live Tennis API", "gave HTTP %d" % res.status_code, "Retrying soon"],
            COLOR_ERROR,
        ))

    body = json.decode(res.body(), None)
    if type(body) != "dict" or type(body.get("data")) != "list":
        return render.Root(child = message_screen(
            "BAD DATA",
            ["Unexpected reply", "from the Live", "Tennis API"],
            COLOR_ERROR,
        ))

    matches = []
    for m in body["data"]:
        # The live feed briefly keeps matches that have just finished; a
        # non-null winner means the match is over, so don't rotate it.
        if type(m) == "dict" and m.get("winner") == None:
            matches.append(m)

    if len(matches) == 0:
        return render.Root(child = idle_screen(tour))

    if len(matches) == 1:
        # A single match gets the whole render, so the tournament name can
        # scroll instead of being abbreviated.
        return render.Root(child = match_page(matches[0], show_rank, True))

    # render.Animation shows one child per frame, so each page is static and
    # the tournament name has to fit; delay controls how long each is shown.
    pages = []
    for m in matches[:MATCH_LIMIT]:
        pages.append(match_page(m, show_rank, False))

    return render.Root(
        show_full_animation = True,
        delay = int(speed) * 1000,
        child = render.Animation(children = pages),
    )

def base_url(config):
    # Not exposed in the schema: lets `pixlet render` point the app at a local
    # fixture server so the render paths can be tested without a real key or
    # a live match. Restricted to loopback so it can never redirect a real
    # installation's traffic (and API keys) to a third-party host.
    dev = config.str("dev_api_base", "")
    if dev.startswith("http://127.0.0.1:") or dev.startswith("http://localhost:"):
        return dev
    return API_BASE

# ---------------------------------------------------------------------------
# Match page
# ---------------------------------------------------------------------------

def match_page(m, show_rank, scroll_header):
    score = m.get("score")
    if type(score) != "dict":
        score = {}

    players = m.get("players")
    if type(players) != "dict":
        players = {}

    has_score = len(score) > 0
    sets = as_pair(score.get("sets"), 0)
    points = as_pair(score.get("points"), "-")
    games = score.get("games")
    if type(games) != "list" or len(games) < 2:
        games = [[], []]
    server = score.get("server")
    is_tiebreak = score.get("is_tiebreak") == True

    return render.Column(
        children = [
            header_bar(m, players, scroll_header),
            render.Box(width = 64, height = 1),
            player_row(players.get("p1"), sets[0], games, 0, points[0], server == 1, is_tiebreak, show_rank, has_score),
            render.Box(width = 64, height = 1),
            player_row(players.get("p2"), sets[1], games, 1, points[1], server == 2, is_tiebreak, show_rank, has_score),
            render.Box(width = 64, height = 1),
            footer_row(games, is_tiebreak, has_score),
        ],
    )

def header_bar(m, players, scroll_header):
    tournament = safe_str(m.get("tournament"), "Tennis")
    match_round = safe_str(m.get("round"), "")

    if scroll_header:
        text = tournament
        if match_round:
            text += " - " + match_round
        child = render.Marquee(
            width = 64,
            offset_start = 8,
            child = render.Text(content = text, color = COLOR_HEADER_FG, font = NAME_FONT),
        )
    else:
        # tom-thumb is 4px per character, so budget the 64px row explicitly:
        # 1px pad + name + 1px gap + round + 1px pad.
        budget = (64 - 3 - 4 * len(match_round)) // 4
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Text(
                        content = short_tournament(tournament)[:budget],
                        color = COLOR_HEADER_FG,
                        font = NAME_FONT,
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 1, 0),
                    child = render.Text(content = match_round, color = COLOR_ROUND, font = NAME_FONT),
                ),
            ],
        )

    return render.Box(width = 64, height = 7, color = tour_color(players), child = child)

def player_row(player, sets_won, games, idx, pts, serving, is_tiebreak, show_rank, has_score):
    if type(player) != "dict":
        player = {}

    # An unfilled slot (qualifier / lucky loser not yet decided) has a null name.
    raw_name = safe_str(player.get("name"), "")
    if raw_name:
        name = surname(raw_name)
        name_color = COLOR_NAME
    else:
        name = "TBD"
        name_color = COLOR_NAME_DIM

    # The name column is 64px minus the 4px serving dot and the 22px score
    # block, i.e. 38px = 9 tom-thumb characters, shared with the ranking.
    rank = player.get("ranking")
    name_cells = []
    budget = NAME_CHARS
    if show_rank and type(rank) == "int" and rank > 0:
        rank_text = str(rank)
        budget = NAME_CHARS - 1 - len(rank_text)
        if budget < 3:
            budget = 3
        name_cells.append(render.Padding(
            pad = (2, 0, 0, 0),
            child = render.Text(content = rank_text, color = COLOR_RANK, font = NAME_FONT),
        ))

    name_cells.insert(0, render.Text(content = name[:budget], color = name_color, font = NAME_FONT))

    if serving:
        dot = render.Box(width = 2, height = 2, color = COLOR_SERVER_DOT)
    else:
        dot = render.Box(width = 2, height = 2)

    if has_score:
        score_cells = [
            score_cell(str(sets_won), COLOR_SETS, 6),
            score_cell(str(current_games(games, idx)), COLOR_GAMES, 6),
            score_cell(str(pts), COLOR_TIEBREAK if is_tiebreak else COLOR_POINTS, 10),
        ]
    else:
        score_cells = [render.Box(width = 22, height = 7)]

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [render.Padding(pad = (1, 2, 1, 2), child = dot)] + name_cells,
            ),
            render.Row(cross_align = "center", children = score_cells),
        ],
    )

def score_cell(content, color, width):
    return render.Box(
        width = width,
        height = 7,
        child = render.Text(content = content, color = color, font = NUM_FONT),
    )

def footer_row(games, is_tiebreak, has_score):
    if not has_score:
        return render.Box(
            width = 64,
            height = 7,
            child = render.Text(content = "About to start", color = COLOR_MUTED, font = NUM_FONT),
        )

    if is_tiebreak:
        status_text = "TB"
        status_color = COLOR_TIEBREAK
    else:
        status_text = "LIVE"
        status_color = COLOR_LIVE

    # Completed sets, e.g. "6-3 4-6" - everything before the set in play.
    # Only the most recent sets that still fit next to the status label are
    # shown; extended final sets ("13-11") are wide, so budget by character.
    p1 = games[0] if type(games[0]) == "list" else []
    p2 = games[1] if type(games[1]) == "list" else []
    finished = min(len(p1), len(p2)) - 1
    parts = []
    for i in range(finished):
        parts.append("%s-%s" % (p1[i], p2[i]))

    budget = (64 - 4 - 4 * len(status_text)) // 4
    summary = ""
    for part in reversed(parts):
        candidate = part if not summary else part + " " + summary
        if len(candidate) > budget:
            break
        summary = candidate

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Padding(
                pad = (1, 0, 0, 0),
                child = render.Text(content = summary, color = COLOR_MUTED, font = NUM_FONT),
            ),
            render.Padding(
                pad = (0, 0, 1, 0),
                child = render.Text(content = status_text, color = status_color, font = NUM_FONT),
            ),
        ],
    )

# ---------------------------------------------------------------------------
# Idle / error / onboarding screens
# ---------------------------------------------------------------------------

def title_bar(text):
    return render.Box(
        width = 64,
        height = 7,
        color = DEFAULT_HEADER_BG,
        child = render.Text(content = text, color = COLOR_HEADER_FG, font = NAME_FONT),
    )

def idle_screen(tour):
    scope = SCOPE_LABEL.get(tour, "across all tours")
    return message_screen("NO MATCHES", ["Nothing is live", scope, "Checking again"], COLOR_NAME)

def missing_key_screen():
    # The sign-up URL lives in the schema field description, where the user can
    # actually act on it; 64px is too narrow to print a URL legibly.
    return message_screen(
        "NEED A KEY",
        ["Add a free Live", "Tennis API key", "in app settings"],
        COLOR_POINTS,
    )

def message_screen(title, lines, title_color):
    # Deliberately static (no Marquee): the app has to render in well under a
    # second for `pixlet check`, and a scrolling line costs ~300 extra frames.
    children = [
        title_bar("LIVE TENNIS"),
        render.Box(
            width = 64,
            height = 7,
            child = render.Text(content = title[:LINE_CHARS], color = title_color, font = NUM_FONT),
        ),
    ]
    for line in lines[:3]:
        children.append(render.Box(
            width = 64,
            height = 6,
            child = render.Text(content = line[:LINE_CHARS], color = COLOR_MUTED, font = NAME_FONT),
        ))

    return render.Column(children = children)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def safe_str(value, fallback):
    # Every string field in the feed is nullable (unfilled draw slots, matches
    # with no score yet), so never let a None reach render.Text.
    if type(value) == "string" and value:
        return value
    return fallback

def as_pair(value, default):
    if type(value) == "list" and len(value) >= 2:
        a = value[0] if value[0] != None else default
        b = value[1] if value[1] != None else default
        return [a, b]
    return [default, default]

def current_games(games, idx):
    side = games[idx] if type(games[idx]) == "list" else []
    if len(side) > 0 and side[-1] != None:
        return side[-1]
    return 0

def surname(name):
    # "Carlos Alcaraz" -> "Alcaraz"; an already-abbreviated "C. Alcaraz" and a
    # single-token name both survive unchanged.
    parts = name.split(" ")
    if len(parts) > 1:
        return parts[-1]
    return name

def short_tournament(name):
    # "ATP Masters 1000 Toronto" -> "Toronto", "ITF W35 Monastir" -> "Monastir",
    # while "Wimbledon" and "US Open" are left alone.
    kept = []
    for token in name.split(" "):
        low = token.lower()
        if low in TOUR_TOKENS:
            continue
        if is_tier_token(low):
            continue
        kept.append(token)
    if len(kept) == 0:
        return name
    return " ".join(kept)

def is_tier_token(token):
    # Drops "1000", "500", "250", "125" and ITF grades like "w35" / "m25".
    body = token
    if body.startswith("w") or body.startswith("m"):
        body = body[1:]
    if len(body) == 0:
        return False
    return body.isdigit()

def tour_color(players):
    for key in ["p1", "p2"]:
        player = players.get(key)
        if type(player) == "dict":
            tour = safe_str(player.get("tour"), "").lower()
            if tour in TOUR_BG:
                return TOUR_BG[tour]
    return DEFAULT_HEADER_BG

# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

def get_schema():
    tour_options = [
        schema.Option(display = "All tours", value = "all"),
        schema.Option(display = "ATP", value = "atp"),
        schema.Option(display = "WTA", value = "wta"),
        schema.Option(display = "Challenger", value = "challenger"),
        schema.Option(display = "ITF", value = "itf"),
    ]

    speed_options = [
        schema.Option(display = "3 seconds", value = "3"),
        schema.Option(display = "4 seconds", value = "4"),
        schema.Option(display = "5 seconds", value = "5"),
        schema.Option(display = "6 seconds", value = "6"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "Your Live Tennis API key. Free keys (1,000 requests/day) at " + FREE_KEY_URL,
                icon = "key",
            ),
            schema.Dropdown(
                id = "tour",
                name = "Tour",
                desc = "Which tour's live matches to show",
                icon = "filter",
                default = tour_options[0].value,
                options = tour_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Rotation speed",
                desc = "How long each live match stays on screen",
                icon = "gauge",
                default = speed_options[0].value,
                options = speed_options,
            ),
            schema.Toggle(
                id = "show_rank",
                name = "Show rankings",
                desc = "Show each player's tour ranking next to their name",
                icon = "rankingStar",
                default = False,
            ),
        ],
    )

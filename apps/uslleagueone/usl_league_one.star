"""
Applet: USL League One
Summary: League One scores
Description: Displays live, recent, and upcoming USL League One matches for your selected team.
Author: jruasap
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API = "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.usl.l1/scoreboard"
CACHE_TTL_SECONDS = 60
LOGO_CACHE_TTL_SECONDS = 86400
DEFAULT_TEAM_ID = "131582"
DEFAULT_TIMEZONE = "America/New_York"
LOOKBACK_DAYS = 14
LOOKAHEAD_DAYS = 45

# Keep this mapping in one place so seasonal membership changes are easy to update.
TEAM_DATA = {
    "22526": ["AV Alta FC", "ALT", "#13322B"],
    "131581": ["Athletic Club Boise", "BOI", "#616233"],
    "17826": ["Charlotte Independence", "CLT", "#076AED"],
    "20000": ["Chattanooga Red Wolves", "CRW", "#7C2629"],
    "20671": ["Corpus Christi FC", "CCFC", "#C60000"],
    "22525": ["FC Naples", "NAP", "#1B365D"],
    "131580": ["Fort Wayne FC", "FOR", "#7D623C"],
    "19995": ["Forward Madison FC", "MAD", "#11A9D8"],
    "19964": ["Greenville Triumph", "GRE", "#4D8208"],
    "131582": ["New York Cosmos", "COS", "#296D23"],
    "21821": ["One Knoxville SC", "KNX", "#071D49"],
    "22528": ["Portland Hearts of Pine", "POR", "#1D3C34"],
    "17545": ["Richmond Kickers", "RIC", "#D8172B"],
    "22542": ["Sarasota Paradise", "SAR", "#167D78"],
    "22130": ["Spokane Velocity FC", "SPV", "#007DA8"],
    "20684": ["Union Omaha", "OMA", "#2B2B2B"],
    "22524": ["Westchester SC", "WCH", "#0047BB"],
}

TEAM_OPTIONS = [
    schema.Option(display = "New York Cosmos", value = "131582"),
    schema.Option(display = "AV Alta FC", value = "22526"),
    schema.Option(display = "Athletic Club Boise", value = "131581"),
    schema.Option(display = "Charlotte Independence", value = "17826"),
    schema.Option(display = "Chattanooga Red Wolves", value = "20000"),
    schema.Option(display = "Corpus Christi FC", value = "20671"),
    schema.Option(display = "FC Naples", value = "22525"),
    schema.Option(display = "Fort Wayne FC", value = "131580"),
    schema.Option(display = "Forward Madison FC", value = "19995"),
    schema.Option(display = "Greenville Triumph", value = "19964"),
    schema.Option(display = "One Knoxville SC", value = "21821"),
    schema.Option(display = "Portland Hearts of Pine", value = "22528"),
    schema.Option(display = "Richmond Kickers", value = "17545"),
    schema.Option(display = "Sarasota Paradise", value = "22542"),
    schema.Option(display = "Spokane Velocity FC", value = "22130"),
    schema.Option(display = "Union Omaha", value = "20684"),
    schema.Option(display = "Westchester SC", value = "22524"),
]

def main(config):
    team_id = config.str("team", DEFAULT_TEAM_ID)
    timezone = config.str("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    data = fetch_scoreboard(now)
    if data == None:
        return render_message(team_id, "SCORES UNAVAILABLE", "TRY AGAIN SOON")

    event = select_event(data.get("events", []), team_id)
    if event == None:
        return render_message(team_id, "NO MATCH FOUND", "CHECK BACK SOON")

    match = parse_event(event, team_id)
    if match == None:
        return render_message(team_id, "MATCH DATA ERROR", "SCORE HIDDEN")

    return render_match(match, timezone, now)

def fetch_scoreboard(now):
    start = now - time.parse_duration("%dh" % (LOOKBACK_DAYS * 24))
    end = now + time.parse_duration("%dh" % (LOOKAHEAD_DAYS * 24))
    url = API + "?limit=100&dates=" + start.format("20060102") + "-" + end.format("20060102")
    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return None

    body = response.body()

    # Starlark has no exception handling around json.decode, so reject obvious
    # HTML, empty responses, and unrelated JSON before decoding.
    if len(body) < 2 or not body.startswith("{") or body.find("\"events\"") < 0:
        return None
    return json.decode(body)

def event_for_team(event, team_id):
    competitions = event.get("competitions", [])
    if len(competitions) == 0:
        return False
    competitors = competitions[0].get("competitors", [])
    for competitor in competitors:
        if str(competitor.get("team", {}).get("id", "")) == team_id:
            return True
    return False

def status_name(event):
    return event.get("status", {}).get("type", {}).get("name", "")

def status_state(event):
    return event.get("status", {}).get("type", {}).get("state", "")

def is_special_status(event):
    name = status_name(event)
    return name.find("POSTPONED") >= 0 or name.find("CANCELED") >= 0 or name.find("CANCELLED") >= 0 or name.find("DELAYED") >= 0 or name.find("SUSPENDED") >= 0

def is_completed(event):
    status = event.get("status", {}).get("type", {})
    return status.get("completed", False) or (status.get("state", "") == "post" and not is_special_status(event))

def select_event(events, team_id):
    live = []
    completed = []
    upcoming = []
    special = []
    for event in events:
        if not event_for_team(event, team_id):
            continue
        state = status_state(event)
        if state == "in" and not is_special_status(event):
            live.append(event)
        elif is_completed(event):
            completed.append(event)
        elif state == "pre" and not is_special_status(event):
            upcoming.append(event)
        else:
            special.append(event)

    if len(live) > 0:
        return live[0]
    if len(completed) > 0:
        return newest_event(completed)
    if len(upcoming) > 0:
        return oldest_event(upcoming)
    if len(special) > 0:
        return oldest_event(special)
    return None

def newest_event(events):
    selected = events[0]
    for event in events[1:]:
        if event.get("date", "") > selected.get("date", ""):
            selected = event
    return selected

def oldest_event(events):
    selected = events[0]
    for event in events[1:]:
        if event.get("date", "9999") < selected.get("date", "9999"):
            selected = event
    return selected

def order_competitors(competitors):
    if len(competitors) < 2:
        return None
    home = None
    away = None
    for competitor in competitors:
        if competitor.get("homeAway", "") == "home":
            home = competitor
        elif competitor.get("homeAway", "") == "away":
            away = competitor
    if home == None or away == None:
        # ESPN's soccer scoreboard currently returns home first. This fallback
        # is only used if homeAway metadata is unexpectedly omitted.
        home = competitors[0]
        away = competitors[1]
    return [away, home]

def clean_score(value):
    text = str(value)
    if len(text) == 0:
        return None
    for index in range(len(text)):
        char = text[index]
        if char not in "0123456789":
            return None
    return text

def team_label(competitor):
    team = competitor.get("team", {})
    if str(team.get("id", "")) == DEFAULT_TEAM_ID:
        return "NY COSMOS"
    abbreviation = team.get("abbreviation", "")
    if len(abbreviation) > 0:
        return abbreviation[:4].upper()
    name = team.get("shortDisplayName", team.get("displayName", "TEAM"))
    return name[:4].upper()

def team_label_font(competitor):
    if str(competitor.get("team", {}).get("id", "")) == DEFAULT_TEAM_ID:
        return "CG-pixel-3x5-mono"
    return "tb-8"

def classify_result(selected, opponent):
    if selected.get("winner", False):
        return "W"
    if opponent.get("winner", False):
        return "L"
    selected_score = clean_score(selected.get("score", ""))
    opponent_score = clean_score(opponent.get("score", ""))
    if selected_score == None or opponent_score == None:
        return ""
    if int(selected_score) > int(opponent_score):
        return "W"
    if int(selected_score) < int(opponent_score):
        return "L"
    return "D"

def match_status(event):
    status = event.get("status", {}).get("type", {})
    name = status.get("name", "")
    if name.find("POSTPONED") >= 0:
        return "postponed"
    if name.find("CANCELED") >= 0 or name.find("CANCELLED") >= 0:
        return "canceled"
    if name.find("DELAYED") >= 0:
        return "delayed"
    if name.find("SUSPENDED") >= 0:
        return "suspended"
    if status.get("state", "") == "in":
        return "live"
    if is_completed(event):
        return "final"
    if status.get("state", "") == "pre":
        return "upcoming"
    return "unknown"

def parse_event(event, team_id):
    competitions = event.get("competitions", [])
    if len(competitions) == 0:
        return None
    ordered = order_competitors(competitions[0].get("competitors", []))
    if ordered == None:
        return None

    selected = None
    opponent = None
    for competitor in ordered:
        if str(competitor.get("team", {}).get("id", "")) == team_id:
            selected = competitor
        else:
            opponent = competitor
    if selected == None or opponent == None:
        return None

    state = match_status(event)
    show_score = state == "live" or state == "final"
    selected_score = show_score and clean_score(selected.get("score", "")) or None
    opponent_score = show_score and clean_score(opponent.get("score", "")) or None
    if show_score and (selected_score == None or opponent_score == None):
        return None

    return {
        "date": event.get("date", ""),
        "detail": event.get("status", {}).get("type", {}).get("shortDetail", ""),
        "state": state,
        "result": state == "final" and classify_result(selected, opponent) or "",
        "away": ordered[0],
        "home": ordered[1],
        "selected_id": team_id,
    }

def format_kickoff(date, timezone, now):
    if len(date) == 0:
        return "TBD"
    kickoff = time.parse_time(date, format = "2006-01-02T15:04Z").in_location(timezone)
    if kickoff.format("20060102") == now.format("20060102"):
        return "TODAY " + kickoff.format("3:04P")
    return kickoff.format("Mon 3:04P").upper()

def compact_live_detail(detail):
    value = detail.upper().replace("1ST HALF", "1H").replace("2ND HALF", "2H")
    value = value.replace("HALFTIME", "HT").replace("EXTRA TIME", "ET")
    value = value.replace("PENALTIES", "PENS")
    if len(value) > 10:
        return value[:10]
    return value

def header_text(match, timezone, now):
    state = match["state"]
    if state == "live":
        detail = compact_live_detail(match["detail"])
        return len(detail) > 0 and "LIVE " + detail or "LIVE"
    if state == "final":
        result = match["result"]
        detail = compact_live_detail(match["detail"])
        suffix = "FINAL"
        if detail.find("PEN") >= 0:
            suffix = "FINAL PK"
        elif detail == "AET" or detail.find("ET") >= 0:
            suffix = "FINAL ET"
        return len(result) > 0 and result + " " + suffix or suffix
    if state == "upcoming":
        return format_kickoff(match["date"], timezone, now)
    if state == "postponed":
        return "POSTPONED"
    if state == "canceled":
        return "CANCELED"
    if state == "delayed":
        return "DELAYED"
    if state == "suspended":
        return "SUSPENDED"
    return "STATUS TBD"

def row_score(match, competitor):
    if match["state"] != "live" and match["state"] != "final":
        return "-"
    score = clean_score(competitor.get("score", ""))
    return score == None and "?" or score

def score_color(match, competitor):
    competitor_id = str(competitor.get("team", {}).get("id", ""))
    if competitor_id != match["selected_id"] or match["state"] != "final":
        return "#FFFFFF"
    if match["result"] == "W":
        return "#9CFF57"
    if match["result"] == "L":
        return "#FF6570"
    if match["result"] == "D":
        return "#FFD65A"
    return "#FFFFFF"

def fetch_team_logo(competitor):
    team = competitor.get("team", {})
    logo_url = team.get("logo", "")
    if len(logo_url) == 0:
        team_id = str(team.get("id", ""))
        if len(team_id) == 0:
            return None
        logo_url = "https://a.espncdn.com/i/teamlogos/soccer/500/%s.png" % team_id
    if logo_url.startswith("https://a.espncdn.com/"):
        logo_url = logo_url.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 1) + "&h=24&w=24"
    response = http.get(url = logo_url, ttl_seconds = LOGO_CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return None
    return response.body()

def render_team_logo(competitor):
    logo = fetch_team_logo(competitor)
    if logo == None:
        return render.Box(width = 13, height = 12)
    return render.Box(
        width = 13,
        height = 12,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.Image(logo, width = 10, height = 10)],
        ),
    )

def render_team_row(match, competitor):
    competitor_id = str(competitor.get("team", {}).get("id", ""))
    selected = competitor_id == match["selected_id"]
    accent = TEAM_DATA.get(competitor_id, ["", "", "#6FAE3F"])[2]
    background = selected and "#13241D" or "#0C1017"
    return render.Box(
        width = 64,
        height = 12,
        color = background,
        child = render.Row(
            expanded = True,
            cross_align = "center",
            children = [
                render.Box(width = 2, height = 12, color = selected and accent or "#202731"),
                render_team_logo(competitor),
                render.Box(
                    width = 37,
                    height = 12,
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Box(width = 1, height = 1),
                            render.Text(content = team_label(competitor), font = team_label_font(competitor), color = selected and "#FFFFFF" or "#B7C0CA"),
                        ],
                    ),
                ),
                render.Box(
                    width = 12,
                    height = 12,
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [render.Text(content = row_score(match, competitor), font = "Dina_r400-6", color = score_color(match, competitor))],
                    ),
                ),
            ],
        ),
    )

def render_match(match, timezone, now):
    header = header_text(match, timezone, now)
    live = match["state"] == "live"
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = "#070A0F",
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 8,
                        color = live and "#A81624" or "#17202B",
                        child = render.Row(
                            expanded = True,
                            cross_align = "center",
                            children = [
                                render.Box(width = 20, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [render.Text(content = "USL1", font = "CG-pixel-3x5-mono", color = "#FFFFFF")])),
                                render.Box(width = 44, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [render.Text(content = header[:11], font = "CG-pixel-3x5-mono", color = live and "#FFFFFF" or "#BBD1E5"), render.Box(width = 2, height = 1)])),
                            ],
                        ),
                    ),
                    render_team_row(match, match["away"]),
                    render_team_row(match, match["home"]),
                ],
            ),
        ),
    )

def render_message(team_id, title, subtitle):
    metadata = TEAM_DATA.get(team_id, ["USL LEAGUE ONE", "USL1", "#296D23"])
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = "#070A0F",
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = metadata[1], font = "tb-8", color = "#FFFFFF"),
                    render.Text(content = title[:16], font = "CG-pixel-3x5-mono", color = "#FFD65A"),
                    render.Text(content = subtitle[:16], font = "CG-pixel-3x5-mono", color = "#7F8B99"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Favorite team",
                desc = "Choose a USL League One team.",
                icon = "futbol",
                default = DEFAULT_TEAM_ID,
                options = TEAM_OPTIONS,
            ),
        ],
    )

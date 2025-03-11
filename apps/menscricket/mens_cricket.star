"""
Applet: Mens Cricket
Summary: Display cricket scores
Description: For a selected team, this app shows the scorecard for a current match. If no match in progress, it will display scorecard for a recently completed match. If none of these, it will display the next match details in user's local timezone.
Author: adilansari

v 1.0 - Intial version with T20/ODI match support
v 1.1 - Using CricBuzz API for match data and adding Test match support
"""

load("bsoup.star", "bsoup")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# API
TEAM_SCHEDULE_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/schedule"
TEAM_RESULTS_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/results"
MATCH_FULL_COMM_URL = "https://www.cricbuzz.com/api/cricket-match/{match_id}/full-commentary/0"

# FALLBACK_MATCH_COMM_URL = "https://www.cricbuzz.com/api/cricket-match/commentary/{match_id}"
LIVE_SCORE_URL = "https://www.cricbuzz.com/api/cricket-match/commentary/{match_id}"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"

# Timings
ONE_HOUR = 3600  # 1 hour
ONE_MINUTE = 60  # 1 minute
DEFAULT_SCREEN = render.Root(
    child = render.WrappedText(
        content = "Match cannot be displayed. Please choose a different team.",
        font = "tom-thumb",
    ),
)

# Config
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_TEAM_ID = "2"
DEFAULT_PAST_RESULT_DAYS = 3
ALWAYS_SHOW_FIXTURES_SCHEMA_KEY = "Always"

# Styling
LRG_FONT = "CG-pixel-4x5-mono"
SML_FONT = "CG-pixel-3x5-mono"
BLACK_COLOR = "#222222"
WHITE_COLOR = "#FFFFFF"
CHARCOAL_COLOR = "#36454F"

def main(config):
    tz = config.get("$tz", DEFAULT_TIMEZONE)
    team_id = config.get("team", DEFAULT_TEAM_ID)
    fixture_days = config.get("days_forward", ALWAYS_SHOW_FIXTURES_SCHEMA_KEY)
    result_days = int(config.get("days_back", DEFAULT_PAST_RESULT_DAYS))
    now = time.now().in_location(tz)
    team_settings = team_settings_by_id[team_id]
    if not team_settings:
        return DEFAULT_SCREEN
    result_match_ids = get_cached_past_match_ids(team_settings.id, team_settings.name)
    scheduled_match_ids = get_cached_scheduled_match_ids(team_settings.id, team_settings.name)
    current_match, past_match, next_match = None, None, None
    for match_id in result_match_ids:
        match_api_resp = fetch_match_comm(match_id)
        if not match_api_resp or "matchHeader" not in match_api_resp:
            continue
        if str(match_api_resp["matchHeader"]["team1"]["id"]) not in team_settings_by_id:
            continue
        if str(match_api_resp["matchHeader"]["team2"]["id"]) not in team_settings_by_id:
            continue
        past_match = match_api_resp
        break
    for match_id in scheduled_match_ids:
        match_api_resp = fetch_match_comm(match_id)
        if not match_api_resp:
            continue
        if "matchHeader" not in match_api_resp:
            continue
        if str(match_api_resp["matchHeader"]["team1"]["id"]) not in team_settings_by_id:
            continue
        if str(match_api_resp["matchHeader"]["team2"]["id"]) not in team_settings_by_id:
            continue
        next_match = match_api_resp
        break

    if next_match:
        live_inning = next_match.get("miniscore", {}).get("inningsId", 0)
        if live_inning > 0:
            current_match = next_match

    match_to_render, render_fn = None, None
    if current_match:
        match_to_render, render_fn = current_match, render_current_match
    if past_match and not match_to_render:
        match_time = time.from_timestamp(int(past_match["matchHeader"]["matchCompleteTimestamp"] / 1000)).in_location(tz)
        result_days_duration = time.parse_duration("{}h".format(result_days * 24))
        if now <= match_time + result_days_duration:
            match_to_render, render_fn = past_match, render_past_match
    if next_match and not match_to_render:
        if fixture_days == ALWAYS_SHOW_FIXTURES_SCHEMA_KEY:
            match_to_render, render_fn = next_match, render_next_match
        else:
            match_time = time.from_timestamp(int(next_match["matchHeader"]["matchStartTimestamp"] / 1000)).in_location(tz)
            fixture_days_duration = time.parse_duration("{}h".format(int(fixture_days) * 24))
            if now > match_time - fixture_days_duration:
                match_to_render, render_fn = next_match, render_next_match

    if not match_to_render:
        return []
    print("rendering match id {} at {} with state {}".format(match_to_render["matchHeader"]["matchId"], now, match_to_render["matchHeader"]["state"]))
    return render_fn(match_to_render, tz)

def render_current_match(match, tz):
    print(tz)
    match_data = fetch_live_score(match["matchHeader"]["matchId"])
    details, scorecard = match_data["matchHeader"], match_data["miniscore"]
    is_test_match = details["matchFormat"].lower() == "test"
    team_scores = [
        {
            "id": "",
            "abbr": "",
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row_1": None,
            "player_row_2": None,
            "team_settings": None,
        },
        {
            "id": "",
            "abbr": "",
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "team_settings": None,
        },
    ]
    live_inning = scorecard.get("inningsId", 0)
    if live_inning == 0 or "matchScoreDetails" not in scorecard:
        return render_next_match(match_data, tz)
    for ing in scorecard["matchScoreDetails"]["inningsScoreList"]:
        if live_inning == ing["inningsId"]:
            team_scores[0]["id"] = ing["batTeamId"]
            team_scores[0]["abbr"] = ing["batTeamName"]

    if details["matchTeamInfo"][0]["battingTeamId"] == team_scores[0]["id"]:
        team_scores[1]["id"] = details["matchTeamInfo"][0]["bowlingTeamId"]
        team_scores[1]["abbr"] = details["matchTeamInfo"][0]["bowlingTeamShortName"]
    else:
        team_scores[1]["id"] = details["matchTeamInfo"][0]["battingTeamId"]
        team_scores[1]["abbr"] = details["matchTeamInfo"][0]["battingTeamShortName"]

    for ts in team_scores:
        ts["team_settings"] = team_settings_by_id[str(ts["id"])]

    for ing in reversed(scorecard["matchScoreDetails"]["inningsScoreList"]):
        ts = team_scores[0] if ing["batTeamId"] == team_scores[0]["id"] else team_scores[1]
        if is_test_match:
            in_score = str(ing["score"])
            if ing["wickets"] < 10:
                in_score = "{}/{}{}".format(ing["score"], ing["wickets"], "d" if ing["isDeclared"] else "")
            if ts["score"]:
                ts["score"] = "{} & {}".format(ts["score"], in_score)
            else:
                ts["score"] = in_score
        else:
            ts["score"] = ing["score"]
            ts["wickets"] = ing["wickets"]
            ts["overs"] = ing["overs"]

    for k, m in [("batsmanStriker", "player_row_1"), ("batsmanNonStriker", "player_row_2")]:
        if scorecard.get(k, {}):
            name = scorecard[k]["batName"]
            runs = scorecard[k]["batRuns"]
            balls = scorecard[k]["batBalls"]
            if not name:
                name = " ".join(scorecard.get("lastWicket", "Wicket Out").split(" ")[:2])
                runs = "out"
            ts = team_scores[0] if scorecard["batTeam"]["teamId"] == team_scores[0]["id"] else team_scores[1]
            ts[m] = render_batsmen_row(name, runs, balls, ts["team_settings"].fg_color)

    row_team_1 = render_team_score_row(team_scores[0]["abbr"], team_scores[0]["score"], team_scores[0]["wickets"], team_scores[0]["overs"], team_scores[0]["team_settings"].fg_color, team_scores[0]["team_settings"].bg_color)
    row_team_2 = render_team_score_row(team_scores[1]["abbr"], team_scores[1]["score"], team_scores[1]["wickets"], team_scores[1]["overs"], team_scores[1]["team_settings"].fg_color, team_scores[1]["team_settings"].bg_color)
    statuses, render_columns = ["", "", "", ""], []
    default_match_status = ""
    if is_test_match:
        day_number, match_state = details.get("dayNumber", 0), details["state"].lower()
        default_match_status = "Day {} {}".format(day_number, match_state)
        overs_rem = scorecard.get("oversRem", 0)
        if overs_rem > 0:
            statuses[2] = "Overs rem - {}".format(humanize.float("#.#", float(overs_rem)))
        else:
            statuses[2] = "{} Innings".format(humanize.ordinal(int(live_inning)))
        need_runs = scorecard.get("remRunsToWin", 0)
        if need_runs == 0 and scorecard.get("target", 0) > 0:
            need_runs = scorecard.get("target", 0) - scorecard["batTeam"]["teamScore"]
        if need_runs > 0:
            statuses[0] = "{} runs to win".format(need_runs)
    else:
        recent_balls = scorecard["recentOvsStats"].split(" ")
        last_6_balls = []
        for b in reversed(recent_balls):
            if len(last_6_balls) == 6:
                break
            if b in ["|", "..."]:
                continue
            last_6_balls.append(b)
        default_match_status = "..." + " ".join(reversed(last_6_balls))
        current_run_rate = "Run Rate: {}".format(humanize.float("#.#", float(scorecard["currentRunRate"])))
        statuses[1] = current_run_rate
        if live_inning == 2:
            need_runs = scorecard["remRunsToWin"]
            statuses[0] = "{} runs to win".format(need_runs)
            reqd_run_rate = "Reqd Rate: {}".format(humanize.float("#.#", float(scorecard["requiredRunRate"])))
            statuses[2] = reqd_run_rate

    for i in range(len(statuses)):
        if not statuses[i]:
            statuses[i] = default_match_status
        render_columns.append(
            render.Column(
                children = [
                    row_team_1,
                    team_scores[0]["player_row_1"],
                    team_scores[0]["player_row_2"],
                    row_team_2,
                    render_status_row(statuses[i]),
                ],
            ),
        )
    return render.Root(
        delay = int(4000),
        child = render.Animation(
            children = render_columns,
        ),
    )

def render_next_match(match_data, tz):
    details = match_data["matchHeader"]
    match_start_time = time.from_timestamp(int(details["matchStartTimestamp"] / 1000)).in_location(tz)
    match_time_status = match_start_time.format("Jan 2 - 3:04 PM")
    time_to_start = match_start_time - time.now().in_location(tz)
    if time_to_start < time.parse_duration("48h"):
        match_time_status = humanize.time(match_start_time)
    elif time_to_start < time.parse_duration("168h"):
        match_time_status = match_start_time.format("Mon - 3:04 PM")

    team_1_id, team_1_name = str(details["team1"]["id"]), details["team1"]["name"]
    team_2_id, team_2_name = str(details["team2"]["id"]), details["team2"]["name"]

    team_1_settings = team_settings_by_id[team_1_id]
    team_2_settings = team_settings_by_id[team_2_id]

    match_title_status = details["matchDescription"]
    match_venue_status = details["venue"]["city"]
    if len(match_venue_status) < 14:
        country = details["venue"]["country"]
        for tm in team_settings_by_id.values():
            if country.lower() == tm.name.lower():
                country = tm.abbr
                break

        match_venue_status = "{}, {}".format(match_venue_status, country)

    team_1_row = render_team_row(team_1_name, team_1_settings.fg_color, team_1_settings.bg_color)
    vs_row = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Box(height = 9, child = render.Text(content = "vs", color = WHITE_COLOR, font = SML_FONT)),
        ],
    )
    team_2_row = render_team_row(team_2_name, team_2_settings.fg_color, team_2_settings.bg_color)
    match_venue_status_row = render_status_row(match_venue_status)
    match_title_status_row = render_status_row(match_title_status)
    match_state = details["state"].lower()
    match_state_status = match_time_status if match_state in ["preview", "upcoming"] else match_state
    match_state_status_row = render_status_row(match_state_status)
    return render.Root(
        delay = int(4000),
        child = render.Animation(
            children = [
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_title_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_state_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_state_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_venue_status_row,
                    ],
                ),
            ],
        ),
    )

def render_past_match(match, tz):
    details, scorecard = match["matchHeader"], match["miniscore"]
    is_test_match = details["matchFormat"].lower() == "test"
    match_start = time.from_timestamp(int(details["matchStartTimestamp"] / 1000)).in_location(tz)
    match_dt_status = match_start.format("Jan 2 2006")

    team_scores = [
        {
            "id": details["matchTeamInfo"][0]["battingTeamId"],
            "abbr": details["matchTeamInfo"][0]["battingTeamShortName"],
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row": None,
            "team_settings": None,
        },
        {
            "id": details["matchTeamInfo"][0]["bowlingTeamId"],
            "abbr": details["matchTeamInfo"][0]["bowlingTeamShortName"],
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row": None,
            "team_settings": None,
        },
    ]

    for ts in team_scores:
        ts["team_settings"] = team_settings_by_id[str(ts["id"])]

    for ing in reversed(scorecard["matchScoreDetails"]["inningsScoreList"]):
        ts = team_scores[0] if ing["batTeamId"] == team_scores[0]["id"] else team_scores[1]
        if is_test_match:
            in_score = str(ing["score"])
            if ing["wickets"] < 10:
                in_score = "{}/{}{}".format(ing["score"], ing["wickets"], "d" if ing["isDeclared"] else "")
            if ts["score"]:
                ts["score"] = "{} & {}".format(ts["score"], in_score)
            else:
                ts["score"] = in_score
        else:
            ts["score"] = ing["score"]
            ts["wickets"] = ing["wickets"]
            ts["overs"] = ing["overs"]

    # find last innings batsman and bowler
    if len(scorecard.get("bowlerStriker", {})) > 0:
        name = scorecard["bowlerStriker"]["bowlName"]
        ovs = scorecard["bowlerStriker"]["bowlOvs"]
        runs = scorecard["bowlerStriker"]["bowlRuns"]
        wkts = scorecard["bowlerStriker"]["bowlWkts"]
        ts = team_scores[0] if scorecard["batTeam"]["teamId"] != team_scores[0]["id"] else team_scores[1]
        ts["player_row"] = render_bowler_row(name, ovs, runs, wkts, ts["team_settings"].fg_color)

    if len(scorecard.get("batsmanStriker", {})) > 0:
        name = scorecard["batsmanStriker"]["batName"]
        runs = scorecard["batsmanStriker"]["batRuns"]
        balls = scorecard["batsmanStriker"]["batBalls"]
        ts = team_scores[0] if scorecard["batTeam"]["teamId"] == team_scores[0]["id"] else team_scores[1]
        ts["player_row"] = render_batsmen_row(name, runs, balls, ts["team_settings"].fg_color)

    match_result_status = details["status"]
    if "result" in details:
        result = details["result"]
        if result["resultType"] == "tie":
            match_result_status = "Match tied"
        elif result["resultType"] == "noresult":
            match_result_status = "Match abandoned"
        elif result["resultType"] == "draw":
            match_result_status = "Match draw"
        else:
            win_type = " runs" if result["winByRuns"] else " wkts"
            inn_win = "in & " if result["winByInnings"] else ""
            win_by = "by " + inn_win + str(result["winningMargin"]) + win_type
            win_team_abbr = team_scores[0]["abbr"] if result["winningteamId"] == team_scores[0]["id"] else team_scores[1]["abbr"]
            match_result_status = win_team_abbr + " " + win_by

    team_1_score_row = render_team_score_row(team_scores[0]["abbr"], team_scores[0]["score"], team_scores[0]["wickets"], team_scores[0]["overs"], team_scores[0]["team_settings"].fg_color, team_scores[0]["team_settings"].bg_color)
    team_1_player_row = team_scores[0]["player_row"]
    team_2_score_row = render_team_score_row(team_scores[1]["abbr"], team_scores[1]["score"], team_scores[1]["wickets"], team_scores[1]["overs"], team_scores[1]["team_settings"].fg_color, team_scores[1]["team_settings"].bg_color)
    team_2_player_row = team_scores[1]["player_row"]
    match_result_status_row = render_status_row(match_result_status)
    match_dt_status_row = render_status_row(match_dt_status)

    columns = []
    for i in range(4):
        stat_row = match_dt_status_row if i == 3 else match_result_status_row
        columns.append(
            render.Column(
                children = [
                    team_1_score_row,
                    team_1_player_row,
                    team_2_score_row,
                    team_2_player_row,
                    stat_row,
                ],
            ),
        )
    return render.Root(
        delay = int(4000),
        child = render.Animation(
            children = columns,
        ),
    )

def render_team_score_row(abbr, score, wickets, overs, fg_color, bg_color):
    wkt_display, over_display = "", ""
    if overs:
        over_display = " {}".format(rounded_overs(overs))
    if overs and wickets != 10:
        wkt_display = "/{}".format(wickets)

    if not score and not wickets:
        score_display = "-"
    else:
        score_display = "{}{}{}".format(score, wkt_display, over_display)

    split_score = score_display.split(" ")
    score_columns = [
        render.Text(content = split_score[0], color = fg_color, font = SML_FONT),
    ]
    for s in split_score[1:]:
        txt = render.Text(content = s, color = fg_color, font = SML_FONT)
        txt = render.Padding(pad = (2, 0, 0, 0), child = txt)
        score_columns.append(txt)

    rendered_display = render.Box(
        height = 7,
        color = bg_color,
        child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [render.Text(content = abbr, color = fg_color, font = LRG_FONT)],
                    ),
                    render.Row(
                        children = score_columns,
                    ),
                ],
            ),
        ),
    )

    return rendered_display

def render_batsmen_row(name, runs, balls, fg_color = WHITE_COLOR, bg_color = ""):
    left_text = reduce_player_name(name)
    balls_text = "({})".format(balls) if balls else ""
    right_text = "{}{}".format(runs, balls_text)
    return render_player_row(left_text, right_text, fg_color, bg_color)

def render_bowler_row(name, overs, runs, wickets, fg_color = WHITE_COLOR, bg_color = ""):
    left_text = reduce_player_name(name)

    # remove decimal from overs
    overs = rounded_overs(overs)
    overs = str(int(overs)) if overs > 10 else str(overs)
    right_text = "{}-{}-{}".format(overs, runs, wickets)
    return render_player_row(left_text, right_text, fg_color, bg_color)

def render_player_row(left_text, right_text, fg_color, bg_color):
    return render.Box(
        height = 6,
        color = bg_color,
        child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Column(
                        cross_align = "start",
                        children = [render.Text(content = left_text, color = fg_color, font = "tom-thumb")],
                    ),
                    render.Column(
                        cross_align = "end",
                        children = [render.Text(content = right_text, color = fg_color, font = SML_FONT)],
                    ),
                ],
            ),
        ),
    )

def render_team_row(name, fg_color, bg_color):
    name = name.upper()
    return render.Box(
        height = 8,
        color = bg_color,
        child = render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = name, color = fg_color, font = "tb-8"),
            ],
        ),
    )

def render_status_row(text, fg_color = WHITE_COLOR, bg_color = BLACK_COLOR):
    text_split = text.split(" ")
    content_columns = []
    for s in text_split:
        content_columns.append(
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Text(content = s, color = fg_color, font = SML_FONT),
            ),
        )

    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Box(
            height = 5,
            color = bg_color,
            child = render.Row(
                main_align = "center",
                expanded = True,
                children = content_columns,
            ),
        ),
    )

def reduce_player_name(name):
    first, last = name.split(" ")[0], name.split(" ")[-1]
    display = first[0] + "." + last
    if len(display) <= 7:
        return display
    else:
        return last[:7]

def rounded_overs(overs):
    if overs % 1 > 0.5:
        return int(overs) + 1
    elif overs % 1 == 0:
        return int(overs)
    return overs

def _team_setting(id, name, abbr, fg_color, bg_color):
    return {
        "id": str(id),
        "name": name,
        "abbr": abbr,
        "fg_color": fg_color,
        "bg_color": bg_color,
    }

team_settings_by_id = {
    ts.id: ts
    for ts in [
        struct(**_team_setting("96", "Afghanistan", "AFG", "#D32011", BLACK_COLOR)),
        struct(**_team_setting("4", "Australia", "AUS", "#FFCE00", "#006A4A")),
        struct(**_team_setting("6", "Bangladesh", "BAN", "#F42A41", "#006A4E")),
        struct(**_team_setting("9", "England", "ENG", "#FFFFFF", "#CE1124")),
        struct(**_team_setting("2", "India", "IND", "#FFAC1C", "#050CEB")),
        struct(**_team_setting("27", "Ireland", "IRE", "#169B62", "#FF883E")),
        struct(**_team_setting("24", "Netherlands", "NED", "#FFFFFF", "#FF4F00")),
        struct(**_team_setting("13", "New Zealand", "NZ", "#FFFFFF", "#008080")),
        struct(**_team_setting("3", "Pakistan", "PAK", "#FFFFFF", "#115740")),
        struct(**_team_setting("23", "Scotland", "SCO", "#FFFFFF", "#005EB8")),
        struct(**_team_setting("11", "South Africa", "SA", "#FFB81C", "#007749")),
        struct(**_team_setting("5", "Sri Lanka", "SL", "#EB7400", "#0A2351")),
        struct(**_team_setting("15", "United States", "USA", "#B31942", "#003087")),
        struct(**_team_setting("10", "West Indies", "WI", "#f2b10e", "#660000")),
        struct(**_team_setting("12", "Zimbabwe", "ZIM", "#FCE300", "#EF3340")),
        struct(**_team_setting("63", "Kolkata Knight Riders", "KKR", "#F7D54E", "#3A225D")),
        struct(**_team_setting("65", "Punjab Kings", "PK", "#D3D3D3", "#DD1F2D")),
        struct(**_team_setting("62", "Mumbai Indians", "MI", "#E9530D", "#004B8D")),
        struct(**_team_setting("966", "Lucknow Giants", "LSG", "#F28B00", "#0057E2")),
        struct(**_team_setting("971", "Gujarat Titans", "GT", "#DBBE6E", "#002244")),
        struct(**_team_setting("255", "Sunrisers Hyderabad", "SRH", "#FCCB11", "#B02528")),
        struct(**_team_setting("61", "Delhi Capitals", "DC", "#D71921", "#282968")),
        struct(**_team_setting("59", "Royal Challengers Bangalore", "RCB", "#D1AB3E", "#EC1C24")),
        struct(**_team_setting("58", "Chennai Super Kings", "CSK", "#FFFF3C", "#2B5DA8")),
        struct(**_team_setting("64", "Rajasthan Royals", "RR", "#C3A11F", "#074EA2")),
    ]
}

team_list_schema_options = [schema.Option(display = ts.name, value = ts.id) for ts in team_settings_by_id.values()]
past_results_day_options = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
    schema.Option(
        display = "7",
        value = "7",
    ),
]
upcoming_fixtures_day_options = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
    schema.Option(
        display = "7",
        value = "7",
    ),
    schema.Option(
        display = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
        value = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "Choose your team",
                icon = "tag",
                default = team_list_schema_options[1].value,
                options = team_list_schema_options,
            ),
            schema.Dropdown(
                id = "days_back",
                name = "# of days back to show scores",
                desc = "Number of days back to search for scores",
                icon = "arrowLeft",
                default = "1",
                options = past_results_day_options,
            ),
            schema.Dropdown(
                id = "days_forward",
                name = "# of days forward to show fixtures",
                desc = "Number of days forward to search for fixtures",
                icon = "arrowRight",
                default = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
                options = upcoming_fixtures_day_options,
            ),
        ],
    )

def get_cached_past_match_ids(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    res = _get_cached_match_ids(TEAM_RESULTS_URL.format(team_name = team_name, team_id = team_id), "teams-results")
    return res

def get_cached_scheduled_match_ids(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    res = _get_cached_match_ids(TEAM_SCHEDULE_URL.format(team_name = team_name, team_id = team_id), "teams-schedule")
    return res

def _get_cached_match_ids(url, span_id):
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)
    print("--MISS for {}".format(url))
    res = fetch_url(url)
    page = bsoup.parseHtml(res)
    spans = page.find_all("span")
    result_span = None
    for span in spans:
        if span_id in str(span):
            result_span = span
            break
    if not result_span:
        return None
    links = result_span.find_all("a")
    match_ids = []
    for link in links:
        href = link.attrs().get("href", "")
        if "cricket-scores" in href:
            url_split = href.strip().split("/")
            if len(url_split) > 2:
                if url_split[2] not in match_ids:
                    match_ids.append(url_split[2])

    # cache the upcoming/past fixtures for 1 hour as this data is not expected to change frequently
    cache.set(url, json.encode(match_ids), ONE_HOUR)
    return match_ids

def fetch_match_comm(match_id):
    url = MATCH_FULL_COMM_URL.format(match_id = match_id)
    json_resp = {}
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        json_resp = json.decode(cached_data)
        return json_resp.get("matchDetails")

    print("--MISS for {}".format(url))
    json_resp = json.decode(fetch_url(url))
    if not json_resp:
        print("NULL match details for {}".format(url))
        return {}

    cache_ttl = 5 * ONE_MINUTE
    match_state = json_resp.get("matchDetails", {}).get("matchHeader", {}).get("state", "Preview").lower()
    if match_state in ["complete", "abandon", "upcoming"]:
        # completed/way in future matches can be cached for longer as they are less likely to change now
        cache_ttl = 4 * ONE_HOUR
    if match_state in ["preview"]:
        # matches about to start within next 1 day
        cache_ttl = ONE_HOUR

    cache.set(url, json.encode(json_resp), cache_ttl)
    return json_resp.get("matchDetails")

def fetch_live_score(match_id):
    url = LIVE_SCORE_URL.format(match_id = match_id)
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)
    print("--MISS for {}".format(url))
    json_resp = json.decode(fetch_url(url))
    cache.set(url, json.encode(json_resp), ONE_MINUTE)
    return json_resp

def fetch_url(url):
    res = http.get(url = url, headers = {"User-Agent": USER_AGENT})

    if res.status_code == 204:
        cache.set(url, json.encode({}), 5 * ONE_MINUTE)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

"""
Applet: FlyTheL
Summary: Show MLB Win/Loss Status
Description: Displays whether your chosen MLB team has recently won or lost.
Author: Jake Manske
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/Chicago"
DEFAULT_RELATIVE = "relative"
FIVE_WIDE_FONT = "CG-pixel-4x5-mono"
DEFAULT_TEAM = "112"
DEFAULT_HOUR_TO_SWITCH = "10"
OK = 200
SMALL_FONT = "CG-pixel-3x5-mono"
SMALL_FONT_COLOR = "#39FF14"
INNING_COLOR = "#ffd500"
LIVE_DATA_CACHE_TTL = 300  # cache live data for 5 minutes in case API calls fail

# this is used in case the cache is empty so we do not bomb out completely
DEFAULT_LIVE_DATA = """
{
    "plays": {
        "allPlays": [
            {
                "result": {
                    "isCompleted": true,
                    "event": "",
                    "eventType": "",
                    "description": ""
                },
                "about": {
                    "halfInning": "top",
                    "isTopInning": true,
                    "inning": 1,
                    "isScoringPlay": false
                },
                "count": {
                    "balls": 0,
                    "strikes": 0,
                    "outs": 0
                },
                "matchup": {
                    "batter": {
                        "id": 0
                    },
                    "pitcher": {
                        "id": 0
                    }
                },
                "runners": [
                    {
                        "details": {
                            "event": "Groundout",
                            "eventType": "field_out",
                            "runner": {
                                "id": 0
                            }
                        },
                        "credits": [
                            {
                                "position": {
                                    "code": "1"
                                }
                            }
                        ]
                    }
                ]
            }
        ],
        "currentPlay": {
            "matchup": { }
        }
    },
    "linescore": {
        "currentInning": 1,
        "isTopInning": true,
        "teams": {
            "home": {
                "runs": 0,
                "hits": 0,
                "errors": 0
            },
            "away": {
                "runs": 0,
                "hits": 0,
                "errors": 0
            }
        },
        "balls": 0,
        "strikes": 0,
        "outs": 0
    },
    "boxscore": {
        "teams": {
            "home": {
                "players": {
                    "parentTeamId": 144
                },
                "battingOrder": [

                ]
            },
            "away": {
                "players": {
                    "parentTeamId": 144
                },
                "battingOrder": [

                ]
            }
        }
    }
}
"""
DEFAULT_GAME_DATA = """
{
    "players": {

    }
}
"""
MLB_SCHED_ENDPOINT = "/api/v1/schedule/games/"
MLB_BASE_URL = "https://statsapi.mlb.com{0}"

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    team = config.str("team", DEFAULT_TEAM)
    hour_to_switch = int(config.str("hour", DEFAULT_HOUR_TO_SWITCH))
    relative_or_absolute = config.str("game_time", DEFAULT_RELATIVE)

    # get schedule
    response = get_sched(team, timezone)

    # if API call is not successful render generic error screen
    if response.status_code != OK:
        return render.Root(
            child = render_http_error(response),
        )

    # we are good, go ahead and start processing the schedule
    sched = response.json()

    # figure out what to display
    current_hour = get_now(timezone).hour
    yesterday = get_yesterday_date(timezone)

    game = None
    if current_hour < hour_to_switch:
        # want to do yesterday's game, if it exists (will be 0-index if it is there)
        event = sched.get("dates")[0]
        if event.get("date") == yesterday:
            # TODO: add handling for doubleheaders somehow
            game = event.get("games")[0]

    # if we didn't find a game above, find one now
    if not game:
        # loop through events until we find one to display
        for event in sched.get("dates"):
            if event.get("date") > yesterday:
                # TODO: add handling for doubleheaders somehow
                game = event.get("games")[0]
                break  # we found what we wanted, break

    # if we still have no game, it means no games are scheduled for the next week
    # display zero state image
    if not game:
        widget = render_no_games(team)
    else:
        widget = render_game(game, team, timezone, relative_or_absolute)

    return render.Root(
        show_full_animation = True,
        child = widget,
    )

def render_no_games(team):
    team = int(team)
    return render.Row(
        children = [
            render.Image(
                src = TEAM_INFO[team].Logo,
            ),
            render.Box(
                width = 32,
                height = 32,
                color = TEAM_INFO[team].BackgroundColor,
                child = render.WrappedText(
                    align = "center",
                    content = "no games for the next week",
                    linespacing = 1,
                    font = SMALL_FONT,
                    color = TEAM_INFO[team].ForegroundColor,
                ),
            ),
        ],
    )

def get_time_to_game(game, timezone, relative_or_absolute):
    # if start time is in the past, say "starting now"
    game_time = time.parse_time(game.get("gameDate")).in_location(timezone)

    time_to_game = get_now(timezone) - game_time

    if time_to_game > time.parse_duration("0s"):
        return struct(Imminent = True, Message = "starting now")

    if relative_or_absolute == "relative":
        # otherwise say how close to the game we are
        relative = humanize.time(game_time).split(" ")

        # don't crash if we don't have the length we are expecting
        if len(relative) < 2:
            return struct(Imminent = True, Message = "starting now")
        return struct(Imminent = False, Message = "in " + relative[0] + " " + relative[1])
    else:
        nice_time = humanize.time_format("M/d K:mm", game_time)
        hour = game_time.hour
        if hour >= 12:
            meridiem = "PM"
        else:
            meridiem = "AM"
        return struct(Imminent = False, Message = str(nice_time + meridiem))

def get_now(timezone):
    return time.now().in_location(timezone)

def render_http_error(response):
    return render.Stack(
        children = [
            render.Image(
                src = MLB_LEAGUE_IMAGE,
            ),
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "HTTP error: " + str(response.status_code),
                    color = SMALL_FONT_COLOR,
                    font = SMALL_FONT,
                ),
            ),
        ],
    )

def render_game(game, team, timezone, relative_or_absolute):
    # get the game state
    status = game.get("statusFlags")

    # if game is cancelled/postponed/delayed or in pre-game, show that
    if should_render_preview(status):
        return render_preview(game, timezone, status, relative_or_absolute)

    # game is finished, render final
    if status.get("isFinal"):
        return render_final(game, team)

    # otherwise the game must be in progress, so render that
    return render_in_progress(game)

def should_render_preview(status):
    return status.get("isCancelled") or status.get("isSuspended") or status.get("isPostponed") or status.get("isDelayed") or status.get("isPreGameDelay") or status.get("isInGameDelay") or status.get("isPreview") or status.get("isWarmup")

def render_final(game, team):
    away = game.get("teams").get("away")
    winner = False
    if str(int(away.get("team").get("id"))) == team:
        winner = away.get("isWinner")
    else:
        winner = game.get("teams").get("home").get("isWinner")
    return render_flag(team, winner)

def render_flag(team, winner):
    team = int(team)

    # cubs get the special flag
    if team == CHC_TEAM_ID:
        fg = TEAM_INFO[team].BackgroundColor if winner else "#FFFFFF"
        bg = "#FFFFFF" if winner else TEAM_INFO[team].BackgroundColor
    else:
        bg = TEAM_INFO[team].BackgroundColor if winner else TEAM_INFO[team].ForegroundColor
        fg = TEAM_INFO[team].ForegroundColor if winner else TEAM_INFO[team].BackgroundColor
    return render.Box(
        height = 32,
        width = 64,
        color = bg,
        child = render_W(fg) if winner else render_L(fg),
    )

def render_preview(game, timezone, status, relative_or_absolute):
    msg = ""
    if status.get("isCancelled"):
        msg = "cancelled"
    if status.get("isSuspended"):
        msg = "suspended"
    if status.get("isPostponed"):
        msg = "postponed"
    if status.get("isDelayed") or status.get("isPreGameDelay") or status.get("isInGameDelay"):
        msg = "delayed"

    away_id = get_away_team_id(game)
    home_id = get_home_team_id(game)

    game_time = get_time_to_game(game, timezone, relative_or_absolute)

    footer = None
    if len(msg) > 0:
        footer = render_preview_msg(msg, False)
    elif game_time.Imminent:
        footer = render_preview_msg(game_time.Message, True)
    else:
        footer = render_pitcher_preview(game, game_time.Message)

    return render.Column(
        cross_align = "center",
        children = [
            render.Row(
                children = [
                    render.Image(
                        src = TEAM_INFO[away_id].Logo,
                        width = 26,
                    ),
                    render.Text(
                        content = "at",
                        font = "6x13",
                        color = INNING_COLOR,
                    ),
                    render.Image(
                        src = TEAM_INFO[home_id].Logo,
                        width = 26,
                    ),
                ],
            ),
            footer,
        ],
    )

def render_preview_msg(msg, flashy):
    return render.Box(
        height = 6,
        width = 64,
        child = render.Text(
            font = FIVE_WIDE_FONT,
            content = msg,
        ) if not flashy else render_rainbow_word(msg, FIVE_WIDE_FONT),
    )

def render_pitcher_preview(game, time_to_game):
    away = get_away_team_id(game)
    away_pitcher = get_away_probable_pitcher(game)
    home = get_home_team_id(game)
    home_pitcher = get_home_probable_pitcher(game)

    return animation.Transformation(
        duration = 200,
        height = 24,
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(-6, 0.25),
            build_keyframe(-12, 0.5),
            build_keyframe(-18, 0.75),
            build_keyframe(-18, 1.0),
        ],
        wait_for_child = True,
        child = render.Column(
            children = [
                render.Box(
                    height = 6,
                    width = 64,
                    child = render.Text(
                        font = FIVE_WIDE_FONT,
                        content = time_to_game,
                    ),
                ),
                render_player(away, away_pitcher),
                render.Box(
                    height = 6,
                    width = 64,
                    child = render_american_word("versus", FIVE_WIDE_FONT),
                ),
                render_player(home, home_pitcher),
            ],
        ),
    )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(0, offset)],
        curve = "ease_in_out",
    )

def render_player(team, player):
    team = int(team)
    bg = TEAM_INFO[team].BackgroundColor
    fg = TEAM_INFO[team].ForegroundColor
    sanitized = ""

    # sanitize the pitcher name
    # the font we use cannot handle diacritical marks
    if player != None:
        sanitized = sanitize_name(player.get("useLastName"))

    return render.Box(
        height = 6,
        width = 64,
        color = bg,
        child = render.Text(
            font = FIVE_WIDE_FONT if len(sanitized) < 14 else SMALL_FONT,
            color = fg,
            content = sanitized if player != None else "TBD",
        ),
    )

def sanitize_name(name):
    return name.replace("ó", "o").replace("í", "i").replace("é", "e").replace("á", "a").replace("ñ", "n")

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    return render_flashy_word(word, font, colors, 1)

def render_american_word(word, font):
    colors = ["#B31942", "#FFFFFF", "#0A3161"]
    return render_flashy_word(word, font, colors, 4)

def render_flashy_word(word, font, colors, repeater):
    widgets = []
    flash_list = []

    # set up the color list
    for color in colors:
        for _ in range(repeater):
            flash_list.append(color)

    ranger = len(flash_list)

    for j in range(ranger):
        flashy_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = flash_list[(j + i) % ranger],
            )
            flashy_word.append(letter)
        widgets.append(
            render.Row(
                children = flashy_word,
            ),
        )
    return render.Animation(
        children = widgets,
    )

def render_in_progress(game):
    # we have to make another API call here
    # but if a game is in progress, we do not want to fail because an API call failed
    url = MLB_BASE_URL.format(game.get("link"))

    # hit the API again to get current in-game live data
    query_params = {
        "fields": ",".join(LIVE_DATA_FIELDS),
    }

    # refresh this every 15 seconds to stay up to date
    response = http.get(url, params = query_params, ttl_seconds = 15)

    # this is our cache key
    cache_key = str(int(game.get("gamePk")))

    # if the API call failed for some reason, get the linescore from the last successful call
    if response.status_code != OK:
        data = cache.get(cache_key)
        if data != None:
            live_data = json.decode(data).get("liveData")
            game_data = json.decode(data).get("gameData")
        else:
            live_data = json.decode(DEFAULT_LIVE_DATA)
            game_data = json.decode(DEFAULT_GAME_DATA)
    else:
        decoded = response.json()
        live_data = decoded.get("liveData")
        game_data = decoded.get("gameData")

        # cache this data
        # we almost never look it up because we are using http cache almost all of the time
        # but in case the http call fails for some reason, we want to be able to use the latest result we got from the API
        cache.set(key = cache_key, value = json.encode(decoded), ttl_seconds = LIVE_DATA_CACHE_TTL)

    return render.Stack(
        children = [
            render.Column(
                children = [
                    render_in_progress_header(live_data, game_data),
                    render_competitors(game),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_in_progress_footer(live_data),
                ],
            ),
            render_state(live_data),
        ],
    )

def render_in_progress_footer(live_data):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_linescore(live_data, "away"),
            render_linescore(live_data, "home"),
        ],
    )

def render_competitors(game):
    away_id = get_away_team_id(game)
    home_id = get_home_team_id(game)

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_team_logo(away_id),
            render_team_logo(home_id),
        ],
    )

def render_team_logo(team_id):
    return render.Image(
        src = TEAM_INFO[team_id].Logo,
        width = 21,
    )

def process_play(play):
    # cache the result node
    result_node = play.get("result")

    # parse the result
    outcome = result_node.get("eventType")
    event = result_node.get("event")
    desc = result_node.get("description")

    # get the outcome code from our map
    code = PLAY_OUTCOME_MAP.get(outcome, "")

    # if it is an error or a certain kind of field out, it is easy to render more details
    if outcome == "field_error" or (outcome == "field_out" and (event == "Flyout" or event == "Lineout" or event == "Pop Out")):
        # get the credits
        # TODO: figure out a good way to render things like 6-3 putout
        abbrev = ""
        if outcome == "field_error":
            abbrev = "E"
        elif event == "Flyout" or event == "Lineout" or event == "Pop Out":
            abbrev = event[0]
        for runner in play.get("runners"):
            details = runner.get("details")
            if details.get("eventType") == outcome:
                credits = runner.get("credits")
                if len(credits) > 0:
                    position_code = int(credits[0].get("position").get("code"))

                    # if we got this far, update the code we display from our map to something more desscriptive
                    code = abbrev + str(position_code)

        # if it is a strikeout, we can make it forward or backward K
    elif outcome == "strikeout":
        if desc.find("called out") > -1:
            return render_backward_K()
        else:
            return render.Row(
                children = [
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render.Text(
                        font = FIVE_WIDE_FONT,
                        color = INNING_COLOR,
                        content = code,
                    ),
                ],
            )

    # make it flashy if there was a run scored
    if play.get("about").get("isScoringPlay"):
        widget = render_rainbow_word(code, SMALL_FONT)
    else:
        widget = render.Text(
            font = SMALL_FONT,
            color = INNING_COLOR,
            content = code,
        )
    return widget

def render_backward_K():
    color = INNING_COLOR
    return render.Row(
        children = [
            render.Column(
                children = [
                    render_block(1, 1, color),
                    render_blank_block(1, 3),
                    render_block(1, 1, color),
                ],
            ),
            render.Column(
                children = [
                    render_blank_block(1, 1),
                    render_block(1, 1, color),
                    render_blank_block(1, 1),
                    render_block(1, 1, color),
                ],
            ),
            render.Column(
                children = [
                    render_blank_block(1, 2),
                    render_block(1, 1, color),
                ],
            ),
            render_block(1, 5, color),
        ],
    )

def render_in_progress_header(live_data, game_data):
    play = get_play_to_process(live_data)

    # get the batter and pitcher
    matchup = play.get("matchup")
    batter_id = matchup.get("batter").get("id")
    pitcher_id = matchup.get("pitcher").get("id")
    boxscore = live_data.get("boxscore").get("teams")

    away_team_lineup = boxscore.get("away").get("battingOrder")
    home_team_lineup = boxscore.get("home").get("battingOrder")
    home_players = boxscore.get("home").get("players")
    away_players = boxscore.get("away").get("players")

    batter_dict_id = "ID" + str(int(batter_id))
    pitcher_dict_id = "ID" + str(int(pitcher_id))
    batter = home_players.get(batter_dict_id)
    pitcher = away_players.get(pitcher_dict_id)

    # if we didn't find the batter, flip from home to away
    if batter == None:
        batter = away_players.get(batter_dict_id)
        pitcher = home_players.get(pitcher_dict_id)
        lineup = away_team_lineup
    else:
        lineup = home_team_lineup

    # do not use .index here
    # it throws an error if the element is not in the list
    # instead loop over the list
    order = "?"
    for i in range(len(lineup)):
        if batter_id == lineup[i]:
            order = i + 1
            break

    # can be no pitcher if API calls failed and cache was not populated
    if pitcher != None:
        pitches = int(pitcher.get("stats").get("pitching").get("numberOfPitches") or 0)
    else:
        pitches = 0

    # get the team of each player
    # this is more straightforward than trying to figure out
    # who is at bat based on top/bottom of inning, which is less reliable
    if batter != None and pitcher != None:
        batter_team_id = int(batter.get("parentTeamId"))
        pitcher_team_id = int(pitcher.get("parentTeamId"))
    else:
        batter_team_id = int(DEFAULT_TEAM)
        pitcher_team_id = int(DEFAULT_TEAM)

    # go back to the overall player dictionary to get the last name
    batter = game_data.get("players").get(batter_dict_id)
    if batter != None:
        batter_name = sanitize_name(batter.get("useLastName"))
    else:
        batter_name = "???"
    pitcher = game_data.get("players").get(pitcher_dict_id)
    if pitcher != None:
        pitcher_name = sanitize_name(pitcher.get("useLastName"))
    else:
        pitcher_name = "???"

    matchup_array = []
    ranger = 100
    for _ in range(ranger):
        matchup_array.append(
            render.Box(
                width = 64,
                height = 5,
                color = TEAM_INFO[batter_team_id].BackgroundColor,
                child = render.Text(
                    content = str(order) + "." + batter_name,
                    font = FIVE_WIDE_FONT if len(batter_name) < 12 else SMALL_FONT,
                    color = TEAM_INFO[batter_team_id].ForegroundColor,
                ),
            ),
        )
    for _ in range(ranger):
        matchup_array.append(
            render.Box(
                width = 64,
                height = 5,
                color = TEAM_INFO[pitcher_team_id].BackgroundColor,
                child = render.Row(
                    children = [
                        render.Text(
                            content = pitcher_name,
                            font = FIVE_WIDE_FONT if len(pitcher_name) < 12 else SMALL_FONT,
                            color = TEAM_INFO[pitcher_team_id].ForegroundColor,
                        ),
                        render.Box(
                            width = 2,
                            height = 1,
                        ),
                        render.Text(
                            content = str(pitches),
                            font = FIVE_WIDE_FONT,
                            color = TEAM_INFO[pitcher_team_id].ForegroundColor,
                        ),
                    ],
                ),
            ),
        )
    return render.Animation(
        children = matchup_array,
    )

def render_linescore(live_data, team_type):
    runs = get_runs(live_data, team_type)
    hits = get_hits(live_data, team_type)
    errors = get_errors(live_data, team_type)

    # dynamically size linescore font based on whether runs or hits are double digits
    if len(runs) >= 2 or len(hits) >= 2:
        font = SMALL_FONT
    else:
        font = FIVE_WIDE_FONT
    return render.Row(
        children = [
            render.Text(
                font = font,
                content = runs,
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = hits,
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = errors,
            ),
        ],
    )

def get_runs(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("runs")))

def get_hits(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("hits")))

def get_errors(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("errors")))

def render_inning(inning, half_inning, outs):
    array = []
    if outs == 3:
        if half_inning == "top":
            content = "MID"
        else:
            content = "END"
        content += " " if inning < 10 else ""
        array.append(
            render.Text(
                content = content,
                font = SMALL_FONT,
                color = INNING_COLOR,
            ),
        )
    array.append(
        render.Text(
            content = str(inning),
            font = FIVE_WIDE_FONT,
            color = INNING_COLOR,
        ),
    )
    if outs < 3:
        is_top = half_inning == "top"
        array.append(
            render.Padding(
                pad = (0, 1 if is_top else 2, 0, 0),
                child = render.Image(
                    src = TOP_INNING if is_top else BOTTOM_INNING,
                ),
            ),
        )

    return render.Row(
        expanded = True,
        main_align = "center",
        children = array,
    )

def get_play_to_process(live_data):
    # need the most recent completed play
    # start by seeing if the most recent play is completed
    # if it is not, then the one right before it will be
    all_plays = live_data.get("plays").get("allPlays")
    play = all_plays[-1]

    if not play.get("about").get("isComplete") and len(all_plays) > 1:
        play = all_plays[len(all_plays) - 2]
    return play

def render_state(live_data):
    play = get_play_to_process(live_data)
    inning = int(play.get("about").get("inning"))
    half_inning = play.get("about").get("halfInning")
    outs = int(play.get("count").get("outs"))

    return render.Padding(
        pad = (22, 3, 0, 0),
        child = render.Box(
            height = 32,
            width = 22,
            child = render.Column(
                main_align = "start",
                cross_align = "center",
                children = [
                    render_inning(inning, half_inning, outs),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_bases(live_data),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_current_outs(outs),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    process_play(play),
                ],
            ),
        ),
    )

def render_count(balls, strikes):
    content = ""
    if balls == 4:
        content = "BB"
    elif strikes == 3:
        content = "K"
    else:
        content = str(balls) + "-" + str(strikes)
    return render.Text(
        font = SMALL_FONT,
        content = content,
        color = INNING_COLOR,
    )

def render_bases(live_data):
    if live_data.get("plays").get("currentPlay") == None:
        first = EMPTY_BASE_IMG
        second = EMPTY_BASE_IMG
        third = EMPTY_BASE_IMG
    else:
        matchup = live_data.get("plays").get("currentPlay").get("matchup")
        first = OCCUPIED_BASE_IMG if matchup.get("postOnFirst") != None else EMPTY_BASE_IMG
        second = OCCUPIED_BASE_IMG if matchup.get("postOnSecond") != None else EMPTY_BASE_IMG
        third = OCCUPIED_BASE_IMG if matchup.get("postOnThird") != None else EMPTY_BASE_IMG

    return render.Stack(
        children = [
            render.Row(
                children = [
                    render.Box(
                        height = 4,
                        width = 3,
                    ),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = second,  # second base
                            ),
                        ],
                    ),
                ],
            ),
            render.Padding(
                pad = (0, 4, 0, 0),
                child = render.Row(
                    children = [
                        render.Image(
                            src = third,  # third base
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                        ),
                        render.Image(
                            src = first,  # first base
                        ),
                    ],
                ),
            ),
        ],
    )

def get_sched(team, timezone):
    yesterday = get_now(timezone) - time.parse_duration("86400s")
    future = yesterday + time.parse_duration("518400s")
    query_params = {
        "teamId": team,
        "sportId": "1",
        "startDate": get_date(yesterday),
        "endDate": get_date(future),
        "hydrate": "statusFlags,linescore,person,probablePitcher",  # hydrate stuff so we don't have to hit API again
        "fields": ",".join(SCHED_FIELDS),
    }
    url = MLB_BASE_URL.format(MLB_SCHED_ENDPOINT)

    # cache schedule info for 60 seconds
    return http.get(url, params = query_params, ttl_seconds = 60)

SCHED_FIELDS = (
    "dates",
    "date",
    "games",
    "gamePk",
    "game",
    "link",
    "gameDate",
    "statusFlags",
    "isFinal",
    "isPreview",
    "isWarmup",
    "isCancelled",
    "isClassicDoubleHeader",
    "isDoubleHeader",
    "isPostponed",
    "isDelayed",
    "isPreGameDelay",
    "isInGameDelay",
    "isSuspended",
    "isWinner",
    "linescore",
    "away",
    "home",
    "teams",
    "team",
    "id",
    "probablePitcher",
    "useLastName",
)

LIVE_DATA_FIELDS = (
    "liveData",
    "plays",
    "allPlays",
    "currentPlay",
    "atBatIndex",
    "matchup",
    "postOnFirst",
    "postOnSecond",
    "postOnThird",
    "linescore",
    "isTopInning",
    "currentInning",
    "outs",
    "count",
    "balls",
    "strikes",
    "teams",
    "home",
    "away",
    "runs",
    "hits",
    "count",
    "outs",
    "errors",
    "result",
    "eventType",
    "event",
    "description",
    "runners",
    "details",
    "about",
    "inning",
    "halfInning",
    "isScoringPlay",
    "isComplete",
    "credits",
    "position",
    "code",
    "gameData",
    "players",
    "id",
    "useLastName",
    "batter",
    "pitcher",
    "stats",
    "pitching",
    "numberOfPitches",
    "parentTeamId",
    "battingOrder",
    "team",
    "boxscore",
)

def get_yesterday_date(timezone):
    yesterday = get_now(timezone) - time.parse_duration("86400s")
    return get_date(yesterday)

def get_schema():
    hour_options = []
    for hour in [4, 5, 6, 7, 8, 9, 10, 11]:
        hour_options.append(
            schema.Option(
                display = str(hour),
                value = str(hour),
            ),
        )
    team_options = []
    for team in TEAM_INFO.values():
        team_options.append(
            schema.Option(
                display = team.Name,
                value = str(team.Id),
            ),
        )
    game_time_options = []
    game_time_options.append(
        schema.Option(
            display = "Relative",
            value = "relative",
        ),
    )
    game_time_options.append(
        schema.Option(
            display = "Absolute",
            value = "absolute",
        ),
    )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "MLB Team to follow.",
                icon = "baseballBatBall",
                options = team_options,
                default = DEFAULT_TEAM,  # CHICAGO CUBS
            ),
            schema.Dropdown(
                id = "hour",
                name = "Hour of the Day",
                desc = "The hour of the day to switch from yesterday's result to upcoming game.",
                icon = "clock",
                options = hour_options,
                default = DEFAULT_HOUR_TO_SWITCH,
            ),
            schema.Dropdown(
                id = "game_time",
                name = "Relative or Absolute",
                desc = "Whether to display the upcoming game time in relative or absolute terms.",
                icon = "hourglass",
                options = game_time_options,
                default = DEFAULT_RELATIVE,
            ),
        ],
    )

def get_date(timestamp):
    month = str(timestamp.month)
    day = str(timestamp.day)
    month = "0" + month if len(month) == 1 else month
    day = "0" + day if len(day) == 1 else day
    return str(timestamp.year) + "-" + month + "-" + day

TOP_INNING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAYAAACddGYaAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAA6ADAAQAAAABAAAAAgAAAABqvnfpAAAAFklEQVQIHWNgAIL/Vxn+g2hGGAPEAQBVtgWoSRQwXgAAAABJRU5ErkJggg==
""")

BOTTOM_INNING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAYAAACddGYaAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAA6ADAAQAAAABAAAAAgAAAABqvnfpAAAAEklEQVQIHWP8f5XhPwMygAkAAFXDBaj4uKqgAAAAAElFTkSuQmCC
""")

#################
## TEAM CONFIG ##
#################

LAA_TEAM_ID = 108  #Los Angeles Angels
ARI_TEAM_ID = 109  #Arizona Diamondbacks
BAL_TEAM_ID = 110  #Baltimore Orioles
BOS_TEAM_ID = 111  #Boston Red Sox
CHC_TEAM_ID = 112  #Chicago Cubs
CIN_TEAM_ID = 113  #Cincinnati Reds
CLE_TEAM_ID = 114  #Cleveland Guardians
COL_TEAM_ID = 115  #Colorado Rockies
DET_TEAM_ID = 116  #Detroit Tigers
HOU_TEAM_ID = 117  #Houston Astros
KC_TEAM_ID = 118  #Kansas City Royals
LAD_TEAM_ID = 119  #Los Angeles Dodgers
WAS_TEAM_ID = 120  #Washington Nationals
NYM_TEAM_ID = 121  #New York Mets
ATH_TEAM_ID = 133  #Athletics
PIT_TEAM_ID = 134  #Pittsburgh Pirates
SD_TEAM_ID = 135  #San Diego Padres
SEA_TEAM_ID = 136  #Seattle Mariners
SF_TEAM_ID = 137  #San Francisco Giants
STL_TEAM_ID = 138  #St. Louis Cardinals
TB_TEAM_ID = 139  #Tampa Bay Rays
TEX_TEAM_ID = 140  #Texas Rangers
TOR_TEAM_ID = 141  #Toronto Blue Jays
MIN_TEAM_ID = 142  #Minnesota Twins
PHI_TEAM_ID = 143  #Philadelphia Phillies
ATL_TEAM_ID = 144  #Atlanta Braves
CWS_TEAM_ID = 145  #Chicago White Sox
MIA_TEAM_ID = 146  #Miami Marlins
NYY_TEAM_ID = 147  #New York Yankees
MIL_TEAM_ID = 158  #Milwaukee Brewers

MLB_LEAGUE_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAQKADAAQAAAABAAAAIAAAAADfYzX9AAACDElEQVRoBeVXvUoEMRDenHsrWIj4BxanNnY2FjYKp6iVpeDbWAvWtj6AjfoAKqgP4AtcJYKIHgda2FisZnWO7GTiJrlNNrcuHNl8O0nm+2YyybF4fiuNAn4+H64l727GNyTMFmjYDvQ1rrmwLS21+X4rYbZA8AJwYgdHJxI/Fo9ImA3AqtgCVFqD81TE+TdqTBlbwXsGUESAPBClbChh2q+X4lCrd68CUMRUXlO2WITGaKIaro17FUDbq19DSoTW6n5umkELojcBKDI5Jpqd55eeZNlImhKmC3gTQNchbPd0f4ahCG+FdvdKstEFghdgZmqC5IJFWD49JO2KQOcC3J0fk0dYkWM63+dW9vpm07vr/XeTl9jE2NS2rH2vWrfbe4vSNI0YY5kJL4imdwOnAuA0tREEz4HFSBZ3Bsow51sAO+yiL4pkeizWQgAuKs8EeEwKorf/AjbpD4T+aiH61Pw69cCbAECCchS+uWiLRKjNFrAVr/YC8KKYzE4q9XF6DIqr+k59ce3o55qQg6DjJQMqJf/NdK1zAXyl1nkRrJo8ZoyLojIDuOPww5MMcx9flEgBcNRwX1cA23G685dhRwpQxsQhzyFmgTMBQo/+2FIrixEpAFwvIYq4D/gwtx+dx8x95T2gjqSpgJEZQBnWCROPwn8ngEieB9X5RQgyx2dRxCTBB6r1lgGh1pQvQzmLGvG9jN0AAAAASUVORK5CYII=
""")

#id: 108 - Los Angeles Angels
LAA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB0klEQVRYCa2WMU4DMRBFdxEVouEKIFEjoExDAWego8kFaDlA2lwgp6AMBRJKCRE1EmegoV/2m/xomNiesY0ba70z85/H49ntl93x0DWM6+Gze+pPqiPsVXuOjhDvL6Zhro1TDUBxCLdAVAFI8eX6OWy+FqIIAMJSfPb9HsQ1BGy8Y99rKIVXi/sdt9VmBZnAGJzF6QKguBSeTOcdMnD58RUEb86vOrynDUA8ECaAFIcohxTHGo5h8rv5YAIQD4RZA7jjw9tiDD7f7o4QqRnisIef1SN6byOSmXi5vdumXkMcrB/d4vA1j4ACIRObxjPj4ji/nh79gfHunCHMI6Bhan44PAsQqffWehWArHyccwuEG4A1wOaT2hluQ0lXdAOkBFvXXQBy9zr9vKbyGEqyYALExD279kJkAWrFCeiByALE0svgnhnfB6sbZgEgEoPQgaUNwbQN1/VsAmgH6xmdsWS4W3EsKGqkdVQD8MejFcD8GrbcBE8dFGfAe8ZsWFaGigHQ8axhfS+kfzEAnHG3U6O0NrIAufPH3ddD3wp2wtzP6b/3AQ1lPSczIHePIN7ioyDtUQ+5v+MoAMURzFN0FOUc80lB7PQBfY4MGptlHdT6/QCZ3x5vRz7hxwAAAABJRU5ErkJggg==
""")

#id: 109 - Arizona Diamondbacks
ARI_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACe0lEQVRYCcVWsW7UQBDd9eWSlpYiEh+QJh0KBEh0kAAlafgGagqkk9ApQUip0vANVGkjoSASJSgpUtBcTwFSqOhSwfnwW+5Z492xvbZB2cK73puZ92bmrffs+5vLU3ONI7lGbAc99y8I3D0c1ob5/HBHtelM4Kr/ywVeXHqmAmDz23jfJFmjUxuadCKAoBsHIwNwgJRlCdik1zNpOgkYdNLAysehA0dUkChrBX67/eFVAI6N1hUA2L3NFy4osseoqoAzUB6tCSDW1+8/akuvYBa2WrUA2VN0VaUvIJW8tCLgx6ojkX3sSjXSmIDMnkTqTgDttLmRBnzwLuIjmWgCtr9AHyc8vEjVP7/8kv+OkseOaAJ3Dl66PmrlBjirAWBowidBHfj+URqQpfcFR/CzzTfmdH07NvHcLopAbj1b+CSw/TudmiRRPva+s/deS0BmT1+WkdmfDLaNbfmvolIDPjj7LMXnSCHz/0GAGWNm1txj9qfZPc/Ca9ct7TFrQixtgcy+DPzT4LWM79YXT3YdWRCMGZUtQAAfXAadt/3gCg7aIx2UtUpAZg/FSxIs/fmjtw4cLeBAK+DbZAQtkOAMpB27yXRijtd2zOoMkOB1FaAOSDQgQFBtZvZng79ZPzgaGlYAhwDgCHyyNorWQaEFWvYoP0ahFVm6sAUgKyAzt3M95xPzyAmUgY9Xd4M4BOcMA7kOHCo2HAEfnFlr4IzlA7L8mLcO98z80v3gQqKvnG0GNkV5MaqAU5uapz8vCidCBpLrx+fvzI1bK5UEqKe8BQAnERms6RqVAThGzMfIVaApCOyl6OgP8KbDZuey5TXSFEq3b/Qd0EN02/0DFm0usUeKTK8AAAAASUVORK5CYII=
""")

#id: 110 - Baltimore Orioles
BAL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAEJUlEQVRYCa1XbU8TQRCeuxaBvlElIcbEBkSjnwiamKhg1A8KaOJP8FcSQL/5gpj4AUOMEQ0Uo0ZiYrHXAgrtnfvs3tzt7d31SuJ86L7N7PPszOzs1SqXyx5liOM4UqNSqWRonnw538uEgXfmbanmOG5E/X8QSiUAcAaeeKqcVPeJgIW779HeXodyuRxlEeGD6OzZJpGACV5/YElbEKnPqb5dtOjrowEiO0+OcxSQiIF5LtXvWGQNKzsm0Wx2aWRkhCwzB0xwNkhqmQzWaksdsm2btmctsktRsCRbzI2vuFECWeDwxMQzEY5hkYyHKjF1EklAd98WqXEcJVQbcmnx2gGNL3cpCAHA6/eEqwYFiB9zfUMGRzu15tF+oUzFHNHUa6KNW23RlujQtWjYDi8VYD/NtunSqxJt3GwH202tlWTfE+EJCGAG4P1Iq9UiETrKCfWuwAP4ZwF02I1bX1kNwRkYhCGWnVME9MRJOj2U4Xr2AsAh7260ic+bBA7AzZkWXV5V+utCP6dutIw/boJMQhn7hVM0sXIsN876sQsV2pptpapNvymRy8yEFp+YDZCw1WpVDoMQ2EVUuV9UrZTpt5O++fZ9kSdWfB0latqPLXb+INzcQUcTJJ0wDq4sloJr6DSbtLOQS0xAbY/ULodFPy2umS5cfPS5wANgZornKT9aCWusyzoY6wDyjgs7Jsb6ZhsS8FdcV7AW10OkqOAUJwU1HZR1MLe7u0vVsbPy6kX03C51RFLk8wpOJypn9AKEapYlAGUS+gkLhQIN+eb8jiTthUeNSeQB/u3JZJJezzkmgVM1Gg2pOzo6KtvJlyhSKnyoFetaEYICyDEJ6YHOz7o0TKsBcjHlp9PpyNOAUFe4+f1MWPFgAh41fk39h0zfKi98GYxR1/shwe5nQz3zeQ4tPOEeiBKvAfPNCEJw/GM7sBlKzrnIBiCI07Lom/Mc2osCfOs26oXSZWCsMTj6+YFzkzS+dEw7Dwcob4XewCLklCxQqvBcFYWmPhd1sdKK/oJkfS4sVqh8OqiubcsF8ShA2uI1M2XTL7l4cMxkMnUxVuDRfXrdrOw752+KOPfKD6yBpBkSuD7t9CAcK0SYTBM9SfX7j8Cp0GSHx9w7RmCwWKa/+2H82KXchic8OZgJjrEMAVzEWfpRfFiYUhRfOfrpzXVzHITKUrllruvjaA74nwPhKZXq2LJqzXl9I+6zpzA+v/inZ/yhEzzHGOhvAsbBSTDw5fu8RUfx2ypXkYRclNijvRIQRhECmOiHBPRMqZ0p0fPr+8F0VvazYowAFkDiy+PT5B01WS9oUYz4iykpJP2enDdMJIBFkID0elalgv/jHnh04YWXGXPdBv3YNWQFjp35hxSEAGYXLHlz8AHDlY5teI9+2lQCbGxuqhMy19jmJO0/2V+5jCW73rQAAAAASUVORK5CYII=
""")

#id: 111 - Boston Red Sox
BOS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB70lEQVRYCc1XsU4DMQzNcfQkJBiAT4ABMSAxdYChMPAFfCoTqMDAzWyd+gkwdQAVjnK+47WOFV/cIxJk4BI79nuxHadk2wejhfvDsWnBnk0fmm07hxfedsghlHrIu76dBABwf3rW+JhNS8/X+GTosnzlAvp1iGRaCggcwB5qvVhUnx6w1F8+l85KYkMa83U2yB05k4OfWupoTcQRvZCeyzojQBvpJFo0JDkZMUskVgnktH6AIWpJlF5KQs6pBiQJ+NC+nSnQjDQ5EeVRsaTCTGA+/9BwfyU3E7CghGolFoWkBCwk5Z6kBGQNEFioWDmJpAS4Y+s8KYFQDcSIqH1AGhbFwBO1xeV3SdkDYuEnhyYC2skkoMfQuIimgMD7DDr91tF11FR9C6SlFgV0vsfhyH2JZpUsBZIMrQFMV4/G6+TOUZ3wtKBOsKfZKP6YaoBsQq2YO94/vmpcr/sgRWtAEE6+TEogVCdtGvRCTkqgT3iSEvh3b8H5+CZYvDxS5lsgWzF3grmsgWJvN/rrWCVAznDNXia3wFh+cceXgnrCewCXd83VTkgEMPo4tnRB8q9GgJR9gMmOwEONi3RyqAQo/KGuhhZcvb27Ks/dU/0G8AFwdEauC81VArQZJLgh6gIy/D+ItdRDrn3VGtAMUsu/AaALyHmdviL3AAAAAElFTkSuQmCC
""")

#id: 112 - Chicago Cubs
CHC_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACFElEQVRYCcVVO07DQBS0UZCgIRyCFkXKR+QCpOI4NFwAahpOQ0qkSIlTcAQakJAipaGhCDyTsWafd/12HUtEivZ95s2MnxeSnw3vd9k/fnop2tviLhreHz1EYXNrAyHRYjx2BEarlZMjsYw0GmDx780me53NwGuebKjJxFGIicXlaVPEhZM3xFxaz7sBDDCJHkzJsQ3fJmob6FpcjOJBwM3mHQMAYICBh8bghAb4kv4MMYSVIscJEeR8hmaqOwBnbUhYSGLN4RPHfXBegSbi3EfCfY4ZyzFjEJcbsJ7eIgFZ6ilbiL4DWCvMcI6YDQAnNd3nnvkKGMwCVgxRnIxfT6+qNHoD1URDALM+UfT0eKcGWFgLhnrmK9COm3IRhTAEJR/M5+UXs+hJnrwBHgYhTl8PNRgDFqe5ARD0zvuYiTq1IHhkmHvRGxg8z4PCTKhBTT3BlhvAv8XRcqnny5zdewEtim/v23LKfQV5HqRKMSFYfEOElzdPHgMh9L4eY0JjdK4lql9DaVi/CTw8XCyyvLe/QrtdVkwm3K7FfBfwygXkXEJpiAkBW87X02lNJKbwuflyYO4doBY7pnKrkLkurh8djpoBXg8POlMJCXMwNyicO4CinLgPqFmvBDicLCw1n7jUgwakKZ9UI7HCf+wRBgDURlBvOkNPzTPmBhgs8cfLbXZ6cqzLVR4jWoF/g2QDPNxF/AMGb9WCxchThAAAAABJRU5ErkJggg==
""")

#id: 113 - Cincinnati Reds
CIN_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABeElEQVRYCe1VTU/FIBAEYvTm3RifJl486+n5/6PvZ/jxM/zADsk0Wwrbra+EyyNpS+kwMwvL1r/4XXQdW+ionaRPBrqvwNl/cmD/+7447TXcLmIA8NZTcH595Z4+DybSHKSZMRmwRJyLlt5LRtQc2P+8ua3EYajEVTWQwN6XAnF+GLdcpcm5iWIS5iASQRRtyBsOqU/iY5wWW/BzO2YroIlfumAWp1GYpRHpljqTFeCgBKL/cLNbJZzPr5lI48MtrU9NHGSIAOAWLW1BL3EEFDTxFhHnnKGUIBL0eHcvXzfvp0r4HD9cflSkUvMcqGWpNNGqP9YBzYS2Oscam/2MtO1g9VorWkt08M0MgFwzge9WIzVhcDCvigYAWDIBTPz6doeL6SnRRDEHjeKpz0qYvmQ3mEDbKgd45GVVnfwLMv2x/GLisSZk1FJHNUCgPCFrjDBi8MioyYunyQCAJJCkGNca52gYswGSWEiJtTzHQmQBt8CcDHRfgT+MAX2rBfQkPwAAAABJRU5ErkJggg==
""")

#id: 114 - Cleveland Guardians
CLE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACGUlEQVRYCe2XwUrDQBCGZ2NS21IFpaBGPAnSk2ctPoQvoBTBB/BNPEgfwKfwoogHfQFRoXorVRELKiqmTdbu6ki6zqTZWPFiDt3M7Mw/3252k62ApTUJGS95sqszxfJ6RgUAN0vm40EdxgolaIl5nS7lVR8IgqF2EqAVgBLuyA7cORV4QvVea4KgjSEKkINIBaBH1Am/CqGw2ZqFzX7KZgHmi+Nwub8D8vVlYGFKOK2PBTjf2/7VwgjIAnge26Vz/c+Fh0Kq5R5Bt8tvNLaKWjRh6xhu/Gq8BqjCzdt7clGpxUZBuK7o04gbTtww752ZKdOl7bnVLdJPOf3mEQmLsYkAGPSTNvBnE9MzAHQSBc3OHD/7OtQaIDIr/NBmF2EW3VBGvUV6CVEUQrsdQLlcBH9lI1HKGsABjxV0qzW2j+uwfgScUFb/P8D/DPz5DFhvwwj4N+HLYR0Ko6W+DcGdhDDIGiDpPQDS+/Y1TDqOKYjhPgLisy/fnnGwZDtcAKLEdX4RzFNyPIwFUEnU4SKebN57uRHTNdC2XgMKCv8HmOq2wCrfGkAlZSmk8qiLfQQqmDp4UiKDfFJ22RB2BnD/4nTbjtoPGgDex/hQi6JgATAYk4PoDFzhwLWoYBfZTssLcEIJYqVG9pvOgQCYkKtu6luckWcI4UEsaN9k1IB8D05dCKyNFD+pAVArXuCufQqFiRwUlmvYbd2+A57uksVWYazdAAAAAElFTkSuQmCC
""")

#id: 115 - Colorado Rockies
COL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB2ElEQVRYCb2XPU4DMRCFd1c0oQ33oaPlFLQg0XIJoAQOQIWUKhIFEmcCpczCW/Ss8Xg89v6xUmSv53ne57HjKO32bNs3Fc/u/TNRXV6cJ2NjB1oPwDL1DKYAneQS0vx47JuuaweZNqAml6NmvLNETHxz9TiYw1ibY541ZuXzxhIAaf7wfO3NHWJzIRIAZMXK+cw1YJ5cGwFg9TSvWT2TzoGMAJiQ7ZjEY7TMj9YFkMK1+gGAh28to1zeAAAB9z8nXmM8AljDoJQzuglx8q0qTN2emoMZKuCJdQyQBEVMfrBixgBego8q4JWLEF5CxKBDS4jSfRIqQPP273dnSOCZUc82pwVILoa5EQDo75/K9z9Ndcsq6XHvPQKgkGW7u31x6an3VkhNrk0AuApAfH8dhnmegRfLmcrxBABBCUExjKaYsZrMo1sTACJAEERPst6pfdt/hDDNGQsB0Sl+DfVkXQUZZ6zv+6bGHBxFAAFrdmkqg+3vd1mCyZjuzwagEUB4+cAE74xpU/mePQNSNLX/utsXpy4GgNVy3+GKamw2p/8HQCcNYZ0RatEuVgEkq9lz6OSzKAASW1vhVWFxALm6mr7751QnyK3EKr2ltXTVFbASEtCKWWaW7gdaTqyfBlTt/QAAAABJRU5ErkJggg==
""")

#id: 116 - Detroit Tigers
DET_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABgElEQVRYCbWWUU7DMBBEE1SJn3IK+sMt4BQcl4twi37xBRpVT11Fnt11Q/wR27vjmck4lbqeX99/l8G4fn8tL5ePQed/S0+OTuIycfSwBhCWiVkjM2dWdwXRAGvN2bWMjGZ48ZUGBNIYkd869TMzUV4B9CLJiMDNzu0EIjFpYEh71uDAsNe8xajWTkBgDYghY3/r3p/075Xx6jQuj6tRLK47Yg7TTmAr6AjH1n21bcBT7OuUVxDf3EmBIRX2Dh/raQJdoijMmfXt8ycKuXWaAMQ6DLEjilhhzsvy7LCxniYAsBIH98icJnCkMGZTAwIRbWYm6yHk5tQA4u4wdYfrGGt9AwgdMacJOMHOm7mz2/pDCShyF/tWoNpPG0CYFNhXQq4/bcARVXUMb3Gtb0CH45tCFmuRmH6suXX7H1FFipkuDkMtAxUpZG7G3KhfXsEe8UwYM6mBKF6RRazIKzwGyl+BiDpkERPXCLnZfgN6oxkiJ1DVywQqgr19m8Be4u75P20Tima8EdwbAAAAAElFTkSuQmCC
""")

#id: 117 - Houston Astros
HOU_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACkklEQVRYCbVXwU4UQRCtgXUTQ/TkgAtEPelNE5GLJxJiwi9whX8gJJz9AD9A/Q0PmqiJJ4kJZy9KQiByEg0QQlj29fKamrJ6pmeFPmx1V796r6qY7mEKebzSl5Zjf+GDCKIKFThYl58WlSNv2smDiQTRC3D50RfKwVi9oqkDJPVE/y6/l6PdQry9ujidRLIDuQSaTM+ZVBPPmA7ivCmIuBxrE7Ex/ySQK472czCGa2vrkqgkQCIGWKL/WZOTGuSqJAAngQRcpfW4YwLIzAN4Cej2c99WRr+10NDY5ClgYH/rNacVu/drX269eRZ8d179CNa70Yonq5U4uwgdaFO9JRhlrbsQLiK25GbPq0Hkz8qm3J0sgxYqx2D1uIgwTje+ysHhqTx80Atr3aHgUD+MQSLxGcACG9xU+ChGH8W5hu28nI/iXJPPWmhxdHT7uQFfqhsMHMWSH7GYQyd2QBNiE1n3+/p1pxHt51pcRydPAQLePd2Uudu/K90Iz8L6z8gxEWf+5O3OrKx9f+RvDrzJBBCx9G14zNCqJiFPIVW1xtYmQCCIeD62d3bpdu29meEpyBEHQVYCWql7oxNOhXdaeCFpfGrOh38MmWLRZnjibeI11j0FGnDd86wE9PtgqizFa7X16Zi6IuL/hPybWHCKCFdt78V6gKcw2PReRlorqwM2qatcxw6AVGdGEb77+eA1HS/7QFu81ah0IHUicsWRtBVkIbBWHL5KAnBg6CogDtI64mHU5a/Gj19cYZrzEomPK+fTLIJH/NzSApFr4PSKcG9CAhHcHVRwUvkI1PR5c/J5aLcDGsgK7n9ekMOzcb2VnE93j2Xr+ZewXycOQGMCVGEiXFvipn3GWZudgA0cVdDynAMxjBOkRq7N3wAAAABJRU5ErkJggg==
""")

#id: 118 - Kansas City Royals
KC_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACIAAAAiCAYAAAA6RwvCAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIqADAAQAAAABAAAAIgAAAAACeqFUAAABnklEQVRYCdWXPU4DQQyFsxHHoOYgFHAIqkgcgpqG9GmROAai4RRp6ClyAtrAi/SiJ8sz9vxIQKTIP2v7fevZrJRldfN0XBU+x7eHwpX+9HK7dZsv3Kwk35835+j6/uXkezlc8PJe7jxQnLX4v+ouf+Vowo3oanVls/KcGYKg0IoypuUwxrQ2z9izKRA0cjgthzGmjfK8bm0aBI1WjMNa8+xT2wSijbP98D3Cd8dsYTsvBCm9Ce2gTFx7U/+fo+Gd2rvBpjQ3urn0RlRIfYDamPAtNg1SGjoDArO7QXAssyAAEv5qUGQ/NQh9btiXAe4CgYAHU8oRqGa7jgZ3iK/evfoqmNkG6rtAKGRhsqLsVzsEooNG/WEQu5VeoGEQFb5af2nY5KdB9GFUH2p8Nj5eH5vEtTj986WYNmd9gEf96Y1EohSy29rv7kIIzE5vJALBdQ+Guai/CoIhmbVaEU98ORw+f+oubS3j6h8sFnHdngBrajbTnwKhSOt2MgCc3QSCpszwTA0BaJtB2FgSQ77nCLtBLBDjHgj0DoMQYNR+A+VlpegIj++wAAAAAElFTkSuQmCC
""")

#id: 119 - Los Angeles Dodgers
LAD_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAA6UlEQVRYCe2WSwrDMAxE49JbtrteK931nileDBkUSViuQBiajWJbn9GTCWnbYz828Ryfl9g5l+35PhcJb7eEHD+lKBfQtBGgJR5FNnrUKCfwF1BO4I7LELV8QRE7c1HLCawpgPHPYMfIuk0lwMK4iPeeKsArZJ2tJ4AxY/6wVpfefjoBFugVxtn0hwgJPMtiLErpBDxB2tm0ANmRXGvFtL2QAEaqJcPeqF/3v/wRRYJRcMRahEIERgpFfcoFXEZgdcCjsXD22FE/1CknsIaACFYeD8cBubTlBNxL6HXAnaKrqH+PKydQLuAL5/o8FLivrBMAAAAASUVORK5CYII=
""")

#id: 120 - Washington Nationals
WAS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACaUlEQVRYCbVXTWtTQRSdl1fBdlWCQVxZEvo/+g8K3VjUteDOlb8ju0K3TaGl4P9RTOiyWBBBEARjzHnhDOfdd+e96asZCHdyP845c+9kSoubUK7Cltf0xVH4vPu8YjlbXNfYdmrftvDl/fhVuJ9fRuTRJAQVMYiRLWw+HJzUyEEBMRDFtVUB09tPYTR5Q65oVUTWCFRxRFlvtJX0I1f92KPtWDqKjSeEpAAl9QrtyZiP3NFhGcLfZRQCEYyTOFr8CvTzbPx6hU/bQtzWePldeYjXOgCV3mmjWmfTVlN1Q279/p9fDYR4CduAtAqt54xza1j/Y2eP22irDnhAdsY5nRlO3lbA3+ezSKAbXkjFqo2AyTmntKJBfr64qiCG67ZThB0DOWgHFkjJmUSbiik5c3NtvAMosATeS4Y8K7oM/f+c1ASgXQDn+j14wm1DHANWNP20XfHGHeDMAKCXhYDWLkNhXSHVEds5FA42N7P5XjdQMx0eiVfKzlQjUBEMaJHn07juvY5o3O7jCPgbhf348jir/Rasz/faJQQ51s/yaR+sqkbnr51LjSZ2IMWoIKkc+t+NT+MDRJ9nFbPWASSnlHpAbT4lAebdlws3vbMDbpU48eSOJpuHiM+vhOO2LDdnVWEIPloAQOzNV5KujjZGAMCupT9b5nqnt+QqjHW9BLCYVslBgmXJmWtt7xHw3bDP9bevs1AUzefZOz3E9O5A6oQPIYeAwvvXzIKzrSjg0pMjrt+Zwzo+cPSrzRqBB64g2JNM/W3EzHMFpObLIlqS5hCxxlpXAJK6RID8McQUkhSgIpis9n+QA+8fSCp7mb6idS4AAAAASUVORK5CYII=
""")

#id: 121 - New York Mets
NYM_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB30lEQVRYCe1XXU7DMAxOxp7gJgXtSkg7AsfhAQnOBDsJ4gko+aLacRI7IV0RQiJSW/fz3+fESTfvDnez+8Wxs3LP1w8Olxwa1tP3fLw2A/MUEnsZupb9yzEDS7KZEi9hnv0p9wG8x00blEAGJuxtetRcXNR/7N18uGc9+cSiGE2CugQaU7gQmcvTbYqwSJTIXbwLXWovK6ZKQESoRKuSyvCbwDAB9MaWJMYJoLINSQwR8M/HNLEbkRgiEIuX269LIhh0hnoOwIc6vvSPs4DEdEjtQteHrUddznjhyLukxNccRBUJ2m2tgo2DaHgJUMB8E05KBKTlQOIlOWOxUmIWX9Rbk0AeTCQMoSoSASvtkVHDgNNQCdB6kpF8VgE/U4h4PhhFWzG73wKZnGUkQSNiKeQARs0p8Iq00CX6AuyJWjWcZOmFXgzSryJAzuWTSZSKxvtqAjKZJTfysmo1AY5wpqAS6H3tND2wKy9/C4BZagjNBxbmLtC6mTFjq71OT4iZjZ6POgOyy7G+dFFkqdcwsufeCN8LzQe+5seIAreeVB0nahkbOnUGDNsfgf8J/K0ZkHuZGhCNkcn4VzUwzHPAiiGTSRvGjTNC2kp5aAnKvUz7XQYsbaROk886B7SAo9gXR3+qFEXscLkAAAAASUVORK5CYII=
""")

#id: 133 - Athletics
ATH_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAADvElEQVRYCe1XO28TQRCevbNjG/K4KOmQ8oKAQocQCKFISDwSCXD8BxC/gZIGAR0l/4MGE1EQFERBBUIKFKAQEZKCBhLZsazYTpw75tv13u05uTtHMaJhLe9jdh7fzM7O2oIunfPoHzbrMLZL9zcJ3262jgBow07+s7TdTRCpJG9grK+wSjZ/0JzCOvdNKtFJGnwyJGlH6WIjAOP9+RWyXZiQXctWIu6OMSVqqsxPhpSpCCASKxyFySNHIRGAGWZ19oiExfFIFA0Bj1rEHoFpPFCgRCwGkcuOBOTW7LAJGutGkrLM7CKV6sEx1B+nKHN1hfZyV8h+2JCQDtJhOhYJAILO7Aei7DCHG/7qpo5ArXo0UY6ulyM3xSo90BuyZsicQakTitUDnU77uRPoVfvhvmeIysVxpm2H6aEbEWxl2LBFv6lmt6zpLVGm6qsbvNpgHOo6661YAOX5CYm0Upxi/qaU8TyvBQpLl/puL/nVsSY2qfb2DvU+qEha3xxqBtHuwk0SdoOqb+7Szutp33vsRR6BeU5g9PgDv7ZeTGDJIEZlUbLtQblGt1vfpMFH/pJs8ZMXJyg9847SLktbDaovTktwWn9sBAJV8JVZW8+WFjb3MTfpmJeLl8l1WzljAX6WstfeM/BlP2qREWhXjlLsCigzm1o7cx85sc6HAIBr/GmFNnIXeSaoXPslIyYT2s36ShIjgNswMLcmBSoyIclHrxKUVYhhX6E5+XGvn+yZZ7Rr7SrywgV1m6zAkY4jAA26DJtGoubyGnOoPS9N6etL5FCdvB3kUWAcsocCoIxBAQKnR0UFuBKN+seAHCjRGbk5wA8aiQyXB6SyRRVOYJ0vsQBk+PPrJHD1XowqS229U/jOlFSbX4pJG8GjZTZNBy0WABgE7bHDqniYgtgDwCb7BCVxydQuB1nd4uQUDxt3W0VIC+kRiqvFU3rJObLqJ6gmAiS+US0SAISc/DcpVyl2+usnXGahYyC/HGVb0vcdgYnWtTIc2nDWQgo8ZlhRnoVAoVFN6+gtrNFWcUyTDxx9AFrIya+Ry1UrCA2/+zNfOaPxHqjm5L/w+qwEASAlGvOvaPiqKvAmWK1DjxIAjDu3PnFK9jN9j31OGQBcyuSOUUb+GIWYKx+jfUqNJ1dxNfm6JR+dHwGXjetKBwVmM71C9dtnHMyiyl2vL2Zx4emkidLzkdYTE35MTGF9PKAdaJzp4DnOCZe2stRoblPt5VQkr6lbdPOvWSdATeOYdxVAu/JO1kGyd8L9F3j+A/gD8NpGOtOs364AAAAASUVORK5CYII=
""")

#id: 134 - Pittsburgh Pirates
PIT_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKElEQVRYCe2USw7CMAxEy6cScAlWCAmJU7HtcTgbRwFExaezsBQ5tpOWuOqi2Zg6zsyLE7I4HvbfymHcrpvq1DyTystkxYACmGNQtCTW1mSOgLW+re/dtL1HdfZfc4DV7S7ZBRGghHnYGUvPPIJQBL/f2091vrx4OvqWDCnHL2bUASqMVLvE6hGVS2Xm7ef6eYqijZ3kO6Vqno8AeAEtLBEl7QgARlJhCQBJQwQYE0IFkGg9cqMC8H8ANuQGIJnBkOddALgJjGnwC97rJYSIJU4mUuTGVOPSARKnqJlj3h3AMgdA7yNICUK0zzG5dIAgKQJKGy4AMMsxR50bAMRzxgwwd2C6HdAeEy2fc+Olmul2QKL1yKkd0F4yLT8UTgWAIDfj30NNw3U/QCBGzGkW/KwAAAAASUVORK5CYII=
""")

#id: 135 - San Diego Padres
SD_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABPElEQVRYCeVXMQ6CUAwFg4mjF3Bzl/Po4NlcPA9HcTRx0JSkSWna19JAGGT58Nu+9/r6wdhezqdvs+G125B7pO48AcPj4IXc/f7+dmNewHSgQk4ElTrXAVac6apCzPimAxxMr938cTF26AAnorW/vVAYxpZxAFLgYNqB6pyjM5R2IALy+oyEpx3QBJEgSTw8j01/tc9J2gEtIHqeCPz4H6jQAdmJJNX7E0KZGNybDlTASJAWFXCPYVMARSoiMoQ6B44gK6LSOQuBAjiJV0mUFce13uqOwCtYet90YI1OPeGbO4AF7Os/s17Heh8LAF8wDVR9Ns+ABJPnIbMvczL3pgNLvWJlAVQ4VwTlz60hHjgCDSjHoWMEVrnMEVSAqjWrCZBuIXFwBKgwS0AYaFxpB+YQSuGInPLav/93/AMr5kevP8pFOQAAAABJRU5ErkJggg==
""")

#id: 136 - Seattle Mariners
SEA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACaUlEQVRYCa1WsU4bQRDdIwQp6BASNPxCIAUSEgXKB1BESpfKTuEiqZMKUaRIlSrQ0iAE+QQKPiChiIRCk/xFigjLEk6iy70xz1qP73ZnHMYyuzt7N+/tzNsxRfnkRRVmsP7mwvit8no4nnsn894XCByDap9epzBcBBAYwBen76Zi7r58H2JgzqceVI45tW5dpsDxEkiBXJyZ1mDRRmHRQBu4nDr0Q1l/4qwwGxYy5gzEADgAQcLmiqT+6ccP0bns0ywBnj4OSXCmnCeF32tZAtaAIAGyXhL/RQCAujTweWwmAlS8BmIptD+1nokAAuqTE4Sl4Do3ugk0qb2/8zDgC6NordlwdUIAfH67F0CiOjvDUqw6+iRj8boTykvf74I7A0AC+I9iS0D5B2sQuXcRsqb6eq1XV8QORbcbNjrrMsIJElYiplbcJjiAPTs+COe9N5hOmDSrWhfl5e8Jv16YNNAkPAbSmvjy7Tu3TKNJAyiDqPrrzxAWK9EAdBALUaNJr6hPnyuFiQCDlwtLklKovUmE0ILXXAQQXPQwKMLGq8cTWBAlyzGxkVlkCWhFQw9Skjq9yASNtQcJj2UJIJhcxbtOJ1q4Q4gVrq+plYSJgCUYMjULCTMBnJb9Pib0vDf6XzD2eeZmAm3X6vaPqZW0cjITQIS1lRGYvtv94c0UgHTCuiyxZqYeqh0uAieH+6OAf0cNZnxDtlfFn2rZTeDwufNHEC04+hHUeno3AYICLAZEIJoHHO9kfw2R5sWrX2HuwaNxX0/VFc+n9kmUo6kEg61leZ6BtQgZDCOfiX2peZZAU8AmXwoktfcPZQQOyKV6fAkAAAAASUVORK5CYII=
""")

#id: 137 - San Francisco Giants
SF_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABn0lEQVRYCcVVPU8DMQzNHWXuBiMTonRiQYgRiZ+NxFjxMTBB/wL8h+Y4p6R5jWLHSU5cpCqpYz8/Pye57uryYjAzjn7G3C71Ikfg63YwNRKt37octNsXFfisTE7IFKsZrAIxgLYijKN1Lo5VoF+ErRwIVlriS3GsAqvNMMqI0Pp1CQmWQCodypva52wSoaAzFz2BXSL+LwSkGtgWbO+MsfY4lKTEaiRpfST6exvOrALWhnucA0HAeE0kJaKd9C2oTdyNj+D16wQvocQ8rhT/D0E8NCfXogKpCFQlJri52Znlaejqw9OP+V6ep2AOtuB9MNUv7j9Ojvr9/HiWBZuUQDZbwoG9hpLUHoeuqhnPmt3tmx63xPtJM0tACvJ7eFW9rXRuakHf76/a31Sa2/k3KbB6IQzdfefYNSnAgZbYWQJ4oPBA5sBLfAkr+xCVAiJBLALtuGYV8E4aEO+LszZOdQgRDBVBOyYvWWcVKAGr8Z2dgKoFVBlK7yt1tvEVXr/XvwV6BQq+8Z6gZlYTcFUSiejXUj0RVLeAnFuTEUY8fgEFwWvalBhjtQAAAABJRU5ErkJggg==
""")

#id: 138 - St. Louis Cardinals
STL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAC7UlEQVRYCbVXzW7TQBAeO0krgeACzYFSECqlqngDbr2gvAM/4gAH3oVHQKIqHHiEHpB64SGQSEiDEAd6qFBOtRuH/dZde/Zn1rFVRoq9npmd+XZmdnaTfL33ZEkCvUh3KBFkf3ozOsozQbo6ux9ThfPJ9CCocuPhfpDflpm2nXDV+lEACPP2g1eWT3y7PEuh5Uc0BcjxaDALmtxY3LdkXeshkYpwNFijoXIi1QBHhXqAriFEziUJYDACL1X1z8cHrg3xez4+FmUQxArWA4CVx5zfvfOM/l77rR02OYYS6uWokLerB4CHMsty2tt9Y6VhfX2g9z+AYmW7i006o9rMRX5Bs1+fNMCtzef0uT/VY+lRz1Qa7urhPJRPGKtz6jjolSHHQpqcw44FAAxDWB1CN+qtGVb1NgVaMZzBcEEl8MIRBD5FAAFdi9W0O2KFxw1FGxFX/F9jKwLIK6oWq0OFlx0vvKchQ33wXgHeBuV0SqpQI5XPF+NFYMmkBghj6SH6BIjvGM1QDzgHvU239bvpEeyEcNCU4ybDkCMiQxWRd8WJqB4EAO2rAgFbAHJYfMfQIxEANM1249EIVbfpiEZ2K9uik5+HlbPz85xuP37KekclkvsAVFCUodOwbkIlyNrcZYNKJrpLGmDonhJ5RSgptuUDpIlIbK61DY0iQt+GVnEk2fMAlOdBfbw2GefpkJzE+BYA1zkmmjxyIzxCLgAuC83ldjC2dgEmo7mgGSXqN/7xgZIEI5+WSunmzr4vUBzXcadtaFbCW23QWwMTzj+qHsA7LJ9ipYALTGjdbQiDvC/wOXy89+g1ZepyggYkOYe+CIAbc8cozNA5YPSuU0Hvi4n+RCRxgz4V/kl1AlBGJ9xaDQg3hYgcomkia/SiAMpTzz6OcQSHbknGIH+ffftC/b66oylC2gCCyAYeBVAUBc2nx5hfkVvhlaDjIAqgo01vmqkZfcF17olRAGmaXobNs7kyQ/tTWdDHseMcRv4BiiQh4Af6fuMAAAAASUVORK5CYII=
""")

#id: 139 - Tampa Bay Rays
TB_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABq0lEQVRYCeVXy1HDQAzVOlxCBVADUEXKAHowFw4UwIFThhYYymCGHhhqYIYC4BA7wRJokTWS195g+4AvliXt01v9MgnL04sdzPgUM8am0AdM4OPlgcXs9/rpDW7K60HnZ89AwB7g2+MNrKdcHUd1ymdoFmIJug6WqjxWmrVPZJwQ/qwEh2eXiVC2mQh4abWP+NocHCqBlVI/jG/JwYk94MPaFm5c29rWLk/OIRR2tW1t+7z5hemuqsq0aeXn6yMgYYt0dgYo3es7itU1prjnr8QYIwnZsNkEMDLXXI8g64kdElBjfNsQZ5/sEjB4n3ez7Fy3SQiEEOYl4EZvDJNkQHa/XvmjE9hs6pgAHRwNe01BRHYEvvm2ruH++T12vnQfLQMcHIMViwXgrkAdjqB8khmQQHiwXB0B/IDwLEtAluUPk1xUJIs94BLQgRkYINBt6FsA/dq/pRa5xs8j4RKQN9DgQ7+JjCLBGC6B1g3Ye4834umVjXCjNWFfrv+HgNfUk2RAB5cbkf4X9K2X9NOg0tYly+Do505BFwjacsdUT1d2BlIE+9on6YEuMl/j554SEbiiJgAAAABJRU5ErkJggg==
""")

#id: 140 - Texas Rangers
TEX_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABkUlEQVRYCWNkMKr4zzCAgAXZ7v9n25G5VGczGldimMmEIUJjgQP3VzCAMAzQ3QEwi2E0ShTABNFpRoNyBgZmqFv//WP4f74TRYmocwvDmw9f4WKkRCVeB8Di7MCjVXDDIQxUB4DEYMHK8v8vA6MxRBUxDsHpAJDlMEMhxhFH2ihFw/WBHELIETgdwPX/D9xGB8UIOJsBFAUIHlYWinqsKhCCOBPhN0acbkPoJoIFi0ZcSnE6AJcGaoujeJOQa8m1HJ+5KA4AWUAw4WFJADxcbATdhstckqPg/wXMLHh/cxkDKQkP2bWMpFRGhLIULOuS4hiSQgBfXEIsXw703H+GQ/eXIXsSLxsjDeBVDZRk1C9n+H8RNRoQljMAoyKSkBEo8iSFAFgnFh0iAtwohpLCwWIcKdopVzvqgNEQGIIhgKUuoCQvkFwQYasLXu+tATbDEG1CUhxEVF1AqA5AtxBWJ4DECdULQzANoHuXQj5RaQBfLUih/QxEOQBkCa4WDaUOIDoNEEpM5DqEqFxAruHE6AMA559km57PrhAAAAAASUVORK5CYII=
""")

#id: 141 - Toronto Blue Jays
TOR_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACN0lEQVRYCeVWO0oEQRDt2dlFxFBBAzUW/N3AyEhPIOgNRDDwFIJeQVDMDYxMPICBoOIBVpCFQREMRPfjvO55S29t98707MoGVjA93V1V79Wrnk80vXXSUWO0yhixNfT/IJBcH3qF/nMFAD6zfaowuohUvdSG3CAYwH9abU0CKUmI6UdGgIBMDGBaLa50q7fXsR9MQAIRZGrzWE1O+NOxDfTn6I+gRzYSWFZANx/413dTfd4caTdXbCECsm8ELTICvLG8oGaf6k73gQRk1Y2rAxVXY281EgHxAIdhTFISUoU+AgRF0MLqnqo/nOO2e4j0JJvLZLafa8+OxT18InwLbNC5pR1Vq/XyIon1jX319v6h83CNSTmyYkrOOfblGuZRJzVUOsgAlueD+Lv2bU8aAEgC9hzOmoCr6k76jXx5NPLbWe222Ou4l8nlvmve1wJZqU9qVzKshZDQLZD/A/Z5QEIQ8qmBfZcVIQFwHMLe05Zmk6c3yZ4CKpOniG6R6L0kSXCs6xZIB9ccyuSR4H6z2UrPz4WK02+ArQaAYXaRhQkgMJTE6/MlwrpmA3OxrwXcyBu11Fl76Du/squiKFJQAOAuQPpyDPohQUL7DFByJMNBDQVHXBABBPhILK6Zl1nRypELFkzAhJkrpIZRCahTRHYTba6lCFCFavZlRKoy4IgrRQCBo7LSBKgCiJStHrGlCSAYVonND4qZhV9LvwcABRWS+7Pgg2fTDHoT2oGjuh+6BcMSGTuBX++G/43JEvuGAAAAAElFTkSuQmCC
""")

#id: 142 - Minnesota Twins
MIN_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACPElEQVRYCcVXa07DMAx2JtbBL34hEEMcALY/cB0QQuJYPIS4BzcA8dgRAIE4AGr3CPFWp27iLG23QaSpduzP3zd7yzIFhyca/nGtVebudIpUlJyl8PNwDeuddrFvLNU7LfkxR3kdQKLRGPTzTQzbKK56ZwY3sdiWtZixKnKk0INbxgQQHYE6MC3dyNs/GgGMx0WBtTbop2vrB9ufJKAfr2weN7wO6IdLG1fHFwCYkaazFye3WRWMLINprTxVD+4syBNgI2gg8bKWqZVmpoPOEkcQauXrx1cJ3t/fK/no8Jx+d8cMvfiWrx+dAzjj8ARUJfeYhY3X90+729/dntk4DvyqKjUVN38EOZy/K1uxpuHVyDsTFeABaxLzdKmWNwICmAbBizNzjNlWUqLzdOMuKfo8J9gBlxxBHOjwBl0Jw0WJAngCVpaKBBmFgIQnDk8ABYQ6C21JIrBg6TMgkYeATdS454IVIBE3IYhi2KFEud4IKPBXz+kIqM1SJ3CP4ouKcutj3VIHlkUkCXXJKackADclEQjemhS3GAJXfUrkxOMJCIm4//zOf+nwjIyvTSMYieeRYxX/TshqD97fQKvypZOFp+ZED6FlctqTDIatxA17Pr1zCogdoGCv6//eU4yeSI6rCTni5grABFcx7jVZoTqlkzBUmMDSPEMY2ics+e6zkgACecWcW3FyeAJDvOnUWNER1KhVmxxrLySA/yfAYvy6jX6V1VhAiCy0HxLTSECMJBbnYuYeRDxxVfYvEfDAerpmv1QAAAAASUVORK5CYII=
""")

#id: 143 - Philadelphia Phillies
PHI_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABTUlEQVRYCe2WPQ7CMAyFEwRcgKGFmQF6A+5/B2AAMdIKoTICA4UMr0qK49RtJASiixPH9vvqpD86TxeV+uA1lGpX16tKywOblk/mSo9HbAwWWwMkxw1ygjY97+qYYrqsx9RgQDmbPom4NDcAoFUfccBwNdgtSI5r1AjaYprVMWRe9TrrWtcxGHg7wFEj2WdtGMQk+RZDx3oA3klNVjHLVOhQoToFgTXbkgBkC02WaWPkiwSIrMGWEwFIzkV1v7HCWBQBIKmNTc97J+yUrZw5JiSA76D5/CgGS52hR3nBsmM19zGyW26L236nmmdi5zZD2BcRl9gs5JuHapBb4Csm9YfETT22A1JBxLcRRmxUAIkwAKJtQRdxAxENAHcktX+Afwe+rwPS70DoqRB1ILa4gRMBhO6my/pvAHR9DYu3gPrV7iNuANg/oi57Ks15ApjLTyQeWo8UAAAAAElFTkSuQmCC
""")

#id: 144 - Atlanta Braves
ATL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAACxUlEQVRYCcVWvW4UMRC2l1wEFBwJCXQUCAEpwt0+AQnQUYDEm/EUSEgJ0CAhhVDTXECKdBUFiCK55SQahIJyy3y+He/YXt9uLptgKfF4PDPf/Hlu9bW7T3P1H1dyXtjZ8LXK9rcDuIWA0zIDwFiD5U2VjncD62fmwLcvr9TlxY4BDlAF40wckFEzFqJfufeMj3ZvvQdGlPK/hyMn8hg4vGg1A4j8Y++J6n7/bSOsI1pzAOBotK6HOCt6iLZSAlPziYfc8NiKA8AarGwGkIg+z48DvmSc2gFOvTQq6dW15/IY0Kdy4LCoO1tNs3DQ8F1sn7sJTd19qzXhsI6cBzUqPoJ7RtfzQr3lSn+6gydWqrkc8I2l4w+qe+uBxFdKl8/Cl5eCczmQSwuG1qqzuORwJ8ULz4ZbDt8/nNgBRLPnpV7WlAESNVGQVXnijOUyL1PJuZuQgeK7doAhVzUV9Um+iLLhNhl9aDHT8Q7RZRJzlVN2ynsrGAHHfeMMHBA4dRZ07BosP7J0jPh1e0ltfNqq/CmGTq0Dpo4kKJ9cDEzyez/eqeTSRcOq6hGWnVkCgKPjZdOxIu/p+D2RHfqDpFv3qpqzHu/RDAD8iKT2RcezUp+GjKZqANKPLqOZIPuEdXjH+MZC50DXdBDAONXmtvjH4P6UQydAebXiE8vvE3whyZWQ158pqLx4jwmAY/VNsx3zdOS9Seta+G0nQZiGntu2dFMw9ujnG9j2DUE4yEJir9lm7Y7M9MXvAuxy2quUnR4wTnjKUqlHd37N5T3TftT6z5ENDhhymVcwojceGyAsfJ/AkY/qurNUuc8qLaTWhy/VwvUb0xJoLkyp71Co+wXiNAWHMjLlN680CnDI2DnA9fdTxEaapF4CMD21e0yN/tiw+l/fKH31ii2ldcBV4FP4zsub5tTu2xdq/c5NqyCDCRywUudE/AOmXf9uiiAIrwAAAABJRU5ErkJggg==
""")

#id: 145 - Chicago White Sox
CWS_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAB+klEQVRYCcWXwUoDQRBENxIERb/Bk/glIhj0KslV8a8ieFP0Iih+3SZSCy/UTnpmx13BgdA91d1VNbObQGYX52fb5h/XvFZ7/fqVbb2/W3Q19ZBnm5PCrOYGEM+RU4c710fd46AByJ00wiDdtvPm6f2j+iaKBiIhMAQVU3O+974oP4hAx1aLK992uQT4CMAUcW+gAAwaODrZf08lhBinTfcFzV5p0IC6IVeenlw1TBDVV7uqDCyvL3smRJ4aqRVM+6oMHJ8edoJ+ExBNNTL6W5C7bn8kmCzFogENcupUMIczk/bnTAw+Aoie3757HOAygpleQ+Vm8Aacx4XcAD2OkVPLxcEb8EGRQowZx7y3Nt//lclMIpgp74xRVz9mwaI4aMCFIXRy6tQikRKWNVAiTsXSfdu2zePqtqS7qxXfgZR4N2UJPRi2UpcKz9XUEN6ABkRcGnRh5fSDi9x5yIX7Cg2oAXEnZJAa+yi6IOaivvARaIBPOhSJg2G29vmLO3sDqXBuj6jX/fSY87rnv/ol9EGIIwP01fSEjwCCUkQYEUVyzZHTl+MabcAJh8So+wz5ZAO5EwrfbjbN+uUTrTBOfgnF6iY4rbCH5U0nChY5mHwDTloS8j7PJxnQKRHVPyItYY5Td1HPR38NnQQRCbPAtHecOvFPDEA2Jv4AwjQEsSFRgBwAAAAASUVORK5CYII=
""")

#id: 146 - Miami Marlins
MIA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAADbUlEQVRYCa1WvW4TQRDeAysiEgUWokljvwEITENDzCtQoYSkp+InPAUgniHYRKKAgoIGKU4PBY/gNAiJoFhQgCDimG9uZ3Zub+/HKCOdd3d+dr75u3PmnMvpaaQ8L6tkWdaov4yw11U5mxyqKgCdFojOANj71pCXzM3daYFYDgDcv5g7R0AEBFipbHQtWysAjtSkHw4tCBxjZ+DZkrkzhU4KKLqp3GGw9qTOfeqFX1mRlZi8zXjnGUv2nzxMZqoWQMr55+u31M3ah33dpzbWMeSp6MFPliB2Lo67OsXFiBgkjpNl8uOMEuhDijnVWM/kXPdWL95TxDBVErkw3JTunJQfyEgvOMeemR7A/zi39/Fd4tj6ISAsIx6XgA4AwsTduzV0SDunfDr3Er9sDstnOs2ePnLSHaW7XtLLK9afzF2+OdDS9GAQjwyly60ZN+NPr/U00115AxAgATK7crvqHApoe0M8BQyC0FpHRocjtGe7l24X3pvZW9d/sJt2HkUPGy4BOpVB/CXUNv1yq1ljhxI57Bej9XrnuCOKXq5FA5A93dDSfOh06OpDDSZ0fO1mzp1u5XbvddXWyzgDxGwkiVqijZUl8t69kTuJhXIG7AS1AoBzdYyJiLoazoVOvh/J1tHMO3d3qOeLK+n8JwFg/CRqvUE2FgSB6cuYWmBwHvn79qcmBXSv1pT7AC8O4qHePy/fUBnXl2TM8zpsa/e4i86Lq1E/mBeP9Yc9fSgD8TRsDNz5vTkzV3f2gpB2OcmYVs4Fvo2csgGdPIo+KFd3JQAQA8SPOwP37n14+Viz1ccE6vcvZlXKRPlajMY0itNyr7QACmmmIEHJkXr1RccM5cFDKMJDqS9s11WP5Q3ph7ySAQ4t9YOoTbp1MqBbpP4S7UgJmLpTcgqS5tlZZlfSHpS/8vvg/m4JaDwNQT3sNI116acSFt9yWjX10v1+Tdq2pJ8gdCtBjrk2LxXGDth4B5iy9OPoWbH5p70H4KSOvHOKnj9EFbWW7hd9LkEyhUi9pJrSSQahBJDRU2vnbSGHXt3T3IRRiukSJjRiaQpE0JQt0YlWBgCQ8kVjOWpO6Tt+vu36kQEcpyYBuknaOEiyhYkqcZbsV02EFz4e6H835plmlCwUGRaL6ip/y6uSgqMAUgpJY4AAxVNRcJf+/Qd1lY9ijEsKygAAAABJRU5ErkJggg==
""")

#id: 147 - New York Yankees
NYY_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABv0lEQVRYCcWXz0oDQQzGd4ray/bgWVRQjz6E//DqAwv6Ih4E32CrYLF2NQtZvmQzk8xeWiiTTPJ9+WWKB1N7edM3e/ws9jh7GB0GWL+9NvT1PtE+9gkBRAazIZ9RjQsQNeLBeEa0LgAaUlwyLdW0D+cuwOrqlnurz4jWBKBNcBtttNskF0Zr0A/FE4BcI4q+Pl4wHeKSjmt8olgA6AbM9UZoomPs7dVr9RsxshEZCtkUIfiOTrzHuD27x7bmU71WWu5EXQBQpQRh1YTbf5KO5ACsW/oJAAmsRt6yPb1DTxEfXzyKnDXiUiUmgOoZUzJMy34EpJyHEPR28TP26mB1/qCvhrwKgBQ80HQrXR7+mtUQwMn1kxBrCOsnE4JCEgLovrvx2Qtes0ohAHau2VS/EnvoswqAxDUQPKykMQE8em3o9TOIdZoAVqN3NxfCBdDblkAQAnV4r/UugBZ4OQ1L2wOvbaxPAEq0o0oFuC2Vuvdn1ZFPJwD51nJFQ0QXEQBRUQ5FQ+T68F4AYIHiOYY5TW45AZATazAvr/ERALh1jYkFRPqIxwQAISxjutPPqXPUeRDxP1h0rYxLEGnf/57/ATjXmnGcbE8GAAAAAElFTkSuQmCC
""")

#id: 158 - Milwaukee Brewers
MIL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAAFzUlEQVRYCZVXy28bRRj/zezDjp2kiZ02SWNIi6jECSHxEKiHXpAQ4syhoqC2aZqqF/4bFNqUFEEB9Y9A9NCqSKjqAcGhL2jakLh2WjcPe3dnd/lm17s7411DO5Z2Zr75XvM9x6z2xichXmK0L21AOAKmHRPVzzSiRXvlkcYlgWvAgo1ZACsERQJMH/WT89q5KlgVKuHqXiNSNi+kQPPiAyKxMHZqDv2LRyyEL2IhPgeMQGErlwKRchUO12GwfVK+by0VkQ1zQcW0sLZMgu1RjB/fB8tiKl26DhCCo/jM4TsoB2UY3MTa5U3YDkd9cX9KKxeken5McDsWTkejS1WQLgiYn0ckyNOVx4VwCSwFo6SeCUHGmf1iOhLeXmlq+HkF+D+4d+F+hDS1MAfDtbBFQlqrf6NibmnEjMwclHsxTOStsPnjmoYfb1y0r8b85V5ToAoPm8ss8tXkwkGEjKET+Z9cLGy0/QMaQ3k78JgFI9zBYe7mYVOn5xF2snjRFHi4uofpszMRH876R8H4IF9tz/fUsNSOCjee4cA3RHqWKvB4mfLY304P0kW4my3DgpJR8tLzF1mYoQnPHUlRUwXK5ghqi4fSg3RhltLloJlZYABsuAK+KA5cw6ao7o9UAaALI8x8kyDAHy4g5CSADS8ljBVYLGUcLzIFmIOAfoNjdmF+EBTtZf47bheuEaJ9oUNZ8jCCR1bpU3Ars14hEwKm6ougOJhcmf/uK1SQ4pQqoYz1lbtEShFOFvB2bMqdDly/hA1KV4tRgIU2ZdIszdVhchH4+8CNTqaASWkU1e9Th2TOaYT183TLFSosXQuPrkjhNrrGLuqnjlCx6YKzzKeS8MmlB4S/BuGVNT7JJqRgNgyDbKjUgahOU1CJoJPgabMPF08v36VLW2DHj6Bx8jBGQpETHpBlamfp9jSbpkDzu9+oTWSZJJnajOT43Yh/FgNySyY1rSpFQj54DLr1czJ//ewB1CqZkmFoaPicaA2/jMkzc5EbuNXAox+2YfYLlk8yJP9Kv5+nMRCpQ5+Ny03MnNQrnjyzz72OCqWVQR6XQzJxqUnsLv8V7eVnZmkeHnU9OZIGxXZE1EHdoEqwbVh8C75jwQnjS2gWkG6wQifVNuLU/4yJXiqckTvuXFnD9vJ9ON4T4OhteN4O1i/ei+JIjaDaYo06s4H1738hBcg+W+OwS1lwagpIWU7wjOIgn46qMi3qaBPdEey9fwulY3E3NI/dxfMPfocjBDrK64iFFdTPzVJcz8BlLlpXSeGgnbLLKVAKJ/Hwwl6KMLgQXgkea0Ic/RWjN98hR8TxInvRxPW3YB77mbKI3KQ8UGRtMMl9pb0xSvxAe5jkFJBuqJKfdneKrdD59h5C36ZwjMdgeTZA8UPuan+9nuouKK05ObB55Q6lpt7ccgokVL2fMgYJTM5u2YXNJ1RQbi049QhlGKFsy1KUgelFnbZQAWkFX+RTUfK0e1Qx+fASK8PHdBP7SAp6TVLRkXnjU+Mao1kdhQpMsgCC9V86Kjatxz97k4qIS3nQGjiJt12+SRIZKp/H7woJdX1KXnrAHlh4lRJRF6nv+iyfhhwlYwStr/7oQ7LJqj6GOerDvvYxepR+6vDeu4bqzQ/RKXOMJH8cCEGmrVlSkzOjKlRAHk8v1MBs3V8SzoSFqRN0O9MDu3EUoMiXw7n+Nvitd9ELXBz+9DUtC2SPYaLYbUOf5RFX+rS+uYHa6Y/IcAWvJTqP3v59ZPtEA2OK++WjtbWyga7w0Dh3OGGpzblSrJ3ShgWv0tP7T+xfOkItNG4gKk7UxPoAVbgEBT5ZUDzD3JczsnkXjqEuSLATAZvLt9ENhr+OEnx1bq4+oCo4BeYMv+f/uiBhGJm65KBL1ayxFDcr+WeFR92QkYuoJvbGwcrP0V6lPx/uOOpLij8SRgPzCyuQ0Kk+T2DpLPPdd2hr4uD5Bj3Z0pOhi5dWQOVUpEziMhXvv9b/AparAWFoF74ZAAAAAElFTkSuQmCC
""")

# league IDs
NAT_LEAGUE_ID = 104
AMER_LEAGUE_ID = 103

# division IDs
NL_WEST = 203
NL_CENTRAL = 205
NL_EAST = 204
AL_WEST = 200
AL_CENTRAL = 202
AL_EAST = 201

def struct_TeamDefinition(name, abbrev, logo, foreground_color, background_color, id, leagueId, divisionId):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, ForegroundColor = foreground_color, BackgroundColor = background_color, Id = id, LeagueId = leagueId, DivisionId = divisionId)

TEAM_INFO = {
    ARI_TEAM_ID: struct_TeamDefinition("Arizona DiamondBacks", "ARI", ARI_LOGO, "#E3D4AD", "#A71930", ARI_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    ATH_TEAM_ID: struct_TeamDefinition("Athletics", "ATH", ATH_LOGO, "#EFB21E", "#003831", ATH_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    ATL_TEAM_ID: struct_TeamDefinition("Atlanta Braves", "ATL", ATL_LOGO, "#FFFFFF", "#13274F", ATL_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    BOS_TEAM_ID: struct_TeamDefinition("Boston Red Sox", "BOS", BOS_LOGO, "#FFFFFF", "#0C2340", BOS_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    BAL_TEAM_ID: struct_TeamDefinition("Baltimore Orioles", "BAL", BAL_LOGO, "#DF4701", "#000000", BAL_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    CHC_TEAM_ID: struct_TeamDefinition("Chicago Cubs", "CHC", CHC_LOGO, "#CC3433", "#0E3386", CHC_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CWS_TEAM_ID: struct_TeamDefinition("Chicago White Sox", "CWS", CWS_LOGO, "#C4CED4", "#27251F", CWS_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    CIN_TEAM_ID: struct_TeamDefinition("Cincinnati Reds", "CIN", CIN_LOGO, "#FFFFFF", "#C6011F", CIN_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CLE_TEAM_ID: struct_TeamDefinition("Cleveland Guardians", "CLE", CLE_LOGO, "#FFFFFF", "#00385D", CLE_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    COL_TEAM_ID: struct_TeamDefinition("Colorado Rockies", "COL", COL_LOGO, "#C4CED4", "#333366", COL_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    DET_TEAM_ID: struct_TeamDefinition("Detroit Tigers", "DET", DET_LOGO, "#FFFFFF", "#0C2340", DET_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    HOU_TEAM_ID: struct_TeamDefinition("Houston Astros", "HOU", HOU_LOGO, "#EB6E1F", "#002D62", HOU_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    KC_TEAM_ID: struct_TeamDefinition("Kansas City Royals", "KC", KC_LOGO, "#BD9B60", "#004687", KC_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    LAA_TEAM_ID: struct_TeamDefinition("Los Angeles Angels", "LAA", LAA_LOGO, "#FFFFFF", "#BA0021", LAA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    LAD_TEAM_ID: struct_TeamDefinition("Los Angeles Dodgers", "LAD", LAD_LOGO, "#FFFFFF", "#005A9C", LAD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    MIA_TEAM_ID: struct_TeamDefinition("Miami Marlins", "MIA", MIA_LOGO, "#00A3E0", "#000000", MIA_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    MIL_TEAM_ID: struct_TeamDefinition("Milwaukee Brewers", "MIL", MIL_LOGO, "#FFC52F", "#12284B", MIL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    MIN_TEAM_ID: struct_TeamDefinition("Minnesota Twins", "MIN", MIN_LOGO, "#FFFFFF", "#002B5C", MIN_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    NYM_TEAM_ID: struct_TeamDefinition("New York Mets", "NYM", NYM_LOGO, "#FF5910", "#002D72", NYM_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    NYY_TEAM_ID: struct_TeamDefinition("New York Yankees", "NYY", NYY_LOGO, "#C4CED3", "#0C2340", NYY_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    PHI_TEAM_ID: struct_TeamDefinition("Philadelphia Phillies", "PHI", PHI_LOGO, "#FFFFFF", "#E81828", PHI_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    PIT_TEAM_ID: struct_TeamDefinition("Pittsburgh Pirates", "PIT", PIT_LOGO, "#FDB827", "#27251F", PIT_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SEA_TEAM_ID: struct_TeamDefinition("Seattle Mariners", "SEA", SEA_LOGO, "#C4CED4", "#0C2C56", SEA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    SD_TEAM_ID: struct_TeamDefinition("San Diego Padres", "SD", SD_LOGO, "#FFC425", "#2F241D", SD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    STL_TEAM_ID: struct_TeamDefinition("St. Louis Cardinals", "STL", STL_LOGO, "#FFFFFF", "#C41E3A", STL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SF_TEAM_ID: struct_TeamDefinition("San Francisco Giants", "SF", SF_LOGO, "#FD5A1E", "#27251F", SF_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    TB_TEAM_ID: struct_TeamDefinition("Tampa Bay Rays", "TB", TB_LOGO, "#8FBCE6", "#092C5C", TB_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    TEX_TEAM_ID: struct_TeamDefinition("Texas Rangers", "TEX", TEX_LOGO, "#FFFFFF", "#003278", TEX_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    TOR_TEAM_ID: struct_TeamDefinition("Toronto Blue Jays", "TOR", TOR_LOGO, "#FFFFFF", "#134A8E", TOR_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    WAS_TEAM_ID: struct_TeamDefinition("Washington Nationals", "WAS", WAS_LOGO, "#FFFFFF", "#AB0003", WAS_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
}

# utility functions

def render_W(color):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render_block(6, 2, color),
                    render_blank_block(8, 2),
                    render_block(6, 2, color),
                    render_blank_block(8, 2),
                    render_block(6, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                    render_blank_block(7, 2),
                    render_block(8, 2, color),
                    render_blank_block(7, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(6, 1),
                    render_block(8, 1, color),
                    render_blank_block(6, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 2),
                    render_block(5, 2, color),
                    render_blank_block(5, 2),
                    render_block(10, 2, color),
                    render_blank_block(5, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(5, 1),
                    render_block(4, 1, color),
                    render_blank_block(2, 1),
                    render_block(4, 1, color),
                    render_blank_block(5, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                    render_blank_block(2, 2),
                    render_block(5, 2, color),
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                    render_blank_block(3, 1),
                    render_block(4, 1, color),
                    render_blank_block(4, 1),
                    render_block(4, 1, color),
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(4, 1),
                    render_block(5, 1, color),
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(4, 2),
                    render_block(5, 2, color),
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                    render_blank_block(4, 2),
                    render_block(5, 2, color),
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(4, 1),
                    render_block(5, 1, color),
                    render_blank_block(1, 1),
                    render_block(4, 1, color),
                    render_blank_block(6, 1),
                    render_block(4, 1, color),
                    render_blank_block(1, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(5, 2),
                    render_block(9, 2, color),
                    render_blank_block(6, 2),
                    render_block(9, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(5, 2),
                    render_block(8, 2, color),
                    render_blank_block(8, 2),
                    render_block(8, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(6, 1),
                    render_block(7, 1, color),
                    render_blank_block(8, 1),
                    render_block(7, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(6, 1),
                    render_block(6, 1, color),
                    render_blank_block(10, 1),
                    render_block(6, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(7, 1),
                    render_block(5, 1, color),
                    render_blank_block(10, 1),
                    render_block(5, 1, color),
                ],
            ),
        ],
    )

def render_blank_block(width, height):
    return render.Box(
        width = width,
        height = height,
    )

def render_block(width, height, color):
    return render.Box(
        width = width,
        height = height,
        color = color,
    )

def render_L(color):
    return render.Row(
        children = [
            render.Box(
                width = 4,
                height = 23,
                color = color,
            ),
            render.Column(
                children = [
                    render.Box(
                        width = 12,
                        height = 19,
                    ),
                    render.Box(
                        width = 12,
                        height = 4,
                        color = color,
                    ),
                ],
            ),
        ],
    )

def get_away_team_id(game):
    return get_team_id(game, "away")

def get_home_team_id(game):
    return get_team_id(game, "home")

def get_team_id(game, team_type):
    return int(game.get("teams").get(team_type).get("team").get("id"))

def get_away_probable_pitcher(game):
    return get_probable_pitcher(game, "away")

def get_home_probable_pitcher(game):
    return get_probable_pitcher(game, "home")

def get_probable_pitcher(game, team_type):
    return game.get("teams").get(team_type).get("probablePitcher")

def render_separator():
    return render.Box(
        height = 5,
        width = 1,
        color = "373737",
    )

NO_OUT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAABAAAAADFbP4CAAAAG0lEQVQIHWNgAIL/UABigzlgBpTNBOOg0MhaAHFBF+usLcu4AAAAAElFTkSuQmCC
""")
OUT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAABAAAAADFbP4CAAAAIElEQVQIHWNgAIL/UABis4DYD8XtQWywBBOYhU4gawEAqVoZJnsyPbsAAAAASUVORK5CYII=
""")

def render_current_outs(number_of_outs):
    if number_of_outs == 0 or number_of_outs > 2:
        return render.Row(
            children = render_outs(NO_OUT, NO_OUT),
        )
    if number_of_outs == 1:
        return render.Row(
            children = render_outs(OUT, NO_OUT),
        )
    return render.Row(
        children = render_outs(OUT, OUT),
    )

def render_outs(one_out, two_out):
    return [
        render.Image(
            src = one_out,
        ),
        render.Box(
            width = 1,
            height = 1,
        ),
        render.Image(
            src = two_out,
        ),
    ]

EMPTY_BASE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAABQAAAAB/qhzxAAAAIUlEQVQIHWNggIL/QABjg2mYAIxmgDPQdcAkYDTcGGQBAIozH+GWL3b+AAAAAElFTkSuQmCC
""")
OCCUPIED_BASE_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAABQAAAAB/qhzxAAAAMElEQVQIHWNggIL/QABjM4EYIIGN6hAaxGeECYA4IOB/E0KDVW5QA0kjjABLIQsAANZAIZSR/thKAAAAAElFTkSuQmCC
""")

PLAY_OUTCOME_MAP = {
    "catcher_interf": "CI",
    "caught_stealing_2b": "CS",
    "caught_stealing_3b": "CS",
    "caught_stealing_home": "CS",
    "double": "2B",
    "double_play": "DP",
    "fielders_choice": "FC",
    "fielders_choice_out": "FC",
    "field_error": "E",
    "field_out": "OUT",
    "force_out": "FO",
    "game_advisory": "",
    "grounded_into_double_play": "GDP",
    "hit_by_pitch": "HBP",
    "home_run": "HR",
    "intent_walk": "IBB",
    "other_out": "OUT",
    "pickoff_1b": "OUT",
    "pickoff_caught_stealing_2b": "CS",
    "pickoff_caught_stealing_3b": "CS",
    "sac_fly": "SF",
    "sac_bunt": "SAC",
    "single": "1B",
    "stolen_base_2b": "SB",
    "stolen_base_3b": "SB",
    "stolen_base_home": "SB",
    "strikeout": "K",
    "strikeout_double_play": "KDP",
    "triple": "3B",
    "walk": "BB",
}

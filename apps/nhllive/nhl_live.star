"""
Applet: NHL Live
Summary: Live updates of NHL games
Description: Displays live game stats or next scheduled NHL game information
Author: Reed Arneson
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

APP_VERSION = "2.3.0"

# Constants
DEFAULT_LOCATION = """
{
	"lat": "39.7392",
	"lng": "104.9903",
	"description": "Denver, CO, USA",
	"locality": "Denver",
	"place_id": "ChIJzxcfI6qAa4cR1jaKJ_j0jhE",
	"timezone": "America/Denver"
}
"""

FONT_STYLE = "CG-pixel-3x5-mono"
FONT_COLOR_EVEN = "#FFFFFF"
FONT_COLOR_POWERPLAY = "#59e9ff"
FONT_COLOR_EMPTYNET = "#eb4c46"
FONT_COLOR_POWERPLAY_EMPTYNET = "#a838d1"

CACHE_LOGO_SECONDS = 86400
CACHE_GAME_SECONDS = 60
CACHE_UPDATE_SECONDS = 30
CACHE_SHUFFLETEAMS_SECONDS = 3600

BASE_API_URL = "https://api-web.nhle.com"
BASE_IMAGE_URL = "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nhl/500/{}.png&scale=crop&cquality=40&location=origin&w=80&h=80"

NHL_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAATCAYAAACZZ43PAAAAAXNSR0IArs4c6QAABCdJREFUOE9jZIACAQEBBQMjo4AD+/ZNgImpamj4yElLf9y7d
+9hmJiLu3vBmZMnN3z48OEBSIwRJhESEpJibG4RxM/Nda+qqmpNWGSkyveff6JsLUwZPnz4sKytre12eHRsKC8vr9KLJ4/WLVmyZA7cAJDtFZU1M2
bNnqkmJSX5UUlR8cejR48ZhYSERJlZWBj+/v71hpOL69/ly5d5ONjZmVNSUx+VlZZmgFzBGBMT06enp2e2YuUqDk8fP+NvX748YGNjVZCXl2OYMmn
iLZAtlZVVap8+fWLwDwhguHHjBkNzU+NZb1/fT7t27bnAWF1dXbNj1+7wkPBIna7Wpg8MDAwCMG/BaGVlld/tHR0MmRnpN96+fSu7es1agdramgvi
UjJrGQUEBAwsrW0namtr282dPRNdL4O/vz+Dq6vbtcmTJ72/efOmNUhBS0srw5Zt2w8dP3o4HhyINnaOB9LSUuzzc3NQDAApvHbj+pETx479bmpuk
Y6JjlIDKZg3fwHDrFmzD27ftsUBbICtg+OBvNxc+7SUZLABPDw87yZNniI0deqUA2fPnHGYNGnyRZD43LlzXr1//0GkobHRcOOG9QcXLFjgAPaCgb
FJn7+vj0FTY6Ogqqrq6+KS0n8F+Xkf5sydx9jc1Pg6OzuHB2TAipUrfmhraQm4uXuoL1wwf//mzZuLGKura2s2b9kUrKenJygmJsYvKyt7va+3l83
S2vqLr7ePwPHjxz5aWlrxV1VV8vb3TxSZPGXSLUkJCR4mZuYPf/4xbGJsb2/vOHX6tEd2do7+rJkz96tpqLPu2bWLUU5B4Q/IgLy8XH19fYML+QUF
BjnZWbe+ffumJiAg8NDB0en3+0+fFzJOmz59wamTJ3UOHDjA/PHjR4MlS5fdUlJSkqhvqD//6MEDZikpKV7/gEC9gvy8j8hRHBkdw/D81et5jLNmz
albsGCex6tXr+Tevn0rDQqwzVu3fLh3587/pORkyWNHj7Jt3bpVETl6REREbqqoabDz8guuZOzs7Ezcvn17WGBQsH1DfR1nTk7O0Xnz5olPnjJVob
am+v6zZ89U0RNHbGLy17OnTx3k4+PfDYoFgdLS0t5jx45rKyjIi1+8ePFlcUmpeUpy0qd///7xoWv2CQh8cfP69YfaOroP1q9ZlQFOB87OzrbOLi7
ZC+bPl66trbMBpfujR4/c37t3L+e/f//+6+kbPtfR01P5/fcf375d23f7+gf83LtrZ9e5c+cOw7NzcHCwnq6eQdHxU6cUP394JywhIcklISmp+PPX
L4bXr17e//L58zcJcck3hkZGD/YeOtC3Y9OmSyjlAVLBYmBgZGrCy8erx8bOYWRubMDAysp65MqVK3fWrl175sOHDxeQvQV3AUYuYmBgMDc3j5CSk
mJYv379CmzyIDEA/Aa7ZTTsFScAAAAASUVORK5CYII=
""")

# Some teams have abbr_fix due to inconsistent pattern by logo scrape source
TEAMS_LIST = {
    1: {"name": "New Jersey Devils", "abbreviation": "NJD"},
    2: {"name": "New York Islanders", "abbreviation": "NYI"},
    3: {"name": "New York Rangers", "abbreviation": "NYR"},
    4: {"name": "Philadelphia Flyers", "abbreviation": "PHI"},
    5: {"name": "Pittsburgh Penguins", "abbreviation": "PIT"},
    6: {"name": "Boston Bruins", "abbreviation": "BOS"},
    7: {"name": "Buffalo Sabres", "abbreviation": "BUF"},
    8: {"name": "Montreal Canadiens", "abbreviation": "MTL"},
    9: {"name": "Ottawa Senators", "abbreviation": "OTT"},
    10: {"name": "Toronto Maple Leafs", "abbreviation": "TOR"},
    12: {"name": "Carolina Hurricanes", "abbreviation": "CAR"},
    13: {"name": "Florida Panthers", "abbreviation": "FLA"},
    14: {"name": "Tampa Bay Lightning", "abbreviation": "TBL", "abbr_fix": "TB"},
    15: {"name": "Washington Capitals", "abbreviation": "WSH"},
    16: {"name": "Chicago Blackhawks", "abbreviation": "CHI"},
    17: {"name": "Detroit Red Wings", "abbreviation": "DET"},
    18: {"name": "Nashville Predators", "abbreviation": "NSH"},
    19: {"name": "St. Louis Blues", "abbreviation": "STL"},
    20: {"name": "Calgary Flames", "abbreviation": "CGY"},
    21: {"name": "Colorado Avalanche", "abbreviation": "COL"},
    22: {"name": "Edmonton Oilers", "abbreviation": "EDM"},
    23: {"name": "Vancouver Canucks", "abbreviation": "VAN"},
    24: {"name": "Anaheim Ducks", "abbreviation": "ANA"},
    25: {"name": "Dallas Stars", "abbreviation": "DAL"},
    26: {"name": "Los Angeles Kings", "abbreviation": "LAK", "abbr_fix": "LA"},
    28: {"name": "San Jose Sharks", "abbreviation": "SJS", "abbr_fix": "SJ"},
    29: {"name": "Columbus Blue Jackets", "abbreviation": "CBJ"},
    30: {"name": "Minnesota Wild", "abbreviation": "MIN"},
    52: {"name": "Winnipeg Jets", "abbreviation": "WPG"},
    # 53: {"name": "Arizona Coyotes", "abbreviation": "ARI"}, LOL
    54: {"name": "Vegas Golden Knights", "abbreviation": "VGK"},
    55: {"name": "Seattle Kraken", "abbreviation": "SEA"},
    68: {"name": "Utah Mammoth", "abbreviation": "UTA", "abbr_fix": "UTAH"},
}

# Main App
def main(config):
    # Get timezone and set today date
    currDate = get_current_date(config)

    # Grab teamid, teamAbbr from our schema
    teamId, team_abbr = get_team(config)

    print("###################################################")
    print("## NHL Live Applet - teamId: %s" % teamId)
    print("## NHL Live Applet - teamAbbr: %s" % team_abbr)
    print("## NHL Live Applet - currDate: %s" % currDate)
    print("###################################################")

    # check if this team knows of a cached game:
    game_info = cache.get("teamid_" + str(teamId) + "_game") or None

    # No cached game, normal flow
    if game_info == None:
        print("  - CACHE: No Game found for teamid %s" % str(teamId))

        # Create our game_info dict
        game_info = {
            "gameId": None,
            "is_game_today": False,
            "teamId_away": None,
            "teamId_home": None,
            "goals_away": "",
            "goals_home": "",
            "game_time": "",
            "game_period": "",
            "is_pp_away": False,
            "is_pp_home": False,
            "is_empty_away": False,
            "is_empty_home": False,
            "game_update": "",
            "game_state": "",
            "start_time": "",
            "is_intermission": "",
        }

        # Get game info (current game, opponent, basic stats, or next game scheduled)
        game_info = get_games(teamId, currDate, game_info)

        print("  - CACHE: Setting Game for teamid %s" % str(teamId))
        cache.set("teamid_" + str(teamId) + "_game", json.encode(game_info), ttl_seconds = CACHE_GAME_SECONDS)

    else:
        print("  - CACHE: Game found for teamid %s" % str(teamId))
        game_info = json.decode(game_info)
        if game_info["game_state"] in ["LIVE", "CRIT"]:
            game_info = get_game_boxscore(game_info)

    # Optionally pull live game stat updates
    if game_info["game_state"] in ["LIVE", "CRIT"] and config.bool("liveupdates", True):
        game_info["game_update"] = get_live_game_update(game_info, config)
    elif game_info["game_state"] in ["LIVE", "CRIT"] and not config.bool("liveupdates", True):
        game_info["game_update"] = ""
        # If game is FUT/PRE scheduled, override game_update with local start_time

    elif game_info["game_state"] in ["FUT", "PRE"]:
        print("  - INFO: Overriding game_update with start_time")
        game_info["game_update"] = get_local_start_time(game_info["start_time"], config)

    # If we have no gameId, return NHL logo
    if game_info["gameId"] == None:
        print("  - ERROR: No Games Found. Displaying NHL Logo.")
        return render.Root(
            child = render.Box(
                child = render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = NHL_LOGO,
                            width = 20,
                            height = 20,
                        ),
                        render.Text(
                            content = "No %s Games" % team_abbr,
                            font = FONT_STYLE,
                            color = "#ababab",
                        ),
                    ],
                ),
            ),
        )

    # Grab the logos
    logo_away = str(get_team_logo(game_info["teamId_away"]))
    logo_home = str(get_team_logo(game_info["teamId_home"]))

    # # PowerPlay/EmptyNet Color Change
    score_color_away = get_score_color(game_info["is_pp_away"], game_info["is_empty_away"])
    score_color_home = get_score_color(game_info["is_pp_home"], game_info["is_empty_home"])

    # Game Day Only
    if config.bool("gameday", False) and (game_info["is_game_today"] == False):
        print("  - No %s games today, returning nothing." % str(team_abbr))
        return []

    # print("-->", game_info)

    # Main Display Render
    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Image(width = 18, height = 18, src = logo_away),
                                render.Box(height = 1, width = 5, color = "#000000"),
                                render.Text(
                                    content = TEAMS_LIST[game_info["teamId_away"]]["abbreviation"] + " " + game_info["goals_away"],
                                    font = FONT_STYLE,
                                    color = score_color_away,
                                ),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            main_align = "space evenly",
                            children = [
                                render.Box(height = 2, width = 5, color = "#000000"),
                                render.Text(
                                    content = game_info["game_time"],
                                    font = FONT_STYLE,
                                    color = "#ffbe0a",
                                ),
                                render.Text(
                                    content = "vs",
                                    font = FONT_STYLE,
                                    color = "#525252",
                                ),
                                render.Text(
                                    content = game_info["game_period"],
                                    font = FONT_STYLE,
                                    color = "#ffbe0a",
                                ),
                                render.Box(height = 1, width = 5, color = "#000000"),
                                render.Text(
                                    content = game_info["is_intermission"],
                                    font = FONT_STYLE,
                                    color = "#ffbe0a",
                                ),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Image(width = 18, height = 18, src = logo_home),
                                render.Box(height = 1, width = 5, color = "#000000"),
                                render.Text(
                                    content = game_info["goals_home"] + " " + TEAMS_LIST[game_info["teamId_home"]]["abbreviation"],
                                    font = FONT_STYLE,
                                    color = score_color_home,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(
                    height = 9,
                    child = render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Marquee(
                                offset_start = 16,
                                offset_end = 16,
                                width = 64,
                                child = render.Text(
                                    content = game_info["game_update"],
                                    font = FONT_STYLE,
                                    color = "#ffbe0a",
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

# Check if there is a game, if it's live or over or scheduled.
# If live or over, grab game info. If scheduled, grab next game info.
def get_games(teamId, currDate, game_info):
    print("  - Get Games for week")

    # Get team schedule for a team week
    games = get_club_schedule_week(teamId)

    # init some vars
    start_time = None
    teamId_away = None
    teamId_home = None
    gameId = None
    game_state = None

    if len(games["games"]) > 0:
        print("  - Games found for week")
        game_info["gameId"] = str(int(games["games"][0]["id"]))
        game_info["game_date"] = str(games["games"][0]["gameDate"])
        game_info["teamId_away"] = int(games["games"][0]["awayTeam"]["id"])
        game_info["teamId_home"] = int(games["games"][0]["homeTeam"]["id"])

        game_info = get_game_status(game_info, games, currDate)

        # If no games this week, get schedule for the season
    else:
        print("  - No games this week, getting season schedule")
        games = get_club_schedule_season(teamId)

        # If games set game_live, game_over, teamId_away, teamId_home, start_time
        if games:
            teamId_away, teamId_home, start_time, gameId, game_state = get_next_game(currDate, games)

        game_info["teamId_away"] = teamId_away
        game_info["teamId_home"] = teamId_home
        game_info["game_state"] = game_state
        game_info["gameId"] = gameId
        game_info["start_time"] = start_time

    return game_info

def get_game_status(game_info, games, currDate):
    # Check if game is today
    if game_info["game_date"] == str(currDate):
        game_info["is_game_today"] = True

    # If games this week, check if game[0] is live or over
    if is_game_live(games):
        print("  - Game is live")
        game_info = get_game_boxscore(game_info)
        game_info["game_state"] = "LIVE"

    elif is_game_over(games):
        print("  - Game is over")
        game_info = get_final_game_info(games, game_info)
        game_info["game_state"] = "OVER"

    else:
        # Grab the start time
        game_info["game_state"] = "FUT"
        game_info["start_time"] = games["games"][0]["startTimeUTC"]

    return game_info

def get_live_game_update(game_info, config):
    game_stats = cache.get("game_" + str(game_info["gameId"]) + "_liveupdate") or None
    opts = []

    if game_stats == None:
        print("  - CACHE: No LiveUpdate found for gameid %s" % str(game_info["gameId"]))
        url = BASE_API_URL + "/v1/gamecenter/" + game_info["gameId"] + "/right-rail"
        print("  - HTTP.GET: %s" % url)

        response = http.get(url)

        if response.status_code == 200:
            game_stats = {}
            game = response.json()

            # Reformat our game stats a bit
            for stat in game["teamGameStats"]:
                if stat["category"] == "faceoffWinningPctg":
                    stat["category"] = "fo"
                    stat["awayValue"] = str(int(math.round(stat["awayValue"] * 100))) + "%"
                    stat["homeValue"] = str(int(math.round(stat["homeValue"] * 100))) + "%"
                elif stat["category"] == "blockedShots":
                    stat["category"] = "blk"
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))
                elif stat["category"] == "takeaways":
                    stat["category"] = "take"
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))
                elif stat["category"] == "giveaways":
                    stat["category"] = "give"
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))
                elif stat["category"] == "hits":
                    stat["category"] = "hit"
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))
                elif stat["category"] == "powerPlay":
                    stat["category"] = "ppg"
                elif stat["category"] == "sog":
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))
                elif stat["category"] == "pim":
                    stat["awayValue"] = str(int(stat["awayValue"]))
                    stat["homeValue"] = str(int(stat["homeValue"]))

                stat_type = stat["category"]
                game_stats[stat_type] = [stat["awayValue"], stat["homeValue"]]

            cache.set("game_" + str(game_info["gameId"]) + "_liveupdate", json.encode(game_stats), ttl_seconds = CACHE_UPDATE_SECONDS)
            print("  - CACHE: Setting LiveUpdate for gameid %s" % str(game_info["gameId"]))

    else:
        print("  - CACHE: LiveUpdate found for gameid %s" % str(game_info["gameId"]))
        game_stats = json.decode(game_stats)

    team_away = TEAMS_LIST[game_info["teamId_away"]]["abbreviation"]
    team_home = TEAMS_LIST[game_info["teamId_home"]]["abbreviation"]

    # Create our opts set for use in random update based on schema config selections
    if config.bool("sog", True):
        opts.append("sog")
    if config.bool("ppg", True):
        opts.append("ppg")
    if config.bool("fo", True):
        opts.append("fo")
    if config.bool("pim", True):
        opts.append("pim")
    if config.bool("hit", True):
        opts.append("hit")
    if config.bool("blk", True):
        opts.append("blk")
    if config.bool("take", True):
        opts.append("take")
    if config.bool("give", True):
        opts.append("give")

    print("  - OPTS: %s" % opts)

    # Randomly choose what update to show
    if len(opts) > 0:
        opt = opts[random.number(0, len(opts) - 1)]

        # print("  - OPT: %s" % opt)
        update = opt.upper() + " - " + team_away + ":" + str(game_stats[opt][0]) + " " + team_home + ":" + str(game_stats[opt][1])
    else:
        update = ""

    return update

# Grab basic game info via boxscore
def get_game_boxscore(game_info):
    update = cache.get("game_" + str(game_info["gameId"]) + "_boxscore") or None

    if update == None:
        print("  - CACHE: No Boxscore found for gameid %s" % str(game_info["gameId"]))
        url = BASE_API_URL + "/v1/gamecenter/" + game_info["gameId"] + "/boxscore"
        print("  - HTTP.GET: %s" % url)
        response = http.get(url)

        if response.status_code == 200:
            game = response.json()
            game_info["goals_away"] = str(int(game["awayTeam"]["score"]))
            game_info["goals_home"] = str(int(game["homeTeam"]["score"]))

            game_info["game_time"] = game["clock"]["timeRemaining"]
            game_info["game_period"] = get_game_period(game["periodDescriptor"]["number"], game["periodDescriptor"]["periodType"])

            if game["gameState"] in ["LIVE", "CRIT"]:
                game_info["game_state"] = "LIVE"
            elif game["gameState"] in ["OVER", "FINAL", "OFF"]:
                game_info["game_state"] = "OVER"

            # Check if intermission
            if game["clock"]["inIntermission"]:
                game_info["is_intermission"] = "INT"
            else:
                game_info["is_intermission"] = ""

            # Grab Empty Net and Power Play
            if "situation" in game:
                situationCode = game["situation"]["situationCode"]

                goalie_away = int(situationCode[0])
                skater_away = int(situationCode[1])
                skater_home = int(situationCode[2])
                goalie_home = int(situationCode[3])

                if goalie_away == 0:
                    game_info["is_empty_away"] = True
                    skater_away = skater_away - 1
                if skater_away > skater_home:
                    game_info["is_pp_away"] = True
                if goalie_home == 0:
                    game_info["is_empty_home"] = True
                    skater_home = skater_home - 1
                if skater_home > skater_away:
                    game_info["is_pp_home"] = True
            else:
                game_info["is_empty_away"] = False
                game_info["is_empty_home"] = False
                game_info["is_pp_away"] = False
                game_info["is_pp_home"] = False

            print("  - CACHE: Setting Boxscore for gameid %s" % str(game_info["gameId"]))
            cache.set("game_" + str(game_info["gameId"]) + "_boxscore", json.encode(game_info), ttl_seconds = CACHE_UPDATE_SECONDS)
    else:
        print("  - CACHE: Boxscore found for gameid %s" % str(game_info["gameId"]))
        game_info = json.decode(update)

    return game_info

# If the game is over, grab the final game info (scores, period) and format for the display
def get_final_game_info(games, game_info):
    game_info["goals_away"] = str(int(games["games"][0]["awayTeam"]["score"]))
    game_info["goals_home"] = str(int(games["games"][0]["homeTeam"]["score"]))
    if games["games"][0]["gameOutcome"]["lastPeriodType"] == "SO":
        game_info["game_update"] = "    FINAL/SO"
    elif games["games"][0]["gameOutcome"]["lastPeriodType"] == "OT":
        game_info["game_update"] = "    FINAL/OT"
    else:
        game_info["game_update"] = "      FINAL"
    return game_info

# Build the period display info
def get_game_period(period, periodType):
    if periodType == "SO":
        return "SO"
    if period == 1:
        return "1st"
    elif period == 2:
        return "2nd"
    elif period == 3:
        return "3rd"
    elif period > 4:
        return str(int(period)) + "th"
    else:
        return "OT"

def get_local_start_time(start_time, config):
    local_start_time = time.parse_time(start_time)
    local_start_time = local_start_time.in_location(get_timezone(config))
    local_start_time = local_start_time.format("Mon, Jan 2 @ 3:04PM")
    return str(local_start_time)

# Get club schedule for a team week
def get_club_schedule_week(teamId):
    url = BASE_API_URL + "/v1/club-schedule/" + TEAMS_LIST[teamId]["abbreviation"] + "/week/now"
    print("  - HTTP.GET: %s" % url)
    response = http.get(url)

    if response.status_code == 200:
        return response.json()
    else:
        return None

def get_club_schedule_season(teamId):
    url = BASE_API_URL + "/v1/club-schedule-season/" + TEAMS_LIST[teamId]["abbreviation"] + "/now"
    print("  - HTTP.GET: %s" % url)
    response = http.get(url)

    if response.status_code == 200:
        return response.json()
    else:
        return None

def is_game_live(games):
    return games["games"][0]["gameState"] in ["LIVE", "CRIT"]

def is_game_over(games):
    return games["games"][0]["gameState"] in ["OVER", "FINAL", "OFF"]

def get_next_game(currDate, games):
    for game in games["games"]:
        if game["gameDate"] >= currDate and game["gameState"] in ["FUT", "PRE"]:
            return int(game["awayTeam"]["id"]), int(game["homeTeam"]["id"]), game["startTimeUTC"], game["id"], game["gameState"]
    return None, None, None, None, None

def get_current_date(config):
    timezone = get_timezone(config)
    now = time.now().in_location(timezone)
    today = now.format("2006-01-02").upper()
    return today

def get_team(config):
    teamId = int(config.get("teamid") or 0)
    if teamId == 0:
        teamId = get_random_team()

    # Grab team name
    if teamId in TEAMS_LIST.keys():
        team_abbr = TEAMS_LIST[teamId]["abbreviation"]
    else:
        team_abbr = "NHL"
    return teamId, team_abbr

def get_team_logo(teamId):
    # check cache for logo
    cache_key = "logo_" + str(int(teamId))
    logo = cache.get(cache_key)

    if logo == None:
        print("  - CACHE: No Logo found for teamid %s" % str(int(teamId)))

        # janky abbrevations fix
        if "abbr_fix" in TEAMS_LIST[teamId]:
            abbr = TEAMS_LIST[teamId]["abbr_fix"]
        else:
            abbr = TEAMS_LIST[teamId]["abbreviation"]

        url = BASE_IMAGE_URL.format(abbr)
        print("  - HTTP.GET: %s" % url)
        response = http.get(url)

        if response.status_code != 200:
            logo = NHL_LOGO
        else:
            logo = response.body()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(cache_key, logo, ttl_seconds = CACHE_LOGO_SECONDS)
    else:
        print("  - CACHE: Logo found for teamid %s" % str(int(teamId)))
    return logo

# Check what color to use for team abbreviation based on pp or empty net
def get_score_color(power_play, empty_net):
    # TODO: make this better
    if power_play == "True" or power_play == True:
        power_play = True
    else:
        power_play = False

    if empty_net == "True" or empty_net == True:
        empty_net = True
    else:
        empty_net = False

    if power_play and empty_net:
        return FONT_COLOR_POWERPLAY_EMPTYNET
    elif empty_net:
        return FONT_COLOR_EMPTYNET
    elif power_play:
        return FONT_COLOR_POWERPLAY
    else:
        return FONT_COLOR_EVEN

def get_random_team():
    # TODO: re-implement random team that only has a scheduled game
    rand = random.number(0, len(TEAMS_LIST.keys()) - 1)
    return int(TEAMS_LIST.keys()[rand])

def get_timezone(config):
    return json.decode(config.get("location") or DEFAULT_LOCATION)["timezone"]

# Schema
def get_schema():
    team_schema_list = [
        schema.Option(display = t[1]["name"], value = str(t[0]))
        for t in sorted(TEAMS_LIST.items(), key = lambda item: item[1]["name"])
    ]
    team_schema_list.insert(0, schema.Option(display = "Shuffle All Teams", value = "0"))

    version = [
        schema.Option(
            display = APP_VERSION,
            value = APP_VERSION,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "teamid",
                name = "Team",
                desc = "The team you wish to follow.",
                icon = "user",
                options = team_schema_list,
                default = "0",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "gameday",
                name = "Game Day Only",
                desc = "",
                icon = "calendar",
                default = False,
            ),
            schema.Toggle(
                id = "liveupdates",
                name = "Live Updates",
                desc = "Pull Live Game Updates",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "sog",
                name = "SOG",
                desc = "Toggle Shots on Goal Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "pim",
                name = "PIM",
                desc = "Toggle Penalty Minutes Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "ppg",
                name = "PPG",
                desc = "Toggle Power Play Goal Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "fo",
                name = "Face Offs",
                desc = "Toggle Face Off Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "hit",
                name = "Hit",
                desc = "Toggle Hits Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "blk",
                name = "Blocks",
                desc = "Toggle Block Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "take",
                name = "Takeaways",
                desc = "Toggle Takeaway Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "give",
                name = "Giveaways",
                desc = "Toggle Giveaway Stats",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Dropdown(
                id = "version",
                name = "Version",
                desc = "NHL Live App Version",
                icon = "codeCompare",
                options = version,
                default = version[0].value,
            ),
        ],
    )

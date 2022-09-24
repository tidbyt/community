"""
Applet: NHL Live
Summary: Live updates of NHL games
Description: Displays live game stats or next scheduled NHL game information
Author: Reed Arnesonx
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("random.star", "random")
load("cache.star", "cache")

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
CACHE_GAME_SECONDS = 3600
CACHE_UPDATE_SECONDS = 30
CACHE_SHUFFLETEAMS_SECONDS = 3600

BASE_URL = "https://statsapi.web.nhl.com"
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
    53: {"name": "Arizona Coyotes", "abbreviation": "ARI"},
    54: {"name": "Vegas Golden Knights", "abbreviation": "VGK"},
    55: {"name": "Seattle Kraken", "abbreviation": "SEA"},
}

# Main App
def main(config):
    game_data = None

    # Get timezone and set today date
    timezone = get_timezone(config)
    now = time.now().in_location(timezone)
    today = now.format("2006-1-2").upper()

    # Grab teamid from our schema
    config_teamid = config.get("teamid") or 0
    config_teamid = int(config_teamid)

    if config_teamid == 0:
        config_teamid = get_random_team()
        if config_teamid == None:
            team = "NHL"
            team_abbr = "NHL"

    # Grab team name
    if config_teamid in TEAMS_LIST.keys():
        team = TEAMS_LIST[config_teamid]["name"]
        team_abbr = TEAMS_LIST[config_teamid]["abbreviation"]
    else:
        team = config_teamid
        team_abbr = "NHL"

    # Check our game info cache first
    print("Grabbing Game for team: %s" % team)
    teamid_away, teamid_home, gamePk, game_state, gameDate, score_away, score_home = get_game(today, config_teamid)

    # No Game URL found
    if gamePk != None:
        game_info = get_linescore_game_data(gamePk, config)

        # This cane be bypassed to skip live updates
        if game_info["game_state"] == "Live" and config.bool("liveupdates", True):
            game_update = get_live_game_update(gamePk, config, game_state, game_info["goals_away"], game_info["goals_home"])
        else:
            game_update = game_info

        # This isn't ideal but the quickest way to avoid some bigger rewrites. We cache the game_update, which is
        #  a problem for Preview games + timezones. So, if we're in preview, let's just update this before displaying.
        if game_state == "Preview":
            print("  - PREVIEW: Updating GameTime")
            game_schedule = time.parse_time(gameDate)
            game_schedule = game_schedule.in_location(get_timezone(config))
            game_schedule = game_schedule.format("Mon, Jan 2 @ 3:04PM")
            game_update["game_update"] = "Next Game: " + game_schedule

    else:
        print("  - ERROR: No GamePk Found. Displaying NHL Logo.")
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
    logo_away = str(get_team_logo(teamid_away))
    logo_home = str(get_team_logo(teamid_home))

    # PowerPlay/EmptyNet Color Change
    score_color_away = get_score_color(game_info["is_pp_away"], game_info["is_empty_away"])
    score_color_home = get_score_color(game_info["is_pp_home"], game_info["is_empty_home"])

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
                                render.Text(
                                    content = TEAMS_LIST[int(teamid_away)]["abbreviation"] + " " + game_info["goals_away"],
                                    font = FONT_STYLE,
                                    color = score_color_away,
                                ),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            main_align = "space evenly",
                            children = [
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
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Image(width = 18, height = 18, src = logo_home),
                                render.Text(
                                    content = game_info["goals_home"] + " " + TEAMS_LIST[int(teamid_home)]["abbreviation"],
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
                                    content = game_update["game_update"],
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
            cache.set(cache_key, logo, ttl_seconds = CACHE_LOGO_SECONDS)
    else:
        print("  - CACHE: Logo found for teamid %s" % str(int(teamId)))
    return logo

# returns today's current or next-schedule game for team - including opponent and live game feed url
def get_game(date, teamId):
    # check if this team knows of a cached game:
    gamePk = cache.get("teamid_" + str(teamId) + "_gamepk") or None

    if gamePk != None:
        print("  - CACHE: Found GamePk %s" % gamePk)
        teamid_away = cache.get("game_" + gamePk + "_away") or None
        teamid_home = cache.get("game_" + gamePk + "_home") or None
        gameDate = cache.get("game_" + gamePk + "_gamedate") or None
        game_state = cache.get("game_" + gamePk + "_gamestate") or None
        score_away = cache.get("game_" + gamePk + "_scoreaway") or None
        score_home = cache.get("game_" + gamePk + "_scorehome") or None
    else:
        print("  - CACHE: No GamePk Found")
        teamid_away = None
        teamid_home = None
        gameDate = None
        game_state = None
        score_away = None
        score_home = None

    if teamid_away == None or teamid_home == None or gamePk == None or gameDate == None or game_state == None:
        print("  - CACHE: No Game Info Found")
        url = BASE_URL + "/api/v1/schedule?startDate=" + date + "&teamId=" + str(teamId)
        print("  - HTTP.GET: %s" % url)
        response = http.get(url)

        if response.status_code == 200:
            response = response.json()

            # Check next scheduled
            if response["totalGames"] == 0:
                response = get_next_game(teamId)

            if response["totalGames"] > 0:
                gamePk = str(int(response["dates"][0]["games"][0]["gamePk"]))
                teamid_away = int(response["dates"][0]["games"][0]["teams"]["away"]["team"]["id"])
                teamid_home = int(response["dates"][0]["games"][0]["teams"]["home"]["team"]["id"])

                game_state = response["dates"][0]["games"][0]["status"]["abstractGameState"]
                gameDate = str(response["dates"][0]["games"][0]["gameDate"])

                score_away = int(response["dates"][0]["games"][0]["teams"]["away"]["score"])
                score_home = int(response["dates"][0]["games"][0]["teams"]["home"]["score"])

                # Get Preview
                cache.set("game_" + gamePk + "_away", str(teamid_away), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_home", str(teamid_home), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_gamePk", str(gamePk), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_gamedate", str(gameDate), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_gamestate", str(game_state), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_scoreaway", str(score_away), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("game_" + gamePk + "_scorehome", str(score_home), ttl_seconds = CACHE_GAME_SECONDS)

                # Associate team with game in cache
                cache.set("teamid_" + str(teamid_away) + "_gamepk", str(gamePk), ttl_seconds = CACHE_GAME_SECONDS)
                cache.set("teamid_" + str(teamid_home) + "_gamepk", str(gamePk), ttl_seconds = CACHE_GAME_SECONDS)
    else:
        print("  - CACHE: Game Info Found for GamePk %s" % gamePk)

    return teamid_away, teamid_home, gamePk, game_state, gameDate, score_away, score_home

# looks up the next game for a team
def get_next_game(teamId):
    url = BASE_URL + "/api/v1/teams?expand=team.schedule.next&teamId=" + str(teamId)
    print("  - HTTP.GET: %s" % url)
    response = http.get(url)

    # Failed http.get
    if response.status_code != 200:
        return {"totalGames": 0}

    response = response.json()

    # No game
    if "nextGameSchedule" not in response["teams"][0].keys():
        return {"totalGames": 0}

    return response["teams"][0]["nextGameSchedule"]

# Get basic game info
def get_linescore_game_data(gamePk, config):
    game_info = cache.get("game_" + str(gamePk) + "_info") or None

    if game_info != None:
        print("  - CACHE: Found GamePk %s Info" % gamePk)
        game_info = json.decode(game_info)
        game_info["game_update"] = game_info["INFO"]
        return game_info

    url = BASE_URL + "/api/v1/schedule?gamePk=" + gamePk + "&expand=schedule.teams,schedule.linescore"

    print("  - HTTP.GET: %s" % url)
    response = http.get(url)

    # Failed http.get
    if response.status_code != 200:
        return None

    game = response.json()

    teamid_away = int(game["dates"][0]["games"][0]["teams"]["away"]["team"]["id"])
    teamid_home = int(game["dates"][0]["games"][0]["teams"]["home"]["team"]["id"])
    goals_away = int(game["dates"][0]["games"][0]["teams"]["away"]["score"])
    goals_home = int(game["dates"][0]["games"][0]["teams"]["home"]["score"])
    game_state = game["dates"][0]["games"][0]["status"]["abstractGameState"]
    currentPeriod = game["dates"][0]["games"][0]["linescore"]["currentPeriod"]
    sog_away = int(game["dates"][0]["games"][0]["linescore"]["teams"]["away"]["shotsOnGoal"])
    sog_home = int(game["dates"][0]["games"][0]["linescore"]["teams"]["home"]["shotsOnGoal"])
    is_pp_away = game["dates"][0]["games"][0]["linescore"]["teams"]["away"]["powerPlay"]
    is_pp_home = game["dates"][0]["games"][0]["linescore"]["teams"]["home"]["powerPlay"]
    is_empty_away = game["dates"][0]["games"][0]["linescore"]["teams"]["away"]["goaliePulled"]
    is_empty_home = game["dates"][0]["games"][0]["linescore"]["teams"]["home"]["goaliePulled"]
    info = get_game_info(game, config)

    if game_state == "Preview" or game_state == "Final":
        currentPeriodOrdinal = ""
        currentPeriodTimeRemaining = ""
        is_pp_away = False
        is_pp_home = False
        is_empty_away = False
        is_empty_away = False
    else:
        currentPeriodOrdinal = game["dates"][0]["games"][0]["linescore"]["currentPeriodOrdinal"]
        currentPeriodTimeRemaining = game["dates"][0]["games"][0]["linescore"]["currentPeriodTimeRemaining"]

    game_info = {
        "game_state": str(game_state),
        "goals_away": str(goals_away),
        "goals_home": str(goals_home),
        "is_pp_away": str(is_pp_away),
        "is_pp_home": str(is_pp_home),
        "is_empty_away": str(is_empty_away),
        "is_empty_home": str(is_empty_home),
        "INFO": str(info),
        "game_period": str(currentPeriodOrdinal),
        "game_time": str(currentPeriodTimeRemaining),
    }

    game_info_enc = json.encode(game_info)

    cache.set("game_" + str(gamePk) + "_info", game_info_enc, ttl_seconds = CACHE_UPDATE_SECONDS)
    game_info["game_update"] = game_info["INFO"]

    return game_info

# return live game data
def get_live_game_data(gamePk):
    url = BASE_URL + "/api/v1/game/" + str(gamePk) + "/feed/live"
    print("  - HTTP.GET: %s" % url)
    response = http.get(url)
    if response.status_code != 200:
        return None
    return response.json()

# collection function to get current score, time, and other random updates
def get_live_game_update(gamePk, config, game_state, goals_away, goals_home):
    update = ""
    play = ""
    sog = ""
    lg = ""
    pen = ""
    pim = ""
    ppg = ""
    fo = ""
    hit = ""
    blk = ""
    take = ""
    give = ""
    opts = []
    opt = ""

    game_updates = cache.get("game_" + str(gamePk) + "_updates") or None

    if game_updates != None:
        print("  - CACHE: Found GamePk %s Updates" % gamePk)
        game_updates = json.decode(game_updates)

    else:
        game = get_live_game_data(gamePk)

        sog = get_sog(game)
        lg = get_latest_goal(game)
        play = get_last_play(game)
        pen = get_penalties(game)
        pim = get_pim(game)
        ppg = get_ppg(game)
        fo = get_faceoffs(game)
        hit = get_hits(game)
        blk = get_blocks(game)
        take = get_takeaways(game)
        give = get_giveaways(game)

        game_updates = {
            "SOG": str(sog),
            "LG": str(lg),
            "PLAY": str(play),
            "PEN": str(pen),
            "PIM": str(pim),
            "PPG": str(ppg),
            "FO": str(fo),
            "HIT": str(hit),
            "BLK": str(blk),
            "TAKE": str(take),
            "GIVE": str(give),
            "update": str(update),
        }

        game_updates_enc = json.encode(game_updates)
        cache.set("game_" + str(gamePk) + "_updates", game_updates_enc, ttl_seconds = CACHE_UPDATE_SECONDS)

    if config.bool("sog", True):
        opts.append("SOG")
    if config.bool("play", True):
        opts.append("PLAY")
    if config.bool("pen", True):
        opts.append("PEN")
    if config.bool("ppg", True):
        opts.append("PPG")
    if config.bool("fo", True):
        opts.append("FO")
    if config.bool("pim", True):
        opts.append("PIM")
    if config.bool("hit", True):
        opts.append("HIT")
    if config.bool("blk", True):
        opts.append("BLK")
    if config.bool("take", True):
        opts.append("TAKE")
    if config.bool("give", True):
        opts.append("GIVE")

    # No reason to pull this info unless there has been a goal scored
    if (int(goals_away) > 0 or int(goals_home) > 0) and config.bool("lg", True):
        opts.append("LG")

    print("  - OPTS: %s" % opts)

    # randomly choose what update to show
    if len(opts) > 0:
        opt = opts[random.number(0, len(opts) - 1)]
        print("  - OPT: %s" % opt)

    if len(opts) > 0:
        game_updates["game_update"] = game_updates[opt]
    else:
        game_updates["game_update"] = ""
    print("  - Update: %s" % game_updates["game_update"])

    return game_updates

# Get scheduled/finished game info
def get_game_info(game, config):
    if game["dates"][0]["games"][0]["status"]["abstractGameState"] == "Final":
        if game["dates"][0]["games"][0]["linescore"]["currentPeriodOrdinal"] == "SO":
            return "    FINAL/SO"
        if game["dates"][0]["games"][0]["linescore"]["currentPeriodOrdinal"] == "OT":
            return "    FINAL/OT"
        return "      FINAL"
    elif game["dates"][0]["games"][0]["status"]["abstractGameState"] == "Preview":
        game_schedule = time.parse_time(game["dates"][0]["games"][0]["gameDate"])
        game_schedule = game_schedule.in_location(get_timezone(config))
        game_schedule = game_schedule.format("Mon, Jan 2 @ 3:04PM")
        return str("Next Game: " + game_schedule)
    else:
        return ""

# get game time and period
def get_current_live_game_time(game):
    if game["gameData"]["status"]["abstractGameState"] == "Live":
        period = game["liveData"]["linescore"]["currentPeriodOrdinal"]
        currentPeriodTimeRemaining = game["liveData"]["linescore"]["currentPeriodTimeRemaining"]
        return currentPeriodTimeRemaining, period
    else:
        return ""

# get the current score
def get_current_score(game):
    score_away = int(game["liveData"]["linescore"]["teams"]["away"]["goals"])
    score_home = int(game["liveData"]["linescore"]["teams"]["home"]["goals"])
    return score_away, score_home

# get team abbreviations for away/home
def get_current_teams(game):
    team_away = game["liveData"]["linescore"]["teams"]["away"]["team"]["abbreviation"]
    team_home = game["liveData"]["linescore"]["teams"]["home"]["team"]["abbreviation"]
    return team_away, team_home

# return info of whoever scored last
def get_latest_goal(game):
    scoringPlays = game["liveData"]["plays"]["scoringPlays"]
    if len(scoringPlays) > 0:
        last_goal = int(scoringPlays[-1])
        period = game["liveData"]["plays"]["allPlays"][last_goal]["about"]["ordinalNum"]
        time = game["liveData"]["plays"]["allPlays"][last_goal]["about"]["periodTime"]
        description = game["liveData"]["plays"]["allPlays"][last_goal]["result"]["description"]
        return "LG: " + description + " @ " + time + " in " + period
    else:
        return "LG: Play Data Not Available Yet"

# whatever last play happened
def get_last_play(game):
    play = game["liveData"]["plays"]["currentPlay"]["result"]["description"]
    period = game["liveData"]["plays"]["currentPlay"]["about"]["ordinalNum"]
    time = game["liveData"]["plays"]["currentPlay"]["about"]["periodTime"]
    return play + " @ " + time + " in " + period

# current num of penalites
def get_penalties(game):
    ppo_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["powerPlayOpportunities"])
    ppo_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["powerPlayOpportunities"])
    team_away, team_home = get_current_teams(game)
    return "PEN: " + team_away + "-" + str(ppo_home) + " " + team_home + "-" + str(ppo_away)

# get shots on goal stats
def get_sog(game):
    sog_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["shots"])
    sog_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["shots"])
    team_away, team_home = get_current_teams(game)
    return "SOG: " + team_away + "-" + str(sog_away) + " " + team_home + "-" + str(sog_home)

# current penality minutes
def get_pim(game):
    pim_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["pim"])
    pim_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["pim"])
    team_away, team_home = get_current_teams(game)
    return "PIM: " + team_away + "-" + str(pim_away) + " " + team_home + "-" + str(pim_home)

# get current ppg / opportunities
def get_ppg(game):
    ppg_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["powerPlayGoals"])
    ppg_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["powerPlayGoals"])
    ppo_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["powerPlayOpportunities"])
    ppo_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["powerPlayOpportunities"])
    team_away, team_home = get_current_teams(game)
    return "PPG: " + team_away + "-" + str(ppg_away) + "/" + str(ppo_away) + " " + team_home + "-" + str(ppg_home) + "/" + str(ppo_home)

# get faceoff percentages
def get_faceoffs(game):
    fo_away = game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["faceOffWinPercentage"]
    fo_home = game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["faceOffWinPercentage"]
    team_away, team_home = get_current_teams(game)
    return "Faceoffs: " + team_away + "-" + str(fo_away) + "%" + " " + team_home + "-" + str(fo_home) + "%"

# get hit stats
def get_hits(game):
    hits_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["hits"])
    hits_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["hits"])
    team_away, team_home = get_current_teams(game)
    return "HITS: " + team_away + "-" + str(hits_away) + " " + team_home + "-" + str(hits_home)

# get block stats
def get_blocks(game):
    blocks_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["blocked"])
    blocks_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["blocked"])
    team_away, team_home = get_current_teams(game)
    return "Blocks: " + team_away + "-" + str(blocks_away) + " " + team_home + "-" + str(blocks_home)

# get takeaway stats
def get_takeaways(game):
    take_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["takeaways"])
    take_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["takeaways"])
    team_away, team_home = get_current_teams(game)
    return "Takeaways: " + team_away + "-" + str(take_away) + " " + team_home + "-" + str(take_home)

# get giveaway stats
def get_giveaways(game):
    give_away = int(game["liveData"]["boxscore"]["teams"]["away"]["teamStats"]["teamSkaterStats"]["giveaways"])
    give_home = int(game["liveData"]["boxscore"]["teams"]["home"]["teamStats"]["teamSkaterStats"]["giveaways"])
    team_away, team_home = get_current_teams(game)
    return "Giveaways: " + team_away + "-" + str(give_away) + " " + team_home + "-" + str(give_home)

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

# Old simple random
# def get_random_team():
#     rand = random.number(0, len(TEAMS_LIST)-1)
#     return TEAMS_LIST.keys()[rand]

# This is WIP to random only current games.
def get_random_team():
    scheduled_teams = cache.get("scheduled_teams") or None

    if scheduled_teams == None:
        url = BASE_URL + "/api/v1/teams?expand=team.schedule.next"
        print("  - HTTP.GET: %s" % url)
        response = http.get(url)

        # Failed http.get
        if response.status_code != 200:
            return {"totalGames": 0}

        response = response.json()

        scheduled_teams = {}
        for r in response["teams"]:
            if "nextGameSchedule" in r:
                if r["id"] not in scheduled_teams:
                    scheduled_teams[str(int(r["id"]))] = True

        scheduled_teams_enc = json.encode(scheduled_teams)
        cache.set("scheduled_teams", scheduled_teams_enc, ttl_seconds = CACHE_SHUFFLETEAMS_SECONDS)

    else:
        print("  - CACHE: Found Scheduled Teams %s" % scheduled_teams)
        scheduled_teams = json.decode(scheduled_teams)

    if len(scheduled_teams) == 0:
        return None

    rand = random.number(0, len(scheduled_teams) - 1)
    return int(scheduled_teams.keys()[rand])

def get_timezone(config):
    return json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]

# Schema
def get_schema():
    team_schema_list = [
        schema.Option(display = t[1]["name"], value = str(t[0]))
        for t in sorted(TEAMS_LIST.items(), key = lambda item: item[1]["name"])
    ]
    team_schema_list.insert(0, schema.Option(display = "Shuffle All Teams", value = "0"))

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
                id = "liveupdates",
                name = "Live Updates",
                desc = "Pull Live Game Updates",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "play",
                name = "Last Play",
                desc = "Toggle Last Play Info",
                icon = "hockeyPuck",
                default = True,
            ),
            schema.Toggle(
                id = "lg",
                name = "Last Goal",
                desc = "Toggle Last Goal Info",
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
                id = "pen",
                name = "Penalties",
                desc = "Toggle Penalty Stats",
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
        ],
    )

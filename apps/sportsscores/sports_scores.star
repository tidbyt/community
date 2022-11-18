"""
Applet: Sports Scores
Summary: Get daily sports scores
Description: Get daily scores or live updates of sports games (MLB and NHL not from ESPN). Scores for the previous day are shown until 11am ET.
Author: rs7q5
"""
#sports_scores.star
#Created 20220220 RIS
#Last Modified 20221116 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

#this list are the sports that can have their scores pulled
#list for each league is [display text, url code added to base code, timezone to reset day stuff]
SPORTS_LIST = {
    "Baseball": ("MLB", {
        "MLB": ["MLB", "mlb", "America/New_York"],
    }),
    "Hockey": ("NHL", {
        "NHL": ["NHL", "nhl", "America/New_York"],
    }),
    "Basketball": ("NBA", {
        "NBA": ["NBA", "nba", "America/New_York"],
        "WNBA": ["WNBA", "wnba", "America/New_York"],
        "NCAAM": ["NCAAM", "mens-college-basketball", "America/New_York"],
        "NCAAW": ["NCAAW", "womens-college-basketball", "America/New_York"],
    }),
    "Football": ("NFL", {
        "NFL": ["NFL", "nfl", "America/New_York"],
        "NCAAF": ["NCAAF", "college-football", "America/New_York"],
    }),
    "Soccer": ("MLS", {
        "MLS": ["MLS", "usa.1", "America/New_York"],
        "NWSL": ["NWSL", "usa.nwsl", "America/New_York"],
        "EPL": ["EPL (scores reset at 11am London time)", "eng.1", "Europe/London"],
    }),
}
TWO_LINE_LEAGUES = ["NBA", "WNBA", "NCAAM", "NCAAW"]  #sports whose standings take up two lines

no_games_text = ["No Games Today!!"]  #vector of text to use if no games are present

def sport_from_league(league):
    for sport in SPORTS_LIST:
        for l in SPORTS_LIST[sport][1]:
            if l == league:
                return sport
    return None

def main(config):
    sport_tmp = config.str("sport", "Baseball")

    if sport_tmp not in SPORTS_LIST:
        # older installations may hold league in the "sport" field
        sport = sport_from_league(sport_tmp)
        league = sport_tmp
    else:
        sport = sport_tmp
        league = config.str("league_%s" % sport, SPORTS_LIST[sport][0])

    league_txt, league_ext, timezone_reset = SPORTS_LIST[sport][1].get(league)

    font = "CG-pixel-3x5-mono"  #set font

    #check for cached data
    stats_cached = cache.get("stats_rate_games%s_%s" % (sport, league))
    if stats_cached != None:
        print("Hit! Displaying %s (%s) gameday data." % (sport, league))
        stats = json.decode(stats_cached)
    else:
        print("Miss! Calling %s (%s) gameday data." % (sport, league))  #error code checked within each function!!!!
        today_str = get_date_str(timezone_reset)

        #get the data
        if sport == "Baseball":
            stats = get_mlbgames(today_str)
        elif sport == "Hockey":
            stats = get_nhlgames(today_str)
        elif sport == "Basketball":
            stats = get_basketballgames(today_str, league_ext)
        elif sport == "Football":
            stats = get_footballgames(today_str, league_ext)
        elif sport == "Soccer":
            stats = get_soccergames(today_str, league_ext)

        #cache the data
        cache.set("stats_rate_games%s_%s" % (sport, league), json.encode(stats), ttl_seconds = 60)

    #get frames before display
    if stats == no_games_text and config.bool("gameday", False):
        return []  #return nothing if no games
    else:
        frame_vec = get_frames(stats, league, font, config)

    speed_factor = 20 if config.bool("scroll_logic", False) else 1  #get factor for scaling animation speed

    return render.Root(
        delay = int(config.str("speed", "1000")) // speed_factor,  #speed up scroll text
        child = frame_vec,
    )

def get_schema():
    sports = [
        schema.Option(display = sport, value = sport)
        for sport in SPORTS_LIST
    ]

    frame_speed = [
        schema.Option(display = "Slower", value = "5000"),
        schema.Option(display = "Slow", value = "4000"),
        schema.Option(display = "Normal", value = "3000"),
        schema.Option(display = "Fast", value = "2000"),
        schema.Option(display = "Faster (Default)", value = "1000"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sport",
                name = "Sport",
                desc = "The sport of the live games that should be displayed.",
                icon = "medal",
                options = sports,
                default = "Baseball",
            ),
            schema.Generated(
                id = "generated",  #other options are all in here because the generated fields go at the end always
                source = "sport",
                handler = more_options,
            ),
            schema.Toggle(
                id = "gameday",
                name = "Game day only",
                desc = "",
                icon = "calendar",
                default = False,
            ),
            schema.Toggle(
                id = "local_tz",
                name = "Local timezone",
                desc = "Enable to display game times in your local timezone (default is ET).",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "time_format",
                name = "Time format",
                desc = "Enable to display game times in 12 hour format (does not show AM/PM).",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "row_space",
                name = "Add space between rows",
                desc = "This may reduce the number of games displayed on each frame.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "scroll_logic",
                name = "Scroll games?",
                desc = "",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Frame speed",
                desc = "Change the speed that the games listed change.",
                icon = "gear",
                default = frame_speed[-1].value,
                options = frame_speed,
            ),
            schema.Toggle(
                id = "hide_tbd_scores",
                name = "Hide the score of games not started?",
                desc = "Enable to hide zeros for games not started.",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Toggle(
                id = "hide_ordinal",
                name = "Hide ordinal endings of the game status?",
                desc = "Enable to hide ordinal endings (e.g. only show 1 instead of 1st).",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Toggle(
                id = "highlight_winner",
                name = "Highlight winner?",
                desc = "Enable to highlight the winner of a completed game.",
                icon = "highlighter",
                default = False,
            ),
            schema.Toggle(
                id = "highlight_team",
                name = "Highlight team?",
                desc = "Enable to highlight a select team.",
                icon = "highlighter",
                default = False,
            ),
            schema.Text(
                id = "team_select",
                name = "Team abbreviation",
                desc = "Enter the team code to highlight.",
                icon = "highlighter",
                default = "None",
            ),
        ],
    )

def more_options(sport):
    if sport not in SPORTS_LIST:
        # older installations may hold league in the "sport" field
        sport = sport_from_league(sport)

    leagues = [
        schema.Option(display = league[1][0], value = league[0])
        for league in SPORTS_LIST[sport][1].items()
    ]
    return [
        schema.Dropdown(
            id = "league_%s" % sport,  #id must be unique to get different default values
            name = "League",
            desc = "Select which league of games should be displayed.",
            icon = "medal",
            options = leagues,
            default = SPORTS_LIST[sport][0],
        ),
    ]

# def team_options(highlight_team):
#     if highlight_team:
#         return [
#             schema.Text(
#                 id = "team_select",
#                 name = "Team abbreviation",
#                 desc = "Enter the team code to highlight.",
#                 icon = "highlighter",
#                 default = "None",
#             ),
#         ]
#     else:
#         return []

######################################################
def get_frames(stats, league_txt, font, config):
    frame_vec = []
    if stats == no_games_text:
        header_txt = render.Box(width = 64, height = 7, child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Text(league_txt, color = "#a00", font = font),
                render.Text("Away/Home", font = font),
            ],
        ))

        #find how many empty lines to add (this should be the right math)
        frame_vec_data = [
            header_txt,
            render.WrappedText(stats[0], font = font),
        ]
        line_cnt = 64 // (len(stats[0]) * 3)  #times 3 is the width of each letter
        for i in range(5 - line_cnt):
            frame_vec_data.append(render.Text("", font = font))
        frame_vec_tmp = render.Column(
            expanded = True,
            main_align = "space_between",
            children = frame_vec_data,
        )
        return frame_vec_tmp

    force_two = league_txt in TWO_LINE_LEAGUES  #forces text on two lines

    if config.bool("scroll_logic", False):
        line_max = len(stats)
    elif force_two or config.bool("row_space", False):  #number of lines per frame (NBA is shorter because each game is two lines if it is on live)
        line_max = 4
    else:
        line_max = 5

    txt_height = 6 if config.bool("row_space", False) else 5  #change height of text based on number of rows to be displayed

    away_team = []
    away_score = []
    home_team = []
    home_score = []
    status_txt = []
    status_txt2 = []
    frame_vec_tmp = []

    team_sel = config.str("team_select", "None").upper()
    for i, team in enumerate(stats):
        if config.bool("highlight_team", False) and (team["away"][0] == team_sel or team["home"][0] == team_sel):
            ctmp = "#A8F0CB"
            ctmp_win = "#1EAE64"
            ctmp2 = "#08FF08"
            ctmp3 = "#52BB52"
            if team["away"][1] == 1000 and force_two:
                ctmp = "#CCFFE5"
        elif i % 2 == 0:
            ctmp = "#c8c8fa"
            ctmp_win = "#6969F1"
            ctmp2 = "#a00"
            ctmp3 = "#228B22"  #dark green
        else:
            ctmp = "#fff"
            ctmp_win = "#786868"
            ctmp2 = "#D2691E"
            ctmp3 = "#52BB52"  #light green

        status_tmp = team["status"].split("/")

        if status_tmp[0] == "time":  #reformat game time
            status_tmp = adjust_gametime(status_tmp[1], config).split("/")
        elif config.bool("hide_ordinal", False) and len(status_tmp) == 2:
            if status_tmp[1].endswith(("st", "nd", "rd", "th")):
                for suffix in ("st", "nd", "rd", "th"):
                    status_tmp[1] = status_tmp[1].removesuffix(suffix)

        #additional color options
        ctmp_away = ctmp
        ctmp_home = ctmp
        if config.bool("highlight_winner", False):
            if team["highlight"] == "away":
                ctmp_away = ctmp_win
            elif team["highlight"] == "home":
                ctmp_home = ctmp_win

        if config.bool("hide_tbd_scores", False) and team["highlight"] == "scores":
            ctmp2_score = "#000"
        else:
            ctmp2_score = ctmp2

        #away team name
        if team["away"][1] == 1000 and force_two:  #NBA condition is safety net
            away_team.append(render.Text(team["away"][0], font = font, color = "#000", height = txt_height))
        else:
            away_team.append(render.Text(team["away"][0], font = font, color = ctmp_away, height = txt_height))

        #away team score
        if team["away"][1] == 1000 and force_two:  #NBA condition is safety net
            away_score.append(render.Text("-", font = font, color = "#000", height = txt_height))
        elif team["away"][1] < 0:
            away_score.append(render.Text("-", font = font, color = ctmp2_score, height = txt_height))
        else:
            away_score.append(render.Text(str(team["away"][1]), font = font, color = ctmp2_score, height = txt_height))

        #home team name
        if team["home"][1] == 1000 and force_two:  #NBA condition is safety net
            home_team.append(render.Text(team["home"][0], font = font, color = "#000", height = txt_height))
        else:
            home_team.append(render.Text(team["home"][0], font = font, color = ctmp_home, height = txt_height))

        #home team score

        if team["home"][1] == 1000 and force_two:  #NBA condition is safety net
            home_score.append(render.Text("-", font = font, color = "#000", height = txt_height))
        elif team["home"][1] < 0:
            home_score.append(render.Text("-", font = font, color = ctmp2_score, height = txt_height))
        else:
            home_score.append(render.Text(str(team["home"][1]), font = font, color = ctmp2_score, height = txt_height))

        if team["away"][1] == 1000 and force_two:  #NBA condition is safety net
            if len(status_tmp) == 1:
                status_txt.append(render.Text("", font = font, color = ctmp, height = 6))
            else:
                status_txt.append(render.Text(status_tmp[1], font = font, color = ctmp, height = txt_height))
        else:
            status_txt.append(render.Text(status_tmp[0], font = font, color = ctmp, height = txt_height))

        if len(status_tmp) == 1 or force_two:
            status_txt2.append(render.Text("", font = font, color = ctmp2, height = txt_height))
        else:
            status_txt2.append(render.Text(status_tmp[1], font = font, color = ctmp2, height = txt_height))

        if (i % line_max == line_max - 1 or i == len(stats) - 1):  #stores only a certain number of teams
            game_cnt = (i + 1) % line_max  #number of games on current frame
            if game_cnt != 0:  #add empty entries to space (only have to add to one array since other's must be in line)
                for j in range(line_max - game_cnt):
                    #away_team.append(render.Text("",font=font,color=ctmp))
                    status_txt.append(render.Text("", font = font, color = ctmp, height = txt_height))  #add to status txt since this is the one with multiple lines

            header_text = render.Box(width = 64, height = 7, child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Text(league_txt, color = "#a00", font = font),
                    render.Text("Away/Home", font = font),
                ],
            ))

            frame_data_tmp = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Column(
                        cross_align = "start",
                        children = away_team,
                    ),
                    render.Column(
                        cross_align = "start",
                        children = away_score,
                    ),
                    render.Column(
                        cross_align = "start",
                        children = home_team,
                    ),
                    render.Column(
                        cross_align = "start",
                        children = home_score,
                    ),
                    render.Column(
                        cross_align = "end",
                        children = status_txt,
                    ),
                    render.Column(
                        cross_align = "end",
                        children = status_txt2,
                    ),
                ],
            )
            if config.bool("scroll_logic", False):
                frame_data_tmp = render.Marquee(
                    height = 27,
                    scroll_direction = "vertical",
                    offset_start = 32,
                    offset_end = 32,
                    align = "start",
                    child = frame_data_tmp,
                )

            frame_vec_tmp = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    header_text,
                    frame_data_tmp,
                ],
            )

            frame_vec.append(frame_vec_tmp)
            frame_vec_tmp = []
            away_team = []
            away_score = []
            home_team = []
            home_score = []
            status_txt = []
            status_txt2 = []

    if config.bool("scroll_logic", False):
        return frame_vec[0]
    else:
        return render.Animation(frame_vec)

######################################################
#functions
def pad_text(text):
    #format strings so they are all the same length (leads to better scrolling)
    if type(text) == "dict":
        max_len = max([len(x) for x in text.values()])  #length of each string

        #add padding to shorter titles
        for key, val in text.items():
            text_new = val + " " * (max_len - len(val))
            text[key] = text_new
    else:
        max_len = max([len(x) for x in text])  #length of each string

        #add padding to shorter titles
        for i, x in enumerate(text):
            text[i] = x + " " * (max_len - len(x))
    return text

######################################################
#was messing around with getting daily schedule of games here
def get_date_str(timezone):
    today = time.now().in_location(timezone)
    hour_str = int(today.format("15"))  #used to check if should pull last night's scores or today's games (may want to set this as a toggle, but it's fine)
    if hour_str < 11:  #if before 11am EST, get yesterday's scores
        today_str = str(today - time.parse_duration("24h")).split(" ")[0]
    else:
        today_str = str(today).split(" ")[0]
    return today_str

def adjust_gametime(gametime_raw, config):
    #return gametime string and adjust for local time
    if config.bool("local_tz", False):
        timezone = config.get("$tz", "America/New_York")
    else:
        timezone = "America/New_York"
    game_time = time.parse_time(gametime_raw).in_location(timezone)

    #game_time_str = str(game_time.format("15:04"))
    if config.bool("time_format", False):
        game_time_str = str(game_time.format("3:04"))
        if len(game_time_str) == 4:  #not double digit hour
            game_time_str = " " + game_time_str
    else:
        game_time_str = str(game_time.format("15:04"))

    if config.bool("local_tz", False):
        return game_time_str
    else:
        return game_time_str + "/ET"

def get_mlbgames(today_str):
    start_date = today_str
    end_date = today_str

    #start_date = "2021-06-10"   #tested using 2021-06-06 and 2021-06-10
    #end_date = "2021-06-10"     #tested using 2021-06-06 and 2021-06-10
    base_URL = "https://statsapi.mlb.com/api/v1/schedule/games/?sportId=1"
    full_URL = base_URL + "&startDate=" + start_date + "&endDate=" + end_date + "&hydrate=team,linescore"

    #print(full_URL)
    rep = http.get(full_URL)

    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["dates"]

    if data == []:
        return no_games_text
    else:
        data2 = data[0]["games"]

    #iterate through games
    stats = []

    for i, game in enumerate(data2):
        stats_tmp = dict()
        status = game["status"]["codedGameState"]  #Need to figure out what the possible values are here (may impact inning info)

        #get team info
        #team_info = dict()
        #stats_tmp["winner"] = None
        stats_tmp["highlight"] = None
        for key, value in game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            stats_tmp[key] = (value["team"]["abbreviation"], int(value.get("score", 0)))  #for some reason some games have no score so instead of doing -1, doing 0
            if value.get("isWinner", False):
                stats_tmp["highlight"] = key

        linescore = game.get("linescore", [])
        if game["status"]["abstractGameCode"] == "L" or status == "F":  #this should cover live or final games
            inning = int(linescore["currentInning"])
            inningState = linescore["inningState"]
            status_txt = inningState[:3] + "/" + str(inning)

            #Need to check how data is updated during an actual game to check status codes
            if status == "F":
                if inning != 9:
                    status_txt = status + "/" + str(inning)
                else:
                    status_txt = status
            else:
                status_txt = inningState[:3] + "/" + str(inning)
        else:  #this should cover scheduled games
            if game["status"]["statusCode"] in ["S", "PW", "P"]:
                status_txt = "time/" + game["gameDate"]  #adjust game time in get_frames so it works witch cached data
                stats_tmp["highlight"] = "scores"
            else:  #not delayed before the game has started
                status_txt = status

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)

    return (stats)

def get_nhlgames(today_str):
    start_date = today_str
    end_date = today_str
    base_URL = "https://statsapi.web.nhl.com/api/v1/schedule"
    full_URL = base_URL + "?startDate=" + start_date + "&endDate=" + end_date + "&expand=schedule.linescore,schedule.teams"

    #print(full_URL)
    rep = http.get(full_URL)
    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["dates"]

    if data == []:
        return no_games_text
    else:
        data2 = data[0]["games"]

    #iterate through games
    stats = []
    for i, game in enumerate(data2):
        stats_tmp = dict()
        status = game["status"]["codedGameState"]  #Need to figure out what the possible values are here (may impact info)

        #get team info
        #team_info = dict()
        stats_tmp["highlight"] = None
        for key, value in game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            stats_tmp[key] = (value["team"]["abbreviation"], int(value.get("score", -1)))
            if value.get("isWinner", False):  #the API does not actually have this
                stats_tmp["highlight"] = key

        linescore = game.get("linescore", [])

        #https://statsapi.web.nhl.com/api/v1/gameStatus
        if status == "1":
            #status_txt = "Preview"
            status_txt = "time/" + game["gameDate"]  #adjust game time in get_frames so it works witch cached data
            stats_tmp["highlight"] = "scores"
        elif status == "9":
            status_txt = "PostP"
        elif linescore != []:  #this should cover live and final states
            period = linescore["currentPeriodOrdinal"]
            period_T = linescore["currentPeriodTimeRemaining"]

            if period_T == "Final":
                if period == "3rd":
                    status_txt = "F"
                else:
                    status_txt = "F/" + period

                #figure out which team should be highlighted
                if stats_tmp["away"][1] > stats_tmp["home"][1]:
                    stats_tmp["highlight"] = "away"
                elif stats_tmp["away"][1] < stats_tmp["home"][1]:
                    stats_tmp["highlight"] = "home"
                else:  #no ties in hockey, but here for completion
                    pass  #this case should never happen as ties in hockey aren't a thing, but here for completion
            else:
                status_txt = period_T + "/" + period  #switch status and period here so time doesn't get cutoff
        else:  #this is a safety net
            status_txt = status

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)

    return (stats)

def get_basketballgames(today_str, league):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/basketball/%s/scoreboard" % league
    full_URL = base_URL + "?dates=" + start_date.replace("-", "") + "-" + end_date.replace("-", "")

    #print(full_URL)
    rep = http.get(full_URL)
    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["events"]

    if data == []:
        return no_games_text
    else:
        data2 = data

    #iterate through games
    stats = []
    for i, game in enumerate(data2):
        stats_tmp = dict()
        stats_tmp2 = dict()
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact info)

        #get team info
        stats_tmp["highlight"] = None
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
            if value.get("winner", False):
                stats_tmp["highlight"] = key2
                stats_tmp2["highlight"] = key2

        linescore = game.get("linescore", [])

        if status == "1":
            #status_txt = "Preview"
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = "time/" + game_time_tmp  #adjust game time in get_frames so it works witch cached data
            stats_tmp["highlight"] = "scores"
            stats_tmp2["highlight"] = "scores"
        elif game["status"]["type"]["state"] == "in" or status in ["2", "3"]:  #linescore!=[]: #this should cover live and final states
            period = int(game["status"]["period"])  #str(int(game["status"]["period"]))
            period_T = game["status"]["displayClock"]
            if game["status"]["type"]["state"] == "post":  #check if playing or not
                if period == 5:
                    status_txt = "F/OT"
                else:
                    status_txt = "F"
            elif period == 5:
                status_txt = period_T + "/OT"
            elif period_T == "0.0":
                status_txt = "END/" + humanize.ordinal(period)
            else:
                status_txt = period_T + "/" + humanize.ordinal(period)
        else:  #this is a safety net
            status_txt = game["status"]["type"]["state"]

        #status_txt="3rd/END"
        stats_tmp["status"] = status_txt
        stats_tmp2["status"] = status_txt
        stats.append(stats_tmp)
        stats.append(stats_tmp2)  #used for multi-line stuff
    return (stats)

def get_footballgames(today_str, league):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/football/%s/scoreboard" % league
    full_URL = base_URL + "?dates=" + start_date.replace("-", "") + "-" + end_date.replace("-", "")

    #print(full_URL)
    rep = http.get(full_URL)
    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["events"]

    if data == []:
        return no_games_text
    else:
        data2 = data

    #iterate through games
    stats = []
    for i, game in enumerate(data2):
        stats_tmp = dict()
        stats_tmp2 = dict()
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact info)

        #get team info
        stats_tmp["highlight"] = None
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
            if value.get("winner", False):
                stats_tmp["highlight"] = key2
                stats_tmp2["highlight"] = key2

        linescore = game.get("linescore", [])

        if status == "1":
            #status_txt = "Preview"
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = "time/" + game_time_tmp  #adjust game time in get_frames so it works witch cached data
            stats_tmp["highlight"] = "scores"
            stats_tmp2["highlight"] = "scores"
        elif game["status"]["type"]["state"] == "in" or status in ["2", "3"]:  #linescore!=[]: #this should cover live and final states
            period = int(game["status"]["period"])  #str(int(game["status"]["period"]))
            period_T = game["status"]["displayClock"]
            if game["status"]["type"]["state"] == "post":  #check if playing or not
                if period == 5:
                    status_txt = "F/OT"
                else:
                    status_txt = "F"
            elif period == 5:
                status_txt = period_T + "/OT"
            elif period_T == "0.0":
                status_txt = "END/" + humanize.ordinal(period)
            else:
                status_txt = period_T + "/" + humanize.ordinal(period)
        else:  #this is a safety net
            status_txt = game["status"]["type"]["state"]

        #status_txt="3rd/END"
        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)
    return (stats)

def get_soccergames(today_str, league):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/soccer/%s/scoreboard" % league
    full_URL = base_URL + "?dates=" + start_date.replace("-", "") + "-" + end_date.replace("-", "")

    #print(full_URL)
    rep = http.get(full_URL)
    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["events"]

    if data == []:
        return no_games_text
    else:
        data2 = data

    #iterate through games
    stats = []
    for i, game in enumerate(data2):
        stats_tmp = dict()
        stats_tmp2 = dict()
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact info)

        #get team info
        stats_tmp["highlight"] = None
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
            if value.get("winner", False):
                stats_tmp["highlight"] = key2
                stats_tmp2["highlight"] = key2

        linescore = game.get("linescore", [])

        if status == "1":
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = "time/" + game_time_tmp  #adjust game time in get_frames so it works witch cached data
            stats_tmp["highlight"] = "scores"
            stats_tmp["highlight"] = "scores"
        elif game["status"]["type"]["state"] == "in" or status in ["2", "3"]:  #linescore!=[]: #this should cover live and final states
            period = int(game["status"]["period"])  #str(int(game["status"]["period"]))
            period_T = game["status"]["displayClock"]
            if game["status"]["type"]["detail"] == "HT":  #check for halftime
                status_txt = "HT"
            else:  #Show current game time
                status_txt = humanize.ordinal(period) + "/" + period_T
        elif game["status"]["type"]["state"] == "post":  #Full time in soccer is covered here
            status_txt = "FT"
        else:  #this is a safety net
            status_txt = game["status"]["type"]["state"]

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)
    return (stats)

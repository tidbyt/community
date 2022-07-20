"""
Applet: Sports Scores
Summary: Get daily sports scores
Description: Get daily scores or live updates of sports games (NBA and NFL from ESPN). Scores for the previous day are shown until 11am EST.
Author: rs7q5
"""
#sports_scores.star
#Created 20220220 RIS
#Last Modified 20220719 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

#this list are the sports that can have their standings pulled
SPORTS_LIST = {
    "MLB": ["MLB", "mlb"],
    "NHL": ["NHL", "nhl"],
    "NBA": ["NBA", "nba"],
    "NFL": ["NFL", "nfl"],
    "WNBA": ["WNBA", "wnba"],
    "MLS": ["MLS", "usa.1"],
    "NWSL": ["NWSL", "usa.nwsl"],
}

TWO_LINE_SPORTS = ["NBA", "WNBA"]  #sports whose standings take up two lines

no_games_text = ["No Games Today!!"]  #vector of text to use if no games are present

def main(config):
    sport = config.get("sport") or "MLB"
    sport_txt, sport_ext = SPORTS_LIST.get(sport)

    font = "CG-pixel-3x5-mono"  #set font

    #check for cached data
    stats_cached = cache.get("stats_rate_games%s" % sport)
    if stats_cached != None:
        print("Hit! Displaying %s gameday data." % sport)
        stats = json.decode(stats_cached)
    else:
        print("Miss! Calling %s gameday data." % sport)  #error code checked within each function!!!!
        today_str = get_date_str()

        #get the data
        if sport == "MLB":
            stats = get_mlbgames(today_str, config)
        elif sport == "NHL":
            stats = get_nhlgames(today_str, config)
        elif sport in ["NBA", "WNBA"]:
            stats = get_basketballgames(today_str, sport_ext, config)
        elif sport == "NFL":
            stats = get_nflgames(today_str, config)
        elif sport in ["MLS", "NWSL"]:
            stats = get_soccergames(today_str, sport_ext, config)

        #cache the data
        cache.set("stats_rate_games%s" % sport, json.encode(stats), ttl_seconds = 60)

    #get frames before display
    if stats == no_games_text and config.bool("gameday", False):
        return []  #return nothing if no games
    else:
        frame_vec = get_frames(stats, sport, font, config)

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
            schema.Toggle(
                id = "local_tz",
                name = "Local timezone",
                desc = "Enable to display game times in your local timezone (default is ET).",
                icon = "cog",
                default = False,
            ),
            schema.Dropdown(
                id = "sport",
                name = "Sport",
                desc = "The sport of the live games that should be displayed.",
                icon = "medal",
                options = sports,
                default = "MLB",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Frame speed",
                desc = "Change the speed that the games listed change.",
                icon = "cog",
                default = frame_speed[-1].value,
                options = frame_speed,
            ),
            schema.Toggle(
                id = "row_space",
                name = "Add space between rows",
                desc = "This may reduce the number of games displayed on each frame.",
                icon = "cog",
                default = False,
            ),
            schema.Toggle(
                id = "gameday",
                name = "Game day only",
                desc = "",
                icon = "calendar",
                default = False,
            ),
            schema.Toggle(
                id = "scroll_logic",
                name = "Scroll games?",
                desc = "",
                icon = "cog",
                default = False,
            ),
            schema.Toggle(
                id = "highlight_team",
                name = "Highlight team",
                desc = "Highlight a select team.",
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

def get_frames(stats, sport_txt, font, config):
    frame_vec = []
    if stats == no_games_text:
        header_txt = render.Box(width = 64, height = 7, child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Text(sport_txt, color = "#a00", font = font),
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

    force_two = sport_txt in TWO_LINE_SPORTS  #forces text on two lines

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
            ctmp2 = "#08FF08"
            ctmp3 = "#52BB52"
            if team["away"][1] == 1000 and force_two:
                ctmp = "#CCFFE5"
        elif i % 2 == 0:
            ctmp = "#c8c8fa"
            ctmp2 = "#a00"
            ctmp3 = "#228B22"  #dark green
        else:
            ctmp = "#fff"
            ctmp2 = "#D2691E"
            ctmp3 = "#52BB52"  #light green

        status_tmp = team["status"].split("/")

        #away team name
        if team["away"][1] == 1000 and force_two:  #NBA condition is safety net
            away_team.append(render.Text(team["away"][0], font = font, color = "#000", height = txt_height))
        else:
            away_team.append(render.Text(team["away"][0], font = font, color = ctmp, height = txt_height))

        #away team score
        if team["away"][1] == 1000 and force_two:  #NBA condition is safety net
            away_score.append(render.Text("-", font = font, color = "#000", height = txt_height))
        elif team["away"][1] < 0:
            away_score.append(render.Text("-", font = font, color = ctmp2, height = txt_height))
        else:
            away_score.append(render.Text(str(team["away"][1]), font = font, color = ctmp2, height = txt_height))

        #home team name
        if team["home"][1] == 1000 and force_two:  #NBA condition is safety net
            home_team.append(render.Text(team["home"][0], font = font, color = "#000", height = txt_height))
        else:
            home_team.append(render.Text(team["home"][0], font = font, color = ctmp, height = txt_height))

        #home team score

        if team["home"][1] == 1000 and force_two:  #NBA condition is safety net
            home_score.append(render.Text("-", font = font, color = "#000", height = txt_height))
        elif team["home"][1] < 0:
            home_score.append(render.Text("-", font = font, color = ctmp2, height = txt_height))
        else:
            home_score.append(render.Text(str(team["home"][1]), font = font, color = ctmp2, height = txt_height))

        #status_tmp = team["status"].split("/")
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
                    render.Text(sport_txt, color = "#a00", font = font),
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
                frame_data_tmp = render.Marquee(height = 27, scroll_direction = "vertical", child = frame_data_tmp)

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
def get_date_str():
    today = time.now().in_location("America/New_York")
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

    game_time_str = str(game_time.format("15:04"))
    if config.bool("local_tz", False):
        return game_time_str
    else:
        return game_time_str + "/ET"

def get_mlbgames(today_str, config):
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
        for key, value in game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            stats_tmp[key] = (value["team"]["abbreviation"], int(value.get("score", 0)))  #for some reason some games have no score so instead of doing -1, doing 0

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
                status_txt = adjust_gametime(game["gameDate"], config)
            else:  #not delayed before the game has started
                status_txt = status

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)

    return (stats)

def get_nhlgames(today_str, config):
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
        status = game["status"]["codedGameState"]  #Need to figure out what the possible values are here (may impact inning info)

        #get team info
        #team_info = dict()
        for key, value in game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            stats_tmp[key] = (value["team"]["abbreviation"], int(value.get("score", -1)))

        linescore = game.get("linescore", [])

        #https://statsapi.web.nhl.com/api/v1/gameStatus
        if status == "1":
            #status_txt = "Preview"
            status_txt = adjust_gametime(game["gameDate"], config)
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
            else:
                status_txt = period_T + "/" + period  #switch status and period here so time doesn't get cut off
        else:  #this is a safety net
            status_txt = status

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)

    return (stats)

def get_basketballgames(today_str, sport, config):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/basketball/%s/scoreboard" % sport
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
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact inning info)

        #get team info
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
        linescore = game.get("linescore", [])

        if status == "1":
            #status_txt = "Preview"
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = adjust_gametime(game_time_tmp, config)
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

def get_nflgames(today_str, config):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard"
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
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact inning info)

        #get team info
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
        linescore = game.get("linescore", [])

        if status == "1":
            #status_txt = "Preview"
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = adjust_gametime(game_time_tmp, config)
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

def get_soccergames(today_str, sport, config):
    start_date = today_str
    end_date = today_str
    base_URL = "https://site.api.espn.com/apis/site/v2/sports/soccer/%s/scoreboard" % sport
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
        status = game["status"]["type"]["id"]  #["codedGameState"] #Need to figure out what the possible values are here (may impact inning info)

        #get team info
        for key, value in enumerate(game["competitions"][0]["competitors"]):  #game["teams"].items():
            #team_info[key] = (value["team"]["abbreviation"],int(value.get("score",-1)))
            key2 = value["homeAway"]
            stats_tmp[key2] = (value["team"]["abbreviation"][:3], int(value.get("score", -1)))
            stats_tmp2[key2] = (value["team"]["abbreviation"][:3], 1000)
        linescore = game.get("linescore", [])

        if status == "1":
            game_time_tmp = game["date"].replace("Z", ":00Z")  #date does not include seconds so add here to parse time
            status_txt = adjust_gametime(game_time_tmp, config)
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

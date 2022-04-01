"""
Applet: Sports Scores
Summary: Get daily sports scores
Description: Get daily scores or live updates of sports. Scores for the previous day are shown until 11am EST.
Author: rs7q5
"""

#sports_scores.star
#Created 20220220 RIS
#Last Modified 20220226 RIS

load("render.star", "render")
load("http.star", "http")

#load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("time.star", "time")

#load("re.star","re")
#this list are the sports that can have their standings pulled
SPORTS_LIST = {
    "MLB": ["MLB", "mlb"],
    "NHL": ["NHL", "nhl"],
    #"NBA": ["NBA","nba"],
    #"NFL": ["NFL","nfl"],
    #"WNBA": ["WNBA","wnba"],
}

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
            stats = get_mlbgames(today_str)
        elif sport == "NHL":
            stats = get_nhlgames(today_str)

        #cache the data
        cache.set("stats_rate_games%s" % sport, json.encode(stats), ttl_seconds = 60)

    #get frames before display
    frame_vec = get_frames(stats, sport, font)

    return render.Root(
        delay = int(config.str("speed", "1000")),  #speed up scroll text
        child = render.Animation(children = frame_vec),
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
                default = "MLB",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Frame Speed",
                desc = "Change the speed that the games listed change.",
                icon = "cog",
                default = frame_speed[-1].value,
                options = frame_speed,
            ),
        ],
    )

def get_frames(stats, sport_txt, font):
    frame_vec = []
    if stats[0] == "No Games Today!!":
        header_txt = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Text(sport_txt, color = "#a00", font = font),
                render.Text("Away/Home", font = font),
            ],
        )

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
        return [frame_vec_tmp]
    away_team = []
    away_score = []
    home_team = []
    home_score = []
    status_txt = []
    status_txt2 = []
    frame_vec_tmp = []
    for i, team in enumerate(stats):
        if i % 2 == 0:
            ctmp = "#c8c8fa"
            ctmp2 = "#a00"
            ctmp3 = "#228B22"
        else:
            ctmp = "#fff"
            ctmp2 = "#D2691E"
            ctmp3 = "#52BB52"

        away_team.append(render.Text(team["away"][0], font = font, color = ctmp))
        if team["away"][1] < 0:
            away_score.append(render.Text("-", font = font, color = ctmp2))
        else:
            away_score.append(render.Text(str(team["away"][1]), font = font, color = ctmp2))
        home_team.append(render.Text(team["home"][0], font = font, color = ctmp))
        if team["home"][1] < 0:
            home_score.append(render.Text("-", font = font, color = ctmp2))
        else:
            home_score.append(render.Text(str(team["home"][1]), font = font, color = ctmp2))
        status_tmp = team["status"].split("/")
        status_txt.append(render.Text(status_tmp[0], font = font, color = ctmp))
        if len(status_tmp) == 1:
            status_txt2.append(render.Text("", font = font, color = ctmp2))
        else:
            status_txt2.append(render.Text(status_tmp[1], font = font, color = ctmp2))

        if (i % 5 == 4 or i == len(stats) - 1):  #stores five teams per frame
            game_cnt = (i + 1) % 5  #number of games on current frame
            if game_cnt != 0:  #add empty entries to space (only have to add to one array since other's must be in line)
                for j in range(5 - game_cnt):
                    away_team.append(render.Text("", font = font, color = ctmp))

            header_text = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.Text(sport_txt, color = "#a00", font = font),
                    render.Text("Away/Home", font = font),
                ],
            )
            frame_vec_tmp = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    header_text,
                    render.Row(
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
                    ),
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

    return (frame_vec)

######################################################
#functions
def http_check(URL):
    rep = http.get(URL)
    if rep.status_code != 200:
        fail("ESPN request failed with status %d", rep.status_code)
    return rep

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

def get_mlbgames(today_str):
    start_date = today_str
    end_date = today_str

    #start_date = "2021-06-10"   #tested using 2021-06-06 and 2021-06-10
    #end_date = "2021-06-10"     #tested using 2021-06-06 and 2021-06-10
    base_URL = "http://statsapi.mlb.com/api/v1/schedule/games/?sportId=1"
    full_URL = base_URL + "&startDate=" + start_date + "&endDate=" + end_date + "&hydrate=team,linescore"

    #print(full_URL)
    rep = http.get(full_URL)

    if rep.status_code != 200:
        return ["Error getting data"]
    else:
        data = rep.json()["dates"]

    if data == []:
        return ["No Games Today!!"]
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
        if linescore != []:
            inning = int(linescore["currentInning"])

            inningState = linescore["inningState"]

            #Need to check how data is updated during an actual game to check status codes
            if status == "F":
                if inning != 9:
                    status_txt = status + "/" + str(inning)
                else:
                    status_txt = status
            else:
                status_txt = inningState[:3] + "/" + str(inning)
        elif game["status"]["statusCode"] in ["S", "PW"]:
            game_time = time.parse_time(game["gameDate"]).in_location("America/New_York")
            game_time_str = str(game_time.format("15:04"))
            status_txt = game_time_str + "/EST"
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
        return ["No Games Today!!"]
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
            game_time = time.parse_time(game["gameDate"]).in_location("America/New_York")
            game_time_str = str(game_time.format("15:04"))

            status_txt = game_time_str + "/EST"
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
                status_txt = period + "/" + period_T
        else:  #this is a safety net
            status_txt = status

        stats_tmp["status"] = status_txt
        stats.append(stats_tmp)

    return (stats)

"""
Applet: Sports Standings
Summary: Get sports standings
Description: Get various sports standings (data courtesy of ESPN).
Author: rs7q5
"""
#sports_standings.star
#Created 20220119 RIS
#Last Modified 20221022 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("time.star", "time")
load("re.star", "re")

#this list are the sports that can have their standings pulled
SPORTS_LIST = {
    "Baseball": ("MLB", {
        "MLB": ["MLB", "mlb", "(1 = AL, 2 = NL)"],
    }),
    "Hockey": ("NHL", {
        "NHL": ["NHL", "nhl", "(1 = East, 2 = West)"],
    }),
    "Basketball": ("NBA", {
        "NBA": ["NBA", "nba", "(1 = East, 2 = West)"],
        "WNBA": ["WNBA", "wnba", "(1 = East, 2 = West)"],
    }),
    "Football": ("NFL", {
        "NFL": ["NFL", "nfl", "(1 = AFC, 2 = NFC)"],
    }),
}

def sport_from_league(league):
    for sport in SPORTS_LIST:
        for l in SPORTS_LIST[sport][1]:
            if l == league:
                return sport
    return None

def main(config):
    if config.bool("hide_app", False):
        return []

    sport_tmp = config.str("sport", "Baseball")
    if sport_tmp not in SPORTS_LIST:
        # older installations may hold league in the "sport" field
        sport = sport_from_league(sport_tmp)
        league = sport_tmp
    else:
        sport = sport_tmp
        league = config.str("league_%s" % sport, SPORTS_LIST[sport][0])

    league_txt, league_ext, sport_conf_code = SPORTS_LIST[sport][1].get(league)

    font = "CG-pixel-3x5-mono"  #set font

    #check for cached data
    stats_cached = cache.get("stats_rate/%s_%s" % (sport, league))
    if stats_cached != None:  #if any are None then all(title_cached)==False
        print("Hit! Displaying %s (%s) standings data." % (sport, league))
        stats = json.decode(stats_cached)
    else:
        print("Miss! Calling %s (%s) standings data." % (sport, league))  #error code checked within each function!!!!
        #print("Miss! Calling ESPN data.")  #error code checked within each function!!!!

        #get the data
        if sport == "Baseball":
            stats = get_mlbstandings()
        elif sport == "Hockey":
            stats = get_nhlstandings()
        elif sport == "Basketball":
            stats = get_basketballstandings(league_ext)
        elif sport == "Football":
            stats = get_footballstandings()

        #cache the data
        if stats != None:
            cache.set("stats_rate/%s_%s" % (sport, league), json.encode(stats), ttl_seconds = 28800)  #grabs it three times a day

    #get frames before display
    if stats == None:
        frame_vec = [render.WrappedText(width = 64, content = "Error getting %s (%s) standings!!!!" % (sport, league), font = font, linespacing = 1)]
    else:
        #filter stats
        sport_conf_code_split = [re.split("[() ,]", sport_conf_code)[x] for x in [3, 7]]  #sport_conf_code.split(" ")

        filter_idx = int(config.str("standings_filter", "0"))
        if filter_idx != 0:
            split_conf_txt = sport_conf_code_split[filter_idx - 1]
            stats2 = []
            for x in stats:
                if x["name"].lower().startswith(split_conf_txt.lower()):
                    stats2.append(x)
        else:
            stats2 = stats

        frame_vec = get_frames(stats2, league, font, config)

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
    standings_opt = [
        schema.Option(display = "All (Default)", value = "0"),
        schema.Option(display = "League/Conference 1", value = "1"),
        schema.Option(display = "League/Conference 2", value = "2"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sport",
                name = "Sport",
                desc = "The sport of the standings that should be displayed.",
                icon = "medal",
                options = sports,
                default = "Baseball",
            ),
            schema.Generated(
                id = "generated",  #other options are all in here because the generated fields go at the end always
                source = "sport",
                handler = more_options,
            ),
            schema.Dropdown(
                id = "standings_filter",
                name = "Filter Standings",
                desc = "Choose to display only a conference. Use the key noted next to the selected sport above.",
                icon = "filter",
                default = standings_opt[0].value,
                options = standings_opt,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Animation Speed",
                desc = "Change the speed that the standings change.",
                icon = "gear",
                default = frame_speed[-1].value,
                options = frame_speed,
            ),
            schema.Toggle(
                id = "highlight_team",
                name = "Highlight Team",
                desc = "Highlight a select team.",
                icon = "highlighter",
                default = False,
            ),
            schema.Text(
                id = "team_select",
                name = "Team Abbreviation",
                desc = "Enter the team code to highlight.",
                icon = "highlighter",
                default = "None",
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide standings?",
                desc = "",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

def more_options(sport):
    if sport not in SPORTS_LIST:
        # older installations may hold league in the "sport" field
        sport = sport_from_league(sport)

    leagues = [
        schema.Option(display = league[1][0] + " " + league[1][2], value = league[0])
        for league in SPORTS_LIST[sport][1].items()
    ]

    return [
        schema.Dropdown(
            id = "league_%s" % sport,  #id must be unique to get different default values
            name = "League",
            desc = "Select which league standings should be displayed.",
            icon = "medal",
            options = leagues,
            default = SPORTS_LIST[sport][0],
        ),
    ]

def get_frames(stats, league_txt, font, config):
    frame_vec = []
    for x in stats:
        name_split = re.split("[()/]", x["name"])
        team_name = []
        team_record = []
        team_rank = []
        for i, team in enumerate(x["data"]):
            team_tmp = render.Text(team[0], font = font)
            team_split = team[1].split("/")
            record_tmp = render.Text(team_split[0], font = font)
            rank_tmp = render.Text(team_split[1], font = font)
            if config.bool("highlight_team", False) and team[0] == config.str("team_select", "None").upper():
                ctmp = "#D2691E"
            elif i % 2 == 0:
                ctmp = "#c8c8fa"
            else:
                ctmp = "#fff"

            team_name.append(render.Text(team[0], font = font, color = ctmp))
            team_record.append(render.Text(team_split[0], font = font, color = ctmp))
            team_rank.append(render.Text(team_split[1], font = font, color = ctmp))

        header_text = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                render.Text(league_txt + " " + name_split[0].rstrip(), color = "#a00", font = font),
                render.Text(name_split[len(name_split) - 2], font = font),
            ],
        )

        ###
        #pad text for WNBA cases particularly
        line_max = 5
        txt_height = 5
        team_cnt = len(team_name)
        if team_cnt - line_max != 0:  #add empty entries to space (only have to add to one array since other's must be in line)
            for j in range(line_max - team_cnt):
                #away_team.append(render.Text("",font=font,color=ctmp))
                team_name.append(render.Text("", font = font, color = ctmp, height = txt_height))

        #create final frame
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
                            children = team_name,
                        ),
                        render.Column(
                            cross_align = "start",
                            children = team_record,
                        ),
                        render.Column(
                            cross_align = "end",
                            children = team_rank,
                        ),
                    ],
                ),
            ],
        )
        frame_vec.append(frame_vec_tmp)

    return (frame_vec)

######################################################
#functions
def http_check(URL):
    rep = http.get(URL)
    if rep.status_code != 200:
        print("ESPN request failed with status %d", rep.status_code)
        return None
    else:
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
#functions to get data for different sports
def get_mlbstandings():
    yearcheck = time.now().in_location("America/New_York").year  #MLB based in New York, year is used to make sure records exist otherwise retrieves previous years data
    base_URL = "https://site.api.espn.com/apis/v2/sports/baseball/mlb/standings"

    stats = dict()
    stats2 = []

    for i in range(6):  #iterate through each division
        standings_URL = base_URL + "?group=" + str(i + 1) + "&sort=gamesbehind"
        standings_rep = http_check(standings_URL)
        if standings_rep == None:
            return None
        if standings_rep.json()["abbreviation"] == "MLB":
            #no regular season records yet so get previous years (likely in preseason)
            standings_URL = base_URL + "?group=" + str(i + 1) + "&sort=gamesbehind&season=" + str(yearcheck - 1)
            standings_rep = http_check(standings_URL)

        div_name = standings_rep.json()["shortName"]
        standings_data = standings_rep.json()["standings"]["entries"]

        stats_tmp = []
        cnt = 0
        for (j, team) in enumerate(standings_data):  #iterate through each team in each division
            #get index of abbreviations (when playoff stuff gets added variables get shifted, WILL FAIL IF NONE OF THESE EXIST, WHICH SHOULDN'T HAPPEN)
            stat_name = [x["abbreviation"] for x in team["stats"]]
            total_idx = stat_name.index("Total")
            GB_idx = stat_name.index("GB")

            name = team["team"]["abbreviation"]
            record = team["stats"][total_idx]["displayValue"]  #W-L
            GB = team["stats"][GB_idx]["displayValue"]  #games back

            record_full = record + "/" + str(GB)
            stats_tmp.append((name, record_full, record, str(GB)))
        stats[div_name] = stats_tmp
        stats2.append(dict(name = div_name + " (W-L/GB)", data = stats_tmp))

    #set up data for frames to work
    return (stats2)

def get_nhlstandings():
    base_URL = "https://site.api.espn.com/apis/v2/sports/hockey/nhl/standings"
    stats = []
    for i in range(2):  #iterate through each division
        standings_URL = base_URL + "?group=" + str(i + 7) + "&sort=points"
        standings_rep = http_check(standings_URL)
        if standings_rep == None:
            return None
        conf_name = standings_rep.json()["abbreviation"]
        standings_data = standings_rep.json()["children"]
        for (j, div) in enumerate(standings_data):  #iterate through each team in each division
            div_name = div["abbreviation"]
            div_data = div["standings"]["entries"]
            stats_tmp = []
            for (k, team) in enumerate(div_data):
                name = team["team"]["abbreviation"]

                #get index of abbreviations (when playoff stuff gets added variables get shifted, WILL FAIL IF NONE OF THESE EXIST, WHICH SHOULDN'T HAPPEN)
                stat_name = [x["abbreviation"] for x in team["stats"]]
                total_idx = stat_name.index("TOTAL")
                pt_idx = stat_name.index("PTS")
                GP_idx = stat_name.index("GP")

                record = team["stats"][total_idx]["displayValue"]  #W-L-OTL, pts
                pts = team["stats"][pt_idx]["value"]  #points
                pt_pct = pts / (team["stats"][GP_idx]["value"] * 2)  #pts/(GP*2) calculate point percentage (first tie breaker rules,for some reason raw standings doesn't sort ties correctly in JSON)

                record_text = record.split(",")
                record_full = record_text[0] + "/" + record_text[1].split(" ")[1]
                stats_tmp.append((name, record_full, record, pts, pt_pct))

            #sort by points then percentage (just in case the names aren't pulled in the same)
            team_sort = sorted(stats_tmp, key = lambda x: (x[3], x[4]), reverse = True)

            #store data so only get 4 teams per frame (ensures they all fit)
            frame_name = conf_name + " " + div_name + " (W-L-OTL/PTS)"
            stats.append(dict(name = frame_name, data = team_sort[:4]))
            stats.append(dict(name = frame_name, data = team_sort[4:]))
    return (stats)

def get_basketballstandings(league_ext):
    #NBA stats are only sorted by conference because divisions don't matter for playoffs!!
    base_URL = "https://site.api.espn.com/apis/v2/sports/basketball/%s/standings" % league_ext
    standings_URL = base_URL + "?sort=winpercent"
    standings_rep = http_check(standings_URL)
    if standings_rep == None:
        return None
    standings_data = standings_rep.json()["children"]

    stats = dict()
    stats2 = []
    for i, conf_data in enumerate(standings_data):  #iterate through each division
        #div_name = conf_data["abbreviation"]
        div_name = conf_data["name"][0:4]  #abbreviation for WNBA is only E or W
        div_data = reversed(conf_data["standings"]["entries"])
        stats_tmp = []
        cnt = 0
        for (j, team) in enumerate(div_data):  #iterate through each team in each division
            name = team["team"]["abbreviation"]
            stat_name = [x["shortDisplayName"] for x in team["stats"]]
            total_idx = stat_name.index("OVER")
            pct_idx = stat_name.index("PCT")
            GB_idx = stat_name.index("GB")
            record = team["stats"][total_idx]["displayValue"]  #W-L
            GB = team["stats"][GB_idx]["displayValue"]  #games behind
            pct = team["stats"][pct_idx]["value"]  #win percent

            record_full = record + "/" + str(GB)
            stats_tmp.append((name, record_full, record, str(GB), pct))
            conf_logic = True if (j == 5 and league_ext == "wnba") else False

            if j % 5 == 4 or conf_logic:  #store it so they are split across
                stats[div_name] = stats_tmp
                stats2.append(dict(name = div_name + " (W-L/GB)", data = stats_tmp))
                stats_tmp = []

    return (stats2)

def get_footballstandings():
    base_URL = "https://site.api.espn.com/apis/v2/sports/football/nfl/standings"
    stats = []
    for i in range(2):  #iterate through each division
        standings_URL = base_URL + "?group=" + str(i + 7) + "&sort=winpercent"
        standings_rep = http_check(standings_URL)
        if standings_rep == None:
            return None
        conf_name = standings_rep.json()["abbreviation"]
        standings_data = standings_rep.json()["children"]
        for (j, div) in enumerate(standings_data):  #iterate through each team in each division
            div_name = div["abbreviation"]
            div_data = div["standings"]["entries"]
            stats_tmp = []
            for (k, team) in enumerate(div_data):
                name = team["team"]["abbreviation"]

                #get index of abbreviations (when playoff stuff gets added variables get shifted, WILL FAIL IF NONE OF THESE EXIST, WHICH SHOULDN'T HAPPEN)
                #stat_name = [x["abbreviation"] for x in team["stats"]]
                stat_name = [x["name"] for x in team["stats"]]  #not all stats have abbreviation so used name
                total_idx = stat_name.index("All Splits")
                pct_idx = stat_name.index("winPercent")

                record = team["stats"][total_idx]["displayValue"]  #W-L-T
                pct = team["stats"][pct_idx]["value"]  #win percent
                pct_str = team["stats"][pct_idx]["displayValue"]

                #record_text = record.split(",")
                record_full = record + "/" + pct_str

                #record_full = record_text[0]+"/"+record_text[1].split(" ")[1]
                stats_tmp.append((name, record_full, record, pct))

            #sort by points then percentage (just in case the names aren't pulled in the same)
            team_sort = sorted(stats_tmp, key = lambda x: (x[3]), reverse = True)  #only sorts by win percent
            frame_name = conf_name + " " + div_name + " (W-L-T/PCT)"
            stats.append(dict(name = frame_name, data = team_sort))

    return (stats)

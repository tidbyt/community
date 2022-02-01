"""
Applet: Sports Standings
Summary: Sports standings from ESPN
Description: Get various sports standings (data courtesy of ESPN).
Author: rs7q5 (RIS)
"""
#sports_standings.star
#Created 20220119 RIS
#Last Modified 20220201 RIS

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("schema.star", "schema")
load("re.star", "re")

#this list are the sports that can have their standings pulled
#ESPN_URL = "https://www.espn.com/"
ESPN_SPORTS_LIST = {
    "MLB": ["MLB", "mlb"],
    "NHL": ["NHL", "nhl"],
    "NBA": ["NBA", "nba"],
    #"NFL": ["NFL","nfl"],
    #"WNBA": ["WNBA","wnba"],
}

def main(config):
    sport = config.get("sport") or "MLB"
    sport_txt, sport_ext = ESPN_SPORTS_LIST.get(sport)

    font = "CG-pixel-3x5-mono"  #set font

    #check for cached data
    stats_cached = cache.get("stats_rate/%s" % sport)
    if stats_cached != None:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")
        stats = json.decode(stats_cached)
        frame_vec = get_frames(stats, font)
    else:
        print("Miss! Calling ESPN data.")  #error code checked within each function!!!!

        #get the data
        if sport == "MLB":
            stats = get_mlbstats()
        elif sport == "NHL":
            stats = get_nhlstats()
        elif sport == "NBA":
            stats = get_nbastats()

        #cache the data
        cache.set("stats_rate/%s" % sport, json.encode(stats), ttl_seconds = 86400)  #grabs it once a day

        #get frames before display
        frame_vec = get_frames(stats, sport, font)
        #frame_vec.insert(0,render.WrappedText(sport + " Standings",color="#a00",font=font))

    return render.Root(
        delay = 1000,  #speed up scroll text
        child = render.Animation(children = frame_vec),
    )

def get_schema():
    sports = [
        schema.Option(display = sport, value = sport)
        for sport in ESPN_SPORTS_LIST
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
                default = "MLB",
            ),
        ],
    )

def get_frames(stats, sport_txt, font):
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
            if i % 2 == 0:
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
                render.Text(sport_txt + " " + name_split[0].rstrip(), color = "#a00", font = font),
                render.Text(name_split[len(name_split) - 2], font = font),
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
#functions to get data for different sports
def get_mlbstats():
    base_URL = "https://site.api.espn.com/apis/v2/sports/baseball/mlb/standings"

    stats = dict()
    stats2 = []
    for i in range(6):  #iterate through each division
        standings_URL = base_URL + "?group=" + str(i + 1) + "&sort=gamesbehind"
        standings_rep = http_check(standings_URL)

        div_name = standings_rep.json()["shortName"]
        standings_data = standings_rep.json()["standings"]["entries"]

        stats_tmp = []
        cnt = 0
        for (j, team) in enumerate(standings_data):  #iterate through each team in each division
            name = team["team"]["abbreviation"]
            record = team["stats"][33]["displayValue"]  #W-L
            GB = team["stats"][4]["displayValue"]  #games back

            record_full = record + "/" + str(GB)
            stats_tmp.append((name, record_full, record, str(GB)))
        stats[div_name] = stats_tmp
        stats2.append(dict(name = div_name + " (W-L/GB)", data = stats_tmp))

    #set up data for frames to work
    return (stats2)

def get_nhlstats():
    base_URL = "https://site.api.espn.com/apis/v2/sports/hockey/nhl/standings"
    stats = []
    for i in range(2):  #iterate through each division
        standings_URL = base_URL + "?group=" + str(i + 7) + "&sort=points"
        standings_rep = http_check(standings_URL)

        conf_name = standings_rep.json()["abbreviation"]
        standings_data = standings_rep.json()["children"]
        for (j, div) in enumerate(standings_data):  #iterate through each team in each division
            div_name = div["abbreviation"]
            div_data = div["standings"]["entries"]
            stats_tmp = []
            for (k, team) in enumerate(div_data):
                name = team["team"]["abbreviation"]
                record = team["stats"][15]["displayValue"]  #W-L-OTL, pts
                pts = team["stats"][6]["value"]  #points
                pt_pct = pts / (team["stats"][3]["value"] * 2)  #pts/(GP*2) calculate point percentage (first tie breaker rules,for some reason raw standings doesn't sort ties correctly in JSON)

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

def get_nbastats():
    #NBA stats are only sorted by conference because divisions don't matter for playoffs!!
    base_URL = "https://site.api.espn.com/apis/v2/sports/basketball/nba/standings"
    standings_URL = base_URL + "?sort=winpercent"
    standings_rep = http_check(standings_URL)
    standings_data = standings_rep.json()["children"]

    stats = dict()
    stats2 = []
    for i, conf_data in enumerate(standings_data):  #iterate through each division
        div_name = conf_data["abbreviation"]
        div_data = reversed(conf_data["standings"]["entries"])
        stats_tmp = []
        cnt = 0
        for (j, team) in enumerate(div_data):  #iterate through each team in each division
            name = team["team"]["abbreviation"]
            record = team["stats"][11]["displayValue"]  #W-L
            GB = team["stats"][4]["displayValue"]  #games behind
            pct = team["stats"][3]["value"]  #win percent

            record_full = record + "/" + str(GB)
            stats_tmp.append((name, record_full, record, str(GB), pct))
            if j % 5 == 4:  #store it in every fifth frame
                stats[div_name] = stats_tmp
                stats2.append(dict(name = div_name + " (W-L/GB)", data = stats_tmp))
                stats_tmp = []

    return (stats2)

"""
Applet: MLB Leaders
Summary: Get MLB league leaders
Description: Get the top 2 (3 stats) or 3 (1 stat) league leaders in various MLB stats.
Author: rs7q5
"""
#mlb_leaders.star
#Created 20220412 RIS
#Last Modified 20230210 RIS

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#this list are the sports that can have their standings pulled
#leaderType_URL = "https://statsapi.mlb.com/api/v1/leagueLeaderTypes"
STATS_LIST = {
    "assists": "assists",
    "shutouts": "shutouts",
    "homeRuns": "homeRuns",
    "sacrificeBunts": "sacrificeBunts",
    "sacrificeFlies": "sacrificeFlies",
    "runs": "runs",
    "groundoutToFlyoutRatio": "groundoutToFlyoutRatio",
    "stolenBases": "stolenBases",
    "battingAverage": "battingAverage",
    "groundOuts": "groundOuts",
    "numberOfPitches": "numberOfPitches",
    "onBasePercentage": "onBasePercentage",
    "caughtStealing": "caughtStealing",
    "groundIntoDoublePlays": "groundIntoDoublePlays",
    "totalBases": "totalBases",
    "earnedRunAverage": "earnedRunAverage",
    "fieldingPercentage": "fieldingPercentage",
    "walksAndHitsPerInningPitched": "walksAndHitsPerInningPitched",
    "flyouts": "flyouts",
    "hitByPitches": "hitByPitches",
    "gamesPlayed": "gamesPlayed",
    "walks": "walks",
    "sluggingPercentage": "sluggingPercentage",
    "onBasePlusSlugging": "onBasePlusSlugging",
    "runsBattedIn": "runsBattedIn",
    "triples": "triples",
    "extraBaseHits": "extraBaseHits",
    "hits": "hits",
    "atBats": "atBats",
    "strikeouts": "strikeouts",
    "doubles": "doubles",
    "totalPlateAppearances": "totalPlateAppearances",
    "intentionalWalks": "intentionalWalks",
    "wins": "wins",
    "losses": "losses",
    "saves": "saves",
    "wildPitch": "wildPitch",
    "airOuts": "airOuts",
    "balk": "balk",
    "blownSaves": "blownSaves",
    "catcherEarnedRunAverage": "catcherEarnedRunAverage",
    "catchersInterference": "catchersInterference",
    "chances": "chances",
    "completeGames": "completeGames",
    "doublePlays": "doublePlays",
    "earnedRun": "earnedRun",
    "errors": "errors",
    "gamesFinished": "gamesFinished",
    "gamesStarted": "gamesStarted",
    "hitBatsman": "hitBatsman",
    "hitsPer9Inn": "hitsPer9Inn",
    "holds": "holds",
    "innings": "innings",
    "inningsPitched": "inningsPitched",
    "outfieldAssists": "outfieldAssists",
    "passedBalls": "passedBalls",
    "pickoffs": "pickoffs",
    "pitchesPerInning": "pitchesPerInning",
    "putOuts": "putOuts",
    "rangeFactorPerGame": "rangeFactorPerGame",
    "rangeFactorPer9Inn": "rangeFactorPer9Inn",
    "saveOpportunities": "saveOpportunities",
    "stolenBasePercentage": "stolenBasePercentage",
    "strikeoutsPer9Inn": "strikeoutsPer9Inn",
    "strikeoutWalkRatio": "strikeoutWalkRatio",
    "throwingErrors": "throwingErrors",
    "totalBattersFaced": "totalBattersFaced",
    "triplePlays": "triplePlays",
    "walksPer9Inn": "walksPer9Inn",
    "winPercentage": "winPercentage",
}
STATS_LIST_SORTED = dict(sorted(list(STATS_LIST.items()), key = lambda x: x))  #get list in alphabetical order (original order is the order that MLB api has them in)

no_stat_text = ["No Stats!!"]  #vector of text to use if no games are present

font = "CG-pixel-3x5-mono"  #set font
font2 = "CG-pixel-4x5-mono"
font3 = "5x8"
font4 = "tom-thumb"

mlb_blue = "#002D72"
mlb_red = "#D50032"

color_opts = ["#c8c8fa", "#fff"]

def main(config):
    if config.bool("hide_app", False):
        return []

    #get config settings
    if config.bool("show_random", False):
        statName_vec = []
        for x in range(3):
            statName_vec.append(STATS_LIST_SORTED.values()[random.number(0, len(STATS_LIST_SORTED) - 1)])
    else:
        statName_vec = [config.str("statName%d" % (idx + 1), x) for idx, x in enumerate(["homeRuns", "hits", "battingAverage"])]
    display_opt = config.bool("show_single", False)

    frames_all = []
    frames_all2 = []
    for _, x in enumerate(statName_vec):
        #get data

        stat_tmp = get_leaders(x)

        #create frames
        if config.bool("title_bkgd", False):
            title_tmp = render.Box(
                width = 64,
                height = 5,
                color = mlb_blue,  #002d7266",#"#00000099",
                child = render.Marquee(width = 64, child = render.Text(format_title(x), font = font, color = "#fff")),
            )
        else:
            title_tmp = render.Marquee(width = 64, child = render.Text(format_title(x), font = font, color = mlb_blue))
        frame_tmp = [title_tmp]
        frames_all2.append(title_tmp)

        if type(stat_tmp) != "dict":
            frame_tmp.append(render.WrappedText(stat_tmp[0], font = font, color = mlb_red))
            frames_all2.append(render.Marquee(width = 64, child = render.Text(stat_tmp[0], font = font, color = mlb_red)))
        elif display_opt:  #show statistic 1 only
            frame_tmp.append(get_frame_single(stat_tmp))
        else:  #display multiple stats
            frames_all2.append(get_frame_multi(stat_tmp))

        frames_all.append(render.Column(frame_tmp))

        if display_opt:  #only need first statistic
            break

    final_frame = frames_all[0] if display_opt else render.Column(children = frames_all2)  #show single frame or not

    return render.Root(
        delay = int(config.str("speed", "50")),  #speed up scroll text
        show_full_animation = True,
        child = final_frame,
    )

def get_schema():
    stats = [
        schema.Option(display = format_title(stat), value = stat)
        for stat in STATS_LIST_SORTED.keys()
    ]
    frame_speed = [
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "75"),
        schema.Option(display = "Normal (Default)", value = "50"),
        schema.Option(display = "Fast", value = "40"),
        schema.Option(display = "Faster", value = "30"),
        schema.Option(display = "Fastest", value = "20"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "statName1",
                name = "Statistic 1",
                desc = "Choose a statistic.",
                icon = "baseballBatBall",
                options = stats,
                default = "homeRuns",
            ),
            schema.Dropdown(
                id = "statName2",
                name = "Statistic 2",
                desc = "Choose a statistic.",
                icon = "baseballBatBall",
                options = stats,
                default = "hits",
            ),
            schema.Dropdown(
                id = "statName3",
                name = "Statistic 3",
                desc = "Choose a statistic.",
                icon = "baseballBatBall",
                options = stats,
                default = "battingAverage",
            ),
            schema.Toggle(
                id = "show_single",
                name = "Show only Statistic 1?",
                desc = "Show only Statistic 1 in a vertical format?",
                icon = "baseball",
                default = False,
            ),
            schema.Toggle(
                id = "show_random",
                name = "Randomize the statistic(s)?",
                desc = "",
                icon = "shuffle",
                default = False,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Frame Speed",
                desc = "Change the speed that the text scrolls.",
                icon = "gear",
                default = frame_speed[2].value,
                options = frame_speed,
            ),
            schema.Toggle(
                id = "title_bkgd",
                name = "Title Background",
                desc = "Make the title background blue instead?",
                icon = "fillDrip",
                default = False,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide app?",
                desc = "",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

######################################################
#functions
def format_title(x):
    #split and formats a title that is formatted with no spaces but can be separated by capital letters or a single digit

    title = ""
    for idx, y in enumerate(list(x.elems())):
        if idx == 0:
            title += y.upper()
        else:
            title += " %s" % y if y.isupper() or y.isdigit() else y

    return title

def split_sentence(sentence, span, **kwargs):
    #split long sentences along with long words

    sentence_new = ""
    for word in sentence.split(" "):
        if len(word) >= span:
            sentence_new += split_word(word, span, **kwargs) + " "

        else:
            sentence_new += word + " "

    return sentence_new

def split_word(word, span, join_word = False):
    #split long words

    word_split = []

    for i in range(0, len(word), span):
        word_split.append(word[i:i + span])
    if join_word:
        return " ".join(word_split)
    else:
        return word_split

def text_len(x, l):
    #this calculation assumes you're using a monospaced font
    #+1 because there is a pixel space between characters and -1 is because last character shouldn't have a single pixel space after it
    return len(x) * (l + 1) - 1

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

#####################################################
#functions to get data or create frames
def get_leaders(statName):
    #get leader stats
    #base_URL = "https://statsapi.mlb.com/api/v1/stats/leaders"
    today = time.now().in_location("America/New_York")  #get year (season)

    #check for cached data
    stats = {}
    stat_cached = cache.get("mlb_leagueleaders_%s" % statName)
    if stat_cached != None:
        print("Hit! Displaying MLB league leaders in %s data." % statName)
        stats = json.decode(stat_cached)
    else:
        print("Miss! Calling MLB league leaders in %s data." % statName)  #error code checked within each function!!!!
        full_URL = "https://statsapi.mlb.com/api/v1/stats/leaders?sportId=1&leaderCategories=%s&season=%s&hydrate=team&limit=5" % (statName, today.year)

        #print(full_URL)
        rep = http.get(full_URL)
        if rep.status_code != 200:
            return ["Error getting data"]
        else:
            data = rep.json()["leagueLeaders"]

        if data == []:
            return no_stat_text
        else:
            stats = dict()

            #print(data["statGroup"])
            for _, x in enumerate(data):
                stats_tmp = []
                statGroup = x["statGroup"]
                if x.get("leaders") != None:
                    for (idx2, player) in enumerate(x["leaders"]):
                        rank = int(player["rank"])
                        name = player["person"]["fullName"]
                        team = player.get("team", {"abbreviation": "?"})["abbreviation"]  #player["team"]["abbreviation"]
                        value = player["value"]
                        stats_tmp.append([rank, name, team, value])  #this becomes
                        if idx2 == 2:  #don't get more than 3 players in case of ties
                            break
                stats[statGroup] = stats_tmp
                #print(stats_tmp)

            #cache the data
            cache.set("mlb_leagueleaders_%s" % statName, json.encode(stats), ttl_seconds = 43200)  #grab twice a day

    return stats

def get_frame_single(stat):
    #format results for displaying multiple stats
    frame_tmp = []
    for key, val in stat.items():
        frame_tmp.append(render.Box(width = 64, height = 7, child = render.Text(key, font = font), color = "#808080"))
        if val == []:
            frame_tmp.append(render.Text("NONE", font = font))
        else:
            for idx2, y in enumerate(val):
                ctmp = color_opts[idx2 % 2]  #get color

                #format rank and name
                name_tmp = split_sentence(y[1], 8, join_word = True)
                name_final = render.WrappedText(content = name_tmp, width = 32, font = font4, color = ctmp)
                rank_name = render.Row(
                    children = [
                        render.Text("%d." % y[0], font = font4, color = ctmp),  #rank
                        name_final,
                    ],
                )

                #create final row with team and stats
                frame_tmp.append(render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        rank_name,
                        render.Column(
                            cross_align = "end",
                            children = [
                                render.Text(y[2], font = font, color = ctmp),  #team
                                render.Text(y[3], font = font, color = mlb_red),  #value
                            ],
                        ),
                    ],
                ))

    return render.Marquee(render.Column(expanded = False, children = frame_tmp), scroll_direction = "vertical", height = 27, offset_start = 32, offset_end = 32)

def get_frame_multi(stat):
    #format results for displaying multiple stats
    frame_tmp = []
    for key, val in stat.items():
        frame_tmp.append(render.Text(key, font = font, color = mlb_red))  #"#52BB52"))
        if val == []:
            frame_tmp.append(render.Text("NONE", font = font))
            continue
        else:
            for idx2, y in enumerate(val):
                ctmp = color_opts[idx2 % 2]  #get color

                #create final frame here
                full_text = render.Row(
                    children = [
                        render.Text("%d." % y[0], font = font4, color = ctmp),  #rank
                        render.Text(y[1], font = font4, color = ctmp),  #name
                        render.Text("(%s/%s)" % (y[2], y[3]), font = font, color = ctmp),  #team and value
                    ],
                )
                frame_tmp.append(full_text)
                if idx2 == 1:  #only show top 2
                    break
    return render.Marquee(render.Row(expanded = False, children = frame_tmp), scroll_direction = "horizontal", width = 64, offset_start = 64, offset_end = 64)

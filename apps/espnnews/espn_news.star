"""
Applet: ESPN News
Summary: Get top headlines from ESPN
Description: Displays the top three headlines from the "Top Headlines" section on ESPN or a specific user-selected sport.
Author: rs7q5
"""
#espn_news.star
#Created 20211231 RIS
#Last Modified 20220501 RIS

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#this list are any of the sports that have a "Top headlines" section and can be done with the following base ESPN_URL
ESPN_URL = "https://www.espn.com/"
ESPN_SPORTS_LIST = {
    "All": ["All", ""],  #default
    "NFL": ["NFL", "nfl"],
    "NBA": ["NBA", "nba"],
    "NHL": ["NHL", "nhl"],
    "Soccer": ["SOCC", "soccer"],
    "Golf": ["Golf", "golf"],
    "NCAAF": ["NCAAF", "college-football"],
    "College Sports": ["COL.", "college-sports"],
    "F1": ["F1", "f1"],
    "MLB": ["MLB", "mlb"],
    "MMA": ["MMA", "mma"],
    "NASCAR": ["NASC", "racing/nascar"],
    "NCAAM": ["NCAAM", "mens-college-basketball"],
    "NCAAW": ["NCAAW", "womens-college-basketball"],
    "Olympic Sports": ["OLY", "olympics"],
    "Racing": ["RCNG", "racing"],
    "Tennis": ["TENNS", "tennis"],
    "WNBA": ["WNBA", "wnba"],
}

def main(config):
    sport = config.get("sport") or "All"
    sport_txt, sport_ext = ESPN_SPORTS_LIST.get(sport)

    #create full URL
    ESPN_API_URL = ESPN_URL + sport_ext
    if sport != "All":
        ESPN_API_URL += "/?xhr=1"
    else:
        ESPN_API_URL += "?xhr=1"

    font = "CG-pixel-4x5-mono"  #set font

    #check for cached data
    cached_sport_txt = "_" + sport
    title_cached = cache.get("title_rate1" + cached_sport_txt), cache.get("title_rate2" + cached_sport_txt), cache.get("title_rate3" + cached_sport_txt)
    if all(title_cached) != False:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")
        title = title_cached
    else:
        print("Miss! Calling ESPN data.")
        rep = http.get(ESPN_API_URL)
        if rep.status_code != 200:
            #fail("ESPN request failed with status %d", rep.status_code)
            title = ["Error getting data!!!!", "", ""]
        else:
            #get top 3 newest headlines
            title = []
            for i in range(3):
                title.append(rep.json()["headlines"][i]["headline"])

            #format strings so they are all the same length (leads to better scrolling)
            max_len = max([len(x) for x in title])  #length of each string

            #add padding to shorter titles
            for i, x in enumerate(title):
                title[i] = x + " " * (max_len - len(x))

            #cache headlines
            for (i, x) in enumerate(title):
                cache_name = "title_rate" + str(i + 1) + cached_sport_txt  #i+1 just to be consistent when retrieving cached names
                cache.set(cache_name, x, ttl_seconds = 14400)

    #format output
    title_format = []
    if config.bool("scroll_vertical", False):  #scroll text vertically if true
        #redo titles to make sure words don't get cut off
        for title_tmp in title:
            title_tmp2 = split_sentence(title_tmp.rstrip(), 9, join_word = True).rstrip()

            title_format.append(render.Padding(child = render.WrappedText(content = title_tmp2, font = font, linespacing = 1), pad = (0, 0, 0, 6)))

        title_format2 = render.Marquee(
            height = 32,
            scroll_direction = "vertical",
            child = render.Column(
                #main_align="space_between",
                cross_align = "start",
                children = title_format,
            ),
            offset_start = 32,
            offset_end = 32,
        )

    else:
        for title_tmp in title:
            title_format.append(render.Text(content = title_tmp, font = font))
        title_format2 = render.Marquee(
            width = 64,
            child = render.Column(
                main_align = "space_around",
                cross_align = "start",
                expanded = True,
                children = title_format,
            ),
            offset_start = 64,
            offset_end = 64,
        )
    return render.Root(
        delay = int(config.str("speed", "30")),  #speed up scroll text
        show_full_animation = True,
        child = render.Row(
            expanded = True,
            children = [
                render.Column(
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text("ESPN", color = "#a00", font = font),
                        render.Text(sport_txt, color = "#a00", font = font),
                    ],
                ),
                title_format2,
            ],
        ),
    )

def get_schema():
    sports = [
        schema.Option(display = sport, value = sport)
        for sport in ESPN_SPORTS_LIST
    ]
    scroll_speed = [
        schema.Option(display = "Slower", value = "100"),
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal", value = "50"),
        schema.Option(display = "Fast (Default)", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sport",
                name = "Sport",
                desc = "The headlines of the sport to be displayed.",
                icon = "newspaper",
                options = sports,
                default = "All",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change the speed that text scrolls.",
                icon = "gear",
                default = scroll_speed[-1].value,
                options = scroll_speed,
            ),
            schema.Toggle(
                id = "scroll_vertical",
                name = "Scroll Vertically?",
                desc = "Should text scroll vertically?",
                icon = "gear",
                default = False,
            ),
        ],
    )

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

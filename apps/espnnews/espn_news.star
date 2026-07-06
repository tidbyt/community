"""
Applet: ESPN News
Summary: Get top headlines from ESPN
Description: Displays the top three headlines from the "Top Headlines" section on ESPN or a specific user-selected sport.
Author: rs7q5
"""
#espn_news.star
#Created 20211231 RIS
#Last Modified 20230516 RIS
#
# FIX (this version): the original app pulled JSON out of ESPN's website via
# the "?xhr=1" query trick (https://www.espn.com/nfl/?xhr=1). That's not a
# real API - it's ESPN's frontend data layer, and it changed shape, which is
# why the app started returning "Error getting data!!!!" for everyone.
# This version instead calls ESPN's actual public sports API
# (site.api.espn.com), which returns headlines under "articles" instead of
# "headlines". Everything else - schema, scrolling, formatting - is unchanged.

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Second element of each entry is now the site.api.espn.com path segment
# (sport/league), not a espn.com URL path. A few categories (Soccer, Golf,
# College Sports, Olympic Sports, Racing, Tennis) don't have one single
# universal feed on this API - ESPN requires a specific league slug (e.g.
# eng.1 for Premier League, pga for golf) - so those default to a reasonable
# top-level pick rather than a true "all of X" feed.
ESPN_SPORTS_LIST = {
    "All": ["All", ""],  #default - general top headlines across sports
    "NFL": ["NFL", "football/nfl"],
    "NBA": ["NBA", "basketball/nba"],
    "NHL": ["NHL", "hockey/nhl"],
    "Soccer": ["SOCC", "soccer/eng.1"],  #Premier League as a stand-in for general soccer
    "Golf": ["Golf", "golf/pga"],
    "NCAAF": ["NCAAF", "football/college-football"],
    "College Sports": ["COL.", "football/college-football"],
    "F1": ["F1", "racing/f1"],
    "MLB": ["MLB", "baseball/mlb"],
    "MMA": ["MMA", "mma/ufc"],
    "NASCAR": ["NASC", "racing/nascar"],
    "NCAAM": ["NCAAM", "basketball/mens-college-basketball"],
    "NCAAW": ["NCAAW", "basketball/womens-college-basketball"],
    "Olympic Sports": ["OLY", ""],  #no dedicated feed - falls back to general news
    "Racing": ["RCNG", "racing/nascar"],
    "Tennis": ["TENNS", "tennis/atp"],
    "WNBA": ["WNBA", "basketball/wnba"],
}

def main(config):
    sport = config.get("sport") or "All"
    sport_txt, sport_ext = ESPN_SPORTS_LIST.get(sport)

    #build the real ESPN API URL
    if sport_ext == "":
        ESPN_API_URL = "https://site.api.espn.com/apis/site/v2/sports/news"
    else:
        ESPN_API_URL = "https://site.api.espn.com/apis/site/v2/sports/%s/news" % sport_ext

    font = "CG-pixel-4x5-mono"  #set font

    #get data
    rep = http.get(url = ESPN_API_URL, ttl_seconds = 14400)  #update every 4 hours
    if rep.status_code != 200:
        title = ["Error getting data!!!!", "", ""]
    else:
        # defensive json parse: make sure we have a dict before .get()
        ok_json = None
        try:
            ok_json = rep.json()
        except Exception:
            ok_json = None

        if ok_json is None or type(ok_json) != dict:
            title = ["No headlines available", "", ""]
        else:
            articles = ok_json.get("articles", [])
            if len(articles) == 0:
                title = ["No headlines available", "", ""]
            else:
                #get top 3 newest headlines
                title = []
                for i in range(min(3, len(articles))):
                    a = articles[i]
                    # defensive extraction: headline -> title -> description -> str
                    if type(a) == dict:
                        headline_text = a.get("headline") or a.get("title") or a.get("description") or ""
                    else:
                        headline_text = str(a)
                    title.append(headline_text)
                #pad out to 3 entries if fewer than 3 came back (Starlark doesn't support while)
                missing = 3 - len(title)
                if missing > 0:
                    for _ in range(missing):
                        title.append("")

        #format strings so they are all the same length (leads to better scrolling)
        max_len = max([len(x) for x in title])  #length of each string

        #add padding to shorter titles
        for i, x in enumerate(title):
            title[i] = x + " " * (max_len - len(x))

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

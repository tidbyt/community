"""
Applet: ESPN News
Summary: Get top headlines from ESPN
Description: Displays the top three headlines from the "Top Headlines" section on ESPN or a specific user-selected sport.
Author: rs7q5 (RIS)
"""
#espn_news.star
#Created 20211231 RIS
#Last Modified 20220117 RIS

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
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
    title_cached = cache.get("title_rate1"), cache.get("title_rate2"), cache.get("title_rate3")

    if all(title_cached) != False:  #if any are None then all(title_cached)==False
        print("Hit! Displaying cached data.")
        title = title_cached
    else:
        print("Miss! Calling ESPN data.")
        rep = http.get(ESPN_API_URL)
        if rep.status_code != 200:
            fail("ESPN request failed with status %d", rep.status_code)

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
            cache_name = "title_rate" + str(i + 1)  #i+1 just to be consistent when retrieving cached names
            cache.set(cache_name, x[i], ttl_seconds = 14400)
    return render.Root(
        delay = 30,  #speed up scroll text
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
                render.Column(
                    main_align = "space_around",
                    cross_align = "start",
                    expanded = True,
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(title[0], font = font),
                            offset_start = 5,
                            offset_end = 32,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(title[1], font = font),
                            offset_start = 5,
                            offset_end = 32,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(title[2], font = font),
                            offset_start = 5,
                            offset_end = 32,
                        ),
                    ],
                ),
            ],
        ),
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
                desc = "The headlines of the sport to be displayed.",
                icon = "newspaper",
                options = sports,
                default = "All",
            ),
        ],
    )

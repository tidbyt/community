"""
Applet: VALORANT Stats
Summary: Live VALORANT Rank Stats
Description: Pulls live VALORANT rank stats using henrikdev's Valorant API based on provided Riot ID.
Author: ohdxnte
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("schema.star", "schema")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("re.star", "re")

def main(config):
    #set vars
    rank1Name = ""
    rank1Tag = ""
    rank = ""
    rankImage = ""
    jsonImage = ""
    data = ""
    lbData = ""
    lbRankOneName = ""

    # set vars to schema input
    riotName = config.str("riot_name")
    riotTag = config.str("riot_tag")

    # define custom riot id api link to ref user's stats
    valTagAPILink = "https://api.henrikdev.xyz/valorant/v2/mmr/na/" + config.str("riot_name") + "/" + config.str("riot_tag")
    print("API link: " + valTagAPILink)

    providedValTag = riotName + "#" + riotTag
    print("Set riot id to: " + providedValTag)

    #allow for riot#id input instead of two field
    #turn riotNameTag into Name and Tag
    #riotNameTag = config.str("riotNameTag")
    #regex concat string before # and after # into Name and Tag var

    # If no riot id provided, return rank 1 stats
    if riotName == "":
        print("riot ID not set, checking lb for spot 1")
        lbData1, lbData2, lbData3 = checkRank1(lbData, valTagAPILink, providedValTag)
        providedValTag = lbData3
        print("valTagAPILink is: " + valTagAPILink)
        valTagAPILink = "https://api.henrikdev.xyz/valorant/v2/mmr/na/" + lbData1
        print("valTagAPILink is: " + valTagAPILink)
        print("checked lb, api link set as: " + valTagAPILink)

    # call get api data function (check if have cache or make fresh api call) w/ ttl of 300 to not rate limit api
    print(valTagAPILink)
    userStatData = getAPIDataCacheOrHTTP(valTagAPILink, data, ttl_seconds = 300)

    # encode json data for parsing later
    userStatData = json.encode(userStatData)

    #call user stats function passing in API JSON data and providedValTag
    if userStatData == None:
        print("yo u aint got NO data my boy das not good")
        # draft fail render screen here

    else:
        print("You have data, proceeding")

        # set data variables from cached/parsed json
        rank = json.decode(userStatData)["data"]["current_data"]["currenttierpatched"]
        jsonImage = json.decode(userStatData)["data"]["current_data"]["images"]["small"]

        # exception case if rank is set to none set text/image to unranked so it can still pass data
        if rank == None:
            rank = "Unranked"
            jsonImage = "https://trackercdn.com/cdn/tracker.gg/valorant/icons/tiersv2/0.png"

        # get base64 image from json png url
        rankImage = getImage(jsonImage)

        # render data
    print(rank + providedValTag)
    return renderStats(rank, rankImage, providedValTag)

# caching!
def getAPIDataCacheOrHTTP(valTagAPILink, data, ttl_seconds):
    userCache = cache.get(data)
    if userCache != None:
        print("Displaying cached user data")

        rep = json.decode(userCache)
        data = rep.json()
        print(data)

    else:
        print("No cached data. Hitting API")

        rep = http.get(valTagAPILink)
        if rep.status_code != 200:
            fail("VALORANT API request failed with status %d", rep.status_code)

        cache.set(valTagAPILink, json.encode(rep.json()), ttl_seconds = ttl_seconds)
        data = rep.json()
        print("hit api and cached data")
    return data

# get image from predefined json image url from stats api
def getImage(url):
    if url:
        print("Getting image from: " + url)
        response = http.get(url)

        if response.status_code == 200:
            return response.body()
        else:
            #return default image, change this to unranked OR to defaultUser aka #1 on lb
            return base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKklEQVRYCe2VUY7DIAxEQ9UD9f6n6I3SDPCQMURVpUD6gbVbw2A8g4OTsG/b8XefPaEODCZ5Tv0Qn8gBZvCLiwNHASKdJcKSi7cImCHCk4uz3AFNZCMrQdkTU/ptBLD4YnCRf5/kqR7BScxQeAlYFQhHb+60h/p0hlm+tg13JyMc4RbTXNbDLP4tLibpvIgizuYcVGEiZh0PhtcGO/ZxJm9bATbLs/EXTLHeJEZm8yWk/hZkLAX6YD8/SVhy2EFvb17vt6EU8+8TcRpwJQdjrLknZY192f9XF9j2GPExIr8tQv8R2IjB4yVgVeD2ClTvAS58fnEyvcz7NhRP8y0Q6AOvUtDLXT2CXsBV5Mqjg4nDWhEwmhxSLyLeAS2OKjvE3lOJcgcAfODo+Qful09RLycDuQAAAABJRU5ErkJggg==""")

def checkRank1(lbData, valTagAPILink, providedValTag):
    print("No provided Riot ID, pulling Leaderboard for Rank #1 data")

    lbApiLink = "https://api.henrikdev.xyz/valorant/v1/leaderboard/na"
    lbRep = http.get(lbApiLink)
    if lbRep.status_code != 200:
        fail("VALORANT API leaderboard request failed with status %d", lbRep.status_code)

    lbData = lbRep.json()
    for obj in lbData:
        if obj.get("leaderboardRank") == 1:
            lbData = json.encode(lbData)
            lbRankOneName = obj.get("gameName")
            lbRankOneTag = obj.get("tagLine")

    lbRankOneLink = re.sub(r" ", "%20", lbRankOneName)
    print("setting lbRank1 name and tag as: " + lbRankOneName + lbRankOneTag)

    providedValTag = lbRankOneName + "#" + lbRankOneTag

    lbData = lbRankOneLink + "/" + lbRankOneTag
    return lbData, valTagAPILink, providedValTag

# render stats w data from main/api/etc
def renderStats(rank, rankImage, providedValTag):
    return render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = rankImage, width = 16, height = 16),
                        render.Box(width = 1, height = 28, color = "#FFFFFF"),
                        render.Column(
                            expanded = False,
                            main_align = "space_around",
                            cross_align = "right",
                            children = [
                                render.Box(
                                    height = 16,
                                    child = render.Text(content = rank),
                                ),
                                render.Box(
                                    render.Marquee(
                                        height = 16,
                                        width = 45,
                                        child = render.Text(content = providedValTag),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

# define app schema input fields (riot name#tag)
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "riot_name",
                name = "Riot Name",
                desc = "Your name for your Riot account. This consists of your username before the # in your Riot ID.",
                icon = "user",
            ),
            schema.Text(
                id = "riot_tag",
                name = "Riot Code",
                desc = "Your tag for your Riot account. This consists of the numbers after the # in your Riot ID.",
                icon = "hashtag",
            ),
        ],
    )

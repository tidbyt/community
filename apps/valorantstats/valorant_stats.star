"""
Applet: VALORANT Stats
Summary: Live VALORANT Rank Stats
Description: Pulls live VALORANT rank stats using henrikdev's Valorant API based on provided Riot ID.
Author: ohdxnte
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# DEFAULTS
DEFAULT_RIOT_NAME = "Dante"
DEFAULT_RIOT_TAG = "aim"

def main(config):
    #set vars
    rank = ""
    rank_image = ""
    json_image = ""
    data = ""
    lb_data = ""

    # set vars to schema input
    riot_name = config.str("riot_name", DEFAULT_RIOT_NAME)
    riot_tag = config.str("riot_tag", DEFAULT_RIOT_TAG)

    # define custom riot id api link to ref user's stats
    val_tag_api_link = "https://api.henrikdev.xyz/valorant/v2/mmr/na/" + riot_name + "/" + riot_tag
    provided_val_tag_name = riot_name + "#" + riot_tag

    #future plan!
    #allow for riot#id input instead of two field
    #turn riot_nameTag into Name and Tag
    #riot_nameTag = config.str("riot_nameTag")
    #regex concat string before # and after # into Name and Tag var
    # If no riot id provided, return rank 1 stats
    if riot_name == "":
        print("riot ID not set, checking lb for spot 1")
        lb_data1, lb_data3 = checkRank1(lb_data, provided_val_tag_name)
        provided_val_tag_name = lb_data3
        print("val_tag_api_link is: " + val_tag_api_link)
        val_tag_api_link = "https://api.henrikdev.xyz/valorant/v2/mmr/na/" + lb_data1
        print("val_tag_api_link is: " + val_tag_api_link)
        print("checked lb, api link set as: " + val_tag_api_link)

    # call get api data function (check if have cache or make fresh api call) w/ ttl of 300 to not rate limit api
    user_stat_data = getAPIDataCacheOrHTTP(val_tag_api_link, data, ttl_seconds = 300)

    # encode json data for parsing later
    user_stat_data = json.encode(user_stat_data)

    #call user stats function passing in API JSON data and provided_val_tag_name
    if user_stat_data == None:
        print("yo u aint got NO data my boy das not good")
        # draft fail render screen here
        # it wont reach this point as if it has no data it will either 404/error from api HTTP req OR it will default to #1 leaderboard spot

    else:
        print("You have data, proceeding")

        # set data variables from cached/parsed json
        rank = json.decode(user_stat_data)["data"]["current_data"]["currenttierpatched"]
        json_image = json.decode(user_stat_data)["data"]["current_data"]["images"]["small"]

        # exception case if rank is set to none set text/image to unranked so it can still pass data
        if rank == None:
            rank = "Unranked"
            json_image = "https://trackercdn.com/cdn/tracker.gg/valorant/icons/tiersv2/0.png"

        # get base64 image from json png url
        rank_image = getImage(json_image)

    # render data
    print(provided_val_tag_name + ", " + rank)
    return renderStats(rank, rank_image, provided_val_tag_name)

# caching!
def getAPIDataCacheOrHTTP(val_tag_api_link, data, ttl_seconds):
    user_cache = cache.get(data)
    if user_cache != None:
        print("Displaying cached user data")
        rep = json.decode(user_cache)
        data = rep.json()
        print(data)
    else:
        print("No cached data. Hitting API")
        rep = http.get(val_tag_api_link)
        if rep.status_code != 200:
            fail("VALORANT API request failed with status %d", rep.status_code)
        cache.set(val_tag_api_link, json.encode(rep.json()), ttl_seconds = ttl_seconds)
        data = rep.json()
        print("Hit API and cached data")
    return data

# get image from predefined json image url from stats api
def getImage(url, ttl_seconds = 3600):
    if not url:
        fail("No API string provided")

    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        return base64.decode("""iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAABKklEQVRYCe2VUY7DIAxEQ9UD9f6n6I3SDPCQMURVpUD6gbVbw2A8g4OTsG/b8XefPaEODCZ5Tv0Qn8gBZvCLiwNHASKdJcKSi7cImCHCk4uz3AFNZCMrQdkTU/ptBLD4YnCRf5/kqR7BScxQeAlYFQhHb+60h/p0hlm+tg13JyMc4RbTXNbDLP4tLibpvIgizuYcVGEiZh0PhtcGO/ZxJm9bATbLs/EXTLHeJEZm8yWk/hZkLAX6YD8/SVhy2EFvb17vt6EU8+8TcRpwJQdjrLknZY192f9XF9j2GPExIr8tQv8R2IjB4yVgVeD2ClTvAS58fnEyvcz7NhRP8y0Q6AOvUtDLXT2CXsBV5Mqjg4nDWhEwmhxSLyLeAS2OKjvE3lOJcgcAfODo+Qful09RLycDuQAAAABJRU5ErkJggg==""")

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()

def checkRank1(lb_data, provided_val_tag_name):
    print("No provided Riot ID, pulling Leaderboard for Rank #1 data")
    lb_rank_one_name = ""
    lb_rank_one_tag = ""
    lb_api_link = "https://api.henrikdev.xyz/valorant/v1/leaderboard/na"
    lb_rep = http.get(lb_api_link)
    if lb_rep.status_code != 200:
        fail("VALORANT API leaderboard request failed with status %d", lb_rep.status_code)
    lb_data = lb_rep.json()
    for obj in lb_data:
        if obj.get("leaderboardRank") == 1:
            lb_data = json.encode(lb_data)
            lb_rank_one_name = obj.get("gameName")
            lb_rank_one_tag = obj.get("tagLine")
    lb_rank_one_link = re.sub(r" ", "%20", lb_rank_one_name)
    print("setting lbRank1 name and tag as: " + lb_rank_one_name + lb_rank_one_tag)
    provided_val_tag_name = lb_rank_one_name + "#" + lb_rank_one_tag
    lb_data = lb_rank_one_link + "/" + lb_rank_one_tag
    return lb_data, provided_val_tag_name

# render stats w data from main/api/etc
def renderStats(rank, rank_image, provided_val_tag_name):
    return render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = rank_image, width = 16, height = 16),
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
                                        child = render.Text(content = provided_val_tag_name),
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

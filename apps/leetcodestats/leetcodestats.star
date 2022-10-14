"""
Applet: LeetCodeStats
Summary: Gets LeetCode stats
Description: Displays your LeetCode stats in a nice way.
Author: Jake Manske
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("math.star", "math")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")

LEETCODE_BASE_URL = "https://leetcode.com/{0}"
EASY_COLOR = "#00E400"
MEDIUM_COLOR = "#FFA400"
HARD_COLOR = "#E60707"
FONT = "5x8"
TOTAL_HIST_LENGTH = 62
LEET_CODE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAJCAYAAAAPU20uAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAACKADAAQAAAABAAAACQAAAACo5FLiAAAAWklEQVQYGV1OgQ3AMAiCZVfupt7RnenEpUYlaUJBBQIwfwkzA8n8X8mcTFNeDsjES9iuKz93z7EjSnGNU17NnPv3FNZaTVJdHWnN60SUVISGDmrRuDANPkcBPgGIK90UIPuQAAAAAElFTkSuQmCC
""")
HEADER_FONT = "CG-pixel-3x5-mono"
HTTP_SUCCESS_CODE = 200

CACHE_LIFE_LENGTH_SECONDS = 300

def main(config):
    user_name = config.get("user_name") or "LeetCode"

    if user_name == None:
        return render.Root(
            child = render_Header("No user name supplied"),
        )

    # grab stats for the user
    my_stats = get_Stats(user_name)

    # return the histogram
    return render.Root(
        render.Column(
            children = [
                render_Header(my_stats.Header),
                render_Histogram("easy", my_stats),
                render_Histogram("medium", my_stats),
                render_Histogram("hard", my_stats),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_name",
                name = "User Name",
                desc = "The user name to look up on LeetCode.",
                icon = "user",
            ),
        ],
    )

def render_Histogram(type, statsObj):
    if type == "easy":
        pct = statsObj.EasyPercent
        number_solved = statsObj.EasySolved
    elif type == "medium":
        pct = statsObj.MediumPercent
        number_solved = statsObj.MediumSolved
    elif type == "hard":
        pct = statsObj.HardPercent
        number_solved = statsObj.HardSolved
    else:
        pct = 0
        number_solved = 0

    attr = get_HistogramAttributes(type, pct, statsObj.HistogramMaxLength)

    return render.Row(
        children = [
            render.Text(
                content = attr.Label,
                color = attr.HistogramColor,
                font = FONT,
            ),
            render.Padding(
                pad = (0, 2, 0, 0),
                child = render.Box(
                    width = attr.Width if attr.Width > 0 else 1,
                    height = 5,
                    color = attr.HistogramColor if attr.Width > 0 else "#000000",
                ),
            ),
            render.Box(
                width = 1,
                height = 1,
            ),
            render.Text(
                content = str(int(number_solved)),
                color = attr.HistogramColor,
                font = FONT,
            ),
        ],
    )

def get_HistogramAttributes(type, percentage, total_length):
    label = ""
    hist_color = ""
    if type == "easy":
        label = "E:"
        hist_color = EASY_COLOR
    elif type == "medium":
        label = "M:"
        hist_color = MEDIUM_COLOR
    elif type == "hard":
        label = "H:"
        hist_color = HARD_COLOR

    bar_width = math.ceil(float(percentage) * int(total_length))

    return struct(Label = label, HistogramColor = hist_color, Width = bar_width)

def get_PercentageSolved(number_solved, total_problems):
    if total_problems == 0:
        return 0
    return float(number_solved) / float(total_problems)

def render_Header(msg):
    return render.Row(
        children = [
            render.Image(
                src = LEET_CODE_LOGO,
            ),
            render.Padding(
                pad = (0, 3, 0, 0),
                child = render.Marquee(
                    width = 56,
                    child = render.Text(
                        content = " " + msg,
                        font = HEADER_FONT,
                    ),
                ),
            ),
        ],
    )

def get_Stats(user_name):
    my_stats_cached = cache.get(user_name)

    # if we didn't find stats in the cache, get them from http endpoint
    if my_stats_cached == None:
        my_stats = get_StatsHttp(user_name)

        # cache them if the response code was successful
        if my_stats.ResponseCode == HTTP_SUCCESS_CODE:
            cache_StatsObj(user_name, my_stats)
    else:
        decoded = json.decode(my_stats_cached)
        my_stats = get_statsStruct(decoded)

    return my_stats

def get_StatsHttp(user_name):
    headers = {
        "Content-Type": "application/json",
        "referer": LEETCODE_BASE_URL.format(user_name),
    }

    # get the graphql query to use
    json_body = get_query(user_name)

    # use POST to get data
    response = http.post(url = LEETCODE_BASE_URL.format("graphql"), headers = headers, json_body = json_body)

    # check status_code to see if we were successful
    code = response.status_code

    # if we fail bubble this up
    if code != HTTP_SUCCESS_CODE:
        return struct(Header = "HTTP error code: {0}".format(code), TotalSolved = 0, EasySolved = 0, MediumSolved = 0, HardSolved = 0, EasyPercent = 0, MediumPercent = 0, HardPercent = 0, HistogramMaxLength = 0, ResponseCode = code)

    resp_as_json = response.json()

    # if we were successful, we can parse the response
    # check for errors first
    # if there is an error, display it in the header (usually "user does not exist")
    errors = resp_as_json.get("errors")
    if errors != None:
        for error in errors:
            return struct(Header = error.get("message"), TotalSolved = 0, EasySolved = 0, MediumSolved = 0, HardSolved = 0, EasyPercent = 0, MediumPercent = 0, HardPercent = 0, HistogramMaxLength = 0, ResponseCode = code)

    accepted_submissions = resp_as_json["data"]["matchedUser"]["submitStats"]["acSubmissionNum"]

    # parse through the list and get the easy/medium/hard counts
    # initialize variables to please the linter
    total_solved = 1
    easy_solved = 0
    medium_solved = 0
    hard_solved = 0
    for stat in accepted_submissions:
        difficulty = stat["difficulty"]
        count = stat["count"]
        if difficulty == "All":
            total_solved = count
        if difficulty == "Easy":
            easy_solved = count
        if difficulty == "Medium":
            medium_solved = count
        if difficulty == "Hard":
            hard_solved = count

    easy_pct = get_PercentageSolved(easy_solved, total_solved)
    medium_pct = get_PercentageSolved(medium_solved, total_solved)
    hard_pct = get_PercentageSolved(hard_solved, total_solved)

    # figure out the biggest total number, scale the histogram size to it
    len_array = [len(str(int(easy_solved))), len(str(int(medium_solved))), len(str(int(hard_solved)))]
    most_digits = 0
    for size in len_array:
        if size > most_digits:
            most_digits = size

    # the histogram max length must have space for the total number solved
    # we are using a 5-point width font so we reduce the max length by 5 * that number
    hist_max_length = TOTAL_HIST_LENGTH - 5 * most_digits

    return struct(Header = user_name, TotalSolved = total_solved, EasySolved = easy_solved, MediumSolved = medium_solved, HardSolved = hard_solved, EasyPercent = easy_pct, MediumPercent = medium_pct, HardPercent = hard_pct, HistogramMaxLength = hist_max_length, ResponseCode = code)

def cache_StatsObj(user_name, statsObj):
    stats_as_json = json.encode(statsObj)
    cache.set(user_name, str(stats_as_json), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)

def get_query(user_name):
    return {
        "query": "query getUserProfile($username: String!) { allQuestionsCount { difficulty count } matchedUser(username: $username) { contributions { points } profile { reputation ranking } submissionCalendar submitStats { acSubmissionNum { difficulty count submissions } totalSubmissionNum { difficulty count submissions } } } }",
        "variables": {
            "username": user_name,
        },
    }

def get_statsStruct(stats_as_json):
    user_name = stats_as_json.get("Header")
    total_solved = stats_as_json.get("TotalSolved")
    easy_solved = stats_as_json.get("EasySolved")
    medium_solved = stats_as_json.get("MediumSolved")
    hard_solved = stats_as_json.get("HardSolved")
    easy_pct = stats_as_json.get("EasyPercent")
    medium_pct = stats_as_json.get("MediumPercent")
    hard_pct = stats_as_json.get("HardPercent")
    hist_max_length = stats_as_json.get("HistogramMaxLength")
    code = stats_as_json.get("ResponseCode")
    return struct(Header = user_name, TotalSolved = total_solved, EasySolved = easy_solved, MediumSolved = medium_solved, HardSolved = hard_solved, EasyPercent = easy_pct, MediumPercent = medium_pct, HardPercent = hard_pct, HistogramMaxLength = hist_max_length, ResponseCode = code)

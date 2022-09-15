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
load("cache.star", "cache")

LEET_CODE_STATS_URL = "https://leetcode-stats-api.herokuapp.com/{user_name}"
EASY_COLOR = "#00E400"
MEDIUM_COLOR = "#FFA400"
HARD_COLOR = "#E60707"
FONT = "5x8"
TOTAL_HIST_LENGTH = 52
LEET_CODE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAJCAYAAAAPU20uAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAACKADAAQAAAABAAAACQAAAACo5FLiAAAAWklEQVQYGV1OgQ3AMAiCZVfupt7RnenEpUYlaUJBBQIwfwkzA8n8X8mcTFNeDsjES9iuKz93z7EjSnGNU17NnPv3FNZaTVJdHWnN60SUVISGDmrRuDANPkcBPgGIK90UIPuQAAAAAElFTkSuQmCC
""")
HEADER_FONT = "CG-pixel-3x5-mono"
HTTP_SUCCESS_CODE = 200

## cache key formats
TOTAL_SOLVED_CACHE_KEY = "{0}^total_solved"
EASY_SOLVED_CACHE_KEY = "{0}^easy_solved"
MEDIUM_SOLVED_CACHE_KEY = "{0}^medium_solved"
HARD_SOLVED_CACHE_KEY = "{0}^hard_solved"
EASY_TOTAL_CACHE_KEY = "{0}^easy_total"
MEDIUM_TOTAL_CACHE_KEY = "{0}^medium_total"
HARD_TOTAL_CACHE_KEY = "{0}^hard_total"
EASY_PCT_CACHE_KEY = "{0}^easy_pct"
MEDIUM_PCT_CACHE_KEY = "{0}^medium_pct"
HARD_PCT_CACHE_KEY = "{0}^hard_pct"
HIST_MAX_LENGTH_CACHE_KEY = "{0}^hist_max_length"

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
    total_solved = cache.get(TOTAL_SOLVED_CACHE_KEY.format(user_name))
    easy_solved = cache.get(EASY_SOLVED_CACHE_KEY.format(user_name))
    medium_solved = cache.get(MEDIUM_SOLVED_CACHE_KEY.format(user_name))
    hard_solved = cache.get(HARD_SOLVED_CACHE_KEY.format(user_name))
    easy_pct = cache.get(EASY_PCT_CACHE_KEY.format(user_name))
    medium_pct = cache.get(MEDIUM_PCT_CACHE_KEY.format(user_name))
    hard_pct = cache.get(HARD_PCT_CACHE_KEY.format(user_name))
    hist_max_length = cache.get(HIST_MAX_LENGTH_CACHE_KEY.format(user_name))

    # if any of the above are not found in the cache, then use http response
    if total_solved == None or easy_solved == None or medium_solved == None or hard_solved == None or easy_pct == None or medium_pct == None or hard_pct == None:
        my_stats = get_StatsHttp(user_name)

        # cache them if the response code was successful
        if my_stats.ResponseCode == HTTP_SUCCESS_CODE:
            cache_StatsObj(user_name, my_stats)
    else:
        my_stats = struct(Header = user_name, TotalSolved = total_solved, EasySolved = easy_solved, MediumSolved = medium_solved, HardSolved = hard_solved, EasyPercent = easy_pct, MediumPercent = medium_pct, HardPercent = hard_pct, HistogramMaxLength = hist_max_length)

    return my_stats

def get_StatsHttp(user_name):
    response = http.get(LEET_CODE_STATS_URL.format(user_name = user_name))
    code = response.status_code

    # if we fail bubble this up
    if code != HTTP_SUCCESS_CODE:
        return struct(Header = "HTTP error code: {0}".format(code), TotalSolved = 0, EasySolved = 0, MediumSolved = 0, HardSolved = 0, EasyPercent = 0, MediumPercent = 0, HardPercent = 0, HistogramMaxLength = 0, ResponseCode = code)

    json_response = response.json()

    total_solved = json_response["totalSolved"]
    easy_solved = json_response["easySolved"]
    medium_solved = json_response["mediumSolved"]
    hard_solved = json_response["hardSolved"]
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
    cache.set(TOTAL_SOLVED_CACHE_KEY.format(user_name), str(int(statsObj.TotalSolved)), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(EASY_SOLVED_CACHE_KEY.format(user_name), str(int(statsObj.EasySolved)), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(MEDIUM_SOLVED_CACHE_KEY.format(user_name), str(int(statsObj.MediumSolved)), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(HARD_SOLVED_CACHE_KEY.format(user_name), str(int(statsObj.HardSolved)), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(EASY_PCT_CACHE_KEY.format(user_name), str(statsObj.EasyPercent), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(MEDIUM_PCT_CACHE_KEY.format(user_name), str(statsObj.MediumPercent), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(HARD_PCT_CACHE_KEY.format(user_name), str(statsObj.HardPercent), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)
    cache.set(HIST_MAX_LENGTH_CACHE_KEY.format(user_name), str(int(statsObj.HistogramMaxLength)), ttl_seconds = CACHE_LIFE_LENGTH_SECONDS)

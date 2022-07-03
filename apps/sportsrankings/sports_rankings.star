"""
Applet: Sports Rankings
Summary: Shows rankings for sports
Description: Shows the poll rankings for various sports.
Author: Derek Holevinsky
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("cache.star", "cache")

# URLs
BASE_URL = "https://site.api.espn.com/apis/site/v2/sports/"
FOOTBALL_RANKINGS_URL = "football/college-football/rankings"
MENS_BASKETBALL_RANKINGS_URL = "basketball/mens-college-basketball/rankings"
WOMENS_BASKETBALL_RANKINGS_URL = "basketball/womens-college-basketball/rankings"

# Cache keys
MENS_COLLEGE_BASKETBALL_KEY = "mensCollegeBasketball"
WOMENS_COLLEGE_BASKETBALL_KEY = "womensCollegeBasketball"
RANKINGS_SPORT_ID = "rankingsSport"

# schema keys
FOOTBAL_KEY = "collegeFootball"

# Parsing property keys
TEAM_PROP_KEY = "team"
RANKINGS_PROP_KEY = "rankings"
RANKS_PROP_KEY = "ranks"
RECORD_SUMMARY_PROP_KEY = "recordSummary"
ABBREVIATION_PROP_KEY = "abbreviation"
COLOR_PROP_KEY = "color"

# Constants
TEXT_FONT = "tom-thumb"
COLOR_BLACK = "000000"
COLOR_READABLE_WHITE = "ebebeb"
TEAMS_PER_PAGE = 5

def main(config):
    sport = config.get(RANKINGS_SPORT_ID, FOOTBAL_KEY)

    if sport == WOMENS_COLLEGE_BASKETBALL_KEY:
        teams = json.decode(get_cachable_data(BASE_URL + WOMENS_BASKETBALL_RANKINGS_URL))
    elif sport == MENS_COLLEGE_BASKETBALL_KEY:
        teams = json.decode(get_cachable_data(BASE_URL + MENS_BASKETBALL_RANKINGS_URL))
    else:
        teams = json.decode(get_cachable_data(BASE_URL + FOOTBALL_RANKINGS_URL))

    rankings = teams[RANKINGS_PROP_KEY][0][RANKS_PROP_KEY]

    def get_name(index):
        name = rankings[index][TEAM_PROP_KEY][ABBREVIATION_PROP_KEY]

        # 4 characters is the max number of a team's abbreviation
        if len(name) == 2:
            return "%s  " % name
        elif len(name) == 3:
            return "%s " % name
        return name

    def get_record(index):
        return rankings[index][RECORD_SUMMARY_PROP_KEY]

    def get_color(index):
        color = rankings[index][TEAM_PROP_KEY][COLOR_PROP_KEY]

        if color == COLOR_BLACK:
            return COLOR_READABLE_WHITE
        return get_lighter_color(color)

    def get_rank(index):
        rank = index

        # adjust spacing to keep everthing lined up for uneven character counts
        if index < 10:
            return "%s " % rank
        return rank

    def get_row(currentPage, index):
        return "%s %s %s" % (
            get_rank(currentPage * TEAMS_PER_PAGE + index + 1),
            get_name(currentPage * TEAMS_PER_PAGE + index),
            get_record(currentPage * TEAMS_PER_PAGE + index),
        )

    def get_page(currentPage):
        return render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "left",
            children = [
                render.Text(get_row(currentPage, 0), color = "#%s" % get_color(currentPage * TEAMS_PER_PAGE), font = TEXT_FONT),
                render.Text(get_row(currentPage, 1), color = "#%s" % get_color(currentPage * TEAMS_PER_PAGE + 1), font = TEXT_FONT),
                render.Text(get_row(currentPage, 2), color = "#%s" % get_color(currentPage * TEAMS_PER_PAGE + 2), font = TEXT_FONT),
                render.Text(get_row(currentPage, 3), color = "#%s" % get_color(currentPage * TEAMS_PER_PAGE + 3), font = TEXT_FONT),
                render.Text(get_row(currentPage, 4), color = "#%s" % get_color(currentPage * TEAMS_PER_PAGE + 4), font = TEXT_FONT),
            ],
        )

    def get_all_pages(currentPage):
        return [
            get_page(0),
            get_page(1),
            get_page(2),
            get_page(3),
            get_page(4),
        ]

    return render.Root(
        delay = int(3 * 1000),
        child = render.Box(
            render.Column(
                expanded = True,
                cross_align = "left",
                children = [
                    render.Animation(
                        children = get_all_pages(0),
                    ),
                ],
            ),
        ),
    )

rankingsSport = [
    schema.Option(
        display = "College Football",
        value = FOOTBAL_KEY,
    ),
    schema.Option(
        display = "Men's College Basketball",
        value = MENS_COLLEGE_BASKETBALL_KEY,
    ),
    schema.Option(
        display = "Women's College Basketball",
        value = WOMENS_COLLEGE_BASKETBALL_KEY,
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = RANKINGS_SPORT_ID,
                name = "Sport",
                desc = "Sport rankings to display",
                icon = "football",
                default = rankingsSport[0].value,
                options = rankingsSport,
            ),
        ],
    )

def get_cachable_data(url, ttl_seconds = 240):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = 240)

    return res.body()

def hex_to_rgb(color):
    rgb = []
    for i in (0, 2, 4):
        decimal = int(color[i:i + 2], 16)
        rgb.append(decimal)

    return tuple(rgb)

def rgb_to_hex(r, g, b):
    ret = ""

    for i in (r, g, b):
        this = "%X" % i
        if len(this) == 1:
            this = "0" + this
        ret = ret + this

    if len(ret) > 6:
        return ret[:-1]
    return ret

def get_lighter_color(color):
    rgb = hex_to_rgb(color)

    # colors below this value are hard to read on the device
    colorLimit = 125

    redValue = rgb[0]
    greenValue = rgb[1]
    blueValue = rgb[2]

    if redValue < colorLimit and greenValue < colorLimit and blueValue < colorLimit:
        maxValue = max(rgb)

        # increase primary color to increase readibility
        increase = 125

        if maxValue == redValue:
            redValue += increase

        if maxValue == greenValue:
            greenValue += increase

        if maxValue == blueValue:
            blueValue += increase

        return rgb_to_hex(redValue, greenValue, blueValue)
    return color

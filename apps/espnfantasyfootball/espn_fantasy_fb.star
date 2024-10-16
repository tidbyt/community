"""
Applet: ESPN Fantasy FB
Summary: Fantasy FB matchup scores
Description: Connects to your ESPN fantasy football league and randomly displays the scoreboard for a given matchup.
Author: jack_markle
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FANTASY_BASE_ENDPOINT = "https://lm-api-reads.fantasy.espn.com/apis/v3/games/"
FANTASY_SPORTS = {
    "nfl": "ffl",
}

# Defaults for schema
DEFAULT_LEAGUE_ID = "59435668"
DEFAULT_YEAR = "2024"
DEFAULT_ESPN_S2 = "AEBNW6lF76hmygYwDoVCeLE0eiLYeQk0CkodwxI4bkai3oUFqXytKGYSz6tK24XYAl0pzWWA81wta%2B6qSzSsrHah1%2Fw7Z4No1Ab6xNIrtJAn58VuzDXgpfD7kYFHTFvURXcZ6%2BYqaWkfnRWK9Resmsi%2FpKrNEO7mAh3s%2BvssEoBp4ZISJhzugizeeKFhm4QfPtopPYgp%2BTrMJBbNra6SVOjPrHOAvQTc4JCxL8oyUfMINUS2EHCykNO8CayEaSHVMzkt6M3w%2B%2BDd8NxvuDqRsmYh%2F%2F%2FmpQgx1429twDdK1cvrg%3D%3D"
DEFAULT_SWID = "{ED2E7200-9E5C-43DE-AE72-009E5C23DE71}"

# There is no team ID 0, so use 0 as random. However
# ESPN makes this a float for some odd reason. User
# will enter an integer so we cast it later.
#DEFAULT_TEAM_ID = "0.0"
DEFAULT_TEAM_ID = "5"

def main(config):
    # Get user config values
    league_id = config.str("fantasy_league_id", DEFAULT_LEAGUE_ID)
    year = config.get("year", DEFAULT_YEAR)
    espn_s2 = config.str("schema_espn_s2", DEFAULT_ESPN_S2)
    swid = config.get("schema_swid", DEFAULT_SWID)

    # team_id needs to be a float for some odd reason
    team_id = float(config.get("schema_team", DEFAULT_TEAM_ID))

    # Initialize base league data with values from user
    LEAGUE_DATA = init_base_league(league_id, int(year), "nfl", espn_s2, swid)  #add args)

    # Initialize requests data
    LEAGUE_DATA = init_requests_data(LEAGUE_DATA)

    # Initialize specific league data
    LEAGUE_DATA = league_get_request(LEAGUE_DATA, "")

    # Get more data specific to retrieving box scores
    LEAGUE_DATA = json_to_league_data(LEAGUE_DATA, LEAGUE_DATA["league_request_data"])

    # Get actual box score data to use in render
    BOX_SCORE_DATA = box_scores(LEAGUE_DATA, LEAGUE_DATA["current_week"])

    if team_id == 0.0:
        # Choose a random matchup
        matchup_string = "matchup_" + random_matchup(BOX_SCORE_DATA)
    else: 
        matchup_string = "matchup_" + find_matchup(BOX_SCORE_DATA, team_id)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "end",
            children = [
                # Left side - Home team
                render.Box(
                    width = 30,
                    height = 32,
                    child = render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            # Team Name box
                            render.Box(
                                width = 30,
                                height = 8,
                                child = render.Marquee(
                                    width = 30,
                                    height = 8,
                                    child = render.Text(BOX_SCORE_DATA[matchup_string]["home_team"]["team_name"]),
                                    # offset_start = 5,
                                    # offset_end = 32,
                                ),
                            ),
                            # Logo Box
                            render.Box(
                                width = 30,
                                height = 16,
                                child = render.Image(
                                    src = BOX_SCORE_DATA[matchup_string]["home_team"]["decoded_logo"],
                                    width = 21,
                                    height = 16,
                                ),
                            ),
                            # Score box
                            render.Box(
                                width = 30,
                                height = 8,
                                child = render.Text(
                                    content = str(BOX_SCORE_DATA[matchup_string]["home_team"]["team_score"]),  # Text label to display
                                    font = "tb-8",  # Font style
                                    height = 8,
                                    offset = 0,
                                ),
                            ),
                        ],
                    ),
                ),
                # Middle Divider
                render.Box(
                    width = 2,
                    height = 32,
                    color = "#fff",
                ),
                # Right side - Away team
                render.Box(
                    width = 30,
                    height = 32,
                    child = render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            # Team Name box
                            render.Box(
                                width = 30,
                                height = 8,
                                child = render.Marquee(
                                    width = 30,
                                    height = 8,
                                    child = render.Text(BOX_SCORE_DATA[matchup_string]["away_team"]["team_name"]),
                                    # offset_start = 5,
                                    # offset_end = 32,
                                ),
                            ),
                            # Logo Box
                            render.Box(
                                width = 30,
                                height = 16,
                                child = render.Image(
                                    src = BOX_SCORE_DATA[matchup_string]["away_team"]["decoded_logo"],  # Replace with the URL of the image you want to display
                                    width = 21,
                                    height = 16,
                                ),
                            ),
                            # Score box
                            render.Box(
                                width = 30,
                                height = 8,
                                child = render.Text(
                                    content = str(BOX_SCORE_DATA[matchup_string]["away_team"]["team_score"]),  # Text label to display
                                    font = "tb-8",  # Font style
                                    height = 8,
                                    offset = 0,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fantasy_league_id",
                name = "ESPN Fantasy league ID",
                desc = "To find your league ID, open the ESPN Fantasy App, navigate to your league, tap on the 'LEAGUE' tab, then tap 'League Info'. You should then see your League ID listed under basic settings.",
                icon = "user",
            ),
            schema.Text(
                id = "year",
                name = "Year of League",
                desc = "The year you want display, usually the current year.",
                icon = "user",
            ),
            schema.Text(
                id = "team_id",
                name = "Team Id to show scores for, leave blank for Random matchup.",
                desc = "To find your team Id, click on 'My Team' in a browser and look at the URL. The teamId should be at the end of the URL in the format &teamId=N. Take the value N and put it here. It should be a number between 1 and the number of teams in your league (for example 3 or 8).",
                icon = "user",
            ),
            schema.Text(
                id = "schema_espn_s2",
                name = "Cookie: espn_s2",
                desc = "[NOT NEEDED FOR PUBLIC LEAGUES; MUST BE FOUND FROM COMPUTER BROWSER] To find your espn_s2 cookie value, log in to https://fantasy.espn.com/football. Once you're at your team's home page, right click anywhere on the page and click 'Inspect'. Once the inspector menu appears, in the top bar of the menu, select 'Application'. In the 'Application' page, on the right bar under 'Cookies', click https://fantasy.espn.com. The espn_s2 value should then displayed in the cookie list. Email your espn_s2 to yourself so you are able to copy it from your mobile device.",
                icon = "user",
            ),
            schema.Text(
                id = "schema_swid",
                name = "Cookie: swid",
                desc = "[NOT NEEDED FOR PUBLIC LEAGUES; MUST BE FOUND FROM COMPUTER BROWSER] To find your swid cookie value, log in to https://fantasy.espn.com/football. Once you're at your team's home page, right click anywhere on the page and click 'Inspect'. Once the inspector menu appears, in the top bar of the menu, select 'Application'. In the 'Application' page, on the right bar under 'Cookies', click https://fantasy.espn.com. The swid value should then displayed in the cookie list under the 'espnAuth' value. It should be a string of alphanumerics similar to: '{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}'. Email your swid to yourself so you are able to copy it from your mobile device.",
                icon = "user",
            ),
        ],
    )

# Gets a random matchup to display
def random_matchup(box_data):
    i = len(box_data)
    num = random.number(1, i)
    return str(num)

# Find a matchup for a specific team_id
def find_matchup(box_data, team_id):
    if team_id < 1 or team_id > len(box_data):
        print("Team ID is out of range, this isn't going to work. Picking a random matchup.")
        return random_matchup(box_data)

    for i in range(1,len(box_data)+1):
        matchup = box_data["matchup_"+str(i)]
#        print("%d: HT: %d" % (i, matchup["home_team"]["team_id"]))
#        print("%d: AT: %d" % (i, matchup["away_team"]["team_id"]))
       
        if matchup["home_team"]["team_id"] == team_id or \
           matchup["away_team"]["team_id"] == team_id:
            return str(i)

    print("Team ID %d not found. Picking a random matchup." % int(team_id))
    return random_matchup(box_data)

# Initialize a dict for holding all league data
def init_base_league(league_id, year, sport, espn_s2, swid):
    LEAGUE_DATA = {
        "league_id": None,
        "year": None,
        "sport": None,
        "espn_s2": None,
        "swid": None,
        "cookies": None,
    }
    LEAGUE_DATA["league_id"] = league_id
    LEAGUE_DATA["year"] = year
    LEAGUE_DATA["sport"] = sport
    if espn_s2 and swid:
        s2_cookie = "espn_s2=" + espn_s2 + ";"
        swid_cookie = " SWID=" + swid
        cookie_combined = s2_cookie + swid_cookie
        LEAGUE_DATA["espn_s2"] = espn_s2
        LEAGUE_DATA["swid"] = swid
        LEAGUE_DATA["cookies"] = cookie_combined

    return LEAGUE_DATA

# Make the HTTP request to get more specific league information
def league_get_request(league_data, extend):
    # Set HTTP query values
    headers = {}
    cookies = league_data["cookies"]
    endpoint = league_data["LEAGUE_ENDPOINT"] + extend
    url = endpoint + "?view=mTeam&view=mRoster&view=mMatchup&view=mSettings&view=mStandings"
    headers["Cookie"] = str(cookies)

    # Make the http request
    response = http.get(url = url, headers = headers, ttl_seconds = 3600)  # cache for 1 hour

    if response.status_code != 200:
        fail("GET %s failed with status %d: %s", endpoint, response.status_code, response.body())

    league_data["league_request_data"] = response.json()
    return league_data

# Grab important info from the request data
def json_to_league_data(league_data, json):
    league_data["currentMatchupPeriod"] = json["status"]["currentMatchupPeriod"]
    league_data["scoringPeriodId"] = json["scoringPeriodId"]
    league_data["firstScoringPeriod"] = json["status"]["firstScoringPeriod"]
    league_data["finalScoringPeriod"] = json["status"]["finalScoringPeriod"]
    league_data["previousSeasons"] = [
        year
        for year in json["status"]["previousSeasons"]
        if year < league_data["year"]
    ]
    league_data["current_week"] = league_data["scoringPeriodId"] if league_data["scoringPeriodId"] <= json["status"]["finalScoringPeriod"] else json["status"]["finalScoringPeriod"]
    league_data["settings"] = {}
    league_data = init_settings(league_data, json["settings"])
    league_data["members"] = json["members"]
    return league_data

# Set basic endpoint data
def init_requests_data(league_data):
    ## Init data
    league_data["ENDPOINT"] = FANTASY_BASE_ENDPOINT + FANTASY_SPORTS["nfl"] + "/seasons/" + str(league_data["year"])
    league_data["LEAGUE_ENDPOINT"] = FANTASY_BASE_ENDPOINT + FANTASY_SPORTS["nfl"] + "/seasons/" + str(league_data["year"]) + "/segments/0/leagues/" + str(league_data["league_id"])
    return league_data

# Initialize basic league settings
def init_settings(league_data, data):
    league_data["settings"]["reg_season_count"] = data["scheduleSettings"]["matchupPeriodCount"]
    league_data["settings"]["matchup_periods"] = data["scheduleSettings"]["matchupPeriods"]
    league_data["settings"]["name"] = data["name"]

    # There's a lot more info that could go here, limiting it for use case.
    return league_data

# Grabs the box scores of the current fantasy week.
def box_scores(league_data, week):
    # Get matchup information
    matchup_period = league_data["currentMatchupPeriod"]
    scoring_period = league_data["current_week"]
    if week and week <= league_data["current_week"]:
        scoring_period = week
        for matchup_id in league_data["settings"]["matchup_periods"]:
            if week in league_data["settings"]["matchup_periods"][matchup_id]:
                matchup_period = matchup_id
            break

    # Set HTTP request values
    filters = '{"schedule":{"filterMatchupPeriodIds":{"value":[' + str(matchup_period) + "]}}}"
    headers = {"x-fantasy-filter": filters}
    headers["Cookie"] = str(league_data["cookies"])
    extend = ""
    endpoint = league_data["LEAGUE_ENDPOINT"] + extend
    url = endpoint + "?view=mMatchupScore&view=mScoreboard&scoringPeriodId=" + str(int(scoring_period)) + ""

    # Make request
    data = http.get(url = url, headers = headers, ttl_seconds = 3600)  # cache for 1 hour
    if data.status_code != 200:
        fail("GET %s failed with status %d: %s", endpoint, data.status_code, data.body())

    # Grab the info
    json_data = data.json()
    league_data["schedule"] = json_data["schedule"]
    box_score_data = {}
    i = 0
    for matchup in league_data["schedule"]:
        i = i + 1
        home_team = get_team_data(matchup, "home", json_data)
        away_team = get_team_data(matchup, "away", json_data)
        box_score_data["matchup_" + str(i)] = {
            "home_team": home_team,
            "away_team": away_team,
        }

    return box_score_data

# Gets team data like name, points, id.
def get_team_data(matchup, team, json_data):
    if team not in matchup:
        return (0, 0, -1, [])

    team_id = matchup[team]["teamId"]
    team_projected = -1
    if "totalPointsLive" in matchup[team]:
        team_score = matchup[team]["totalPointsLive"]
        team_projected = matchup[team]["totalProjectedPointsLive"]
    else:
        team_score = matchup[team]["totalPoints"]

    # Get team name from team id
    team_name = ""
    team_logo = ""
    for team in json_data["teams"]:
        if team_id == team["id"]:
            team_name = team["name"]
            team_logo = team["logo"]
        else:
            continue

    # Convert logo from url
    decoded_logo = convert_logo(team_logo)

    team_values = {
        "team_id": team_id,
        "team_name": team_name,
        "team_score": team_score,
        "team_proj_score": team_projected,
        "decoded_logo": decoded_logo,
    }
    return team_values

def convert_logo(logo_url):
    response = http.get(url = logo_url)

    if response.status_code != 200:
        fail("Failed to load image")

    image_data = response.body()

    base64_image = base64.encode(image_data)

    decoded_image = base64.decode(base64_image)

    return decoded_image

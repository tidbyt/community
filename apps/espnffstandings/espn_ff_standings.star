"""
Applet: ESPN FF Standings
Summary: Fantasy Football Standings
Description: Displays the ordered standings with team name and team record.
Author: George Matthews
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("http.star", "http")
load("render.star", "render")

FANTASY_BASE_ENDPOINT = "https://lm-api-reads.fantasy.espn.com/apis/v3/games/"
FANTASY_SPORTS = {
    "nfl": "ffl",
}

DEFAULT_LEAGUE_ID = "1524051886"
DEFAULT_YEAR = "2024"
DEFAULT_SWID_COOKIE = "AE876AEC-73E2-4871-826D-C37E201A80E8"
DEFAULT_ESPN_S2_COOKIE = "AEAr0sZC9CqbI1vcUezBy4ni61%2B1Y3kmRD72n%2BHCBTIkgm5ckYEe7sMw8d%2FDp1o9nSswId5J9uFgzlO6YQVeapm%2Fd3%2BAtXbuPgjbbFJNBDZZ9P9Bi3N0APLVaoUn1N1Tda5eqsWFU2jvtKl0ooGTRdOVPUNyrkUUj7x4fzXb1qFbnDuMhKf0r3slw7i8WAvruh26MhOo7BDlYNsqnWfOMjOF7wAu24CJe%2BDU4luJ632%2BRyFpPCKiZVODSgZirBMvauCodUYEmY5PeZCWJ3Cv8q0g4pKUgCLSswW249idO%2BxE0e0RoU17uY7LT5MOIN1%2Fqfs%3D"
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

def main(config):
    # Get user config values
    league_id = config.str("fantasy_league_id", DEFAULT_LEAGUE_ID)
    year = config.get("year", DEFAULT_YEAR)
    espn_s2 = config.str("schema_espn_s2", DEFAULT_ESPN_S2_COOKIE)
    swid = config.get("schema_swid", DEFAULT_SWID_COOKIE)

    # Initialize base league data with values from user
    LEAGUE_DATA = init_base_league(league_id, int(year), "nfl", espn_s2, swid)  #add args)

    # Initialize requests data
    LEAGUE_DATA = init_requests_data(LEAGUE_DATA)

    # Initialize specific league data
    LEAGUE_DATA = league_get_request(LEAGUE_DATA, "")
    list_of_teams = get_team_data(LEAGUE_DATA)
    print(list_of_teams)        
    render_category = []
    teams_per_view = 3  # Number of teams to display at once

    # Create a fixed title with a softer color scheme
    title = render.Box(
        width=64,
        height=7,
        color="#2E3B4E",  # Darker blue-gray for background
        child=render.Box(
            width=64,
            height=7,
            color="#4B6F93",  # Lighter blue-gray for inner box
            child=render.Padding(
                pad=2,  # Padding to create space for the inner box
                child=render.Box(
                    width=60,
                    height=7,
                    color="#2E3B4E",  # Matching background color for consistency
                    child=render.Text(content="ESPN Fantasy", color="#F0E68C")  # Softer yellow for title text
                )
            )
        )
    )

    # Group teams into sets of three
    for i in range(0, len(list_of_teams), teams_per_view):
        team_group = list_of_teams[i:i + teams_per_view]
        team_rows = []

        for team in team_group:
            team_rows.append(
                render.Box(
                    width=64,
                    height=8,
                    color="#000000",  # Black background for team boxes
                    child=render.Row(
                        main_align="start",
                        cross_align="center",
                        children=[
                            render.Marquee(
                                width=45,
                                height=7,
                                child=render.Text(content=team["team_name"], color="#F0E68C"),  # Softer yellow for team name
                                align="start",
                                delay=6000
                            ),
                            render.Box(
                                width=16,
                                height=6,
                                child=render.Text(content=team["team_record"], color="#FFFFFF")  # White text for team record
                            ),
                        ]
                    )
                )
            )

        # Create a column for the group of teams
        render_category.append(
            render.Column(
                children=team_rows,
                expanded=True,
                main_align="start",
                cross_align="start",
            )
        )

    # Return the rendered animation with the title at the top
    return render.Root(
        delay=int('4') * 1000,
        show_full_animation=True,
        child=render.Column(
            children=[
                title, 
                render.Animation(children=render_category)  # Animated team display below
            ]
        )
    )
    

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

def league_get_request(league_data, extend):
    # Set HTTP query values
    headers = {}
    cookies = league_data["cookies"]
    endpoint = league_data["LEAGUE_ENDPOINT"] + extend
    url = endpoint + "?view=mTeam&view=mStandings"
    headers["Cookie"] = str(cookies)

    # Make the http request
    response = http.get(url = url, headers = headers, ttl_seconds = 3600)  # cache for 1 hour

    if response.status_code != 200:
        fail("GET %s failed with status %d: %s", endpoint, response.status_code, response.body())

    league_data["league_request_data"] = response.json()
    return league_data

def init_requests_data(league_data):
    ## Init data
    league_data["ENDPOINT"] = FANTASY_BASE_ENDPOINT + FANTASY_SPORTS["nfl"] + "/seasons/" + str(league_data["year"])
    league_data["LEAGUE_ENDPOINT"] = FANTASY_BASE_ENDPOINT + FANTASY_SPORTS["nfl"] + "/seasons/" + str(league_data["year"]) + "/segments/0/leagues/" + str(league_data["league_id"])
    return league_data

# Gets team data like name, rank, record.
def get_team_data(league_data):

    headers = {}
    headers["Cookie"] = str(league_data["cookies"])
    url = league_data["LEAGUE_ENDPOINT"] + "?view=mTeam&view=mStandings"
    

    # Make request
    data = http.get(url = url, headers = headers, ttl_seconds = 3600)  # cache for 1 hour
    if data.status_code != 200:
        fail("GET %s failed with status %d: %s", url, data.status_code, data.body())

    # Grab the info
    json_data = data.json()
    # Get team name from team id
    team_values = []
    for team in json_data["teams"]:
        team_name = team["name"]
        team_rank = team["playoffSeed"]
        team_win = team["record"]["overall"]["wins"]
        team_loss = team["record"]["overall"]["losses"]
        team_record = str(int(team_win)) + "-" + str(int(team_loss))
        team_info = {
            "team_name": team_name,
            "team_rank": team_rank,
            "team_record": team_record,
        }
        team_values.append(team_info)
    return sorted(team_values, key=lambda team: (team["team_rank"]))

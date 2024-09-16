"""
Applet: YahooFantasyMLB
Summary: Fantasy Standings & Scores
Description: Display standings or scores for a Yahoo Fantasy Baseball league (MLB).
Author: jweier extended from LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("xpath.star", "xpath")

# Constants for production repo
TIDBYT_OAUTH_CALLBACK_URL = "https%3A%2F%2Fappauth.tidbyt.com%2Fyahoofantasymlb"  # registered https://appauth.tidbyt.com/yahoofantasymlb as redirect_uri at Yahoo
YAHOO_CLIENT_ID = secret.decrypt("AV6+xWcEWMDT2jcxrD35wOfTQxWvAHKAxFxzai1GSmDkB/h8jchP1n+cCcESoBAHJUl1JBye3kuoEn6UwKzBFMBOohXSO8NvwASENm03L0Kj+wY88Nj4a4WEU+2qEIbMgw89CAGElNxcKNS4n4uKs3nYtqSnQj7X0NdtLYmX21ICNuaPpAzbO53vpnYFM3YypK0ZkEa2QN5jButjapgz3znET09eUF0/F+XhtbXDFCCmTtSlpojga86zPut3dwj1mzEdRycg") or ""
YAHOO_CLIENT_SECRET = secret.decrypt("AV6+xWcEJ6YJpwBZ4iTBKHweMQHJENU/9ZnBsKHYMeCFoo3vjq0NwB0nOnFqFSSZNKJfxo+KUIPxIcqO23MpxhIcp5Zb/XYHqz1YCa/a1Q9uke9iZgm7IT/R1RBSo0LZdJDQZtC+5WCklkCMNFMTAnk9frRstdIzCA13+CF+n89sPOYMwGFEJJW1qMqbOg==") or ""

# Common Constants
YAHOO_CLIENT_ID_AND_SECRET_BASE_64 = base64.encode(YAHOO_CLIENT_ID + ":" + YAHOO_CLIENT_SECRET)
YAHOO_OAUTH_AUTHORIZATION_URL = "https://api.login.yahoo.com/oauth2/request_auth"
YAHOO_OAUTH_TOKEN_URL = "https://api.login.yahoo.com/oauth2/get_token"
ACCESS_TOKEN_CACHE_TTL = 3000  # 50 minutes as Yahoo access tokens only last 60 minutes
STANDINGS_CACHE_TTL = 14400  # 4 days
LEAGUE_NAME_CACHE_TTL = 28800  # 8 days
GAME_KEY = "422"

def main(config):
    render_category = []
    league_name = ""
    refresh_token = config.get("auth")
    league_number = config.get("league_number", "")
    rotation_speed = config.get("rotation_speed", "5")
    teams_per_view = int(config.get("teams_per_view", "3"))
    heading_font_color = config.get("heading_font_color", "#FFA500")
    color_scheme = config.get("color_scheme", '["BD3039", "0C2340", "BD3039", "0C2340", "FFFFFF"]')
    color_scheme = json.decode(color_scheme)
    show_scores = config.bool("show_scores", False)

    if refresh_token:
        print("Calling Get Access Token")
        access_token = get_access_token(refresh_token)

        if (access_token):
            print("League Name: " + league_name)
            league_name = get_league_name(access_token, GAME_KEY, league_number)

            if (league_name):
                if show_scores:
                    entries_to_display = 2
                    current_matchup = get_current_matchup(access_token, GAME_KEY, league_number)

                    render_category.extend(
                        [
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = render_current_matchup(current_matchup, entries_to_display, heading_font_color, color_scheme, league_name),
                                    ),
                                ],
                            ),
                        ],
                    )
                else:
                    entries_to_display = teams_per_view
                    standings = get_standings_and_records(access_token, GAME_KEY, league_number)

                    for x in range(0, len(standings), entries_to_display):
                        render_category.extend(
                            [
                                render.Column(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name),
                                        ),
                                    ],
                                ),
                            ],
                        )

                return render.Root(
                    delay = int(rotation_speed) * 1000,
                    show_full_animation = True,
                    child = render.Animation(children = render_category),
                )
            else:
                error_message = "Please check your league number."
                return render.Root(
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(error_message),
                    ),
                )
        else:
            error_message = "Unable to acquire an access token from the refresh token."
            return render.Root(
                child = render.Marquee(
                    width = 64,
                    child = render.Text(error_message),
                ),
            )
    else:
        entries_to_display = teams_per_view
        league_name = "Yahoo Fantasy"

        standings = [{"Name": "Stealing Signals", "Standings": "1", "Wins": "11", "Losses": "0", "Ties": "0"}, {"Name": "Me Casas Su Casas", "Standings": "2", "Wins": "8", "Losses": "2", "Ties": "1"}, {"Name": "Judge Dread", "Standings": "3", "Wins": "8", "Losses": "3", "Ties": "0"}, {"Name": "A Christmas Carroll", "Standings": "4", "Wins": "8", "Losses": "5", "Ties": "1"}, {"Name": "Judge and Eury Perez", "Standings": "5", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "You're Making Me Mervis", "Standings": "6", "Wins": "8", "Losses": "6", "Ties": "0"}, {"Name": "Honey Nut Chourio", "Standings": "7", "Wins": "5", "Losses": "9", "Ties": "0"}, {"Name": "Jordan Lawler n Orderler", "Standings": "8", "Wins": "3", "Losses": "11", "Ties": "0"}, {"Name": "Jack Cigarette Leiter", "Standings": "9", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "Jake Burger in Paradise", "Standings": "10", "Wins": "6", "Losses": "8", "Ties": "0"}, {"Name": "Triston the Night Away", "Standings": "11", "Wins": "4", "Losses": "10", "Ties": "0"}, {"Name": "Men Behaving Adley", "Standings": "12", "Wins": "6", "Losses": "8", "Ties": "0"}]
        for x in range(0, len(standings), entries_to_display):
            render_category.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name),
                            ),
                        ],
                    ),
                ],
            )

        return render.Root(
            delay = int(rotation_speed) * 1000,
            show_full_animation = True,
            child = render.Animation(children = render_category),
        )

rotation_options = [
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

teams_per_view_options = [
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
]

color_scheme_options = [
    schema.Option(
        display = "Blue",
        value = json.encode(["0A2647", "144272", "205295", "2C74B3", "FFFFFF"]),
    ),
    schema.Option(
        display = "Arizona Diamondbacks",
        value = json.encode(["A71930", "000000", "A71930", "000000", "E3D4AD"]),
    ),
    schema.Option(
        display = "Atlanta Braves",
        value = json.encode(["CE1141", "13274F", "CE1141", "13274F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Baltimore Orioles",
        value = json.encode(["DF4601", "000000", "DF4601", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Boston Red Sox",
        value = json.encode(["BD3039", "0C2340", "BD3039", "0C2340", "FFFFFF"]),
    ),
    schema.Option(
        display = "Chicago Cubs",
        value = json.encode(["0E3386", "CC3433", "0E3386", "CC3433", "FFFFFF"]),
    ),
    schema.Option(
        display = "Chicago White Sox",
        value = json.encode(["27251F", "27251F", "27251F", "27251F", "C4CED4"]),
    ),
    schema.Option(
        display = "Cincinnati Reds",
        value = json.encode(["C6011F", "000000", "C6011F", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Cleveland Indians",
        value = json.encode(["00385D", "E50022", "00385D", "E50022", "FFFFFF"]),
    ),
    schema.Option(
        display = "Colorado Rockies",
        value = json.encode(["333366", "131413", "333366", "131413", "FFFFFF"]),
    ),
    schema.Option(
        display = "Detroit Tigers",
        value = json.encode(["0C2340", "FA4616", "0C2340", "FA4616", "FFFFFF"]),
    ),
    schema.Option(
        display = "Houston Astros",
        value = json.encode(["002D62", "EB6E1F", "002D62", "EB6E1F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Kansas City Royals",
        value = json.encode(["004687", "BD9B60", "004687", "BD9B60", "FFFFFF"]),
    ),
    schema.Option(
        display = "Los Angeles Angels",
        value = json.encode(["003263", "BA0021", "003263", "BA0021", "FFFFFF"]),
    ),
    schema.Option(
        display = "Los Angeles Dodgers",
        value = json.encode(["005A9C", "EF3E42", "005A9C", "EF3E42", "FFFFFF"]),
    ),
    schema.Option(
        display = "Miami Marlins",
        value = json.encode(["00A3E0", "000000", "00A3E0", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Milwaukee Brewers",
        value = json.encode(["12284B", "FFC52F", "12284B", "FFC52F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Minnesota Twins",
        value = json.encode(["002B5C", "D31145", "002B5C", "D31145", "FFFFFF"]),
    ),
    schema.Option(
        display = "Montreal Expos",
        value = json.encode(["003087", "E4002B", "003087", "E4002B", "FFFFFF"]),
    ),
    schema.Option(
        display = "New York Mets",
        value = json.encode(["002D72", "FF5910", "002D72", "FF5910", "FFFFFF"]),
    ),
    schema.Option(
        display = "New York Yankees",
        value = json.encode(["0C2340", "0C2340", "0C2340", "0C2340", "C4CED3"]),
    ),
    schema.Option(
        display = "Okaland Athletics",
        value = json.encode(["003831", "EFB21E", "003831", "EFB21E", "FFFFFF"]),
    ),
    schema.Option(
        display = "Philadelphia Phillies",
        value = json.encode(["E81828", "002D72", "E81828", "002D72", "FFFFFF"]),
    ),
    schema.Option(
        display = "Pittsburgh Pirates",
        value = json.encode(["27251F", "27251F", "27251F", "27251F", "FDB827"]),
    ),
    schema.Option(
        display = "St. Louis Cardinals",
        value = json.encode(["C41E3A", "0C2340", "C41E3A", "0C2340", "FFFFFF"]),
    ),
    schema.Option(
        display = "San Deigo Padres",
        value = json.encode(["2F241D", "FFC425", "2F241D", "FFC425", "FFFFFF"]),
    ),
    schema.Option(
        display = "San Francisco Giants",
        value = json.encode(["FD5A1E", "27251F", "FD5A1E", "27251F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Seattle Mariners",
        value = json.encode(["0C2C56", "005C5C", "0C2C56", "005C5C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Tampa Bay Rays",
        value = json.encode(["092C5C", "8FBCE6", "092C5C", "8FBCE6", "FFFFFF"]),
    ),
    schema.Option(
        display = "Texas Rangers",
        value = json.encode(["003278", "C0111F", "003278", "C0111F", "FFFFFF"]),
    ),
    schema.Option(
        display = "Toronto Blue Jays",
        value = json.encode(["134A8E", "1D2D5C", "134A8E", "1D2D5C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Washington Nationals",
        value = json.encode(["AB0003", "14225A", "AB0003", "14225A", "FFFFFF"]),
    ),
]

def oauth_handler(params):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }

    # deserialize oauth2 parameters
    params = json.decode(params)
    print("Redirect URL: " + params["redirect_uri"])
    print("Code: " + params["code"])

    body = (
        "grant_type=authorization_code" +
        "&client_id=" + params["client_id"] +
        "&client_secret=" + YAHOO_CLIENT_SECRET +
        "&code=" + params["code"] +
        "&scope=fspt-r" +
        "&redirect_uri=" + params["redirect_uri"]
    )

    # exchange parameters and client secret for an access token
    response = http.post(
        url = YAHOO_OAUTH_TOKEN_URL,
        headers = headers,
        body = body,
    )

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    refresh_token = token_params["refresh_token"]

    print("Refresh Token:" + refresh_token)
    print("Access Token: " + token_params["access_token"])

    return refresh_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Yahoo Account",
                desc = "Connect your Yahoo account.",
                icon = "baseball",
                handler = oauth_handler,
                client_id = YAHOO_CLIENT_ID or "foo",
                authorization_endpoint = "https://api.login.yahoo.com/oauth2/request_auth",
                scopes = [
                    "fspt-r",
                ],
            ),
            schema.Text(
                id = "league_number",
                name = "League Number",
                desc = "Type in the league number for your league. Go to your league in a browser and look at the URL. It should end in /b1 then /#######. Input just those numbers here.",
                icon = "hashtag",
                default = "",
            ),
            schema.Toggle(
                id = "show_scores",
                name = "Show Scores",
                desc = "Show scores instead of standings",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "rotation_speed",
                name = "Rotation Speed",
                desc = "Seconds per rotation",
                icon = "gear",
                default = rotation_options[1].value,
                options = rotation_options,
            ),
            schema.Dropdown(
                id = "teams_per_view",
                name = "Teams Per View",
                desc = "Number of teams to show at once (standings only)",
                icon = "gear",
                default = teams_per_view_options[1].value,
                options = teams_per_view_options,
            ),
            schema.Color(
                id = "heading_font_color",
                name = "Font Color",
                desc = "Heading font color",
                icon = "brush",
                default = "#FFA500",
                palette = [
                    "#FFF",
                    "#FF0",
                    "#F00",
                    "#00F",
                    "#0F0",
                    "#FFA500",
                ],
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color Scheme",
                desc = "Select the color scheme",
                icon = "gear",
                default = color_scheme_options[4].value,
                options = color_scheme_options,
            ),
        ],
    )

def get_access_token(refresh_token):
    #Try to load access token from cache
    access_token_cached = cache.get(refresh_token + "_access_token")

    if access_token_cached != None:
        print("Hit! Using cached access token " + access_token_cached)
        return access_token_cached
    else:
        print("Miss! Getting new access token from Yahoo API.")

        url = "https://api.login.yahoo.com/oauth2/get_token"
        body = (
            "grant_type=refresh_token" +
            "&redirect_uri=" + TIDBYT_OAUTH_CALLBACK_URL +
            "&refresh_token=" + refresh_token
        )
        headers = {
            "Authorization": "Basic " + YAHOO_CLIENT_ID_AND_SECRET_BASE_64,
            "Content-Type": "application/x-www-form-urlencoded",
        }
        print("Making Call")
        r = http.post(url, body = body, headers = headers)
        body = r.json()
        access_token = body["access_token"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(refresh_token + "_access_token", access_token, ttl_seconds = ACCESS_TOKEN_CACHE_TTL)
        print("Printing access token:")
        print(access_token)

        return access_token

def get_league_name(access_token, GAME_KEY, league_number):
    league_name = ""

    #Try to load league name from cache
    league_name_cached = cache.get(access_token + "_league_name")

    if league_name_cached != None:
        print("Hit! Using cached league name!")
        league_name = league_name_cached
    else:
        print("Miss! Getting new league name from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number
        headers = {
            "Authorization": "Bearer " + access_token,
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        print("Making Call for League Name")
        league_name_response = http.get(url, headers = headers)

        league_name = xpath.loads(league_name_response.body()).query("/fantasy_content/league/name")
        if league_name != None:
            print("Caching league name")

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(access_token + "_league_name", league_name, ttl_seconds = LEAGUE_NAME_CACHE_TTL)

    print(league_name)
    return league_name

def get_standings_and_records(access_token, GAME_KEY, league_number):
    allstandings = []

    #Try to load standings from cache
    standings_cached = cache.get(access_token + "_standings")

    if standings_cached != None:
        print("Hit! Using cached standings!")
        allstandings = json.decode(standings_cached)
    else:
        print("Miss! Getting new standings from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number + "/standings"
        headers = {
            "Authorization": "Bearer " + access_token,
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        print("Making Call for Standings")
        standings_response = http.get(url, headers = headers)

        total_teams = int(xpath.loads(standings_response.body()).query("/fantasy_content/league/standings/teams/@count"))
        team_names = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/name")
        team_standings = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/rank")
        team_wins = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/wins")
        team_losses = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/losses")
        team_ties = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/outcome_totals/ties")
        team_standings = xpath.loads(standings_response.body()).query_all("/fantasy_content/league/standings/teams/team/team_standings/rank")

        for team_number in range(total_teams):
            allstandings.append({"Name": team_names[team_number], "Standings": team_standings[team_number], "Wins": team_wins[team_number], "Losses": team_losses[team_number], "Ties": team_ties[team_number]})

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(access_token + "_standings", json.encode(allstandings), ttl_seconds = STANDINGS_CACHE_TTL)
    print(allstandings)
    return allstandings

def render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, leagueName):
    output = []
    teamTies = ""
    teamWins = ""
    teamLosses = ""

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = heading_font_color, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entries_to_display)
    for i in range(entries_to_display):
        if i + x < len(standings):
            mainFont = "CG-pixel-3x5-mono"
            teamName = standings[i + x]["Name"]
            teamWins = standings[i + x]["Wins"]
            teamLosses = standings[i + x]["Losses"]
            teamTies = standings[i + x]["Ties"]
            totalGames = int(teamWins) + int(teamLosses) + int(teamTies)
            if totalGames > 0:
                teamRecord = ((2 * int(teamWins) + int(teamTies)) / (2 * int(totalGames)))
                if teamRecord != 1:
                    # Multiply by 1000 and then truncate because there is no format library and we want a constant 3 digits after decimal.
                    teamRecord *= 1000
                    teamRecord = humanize.ftoa(teamRecord)
                    teamRecord = "." + teamRecord[-3:]
                else:
                    teamRecord = "1.00"
            else:
                teamRecord = "0.00"
            teamNameBoxSize = 40
            recordBoxSize = 20
            teamName = teamName[:10]

            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            elif i == 2:
                teamColor = "#" + color_scheme[2]
            else:
                teamColor = "#" + color_scheme[3]
            textColor = "#" + color_scheme[4]

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = teamNameBoxSize, height = containerHeight, child = render.Text(content = teamName, color = textColor, font = mainFont)),
                        render.Box(width = 4, height = containerHeight, child = render.Text(content = "", color = textColor, font = mainFont)),
                        render.Box(width = recordBoxSize, height = containerHeight, child = render.Text(content = str(teamRecord), color = textColor, font = mainFont)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output

def get_current_matchup(access_token, GAME_KEY, league_number):
    current_matchup = []

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_number + "/scoreboard"
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    print("Making Call for Matchups")
    current_matchup_response = http.get(url, headers = headers)

    # owners_team = xpath.loads(current_matchup_response.body()).query("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//preceding-sibling::name/text()")
    # print("Owner's Team: " + str(owners_team))

    teams_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/name")
    scores_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/team_points/total")

    for i in range(2):
        current_matchup.append({"Name": teams_in_matchup_xml[i], "Score": scores_in_matchup_xml[i]})

    print("CURRENT MATCHUP: " + str(current_matchup))
    return current_matchup

def render_current_matchup(current_matchup, entries_to_display, heading_font_color, color_scheme, leagueName):
    output = []

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = heading_font_color, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entries_to_display)
    for i in range(2):
        if i < len(current_matchup):
            mainFont = "CG-pixel-3x5-mono"
            teamName = current_matchup[i]["Name"]
            teamName = teamName[:11]
            teamColor = ""
            print(teamName)
            teamScore = current_matchup[i]["Score"]
            teamNameBoxSize = 46
            scoreBoxSize = 18
            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            textColor = "#" + color_scheme[4]

            team = render.Column(
                children = [
                    render.Box(width = 64, height = containerHeight, color = teamColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                        render.Box(width = teamNameBoxSize, height = containerHeight, child = render.Text(content = teamName, color = textColor, font = mainFont)),
                        render.Box(width = 4, height = containerHeight, child = render.Text(content = "", color = textColor, font = mainFont)),
                        render.Box(width = scoreBoxSize, height = containerHeight, child = render.Text(content = teamScore, color = textColor, font = mainFont)),
                    ])),
                ],
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])

    return output

"""
Applet: YahooFantasyNFL
Summary: Fantasy Standings & Scores
Description: Display standings or scores for a Yahoo Fantasy Football league (NFL).
Author: jweier extended from LunchBox8484
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("xpath.star", "xpath")

print("Top of File - Start")

# Constants for production repo
TIDBYT_OAUTH_CALLBACK_URL = "https%3A%2F%2Fappauth.tidbyt.com%2Fyahoofantasynfl"  # registered https://appauth.tidbyt.com/yahoofantasynfl as redirect_uri at Yahoo
YAHOO_CLIENT_ID = secret.decrypt("AV6+xWcESOzU0+vxd/pD9p6eJsSh+fkgPTLUMzJbnS00CHWXmoKWQbvmTpVIUUE3Y/J2LeplFDCPh3zEwpX0XEyHZubCkNlgu2CrTnGcGYRv4H7xOtS+BTwiEQUu40mgSarmMkxR/uo2BetzoVEctK3SkbEdVW5mZBJTPjoHZwfwPFhzXMyYKqO8EejDPYOg48beUv3MnNRx+nrtbtWf8Ip8Vj0riv9lceqgbGT5KiM5AgBNLSPHKyFwDLnj2R/3dhqyVBTR") or ""
YAHOO_CLIENT_SECRET = secret.decrypt("AV6+xWcEUbzKOHZ63pL4mNLO8MGfmkVomrRiBERdm2WxRiPjMdymwN9lROH88N5pCfo5ZSUiNlOt9J3WeM9dUe1kGTPT6AykhXEXOXPjjqhVjKBGy3UOBDeYll33K6XxYiS06WP5Au6EBK6bc3gQd6+Y1h+zZyYL4NTzh2R4U/y1Xkj7sx/0wWQEmfhBww==") or ""

# Common Constants
YAHOO_CLIENT_ID_AND_SECRET_BASE_64 = base64.encode(YAHOO_CLIENT_ID + ":" + YAHOO_CLIENT_SECRET)
YAHOO_OAUTH_AUTHORIZATION_URL = "https://api.login.yahoo.com/oauth2/request_auth"
YAHOO_OAUTH_TOKEN_URL = "https://api.login.yahoo.com/oauth2/get_token"
ACCESS_TOKEN_CACHE_TTL = 3000  # 50 minutes as Yahoo access tokens only last 60 minutes
STANDINGS_CACHE_TTL = 14400  # 4 days
LEAGUE_NAME_CACHE_TTL = 28800  # 8 days
GAME_KEY = "423"  #2023 Season
FONT = "CG-pixel-3x5-mono"

print("Top of File - End")

def get_schema():
    print("get_schema - Start")
    print("get_schema - End")

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Yahoo Account",
                desc = "Connect your Yahoo account.",
                icon = "football",
                handler = oauth_handler,
                client_id = YAHOO_CLIENT_ID or "foo",
                authorization_endpoint = "https://api.login.yahoo.com/oauth2/request_auth",
                scopes = [
                    "fspt-r",
                ],
            ),
            schema.Generated(
                id = "generated_teams",
                source = "auth",
                handler = get_current_leagues,
            ),
        ],
    )

def main(config):
    print("Main - Start")
    render_category = []
    league_name = ""
    refresh_token = config.get("auth")
    league_id = config.get("league_id", "")
    rotation_speed = config.get("rotation_speed", "5")
    teams_per_view = int(config.get("teams_per_view", "4"))
    heading_font_color = config.get("heading_font_color", "#FFA500")
    color_scheme = config.get("color_scheme", '["0A2647", "144272", "205295", "2C74B3", "FFFFFF"]')
    color_scheme = json.decode(color_scheme)
    show_scores = config.bool("show_scores", False)
    show_projections = config.bool("show_projections", True)
    show_ties = config.bool("show_ties", False)
    num_of_loops = 1

    if refresh_token:
        access_token = get_access_token(refresh_token)

        if (access_token):
            league_name = get_league_name(access_token, GAME_KEY, league_id)

            if (league_name):
                if show_scores:
                    entries_to_display = 2
                    current_matchup = get_current_matchup(access_token, GAME_KEY, league_id)
                    if show_projections:
                        # Set to two loops so it renders 2 frames for the animation
                        num_of_loops = 2
                    for x in range(0, num_of_loops):
                        render_category.extend(
                            [
                                render.Column(
                                    children = render_current_matchup(x, current_matchup, entries_to_display, heading_font_color, color_scheme),
                                ),
                            ],
                        )
                else:
                    entries_to_display = teams_per_view
                    standings = get_standings_and_records(access_token, GAME_KEY, league_id)

                    for x in range(0, len(standings), entries_to_display):
                        render_category.extend(
                            [
                                render.Column(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties),
                                        ),
                                    ],
                                ),
                            ],
                        )
                print("Main - End")
                return render.Root(
                    delay = int(rotation_speed) * 1000,
                    show_full_animation = True,
                    child = render.Animation(children = render_category),
                )
            else:
                error_message = "    ERROR! Please check your league number."
                print("Main - End")
                return render.Root(
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(error_message),
                    ),
                )
        else:
            error_message = "    ERROR! Unable to acquire an access token from the refresh token."
            print("Main - End")
            return render.Root(
                child = render.Marquee(
                    width = 64,
                    child = render.Text(error_message),
                ),
            )
    else:
        entries_to_display = teams_per_view
        league_name = "Yahoo Fantasy"

        standings = [{"Name": "Dumpster Fire", "Standings": "1", "Wins": "10", "Losses": "4", "Ties": "0"}, {"Name": "Who is Mac Jones?", "Standings": "2", "Wins": "7", "Losses": "6", "Ties": "1"}, {"Name": "Campin my style", "Standings": "3", "Wins": "12", "Losses": "2", "Ties": "0"}, {"Name": "Mixon It Up", "Standings": "4", "Wins": "8", "Losses": "5", "Ties": "1"}, {"Name": "Lamar Ja’Marr & Dally G", "Standings": "5", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "I BEAT STEVE IN THE MARATHON", "Standings": "6", "Wins": "8", "Losses": "6", "Ties": "0"}, {"Name": "WelcomeToTheZappeParade", "Standings": "7", "Wins": "5", "Losses": "9", "Ties": "0"}, {"Name": "Amon-Ra-Ah-Ah-Ah", "Standings": "8", "Wins": "3", "Losses": "11", "Ties": "0"}, {"Name": "Mar-a-Lago Raiders", "Standings": "9", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "Everyday I'm Russell'n", "Standings": "10", "Wins": "6", "Losses": "8", "Ties": "0"}, {"Name": "Jeudy's Pontiac Bandits", "Standings": "11", "Wins": "4", "Losses": "10", "Ties": "0"}, {"Name": "Poppy's Belle and Dude Perfect", "Standings": "12", "Wins": "6", "Losses": "8", "Ties": "0"}]
        for x in range(0, len(standings), entries_to_display):
            render_category.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties),
                            ),
                        ],
                    ),
                ],
            )
        print("Main - End")
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
        display = "Arizona Cardinals",
        value = json.encode(["97233F", "000000", "97233F", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Atlanta Falcons",
        value = json.encode(["A71930", "000000", "A71930", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Baltimore Ravens",
        value = json.encode(["241773", "000000", "241773", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Buffalo Bills",
        value = json.encode(["00338D", "C60C30", "00338D", "C60C30", "FFFFFF"]),
    ),
    schema.Option(
        display = "Carolina Panthers",
        value = json.encode(["0085CA", "101820", "0085CA", "101820", "FFFFFF"]),
    ),
    schema.Option(
        display = "Chicago Bears",
        value = json.encode(["C83803", "0B162A", "C83803", "0B162A", "FFFFFF"]),
    ),
    schema.Option(
        display = "Cincinnati Bengals",
        value = json.encode(["FB4F14", "000000", "FB4F14", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Cleveland Browns",
        value = json.encode(["311D00", "FF3C00", "311D00", "FF3C00", "FFFFFF"]),
    ),
    schema.Option(
        display = "Dallas Cowboys",
        value = json.encode(["003594", "041E42", "003594", "041E42", "869397"]),
    ),
    schema.Option(
        display = "Denver Broncos",
        value = json.encode(["FB4F14", "002244", "FB4F14", "002244", "FFFFFF"]),
    ),
    schema.Option(
        display = "Detroit Lions",
        value = json.encode(["0076B6", "000000", "0076B6", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Green Bay Packers",
        value = json.encode(["203731", "FFB612", "203731", "FFB612", "FFFFFF"]),
    ),
    schema.Option(
        display = "Houston Texans",
        value = json.encode(["03202F", "A71930", "03202F", "A71930", "FFFFFF"]),
    ),
    schema.Option(
        display = "Indianapolis Colts",
        value = json.encode(["002C5F", "002C5F", "002C5F", "002C5F", "B0B7BC"]),
    ),
    schema.Option(
        display = "Jacksonville Jaguars",
        value = json.encode(["006778", "9F792C", "006778", "9F792C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Kansas City Chiefs",
        value = json.encode(["E31837", "FFB81C", "E31837", "FFB81C", "FFFFFF"]),
    ),
    schema.Option(
        display = "Las Vegas Raiders",
        value = json.encode(["000000", "000000", "000000", "000000", "A5ACAF"]),
    ),
    schema.Option(
        display = "Los Angeles Chargers",
        value = json.encode(["0080C6", "FFC20E", "0080C6", "FFC20E", "FFFFFF"]),
    ),
    schema.Option(
        display = "Los Angeles Rams",
        value = json.encode(["003594", "FFA300", "003594", "FFA300", "FFFFFF"]),
    ),
    schema.Option(
        display = "Miami Dolphins",
        value = json.encode(["008E97", "FC4C02", "008E97", "FC4C02", "FFFFFF"]),
    ),
    schema.Option(
        display = "Minnestoa Vikings",
        value = json.encode(["4F2683", "FFC62F", "4F2683", "FFC62F", "FFFFFF"]),
    ),
    schema.Option(
        display = "New England Patriots",
        value = json.encode(["002244", "C60C30", "002244", "C60C30", "FFFFFF"]),
    ),
    schema.Option(
        display = "New Orleans Saints",
        value = json.encode(["101820", "101820", "101820", "101820", "D3BC8D"]),
    ),
    schema.Option(
        display = "New York Giants",
        value = json.encode(["0B2265", "A71930", "0B2265", "A71930", "A5ACAF"]),
    ),
    schema.Option(
        display = "New York Jets",
        value = json.encode(["125740", "000000", "125740", "000000", "FFFFFF"]),
    ),
    schema.Option(
        display = "Philadelphia Eagles",
        value = json.encode(["004C54", "000000", "004C54", "000000", "A5ACAF"]),
    ),
    schema.Option(
        display = "Pittsburgh Steelers",
        value = json.encode(["101820", "101820", "101820", "101820", "FFB612"]),
    ),
    schema.Option(
        display = "San Francisco 49ers",
        value = json.encode(["AA0000", "B3995D", "AA0000", "B3995D", "FFFFFF"]),
    ),
    schema.Option(
        display = "Seattle Seahawks",
        value = json.encode(["002244", "69BE28", "002244", "69BE28", "FFFFFF"]),
    ),
    schema.Option(
        display = "Tampa Bay Buccaneers",
        value = json.encode(["D50A0A", "FF7900", "D50A0A", "FF7900", "FFFFFF"]),
    ),
    schema.Option(
        display = "Tennessee Titans",
        value = json.encode(["0C2340", "4B92DB", "0C2340", "4B92DB", "FFFFFF"]),
    ),
    schema.Option(
        display = "Washington Commanders",
        value = json.encode(["773141", "FFB612", "773141", "FFB612", "FFFFFF"]),
    ),
]

def oauth_handler(params):
    print("oauth_handler - Start")
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }

    # deserialize oauth2 parameters
    params = json.decode(params)

    print("    Redirect URL: " + params["redirect_uri"])
    print("    Code: " + params["code"])

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
    print("oauth_handler - End")
    return refresh_token

def get_access_token(refresh_token):
    print("get_access_token - Start")

    #Try to load access token from cache
    access_token_cached = cache.get(refresh_token + "_access_token")

    if access_token_cached != None:
        print("    Cache Hit! Used cached access token")
        print("get_access_token - End")
        return access_token_cached
    else:
        print("    Cache Miss! Getting new access token from Yahoo API.")

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
        print("    Making Call for access token")
        r = http.post(url, body = body, headers = headers)
        body = r.json()
        access_token = body["access_token"]

        print("    Caching access token")

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(refresh_token + "_access_token", access_token, ttl_seconds = ACCESS_TOKEN_CACHE_TTL)
        print("get_access_token - End")
        return access_token

def get_current_leagues(refresh_token):
    print("get_current_leagues - Start")
    access_token = get_access_token(refresh_token)

    url = "https://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games;game_keys=nfl/leagues/"
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    print("    Making Call for Leagues")
    current_leagues_response = http.get(url, headers = headers)

    # Get both ID and Name so you can show the name but set the ID as the actual value so it can be used in API requests
    current_leagues_id = xpath.loads(current_leagues_response.body()).query_all("/fantasy_content/users/user/games/game/leagues/league/league_id")
    current_leagues_name = xpath.loads(current_leagues_response.body()).query_all("/fantasy_content/users/user/games/game/leagues/league/name")

    league_name_options = []

    for count, league in enumerate(current_leagues_name):
        league_name_options.append(
            schema.Option(
                display = league,
                value = current_leagues_id[count],
            ),
        )
    print("get_current_leagues - End")
    return [
        schema.Dropdown(
            id = "league_id",
            name = "League",
            desc = "Choose the appropriate league",
            icon = "hashtag",
            options = league_name_options,
            default = league_name_options[0].value,
        ),
        schema.Toggle(
            id = "show_scores",
            name = "Show Scores",
            desc = "Show scores instead of standings",
            icon = "gear",
            default = False,
        ),
        schema.Toggle(
            id = "show_projections",
            name = "Show Live Projections",
            desc = "Show live scoring and win pct projections (scores only)",
            icon = "gear",
            default = False,
        ),
        schema.Toggle(
            id = "show_ties",
            name = "Show Ties",
            desc = "Show ties in team record",
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
            default = color_scheme_options[0].value,
            options = color_scheme_options,
        ),
    ]

def get_league_name(access_token, GAME_KEY, league_id):
    print("get_league_name - Start")
    league_name = ""

    #Try to load league name and id from cache
    league_id_cached = cache.get(access_token + "_league_id")
    league_name_cached = cache.get(access_token + "_league_name")

    if league_name_cached != None and league_id == league_id_cached:
        print("    Cache Hit! Using cached league name!")
        league_name = league_name_cached
    else:
        print("    Cache Miss! Getting new league name from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_id
        headers = {
            "Authorization": "Bearer " + access_token,
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        print("    Making Call for League Name")
        league_name_response = http.get(url, headers = headers)

        league_name = xpath.loads(league_name_response.body()).query("/fantasy_content/league/name")
        if league_name != None:
            print("    Caching league name")

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(access_token + "_league_name", league_name, ttl_seconds = LEAGUE_NAME_CACHE_TTL)

    print("get_league_name - End")
    return league_name

def get_standings_and_records(access_token, GAME_KEY, league_id):
    print("get_standings_and_records - Start")
    allstandings = []
    league_id_cached = cache.get(access_token + "_league_id")
    standings_cached = cache.get(access_token + "_standings")

    if league_id_cached != league_id or standings_cached == None:
        # If the league ID has changed or the standings aren't cache, then make the call for the standings and set the cache
        if league_id_cached != league_id:
            print("    League ID changed so re-querying standings and records")
        if standings_cached == None:
            print("    Cache Miss! Getting new standings from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_id + "/standings"
        headers = {
            "Authorization": "Bearer " + access_token,
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        print("    Making Call for Standings")
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
    else:
        # If league ID matches and standings are cached, then call the cache
        print("    Cache Hit! Using cached standings!")
        allstandings = json.decode(standings_cached)
    print("get_standings_and_records - End")
    return allstandings

def get_current_matchup(access_token, GAME_KEY, league_id):
    print("get_current_matchup - Start")
    current_matchup = []

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + GAME_KEY + ".l." + league_id + "/scoreboard"
    headers = {
        "Authorization": "Bearer " + access_token,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    print("    Making Call for Matchups")
    current_matchup_response = http.get(url, headers = headers)

    # owners_team = xpath.loads(current_matchup_response.body()).query("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//preceding-sibling::name/text()")
    # print("Owner's Team: " + str(owners_team))

    teams_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/name")
    scores_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/team_points/total")
    projected_scores_in_matchup_xml = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/team_projected_points/total")
    win_probability_in_matchup = xpath.loads(current_matchup_response.body()).query_all("/fantasy_content/league/scoreboard/matchups/matchup/teams/team/is_owned_by_current_login//ancestor::matchup/teams/team/win_probability")

    for i in range(2):
        current_matchup.append({"Name": teams_in_matchup_xml[i], "Score": scores_in_matchup_xml[i], "Projected": projected_scores_in_matchup_xml[i], "Win_Probability": str(100 * float(win_probability_in_matchup[i]))[:2] + "%"})

    print("    Current Matchup: " + str(current_matchup))
    print("get_current_matchup - End")
    return current_matchup

def render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties):
    print("render_standings_and_records - Start")
    output = []
    teamTies = ""
    teamWins = ""
    teamLosses = ""

    title_bar = render.Column(
        children = [
            render.Box(
                width = 64,
                height = 8,
                child = render.Row(
                    children = [
                        render.Text(content = league_name, color = heading_font_color, font = FONT),
                    ],
                ),
            ),
        ],
    )
    output.extend([title_bar])

    containerHeight = int(24 / entries_to_display)
    for i in range(entries_to_display):
        if i + x < len(standings):
            teamName = standings[i + x]["Name"]
            teamWins = standings[i + x]["Wins"]
            teamLosses = standings[i + x]["Losses"]
            teamTies = standings[i + x]["Ties"]
            if show_ties:
                teamName = teamName[:9]
                teamRecord = teamWins + "-" + teamLosses + "-" + teamTies
            else:
                teamName = teamName[:10]
                teamRecord = teamWins + "-" + teamLosses

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
                    render.Box(
                        width = 64,
                        height = containerHeight,
                        color = teamColor,
                        child = render.Row(
                            children = [
                                render.Text(content = teamName, color = textColor, font = FONT),
                                render.Text(content = teamRecord, color = textColor, font = FONT),
                            ],
                            expanded = True,
                            main_align = "space_between",
                        ),
                    ),
                ],
            )
            output.extend([team])

        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])
    print("render_standings_and_records - End")
    return output

def render_current_matchup(x, current_matchup, entries_to_display, heading_font_color, color_scheme):
    print("render_current_matchup - Start")
    output = []
    containerHeight = int(24 / entries_to_display)
    teamColor = ""

    if x == 0:
        title_bar = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    child = render.Row(
                        children = [
                            render.Text(content = "Live Score", color = heading_font_color, font = FONT),
                        ],
                    ),
                ),
            ],
        )
        output.extend([title_bar])

        i = 0
        for roster in current_matchup:
            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            textColor = "#" + color_scheme[4]
            if len(str(roster["Projected"])[:3]) == 1:
                projected = "  " + str(roster["Projected"])
            elif len(str(roster["Projected"])[:3]) == 2:
                projected = " " + str(roster["Projected"])
            else:
                projected = str(roster["Projected"])[:3]
            team = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = containerHeight,
                        color = teamColor,
                        child = render.Row(
                            children = [
                                render.Text(content = roster["Name"][:11], color = textColor, font = FONT),
                                render.Text(content = roster["Score"][:3], color = textColor, font = FONT),
                            ],
                            expanded = True,
                            main_align = "space_between",
                        ),
                    ),
                ],
            )
            output.extend([team])
            i = i + 1

    elif x == 1:
        title_bar = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    child = render.Row(
                        children = [
                            render.Text(content = "Proj    Pct  Pts", color = heading_font_color, font = FONT),
                        ],
                    ),
                ),
            ],
        )
        output.extend([title_bar])

        i = 0
        for roster in current_matchup:
            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            textColor = "#" + color_scheme[4]
            if len(str(roster["Projected"])[:3]) == 1:
                projected = "  " + str(roster["Projected"])
            elif len(str(roster["Projected"])[:3]) == 2:
                projected = " " + str(roster["Projected"])
            else:
                projected = str(roster["Projected"])[:3]
            team = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 12,
                        color = teamColor,
                        child = render.Row(
                            children = [
                                render.Text(content = roster["Name"][:7], color = textColor, font = FONT),
                                render.Text(content = roster["Win_Probability"], color = textColor, font = FONT),
                                render.Text(content = projected, color = textColor, font = FONT),
                            ],
                            expanded = True,
                            main_align = "space_between",
                        ),
                    ),
                ],
            )
            output.extend([team])
            i = i + 1

    print("render_current_matchup - End")
    return output

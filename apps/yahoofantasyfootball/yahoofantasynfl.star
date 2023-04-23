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

#TIDBYT_OAUTH_CALLBACK_URL = "https%3A%2F%2Flocalhost%2Foauth-callback"  # registered https://localhost/oauth-callback as redirect_uri at Yahoo
TIDBYT_OAUTH_CALLBACK_URL = "https%3A%2F%2Fappauth.tidbyt.com%2Fyahoofantasynfl"

YAHOO_CLIENT_ID = secret.decrypt("AV6+xWcESOzU0+vxd/pD9p6eJsSh+fkgPTLUMzJbnS00CHWXmoKWQbvmTpVIUUE3Y/J2LeplFDCPh3zEwpX0XEyHZubCkNlgu2CrTnGcGYRv4H7xOtS+BTwiEQUu40mgSarmMkxR/uo2BetzoVEctK3SkbEdVW5mZBJTPjoHZwfwPFhzXMyYKqO8EejDPYOg48beUv3MnNRx+nrtbtWf8Ip8Vj0riv9lceqgbGT5KiM5AgBNLSPHKyFwDLnj2R/3dhqyVBTR") or ""
YAHOO_CLIENT_SECRET = secret.decrypt("AV6+xWcEUbzKOHZ63pL4mNLO8MGfmkVomrRiBERdm2WxRiPjMdymwN9lROH88N5pCfo5ZSUiNlOt9J3WeM9dUe1kGTPT6AykhXEXOXPjjqhVjKBGy3UOBDeYll33K6XxYiS06WP5Au6EBK6bc3gQd6+Y1h+zZyYL4NTzh2R4U/y1Xkj7sx/0wWQEmfhBww==") or ""
YAHOO_CLIENT_ID_AND_SECRET_BASE_64 = base64.encode(YAHOO_CLIENT_ID + ":" + YAHOO_CLIENT_SECRET)
YAHOO_OAUTH_AUTHORIZATION_URL = "https://api.login.yahoo.com/oauth2/request_auth"
YAHOO_OAUTH_TOKEN_URL = "https://api.login.yahoo.com/oauth2/get_token"

ACCESS_TOKEN_CACHE_TTL = 3000  # 50 minutes as Yahoo access tokens only last 60 minutes
STANDINGS_CACHE_TTL = 14400  # 4 days
LEAGUE_NAME_CACHE_TTL = 28800  # 8 days

gameKey = "414"

def main(config):
    renderCategory = []
    refresh_token = config.get("auth")
    leagueNumber = config.get("leagueNumber", "")
    league_name = ""
    rotationSpeed = config.get("rotationSpeed", "5")
    teamsToShow = int(config.get("teamsOptions", "4"))
    topColor = config.get("topFontColor", "#FFA500")
    colorScheme = config.get("colorScheme", '["0A2647", "144272", "205295", "2C74B3", "FFFFFF"]')
    colorScheme = json.decode(colorScheme)
    displayScores = config.bool("displayScores", False)
    displayTies = config.bool("displayTies", False)
    if refresh_token:
        print("Calling Get Access Token")
        access_token = get_access_token(refresh_token)

        if (access_token):
            print("League Name: " + league_name)
            league_name = get_league_name(access_token, gameKey, leagueNumber)

            if (league_name):
                if displayScores:
                    entriesToDisplay = 2
                    current_matchup = get_current_matchup(access_token, gameKey, leagueNumber)

                    renderCategory.extend(
                        [
                            render.Column(
                                expanded = True,
                                main_align = "start",
                                cross_align = "start",
                                children = [
                                    render.Column(
                                        children = render_matchup(current_matchup, entriesToDisplay, topColor, colorScheme, league_name),
                                    ),
                                ],
                            ),
                        ],
                    )
                else:
                    entriesToDisplay = teamsToShow
                    standings = get_standings_and_records(access_token, gameKey, leagueNumber)

                    #sampleStandings = [{"Name": "Dumpster Fire", "Standings": "1", "Wins": "10", "Losses": "4", "Ties": "0"}, {"Name": "Who is Mac Jones?", "Standings": "2", "Wins": "7", "Losses": "6", "Ties": "1"}, {"Name": "Campin my style", "Standings": "3", "Wins": "12", "Losses": "2", "Ties": "0"}, {"Name": "Mixon It Up", "Standings": "4", "Wins": "8", "Losses": "5", "Ties": "1"}, {"Name": "Lamar Ja’Marr & Dally G", "Standings": "5", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "I BEAT STEVE IN THE MARATHON", "Standings": "6", "Wins": "8", "Losses": "6", "Ties": "0"}, {"Name": "WelcomeToTheZappeParade", "Standings": "7", "Wins": "5", "Losses": "9", "Ties": "0"}, {"Name": "Amon-Ra-Ah-Ah-Ah", "Standings": "8", "Wins": "3", "Losses": "11", "Ties": "0"}, {"Name": "Mar-a-Lago Raiders", "Standings": "9", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "Everyday I'm Russell'n", "Standings": "10", "Wins": "6", "Losses": "8", "Ties": "0"}, {"Name": "Jeudy's Pontiac Bandits", "Standings": "11", "Wins": "4", "Losses": "10", "Ties": "0"}, {"Name": "Poppy's Belle and Dude Perfect", "Standings": "12", "Wins": "6", "Losses": "8", "Ties": "0"}]
                    for x in range(0, len(standings), entriesToDisplay):
                        renderCategory.extend(
                            [
                                render.Column(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = render_standings(x, standings, entriesToDisplay, topColor, colorScheme, league_name, displayTies),
                                        ),
                                    ],
                                ),
                            ],
                        )

                return render.Root(
                    delay = int(rotationSpeed) * 1000,
                    show_full_animation = True,
                    child = render.Animation(children = renderCategory),
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
        error_message = "Please connect your Yahoo account."
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text(error_message),
            ),
        )

rotationOptions = [
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

teamsOptions = [
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

colorSchemeColorOptions = [
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
        cache.set(refresh_token + "_access_token", access_token, ttl_seconds = ACCESS_TOKEN_CACHE_TTL)
        print("Printing access token:")
        print(access_token)

        return access_token

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
                icon = "football",
                handler = oauth_handler,
                client_id = "dj0yJmk9RkJhYkJhWmFsaWREJmQ9WVdrOVNXRkhOVVI2YkVrbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWRl",
                authorization_endpoint = "https://api.login.yahoo.com/oauth2/request_auth",
                scopes = [
                    "fspt-r",
                ],
            ),
            schema.Text(
                id = "leagueNumber",
                name = "League Number",
                desc = "Type in the league number for your league. Go to your league in a browser and look at the URL. It should end in /f1 then /#######. Input just those numbers here.",
                icon = "hashtag",
                default = "",
            ),
            schema.Toggle(
                id = "displayScores",
                name = "Display Scores",
                desc = "Should scores be shown instead of standings?",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "displayTies",
                name = "Display Ties",
                desc = "Should ties be shown in the standings?",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gear",
                default = rotationOptions[1].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams it should show at once. Only applies to standings.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "colorScheme",
                name = "Primary Color Scheme",
                desc = "Select the primary color screen",
                icon = "gear",
                default = colorSchemeColorOptions[0].value,
                options = colorSchemeColorOptions,
            ),
            schema.Color(
                id = "topFontColor",
                name = "Top Font Color",
                desc = "Customize the color of the font at the top.",
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
        ],
    )

def get_standings_and_records(access_token, gameKey, leagueNumber):
    allstandings = []

    #Try to load standings from cache
    standings_cached = cache.get(access_token + "_standings")

    if standings_cached != None:
        print("Hit! Using cached standings!")
        allstandings = json.decode(standings_cached)
    else:
        print("Miss! Getting new standings from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + gameKey + ".l." + leagueNumber + "/standings"
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

        cache.set(access_token + "_standings", json.encode(allstandings), ttl_seconds = STANDINGS_CACHE_TTL)
    print(allstandings)
    return allstandings

def get_league_name(access_token, gameKey, leagueNumber):
    league_name = ""

    #Try to load league name from cache
    league_name_cached = cache.get(access_token + "_league_name")

    if league_name_cached != None:
        print("Hit! Using cached league name!")
        league_name = league_name_cached
    else:
        print("Miss! Getting new league name from Yahoo API.")
        url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + gameKey + ".l." + leagueNumber
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
            cache.set(access_token + "_league_name", league_name, ttl_seconds = LEAGUE_NAME_CACHE_TTL)

    print(league_name)
    return league_name

def render_standings(x, standings, entriesToDisplay, topColor, colorScheme, leagueName, displayTies):
    output = []
    teamTies = ""
    teamWins = ""
    teamLosses = ""

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = topColor, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entriesToDisplay)
    for i in range(entriesToDisplay):
        if i + x < len(standings):
            mainFont = "CG-pixel-3x5-mono"
            teamName = standings[i + x]["Name"]
            teamWins = standings[i + x]["Wins"]
            teamLosses = standings[i + x]["Losses"]
            teamTies = standings[i + x]["Ties"]
            if displayTies:
                teamRecord = teamWins + "-" + teamLosses + "-" + teamTies
                teamNameBoxSize = 36
                recordBoxSize = 24
                teamName = teamName[:9]
            else:
                teamRecord = teamWins + "-" + teamLosses
                teamNameBoxSize = 40
                recordBoxSize = 20
                teamName = teamName[:10]

            if i == 0:
                teamColor = "#" + colorScheme[0]
            elif i == 1:
                teamColor = "#" + colorScheme[1]
            elif i == 2:
                teamColor = "#" + colorScheme[2]
            else:
                teamColor = "#" + colorScheme[3]
            textColor = "#" + colorScheme[4]

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

def render_matchup(current_matchup, entriesToDisplay, topColor, colorScheme, leagueName):
    output = []

    topColumn = [
        render.Box(width = 64, height = 8, child = render.Stack(children = [
            render.Box(width = 64, height = 8, color = "#000"),
            render.Box(width = 64, height = 8, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(color = topColor, content = leagueName, font = "CG-pixel-3x5-mono"),
            ])),
        ])),
    ]

    output.extend(topColumn)
    containerHeight = int(24 / entriesToDisplay)
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
                teamColor = "#" + colorScheme[0]
            elif i == 1:
                teamColor = "#" + colorScheme[1]
            textColor = "#" + colorScheme[4]

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

def get_current_matchup(access_token, gameKey, leagueNumber):
    current_matchup = []

    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/" + gameKey + ".l." + leagueNumber + "/scoreboard"
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

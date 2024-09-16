"""
Applet: SleeperFantasyNFL
Summary: Fantasy Standings & Scores
Description: Display standings or scores for a Sleeper Fantasy Football league (NFL).
Author: jweier
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

print("     ")
print("---------------TOP OF FILE START---------------")
print("     ")

#Constants
SLEEPER_API_BASE_URL = "https://api.sleeper.app/v1"
SLEEPER_GAME_KEY = "2023"  #2023 Season
FONT = "CG-pixel-3x5-mono"
USER_ID_CACHE_TTL = 604800  # 1 day
LEAGUE_NAME_CACHE_TTL = 259200  # 3 days
CURRENT_WEEK_CACHE_TTL = 43200  # 12 hours
LEAGUE_ROSTERS_CACHE_TTL = 43200  # 12 hours
LEAGUE_USERS_CACHE_TTL = 259200  # 3 days

def main(config):
    print("Main - Start")
    render_category = []
    output = []
    roster_details_in_matchup = []
    league_name = ""
    username = config.get("username")
    league_id = config.get("league_name")
    rotation_speed = config.get("rotation_speed", "5")
    teams_per_view = int(config.get("teams_per_view", "4"))
    heading_font_color = config.get("heading_font_color", "#FFA500")
    color_scheme = config.get("color_scheme", '["0A2647", "144272", "205295", "2C74B3", "FFFFFF"]')
    color_scheme = json.decode(color_scheme)
    show_scores = config.bool("show_scores", False)
    show_ties = config.bool("show_ties", False)

    if league_id != None:
        league_name = get_league_name(league_id)
        league_users = get_league_users(league_id)
        league_rosters = get_league_rosters(league_id)
        user_id = get_current_user_user_id(league_id, username, league_users)
        roster_id = get_current_user_roster_id(user_id, league_rosters)
        user_and_roster_map = build_user_and_roster_mapping(league_rosters, league_users)

        if show_scores:
            current_week = get_current_nfl_week()
            roster_ids_in_matchup = get_current_matchup(league_id, roster_id, current_week)
            roster_details_in_matchup = get_roster_names_in_matchup(roster_ids_in_matchup, user_and_roster_map)
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

            color_x = 0
            for roster in roster_details_in_matchup:
                if color_x % 2 == 0:
                    color = color_scheme[0]
                else:
                    color = color_scheme[1]
                team = render.Column(
                    children = [
                        render.Box(
                            width = 64,
                            height = 12,
                            color = color,
                            child = render.Row(
                                children = [
                                    render.Text(content = roster_details_in_matchup[roster]["username"][:10], color = color_scheme[4], font = FONT),
                                    render.Text(content = str(roster_details_in_matchup[roster]["points"])[:5], color = color_scheme[4], font = FONT),
                                ],
                                expanded = True,
                                main_align = "space_between",
                            ),
                        ),
                    ],
                )
                color_x = color_x + 1
                output.extend([team])

            render_category.extend(
                [
                    render.Column(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = [
                            render.Column(
                                children = output,
                            ),
                        ],
                    ),
                ],
            )

        else:
            team_records = get_team_records(user_and_roster_map, league_rosters)
            sorted_team_winning_percentage = get_team_winning_percentage(user_and_roster_map, league_rosters)
            entries_to_display = teams_per_view
            standings = calculate_standings(sorted_team_winning_percentage, team_records)
            for x in range(0, len(standings), entries_to_display):
                render_category.extend(
                    [
                        render.Column(
                            children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties),
                        ),
                    ],
                )
    else:
        entries_to_display = teams_per_view
        league_name = "Sleeper Fantasy"

        standings = [{"Name": "Dumpster Fire", "Standings": "1", "Wins": "10", "Losses": "4", "Ties": "0"}, {"Name": "Who is Mac Jones?", "Standings": "2", "Wins": "7", "Losses": "6", "Ties": "1"}, {"Name": "Campin my style", "Standings": "3", "Wins": "12", "Losses": "2", "Ties": "0"}, {"Name": "Mixon It Up", "Standings": "4", "Wins": "8", "Losses": "5", "Ties": "1"}, {"Name": "Lamar Ja’Marr & Dally G", "Standings": "5", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "I BEAT STEVE IN THE MARATHON", "Standings": "6", "Wins": "8", "Losses": "6", "Ties": "0"}, {"Name": "WelcomeToTheZappeParade", "Standings": "7", "Wins": "5", "Losses": "9", "Ties": "0"}, {"Name": "Amon-Ra-Ah-Ah-Ah", "Standings": "8", "Wins": "3", "Losses": "11", "Ties": "0"}, {"Name": "Mar-a-Lago Raiders", "Standings": "9", "Wins": "7", "Losses": "7", "Ties": "0"}, {"Name": "Everyday I'm Russell'n", "Standings": "10", "Wins": "6", "Losses": "8", "Ties": "0"}, {"Name": "Jeudy's Pontiac Bandits", "Standings": "11", "Wins": "4", "Losses": "10", "Ties": "0"}, {"Name": "Poppy's Belle and Dude Perfect", "Standings": "12", "Wins": "6", "Losses": "8", "Ties": "0"}]
        for x in range(0, len(standings), entries_to_display):
            render_category.extend(
                [
                    render.Column(
                        children = render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties),
                    ),
                ],
            )

    print("Main - End")
    return render.Root(
        delay = int(rotation_speed) * 1000,
        show_full_animation = True,
        child = render.Animation(children = render_category),
    )

def get_league_name(league_id):
    league_name_cached = cache.get(league_id + "_league_name")
    if league_name_cached != None:
        print("    Cache Hit! Used cached league name")
        return league_name_cached
    else:
        league_url = SLEEPER_API_BASE_URL + "/league/" + league_id
        league_response = http.get(league_url)
        league_response_json = league_response.json()
        if league_response_json != None:
            league_name = str(league_response_json["name"])
            cache.set(league_id + "_league_name", league_name, ttl_seconds = LEAGUE_NAME_CACHE_TTL)
            return league_name
        else:
            return []

def get_league_users(league_id):
    league_users_cached = cache.get(league_id + "_league_users")
    if league_users_cached != None:
        print("    Cache Hit! Used cached league users")
        league_users_response_json = json.decode(league_users_cached)
        return league_users_response_json
    else:
        league_users_url = SLEEPER_API_BASE_URL + "/league/" + league_id + "/users"
        league_users_response = http.get(league_users_url)
        league_users_response_json = league_users_response.json()
        if league_users_response_json != None:
            cache.set(league_id + "_league_users", json.encode(league_users_response_json), ttl_seconds = LEAGUE_USERS_CACHE_TTL)
            return league_users_response_json
        else:
            return []

def get_league_rosters(league_id):
    league_rosters_cached = cache.get(league_id + "_league_rosters")
    if league_rosters_cached != None:
        print("    Cache Hit! Used cached league rosters")
        league_rosters_response_json = json.decode(league_rosters_cached)
        return league_rosters_response_json
    else:
        league_rosters_url = SLEEPER_API_BASE_URL + "/league/" + league_id + "/rosters"
        league_rosters_response = http.get(league_rosters_url)
        league_rosters_response_json = league_rosters_response.json()
        if league_rosters_response_json != None:
            cache.set(league_id + "_league_rosters", json.encode(league_rosters_response_json), ttl_seconds = LEAGUE_ROSTERS_CACHE_TTL)
            return league_rosters_response_json
        else:
            return []

def get_current_user_user_id(league_id, username, league_users):
    user_id = ""
    user_id_cached = cache.get(league_id + "_user_id")
    if user_id_cached != None:
        print("    Cache Hit! Used cached user id")
        return user_id_cached
    else:
        for user in league_users:
            if user["display_name"] == username:
                user_id = user["user_id"]
                cache.set(league_id + "_user_id", str(user_id), ttl_seconds = USER_ID_CACHE_TTL)

        return user_id

def get_current_user_roster_id(user_id, league_rosters):
    roster_id = ""
    for roster in league_rosters:
        if roster["owner_id"] == user_id:
            roster_id = roster["roster_id"]
    return roster_id

def build_user_and_roster_mapping(league_rosters, league_users):
    user_dict = {}

    for user in league_users:
        user_dict[user["user_id"]] = user["display_name"]

    roster_dict = {}
    for roster in league_rosters:
        roster_dict[roster["roster_id"]] = {"owner_id": roster["owner_id"], "username": user_dict[roster["owner_id"]]}

    return roster_dict

def get_current_nfl_week():
    current_week = 1
    current_week_cached = cache.get("current_week")
    if current_week_cached != None:
        print("    Cache Hit! Used cached current week")
        current_week = current_week_cached
        return current_week
    else:
        current_week_url = SLEEPER_API_BASE_URL + "/state/nfl"
        current_week_response = http.get(current_week_url)
        current_week_response_json = current_week_response.json()
        if current_week_response_json != None:
            current_week = int(current_week_response_json["week"])
            cache.set("current_week", str(current_week), ttl_seconds = CURRENT_WEEK_CACHE_TTL)
            return current_week
        else:
            return []

def get_current_matchup(league_id, roster_id, current_week):
    matchup_id = ""
    roster_ids_in_matchup = {}
    league_matchups_url = SLEEPER_API_BASE_URL + "/league/" + league_id + "/matchups/" + str(current_week)
    league_matchups_response = http.get(league_matchups_url)
    league_matchups_response_json = league_matchups_response.json()
    if league_matchups_response_json != None:
        for matchup in league_matchups_response_json:
            if matchup["roster_id"] == roster_id:
                matchup_id = int(matchup["matchup_id"])
        for matchup in league_matchups_response_json:
            if matchup["matchup_id"] == matchup_id:
                roster_ids_in_matchup[matchup["roster_id"]] = {"points": matchup["points"]}
        return roster_ids_in_matchup
    else:
        return []

def get_roster_names_in_matchup(roster_ids_in_matchup, user_and_roster_map):
    for roster_id in roster_ids_in_matchup:
        roster_ids_in_matchup[roster_id]["username"] = user_and_roster_map[roster_id]["username"]

    return roster_ids_in_matchup

def get_team_records(user_and_roster_map, league_rosters):
    team_records = {}
    for team_record in league_rosters:
        team_wins = team_record["settings"]["wins"]
        team_losses = team_record["settings"]["losses"]
        team_ties = team_record["settings"]["ties"]
        team_records[user_and_roster_map[team_record["roster_id"]]["username"]] = {"Wins": team_wins, "Losses": team_losses, "Ties": team_ties}
    return team_records

def get_team_winning_percentage(user_and_roster_map, league_rosters):
    team_winning_percentage = {}
    for team in league_rosters:
        team_wins = team["settings"]["wins"]
        team_losses = team["settings"]["losses"]
        team_ties = team["settings"]["ties"]
        team_winning_pct_calc = (2 * team_wins) / (2 * (team_wins + team_losses + team_ties))
        team_winning_percentage[user_and_roster_map[team["roster_id"]]["username"]] = team_winning_pct_calc

    sorted_team_winning_percentage = sorted(team_winning_percentage.items(), key = lambda x: x[1], reverse = True)
    return sorted_team_winning_percentage

def calculate_standings(sorted_team_winning_percentage, team_records):
    standings = []
    standing = 1
    for team in sorted_team_winning_percentage:
        standings.append({"Name": team[0], "Standings": standing, "WinPct": team[1], "Wins": team_records[team[0]]["Wins"], "Losses": team_records[team[0]]["Losses"], "Ties": team_records[team[0]]["Ties"]})
        standing = standing + 1
    return standings

def render_standings_and_records(x, standings, entries_to_display, heading_font_color, color_scheme, league_name, show_ties):
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
                teamRecord = str(int(teamWins)) + "-" + str(int(teamLosses)) + "-" + str(int(teamTies))
                teamName = teamName[:10]
            else:
                teamRecord = str(int(teamWins)) + "-" + str(int(teamLosses))
                teamName = teamName[:11]
            if i == 0:
                teamColor = "#" + color_scheme[0]
            elif i == 1:
                teamColor = "#" + color_scheme[1]
            elif i == 2:
                teamColor = "#" + color_scheme[2]
            else:
                teamColor = "#" + color_scheme[3]
            textColor = "#" + color_scheme[4]

            team = render.Box(
                width = 64,
                height = containerHeight,
                color = teamColor,
                child = render.Row(
                    children = [
                        render.Text(content = teamName[:8], color = textColor, font = FONT),
                        render.Text(content = str(teamRecord), color = textColor, font = FONT),
                    ],
                    expanded = True,
                    main_align = "space_between",
                ),
            )
            output.extend([team])
        else:
            output.extend([render.Column(children = [render.Box(width = 64, height = containerHeight, color = "#111")])])
    print("render_standings_and_records - End")
    return output

def get_schema():
    print("get_schema - Start")
    print("get_schema - End")

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Enter your username",
                icon = "gear",
            ),
            schema.Generated(
                id = "generated_leagues",
                source = "username",
                handler = get_current_leagues,
            ),
        ],
    )

def get_current_leagues(username):
    league_name_options = []

    user_id_cached = cache.get(username + "_user_id")
    if user_id_cached != None:
        print("    Cache Hit! Used cached used id")
        user_id = user_id_cached
    else:
        user_url = SLEEPER_API_BASE_URL + "/user/" + username
        print(user_url)
        user_response = http.get(user_url)
        user_response_json = user_response.json()
        if user_response_json != None:
            user_id = user_response_json["user_id"]
            cache.set(username + "_user_id", user_id, ttl_seconds = USER_ID_CACHE_TTL)
        else:
            return []

    leagues_url = SLEEPER_API_BASE_URL + "/user/" + user_id + "/leagues/nfl/" + SLEEPER_GAME_KEY
    print(leagues_url)
    leagues_response = http.get(leagues_url)
    leagues_response_json = leagues_response.json()
    if leagues_response_json != None:
        for league in leagues_response_json:
            league_name_options.append(
                schema.Option(
                    display = league["name"],
                    value = league["league_id"],
                ),
            )

    else:
        print("get_current_leagues - End")
        return []

    return [
        schema.Dropdown(
            id = "league_name",
            name = "League Name",
            desc = "Choose the appropriate league",
            icon = "gear",
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

print("     ")
print("---------------TOP OF FILE END---------------")
print("     ")

"""
Applet: LOL Stats
Summary: Shows LOL summoner stats
Description: Displays League of Legends summoner wins/loss status, rank and recent match kda, champ, gold and minions. Also lists win/losses sequence of the most recent matches.
Author: thiagoss
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

PLAYER_FONT = "6x10-rounded"
RANK_FONT = "tom-thumb"
WL_FONT = "tom-thumb"
LAST_MATCH_FONT = "tom-thumb"

ACCOUNT_PATH = "/riot/account/v1/accounts/by-riot-id/"
STATS_PATH = "/lol/league/v4/entries/by-puuid/"
MATCHES_PATH = "/lol/match/v5/matches/by-puuid/"
MATCH_PATH = "/lol/match/v5/matches/"

DEFAULT_QUEUE = "solo"
DEFAULT_REGION = "NA1"

# TODO to add once RIOT API key is approved
ENCRYPTED_API_KEY = ""

# standard components:
win = render.Text(content = "W", color = "#00FF00", font = WL_FONT)
loss = render.Text(content = "L", color = "#FF0000", font = WL_FONT)
horizontal_rule = render.Box(
    height = 1,
    color = "#555",
)

# Some LOL famous players:
famous_players = [
    struct(name = "Faker", summoner_name = "Hide on bush", tag_line = "KR1", region = "KR"),
    struct(name = "Viper", summoner_name = "Blue", tag_line = "KR33", region = "KR"),
    struct(name = "Agurin", summoner_name = "NAgurin", tag_line = "EU1", region = "NA1"),
    struct(name = "Nemesis", summoner_name = "LR Nemesis", tag_line = "LRAT", region = "EUW1"),
    struct(name = "KatEvolved", summoner_name = "KatEvolved", tag_line = "666", region = "NA1"),
    struct(name = "BrokenBlade", summoner_name = "G2 BrokenBlade", tag_line = "1819", region = "NA1"),
    struct(name = "Rekkles", summoner_name = "LR Rekkles", tag_line = "SUP", region = "EUW1"),
    struct(name = "Jankos", summoner_name = "Jankos", tag_line = "MYBAD", region = "EUW1"),
    struct(name = "Baus", summoner_name = "Thebausffs", tag_line = "COOL", region = "EUW1"),
]

def random_famous_player():
    selection_index = random.number(0, len(famous_players) - 1)
    return famous_players[selection_index]

def main(config):
    random.seed(time.now().unix // 15)

    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("apikey", "")
    if not api_key:
        return render_error(
            title = "No API key",
            msg = "Please set the API key in the app settings. You can obtain it from the RIOT developer portal.",
        )

    configured_queue = config.str("queue", DEFAULT_QUEUE)
    configured_summoner = config.str("gamename", "")
    tag_line = config.str("tagline", "")
    region = config.str("region", "")

    summoner = struct(name = configured_summoner, summoner_name = configured_summoner, tag_line = tag_line, region = region)

    if summoner.summoner_name == "":
        summoner = random_famous_player()

    # player uuid from RIOT API - use it to fetch the data we need from the player
    resp, puuid = fetch_puuid(summoner, api_key)
    if puuid == None:
        title = "Error fetching player"
        if resp == 404:
            msg = "Player not found. Please check the summoner name, tagline and region."
        elif resp == 401:
            msg = "Unauthorized. Please check your API key and ensure it is valid."
        else:
            msg = "An error occurred while fetching player data. Please try again later. Err: %s" % resp

        return render_error(title, msg)
    resp, summoner_stats = fetch_summoner_stats(puuid, summoner.region, configured_queue, api_key)
    if resp != 200:
        title = "Error fetching summoner stats"
        if summoner_stats == {}:
            msg = "No data found for queue: %s. Please check the queue type (solo/flex) and try again." % configured_queue
        else:
            msg = "An error occurred while fetching player stats. Please try again later. Err: %s" % resp
        return render_error(title, msg)

    resp, match_ids = fetch_match_ids(puuid, summoner.region, configured_queue, api_key)
    matches_error_msg = ""
    match_results = []
    if resp != 200:
        matches_error_msg = "An error occurred while fetching match IDs. Please try again later. Err: %s" % resp
    else:
        match_status_and_results = [fetch_match_data(puuid, summoner.region, id, api_key) for id in match_ids[0:17]]
        error_code = 200
        for m in match_status_and_results:
            if m[0] == 200:
                match_results.append(m[1])
            else:
                # print error but continue processing with the data we got
                print("Error fetching match data for match ID: %s, Error: %s" % (m[1].get("gameId", "Unknown"), m[0]))
                error_code = m[0]
                matches_error_msg = "An error occurred while fetching match data. Please try again later. Err: %s" % m[0]

        # if all are errors
        if len(match_results) == 0 and error_code != 200:
            matches_error_msg = "An error occurred while fetching match data. Please try again later. Err: %s" % error_code

    player_row = render_player_row(summoner.summoner_name, summoner_stats)
    total_win_losses_row = render.Padding(
        pad = (0, 1, 0, 0),
        child = render_total_win_losses_row(summoner_stats),
    )

    if matches_error_msg:
        last_match_row = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Text(
                content = "Error fetching matches",
                font = LAST_MATCH_FONT,
                color = "#FF0000",
            ),
        )
        match_sequence_row = render.Marquee(
            child = render.Text(
                content = matches_error_msg,
                font = LAST_MATCH_FONT,
                color = "#999999",
            ),
            width = 64,
            delay = 12,
        )
    elif len(match_results) > 0:
        last_match_row = render.Padding(
            pad = (0, 1, 0, 0),
            child = render_match(match_results[0]),
        )
        match_sequence_row = render_match_sequence_row(match_results[1:])
    else:
        last_match_row = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Text(
                content = "No matches found",
                font = LAST_MATCH_FONT,
                color = "#FF0000",
            ),
        )
        match_sequence_row = render.Row(
            children = [],
        )

    return render.Root(
        child = render.Column(
            children = [
                player_row,
                horizontal_rule,
                total_win_losses_row,
                horizontal_rule,
                last_match_row,
                match_sequence_row,
            ],
        ),
    )

def render_error(title, msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    delay = 12,
                    child = render.Text(
                        content = title,
                        color = "#FF0000",
                        font = PLAYER_FONT,
                    ),
                ),
                render.Marquee(
                    width = 64,
                    delay = 12,
                    child = render.Text(
                        content = msg,
                        font = WL_FONT,
                    ),
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = horizontal_rule,
                ),
                render.Padding(
                    pad = (0, 8, 0, 0),
                    child = render.Text(
                        content = "== LOL Stats. ==",
                        font = WL_FONT,
                        color = "#AAAAAA",
                    ),
                ),
            ],
        ),
    )

def queue_name(q):
    if q == "RANKED_SOLO_5x5":
        return "solo"
    if q == "RANKED_FLEX_SR":
        return "flex"
    return ""

def queue_id(q):
    if q == "solo":
        return 420
    if q == "flex":
        return 440
    return ""

def tier_color(tier):
    colors = {
        "IRON": "#8B4513",
        "BRONZE": "#CD7F32",
        "SILVER": "#C0C0C0",
        "GOLD": "#FFD700",
        "PLATINUM": "#E5E4E2",
        "EMERALD": "#50C878",
        "DIAMOND": "#B9F2FF",
        "MASTER": "#D3D3D3",
        "GRANDMASTER": "#FF4500",
        "CHALLENGER": "#FFFC77",
    }
    return colors.get(tier, "#FFFFFF")  # Default to white if tier not found

def tier_short_name(tier):
    if tier == "IRON":
        return "I"
    if tier == "BRONZE":
        return "B"
    if tier == "SILVER":
        return "S"
    if tier == "GOLD":
        return "G"
    if tier == "PLATINUM":
        return "P"
    if tier == "DIAMOND":
        return "D"
    if tier == "MASTER":
        return "M"
    if tier == "GRANDMASTER":
        return "GM"
    if tier == "CHALLENGER":
        return "C"
    return "-"

def render_player_row(summoner, summoner_stats):
    tier = summoner_stats["tier"]
    rank = summoner_stats["rank"]
    tier_sn = tier_short_name(tier)
    return render.Row(
        children = [
            render.Marquee(
                width = 42,
                delay = 12,
                child = render.Text(summoner, height = 10, font = PLAYER_FONT),
            ),
            render.Box(
                height = 11,
                child = render.Text(
                    content = tier_sn + " " + rank,
                    font = RANK_FONT,
                    color = tier_color(tier),
                    offset = 0,
                ),
            ),
        ],
    )

def render_total_win_losses_row(summoner_stats):
    wins = summoner_stats["wins"]
    losses = summoner_stats["losses"]
    points = summoner_stats["leaguePoints"]
    return render.Row(
        children = [
            render.Text("W:", font = WL_FONT),
            render.Text(str(int(wins)), font = WL_FONT, color = "#00FF00"),
            render.Text(" ", font = WL_FONT),
            render.Text("L:", font = WL_FONT),
            render.Text(str(int(losses)), font = WL_FONT, color = "#FF0000"),
            render.Text(" ", font = WL_FONT),
            render.Text("LP:", font = WL_FONT),
            render.Text(str(int(points)), font = WL_FONT, color = "#FFFF00"),
        ],
    )

def render_match(match_data):
    animation_children = []

    kda_row = render.Row(
        children = [
            render.Text(
                content = "%d" % (match_data["kills"]),
                font = LAST_MATCH_FONT,
            ),
            render.Text(
                content = "/",
                font = LAST_MATCH_FONT,
                color = "#999999",
            ),
            render.Text(
                content = "%d" % (match_data["deaths"]),
                font = LAST_MATCH_FONT,
            ),
            render.Text(
                content = "/",
                font = LAST_MATCH_FONT,
                color = "#999999",
            ),
            render.Text(
                content = "%d" % (match_data["assists"]),
                font = LAST_MATCH_FONT,
            ),
        ],
    )

    champ_row = render.Row(
        children = [
            render.Text(
                content = match_data["champion"],
                font = LAST_MATCH_FONT,
                color = "#AAAA00",
            ),
            render.Text(
                content = " ",
                font = LAST_MATCH_FONT,
            ),
        ],
    )

    gold_row = render.Row(
        children = [
            render.Text(
                content = str(match_data["goldEarned"]),
                font = LAST_MATCH_FONT,
                color = "#FFD700",
            ),
            render.Text(
                content = " ",
                font = LAST_MATCH_FONT,
            ),
            render.Text(
                content = str(match_data["totalMinionsKilled"]),
                font = LAST_MATCH_FONT,
                color = "#00FFFF",
            ),
        ],
    )

    for _ in range(60):
        animation_children.append(kda_row)
    for _ in range(60):
        animation_children.append(champ_row)
    for _ in range(60):
        animation_children.append(gold_row)

    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Text(
                        content = "Last:",
                        font = LAST_MATCH_FONT,
                    ),
                    win if match_data["win"] else loss,
                    render.Text(
                        content = " ",
                        font = LAST_MATCH_FONT,
                    ),
                    render.Sequence(
                        children = [
                            render.Animation(
                                children = animation_children,
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def render_match_sequence_row(match_results):
    matches_row_children = []
    for r in match_results:
        if r["win"]:
            matches_row_children.append(win)
        else:
            matches_row_children.append(loss)
    return render.Row(
        children = matches_row_children,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "gamename",
                name = "Game Name",
                desc = "Game name (summoner name).",
                icon = "user",
            ),
            schema.Text(
                id = "tagline",
                name = "Tag Line",
                desc = "tagline (e.g NA1).",
                icon = "user",
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Region for the summoner.",
                icon = "globe",
                options = [
                    schema.Option(display = "North America", value = "NA1"),
                    schema.Option(display = "Europe West", value = "EUW1"),
                    schema.Option(display = "Europe Nordic & East", value = "EUN1"),
                    schema.Option(display = "Korea", value = "KR"),
                    schema.Option(display = "Brazil", value = "BR1"),
                    schema.Option(display = "Middle East", value = "ME1"),
                    schema.Option(display = "Latin America 1", value = "LA1"),
                    schema.Option(display = "Latin America 2", value = "LA2"),
                    schema.Option(display = "Japan", value = "JP1"),
                    schema.Option(display = "Oceania", value = "OC1"),
                    schema.Option(display = "Singapore", value = "SG2"),
                    schema.Option(display = "Turkey", value = "TR1"),
                    schema.Option(display = "Russia", value = "RU"),
                    schema.Option(display = "Vietnam", value = "VN2"),
                    schema.Option(display = "Taiwan", value = "TW2"),
                ],
                default = "NA1",
            ),
            schema.Dropdown(
                id = "queue",
                name = "Solo or flex?",
                desc = "show solo or flex queue?.",
                icon = "usersLine",
                options = [
                    schema.Option(display = "Solo", value = "solo"),
                    schema.Option(display = "Flex", value = "flex"),
                ],
                default = "solo",
            ),
            schema.Text(
                id = "apikey",
                name = "API Key",
                desc = "Riot Games API key. (ideally we have a production key - if not, use your own dev key)",
                icon = "key",
            ),
        ],
    )

def routing_domain(region):
    # Ideally we use geolocation to decide the best routing - for now just use the summoner region
    if region in ["NA1", "BR1", "LA1", "LA2", "TR1", "RU"]:
        return "https://americas.api.riotgames.com"
    elif region in ["EUW1", "EUN1"]:
        return "https://europe.api.riotgames.com"
    elif region in ["KR", "JP1", "OC1", "SG2", "ME1", "VN2", "TW2"]:
        return "https://asia.api.riotgames.com"
    else:
        #default to americas if region is not recognized
        print("Warning: Unsupported region %s, defaulting to americas.api.riotgames.com" % region)
        return "https://americas.api.riotgames.com"

def region_domain(region):
    return "https://" + region.lower() + ".api.riotgames.com"

# === RIOT API Fetching Functions
def fetch_puuid(summoner, api_key):
    account_url = routing_domain(summoner.region) + ACCOUNT_PATH + summoner.summoner_name + "/" + summoner.tag_line
    account_rep = http.get(account_url, headers = {"X-Riot-Token": api_key}, ttl_seconds = 60 * 60 * 10)
    if account_rep.status_code == 200:
        return 200, account_rep.json()["puuid"]
    return account_rep.status_code, None

def fetch_summoner_stats(puuid, region, configured_queue, api_key):
    stats_url = region_domain(region) + STATS_PATH + puuid
    stats_rep = http.get(stats_url, headers = {"X-Riot-Token": api_key}, ttl_seconds = 600)
    if stats_rep.status_code != 200:
        return stats_rep.status_code, None
    for d in stats_rep.json():
        queue = queue_name(d["queueType"])
        if queue == configured_queue:
            return 200, d
    return 200, {}

def fetch_match_ids(puuid, region, configured_queue, api_key):
    queue_filter = queue_id(configured_queue)
    match_url = routing_domain(region) + MATCHES_PATH + puuid + "/ids?queue=" + str(queue_filter)
    matches_rep = http.get(match_url, headers = {"X-Riot-Token": api_key}, ttl_seconds = 600)
    if matches_rep.status_code != 200:
        return matches_rep.status_code, []
    match_ids = matches_rep.json()
    return 200, match_ids

def fetch_match_data(puuid, region, match_id, api_key):
    match_details_url = routing_domain(region) + MATCH_PATH + match_id
    match_details_rep = http.get(match_details_url, headers = {"X-Riot-Token": api_key}, ttl_seconds = 60 * 60 * 10)
    if match_details_rep.status_code != 200:
        return match_details_rep.status_code, {}
    match_data = match_details_rep.json()
    for participant in match_data.get("info", {}).get("participants", []):
        if participant.get("puuid") == puuid:
            return 200, {
                "gameId": match_data.get("metadata", {}).get("matchId"),
                "champion": participant.get("championName"),
                "win": participant.get("win"),
                "kills": participant.get("kills"),
                "deaths": participant.get("deaths"),
                "assists": participant.get("assists"),
                "goldEarned": int(participant.get("goldEarned")),
                "totalMinionsKilled": int(participant.get("totalMinionsKilled")),
                "totalDamageDealtToChampions": int(participant.get("totalDamageDealtToChampions")),
                "totalDamageTaken": int(participant.get("totalDamageTaken")),
            }
    return 200, {}

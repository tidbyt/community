"""
Applet: Chess Viewer
Summary: Shows Active Chess Games
Description: This app shows a visual representation of currently active chess games for a given user on Chess.com.
Author: Neal Wright
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# Get all games for a given player ID
def get_player_games(username):
    games_url = "https://api.chess.com/pub/player/{}/games".format(username)
    req = http.get(
        url = games_url,
    )
    if req.status_code != 200:
        fail("Chess.com request failed with status %d", req.status_code)

    return req.json()

def parse_pgn(game_pgn):
    pgn_dict = {}
    pgn_array = game_pgn.split("\n")
    for entry in pgn_array:
        entry_array = entry.split(" ", 1)
        entry_array[0] = entry_array[0][1:].lower()
        if len(entry_array) > 1:
            entry_array[1] = entry_array[1][1:-2]
            pgn_dict[entry_array[0]] = entry_array[1]
    return pgn_dict

def get_games_dict(games_json):
    games_dict = {}
    for game in games_json['games']:
        pgn_dict = parse_pgn(game['pgn'])
        games_dict['white'] = pgn_dict['white']
        games_dict['black'] = pgn_dict['black']
        games_dict['fen'] = game['fen']
    return games_dict

def main(config):
    username = config.get("username", "nealosan")
    games_json = get_player_games(username)
    games_dict = get_games_dict(games_json)
    print(games_dict)
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

# Set up options for Username entry
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Chess.com Username to use",
                icon = "user",
            ),
        ],
    )
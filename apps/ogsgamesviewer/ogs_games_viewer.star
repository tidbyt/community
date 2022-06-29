"""
Applet: OGS Games Viewer
Summary: Shows OGS Games
Description: Shows a visualization of currently active Go games on OGS (Online Go Server) for a given user.
Author: Neal Wright
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NUM_OF_GAMES = 5
FRAMES = 50

# Sort moves by axis instead of by move number
def sort_moves(moves):
    moves_dict = {}
    turn_dict = {
        "b": "w",
        "w": "b",
    }
    turn = "b"
    for move in moves:
        move_key = "{},{}".format(int(move[0] + 1), int(move[1] + 1))
        moves_dict[move_key] = turn
        turn = turn_dict[turn]
    return moves_dict

# Query the API for the ID of a given username
def get_player_id_by_username(username):
    PLAYER_ID_URL = "https://online-go.com/api/v1/players?username={}".format(username)
    req = http.get(
        url = PLAYER_ID_URL,
    )

    if req.status_code != 200:
        fail("OGS request failed with status %d", req.status_code)

    if len(req.json()["results"]) > 0:
        player_info = req.json()["results"][0]
        player_id = int(player_info["id"])
        return player_id
    else:
        return False

# Get all games for a given player ID
def get_player_games(player_id):
    games_url = "https://online-go.com/api/v1/players/{}/games?ended__isnull=true&ordering=-ended&page_size={}".format(player_id, NUM_OF_GAMES)
    req = http.get(
        url = games_url,
    )
    if req.status_code != 200:
        fail("OGS request failed with status %d", req.status_code)

    return req.json()["results"]

def get_game_state(game_id):
    state_url = "https://online-go.com/termination-api/game/{}/state".format(game_id)
    state_req = http.get(
        url = state_url,
    )
    if state_req.status_code != 200:
        fail("OGS request failed with status %d", state_req.status_code)
    board_state = state_req.json()
    return board_state["board"]

# Get the details for each of a player's games
def get_games_info(games, player_id):
    games_info = []
    for game in games:
        detail = game["related"]["detail"]
        game_id = int(game["id"])
        board_state = get_game_state(game_id)
        game_url = "https://online-go.com{}".format(detail)
        game_req = http.get(
            url = game_url,
        )
        if game_req.status_code != 200:
            fail("OGS request failed with status %d", game_req.status_code)
        game_json = game_req.json()
        width = int(game_json["width"])
        height = int(game_json["height"])
        if (width != height and
            width != 19 and
            width != 13 and
            width != 9):
            continue
        if game_json["players"]["black"]["id"] == player_id:
            opponent = game_json["players"]["white"]["username"]
            opp_color = "w"
        else:
            opponent = game_json["players"]["black"]["username"]
            opp_color = "b"
        games_info.append({
            "moves": game_json["gamedata"]["moves"],
            "opponent": opponent,
            "opp_color": opp_color,
            "state": board_state,
            "width": width,
            "height": height,
        })
    return games_info

# Initialize a dictionary with all of the board coordinates
def init_coords():
    coords = {}
    for x in range(1, 28):
        for y in range(1, 28):
            coord_string = "{},{}".format(x, y)
            coords[coord_string] = ""
    return coords

# Using the populated coordinates object, create the graphics for
# the current board state
def draw_game_board(coords, width, height):
    game_board = []
    game_columns = []
    total_width = width + 4
    total_height = height + 4
    board_max_width = width + 3
    board_max_height = height + 3
    for y in range(0, total_height):
        this_row = []
        for x in range(0, total_width):
            if x == 0 or x == board_max_width or y == 0 or y == board_max_height:
                this_color = "#D19A34"
            elif x == 1 or x == (board_max_width - 1) or y == 1 or y == (board_max_height - 1):
                this_color = "#222222"
            else:
                coord_string = "{},{}".format(x - 1, y - 1)
                if coords[coord_string] == "b":
                    this_color = "#000000"
                elif coords[coord_string] == "w":
                    this_color = "#ffffff"
                else:
                    this_color = "#D19A34"
            this_row.append(
                render.Box(
                    width = 1,
                    height = 1,
                    color = this_color,
                ),
            )
        game_columns.append(render.Row(
            children = this_row,
        ))
    game_board = render.Box(
        width = total_width,
        height = total_height,
        child = render.Column(
            children = game_columns,
        ),
    )
    return game_board

# Draw a box with the board, stone color, and opponent name
def draw_game_box(game_board, game_info):
    game_box = []
    game_box.append(
        render.Box(
            width = 4,
            height = 32,
            color = "#000000",
        ),
    )
    game_box.append(game_board)
    opponent = game_info["opponent"]
    if game_info["opp_color"] == "b":
        stone = render.Circle(
            color = "#ffffff",
            diameter = 6,
            child = render.Circle(
                color = "#000000",
                diameter = 4,
            ),
        )
    else:
        stone = render.Circle(
            color = "#ffffff",
            diameter = 6,
        )
    game_box.append(render.Box(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        stone,
                        render.Box(
                            width = 6,
                            height = 6,
                            color = "#000000",
                        ),
                        render.Text(
                            content = "({})".format(game_info["opp_color"]),
                            color = "#ffffff",
                        ),
                    ],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Marquee(
                    child = render.Text(
                        content = "{}".format(opponent),
                        color = "#ffffff",
                    ),
                    width = 30,
                ),
            ],
        ),
        width = 42,
        height = 32,
    ))
    return game_box

# Draw the frames for the final animation
def draw_games_graphics(game_boxes):
    games_graphics = []
    for game_box in game_boxes:
        for i in range(0, FRAMES):
            games_graphics.append(render.Box(
                child = render.Row(
                    main_align = "start",
                    cross_align = "center",
                    children = game_box,
                    expanded = True,
                ),
                width = 64,
                height = 32,
            ))
    return games_graphics

def draw_username_not_found():
    return render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "OGS username",
                    color = "#ffffff",
                ),
                render.Text(
                    content = "not found!",
                    color = "#ffffff",
                ),
            ],
            main_align = "center",
            cross_align = "center",
        ),
    )

def draw_no_games():
    return render.Box(
        child = render.Column(
            children = [
                render.Text(
                    content = "No active",
                    color = "#ffffff",
                ),
                render.Text(
                    content = "games found!",
                    color = "#ffffff",
                ),
            ],
            main_align = "center",
            cross_align = "center",
        ),
    )

def main(config):
    USERNAME = config.get("username", "")
    cached_user = cache.get("username")

    # If a username has not been set, show a
    # "Username not found" message
    if USERNAME == "":
        not_found_graphics = draw_username_not_found()
        return render.Root(
            child = not_found_graphics,
        )

    # If a new Username has been set in the options, reset the games cache
    # and pull a new player_id
    if cached_user == None:
        cached_user = cache.set("username", USERNAME, ttl_seconds = 240)
        PLAYER_ID = get_player_id_by_username(USERNAME)
        cached_player_id = cache.set("player_id", str(PLAYER_ID), ttl_seconds=240 )
        games_cache = None
    elif USERNAME != cached_user:
        cached_user = cache.set("username", USERNAME, ttl_seconds = 240)
        PLAYER_ID = get_player_id_by_username(USERNAME)
        cached_player_id = cache.set("player_id", str(PLAYER_ID), ttl_seconds=240 )
        games_cache = None
    else:
        PLAYER_ID = cache.get("player_id")
        games_cache = cache.get("games")

    # Get the player ID and game details from the API
    # If the API didn't return a player ID, show a message
    if PLAYER_ID == False:
        not_found_graphics = draw_username_not_found()
        return render.Root(
            child = not_found_graphics,
        )

    # If there is an existing games cache, pull info from the cache
    # otherwise, pull in new games and cache them
    if games_cache != None:
        games = json.decode(games_cache)
    else:
        games = get_player_games(PLAYER_ID)
        cache.set("games", json.encode(games), ttl_seconds = 240)

    # Get details about each game
    games_info = get_games_info(games, PLAYER_ID)

    if len(games) == 0:
        no_games_graphics = draw_no_games()
        return render.Root(
            child = no_games_graphics,
        )

    games_graphics = []
    game_boxes = []

    # Get the board state for each game and draw the game graphics
    for game_info in games_info:
        # Sort moves in spacially instead of by move number
        state = game_info["state"]
        coords = init_coords()
        for (y, row) in enumerate(game_info["state"], 1):
            for (x, column) in enumerate(row, 1):
                move_string = "{},{}".format(x, y)
                if column > 0:
                    if column == 1:
                        coords[move_string] = "b"
                    else:
                        coords[move_string] = "w"
        game_board = draw_game_board(coords, game_info["width"], game_info["height"])
        game_box = draw_game_box(game_board, game_info)
        game_boxes.append(game_box)

    # Create the final animation and render it
    games_graphics = draw_games_graphics(game_boxes)
    return render.Root(
        child = render.Animation(
            children = games_graphics,
        ),
    )

# Set up options for Username entry
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "OGS Username to use",
                icon = "user",
            ),
        ],
    )

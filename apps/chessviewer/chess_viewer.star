"""
Applet: Chess Viewer
Summary: Shows Active Chess Games
Description: This app shows a visual representation of currently active chess games for a given user on Chess.com.
Author: Neal Wright
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

### CONSTANTS ###

# Schema Dropdown Options #
# ----------------------- #
BOARD_THEME_OPTIONS = [
    schema.Option(
        display = "Autumn",
        value = "autumn",
    ),
    schema.Option(
        display = "Spring",
        value = "spring",
    ),
    schema.Option(
        display = "Summer",
        value = "summer",
    ),
    schema.Option(
        display = "Winter",
        value = "winter",
    ),
]
PIECE_THEME_OPTIONS = [
    schema.Option(
        display = "Minim",
        value = "minim",
    ),
    schema.Option(
        display = "Block",
        value = "block",
    ),
    schema.Option(
        display = "Dot",
        value = "dot",
    ),
    schema.Option(
        display = "Point",
        value = "point",
    ),
]

# Application Constants #
# --------------------- #
ANIMATION_FRAMES = 60
PIECE_CHARS = "pPnNbBrRqQkK"
PIECE_COUNTS = {
    "p": {
        "count": 8,
        "value": 1,
    },
    "n": {
        "count": 2,
        "value": 3,
    },
    "b": {
        "count": 2,
        "value": 3,
    },
    "r": {
        "count": 2,
        "value": 5,
    },
    "q": {
        "count": 1,
        "value": 9,
    },
}

# Color Constants #
# --------------- #
BOARD_COLORS = {
    "summer": {
        "board_color_1": "#8d1c1c",
        "board_color_2": "#ff8f00",
        "king_color": "#40ff2b",
    },
    "spring": {
        "board_color_1": "#1b872e",
        "board_color_2": "#5bc66f",
        "king_color": "#ff5a35",
    },
    "autumn": {
        "board_color_1": "#a35c26",
        "board_color_2": "#c89169",
        "king_color": "#ffa80b",
    },
    "winter": {
        "board_color_1": "#0064c1",
        "board_color_2": "#48cfea",
        "king_color": "#e80404",
    },
}
MATERIAL_COUNT_COLOR = "#8ec24c"
PAWN_COLORS = {
    "w": [
        "",
        "#ffeb96",
        "#ffffff",
        "#fff6e0",
    ],
    "b": [
        "",
        "#484848",
        "#ffffff",
        "#6d6d6d",
    ],
}
PIECE_WHITE = "#ffffff"
PIECE_BLACK = "#000000"

# Graphics Constants #
# ------------------ #
PAWN_MATRIX = [
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 3, 2, 2, 1, 0, 0],
    [0, 0, 3, 2, 1, 1, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 3, 2, 1, 1, 0, 0],
    [0, 3, 2, 1, 1, 1, 1, 0],
]
PIECE_GRAPHICS = {
    "p": {
        "minim": [
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 0, 0, 0],
        ],
        "block": [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "dot": [
            [0, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ],
        "point": [
            [1, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ],
    },
    "n": {
        "minim": [
            [0, 0, 0, 0],
            [0, 1, 1, 1],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
        ],
        "block": [
            [0, 0, 0, 0],
            [0, 1, 1, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
        ],
        "dot": [
            [0, 0, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 0],
        ],
        "point": [
            [1, 1, 0, 0],
            [1, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ],
    },
    "b": {
        "minim": [
            [0, 0, 0, 1],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [1, 0, 0, 0],
        ],
        "block": [
            [0, 1, 1, 0],
            [1, 0, 0, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "dot": [
            [0, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 0],
        ],
        "point": [
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 0],
        ],
    },
    "r": {
        "minim": [
            [1, 0, 0, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "block": [
            [1, 0, 0, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "dot": [
            [0, 1, 0, 0],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [0, 0, 0, 0],
        ],
        "point": [
            [1, 1, 1, 0],
            [1, 1, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ],
    },
    "q": {
        "minim": [
            [1, 0, 0, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [1, 0, 0, 1],
        ],
        "block": [
            [1, 0, 0, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
            [1, 0, 0, 1],
        ],
        "dot": [
            [0, 1, 1, 0],
            [0, 1, 1, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "point": [
            [1, 1, 1, 0],
            [1, 1, 1, 0],
            [1, 1, 1, 0],
            [0, 0, 0, 0],
        ],
    },
    "k": {
        "minim": [
            [0, 1, 1, 0],
            [1, 2, 2, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "block": [
            [0, 1, 1, 0],
            [1, 2, 2, 1],
            [0, 1, 1, 0],
            [0, 1, 1, 0],
        ],
        "dot": [
            [0, 1, 1, 0],
            [2, 1, 1, 2],
            [2, 1, 1, 2],
            [0, 1, 1, 0],
        ],
        "point": [
            [1, 1, 1, 0],
            [1, 1, 1, 0],
            [1, 1, 1, 0],
            [0, 0, 0, 2],
        ],
    },
    " ": [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
}

# Famous Games #
# ------------ #
# To show when username is empty #
FAMOUS_GAMES = [
    {
        "white": "V. Topalov",
        "black": "A. Shirov",
        "turn": "white",
        "board_state": [
            [" ", " ", " ", " ", " ", " ", " ", " "],
            [" ", " ", " ", " ", " ", " ", " ", " "],
            [" ", " ", " ", " ", "k", "p", "p", " "],
            [" ", " ", " ", "p", " ", " ", " ", " "],
            ["p", " ", " ", " ", " ", " ", " ", " "],
            [" ", " ", "B", " ", " ", " ", " ", "b"],
            [" ", " ", " ", " ", " ", " ", "P", " "],
            [" ", " ", " ", " ", " ", " ", "K", " "],
        ],
        "material": {
            "black_material": 2,
            "white_material": 0,
        },
    },
    {
        "white": "R. Meier",
        "black": "S. Muller",
        "turn": "black",
        "board_state": [
            [" ", " ", "r", "q", " ", " ", "k", "b"],
            ["p", "b", "Q", "r", " ", " ", " ", "p"],
            [" ", " ", "n", " ", "R", " ", "p", "B"],
            [" ", "p", "p", " ", " ", "p", "N", " "],
            [" ", " ", " ", "p", " ", " ", " ", " "],
            ["P", " ", "P", "P", " ", " ", "P", " "],
            [" ", "P", " ", " ", " ", "P", "B", "P"],
            [" ", " ", " ", " ", "R", " ", "K", " "],
        ],
        "material": {
            "black_material": 0,
            "white_material": 0,
        },
    },
    {
        "white": "S. Levitsky",
        "black": "F. J. Marshall",
        "turn": "white",
        "board_state": [
            [" ", " ", " ", " ", " ", "r", "k", " "],
            ["p", "p", " ", " ", " ", " ", "p", "p"],
            [" ", " ", " ", " ", "p", " ", " ", " "],
            [" ", " ", "R", " ", " ", " ", "Q", " "],
            [" ", " ", " ", "n", " ", " ", " ", " "],
            [" ", " ", " ", " ", " ", " ", "q", "r"],
            ["P", " ", "P", " ", " ", "P", "P", "P"],
            [" ", " ", " ", " ", " ", "R", "K", " "],
        ],
        "material": {
            "black_material": 3,
            "white_material": 0,
        },
    },
    {
        "white": "E. Y. Vladimirov",
        "black": "V. V. Epishin",
        "turn": "black",
        "board_state": [
            ["r", " ", " ", " ", " ", "k", " ", "r"],
            [" ", "b", " ", " ", "b", "P", "R", " "],
            ["p", " ", " ", " ", " ", "n", " ", "B"],
            [" ", " ", " ", "p", " ", " ", " ", " "],
            [" ", " ", " ", " ", "P", " ", " ", "P"],
            [" ", "q", " ", " ", " ", " ", " ", "B"],
            ["P", "p", "P", " ", " ", " ", " ", " "],
            [" ", "K", " ", " ", " ", " ", "R", " "],
        ],
        "material": {
            "black_material": 10,
            "white_material": 0,
        },
    },
    {
        "white": "S. Flohr",
        "black": "E. Geller",
        "turn": "white",
        "board_state": [
            [" ", " ", " ", " ", " ", " ", " ", " "],
            [" ", " ", " ", " ", " ", " ", "k", "p"],
            [" ", " ", " ", " ", " ", " ", "p", " "],
            [" ", " ", " ", " ", "p", " ", " ", " "],
            ["p", " ", " ", " ", "r", "P", "R", "P"],
            [" ", " ", " ", "K", " ", " ", "P", " "],
            [" ", " ", " ", " ", " ", " ", " ", " "],
            [" ", " ", " ", " ", " ", " ", " ", " "],
        ],
        "material": {
            "black_material": 1,
            "white_material": 0,
        },
    },
]

### FUNCTIONS ###

# Graphics Functions #
# ------------------ #
def draw_game_board(board_theme):
    columns = []
    for col in range(0, 8):
        current_row = []
        for row in range(0, 8):
            if col & 1:
                if row & 1:
                    square_color = BOARD_COLORS[board_theme]["board_color_1"]
                else:
                    square_color = BOARD_COLORS[board_theme]["board_color_2"]
            elif row & 1:
                square_color = BOARD_COLORS[board_theme]["board_color_2"]
            else:
                square_color = BOARD_COLORS[board_theme]["board_color_1"]
            current_row.append(render.Box(
                width = 4,
                height = 4,
                color = square_color,
            ))
        columns.append(render.Row(
            children = current_row,
        ))
    return render.Box(
        width = 32,
        height = 32,
        child = render.Column(
            children = columns,
        ),
    )

def draw_piece(piece, piece_theme, board_theme):
    if piece.isupper():
        piece_color = PIECE_WHITE
    else:
        piece_color = PIECE_BLACK
    if piece.lower() == " ":
        piece_matrix = PIECE_GRAPHICS[piece.lower()]
    else:
        piece_matrix = PIECE_GRAPHICS[piece.lower()][piece_theme]
    piece_box_children = []
    for col in piece_matrix:
        piece_row = []
        for row in col:
            if row == 1:
                piece_row.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = piece_color,
                    ),
                )
            elif row == 2:
                piece_row.append(
                    render.Box(
                        width = 1,
                        height = 1,
                        color = BOARD_COLORS[board_theme]["king_color"],
                    ),
                )
            else:
                piece_row.append(
                    render.Box(
                        width = 1,
                        height = 1,
                    ),
                )
        piece_box_children.append(render.Row(
            children = piece_row,
        ))
    return render.Box(
        width = 4,
        height = 4,
        child = render.Column(
            children = piece_box_children,
        ),
    )

def draw_pieces(board_state, piece_theme, board_theme):
    pieces = []
    for col in range(0, 8):
        this_row = []
        for row in range(0, 8):
            piece = draw_piece(board_state[col][row], piece_theme, board_theme)
            this_row.append(piece)
        pieces.append(render.Row(
            children = this_row,
        ))
    columns = render.Column(
        children = pieces,
    )
    return render.Box(
        width = 32,
        height = 32,
        child = columns,
    )

def draw_pawn_image(color):
    pawn_columns = []
    for row in PAWN_MATRIX:
        pawn_row = []
        for square in row:
            pawn_row.append(render.Box(
                width = 1,
                height = 1,
                color = PAWN_COLORS[color][square],
            ))
        pawn_columns.append(
            render.Row(
                children = pawn_row,
            ),
        )
    pawn_box = render.Box(
        width = 8,
        height = 8,
        child = render.Column(
            children = pawn_columns,
        ),
    )
    return pawn_box

def draw_game_stats(opponent_name, opponent_color, material, turn):
    pawn_image = draw_pawn_image(opponent_color)
    opponent_text = render.Marquee(
        child = render.Text(
            font = "tb-8",
            content = opponent_name,
        ),
        width = 24,
    )
    white_material_w_text = "W: " if turn == "black" else "*W: "
    white_material_w = render.Text(
        content = white_material_w_text,
    )
    white_material_count = render.Text(
        content = "+{}".format(material["white_material"]),
        color = MATERIAL_COUNT_COLOR,
    )
    black_material_w_text = "B: " if turn == "white" else "*B: "
    black_material_b = render.Text(
        content = black_material_w_text,
    )
    black_material_count = render.Text(
        content = "+{}".format(material["black_material"]),
        color = MATERIAL_COUNT_COLOR,
    )
    top_row = render.Row(
        children = [
            white_material_w,
            white_material_count,
        ],
    )
    middle_row = render.Row(
        children = [
            pawn_image,
            opponent_text,
        ],
        expanded = True,
    )
    bottom_row = render.Row(
        children = [
            black_material_b,
            black_material_count,
        ],
    )
    padding_row = render.Box(
        width = 32,
        height = 2,
    )
    return render.Box(
        width = 32,
        height = 32,
        child = render.Column(
            children = [
                top_row,
                padding_row,
                middle_row,
                padding_row,
                bottom_row,
            ],
            cross_align = "center",
            main_align = "center",
        ),
    )

def draw_game_boxes(games, game_board, username, piece_theme, board_theme):
    game_boxes = []
    for game in games:
        game_pieces = draw_pieces(game["board_state"], piece_theme, board_theme)
        if game["white"].lower() != username.lower():
            opponent_color = "w"
            opponent_name = game["white"]
        else:
            opponent_color = "b"
            opponent_name = game["black"]
        game_board_stacked = render.Stack(
            children = [
                game_board,
                game_pieces,
            ],
        )
        game_stats = draw_game_stats(opponent_name, opponent_color, game["material"], game["turn"])
        for _ in range(0, ANIMATION_FRAMES):
            game_boxes.append(
                render.Box(
                    width = 64,
                    height = 32,
                    child = render.Row(
                        children = [
                            game_board_stacked,
                            game_stats,
                        ],
                    ),
                ),
            )
    return game_boxes

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

# Game Data Functions #
# ------------------- #

# Get all games for a given player ID
def get_player_games(username):
    games_url = "https://api.chess.com/pub/player/{}/games".format(username)
    req = http.get(
        url = games_url,
    )
    if req.status_code != 200:
        return False

    results = req.json()
    if results:
        return results
    else:
        return False

def get_fen_array(game_fen):
    fen_array = game_fen.split("/")
    end_array = fen_array[-1].split(" ")
    fen_array[-1] = end_array.pop(0)
    return fen_array

def get_board_state_array(game_fen):
    fen_array = get_fen_array(game_fen)
    board_state_array = []
    for row in fen_array:
        row_array = []
        for char in row.elems():
            if char in PIECE_CHARS:
                row_array.append(char)
            else:
                for _ in range(0, int(char)):
                    row_array.append(" ")
        board_state_array.append(row_array)
    return board_state_array

def get_material_count(board_state_array):
    counts = {
        "p": 0,
        "P": 0,
        "n": 0,
        "N": 0,
        "b": 0,
        "B": 0,
        "r": 0,
        "R": 0,
        "q": 0,
        "Q": 0,
    }
    white_material = 0
    black_material = 0
    for row in board_state_array:
        for square in row:
            if square:
                if square in counts:
                    counts[square] += 1
    for piece in counts:
        if piece in PIECE_COUNTS:
            deficit = PIECE_COUNTS[piece]["count"] - counts[piece]
            if piece.isupper():
                white_material += deficit * (PIECE_COUNTS[piece]["value"])
            else:
                black_material += deficit * (PIECE_COUNTS[piece]["value"])
    if black_material > white_material:
        black_material -= white_material
        white_material = 0
    else:
        white_material -= black_material
        black_material = 0
    return {
        "white_material": white_material,
        "black_material": black_material,
    }

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

def get_games_dicts(games_json):
    games_dict = []
    for game in games_json["games"]:
        this_game_dict = {}
        pgn_dict = parse_pgn(game["pgn"])
        board_state_array = get_board_state_array(game["fen"])
        this_game_dict["white"] = pgn_dict["white"]
        this_game_dict["black"] = pgn_dict["black"]
        this_game_dict["turn"] = game["turn"]
        this_game_dict["board_state"] = board_state_array
        this_game_dict["material"] = get_material_count(board_state_array)
        games_dict.append(this_game_dict)
    return games_dict

# Main Functions #
# ------------- #

def main(config):
    username = config.get("username", "")
    board_theme = config.get("board_theme", "summer")
    piece_theme = config.get("piece_theme", "minim")
    if username == "":
        games = FAMOUS_GAMES
    else:
        user_cache_key = "username_{}".format(username)
        games_cache_key = "games_{}".format(username)
        cached_user = cache.get(user_cache_key)
        if cached_user == None:
            cache.set(user_cache_key, "True", ttl_seconds = 3600)
        cached_games = cache.get(games_cache_key)
        if cached_games == None:
            games_json = get_player_games(username)
            if games_json == False:
                games = FAMOUS_GAMES
            else:
                cache.set(games_cache_key, json.encode(games_json), ttl_seconds = 240)
                games = get_games_dicts(games_json)
        else:
            games_json = json.decode(cached_games)
            games = get_games_dicts(games_json)
    if len(games) == 0:
        no_games_graphics = draw_no_games()
        return render.Root(
            child = no_games_graphics,
        )
    game_board = draw_game_board(board_theme)
    game_boxes = draw_game_boxes(games, game_board, username, piece_theme, board_theme)
    return render.Root(
        child = render.Animation(
            children = game_boxes,
        ),
    )

# Set up configuration options
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
            schema.Dropdown(
                id = "piece_theme",
                name = "Piece Theme",
                desc = "The design of the chess pieces.",
                icon = "chess",
                default = PIECE_THEME_OPTIONS[0].value,
                options = PIECE_THEME_OPTIONS,
            ),
            schema.Dropdown(
                id = "board_theme",
                name = "Board Theme",
                desc = "The design of the chess board.",
                icon = "chessBoard",
                default = BOARD_THEME_OPTIONS[0].value,
                options = BOARD_THEME_OPTIONS,
            ),
        ],
    )

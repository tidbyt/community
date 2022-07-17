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

ANIMATION_FRAMES = 40
PIECE_CHARS = 'pPnNbBrRqQkK'
BOARD_COLOR_1 = '#8d1c1c'
BOARD_COLOR_2 = '#ff8f00'
MATERIAL_COUNT_COLOR = '#8ec24c'
PIECE_WHITE = '#ffffff'
PIECE_BLACK = '#000000'
PIECE_GRAPHICS = {
    'p': [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0]
    ],
    'n': [
        [0, 0, 0, 0],
        [0, 1, 1, 1],
        [0, 1, 0, 0],
        [0, 1, 0, 0]
    ],
    'b': [
        [0, 0, 0, 1],
        [0, 0, 1, 0],
        [0, 1, 0, 0],
        [1, 0, 0, 0]
    ],
    'r': [
        [1, 0, 0, 1],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0]
    ],
    'q': [
        [1, 0, 0, 1],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [1, 0, 0, 1]
    ],
    'k': [
        [0, 1, 1, 0],
        [1, 1, 1, 1],
        [1, 1, 1, 1],
        [0, 1, 1, 0]
    ],
    '': [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0]
    ]
}
PIECE_COUNTS = {
    'p': {
        'count': 8,
        'value': 1
    },
    'n': {
        'count': 2,
        'value': 3
    },
    'b': {
        'count': 2,
        'value': 3
    },
    'r': {
        'count': 2,
        'value': 5
    },
    'q': {
        'count': 1,
        'value': 9
    }
}
PAWN_MATRIX = [
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 3, 2, 2, 1, 0, 0],
    [0, 0, 3, 2, 1, 1, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 3, 2, 1, 1, 0, 0],
    [0, 3, 2, 1, 1, 1, 1, 0]
]
PAWN_COLORS = {
    'w': [
        '',
        '#ffeb96',
        '#ffffff',
        '#fff6e0',
    ],
    'b': [
        '',
        '#484848',
        '#ffffff',
        '#6d6d6d'
    ],
}

# Get all games for a given player ID
def get_player_games(username):
    games_url = "https://api.chess.com/pub/player/{}/games".format(username)
    req = http.get(
        url = games_url,
    )
    if req.status_code != 200:
        fail("Chess.com request failed with status %d", req.status_code)

    return req.json()

def get_fen_array(game_fen):
    fen_array = game_fen.split('/')
    end_array = fen_array[-1].split(' ')
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
                for i in range(0, int(char)):
                    row_array.append('')
        board_state_array.append(row_array)
    return board_state_array

def get_material_count(board_state_array):
    counts = {
        'p': 0,
        'P': 0,
        'n': 0,
        'N': 0,
        'b': 0,
        'B': 0,
        'r': 0,
        'R': 0,
        'q': 0,
        'Q': 0,
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
            deficit = PIECE_COUNTS[piece]['count'] - counts[piece]
            if piece.isupper():
                white_material += deficit * (PIECE_COUNTS[piece]['value'])
            else:
                black_material += deficit * (PIECE_COUNTS[piece]['value'])
    return {
        'white_material': white_material,
        'black_material': black_material
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
    for game in games_json['games']:
        this_game_dict = {}
        pgn_dict = parse_pgn(game['pgn'])
        board_state_array = get_board_state_array(game['fen'])
        this_game_dict['white'] = pgn_dict['white']
        this_game_dict['black'] = pgn_dict['black']
        this_game_dict['board_state'] = board_state_array
        this_game_dict['material']= get_material_count(board_state_array)
        games_dict.append(this_game_dict)
    return games_dict

def draw_game_board():
    columns = []
    for col in range(0, 8):
        current_row = []
        for row in range(0, 8):
            if col & 1:
                if row & 1:
                    square_color = BOARD_COLOR_1
                else:
                    square_color = BOARD_COLOR_2
            else:
                if row & 1:
                    square_color = BOARD_COLOR_2
                else:
                    square_color = BOARD_COLOR_1
            current_row.append(render.Box(
                        width=4,
                        height=4,
                        color=square_color
                    ))
        columns.append(render.Row(
            children=current_row
        ))
    return render.Box(
        width=32,
        height=32,
        child=render.Column(
            children=columns
        )
    )

def draw_piece(piece):
    if piece.isupper():
        piece_color = PIECE_WHITE
    else:
        piece_color = PIECE_BLACK
    piece_matrix = PIECE_GRAPHICS[piece.lower()]
    piece_box_children = []
    for col in piece_matrix:
        piece_row = []
        for row in col:
            if row == 1:
                piece_row.append(
                    render.Box(
                        width=1,
                        height=1,
                        color=piece_color
                    )
                )
            else:
                piece_row.append(
                    render.Box(
                    width=1,
                    height=1
                    )
                )
        piece_box_children.append(render.Row(
            children=piece_row
        ))
    return render.Box(
        width=4,
        height=4,
        child=render.Column(
            children=piece_box_children
        )
    )

def draw_pieces(board_state):
    pieces = []
    for col in range(0, 8):
        this_row = []
        for row in range(0, 8):
            piece = draw_piece(board_state[col][row])
            this_row.append(piece)
        pieces.append(render.Row(
            children=this_row
        ))
    columns = render.Column(
            children=pieces
        )
    return render.Box(
        width=32,
        height=32,
        child=columns
    )

def draw_pawn_image(color):
    pawn_columns = []
    for row in PAWN_MATRIX:
        pawn_row = []
        for square in row:
            pawn_row.append(render.Box(
                width=1,
                height=1,
                color=PAWN_COLORS[color][square]
            ))
        pawn_columns.append(
            render.Row(
                children=pawn_row
            )
        )
    pawn_box = render.Box(
        width=8,
        height=8,
        child=render.Column(
            children=pawn_columns
        )
    )
    return pawn_box

def draw_game_stats(opponent_name, opponent_color, material):
    pawn_image = draw_pawn_image(opponent_color)
    opponent_text = render.Marquee(
        child=render.Text(
            font='tb-8',
            content=opponent_name
        ),
        width=24
    )
    white_material_w = render.Text(
        content='W: '
    )
    white_material_count = render.Text(
        content='+{}'.format(material['white_material']),
        color=MATERIAL_COUNT_COLOR
    )
    black_material_b = render.Text(
        content='B: '
    )
    black_material_count = render.Text(
        content='+{}'.format(material['black_material']),
        color=MATERIAL_COUNT_COLOR
    )
    top_row = render.Row(
        children = [
            white_material_w,
            white_material_count
        ]
    )
    middle_row = render.Row(
        children = [
            pawn_image,
            opponent_text
        ],
        expanded=True
    )
    bottom_row = render.Row(
        children=[
            black_material_b,
            black_material_count
        ]
    )
    padding_row = render.Box(
        width=32,
        height=2
    )
    return render.Box(
        width=32,
        height=32,
        child=render.Column(
            children=[
                top_row,
                padding_row,
                middle_row,
                padding_row,
                bottom_row
            ],
            cross_align='center',
            main_align='center'
        )
    )

def draw_game_boxes(games, game_board, username):
    game_boxes = []
    for game in games:
        game_pieces = draw_pieces(game['board_state'])
        if game['white'].lower() != username.lower():
            opponent_color = 'w'
            opponent_name = game['white']
        else:
            opponent_color = 'b'
            opponent_name = game['black']
        game_board_stacked = render.Stack(
            children=[
                game_board, game_pieces
            ]
        )
        game_stats = draw_game_stats(opponent_name, opponent_color, game['material'])
        for i in range(0, ANIMATION_FRAMES):
            game_boxes.append(
                render.Box(
                    width=64,
                    height=32,
                    child=render.Row(
                        children=[
                            game_board_stacked,
                            game_stats
                        ]
                    )
                )
            )
    return game_boxes


def main(config):
    username = config.get("username", "nealosan")
    games_json = get_player_games(username)
    games = get_games_dicts(games_json)
    game_board = draw_game_board()
    game_boxes = draw_game_boxes(games, game_board, username)
    return render.Root(
        child=render.Animation(
            children=game_boxes
        )
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
"""
Applet: Life
Summary: Conways Game of Life
Description: Runs a famous cellular automaton and animates the state on screen.
Author: dinosaursrarr
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ALIVE = 1
DEAD = 0
WIDTH = 64
HEIGHT = 32
APP_DURATION_MILLISECONDS = 15000
REFRESH_MILLISECONDS = 75

COLOURS = [
    schema.Option(display = "White", value = "#ffffff"),
    schema.Option(display = "Silver", value = "#c0c0c0"),
    schema.Option(display = "Gray", value = "#808080"),
    schema.Option(display = "Black", value = "#000000"),
    schema.Option(display = "Red", value = "#ff0000"),
    schema.Option(display = "Maroon", value = "#800000"),
    schema.Option(display = "Yellow", value = "#ffff00"),
    schema.Option(display = "Olive", value = "#808000"),
    schema.Option(display = "Lime", value = "#00ff00"),
    schema.Option(display = "Green", value = "#008000"),
    schema.Option(display = "Aqua", value = "#00ffff"),
    schema.Option(display = "Teal", value = "#008080"),
    schema.Option(display = "Blue", value = "#0000ff"),
    schema.Option(display = "Navy", value = "#000080"),
    schema.Option(display = "Fuchsia", value = "#ff00ff"),
    schema.Option(display = "Purple", value = "#800080"),
]

# Random starting point where every cell has equal chance
# of starting dead or alive.
def generate_board():
    return [
        [random.number(DEAD, ALIVE) for c in range(WIDTH)]
        for r in range(HEIGHT)
    ]

# Wrap around at the edges, so we are treating the board
# as a toroidal array. Seems appropriate when small.
def prev_row(row):
    if row == 0:
        return HEIGHT - 1
    return row - 1

def next_row(row):
    if row == HEIGHT - 1:
        return 0
    return row + 1

def prev_col(col):
    if col == 0:
        return WIDTH - 1
    return col - 1

def next_col(col):
    if col == WIDTH - 1:
        return 0
    return col + 1

# Key input to determining next state
def count_living_neighbours(board, row, col):
    living = 0
    for r in [prev_row(row), row, next_row(row)]:
        for c in [prev_col(col), col, next_col(col)]:
            if r == row and c == col:
                continue  # cells are not their own neighbours.
            living += board[r][c]
    return living

# Determine what happens to a given cell in the next generation,
# based on its current state and that of its neighbours.
def next_state(board, row, col):
    living_neighbours = count_living_neighbours(board, row, col)
    current_state = board[row][col]
    if current_state == ALIVE and living_neighbours in [2, 3]:
        return ALIVE
    if current_state == DEAD and living_neighbours == 3:
        return ALIVE
    return DEAD

# Compute a new board representing the next generation of the
# given board.
def next_board(board):
    return [
        [next_state(board, r, c) for c in range(WIDTH)]
        for r in range(HEIGHT)
    ]

# Display the board as widgets on screen.
def render_board(board, alive_colour, dead_colour):
    rows = []
    for r in range(HEIGHT):
        cells = []
        for c in range(WIDTH):
            if board[r][c] == ALIVE:
                colour = alive_colour
            else:
                colour = dead_colour
            cells.append(
                render.Box(
                    width = 1,
                    height = 1,
                    color = colour,
                ),
            )
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

# Create an animation of the game of life with a random starting point.
def animate(alive_colour, dead_colour):
    frames = []
    board = generate_board()

    # Generate enough frames to last for the maximum time the app can be on screen.
    for delay in range(0, APP_DURATION_MILLISECONDS, REFRESH_MILLISECONDS):
        frames.append(render_board(board, alive_colour, dead_colour))
        board = next_board(board)  # eveolve to next step
    return render.Animation(children = frames)

def main(config):
    alive_colour = config.get("alive_colour")
    if not alive_colour:
        alive_colour = COLOURS[0].value  # White
    dead_colour = config.get("dead_colour")
    if not dead_colour:
        dead_colour = COLOURS[3].value  # Black

    return render.Root(
        delay = REFRESH_MILLISECONDS,
        child = animate(alive_colour, dead_colour),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "alive_colour",
                name = "Alive colour",
                desc = "The colour to show for living cells",
                icon = "heart-pulse",
                default = COLOURS[0].value,
                options = COLOURS,
            ),
            schema.Dropdown(
                id = "dead_colour",
                name = "Dead colour",
                desc = "The colour to show for dead cells",
                icon = "skull-crossbones",
                default = COLOURS[3].value,
                options = COLOURS,
            ),
        ],
    )

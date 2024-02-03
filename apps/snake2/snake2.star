"""
Applet: Snake
Summary: Snake game
Description: Watch snake play out.
Author: dgoldstein1
"""

load("schema.star", "schema")

# A simple clock applet

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

BOARD_SIZE_X = 16
BOARD_SIZE_Y = 8
MAX_FRAMES = 800
DELAY_PER_FRAME_MS = 20
CELL_SIZE = 4
STARTING_SNAKE_SIZE = 3

BLANK_CELL = render.Box(width = CELL_SIZE, height = CELL_SIZE, color = "#808080")
APPLE_CELL = render.Box(width = CELL_SIZE, height = CELL_SIZE, color = "#9cf774")
SNAKE_CELL = render.Box(width = CELL_SIZE, height = CELL_SIZE, color = "#5ff")

SNAKE_DIRECTION_N = "north"
SNAKE_DIRECTION_S = "south"
SNAKE_DIRECTION_E = "east"
SNAKE_DIRECTION_W = "west"

def new_apple_position(curr_position, snake_position):
    pos = [
        random.number(0, BOARD_SIZE_X - 1),
        random.number(0, BOARD_SIZE_Y - 1),
    ]
    if pos in snake_position or pos == curr_position:
        return new_apple_position(curr_position, snake_position)
    return pos

def get_next_snake_position(snake_position, snake_direction):
    """
    returns where the snake will be during next move
    """

    # python: need to copy out mutable list somehow, otherwise
    # call by object updates snake_position for caller
    # starlark has no copy() method
    new_snake_position = [[x, y] for [x, y] in snake_position]
    new_head = [[x, y] for [x, y] in snake_position][0]
    if snake_direction == SNAKE_DIRECTION_N:
        new_head[1] = new_head[1] + 1
    elif snake_direction == SNAKE_DIRECTION_E:
        new_head[0] = new_head[0] + 1
    elif snake_direction == SNAKE_DIRECTION_S:
        new_head[1] = new_head[1] - 1
    else:
        # west
        new_head[0] = new_head[0] - 1

    new_snake_position.pop()
    new_snake_position.insert(0, new_head)
    return new_snake_position

def move_snake_towards_apple(snake_position, snake_direction, apple_position):
    """
    change the snake direction towards an apple, if that is more direct or in bounds
    """
    directions = [
        SNAKE_DIRECTION_N,
        SNAKE_DIRECTION_E,
        SNAKE_DIRECTION_S,
        SNAKE_DIRECTION_W,
    ]

    i = directions.index(snake_direction)

    def distanceFromApple(direction):
        """
        √((x2 – x1)² + (y2 – y1)²).
        """
        [x1, y1] = get_next_snake_position(snake_position, direction)[0]
        [x2, y2] = apple_position
        return math.sqrt((math.pow(x2 - x1, 2)) + (math.pow(y2 - y1, 2)))

    # if you're going N, your next options are N,E or W
    options = [
        snake_direction,
        directions[(i + 1) % len(directions)],
        directions[(i + 3) % len(directions)],
    ]

    # sort options by what gets snake closest to apple
    for opt in sorted(
        options,
        key = lambda direction: distanceFromApple(direction),
    ):
        new_pos = get_next_snake_position(snake_position, opt)
        if in_bounds(new_pos):
            return False, new_pos, opt

    return True, [], ""

def in_bounds(snake_position):
    """
    check if snake is in a valid position
    """
    if snake_position[0] in snake_position[1:]:
        return False
    if snake_position[0][0] < 0 or snake_position[0][0] == BOARD_SIZE_X:
        return False
    if snake_position[0][1] < 0 or snake_position[0][1] == BOARD_SIZE_Y:
        return False
    return True

def next_move(snake_position, snake_direction, apple_position):
    """
    update model after a frame has been rendered
    """

    # turn snake if we're going to hit a wall
    game_over, new_snake_position, new_snake_direction = move_snake_towards_apple(
        snake_position,
        snake_direction,
        apple_position,
    )
    if game_over:
        return True, None, None, None

    if new_snake_position[0] == apple_position:
        # add apple to front of old snake
        snake_position.insert(0, apple_position)
        return False, snake_position, new_snake_direction, new_apple_position(
            apple_position,
            snake_position,
        )

    return False, new_snake_position, new_snake_direction, apple_position

def render_cell(x, y, snake_position, apple_position, game_over):
    """
    renders inividual cell
    """
    if game_over:
        return BLANK_CELL
    if [x, y] in snake_position:
        return SNAKE_CELL
    if [x, y] == apple_position:
        return APPLE_CELL
    return BLANK_CELL

def render_board(game_over, snake_position, apple_position):
    """
    renders main game board onto screen
    """
    children = []
    for y in range(BOARD_SIZE_Y):
        row = []
        for x in range(BOARD_SIZE_X):
            row.append(
                render_cell(x, y, snake_position, apple_position, game_over),
            )
        children.append(render.Row(
            expanded = True,
            children = row,
        ))
    return children

def generate_board_animation():
    """
    returns animation of gameboard throughout game
    """
    frames = []

    def reset():
        starting_snake_position_x = int((BOARD_SIZE_X - 1) / 2)
        snake_position = []
        for i in range(STARTING_SNAKE_SIZE):
            snake_position.append(
                [starting_snake_position_x - i, starting_snake_position_x],
            )

        snake_direction = SNAKE_DIRECTION_E

        apple_position = new_apple_position(None, snake_position)
        game_over = False
        return snake_position, snake_direction, apple_position, game_over

    snake_position, snake_direction, apple_position, game_over = reset()

    for _ in range(MAX_FRAMES):
        frames.append(
            render.Column(
                expanded = True,
                children = render_board(
                    game_over,
                    snake_position,
                    apple_position,
                ),
            ),
        )

        if not game_over:
            game_over, snake_position, snake_direction, apple_position = next_move(
                snake_position,
                snake_direction,
                apple_position,
            )
        else:
            snake_position, snake_direction, apple_position, game_over = reset()

    return render.Animation(children = frames)

def main():
    random.seed(time.now().unix // 15)
    return render.Root(
        delay = DELAY_PER_FRAME_MS,
        child = generate_board_animation(),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

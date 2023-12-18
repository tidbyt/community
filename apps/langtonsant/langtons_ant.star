"""
Applet: Langton's Ant
Summary: 2-D Cellular Automata
Description: Automata with simple rules but complex emergent behavior.
Author: alewando
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Constants.
EMPTY = 0
BOARD_WIDTH = 64
BOARD_HEIGHT = 32

STATE_COLORS = [
    render.Box(width = 1, height = 1, color = "#000000"),  # Black/empty
    render.Box(width = 1, height = 1, color = "#ffffff"),  # White
    render.Box(width = 1, height = 1, color = "#800000"),  # Maroon
    render.Box(width = 1, height = 1, color = "#ffff00"),  # Yellow
    render.Box(width = 1, height = 1, color = "#808000"),  # Olive
    render.Box(width = 1, height = 1, color = "#c0c0c0"),  # Silver
    render.Box(width = 1, height = 1, color = "#808080"),  # Gray
    render.Box(width = 1, height = 1, color = "#00ff00"),  # Lime
    render.Box(width = 1, height = 1, color = "#008000"),  # Green
    render.Box(width = 1, height = 1, color = "#00ffff"),  # Aqua
    render.Box(width = 1, height = 1, color = "#008080"),  # Teal
    render.Box(width = 1, height = 1, color = "#0000ff"),  # Blue
    render.Box(width = 1, height = 1, color = "#000080"),  # Navy
    render.Box(width = 1, height = 1, color = "#ff00ff"),  # Fuchsia
    render.Box(width = 1, height = 1, color = "#800080"),  # Purple
    render.Box(width = 1, height = 1, color = "#ffffff"),  # White (Repeating list due to long ruleset and lack of vision)
    render.Box(width = 1, height = 1, color = "#800000"),  # Maroon
    render.Box(width = 1, height = 1, color = "#ffff00"),  # Yellow
    render.Box(width = 1, height = 1, color = "#808000"),  # Olive
    render.Box(width = 1, height = 1, color = "#c0c0c0"),  # Silver
    render.Box(width = 1, height = 1, color = "#808080"),  # Gray
    render.Box(width = 1, height = 1, color = "#00ff00"),  # Lime
    render.Box(width = 1, height = 1, color = "#008000"),  # Green
    render.Box(width = 1, height = 1, color = "#00ffff"),  # Aqua
    render.Box(width = 1, height = 1, color = "#008080"),  # Teal
    render.Box(width = 1, height = 1, color = "#0000ff"),  # Blue
    render.Box(width = 1, height = 1, color = "#000080"),  # Navy
]
ANT_COLOR = render.Box(width = 1, height = 1, color = "#ff0000")  # Red

# Each character in the rule string indicates which direction the ant should turn when encountering the state/color whose index matches the character
# Ex: "RL" means the ant should turn right (char at index 0 of the rule string) when encountering a black square (color at index 0 of the colors list)
DEFAULT_RULES = "RANDOM"
PREDEFINED_RULES = ["RL", "RLR", "LLRR", "LRRRRRLLR", "LLRRRLRLRLLR", "RRLLLRLLLRRR"]

DEFAULT_FRAMES_PER_VIEW = 100
DEFAULT_NUM_ANTS = 5

DEBUG_ENABLED = False

def log(message, vars = None):
    if DEBUG_ENABLED:
        if not vars:
            print(message)
        else:
            print(message % vars)

def main(config):
    num_frames = int(config.get("num_frames", DEFAULT_FRAMES_PER_VIEW))
    num_frames = min(num_frames, 300)  # doesn't make sense to render more frames than can be displayed in 15s

    num_ants = int(config.get("num_ants", DEFAULT_NUM_ANTS))
    num_ants = min(num_ants, DEFAULT_NUM_ANTS * 2)  # ok guys let's keep it reasonable

    selected_rules = config.str("rule_set", DEFAULT_RULES)

    board = create_empty_board(BOARD_WIDTH, BOARD_HEIGHT)

    # Ant state is a 4-tuple (X-pos, Y-pos, direction, rules), Direction: 0=up, 1=right, 2=down, 3=left
    # initial ant position is random
    ants = [random_ant(selected_rules) for x in range(num_ants)]

    # ant = (BOARD_WIDTH // 2, BOARD_HEIGHT // 2, 0)

    # Render a bunch of frames
    frames = []
    for gen in range(num_frames):
        # Render the current generation
        frames.append(render_frame(ants, board))

        # Generate the next generation
        (ants, board) = next_generation(gen, ants, board)

    # Render all of our frames as an animation
    return render.Root(
        delay = 0,
        child = render.Animation(
            children = frames,
        ),
    )

def create_empty_board(width, height):
    """
    Create an empty board
    """
    return [
        [EMPTY for x in range(width)]
        for y in range(height)
    ]

def random_ant(selected_rules):
    x = random.number(0, BOARD_WIDTH - 1)
    y = random.number(0, BOARD_HEIGHT - 1)
    direction = random.number(0, 3)
    ant_rules = selected_rules
    if (selected_rules == "RANDOM"):
        ant_rules = PREDEFINED_RULES[random.number(0, len(PREDEFINED_RULES) - 1)]
        log("Selected random rules: %s", ant_rules)
    log("Creating ant with rules %s", ant_rules)
    ant = (x, y, direction, ant_rules)
    return ant

def next_generation(generation_num, ants, current_board):
    """
    Generates the next generation based off of the current generation.
    Returns the new ant position and board state
    """

    # Start by copying the existing board
    new_board = [row[:] for row in current_board]

    # Apply the rules to move each ant
    new_ant_states = []
    for ant_idx, ant in enumerate(ants):
        ant_x = ant[0]
        ant_y = ant[1]
        ant_direction = ant[2]
        ant_rules = ant[3]
        current_state = current_board[ant_y][ant_x]

        # Increment the state of the current square
        new_state = (current_state + 1) % len(ant_rules)
        new_board[ant_y][ant_x] = new_state

        # Figure out what direction to turn
        direction = get_turn_direction_for_state(current_state, ant_rules)

        new_ant_state = ant
        if direction == "R":
            # turn 90 degrees clockwise, flip the color of the square, move forward one unit
            new_direction = (ant_direction + 1) % 4
            new_ant_state = move_ant(ant, new_direction)

        if direction == "L":
            # turn 90 degrees counter-clockwise, flip the color of the square, move forward one unit
            new_direction = (4 + ant_direction - 1) % 4
            new_ant_state = move_ant(ant, new_direction)

        log("generation: %d, ant %d: %d,%d; dir: %d; state: %d->%d  ==> %d, %d; dir: %d", (generation_num, ant_idx, ant_x, ant_y, ant_direction, current_state, new_state, new_ant_state[0], new_ant_state[1], new_ant_state[2]))
        new_ant_states.append(new_ant_state)

    return (new_ant_states, new_board)

def get_turn_direction_for_state(current_state, ant_rules):
    """
    Examines the rule string to determine which direction the ant should turn based on the color of the cell it is currently on
    """

    # If another ant was already here, the state value may be too high for this ant's rule set.
    # When this happens, use the right-most (last) rule for this ant
    return ant_rules[current_state % len(ant_rules)]

def move_ant(ant, ant_direction):
    """
    Moves the ant one unit in the specified direction.
    Returns a new tuple of (x, y, direction)
    """
    ant_x = ant[0]
    ant_y = ant[1]
    if ant_direction == 0:  # Up
        ant_y = (BOARD_HEIGHT + ant_y - 1) % BOARD_HEIGHT
    if ant_direction == 1:  # Right
        ant_x = (ant_x + 1) % BOARD_WIDTH
    if ant_direction == 2:  # Down
        ant_y = (ant_y + 1) % BOARD_HEIGHT
    if ant_direction == 3:  # Left
        ant_x = (BOARD_WIDTH + ant_x - 1) % BOARD_WIDTH
    return (ant_x, ant_y, ant_direction, ant[3])

def render_frame(ants, board):
    """
    Renders a frame for the given board state and ant location
    """
    children = [
        render.Column(
            children = [render_row(row, y, ants) for y, row in enumerate(board)],
        ),
    ]

    return render.Stack(children = children)

def render_row(row, y, ants):
    """
    Render a single row of cells
    """
    return render.Row(children = [render_cell(cell, x, y, ants) for x, cell in enumerate(row)])

def render_cell(cell_state, x, y, ants):
    """
    Render a single cell, using pre-defined Box elements for each color
    """
    cell = STATE_COLORS[cell_state]

    # Render ant positions in separate color
    for ant in ants:
        if x == ant[0] and y == ant[1]:
            cell = ANT_COLOR
            break

    return cell

def get_schema():
    rule_options = [schema.Option(display = r, value = r) for r in PREDEFINED_RULES]
    rule_options.append(schema.Option(display = "Random (from list)", value = "RANDOM"))

    #rule_options.append(schema.Option(display = "Custom (supply below)" ,value = "CUSTOM"))
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "num_ants",
                name = "Ant count",
                desc = "Number of ants",
                icon = "bug",
            ),
            schema.Dropdown(
                id = "rule_set",
                name = "Movement Rules",
                desc = "Rules controling how the ant moves",
                icon = "arrowTurnDown",
                default = "RANDOM",
                options = rule_options,
            ),
            # schema.Generated(
            #     id = "generated",
            #     source = "rule_set",
            #     handler = custom_rule_set_schema,
            # ),
            schema.Text(
                id = "num_frames",
                name = "Frames per cycle",
                desc = "Number of frames to render each app cycle",
                icon = "film",
            ),
        ],
    )

# def custom_rule_set_schema(selected_rule_set):
#     if(selected_rule_set == "CUSTOM"):
#         return [schema.Text(id="custom_rule_set", name="Custom rules", desc="Custom rule set", icon="arrowTurnDown",
#             default="RL")]
#     return []

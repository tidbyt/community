"""
Applet: Life
Summary: Conways Game of Life
Description: Runs a famous cellular automaton and animates the state on screen.
Author: dinosaursrarr
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ALIVE = True
DEAD = False
WIDTH = 64
HEIGHT = 32
APP_DURATION_MILLISECONDS = 15000
REFRESH_MILLISECONDS = 75

# The offsets of a cell's eight neighbours.
# We wrap around at the edges, so we are treating the board
# as a toroidal array. Seems appropriate when small.
NEIGHBOUR_DIFFS = {
    (-1, -1): True,  # NE
    (0, -1): True,  # N
    (1, -1): True,  # NW
    (-1, 0): True,  # E
    (1, 0): True,  # W
    (-1, 1): True,  # SE
    (0, 1): True,  # S
    (1, 1): True,  # SW
}

NEIGHBOUR_AND_CELL_DIFFS = {
    (-1, -1): True,  # NE
    (0, -1): True,  # N
    (1, -1): True,  # NW
    (-1, 0): True,  # E
    (0, 0): True,  # The cell itself
    (1, 0): True,  # W
    (-1, 1): True,  # SE
    (0, 1): True,  # S
    (1, 1): True,  # SW
}

WHITE = "#ffffff"
BLACK = "#000000"

# Random starting point where every cell has equal chance
# of starting dead or alive.
def generate_initial_state():
    neighbours = {}
    changed = []
    living = {}

    for x in range(WIDTH):
        for y in range(HEIGHT):
            is_alive = random.number(0, 1) > 0.5
            if is_alive:
                changed.append((x, y))
                living[(x, y)] = True
                for dx, dy in NEIGHBOUR_DIFFS.keys():
                    #dx, dy = neighbour
                    nx = (x + dx) % WIDTH
                    ny = (y + dy) % HEIGHT
                    neighbours.setdefault((nx, ny), 0)
                    neighbours[(nx, ny)] += 1

    return living, neighbours, changed

# Determine what happens to a given cell in the next generation,
# based on its current state and that of its neighbours.
def next_state(current_state, living_neighbours):
    if current_state == ALIVE and living_neighbours in [2, 3]:
        return ALIVE
    if current_state == DEAD and living_neighbours == 3:
        return ALIVE
    return DEAD

# Returns details of which cells have changed in the next generation and which
# are alive.
def update_changed_cells(living, neighbours, changed):
    # There is some redundancy in keeping track of both of these, but we are
    # optimising for speed. There can be many living cells which don't change
    # between generations, so don't need to be updated, so we can skip them. And
    # neighbours of cells that died don't need their neighbour counts updated.
    next_living = {}
    next_changed = []

    checked = {}
    for x, y in changed:
        for dx, dy in NEIGHBOUR_AND_CELL_DIFFS.keys():
            nx = (x + dx) % WIDTH
            ny = (y + dy) % HEIGHT
            if checked.get((nx, ny)):
                continue
            checked[(nx, ny)] = True
            was_alive = living.get((nx, ny), DEAD)
            is_alive = next_state(was_alive, neighbours.get((nx, ny), 0))
            if is_alive:
                next_living[(nx, ny)] = True
            if is_alive != was_alive:
                next_changed.append((nx, ny))

    return next_living, next_changed

# Returns details of how many living neighbours each cell in the next generation has.
def update_neighbours(living):
    neighbours = {}
    for x, y in living.keys():
        for dx, dy in NEIGHBOUR_DIFFS.keys():
            nx = (x + dx) % WIDTH
            ny = (y + dy) % HEIGHT
            neighbours.setdefault((nx, ny), 0)
            neighbours[(nx, ny)] += 1
    return neighbours

# Compute a new board representing the next generation of the
# given board.
def next_generation(living, neighbours, changed, cache):
    key = (tuple(living.keys()), tuple(neighbours.items()), tuple(changed))
    cached = cache.get(key)
    if cached != None:
        return cached

    next_living, next_changed = update_changed_cells(living, neighbours, changed)
    next_neighbours = update_neighbours(next_living)
    cache[key] = (next_living, next_neighbours, next_changed)
    return next_living, next_neighbours, next_changed

# Display the curent state as widgets on screen.
def render_frame(living, alive_cell, dead_cell, cache):
    cached = cache.get(living)
    if cached != None:
        return cached

    rows = [[dead_cell for c in range(WIDTH)] for r in range(HEIGHT)]
    for x, y in living:
        rows[y][x] = alive_cell

    frame = render.Column(children = [render.Row(children = row) for row in rows])
    cache[living] = frame
    return frame

# Create an animation of the game of life with a random starting point.
def animate(alive_cell, dead_cell):
    frames = []
    living, neighbours, changed = generate_initial_state()

    # We often reach the point where the end has lots of oscillators but no
    # other action. We don't have to recompute each of those frames.
    generation_cache = {}
    frame_cache = {}

    # Generate enough frames to last for the maximum time the app can be on screen.
    for _ in range(0, APP_DURATION_MILLISECONDS, REFRESH_MILLISECONDS):
        frames.append(render_frame(tuple(living.keys()), alive_cell, dead_cell, frame_cache))
        living, neighbours, changed = next_generation(living, neighbours, changed, generation_cache)  # evolve to next step
    return render.Animation(children = frames)

def main(config):
    alive_colour = config.get("alive_colour")
    if not alive_colour:
        alive_colour = WHITE
    dead_colour = config.get("dead_colour")
    if not dead_colour:
        dead_colour = BLACK

    # Turns out to be significantly faster to re-use
    # a single element rather than create one for each
    # cell on each iteration.
    alive_cell = render.Box(
        width = 1,
        height = 1,
        color = alive_colour,
    )
    dead_cell = render.Box(
        width = 1,
        height = 1,
        color = dead_colour,
    )

    return render.Root(
        delay = REFRESH_MILLISECONDS,
        child = animate(alive_cell, dead_cell),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "alive_colour",
                name = "Alive colour",
                desc = "The colour to show for living cells",
                icon = "heartPulse",
                default = WHITE,
            ),
            schema.Color(
                id = "dead_colour",
                name = "Dead colour",
                desc = "The colour to show for dead cells",
                icon = "skullCrossbones",
                default = BLACK,
            ),
        ],
    )

"""
Applet: Amazing
Summary: Draws lovely mazes
Description: Draws mazes on the screen and animates progress as it goes.
Author: dinosaursrarr
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Tidbyt size is fixed
WIDTH_CELLS = 32
HEIGHT_CELLS = 16

# Display final result for longer than intermediate steps.
FINAL_FRAME_LENGTH = 40

# Determines how many cells to add in each frame of animation. Higher values
# mean faster render times but less smooth animations.
STEP_SIZE = 8

# make lint doesn't allow while loops, so workaround with large finite limit.
MAX_STEPS = 1000000

# Returns a pixel at x, y in a given colour.
def draw_pixel(x, y, cell):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = cell,
    )

# Draws a single frame from a list of pairs of points that are connected.
def draw_frame(old_pixels, edge_pairs, foreground_cell):
    pixels = list(old_pixels)
    for edge_pair in edge_pairs:
        first = edge_pair[0]
        second = edge_pair[1]
        pixels.extend([
            draw_pixel(2 * first[0], 2 * first[1], foreground_cell),
            draw_pixel(first[0] + second[0], first[1] + second[1], foreground_cell),
            draw_pixel(2 * second[0], 2 * second[1], foreground_cell),
        ])
    return render.Stack(children = pixels), pixels

# Draws a series of frames from the given maze generator function. Maze generator
# functions should return a list containing cells added at each step.
def draw_animation(generator_fn, foreground_cell, background):
    frames = []
    pixels = [background]
    sequence = generator_fn()
    for i in range(0, len(sequence), STEP_SIZE):
        frame, pixels = draw_frame(pixels, sequence[i:i + STEP_SIZE], foreground_cell)
        frames.append(frame)

    # Pause on end result so we can admire it
    frames.extend([frames[-1]] * FINAL_FRAME_LENGTH)

    return render.Root(
        child = render.Animation(children = frames),
    )

# Returns a random cell somewhere on the grid.
def random_cell():
    return (random.number(0, WIDTH_CELLS - 1), random.number(0, HEIGHT_CELLS - 1))

# Gives a list of all cells next to `current` and not in `visited`.
def get_neighbours(current, visited):
    neighbours = []
    for diff in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        if current[0] + diff[0] < 0:
            continue
        if current[0] + diff[0] >= WIDTH_CELLS:
            continue
        if current[1] + diff[1] < 0:
            continue
        if current[1] + diff[1] >= HEIGHT_CELLS:
            continue
        neighbour = (current[0] + diff[0], current[1] + diff[1])
        if neighbour in visited:
            continue
        neighbours.append(neighbour)
    return neighbours

# BACKTRACKING
# Perform backtracking search until the space is entirely filled.
# At each step, connect to a random neighbouring cell.
def backtracking():
    sequence = []

    visited = {}
    stack = []

    current = random_cell()
    visited[current] = True
    stack.append(current)

    for i in range(MAX_STEPS):
        if len(stack) <= 0:
            break
        current = stack.pop()
        visited[current] = True
        neighbours = get_neighbours(current, visited)
        if len(neighbours) > 0:
            stack.append(current)
            neighbour = neighbours[random.number(0, len(neighbours) - 1)]
            visited[neighbour] = True
            stack.append(neighbour)
            sequence.append((current, neighbour))

    return sequence

# RANDOMIZED KRUSKAL
# Randomly knock down walls between disjoint parts of the screen until we have a spanning tree.
def find_root(union_finds, child):
    if union_finds[child].parent == child:
        return child
    return find_root(union_finds, union_finds[child].parent)

def union(union_finds, first_root, second_root):
    first = union_finds[first_root]
    second = union_finds[second_root]

    # Starlark structs are immutable, so we have to replace rather than update
    if first.size < second.size:
        union_finds[first_root] = struct(parent = second.parent, size = first.size)
        union_finds[second_root] = struct(parent = second.parent, size = first.size + second.size)
    else:
        union_finds[second_root] = struct(parent = first.parent, size = second.size)
        union_finds[first_root] = struct(parent = first.parent, size = first.size + second.size)

def randomized_kruskal():
    sequence = []

    # Use these to approximate union-find data structure as Starlark doesn't have classes.
    union_finds = {}
    for y in range(HEIGHT_CELLS):
        for x in range(WIDTH_CELLS):
            union_finds[(x, y)] = struct(parent = (x, y), size = 1)

    walls_removed = {}
    for i in range(MAX_STEPS):
        if len(walls_removed) >= ((WIDTH_CELLS * HEIGHT_CELLS) - 1):
            break
        current = random_cell()
        neighbours = get_neighbours(current, visited = [])
        neighbour = neighbours[random.number(0, len(neighbours) - 1)]
        wall = (current[0] + neighbour[0], current[1] + neighbour[1])
        if wall in walls_removed:
            continue

        # Check we have two disjoint sets to merge
        current_root = find_root(union_finds, current)
        neighbour_root = find_root(union_finds, neighbour)
        if current_root == neighbour_root:
            continue

        # Join the sets and knock down the wall between cells
        union(union_finds, current_root, neighbour_root)
        walls_removed[wall] = True
        sequence.append((current, neighbour))

    return sequence

# RANDOMIZED PRIM
# Randomly choose a cell and neighbour to add to the maze
def randomized_prim():
    sequence = []

    visited = {}
    cells = []

    # Pick a starting cell, mark visited and add to the list
    current = random_cell()
    visited[current] = True
    cells.append(current)

    for i in range(MAX_STEPS):
        if len(cells) <= 0:
            break

        # Pop a random cell from the list
        i = random.number(0, len(cells) - 1)
        current = cells[i]
        cells = cells[:i] + cells[i + 1:]

        # Add its neighbours to the list and mark the current cell visited
        neighbours = get_neighbours(current, visited)
        cells.extend(neighbours)
        visited[current] = True

        # Knock down the wall between the cell and its neighbours
        if len(neighbours) == 0:
            continue
        neighbour = neighbours[random.number(0, len(neighbours) - 1)]
        sequence.append((current, neighbour))

    return sequence

# ALDOUS BRODER
# Produces uniform spanning trees in an infuriating manner
def aldous_broder():
    sequence = []

    visited = {}
    current = random_cell()
    remaining = WIDTH_CELLS * HEIGHT_CELLS - 1

    for i in range(MAX_STEPS):
        if remaining <= 0:
            break
        neighbours = get_neighbours(current, visited = [])
        neighbour = neighbours[random.number(0, len(neighbours) - 1)]
        if neighbour not in visited:
            visited[neighbour] = True
            remaining -= 1
            sequence.append((current, neighbour))
        current = neighbour

    return sequence

# WILSON
# Use a loop-erased random walk
def wilson_random_walk(start, visited):
    current = start
    neighbours = get_neighbours(current, visited = [current])
    last_destination = {}  # Avoid loops by keeping track of last direction used to exit a cell
    for i in range(MAX_STEPS):
        if len(neighbours) <= 0:
            break
        neighbour = neighbours[random.number(0, len(neighbours) - 1)]
        last_destination[current] = neighbour
        if neighbour in visited:
            return last_destination
        current = neighbour
        neighbours = get_neighbours(current, visited = [current])

def wilson():
    sequence = []
    visited = {}
    current = random_cell()
    visited[current] = True

    for i in range(MAX_STEPS):
        if len(visited) >= (WIDTH_CELLS * HEIGHT_CELLS):
            break
        for j in range(MAX_STEPS):
            if current not in visited:
                break
            current = random_cell()

        walk = wilson_random_walk(current, visited)
        for prev, dest in walk.items():
            visited[prev] = True
            visited[dest] = True
            sequence.append((prev, dest))

    return sequence

# ELLER
# Generate one row at a time. Never looks at more than a single row.
def row_to_sets(row):
    sets = {}
    sets[row[0]] = {"start": 0}
    for cell in range(1, len(row)):
        if row[cell] == row[cell - 1]:
            continue
        sets[row[cell - 1]] = {"start": sets[row[cell - 1]]["start"], "end": cell}
        sets[row[cell]] = {"start": cell}
    sets[row[-1]] = {"start": sets[row[-1]]["start"], "end": len(row)}
    return sets

def eller():
    sequence = []

    # Assign each cell in the first row to its own set
    first_row = list(range(WIDTH_CELLS))

    for row in range(HEIGHT_CELLS):
        next_set = len(first_row)
        for cell in range(1, len(first_row)):
            should_merge = random.number(0, 1) < 0.5
            if not should_merge:
                continue
            first_row[cell] = first_row[cell - 1]
            sequence.append(((cell - 1, row), (cell, row)))

        # Make vertical connections, at least one per set
        next_row = list([None] * WIDTH_CELLS)
        sets = row_to_sets(first_row)
        for k, v in sets.items():
            made_vertical = False
            for cell in range(v["start"], v["end"]):
                should_merge = random.number(0, 1) < 0.5
                if not should_merge:
                    continue
                next_row[cell] = k
                sequence.append(((cell, row - 1), (cell, row)))
                made_vertical = True
            if not made_vertical:
                next_row[v["start"]] = k
                sequence.append(((v["start"], row - 1), (v["start"], row)))

        for cell in range(len(next_row)):
            if next_row[cell] != None:
                continue
            next_row[cell] = next_set
            next_set += 1

        # Generate the next one
        first_row = next_row

    return sequence

# HUNT AND KILL
# Perform a random walk as long as possible, then find a new starting point
def hunt_random_walk(start, visited, sequence):
    current = start
    visited[current] = True
    neighbours = get_neighbours(current, visited)
    for i in range(MAX_STEPS):
        if len(neighbours) <= 0:
            break
        neighbour = neighbours[random.number(0, len(neighbours) - 1)]
        sequence.append((current, neighbour))
        visited[neighbour] = True
        current = neighbour
        neighbours = get_neighbours(current, visited)

def next_start(visited):
    for row in range(HEIGHT_CELLS):
        for col in range(WIDTH_CELLS):
            cell = (col, row)
            if cell in visited:
                continue
            for neighbour in get_neighbours(cell, visited = []):
                if neighbour in visited:
                    return cell

def hunt_and_kill():
    sequence = []
    visited = {}

    current = random_cell()
    visited[current] = True

    for i in range(MAX_STEPS):
        if len(visited) >= (WIDTH_CELLS * HEIGHT_CELLS):
            break
        hunt_random_walk(current, visited, sequence)
        next_cell = next_start(visited)
        if next_cell == None:
            break
        visited[next_cell] = True
        sequence.append((current, next_cell))
        current = next_cell

    return sequence

# RECURSIVE DIVISION
# Generates rooms to fill the space
def should_bisect_horizontally(width, height):
    if width < height:
        return True
    if height < width:
        return False
    return random.number(0, 1) < 0.5

def bisect(sequence, width_start, width_end, height_start, height_end):
    width = width_end - width_start
    height = height_end - height_start
    if width < 2 or height < 2:
        return  # Reached desired resolution

    if should_bisect_horizontally(width, height):
        bisect_height = int(random.number(height_start, height_end))
        gap = int(random.number(width_start, width_end))
        for x in range(width_start, width_end):
            if x == gap:
                continue
            carved = ((x, bisect_height), (x - 1, bisect_height))
            sequence.append(carved)
        bisect(sequence, width_start, width_end, height_start, bisect_height)
        bisect(sequence, width_start, width_end, bisect_height, height_end)
    else:
        bisect_width = int(random.number(width_start, width_end))
        gap = int(random.number(height_start, height_end))
        for y in range(height_start, height_end):
            if y == gap:
                continue
            carved = ((bisect_width, y), (bisect_width, y - 1))
            sequence.append(carved)
        bisect(sequence, width_start, bisect_width, height_start, height_end)
        bisect(sequence, bisect_width, width_end, height_start, height_end)

def recursive_division():
    sequence = []
    bisect(sequence, 0, WIDTH_CELLS, 0, HEIGHT_CELLS)
    return sequence

# BINARY TREE
# Look at each cell individually, and randomly carve east or down.
# Generates a random binary tree where each cell has a single path to the
# bottom-right corner.
def binary_tree():
    sequence = []

    for y in range(HEIGHT_CELLS):
        for x in range(WIDTH_CELLS):
            carve_east = (random.number(0, 1) < 0.5) or (y == HEIGHT_CELLS - 1)
            if carve_east and (x < WIDTH_CELLS - 1):
                carved = ((x, y), (x + 1, y))
                sequence.append(carved)
            else:
                carved = ((x, y), (x, y + 1))
                sequence.append(carved)

    return sequence

# SIDEWINDER
# Quick and easy and draws one row at a time. Won't have dead ends going from top to bottom.
def sidewinder():
    sequence = []

    for y in range(HEIGHT_CELLS):
        run_start_x = 0
        for x in range(WIDTH_CELLS):
            carve_east = random.number(0, 1) < 0.5
            if carve_east:
                carved = ((x, y), (x + 1, y))
                sequence.append(carved)
            elif y == 0:
                continue  # can't carve north from top row
            else:
                carve_north_from_x = random.number(run_start_x, x)
                carved = ((carve_north_from_x, y), (carve_north_from_x, y - 1))
                sequence.append(carved)
                run_start_x = x + 1

    return sequence

# Orchestre choosing a technique and running it
CHOOSE_RANDOM_ALGORITHM = "#"
ALGORITHMS = {
    # Many thanks to https://weblog.jamisbuck.org
    "Backtracking": backtracking,
    "Randomized Kruskal": randomized_kruskal,
    "Randomized Prim": randomized_prim,
    "Aldous-Broder": aldous_broder,
    "Wilson": wilson,
    "Eller": eller,
    "Hunt and kill": hunt_and_kill,
    "Recursive division": recursive_division,
    "Binary tree": binary_tree,
    "Sidewinder": sidewinder,
}

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

def main(config):
    algorithm_name = config.get("algorithm")
    if not algorithm_name or algorithm_name == CHOOSE_RANDOM_ALGORITHM:
        index = random.number(0, len(ALGORITHMS) - 1)
        algorithm_name = ALGORITHMS.keys()[index]
    algorithm = ALGORITHMS[algorithm_name]

    wall_colour = config.get("foreground")
    if not wall_colour:
        wall_colour = COLOURS[0].value  # White
    background_colour = config.get("background")
    if not background_colour:
        background_colour = COLOURS[3].value  # Black

    # Turns out to be much faster to reuse a single pixel than
    # to create new ones as needed.
    wall_cell = render.Box(
        height = 1,
        width = 1,
        color = wall_colour,
    )
    background = render.Box(
        color = background_colour,
    )

    return draw_animation(algorithm, wall_cell, background)

def get_schema():
    algorithms = [
        schema.Option(
            display = "Random",
            value = CHOOSE_RANDOM_ALGORITHM,
        ),
    ]
    algorithms.extend([
        schema.Option(
            display = k,
            value = k,
        )
        for k in ALGORITHMS.keys()
    ])
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "algorithm",
                name = "Algorithm",
                desc = "Algorithm to draw maze with",
                icon = "gears",
                default = CHOOSE_RANDOM_ALGORITHM,
                options = algorithms,
            ),
            schema.Dropdown(
                id = "foreground",
                name = "Wall colour",
                desc = "The colour to show for walls",
                icon = "trowelBricks",
                default = COLOURS[0].value,
                options = COLOURS,
            ),
            schema.Dropdown(
                id = "background",
                name = "Background colour",
                desc = "The colour to show for empty cells",
                icon = "brush",
                default = COLOURS[3].value,
                options = COLOURS,
            ),
        ],
    )

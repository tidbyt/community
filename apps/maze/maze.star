"""
Applet: Maze
Summary: Draws and solves random mazes.
Description: Draws and solves random mazes.
Author: gstark
"""

# Load support utilities
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Constants defining the size of the Tidbyt
GRID_ROWS = 15
GRID_COLS = 31

# Returns False if there is no cell to the east
# or the cell itself.
def east(grid, cell):
    if cell["col"] < GRID_COLS - 1:
        return grid[cell["row"]][cell["col"] + 1]
    else:
        return False

# Returns False if there is no cell to the west
# or the cell itself.
def west(grid, cell):
    if cell["col"] > 0:
        return grid[cell["row"]][cell["col"] - 1]
    else:
        return False

# Returns False if there is no cell to the north
# or the cell itself.
def north(grid, cell):
    if cell["row"] > 0:
        return grid[cell["row"] - 1][cell["col"]]
    else:
        return False

# Returns False if there is no cell to the south
# or the cell itself.
def south(grid, cell):
    if cell["row"] < GRID_ROWS - 1:
        return grid[cell["row"] + 1][cell["col"]]
    else:
        return False

# Returns True/False if the two cells are "linked"
def linked(cell, other_cell):
    if cell == False or other_cell == False:
        return False
    else:
        return [other_cell["row"], other_cell["col"]] in cell["links"]

# Links two cells together, the "other_cell" is added
# as a link to the "cell"
def link(cell, other_cell):
    cell["links"].append([other_cell["row"], other_cell["col"]])

# Return all the valid neighbors of the given cell
def neighbors(grid, cell):
    list = []

    n = north(grid, cell)
    s = south(grid, cell)
    e = east(grid, cell)
    w = west(grid, cell)

    if n:
        list.append(n)
    if s:
        list.append(s)
    if e:
        list.append(e)
    if w:
        list.append(w)

    return list

# Make a new cell representing this row and column
def new_cell(row, col):
    return {"row": row, "col": col, "links": []}

# Return True/False if the two cells a and b are the same cell
def same_cell(a, b):
    if a == False or b == False:
        return False

    return a["row"] == b["row"] and a["col"] == b["col"]

# Render the current grid and the current solution path
def render_frame(colors, grid, full_path, pixel, blank):
    path = full_path  # full_path[-26:-1]

    frame = []
    frame_row = []

    # Draw a solid line of pixels
    # along the top of the maze
    frame_row.append(pixel)
    for count in range(GRID_COLS):
        frame_row.append(pixel)
        frame_row.append(pixel)

    # Append that row to the current frame
    frame.append(frame_row)

    for row in grid:
        # We'll draw multiple frame rows per maze row
        # Starting with a solid pixel along the left
        top = [pixel]
        bottom = [pixel]

        for cell in row:
            top.append(blank)

            # Get the cell to the east. If it is linked
            # to this cell fill with a blank otherwise
            # fill with the maze color
            e = east(grid, cell)
            if linked(cell, e):
                top.append(blank)
            else:
                top.append(pixel)

            # Get the cell to the south. If it is linked
            # to this cell fill with a blank otherwise
            # fill with the maze color
            s = south(grid, cell)
            if linked(cell, s):
                bottom.append(blank)
            else:
                bottom.append(pixel)
            bottom.append(pixel)

        # Append the top and bottom rows
        frame.append(top)
        frame.append(bottom)

    # Return this frame
    return frame

def copy_frame(colors, frame, path):
    new_frame = [row[:] for row in frame]
    draw_path(colors, new_frame, path)
    return new_frame

def digit_to_hex(digit):
    return "0123456789ABCDEF"[digit]

def draw_path(colors, frame, path):
    prev_row = path[0][0] * 2 + 1
    prev_col = path[0][0] * 2 + 1

    index = -1
    for cell in path:
        index += 1

        if len(path) <= 1:
            opacity = 255
        else:
            opacity = int(index / (len(path) - 1) * 254)
        opacity = digit_to_hex(int(opacity / 16)) + digit_to_hex(opacity % 16)

        color = colors["solve_color"] + opacity

        pixel = render.Box(
            width = 1,
            height = 1,
            color = color,
        )

        row = cell[0] * 2 + 1
        col = cell[1] * 2 + 1
        frame[row][col] = pixel

        mid_row = int((prev_row + row) / 2)
        mid_col = int((prev_col + col) / 2)
        frame[mid_row][mid_col] = pixel

        prev_row = row
        prev_col = col

def solve(colors, grid, row, col, path, maze_frame, frames):
    frames.append(copy_frame(colors, maze_frame, path))

    if row == GRID_ROWS - 1 and col == GRID_COLS - 1:
        for index in range(0, 50):
            frames.append(copy_frame(colors, maze_frame, path))
        return True

    for cell in [neighbor for neighbor in grid[row][col]["links"] if neighbor not in path]:
        new_path = path[:]
        new_path.append([cell[0], cell[1]])

        if solve(colors, grid, cell[0], cell[1], new_path, maze_frame, frames):
            return True

COLORS = [
    schema.Option(display = "White", value = "#FFFFFF"),
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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "maze_color",
                name = "Maze color",
                desc = "The color to draw the maze",
                icon = "droplet",
                default = COLORS[0].value,
                options = COLORS,
            ),
            schema.Dropdown(
                id = "solve_color",
                name = "Solve color",
                desc = "The color to draw the maze solution",
                icon = "droplet",
                default = COLORS[8].value,
                options = COLORS,
            ),
        ],
    )

def frame_to_render(frame):
    return render.Column(children = [render.Row(children = row) for row in frame])

def main(config):
    colors = {
        "maze_color": config.get("maze_color"),
        "solve_color": config.get("solve_color"),
    }

    if not colors["maze_color"]:
        colors["maze_color"] = COLORS[0].value
    if not colors["solve_color"]:
        colors["solve_color"] = COLORS[8].value

    grid = []
    for row in range(GRID_ROWS):
        new_row = []
        grid.append(new_row)
        for col in range(GRID_COLS):
            new_row.append(new_cell(row, col))

    active = []
    active.append(grid[random.number(0, GRID_ROWS - 1)][random.number(0, GRID_COLS - 1)])

    for index in range(GRID_COLS * GRID_ROWS * 3):
        if len(active) > 0:
            cell_index = random.number(0, len(active) - 1)
            cell = active[cell_index]

            all_neighbors = [cell for cell in neighbors(grid, cell)]
            available_neighbors = [cell for cell in all_neighbors if len(cell["links"]) == 0]

            if (len(available_neighbors) > 0):
                neighbor = available_neighbors[random.number(0, len(available_neighbors) - 1)]
                link(cell, neighbor)
                link(neighbor, cell)
                active.append(neighbor)
            else:
                active.pop(cell_index)

    pixel = render.Box(
        width = 1,
        height = 1,
        color = colors["maze_color"],
    )

    blank = render.Box(
        width = 1,
        height = 1,
        color = "#000000",
    )

    maze_frame = render_frame(colors, grid, [], pixel, blank)

    path = [[0, 0]]
    frames = []
    solve(colors, grid, 0, 0, path, maze_frame, frames)

    animation = render.Animation(children = [frame_to_render(frame) for frame in frames])

    return render.Root(child = animation)

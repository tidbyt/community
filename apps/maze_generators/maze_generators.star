"""
Applet: Maze Generators
Summary: Generates mazes
Description: Generates mazes using different maze generation algorithms. Currently supported are Hilbert, Binary Tree, Depth-First Search, Aldous-Broder, Recursive Division, and Fractal Tesselation.
Author: SwinkyWorks
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

def hilbert(colorInfo, *_):
    validDirs = [
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
    ]
    slopeMap = [
        [0, 3, 4, 5, 58, 59, 60, 63, 64, 67, 68, 69, 122, 123, 124, 127],
        [1, 2, 7, 6, 57, 56, 61, 62, 65, 66, 71, 70, 121, 120, 125, 126],
        [14, 13, 8, 9, 54, 55, 50, 49, 78, 77, 72, 73, 118, 119, 114, 113],
        [15, 12, 11, 10, 53, 52, 51, 48, 79, 76, 75, 74, 117, 116, 115, 112],
        [16, 17, 30, 31, 32, 33, 46, 47, 80, 81, 94, 95, 96, 97, 110, 111],
        [19, 18, 29, 28, 35, 34, 45, 44, 83, 82, 93, 92, 99, 98, 109, 108],
        [20, 23, 24, 27, 36, 39, 40, 43, 84, 87, 88, 91, 100, 103, 104, 107],
        [21, 22, 25, 26, 37, 38, 41, 42, 85, 86, 89, 90, 101, 102, 105, 106],
    ]
    for y in range(0, 8):
        for x in range(0, 16):
            if (y > 0):
                if (slopeMap[y - 1][x] > slopeMap[y][x]):
                    validDirs[y][x].append(1)
            if (x < 15):
                if (slopeMap[y][x + 1] > slopeMap[y][x]):
                    validDirs[y][x].append(2)
            if (y < 7):
                if (slopeMap[y + 1][x] > slopeMap[y][x]):
                    validDirs[y][x].append(3)
            if (x > 0):
                if (slopeMap[y][x - 1] > slopeMap[y][x]):
                    validDirs[y][x].append(4)
    grid = [
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    ]
    frames = []
    for y in range(0, 8):
        for x in range(0, 16):
            if (len(validDirs[7 - y][x]) > 0):
                grid[7 - y][x] = validDirs[7 - y][x][random.number(0, len(validDirs[7 - y][x]) - 1)]
            else:
                grid[7 - y][x] = 0
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    if (grid[j][i] >= 0):
                        if i == x and j == 7 - y:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[5]))
                        else:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                    else:
                        columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 2 or grid[j][i + 1] == 4:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 3 or grid[j + 1][i] == 1:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
    if True:
        squaresChildren = []
        for i in range(0, 16):
            columnChildren = []
            for j in range(0, 8):
                if (grid[j][i] >= 0):
                    columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                else:
                    columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
            squaresChildren.append(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = columnChildren,
                ),
            )
        horizontalChildren = []
        horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
        verticalChildren = []
        for i in range(0, 15):
            hColumnChildren = []
            for j in range(0, 8):
                if grid[j][i] == 2 or grid[j][i + 1] == 4:
                    hColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = colorInfo[3],
                    ))
                else:
                    hColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "0000",
                    ))
            horizontalChildren.append(render.Column(
                expanded = True,
                main_align = "space_around",
                children = hColumnChildren,
            ))
        horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
        for i in range(0, 16):
            vColumnChildren = []
            vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
            for j in range(0, 7):
                if grid[j][i] == 3 or grid[j + 1][i] == 1:
                    vColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = colorInfo[3],
                    ))
                else:
                    vColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "0000",
                    ))
            vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
            verticalChildren.append(render.Column(
                expanded = True,
                main_align = "space_between",
                children = vColumnChildren,
            ))
        frames.append(
            render.Stack(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = squaresChildren,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = horizontalChildren,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = verticalChildren,
                    ),
                ],
            ),
        )
    for i in range(0, 49):
        frames.append(frames[len(frames) - 1])
    return [render.Animation(children = frames), 15000 / len(frames)]

def binary_tree(colorInfo, *_):
    validDirs = [
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []],
    ]
    slopeMap = [
        [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
        [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
        [17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
        [18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3],
        [19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
        [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5],
        [21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
        [22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7],
    ]
    for y in range(0, 8):
        for x in range(0, 16):
            if (y > 0):
                if (slopeMap[y - 1][x] > slopeMap[y][x]):
                    validDirs[y][x].append(1)
            if (x < 15):
                if (slopeMap[y][x + 1] > slopeMap[y][x]):
                    validDirs[y][x].append(2)
            if (y < 7):
                if (slopeMap[y + 1][x] > slopeMap[y][x]):
                    validDirs[y][x].append(3)
            if (x > 0):
                if (slopeMap[y][x - 1] > slopeMap[y][x]):
                    validDirs[y][x].append(4)
    grid = [
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    ]
    frames = []
    for y in range(0, 8):
        for x in range(0, 16):
            if (len(validDirs[7 - y][x]) > 0):
                grid[7 - y][x] = validDirs[7 - y][x][random.number(0, len(validDirs[7 - y][x]) - 1)]
            else:
                grid[7 - y][x] = 0
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    if (grid[j][i] >= 0):
                        if i == x and j == 7 - y:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[5]))
                        else:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                    else:
                        columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 2 or grid[j][i + 1] == 4:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 3 or grid[j + 1][i] == 1:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
    if True:
        squaresChildren = []
        for i in range(0, 16):
            columnChildren = []
            for j in range(0, 8):
                if (grid[j][i] >= 0):
                    columnChildren.append(render.Box(width = 2, height = 2, color = "#ffff"))
                else:
                    columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
            squaresChildren.append(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = columnChildren,
                ),
            )
        horizontalChildren = []
        horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
        verticalChildren = []
        for i in range(0, 15):
            hColumnChildren = []
            for j in range(0, 8):
                if grid[j][i] == 2 or grid[j][i + 1] == 4:
                    hColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "ffff",
                    ))
                else:
                    hColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "0000",
                    ))
            horizontalChildren.append(render.Column(
                expanded = True,
                main_align = "space_around",
                children = hColumnChildren,
            ))
        horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
        for i in range(0, 16):
            vColumnChildren = []
            vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
            for j in range(0, 7):
                if grid[j][i] == 3 or grid[j + 1][i] == 1:
                    vColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "ffff",
                    ))
                else:
                    vColumnChildren.append(render.Box(
                        width = 2,
                        height = 2,
                        color = "0000",
                    ))
            vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
            verticalChildren.append(render.Column(
                expanded = True,
                main_align = "space_between",
                children = vColumnChildren,
            ))
        frames.append(
            render.Stack(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = squaresChildren,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = horizontalChildren,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = verticalChildren,
                    ),
                ],
            ),
        )
    for i in range(0, 49):
        frames.append(frames[len(frames) - 1])
    return [render.Animation(children = frames), 15000 / len(frames)]

def depth_first(colorInfo, *_):
    visitedCells = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: Not visited
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Visited, not marked as complete
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 2: Visited, marked as complete
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    grid = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: No walls open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Wall right open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 2: Wall down open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 3: Both right wall and down wall open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    currentCell = [random.number(0, 15), random.number(0, 7)]
    visitedCells[currentCell[1]][currentCell[0]] = 1
    stack = []
    running = True
    frames = []
    for _ in range(0, 10000000000):
        if running:
            visitableDirs = []
            if currentCell[1] != 0:
                if visitedCells[currentCell[1] - 1][currentCell[0]] == 0:
                    visitableDirs.append(1)
            if currentCell[0] != 15:
                if visitedCells[currentCell[1]][currentCell[0] + 1] == 0:
                    visitableDirs.append(2)
            if currentCell[1] != 7:
                if visitedCells[currentCell[1] + 1][currentCell[0]] == 0:
                    visitableDirs.append(3)
            if currentCell[0] != 0:
                if visitedCells[currentCell[1]][currentCell[0] - 1] == 0:
                    visitableDirs.append(4)
            if len(visitableDirs) == 0:
                visitedCells[currentCell[1]][currentCell[0]] = 2
                if len(stack) == 0:
                    running = False
                    currentCell = [-1, -1]
                else:
                    currentCell = stack[len(stack) - 1]
                    stack.pop(len(stack) - 1)
            else:
                direction = visitableDirs[random.number(0, len(visitableDirs) - 1)]
                if direction == 1:
                    stack.append([currentCell[0], currentCell[1]])
                    currentCell[1] -= 1
                    visitedCells[currentCell[1]][currentCell[0]] = 1
                    grid[currentCell[1]][currentCell[0]] += 2
                elif direction == 2:
                    grid[currentCell[1]][currentCell[0]] += 1
                    stack.append([currentCell[0], currentCell[1]])
                    currentCell[0] += 1
                    visitedCells[currentCell[1]][currentCell[0]] = 1
                elif direction == 3:
                    grid[currentCell[1]][currentCell[0]] += 2
                    stack.append([currentCell[0], currentCell[1]])
                    currentCell[1] += 1
                    visitedCells[currentCell[1]][currentCell[0]] = 1
                elif direction == 4:
                    stack.append([currentCell[0], currentCell[1]])
                    currentCell[0] -= 1
                    visitedCells[currentCell[1]][currentCell[0]] = 1
                    grid[currentCell[1]][currentCell[0]] += 1
            x = currentCell[0]
            y = currentCell[1]
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    if (visitedCells[j][i] > 0):
                        if i == x and j == y:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[5]))
                        elif (visitedCells[j][i] == 1):
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                        else:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[4]))
                    else:
                        columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 1 or grid[j][i] == 3:
                        if visitedCells[j][i] == 2 or visitedCells[j][i + 1] == 2:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[4],
                            ))
                        else:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 2 or grid[j][i] == 3:
                        if visitedCells[j][i] == 2 or visitedCells[j + 1][i] == 2:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[4],
                            ))
                        else:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
        else:
            break
    for i in range(0, 50):
        frames.append(frames[len(frames) - 1])
    frameTime = 15000 / len(frames)
    return [render.Animation(children = frames), frameTime]

def aldous_broder(colorInfo, framesNum, ipf):
    visitedCells = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: Not visited
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Visited
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    grid = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: No walls open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Wall right open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 2: Wall down open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 3: Both right wall and down wall open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    currentCell = [random.number(0, 15), random.number(0, 7)]
    visitedCells[currentCell[1]][currentCell[0]] = 1
    running = True
    frames = []
    for _ in range(0, framesNum):
        if running:
            willStillRun = False
            for i in range(16):
                for j in range(8):
                    if visitedCells[j][i] == 0:
                        willStillRun = True
                        break
                if willStillRun:
                    break
            if willStillRun:
                for _ in range(ipf):
                    visitableDirs = []
                    if currentCell[1] > 0:
                        visitableDirs.append(1)
                    if currentCell[0] < 15:
                        visitableDirs.append(2)
                    if currentCell[1] < 7:
                        visitableDirs.append(3)
                    if currentCell[0] > 0:
                        visitableDirs.append(4)
                    direction = visitableDirs[random.number(0, len(visitableDirs) - 1)]
                    if direction == 1:
                        currentCell[1] -= 1
                        if not visitedCells[currentCell[1]][currentCell[0]]:
                            visitedCells[currentCell[1]][currentCell[0]] = 1
                            grid[currentCell[1]][currentCell[0]] += 2
                    elif direction == 2:
                        if not visitedCells[currentCell[1]][currentCell[0] + 1]:
                            grid[currentCell[1]][currentCell[0]] += 1
                            visitedCells[currentCell[1]][currentCell[0] + 1] = 1
                        currentCell[0] += 1
                    elif direction == 3:
                        if not visitedCells[currentCell[1] + 1][currentCell[0]]:
                            grid[currentCell[1]][currentCell[0]] += 2
                            visitedCells[currentCell[1] + 1][currentCell[0]] = 1
                        currentCell[1] += 1
                    elif direction == 4:
                        currentCell[0] -= 1
                        if not visitedCells[currentCell[1]][currentCell[0]]:
                            visitedCells[currentCell[1]][currentCell[0]] = 1
                            grid[currentCell[1]][currentCell[0]] += 1
            else:
                currentCell = [-1, -1]
                running = False
            x = currentCell[0]
            y = currentCell[1]
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    if (visitedCells[j][i] > 0):
                        if i == x and j == y:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[5]))
                        else:
                            columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                    else:
                        columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 1 or grid[j][i] == 3:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 2 or grid[j][i] == 3:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = colorInfo[3],
                        ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
        else:
            break
    for i in range(0, 100):
        frames.append(frames[len(frames) - 1])
    frameTime = 15000 / len(frames)
    return [render.Animation(children = frames), frameTime]

def recursive_division(colorInfo, *_):
    grid = [
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],  # 0: No walls open
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],  # 1: Wall right open
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],  # 2: Wall down open
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],  # 3: Both right wall and down wall open
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    ]
    currentCell = [-1, -1]
    chambers = [[0, 0, 16, 8]]
    running = True
    frames = []
    for _ in range(0, 1000):
        if running:
            direction = random.number(0, 1)
            oldChamber = []
            availableChambers = []
            for i in range(len(chambers)):
                if chambers[i][2] != 1 and chambers[i][3] != 1:
                    availableChambers.append(i)
            if len(availableChambers) > 0:
                randomChamber = availableChambers[random.number(0, len(availableChambers) - 1)]
                oldChamber = [chambers[randomChamber][0], chambers[randomChamber][1], chambers[randomChamber][2], chambers[randomChamber][3]]
                if direction == 1:  # Vertical line
                    currentCell = [
                        chambers[randomChamber][0] + random.number(0, chambers[randomChamber][2] - 2),
                        chambers[randomChamber][1] + random.number(0, chambers[randomChamber][3] - 1),
                    ]
                    for i in range(chambers[randomChamber][3]):
                        if i + chambers[randomChamber][1] != currentCell[1]:
                            if grid[i + chambers[randomChamber][1]][currentCell[0]] == 1 or grid[i + chambers[randomChamber][1]][currentCell[0]] == 3:
                                grid[i + chambers[randomChamber][1]][currentCell[0]] -= 1

                    # This should create:
                    # A chamber starting at the original start with a width of (currentCell[0]+1) - chambers[randomChamber][0]
                    # A chamber starting at currentCell[0]+1 with a width of chambers[randomChamber][2] + chambers[randomChamber][0] - currentCell[0] - 1
                    newChambers = [
                        [
                            chambers[randomChamber][0],
                            chambers[randomChamber][1],
                            (currentCell[0] + 1) - chambers[randomChamber][0],
                            chambers[randomChamber][3],
                        ],
                        [
                            currentCell[0] + 1,
                            chambers[randomChamber][1],
                            chambers[randomChamber][2] + chambers[randomChamber][0] - currentCell[0] - 1,
                            chambers[randomChamber][3],
                        ],
                    ]
                    chambers.pop(randomChamber)
                    chambers.append(newChambers[0])
                    chambers.append(newChambers[1])
                else:  # Horizontal line
                    currentCell = [
                        chambers[randomChamber][0] + random.number(0, chambers[randomChamber][2] - 1),
                        chambers[randomChamber][1] + random.number(0, chambers[randomChamber][3] - 2),
                    ]
                    for i in range(chambers[randomChamber][2]):
                        if i + chambers[randomChamber][0] != currentCell[0]:
                            if grid[currentCell[1]][i + chambers[randomChamber][0]] == 2 or grid[currentCell[1]][i + chambers[randomChamber][0]] == 3:
                                grid[currentCell[1]][i + chambers[randomChamber][0]] -= 2
                    newChambers = [
                        [
                            chambers[randomChamber][0],
                            chambers[randomChamber][1],
                            chambers[randomChamber][2],
                            (currentCell[1] + 1) - chambers[randomChamber][1],
                        ],
                        [
                            chambers[randomChamber][0],
                            currentCell[1] + 1,
                            chambers[randomChamber][2],
                            chambers[randomChamber][1] - currentCell[1] + chambers[randomChamber][3] - 1,
                        ],
                    ]
                    chambers.pop(randomChamber)
                    chambers.append(newChambers[0])
                    chambers.append(newChambers[1])
            else:
                currentCell = [-1, -1]
                running = False
            x = currentCell[0]
            y = currentCell[1]
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 1 or grid[j][i] == 3:
                        if i == x and j == y and direction == 1:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[5],
                            ))
                        else:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    elif oldChamber:
                        if direction == 1 and oldChamber[1] <= j and (oldChamber[1] + oldChamber[3]) >= j and i == x:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[6],
                            ))
                        else:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = "0000",
                            ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 2 or grid[j][i] == 3:
                        if i == x and j == y and direction == 0:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[5],
                            ))
                        else:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    elif oldChamber:
                        if direction == 0 and oldChamber[0] <= i and (oldChamber[0] + oldChamber[2]) >= i and j == y:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[6],
                            ))
                        else:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = "0000",
                            ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
        else:
            break
    for i in range(0, 10):
        frames.append(frames[len(frames) - 1])
    frameTime = 15000 / len(frames)
    return [render.Animation(children = frames), frameTime]

def fractal_tesselation(colorInfo, *_):
    visitedCells = [
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: Not visited
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Visited
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    grid = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 0: No walls open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 1: Wall right open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 2: Wall down open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # 3: Both right wall and down wall open
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    removedWalls = []
    running = True
    frames = []
    for currentFrame in range(0, 16):
        if running:
            removedWalls = []
            if currentFrame == 1:
                visitedCells[0][1] = 1
            elif currentFrame == 2:
                visitedCells[1][0] = 1
            elif currentFrame == 3:
                visitedCells[1][1] = 1
            elif currentFrame == 4:
                randomSidetoKeep = random.number(0, 3)
                if randomSidetoKeep != 0:
                    grid[0][0] += 1
                    removedWalls.append([0, 0, 0])
                if randomSidetoKeep != 1:
                    grid[0][1] += 2
                    removedWalls.append([1, 0, 1])
                if randomSidetoKeep != 2:
                    grid[1][0] += 1
                    removedWalls.append([0, 1, 0])
                if randomSidetoKeep != 3:
                    grid[0][0] += 2
                    removedWalls.append([0, 0, 1])
            elif currentFrame == 5:
                for a in range(2):
                    for b in range(2):
                        visitedCells[a][2 + b] = 1
                        grid[a][2 + b] = grid[a][b]
            elif currentFrame == 6:
                for a in range(2):
                    for b in range(2):
                        visitedCells[2 + a][b] = 1
                        grid[2 + a][b] = grid[a][b]
            elif currentFrame == 7:
                for a in range(2):
                    for b in range(2):
                        visitedCells[2 + a][2 + b] = 1
                        grid[2 + a][2 + b] = grid[a][b]
            elif currentFrame == 8:
                randomSidetoKeep = random.number(0, 3)
                if randomSidetoKeep != 0:
                    randomWall = random.number(0, 1)
                    grid[randomWall][1] += 1
                    removedWalls.append([1, randomWall, 0])
                if randomSidetoKeep != 1:
                    randomWall = random.number(0, 1)
                    grid[1][2 + randomWall] += 2
                    removedWalls.append([2 + randomWall, 1, 1])
                if randomSidetoKeep != 2:
                    randomWall = random.number(0, 1)
                    grid[2 + randomWall][1] += 1
                    removedWalls.append([1, 2 + randomWall, 0])
                if randomSidetoKeep != 3:
                    randomWall = random.number(0, 1)
                    grid[1][randomWall] += 2
                    removedWalls.append([randomWall, 1, 1])
            elif currentFrame == 9:
                for a in range(4):
                    for b in range(4):
                        visitedCells[a][4 + b] = 1
                        grid[a][4 + b] = grid[a][b]
            elif currentFrame == 10:
                for a in range(4):
                    for b in range(4):
                        visitedCells[4 + a][b] = 1
                        grid[4 + a][b] = grid[a][b]
            elif currentFrame == 11:
                for a in range(4):
                    for b in range(4):
                        visitedCells[4 + a][4 + b] = 1
                        grid[4 + a][4 + b] = grid[a][b]
            elif currentFrame == 12:
                randomSidetoKeep = random.number(0, 3)
                if randomSidetoKeep != 0:
                    randomWall = random.number(0, 3)
                    grid[randomWall][3] += 1
                    removedWalls.append([3, randomWall, 0])
                if randomSidetoKeep != 1:
                    randomWall = random.number(0, 3)
                    grid[3][4 + randomWall] += 2
                    removedWalls.append([4 + randomWall, 3, 1])
                if randomSidetoKeep != 2:
                    randomWall = random.number(0, 3)
                    grid[4 + randomWall][3] += 1
                    removedWalls.append([3, 4 + randomWall, 0])
                if randomSidetoKeep != 3:
                    randomWall = random.number(0, 3)
                    grid[3][randomWall] += 2
                    removedWalls.append([randomWall, 3, 1])
            elif currentFrame == 13:
                for a in range(8):
                    for b in range(8):
                        visitedCells[a][8 + b] = 1
                        grid[a][8 + b] = grid[a][b]
            elif currentFrame == 14:
                randomWall = random.number(0, 7)
                grid[randomWall][7] += 1
                removedWalls.append([7, randomWall, 0])
            squaresChildren = []
            for i in range(0, 16):
                columnChildren = []
                for j in range(0, 8):
                    if visitedCells[j][i] == 1:
                        columnChildren.append(render.Box(width = 2, height = 2, color = colorInfo[3]))
                    else:
                        columnChildren.append(render.Box(width = 2, height = 2, color = "#0000"))
                squaresChildren.append(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = columnChildren,
                    ),
                )
            horizontalChildren = []
            verticalChildren = []
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 15):
                hColumnChildren = []
                for j in range(0, 8):
                    if grid[j][i] == 1 or grid[j][i] == 3:
                        hasBeenRemoved = False
                        for a in removedWalls:
                            if a[0] == i and a[1] == j and a[2] == 0:
                                hasBeenRemoved = True
                                break
                        if hasBeenRemoved:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[5],
                            ))
                        else:
                            hColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    else:
                        hColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                horizontalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = hColumnChildren,
                ))
            horizontalChildren.append(render.Box(width = 1, height = 32, color = "0000"))
            for i in range(0, 16):
                vColumnChildren = []
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                for j in range(0, 7):
                    if grid[j][i] == 2 or grid[j][i] == 3:
                        hasBeenRemoved = False
                        for a in removedWalls:
                            if a[0] == i and a[1] == j and a[2] == 1:
                                hasBeenRemoved = True
                                break
                        if hasBeenRemoved:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[5],
                            ))
                        else:
                            vColumnChildren.append(render.Box(
                                width = 2,
                                height = 2,
                                color = colorInfo[3],
                            ))
                    else:
                        vColumnChildren.append(render.Box(
                            width = 2,
                            height = 2,
                            color = "0000",
                        ))
                vColumnChildren.append(render.Box(width = 2, height = 1, color = "0000"))
                verticalChildren.append(render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = vColumnChildren,
                ))
            frames.append(
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = squaresChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = horizontalChildren,
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = verticalChildren,
                        ),
                    ],
                ),
            )
        else:
            break
    for i in range(0, 3):
        frames.append(frames[len(frames) - 1])
    frameTime = 15000 / len(frames)
    return [render.Animation(children = frames), frameTime]

# Setup
algorithms = [hilbert, binary_tree, depth_first, aldous_broder, recursive_division, fractal_tesselation]
userFriendlyNames = ["Hilbert", "Binary Tree", "Depth-First", "Aldous-Broder", "Recursive Divis.", "Fractal Tessel."]

def main(config):
    aldous_broder_frames = 1000
    aldous_broder_ipf = 3
    colorInfo = ["#AAAAFF", "#000000", "#444444", "#FFFFFF", "#FFFF00", "#00FF00", "#FF0000"]
    possibleAlgorithms = []
    if True:  # Getting color info
        if config.get("color_text") != None:
            colorInfo[0] = config.get("color_text")
        if config.get("color_bg") != None:
            colorInfo[1] = config.get("color_bg")
        if config.get("color_grid") != None:
            colorInfo[2] = config.get("color_grid")
        if config.get("color_main") != None:
            colorInfo[3] = config.get("color_main")
        if config.get("color_marked") != None:
            colorInfo[4] = config.get("color_marked")
        if config.get("color_active") != None:
            colorInfo[5] = config.get("color_active")
        if config.get("color_removed") != None:
            colorInfo[6] = config.get("color_removed")
    if True:  # Algorithm selection and stuff
        if config.get("aldous_broder_frames") != None:
            aldous_broder_frames = int(config.get("aldous_broder_frames"))
        if config.get("aldous_broder_ipf") != None:
            aldous_broder_ipf = int(config.get("aldous_broder_ipf"))
        if config.bool("hilbert") != None:
            if config.bool("hilbert"):
                possibleAlgorithms.append(0)
        else:
            possibleAlgorithms.append(0)
        if config.bool("binary_tree") != None:
            if config.bool("binary_tree"):
                possibleAlgorithms.append(1)
        else:
            possibleAlgorithms.append(1)
        if config.bool("depth_first") != None:
            if config.bool("depth_first"):
                possibleAlgorithms.append(2)
        else:
            possibleAlgorithms.append(2)
        if config.bool("aldous_broder") != None:
            if config.bool("aldous_broder"):
                possibleAlgorithms.append(3)
        else:
            possibleAlgorithms.append(3)
        if config.bool("recursive_division") != None:
            if config.bool("recursive_division"):
                possibleAlgorithms.append(4)
        else:
            possibleAlgorithms.append(4)
        if config.bool("fractal_tesselation") != None:
            if config.bool("fractal_tesselation"):
                possibleAlgorithms.append(5)
        else:
            possibleAlgorithms.append(5)
    if len(possibleAlgorithms) > 0:
        algo_tuple = select_algorithm(possibleAlgorithms)
        return render_algorithm(algo_tuple, colorInfo, aldous_broder_frames, aldous_broder_ipf)
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color_text",
                name = "Name color",
                desc = "Color of the algorithm name.",
                icon = "brush",
                default = "#AAAAFF",
            ),
            schema.Color(
                id = "color_bg",
                name = "Background color",
                desc = "Color of the background, minus the grid.",
                icon = "brush",
                default = "#000000",
            ),
            schema.Color(
                id = "color_grid",
                name = "Grid color",
                desc = "Color of the grid behind the maze.",
                icon = "brush",
                default = "#444444",
            ),
            schema.Color(
                id = "color_main",
                name = "Main color",
                desc = "Color of the main portion of the maze for most algorithms, or the non-marked part of Depth-First Search.",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Color(
                id = "color_marked",
                name = "Marked color",
                desc = "Color of the marked portion of the maze for Depth-First Search.",
                icon = "brush",
                default = "#FFFF00",
            ),
            schema.Color(
                id = "color_active",
                name = "Active color",
                desc = "Color of the active portion of the maze for all algorithms.",
                icon = "brush",
                default = "#00FF00",
            ),
            schema.Color(
                id = "color_removed",
                name = "Removal color",
                desc = "Color of the removed portion of the maze for Recursive Division.",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Toggle(
                id = "hilbert",
                name = "Hilbert",
                desc = "An algorithm that generates from bottom to top, and has no obvious patterns.",
                icon = "gg",
                default = True,
            ),
            schema.Toggle(
                id = "binary_tree",
                name = "Binary Tree",
                desc = "Generates like Hilbert, but it always appears like a binary tree.",
                icon = "gg",
                default = True,
            ),
            schema.Toggle(
                id = "depth_first",
                name = "Depth-First",
                desc = "Also known as Recursive Backtracker, this algorithm does a random walk, but backtracks when it gets cornered.",
                icon = "gg",
                default = True,
            ),
            schema.Toggle(
                id = "aldous_broder",
                name = "Aldous-Broder",
                desc = "Does a random walk and extends the maze when it moves into an empty space. Doesn't always finish.",
                icon = "gg",
                default = True,
            ),
            schema.Text(
                id = "aldous_broder_frames",
                name = "Aldous-Broder # of frames",
                desc = "The max number of frames for Aldus-Broder to run for before it stops.",
                icon = "gg",
                default = "1000",
            ),
            schema.Text(
                id = "aldous_broder_ipf",
                name = "Aldous-Broder iters per frame",
                desc = "The number of iterations per frame for Aldus-Broder.",
                icon = "gg",
                default = "3",
            ),
            schema.Toggle(
                id = "recursive_division",
                name = "Recursive Division",
                desc = "Repeatedly divides the grid into smaller rooms until every room is one unit in either width or height.",
                icon = "gg",
                default = True,
            ),
            schema.Toggle(
                id = "fractal_tesselation",
                name = "Fractal Tesselation",
                desc = "Copies the grid 3 times, then opens 3 random passages.",
                icon = "gg",
                default = True,
            ),
        ],
    )

def select_algorithm(possibleAlgorithms):
    algoIndex = random.number(0, len(possibleAlgorithms) - 1)
    algorithm = algorithms[possibleAlgorithms[algoIndex]]
    userFriendlyName = userFriendlyNames[possibleAlgorithms[algoIndex]]
    return (algorithm, userFriendlyName)

def render_algorithm(algo_tuple, colorInfo, aldous_broder_frames, aldous_broder_ipf):
    result = render.Animation(children = [])
    frameTime = 15000
    xresult = algo_tuple[0](colorInfo, aldous_broder_frames, aldous_broder_ipf)
    result = xresult[0]
    frameTime = xresult[1]

    return render.Root(
        delay = math.floor(frameTime),
        child = render.Stack(
            children = [
                render.Box(width = 64, height = 32, color = colorInfo[1]),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 1, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 2, height = 32, color = colorInfo[2]),
                        render.Box(width = 1, height = 32, color = colorInfo[2]),
                    ],
                ),
                render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 64, height = 1, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 2, color = colorInfo[2]),
                        render.Box(width = 64, height = 1, color = colorInfo[2]),
                    ],
                ),
                result,
                render.Text(
                    content = algo_tuple[1],
                    color = colorInfo[0],
                    font = "tom-thumb",
                ),
            ],
        ),
    )

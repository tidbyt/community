"""
Applet: Color Blocks
Summary: Display color blocks with an optional Matrix-style rain animation
Description: Colored pixel streams fall from the top and lock into the selected block formation.
Author: amhefele
"""

load("render.star", "render")
load("schema.star", "schema")

DISPLAY_WIDTH = 64
DISPLAY_HEIGHT = 32
BLOCK_WIDTH = 16
BLOCK_HEIGHT = 8
DOT_SIZE = 2

# Animation tuning
DOTS_PER_BATCH = 8
RAIN_STEPS = 10
START_HOLD_FRAMES = 5
FINAL_HOLD_FRAMES = 30
RESET_FRAMES = 5

COLORS = [
    schema.Option(display = "White", value = "#ffffff"),
    schema.Option(display = "Silver", value = "#c0c0c0"),
    schema.Option(display = "Gray", value = "#808080"),
    schema.Option(display = "Black", value = "#000000"),
    schema.Option(display = "Maroon", value = "#800000"),
    schema.Option(display = "Olive", value = "#808000"),
    schema.Option(display = "Lime", value = "#00ff00"),
    schema.Option(display = "Green", value = "#008000"),
    schema.Option(display = "Aqua", value = "#00ffff"),
    schema.Option(display = "Teal", value = "#008080"),
    schema.Option(display = "Navy", value = "#000080"),
    schema.Option(display = "Fuchsia", value = "#ff00ff"),
    schema.Option(display = "Purple", value = "#800080"),
]

BLOCK_COLOR_OPTIONS = [
    schema.Option(display = " ", value = "#000000"),
    schema.Option(display = "Yellow", value = "#ffff00"),
    schema.Option(display = "Red", value = "#ff0000"),
    schema.Option(display = "Blue", value = "#0000ff"),
    schema.Option(display = "Green", value = "#00ff00"),
]

SHAPE_OPTIONS = [
    schema.Option(display = "Column", value = "columnShape"),
    schema.Option(display = "T", value = "tShape"),
    schema.Option(display = "Plus", value = "plusShape"),
    schema.Option(display = "Inverted T", value = "invertedTShape"),
]

ANIMATION_OPTIONS = [
    schema.Option(display = "Off", value = "off"),
    schema.Option(display = "On", value = "on"),
]

def getBlockPositions(selectedShape):
    if selectedShape == "tShape":
        return [[16, 4], [32, 4], [24, 12], [24, 20]]

    if selectedShape == "plusShape":
        return [[24, 4], [16, 12], [32, 12], [24, 20]]

    if selectedShape == "invertedTShape":
        return [[24, 4], [24, 12], [16, 20], [32, 20]]

    return [[24, 0], [24, 8], [24, 16], [24, 24]]

def positionedRectangle(x, y, width, height, color):
    return render.Column(
        expanded = True,
        main_align = "start",
        children = [
            render.Box(width = DISPLAY_WIDTH, height = y),
            render.Row(
                expanded = True,
                main_align = "start",
                children = [
                    render.Box(width = x, height = height),
                    render.Box(width = width, height = height, color = color),
                ],
            ),
        ],
    )

def backgroundFrame(backgroundColor, layers = []):
    return render.Box(
        width = DISPLAY_WIDTH,
        height = DISPLAY_HEIGHT,
        color = backgroundColor,
        child = render.Stack(children = layers),
    )

def drawStaticShape(selectedShape, backgroundColor, blockColors):
    positions = getBlockPositions(selectedShape)
    layers = []

    for blockIndex in range(4):
        position = positions[blockIndex]
        layers.append(
            positionedRectangle(
                position[0],
                position[1],
                BLOCK_WIDTH,
                BLOCK_HEIGHT,
                blockColors[blockIndex],
            ),
        )

    return backgroundFrame(backgroundColor, layers)

def buildTargets(selectedShape, blockColors):
    positions = getBlockPositions(selectedShape)
    targets = []

    # Bottom rows are added first so the final shape materializes upward.
    for targetY in reversed(range(0, DISPLAY_HEIGHT, DOT_SIZE)):
        for blockIndex in range(4):
            blockX = positions[blockIndex][0]
            blockY = positions[blockIndex][1]

            if targetY >= blockY and targetY < blockY + BLOCK_HEIGHT:
                for xOffset in range(0, BLOCK_WIDTH, DOT_SIZE):
                    targets.append([
                        blockX + xOffset,
                        targetY,
                        blockColors[blockIndex],
                    ])

    return targets

def drawRainFrame(backgroundColor, targets, settledCount, batchEnd, rainStep):
    layers = []

    # Pixels that have already locked into the final formation.
    for targetIndex in range(settledCount):
        target = targets[targetIndex]
        layers.append(
            positionedRectangle(
                target[0],
                target[1],
                DOT_SIZE,
                DOT_SIZE,
                target[2],
            ),
        )

    # Active streams. Each stream begins on a slightly different frame.
    for targetIndex in range(settledCount, batchEnd):
        target = targets[targetIndex]
        delay = (targetIndex - settledCount) % 4
        activeStep = rainStep - delay

        if activeStep >= 0:
            targetY = target[1]
            denominator = RAIN_STEPS - 5

            if denominator < 1:
                denominator = 1

            if activeStep >= denominator:
                y = targetY
            else:
                y = (targetY * activeStep) // denominator

            streamHeight = 4
            if y >= targetY:
                streamHeight = DOT_SIZE

            # Keep the stream inside the display and out of settled rows.
            if y + streamHeight > targetY + DOT_SIZE:
                streamHeight = DOT_SIZE

            layers.append(
                positionedRectangle(
                    target[0],
                    y,
                    DOT_SIZE,
                    streamHeight,
                    target[2],
                ),
            )

    return backgroundFrame(backgroundColor, layers)

def buildRainAnimation(selectedShape, backgroundColor, blockColors):
    targets = buildTargets(selectedShape, blockColors)
    frames = []

    for _ in range(START_HOLD_FRAMES):
        frames.append(backgroundFrame(backgroundColor))

    # Pixlet's Starlark dialect has no while loops, so batches are generated
    # with a stepped range instead.
    for batchStart in range(0, len(targets), DOTS_PER_BATCH):
        batchEnd = batchStart + DOTS_PER_BATCH

        if batchEnd > len(targets):
            batchEnd = len(targets)

        for rainStep in range(RAIN_STEPS):
            frames.append(
                drawRainFrame(
                    backgroundColor,
                    targets,
                    batchStart,
                    batchEnd,
                    rainStep,
                ),
            )

    completedFrame = drawStaticShape(
        selectedShape,
        backgroundColor,
        blockColors,
    )

    for _ in range(FINAL_HOLD_FRAMES):
        frames.append(completedFrame)

    for _ in range(RESET_FRAMES):
        frames.append(backgroundFrame(backgroundColor))

    return render.Animation(children = frames)

def main(config):
    selectedShape = config.get("shape", "columnShape")
    animationEnabled = config.get("animationEnabled", "off")
    backgroundColor = config.get("backgroundColor", "#000000")

    blockColors = [
        config.get("block1Color", "#ffff00"),
        config.get("block2Color", "#ff0000"),
        config.get("block3Color", "#0000ff"),
        config.get("block4Color", "#00ff00"),
    ]

    if animationEnabled == "on":
        child = buildRainAnimation(
            selectedShape,
            backgroundColor,
            blockColors,
        )
    else:
        child = drawStaticShape(
            selectedShape,
            backgroundColor,
            blockColors,
        )

    return render.Root(child = child)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animationEnabled",
                name = "Animation",
                desc = "Enable the Matrix-style pixel rain animation.",
                icon = "wandMagicSparkles",
                default = ANIMATION_OPTIONS[0].value,
                options = ANIMATION_OPTIONS,
            ),
            schema.Dropdown(
                id = "shape",
                name = "Display Shape",
                desc = "The shape of your blocks.",
                icon = "trowelBricks",
                default = SHAPE_OPTIONS[0].value,
                options = SHAPE_OPTIONS,
            ),
            schema.Dropdown(
                id = "block1Color",
                name = "First block",
                desc = "The color of your first block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[1].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block2Color",
                name = "Second block",
                desc = "The color of your second block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[2].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block3Color",
                name = "Third block",
                desc = "The color of your third block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[3].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block4Color",
                name = "Fourth block",
                desc = "The color of your fourth block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[4].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "backgroundColor",
                name = "Background color",
                desc = "The background color.",
                icon = "brush",
                default = COLORS[3].value,
                options = COLORS,
            ),
        ],
    )

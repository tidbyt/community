"""
Applet: Color Blocks
Summary: Display color blocks
Description: Display your Insights profile color blocks.
Author: amhefele
"""

load("render.star", "render")
load("schema.star", "schema")

#constants
BLOCK_HEIGHT = 8
BLOCK_WIDTH = 16

#selection options
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
    schema.Option(
        display = " ",
        value = "#000000",
    ),
    schema.Option(
        display = "Yellow",
        value = "#ffff00",
    ),
    schema.Option(
        display = "Red",
        value = "#ff0000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000ff",
    ),
    schema.Option(
        display = "Green",
        value = "#00ff00",
    ),
]

SHAPE_OPTIONS = [
    schema.Option(
        display = "Column",
        value = "columnShape",
    ),
    schema.Option(
        display = "T",
        value = "tShape",
    ),
    schema.Option(
        display = "Plus",
        value = "plusShape",
    ),
    schema.Option(
        display = "Inverted T",
        value = "invertedTShape",
    ),
]

#block rendering methods
def drawBlocks(selectedShape, block1Color, block2Color, block3Color, block4Color):
    renderShape = drawColumnBlocks(block1Color, block2Color, block3Color, block4Color)

    # if selectedShape == SHAPE_OPTIONS[0].value:
    #     renderShape = drawColumnBlocks(block1Color, block2Color, block3Color, block4Color)

    if selectedShape == SHAPE_OPTIONS[1].value:
        renderShape = drawTBlocks(block1Color, block2Color, block3Color, block4Color)

    if selectedShape == SHAPE_OPTIONS[2].value:
        renderShape = drawPlusBlocks(block1Color, block2Color, block3Color, block4Color)

    if selectedShape == SHAPE_OPTIONS[3].value:
        renderShape = drawInvertedTBlocks(block1Color, block2Color, block3Color, block4Color)

    return renderShape

def drawColumnBlocks(block1Color, block2Color, block3Color, block4Color):
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block1Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block2Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block3Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block4Color),
                ],
            ),
        ],
    )

def drawTBlocks(block1Color, block2Color, block3Color, block4Color):
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block1Color),
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block2Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block3Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block4Color),
                ],
            ),
        ],
    )

def drawPlusBlocks(block1Color, block2Color, block3Color, block4Color):
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block1Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block2Color),
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block3Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block4Color),
                ],
            ),
        ],
    )

def drawInvertedTBlocks(block1Color, block2Color, block3Color, block4Color):
    return render.Column(
        children = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block1Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block2Color),
                ],
            ),
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block3Color),
                    render.Box(width = BLOCK_WIDTH, height = BLOCK_HEIGHT, color = block4Color),
                ],
            ),
        ],
    )

#main
def main(config):
    #get configuration values
    selectedShape = config.get("shape", "column")
    block1Color = config.get("block1Color", "#000000")
    block2Color = config.get("block2Color", "#000000")
    block3Color = config.get("block3Color", "#000000")
    block4Color = config.get("block4Color", "#000000")
    backgroundColor = config.get("backgroundColor", "#000000")

    # return main view
    return render.Root(
        child = render.Box(
            color = backgroundColor,
            child = drawBlocks(selectedShape, block1Color, block2Color, block3Color, block4Color),
        ),
    )

#configuration settings
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "shape",
                name = "Display Shape",
                desc = "The shape of your blocks",
                icon = "trowelBricks",
                default = SHAPE_OPTIONS[0].value,
                options = SHAPE_OPTIONS,
            ),
            schema.Dropdown(
                id = "block1Color",
                name = "First block",
                desc = "The color of your first block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[0].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block2Color",
                name = "Second block",
                desc = "The color of your second block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[0].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block3Color",
                name = "Third block",
                desc = "The color of your third block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[0].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "block4Color",
                name = "Fourth block",
                desc = "The color of your fourth block.",
                icon = "brush",
                default = BLOCK_COLOR_OPTIONS[0].value,
                options = BLOCK_COLOR_OPTIONS,
            ),
            schema.Dropdown(
                id = "backgroundColor",
                desc = "Background color",
                name = "Background color",
                icon = "brush",
                default = COLORS[3].value,
                options = COLORS,
            ),
        ],
    )

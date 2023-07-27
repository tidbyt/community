"""
Applet: Gradient
Summary: Displays dynamic gradients
Description: Customize gradient fills for your Tidbyt.
Author: Jeffrey Lancaster
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PIXLET_W = 64
PIXLET_H = 32

def median(val1, val2):
    return math.floor((val1 + val2) / 2)

def makeRange(minValue, maxValue, numValues):
    rangeArray = []
    for i in range(0, numValues):
        step = (maxValue - minValue) / numValues
        calcValue = math.round(minValue + (i * step))
        rangeArray.append(calcValue)
    return rangeArray

def rgbRange(start, end, steps):
    rRange = makeRange(start[0], end[0], steps)
    gRange = makeRange(start[1], end[1], steps)
    bRange = makeRange(start[2], end[2], steps)
    returnRange = []
    for n in range(0, steps):
        returnRange.append([rRange[n], gRange[n], bRange[n]])
    return returnRange

# from: https://www.educative.io/answers/how-to-convert-hex-to-rgb-and-rgb-to-hex-in-python
def hex_to_rgb(hex):
    hex = hex.replace("#", "")
    rgb = []
    for i in (0, 2, 4):
        decimal = int(hex[i:i + 2], 16)
        rgb.append(decimal)
    return tuple(rgb)

def rgb_to_hex(r, g, b):
    rgbArr = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    hex = "#"
    r = math.floor(r)
    g = math.floor(g)
    b = math.floor(b)
    for i in (r, g, b):
        secondNum = i % 16
        firstNum = math.floor((i - secondNum) / 16)
        hex += rgbArr[firstNum] + rgbArr[secondNum]
    return hex

def randomColor():
    randomRed = random.number(0, 255)
    randomGreen = random.number(0, 255)
    randomBlue = random.number(0, 255)
    return rgb_to_hex(randomRed, randomGreen, randomBlue)

def four_color_gradient(topL, topR, botL, botR):
    # convert inputs to rgb
    topLrgb = hex_to_rgb(topL)
    topRrgb = hex_to_rgb(topR)
    botLrgb = hex_to_rgb(botL)
    botRrgb = hex_to_rgb(botR)

    # determine left column and right column ranges: PIXLET_H
    leftCol = rgbRange(topLrgb, botLrgb, PIXLET_H)
    rightCol = rgbRange(topRrgb, botRrgb, PIXLET_H)

    # for each row, determine range: PIXLET_W
    gradientArray = []
    for n in range(0, PIXLET_H):
        rowGradient = rgbRange(leftCol[n], rightCol[n], PIXLET_W)

        # convert row to hex values
        for n, i in enumerate(rowGradient):
            rowGradient[n] = rgb_to_hex(i[0], i[1], i[2])
        gradientArray.append(rowGradient)

    return gradientArray

def two_color_gradient(topL, botR):
    topLrgb = hex_to_rgb(topL)
    botRrgb = hex_to_rgb(botR)
    medianR = median(topLrgb[0], botRrgb[0])
    medianG = median(topLrgb[1], botRrgb[1])
    medianB = median(topLrgb[2], botRrgb[2])

    # average r, g, b for other two corners
    medianRGB = rgb_to_hex(medianR, medianG, medianB)
    return four_color_gradient(topL, medianRGB, medianRGB, botR)

def main(config):
    random.seed(time.now().unix // 15)

    # define gradientArray and labels
    gradientArray = []
    labels = []

    if config.get("gradient_type") == "random":
        color1 = randomColor()
        color2 = randomColor()
        color3 = randomColor()
        color4 = randomColor()
        gradientArray = four_color_gradient(color1, color2, color3, color4)
        labels = [color1, color2, color3, color4]
    elif config.get("gradient_type") == "4color":
        color1 = config.get("color1")
        color2 = config.get("color2")
        color3 = config.get("color3")
        color4 = config.get("color4")
        gradientArray = four_color_gradient(color1, color2, color3, color4)
        labels = [color1, color2, color3, color4]
    elif config.get("gradient_type") == "2color":
        color1 = config.get("color1")
        color2 = config.get("color2")
        gradientArray = two_color_gradient(color1, color2)
        labels = [color1, color2]
    else:
        gradientArray = four_color_gradient("#FF0000", "#FFFF00", "#0000FF", "#FFFFFF")
        labels = ["#FF0000", "#FFFF00", "#0000FF", "#FFFFFF"]

    # show rangeArray
    columnChildren = []
    if len(gradientArray) > 0:
        for j in range(0, PIXLET_H):
            # build the column
            rowChildren = []
            for i in range(0, PIXLET_W):
                # build the row
                rowChildren.append(
                    render.Box(width = 1, height = 1, color = gradientArray[j][i]),
                )
            columnChildren.append(
                render.Row(
                    children = rowChildren,
                ),
            )

    stackChildren = [render.Column(children = columnChildren)]

    GLOBAL_FONT = "tom-thumb"  # or "CG-pixel-3x5-mono"

    if config.bool("labels", False):
        if len(labels) == 4:
            stackChildren.extend([
                render.Padding(
                    child = render.Text(content = labels[0].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (1, 1, 1, 1),
                ),
                render.Padding(
                    child = render.Text(content = labels[1].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (40, 1, 1, 1),
                ),
                render.Padding(
                    child = render.Text(content = labels[2].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (1, 26, 1, 1),
                ),
                render.Padding(
                    child = render.Text(content = labels[3].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (40, 26, 1, 1),
                ),
            ])
        elif len(labels) == 2:
            stackChildren.extend([
                render.Padding(
                    child = render.Text(content = labels[0].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (1, 1, 1, 1),
                ),
                render.Padding(
                    child = render.Text(content = labels[1].replace("#", ""), color = "#000", font = GLOBAL_FONT),
                    pad = (40, 26, 1, 1),
                ),
            ])

    return render.Root(
        child = render.Stack(
            children = stackChildren,
        ),
    )

def more_gradient_options(gradient_type):
    if gradient_type == "2color":
        return [
            schema.Color(
                id = "color1",
                name = "Color #1",
                desc = "Top left corner",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Color(
                id = "color2",
                name = "Color #2",
                desc = "Bottom right corner",
                icon = "brush",
                default = "#0000FF",
            ),
        ]
    elif gradient_type == "4color":
        return [
            schema.Color(
                id = "color1",
                name = "Color #1",
                desc = "Top left corner",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Color(
                id = "color2",
                name = "Color #2",
                desc = "Top right corner",
                icon = "brush",
                default = "#FFFF00",
            ),
            schema.Color(
                id = "color3",
                name = "Color #3",
                desc = "Bottom left corner",
                icon = "brush",
                default = "#0000FF",
            ),
            schema.Color(
                id = "color4",
                name = "Color #4",
                desc = "Bottom right corner",
                icon = "brush",
                default = "#FFFFFF",
            ),
        ]
    else:
        return []

def get_schema():
    gradientOptions = [
        schema.Option(
            display = "Default",
            value = "default",
        ),
        schema.Option(
            display = "Random",
            value = "random",
        ),
        schema.Option(
            display = "Pick 2",
            value = "2color",
        ),
        schema.Option(
            display = "Pick 4",
            value = "4color",
        ),
    ]

    # icons from: https://fontawesome.com/
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "gradient_type",
                name = "Gradient Type",
                icon = "circleHalfStroke",
                desc = "Which gradient to show",
                default = gradientOptions[0].value,
                options = gradientOptions,
            ),
            schema.Toggle(
                id = "labels",
                name = "Text",
                desc = "Show hex values?",
                icon = "font",
                default = False,
            ),
            #schema.Toggle(
            #    id = "animation",
            #    name = "Animation",
            #    desc = "Animate the gradient?",
            #    icon = "arrows",
            #    default = False,
            #),
            #schema.Toggle(
            #    id = "rotation",
            #    name = "Rotation",
            #    desc = "Rotate the gradient?",
            #    icon = "syncAlt",
            #    default = False,
            #),
            schema.Generated(
                id = "generated",
                source = "gradient_type",
                handler = more_gradient_options,
            ),
        ],
    )

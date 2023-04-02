"""
Applet: TIX Clock
Summary: Coloful blocks tell time
Description: A Tidbyt version of the TIX clock. It uses arrays of colorful blocks to show the time.
Author: pawliger
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Location and timezone defaults

DEFAULT_LOCATION = {
    "lat": 37.295694914604105,
    "lng": -121.99696200840278,
    "locality": "San_Jose",
}

DEFAULT_TIMEZONE = "America/Los_Angeles"

# 12/24 hour option

DEFAULT_IS_24_HOUR = False

# Color Themes

TIX_THEME_NAME = "Classic TIX"
CMYK_THEME_NAME = "CMYK"
GRAYSCALE_THEME_NAME = "Grayscale"
SPRING_THEME_NAME = "Spring"
SUMMER_THEME_NAME = "Summer"
FALL_THEME_NAME = "Fall"
WINTER_THEME_NAME = "Winter"

# Use the classic TIX theme by default

DEFAULT_THEME_NAME = TIX_THEME_NAME

# This dictionary is needed for the options UI

THEME_NAMES = {
    TIX_THEME_NAME: TIX_THEME_NAME,
    SPRING_THEME_NAME: SPRING_THEME_NAME,
    SUMMER_THEME_NAME: SUMMER_THEME_NAME,
    FALL_THEME_NAME: FALL_THEME_NAME,
    WINTER_THEME_NAME: WINTER_THEME_NAME,
    CMYK_THEME_NAME: CMYK_THEME_NAME,
    GRAYSCALE_THEME_NAME: GRAYSCALE_THEME_NAME,
}

# Indices into the theme color array

HOURS_TENS_COLOR_INDEX = 0
HOURS_ONES_COLOR_INDEX = 1
MINUTES_TENS_COLOR_INDEX = 2
MINUTES_ONES_COLOR_INDEX = 3

THEME_COLORS = {
    TIX_THEME_NAME: ["#f00", "#0f0", "#00f", "#f00"],
    SPRING_THEME_NAME: ["#e7d", "#7e7", "#ee4", "#4fb"],
    SUMMER_THEME_NAME: ["#ff0", "#f70", "#f00", "#ff0"],
    FALL_THEME_NAME: ["#752", "#c61", "#ee4", "#a34"],
    WINTER_THEME_NAME: ["#fff", "#fff", "#fff", "#fff"],
    CMYK_THEME_NAME: ["#0ff", "#f0f", "#ff0", "#111"],
    GRAYSCALE_THEME_NAME: ["#999", "#999", "#999", "#999"],
}

GRAYED_OUT_COLOR = "#333"  # for lights that are off

# Layout parameters

# Size of each light. 5x4 is the closest to the original TIX clock

BOX_HEIGHT = 5
BOX_WIDTH = 4
BOX_PADDING = 1

# Spacer needed to be cheated a bit to make all the columns fit

SPACER_WIDTH = (BOX_WIDTH - 1)

# 3 rows of lights

ROWS_OF_BOXES = 3

# Column count for each digit * 3 rows per column

HOURS_TENS_COLUMNS = 1  # 0 - 2
HOURS_ONES_COLUMNS = 3  # 0 - 9

MINUTES_TENS_COLUMNS = 2  # 0 - 5
MINUTES_ONES_COLUMNS = 3  # 0 - 9

# Indexes into light arrays

TIME_INDEX = 0
COLUMNS_INDEX = 1
COLOR_INDEX = 2
BOXES_INDEX = 3

# Misc constants

BOX_ON = True
BOX_OFF = False

# Return a Box to be used later for populating each array of lights for each time digit

def getPaddedBox(box, isBoxOn):
    if (isBoxOn):
        boxColor = box[COLOR_INDEX]
    else:
        boxColor = GRAYED_OUT_COLOR

    return render.Padding(
        render.Box(
            width = BOX_WIDTH,
            height = BOX_HEIGHT,
            color = boxColor,
        ),
        pad = BOX_PADDING,
    )

# Return an array of Boxes to be used in Rows and Columns

def getArrayOfPaddedBoxes(box, row):
    boxArray = []

    for col in range(0, box[COLUMNS_INDEX]):
        boxIndex = (row * box[COLUMNS_INDEX]) + col
        boxArray.append(box[BOXES_INDEX][boxIndex])

    return boxArray

# Return an array of Rows of Boxes

def getArrayOfRowsOfPaddedBoxes(box):
    rowArray = []

    for row in range(0, ROWS_OF_BOXES):
        rowArray.append(
            render.Row(
                children = getArrayOfPaddedBoxes(box, row),
            ),
        )

    return rowArray

# Return a Column of Rows for each digit

def renderArrayOfRowsOfPaddedBoxes(box):
    return render.Column(
        expanded = True,
        main_align = "center",
        children = getArrayOfRowsOfPaddedBoxes(box),
    )

# Return a Column spacer

def renderSpacer():
    return render.Column(
        children = [render.Box(width = SPACER_WIDTH)],
    )

# Return an array [size] of Booleans where amount of them are set to True, the rest False
# Indicates which lights are on for each digit

def getOnOffSwitches(size, amount):
    onOffSwitches = []

    # start with all lights off

    for _ in range(0, size):
        onOffSwitches.append(False)

    # if we didn't want any set, we're done

    if amount == 0:
        return onOffSwitches

    count = 0

    #   I want this here: while count != amount:
    #   But "while" seems to be prohibited?

    for _ in range(0, 100):  # never need more than 20 in tests, but...
        checkSwitch = random.number(0, size - 1)
        if (onOffSwitches[checkSwitch] == False):
            onOffSwitches[checkSwitch] = True
            count = count + 1
        if (count == amount):
            break

    return onOffSwitches

# The main function that draws each frame

def renderFrame(current_time, use24HourFormat, colorThemeName):
    if use24HourFormat:
        hourFormat = "15"
    else:
        hourFormat = "03"

    hours = int(current_time.format(hourFormat))
    hoursTens = int(hours // 10)
    hoursOnes = int(math.mod(hours, 10))

    minutes = int(current_time.format("04"))
    minutesTens = int(minutes // 10)
    minutesOnes = int(math.mod(minutes, 10))

    # for fast testing

    # seconds = int(current_time.format("05"))
    # secondsTens = int(seconds / 10)
    # secondsOnes = int(math.mod(seconds, 10))

    # minutesTens = ssTens
    # minutesOnes = ssOnes

    # for screenshots

    # hoursTens = 1
    # hoursOnes = 2
    # minutesTens = 3
    # minutesOnes = 5

    # print("time: ", hourFormat, hoursTens, hoursOnes, minutesTens, minutesOnes)

    # Dictionary of arrays of Boxes for each digit

    hours_tens_boxes = []
    hours_ones_boxes = []
    minutes_tens_boxes = []
    minutes_ones_boxes = []

    boxes = {
        "hours_tens": [
            hoursTens,
            HOURS_TENS_COLUMNS,
            THEME_COLORS[colorThemeName][HOURS_TENS_COLOR_INDEX],
            hours_tens_boxes,
        ],
        "hours_ones": [
            hoursOnes,
            HOURS_ONES_COLUMNS,
            THEME_COLORS[colorThemeName][HOURS_ONES_COLOR_INDEX],
            hours_ones_boxes,
        ],
        "minutes_tens": [
            minutesTens,
            MINUTES_TENS_COLUMNS,
            THEME_COLORS[colorThemeName][MINUTES_TENS_COLOR_INDEX],
            minutes_tens_boxes,
        ],
        "minutes_ones": [
            minutesOnes,
            MINUTES_ONES_COLUMNS,
            THEME_COLORS[colorThemeName][MINUTES_ONES_COLOR_INDEX],
            minutes_ones_boxes,
        ],
    }

    # Populate the sets of Boxes for each digit

    for boxArray in boxes.values():
        numberOfBoxes = ROWS_OF_BOXES * boxArray[COLUMNS_INDEX]

        onOffSwitches = getOnOffSwitches(numberOfBoxes, boxArray[TIME_INDEX])

        for boxIndex in range(0, numberOfBoxes):
            isBoxOn = onOffSwitches[boxIndex]
            boxArray[BOXES_INDEX].append(getPaddedBox(boxArray, isBoxOn))
            boxIndex = boxIndex + 1

    # Now draw them as columns of rows

    return render.Row(
        main_align = "space_evenly",
        children = [
            renderArrayOfRowsOfPaddedBoxes(boxes["hours_tens"]),
            renderSpacer(),
            renderArrayOfRowsOfPaddedBoxes(boxes["hours_ones"]),
            renderSpacer(),
            renderArrayOfRowsOfPaddedBoxes(boxes["minutes_tens"]),
            renderSpacer(),
            renderArrayOfRowsOfPaddedBoxes(boxes["minutes_ones"]),
        ],
    )

# Main entry

def main(config):
    random.seed(time.now().unix // 15)

    # Get the current time in 24 hour format

    location = config.get("location")

    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get(
        "timezone",
        config.get("$tz", DEFAULT_TIMEZONE),
    )

    # Get the current time

    use24HourFormat = config.bool("is24hr", DEFAULT_IS_24_HOUR)

    if use24HourFormat:
        timeFormat = "15:04"
    else:
        timeFormat = "03:04"

    current_time = time.parse_time(
        time.now().in_location(timezone).format(timeFormat),
        format = timeFormat,
        location = timezone,
    )

    # print(use24HourFormat, timeFormat, current_time)

    # Get color choices

    colorThemeName = config.get("colorTheme", DEFAULT_THEME_NAME)

    # Set up the animation frames

    SECONDS_PER_FRAME = 4
    NUMBER_OF_FRAMES = 30

    # NUMBER_OF_FRAMES frames, SECONDS_PER_FRAME seconds apart

    clockFrames = []

    for _ in range(0, NUMBER_OF_FRAMES):
        clockFrames.append(renderFrame(
            current_time,
            use24HourFormat,
            colorThemeName,
        ))
        current_time = current_time + (SECONDS_PER_FRAME * time.second)

    # display one frame per SECONDS_PER_FRAME seconds

    return render.Root(

        # SECONDS_PER_FRAME msec delay
        delay = SECONDS_PER_FRAME * 1000,

        # max_age seconds TTL
        max_age = NUMBER_OF_FRAMES * SECONDS_PER_FRAME,
        child = render.Animation(
            children = clockFrames,
        ),
    )

# User settings

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location, used for determining timezone",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is24hr",
                name = "24 hour format",
                desc = "Toggle between 12/24 hour clock",
                icon = "clock",
                default = DEFAULT_IS_24_HOUR,
            ),
            schema.Dropdown(
                id = "colorTheme",
                name = "Color Theme",
                icon = "brush",
                desc = "Color theme",
                options = [
                    schema.Option(display = theme_name, value = theme_colors)
                    for (theme_name, theme_colors) in THEME_NAMES.items()
                ],
                default = THEME_NAMES.get(DEFAULT_THEME_NAME),
            ),
        ],
    )

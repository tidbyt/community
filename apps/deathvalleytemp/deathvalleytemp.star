"""
Applet: Death Valley Thermometer
Summary: Temperature in F and C
Description: Based on the thermometers at Death Valley National Park
Author: Kyle Stark @kaisle51
Thanks: //Code usage: Steve Otteson. Sprite source: https://www.youtube.com/watch?v=RCL1iwIU57k
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("random.star", "random")
load("encoding/json.star", "json")

DEFAULT_TIME_ZONE = "America/Phoenix"
BG_COLOR = "#95a87e"

#12 x 13
CELCIUS_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAE9JREFUKJGtkVEKACAIQ2d0/yvbRwaZxhJ6EEo4lymYqEWBR5GgJNftoGcdDpFz7XZxe1JgOdDCF9KBv5I6tKqICcoOAba4fUcAIOz/wwwDfZoPEer2YU8AAAAASUVORK5CYII=
""")

#12 x 12
FAHRENHEIT_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAEtJREFUKJGVkFEKACAIQ2d4/yvbRwZqhuxBKOG2UnAwr4KMocGG3sKBdg5FlFLVL35PergJ42AV/IjpACCTc7slanixoklAJ1C0f9jIHw8RR0OxxAAAAABJRU5ErkJggg==
""")

def main(config):
    FRAME_DELAY = 750

    def getFrames(animationName):
        FRAMES = []
        for i in range(0, len(animationName[0])):
            FRAMES.extend([
                render.Column(
                    children = [
                        render.Box(
                            width = animationName[1],
                            height = animationName[2],
                            child = render.Image(base64.decode(animationName[0][i]), width = animationName[1], height = animationName[2]),
                        ),
                    ],
                ),
            ])
        return FRAMES

    # def getPikachu(animationName):
    #  setDelay(animationName)
    #  return render.Padding(
        #     pad = (animationName[3], animationName[4], 0, 0),
        #     child = render.Animation(
            #         getFrames(animationName),
            #    ),
            #   )

    def setDelay(animationName):
        FRAME_DELAY = animationName[5]
        return FRAME_DELAY

    LOCATION = config.get("location")
    LOCATION = json.decode(LOCATION) if LOCATION else {}
    TIME_ZONE = LOCATION.get(
        "timezone",
        config.get("$tz", DEFAULT_TIME_ZONE),
    )
    TIME_NOW = time.now().in_location(TIME_ZONE)
    HOUR = int(TIME_NOW.format("15"))
    MINUTE = int(TIME_NOW.format("4"))
    DATE = int(TIME_NOW.format("2"))
    DAY = TIME_NOW.format("Mon")
    RANDOM_NUMBER = random.number(0, 100)

    # available actions (1):
    # READ

    #action():
       # return READ

    return render.Root(
        # delay = setDelay(action()),
        child = render.Stack(
            children = [
                render.Box( # border
                    width = 64,
                    height = 32,
                    color = "#ddd",
                ),
                render.Padding(
                    render.Box( # inner box
                        width = 58,
                        height = 30,
                        color = "#bbb",
                    ),
                    pad = (5, 1, 0, 0),
                ),
                render.Padding(
                    render.Box( # black box F
                        width = 27,
                        height = 15,
                        color = "#000",
                    ),
                    pad = (11, 1, 0, 0),
                ),
                render.Padding(
                    render.Box( # black box C
                        width = 18,
                        height = 15,
                        color = "#000",
                    ),
                    pad = (11, 16, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = FAHRENHEIT_IMG,
                        width = 12,
                        height = 12,
                    ),
                    pad = (40, 2, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = CELCIUS_IMG,
                        width = 12,
                        height = 13,
                    ),
                    pad = (31, 17, 0, 0),
                ),
                #render.Box(
                #    render.Row(
                #        expanded = True,
                #        main_align = "space_evenly",
                #        children = [
                #            render.Text(
                #                content = "126",
                #                font = "6x13",
                #                color = "#f5f24f",
                #            ),
                #        ],
                #    ),
                #    width = 64,
                #    height = 22,
                #),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "So Pikachu's activities match the time of day",
                icon = "place",
            ),
        ],
    )

# Animation frames:
# READ
READ_1 = """iVBORw0KGgoAAAANSUhEUgAAACAAAAAPCAYAAACFgM0XAAAAAXNSR0IArs4c6QAAANtJREFUOI3FVbsRgzAMFbkMQc8elCxBzVSuvQQle7hnC6fIKfei83OkHHeoAUmW9KyfRW6moacc56V6nJzHHvKD512G2zrRMykXCgLt2blnD8A/hLdV4CkXmqUQAL0FOreBrbwVHEG6AaRcvpxbnpVpWydJslQFMc5Lxcw8vADUAL9MzwiDK4UAqLF1wuQseMrlAzYEQI2jels6kfc0nMc+uAHgKGn9kdf/XhZa+tAUtJz/CmgzYvnQFLSCWznrD8wQ2oR7oEW9JsTyKH/5Ko6UwS6lSx4jD7FV/AKZtJEg8ClOMQAAAABJRU5ErkJggg=="""
READ_2 = """iVBORw0KGgoAAAANSUhEUgAAACAAAAAPCAYAAACFgM0XAAAAAXNSR0IArs4c6QAAANVJREFUOI3FlUESwyAIRWMnh+jee3TZS7j2VK49lmexm9D5EiDQyUzZZBCBF1Dctj9LsozP13t6gtSSzTitD74/BoAOWnAJ4rCJP0H7dwvgF2l9LAkJXgMNAWApeVUosbB+SoyQboDWxxKc61qbaskLeOtjYlUeXgBywK9mN/wnBw0BkDMPoq1ryVsfX9gQADlH7bx1x1qqJSc3APaS+o86BL6MgxK6BVLwq4S8IlwP3QIpuTXlUMcKoU/4DEhiHUJsD+k4E24ZxZE28El4y2PkEe3B+gDG6IZ1VyfnJQAAAABJRU5ErkJggg=="""
READ_3 = """iVBORw0KGgoAAAANSUhEUgAAACAAAAAPCAYAAACFgM0XAAAAAXNSR0IArs4c6QAAAOlJREFUOI29VTEShDAIJDc+wt5/WOYT1r4qdT5h6T/S+4tYMcMgG/Bu5raKYQ0LAUL0J8xr7vOau95P1uYbXOeRPMcj7sSLfVteOy+1De3zmvu+LUPeBC1fQkYsg0KZggIs1aMssWPNKbU9nEuRpoBSm+kM7XOqLezbQoVyZxGSW2qjD4pIZ8C77wjHEgoFaCKKUB7qXZGMnMVCAYxI5B5fCmP7dR7pOo9k1oBuHV6jCKXda2d9NuyC6FzweF4twS6IOtRcVDsyS/IftwYiGBWhLDj+lnMhoQESgVcbmkf0nIg/P0ZRoFF8A1UgjdVWjc81AAAAAElFTkSuQmCC"""

# Animations list: [[frames], width, height, xPosition, yPosition, frameMilliseconds]
READ = [
    [READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_3, READ_3, READ_3],
    32,
    15,
    5,
    12,
    750,
]
"""
Applet: Death Valley Thermometer
Summary: Death Valley temp in F and C
Description: Based on the thermometers at Death Valley National Park, one of the hottest places on earth
Author: Kyle Stark @kaisle51
Thanks: Dubhouze-Tāvis/tavdog for general help and FtoC, Chad Milburn for dark mode logic, wshue0 for API stuff
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_DARK_MODE = False
CACHE_TTL_SECONDS = 1799  #half hour
WEATHER_URL = "https://api.weather.gov/gridpoints/VEF/63,120/forecast/hourly"
IMG_CELCIUS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAE9JREFUKJGtkVEKACAIQ2d0/yvbRwaZxhJ6EEo4lymYqEWBR5GgJNftoGcdDpFz7XZxe1JgOdDCF9KBv5I6tKqICcoOAba4fUcAIOz/wwwDfZoPEer2YU8AAAAASUVORK5CYII=
""")
IMG_CELCIUS_WHITE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAFNJREFUKJGtkUkKwEAIBKuD//9y5zQgEzUZSJ1U1HYRgG0DSBKJFacLVrYTAPHosDXbVUOSupEq4mviK+XCv9IpXKdFY8GxQsX4uPyj5Y/3r3a4Ael+O/mTPITQAAAAAElFTkSuQmCC
""")
IMG_FAHRENHEIT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAEtJREFUKJGVkFEKACAIQ2d4/yvbRwZqhuxBKOG2UnAwr4KMocGG3sKBdg5FlFLVL35PergJ42AV/IjpACCTc7slanixoklAJ1C0f9jIHw8RR0OxxAAAAABJRU5ErkJggg==
""")
IMG_FAHRENHEIT_WHITE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAE9JREFUKJGVkMENwDAIA88V+6/sviKRFKJyL0DYJhGAbQNIEok1pxtWtRMA8XE4zM7UkKTupIr4u7gJOnL66q/O5S9Nl5+p6CoYJ4zo3vACENE7+ZrutVcAAAAASUVORK5CYII=
""")

def main(config):
    dark_mode = config.bool("dark_mode") if config.bool("dark_mode") != None and config.bool("dark_mode") != "" else DEFAULT_DARK_MODE

    tempF = get_cachable_data(WEATHER_URL, CACHE_TTL_SECONDS)
    tempFstring = str(int(math.round(float(tempF)))) if tempF != "Err" else "Err"
    tempFarray = []

    if len(tempFstring) == 2:
        tempFarray = ["x", tempFstring[0], tempFstring[1]]
    elif len(tempFstring) == 3:
        if tempFstring == "Err":
            tempFarray = ["E", "R", "R"]
        else:
            tempFarray = [tempFstring[0], tempFstring[1], tempFstring[2]]

    def FtoC(F):
        c = (float(F) - 32) * 0.55
        c = int(c * 10)
        return c / 10.0

    tempC = FtoC(tempF) if tempFstring != "Err" else ""
    tempCstring = str(int(tempC)) if tempFstring != "Err" else ""
    tempCarray = []

    if len(tempCstring) == 2:
        tempCarray = [tempCstring[0], tempCstring[1]]
    elif len(tempCstring) == 1:
        tempCarray = ["x", tempCstring[0]]
    else:
        tempCarray = ["-", "-"]

    def getTempDigit(digit):
        if digit == "1":
            return IMG_ONE
        elif digit == "2":
            return IMG_TWO
        elif digit == "3":
            return IMG_THREE
        elif digit == "4":
            return IMG_FOUR
        elif digit == "5":
            return IMG_FIVE
        elif digit == "6":
            return IMG_SIX
        elif digit == "7":
            return IMG_SEVEN
        elif digit == "8":
            return IMG_EIGHT
        elif digit == "9":
            return IMG_NINE
        elif digit == "0":
            return IMG_ZERO
        elif digit == "E":
            return IMG_E
        elif digit == "R":
            return IMG_R
        else:
            return IMG_DASH

    def generateImageF(i):
        if tempFarray[i] == "x":
            return render.Box(
                width = 9,
                height = 15,
                color = "#000",
            )
        else:
            return render.Image(
                src = base64.decode(getTempDigit(tempFarray[i])),
                width = 9,
                height = 15,
            )

    def layoutF():
        return render.Padding(
            child = render.Box(
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                        generateImageF(0),
                        generateImageF(1),
                        generateImageF(2),
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                    ],
                ),
                color = "#000",
                width = 29,
                height = 15,
            ),
            pad = (11, 1, 0, 0),
        )

    def generateImageC(i):
        if tempCarray[i] == "x":
            return render.Box(
                width = 9,
                height = 15,
                color = "#000",
            )
        else:
            return render.Image(
                src = base64.decode(getTempDigit(tempCarray[i])),
                width = 9,
                height = 15,
            )

    def layoutC():
        return render.Padding(
            child = render.Box(
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                        generateImageC(0),
                        generateImageC(1),
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                    ],
                ),
                color = "#000",
                width = 20,
                height = 15,
            ),
            pad = (11, 16, 0, 0),
        )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    # border
                    width = 64,
                    height = 32,
                    color = "#fff" if dark_mode == False else "",
                ),
                render.Padding(
                    render.Box(
                        # inner box
                        width = 58,
                        height = 30,
                        color = "#e5ffff" if dark_mode == False else "",
                    ),
                    pad = (3, 1, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_FAHRENHEIT if dark_mode == False else IMG_FAHRENHEIT_WHITE,
                        width = 12,
                        height = 12,
                    ),
                    pad = (42, 2, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_CELCIUS if dark_mode == False else IMG_CELCIUS_WHITE,
                        width = 12,
                        height = 13,
                    ),
                    pad = (33, 17, 0, 0),
                ),
                layoutF(),
                layoutC(),
            ],
        ),
    )

def get_cachable_data(url, timeout):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        return "Err"

    temp_data = res.json()
    temp_f = str(temp_data["properties"]["periods"][0]["temperature"])
    cache.set(key, temp_f, ttl_seconds = timeout)

    return temp_f

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "dark_mode",
                name = "Dark mode",
                desc = "Toggle between light and dark modes",
                icon = "lightbulb",
                default = False,
            ),
        ],
    )

# number images
IMG_ONE = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAACdJREFUKJFjYKAL+Poh4D8DAwMDEyEFeBUhA6IUEeUmysHw9h0MAAAICBNFsA0FpgAAAABJRU5ErkJggg=="""
IMG_TWO = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAE5JREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDAhC6AzMemEQV8/RDwH6aICa9KKCBKEQu6FdjcRJTvcCrA6iZ8CmngO/QQRnY08b4jBACKkim05rA2PQAAAABJRU5ErkJggg=="""
IMG_THREE = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAEZJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDAhC6AzMemEQV8/RDwH6aICa9KKCBKEQu6FdjcRJTv8AKCDkc2ecj5DgYAvLgsHMNwUW8AAAAASUVORK5CYII="""
IMG_FOUR = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAEBJREFUKJFjYKAq+Poh4D8+cSZcCpH5TAxEAKIUscAY3AIbGJGtQOYz4nITTCFBazB8h0sBXkXIgChFRLmJegAAw84ifoWjgLsAAAAASUVORK5CYII="""
IMG_FIVE = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAFJJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BXAAdfPwT8x2YSDDAR4yaiFLEguwHZSmQ3EeU7vACmEaebkE2mge/QrUD2LeW+gwEAwSQptIi80uQAAAAASUVORK5CYII="""
IMG_SIX = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAFBJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BXAAdfPwT8x2YSDDAR4yaiFLEguwHZSmQ3EeU7nAqQxZlwKUTm08l3MD7xviMEAOAVMOimYoddAAAAAElFTkSuQmCC"""
IMG_SEVEN = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAENJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDAhC6AzMemEQV8/RDwH6aICa9KKCBKEUErKTYExSScbkK2asj5DgYA9qIcEuzehakAAAAASUVORK5CYII="""
IMG_EIGHT = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAElJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BWANPIgmwSskJkk5mIcRNRiuDWIbsBnU+U73AqQBZnwqVwSPiOEAAAahE4ICNeiqcAAAAASUVORK5CYII="""
IMG_NINE = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAExJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BWANPIgmwSskJkk5mIcRNRiuDWIbsBnU+U7/ACmEacbqKx79CtoK7vYAAASyAw7AlgA1kAAAAASUVORK5CYII="""
IMG_ZERO = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAExJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BWANPIgmwSskJkk5mIcRNRinA6Gp84+SYx4VJIG9/BAxM5hNH5RMUdUQAAIjEyg2qVaS8AAAAASUVORK5CYII="""
IMG_E = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAEhJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BXAAdfPwT8x2YSDDAR4yaiFLEguwHZSmQ3EeU7nAqwumlI+o4QAACO/idMvTDKIgAAAABJRU5ErkJggg=="""
IMG_R = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAADFJREFUKJFjYBjOgBGZ8/VDwH8Ym1tgAyOGImQF2BRiVYAMmIhRyIRLgmRFRLmJegAAfiMRpW0nYCcAAAAASUVORK5CYII="""
IMG_DASH = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAACJJREFUKJFjYBjOgBGZ8/VDwH8Ym1tgAyOGImQF2BSOcAAAW6cIA5vDZfAAAAAASUVORK5CYII="""

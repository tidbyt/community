"""
Applet: Death Valley Thermometer
Summary: Temperature in F and C
Description: Based on the thermometers at Death Valley National Park
Author: Kyle Stark @kaisle51
Thanks: //Code usage: Steve Otteson. Sprite source: https://www.youtube.com/watch?v=RCL1iwIU57k
"""
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("secret.star", "secret")
load("random.star", "random")
load("math.star", "math")

DEFAULT_TIME_ZONE = "America/Phoenix"
BG_COLOR = "#95a87e"

#12 x 13
IMG_CELCIUS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAE9JREFUKJGtkVEKACAIQ2d0/yvbRwaZxhJ6EEo4lymYqEWBR5GgJNftoGcdDpFz7XZxe1JgOdDCF9KBv5I6tKqICcoOAba4fUcAIOz/wwwDfZoPEer2YU8AAAAASUVORK5CYII=
""")

#12 x 12
IMG_FAHRENHEIT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAEtJREFUKJGVkFEKACAIQ2d4/yvbRwZqhuxBKOG2UnAwr4KMocGG3sKBdg5FlFLVL35PergJ42AV/IjpACCTc7slanixoklAJ1C0f9jIHw8RR0OxxAAAAABJRU5ErkJggg==
""")

#full url: https://api.weatherapi.com/v1/current.json?key=7d679e810fcf4099a98224250230104&q=Death%20Valley&aqi=no 

WEATHER_URL = "https://api.weatherapi.com/v1/current.json?key=7d679e810fcf4099a98224250230104&q=Death%20Valley&aqi=no"
WEATHER_API = "7d679e810fcf4099a98224250230104"
WEATHER_QUERY = "&q=Death%20Valley&aqi=no"
FULL_URL = WEATHER_URL + WEATHER_API + WEATHER_QUERY

def main(config):
    data = get_weather(WEATHER_API)
    tempF = data["current"]["temp_f"]
    #tempFstring = str(int(math.round(tempF)))
    tempFstring = str(int(math.round(88))) #test
    tempFarray = []
    
    if len(tempFstring) == 2:
        tempFarray = ["x", tempFstring[0], tempFstring[1]]
    elif len(tempFstring) == 3:
        tempFarray = [tempFstring[0], tempFstring[1], tempFstring[2]]
    print(tempFarray)
    
    tempC = data["current"]["temp_c"]
    #tempCstring = str(int(math.round(tempC)))
    tempCstring = str(int(math.round(88))) #test
    tempCarray = []

    if len(tempCstring) == 2:
        tempCarray = [tempCstring[0], tempCstring[1]]
    elif len(tempCstring) == 1:
        tempCarray = [tempCstring[0]]
    print(tempCarray)

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
                        generateImageF(0),
                        generateImageF(1),
                        generateImageF(2)
                    ],
                ),
                color = "#000",
                width = 27,
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
                        generateImageC(0),
                        generateImageC(1)
                    ],
                ),
                color = "#000",
                width = 18,
                height = 15,
            ),
            pad = (11, 16, 0, 0),
        )
    
    return render.Root(
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
                        color = "#ababab",
                    ),
                    pad = (5, 1, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_FAHRENHEIT,
                        width = 12,
                        height = 12,
                    ),
                    pad = (40, 2, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_CELCIUS,
                        width = 12,
                        height = 13,
                    ),
                    pad = (31, 17, 0, 0),
                ),
                layoutF(),   
                layoutC(),
            ],
        ),
    )

def get_weather(api_key):
    res = http.get(WEATHER_URL, params = {
        "key": api_key,
        "q": "Death%20Valley",
        "aqi": "no"
    })
    if res.status_code != 200:
        fail("Temperature request failed with status ", res.status_code)
    print(res.json())

    return res.json()

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

# number images
IMG_ONE = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_TWO = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_THREE = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_FOUR = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_FIVE = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_SIX = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_SEVEN = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_EIGHT = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAAElJREFUKJFjYCACMMIYXz8E/EeX5BbYwMjAwMDABFMAE0BWANPIgmwSskJkk5mIcRNRiuDWIbsBnU+U73AqQBZnwqVwSPiOEAAAahE4ICNeiqcAAAAASUVORK5CYII="""
IMG_NINE = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_ZERO = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
IMG_DASH = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg=="""
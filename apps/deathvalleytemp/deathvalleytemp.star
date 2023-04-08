"""
Applet: Death Valley Thermometer
Summary: Temperature in F and C
Description: Based on the thermometers at Death Valley National Park
Author: Kyle Stark @kaisle51
Thanks: ...
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

WEATHER_URL = "https://api.weather.gov/gridpoints/VEF/63,120/forecast/hourly"
IMG_CELCIUS = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAANCAYAAACdKY9CAAAAAXNSR0IArs4c6QAAAE9JREFUKJGtkVEKACAIQ2d0/yvbRwaZxhJ6EEo4lymYqEWBR5GgJNftoGcdDpFz7XZxe1JgOdDCF9KBv5I6tKqICcoOAba4fUcAIOz/wwwDfZoPEer2YU8AAAAASUVORK5CYII=
""")
IMG_FAHRENHEIT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAEtJREFUKJGVkFEKACAIQ2d4/yvbRwZqhuxBKOG2UnAwr4KMocGG3sKBdg5FlFLVL35PergJ42AV/IjpACCTc7slanixoklAJ1C0f9jIHw8RR0OxxAAAAABJRU5ErkJggg==
""")
CACHE_TTL_SECONDS = 3599 #1 hour

def main(config):
    tempF = get_cachable_data(WEATHER_URL, CACHE_TTL_SECONDS)
    tempFstring = str(int(math.round(float(tempF))))
    tempFarray = []
    
    if len(tempFstring) == 2:
        tempFarray = ["x", tempFstring[0], tempFstring[1]]
    elif len(tempFstring) == 3:
        tempFarray = [tempFstring[0], tempFstring[1], tempFstring[2]]

    def FtoC(F):  # returns rounded to 1 decimal
        c = (float(F) - 32) * 0.55
        c = int(c * 10)
        return c / 10.0
    
    tempC = FtoC(tempF)
    tempCstring = str(int(tempC))
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

def get_cachable_data(url, timeout):
    key = url

    data = cache.get(key)
    if data != None:
        return data

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    
    temp_data = res.json()
    temp_f = str(temp_data["properties"]["periods"][0]["temperature"])
    cache.set(key, temp_f, ttl_seconds = CACHE_TTL_SECONDS)

    return temp_f

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
IMG_DASH = """iVBORw0KGgoAAAANSUhEUgAAAAkAAAAPCAYAAAA2yOUNAAAAAXNSR0IArs4c6QAAACJJREFUKJFjYBjOgBGZ8/VDwH8Ym1tgAyOGImQF2BSOcAAAW6cIA5vDZfAAAAAASUVORK5CYII="""
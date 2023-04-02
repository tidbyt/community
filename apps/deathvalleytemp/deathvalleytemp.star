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

#full url: https://api.weatherapi.com/v1/current.json?key=7d679e810fcf4099a98224250230104&q=Death%20Valley&aqi=no 

WEATHER_URL = "https://api.weatherapi.com/v1/current.json?key=7d679e810fcf4099a98224250230104&q=Death%20Valley&aqi=no"
WEATHER_API = "7d679e810fcf4099a98224250230104"
WEATHER_QUERY = "&q=Death%20Valley&aqi=no"
FULL_URL = WEATHER_URL + WEATHER_API + WEATHER_QUERY

def main(config):
    data = get_weather(WEATHER_API)
    # weatherJSON = json.decode(data)
    tempF = data["current"]["temp_f"]

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
                        color = "#ababab",
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
                #render.Padding(
                    render.Box(
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            children = [
                                render.Text(
                                    content = str(tempF),
                                    font = "6x13",
                                    color = "#f5f24f",
                                ),
                            ],
                        ),
                        width = 64,
                        height = 22,
                    ),
                #    pad = (0, 0, 0, 0),
                #),
            ],
        ),
    )

def get_weather(api_key):
    res = http.get(WEATHER_URL, params = {
        "key": api_key,
        "q": "Death%20Valley",
        "aqi": "no"
    })
    #if res.status_code != 200:
    #  fail("Predictions request failed with status ", res.status_code)
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
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_RATE = 43200  #twice a day
OPEN_WEATHER_URL = "https://api.openweathermap.org/data/2.5/onecall"
ADVERBS = [
    "damn cold",
    "darn cold",
    "bone chilling",
    "glacial",
    "frigid",
    "freezing",
    "frosty",
    "pretty cold",
    "chilly",
    "brisk",
    "cool",
    "quite temperate",
    "rather mild",
    "pretty nice",
    "positively balmy",
    "extra warm",
    "kinda hot",
    "roasting",
    "scorching",
    "oven-like",
    "your hair is on FIRE",
]
RANGE_MIN = -10
RANGE_MAX = 110
DEFAULT_JACKET_LIMIT = 60
DEFAULT_COAT_LIMIT = 35

def ktof(k):
    return c2f(k - 273.15)

def f2c(f):
    return (((f - 32) * 5) / 9)

def c2f(c):
    return (((c * 9) / 5) + 32)

def normalize(value, min, max):
    excess = min < 0 and 0 - min or 0
    return value + excess, min + excess, max + excess

def clamp(value, min, max):
    clamped = value
    if value < min:
        clamped = min
    elif value > max:
        clamped = max
    return clamped

def percentOfRange(value, min, max):
    # normalize
    value, min, max = normalize(value, min, max)

    # maths
    percent = value / max - min

    # clamping
    return clamp(percent, 0, 1)

def getTempWord(temp, unit = "f"):
    # convert our range bounds to c if necessary
    tmin = unit == "f" and RANGE_MIN or f2c(RANGE_MIN)
    tmax = unit == "f" and RANGE_MAX or f2c(RANGE_MAX)

    # % of our temp range
    tempPer = percentOfRange(temp, tmin, tmax)

    # index in array of desc, based on that percentage
    index = math.floor(tempPer * len(ADVERBS))

    # ensure temp is not outside of our range
    index = max(0, index)
    index = min(len(ADVERBS) - 1, index)

    # return that word
    return ADVERBS[index]

def getMainString(temp, jacketLimit, coatLimit):
    negation = (temp > jacketLimit) and " don't" or ""
    outerwear = (temp < coatLimit) and "coat" or "jacket"
    return "You%s need a %s" % (negation, outerwear)

def getSubString(temp, unit = "f"):
    return "It's %s outside" % getTempWord(temp, unit)

def main(config):
    current_data = get_weather_data(config)
    feels_like = ktof(current_data["feels_like"])

    mainString = getMainString(feels_like, DEFAULT_JACKET_LIMIT, DEFAULT_COAT_LIMIT)
    show_description = config.get("show_description")
    subString = ""

    weather_info = []

    # weather_info.append(add_row("Temp", "{0}{1}".format(outside_temp, degree_sign)))
    # weather_info.append(add_row("Feel", "{0}{1}".format(feels_like, degree_sign)))
    weather_info.append(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText("%s" % mainString, "tb-8", align = "center"),
            ],
        ),
    )
    if show_description != "false":
        subString = getSubString(feels_like)
        weather_info.append(render.Box(width = 64, height = 1, color = config.get("divider_color", "#1167B1")))
        weather_info.append(
            render.Row(
                # expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("%s" % subString, "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = weather_info,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time and weather",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "OpenWeather API Key.",
                icon = "key",
            ),
            schema.Toggle(
                id = "show_description",
                name = "Show Description",
                desc = "Show description of weather",
                icon = "gear",
                default = True,
            ),
            schema.Color(
                id = "divider_color",
                name = "Divider Color",
                desc = "The color of the dividers",
                icon = "brush",
                default = "#1167B1",
            ),
        ],
    )

def get_weather_data(config):
    api_key = config.get("api_key", None)
    location = config.get("location", None)
    cached_data = cache.get("weather_data-{0}".format(api_key))
    if cached_data != None:
        print("Using existing weather data")
        cache_res = json.decode(cached_data)
        return cache_res

    else:
        if api_key == None:
            print("Missing api_key")
            return SAMPLE_STATION_RESPONSE["current"]
        if location == None:
            print("Missing location")
            return SAMPLE_STATION_RESPONSE["current"]

        print("Getting new weather data")
        location = json.decode(location)
        query = "%s?exclude=minutely,hourly,daily,alerts&lat=%s&lon=%s&appid=%s" % (OPEN_WEATHER_URL, location["lat"], location["lng"], api_key)
        res = http.get(
            url = query,
            ttl_seconds = REFRESH_RATE,
        )
        if res.status_code != 200:
            print("Open Weather request failed with status %d", res.status_code)
            return SAMPLE_STATION_RESPONSE["current"]

        current_data = res.json()["current"]

        cache.set("weather_data-{0}".format(api_key), json.encode(current_data), ttl_seconds = REFRESH_RATE)
        return current_data

SAMPLE_STATION_RESPONSE = {
    "lat": 40.678,
    "lon": -73.944,
    "timezone": "America/New_York",
    "timezone_offset": -14400,
    "current": {
        "dt": 1685459950,
        "sunrise": 1685438891,
        "sunset": 1685492324,
        "temp": 291.72,
        "feels_like": 291.02,
        "pressure": 1024,
        "humidity": 53,
        "dew_point": 281.97,
        "uvi": 6.51,
        "clouds": 0,
        "visibility": 10000,
        "wind_speed": 7.2,
        "wind_deg": 40,
        "weather": [
            {
                "id": 711,
                "main": "Smoke",
                "description": "smoke",
                "icon": "50d",
            },
        ],
    },
}

def add_row(title, font):
    return render.Row(
        # expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Marquee(
                width = 64,
                child = render.Text("%s" % title, font),
            ),
        ],
    )

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

AMBIENT_WEATHER_URL = "https://rt.ambientweather.net/v1/devices"
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

    feels_like = current_data["feelsLike"]
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
            schema.Text(
                id = "application_key",
                name = "Application Key",
                desc = "Ambient Weather Application Key.",
                icon = "key",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Ambient Weather API Key.",
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
    application_key = config.get("application_key", None)
    cached_data = cache.get("weather_data-{0}".format(api_key))
    if cached_data != None:
        print("Using existing weather data")
        cache_res = json.decode(cached_data)
        return cache_res

    else:
        if api_key == None:
            print("Missing api_key")
            return SAMPLE_STATION_RESPONSE
        if application_key == None:
            print("Missing application_key")
            return SAMPLE_STATION_RESPONSE

        print("Getting new weather data")
        res = http.get(
            url = AMBIENT_WEATHER_URL,
            params = {
                "applicationKey": config.get("application_key"),
                "apiKey": config.get("api_key"),
            },
        )
        if res.status_code != 200:
            print("Ambient Weather request failed with status %d", res.status_code)
            return SAMPLE_STATION_RESPONSE

        current_data = res.json()[0]["lastData"]
        print("{0}".format(current_data))

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("weather_data-{0}".format(api_key), json.encode(current_data), ttl_seconds = 60)
        return current_data

SAMPLE_STATION_RESPONSE = {
    "dateutc": 1679845380000,
    "tempinf": 67.5,
    "battin": 1,
    "humidityin": 33,
    "baromrelin": 28.787,
    "baromabsin": 28.787,
    "tempf": 44.6,
    "battout": 1,
    "humidity": 66,
    "winddir": 352,
    "winddir_avg10m": 268,
    "windspeedmph": 8.5,
    "windspdmph_avg10m": 6.9,
    "windgustmph": 11.4,
    "maxdailygust": 18.3,
    "hourlyrainin": 0,
    "eventrainin": 0.232,
    "dailyrainin": 0.012,
    "weeklyrainin": 0.012,
    "monthlyrainin": 1.39,
    "yearlyrainin": 4.441,
    "solarradiation": 152.68,
    "uv": 1,
    "feelsLike": 39.96,
    "dewPoint": 33.95,
    "feelsLikein": 67.5,
    "dewPointin": 37.4,
    "lastRain": "2023-03-26T04:20:00.000Z",
    "tz": "America/New_York",
    "date": "2023-03-26T15:43:00.000Z",
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

"""
Applet: Air Quality
Summary: Monitor local air quality
Description: Monitor your local air quality with the OpenWeather Air Pollution API.
Author: Daniel Sitnik
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# default location to be shown if none is configured, Tidbyt HQ :)
DEFAULT_LOCATION = json.encode({
    "lat": "40.6969512",
    "lng": "-73.9538453",
    "description": "Brooklyn, NY, USA",
    "locality": "Tidbyt",
    "place_id": "ChIJr3Hjqu5bwokRmeukysQhFCU",
    "timezone": "America/New_York",
})

# 6 hours (4 updates per day)
DEFAULT_CACHE = 6 * 60 * 60

# default options
DEFAULT_LOCATION_NAME = ""
DEFAULT_24H_CLOCK = False
DEFAULT_SCROLL_AQI = False
DEFAULT_COLOR_AQI1 = "#00ff38"  # green (good)
DEFAULT_COLOR_AQI2 = "#f9cd03"  # yellow (fair)
DEFAULT_COLOR_AQI3 = "#ffa500"  # orange (moderate)
DEFAULT_COLOR_AQI4 = "#ff0000"  # red (poor)
DEFAULT_COLOR_AQI5 = "#ff41ff"  # purple (very poor)
DEFAULT_COLOR_AQI6 = "#ffffff"  # white (unknown)

# OpenWeather production API key
OW_API_KEY = "AV6+xWcE8tlc8kG2+46k6VdWihmVUMUgF0UlFZa0ZzucnuUIVRSReDVB/Q+cfZg5oFeiFEvdP9Pi2bi5CjL4tFFsHe2Re2pqQ5bNxlvLqf8TeBhuE/C9SaFp3x3DX55DM2gAPc1I2kSWOH1hpVLrPrM8gI0VtJiWSVJ++i1Ba4ZPJcUCuSc="

# development API key, provide your key here or the app will fail!
OW_DEV_API_KEY = ""

# OpenWeather API base url
OW_API_URL = "https://api.openweathermap.org"

def main(config):
    use24h = config.bool("use24h", DEFAULT_24H_CLOCK)
    location_name = config.str("location_name", DEFAULT_LOCATION_NAME)
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    timezone = location["timezone"]

    # try to load from cache
    cache_key = "%s#%s" % (location["lat"], location["lng"])
    data = cache.get(cache_key)

    if data == None:
        print("Data not found in cache")
        data = get_data(location)
    else:
        print("Data loaded from cache")
        data = json.decode(data)

    # use locality from selected place
    locality = location["locality"]

    # if user chose to override location name
    if location_name != "":
        locality = location_name

    # if there was an API error, use a fake location name
    if data.get("api_error", False):
        locality = "Unknown (API error)"

    # find data point closest to the current time
    # this allows using the cached data up to the
    # next 6th hour, where a refresh will happen
    now = time.now().unix
    index = 1

    for i in range(1, len(data["list"])):
        if int(data["list"][i]["dt"]) > now:
            index = i - 1
            break

    # retrieve air quality index
    aqi = data["list"][index]["main"]["aqi"] or 6
    aqi_color = get_color_for_aqi(aqi, config)
    aqi_text = get_text_for_aqi(aqi, config)

    # retrieve forecasts for 6 and 12 hours
    aqi6 = data["list"][6]["main"]["aqi"] or 6
    aqi6_color = get_color_for_aqi(aqi6, config)
    aqi6_hour = get_formatted_hour(use24h, data["list"][6]["dt"] or (time.now().unix + 21600), timezone)

    aqi12 = data["list"][12]["main"]["aqi"] or 6
    aqi12_color = get_color_for_aqi(aqi12, config)
    aqi12_hour = get_formatted_hour(use24h, data["list"][12]["dt"] or (time.now().unix + 43200), timezone)

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    color = "#151968",
                    height = 8,
                    child = render.Text("AIR QUALITY", font = "tb-8", color = "#01ffff"),
                ),
                render.Row(
                    children = [
                        render.Padding(
                            pad = 2,
                            child = render.Circle(
                                color = aqi_color,
                                diameter = 20,
                                child = render.Circle(
                                    color = "#1a1a1a",
                                    diameter = 16,
                                    child = render.Marquee(
                                        width = 10,
                                        align = "center",
                                        child = render.Text(aqi_text, font = "6x13", color = aqi_color),
                                    ),
                                ),
                            ),
                        ),
                        render.Padding(
                            pad = 2,
                            child = render.Column(
                                children = [
                                    render.Marquee(
                                        align = "left",
                                        width = 36,
                                        offset_start = 36,
                                        offset_end = 36,
                                        child = render.Text(locality, font = "Dina_r400-6"),
                                    ),
                                    render.Row(
                                        children = [
                                            render.Padding(
                                                pad = (0, 1, 1, 0),
                                                child = render.Box(
                                                    width = 16,
                                                    height = 9,
                                                    color = aqi6_color,
                                                    child = render.Box(
                                                        width = 14,
                                                        height = 7,
                                                        color = "#000",
                                                        child = render.Padding(
                                                            pad = (0, 1, 0, 0),
                                                            child = render.Text(aqi6_hour, font = "tom-thumb", color = "#fff"),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (1, 1, 0, 0),
                                                child = render.Box(
                                                    padding = 0,
                                                    width = 16,
                                                    height = 9,
                                                    color = aqi12_color,
                                                    child = render.Box(
                                                        width = 14,
                                                        height = 7,
                                                        color = "#000",
                                                        child = render.Padding(
                                                            pad = (0, 1, 0, 0),
                                                            child = render.Text(aqi12_hour, font = "tom-thumb", color = "#fff"),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
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
                desc = "Location for which to display air quality.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_name",
                name = "Location name (blank for default)",
                desc = "Override location name, leave blank for default.",
                icon = "font",
                default = DEFAULT_LOCATION_NAME,
            ),
            schema.Toggle(
                id = "use24h",
                name = "24-Hour Clock",
                desc = "Use 24-Hour format in forecast.",
                icon = "clock",
                default = DEFAULT_24H_CLOCK,
            ),
            schema.Toggle(
                id = "scroll_desc",
                name = "Scroll Description",
                desc = "Scroll air quality description.",
                icon = "arrowsLeftRightToLine",
                default = DEFAULT_SCROLL_AQI,
            ),
            schema.Color(
                id = "aqi1_color",
                name = "Good Quality Color",
                desc = "Color for Good air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI1,
            ),
            schema.Color(
                id = "aqi2_color",
                name = "Fair Quality Color",
                desc = "Color for Fair air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI2,
            ),
            schema.Color(
                id = "aqi3_color",
                name = "Moderate Quality Color",
                desc = "Color for Moderate air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI3,
            ),
            schema.Color(
                id = "aqi4_color",
                name = "Poor Quality Color",
                desc = "Color for Poor air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI4,
            ),
            schema.Color(
                id = "aqi5_color",
                name = "Very Poor Quality Color",
                desc = "Color for Very Poor air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI5,
            ),
            schema.Color(
                id = "aqi6_color",
                name = "Unknown Quality Color",
                desc = "Color for Unknown air quality.",
                icon = "brush",
                default = DEFAULT_COLOR_AQI6,
            ),
        ],
    )

def get_data(location):
    # round coordinates to avoid exposing user's precise location
    lat = get_rounded_coord(location["lat"])
    lon = get_rounded_coord(location["lng"])

    apikey = secret.decrypt(OW_API_KEY) or OW_DEV_API_KEY

    # validate if api key was provided
    if apikey in (None, ""):
        fail("Please provide an API key in the OW_DEV_API_KEY variable!")

    print("Requesting data from API")

    # call openweather api
    res = http.get(OW_API_URL + "/data/2.5/air_pollution/forecast", params = {
        "appid": apikey,
        "lat": str(lat),
        "lon": str(lon),
    })

    # check response code
    if res.status_code != 200:
        print("Failed to get air pollution data (%d): %s" % (res.status_code, res.body()))

        # return a fake dictionary forcing unknown values
        return {
            "api_error": True,
            "list": [
                {"main": {"aqi": 6}, "dt": time.now().unix},  # current
                {"main": {"aqi": 6}, "dt": time.now().unix + 3600},
                {"main": {"aqi": 6}, "dt": time.now().unix + 7200},
                {"main": {"aqi": 6}, "dt": time.now().unix + 10800},
                {"main": {"aqi": 6}, "dt": time.now().unix + 14400},
                {"main": {"aqi": 6}, "dt": time.now().unix + 18800},
                {"main": {"aqi": 6}, "dt": time.now().unix + 21600},  # 6h forecast
                {"main": {"aqi": 6}, "dt": time.now().unix + 25200},
                {"main": {"aqi": 6}, "dt": time.now().unix + 28800},
                {"main": {"aqi": 6}, "dt": time.now().unix + 32400},
                {"main": {"aqi": 6}, "dt": time.now().unix + 36000},
                {"main": {"aqi": 6}, "dt": time.now().unix + 39600},
                {"main": {"aqi": 6}, "dt": time.now().unix + 43200},  # 12h forecast
            ],
        }

    # convert to json
    data = res.json()

    # remove excessive forecast data to alleviate cache
    for _ in range(0, len(data["list"]) - 13):
        data["list"].pop()

    # cache results using lat#lon as the key
    cache_key = "%s#%s" % (location["lat"], location["lng"])

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(cache_key, json.encode(data), ttl_seconds = DEFAULT_CACHE)
    print("Data cached for %d seconds" % DEFAULT_CACHE)

    return data

def get_rounded_coord(coord):
    # rounds to 4 decimal places
    return math.ceil(float(coord) * 10000) / 10000

def get_color_for_aqi(aqi, config):
    # returns the color for the ring and text based on the quality index

    aqi1_color = config.str("aqi1_color", DEFAULT_COLOR_AQI1)
    aqi2_color = config.str("aqi2_color", DEFAULT_COLOR_AQI2)
    aqi3_color = config.str("aqi3_color", DEFAULT_COLOR_AQI3)
    aqi4_color = config.str("aqi4_color", DEFAULT_COLOR_AQI4)
    aqi5_color = config.str("aqi5_color", DEFAULT_COLOR_AQI5)
    aqi6_color = config.str("aqi6_color", DEFAULT_COLOR_AQI5)

    if aqi == 1:
        return aqi1_color
    elif aqi == 2:
        return aqi2_color
    elif aqi == 3:
        return aqi3_color
    elif aqi == 4:
        return aqi4_color
    elif aqi == 5:
        return aqi5_color
    else:
        return aqi6_color

def get_text_for_aqi(aqi, config):
    # returns the textual description of the quality index

    descs = [
        {"short": "G", "long": "Good"},
        {"short": "F", "long": "Fair"},
        {"short": "M", "long": "Moderate"},
        {"short": "P", "long": "Poor"},
        {"short": "V", "long": "Very Poor"},
        {"short": "U", "long": "Unknown"},
    ]

    scroll = config.bool("scroll_desc", DEFAULT_SCROLL_AQI)
    safe_aqi = int(aqi - 1) if aqi <= 5 else 5

    if scroll:
        return descs[safe_aqi]["long"]
    else:
        return descs[safe_aqi]["short"]

def get_formatted_hour(use24h, timestamp, timezone):
    # formats hours based on 12 or 24 format

    # default is 12h format
    format = "Kaa"

    if use24h:
        format = "HH"

    # create a time object from the timestamp
    time_object = time.from_timestamp(int(timestamp))

    # convert timezone
    time_in_timezone = time_object.in_location(timezone)

    # humanize it using the specified format
    hour = humanize.time_format(format, time_in_timezone)

    # if using 24h, append an "h" at the end
    if use24h:
        return hour + "h"
    else:
        return hour

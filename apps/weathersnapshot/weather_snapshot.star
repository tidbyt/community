load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# development API key, provide your key here or the app will default to static data
DEV_API_KEY = ""

PROD_API_KEYS = [
    "AV6+xWcEZIMGFviu8oqBudMgmkxE1fU8GovLMKoBnQ4qAAbxGy6+HJWkSa4Or1g37TlcSepcNSsL7tORiavmprZfs9Ou7/Yen8FtI6hcIgreqKY/jQKA3QV6VtvCXXfwanjxwV2KZbcHi4W0mf5U0s4Xesy32wGLLclT/up2keKAXdgVaZE=",
    "AV6+xWcEX8BBnVXJmCZLWWTaw/YBgpmXjqdTjGtdZWfqOJHJZU0X+x2t/xsSI/OkZ256iP3cyWF5ft528Lfz7W2Ss+InURzEmEp/t1aGr3b+c9DqcwXzTcdqBybg/H4CeSf+idUuBhyIRRMCA+eo9Y4ttckthcM26AlbAbbY5YZAhVUvsu0=",
]

# Functions to calculate USA AQI based on pollutant data

aqi_ranges = [50, 100, 150, 200, 300, 400, 500]
co_ranges = [4.4, 9.4, 12.4, 15.4, 30.4, 40.4, 50.4]
no2_ranges = [53, 100, 360, 649, 1249, 1649, 2049]
o3_ranges = [54, 70, 164, 204, 404, 504, 604]
so2_ranges = [35, 75, 185, 304, 604, 804, 1004]
pm2_5_ranges = [12, 35.4, 55.4, 150.4, 250.4, 350.4, 500.4]
pm10_ranges = [54, 154, 254, 354, 424, 504, 604]

def get_range_by_index(ranges, index):
    low = 0 if (index == 0) else ranges[index - 1]
    return low, ranges[index]

def get_range_by_value(ranges, value):
    for i, high in enumerate(ranges):
        if value < high:
            low = 0 if (i == 0) else ranges[i - 1]
            return i, (low, high)

    # Should never get here, but if we do return the highest range
    i = len(ranges) - 1
    return i, (ranges[i - 1], ranges[i])

def _calculate_aqi(ranges, value):
    index, (c_low, c_high) = get_range_by_value(ranges, value)
    i_low, i_high = get_range_by_index(aqi_ranges, index)
    return ((i_high - i_low) / (c_high - c_low)) * (value - c_low) + i_low

def calculate_aqi(co, no2, o3, so2, pm2_5, pm10):
    co_aqi = _calculate_aqi(co_ranges, co)
    no2_aqi = _calculate_aqi(no2_ranges, no2)
    o3_aqi = _calculate_aqi(o3_ranges, o3)
    so2_aqi = _calculate_aqi(so2_ranges, so2)
    pm2_5_aqi = _calculate_aqi(pm2_5_ranges, pm2_5)
    pm10_aqi = _calculate_aqi(pm10_ranges, pm10)
    return int(max(co_aqi, no2_aqi, o3_aqi, so2_aqi, pm2_5_aqi, pm10_aqi))

# Functions to fetch data from OpenWeatherMap

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

def fetch(url, request_name):
    rep = http.get(url, ttl_seconds = 21600)  # Only update once per 6 hours
    if rep.status_code != 200:
        fail(request_name + " request failed with status %d: %s", rep.status_code, rep.body())
    return rep.json()

def fetch_weather_data(lat, long, api_key):
    current_weather_url = "https://api.openweathermap.org/data/3.0/onecall?lat=" + lat + "&lon=" + long + "&exclude=minutely,hourly,daily,alerts&appid=" + api_key
    return fetch(current_weather_url, "Weather")

def fetch_aqi_data(lat, long, api_key):
    current_aqi_url = "http://api.openweathermap.org/data/2.5/air_pollution?lat=" + lat + "&lon=" + long + "&appid=" + api_key
    return fetch(current_aqi_url, "AQI")

# Functions to select the correct icon

SUN_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAIVJREFUKFNjZMAC/l9i+M+ox8CITQ4khlWCKE2EFKHbCLcJphFEwxTd57mHol5JSQmsHsV5+DTAdIM0MsIUgjwOY6PbgNN59+7dgzsLWdHu3zxgrivrF7gw2HmENMBUwzQywjTATISZisxHthmkEWzTzJuvsDoNW+Smq4sx4ox1XKkBJA4AoH84cEr5M3wAAAAASUVORK5CYII="
SUN_WITH_CLOUDS_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAIVJREFUKFNjZMAC/l9i+M+ox8CITQ4khlWCKE2EFKHbCLcJphFEwxTd57mHol5JSQmsHsV5+DTAdIM0MsIUgjwOY6PbgNN59+7dgzsLWdHu3zxgrivrF7gw2HmENMBUwzQywjTATISZisxHthmkEWzTzJuvsDoNW+Smq4sx4ox1XKkBJA4AoH84cEr5M3wAAAAASUVORK5CYII="
CLOUDS_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGdJREFUKFNjZCADMJKhhwGvpnv37v1HNlRJSQmsHqcmdA0wzSCNWDXh0gDTCNeES+Hu3zxgta6sX+AuBWsipAGmGqaREaYBZiLMVGQ+cmCANIJtmnnzFUoo4YuGdHUx7AFBKO7IilwAmVomcJu9o24AAAAASUVORK5CYII="
GRAY_CLOUDS_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGVJREFUKFOd0UEKACEIBdC8ikvP4nE7i8uuMkPCD2fIAtsF/1n4qRUOFUw7ojHGE4cys+dT9AfAE25RBgAXyoJm5lkRWT91dANIAxIAJmJqvMdlTOgv9d4/WzrVoKr7Rdy6K5X7ArtaJnAgKPSJAAAAAElFTkSuQmCC"
RAIN_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAHpJREFUKFOFkcENwCAIRWWEruDRTZo4Lkk38cgKHcFGkm+gQeWgQf5D/FLahIh0W84508h1ieIPQDPAEFoBACe0ErbWVFtKmQMpdAKgBkgA0BFdbW7fPEC9iZmdSztHa62xETvIW/68Pd0XpdPu/ukkRj2EMJsR6ZHJP9b5TXASHYv4AAAAAElFTkSuQmCC"
THUNDER_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAJFJREFUKFOFkTEOgCAMRdvdxQs4MDJ4DyPHxXgPB0ZMvIBHwFDzDSJIB0jT/9ryYfoJ731Iy0opjrkcpcgBaCJYhGoAwAeqCZ1zotVaPwsJ1AKgBsgAYsd5MFLfO0+YkL83gjLJWhsALIf9M5SMMbcRYSOxlse6m2mnl3sveD0DTT1Tfqf/9JnWgorrAcJeSX4B3rBPcIo8/EUAAAAASUVORK5CYII="
SNOW_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAG9JREFUKFOFkcENACEIBI9WfFKL5VKLT1rhIsl66CnyMNm4A7jSk5SqWrwupVDXfuxqBeDp4BY6AQAHdDK21tzLzGMhh24A3AAJADqia9TxzR30SSIypZQlWmvdB5FBU+RmZkRfk0z/Ir/B6edmK75T6Tpw9IEWMAAAAABJRU5ErkJggg=="
HUMID_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAADlJREFUKFNjZCADMJKhhwG3pu3v/zN4CmKVx64JpAEGsGikkiZkW3DYhmkT/TSBnERWQBCIPLIiFwA4zRUMOIQ2agAAAABJRU5ErkJggg=="
VERY_HUMID_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAD5JREFUKFNjZCADMJKhhwFV0/b3/xk8BTENQhNHKABJwACyRiziFGhCNg3ZNhziEJvopwndNqIDgoQIIytyAWGpKgz5a70AAAAAAElFTkSuQmCC"
SUPER_HUMID_ICON = "iVBORw0KGgoAAAANSUhEUgAAABEAAAALCAYAAACZIGYHAAAAAXNSR0IArs4c6QAAAEBJREFUKFNjZKACYKSCGQwIQ7a//8/gKYhpKBHiEE0ghTCAbBCR4lQyBNk2ZNeQIM6I4pWBNYRqAUthYqFKYgMAE4Y9+xOWAyIAAAAASUVORK5CYII="
GREEN_CLOUD_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGdJREFUKFNjZCADMJKhhwGvpqoPVf+RDW0TaAOrx6kJXQNMM0gjVk24NMA0wjXhUrj4w2Kw2liBWLhLwZoIaYCphmlkhGmAmQgzFZmPHBggjWCbZB/IooQSvmh4rPAYe0AQijuyIhcAQBEjmP6YINkAAAAASUVORK5CYII="
YELLOW_CLOUD_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGVJREFUKFNjZCADMJKhhwGvpv+P0/4jG8ooOwusHqcmdA0wzSCNWDXh0gDXCGPgVPh+FkSJYBrcpWCbCGqAKYdqZIRrgJkIMxWZjxwagmmQgPh/iQEllPBFA6MeA/aAIBR3ZEUuAEG3IChXL3VOAAAAAElFTkSuQmCC"
ORANGE_CLOUD_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGVJREFUKFNjZCADMJKhhwGvpv9L/P8jG8oYsxGsHqcmdA0wzSCNWDXh0gDXCGPgVHhrI0SJmj/cpWCbCGqAKYdqZIRrgJkIMxWZjxwaav6QgPhfx4ASSviigbGJAXtAEIo7siIXAKxJHtBQyYTuAAAAAElFTkSuQmCC"
RED_CLOUD_ICON = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAALCAYAAACksgdhAAAAAXNSR0IArs4c6QAAAGVJREFUKFNjZCADMJKhhwGvpv8hsf+RDWVcsxisHqcmdA0wzSCNWDXh0gDXCGPgVLhmC0RJiA/cpWCbCGqAKYdqZIRrgJkIMxWZjxwaIT6QgPjPIIgSSviigZHhPfaAIBR3ZEUuAGGWHcgzSmJ7AAAAAElFTkSuQmCC"

def get_weather_icon(weather_id):
    # 200s - thunderstorm
    # 300s - light rain
    # 500s - rain
    # 600s - snow
    # 700s - "atmosphere" (e.g. mist, smoke, dust, fog, etc)
    # 800 - clear
    # 800s - clouds
    if weather_id < 300:
        return THUNDER_ICON
    elif weather_id < 600:
        return RAIN_ICON
    elif weather_id >= 600 and weather_id < 700:
        return SNOW_ICON
    elif weather_id >= 700 and weather_id < 800:
        return GRAY_CLOUDS_ICON
    elif weather_id == 800:
        return SUN_ICON
    elif weather_id == 801 or weather_id == 802:
        return SUN_WITH_CLOUDS_ICON
    elif weather_id > 800:
        return CLOUDS_ICON
    else:
        # Should never get here
        return CLOUDS_ICON

def get_humidity_icon(humidity):
    if humidity < 70:
        return HUMID_ICON
    elif humidity < 85:
        return VERY_HUMID_ICON
    else:
        return SUPER_HUMID_ICON

def get_aqi_icon(aqi):
    if aqi < 51:
        return GREEN_CLOUD_ICON
    elif aqi < 101:
        return YELLOW_CLOUD_ICON
    elif aqi < 151:
        return ORANGE_CLOUD_ICON
    else:
        return RED_CLOUD_ICON

def get_api_key(long):
    if DEV_API_KEY:
        return DEV_API_KEY

    index = int(long[-1]) % len(PROD_API_KEYS)
    api_key = PROD_API_KEYS[index]
    return secret.decrypt(api_key)

def main(config):
    location = config.get("location", DEFAULT_LOCATION)

    location = json.decode(location)
    lat = str(location["lat"])
    long = str(location["lng"])

    api_key = get_api_key(long)

    if api_key in (None, ""):
        print("DEV_API_KEY not provided, using static data instead")
        weather_response = json.decode('{"timezone": "America/New_York", "timezone_offset": -18000.0, "current": {"visibility": 10000.0, "pressure": 1027.0, "humidity": 47.0, "dew_point": 262.68, "wind_speed": 7.6, "clouds": 0.0, "wind_deg": 316.0, "uvi": 1.51, "wind_gust": 7.6, "weather": [{"id": 800.0, "main": "Clear", "description": "clear sky", "icon": "01d"}], "temp": 271.44, "feels_like": 264.77}, "lat": 40.6894, "lon": -73.9858}')
        aqi_response = json.decode('{"coord": {"lon": -73.9442, "lat": 40.6782}, "list": [{"main": {"aqi": 2.0}, "components": {"nh3": 1.81, "co": 547.41, "no": 22.35, "no2": 31.19, "o3": 9.21, "so2": 9.3, "pm2_5": 12.53, "pm10": 16.06}}]}')
    else:
        weather_response = fetch_weather_data(lat, long, api_key)
        aqi_response = fetch_aqi_data(lat, long, api_key)

    temp_kelvin = weather_response["current"]["temp"]
    temp_fahrenheit = (temp_kelvin - 273.15) * 1.8 + 32

    humidity = int(weather_response["current"]["humidity"])
    humidity_icon = base64.decode(get_humidity_icon(humidity))

    weather_id = weather_response["current"]["weather"][0]["id"]
    weather_icon = base64.decode(get_weather_icon(weather_id))

    components = aqi_response["list"][0]["components"]

    # converts from ug / m^3 to ppm and ppb
    co = (components["co"] / 1.15) / 1000
    no2 = components["no2"] / 1.88
    o3 = (components["o3"] / 1.96) / 1000
    so2 = components["so2"] / 2.62
    pm2_5 = components["pm2_5"]
    pm10 = components["pm10"]
    aqi = calculate_aqi(co, no2, o3, so2, pm2_5, pm10)
    aqi_icon = base64.decode(get_aqi_icon(aqi))

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = str(int(temp_fahrenheit)) + chr(176)),
                            ),
                            render.Image(src = weather_icon),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = str(humidity)),
                            ),
                            render.Image(src = humidity_icon),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 3, 0, 1),
                                child = render.Text(font = "tb-8", content = str(aqi)),
                            ),
                            render.Image(src = aqi_icon),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the weather",
                icon = "locationDot",
            ),
        ],
    )

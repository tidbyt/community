load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# development API key, provide your key here or the app will default to static data
DEV_API_KEY = ""

PROD_API_KEYS = [
    "AV6+xWcEZIMGFviu8oqBudMgmkxE1fU8GovLMKoBnQ4qAAbxGy6+HJWkSa4Or1g37TlcSepcNSsL7tORiavmprZfs9Ou7/Yen8FtI6hcIgreqKY/jQKA3QV6VtvCXXfwanjxwV2KZbcHi4W0mf5U0s4Xesy32wGLLclT/up2keKAXdgVaZE=",
    "AV6+xWcEX8BBnVXJmCZLWWTaw/YBgpmXjqdTjGtdZWfqOJHJZU0X+x2t/xsSI/OkZ256iP3cyWF5ft528Lfz7W2Ss+InURzEmEp/t1aGr3b+c9DqcwXzTcdqBybg/H4CeSf+idUuBhyIRRMCA+eo9Y4ttckthcM26AlbAbbY5YZAhVUvsu0=",
]

# Only query APIs once per 6 hours
CACHE_TTL_SEC = 60 * 60 * 6

# Functions to calculate USA AQI based on pollutant data

aqi_ranges = [50, 100, 150, 200, 300, 400, 500]
co_ranges = [4.4, 9.4, 12.4, 15.4, 30.4, 40.4, 50.4]
no2_ranges = [53, 100, 360, 649, 1249, 1649, 2049]
o3_1h_ranges = [125, 125, 164, 204, 404, 504, 604]
o3_8h_ranges = [54, 70, 85, 105, 200, 504, 604]
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

def parse_aqi_slice(aqi_slice):
    dt = int(aqi_slice["dt"])
    components = aqi_slice["components"]

    # converts from ug / m^3 to ppm and ppb
    co = (components["co"] / 1.15) / 1000
    no2 = components["no2"] / 1.88
    o3 = (components["o3"] / 1.96) / 1000
    so2 = components["so2"] / 2.62
    pm2_5 = components["pm2_5"]
    pm10 = components["pm10"]
    return struct(dt = dt, co = co, no2 = no2, o3 = o3, so2 = so2, pm2_5 = pm2_5, pm10 = pm10)

def average_over(components, getter, num_hours):
    components = components[0:num_hours]
    acc = 0
    for x in components:
        acc += getter(x)
    return acc / len(components)

def calculate_aqi(aqi_list):
    components = [parse_aqi_slice(x) for x in aqi_list]
    components = sorted(components, key = lambda x: x.dt, reverse = True)
    co_aqi = _calculate_aqi(co_ranges, average_over(components, lambda x: x.co, 8))
    no2_aqi = _calculate_aqi(no2_ranges, average_over(components, lambda x: x.no2, 1))
    o3_8h_aqi = _calculate_aqi(o3_8h_ranges, average_over(components, lambda x: x.o3, 8))
    o3_1h_aqi = _calculate_aqi(o3_1h_ranges, average_over(components, lambda x: x.o3, 1))
    so2_aqi = _calculate_aqi(so2_ranges, average_over(components, lambda x: x.so2, 1))
    pm2_5_aqi = _calculate_aqi(pm2_5_ranges, average_over(components, lambda x: x.pm2_5, 24))
    pm10_aqi = _calculate_aqi(pm10_ranges, average_over(components, lambda x: x.pm10, 24))
    return int(max(co_aqi, no2_aqi, o3_1h_aqi, o3_8h_aqi, so2_aqi, pm2_5_aqi, pm10_aqi))

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
    rep = http.get(url, ttl_seconds = CACHE_TTL_SEC)
    if rep.status_code != 200:
        fail(request_name + " request failed with status " + rep.status_code + ": " + rep.body())
    return rep.json()

def fetch_weather_data(lat, long, api_key):
    current_weather_url = "https://api.openweathermap.org/data/3.0/onecall?lat=" + lat + "&lon=" + long + "&exclude=minutely,hourly,daily,alerts&appid=" + api_key
    return fetch(current_weather_url, "Weather")

def fetch_aqi_data(lat, long, api_key):
    now = time.now()

    # End = current time rounded down to nearest CACHE_TTL_SEC. Start = 24h before end
    end = math.round(now.unix / CACHE_TTL_SEC) * CACHE_TTL_SEC
    start = end - (60 * 60 * 24)
    historical_aqi_url = "http://api.openweathermap.org/data/2.5/air_pollution/history?lat=" + lat + "&lon=" + long + "&start=" + "%d" % start + "&end=" + "%d" % end + "&appid=" + api_key

    return fetch(historical_aqi_url, "AQI")

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
        aqi_response = json.decode('{"coord": {"lon": -73.9442, "lat": 40.6782}, "list": [{"main": {"aqi": 5.0}, "components": {"co": 4058.84, "no": 522.14, "no2": 161.77, "o3": 1.97, "so2": 29.56, "pm2_5": 243.74, "pm10": 298.49, "nh3": 38.51}, "dt": 1.7086104e+09}, {"dt": 1.708614e+09, "main": {"aqi": 5.0}, "components": {"nh3": 25.33, "co": 4486.08, "no": 565.05, "no2": 197.41, "o3": 5.81, "so2": 26.94, "pm2_5": 289.75, "pm10": 343.57}}, {"main": {"aqi": 4.0}, "components": {"o3": 31.47, "so2": 30.99, "pm2_5": 64.35, "pm10": 77.48, "nh3": 6.78, "co": 1121.52, "no": 88.51, "no2": 101.45}, "dt": 1.7086176e+09}, {"main": {"aqi": 3.0}, "components": {"nh3": 3.58, "co": 674.25, "no": 35.32, "no2": 67.17, "o3": 51.5, "so2": 21.22, "pm2_5": 37.09, "pm10": 45.63}, "dt": 1.7086212e+09}, {"dt": 1.7086248e+09, "main": {"aqi": 2.0}, "components": {"so2": 18.12, "pm2_5": 23.33, "pm10": 29.68, "nh3": 2.85, "co": 507.36, "no": 21.68, "no2": 49.35, "o3": 60.08}}, {"components": {"no2": 50.72, "o3": 51.5, "so2": 18.6, "pm2_5": 16.89, "pm10": 22.6, "nh3": 3.39, "co": 473.98, "no": 15.42}, "dt": 1.7086284e+09, "main": {"aqi": 2.0}}, {"main": {"aqi": 2.0}, "components": {"pm10": 19.2, "nh3": 4.12, "co": 480.65, "no": 13.75, "no2": 54.15, "o3": 41.49, "so2": 20.27, "pm2_5": 13.42}, "dt": 1.708632e+09}, {"main": {"aqi": 2.0}, "components": {"so2": 17.41, "pm2_5": 10.52, "pm10": 15.77, "nh3": 3.77, "co": 453.95, "no": 7.38, "no2": 53.47, "o3": 36.48}, "dt": 1.7086356e+09}, {"main": {"aqi": 2.0}, "components": {"so2": 14.54, "pm2_5": 9.94, "pm10": 14.28, "nh3": 3.14, "co": 447.27, "no": 2.12, "no2": 55.52, "o3": 33.26}, "dt": 1.7086392e+09}, {"main": {"aqi": 2.0}, "components": {"pm10": 14.95, "nh3": 2.72, "co": 460.63, "no": 0.38, "no2": 58.95, "o3": 31.11, "so2": 12.76, "pm2_5": 11.16}, "dt": 1.7086428e+09}, {"main": {"aqi": 2.0}, "components": {"nh3": 2.57, "co": 480.65, "no": 0.34, "no2": 61.69, "o3": 29.33, "so2": 11.21, "pm2_5": 13.33, "pm10": 17.27}, "dt": 1.7086464e+09}, {"main": {"aqi": 2.0}, "components": {"o3": 28.97, "so2": 10.25, "pm2_5": 14.66, "pm10": 18.9, "nh3": 2.63, "co": 494.0, "no": 0.37, "no2": 62.38}, "dt": 1.70865e+09}, {"dt": 1.7086536e+09, "main": {"aqi": 2.0}, "components": {"o3": 29.33, "so2": 10.01, "pm2_5": 14.13, "pm10": 18.6, "nh3": 2.57, "co": 487.33, "no": 0.31, "no2": 59.63}}, {"main": {"aqi": 2.0}, "components": {"no": 0.36, "no2": 58.95, "o3": 27.9, "so2": 9.78, "pm2_5": 13.49, "pm10": 18.05, "nh3": 2.53, "co": 480.65}, "dt": 1.7086572e+09}, {"dt": 1.7086608e+09, "main": {"aqi": 2.0}, "components": {"co": 453.95, "no": 0.21, "no2": 53.47, "o3": 31.11, "so2": 9.54, "pm2_5": 11.63, "pm10": 15.53, "nh3": 2.25}}, {"main": {"aqi": 2.0}, "components": {"no": 0.04, "no2": 41.47, "o3": 43.27, "so2": 9.54, "pm2_5": 8.34, "pm10": 11.06, "nh3": 1.6, "co": 397.21}, "dt": 1.7086644e+09}, {"main": {"aqi": 1.0}, "components": {"o3": 52.21, "so2": 9.89, "pm2_5": 7.06, "pm10": 9.23, "nh3": 1.38, "co": 363.83, "no": 0.01, "no2": 34.96}, "dt": 1.708668e+09}, {"main": {"aqi": 2.0}, "components": {"o3": 45.42, "so2": 8.7, "pm2_5": 9.2, "pm10": 12.2, "nh3": 1.39, "co": 390.53, "no": 0.03, "no2": 41.13}, "dt": 1.7086716e+09}, {"main": {"aqi": 2.0}, "components": {"so2": 7.63, "pm2_5": 13.7, "pm10": 18.56, "nh3": 1.6, "co": 460.63, "no": 0.29, "no2": 54.84, "o3": 27.54}, "dt": 1.7086752e+09}, {"main": {"aqi": 2.0}, "components": {"pm10": 25.29, "nh3": 1.95, "co": 534.06, "no": 1.52, "no2": 65.8, "o3": 13.23, "so2": 7.99, "pm2_5": 18.46}, "dt": 1.7086788e+09}, {"main": {"aqi": 3.0}, "components": {"o3": 3.67, "so2": 8.94, "pm2_5": 22.98, "pm10": 30.93, "nh3": 2.28, "co": 600.82, "no": 5.87, "no2": 74.71}, "dt": 1.7086824e+09}, {"main": {"aqi": 3.0}, "components": {"no2": 78.83, "o3": 0.28, "so2": 9.42, "pm2_5": 29.01, "pm10": 37.41, "nh3": 2.63, "co": 694.28, "no": 19.22}, "dt": 1.708686e+09}, {"main": {"aqi": 3.0}, "components": {"co": 974.66, "no": 64.37, "no2": 84.31, "o3": 0.0, "so2": 9.3, "pm2_5": 45.99, "pm10": 57.38, "nh3": 4.56}, "dt": 1.7086896e+09}, {"main": {"aqi": 4.0}, "components": {"nh3": 6.52, "co": 1375.2, "no": 128.75, "no2": 94.59, "o3": 0.06, "so2": 10.37, "pm2_5": 68.18, "pm10": 83.16}, "dt": 1.7086932e+09}]}')
    else:
        weather_response = fetch_weather_data(lat, long, api_key)
        aqi_response = fetch_aqi_data(lat, long, api_key)

    temp_kelvin = weather_response["current"]["temp"]
    temp_fahrenheit = (temp_kelvin - 273.15) * 1.8 + 32

    humidity = int(weather_response["current"]["humidity"])
    humidity_icon = base64.decode(get_humidity_icon(humidity))

    weather_id = weather_response["current"]["weather"][0]["id"]
    weather_icon = base64.decode(get_weather_icon(weather_id))

    aqi = calculate_aqi(aqi_response["list"])
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

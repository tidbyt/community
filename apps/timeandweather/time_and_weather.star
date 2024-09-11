"""
Applet: Time & Weather
Summary: Display time & weather
Description: Display the time in addition to current weather conditions from either National Weather Service (NWS), OpenWeather, OpenWeather 3.0 One Call, Tomorrow.io, Open-Meteo, or Weatherbit weather APIs. To request an OpenWeather API key, see https://home.openweathermap.org/users/sign_up. To request a Tomorrow.io API key, see https://docs.tomorrow.io/login?redirect_uri=/reference/intro/getting-started. To request a Weatherbit API key, see https://www.weatherbit.io/account/create.
Author: sudeepban
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default location
DEFAULT_LOCATION = """
{
    "lat": 40.6781784,
    "lng": -73.9441579,
    "locality": "Brooklyn",
    "timezone": "America/New_York",
    "locationKey": 2627454
}
"""

NWS_GRID_FORECAST_POINT_URL = "https://api.weather.gov/points/{latitude},{longitude}"
NWS_HOURLY_GRID_FORECAST_URL = "https://api.weather.gov/gridpoints/BOX/{gridX},{gridY}/forecast/hourly"
OPENWEATHER_CURRWEATHER_URL = "https://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units={units}&lang=en"
OPENWEATHER_AIR_POLLUTION_URL = "http://api.openweathermap.org/data/2.5/air_pollution?lat={latitude}&lon={longitude}&appid={api_key}"
OPENWEATHER_ONECALL_URL = "https://api.openweathermap.org/data/3.0/onecall?lat={latitude}&lon={longitude}&exclude=minutely,hourly,daily,alerts&appid={api_key}&units={units}&lang=en"
TOMORROW_IO_REALTIME_URL = "https://api.tomorrow.io/v4/weather/realtime?location={latitude},{longitude}&apikey={api_key}&units={units}"
OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m&hourly=dew_point_2m,visibility,uv_index&models=best_match&temperature_unit={temperature_unit}&wind_speed_unit={wind_speed_unit}&forecast_hours=1"
WEATHERBIT_CURRENT_WEATHER_URL = "https://api.weatherbit.io/v2.0/current?lat={latitude}&lon={longitude}&key={api_key}&lang=en&units={units}"

TEMP_COLOR_DEFAULT = "#FFFFFF"

# weather icons borrowed from stock Tidbyt Weather app
WEATHER_ICONS = {
    "cloudy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABHSURBVHjaxI/BDQAgCMTAjdh/iLKRPojGgManfQHpJZzIH3RfgBjM7JoA+gRYmau0228p2S1Udz8+s+6aGlSik9ayyfjLGABillSriIbjdwAAAABJRU5ErkJggg==
""",
    "foggy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABvSURBVHjalI+xDcAgDASfbMSEFBSM5YKC8tmAUZzCCkIQlHAVWOeXH/iHGz8k7eG9326Q1AeSfWcrjfa3NNmXqbXW12P63E0NVqyTW8tOxjkxRgvLOasqAFUtpQBoraWUziNDCABEpOeJSJ8fcA8APZp02VzAMvcAAAAASUVORK5CYII=
""",
    "haily.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABjSURBVHjapI/LDcAgDEMNG2Xv7GIGyC7uISpCtNBW9Smfl4+BdypjQjIDM1tOkNQpkn1mCY30MzTRNdHW2u0zvV4mB1ftPO3MApDUKxlv7vzbVzOJCADunm1J7g4gIr6dPgYAveR7WPNsUTIAAAAASUVORK5CYII=
""",
    "moony.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABESURBVHjaYmCgLmBE5vx/bY0iJ3oUizq4ImRpOGBCNx+bIhQb0SwlYB5R6vAYyYTmLDSlCM/hNwyunxHTQ8T6nSIAGAA1nBh8d3skkwAAAABJRU5ErkJggg==
""",
    "moonyish.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABnSURBVHjatNAxDoAgDAXQX84gm4eQGY8vc7kHhyhDFSVpExb/2LyUT4G1kDmVll8Ri+0GUmHvMxGAsNjvdsyiwXa5dqApn6/46AmzaOkAoFb7HZ1LyxQL6Uqv0rGf0/1MmhLhr/QBAAkLWK/QE7DqAAAAAElFTkSuQmCC
""",
    "rainy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABgSURBVHjaYmAgDjAic+bNmwdhJCUl4VQ3b948Q0NDCPv8+fNoqhkxFcHB+fPn4UoZcSlCU82EbBGmCrg4I5oPMAHEakZMz6KpIBcoTvvMwMAg4F2JxiYLYBoDYZMMAAMAIzEsSN19Ip8AAAAASUVORK5CYII=
""",
    "sleety.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABuSURBVHjaYmAgDjAic86f/w9hGBoy4tRx/vx/ODh//j9cD05FyKoJK0JTzQRReuECdsfAxRnRfIAJEH4S8K5EVqo47TOyZogsFMybdx/NVEwRKPj//z+aG+AiDGgWYTUGWZYB2R1wY1BcRiQADAAtrnieBFAHfQAAAABJRU5ErkJggg==
""",
    "sleety2.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABLSURBVHjaYmAgFZw//x/CUJz2GU0EAebNu48mgSkCBf///0czBi4CBQLelXiMQZbFbjABf+ARoa4/4AGG1RhkWRR/wY3B6VMqAMAAN35GO1pYhkoAAAAASUVORK5CYII=
""",
    "snowy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABYSURBVHjahI/JDQAhDAMJHdEwLZkOthTvAxShXMwrMo6DpV0A3MMY0jIAKgB1JzXd7rfJuPu2rhV/RnUxDTxVpwofGRyZ8zMPXjmQNDGqBKQxnirm2eMfAMWodYqa7/ycAAAAAElFTkSuQmCC
""",
    "snowy2.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAAAySURBVHjaYmAgCZw//5+w+Lx597EqxSL+//9/rGYgixMyAxfAacZI8wcxAAAAAP//AwDMP0MnAPn91gAAAABJRU5ErkJggg==
""",
    "sunny.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABISURBVHjaYmAgG9SXyhIl9/+1NT49yNK4RFAM/v/aGp/VcEUQhEUpRBpi0f/X1v9f20AYEBGcGnCaR5r7iPIvCeFHlBxBABgALlQ+G9vS6kUAAAAASUVORK5CYII=
""",
    "sunnyish.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABWSURBVHjaYmAgG9SXyhIl9/+1NT49yNK4RFAM/v/aGp/VcEUQhF3pf2QAUwqxGqHhPzaAZh7j////8QcTIyMjAwMDE5GBygixF79hUHVYlcJVkAYAAwAEFUsViVL8ywAAAABJRU5ErkJggg==
""",
    "thundery.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABfSURBVHjarNC7DcAwCATQIxtRZxsGu5UYJEMkBRKyQP4UOVFg9CwLA2eR8UAyGjObOpKqGr27Fy0dZdw9qcxQ0df4UBc5l7JBT92JJMn3uaMWNwEg0OYzj1DSn9A63wDfPjgqyFON1wAAAABJRU5ErkJggg==
""",
    "tornady.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAAB6SURBVHjapI/RDQMhDMXcU4eALViDMWCwZAzWYIuwRfuBlJOi67VS/W1MHvyOiLw+ICIiAjy3qqqlFCDn7O/HGEDvHXh4EmituaSqLp2eq7XWUNocoZdSMrMgnfft0loLmHN+WW1mYeadeikdYccmHHfRu/suqPzDewBSg1u5d9GMZAAAAABJRU5ErkJggg==
""",
    "windy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAYElEQVR42mJiIA4wkaOuubn5////mGzs4PDhw3A2XCkLRCuQdHBwsLGxATIYGRnh6oBsoDZbW1sCzkI3D2IYUDces4kzD2IAxAwgiWYMAffBvYwzaJCDjUD4URRvAAEGAEibMzC5039xAAAAAElFTkSuQmCC
""",
}

# wind icons representing wind direction as arrows
WIND_ICONS = {
    "N": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAK0lEQVQYV2NkQAIzb776n64uxggTgjNAAlSWhBmHTsPtBEnAHAJzFF4HAQBWXiQItxZOyAAAAABJRU5ErkJggg==
""",
    "NE": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAANUlEQVQYV2NkwAMYscnNvPnqf7q6GCNYEsZBZ6NIIisCKYRLgjggo5CtQZGEScAUYXUQTBEAxkAcCKmkdzkAAAAASUVORK5CYII=
""",
    "E": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAKklEQVQYV2NkwAMYYXIzb776n64uBueDxMEcbBJgSZAELpPx6yRoJy5jAS5WE2MMrMZ9AAAAAElFTkSuQmCC
""",
    "SE": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAANklEQVQYV2NkwAMYQXIzb776j6wmXV0MLI4iCROEKYRLgiRAJiArQJGEWYFiLLqbYCaAdeICAN4xHAhDnlr8AAAAAElFTkSuQmCC
""",
    "S": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAALElEQVQYV2NkQAIzb776n64uxggTgjNAEjBBmAKwJEwHOg3XiawIw1jqSgIAJnwkCGaQSg0AAAAASUVORK5CYII=
""",
    "SW": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAANUlEQVQYV2NkwAMYYXIzb776j6wuXV2MES6JrghDEqQbJAijUYwFSYBMQJGEcdDdhmEnsgIAfjEcCOnI6BYAAAAASUVORK5CYII=
""",
    "W": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAKklEQVQYV2NkwAMY0eVm3nz1P11dDCyOIQkShClgBDFwmYxfJ8l2wjQAAG5HE2P4mYCGAAAAAElFTkSuQmCC
""",
    "NW": """
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAANElEQVQYV2NkwAMYQXIzb776n64uBmYjA7gAsgIYG0U1TBCrJMwKEA2yBsVYZPtQJLE5GgBmQBwIEZjO8AAAAABJRU5ErkJggg==
""",
}

RAINDROP_ICON = """
iVBORw0KGgoAAAANSUhEUgAAAA4AAAASCAYAAABrXO8xAAAAzUlEQVR42mJgIBMw4pJYd+1jAZCyB+LEIC3+D+jyLDg0JQCpfihXAIgd0dUwYdGkgKQJBByAYg0ENQLBfKgtyKAeqNkAp0aovxxweHs+Vo1QJ9bjCUgDZCcj21iPxYnoIB+oWQCuEWpbAhHRB9JUgGxjPglxn4+s0YEEjQJAFzrANBqQmuRgGh+Qq/EACXo+ANPuAZjGRhI0LoDbCDQB5NREIjRdgFkCTwBAzQugmj/g0LQBlEtgWYwRS+4ARXIAECvA/ATSBHUVHAAEGADlNDsN6Dca6wAAAABJRU5ErkJggg==
"""

DROPLETS_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAABEUlEQVR42qxTwRGCMBAExgJSgnbAzy90ECuQDsSfP3n6xAosAe0An760BEqgA91zLszNGRAcd2YnXmL2LrdHEPwJoW/zcHvOsdzB424ZFmOEop79PWjADYtOF+KLGYdvsV8r0hczkSQGK9CMEYpVbMTzTqDl9avQVcUtGt5ArBBJLGLrdY3LpcwNWIEJ/16RGLson0R7CyShNZgpp3I+TJUBlRJxRtD/i+5p3INc9EGKJNwX75i4/kWiGoeE3Blw0etypC1mrEXf7BehbGiy455R8MFIoUYdXqZ+tE6ILD6DNVjCtZI2sdaeJBp1Zz8uPFjMhy3PlQ8tn/f2qAOSUKWpy6wqSbmIaSAXea4+8BJgAD0vWg0EJA+pAAAAAElFTkSuQmCC
"""

EYEGLASSES_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAABH0lEQVR42oxTwXHCQAw8MxSQVIBdAe4AlxA+focKCBUEKiCpIOTrD+nASQW4A9wB7iBZZfaYRbnMWDOyfL493a4kZ0GsaZoS4Q7e13Xdh4QBY/uGG4Dp4veJAB4RTvAWfubaJ3lAuBBzwnr7JxFsbUzgS/gHvEsQ6rm34vs6bmRC1246gO4qjDCyeYYXVobIqGT8CuMtMq5UWuU2x9gn48IeU1kM1jFQjklvukI5OULualZqjb7/udWAr4x7l0Ttfpo42IvcnAlSkpRdeZMIUgo3V2+UPPDQDpitYFpfbJ3aaHNGm5t3vs8SE/5bz8xl9tKCDF8rnR1Emv1ORZS2gR+d7sABPfCyF4QnYRGYcHntmtCtFDSi/R0wliz8CDAA0rFviB0eAx8AAAAASUVORK5CYII=
"""

CLOUD_ICON = """
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAq0lEQVR42mJgoBJgxCa4atUqByAVD8QKQPwAiBeGhYUdIMkgoCHzgVQCFrWJQMMWEGUQ1CX7ifDJBSB2BBr8ASbAhKYgnsggMQDifmQBJiTXgMLDgYTwVcAwCGgIyIbz6JKEXAXU14DuovVALEBijIPU1wMN60c2SIGCJFSALbDJAqDwhRn0gAJzPgCTwQOYQYEgATINKkRJkNDorychvD5As84GBmoCgAADACo0LGmMFE1wAAAAAElFTkSuQmCC
"""

# simple colon image to save space when displaying time
COLON = """
iVBORw0KGgoAAAANSUhEUgAAAAIAAAAFCAYAAABvsz2cAAAAFUlEQVQYV2NkgALG/////2cEAdwiAMSUCAZY17zuAAAAAElFTkSuQmCC"""

def get_nws_hourly_grid_forecast_url(lat, lon, ttl = 3600):
    res = http.get(NWS_GRID_FORECAST_POINT_URL.format(
        latitude = lat,
        longitude = lon,
    ), ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Could not obtain the grid forecast for a point location.", res.status_code)
    return res.json()["properties"]["forecastHourly"]

def get_current_weather_conditions(url, ttl):
    res = http.get(url, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Current conditions request failed with status", res.status_code)
    return res.json()

def aqi_label(num):
    switch = {
        0: "Good",
        1: "Good",
        2: "Fair",
        3: "Moderate",
        4: "Poor",
        5: "Very Poor",
    }
    return switch.get(num, "Invalid input")

def get_openweather_air_pollution(api_key, latitude, longitude):
    res = http.get(
        url = OPENWEATHER_AIR_POLLUTION_URL,
        params = {
            "lat": str(latitude),
            "lon": str(longitude),
            "appid": api_key,
        },
    )

    air_quality = {}
    air_quality["index"] = int(res.json()["list"][0]["main"]["aqi"])
    air_quality["label"] = aqi_label(air_quality["index"])
    return air_quality

def main(config):
    api_service = config.get("weatherApiService") or "OpenWeather"
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    longitude = float(location["lng"])
    timezone = location["timezone"]
    api_key = config.get("apiKey", "")
    system_of_measurement = config.get("systemOfMeasurement", "Imperial").lower()
    temp_color = config.get("tempColor", TEMP_COLOR_DEFAULT)

    display_metric = (system_of_measurement == "metric")
    display_sample = not (api_key) and api_service != "Open-Meteo" and api_service != "National Weather Service (NWS)"

    time_format = config.get("timeFormat", "12 hour")
    now = time.now().in_location(timezone)
    hours = now.hour
    minutes = now.minute

    # Initialize additional various variables
    wind_dir, hours_str, wind_speed_text, wind_mph_text, arrow_image, humidity_text, humidity_unit_text, humidity_image, dew_point_text, dew_point_unit_text, dew_image, uv_index_text, uv_index_label_text, visibility_text, visibility_unit_text, eye_image, cloud_coverage_text, cloud_coverage_unit_text, cloud_image, pressure_text, pressure_unit_text, aqi_prefix_text, aqi_text = "N", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""
    result_current_conditions = {}
    icon_ref = 0

    enabledMetrics = {}
    enabledMetrics["windSpeed"] = config.get("windSpeedEnabled", True)
    enabledMetrics["humidity"] = config.get("humidityEnabled", False)
    enabledMetrics["dewPoint"] = config.get("dewPointEnabled", False)
    enabledMetrics["uvIndex"] = config.get("uvIndexEnabled", False)
    enabledMetrics["visibility"] = config.get("visibilityEnabled", False)
    enabledMetrics["cloudCoverage"] = config.get("cloudCoverageEnabled", False)
    enabledMetrics["pressure"] = config.get("pressureEnabled", False)
    enabledMetrics["aqi"] = config.get("aqiEnabled", False)

    if display_sample:
        # sample data to display if user-specified API / location key are not available, also useful for testing
        icon_ref = "sunnyish.png"
        result_current_conditions["icon_num"] = 3
        result_current_conditions["temp"] = 14 if display_metric else 57
        result_current_conditions["feels_like"] = 18 if display_metric else 63
        result_current_conditions["wind_speed"] = 5 if display_metric else 12
        result_current_conditions["wind_dir"] = "N" if api_service == "National Weather Service (NWS)" or api_service == "Open-Meteo" else 0
        result_current_conditions["humidity"] = 50
        result_current_conditions["dew_point"] = int(16.1) if display_metric else int(61.0)
        result_current_conditions["uv_index"] = 3
        result_current_conditions["visibility"] = int(16.3) if display_metric else int(10.1)
        result_current_conditions["cloud_coverage"] = 80
        result_current_conditions["pressure"] = int(1014.90) if display_metric else int(29.97)
    else:
        if api_service == "National Weather Service (NWS)":
            enabledMetrics["uvIndex"] = False
            enabledMetrics["visibility"] = False
            enabledMetrics["cloudCoverage"] = False
            enabledMetrics["pressure"] = False
            enabledMetrics["aqi"] = False

            hourly_forecast_url = get_nws_hourly_grid_forecast_url(latitude, longitude, 3600)  # cache for minimum of 1 hr. (this does not really change once 'Location' has been set via schema field)
            raw_current_conditions = get_current_weather_conditions(hourly_forecast_url, 300)["properties"]["periods"][0]  # ttl of 5 min. (to prevent abuse)

            result_current_conditions["icon"] = {"condition": str(raw_current_conditions["shortForecast"]).lower(), "daytime": raw_current_conditions["isDaytime"]}
            temperature = int(raw_current_conditions["temperature"])
            result_current_conditions["temp"] = int(temperature if raw_current_conditions["temperatureUnit"] == "F" and not (display_metric) else ((temperature - 32) * (5 / 9)))
            wind_speed = int(re.match("\\d+", raw_current_conditions["windSpeed"])[0][0])
            result_current_conditions["wind_speed"] = int(wind_speed * (1 if "mph" in raw_current_conditions["windSpeed"] and not (display_metric) else 0.44704))
            result_current_conditions["wind_dir"] = str(raw_current_conditions["windDirection"])

            icon_phrase = result_current_conditions["icon"]["condition"]
            is_daytime = result_current_conditions["icon"]["daytime"]
            if (icon_phrase == "sunny" or "fair" in icon_phrase or "clear" in icon_phrase) and is_daytime:
                # sunny
                icon_ref = "sunny.png"
            elif ("mostly sunny" in icon_phrase or "partly sunny" in icon_phrase or "few clouds" in icon_phrase or "partly cloudy" in icon_phrase) and is_daytime:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif icon_phrase == "cloudy" or "mostly cloudy" in icon_phrase or "overcast" in icon_phrase:
                # cloudy (day)
                icon_ref = "cloudy.png"
            elif "rain" in icon_phrase:
                # rain (day and night)
                icon_ref = "rainy.png"
            elif "thunderstorm" in icon_phrase:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif "snow" in icon_phrase:
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif ("fair" in icon_phrase or "clear" in icon_phrase) and not (is_daytime):
                # clear (night)
                icon_ref = "moony.png"
            elif ("few clouds" in icon_phrase or "partly cloudy" in icon_phrase) and not (is_daytime):
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["relativeHumidity"]["value"])
            dewpoint = int(raw_current_conditions["dewpoint"]["value"])
            result_current_conditions["dew_point"] = int(dewpoint if "degC" in raw_current_conditions["dewpoint"]["unitCode"] and display_metric else (dewpoint * 1.8) + 32)

        elif api_service == "OpenWeather":
            enabledMetrics["dewPoint"] = False
            enabledMetrics["uvIndex"] = False

            request_url = OPENWEATHER_CURRWEATHER_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = system_of_measurement,
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)  # allows only 60 free calls per minute (ttl of 5 min.)

            result_current_conditions["icon"] = {"id": int(raw_current_conditions["weather"][0]["id"]), "code": str(raw_current_conditions["weather"][0]["icon"])}
            result_current_conditions["temp"] = int(raw_current_conditions["main"]["temp"])
            result_current_conditions["feels_like"] = int(raw_current_conditions["main"]["feels_like"])
            result_current_conditions["wind_speed"] = int(raw_current_conditions["wind"]["speed"])
            result_current_conditions["wind_dir"] = int(raw_current_conditions["wind"]["deg"])

            icon_num = result_current_conditions["icon"]["id"]
            icon_code = result_current_conditions["icon"]["code"]
            if icon_num == 800 and "d" in icon_code:
                # sunny
                icon_ref = "sunny.png"
            elif icon_num >= 801 and icon_num <= 802 and "d" in icon_code:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif icon_num >= 803 and icon_num <= 804 and "d" in icon_code:
                # cloudy (day)
                icon_ref = "cloudy.png"
            elif (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 701:
                # rain (day and night)
                icon_ref = "rainy.png"
            elif icon_num >= 200 and icon_num < 300:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif icon_num >= 600 and icon_num < 700:
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif icon_num == 731:
                # wind
                icon_ref = "windy.png"
            elif icon_num == 800 and "n" in icon_code:
                # clear (night)
                icon_ref = "moony.png"
            elif icon_num >= 801 and icon_num <= 804 and "n" in icon_code:
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["main"]["humidity"])
            result_current_conditions["visibility"] = int(raw_current_conditions["visibility"] * (0.001 if display_metric == "metric" else 0.00062137))
            result_current_conditions["cloud_coverage"] = int(raw_current_conditions["clouds"]["all"])
            result_current_conditions["pressure"] = int(raw_current_conditions["main"]["pressure"] * (0.02952998307 if display_metric else 1))  # 1 inHg (imperial) = 33.863886666667 hPa (metric)

            air_quality = get_openweather_air_pollution(api_key, latitude, longitude)
            result_current_conditions["aqi"] = air_quality["index"]
            # result_current_conditions["aqi_label"] = air_quality["label"]

        elif api_service == "OpenWeatherOneCall":
            request_url = OPENWEATHER_ONECALL_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = system_of_measurement,
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)  # TTL of 5 min.

            result_current_conditions["icon"] = {"id": int(raw_current_conditions["current"]["weather"][0]["id"]), "code": str(raw_current_conditions["current"]["weather"][0]["icon"])}
            result_current_conditions["temp"] = int(raw_current_conditions["current"]["temp"])
            result_current_conditions["feels_like"] = int(raw_current_conditions["current"]["feels_like"])
            result_current_conditions["wind_speed"] = int(raw_current_conditions["current"]["wind_speed"])
            result_current_conditions["wind_dir"] = int(raw_current_conditions["current"]["wind_deg"])

            icon_num = result_current_conditions["icon"]["id"]
            icon_code = result_current_conditions["icon"]["code"]
            if icon_num == 800 and "d" in icon_code:
                # sunny
                icon_ref = "sunny.png"
            elif icon_num >= 801 and icon_num <= 802 and "d" in icon_code:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif icon_num >= 803 and icon_num <= 804 and "d" in icon_code:
                # cloudy (day)
                icon_ref = "cloudy.png"
            elif (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 701:
                # rain (day and night)
                icon_ref = "rainy.png"
            elif icon_num >= 200 and icon_num < 300:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif icon_num >= 600 and icon_num < 700:
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif icon_num == 731:
                # wind
                icon_ref = "windy.png"
            elif icon_num == 800 and "n" in icon_code:
                # clear (night)
                icon_ref = "moony.png"
            elif icon_num >= 801 and icon_num <= 804 and "n" in icon_code:
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["current"]["humidity"])
            result_current_conditions["dew_point"] = int(raw_current_conditions["current"]["dew_point"])
            result_current_conditions["uv_index"] = int(raw_current_conditions["current"]["uvi"])
            result_current_conditions["visibility"] = int(raw_current_conditions["current"]["visibility"] * (0.001 if display_metric == "metric" else 0.00062137))
            result_current_conditions["cloud_coverage"] = int(raw_current_conditions["current"]["clouds"])
            result_current_conditions["pressure"] = int(raw_current_conditions["current"]["pressure"] * (0.02952998307 if display_metric else 1))  # 1 inHg (imperial) = 33.863886666667 hPa (metric)

            air_quality = get_openweather_air_pollution(api_key, latitude, longitude)
            result_current_conditions["aqi"] = air_quality["index"]
            # result_current_conditions["aqi_label"] = air_quality["label"]

        elif api_service == "Tomorrow.io":
            enabledMetrics["aqi"] = False

            request_url = TOMORROW_IO_REALTIME_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = system_of_measurement,
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)  # allows only 500 free requests per day (ttl of 5 min.)

            result_current_conditions["weather_code"] = int(raw_current_conditions["data"]["values"]["weatherCode"])
            result_current_conditions["temp"] = int(raw_current_conditions["data"]["values"]["temperature"])
            result_current_conditions["feels_like"] = int(raw_current_conditions["data"]["values"]["temperatureApparent"])
            result_current_conditions["wind_speed"] = int(raw_current_conditions["data"]["values"]["windSpeed"])
            result_current_conditions["wind_dir"] = int(raw_current_conditions["data"]["values"]["windDirection"])

            icon_num = result_current_conditions["weather_code"]
            if (icon_num >= 1000 and icon_num <= 1101) and hours < 21:
                # sunny
                icon_ref = "sunny.png"
            elif icon_num == 1100 and hours < 21:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif ((icon_num >= 1101 and icon_num <= 1103) or icon_num == 1001) and hours < 21:
                # cloudy (day and night)
                icon_ref = "cloudy.png"
            elif (icon_num >= 4000 and icon_num <= 4001) or (icon_num >= 4200 and icon_num <= 4201):
                # rain (day and night)
                icon_ref = "rainy.png"
            elif icon_num == 8000:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif (icon_num >= 5000 and icon_num <= 5001) or (icon_num >= 5100 and icon_num <= 5101):
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif (icon_num >= 1000 and icon_num <= 1101) and hours >= 21:
                # clear (night)
                icon_ref = "moony.png"
            elif ((icon_num >= 1102 and icon_num <= 1103) or icon_num == 1001) and hours >= 21:
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["data"]["values"]["humidity"])
            result_current_conditions["dew_point"] = int(raw_current_conditions["data"]["values"]["dewPoint"])
            result_current_conditions["uv_index"] = int(raw_current_conditions["data"]["values"]["uvIndex"])
            result_current_conditions["visibility"] = int(raw_current_conditions["data"]["values"]["visibility"])
            result_current_conditions["cloud_coverage"] = int(raw_current_conditions["data"]["values"]["cloudCover"])
            result_current_conditions["pressure"] = int(raw_current_conditions["data"]["values"]["pressureSurfaceLevel"])

        elif api_service == "Open-Meteo":
            enabledMetrics["aqi"] = False

            request_url = OPEN_METEO_FORECAST_URL.format(
                latitude = latitude,
                longitude = longitude,
                temperature_unit = ("celsius" if system_of_measurement == "metric" else "fahrenheit"),
                wind_speed_unit = ("ms" if system_of_measurement == "metric" else "mph"),
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 3600)

            result_current_conditions["weather_code"] = {"id": int(raw_current_conditions["current"]["weather_code"]), "is_day": int(raw_current_conditions["current"]["is_day"])}
            result_current_conditions["temp"] = int(raw_current_conditions["current"]["temperature_2m"])
            result_current_conditions["feels_like"] = int(raw_current_conditions["current"]["apparent_temperature"])
            result_current_conditions["wind_speed"] = int(raw_current_conditions["current"]["wind_speed_10m"])
            result_current_conditions["wind_dir"] = int(raw_current_conditions["current"]["wind_direction_10m"])

            icon_num = result_current_conditions["weather_code"]["id"]
            is_day = result_current_conditions["weather_code"]["is_day"]
            if icon_num == 0 and is_day == 1:
                # sunny
                icon_ref = "sunny.png"
            elif icon_num == 1 and is_day == 1:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif icon_num >= 2 and icon_num <= 3 and is_day == 1:
                # cloudy (day and night)
                icon_ref = "cloudy.png"
            elif icon_num == 51 or icon_num == 53 or icon_num == 55 or icon_num == 61 or icon_num == 63 or icon_num == 65 or (icon_num >= 80 and icon_num <= 82):
                # rain (day and night)
                icon_ref = "rainy.png"
            elif icon_num == 95 or icon_num == 96 or icon_num == 99:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif icon_num == 71 or icon_num == 73 or icon_num == 75 or icon_num == 77 or (icon_num >= 85 and icon_num <= 86):
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif icon_num == 0 and is_day == 0:
                # clear (night)
                icon_ref = "moony.png"
            elif icon_num >= 1 and icon_num <= 3 and is_day == 0:
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["current"]["relative_humidity_2m"])
            result_current_conditions["dew_point"] = int(raw_current_conditions["hourly"]["dew_point_2m"][0])
            result_current_conditions["uv_index"] = int(raw_current_conditions["hourly"]["uv_index"][0])
            result_current_conditions["visibility"] = int(raw_current_conditions["hourly"]["visibility"][0] * (0.001 if display_metric else 0.0006213712))
            result_current_conditions["cloud_coverage"] = int(raw_current_conditions["current"]["cloud_cover"])
            result_current_conditions["pressure"] = int(raw_current_conditions["current"]["pressure_msl"] * (1 if display_metric else 0.02952998307))  # 1 inHg (imperial) = 33.863886666667 hPa (metric)

        elif api_service == "Weatherbit":
            request_url = WEATHERBIT_CURRENT_WEATHER_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = ("M" if system_of_measurement == "metric" else "I"),
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)["data"][0]  # TTL of 5 min.

            result_current_conditions["icon"] = {"id": int(raw_current_conditions["weather"]["code"]), "code": str(raw_current_conditions["weather"]["icon"])}
            result_current_conditions["temp"] = int(raw_current_conditions["temp"])
            result_current_conditions["feels_like"] = int(raw_current_conditions["app_temp"])
            result_current_conditions["wind_speed"] = int(raw_current_conditions["wind_spd"])
            result_current_conditions["wind_dir"] = int(raw_current_conditions["wind_dir"])

            icon_num = result_current_conditions["icon"]["id"]
            icon_code = result_current_conditions["icon"]["code"]
            if icon_num == 800 and "d" in icon_code:
                # sunny
                icon_ref = "sunny.png"
            elif icon_num >= 801 and icon_num <= 802 and "d" in icon_code:
                # mostly sunny
                icon_ref = "sunnyish.png"
            elif icon_num >= 803 and icon_num <= 804 and "d" in icon_code:
                # cloudy (day)
                icon_ref = "cloudy.png"
            elif (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 900:
                # rain (day and night)
                icon_ref = "rainy.png"
            elif icon_num >= 200 and icon_num < 300:
                # thunderstorm (day and night)
                icon_ref = "thundery.png"
            elif icon_num >= 600 and icon_num < 700:
                # snow (day and night)
                icon_ref = "snowy2.png"
            elif icon_num == 800 and "n" in icon_code:
                # clear (night)
                icon_ref = "moony.png"
            elif icon_num >= 801 and icon_num <= 804 and "n" in icon_code:
                # partly cloudy (night)
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["rh"])
            result_current_conditions["dew_point"] = int(raw_current_conditions["dewpt"])
            result_current_conditions["uv_index"] = int(raw_current_conditions["uv"])
            result_current_conditions["visibility"] = int(raw_current_conditions["vis"])
            result_current_conditions["cloud_coverage"] = int(raw_current_conditions["clouds"])
            result_current_conditions["pressure"] = int(raw_current_conditions["pres"] * (1 if display_metric else 0.02952998307))  # 1 inHg (imperial) = 33.863886666667 hPa (metric)
            result_current_conditions["aqi"] = int(raw_current_conditions["aqi"])

        # print(result_current_conditions)  # uncomment to debug

    if icon_ref:
        weather_image = render.Image(width = 24, height = 24, src = base64.decode(WEATHER_ICONS[icon_ref]))
    else:
        weather_image = render.Box(width = 24, height = 24)

    # wind direction, reduce to cardinal and ordinal directions only
    if result_current_conditions.get("wind_dir", "N"):
        wind_dir = result_current_conditions["wind_dir"]
        if type(wind_dir) == "int" and wind_dir >= 0 and wind_dir < 45:
            wind_dir = "N"
        elif (type(wind_dir) == "int" and wind_dir >= 45 and wind_dir < 90) or wind_dir == "NNE" or wind_dir == "ENE":
            wind_dir = "NE"
        elif type(wind_dir) == "int" and wind_dir >= 90 and wind_dir < 135:
            wind_dir = "E"
        elif (type(wind_dir) == "int" and wind_dir >= 135 and wind_dir < 180) or wind_dir == "ESE" or wind_dir == "SSE":
            wind_dir = "SE"
        elif type(wind_dir) == "int" and wind_dir >= 180 and wind_dir < 225:
            wind_dir = "S"
        elif (type(wind_dir) == "int" and wind_dir >= 225 and wind_dir < 270) or wind_dir == "SSW" or wind_dir == "WSW":
            wind_dir = "SW"
        elif type(wind_dir) == "int" and wind_dir >= 270 and wind_dir < 315:
            wind_dir = "W"
        elif (type(wind_dir) == "int" and wind_dir >= 315 and wind_dir < 360) or wind_dir == "WNW" or wind_dir == "NNW":
            wind_dir = "NW"

    if hours == 0:
        hours_str = ("12" if time_format == "12 hour" else "00")
    elif hours > 12 and time_format == "12 hour":
        hours_str = str(hours - 12)
    else:
        hours_str = ("0" if hours < 10 and time_format != "12 hour" else "") + str(hours)

    time_hh_text = render.Text(
        content = hours_str,
        font = "tom-thumb",
    )
    time_mm_text = render.Text(content = ("0000" + str(minutes))[-2:], font = "tom-thumb")
    time_ampm_text = render.Text(content = "AM" if hours < 12 else "PM", font = "tom-thumb")

    temp_text = render.Text(content = str(result_current_conditions["temp"]) + "°" + ("C" if display_metric else "F"), font = "6x13", color = temp_color)
    feels_like_text = render.Text(content = "FEELS " + str(result_current_conditions["feels_like"]), font = "tom-thumb", color = temp_color) if result_current_conditions.get("feels_like") else None

    if enabledMetrics["windSpeed"]:
        wind_speed_text = render.Text(content = str(result_current_conditions["wind_speed"]), font = "tom-thumb", color = "#AED6F1")
        wind_mph_text = render.Text(content = "m/s" if display_metric else "mph", font = "tom-thumb", color = "#AED6F1")

        arrow_src = WIND_ICONS[wind_dir]
        if arrow_src:
            arrow_image = render.Image(width = 7, height = 7, src = base64.decode(arrow_src))
        else:
            arrow_image = render.Box(width = 7, height = 7)

    if enabledMetrics["humidity"]:
        humidity_text = render.Padding(
            child = render.Text(content = str(result_current_conditions["humidity"]), font = "tom-thumb", color = "#AED6F1"),
            pad = (0, 1, 0, 0),
        )
        humidity_unit_text = render.Text(content = "%", font = "tom-thumb", color = "#AED6F1")
        humidity_image = render.Image(width = 5, height = 6, src = base64.decode(RAINDROP_ICON))

    if enabledMetrics["dewPoint"]:
        dew_point_text = render.Text(content = str(result_current_conditions["dew_point"]), font = "tom-thumb", color = "#88D1FF")
        dew_point_unit_text = render.Text(content = "°C" if display_metric else "°F", font = "tom-thumb", color = "#88D1FF")
        dew_image = render.Image(width = 6, height = 7, src = base64.decode(DROPLETS_ICON))

    if enabledMetrics["uvIndex"]:
        uv_index = result_current_conditions["uv_index"]
        uv_index_label = "Low"
        uv_index_label_color = "#4C9329"
        if uv_index >= 3 and uv_index <= 5:
            uv_index_label = "Mod."  # Moderate
            uv_index_label_color = "#F2E34B"
        elif uv_index >= 6 and uv_index <= 7:
            uv_index_label = "High"
            uv_index_label_color = "#E7642B"
        elif uv_index >= 8 and uv_index <= 10:
            uv_index_label = "V.High"  # Very High
            uv_index_label_color = "#C72A23"
        elif uv_index >= 11:
            uv_index_label = "Extr."  # Extreme
            uv_index_label_color = "#674BC2"
        uv_index_text = render.Padding(
            child = render.Text(content = str(uv_index), font = "tom-thumb", color = uv_index_label_color),
            pad = (0, 1, 0, 0),
        )
        uv_index_label_text = render.Padding(
            child = render.Text(content = uv_index_label, font = "tom-thumb", color = uv_index_label_color),
            pad = (0, 1, 0, 0),
        )

    if enabledMetrics["visibility"]:
        visibility_text = render.Padding(
            child = render.Text(content = str(result_current_conditions["visibility"]), font = "tom-thumb", color = "#FFF"),
            pad = (0, 1, 0, 0),
        )
        visibility_unit_text = render.Text(content = "km" if display_metric else "mi", font = "tom-thumb", color = "#FFF")
        eye_image = render.Image(src = base64.decode(EYEGLASSES_ICON), width = 7, height = 6)

    if enabledMetrics["cloudCoverage"]:
        cloud_coverage_text = render.Padding(
            child = render.Text(
                content = str(result_current_conditions["cloud_coverage"]),
                font = "tom-thumb",
                color = "#FFF",
            ),
            pad = (0, 1, 0, 0),
        )
        cloud_coverage_unit_text = render.Text(
            content = "%",
            font = "tom-thumb",
            color = "#FFF",
        )
        cloud_image = render.Image(width = 8, height = 6, src = base64.decode(CLOUD_ICON))

    if enabledMetrics["pressure"]:
        pressure_text = render.Padding(
            child = render.Text(content = str(result_current_conditions["pressure"]), font = "tom-thumb", color = "#FFF"),
            pad = (0, 1, 0, 0),
        )
        pressure_unit_text = render.Text(content = "hPa" if display_metric else "inHg", font = "tom-thumb", color = "#FFF")

    if enabledMetrics["aqi"]:
        def aqi_color(num):
            switch = {
                1: "#26de81",
                2: "#fed330",
                3: "#fd9644",
                4: "#eb2f06",
                5: "#b71540",
            }
            return switch.get(num, "#FFF")

        aqi = result_current_conditions.get("aqi", "-")
        aqi_text = render.Padding(
            child = render.Text(content = str(aqi), font = "tom-thumb", color = aqi_color(aqi)),
            pad = (0, 1, 0, 0),
        )
        aqi_prefix_text = render.Text(content = "AQI:", font = "tom-thumb", color = "#CCC")

    return render.Root(
        delay = 2500,
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                weather_image,
                                render.Row(
                                    children = [
                                        time_hh_text,
                                        render.Image(width = 2, height = 5, src = base64.decode(COLON)),
                                        time_mm_text,
                                        render.Box(width = 1) if time_format == "12 hour" else None,
                                        time_ampm_text if time_format == "12 hour" else None,
                                    ],
                                ),
                            ],
                            expanded = True,
                            cross_align = "center",
                        ),
                        render.Column(
                            children = [
                                temp_text,
                                feels_like_text,
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Animation(
                                        children = [
                                            render.Row(
                                                children = [
                                                    wind_speed_text,
                                                    render.Box(width = 1, height = 1),
                                                    wind_mph_text,
                                                    # render.Box(width = 2, height = 1),
                                                    arrow_image,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["windSpeed"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    humidity_text,
                                                    render.Box(width = 1, height = 1),
                                                    humidity_unit_text,
                                                    render.Box(width = 2, height = 1),
                                                    humidity_image,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["humidity"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    render.Padding(
                                                        pad = (0, 1, 0, 0),
                                                        child = dew_point_text,
                                                    ),
                                                    render.Padding(
                                                        pad = (0, 1, 0, 0),
                                                        child = dew_point_unit_text,
                                                    ),
                                                    render.Box(width = 2, height = 1),
                                                    dew_image,
                                                ],
                                                cross_align = "center",
                                                main_align = "center",
                                            ) if enabledMetrics["dewPoint"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    uv_index_text,
                                                    render.Box(width = 3, height = 1),
                                                    uv_index_label_text,
                                                ],
                                                cross_align = "center",
                                                main_align = "center",
                                            ) if enabledMetrics["uvIndex"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    visibility_text,
                                                    render.Box(width = 1, height = 1),
                                                    visibility_unit_text,
                                                    render.Box(width = 2, height = 1),
                                                    eye_image,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["visibility"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    cloud_coverage_text,
                                                    render.Box(width = 1, height = 1),
                                                    cloud_coverage_unit_text,
                                                    render.Box(width = 2, height = 1),
                                                    cloud_image,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["cloudCoverage"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    pressure_text,
                                                    render.Box(width = 1, height = 1),
                                                    pressure_unit_text,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["pressure"] == "true" else None,
                                            render.Row(
                                                children = [
                                                    aqi_prefix_text,
                                                    render.Box(width = 1, height = 1),
                                                    aqi_text,
                                                ],
                                                cross_align = "end",
                                                main_align = "center",
                                            ) if enabledMetrics["aqi"] == "true" else None,
                                        ],
                                    ),
                                ),
                            ],
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                        ),
                    ],
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                ),
                render.Row(
                    children = [render.Text("SAMPLE" if display_sample else "", font = "6x13", color = "#FF0000", height = 22)],
                    main_align = "center",
                    expanded = True,
                ),
            ],
        ),
    )

def more_toggles(weatherApiService):
    additional_toggles = {
        "wind_speed": schema.Toggle(
            id = "windSpeedEnabled",
            name = "Wind speed",
            desc = "Display wind speed",
            icon = "wind",
            default = True,
        ),
        "humidity": schema.Toggle(
            id = "humidityEnabled",
            name = "Humidity",
            desc = "Display humidity",
            icon = "water",
            default = False,
        ),
        "dew_point": schema.Toggle(
            id = "dewPointEnabled",
            name = "Dew point",
            desc = "Display dew point",
            icon = "droplet",
            default = False,
        ),
        "uv_index": schema.Toggle(
            id = "uvIndexEnabled",
            name = "UV Index",
            desc = "Display UV Index",
            icon = "umbrellaBeach",
            default = False,
        ),
        "visibility": schema.Toggle(
            id = "visibilityEnabled",
            name = "Visibility",
            desc = "Display visibility",
            icon = "eye",
            default = False,
        ),
        "cloud_coverage": schema.Toggle(
            id = "cloudCoverageEnabled",
            name = "Cloud coverage",
            desc = "Display cloud coverage",
            icon = "cloudSun",
            default = False,
        ),
        "pressure": schema.Toggle(
            id = "pressureEnabled",
            name = "Pressure",
            desc = "Display pressure",
            icon = "arrowTrendDown",
            default = False,
        ),
        "aqi": schema.Toggle(
            id = "aqiEnabled",
            name = "AQI",
            desc = "Display air qualiity index",
            icon = "star",
            default = False,
        ),
    }

    if weatherApiService == "National Weather Service (NWS)":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["dew_point"],
        ]
    elif weatherApiService == "OpenWeather":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["visibility"],
            additional_toggles["cloud_coverage"],
            additional_toggles["pressure"],
            additional_toggles["aqi"],
        ]
    elif weatherApiService == "OpenWeatherOneCall":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["dew_point"],
            additional_toggles["uv_index"],
            additional_toggles["visibility"],
            additional_toggles["cloud_coverage"],
            additional_toggles["pressure"],
            additional_toggles["aqi"],
        ]
    elif weatherApiService == "Tomorrow.io":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["dew_point"],
            additional_toggles["uv_index"],
            additional_toggles["visibility"],
            additional_toggles["cloud_coverage"],
            additional_toggles["pressure"],
        ]
    elif weatherApiService == "Open-Meteo":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["dew_point"],
            additional_toggles["uv_index"],
            additional_toggles["visibility"],
            additional_toggles["cloud_coverage"],
            additional_toggles["pressure"],
        ]
    elif weatherApiService == "Weatherbit":
        return [
            additional_toggles["wind_speed"],
            additional_toggles["humidity"],
            additional_toggles["dew_point"],
            additional_toggles["uv_index"],
            additional_toggles["visibility"],
            additional_toggles["cloud_coverage"],
            additional_toggles["pressure"],
            additional_toggles["aqi"],
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "weatherApiService",
                name = "Weather API Service",
                desc = "Select your preferred Weather API",
                icon = "database",
                default = "OpenWeather",
                options = [
                    schema.Option(
                        display = "National Weather Service (NWS)",
                        value = "National Weather Service (NWS)",
                    ),
                    schema.Option(
                        display = "OpenWeather",
                        value = "OpenWeather",
                    ),
                    schema.Option(
                        display = "OpenWeather (One Call API 3.0)",
                        value = "OpenWeatherOneCall",
                    ),
                    schema.Option(
                        display = "Tomorrow.io",
                        value = "Tomorrow.io",
                    ),
                    schema.Option(
                        display = "Open-Meteo",
                        value = "Open-Meteo",
                    ),
                    schema.Option(
                        display = "Weatherbit",
                        value = "Weatherbit",
                    ),
                ],
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "API key for weather data access",
                icon = "gear",
                default = "",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "systemOfMeasurement",
                name = "System of measurement",
                desc = "Choose which system to display measurements",
                icon = "ruler",
                default = "Imperial",
                options = [
                    schema.Option(
                        display = "Imperial",
                        value = "Imperial",
                    ),
                    schema.Option(
                        display = "Metric",
                        value = "Metric",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "timeFormat",
                name = "Time Format",
                desc = "The format used for the time",
                icon = "clock",
                default = "12 hour",
                options = [
                    schema.Option(
                        display = "12 hour",
                        value = "12 hour",
                    ),
                    schema.Option(
                        display = "24 hour",
                        value = "24 hour",
                    ),
                ],
            ),
            schema.Color(
                id = "tempColor",
                name = "Temperature color",
                desc = "Color for temperature",
                icon = "brush",
                default = TEMP_COLOR_DEFAULT,
            ),
            schema.Generated(
                id = "generatedWeatherMetrics",
                source = "weatherApiService",
                handler = more_toggles,
            ),
        ],
    )

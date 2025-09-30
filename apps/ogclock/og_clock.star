"""
Applet: OG Clock Remake with Weather
Summary: OG Clock Remake with Location Configuration and Weather Display
Description: Display the time in addition to current weather and humidity from either OpenWeather or National Weather Service (no API key required for NWS). To request an OpenWeather API key, see https://home.openweathermap.org/users/sign_up.
Author: g3rmanaviator (with thanks to bendiep and jwinslow23)
Version: 1.0

"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

# Weather API URLs from Time & Weather
NWS_GRID_FORECAST_POINT_URL = "https://api.weather.gov/points/{latitude},{longitude}"
NWS_HOURLY_GRID_FORECAST_URL = "https://api.weather.gov/gridpoints/BOX/{gridX},{gridY}/forecast/hourly"
OPENWEATHER_CURRWEATHER_URL = "https://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units={units}&lang=en"
OPENWEATHER_AIR_POLLUTION_URL = "http://api.openweathermap.org/data/2.5/air_pollution?lat={latitude}&lon={longitude}&appid={api_key}"
OPENWEATHER_ONECALL_URL = "https://api.openweathermap.org/data/3.0/onecall?lat={latitude}&lon={longitude}&exclude=minutely,hourly,daily,alerts&appid={api_key}&units={units}&lang=en"

TEMP_COLOR_DEFAULT = "#FFFFFF"
TIME_NIGHT_COLOR = "#333333"

# Complete weather icons from Time & Weather
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

RAINDROP_ICON = """
iVBORw0KGgoAAAANSUhEUgAAAA4AAAASCAYAAABrXO8xAAAAzUlEQVR42mJgIBMw4pJYd+1jAZCyB+LEIC3+D+jyLDg0JQCpfihXAIgd0dUwYdGkgKQJBByAYg0ENQLBfKgtyKAeqNkAp0aovxxweHs+Vo1QJ9bjCUgDZCcj21iPxYnoIB+oWQCuEWpbAhHRB9JUgGxjPglxn4+s0YEEjQJAFzrANBqQmuRgGh+Qq/EACXo+ANPuAZjGRhI0LoDbCDQB5NREIjRdgFkCTwBAzQugmj/g0LQBlEtgWYwRS+4ARXIAECvA/ATSBHUVHAAEGADlNDsN6Dca6wAAAABJRU5ErkJggg==
"""

# Weather API functions from Time & Weather
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
    return air_quality
	
def nightScreen(now, config):
    # Use OG Clock’s settings
    use_24_hour = config.bool("24hour_format", False)
    time_color = TIME_NIGHT_COLOR  # dim color at night

    # Blinking colon: reuse your exact OG logic
    if config.bool("blink", True):
        blink_vec = [render.Text(":", font = "6x13", color = time_color)] * 5
        blink_vec.extend([render.Text(":", font = "6x13", color = "#000")] * 5)
        blink_text = render.Animation(blink_vec)
    else:
        blink_text = render.Text(":", font = "6x13", color = time_color)

    # Hours / minutes: reuse your existing formatting
    if use_24_hour:
        hour_text = now.format("15")
        minute_text = now.format("04")
    else:
        if now.hour == 0:
            hour_text = "12"
        elif now.hour > 12:
            hour_text = str(now.hour - 12)
        else:
            hour_text = str(now.hour)
        minute_text = now.format("04 PM")

    return render.Root(
        delay = 500,
        max_age = 120,
        child = render.Padding(
            pad = (0, 8, 0, 0),
            child = render.Column(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(width = 64, height = 1),
                    render.Row(
                        children = [
                            render.Text(content = hour_text, font = "6x13", color = time_color),
                            blink_text,
                            render.Text(content = minute_text, font = "6x13", color = time_color),
                        ],
                    ),
                ],
            ),
        ),
    )


def main(config):
    # Get location info from config or use default
    location_info = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location_info["timezone"]
    latitude = float(location_info["lat"])
    longitude = float(location_info["lng"])
    
    # Add this right after getting the current time
    now = time.now().in_location(timezone)

    # Night mode check
    nightModeStr = config.get("nightModeStart")
    if nightModeStr == None:
        nightModeStartHr = 23
        nightModeStartMin = 0
    else:
        nightModeStartHr = int(nightModeStr[0:2])
        if nightModeStartHr >= 24:
            nightModeStartHr = 0
        nightModeStartMin = int(nightModeStr[2:4])

    dayModeStr = config.get("nightModeEnd")
    if dayModeStr == None:
        dayModeEndHr = 7
        dayModeEndMin = 0
    else:
        dayModeEndHr = int(dayModeStr[0:2])
        dayModeEndMin = int(dayModeStr[2:4])

    # Update variable names to match:
    start_total = nightModeStartHr * 60 + nightModeStartMin
    end_total = dayModeEndHr * 60 + dayModeEndMin
    
    night_mode_enabled = config.bool("night_mode", False)
    if night_mode_enabled:
        current_hour = now.hour
        current_minute = now.minute
        current_total = current_hour * 60 + current_minute
        
        # Check if night mode crosses midnight
        if start_total > end_total:
            # Crosses midnight (e.g., 23:00 to 07:00)
            in_night_mode = current_total >= start_total or current_total < end_total
        else:
            # Same day (e.g., 01:00 to 05:00)
            in_night_mode = current_total >= start_total and current_total < end_total
        
        if in_night_mode:
            return nightScreen(now, config)
               
    # Get display settings from OG Clock
    use_24_hour = config.bool("24hour_format", False)
    time_color = config.get("time_color", "fff")
    
    # Get blinking separator setting (matching custom clock implementation)
    if config.bool("blink", True):
        blink_vec = [render.Text(":", font = "6x13", color = time_color)] * 5
        blink_vec.extend([render.Text(":", font = "6x13", color = "#000")] * 5)
        blink_text = render.Animation(blink_vec)
    else:
        blink_text = render.Text(":", font = "6x13", color = time_color)
    
    # Weather settings
    api_service = config.get("weatherApiService") or "OpenWeather"
    api_key = config.get("apiKey", "")
    system_of_measurement = config.get("systemOfMeasurement", "Imperial").lower()
    temp_color = config.get("tempColor", TEMP_COLOR_DEFAULT)
    
    display_metric = (system_of_measurement == "metric")
    display_sample = not (api_key) and api_service != "Open-Meteo" and api_service != "National Weather Service (NWS)"

    # Format time components for proper blinking colon display
    if use_24_hour:
        hour_text = now.format("15")
        minute_text = now.format("04")
    else:
        if now.hour == 0:
            hour_text = "12"
        elif now.hour > 12:
            hour_text = str(now.hour - 12)
        else:
            hour_text = str(now.hour)
        minute_text = now.format("04 PM")

    # Initialize weather variables
    icon_ref = None
    result_current_conditions = {}
    hours = now.hour

    if display_sample:
        # Sample data to display if user-specified API / location key are not available
        icon_ref = "sunnyish.png"
        result_current_conditions["temp"] = 14 if display_metric else 57
        result_current_conditions["humidity"] = 50
    else:
        if api_service == "National Weather Service (NWS)":
            hourly_forecast_url = get_nws_hourly_grid_forecast_url(latitude, longitude, 3600)
            raw_current_conditions = get_current_weather_conditions(hourly_forecast_url, 300)["properties"]["periods"][0]

            result_current_conditions["icon"] = {"condition": str(raw_current_conditions["shortForecast"]).lower(), "daytime": raw_current_conditions["isDaytime"]}
            temperature = int(raw_current_conditions["temperature"])
            result_current_conditions["temp"] = int(temperature if raw_current_conditions["temperatureUnit"] == "F" and not (display_metric) else ((temperature - 32) * (5 / 9)))

            icon_phrase = result_current_conditions["icon"]["condition"]
            is_daytime = result_current_conditions["icon"]["daytime"]
            if (icon_phrase == "sunny" or "fair" in icon_phrase or "clear" in icon_phrase) and is_daytime:
                icon_ref = "sunny.png"
            elif ("mostly sunny" in icon_phrase or "partly sunny" in icon_phrase or "few clouds" in icon_phrase or "partly cloudy" in icon_phrase) and is_daytime:
                icon_ref = "sunnyish.png"
            elif icon_phrase == "cloudy" or "mostly cloudy" in icon_phrase or "overcast" in icon_phrase:
                icon_ref = "cloudy.png"
            elif "rain" in icon_phrase:
                icon_ref = "rainy.png"
            elif "thunderstorm" in icon_phrase:
                icon_ref = "thundery.png"
            elif "snow" in icon_phrase:
                icon_ref = "snowy2.png"
            elif ("fair" in icon_phrase or "clear" in icon_phrase) and not (is_daytime):
                icon_ref = "moony.png"
            elif ("few clouds" in icon_phrase or "partly cloudy" in icon_phrase) and not (is_daytime):
                icon_ref = "moonyish.png"

            result_current_conditions["humidity"] = int(raw_current_conditions["relativeHumidity"]["value"])

        elif api_service == "OpenWeather":
            request_url = OPENWEATHER_CURRWEATHER_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = system_of_measurement,
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)

            result_current_conditions["temp"] = int(raw_current_conditions["main"]["temp"])
            result_current_conditions["humidity"] = int(raw_current_conditions["main"]["humidity"])

            icon_num = int(raw_current_conditions["weather"][0]["id"])
            icon_code = str(raw_current_conditions["weather"][0]["icon"])
            if icon_num == 800 and "d" in icon_code:
                icon_ref = "sunny.png"
            elif icon_num >= 801 and icon_num <= 802 and "d" in icon_code:
                icon_ref = "sunnyish.png"
            elif icon_num >= 803 and icon_num <= 804 and "d" in icon_code:
                icon_ref = "cloudy.png"
            elif (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 701:
                icon_ref = "rainy.png"
            elif icon_num >= 200 and icon_num < 300:
                icon_ref = "thundery.png"
            elif icon_num >= 600 and icon_num < 700:
                icon_ref = "snowy2.png"
            elif icon_num == 731:
                icon_ref = "windy.png"
            elif icon_num == 800 and "n" in icon_code:
                icon_ref = "moony.png"
            elif icon_num >= 801 and icon_num <= 804 and "n" in icon_code:
                icon_ref = "moonyish.png"

        elif api_service == "OpenWeatherOneCall":
            request_url = OPENWEATHER_ONECALL_URL.format(
                latitude = latitude,
                longitude = longitude,
                api_key = api_key,
                units = system_of_measurement,
            )
            raw_current_conditions = get_current_weather_conditions(request_url, 300)

            result_current_conditions["temp"] = int(raw_current_conditions["current"]["temp"])
            result_current_conditions["humidity"] = int(raw_current_conditions["current"]["humidity"])

            icon_num = int(raw_current_conditions["current"]["weather"][0]["id"])
            icon_code = str(raw_current_conditions["current"]["weather"][0]["icon"])
            if icon_num == 800 and "d" in icon_code:
                icon_ref = "sunny.png"
            elif icon_num >= 801 and icon_num <= 802 and "d" in icon_code:
                icon_ref = "sunnyish.png"
            elif icon_num >= 803 and icon_num <= 804 and "d" in icon_code:
                icon_ref = "cloudy.png"
            elif (icon_num >= 300 and icon_num < 400) or (icon_num >= 500 and icon_num < 600) or icon_num == 701:
                icon_ref = "rainy.png"
            elif icon_num >= 200 and icon_num < 300:
                icon_ref = "thundery.png"
            elif icon_num >= 600 and icon_num < 700:
                icon_ref = "snowy2.png"
            elif icon_num == 731:
                icon_ref = "windy.png"
            elif icon_num == 800 and "n" in icon_code:
                icon_ref = "moony.png"
            elif icon_num >= 801 and icon_num <= 804 and "n" in icon_code:
                icon_ref = "moonyish.png"

    # Prepare weather display components
    if icon_ref:
        weather_image = render.Image(width = 16, height = 16, src = base64.decode(WEATHER_ICONS[icon_ref]))
    else:
        weather_image = render.Box(width = 16, height = 16)

    # Temperature and humidity display
    temp_text = render.Text(
        content = str(result_current_conditions.get("temp", "?")) + "°" + ("C" if display_metric else "F"),
        font = "5x8",
        color = temp_color,
    )
    
    humidity_text = render.Text(
        content = str(result_current_conditions.get("humidity", "?")) + "%",
        font = "5x8",        
        color = "#848fEE",
    )

    # Layout - keeping OG Clock structure but adding weather
    return render.Root(
        delay = 500,
		max_age = 60,
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # Render Time - using the exact custom clock blinking implementation
                    render.Row(
                        children = [
                            render.Text(
                                content = hour_text,
                                font = "6x13",
                                color = time_color,
                            ),
                            # Blinking colon separator (exactly like custom clock)
                            blink_text,
                            render.Text(
                                content = minute_text,
                                font = "6x13",
                                color = time_color,
                            ),
                        ],
                    ),
                    # Weather section
                    render.Row(
                        cross_align = "center",
                        children = [
                            # Render Weather Icon
                            weather_image,
                            # Add spacing
                            render.Box(width = 4, height = 1),
                            render.Column(
                                children = [
                                    # Render Temperature
                                    temp_text,
                                    # Render Humidity
                                    humidity_text,
                                ],
                            ),
                        ],
                    ),
                    # Sample indicator
                    render.Text(
                        content = "SAMPLE" if display_sample else "",
                        font = "tom-thumb",
                        color = "#FF0000",
                    ) if display_sample else render.Box(width = 1, height = 1),
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
                desc = "Location for which to display time and weather.",
                icon = "locationArrow",
            ),
            schema.Toggle(
                id = "24hour_format",
                name = "24 hour clock",
                desc = "Enable for 24-hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Color(
                id = "time_color",
                name = "Time color",
                desc = "Change the color of the time.",
                icon = "brush",
                default = "fff",
            ),
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
                ],
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "API key for weather data access (not needed for NWS)",
                icon = "gear",
                default = "",
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
            schema.Color(
                id = "tempColor",
                name = "Temperature color",
                desc = "Color for temperature display",
                icon = "brush",
                default = TEMP_COLOR_DEFAULT,
            ),
            schema.Toggle(
                id = "blink",
                name = "Blinking separator",
                desc = "Blink the colon between hours and minutes.",
                icon = "gear",
                default = True,
            ),
			schema.Toggle(
				id = "night_mode",
				name = "Night Mode",
				desc = "Enable night mode - Dim the display and show only the clock",
				icon = "gear",
				default = False,
			),
            schema.Text(
                id = "nightModeStart",
                name = "Night Mode Start",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 2300",
                default = "2300",
            ),
            schema.Text(
                id = "nightModeEnd", 
                name = "Night Mode End",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 0730",
                default = "0700",
            ),
        ],
    )

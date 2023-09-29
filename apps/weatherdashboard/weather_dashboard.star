load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

AMBIENT_WEATHER_URL = "https://rt.ambientweather.net/v1/devices"

def main(config):
    current_data = get_weather_data(config)

    outside_temp = current_data["tempf"]
    feels_like = current_data["feelsLike"]
    humidity = current_data["humidity"]

    wind_spd_avg = current_data["windspdmph_avg10m"]
    wind_dir = get_wind_direction(current_data["winddir"])

    event_rain = current_data["eventrainin"]
    weekly_rain = current_data["weeklyrainin"]

    degree_sign = "°"

    weather_info = []
    weather_info.append(add_row("Temp", "{0}{1}".format(outside_temp, degree_sign)))
    weather_info.append(add_row("Wind", "{0} {1}".format(wind_dir, wind_spd_avg)))
    if config.bool("show_precip"):
        weather_info.append(render.Box(width = 64, height = 1, color = config.get("divider_color", "#1167B1")))
        weather_info.append(show_rainfall(weekly_rain, event_rain, config))
    else:
        weather_info.append(add_row("Feel", "{0}{1}".format(feels_like, degree_sign)))
        weather_info.append(add_row("Humidity", humidity))

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
                id = "show_precip",
                name = "Show Rainfall",
                desc = "Show rainfall totals",
                icon = "compress",
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

# pragma mark Helper Methods

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

def show_rainfall(week, event, config):
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Column(
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text("Event"),
                    render.Text("{0}\"".format(event), font = "tom-thumb"),
                ],
            ),
            render.Box(width = 1, height = 12, color = config.get("divider_color", "#1167B1")),
            render.Column(
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text("Weekly"),
                    render.Text("{0}\"".format(week), font = "tom-thumb"),
                ],
            ),
        ],
    )

def add_row(title, value):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text("{0}".format(title)),
            render.Text("{0}".format(value)),
        ],
    )

def get_wind_direction(heading):
    if heading <= 360 and heading >= 348.75:
        return "N"
    elif heading >= 0 and heading <= 11.25:
        return "N"
    elif heading >= 11.25 and heading <= 33.75:
        return "NNE"
    elif heading >= 33.75 and heading <= 56.25:
        return "NE"
    elif heading >= 56.25 and heading <= 78.75:
        return "ENE"
    elif heading >= 78.75 and heading <= 101.25:
        return "E"
    elif heading >= 101.25 and heading <= 123.75:
        return "ESE"
    elif heading >= 123.75 and heading <= 146.25:
        return "SE"
    elif heading >= 146.25 and heading <= 168.75:
        return "SSE"
    elif heading >= 168.75 and heading <= 191.25:
        return "S"
    elif heading >= 191.25 and heading <= 213.75:
        return "SSW"
    elif heading >= 213.75 and heading <= 236.25:
        return "SW"
    elif heading >= 236.25 and heading <= 258.75:
        return "WSW"
    elif heading >= 258.75 and heading <= 281.25:
        return "W"
    elif heading >= 281.25 and heading <= 303.75:
        return "WNW"
    elif heading >= 303.75 and heading <= 326.25:
        return "NW"
    elif heading >= 326.25 and heading <= 348.47:
        return "NNW"

    return "-"

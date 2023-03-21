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
    dew_point = current_data["dewPoint"]
    wind_spd_avg = current_data["windspdmph_avg10m"]

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                add_row("Temp", outside_temp),
                add_row("Feel", feels_like),
                add_row("Dew Pt", dew_point),
                add_row("Wind", wind_spd_avg),
            ],
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
            schema.Dropdown(
                id = "temp_sensor_index",
                name = "Temperature Sensor",
                desc = "Choose which Temperature sensor to show.",
                icon = "list",
                default = "tempSensor1",
                options = [
                    schema.Option(
                        display = "Outside Temp",
                        value = "tempSensorInside",
                    ),
                    schema.Option(
                        display = "Inside Temp",
                        value = "tempSensor1",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "humidity_sensor_index",
                name = "Humidity Sensor",
                desc = "Choose which Humidity sensor to show.",
                icon = "list",
                default = "humiditySensor1",
                options = [
                    schema.Option(
                        display = "Outside Humidity",
                        value = "humiditySensorInside",
                    ),
                    schema.Option(
                        display = "Inside Humidity",
                        value = "humiditySensor1",
                    ),
                ],
            ),
        ],
    )

# pragma mark Helper Methods

def get_weather_data(config):
    cached_data = cache.get("cached_data")
    if cached_data != None:
        print("Using existing weather data")
        cache_res = json.decode(cached_data)
        return cache_res

    else:
        print("Getting new weather data")
        res = http.get(
            url = AMBIENT_WEATHER_URL,
            params = {
                "applicationKey": config.get("application_key", APPLICATION_ID_DEF),
                "apiKey": config.get("api_key", API_KEY_DEF),
            },
        )
        if res.status_code != 200:
            fail("Ambient Weather request failed with status %d", res.status_code)

        current_data = res.json()[0]["lastData"]
        print("{0}".format(current_data))
        cache.set("cached_data", json.encode(current_data), ttl_seconds = 60)
        return current_data

def add_row(title, value):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            render.Text("{0}".format(title)),
            render.Text("{0}".format(value)),
        ],
    )

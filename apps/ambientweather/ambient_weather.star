"""
Applet: Ambient Weather
Summary: Your local weather
Description: Show readings from your Ambient weather station.
Author: Jon Maddox
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

AMBIENT_DEVICES_URL = "https://api.ambientweather.net/v1/devices"

def main(config):
    print("Running applet")

    stationID = config.get("station_id", None)

    if is_string_blank(stationID):
        print("using sample data")
        stations_res = json.decode(SAMPLE_STATIONS_RESPONSE)
        station = stations_res[0]
    else:
        print("using real data")
        station = get_station(config)

    if not station:
        return []

    conditions = station["lastData"]

    temp = "N/A"
    humidity = "N/A"
    uv = None
    windInfo = None

    if config.get("temp_sensor_index", None) == "tempSensor1":
        if "tempf" in conditions.keys():
            temp = "%d°" % conditions["tempf"]
        elif "temp1f" in conditions.keys():
            temp = "%d°" % conditions["temp1f"]
    elif config.get("temp_sensor_index", None) == "tempSensor2":
        if "temp2f" in conditions.keys():
            temp = "%d°" % conditions["temp2f"]
    elif config.get("temp_sensor_index", None) == "tempSensorInside":
        if "tempinf" in conditions.keys():
            temp = "%d°" % conditions["tempinf"]

    if config.get("humidity_sensor_index", None) == "humiditySensor1":
        if "humidity" in conditions.keys():
            humidity = "%d%%" % conditions["humidity"]
        elif "humidity1" in conditions.keys():
            humidity = "%d%%" % conditions["humidity1"]
    elif config.get("humidity_sensor_index", None) == "humiditySensor2":
        if "humidity2" in conditions.keys():
            humidity = "%d%%" % conditions["humidity2"]
    elif config.get("humidity_sensor_index", None) == "humiditySensorInside":
        if "humidityin" in conditions.keys():
            humidity = "%d%%" % conditions["humidityin"]

    if "windspeedmph" in conditions.keys():
        windSpeed = "%dmph" % conditions["windspeedmph"]
        windDirection = wind_direction(conditions["winddir"])
        windInfo = "%s %s" % (windSpeed, windDirection)

    if "uv" in conditions.keys():
        uv = "UV %d" % conditions["uv"]

    stationName = station["info"]["name"]

    title = config.get("title", None)
    if is_string_blank(title):
        title = stationName

    uvChild = None
    windInfoChild = None
    if uv:
        uvChild = render.Text(
            content = uv,
            color = "#ff0",
        )
    if windInfo:
        windInfoChild = render.Text(
            content = windInfo,
        )

    return render.Root(
        delay = 500,
        child = render.Box(
            padding = 1,
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(
                                content = title,
                                font = "tom-thumb",
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        children = [
                            render.Text(
                                content = temp,
                                color = "#2a2",
                            ),
                            render.Text(
                                content = humidity,
                                color = "#66f",
                            ),
                            uvChild,
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Box(width = 2, height = 1),
                            windInfoChild,
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
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Optionally overide the name of the station.",
                icon = "gear",
            ),
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
            schema.Text(
                id = "station_id",
                name = "Station ID",
                desc = "Your Ambient Weather station MAC address.",
                icon = "temperatureHalf",
            ),
            schema.Dropdown(
                id = "temp_sensor_index",
                name = "Temperature Sensor",
                desc = "Choose which Temperature sensor to show.",
                icon = "list",
                default = "tempSensor1",
                options = [
                    schema.Option(
                        display = "Inside",
                        value = "tempSensorInside",
                    ),
                    schema.Option(
                        display = "Sensor 1",
                        value = "tempSensor1",
                    ),
                    schema.Option(
                        display = "Sensor 2",
                        value = "tempSensor2",
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
                        display = "Inside",
                        value = "humiditySensorInside",
                    ),
                    schema.Option(
                        display = "Sensor 1",
                        value = "humiditySensor1",
                    ),
                    schema.Option(
                        display = "Sensor 2",
                        value = "humiditySensor2",
                    ),
                ],
            ),
        ],
    )

SAMPLE_STATIONS_RESPONSE = """[
	{
		"macAddress": "A9:B8:0B:A6:34:33",
		"lastData": {
			"dateutc": 1649165580000,
			"tempinf": 70.5,
			"humidityin": 47,
			"baromrelin": 30.08,
			"baromabsin": 30.033,
			"tempf": 65.3,
			"battout": 1,
			"humidity": 83,
			"winddir": 157,
			"windspeedmph": 5.4,
			"windgustmph": 8.1,
			"maxdailygust": 11.4,
			"hourlyrainin": 0,
			"eventrainin": 0,
			"dailyrainin": 0,
			"weeklyrainin": 0.031,
			"monthlyrainin": 0.862,
			"totalrainin": 21.402,
			"solarradiation": 368.23,
			"uv": 3,
			"batt_co2": 1,
			"feelsLike": 65.3,
			"dewPoint": 60,
			"feelsLikein": 69.5,
			"dewPointin": 49.3,
			"lastRain": "2022-04-03T11:41:00.000Z",
			"tz": "America/New_York",
			"date": "2022-04-05T13:33:00.000Z"
		},
		"info": {
			"name": "Nags Head",
			"coords": {
				"coords": {
					"lat": 35.9257597,
					"lon": -75.6183493
				},
				"address": "6701 S Virginia Dare Trail, Nags Head, NC 27959",
				"location": "Nags Head",
				"elevation": 0.0002911043993663043,
				"geo": {
					"type": "Point",
					"coordinates": [
						-75.6183493,
						35.9257597
					]
				}
			}
		}
	}
]"""

def is_string_blank(string):
    return string == None or len(string) == 0

def get_station(config):
    stations = get_stations(config)
    stationID = config.get("station_id", None)
    if stationID == None:
        return None

    for station in stations:
        if station["macAddress"] == stationID:
            return station

    return None

def get_stations(config):
    applicationKey = config.get("application_key", None)
    apiKey = config.get("api_key", None)

    if is_string_blank(applicationKey) or is_string_blank(apiKey):
        return []

    cachedStations = cache.get("ambient-weather-%s" % applicationKey)

    if cachedStations != None:
        print("Using cached stations")
        stations = json.decode(cachedStations)
    else:
        print("Fetching stations...")
        res = http.get(
            url = AMBIENT_DEVICES_URL,
            params = {
                "applicationKey": applicationKey,
                "apiKey": apiKey,
            },
        )
        if res.status_code != 200:
            fail("station request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        stations = res.json()
        cache.set("ambient-weather-%s" % applicationKey, json.encode(stations), ttl_seconds = 30)

    return stations

def wind_direction(heading):
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

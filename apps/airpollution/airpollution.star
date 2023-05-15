load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

### MAIN CODE ###

def main(config):
    status_code = 200

    airly_apikey = config.get("api_key")
    airly_id = config.get("airly_id")

    airly_street_out_cache = cache.get("airly_street_in_cache")
    airly_city_out_cache = cache.get("airly_city_in_cache")
    airly_pm25_out_cache = cache.get("airly_pm25_in_cache")
    airly_pm10_out_cache = cache.get("airly_pm10_in_cache")

    airly_street_value = ""
    airly_city_value = ""
    airly_pm25_value = ""
    airly_pm10_value = ""

    if airly_apikey == "" or airly_apikey == None or airly_id == "" or airly_id == None:
        # If the user does not define the ID of the measuring station and/or Airly ApiKey, there is no need to go through the entire application logic.
        # Information is returned to the user to provide this data.
        status_code = 999

    if status_code == 200:
        today = str(time.now().in_location("Europe/Warsaw"))[:10]
        day_out_cache = cache.get("day_in_cache")

        airly_id_out_cache = cache.get("airly_id")

        if today != day_out_cache:
            # Due to the limitation of 100 requests in free Airly API per day, it is necessary to count requests to Airly API.

            cache.set("day_in_cache", today, ttl_seconds = 86400)
            cache.set("airly_api_limit_counter_in_cache", str(0), ttl_seconds = 86400)

        if airly_street_out_cache == None or airly_id != airly_id_out_cache:
            # When the station ID is entered for the first time, the data about station info is stored in the cache

            print("Calling Airly API for info station")

            headers = {"Accept": "application/json", "apikey": airly_apikey}
            response_installations = http.get(url = AIRLY_INSTALLATIONS_API % airly_id, headers = headers)

            # Due to the limitation of 100 requests in free Airly API, it is necessary to count requests to Airly API.
            cache.set("airly_api_limit_counter_in_cache", str(int(cache.get("airly_api_limit_counter_in_cache")) + 1), ttl_seconds = 86400)

            if response_installations.status_code == 200:
                response_installations_data = response_installations.json()["address"]

                airly_street_value, airly_city_value = response_installations_data["displayAddress2"], response_installations_data["displayAddress1"]
                cache.set("airly_street_in_cache", str(airly_street_value), ttl_seconds = 86400)
                cache.set("airly_city_in_cache", str(airly_city_value), ttl_seconds = 86400)

            else:
                # If there is an error with the Airly API, the appropriate information is returned to the user.

                status_code = response_installations.status_code
                # fail("Airly API request failed with status %d" % response_installations.status_code)

        else:
            # In order not to send queries to the Airly API unnecessarily, station data about info station is stored in the cache until the user changes the station ID.

            print("Getting cached data info station")

            airly_street_value = str(airly_street_out_cache)
            airly_city_value = str(airly_city_out_cache)

    if status_code == 200:
        if airly_pm25_out_cache != None and airly_pm10_out_cache != None and airly_id == cache.get("airly_id"):
            # If 20 minutes have not passed since the measurement data was saved to the cache, we download the data from the cache and do not send unnecessary queries to the Airly API.
            # Or if the user has not changed the ID of the measuring station.

            print("Getting cached data measurments PM25 and PM10")

            airly_pm25_value = float(airly_pm25_out_cache)
            airly_pm10_value = float(airly_pm10_out_cache)

        else:
            # Measurement data is cached for 20 minutes. In order not to send unnecessary queries to the Airly API.

            print("Calling Airly API for measurments PM25 and PM10")

            cache.set("airly_id", str(airly_id), ttl_seconds = 86400)

            headers = {"Accept": "application/json", "apikey": airly_apikey}
            response_measurements = http.get(url = AIRLY_MEASUREMENTS_API % airly_id, headers = headers)

            # Due to the limitation of 100 requests in free Airly API, it is necessary to count requests to Airly API.
            cache.set("airly_api_limit_counter_in_cache", str(int(cache.get("airly_api_limit_counter_in_cache")) + 1), ttl_seconds = 86400)

            if response_measurements.status_code == 200:
                response_measurements_data = response_measurements.json()["current"]["values"]

                airly_pm25_value, airly_pm10_value = get_only_pm25_and_pm10_from_response_data(response_measurements_data)
                cache.set("airly_pm25_in_cache", str(float(airly_pm25_value)), ttl_seconds = 1200)
                cache.set("airly_pm10_in_cache", str(float(airly_pm10_value)), ttl_seconds = 1200)

            else:
                # If there is an error with the Airly API, the appropriate information is returned to the user.

                status_code = response_measurements.status_code
                # fail("Airly API request failed with status %d" % response_measurements.status_code)

    if status_code == 200:
        render_list = render_pm25_pm10_data(
            airly_street_value,
            airly_city_value,
            airly_pm25_value,
            airly_pm10_value,
        )
    else:
        render_list = render_api_error_code(status_code)

    return render.Root(
        child = render.Box(
            color = BACKGROUND_COLOR,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = render_list,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "airly_id",
                name = "Airly Station ID",
                desc = "Set the Airly Station ID",
                icon = "satelliteDish",
                default = "",
            ),
            schema.Text(
                id = "api_key",
                name = "Airly ApiKey",
                desc = "Set the Airly ApiKey",
                icon = "gear",
                default = "",
            ),
        ],
    )

def get_only_pm25_and_pm10_from_response_data(response_data):
    # Because not every measuring station measures PM2.5 and/or PM10 dust pollution.
    # We unpack the measurement data and assign values to the variables.
    # If there are no PM2.5 and/or PM10 measurements, leave the value 0.0.
    pm25 = 0.0
    pm10 = 0.0
    for data in response_data:
        if "name" in data:
            if data["name"] == "PM25":
                pm25 = data["value"]
            if data["name"] == "PM10":
                pm10 = data["value"]
    return pm25, pm10

def render_pm25_pm10_data(street, city, pm25, pm10):
    # Because not every measuring station measures PM2.5 and/or PM10 dust pollution.
    # Only those variables that are different from 0.0 are displayed.
    # We assume that if the value is 0.0, it means that the measuring station does not measure these values.
    # So we don't display these values at all.
    # If both values are 0.0, we display a message that both measurements are missing.
    if pm25 == 0.0 and pm10 == 0.0:
        return [
            render_installation_label(street, city),
            render.Marquee(
                width = 60,
                child = render.Text("No data PM2.5 and PM10 from the installation"),
            ),
        ]
    elif pm25 == 0.0:
        return [
            render_installation_label(street, city),
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Stack(render_graphic_of_degree_pollution(pm10, "pm10", 0.385)),
            ),
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("PM10: %s" % pm10),
            ),
        ]
    elif pm10 == 0.0:
        return [
            render_installation_label(street, city),
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Stack(render_graphic_of_degree_pollution(pm25, "pm25", 0.527)),
            ),
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("PM2.5: %s" % pm25),
            ),
        ]

    return [
        render_installation_label(street, city),
        render.Padding(
            pad = (2, 0, 2, 0),
            child = render.Stack(render_graphic_of_degree_pollution(pm25, "pm25", 0.527)),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Text("PM2.5: %s" % pm25),
        ),
        render.Padding(
            pad = (2, 0, 2, 0),
            child = render.Stack(render_graphic_of_degree_pollution(pm10, "pm10", 0.385)),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Text("PM10: %s" % pm10),
        ),
    ]

def render_installation_label(street, city):
    # Due to the limitation of 100 requests in free Airly API, it is necessary to count and display requests to Airly API.
    return render.Marquee(
        width = 60,
        child = render.Text("%s, %s | api limit %s/100" % (street, city, cache.get("airly_api_limit_counter_in_cache"))),
    )

def render_api_error_code(status_code):
    first_number_status = int(str(status_code)[0])
    return [
        render.Text("%s: %s" % (TYPE_FAIL[first_number_status], status_code if first_number_status != 9 else "")),
        render.Marquee(
            width = 60,
            child = render.Text("%s" % API_OR_USER_INPUT_FAIL[status_code]),
        ),
    ]

def render_graphic_of_degree_pollution(pm, pm_type, factor):
    # The factor is calculated based on the following rule:
    # 60 pixels bar and 3 pixels  pointer means thet max padding form letf 58 pixels is the length of the pollution indicator
    # Very bad pollition for PM2.5 is 110 and for PM10 is 150
    # 58 / 110 = 0.527 and 58 / 150 = 0.385

    # A PM2.5 value above 110 is considered very bad
    # There is no need to show the degree of pollution above this value
    # Information from: https://powietrze.gios.gov.pl/pjp/current
    if pm_type == "pm25":
        if pm > 110:
            pm = 110

        # A PM10 value above 150 is considered very bad
        # There is no need to show the degree of pollution above this value
        # Information from: https://powietrze.gios.gov.pl/pjp/current

    elif pm > 150:
        pm = 150

    # The pollution index is the offset from 0 to the multiplier pollution value and factor
    padding = int(pm * factor)
    return [
        render.Image(RANGE_DEGREE_POLLUTION),
        render.Padding(pad = (padding, 0, 0, 0), child = render.Box(width = 3, height = 4, color = "#fff")),
    ]

### CONSTANTS ###

AIRLY_INSTALLATIONS_API = "https://airapi.airly.eu/v2/installations/%s"
AIRLY_MEASUREMENTS_API = "https://airapi.airly.eu/v2/measurements/installation?installationId=%s"
TYPE_FAIL = {
    4: "Error",
    5: "Error",
    9: "Info",
}
API_OR_USER_INPUT_FAIL = {
    400: "Wrong input data format",
    401: "Wrong Airly ApiKey",
    404: "Installation with the ID does not exist",
    429: "Out of API request limit",
    500: "Airly server internal error",
    999: "Set the Airly ApiKey OR the Airly Station ID",
}

BACKGROUND_COLOR = "#000000"
RANGE_DEGREE_POLLUTION = base64.decode("iVBORw0KGgoAAAANSUhEUgAAADwAAAADCAYAAADP0GwKAAAAAXNSR0IArs4c6QAAAIlJREFUKFONkkEOhSAMRB873an3P6cmKvB/DTWVFHHRdCgk8GYIQyTPCeZoSted+RiBE5CuZdee1lkCtHLR2nvzA9iAtXSr7cw5E8ZEvmEd0CnC0jBgkIcpQA/UM8QCtrTcURuyO6AC9wE8PBJuJSrp272ir4TrlFuJ14b0En4zQBP+APj4Bf/zP6qytwzi8k5DAAAAAElFTkSuQmCC")

"""
Applet: Tempest
Summary: Display your Tempest Weather data
Description: Overview of your Tempest Weather Station, including current temperature, wind chill, pressure, inches of rain, and wind.
Author: epifinygirl
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("resources.star", "resources")
load("schema.star", "schema")
load("secret.star", "secret")

TEMPEST_AUTH_URL = "https://tempestwx.com/authorize.html"

TEMPEST_TOKEN_URL = "https://swd.weatherflow.com/id/oauth2/token"

TEMPEST_STATIONS_URL = "https://swd.weatherflow.com/swd/rest/stations"

TEMPEST_FORECAST_URL = "https://swd.weatherflow.com/swd/rest/better_forecast"

TEMPEST_OBSERVATION_URL = "https://swd.weatherflow.com/swd/rest/observations/station/%s"

OAUTH2_CLIENT_ID = "00d42e54-d040-41a4-af2d-4f65a2c96677"

OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEXmuOs+qlF9GRBt2Mo2XlyWad3xoYBpdZpIFvU0NItqFMtL83qhNRj49UglHKb40yCGgnb3HDcgoteQ0UlzTHyOmCUOwpTLmesoiZh17Fc6H45r4hRP5QpaWyXY/6E6f+zeMAkXjMVU1FDGRVrOPJ0cN56uIWjn6dyrhV51ny8Yn1jjm0")

def main(config):
    if not "station" in config or not "auth" in config:
        station_res = json.decode(resources.sample_station_response)
        forecast_res = json.decode(resources.sample_forecast_response)
        units = station_res["station_units"]
    else:
        # ensure we have the station ID in the correct format
        station_id = config["station"]
        if "." in station_id:
            station_id = station_id.split(".")[0]

        res = http.get(
            url = TEMPEST_OBSERVATION_URL % station_id,
            headers = {
                "Authorization": "Bearer %s" % config["auth"],
            },
        )
        if res.status_code != 200:
            fail("station observation request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        station_res = res.json()
        units = station_res["station_units"]

        res = http.get(
            url = TEMPEST_FORECAST_URL,
            headers = {
                "Authorization": "Bearer %s" % config["auth"],
            },
            params = {
                "station_id": station_id,
                "units_temp": units["units_temp"],
                "units_wind": units["units_wind"],
                "units_distance": units["units_distance"],
                "units_pressure": units["units_pressure"],
                "units_precip": units["units_precip"],
            },
        )
        if res.status_code != 200:
            fail("forecast request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        forecast_res = res.json()

    # If we can't get an observation, we should just skip it in the rotation.
    if len(station_res["obs"]) == 0:
        return []
    feel_dew_choice = config.get("Feels_Dew", "1")
    conditions = forecast_res["current_conditions"]

    temp = "%d°" % conditions["air_temperature"]
    humidity = "%d%%" % conditions["relative_humidity"]
    wind = "%s %d %s" % (
        conditions["wind_direction_cardinal"],
        conditions["wind_avg"],
        units["units_wind"],
    )
    pressure = "%g" % conditions["sea_level_pressure"]
    rain = "%g" % conditions.get("precip_accum_local_day", 0.0)
    feels = "%d°" % conditions["feels_like"]
    dew_pt = "%d°" % conditions["dew_point"]
    pressure_trend = conditions["pressure_trend"]
    icon = resources.icons.get(conditions["icon"], resources.icons["cloudy"])
    if feel_dew_choice == "1":
        updated_temp = (feels)
    elif feel_dew_choice == "2":
        updated_temp = (dew_pt)
    else:
        updated_temp = (" ")

    if pressure_trend == "falling":
        pressure_icon = ("↓")

    elif pressure_trend == "rising":
        pressure_icon = ("↑")

    else:
        pressure_icon = ("→")
    rain_units = units["units_precip"]

    return render.Root(
        delay = 500,
        child = render.Box(
            padding = 1,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render.Column(
                                cross_align = "start",
                                children = [
                                    render.Text(
                                        content = temp,
                                        color = "#2a2",
                                    ),
                                    render.Text(
                                        content = updated_temp,
                                        color = "#FFFF00",
                                    ),
                                    render.Image(icon),
                                    render.Box(width = 2, height = 1),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = humidity,
                                        color = "#66f",
                                    ),
                                    render.Text(
                                        content = rain + " " + rain_units,
                                        color = "#808080",
                                    ),
                                    render.Text(
                                        content = pressure + " " + pressure_icon,
                                    ),
                                    render.Text(
                                        content = wind,
                                        font = "CG-pixel-3x5-mono",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Feels Like",
            value = "1",
        ),
        schema.Option(
            display = "Dew Point",
            value = "2",
        ),
        schema.Option(
            display = "None",
            value = "3",
        ),
    ]
    return [
        {
            "id": "auth",
            "name": "Tempest",
            "description": "Connect your Tempest weather station",
            "icon": "cloud",
            "type": "oauth2",
            "handler": "oauth_handler",
            "client_id": OAUTH2_CLIENT_ID,
            "authorization_endpoint": TEMPEST_AUTH_URL,
            "scopes": ["user"],
        },
        {
            "id": "station",
            "type": "generated",
            "source": "auth",
            "handler": "get_stations",
            "visibility": {
                "type": "invisible",
                "condition": "not_equal",
                "variable": "auth",
                "value": "",
            },
        },
        {
            "id": "Feels_Dew",
            "name": "Feels Like or Dew Point Temperature",
            "type": "dropdown",
            "options": options,
            "default": "1",
        },
    ]

def get_stations(auth):
    if not auth:
        return []

    res = http.get(
        url = TEMPEST_STATIONS_URL,
        headers = {
            "Authorization": "Bearer %s" % auth,
        },
    )
    if res.status_code != 200:
        fail("stations request failed with status code: %d" % res.status_code)

    options = [
        {
            "value": str(int(station["station_id"])),
            "text": station["name"],
        }
        for station in res.json()["stations"]
    ]

    return [
        {
            "id": "station",
            "name": "Station",
            "icon": "temperatureHigh",
            "description": "Tempest weather station",
            "type": "dropdown",
            "options": options,
            "default": options[0]["value"],
        },
    ]

def oauth_handler(params):
    # deserialize oauth2 parameters
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = TEMPEST_TOKEN_URL,
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

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

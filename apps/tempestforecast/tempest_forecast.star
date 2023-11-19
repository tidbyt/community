"""
Applet: Tempest Forecast
Summary: Tempest Weather Forecast
Description: Get your Tempest weather station forecast displayed on your Tidbyt.
Author: mloftis
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", h = "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

TEMPEST_AUTH_URL = "https://tempestwx.com/authorize.html"

TEMPEST_TOKEN_URL = "https://swd.weatherflow.com/id/oauth2/token"

TEMPEST_STATIONS_URL = "https://swd.weatherflow.com/swd/rest/stations"

TEMPEST_FORECAST_URL = "https://swd.weatherflow.com/swd/rest/better_forecast"

TEMPEST_OBSERVATION_URL = "https://swd.weatherflow.com/swd/rest/observations/station/%s"

OAUTH2_CLIENT_ID = "287da6e5-a1d8-419f-9656-ef1151b6697f"

OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcE667ErcVw6c9Ewyk9gfVGhtjc7287cebg2CWGTc2xCS7I8aHUc5K54uFMOPn8GR2YoKTW0gTAZxSl4H6NeEVXgzjiSsFIRpcyNflBM/UmD/b2C2yTuuqHVW/9gCDOoCHYCYM+/YsrymP/RJ7OUQrdttuIhZPf1vF9siVY2wnrnneOID7W")

def main(config):
    temp_units = config.get("temperatureUnits", "F")
    if not "station" in config or not "auth" in config:
        station_res = json.decode(SAMPLE_STATION_RESPONSE)
        forecast_res = json.decode(SAMPLE_FORECAST_RESPONSE)
        units = station_res["station_units"]
    else:
        # ensure we have the station ID in the correct format
        station_id = config["station"]
        if "." in station_id:
            station_id = station_id.split(".")[0]

        # poll observation so that we can localize the units
        res = http.get(
            url = TEMPEST_OBSERVATION_URL % station_id,
            headers = {
                "Authorization": "Bearer %s" % config["auth"],
            },
            ttl_seconds = 3600,
        )
        if res.status_code != 200:
            fail("Tempest forecast station observation request failed with status code: %d - %s" %
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
            ttl_seconds = 3600,
        )
        if res.status_code != 200:
            fail("Tempest forecast request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        forecast_res = res.json()

    # If we can't get an observation, we should just skip it in the rotation.
    if len(station_res["obs"]) == 0:
        return []

    # assemble the days forecasts for render
    # tempest returns a number of days, plus hourlies, when we poll the forecast
    # tidbyt has room for three days and tempest appears to give us

    # shortcut to the forecast data
    dailies = forecast_res["forecast"]["daily"]

    disp = []
    station_units = units["units_temp"].upper()

    disp.append(get_render_for_fx(dailies[0], temp_units, station_units))
    disp.append(get_render_for_fx(dailies[1], temp_units, station_units))
    disp.append(get_render_for_fx(dailies[2], temp_units, station_units))

    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = disp[0],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Column(
                    children = [render.Box(width = 1, height = 32, color = "#5A5A5A")],
                ),
                render.Column(
                    children = disp[1],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Column(
                    children = [render.Box(width = 1, height = 32, color = "#5A5A5A")],
                ),
                render.Column(
                    children = disp[2],
                    main_align = "center",
                    cross_align = "center",
                ),
            ],
            main_align = "space_evenly",
            expanded = True,
        ),
    )

def get_schema():
    unitTempOptions = [
        schema.Option(
            display = "Fahrenheit",
            value = "F",
        ),
        schema.Option(
            display = "Celsius",
            value = "C",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Tempest",
                icon = "cloud",
                desc = "Connect your Tempest weather station",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID,
                authorization_endpoint = TEMPEST_AUTH_URL,
                scopes = ["user"],
            ),
            schema.Generated(
                id = "station",
                source = "auth",
                handler = get_stations,
                #          visibility = {
                #              "type": "invisible",
                #              "condition": "not_equal",
                #              "variable": "auth",
                #              "value": "",
                #          }
            ),
            schema.Dropdown(
                id = "temperatureUnits",
                name = "Temperature units",
                desc = "Units for temperature display",
                icon = "gear",
                default = unitTempOptions[0].value,
                options = unitTempOptions,
            ),
        ],
    )

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
        schema.Option(
            value = str(int(station["station_id"])),
            display = station["name"],
        )
        for station in res.json()["stations"]
    ]

    return [
        schema.Dropdown(
            id = "station",
            name = "Station",
            icon = "temperatureHigh",
            desc = "Tempest weather station",
            options = options,
            default = options[0].value,
        ),
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

def get_dow(unixtime):
    return h.time_format("EEE", time.from_timestamp(int(unixtime))).upper()

def translate_icon(tempest_icon):
    return base64.decode(ICON_MAP.get(tempest_icon, ICON_MAP["cloudy"]))

def convert_temp_units(temp, desired_unit, native_unit):
    if native_unit == "F" and desired_unit == "C":
        return int(math.round((temp - 32) * (5 / 9)))
    return int(math.round((temp * (9 / 5)) + 32))

def get_render_for_fx(daily, desired_unit, native_unit):
    if desired_unit == native_unit:
        temp_high = daily["air_temp_high"]
        temp_low = daily["air_temp_low"]
    else:
        temp_high = convert_temp_units(daily["air_temp_high"], desired_unit, native_unit)
        temp_low = convert_temp_units(daily["air_temp_low"], desired_unit, native_unit)
    return [
        render.Image(translate_icon(daily["icon"])),
        render.Box(height = 1, width = 1),
        render.Text(
            content = get_dow(daily["day_start_local"]),
            font = "CG-pixel-3x5-mono",
            color = "#ffffff",
        ),
        render.Box(height = 1, width = 1),
        render.Text(
            content = "%d°" % temp_high,
            font = "tom-thumb",
            color = "#FA8072",
        ),
        render.Text(
            content = "%d°" % temp_low,
            font = "tom-thumb",
            color = "#0096FF",
        ),
    ]

SAMPLE_STATION_RESPONSE = """{
  "station_id": 45032,
  "station_name": "Nostrand",
  "public_name": "Nostrand Ave.",
  "latitude": 40.68961,
  "longitude": -73.95118,
  "timezone": "America/New_York",
  "elevation": 35.05200043320656,
  "is_public": true,
  "status": {
    "status_code": 0,
    "status_message": "SUCCESS"
  },
  "station_units": {
    "units_temp": "c",
    "units_wind": "mph",
    "units_precip": "mm",
    "units_pressure": "inhg",
    "units_distance": "mi",
    "units_direction": "cardinal",
    "units_other": "imperial"
  },
  "outdoor_keys": [
    "timestamp",
    "air_temperature",
    "barometric_pressure",
    "station_pressure",
    "pressure_trend",
    "sea_level_pressure",
    "relative_humidity",
    "precip",
    "precip_accum_last_1hr",
    "precip_accum_local_day",
    "precip_accum_local_yesterday_final",
    "precip_minutes_local_day",
    "precip_minutes_local_yesterday_final",
    "wind_avg",
    "wind_direction",
    "wind_gust",
    "wind_lull",
    "solar_radiation",
    "uv",
    "brightness",
    "lightning_strike_count",
    "lightning_strike_count_last_1hr",
    "lightning_strike_count_last_3hr",
    "feels_like",
    "heat_index",
    "wind_chill",
    "dew_point",
    "wet_bulb_temperature",
    "delta_t",
    "air_density"
  ],
  "obs": [
    {
      "timestamp": 1616948722,
      "air_temperature": 11.9,
      "barometric_pressure": 1003.3,
      "station_pressure": 1003.3,
      "sea_level_pressure": 1011.7,
      "relative_humidity": 96,
      "precip": 0,
      "precip_accum_last_1hr": 2.748656,
      "precip_accum_local_day": 7.41777,
      "precip_accum_local_yesterday": 0.752003,
      "precip_accum_local_yesterday_final": 0,
      "precip_minutes_local_day": 148,
      "precip_minutes_local_yesterday": 10,
      "precip_minutes_local_yesterday_final": 0,
      "precip_analysis_type_yesterday": 1,
      "wind_avg": 2,
      "wind_direction": 218,
      "wind_gust": 4,
      "wind_lull": 0.8,
      "solar_radiation": 44,
      "uv": 0.35,
      "brightness": 5326,
      "lightning_strike_count": 0,
      "lightning_strike_count_last_1hr": 0,
      "lightning_strike_count_last_3hr": 0,
      "feels_like": 11.9,
      "heat_index": 11.9,
      "wind_chill": 11.9,
      "dew_point": 11.3,
      "wet_bulb_temperature": 11.5,
      "delta_t": 0.4,
      "air_density": 1.22614,
      "pressure_trend": "falling"
    }
  ]
}"""

SAMPLE_FORECAST_RESPONSE = """{
  "latitude": 40.68961,
  "longitude": -73.95118,
  "timezone": "America/New_York",
  "timezone_offset_minutes": -240,
  "current_conditions": {
    "time": 1616953518,
    "conditions": "Clear",
    "icon": "clear-day",
    "air_temperature": 12,
    "sea_level_pressure": 29.763,
    "station_pressure": 29.515,
    "pressure_trend": "falling",
    "relative_humidity": 97,
    "wind_avg": 2,
    "wind_direction": 134,
    "wind_direction_cardinal": "SSW",
    "wind_gust": 6,
    "solar_radiation": 152,
    "uv": 1,
    "brightness": 18230,
    "feels_like": 12,
    "dew_point": 9,
    "lightning_strike_count_last_1hr": 0,
    "lightning_strike_count_last_3hr": 0,
    "precip_accum_local_day": 7.42,
    "precip_accum_local_yesterday": 0,
    "is_precip_local_day_rain_check": false,
    "is_precip_local_yesterday_rain_check": true
  },
  "forecast": {
    "daily": [
      {
        "day_start_local": 1616904000,
        "day_num": 28,
        "month_num": 3,
        "conditions": "Rain Likely",
        "icon": "rainy",
        "sunrise": 1616928321,
        "sunset": 1616973413,
        "air_temp_high": 17,
        "air_temp_low": 9,
        "precip_probability": 80,
        "precip_icon": "chance-rain",
        "precip_type": "rain"
      },
      {
        "day_start_local": 1616990400,
        "day_num": 29,
        "month_num": 3,
        "conditions": "Clear",
        "icon": "clear-day",
        "sunrise": 1617014621,
        "sunset": 1617059876,
        "air_temp_high": 13,
        "air_temp_low": 7,
        "precip_probability": 10,
        "precip_icon": "chance-rain",
        "precip_type": "rain"
      },
      {
        "day_start_local": 1617076800,
        "day_num": 30,
        "month_num": 3,
        "conditions": "Clear",
        "icon": "clear-day",
        "sunrise": 1617100922,
        "sunset": 1617146340,
        "air_temp_high": 14,
        "air_temp_low": 5,
        "precip_probability": 10,
        "precip_icon": "chance-rain",
        "precip_type": "rain"
      },
      {
        "day_start_local": 1617163200,
        "day_num": 31,
        "month_num": 3,
        "conditions": "Rain Likely",
        "icon": "rainy",
        "sunrise": 1617187222,
        "sunset": 1617232803,
        "air_temp_high": 16,
        "air_temp_low": 10,
        "precip_probability": 70,
        "precip_icon": "chance-rain",
        "precip_type": "rain"
      }
    ],
    "hourly": [
      {
        "time": 1616954400,
        "conditions": "Cloudy",
        "icon": "cloudy",
        "air_temperature": 12,
        "sea_level_pressure": 29.62,
        "relative_humidity": 94,
        "precip": 0,
        "precip_probability": 15,
        "precip_type": "rain",
        "precip_icon": "chance-rain",
        "wind_avg": 11,
        "wind_direction": 180,
        "wind_direction_cardinal": "S",
        "wind_gust": 20,
        "uv": 1,
        "feels_like": 12,
        "local_hour": 14,
        "local_day": 28
      },
      {
        "time": 1616958000,
        "conditions": "Rain Possible",
        "icon": "possibly-rainy-day",
        "air_temperature": 13,
        "sea_level_pressure": 29.565,
        "relative_humidity": 90,
        "precip": 0,
        "precip_probability": 20,
        "precip_type": "rain",
        "precip_icon": "chance-rain",
        "wind_avg": 11,
        "wind_direction": 185,
        "wind_direction_cardinal": "S",
        "wind_gust": 22,
        "uv": 2,
        "feels_like": 12,
        "local_hour": 15,
        "local_day": 28
      },
      {
        "time": 1616961600,
        "conditions": "Rain Possible",
        "icon": "possibly-rainy-day",
        "air_temperature": 15,
        "sea_level_pressure": 29.508,
        "relative_humidity": 84,
        "precip": 0,
        "precip_probability": 20,
        "precip_type": "rain",
        "precip_icon": "chance-rain",
        "wind_avg": 11,
        "wind_direction": 186,
        "wind_direction_cardinal": "S",
        "wind_gust": 22,
        "uv": 1,
        "feels_like": 14,
        "local_hour": 16,
        "local_day": 28
      },
      {
        "time": 1616965200,
        "conditions": "Rain Possible",
        "icon": "possibly-rainy-day",
        "air_temperature": 16,
        "sea_level_pressure": 29.473,
        "relative_humidity": 76,
        "precip": 0,
        "precip_probability": 20,
        "precip_type": "rain",
        "precip_icon": "chance-rain",
        "wind_avg": 13,
        "wind_direction": 194,
        "wind_direction_cardinal": "SSW",
        "wind_gust": 25,
        "uv": 1,
        "feels_like": 15,
        "local_hour": 17,
        "local_day": 28
      },
      {
        "time": 1616968800,
        "conditions": "Rain Possible",
        "icon": "possibly-rainy-day",
        "air_temperature": 17,
        "sea_level_pressure": 29.446,
        "relative_humidity": 68,
        "precip": 0.37,
        "precip_probability": 35,
        "precip_type": "rain",
        "precip_icon": "chance-rain",
        "wind_avg": 13,
        "wind_direction": 207,
        "wind_direction_cardinal": "SSW",
        "wind_gust": 22,
        "uv": 0,
        "feels_like": 17,
        "local_hour": 18,
        "local_day": 28
      }
    ]
  },
  "status": {
    "status_code": 0,
    "status_message": "SUCCESS"
  },
  "units": {
    "units_temp": "c",
    "units_wind": "mph",
    "units_precip": "mm",
    "units_pressure": "inhg",
    "units_distance": "mi",
    "units_brightness": "lux",
    "units_solar_radiation": "w/m2",
    "units_other": "metric",
    "units_air_density": "kg/m3"
  }
}"""

# Home made weather icons
HOMEMADE_ICON = {
    "cloudy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBQ6OwZOIkIAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAR0lEQVQoz2NkYGD4z0AiYGIgA5CliQVd4P9/VNcyMjLitwldAy4xJnySOG2HiB
EfgIyMjBSEHjbP4rIF7jxC/kI3lHFwpwgAMj8ZD4TRieYAAAAASUVORK5CYII=
""",
    "foggy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUgGvvIovAAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAATUlEQVQoz82RwQoAIAhDN+n/f9kOYaBhWac8yUTfhgSguKwWBVV/g+SyJLuFTJ
PdMKUPrR6LpLdXLcnCZpRp75QrHuXLn8QIRqn0n5M6wZhK28s4z6IAAAAASUVORK5CYII=
""",
    "haily.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBYDJIZGdmMAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAUUlEQVQoz71Qyw7AMAgC//+f3WFJo2S0podxEx8gBJAoyGwlSEIRuwXHxa5p1V
/OLyhIdntThHvWqSx7p7/0KDXysb2qompf/FUQP9ubDNb6AdIGPedozn0cAAAAAElFTkSu
QmCC
""",
    "moony.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUeOG9t+GkAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAATElEQVQoz2NkYGD4z0AiYGIgA7BgE/z/2hrOZhQ9StgmZA3Y+Bg2EbIBwyZiNZ
AdEJRpQnYSNs8jA0b0yMWmAd2PTIQUYAsURrolIwA2fBgZWqCnTgAAAABJRU5ErkJggg==
""",
    "rainy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUfGE0Y6eAAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAWUlEQVQoz2NkYGD4z0AiYEEXmDdvHgo/KSkJQxMTPg24xJjwSeKSY2RgYPiPTw
M6SEpKQnUesYAJl2dx2QJ3HiF/oRvKSE48ofhJcdpnrDQ6oMwmYm0h2yYAi44iwUl4wOoA
AAAASUVORK5CYII=
""",
    "sleety.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBYAMlm/kPEAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAcElEQVQoz41R2w0AIQijbuLSLuoAvQ/FAAfeNTHR1vKEiFAMSPcUABLRboaKaz
exzL642hABwJf3F61qtspyyvvqKwvKPia3OT2Jvi57Gq9PlncmFeKHij+DIHlq194s38f0
e4qLjEHSkbsowWA1xQN97m3QB9ohLQAAAABJRU5ErkJggg==
""",
    "snowy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBYBILMd0PgAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAXUlEQVQoz42QQRLAMAgCl/z/z/TQaSaxxYZToqKAALPA3r5IomJ0hFQbXTNev2
uZUCFpl3eKkcymK1Pen6+6VDXyY3ndlRi5bSS9BlJ9ynsGunf0tG5PqX4G0REALvX0P/vf
jIHHAAAAAElFTkSuQmCC""",
    "sunny.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBQ5HxFglVAAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAYUlEQVQoz2NgYGD4jw3/f239H5ccEwMDA8P/19YMxABkdQRNRpdnhDJwmsgoeh
TDRiZ8GnA5nYmQAmziLDABbM7ApZmFGMXo/mPCJohLMc6AQFeAyyCS44kBlwYCYqSnPQAb
5W9EvIXnIQAAAABJRU5ErkJggg==""",
    "thundery.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUgBXbArwUAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAb0lEQVQoz5WR0Q2AIAxEX4krOI0zOIR1LnEIZ3Aah8APExOwRbg/enm5axEg0a
mhHMQYs7eqfqBQA7xZqJmeJ0CqAaVUNa/XquAt66W89cruy7wBsB+reUGx/ild02OOp1+v
BzCh5kP0pJhJfwDADQB/I6TUw0mFAAAAAElFTkSuQmCC""",
    "tornady.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBYDCcOZKhYAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAc0lEQVQoz5WQQQ6AIAwER+NH4WHbp9aDKVYUxU1IaOi0ExbAASQBUEqhj5m1e6
2V7Q3IzQEArLnom/KQ6GnQDBg2wKE3UowBeUvb9Ae46M0CEQdckudIckke7905i1lw5SMj
xeGWgdqz3gdw1zOz118D2AFBnJDiZ9h9RAAAAABJRU5ErkJggg==""",
    "windy.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBYAFfy1JZoAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAW0lEQVQoz52QUQrAMAhDk9L7Xzn72ARrFab9UmpMfAQgNN+qPiSVfSkieQz6nh
YvbrbBLAE7N0kCSWzvEiNdsT5nTujtjE7mOHaym/jWtS4S/EXPtvt6dQVjeg/Wq0ED7siM
GwAAAABJRU5ErkJggg==""",
    "moonyish.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUhKsQKox0AAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAbElEQVQoz52S7Q2AIAxE3xlG0Gl0fJ0Gd6g/hEQEFLikCR95ba+pAKNT7uvT/J
rctRwATK3A8821ArFKBpm97J1bBiTtZQDAvNf9/sqvFqZ8h/UowLJiX2VJuj3FQysAoLgR
tYKlpBpZo4kBXblzdDGgW8ZbAAAAAElFTkSuQmCC
""",
    "sunnyish.png": """
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAABhGlDQ1BJQ0MgcHJvZmlsZQ
AAKJF9kT1Iw0AcxV/TiiIVBTuIOGSoThZERR21CkWoEGqFVh1MLv2CJg1Jiouj4Fpw8GOx
6uDirKuDqyAIfoA4OTopukiJ/0sKLWI8OO7Hu3uPu3eAUC8zzQqNAZpum6lEXMxkV8XOVw
QRQgTT6JOZZcxJUhK+4+seAb7exXiW/7k/R4+asxgQEIlnmWHaxBvEU5u2wXmfOMKKskp8
Tjxq0gWJH7muePzGueCywDMjZjo1TxwhFgttrLQxK5oa8SRxVNV0yhcyHquctzhr5Spr3p
O/MJzTV5a5TnMICSxiCRJEKKiihDJsxGjVSbGQov24j3/Q9UvkUshVAiPHAirQILt+8D/4
3a2Vnxj3ksJxoOPFcT6Ggc5doFFznO9jx2mcAMFn4Epv+St1YOaT9FpLix4BvdvAxXVLU/
aAyx1g4MmQTdmVgjSFfB54P6NvygL9t0D3mtdbcx+nD0CaukreAAeHwEiBstd93t3V3tu/
Z5r9/QBe53KfIhP12QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGA
AAAAd0SU1FB+QDBBUhG5XUoycAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBX
gQ4XAAAAbUlEQVQoz52R0Q2AIAxEX4kj6DQ4vk6DO9QfSABbQZuQkJR3dy0Aah1NUb1eAN
AUman63VC570u+uIqynQ/HBlLt+Gs3weACAOuBNfPiAjWYHQss+kp0s4i08b5UKPSsS7M9
L6Ulav7TMN6fmW4ZiETQdYb80QAAAABJRU5ErkJggg==
""",
}

ICON_MAP = {
    "clear-day": HOMEMADE_ICON["sunny.png"],
    "clear-night": HOMEMADE_ICON["moony.png"],
    "cloudy": HOMEMADE_ICON["cloudy.png"],
    "foggy": HOMEMADE_ICON["foggy.png"],
    "partly-cloudy-day": HOMEMADE_ICON["sunnyish.png"],
    "partly-cloudy-night": HOMEMADE_ICON["moonyish.png"],
    "possibly-rainy-day": HOMEMADE_ICON["rainy.png"],
    "possibly-rainy-night": HOMEMADE_ICON["rainy.png"],
    "rainy": HOMEMADE_ICON["rainy.png"],
    "sleet": HOMEMADE_ICON["sleety.png"],
    "possibly-sleet-day": HOMEMADE_ICON["sleety.png"],
    "possibly-sleet-night": HOMEMADE_ICON["sleety.png"],
    "snow": HOMEMADE_ICON["snowy.png"],
    "possibly-snow-day": HOMEMADE_ICON["snowy.png"],
    "possibly-snow-night": HOMEMADE_ICON["snowy.png"],
    "thunderstorm": HOMEMADE_ICON["thundery.png"],
    "possibly-thunderstorm-day": HOMEMADE_ICON["thundery.png"],
    "possibly-thunderstorm-night": HOMEMADE_ICON["thundery.png"],
    "windy": HOMEMADE_ICON["windy.png"],
}

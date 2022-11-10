"""
Applet: Netatmo
Summary: Weather from your Netatmo
Description: Get your current weather from your Netatmo weather station.
Author: danmcclain
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("http.star", "http")
load("secret.star", "secret")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

DOWN_DEG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAAC5JREFUGFdjZACBmcb/GdLPMoLZaAAhiKwIiY2qCyaBUwHMOhANtRLVCmT7oQoACOEVBpf67iYAAAAASUVORK5CYII=")
UP_DEG = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAAC5JREFUGFdjZICBmcb/4WwQI/0sI4gCEygAphCrApAkSAJGo5iAJIipAFkSzUYAQtIVBjuf38UAAAAASUVORK5CYII=")
UP_PRESS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAADBJREFUGFdjZICCmcYM/2FsEJ1+loERRIMJZABTiFUBSBIkAaNRTEAWxFCALIBuJQBQ0hUGX0wZ5wAAAABJRU5ErkJggg==")
DOWN_PRESS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAAXNSR0IArs4c6QAAADFJREFUGFdjZGBgYJhpzPA//SwDI4iNDuCCyIqQ2Si6YBI4FcCsA9EwK1GsQLYfpgAAFuEVBt9EUIYAAAAASUVORK5CYII=")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEY+xlza5nc6Vx3IhSZOD+MGdeVROlRBYrpIwypN5EIIncp7hyCiIQMGVnPS0Q1SlVfHZXB92095MTfHew3wzuEJ14ihbjpxbZNQJhuYA+4O3fR4GFjOTy98EfJobFvxLguAtnNE149hITsJeIxyKfnI2yHZFVgg2Y2pYHoHzSqA==")
CLIENT_ID = "622106585db6d223df25fdf8"

def main(config):
    refresh_token = config.get("auth")
    fahrenheit = config.bool("fahrenheit")

    if refresh_token:
        access_token = cache.get(refresh_token)

        if access_token == None:
            access_token = get_access_token(refresh_token)

        res = http.get(
            url = "https://api.netatmo.com/api/getstationsdata",
            headers = {
                "Accept": "application/json",
                "Authorization": "Bearer %s" % access_token,
            },
        )

        if res.status_code != 200:
            fail("bad request for station infomation: %s %s" %
                 (res.status_code, res.body()))

        body = res.json()
    else:
        body = json.decode(EXAMPLE_DATA)

    indoor_module = body["body"]["devices"][0]
    outdoor_module = select_outdoor_module(indoor_module["modules"])

    rows = [render.Box(height = 3)]
    rows.append(temp_and_humid_row(indoor_module, "In  ", fahrenheit))
    if outdoor_module != None:
        rows.append(temp_and_humid_row(outdoor_module, "Out ", fahrenheit))

    rows.append(render.Box(height = 3))
    pressure = indoor_module["dashboard_data"]["Pressure"]
    press_trend = render.Text("", font = "tom-thumb")
    if "pressure_trend" in indoor_module["dashboard_data"]:
        pressure_trend = indoor_module["dashboard_data"]["pressure_trend"]
        if pressure_trend == "up":
            press_trend = render.Image(src = UP_PRESS)
        if pressure_trend == "down":
            press_trend = render.Image(src = DOWN_PRESS)

    rows.append(render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text("%d.1mbar" % (pressure), font = "tom-thumb", color = "#930"),
                press_trend,
            ],
        ),
    ))

    co2 = indoor_module["dashboard_data"]["CO2"]
    noise = indoor_module["dashboard_data"]["Noise"]
    rows.append(render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text("%dppm  " % (co2), font = "tom-thumb", color = "#ffc107"),
                render.Text("%ddB" % (noise), font = "tom-thumb"),
            ],
        ),
    ))
    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

def select_outdoor_module(modules):
    for m in modules:
        if "data_type" in m and "type" in m:
            if m["data_type"] == ["Temperature", "Humidity"] and m["type"] == "NAModule1":
                return m
    return None

def temp_and_humid_row(module, name, fahrenheit):
    dash = module["dashboard_data"]
    temp = dash["Temperature"]

    if fahrenheit:
        temp = temp * 1.8 + 32

    humid = dash["Humidity"]

    temp_trend = render.Text("  ", font = "tom-thumb")

    if "temp_trend" in dash:
        trend = dash["temp_trend"]
        if trend == "up":
            temp_trend = render.Image(src = UP_DEG)
        if trend == "down":
            temp_trend = render.Image(src = DOWN_DEG)

    return render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text(name, font = "tom-thumb"),
                render.Text("%d°" % (temp), font = "tom-thumb", color = "#093"),
                temp_trend,
                render.Text("%d%%" % humid, font = "tom-thumb", color = "#039"),
            ],
        ),
    )

def oauth_handler(params):
    # deserialize oauth2 parameters, see example aboce.
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://api.netatmo.com/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
            scope = "read_station",
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    cache.set(refresh_token, token_params["access_token"], ttl_seconds = int(token_params["expires_in"] - 30))

    return refresh_token

def get_access_token(refresh_token):
    res = http.post(
        url = "https://api.netatmo.com/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            refresh_token = refresh_token,
            client_secret = OAUTH2_CLIENT_SECRET,
            grant_type = "refresh_token",
            client_id = CLIENT_ID,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                icon = "cloud",
                name = "Netatmo",
                desc = "Connect your Netatmo account.",
                handler = oauth_handler,
                client_id = CLIENT_ID,
                authorization_endpoint = "https://api.netatmo.com/oauth2/authorize",
                scopes = [
                    "read_station",
                ],
            ),
            schema.Toggle(
                id = "fahrenheit",
                icon = "temperatureHigh",
                name = "Fahrenheit",
                desc = "Display temperatures in fahrenheit",
            ),
        ],
    )

EXAMPLE_DATA = """{
  "body": {
    "devices": [
      {
        "_id": "70:ee:50:22:aa:00",
        "date_setup": 1435834348,
        "last_setup": 1435834348,
        "type": "NAMain",
        "last_status_store": 1555677748,
        "module_name": "Indoor",
        "firmware": 137,
        "last_upgrade": 1512405614,
        "wifi_status": 55,
        "reachable": true,
        "co2_calibrating": false,
        "station_name": "Casa",
        "data_type": [
          "string"
        ],
        "place": {
          "timezone": "Africa/Lagos",
          "country": "EG",
          "altitude": 144,
          "location": [
            "30.89600807058707, 29.94281464724796"
          ]
        },
        "read_only": true,
        "home_id": "594xxxxxxxxxdb",
        "home_name": "Home",
        "dashboard_data": {
          "time_utc": 1555677739,
          "Temperature": 23.7,
          "CO2": 967,
          "Humidity": 41,
          "Noise": 42,
          "Pressure": 997.6,
          "AbsolutePressure": 1017.4,
          "min_temp": 21.2,
          "max_temp": 27.4,
          "date_min_temp": 1555631374,
          "date_max_temp": 1555662436,
          "temp_trend": "up",
          "pressure_trend": "up"
        },
        "modules": [
          {
            "oneOf": [
              {
                "_id": "06:00:00:02:47:00",
                "type": "NAModule4",
                "module_name": "Indoor Module",
                "data_type": [
                  "Temperature, Humidity, CO2"
                ],
                "last_setup": 1435834348,
                "reachable": true,
                "dashboard_data": {
                  "time_utc": 1555677739,
                  "Temperature": 23.7,
                  "CO2": 967,
                  "Humidity": 41,
                  "Pressure": 997.6,
                  "AbsolutePressure": 1017.4,
                  "min_temp": 21.2,
                  "max_temp": 27.4,
                  "date_min_temp": 1555631374,
                  "date_max_temp": 1555662436,
                  "temp_trend": "up"
                },
                "firmware": 19,
                "last_message": 1555677746,
                "last_seen": 1555677746,
                "rf_status": 31,
                "battery_vp": 5148,
                "battery_percent": 58
              }
            ]
          }
        ]
      }
    ],
    "user": {
      "mail": "name@mail.com",
      "administrative": {
        "reg_locale": "fr-FR",
        "lang": "fr-FR",
        "country": "FR",
        "unit": 0,
        "windunit": 0,
        "pressureunit": 0,
        "feel_like_algo": 0
      }
    }
  },
  "status": "ok",
  "time_exec": "0.060059070587158",
  "time_server": "1553777827"
}"""

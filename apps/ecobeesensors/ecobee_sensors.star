"""
Applet: Ecobee Sensors
Summary: Display temps from Ecobee
Description: Display the temperatures of Ecobee sensors.
Author: Vestride
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

ECOBEE_API_KEY = secret.decrypt("AV6+xWcE3IBa5g9mNW54HUUeNk8/XgFwE3BQXp2ZJHw4QCn8VHjJVV/4eBh55KV5M0WxARG258cgiFk4nBjSFCVRn3fmXvfagzI4567Dy/OcR97liQmsqA0u60IKuTDp9AVlcrrz5bjc6gJunO8HQnxir1x5YUFZPHAmszS0T6k639/QwYI=")
ECOBEE_REDIRECT_URL = "https://appauth.tidbyt.com/ecobeesensors"

PERSON_SOLID = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAADZJREFUKFNjZEAC/////w/iMjIyMsKE4QyYJFwCqoh4BSCdeK1Adgsymzgr0B2I7FCwCfgUAABezRwJnjKS2AAAAABJRU5ErkJggg==")
PERSON_OUTLINE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAD5JREFUKFONT0EKADAImv9/tOGYYTDGOplKGlYMSWoFANMNJFpI/G/QyWdEdkk8IoZwim5DlrLJXBtuEfqqAP2nKAmyzszhAAAAAElFTkSuQmCC")
ECOBEE_CIRCLE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAACXBIWXMAAA7DAAAOwwHHb6hkAAAE/klEQVR4nMVXXWxUVRC+1CAFFWn3LPUnpkUfxRjEqP3dtnvPOXd3W0qtD0KgIEWj1NYWfdCo6QNifNAHE9+BxhoIb1gatATiQ41Qq0/2SRESSpuI9r8r6e6O+ebe3d7dvbtshegkc3Nzzsw3c86ZMzPHMDKJaI3R11dk/xtrSrR+0q9Ul9DyhF/LUZ82J4Uy/xZaJoSW5HACYz5tTkFGWLJfaNldFpFbGQ8EzOR/TiIWABeVWrJVSPOCUOYtfyRE/qYw+UOahKWSRrPZUizDspEQCSVvCS0vAAuYjJ3TiT571ZvCDeU+Jc/6wxb5w5a9SmXGhTJjzqrdK89kzNmytjxjAAuYwHbbyjIugsFtQqurWIEDEs9jrDB2nGdMra7CRqYTRfiUaV0hLH0F3ia9d/NmS1EZ5rSkEhmkTWZjGmMMc5CBrIcjMca29JUyHahw22YSIXXG9lIuuxX9lmLA++rraG11JfmUSY/taKLHX9yZxhjDHGQgCx1/tiPLbCOkzhhu8ivV5qw8bcsBgtUB0Hyzkz4d+JIujv1I1yanaHZhgRajUWb8X5ucpItjY/TZVwNkdnWyDnSzdkOZcY4vpdpSDghLDdtRu7L1UNzYWE8VrS008M05Wo7FKEmxeJzmFhfpz9lZZvxjLEmQhQ50gZHmBI4Ctiw1zMZxz4Wloq4o5q2D91taW2h0/BcGnV9aouNnB+nlD96n7fv28rbDABj/GMPcscGvWRY0Oj7OGMByHYd9iywVhW3DF9Kd2avXtCFQR/1DZxno9xs3yHqrm9bWVFFxXQ1tDNZTCQeew2YjjxXXVXMM6J5u1gEBA1jAzNwF2DaEVsfdDmwOaT6/+jde560Eh3t76J7K5+mhSIjKkIxyXDnMPRwJsWykt4dicVsfWByYK7rL9jGYxwxhyUuc4ZwAxDXCKj7pP8ErODn8La2rrU5dwUIYstCBLghYwExhIBA5q8pL2IEJJ72mMhy29PzoZVbuOPoR3VtTtWoHoANdELCAmZYxbZsThtAyGYAcKKUySI80hVNnWPVqB597qUfyycWQhQ50kzEETIxn5IYlw71yTMLT8pZmmlmY5/N7oeMAJ5kn2lqzkk8uhix0oAsMYAET2BkOJIzMrJe8fvOLi+x9Mtn8WwYhT3hcR2bjdg78NTeXSjir5ZszM3RzdpZ+m5ig8p07vHaA8hzBAm/fcwf206PNEdriSjyrZRj3qAupI4jmC8Lq1w7S+kAN+VRwJfEUyMBCgSpVdqX04CU4kPcaHvz46KqvYXIx9zcEqLi2mh4MNmQF38o1tPInolPnh+1ElCcDevUOMBrsPESvHDlC2/e1pzuRSkTqB0NoM28qRpWLHO6logJSMXQhs66mira176XpuTleRPM7h2lDoNY7FfsKLUY9KEaVXHC8i1EDxwp279n97VwJQUMjIzyXdgTuYlSSpxwjgi875XjBKce7PkQ5bs8qx8+076GX3nuXvjh9mv6YnmadX69fp6f37KYH0nuC9HJ81xoS13wikaCh70foqd27MqtgdkNSeEt2yGnJxrj9ymrJpqbou59/os9PnaSmt3vZeWx9QS3Z3WpKIY8ruz5Qy3qFNqVF+KBVvpO2HElHKNNuy71uSt62vO//fZh4Pc0G/9unmeHQnTxOLa/HqbmKx6nbids9z+0Clv481zKKOX6eK9nvt1RXiZRbU1g5nuf/AMNGGC9QybltAAAAAElFTkSuQmCC")

TIDBYT_APP_DURATION = 15000  # 15s

DEBUG = True

def main(config):
    refresh_token = config.get("auth")

    if not refresh_token:
        if DEBUG:
            print("no refresh token, using example data")
        result = json.decode(EXAMPLE_DATA)
    else:
        access_token = cache.get(refresh_token)

        if not access_token:
            access_token = get_access_token(refresh_token)

        result = get_thermostats_response(access_token)

    sensors = parse_thermostats_data(result)

    if DEBUG:
        print("parsed sensor data:", sensors)

    return render_display(sensors)

def get_thermostats_response(access_token):
    ecobee_request_params = json.encode({
        "selection": {
            "selectionType": "registered",
            "selectionMatch": "",
            "includeSensors": "true",
        },
    })

    # https://www.ecobee.com/home/developer/api/documentation/v1/operations/get-thermostats.shtml
    response = http.get(
        "https://api.ecobee.com/1/thermostat?json={}".format(ecobee_request_params),
        ttl_seconds = 3 * 60,
        headers = {
            "Authorization": "Bearer " + access_token,
        },
    )

    result = response.json()

    if response.status_code != 200:
        fail("Ecobee api request failed with status %d", response.status_code, result)

    return result

# Make sure that each sensor can be shown in the duration this app is visible.
def get_animation_delay(num_sensors):
    result = TIDBYT_APP_DURATION / num_sensors
    if (result > 2000):
        return 2000
    return result

def render_display(sensors):
    components = []
    for sensor in sensors:
        components.append(render_sensor(sensor))

    return render.Root(
        delay = get_animation_delay(len(sensors)),
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 2, height = 1),  # 2px left-padding
                        render.Image(src = ECOBEE_CIRCLE, width = 12, height = 12),
                        render.Box(width = 1, height = 1),  # 1px between circle and sensors
                        render.Animation(children = components),
                    ],
                    cross_align = "center",
                ),
            ],
            # expand the column to fill the screen so that the content can be centered
            expanded = True,
            main_align = "center",
        ),
    )

# Modify the size of the sensor name text based on the length of the name.
# tb-8 height = 8
# tom-thumb height = 6
# CG-pixel-3x5-mono height = 5
def render_sensor_name(name_text):
    nodes = []

    if len(name_text) < 11:
        nodes.append(render.Text(content = name_text, font = "tb-8"))
    elif len(name_text) < 13:
        nodes.append(render.Box(width = 4, height = 2))
        nodes.append(render.Text(content = name_text, font = "tom-thumb"))
    elif len(name_text) < 14:
        nodes.append(render.Box(width = 4, height = 3))
        nodes.append(render.Text(content = name_text, font = "CG-pixel-3x5-mono"))
    else:
        nodes.append(render.Box(width = 4, height = 3))
        name_text = name_text[0:11] + "_"
        nodes.append(render.Text(content = name_text, font = "CG-pixel-3x5-mono"))

    return render.Column(children = nodes, main_align = "end")

def get_temperature_display_text(sensor_value):
    string_value = str(float(sensor_value) / 10)
    degreesF = string_value + "°"
    return degreesF

def render_sensor(sensor):
    temperature_text = get_temperature_display_text(sensor["temperature"])

    # Offset the temperature display by one because no numbers have descenders.
    temperature = render.Text(temperature_text, offset = -1)
    icon = render.Image(src = PERSON_SOLID, width = 8, height = 8) if sensor["occupancy"] == "true" else render.Image(src = PERSON_OUTLINE, width = 8, height = 8)

    return render.Column(
        children = [
            render_sensor_name(sensor["name"]),
            render.Box(width = 2, height = 1),
            render.Row(
                children = [
                    temperature,
                    render.Box(width = 1, height = 2),
                    icon,
                ],
                cross_align = "center",
            ),
        ],
    )

# Find all the thermostats and temperature sensors, collecting their name,
# occupancy, and temperature.
def parse_thermostats_data(api_response):
    data = []

    for thermostat in api_response.get("thermostatList", []):
        sensors = thermostat.get("remoteSensors", [])

        for sensor in sensors:
            id = sensor.get("id")
            name = sensor.get("name")
            occupancy = None
            temperature = None

            for capability in sensor.get("capability", []):
                if capability.get("type") == "occupancy":
                    occupancy = capability.get("value")
                elif capability.get("type") == "temperature":
                    temperature = capability.get("value")

            data.append({
                "id": id,
                "name": name,
                "occupancy": occupancy,
                "temperature": temperature,
            })

    return data

# Store the refresh token as the "auth" field in the config and the access token
# in the cache. The access token is stored with the refresh token as the key.
def oauth_handler(params):
    params = json.decode(params)
    authorization_code = params.get("code")

    return get_refresh_token(authorization_code)

# https://www.ecobee.com/home/developer/api/documentation/v1/auth/authz-code-authorization.shtml
def get_refresh_token(authorization_code):
    if DEBUG:
        print("getting refresh token with auth code:", authorization_code)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://api.ecobee.com/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            grant_type = "authorization_code",
            code = authorization_code,
            redirect_uri = ECOBEE_REDIRECT_URL,
            client_id = ECOBEE_API_KEY,
            ecobee_type = "jwt",
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    # A successful response will look like this:
    # {
    #     "access_token": "Rc7JE8P7XUgSCPogLOx2aLMfITqQQrjg",
    #     "token_type": "Bearer",
    #     "expires_in": 3599,
    #     "refresh_token": "og2Obost3ucRo1ofo1EDoslGltmFMe2g",
    #     "scope": "smartRead"
    # }

    token_params = res.json()

    # Access token lasts 60 minutes.
    access_token = token_params["access_token"]

    # Refresh token lasts 1 year.
    refresh_token = token_params["refresh_token"]

    # When the access token will expire, in seconds.
    expires_in_seconds = int(token_params["expires_in"])

    # Store the access token in the cache so that it can be retrieved with the refresh token.
    cache.set(refresh_token, access_token, ttl_seconds = expires_in_seconds - 30)

    return refresh_token

# https://www.ecobee.com/home/developer/api/documentation/v1/auth/token-refresh.shtml
def get_access_token(refresh_token):
    if DEBUG:
        print("getting access token with refresh token:", refresh_token)

    res = http.post(
        url = "https://api.ecobee.com/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            grant_type = "refresh_token",
            refresh_token = refresh_token,
            client_id = ECOBEE_API_KEY,
            ecobee_type = "jwt",
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    # Same API response shape as the original access token request.
    token_params = res.json()

    # Access token lasts 60 minutes.
    access_token = token_params["access_token"]

    # Refresh token lasts 1 year.
    refresh_token = token_params["refresh_token"]

    # When the access token will expire, in seconds.
    expires_in_seconds = int(token_params["expires_in"])

    # Store the access token in the cache so that it can be retrieved with the refresh token.
    cache.set(refresh_token, access_token, ttl_seconds = expires_in_seconds - 30)

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Ecobee",
                desc = "Connect your Ecobee account.",
                icon = "temperatureQuarter",
                handler = oauth_handler,
                client_id = str(ECOBEE_API_KEY),
                authorization_endpoint = "https://api.ecobee.com/authorize",
                scopes = [
                    "smartRead",
                ],
            ),
        ],
    )

EXAMPLE_DATA = """
{
  "thermostatList": [
    {
      "name": "Downstairs",
      "remoteSensors": [
        {
          "id": "ei:0",
          "name": "Downstairs",
          "capability": [
            {
              "id": "1",
              "type": "temperature",
              "value": "709"
            },
            {
              "id": "2",
              "type": "humidity",
              "value": "52"
            },
            {
              "id": "3",
              "type": "occupancy",
              "value": "true"
            },
            {
              "id": "4",
              "type": "airQualityAccuracy",
              "value": "unknown"
            },
            {
              "id": "5",
              "type": "airQuality",
              "value": "unknown"
            },
            {
              "id": "6",
              "type": "vocPPM",
              "value": "unknown"
            },
            {
              "id": "7",
              "type": "co2PPM",
              "value": "unknown"
            },
            {
              "id": "8",
              "type": "airPressure",
              "value": "unknown"
            }
          ]
        },
        {
          "id": "rs2:100",
          "name": "Home Office",
          "type": "ecobee3_remote_sensor",
          "capability": [
            {
              "id": "1",
              "type": "temperature",
              "value": "685"
            },
            {
              "id": "2",
              "type": "occupancy",
              "value": "false"
            }
          ]
        }
      ]
    },
    {
      "name": "Upstairs",
      "remoteSensors": [
        {
          "id": "ei:0",
          "name": "Upstairs",
          "capability": [
            {
              "id": "1",
              "type": "temperature",
              "value": "702"
            },
            {
              "id": "2",
              "type": "humidity",
              "value": "51"
            },
            {
              "id": "3",
              "type": "occupancy",
              "value": "false"
            },
            {
              "id": "4",
              "type": "airQualityAccuracy",
              "value": "unknown"
            },
            {
              "id": "5",
              "type": "airQuality",
              "value": "unknown"
            },
            {
              "id": "6",
              "type": "vocPPM",
              "value": "unknown"
            },
            {
              "id": "7",
              "type": "co2PPM",
              "value": "unknown"
            },
            {
              "id": "8",
              "type": "airPressure",
              "value": "unknown"
            }
          ]
        },
        {
          "id": "rs2:101",
          "name": "Bedroom",
          "type": "ecobee3_remote_sensor",
          "capability": [
            {
              "id": "1",
              "type": "temperature",
              "value": "691"
            },
            {
              "id": "2",
              "type": "occupancy",
              "value": "false"
            }
          ]
        },
        {
          "id": "rs2:100",
          "name": "Glens Office",
          "type": "ecobee3_remote_sensor",
          "capability": [
            {
              "id": "1",
              "type": "temperature",
              "value": "692"
            },
            {
              "id": "2",
              "type": "occupancy",
              "value": "false"
            }
          ]
        }
      ]
    }
  ]
}
"""

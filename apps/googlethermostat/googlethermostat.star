"""
Applet: Google Thermostat
Summary: Displays temperature
Description: Displays the temperature of your Google Nest Thermostats.
Author: habond
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

## Auth
GOOGLE_OAUTH_TOKEN_URL = "https://www.googleapis.com/oauth2/v4/token"
GOOGLE_OAUTH_USER_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_NEST_SCOPE = "https://www.googleapis.com/auth/sdm.service"

OAUTH_CLIENT_ID = "1021024143337-j1gomgdbkohrp7lkfebn3h77i2tm4fp3.apps.googleusercontent.com"
OAUTH_CLIENT_SECRET = secret.decrypt("AV6+xWcENuKVRrKEz3kWzUXtflgPOI0/i7PEcOBYYQf0GjIfvfB34wwg+5NrjSuqa5JaS1tVdzRdSbgZtARRhHxgTgLY7JVspwheR9K9uhL7JZmBLCb2RNti3tXwgvkX2h9AWtVQS3s6zNf9k1MvjIQnAMbxJ8+n30Lh9mYEnjbotncA3Wtoplg=")

# OAUTH_REDIRECT_URI = "http://127.0.0.1:8080/oauth-callback"
OAUTH_REDIRECT_URI = "https://appauth.tidbyt.com/googlethermostat"

# Nest Info
NEST_PROJECT_ID = "765f162b-7563-481b-a813-7c7f5d436ca6"
NEST_DEVICE_URI = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + NEST_PROJECT_ID + "/devices"

## Cache Keys
CACHE_KEY_ACCESS_TOKEN = "access_token"

def main(config):
    oauth_code = config.str("auth")

    if oauth_code == None:
        return render.Root(
            child = render.Text("Not Authenticated"),
        )

    oauth_access_token = get_access_token(oauth_code)

    if oauth_access_token == None:
        return render.Root(
            child = render.Text("Auth Failed"),
        )

    devices = get_nest_devices(oauth_access_token)

    if devices == None:
        return render.Root(
            child = render.Text("Auth Devices!"),
        )

    thermostats_info = get_formatted_thermostats_info(devices)

    if len(thermostats_info) == 0:
        return render.Root(
            child = render.Text("No Thermostats!"),
        )

    thermostats_widgets = [render.Text(thermostat_info) for thermostat_info in thermostats_info]
    thermostats_widgets = [render.Text("Thermostats:", color = "#099")] + thermostats_widgets

    return render.Root(
        child = render.Column(
            children = thermostats_widgets,
        ),
    )

def get_nest_devices(access_token):
    headers = {
        "Authorization": "Bearer {}".format(access_token),
        "Content-Type": "application/json",
    }

    response = http.get(NEST_DEVICE_URI, headers = headers)
    response_json = response.json()

    if not "devices" in response_json:
        return None

    return response_json["devices"]

def get_formatted_thermostats_info(nest_devices):
    return [
        get_formatted_thermostat_info(device)
        for device in nest_devices
        if device["type"] == "sdm.devices.types.THERMOSTAT"
    ]

def c_in_f(temperature_c):
    return temperature_c * (9 / 5.0) + 32

def get_formatted_thermostat_info(thermostat):
    temperature_c = thermostat["traits"]["sdm.devices.traits.Temperature"]["ambientTemperatureCelsius"]
    temperature_f = c_in_f(temperature_c)
    rounded_temperature = math.round(temperature_f)
    name = thermostat["traits"]["sdm.devices.traits.Info"]["customName"]
    return "{}°F {}".format(str(rounded_temperature), name)

def get_access_token(oauth_code):
    access_token = cache.get(CACHE_KEY_ACCESS_TOKEN)
    if access_token:
        return access_token

    response = http.post(
        GOOGLE_OAUTH_TOKEN_URL,
        params = {
            "code": oauth_code,
            "client_id": OAUTH_CLIENT_ID,
            "client_secret": OAUTH_CLIENT_SECRET,
            "redirect_uri": OAUTH_REDIRECT_URI,
            "grant_type": "authorization_code",
        },
    )

    if response.status_code != 200:
        return None

    response_json = response.json()

    access_token = response_json["access_token"]
    expires_in = response_json["expires_in"]

    cache.set(CACHE_KEY_ACCESS_TOKEN, access_token, ttl_seconds = int(expires_in - 30))

    return access_token

def oauth_handler(params):
    oauth_data = json.decode(params)
    oauth_code = oauth_data["code"]
    return oauth_code

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "setup",
                name = "Setup Instructions URL",
                desc = "Go here to authorize your Google Nest Thermostats",
                icon = "link",
                default = "https://nestservices.google.com/partnerconnections/" + NEST_PROJECT_ID + "/auth?redirect_uri=" + OAUTH_REDIRECT_URI + "&access_type=offline&prompt=consent&client_id=" + OAUTH_CLIENT_ID + "&response_type=code&scope=" + GOOGLE_NEST_SCOPE,
            ),
            schema.OAuth2(
                id = "auth",
                name = "Google",
                desc = "Connect your Google Nest account",
                icon = "google",
                handler = oauth_handler,
                client_id = OAUTH_CLIENT_ID,
                authorization_endpoint = GOOGLE_OAUTH_USER_AUTH_URL,
                scopes = [GOOGLE_NEST_SCOPE],
            ),
        ],
    )

"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""
# https://appauth.tidbyt.com/FitbitWeight
# https://localhost:8080/?code=42bd56d416272e67a8a23d98d7e73962862d01a2#_=_
#42bd56d416272e67a8a23d98d7e73962862d01a2
#238FC5 OAuth2 Client ID
# Client Secret 13c1038cdd434febc86318cd4322b489

#https://api.fitbit.com/1/user/GGNJL9/body/log/weight/date/today/7d.json

#/1/user/[user-id]/body/[resource]/date/[date]/[period].json
#https://api.fitbit.com/1/user/-/body/weight/date/today/7d.json
load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("http.star", "http")
load("cache.star", "cache")
load("secret.star", "secret")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("math.star", "math")

TEST_DATA = """
{
  "body-weight": [
    { "dateTime": "2022-03-13", "value": "104.53" },
    { "dateTime": "2022-03-14", "value": "103.57" },
    { "dateTime": "2022-03-15", "value": "104.37" },
    { "dateTime": "2022-03-16", "value": "104.9" },
    { "dateTime": "2022-03-17", "value": "104.37" },
    { "dateTime": "2022-03-18", "value": "103.51" },
    { "dateTime": "2022-03-19", "value": "103.34" },
    { "dateTime": "2022-03-20", "value": "102.46" },
    { "dateTime": "2022-04-01", "value": "100.93" },
    { "dateTime": "2022-04-02", "value": "102.07" },
    { "dateTime": "2022-04-03", "value": "101.89" },
    { "dateTime": "2022-04-04", "value": "101.4" },
    { "dateTime": "2022-04-05", "value": "100.73" },
    { "dateTime": "2022-04-06", "value": "100.88" },
    { "dateTime": "2022-04-07", "value": "100.25" },
    { "dateTime": "2022-04-08", "value": "100.59" },
    { "dateTime": "2022-04-09", "value": "100.41" }
  ]
}
"""

TEST_AUTHORIZATION_CODE = "41d52379ec87a26d560c2d85342f02a321d2ad32"

DEFAULT_PERIOD = "30d"
FITBIT_BASE = "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=238FC5&redirect_uri=https%3A%2F%2Fappauth.tidbyt.com%2FFitbitWeight&scope=profile%20weight&expires_in=604800"
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"
FLAG = """
UklGRnoFAABXRUJQVlA4TG0FAAAvJ0AHEIcGsbbdtg0A0r2n7j9G5skIncD/H2tIsm23baQPkJVzXEWttNZYs5rm0M0A4H/IbSQ5kkr0avk7/3E2nSWyu6syE4otAAiTP2nu7hZXl4d2DsHjBH4R7sBB3GnuDsnbwmBaGjdEEgkgABsEEiSLRGATJLlRBDWwFUuygK1YIKCg1KLM8gKCSUSCgRIWNoBsA0HWHQWpomjllCwjDQNwRCwgAIBYJg+aRACgmi3aavg+XEoFgLFcoaCTVpmR8A/qENShT0KqcJbFhUEMiuFjp01RmjV4X+y2oIFRHyI/JaaavJZpqGwG/3LzUQx9kvuV8LuGPrzFl9HuDNrQxLuMbbfsedMiA7ShN5j5mbs/eIt/gz027KFXRyaua5drhn/Pxl8w3uzE8nGQ+sKYaGJQF/fgLYQHd+cePEQJsQYF/PqPw+9t4fCX63w6kMuwNNvw/vJ0uX86HF5s3tzt5u1lvGwvLuxCLt83u8uz2Q/OcbZZH/K/sKhJGe1/bBnALBVQCchSIYYFObAICeHLmimjVJBbQSaWSE1lWMCSFokikmGq7nyC2wmLkM37poBx4vOzjqWGag7LRovYPMgDo22Oxj3Z8W66GS1l9Pnn9dfcx/PnKWtasay9Uc3iZu0S9utvTKir8fjnb06/bfo6+Pb6+mYMgmyb1V/7OUNETEBhvLBs207bZP4/xphRVvTE5JSZaVidhBTR/5SmbdvxRnljO6lt225U27Zt2/o/65gV1Maevm++zhLuJ6L/ity2bcBjgFX3FYcQwv3d5dX1TQjx6vKirHlc9B9aOusOL7fPyvTqoTLzts+7B6isKN8WatfStN3R2IAbovqBdgjHCQEZHjKLXW5PFae6prIONbX1ADaPr54qhGNKm5GVHBWSMCiMXsHxOQ73Bm1yqDjBR3n/pniKIR4pZKJZZAVK9g+51mCyWQxaGQPwcaI2qDs6IgxjpGTSB6WZccF2g5wJkBnD8mYmH2t0IhnvJl5JXFp9wLOP0uzUxCggIa1kd2WZPKfmIT9RODKayXaxFUi1loCotJJ9YA/AKrBCpfHWhzezsXpgC8JsAEoWynjEcp3ZKzCMKMjHpBQzPJw/NAhoJsdFNBYqp/OSI/zNagmDYMEc4+ndbQ4sloLnrltCpfc5ewd5KdHhvuRHFB6fu7a0OHO4b6IZxIqw7BglqzD5hCfn7fN6YoVomZZosSTy8021iNHcLqvsHK+8YByp1uwXHp2cmpmWEhdiVzM83JxNQbksZSh8t/hKxwXb9HIx+4Xc+6j3vNlmcqsL1gcX153XpzQzOtjLbFSrYDD7R+asL0z3qt7SNv/7ev3/+ksiEvP2V3hDuB60CCwA+Rc/f/+8SNgvINZYAiJTch1rWFwnR268v0b88PN2zyR6n4jErGyizOSoIMEvJeYBAOXFzutXdAkvKmCVn8GyIzMuyGZQSvlPrraE5sxP9he6D/ZLUyJ87WbAJyAiIcuxvMQNocU1lyO/2LU+O0c0f3RZVRSs+6UAudErPDnXyZuGWZovTvpWPPxc3zOIVRafMCIK9oFQZjKt3gIYtbzWnyevD7b4Uv6/JV4Ejtz4oF8ilhpDCib7T117WN3PS42LAhLT8p1cUsACnLnpSYiMTUovnt8CGk7qNzKDDFLBusEempTrml0g4vrTFuDO8H76Of1gABR6o52sRp2C/UNptAeGxMQiJNCqZcDj2eu9KiDJsTmDac7MZlFGpJ9ZyYRJTbE7A1dHmw2YpKm2dqK21l6eyemqwozYEH9v4DskqbChb4CGGtDYsd3UIuIbb+7q7ulo6+3j6UUf+mmABsduRXWdEyIhgu1GRzqGhzBMo53NIgAA
"""
MINIMUM_CACHE_TIME_IN_SECONDS = 600
MAXIMUM_CACHE_TIME_IN_SECONDS = 600000
FITBIT_CLIENT_ID = "238FC5"
FITBIT_LAUNCH_CACHE_NAME = "UniqueIDOfUser"
CACHE_TTL = 60 * 60 * 1  # updates once hourly
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcE74PvLnAK9o2UbKXs4mvqPOtEMJzu/AvYJQzd9Ngjvk/N5Ee2G3YD4+EF5TMJyWSs85/MoOk2VZWddwZh7+Zld7+ySKsF49sF+4tFGEQjOqVOebCiKpL1YpwFcBmC0em2bLFO890zJRjVUHDDLfXXkasbIftnKofwR49Kpga5oAY=") or "13c1038cdd434febc86318cd4322b489"

#Get the json from cache, or download a new copy and save that in cache
def get_fitbit_launch_json(config):
    print("get_fitbit_launch_json")

    #Step 1A Get Code
    authorization_code = config.get("auth") or TEST_AUTHORIZATION_CODE
    print(authorization_code)

    #Post and get Response with User ID, Access Token, Refresh Token
    print("My Secret")
    print(OAUTH2_CLIENT_SECRET)


    params = dict(
        code = authorization_code,
        grant_type = "authorization_code",
        client_id = FITBIT_CLIENT_ID,
        redirect_uri = "https%3A%2F%2Flocalhost%3A8080%2F"
    )

    res = http.post(
        url = FITBIT_TOKEN_URL,
        headers = {
            "Accept": "application/x-www-form-urlencoded",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    #cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))

    return access_token

#client_id: The Fitbit API application ID from https://dev.fitbit.com/apps.
#code: The authorization code
#code_verifier: The code verifier value from step 1.
#grant_type: authorization_code





    return None 

def main(config):
    units = config.get("units", DEFAULT_PERIOD)

    print (OAUTH2_CLIENT_SECRET)


    weight_data = get_fitbit_launch_json(config)

    return render.Root(
        child = render.Box(
            child = render.Image(
                src = base64.decode(FLAG), 
            ),
        )
    )

def oauth_handler(params):
    print('calling oauth_handler')
    params = json.decode(params)
    auth_code = params.get("code")
    print(auth_code)
    return get_refresh_token(auth_code)

def get_refresh_token(auth_code):
    print('calling get_refresh_token')
    params = dict(
        client_id = FITBIT_CLIENT_ID,
        code = auth_code,
        client_secret = OAUTH2_CLIENT_SECRET,
        grant_type = "authorization_code",
        
    )

    res = http.post(
        url = "https://api.fitbit.com/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        params = params,
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    refresh_token = token_params["refresh_token"]
    access_token = token_params["access_token"]
    athlete = int(float(token_params["athlete"]["id"]))

    cache.set(refresh_token, access_token, ttl_seconds = int(token_params["expires_in"] - 30))
    cache.set("%s/athlete_id" % refresh_token, str(athlete), ttl_seconds = CACHE_TTL)

    return refresh_token

def get_schema():

    period_options = [
        schema.Option(value = "7d", display = "7 Days"),
        schema.Option(value = "30d", display = "30 Days"),
        schema.Option(value = "1m", display = "1 Month"),
        schema.Option(value = "3m", display = "3 Months"),
        schema.Option(value = "6m", display = "6 Months"),
        schema.Option(value = "1y", display = "1 Year"),
        schema.Option(value = "max", display = "Maximum Allowed"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Fitbit Login",
                desc = "Connect to your Fitbit account",
                icon = "user",
                client_id = str(FITBIT_CLIENT_ID),
                handler = oauth_handler,
                authorization_endpoint = "https://www.fitbit.com/oauth2/authorize",
                scopes = [
                    "profile weight",
                ],
            ),
            schema.Dropdown(
                id = "units",
                name = "Period",
                desc = "The length of time to chart.",
                icon = "pencilRuler",
                options = period_options,
                default = DEFAULT_PERIOD,
            ),
        ],
    )
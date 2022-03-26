load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/json.star", "json")

# The daily step goal - this determines the coaching message you receive
STEP_GOAL = 10000

# Enable Print statements for key data
DEBUG_ON = 1

# This is the Google API URL to pull data from Google FIT.   This particular API is used to aggregate Fitness data over a given time range
# This program uses step count data (defined in the request body below)

GOOGLEFIT_DATASET_URL = "https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate"

# Note: Refresh Token during development was pulled using the Google Playground Console.  Requires User Approval sequence via browser.
# these tokens are reputed to be "permanent" for now, so pasting above.  Else, Need to set up a simple Web server to execute the Google Auth code/token exchange sequence.
#
# A token can be obtained manually via the Playground console (need to ensure the console is configured with TidByt project in your Google developers account - dont forget to give
# Permission for you (user) to access the app while it's in test state.
# Alternately, you may retrieve an Authorization Code via a browser link with redirect to localhost (doesn't really do anything more than the console but was a fun diversion)
# URL looks like: https://accounts.google.com/o/oauth2/v2/auth?client_id=XXXX.apps.googleusercontent.com&redirect_uri=127.0.0.1&scope=https://www.googleapis.com/auth/userinfo.profile&response_type=code
# Need to allow the redirect_uri in the credentials console.

# Google API Call and Body to Get a New Access Token.   These expire every 60 minutes.   However, there doesn't seem to be any harm in fetching more often.
# This script is intended to be invoked once every 30 minutes to refresh step count.

GOOGLE_OAUTH_TOKEN_REFRESH_URL = "https://oauth2.googleapis.com/token"
GOOGLE_OAUTH_USER_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"

# Random Hash Strings to store Secrets required by Google Oauth (for input to Tidbyt "Secrets" functions)
# Note - app name is "stepcounter"
CLIENT_ID_HASH = "AV6+xWcE+SIkQgnPgHzViV78GTRoxpMjlccjdOSUxNRSaBunq5fHKq5xp3sMlKVtYs1V9ZFwBUWg79Pgw+Y3mXoPB5q9AuBVN9bjgND9YpZ9dn3crPs7saefSsj+Mx4K8QUjQgzwLm68+qfWCCtQO419dnPJANjmjXuCrEk02RGw1q3DTRlmaF+Fh+Nf8PRl7wD7Vpfv++8I+WjUlqlhRviULKbMJkyRlZMuBrai"
CLIENT_SECRET_HASH = "AV6+xWcEb1T8b5kw+ugpxOQ55oRdM9Ox+/PxPSm7V3VTC7NtCrMJXsMA/oozP2Eu8yKUnuDO2jmRB87tsr9ffX1sIkUTdLbftv4swDYku77yz79AJb31q0IRS/gxVkeYuLdgwIt2wqFX6Xrqve2t3wvouaI2WIrpH7U9YzWwc1Iwuv8+6NcKjH0="

# Production Code - runs in the Tidbyt production environment.
GOOGLE_CLIENT_ID = secret.decrypt(CLIENT_ID_HASH)
GOOGLE_CLIENT_SECRET = secret.decrypt(CLIENT_SECRET_HASH)

def main(config):
    # Grab Secrets from paraneters if running in Render mode

    if GOOGLE_CLIENT_ID:
        client_id = GOOGLE_CLIENT_ID
    else:
        client_id = config.get("client_id")

    if GOOGLE_CLIENT_SECRET:
        client_secret = GOOGLE_CLIENT_SECRET
    else:
        client_secret = config.get("client_secret")

    # Google Project Required Info for OAuth
    # Note to Developers: You need to create your own project in the Google developers console in order to obtain a Client ID and Client Secret.

    # Get the Refresh Token - from Schema if running in Serve/Production mode or via Params when running in Render mode.

    GOOGLEFIT_REFRESH_TOKEN = config.get("auth") or config.get("googlefit_refresh_token")

    # Stepcount cannot be retrieved if a Refresh Token is not present
    # Render "Unauthorized" in that case

    if not GOOGLEFIT_REFRESH_TOKEN:
        return render.Root(
            child = render.WrappedText("Not Authorized (Stepcounter)"),
        )
    else:
        GOOGLEFIT_OAUTH_TOKEN = cache.get(GOOGLEFIT_REFRESH_TOKEN)

    # Get New Access token if Cache expired
    if not GOOGLEFIT_OAUTH_TOKEN:
        print("Fetching Access Token")

        # This is the JSON format for supplying an OAUTH refresh token to receive a new Authorization Token

        GOOGLE_OAUTH_TOKEN_REFRESH_BODY = {
            "client_secret": client_secret,
            "grant_type": "refresh_token",
            "refresh_token": GOOGLEFIT_REFRESH_TOKEN,
            "client_id": client_id,
        }

        # Make the Google Oauth API call - POST - to exchange Refresh token for Auth Token
        # For some reason this works just fine without the JSON command header (is that header really needed for any of the calls?)

        refresh = http.post(GOOGLE_OAUTH_TOKEN_REFRESH_URL, json_body = GOOGLE_OAUTH_TOKEN_REFRESH_BODY)
        if refresh.status_code != 200:
            fail("Google OAUTH TOKEN API request failed with status:", refresh.json())

        # Grab new Oauthtoken from the Google Token service, format for Data Aggregation API call.
        GOOGLEFIT_OAUTH_TOKEN = "Bearer {}".format(refresh.json()["access_token"])
        cache.set(GOOGLEFIT_REFRESH_TOKEN, GOOGLEFIT_OAUTH_TOKEN, ttl_seconds = int(refresh.json()["expires_in"] - 30))

    else:
        GOOGLEFIT_OAUTH_TOKEN = cache.get(GOOGLEFIT_REFRESH_TOKEN)

    # Header to Specify JSON format for the FIT API Data Aggregation
    GOOGLEFIT_POST_HEADERS = {
        "Content-type": "application/json",
        "Authorization": GOOGLEFIT_OAUTH_TOKEN,
    }

    # Now, compute time infomation for Google FIT API calls (done using milliseconds ePoch per Google developers guide)
    # Current Time (Seconds)
    epoch_time = time.now().unix

    hour_time = time.now().hour
    min_time = time.now().minute
    second_time = time.now().second

    # Subtract out seconds to get the midnight Epoch time
    midnight_delta = hour_time * 3600 + min_time * 60 + second_time
    midnight_epoch = epoch_time - midnight_delta

    # Translate to milliseconds
    epoch_time_millis = epoch_time * 1000
    midnight_epoch_millis = midnight_epoch * 1000

    # Google Fit API JSON Formatting.  Aggregate step count since Midnight of the current day.
    GOOGLEFIT_POSTREQUEST_BODY = {
        "aggregateBy": [{
            "dataSourceId": "derived:com.google.step_count.delta:com.google.android.gms:estimated_steps",
        }],
        "bucketByTime": {"durationMillis": 86400000},
        "startTimeMillis": midnight_epoch_millis,
        "endTimeMillis": epoch_time_millis,
    }

    rep = http.post(GOOGLEFIT_DATASET_URL, headers = GOOGLEFIT_POST_HEADERS, json_body = GOOGLEFIT_POSTREQUEST_BODY)
    if rep.status_code != 200:
        fail("Google FIT API request failed with status:", rep.json()["error"]["message"])

    # Retrieve Step count from the JSON response.   The indexing is slightly tricky.  If there are no steps (e.g, asleep after midnight), the "Point" index is undefined.
    if rep.json()["bucket"][0]["dataset"][0]["point"]:
        step_count = rep.json()["bucket"][0]["dataset"][0]["point"][0]["value"][0]["intVal"]
    else:
        step_count = 0

    # Now select the appropriate "Coaching" message depending on Progress toward step count goal.  Count from 8am-midnight
    # Future enhancement ideas: Count Window set via Parameter/Env variable; Make the coaching message dependent on % of the Expected step count achieved instead of fixed delta from expected.
    if hour_time > 8:  # Avoid divide by zero for early wake up days.
        progress_percent_expected = (hour_time - 8) / 16  # FUTURE ENHANCEMENT: Make the time range a parameter/ENV
    else:
        progress_percent_expected = 0

    steps_expected = STEP_GOAL * progress_percent_expected
    steps_delta = step_count - steps_expected

    if steps_delta > 2000:
        coaching_msg = "Rock Star!"
        coaching_color = "#0f0"  #Green
    elif steps_delta > 0:
        coaching_msg = "Very Good"
        coaching_color = "#fff"  #White
    elif steps_delta <= -2000:
        coaching_msg = "Slug!!"
        coaching_color = "#00f"  #blue
    else:
        coaching_msg = "Get Moving"
        coaching_color = "#f00"  #Red

    # Helpful data to print out for timestamp and key data while debugging
    if DEBUG_ON:
        print("Time Now:      \t %d ms" % epoch_time_millis)
        print("Midnight Today:\t %d ms" % midnight_epoch_millis)
        print("Step Count:", step_count)
        print("Expected Steps:", steps_expected)
        print(coaching_msg)

    # Note, I spent a few hours trying to use time parsing functions to complete the calculations in fewer lines of code.
    # Wasn't able to get it to work, removed the code but it's archived in prior revisions in n case I want to come back and torture myself.
    # The Time Parse functions seem to choke on the formatting that is returned by the day and month methods (since values seem to return as integers and not strings)

    # Now for the Fun stuff, render to Tidbyt!
    # The View that's created is very simplistic.  I tried putting more things in there, but the display easily gets too crowded, especially with smaller font size.
    # Future ideas:
    # 1. Show a running total of steps for the week.
    # 2. Use Images for the coaching message instead of text (my lovely wife already provided me with a 16x16 Slug PNG!)

    return render.Root(
        render.Column(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text("   Step Count   "),
                render.Text("%d" % step_count),
                render.Text(""),
                render.Text("%s" % coaching_msg, color = coaching_color),
            ],
        ),
    )

# Google Oauth Handler.   This needs to handle a response from the following command (Returns an Authorization Code)
# The Authorization code then needs to be exchanged for an Access + Refresh Token (the goal of the handler below)
# This is the HTTP GET call that successfully returns an Authorization code using localhost: https://accounts.google.com/o/oauth2/v2/auth?client_id=xxxx.apps.googleusercontent.com&redirect_uri=http://127.0.0.1:8080/oauth-callback&prompt=consent&scope=https://www.googleapis.com/auth/fitness.activity.read&response_type=code

def oauth_handler(params):
    print("Running Handler")
    params = json.decode(params)

    # Deconstructing params for now since there isn't much/any debug info that comes from Schema.Oauth failures.
    # This makes things easier to debug when something goes wrong in Schema user Auth sequence.

    auth_code = params["code"]
    auth_client_id = params["client_id"]
    auth_grant_type = params["grant_type"]
    auth_redirect_uri = params["redirect_uri"]
    auth_client_secret = GOOGLE_CLIENT_SECRET

    print("checkpoint")
    print("secret1")
    print(auth_client_secret)

    # Re-assemble the Auth Body with a series of parameters that I know work for Google Oauth
    auth_body = "code=" + auth_code + "&redirect_uri=" + auth_redirect_uri + "&client_id=" + auth_client_id + "&client_secret=" + auth_client_secret + "&grant_type=" + auth_grant_type
    print("Checkpoint2")

    #This is a handy debug tool.   Prints out a 1-liner curl command that can be cut and pasted into the terminal
    if (DEBUG_ON):
        curl_cmd = "curl -s --request POST --data \"" + auth_body + "\" " + GOOGLE_OAUTH_TOKEN_REFRESH_URL
        print(curl_cmd)

    # Exchange parameters and client secret for an access token
    GOOGLEAUTH_POST_HEADERS = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    res = http.post(GOOGLE_OAUTH_TOKEN_REFRESH_URL, body = auth_body, headers = GOOGLEAUTH_POST_HEADERS)

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    # Grab the refresh token from the Oauth response - Cache the Access token (at present they are good for 1 hour)

    token_params = res.json()
    refresh_token = token_params["refresh_token"]

    print(token_params["expires_in"])

    cache.set(refresh_token, "Bearer " + token_params["access_token"], ttl_seconds = int(token_params["expires_in"] - 30))

    return refresh_token

def get_schema():
    # Note below that in order to return a refresh token, Google Oauth requires the parameter "access_type" to be set to "offline"
    # The Default setting is "online" - so slipping this parameter via client_id.
    # It cannot be done via the authorization_endpoint because the Auth sequence running behind the scenes inserts a "?" after
    # The authorization_endpoint causing syntax errors with the Google Oauth endpoint.

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Google Fit",
                desc = "Authorize your Google Fit Account.",
                icon = "heartPulse",
                handler = oauth_handler,
                client_id = GOOGLE_CLIENT_ID + "&access_type=offline",
                authorization_endpoint = GOOGLE_OAUTH_USER_AUTH_URL,
                scopes = [
                    "https://www.googleapis.com/auth/fitness.activity.read",
                ],
            ),
        ],
    )

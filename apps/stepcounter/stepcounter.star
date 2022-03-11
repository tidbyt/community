load("render.star", "render")
load("http.star", "http")
load("time.star", "time")

#print getopt.getopt()

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

def main(config):
    # Google Project Required Info for OAuth
    # Note to Developers: You need to create your own project in the Google developers console in order to obtain a Client ID and Client Secret.
    # Obtaining a Refresh Token can be done via the Oauth playground (Manual) or must write server code to accept callback from the User/Browser Authenticaion Sequence.
    # For TIDBYT, the mobile App would provide the necessary Token based on Project "Tidbyt" - go through user acknowledgement, auth code exchange for a token, etc.
    GOOGLE_CLIENT_ID = config.get("client_id")
    GOOGLE_CLIENT_SECRET = config.get("client_secret")
    GOOGLEFIT_REFRESH_TOKEN = config.get("googlefit_refresh_token")

    # This is the JSON format for supplying an OAUTH refresh token to receive a new Authorization Token

    GOOGLE_OAUTH_TOKEN_REFRESH_BODY = {
        "client_secret": GOOGLE_CLIENT_SECRET,
        "grant_type": "refresh_token",
        "refresh_token": GOOGLEFIT_REFRESH_TOKEN,
        "client_id": GOOGLE_CLIENT_ID,
    }

    # Make the Google Oauth API call - POST - to exchange Refresh token for Auth Token
    # For some reason this works just fine without the JSON command header (is that header really needed for any of the calls?)

    refresh = http.post(GOOGLE_OAUTH_TOKEN_REFRESH_URL, json_body = GOOGLE_OAUTH_TOKEN_REFRESH_BODY)
    if refresh.status_code != 200:
        fail("Google OAUTH TOKEN API request failed with status:", refresh.json())

    #        fail("Google OAUTH TOKEN API request failed with status:", refresh.json()["error"]["message"])    #This may be the cleaner print statement.   Somehow ended up without the JSON indexing during debug.

    #    print(refresh.json())    #debug only

    # Grab new Oauthtoken from the Google Token service, format for Data Aggregation API call.
    GOOGLEFIT_OAUTH_TOKEN = "Bearer {}".format(refresh.json()["access_token"])

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

    #    print(rep.json())    # For debug

    # Retrieve Step count from the JSON response.   The indexing is slightly tricky.  If there are no steps (e.g, asleep after midnight), the "Point" index is undefined.
    if rep.json()["bucket"][0]["dataset"][0]["point"]:
        step_count = rep.json()["bucket"][0]["dataset"][0]["point"][0]["value"][0]["intVal"]
    else:
        step_count = 0

    # Now select the appropriate "Coaching" message depending on Progress toward step count goal.  Count from 8am-midnight
    # Future enhancement ideas: Count Window set via Parameter/Env variable; Make the coaching message dependent on % of the Expected step count achieved instead of fixed delta from expected.
    if hour_time > 8:  # Avoid divide by zero for early wake up days.
        progress_percent_expected = (hour_time - 8) // 16  # FUTURE ENHANCEMENT: Make the time range a parameter/ENV
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

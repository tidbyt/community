"""
Applet: Meeting Stats
Summary: Weekly Meeting Insights
Description: Analyzes your Outlook calendar and provides a summary of your weekly meeting load.
Author: Matt-Pesce
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# Enable Print statements for key data
DEBUG_ON = 1

# Conversion from Day of the Week (string) to a Number (relative to Sunday)
# Used to Calculate backward in time to get total steps from the beginning of the week.
WEEKDAY_TO_INT = {
    "Sunday": 6,
    "Monday": 0,
    "Tuesday": 1,
    "Wednesday": 2,
    "Thursday": 3,
    "Friday": 4,
    "Saturday": 5,
}

# Colors to Display the stats, indicates Concern Level of collaboration time
Green = "#0f0"
Red = "#f00"
Yellow = "#ff0"

DEFAULT_TIMEZONE = "America/Detroit"

# Default (bogus) client ID and Secrets to keep the run time Env happy when running in Debug Mode
CLIENT_ID_DEFAULT = "123456"
CLIENT_SECRET_DEFAULT = "78910"

# Except for Tenant ID - MSFT "common" Tenant is used to enable the App to access data from all Enterprise Tenants and/or Personal Outlook Accounts.
# When running non-server mode we pass the Tenant ID via Config to test with a specific Enterprise Tenant.
TENANT_ID_DEFAULT = "common"

# Maximum Number of Events that can be fetched in a week.  Needs to be specified due to link chaining by Graph and also since Tidbyt doesn't permit the WHILE construct.
MAX_EVENT_FETCH_WEEK = 100
MSFT_GRAPH_BUCKET_SIZE = 10
NUMBER_OF_FETCH_ITERATIONS = int(MAX_EVENT_FETCH_WEEK / MSFT_GRAPH_BUCKET_SIZE)

# Other Conversions for obtaining Historical Day
SECONDS_IN_A_DAY = 3600 * 24
SECONDS_IN_A_WEEK = SECONDS_IN_A_DAY * 7

# Endpoint to fetch Outlook calendar events.  Note query language format.  We specify the calendar attributes to be returned
#OUTLOOK_CALENDAR_EVENTS_URL	= "https://graph.microsoft.com/v1.0/me/events?$select=subject,attendees,start,end,isCancelled"
OUTLOOK_CALENDAR_VIEW_URL = "https://graph.microsoft.com/v1.0/me/calendarview?$select=subject,attendees,start,end,isCancelled,organizer"

# Hash Strings to encrypt/store secrets required by MSFT Graph API access.   These ultimately get replaced with Tidbyt Hash when the
# App is placed into the production envirnment.
CLIENT_ID_HASH = "AV6+xWcEBwpG6qbW6ARmQc4DywoBU2qTim/4qONx+4E5KyGvE5v3sYbRaGVzOtd3GPqH8Fg/S5GoI0XiAl9X0KYDyM5iy1AwyeL/a+sTH1uSUt71UegtRpaWVBN2EqW7yCQmlwpjtoqkdZyc0ThLk7wHFM+4ddOuX3utoRkOwjuTTmVpxxX93Zgw"
CLIENT_SECRET_HASH = "AV6+xWcEeAGgyKz4rvduekJjvayWGNcfG+FCAkAJn/MyRBICPS+KniX9oeWCinVlBCwb2RdTfN0tYDcp5n3tGtmx2kJ6epxEA+o+btrvjsrOOkNIYxYZPCSBWTnwLEbNGGY/BGOsfEUqRzCuKImEW7wqU8FOptRKXdcqdF06kesMIDPmZ5xPST1ovzVnoQ=="
TENANT_ID_HASH = "ABCDEFG123456789"

# MSFT Graph uses 3 secrets to operate.  There is the usual Client Secret and Client ID, but Graph uses the Tenant ID as part of
# The endpoint URL
# Note the Client Secret expires on 4/26/2023
# Secrets are hardcoded here for debug with Pixlet "Serve" mode, then replaced with Tidbyt Secrets for production code.
# Update: Tenant is now excluded since when running in production, the Tenant is "common" - use an actual Tenant ID when running locally
# within your organization's Azure Domain

# Production Code - runs in the Tidbyt production environment.  In Deubg mode with Serve need to hard code valid ID, Tenant ID and SECRET here instead (since HASHes above are only valid in production env
MSFT_CLIENT_ID = secret.decrypt(CLIENT_ID_HASH)
MSFT_TENANT_ID = ""
MSFT_CLIENT_SECRET = secret.decrypt(CLIENT_SECRET_HASH)

# Microsoft Auth related End points. Note that the Tenant ID is specific to this application
MSFT_EVENTFETCH_AUTH_ENDPOINT = "https://login.microsoftonline.com/" + (MSFT_TENANT_ID or TENANT_ID_DEFAULT) + "/oauth2/v2.0/authorize"
MSFT_EVENTFETCH_TOKEN_ENDPOINT = "https://login.microsoftonline.com/" + (MSFT_TENANT_ID or TENANT_ID_DEFAULT) + "/oauth2/v2.0/token"

# Time formatting
RFC3339_FORMAT = "2006-01-02T15:04:05Z07:00"

def main(config):
    # Grab Secrets from Parameters if running in Render mode.   Hash functions will return null value if running locally
    # They only return value when running on Tidbyt Servers.

    if MSFT_CLIENT_ID:
        client_id = MSFT_CLIENT_ID
    else:
        client_id = config.get("client_id")

    if MSFT_CLIENT_SECRET:
        client_secret = MSFT_CLIENT_SECRET
    else:
        client_secret = config.get("client_secret")

    if MSFT_TENANT_ID:
        tenant_id = MSFT_TENANT_ID
    else:
        tenant_id = config.get("tenant_id") or TENANT_ID_DEFAULT

    msft_token_endpoint = "https://login.microsoftonline.com/" + tenant_id + "/oauth2/v2.0/token"

    # Refresh token comes from Auth Handler params when running in Production/Serve mode....from Conflig when running locally/Render
    outlook_refresh_token = config.get("auth") or config.get("outlook_refresh_token")

    # Capture the user's time zone.   Allow timezone to be passed via command line for debug and test
    timezone = config.get("time_zone") if config.get("time_zone") else config.get("$tz", DEFAULT_TIMEZONE)

    # At present this application checks the calendar from Monday of the current week until Sunday
    # RFC3339 format works with MSFT Graph API calls (default Starlark time object does not)
    # So we need to figure out the timestamp for Monday at Midnight and the following Sunday at 11:59:59PM
    # Using System time is super convenient once you know the day of the week.   There is probably a more elegant way to do this with time functions.

    epoch_time = time.now().in_location(timezone).unix

    day_time = time.now().in_location(timezone).format("Monday")
    day_oftheweek = WEEKDAY_TO_INT[day_time]

    hour_time = time.now().in_location(timezone).hour
    min_time = time.now().in_location(timezone).minute
    second_time = time.now().in_location(timezone).second

    # Subtract out seconds to get the midnight Epoch time for Today
    midnight_delta = hour_time * 3600 + min_time * 60 + second_time
    midnight_epoch = epoch_time - midnight_delta

    # Compute the epoch time for the beginning of the week - Monday in the case of Calendar events
    beginning_of_the_week_epoch = midnight_epoch - (SECONDS_IN_A_DAY * day_oftheweek)

    # Same for End of the week - Subtract 1 second from Saturday to get 11:59:59 on Friday night.
    end_of_the_week_epoch = beginning_of_the_week_epoch + SECONDS_IN_A_WEEK - 1

    calendar_start_time = time.from_timestamp(beginning_of_the_week_epoch).in_location(timezone).format(RFC3339_FORMAT)
    calendar_end_time = time.from_timestamp(end_of_the_week_epoch).in_location(timezone).format(RFC3339_FORMAT)

    if DEBUG_ON:
        print(time.now().in_location(timezone))
        print(timezone)
        print(calendar_start_time)
        print(calendar_end_time)

    outlook_event_url = OUTLOOK_CALENDAR_VIEW_URL + "&startdatetime=" + calendar_start_time + "&enddatetime=" + calendar_end_time

    if not outlook_refresh_token:
        return render_stats(22, 20, 12, "Not Authorized, Please Sign In")

    else:
        OUTLOOK_ACCESS_TOKEN = cache.get(outlook_refresh_token)

    if not OUTLOOK_ACCESS_TOKEN:
        refresh_body = "refresh_token=" + outlook_refresh_token + "&redirect_uri=http://127.0.0.1:8080/oauth-callback" + "&client_id=" + client_id + "&client_secret=" + client_secret + "&grant_type=refresh_token" + "&scope=Calendars.read"

        # CURL can be handy for debug ops from the Linux command line

        if DEBUG_ON:
            print("Refreshing Outlook Access Token")
            curl_cmd = "curl -s --request POST --data \"" + refresh_body + "\" " + msft_token_endpoint
            print(curl_cmd)

        # Lint Fix
        #MSFT_GRAPH_POST_HEADERS = {"Content-Type": "application/x-www-form-urlencoded"
        #}

        refresh = http.post(msft_token_endpoint, body = refresh_body)

        # Send error message to the display (most common reason for this is MFA revokes the user's refresh token)
        if refresh.status_code != 200:
            auth_failure_code = str(refresh.status_code)
            auth_failure_error_description = refresh.json()["error_description"]
            if DEBUG_ON:
                print("Refresh of Access Token Failed with Code %s - %s" % (auth_failure_code, auth_failure_error_description))
            return render_stats(99, 99, 99, "Auth Failure: " + auth_failure_code + "  **** " + auth_failure_error_description)
            #fail("Refresh of Access Token failed with Status Code: %d - %s" % (refresh.status_code, refresh.body()))

        # Grab new Oauthtoken from the Google Token service, format for Data Aggregation API call.
        OUTLOOK_ACCESS_TOKEN = "Bearer {}".format(refresh.json()["access_token"])
        cache.set(outlook_refresh_token, OUTLOOK_ACCESS_TOKEN, ttl_seconds = int(refresh.json()["expires_in"] - 30))

    else:
        OUTLOOK_ACCESS_TOKEN = cache.get(outlook_refresh_token)

    OUTLOOK_EVENT_HEADERS = {
        #    "Prefer": "outlook.timezone=\"Eastern Standard Time\"",
        "Authorization": OUTLOOK_ACCESS_TOKEN,
    }

    #    DEFAULT_TIME = time.now().in_location(timezone).format("2006-01-02T15:04:05Z07:00")
    #    timezone = config.get("$tz", "America/Chicago")  # Utilize special timezone variable

    # Initialize meeting stats counts.  MSFT Graph returns Outlook events in buckets of 10 or less, need counters to track outside of each bucket scan loop
    total_event_num = 0
    actual_meeting_count = 0
    total_meeting_duration = 0
    total_big_meeting_duration = 0

    next_graph_event_link = outlook_event_url

    # Initialize the enpoint link, this will get overwritten as Graph provides link via Odata for the next "bucket" of events.
    # Iterate over the meeting buckets.   So far, my calendar fits into 3-4 buckets.   Default is to allow 10 buckets max (for now)

    for _ in range(NUMBER_OF_FETCH_ITERATIONS):
        # Get the first Batch of events

        # Also, MSFT generated "Focus Time" shows as 1 attendee, where as MF + Rachel entered morning prep, coding/training shows up as 0 attendees.   Hm.....may need to specifically filter on "Focus Time", dont count as a meeting.
        # Same for "meetings" with Zero attendees.

        CalendarQuery = http.get(next_graph_event_link, headers = OUTLOOK_EVENT_HEADERS)
        if CalendarQuery.status_code != 200:
            fail("Outlook Calendar View Request failed with status:", CalendarQuery.json())

        meeting_num = 0
        for _ in CalendarQuery.json()["value"]:
            meeting = CalendarQuery.json()["value"][meeting_num]["subject"]
            is_cancelled = CalendarQuery.json()["value"][meeting_num]["isCancelled"]
            start_time = CalendarQuery.json()["value"][meeting_num]["start"]["dateTime"] + "Z"
            end_time = CalendarQuery.json()["value"][meeting_num]["end"]["dateTime"] + "Z"

            # This expression returns a time.duration result e.g, 1h30m, etc...  Handy for displaying human readable meeting times on Tidbyt (for example display "Next Meeting")
            #meeting_duration = time.parse_time(end_time) - time.parse_time(start_time)
            # This expression returns timestamps, easier to do math with these.   Again struggling a bit with the time "types"

            meeting_duration = time.parse_time(end_time).unix - time.parse_time(start_time).unix

            if DEBUG_ON:
                print("Event #: %d" % total_event_num)
                print(meeting)
                print(start_time)
                print(end_time)
                print(meeting_duration)
                print(is_cancelled)

            # Count the attendees for each event (+ optional code for tracking attendee details)
            organizer = CalendarQuery.json()["value"][meeting_num]["organizer"]["emailAddress"]["address"]
            print(organizer)

            attendee_num = 1
            attendee_index = 0
            for _ in CalendarQuery.json()["value"][meeting_num]["attendees"]:
                # Can simplify this?   ie if specific attendee names arent required, just delete the line of code below (assignment of attendee)
                attendee = CalendarQuery.json()["value"][meeting_num]["attendees"][attendee_index]["emailAddress"]["address"]
                #               print("Attendee: %s" % attendee)

                attendee_index = attendee_index + 1

                # Look for the case where Outlook is not counting the organizer as an attendee.   Watch out for the case where someone
                # invites themself multiple times.  NOTE Some organizations include meeting rooms as an attendee (this will be counted)
                if organizer != attendee:
                    attendee_num = attendee_num + 1

            if DEBUG_ON:
                print("Attendee Count: %d" % attendee_num)

            # Only count as a "Meeting" if attendee count is two or more
            # Also, filter out "All Day" events that come across as 24 hour meeting invites
            # Ignore Canceled meetings (probably can optimize this somehow to break out of the loop)

            if not is_cancelled:
                if meeting_duration < 86400:
                    if attendee_num > 1:
                        total_meeting_duration = total_meeting_duration + (meeting_duration / 3600)
                        actual_meeting_count = actual_meeting_count + 1
                    if attendee_num > 12:
                        total_big_meeting_duration = total_big_meeting_duration + (meeting_duration / 3600)

            meeting_num = meeting_num + 1
            total_event_num = total_event_num + 1

            if DEBUG_ON:
                print("Number of Meetings for the Week %d" % actual_meeting_count)
                print("Total Hours of Meetings for the Week %d" % total_meeting_duration)
                print(total_meeting_duration)
                print("Including %d Bloated Meeting Hours" % total_big_meeting_duration)

        # MSFT GRAPH only dumps 10 events at a time.   Must check for the existence of "@odata.nextLink" and keep looping until there is no more "next" link.
        # The next link must be fed into a GET command, just like the initial GET (requires the header with access token)
        # Note the .json().get method which protects against the null Index condition (no more links), else get a run time error with no .get when there is no next link.

        next_graph_event_link = CalendarQuery.json().get("@odata.nextLink")

        if DEBUG_ON:
            print("Next Link %s" % next_graph_event_link)

        # When there are no more links, we are done

        if not next_graph_event_link:
            break

    # Render the output for Tidbyt
    return render_stats(total_meeting_duration, actual_meeting_count, total_big_meeting_duration, "")

# This function formats and renders output to Tidbyt
def render_stats(total_duration, total_count, big_duration, banner_line):
    # Color code the stats.....turn yellow/red when they exceed desired thresholds.

    # Format the numbers so that 2 decimal places are shown (0.50 for 30mins, 0.25 for 15 mins)
    format_total_meeting_duration = humanize.float("###.##", float(total_duration))
    format_total_big_meeting_duration = humanize.float("###.##", float(big_duration))

    if total_duration < 21:
        meeting_duration_color = Green
    elif total_duration < 26:
        meeting_duration_color = Yellow
    else:
        meeting_duration_color = Red

    if total_count < 21:
        meeting_count_color = Green
    elif total_count < 26:
        meeting_count_color = Yellow
    else:
        meeting_count_color = Red

    if big_duration < 6:
        big_meeting_duration_color = Green
    elif big_duration < 11:
        big_meeting_duration_color = Yellow
    else:
        big_meeting_duration_color = Red

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Text("Meeting Stats"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            align = "center",
                            child = render.Text(banner_line, font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Text("Count:", font = "tom-thumb"),
                                render.Text("Time:", font = "tom-thumb"),
                                render.Text("Bloated:", font = "tom-thumb"),
                            ],
                        ),
                        render.Column(
                            cross_align = "end",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    children = [
                                        render.Text(" %d" % total_count, font = "tom-thumb", color = meeting_count_color),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    children = [
                                        render.Text(" %sH" % format_total_meeting_duration, font = "tom-thumb", color = meeting_duration_color),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    children = [
                                        render.Text(" %sH" % format_total_big_meeting_duration, font = "tom-thumb", color = big_meeting_duration_color),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def oauth_handler(params):
    # This handler is invoked once the user selects the "Authorize my Outlook Acccount" from the Mobile app
    # It passes Params from a successful user Auth, including the Code that must be exchanged for a Refresh token

    if DEBUG_ON:
        print("Running Handler")
        #print(params)

    params = json.decode(params)

    # Deconstructing params for now since there isn't much/any debug info that comes from Schema.Oauth failures.
    # This makes things easier to debug when something goes wrong in Schema user Auth sequence.

    auth_code = params["code"]
    auth_client_id = params["client_id"]
    auth_grant_type = params["grant_type"]
    auth_redirect_uri = params["redirect_uri"]
    auth_scope = "offline_access%20Calendars.read"
    auth_client_secret = MSFT_CLIENT_SECRET or CLIENT_SECRET_DEFAULT  # Keep run time env happy, it barfs on NULL values in Render Mode

    # Re-assemble the Auth Body with a series of parameters that I know work for Google Oauth
    auth_body = "&code=" + auth_code + "&redirect_uri=" + auth_redirect_uri + "&client_id=" + auth_client_id + "&client_secret=" + auth_client_secret + "&grant_type=" + auth_grant_type + "&scope=" + auth_scope

    #This is a handy debug tool.   Prints out a 1-liner curl command that can be cut and pasted into the terminal
    if DEBUG_ON:
        curl_cmd = "curl -s --request POST --data \"" + auth_body + "\" " + MSFT_EVENTFETCH_TOKEN_ENDPOINT
        print(curl_cmd)

    # Exchange parameters and client secret for an access token
    # Remove for Lint Fix
    #MSFTAUTH_POST_HEADERS = {"Content-type": "application/x-www-form-urlencoded",
    #}
    res = http.post(url = MSFT_EVENTFETCH_TOKEN_ENDPOINT, body = auth_body)

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    # Grab the refresh token from the Oauth response - Cache the Access token (at present they are good for 1 hour)
    # Set cache to expire 30 seconds early to prvide a small time buffer.

    token_params = res.json()
    refresh_token = token_params["refresh_token"]

    cache.set(refresh_token, "Bearer " + token_params["access_token"], ttl_seconds = int(token_params["expires_in"] - 30))

    return refresh_token

def get_schema():
    # Note below that in order to return a refresh token, MSFT Graph requires the parameter offline_access to be provided
    # This needs to be passed as part of the Scope paramater.

    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Microsoft Outlook",
                desc = "Authorize your Microsoft Outlook Calendar",
                icon = "windows",
                handler = oauth_handler,
                client_id = (MSFT_CLIENT_ID or CLIENT_ID_DEFAULT),
                authorization_endpoint = MSFT_EVENTFETCH_AUTH_ENDPOINT,
                scopes = [
                    "offline_access",
                    "Calendars.read",
                ],
            ),
        ],
    )

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")
load("secret.star", "secret")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("humanize.star", "humanize")

CAL_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAOlJREFUaEPtl0EKg1AMRPUW3Xsv957i80/Rfe/VvbewKG1RERO+TzEwrj6SPxlnJgHr6sQnpTTknOuxBXWm6U7kkOfVD2uc9H5Wuemm19R50aN9HOZ/GOBPaBRgRYhyfY6z16/EyFMFKCHkvrMhuPvurFAClKi2eQdyxM0H6qcEuBW3CiFHrDZagj8FIME1Au7IWYWQI1YbjYBG4KsAlDjtAPfMWYWQI1abe+8AN3uo8FZ/g9A3XQ3D7YCrmUP9JAAkZFgYJSCsdRBxJQASMiyMEhDWOoi4EgAJGRZGCQhrHURcCYCEDAvzAXMPoSHYT20lAAAAAElFTkSuQmCC""")

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
Blue = "#00f"

DEFAULT_TIMEZONE = "America/Detroit"
#DEFAULT_TIMEZONE="US/Pacific"

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
OUTLOOK_CALENDAR_VIEW_URL = "https://graph.microsoft.com/v1.0/me/calendarview?$select=subject,attendees,start,end,isCancelled"

# Hash Strings to encrypt/store secrets required by MSFT Graph API access.   These ultimately get replaced with Tidbyt Hash when the
# App is placed into the production envirnment.   Application folder name is "outlookcalendar"   These (hashed) secrets are tied to
# the common tenant version of the Web App (Tidbyt_Ocal)
CLIENT_ID_HASH = "AV6+xWcE/js7NgNeEupVWQvDKGQLeO4ZpKw7M/ue5tO6YKHhwMRe2C7Gcsd885VHB+bZuLFpai/pGLsCrEm2uw+AuFbkBa+H5qXcXy1lRcwYLkQw/nBMqX6A7t7Ucijlo79QVLbgpqtk3srR55Z126aerT4pKBIARqdu3a65Yr9y23Znf5TYImSV"
CLIENT_SECRET_HASH = "AV6+xWcEGY1Cp4+jtOxjvucCkqZsXt6i4A3fLH1ksuc0+BTabBY9g5t1SpKYYszRxFqr1GN0XQYJSkNoZp+6YAFoMTXMz6ypZ6vb53KCJiywBEW1sy6lEC7N8AAE5zlzqvzXN2Um5sSdnMWAM+bDgn/8AFyB0pae6iNXkSRTP8+Dbce3F9av7lCFu6EBOg=="

# MSFT Graph uses 3 secrets to operate.  There is the usual Client Secret and Client ID, but Graph uses the Tenant ID as part of
# The endpoint URL.  For public usage, the Tenant ID is set to "Common"
# Note the Client Secret expires on 4/26/2023
# Secrets are hardcoded here for debug with Pixlet "Serve" mode, then replaced with Tidbyt Secrets for production code.

# Common Tenant (will encrypt these as the production values)
#MSFT_CLIENT_SECRET = "xxxx"
#MSFT_CLIENT_ID = "yyyy"

# Production Code - runs in the Tidbyt production environment.  In Debug mode with Serve need to hard code valid ID, Tenant ID and SECRET here instead (since HASHes above are only valid in production env
MSFT_TENANT_ID = ""
MSFT_CLIENT_ID = secret.decrypt(CLIENT_ID_HASH)
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

    # At present this application checks the calendar from the current time until end of day.
    # RFC3339 format works with MSFT Graph API calls (default Starlark time object does not)
    # Compute and format the current time - and also the time for 11:59:59 PM on the current Day
    current_time = time.now().in_location(timezone)
    current_date = current_time.format("2006-01-02T")
    current_tz = current_time.format("Z07:00")
    midnight_time = current_date + "23:59:59" + current_tz

    calendar_start_time = current_time.format(RFC3339_FORMAT)
    calendar_end_time = midnight_time

    if DEBUG_ON:
        print(calendar_start_time)
        print(calendar_end_time)

    # Show Default screen if the user is not authorized
    if not outlook_refresh_token:
        print("Not Auth")
        return render_calendar("Aug 28", "No More Meetings for today!!!", "")
    else:
        OUTLOOK_ACCESS_TOKEN = cache.get(outlook_refresh_token)

    if not OUTLOOK_ACCESS_TOKEN:
        refresh_body = "refresh_token=" + outlook_refresh_token + "&redirect_uri=http://127.0.0.1:8080/oauth-callback" + "&client_id=" + client_id + "&client_secret=" + client_secret + "&grant_type=refresh_token" + "&scope=Calendars.read"

        # CURL can be handy for debug ops from the Linux command line

        if DEBUG_ON:
            print("Refreshing Outlook Access Token")
            curl_cmd = "curl -s --request POST --data \"" + refresh_body + "\" " + msft_token_endpoint
            print(curl_cmd)

        MSFT_GRAPH_POST_HEADERS = {
            "Content-Type": "application/x-www-form-urlencoded",
        }

        refresh = http.post(msft_token_endpoint, body = refresh_body)

        if refresh.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (refresh.status_code, refresh.body()))

        # Grab new Oauthtoken from the Google Token service, format for Data Aggregation API call.
        OUTLOOK_ACCESS_TOKEN = "Bearer {}".format(refresh.json()["access_token"])
        cache.set(outlook_refresh_token, OUTLOOK_ACCESS_TOKEN, ttl_seconds = int(refresh.json()["expires_in"] - 30))

        # HM, is this ELSE path ever taken or leftover prior to inserting the else condition of the refresh token check?
    else:
        OUTLOOK_ACCESS_TOKEN = cache.get(outlook_refresh_token)

    # Build the meeting list - the function returns the earliest meeting time based on the time ranges given.
    # Not that specifying a time in the past will likely return a meeting time in the past so for this app it's important to
    # call function get_outlook_event_list using the current or future time.

    meeting_list, next_meeting_time = get_outlook_event_list(calendar_start_time, calendar_end_time, OUTLOOK_ACCESS_TOKEN)

    # Filter out case where there is one meeting in the list and it's already in progress (next_meeting_time will be null)

    if meeting_list and next_meeting_time:
        display_next_meeting_time = "at " + time.parse_time(next_meeting_time).in_location(timezone).format("3:04PM")
        display_calendar_date = time.parse_time(next_meeting_time).in_location(timezone).format("Jan 2")

        # Now count the number of meetings in the next time slot.
        display_number_of_conflict_meetings = len(meeting_list[next_meeting_time])
        conflict_meeting_banner = ""
        separator_counter = display_number_of_conflict_meetings - 1

        # Compress Conflicting meetings into a single string
        for m in meeting_list[next_meeting_time]:
            conflict_meeting_banner = conflict_meeting_banner + m
            if separator_counter:
                conflict_meeting_banner = conflict_meeting_banner + " ** "
                separator_counter = separator_counter - 1

        if DEBUG_ON:
            print(meeting_list)
            print(next_meeting_time)
            print(display_calendar_date)
            print(display_next_meeting_time)
            print(display_number_of_conflict_meetings)
            print(meeting_list[next_meeting_time])
            print(conflict_meeting_banner)
    else:
        conflict_meeting_banner = "No More Meetings for Today!"
        display_calendar_date = time.parse_time(calendar_start_time).in_location("America/Detroit").format("Jan 2")
        display_next_meeting_time = ""

        if DEBUG_ON:
            print("No More Meetings for Today!")

    # Display the Output to Tidbyt.
    return render_calendar(display_calendar_date, conflict_meeting_banner, display_next_meeting_time)

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
    MSFTAUTH_POST_HEADERS = {
        "Content-type": "application/x-www-form-urlencoded",
    }
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

def get_outlook_event_list(start_window, end_window, auth_token):
    # This function takes a start and end window and builds a Dict of meetings indexed on the meeting start time.
    # Each dict Has the meeting subject
    # Future enhancement is to add the meeting Organizer
    # For multiple meetings in the same time slot, a list of subjects is created.

    # Define the Endpoint URL query.   As Outlook returns events in buckets of 10, there will be multiple links to iterate
    # And those are provided with each successive call.  NOTE: MSFT Graph doesn't always return the event list in Order,
    # this appears to happen when there are more than 10 events in the specified time period.

    outlook_event_url = OUTLOOK_CALENDAR_VIEW_URL + "&startdatetime=" + start_window + "&enddatetime=" + end_window
    next_graph_event_link = outlook_event_url
    earliest_meeting_time = time.parse_time(end_window).unix
    start_window_timestamp = time.parse_time(start_window).unix
    earliest_meeting_time_index = ""  # Return blank index if there are no meetings in the list.

    OUTLOOK_EVENT_HEADERS = {
        "Authorization": auth_token,
    }

    # Need an (empty) list to create a Dict of lists for the meeting times.
    meeting_list_bytime = {
    }

    # Initialize meeting stats counts.  MSFT Graph returns Outlook events in buckets of 10 or less, need counters to track outside of each bucket scan loop
    total_event_num = 0
    actual_meeting_count = 0
    total_meeting_duration = 0
    total_big_meeting_duration = 0

    # Iterate over the meeting buckets.   So far, my calendar fits into 3-4 buckets for a week.   Default is to allow 10 buckets max (for now)
    # It's hard to imagine that someone could have more than 100 events in a 24 hour period (for this application), however
    # This application can provide incorrect data in that case (simply raise the number of buckets if that happens often

    for x in range(NUMBER_OF_FETCH_ITERATIONS):
        # Get the first Batch of events

        # Also, MSFT generated "Focus Time" shows as 1 attendee, where as MF + Rachel entered morning prep, coding/training shows up as 0 attendees.   Hm.....may need to specifically filter on "Focus Time", dont count as a meeting.
        # Same for "meetings" with Zero attendees.

        CalendarQuery = http.get(next_graph_event_link, headers = OUTLOOK_EVENT_HEADERS)
        if CalendarQuery.status_code != 200:
            fail("Outlook Calendar View Request failed with status:", CalendarQuery.json())

        meeting_num = 0

        for meeting_count in CalendarQuery.json()["value"]:
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

            # Filter out cancelled meetings and also all day events (these tend to be vacations, etc).
            # Build a list of meetings, indexed by the meeting time.
            # For multiple events happening at the same time slot, create a list of meetings at that time.

            if not is_cancelled:
                if meeting_duration < 86400:
                    conflict_meeting = meeting_list_bytime.get(start_time)
                    if conflict_meeting:
                        meeting_list_bytime[start_time].append(meeting)
                    else:
                        new_meeting_list = [meeting]
                        meeting_list_bytime.update({start_time: new_meeting_list})

                    meeting_start_timestamp = time.parse_time(start_time).unix
                    if (meeting_start_timestamp < earliest_meeting_time) and (meeting_start_timestamp > start_window_timestamp):  # track the earliest meeting index in
                        earliest_meeting_time = meeting_start_timestamp
                        earliest_meeting_time_index = start_time

            meeting_num = meeting_num + 1

        # MSFT GRAPH only dumps 10 events at a time.   Must check for the existence of "@odata.nextLink" and keep looping until there is no more "next" link.
        # The next link must be fed into a GET command, just like the initial GET (requires the header with access token)
        # Note the .json().get method which protects against the null Index condition (no more links), else get a run time error with no .get when there is no next link.

        next_graph_event_link = CalendarQuery.json().get("@odata.nextLink")

        if DEBUG_ON:
            print("Next Link %s" % next_graph_event_link)

        # When there are no more links, we are done

        if not next_graph_event_link:
            break

    # Note - the index only makes sense when there are meetings in the list.

    return meeting_list_bytime, earliest_meeting_time_index

def render_calendar(cal_date, cal_meeting_txt, cal_meeting_time):
    return render.Root(
        child = render.Stack(
            children = [
                render.Image(src = CAL_ICON),
                render.Column(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Text("", font = "tom-thumb"),
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Row(
                                main_align = "center",
                                expanded = True,
                                children = [
                                    render.Text(cal_date),
                                ],
                            ),
                        ),
                        render.Padding(
                            pad = (0, 3, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        align = "center",
                                        child = render.Text(cal_meeting_txt, color = Yellow),
                                    ),
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(cal_meeting_time, color = Green, font = "CG-pixel-3x5-mono"),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

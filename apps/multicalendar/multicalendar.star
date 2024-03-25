"""
Name: Multi-Calendar
Summary: Next event from calendars
Description: Displays next event from multiple Google calendars.
Author: Logan Deal
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# TODO POTENTIAL UPDATES:
# get calendar list resource colorId
# only approved events option
# get user address from user parameter
# get time to event location from Google Maps API for walking
# get time to event location from Google Maps API for biking
# subtract time to get to location from event time
# display as time to leave

DEFAULT_TIMEZONE = "America/Chicago"
EVENTS_LIST_URL_BEFORE_ID = "https://www.googleapis.com/calendar/v3/calendars/"
EVENTS_LIST_URL_AFTER_ID = "/events?orderBy=startTime&singleEvents=true"
CALENDAR_LIST_URL = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
UNICODE_OFFSET = 65
GOOGLE_OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token"

CALENDAR_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAALCAYAAACtWacbAAAAAXNSR0IArs4c6QAAAE9JREFUKFNjZGBgYJgzZ87/lJQURlw0I0xRYEMHw/qGCgZ0GqSZ8a2Myv8aX1eGls27GXDRYEUg0/ABxv///xOn6OjRowzW1tYMuOghaxIAD/ltSOskB+YAAAAASUVORK5CYII=")

CLIENT_SECRET = secret.decrypt("AV6+xWcEUtvL1+jIiE+eprfRp98mLjsZ19nosT6wTv859RMYTpPyA2DILVbPaJCtxkbzxIvZIaksYBK09Sl/ItrTGgnXDcR1kt+QmPXkfD6bugGqt5bZqNQbS+JZrZGNi3N/Oknhkh+rodhCVK/RaGKHjAMq3jDn20u+e8GMyTuque7yEG6rRJM=") or ""
CLIENT_ID_DEFAULT = "623568824303-taeuq67dau3l64br2sei1b0blhi0pttp.apps.googleusercontent.com"
CLIENT_ID = secret.decrypt("AV6+xWcE/N5NgV4x2EHaFoRtqRrH0sepZJNIAI9arNKtdBTkj2bNU8a1+LY2M9cEKzCeXuLVq4SaXHQbTJDWBVchyZILX2ZFATpGX0p+hD3PG4pGdckcz9jZuXahp0DHPcdGu1VdBuZphhBsJrsyUy4SgCjTc5khb659X5O9+i15GkDWneMhk6HGKjP/qUVidJQGt/7PdN6STX4Ok874nNWEOBAGf2hL8EwGVmUk") or CLIENT_ID_DEFAULT

def get_24h_window(timezone):
    current_timezone = timezone or DEFAULT_TIMEZONE
    now = time.now().in_location(current_timezone)
    now_plus_24 = now + (time.hour * 24)
    return (now, now_plus_24)

def to_iso(time):
    return time.format("2006-01-02T15:04:05Z07:00")

def split_calendar_ids(calendars_string):
    if not calendars_string:
        return []
    return calendars_string.split(",")

def get_user_calendars(token):
    response = http.get(
        url = CALENDAR_LIST_URL,
        ttl_seconds = 300,
        headers = {
            "Authorization": "Bearer " + token,
            "Accept": "application/json",
        },
    )
    json = response.json()
    if response.status_code != 200:
        print(json)
        return "Error getting calendar list"

    # request successful
    calendars = json["items"]
    calendar_ids = [calendar["id"] for calendar in calendars]
    print("found " + str(len(calendar_ids)) + " user calendars")
    return calendar_ids

def get_earliest_events_from_calendars(calendars, window_24h, token):
    earliest_list = []
    i = 0
    for calendar_id in calendars:
        url = EVENTS_LIST_URL_BEFORE_ID + humanize.url_encode(calendar_id) + EVENTS_LIST_URL_AFTER_ID + "&timeMin=" + humanize.url_encode(to_iso(window_24h[0])) + "&timeMax=" + humanize.url_encode(to_iso(window_24h[1])) + "&eventTypes=default"
        response = http.get(
            url = url,
            ttl_seconds = 300,
            headers = {
                "Authorization": "Bearer " + token,
                "Accept": "application/json",
            },
        )
        json = response.json()
        if response.status_code != 200:
            print(json)
            return ["Error", response.status_code, calendar_id]
            # fail("Google Calendar events list request failed with status", response.status_code, "for calendar id", calendar_id)

        # request successful
        # ignore all-day events
        non_all_day_events = []
        for event in json["items"]:
            if "dateTime" in event["start"] and "dateTime" in event["end"]:
                non_all_day_events.append(event)
        if len(non_all_day_events) == 0:
            continue

        # add earliest event(s) to earliest_list
        if len(non_all_day_events) > 0:
            non_all_day_events[0]["start"]["dateTime"] = non_all_day_events[0]["start"]["dateTime"] + "_" + chr(UNICODE_OFFSET + i)
            non_all_day_events[0]["calendarName"] = json["summary"]
            earliest_list.append(non_all_day_events[0])
        if len(non_all_day_events) > 1:
            non_all_day_events[1]["start"]["dateTime"] = non_all_day_events[1]["start"]["dateTime"] + "_" + chr(UNICODE_OFFSET + i)
            non_all_day_events[1]["calendarName"] = json["summary"]
            earliest_list.append(non_all_day_events[1])
        i += 1
    return earliest_list

def get_start_time(event):
    return event["start"]["dateTime"]

def get_half_of_event_time_difference(event, timezone):
    start = time.parse_time(event["start"]["dateTime"][:-2])
    end = time.parse_time(event["end"]["dateTime"])
    duration = end - start
    start_time_plus_half = start + (duration / 2)
    current_timezone = timezone or DEFAULT_TIMEZONE
    now = time.now().in_location(current_timezone)
    return now - start_time_plus_half

def get_status_time(event, timezone):
    current_timezone = timezone or DEFAULT_TIMEZONE
    now = time.now().in_location(current_timezone)
    print("NOW", now)

    # today_start = time.time(year=now.year, month=now.month, day=now.day).in_location(current_timezone)
    today_start = now - (time.hour * now.hour) - (time.minute * now.minute) - (time.second * now.second) - (time.nanosecond * now.nanosecond)
    print("TODAY", today_start)

    # get timezone time
    tomorrow_start = today_start + (time.hour * 24)
    print("TMRW", tomorrow_start)

    # check if event is tomorrow
    event_start = time.parse_time(event["start"]["dateTime"][:-2])
    print("EVENT", event_start)

    # check if event is in one hour
    one_hour_ahead = now + time.hour
    time_difference = one_hour_ahead - event_start
    if time_difference.hours > 0 and time_difference.hours < 1:
        return "In " + str(event_start - now).split("m")[0] + "m"
    time_difference = event_start - tomorrow_start
    if time_difference.hours >= 0:
        return "Tomorrow"

    # check if event is today before event
    time_difference = event_start - now
    if time_difference.hours > 0:
        return "Today"
    return "Now"

# take first two and then sort it
def get_next_event(calendars, token, window_24h, timezone):
    earliest_list = get_earliest_events_from_calendars(calendars, window_24h, token)
    if len(earliest_list) == 0:
        return None
    if earliest_list[0] == "Error":
        # request unsuccessful
        id_string = ""
        if len(earliest_list[2]) < 5:
            id_string = str(earliest_list[2])
        else:
            id_string = str(earliest_list[2][:4]) + "..."
        if earliest_list[1] == 404:
            # 404 error
            return {"error": "Error: Calendar id " + id_string + " not found"}
        return {"error": "Error: Google Calendar returned " + str(earliest_list[1]) + " on id " + id_string}
    earliest_list = sorted(earliest_list, key = get_start_time)
    time_difference = get_half_of_event_time_difference(earliest_list[0], timezone)
    if time_difference.hours > 0:  # if past half of current event, then it is considered "done"
        if len(earliest_list) == 1:
            return None

        # return next soonest event
        earliest_list[1]["statusTime"] = get_status_time(earliest_list[1], timezone)
        return earliest_list[1]

    # return next soonest event
    earliest_list[0]["statusTime"] = get_status_time(earliest_list[0], timezone)
    return earliest_list[0]

def convert_to_12_hour(time_string):
    hours, minutes = time_string.split(":")
    hours = int(hours)
    minutes = int(minutes)
    if minutes < 10:
        minutes_string = "0" + str(minutes)
    else:
        minutes_string = str(minutes)
    if hours == 0:
        return "12:" + minutes_string + "AM"
    elif hours < 12:
        return str(hours) + ":" + minutes_string + "AM"
    elif hours == 12:
        return "12:" + minutes_string + "PM"
    else:
        return str(hours - 12) + ":" + minutes_string + "PM"

def get_access_token(refresh_token):
    token = ""
    if refresh_token:
        token = cache.get(refresh_token) or ""
        if not token:
            # token expired
            client_secret = CLIENT_SECRET or cache.get("client_secret") or ""
            print("refreshing token...")
            res = http.post(
                url = GOOGLE_OAUTH_TOKEN_URL,
                headers = {
                    "Content-type": "application/x-www-form-urlencoded",
                },
                body = "client_id=" + CLIENT_ID + "&grant_type=refresh_token" + "&client_secret=" + client_secret + "&refresh_token=" + refresh_token,
            )
            if res.status_code != 200:
                fail("Token request failed with status code: %d - %s" % (res.status_code, res.body()))

            print("refreshed token")

            token_params = res.json()
            token = token_params.get("access_token", "")
            expires_in = token_params.get("expires_in", "")
            cache.set(refresh_token, token, ttl_seconds = int(expires_in - 30))
    return token

def main(config):
    cache.set("client_secret", CLIENT_SECRET or config.get("client_secret") or "")
    refresh_token = config.get("auth", "")

    # Force refresh during development
    if config.get("force_refresh") == "true":
        cache.set(refresh_token, "")
    token = get_access_token(refresh_token)
    if token:
        window_24h = get_24h_window(config.get("timezone"))
        calendars = split_calendar_ids(config.get("calendar_ids"))
        if len(calendars) < 1:
            calendars = get_user_calendars(token)
        next_event = get_next_event(calendars, token, window_24h, config.get("timezone"))
        if next_event and "error" in next_event:
            error_message = next_event.get("error")
            return render.Root(
                child = render.WrappedText(error_message),
            )
        if not next_event:
            return render.Root(
                child = render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = CALENDAR_ICON, width = 9, height = 11),
                            render.Padding(
                                pad = (1, 0, 0, 0),
                                child = render.WrappedText(
                                    content = "No events in the next 24 hours!",
                                    color = "FF8FF1",
                                ),
                            ),
                        ],
                    ),
                ),
            )
        time_of_event = (((next_event["start"]["dateTime"][:-2].split("T"))[1]).split("-"))[0][:-3]
        military_time = config.get("time_type")
        if military_time != "true":
            time_of_event = convert_to_12_hour(time_of_event)
        return render.Root(
            delay = 100,
            child = render.Padding(
                pad = (1, 0, 0, 0),
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "left",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "left",
                            cross_align = "center",
                            children = [
                                render.Image(src = CALENDAR_ICON, width = 9, height = 11),
                                render.Padding(
                                    pad = (1, 2, 0, 0),
                                    child = render.Marquee(
                                        width = 52,
                                        child = render.Text(
                                            content = next_event["statusTime"],
                                            color = "FF8FF1",
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        render.Marquee(
                            width = 62,
                            child = render.Text(next_event["summary"]),
                        ),
                        render.Text(
                            content = time_of_event,
                            color = "FFE823",
                        ),
                    ],
                ),
            ),
        )
    return render.Root(
        child = render.WrappedText("Please log in to Google"),
    )

def oauth_handler(params):
    params = json.decode(params)
    client_secret = CLIENT_SECRET or cache.get("client_secret") or ""
    res = http.post(
        url = GOOGLE_OAUTH_TOKEN_URL,
        headers = {
            "Content-type": "application/x-www-form-urlencoded",
        },
        body = "code=" + params["code"] + "&client_id=" + params["client_id"] + "&redirect_uri=" + params["redirect_uri"] + "&grant_type=" + params["grant_type"] + "&client_secret=" + client_secret,
    )
    if res.status_code != 200:
        fail("Token request failed with status code: %d - %s" % (res.status_code, res.body()))

    token_params = res.json()
    token = token_params.get("access_token", "")
    refresh_token = token_params.get("refresh_token", "")
    expires_in = token_params.get("expires_in", "")
    cache.set(refresh_token, token, ttl_seconds = int(expires_in - 30))

    return refresh_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "time_type",
                name = "24-hour time",
                desc = "Enable 24-hour time.",
                icon = "clock",
                default = False,
            ),
            schema.Text(
                id = "calendar_ids",
                name = "Calendar IDs",
                desc = "Comma delimited list of Google Calendar IDs (id1,id2,id3...) Defaults to all calendars",
                icon = "calendar",
                default = "",
            ),
            schema.OAuth2(
                id = "auth",
                name = "Google",
                desc = "Connect your Google account.",
                icon = "google",
                handler = oauth_handler,
                client_id = CLIENT_ID + "&access_type=offline",
                authorization_endpoint = "https://accounts.google.com/o/oauth2/auth",
                scopes = [
                    "https://www.googleapis.com/auth/calendar.events.readonly",
                    "https://www.googleapis.com/auth/calendar.readonly",
                ],
            ),
        ],
    )

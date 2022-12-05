"""
Applet: Office Status
Summary: Show coworkers your status
Description: Show coworkers whether you're free, busy, or remote.
Author: Brian Bell
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

# Set basic schema defaults
DEFAULT_NAME = "Jane Smith"
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/Chicago"
}
"""
TTL_SECONDS = 30

# Values for local server
DEVELOPER_MSFT_CLIENT_ID = "REPLACE_ON_LOCAL"
DEVELOPER_MSFT_CLIENT_SECRET = "REPLACE_ON_LOCAL"

# Values for Tidbyt server
ENCRYPTED_MSFT_CLIENT_ID = "AV6+xWcEEXuYe3pTryNhDHEtNSvhVh5AzuB80JlncWy6vIj/rgonoeEGOXIzDClOEJkL0RAWAKCFRpSglnBCRa0G3ABIpSSA/zXdCSugEoqA4zDfEBxTh78LvvZ6r0pBfoUj1eHRYxH1PTSbKKKBdPg7mdtyC5lfsMyAYYPyqLq6XX0sGBR4f7IR"
ENCRYPTED_MSFT_CLIENT_SECRET = "AV6+xWcESGhLr279hd21f9Zt1YQ4CUEeNMJ+obZE+PENXR6PbXAeO0ZMrz3QQ422C1ZFUBpmOqspjwfRf1WBzqL5BbDxOSPLWpVuakjDnRTdxZCJfQYNR5tpZj3QYvdZeImhrHLpPgWRIPxkjFezKXTHglX/Jdvry401sMaFgNmhc+N4racVgDIC7NU8fQ=="

# Set globals for MSFT authentication
MSFT_TENANT_ID = "common"
MSFT_CLIENT_ID = secret.decrypt(ENCRYPTED_MSFT_CLIENT_ID) or DEVELOPER_MSFT_CLIENT_ID
MSFT_CLIENT_SECRET = secret.decrypt(ENCRYPTED_MSFT_CLIENT_SECRET) or DEVELOPER_MSFT_CLIENT_SECRET
MSFT_AUTH_ENDPOINT = ("https://login.microsoftonline.com/" + MSFT_TENANT_ID + "/oauth2/v2.0/authorize")
MSFT_TOKEN_ENDPOINT = ("https://login.microsoftonline.com/" + MSFT_TENANT_ID + "/oauth2/v2.0/token")

# Set globals for MSFT calendar view endpoint
MSFT_CALENDAR_VIEW_URL = "https://graph.microsoft.com/v1.0/me/calendarview"
MAX_MSFT_EVENT_FETCH_WEEK = 100
MSFT_BUCKET_SIZE = 10
NUMBER_OF_MSFT_FETCH_ITERATIONS = int(MAX_MSFT_EVENT_FETCH_WEEK / MSFT_BUCKET_SIZE)

# Values for local server
DEVELOPER_WEBEX_CLIENT_ID = "REPLACE_ON_LOCAL"
DEVELOPER_WEBEX_CLIENT_SECRET = "REPLACE_ON_LOCAL"

# Values for Tidbyt server
ENCRYPTED_WEBEX_CLIENT_ID = "AV6+xWcEo0OJA8UWuJWzG3SKr1yzOF98lUceQ3941XZ/inLXZcZwKqowtwTkZ0Te3GqhpcMCiOaHFmww3ZfbcbvKz1uBuOO2Kcwics2c6VOZLXWePYyE553apGLnqhNV/7DM/0s/cjB7GdsC/ip9rqxhVBc4Zc3v0lbFU4FPKLrBCZ7NLOKkPKmUQu0bEtC+wcPxf6Q+AtUCF+Om04rk2Bkxc2cS8aY="
ENCRYPTED_WEBEX_CLIENT_SECRET = "AV6+xWcE0orcfJj4wNNbdOQu2ws+0qzBbRL0QIe3r84+kVYaO8NBR7CiH5iArJwcigKHzHoJnGe1PH69S4Z0kjto82zMfKZOn0ehkpuTCNt1QbXNG4TZgIcKEbkMnUa5sLZ9c+hW5UQ6lt0mbBve/bf7fJYf+X7Wa6gEGnFrqoK1lXuJmzBjwBJfw34kjlFJrITT2eDwsJJd1ZK8uHi+3CI1lhwAOw=="

# Set globals for webex authentication
WEBEX_CLIENT_ID = secret.decrypt(ENCRYPTED_WEBEX_CLIENT_ID) or DEVELOPER_WEBEX_CLIENT_ID
WEBEX_CLIENT_SECRET = secret.decrypt(ENCRYPTED_WEBEX_CLIENT_SECRET) or DEVELOPER_WEBEX_CLIENT_SECRET
WEBEX_AUTH_ENDPOINT = "https://webexapis.com/v1/authorize"
WEBEX_TOKEN_ENDPOINT = "https://webexapis.com/v1/access_token"

# Set globals for webex personal details endpoint
WEBEX_PERSONAL_DETAILS_URL = "https://webexapis.com/v1/people/me"

STATUS_MAP = {
    "away": {
        "color": "#FF00FF",
        "schedule_prefix": "For ",
        "status_label": "away",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAALCAYAAABGbhwYAAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAvElEQVQYlWXQMUoDARCF4c/NWiaNKASRgI02WwRM2MLCYg/gAWz1FoqV18gB
UlhYZo+QHEDcckUsE7CNFs7Csjsw8M+8x/AY+lXjs7scdOYXJPhGhrIR0o4xwyv2uG0L
Scd4GKZ9cK9GWOEXpxgHl6FJcB/hP3AQ/BX8HvMDbPGEGywxjV7G7hHbFD+4wwQFFpGx
wA7X4ZFHzhnWOMExNpiHlg/8PxiecYQhrnCOM7yhbr+niuuXuAiuGvEP/lMlte6HL6QA
AAAASUVORK5CYII=
""",
    },
    "busy": {
        "color": "#FF0000",
        "schedule_prefix": "For ",
        "status_label": "busy",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAh0lEQVQYlX3QOw7CQAyE4S8SFyCUlHApaioINAn3oQJulJRQQBluwKPAUdCK
MNLfjMdrr+m1Qo1LUGMt0QFP7DAPKjxw7EIFXpik3cijtoE2XhpSiXuGG6ZYYJmE9rHW
dfRlZsGg2lj83+iW/jP5j9A4atvOOPqcosIsKMM7pd0FGpyDRpwF3ljQIMhNRxrbAAAA
AElFTkSuQmCC
""",
    },
    "free": {
        "color": "#00FF00",
        "schedule_prefix": "For ",
        "status_label": "free",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAb0lEQVQYlYXOsQnCUBAG4C8khQMIGccJsoCNSFrLLCPWlklhJ7hDLDNIOovY
XOAhD3PNcT8fP8f2XDFtoQ4LHv/QJdBtDWoUP6gNdE/DD8bkPgYaUlRixgn7aO7xRJP7
5xwtC145UMZ+Y4cKhxz8Al5ZEuTs2wZwAAAAAElFTkSuQmCC
""",
    },
    "offline": {
        "color": "#808080",
        "schedule_prefix": "Until Later",
        "status_label": "offline",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAo0lEQVQYlW3QOQpCQRAE0Ic3cDmA4BX0AF7FTL5LoFfwJG6hNzAVTAyEL5gY
aeYBDFwCe/DzsaGha6qmpqf4VR85DtE5MqVa4oUpOmhjgidWSZThjXrgORYx14IbwB3j
gvseuwIehsat4AZHbAu4gWulvCw26MaO8EjEHaOSeIZzzL30dPpM7Y97NbhhOlj5RjFB
C03fXJ9Yl29nOOESfRKxwAds1CbJl+J/zQAAAABJRU5ErkJggg==
""",
    },
    "remote": {
        "color": "#0000FF",
        "schedule_prefix": "For ",
        "status_label": "remote",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
    },
    "remote_busy": {
        "color": "#0000FF",
        "schedule_prefix": "Busy for ",
        "status_label": "remote",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
    },
    "remote_free": {
        "color": "#0000FF",
        "schedule_prefix": "Free for ",
        "status_label": "remote",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
    },
    "unknown": {
        "color": "#FFFF00",
        "schedule_prefix": None,
        "status_label": "unknown",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAt0lEQVQYlV3QP0pDYRAE8B9ptHiFghYBOw8gXsAD2EggRcADhPhio0fwBF4g
jeRPn2skpIiaImCnlXYpI7GZh+EtLDvLzH7MN/xXD+/p18xSrYb4RRtNnKGFLSaV6A47
HOMKH1jjAkW4Pnyjm6MFnvEUAdzgB75wUrPyEmGR/bMRsNsTDXCNc2xwCg0c4HZP2MQ0
XqGDQ4mg+gws8RZ8FO6+emWUeB5xmX5IPOOafyVWmGMW3K/IP3NkKS2ii0XRAAAAAElF
TkSuQmCC
""",
    },
}

def main(config):
    name = config.str("name", DEFAULT_NAME)
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    animations = config.bool("animations", False)

    # Retrieve MSFT API access token, returns None if user is not logged in
    msft_access_token = refresh_msft_access_token(config)
    if (msft_access_token != None):
        calendar_app_status = get_msft_status(msft_access_token, timezone)
    else:
        calendar_app_status = None

    # Retrieve Webex API access token, returns None if user is not logged in
    webex_access_token = refresh_webex_access_token(config)
    if (webex_access_token != None):
        messaging_app_status = get_webex_status(webex_access_token)
    else:
        messaging_app_status = None

    availability = get_availability(calendar_app_status, messaging_app_status)
    status = STATUS_MAP[availability["status"]]["status_label"].upper()
    color = STATUS_MAP[availability["status"]]["color"]
    image = base64.decode(STATUS_MAP[availability["status"]]["image"])
    schedule = get_schedule(availability, timezone)

    if not animations:
        return render.Root(
            child = render.Row(
                children = [
                    render.Box(
                        color = color,
                        width = 10,
                        child = render.Image(src = image, width = 10),
                    ),
                    render.Padding(
                        pad = (1, 2, 0, 1),
                        child = render.Column(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Marquee(
                                    child = render.Text(
                                        content = name + " is",
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                                render.Text(
                                    content = status.upper(),
                                    font = "6x13",
                                ),
                                render.Marquee(
                                    child = render.Text(
                                        content = schedule,
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Stack(
                children = [
                    # Left side color indicator
                    animation.Transformation(
                        child = render.Box(
                            color = color,
                            width = 10,
                            child = render.Image(src = image, width = 10),
                        ),
                        duration = 282,
                        delay = 0,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(-64, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.16,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.80,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-64, 0)],
                            ),
                        ],
                    ),
                    # Name row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = name + " is",
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 34)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.10,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.81,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 2)],
                            ),
                        ],
                    ),
                    # Status row
                    animation.Transformation(
                        child = render.Text(
                            content = status.upper(),
                            font = "6x13",
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 42)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.17,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.83,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 10)],
                            ),
                        ],
                    ),
                    # Schedule row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = schedule,
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        wait_for_child = True,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 57)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.20,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.85,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 25)],
                            ),
                        ],
                    ),
                ],
            ),
        )

def refresh_msft_access_token(config):
    # Use refresh token to collect access token
    msft_refresh_token = config.get("msft_auth")

    if msft_refresh_token:
        msft_access_token = cache.get(msft_refresh_token)
    else:
        return None

    if msft_access_token:
        return msft_access_token
    else:
        headers = {
            "Content-type": "application/x-www-form-urlencoded",
        }
        body = (
            "client_id=" + MSFT_CLIENT_ID +
            "&scope=offline_access%20Calendars.read" +
            "&refresh_token=" + msft_refresh_token +
            "&grant_type=refresh_token" +
            "&client_secret=" + MSFT_CLIENT_SECRET
        )
        response = http.post(url = MSFT_TOKEN_ENDPOINT, headers = headers, body = body)

        if response.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (response.status_code, response.body()))

        response_json = response.json()
        cache.set(
            response_json["refresh_token"],
            response_json["access_token"],
            ttl_seconds = int(response_json["expires_in"] - 30),
        )
        return response_json["access_token"]

def get_msft_events(msft_access_token, timezone):
    # Calls MSFT calendar view api
    # Returns all busy, out of office, or working elsewhere events
    # From the user's default outlook calendar for the day
    msft_events_cached = cache.get(msft_access_token + "_msft_events_cached")
    if msft_events_cached != None:
        return json.decode(msft_events_cached)
    else:
        current_time = time.now().in_location(timezone)
        current_date = current_time.format("2006-01-02T")
        current_timezone = current_time.format("Z07:00")
        msft_start_date_time = current_date + "00:00:00" + current_timezone
        msft_end_date_time = (
            time.parse_time(current_date, "2006-01-02T", timezone) +
            time.parse_duration("24h")
        ).format("2006-01-02T15:04:05Z07:00")
        url = MSFT_CALENDAR_VIEW_URL
        headers = {
            "Authorization": "Bearer " + msft_access_token,
        }
        params = {
            "startdatetime": msft_start_date_time,
            "enddatetime": msft_end_date_time,
            "$select": "showAs, start, end, isAllDay",
            "$filter": "(showAs eq 'busy' or showAs eq 'oof' or " +
                       "showAs eq 'workingElsewhere') and isCancelled eq false",
            "$orderby": "start/dateTime",
        }
        msft_events = []

        # Handling MSFT api paging
        for x in range(NUMBER_OF_MSFT_FETCH_ITERATIONS):
            response = http.get(url = url, headers = headers, params = params)
            if response.status_code != 200:
                fail("MSFT request failed with status:%d - %s" % (response.status_code, response.body()))

            for event in response.json()["value"]:
                msft_events.append(event)
            url = response.json().get("@odata.nextLink")
            if not url:
                break
        cache.set(
            msft_access_token + "_msft_events_cached",
            json.encode(msft_events),
            ttl_seconds = TTL_SECONDS,
        )
        return msft_events

def get_msft_current_events(msft_events, timezone):
    # Accepts a json array of MSFT events
    # Returns an array of events happening now
    msft_current_events = []
    for msft_event in msft_events:
        start_time = time.parse_time(msft_event["start"]["dateTime"], "2006-01-02T15:04:05")
        end_time = time.parse_time(msft_event["end"]["dateTime"], "2006-01-02T15:04:05")
        start_date = time.parse_time(start_time.format("2006-01-02"), "2006-01-02", timezone)
        end_date = time.parse_time(end_time.format("2006-01-02"), "2006-01-02", timezone)
        if (
            (
                msft_event["isAllDay"] == False and
                start_time <= time.now().in_location("UTC") and
                end_time >= time.now().in_location("UTC")
            ) or (
                msft_event["isAllDay"] == True and
                start_date <= time.now().in_location(timezone) and
                end_date >= time.now().in_location(timezone)
            )
        ):
            msft_current_events.append(msft_event)
    if (msft_current_events != []):
        return msft_current_events
    else:
        return None

def sort_msft_event_by_end_date(msft_event):
    # Defines end date as sort key
    return msft_event["end"]["dateTime"]

def get_msft_latest_event_by_show_as(msft_events, show_as):
    # Accepts a json array of MSFT events
    # Returns latest event for the provided show as value
    if (msft_events != None):
        msft_events_sorted = sorted(
            msft_events,
            key = sort_msft_event_by_end_date,
            reverse = False,
        )
        latest_msft_event = None
        for msft_event in msft_events_sorted:
            if (msft_event["showAs"] == show_as and latest_msft_event == None):
                latest_msft_event = msft_event
            elif (
                msft_event["showAs"] == show_as and
                msft_event["end"]["dateTime"] > latest_msft_event["end"]["dateTime"] and
                (
                    msft_event["isAllDay"] == True or
                    (
                        msft_event["isAllDay"] == False and
                        latest_msft_event["isAllDay"] == False
                    )
                )
            ):
                latest_msft_event = msft_event
        return latest_msft_event

def sort_msft_event_by_start_date(msft_event):
    # Defines start date as sort key
    return msft_event["start"]["dateTime"]

def get_msft_next_event(msft_events):
    # Accepts a json array of MSFT events
    # Returns the next busy or out of office event
    msft_events_sorted = sorted(msft_events, key = sort_msft_event_by_start_date)
    for msft_event in msft_events_sorted:
        if (
            time.parse_time(
                msft_event["start"]["dateTime"],
                "2006-01-02T15:04:05",
            ) >= time.now().in_location("UTC") and
            msft_event["showAs"] in ("busy", "oof")
        ):
            return msft_event

def get_msft_status(msft_access_token, timezone):
    # Determines a user's status based on MSFT events returned
    msft_events = get_msft_events(msft_access_token, timezone)
    msft_current_events = get_msft_current_events(msft_events, timezone)
    msft_oof_event = get_msft_latest_event_by_show_as(msft_current_events, "oof")
    msft_busy_event = get_msft_latest_event_by_show_as(msft_current_events, "busy")
    msft_wfh_event = get_msft_latest_event_by_show_as(msft_current_events, "workingElsewhere")
    msft_next_event = get_msft_next_event(msft_events)
    if (msft_oof_event != None):
        return {
            "isAllDay": msft_oof_event["isAllDay"],
            "status": "away",
            "time": msft_oof_event["end"]["dateTime"],
        }
    elif (msft_wfh_event != None and msft_busy_event != None):
        return {
            "isAllDay": msft_busy_event["isAllDay"],
            "status": "remote_busy",
            "time": msft_busy_event["end"]["dateTime"],
        }
    elif (msft_wfh_event != None and msft_next_event != None):
        return {
            "isAllDay": msft_next_event["isAllDay"],
            "status": "remote_free",
            "time": msft_next_event["start"]["dateTime"],
        }
    elif (msft_wfh_event != None):
        return {
            "isAllDay": msft_wfh_event["isAllDay"],
            "status": "remote",
            "time": None,
        }
    elif (msft_busy_event != None):
        return {
            "isAllDay": msft_busy_event["isAllDay"],
            "status": "busy",
            "time": msft_busy_event["end"]["dateTime"],
        }
    elif (msft_next_event != None):
        return {
            "isAllDay": msft_next_event["isAllDay"],
            "status": "free",
            "time": msft_next_event["start"]["dateTime"],
        }
    else:
        return {
            "isAllDay": None,
            "status": "free",
            "time": None,
        }

def refresh_webex_access_token(config):
    # Use refresh token to collect access token
    webex_refresh_token = config.get("webex_auth")

    if webex_refresh_token:
        webex_access_token = cache.get(webex_refresh_token)
    else:
        return None

    if webex_access_token:
        return cache.get(webex_refresh_token)
    else:
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
        }
        params = {
            "grant_type": "refresh_token",
            "client_id": WEBEX_CLIENT_ID,
            "client_secret": WEBEX_CLIENT_SECRET,
            "refresh_token": webex_refresh_token,
        }
        response = http.post(WEBEX_TOKEN_ENDPOINT, headers = headers, params = params)

        if response.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (response.status_code, response.body()))

        response_json = response.json()
        cache.set(
            response_json["refresh_token"],
            response_json["access_token"],
            ttl_seconds = int(response_json["expires_in"] - 30),
        )
        return response_json["access_token"]

def get_webex_details(webex_access_token):
    # Calls Webex personal details api
    # Returns an object with details about the user
    webex_too_many_requests = cache.get(webex_access_token + "_webex_too_many_requests")
    if webex_too_many_requests != None:
        return None

    webex_details_cached = cache.get(webex_access_token + "_webex_details_cached")
    if webex_details_cached != None:
        return json.decode(webex_details_cached)
    else:
        headers = {
            "Authorization": "Bearer " + webex_access_token,
        }
        response = http.get(WEBEX_PERSONAL_DETAILS_URL, headers = headers)

        # Set a cache key if API response that there have been too many requests
        if response.status_code == 429:
            cache.set(
                webex_access_token + "_webex_too_many_requests",
                True,
                ttl_seconds = int(response.headers["Retry-After"] + 30),
            )
            return None
        elif response.status_code != 200:
            fail("Webex request failed with status:%d - %s" % (response.status_code, response.body()))

        response_json = response.json()
        cache.set(
            webex_access_token + "_webex_details_cached",
            json.encode(response_json),
            ttl_seconds = TTL_SECONDS,
        )
        return response_json

def get_webex_status(webex_access_token):
    # Determines the user's status based on webex details
    webex_details = get_webex_details(webex_access_token)
    status = webex_details["status"]
    if (status == "OutOfOffice"):
        return "away"
    if (status == "active"):
        return "free"
    elif (status in ("call", "DoNotDisturb", "meeting", "presenting")):
        return "busy"
    elif (status == "inactive"):
        return "offline"
    else:
        return "unknown"

def get_availability(calendar_app_status, messaging_app_status):
    # Determines availability based on calendar and messaging status
    if (calendar_app_status == None):
        if (messaging_app_status != None):
            return {
                "isAllDay": None,
                "status": messaging_app_status,
                "time": None,
            }
        else:
            return {
                "isAllDay": None,
                "status": "unknown",
                "time": None,
            }
    elif (calendar_app_status["status"] == "away" or messaging_app_status == "away"):
        return {
            "isAllDay": calendar_app_status["isAllDay"],
            "status": "away",
            "time": calendar_app_status["time"],
        }
    elif (calendar_app_status["status"] == "remote_busy"):
        return {
            "isAllDay": calendar_app_status["isAllDay"],
            "status": "remote_busy",
            "time": calendar_app_status["time"],
        }
    elif (calendar_app_status["status"] == "remote_free" or calendar_app_status["status"] == "remote"):
        if (messaging_app_status == "busy"):
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote",
                "time": None,
            }
        else:
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote_free",
                "time": calendar_app_status["time"],
            }
    elif (calendar_app_status["status"] == "busy"):
        return {
            "isAllDay": calendar_app_status["isAllDay"],
            "status": "busy",
            "time": calendar_app_status["time"],
        }
    elif (calendar_app_status["status"] == "free"):
        if (messaging_app_status == "busy"):
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "busy",
                "time": None,
            }
        elif (messaging_app_status == "offline"):
            return {
                "isAllDay": None,
                "status": "offline",
                "time": None,
            }
        elif (messaging_app_status == "free"):
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "free",
                "time": calendar_app_status["time"],
            }
        else:
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "free",
                "time": calendar_app_status["time"],
            }
    else:
        return {
            "isAllDay": None,
            "status": "unknown",
            "time": None,
        }

def get_schedule(availability, timezone):
    # Accepts a json object representing the user's availability
    # Returns a string to display the user's schedule
    if (availability["time"] != None):
        if (availability["isAllDay"] == False):
            relative_time = humanize.relative_time(
                time.now().in_location("UTC"),
                time.parse_time(
                    availability["time"],
                    "2006-01-02T15:04:05",
                ),
            )
            relative_time = re.sub("(minutes|minute)", "min", relative_time)
            relative_time = re.sub("(seconds|second)", "sec", relative_time)
            return (STATUS_MAP[availability["status"]]["schedule_prefix"] + relative_time)
        elif (
            time.parse_time(availability["time"], "2006-01-02T15:04:05").format("2006-01-02") !=
            (time.now().in_location(timezone) + time.parse_duration("24h")).format("2006-01-02")
        ):
            relative_time = humanize.relative_time(
                time.now().in_location("UTC"),
                time.parse_time(
                    availability["time"],
                    "2006-01-02T15:04:05",
                ) + time.parse_duration("24h"),
            )
            return (STATUS_MAP[availability["status"]]["schedule_prefix"] + relative_time)
        elif (availability["status"] == "remote_busy"):
            return "Busy until tmrw"
        else:
            return "Until tmrw"
    else:
        return "Until later"

def msft_oauth_handler(params):
    # This handler is invoked once the user selects the "Authorize my Outlook Acccount" from the Mobile app
    # It passes Params from a successful user Auth, including the Code that must be exchanged for a Refresh token
    params = json.decode(params)
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    body = (
        "client_id=" + params["client_id"] +
        "&scope=offline_access%20Calendars.read" +
        "&code=" + params["code"] +
        "&redirect_uri=" + params["redirect_uri"] +
        "&grant_type=authorization_code" +
        "&client_secret=" + MSFT_CLIENT_SECRET  # Provide runtime a default secret
    )
    response = http.post(url = MSFT_TOKEN_ENDPOINT, headers = headers, body = body)

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    response_json = response.json()
    cache.set(
        response_json["refresh_token"],
        response_json["access_token"],
        ttl_seconds = int(response_json["expires_in"] - 30),
    )
    return response_json["refresh_token"]

def webex_oauth_handler(params):
    # This handler is invoked once the user selects the "Authorize your Webex Teams Account" from the Mobile app
    # It passes Params from a successful user Auth, including the Code that must be exchanged for a Refresh token
    params = json.decode(params)
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
    }
    params = {
        "grant_type": "authorization_code",
        "client_id": params["client_id"],
        "client_secret": WEBEX_CLIENT_SECRET,
        "code": params["code"],
        "redirect_uri": params["redirect_uri"],
    }
    response = http.post(url = WEBEX_TOKEN_ENDPOINT, headers = headers, params = params)

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    response_json = response.json()
    cache.set(
        response_json["refresh_token"],
        response_json["access_token"],
        ttl_seconds = int(response_json["expires_in"] - 30),
    )
    return response_json["refresh_token"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Enter the name you want to display.",
                icon = "user",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.OAuth2(
                id = "msft_auth",
                name = "Microsoft Outlook",
                desc = "Authorize your Microsoft Outlook Calendar",
                icon = "windows",
                handler = msft_oauth_handler,
                client_id = MSFT_CLIENT_ID,
                authorization_endpoint = MSFT_AUTH_ENDPOINT,
                scopes = [
                    "offline_access",
                    "Calendars.read",
                ],
            ),
            schema.OAuth2(
                id = "webex_auth",
                name = "Webex Teams",
                desc = "Authorize your Webex Teams Account",
                icon = "message",
                handler = webex_oauth_handler,
                client_id = WEBEX_CLIENT_ID,
                authorization_endpoint = WEBEX_AUTH_ENDPOINT,
                scopes = [
                    "spark:people_read",
                ],
            ),
            schema.Toggle(
                id = "animations",
                name = "Show Animations",
                desc = "Turn on entry and exit animations.",
                icon = "arrowsRotate",
                default = False,
            ),
        ],
    )

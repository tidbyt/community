"""
Applet: Office Status
Summary: Show coworkers your status
Description: Show coworkers whether you're free, busy, or remote.
Author: Brian Bell
"""

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

# Map available status options for display
STATUS_MAP = {
    "away": {
        "color": "#FF00FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAALCAYAAABGbhwYAAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAvElEQVQYlWXQMUoDARCF4c/NWiaNKASRgI02WwRM2MLCYg/gAWz1FoqV18gB
UlhYZo+QHEDcckUsE7CNFs7Csjsw8M+8x/AY+lXjs7scdOYXJPhGhrIR0o4xwyv2uG0L
Scd4GKZ9cK9GWOEXpxgHl6FJcB/hP3AQ/BX8HvMDbPGEGywxjV7G7hHbFD+4wwQFFpGx
wA7X4ZFHzhnWOMExNpiHlg/8PxiecYQhrnCOM7yhbr+niuuXuAiuGvEP/lMlte6HL6QA
AAAASUVORK5CYII=
""",
        "schedule_prefix": "For ",
        "status_label": "away",
    },
    "busy": {
        "color": "#FF0000",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAh0lEQVQYlX3QOw7CQAyE4S8SFyCUlHApaioINAn3oQJulJRQQBluwKPAUdCK
MNLfjMdrr+m1Qo1LUGMt0QFP7DAPKjxw7EIFXpik3cijtoE2XhpSiXuGG6ZYYJmE9rHW
dfRlZsGg2lj83+iW/jP5j9A4atvOOPqcosIsKMM7pd0FGpyDRpwF3ljQIMhNRxrbAAAA
AElFTkSuQmCC
""",
        "schedule_prefix": "For ",
        "status_label": "busy",
    },
    "free": {
        "color": "#00FF00",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAb0lEQVQYlYXOsQnCUBAG4C8khQMIGccJsoCNSFrLLCPWlklhJ7hDLDNIOovY
XOAhD3PNcT8fP8f2XDFtoQ4LHv/QJdBtDWoUP6gNdE/DD8bkPgYaUlRixgn7aO7xRJP7
5xwtC145UMZ+Y4cKhxz8Al5ZEuTs2wZwAAAAAElFTkSuQmCC
""",
        "schedule_prefix": "For ",
        "status_label": "free",
    },
    "offline": {
        "color": "#808080",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAo0lEQVQYlW3QOQpCQRAE0Ic3cDmA4BX0AF7FTL5LoFfwJG6hNzAVTAyEL5gY
aeYBDFwCe/DzsaGha6qmpqf4VR85DtE5MqVa4oUpOmhjgidWSZThjXrgORYx14IbwB3j
gvseuwIehsat4AZHbAu4gWulvCw26MaO8EjEHaOSeIZzzL30dPpM7Y97NbhhOlj5RjFB
C03fXJ9Yl29nOOESfRKxwAds1CbJl+J/zQAAAABJRU5ErkJggg==
""",
        "schedule_prefix": "Until Later",
        "status_label": "offline",
    },
    "remote": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
        "schedule_prefix": "For ",
        "status_label": "remote",
    },
    "remote_busy": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
        "schedule_prefix": "Busy for ",
        "status_label": "remote",
    },
    "remote_free": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAICAYAAADA+m62AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAkklEQVQYlV3PMQ4BURSF4W9iKjQkWtEpKel0YhESYwNKG7AOiU5FyT4UoqMT
ap2guWTMS15e7n/OuSeP/9PBNW432LvgMQ6YYYIn5sEqX9MswCgXHAT7bdzG0C5WoBXa
JsUNR5yQRnWCJc444P5N7uLNcAnDNK+lqKGJMvpY4IUe1qHVE5SwRxWN+PEbq6h8YPgB
eXwhnvIE4jgAAAAASUVORK5CYII=
""",
        "schedule_prefix": "Free for ",
        "status_label": "remote",
    },
    "unknown": {
        "color": "#FFFF00",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAC4jAAAuIwF4
pT92AAAAt0lEQVQYlV3QP0pDYRAE8B9ptHiFghYBOw8gXsAD2EggRcADhPhio0fwBF4g
jeRPn2skpIiaImCnlXYpI7GZh+EtLDvLzH7MN/xXD+/p18xSrYb4RRtNnKGFLSaV6A47
HOMKH1jjAkW4Pnyjm6MFnvEUAdzgB75wUrPyEmGR/bMRsNsTDXCNc2xwCg0c4HZP2MQ0
XqGDQ4mg+gws8RZ8FO6+emWUeB5xmX5IPOOafyVWmGMW3K/IP3NkKS2ii0XRAAAAAElF
TkSuQmCC
""",
        "schedule_prefix": None,
        "status_label": "unknown",
    },
}

# Except for Tenant ID - MSFT "common" Tenant is used to enable the App to access data from all Enterprise Tenants and/or Personal Outlook Accounts
# When running non-server mode we pass the Tenant ID via config to test with a specific Enterprise Tenant
GRAPH_TENANT_ID_DEFAULT = "common"

# Default (invalid) client ID and Secrets to keep the run time environment happy when running in Debug Mode
GRAPH_CLIENT_ID_DEFAULT = "123456"
GRAPH_CLIENT_SECRET_DEFAULT = "78910"

# Hash Strings to encrypt/store secrets required by MSFT Graph API access. These ultimately get replaced with Tidbyt Hash when the
# App is placed into the production environment. Application folder name is "officestatus". These (hashed) secrets are tied to
# the common tenant version of the Web App (Tidbyt_Ocal)
GRAPH_CLIENT_ID_HASH = "AV6+xWcEEXuYe3pTryNhDHEtNSvhVh5AzuB80JlncWy6vIj/rgonoeEGOXIzDClOEJkL0RAWAKCFRpSglnBCRa0G3ABIpSSA/zXdCSugEoqA4zDfEBxTh78LvvZ6r0pBfoUj1eHRYxH1PTSbKKKBdPg7mdtyC5lfsMyAYYPyqLq6XX0sGBR4f7IR"
GRAPH_CLIENT_SECRET_HASH = "AV6+xWcESGhLr279hd21f9Zt1YQ4CUEeNMJ+obZE+PENXR6PbXAeO0ZMrz3QQ422C1ZFUBpmOqspjwfRf1WBzqL5BbDxOSPLWpVuakjDnRTdxZCJfQYNR5tpZj3QYvdZeImhrHLpPgWRIPxkjFezKXTHglX/Jdvry401sMaFgNmhc+N4racVgDIC7NU8fQ=="

# MSFT Graph uses 3 secrets to operate. There is the usual Client Secret and Client ID, but Graph uses the Tenant ID as part of
# The endpoint URL. For public usage, the Tenant ID is set to "Common"
# Secrets are hardcoded here for debug with Pixlet "Serve" mode, then replaced with Tidbyt Secrets for production code

# Common Tenant (will encrypt these as the production values)
#GRAPH_CLIENT_ID = "GRAPH_CLIENT_ID"
#GRAPH_CLIENT_SECRET = "GRAPH_CLIENT_SECRET"

# Production Code - runs in the Tidbyt production environment
GRAPH_TENANT_ID = ""
GRAPH_CLIENT_ID = secret.decrypt(GRAPH_CLIENT_ID_HASH)
GRAPH_CLIENT_SECRET = secret.decrypt(GRAPH_CLIENT_SECRET_HASH)

# Graph auth related End points
GRAPH_AUTH_ENDPOINT = (
    "https://login.microsoftonline.com/" +
    (GRAPH_TENANT_ID or GRAPH_TENANT_ID_DEFAULT) +
    "/oauth2/v2.0/authorize"
)
GRAPH_TOKEN_ENDPOINT = (
    "https://login.microsoftonline.com/" +
    (GRAPH_TENANT_ID or GRAPH_TENANT_ID_DEFAULT) +
    "/oauth2/v2.0/token"
)

# Graph calendar view URL for retrieving calendar events and paging variables
GRAPH_CALENDAR_VIEW_URL = "https://graph.microsoft.com/v1.0/me/calendarview"
MAX_GRAPH_EVENT_FETCH_WEEK = 100
GRAPH_BUCKET_SIZE = 10
NUMBER_OF_GRAPH_FETCH_ITERATIONS = int(MAX_GRAPH_EVENT_FETCH_WEEK / GRAPH_BUCKET_SIZE)

# Default (invalid) client ID and Secrets to keep the run time Env happy when running in Debug Mode
WEBEX_CLIENT_ID_DEFAULT = "123456"
WEBEX_CLIENT_SECRET_DEFAULT = "78910"

# Hash Strings to encrypt/store secrets required for Webex API access. These ultimately get replaced with Tidbyt Hash when the
# App is placed into the production environment. Application folder name is "officestatus". These (hashed) secrets are tied to
# the common tenant version of the Web App (Tidbyt_Ocal)
WEBEX_CLIENT_ID_HASH = "AV6+xWcEo0OJA8UWuJWzG3SKr1yzOF98lUceQ3941XZ/inLXZcZwKqowtwTkZ0Te3GqhpcMCiOaHFmww3ZfbcbvKz1uBuOO2Kcwics2c6VOZLXWePYyE553apGLnqhNV/7DM/0s/cjB7GdsC/ip9rqxhVBc4Zc3v0lbFU4FPKLrBCZ7NLOKkPKmUQu0bEtC+wcPxf6Q+AtUCF+Om04rk2Bkxc2cS8aY="
WEBEX_CLIENT_SECRET_HASH = "AV6+xWcE0orcfJj4wNNbdOQu2ws+0qzBbRL0QIe3r84+kVYaO8NBR7CiH5iArJwcigKHzHoJnGe1PH69S4Z0kjto82zMfKZOn0ehkpuTCNt1QbXNG4TZgIcKEbkMnUa5sLZ9c+hW5UQ6lt0mbBve/bf7fJYf+X7Wa6gEGnFrqoK1lXuJmzBjwBJfw34kjlFJrITT2eDwsJJd1ZK8uHi+3CI1lhwAOw=="

# Credentials are hardcoded here for debug with Pixlet "Serve" mode, then replaced with Tidbyt Secrets for production code
#WEBEX_CLIENT_ID = "WEBEX_CLIENT_ID"
#WEBEX_CLIENT_SECRET = "WEBEX_CLIENT_SECRET"

# Credentials to be decrypted for use in production code
WEBEX_CLIENT_ID = secret.decrypt(WEBEX_CLIENT_ID_HASH)
WEBEX_CLIENT_SECRET = secret.decrypt(WEBEX_CLIENT_SECRET_HASH)

# Webex related end points
WEBEX_AUTH_ENDPOINT = "https://webexapis.com/v1/authorize"
WEBEX_TOKEN_ENDPOINT = "https://webexapis.com/v1/access_token"

# Webex personal details for retrieving calendar events
WEBEX_URL = "https://webexapis.com/v1/people/me"

# Basic schema defaults
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

def refreshGraphAccessToken(config):
    # Use refresh token to collect access token
    graph_refresh_token = config.get("graph_auth")

    if graph_refresh_token:
        graph_access_token = cache.get(graph_refresh_token)
    else:
        return None

    if graph_access_token:
        return graph_access_token
    else:
        headers = {
            "Content-type": "application/x-www-form-urlencoded",
        }
        body = (
            "client_id=" + (GRAPH_CLIENT_ID or GRAPH_CLIENT_ID_DEFAULT) +
            "&scope=offline_access%20Calendars.read" +
            "&refresh_token=" + graph_refresh_token +
            "&grant_type=refresh_token" +
            "&client_secret=" + (GRAPH_CLIENT_SECRET or GRAPH_CLIENT_SECRET_DEFAULT)
        )
        response = http.post(url = GRAPH_TOKEN_ENDPOINT, headers = headers, body = body)

        if response.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (response.status_code, response.body()))

        response_json = response.json()
        cache.set(
            response_json["refresh_token"],
            response_json["access_token"],
            ttl_seconds = int(response_json["expires_in"] - 30),
        )
        return response_json["access_token"]

def getGraphEvents(graph_access_token, timezone):
    # Calls graph calendar view api
    # Returns all busy, out of office, or working elsewhere events
    # From the user's default outlook calendar for the day
    graph_events_cached = cache.get(graph_access_token + "_graph_events_cached")
    if graph_events_cached != None:
        return json.decode(graph_events_cached)
    else:
        current_time = time.now().in_location(timezone)
        current_date = current_time.format("2006-01-02T")
        current_timezone = current_time.format("Z07:00")
        graph_start_date_time = current_date + "00:00:00" + current_timezone
        graph_end_date_time = (
            time.parse_time(current_date, "2006-01-02T", timezone) +
            time.parse_duration("24h")
        ).format("2006-01-02T15:04:05Z07:00")
        url = GRAPH_CALENDAR_VIEW_URL
        headers = {
            "Authorization": "Bearer " + graph_access_token,
        }
        params = {
            "startdatetime": graph_start_date_time,
            "enddatetime": graph_end_date_time,
            "$select": "showAs, start, end, isAllDay",
            "$filter": "(showAs eq 'busy' or showAs eq 'oof' or " +
                       "showAs eq 'workingElsewhere') and isCancelled eq false",
            "$orderby": "start/dateTime",
        }
        graph_events = []

        # Handling graph api paging
        for x in range(NUMBER_OF_GRAPH_FETCH_ITERATIONS):
            response = http.get(url = url, headers = headers, params = params)
            if response.status_code != 200:
                fail("Graph request failed with status:%d - %s" % (response.status_code, response.body()))

            for event in response.json()["value"]:
                graph_events.append(event)
            url = response.json().get("@odata.nextLink")
            if not url:
                break
        cache.set(
            graph_access_token + "_graph_events_cached",
            json.encode(graph_events),
            ttl_seconds = TTL_SECONDS,
        )
        return graph_events

def getGraphCurrentEvents(graph_events):
    # Accepts a json array of graph events
    # Returns an array of events happening now
    graph_current_events = []
    for graph_event in graph_events:
        if (
            (
                time.parse_time(
                    graph_event["start"]["dateTime"],
                    "2006-01-02T15:04:05",
                ) <= time.now().in_location("UTC") and
                time.parse_time(
                    graph_event["end"]["dateTime"],
                    "2006-01-02T15:04:05",
                ) >= time.now().in_location("UTC")
            ) or graph_event["isAllDay"] == True
        ):
            graph_current_events.append(graph_event)
    if (graph_current_events != []):
        return graph_current_events
    else:
        return None

def sortGraphEventByEndDate(graph_event):
    # Defines end date as sort key
    return graph_event["end"]["dateTime"]

def getGraphLatestEventByShowAs(graph_events, show_as):
    # Accepts a json array of graph events
    # Returns latest event for the provided show as value
    if (graph_events != None):
        graph_events_sorted = sorted(
            graph_events,
            key = sortGraphEventByEndDate,
            reverse = False,
        )
        latest_graph_event = None
        for graph_event in graph_events_sorted:
            if (graph_event["showAs"] == show_as and latest_graph_event == None):
                latest_graph_event = graph_event
            elif (
                graph_event["showAs"] == show_as and
                graph_event["end"]["dateTime"] > latest_graph_event["end"]["dateTime"] and
                (
                    graph_event["isAllDay"] == True or
                    (
                        graph_event["isAllDay"] == False and
                        latest_graph_event["isAllDay"] == False
                    )
                )
            ):
                latest_graph_event = graph_event
        return latest_graph_event

def sortGraphEventByStartDate(graph_event):
    # Defines start date as sort key
    return graph_event["start"]["dateTime"]

def getGraphNextEvent(graph_events):
    # Accepts a json array of graph events
    # Returns the next busy or out of office event
    graph_events_sorted = sorted(graph_events, key = sortGraphEventByStartDate)
    for graph_event in graph_events_sorted:
        if (
            time.parse_time(
                graph_event["start"]["dateTime"],
                "2006-01-02T15:04:05",
            ) >= time.now().in_location("UTC") and
            graph_event["showAs"] in ("busy", "oof")
        ):
            return graph_event

def getGraphStatus(graph_access_token, timezone):
    # Determines a user's status based on graph events returned
    graph_events = getGraphEvents(graph_access_token, timezone)
    graph_current_events = getGraphCurrentEvents(graph_events)
    graph_oof_event = getGraphLatestEventByShowAs(graph_current_events, "oof")
    graph_busy_event = getGraphLatestEventByShowAs(graph_current_events, "busy")
    graph_wfh_event = getGraphLatestEventByShowAs(graph_current_events, "workingElsewhere")
    graph_next_event = getGraphNextEvent(graph_events)
    if (graph_oof_event != None):
        return {
            "isAllDay": graph_oof_event["isAllDay"],
            "status": "away",
            "time": graph_oof_event["end"]["dateTime"],
        }
    elif (graph_wfh_event != None and graph_busy_event != None):
        return {
            "isAllDay": graph_busy_event["isAllDay"],
            "status": "remote_busy",
            "time": graph_busy_event["end"]["dateTime"],
        }
    elif (graph_wfh_event != None and graph_next_event != None):
        return {
            "isAllDay": graph_next_event["isAllDay"],
            "status": "remote_free",
            "time": graph_next_event["start"]["dateTime"],
        }
    elif (graph_wfh_event != None):
        return {
            "isAllDay": graph_wfh_event["isAllDay"],
            "status": "remote",
            "time": None,
        }
    elif (graph_busy_event != None):
        return {
            "isAllDay": graph_busy_event["isAllDay"],
            "status": "busy",
            "time": graph_busy_event["end"]["dateTime"],
        }
    elif (graph_next_event != None):
        return {
            "isAllDay": graph_next_event["isAllDay"],
            "status": "free",
            "time": graph_next_event["start"]["dateTime"],
        }
    else:
        return {
            "isAllDay": None,
            "status": "free",
            "time": None,
        }

def refreshWebexAccessToken(config):
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
            "client_id": (WEBEX_CLIENT_ID or WEBEX_CLIENT_ID_DEFAULT),
            "client_secret": (WEBEX_CLIENT_SECRET or WEBEX_CLIENT_SECRET_DEFAULT),
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

def getWebexDetails(webex_access_token):
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
        response = http.get(WEBEX_URL, headers = headers)

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

def getWebexStatus(webex_access_token):
    # Determines the user's status based on webex details
    webex_details = getWebexDetails(webex_access_token)
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

def getAvailability(calendar_app_status, messaging_app_status):
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

def getSchedule(availability, timezone):
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
        else:
            return "Until tomorrow"
    else:
        return "Until later"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]

    # Retrieve Graph API access token, returns None if user is not logged in
    graph_access_token = refreshGraphAccessToken(config)
    if (graph_access_token != None):
        calendar_app_status = getGraphStatus(graph_access_token, timezone)
    else:
        calendar_app_status = None

    # Retrieve Webex API access token, returns None if user is not logged in
    webex_access_token = refreshWebexAccessToken(config)
    if (webex_access_token != None):
        messaging_app_status = getWebexStatus(webex_access_token)
    else:
        messaging_app_status = None

    availability = getAvailability(calendar_app_status, messaging_app_status)
    status = STATUS_MAP[availability["status"]]["status_label"].upper()
    color = STATUS_MAP[availability["status"]]["color"]
    image = base64.decode(STATUS_MAP[availability["status"]]["image"])
    schedule = getSchedule(availability, timezone)

    return render.Root(
        delay = 125,
        child = render.Row(
            children = [
                render.Stack(
                    children = [
                        render.Column(
                            children = [
                                render.Box(
                                    color = color,
                                    width = 10,
                                ),
                            ],
                        ),
                        render.Column(
                            children = [
                                render.Box(
                                    child = render.Image(src = image),
                                    width = 10,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Padding(
                    child = render.Column(
                        expanded = True,
                        children = [
                            render.Marquee(
                                child = render.Text(
                                    content = name + " is",
                                    font = "tom-thumb",
                                ),
                                offset_start = 1,
                                offset_end = 52,
                                width = 52,
                            ),
                            render.Marquee(
                                child = render.Text(
                                    content = status.upper(),
                                    font = "6x13",
                                ),
                                offset_start = 1,
                                offset_end = 52,
                                width = 52,
                            ),
                            render.Marquee(
                                child = render.Text(
                                    content = schedule,
                                    font = "tom-thumb",
                                ),
                                offset_start = 1,
                                offset_end = 52,
                                width = 52,
                            ),
                        ],
                        main_align = "space_evenly",
                    ),
                    pad = (2, 0, 0, 0),
                ),
            ],
        ),
    )

def graph_oauth_handler(params):
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
        "&client_secret=" + (GRAPH_CLIENT_SECRET or GRAPH_CLIENT_SECRET_DEFAULT)  # Provide runtime a default secret
    )
    response = http.post(url = GRAPH_TOKEN_ENDPOINT, headers = headers, body = body)

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
        "client_secret": WEBEX_CLIENT_SECRET or WEBEX_CLIENT_SECRET_DEFAULT,  # Provide runtime a default secret
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
                id = "graph_auth",
                name = "Microsoft Outlook",
                desc = "Authorize your Microsoft Outlook Calendar",
                icon = "windows",
                handler = graph_oauth_handler,
                client_id = (GRAPH_CLIENT_ID or GRAPH_CLIENT_ID_DEFAULT),
                authorization_endpoint = GRAPH_AUTH_ENDPOINT,
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
                client_id = (WEBEX_CLIENT_ID or WEBEX_CLIENT_ID_DEFAULT),
                authorization_endpoint = WEBEX_AUTH_ENDPOINT,
                scopes = [
                    "spark:people_read",
                ],
            ),
        ],
    )

"""
Applet: Office Status
Summary: Show coworkers your status
Description: Show coworkers whether you're free, busy, remote, or away.
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
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAKBJREFUGJV1
0DFqQlEQheHvicWrUwnZQ7qs4AWxepkmW8gWXIHbsBSsMnEb7iOkCQQ3kBSOeHnowMCZ
Mz/MubeLCG1l5idExGvrzybQE0aMpW+DeLijr2BmPmLd7NblnasyvuEHf5P+xTs62N8A
pv2hxAk7bJrlprxTzQb0FWHZgMvyegzd5R8z8xkHLCr+N8aIOMK8eeULvrCteVXXjvAP
+Ck3lqEEP0YAAAAASUVORK5CYII=
""",
        "schedule_prefix": "Back in ",
        "status_label": "away",
    },
    "busy": {
        "color": "#FF0000",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAH9JREFUGJWV
0DEKwlAURNGTYCUux10YyduGpbVYScDK1m18sDaxdzkRK0ELf0pDHLjdZd5jiogAKaUa
Wyx9c8cpIi4gi0e8f9AMZfWINFDBbYLYFuixwBNnvPKPM2wwR1/6I92E01dYTxBXwzzN
iHSICGXecpebOzwyLaqI2MMHXGdIlbVXopsAAAAASUVORK5CYII=
""",
        "schedule_prefix": "Availalble in ",
        "status_label": "busy",
    },
    "free": {
        "color": "#00FF00",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAALCAQAAADsZ9STAAAACXBIWXMAAABUAAAAVAGj
rcQVAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAGFJREFUCNdj
CGDAhAxECTIUMxxGF2pk+M9Qz8AgwsAEFWBk6AEKVQJZDI8ZNjCwAxlMDNMY/jEUgKUZ
PBi+MWxn4GGYBxTKgVvE4MTwheE1wx+GOBTbGWwYrjCEkupOEAQAqIIp6pXUcRUAAAAA
SUVORK5CYII=
""",
        "schedule_prefix": "For ",
        "status_label": "free",
    },
    "offline": {
        "color": "#808080",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAQAAAAnOwc2AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAG1JREFUCNdV
yLENglAUQNGzjrMA4Y3iAHSGYCzcCGEJ4x5CNNHiWfjVmNucXCFozVarSROCYC+lh6eU
+kArpXRwLKqZC3tD0YmlcNAVXX/zYmPr/p5Tmemmc5ZGmu/8VAn6v7ULQlA7WSxGVQgv
DkVMZS6tEjAAAAAASUVORK5CYII=
""",
        "schedule_prefix": "Until Later",
        "status_label": "offline",
    },
    "remote": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAKCAQAAAA9B+e4AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAGhJREFUCB0F
wbEKAQEABuBPysRgspit5wE8xD/ZZKWMyuAdvIBy9yqSwa0GTyHZTrn4PhHh7BAiQmUb
wsjS2iCYevr6uehwVLppNRb09bzUNq7C2N5bEcLJTqkOVj5mCq0hd/PQ9TD5AwrCHGUf
Ol77AAAAAElFTkSuQmCC
""",
        "schedule_prefix": "For the next ",
        "status_label": "remote",
    },
    "remote_busy": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAKCAQAAAA9B+e4AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAGhJREFUCB0F
wbEKAQEABuBPysRgspit5wE8xD/ZZKWMyuAdvIBy9yqSwa0GTyHZTrn4PhHh7BAiQmUb
wsjS2iCYevr6uehwVLppNRb09bzUNq7C2N5bEcLJTqkOVj5mCq0hd/PQ9TD5AwrCHGUf
Ol77AAAAAElFTkSuQmCC
""",
        "schedule_prefix": "Available in ",
        "status_label": "remote",
    },
    "remote_free": {
        "color": "#0000FF",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAYAAAAKCAQAAAA9B+e4AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAGhJREFUCB0F
wbEKAQEABuBPysRgspit5wE8xD/ZZKWMyuAdvIBy9yqSwa0GTyHZTrn4PhHh7BAiQmUb
wsjS2iCYevr6uehwVLppNRb09bzUNq7C2N5bEcLJTqkOVj5mCq0hd/PQ9TD5AwrCHGUf
Ol77AAAAAElFTkSuQmCC
""",
        "schedule_prefix": "Available for ",
        "status_label": "remote",
    },
    "unknown": {
        "color": "#FFFF00",
        "image": """
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAQAAAAnOwc2AAAACXBIWXMAAABJAAAASQHj
iblMAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAHdJREFUCB0F
wb1NggEYgMEbw1HcAQhvZc8ObqAkVJZWOgo/GxiNYxgLPmof74xh6+Lm5mwzhuEgSZL9
YCv58eLgQ7LmItnZeXbnT04skm+/Ht1LriySvHpwlVw5S/LpS5IjG0nevEuyMuwlSfI0
jGHtZLE4Wo3xD+BMSfWYEqnuAAAAAElFTkSuQmCC
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
GRAPH_CLIENT_ID_HASH = """
GRAPH_CLIENT_ID_HASH
"""
GRAPH_CLIENT_SECRET_HASH = """
GRAPH_CLIENT_SECRET_HASH
"""

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
GRAPH_EVENTFETCH_AUTH_ENDPOINT = (
    "https://login.microsoftonline.com/" +
    (GRAPH_TENANT_ID or GRAPH_TENANT_ID_DEFAULT) +
    "/oauth2/v2.0/authorize"
)
GRAPH_EVENTFETCH_TOKEN_ENDPOINT = (
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
WEBEX_CLIENT_ID_HASH = """
WEBEX_CLIENT_ID_HASH
"""
WEBEX_CLIENT_SECRET_HASH = """
WEBEX_CLIENT_SECRET_HASH
"""

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
TTL_SECONDS = 60

def refreshGraphAccessToken(config):
    # Grab Secrets from Parameters if running in Render mode.   Hash functions will return null value if running locally
    # They only return value when running on Tidbyt Servers.
    if GRAPH_CLIENT_ID:
        graph_client_id = GRAPH_CLIENT_ID
    else:
        graph_client_id = config.get("graph_client_id")

    if GRAPH_CLIENT_SECRET:
        graph_client_secret = GRAPH_CLIENT_SECRET
    else:
        graph_client_secret = config.get("graph_client_secret")

    if GRAPH_TENANT_ID:
        graph_tenant_id = GRAPH_TENANT_ID
    else:
        graph_tenant_id = config.get("graph_tenant_id") or GRAPH_TENANT_ID_DEFAULT

    graph_token_endpoint = "https://login.microsoftonline.com/" + graph_tenant_id + "/oauth2/v2.0/token"

    # Refresh token comes from Auth Handler params when running in Production/Serve mode....from Conflig when running locally/Render
    graph_refresh_token = config.get("graph_auth") or config.get("graph_refresh_token")

    # Return none if the user is not authorized
    if not graph_refresh_token:
        return None
    else:
        graph_access_token = cache.get(graph_refresh_token)

    # In Production deployment, this redirect_uri should be replaced with Tidbyt callback uri
    if not graph_access_token:
        refresh_body = (
            "refresh_token=" + graph_refresh_token +
            "&redirect_uri=http://localhost/oauth-callback" +
            "&client_id=" + graph_client_id +
            "&client_secret=" + graph_client_secret +
            "&grant_type=refresh_token" +
            "&scope=offline_access%20Calendars.read"
        )
        refresh = http.post(graph_token_endpoint, body = refresh_body)

        if refresh.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (refresh.status_code, refresh.body()))

        return "Bearer {}".format(refresh.json()["access_token"])
        cache.set(graph_refresh_token, graph_access_token, ttl_seconds = int(refresh.json()["expires_in"] - 30))
    else:
        return cache.get(graph_refresh_token)

def getGraphEvents(config, graph_access_token):
    # Calls graph calendar view api
    # Returns all busy, out of office, or working elsewhere events
    # From the user's default outlook calendar for the day
    graph_events_cached = cache.get("graph_events_cached")
    if graph_events_cached != None:
        return json.decode(graph_events_cached)
    else:
        timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
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
            "Authorization": graph_access_token,
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
                fail("Graph request failed with status:", response.status_code)
            for event in response.json()["value"]:
                graph_events.append(event)
            url = response.json().get("@odata.nextLink")
            if not url:
                break
        cache.set(
            "graph_events_cached",
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

def getGraphLatestOofEvent(graph_events):
    # Accepts a json array of graph events
    # Returns the out of office event with the latest end date
    if (graph_events != None):
        graph_events_reverse_sorted = sorted(
            graph_events,
            key = sortGraphEventByEndDate,
            reverse = True,
        )
        for graph_event in graph_events_reverse_sorted:
            if (graph_event["showAs"]) == "oof":
                return graph_event

def getGraphLatestBusyEvent(graph_events):
    # Accepts a json array of graph events
    # Returns the busy event with the latest end date
    if (graph_events != None):
        graph_events_reverse_sorted = sorted(
            graph_events,
            key = sortGraphEventByEndDate,
            reverse = True,
        )
        for graph_event in graph_events_reverse_sorted:
            if (graph_event["showAs"]) == "busy":
                return graph_event

def getGraphLatestWfhEvent(graph_events):
    # Accepts a json array of graph events
    # Returns the working elsewhere event with the latest end date
    if (graph_events != None):
        graph_events_reverse_sorted = sorted(
            graph_events,
            key = sortGraphEventByEndDate,
            reverse = True,
        )
        for graph_event in graph_events_reverse_sorted:
            if (graph_event["showAs"]) == "workingElsewhere":
                return graph_event

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

def getGraphStatus(config, graph_access_token):
    # Determines a user's status based on graph events returned
    graph_events = getGraphEvents(config, graph_access_token)
    graph_current_events = getGraphCurrentEvents(graph_events)
    graph_oof_event = getGraphLatestOofEvent(graph_current_events)
    graph_busy_event = getGraphLatestBusyEvent(graph_current_events)
    graph_wfh_event = getGraphLatestWfhEvent(graph_current_events)
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
    # Accepts config
    # Returns a Webex access token
    if WEBEX_CLIENT_ID:
        webex_client_id = WEBEX_CLIENT_ID
    else:
        webex_client_id = config.get("webex_client_id")

    if WEBEX_CLIENT_SECRET:
        webex_client_secret = WEBEX_CLIENT_SECRET
    else:
        webex_client_secret = config.get("webex_client_secret")

    # Refresh token comes from oauth handler params when running in Production/Serve mode
    # Refresh token comes from config when running locally/Render
    webex_refresh_token = config.get("webex_auth") or config.get("webex_refresh_token")

    if not webex_refresh_token:
        return None
    else:
        webex_access_token = cache.get(webex_refresh_token)

    if not webex_access_token:
        params = {
            "grant_type": "refresh_token",
            "client_id": webex_client_id,
            "client_secret": webex_client_secret,
            "refresh_token": webex_refresh_token,
        }
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
        }
        refresh = http.post(WEBEX_TOKEN_ENDPOINT, params = params, headers = headers)

        if refresh.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (refresh.status_code, refresh.body()))

        return "Bearer {}".format(refresh.json()["access_token"])
        cache.set(webex_refresh_token, webex_access_token, ttl_seconds = int(refresh.json()["expires_in"] - 30))
    else:
        return cache.get(webex_refresh_token)

def getWebexDetails(webex_access_token):
    # Calls webex personal details api
    # Returns an object with details about the user
    webex_details_cached = cache.get("webex_details_cached")
    if webex_details_cached != None:
        return json.decode(webex_details_cached)
    else:
        headers = {
            "Authorization": webex_access_token,
        }
        response = http.get(WEBEX_URL, headers = headers)
        if response.status_code != 200:
            fail("Webex request failed with status:", response.status_code)
        response_json = response.json()
        cache.set(
            "webex_details_cached",
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
    if (calendar_app_status == None and messaging_app_status == None):
        return {
            "isAllDay": None,
            "status": "unknown",
            "time": None,
        }
    elif (calendar_app_status == None and messaging_app_status != None):
        return {
            "isAllDay": None,
            "status": messaging_app_status,
            "time": None,
        }
    elif (calendar_app_status != None and messaging_app_status == None):
        return {
            "isAllDay": calendar_app_status["isAllDay"],
            "status": calendar_app_status["status"],
            "time": calendar_app_status["time"],
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
    elif (calendar_app_status["status"] == "remote_free"):
        if (messaging_app_status == "busy"):
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote_busy",
                "time": calendar_app_status["time"],
            }
        else:
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote_free",
                "time": calendar_app_status["time"],
            }
    elif (calendar_app_status["status"] == "remote"):
        if (messaging_app_status == "busy"):
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote_busy",
                "time": calendar_app_status["time"],
            }
        else:
            return {
                "isAllDay": calendar_app_status["isAllDay"],
                "status": "remote",
                "time": calendar_app_status["time"],
            }
    elif (calendar_app_status["status"] == "busy" or messaging_app_status == "busy"):
        return {
            "isAllDay": calendar_app_status["isAllDay"],
            "status": "busy",
            "time": calendar_app_status["time"],
        }
    elif (messaging_app_status == "free"):
        return {
            "isAllDay": None,
            "status": "free",
            "time": calendar_app_status["time"],
        }
    elif (messaging_app_status == "offline"):
        return {
            "isAllDay": None,
            "status": "offline",
            "time": None,
        }
    else:
        return {
            "isAllDay": None,
            "status": "unknown",
            "time": None,
        }

def getSchedule(availability):
    # Accepts a json object representing the user's availability
    # Returns a string to display the user's schedule
    if (availability["time"] != None):
        if (
            (
                time.parse_time(
                    availability["time"],
                    "2006-01-02T15:04:05",
                ) != time.parse_time(
                    (
                        time.now().in_location("UTC") +
                        time.parse_duration("24h")
                    ).format("2006-01-02") +
                    "T00:00:00",
                    "2006-01-02T15:04:05",
                )
            ) and availability["isAllDay"] != True
        ):
            relative_time = humanize.relative_time(
                time.now(),
                time.parse_time(
                    availability["time"],
                    "2006-01-02T15:04:05",
                ),
            )
            relative_time = re.sub("(minutes|minute)", "min", relative_time)
            return (STATUS_MAP[availability["status"]]["schedule_prefix"] +
                    relative_time)
        else:
            return "Until tomorrow"
    else:
        return "Until later"

def main(config):
    name = config.str("name", DEFAULT_NAME)

    # Retrieve Graph API access token, returns None if user is not logged in
    graph_access_token = refreshGraphAccessToken(config)
    if (graph_access_token != None):
        calendar_app_status = getGraphStatus(config, graph_access_token)
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
    schedule = getSchedule(availability)

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
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    params = json.decode(params)
    body = (
        "grant_type=authorization_code" +
        "&client_id=" + params["client_id"] +
        "&client_secret=" + (GRAPH_CLIENT_SECRET or GRAPH_CLIENT_SECRET_DEFAULT) +  # Provide runtime a default secret
        "&code=" + params["code"] +
        "&scope=offline_access%20Calendars.read" +
        "&redirect_uri=" + params["redirect_uri"]
    )
    response = http.post(url = GRAPH_EVENTFETCH_TOKEN_ENDPOINT, headers = headers, body = body)

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    refresh_token = token_params["refresh_token"]
    cache.set(
        refresh_token,
        "Bearer " + token_params["access_token"],
        ttl_seconds = int(token_params["expires_in"] - 30),
    )
    return refresh_token

def webex_oauth_handler(params):
    # This handler is invoked once the user selects the "Authorize your Webex Teams Account" from the Mobile app
    # It passes Params from a successful user Auth, including the Code that must be exchanged for a Refresh token
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
    }
    params = json.decode(params)
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

    token_params = response.json()
    refresh_token = token_params["refresh_token"]
    cache.set(
        refresh_token,
        "Bearer " + token_params["access_token"],
        ttl_seconds = int(token_params["expires_in"] - 30),
    )
    return refresh_token

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
                authorization_endpoint = GRAPH_EVENTFETCH_AUTH_ENDPOINT,
                scopes = [
                    "offline_access%20Calendars.read",
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

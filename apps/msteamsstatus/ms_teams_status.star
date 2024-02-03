"""
Applet: MS Teams Status
Summary: Show your MS Teams status
Description: Show your presence and status message from Microsoft Teams on a Tidbyt display.
Author: schumatt
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEBUG_ON = False

M365PresenceAPIEndpoint = "https://graph.microsoft.com/beta/me/presence"
M365UserAPIEndpoint = "https://graph.microsoft.com/beta/me/profile"

defaultUserDisplayName = "Not Signed In"
defaultAvailability = "PresenceUnknown"
defaultActivity = "PresenceUnknown"
defaultStatusMessage = ""

devClientID = "1"
devClientSecret = "1"
defaultTenantID = "common"

prodClientIDHash = "AV6+xWcEmMNAAypNT+S8KqvF4S1iX/kYxlY74g7wRzPxETO/FwSLvbQvq+HA8Ba3MJNj17R4dWvQpdUVRyE7V8OdXSye6BZ6x0928zBg0XLKrxGcdaNc1Hu/vh2DyZvUN8f9UZfXxxjJjhQHoh8Fyck4D+8CobTmOZQyPYNC9oSlLAJNuVwu2j4K"
prodClientSecretHash = "AV6+xWcEREeHhZwZnwakqNh+IoMKwjJH2zrD81B5e5wb3COjbGjHBMFd9AV4Ss35KPhzTmuRaYkcQt2Yq5munUUhVrP5OB1l0eBa8VdMHPMwGhkKqVxnO2umUROamvf2M9KtsS+Ax4LMY+AfUb7mHZPvlfSDfU6k33HPwMUMW/gS8zYcqolYjgdNkMjaGA=="

TenantID = ""
prodClientID = secret.decrypt(prodClientIDHash)
prodClientSecret = secret.decrypt(prodClientSecretHash)

AuthEndpoint = "https://login.microsoftonline.com/" + (TenantID or defaultTenantID) + "/oauth2/v2.0/authorize"
TokenEndpoint = "https://login.microsoftonline.com/" + (TenantID or defaultTenantID) + "/oauth2/v2.0/token"

availabilityMap = {
    "Available": {
        "color": "#0f0",
        "label": "Available",
        "icon": "",
    },
    "AvailableIdle": {
        "color": "#ccc",
        "label": "Available - Idle",
        "icon": "",
    },
    "Away": {
        "color": "#ff0",
        "label": "Away",
        "icon": "",
    },
    "BeRightBack": {
        "color": "#ff0",
        "label": "Be Right Back",
        "icon": "",
    },
    "Busy": {
        "color": "#f00",
        "label": "Busy",
        "icon": "",
    },
    "BusyIdle": {
        "color": "#f00",
        "label": "Busy - Idle",
        "icon": "",
    },
    "DoNotDisturb": {
        "color": "#800000",
        "label": "Do Not Disturb",
        "icon": "",
    },
    "Offline": {
        "color": "#888",
        "label": "Offline",
        "icon": "",
    },
    "PresenceUnknown": {
        "color": "#0ff",
        "label": "Unknown",
        "icon": "",
    },
}
activityMap = {
    "Available": {
        "presence": "Available",
    },
    "Away": {
        "presence": "Away",
    },
    "BeRightBack": {
        "presence": "BeRightBack",
    },
    "Busy": {
        "presence": "Busy",
    },
    "DoNotDisturb": {
        "presence": "DoNotDisturb",
    },
    "InACall": {
        "presence": "Busy",
        "label": "In a Call",
        "color": "#f00",
    },
    "InAConferenceCall": {
        "presence": "Busy",
        "label": "In a Conference Call",
        "color": "#f00",
    },
    "Inactive": {
        "presence": "Offline",
    },
    "InAMeeting": {
        "presence": "Busy",
        "label": "In a Meeting",
    },
    "Offline": {
        "presence": "Offline",
    },
    "OffWork": {
        "presence": "Offline",
        "label": "Off Work",
    },
    "OutOfOffice": {
        "presence": "Offline",
        "label": "Out of Office",
        "color": "#cd00cd",
    },
    "PresenceUnknown": {
        "presence": "PresenceUnknown",
    },
    "Presenting": {
        "presence": "DoNotDisturb",
        "label": "Presenting",
    },
    "UrgentInterruptionsOnly": {
        "presence": "DoNotDisturb",
    },
}

def main(config):
    if DEBUG_ON:
        print("ENTERING main: " + str(config))

    #if prodClientID:
    #    RunningClientID = prodClientID
    #else:
    #    RunningClientID = config.get("client_id")

    #if prodClientSecret:
    #    RunningClientSecret = prodClientSecret
    #else:
    #    RunningClientSecret = config.get("client_secret")

    #if TenantID:
    #    RunningTenantID = TenantID
    #else:
    #    RunningTenantID = config.get("tenant_id") or defaultTenantID

    userDisplayName = defaultUserDisplayName
    availability = defaultAvailability
    activity = defaultActivity
    statusMessage = defaultStatusMessage
    isOutOfOffice = False

    msft_access_token = refresh_msft_access_token(config)
    if (msft_access_token != None):
        statusMessage = "Authenticated"
        # print("We have an access token! Proceed!")

    else:
        statusMessage = "Please authenticate to your Microsoft 365 account"
        return render_teams_status(userDisplayName, availability, defaultActivity, statusMessage, False)

    M365APIHeaders = {
        "Authorization": msft_access_token,
    }

    UserInfoQuery = http.get(M365UserAPIEndpoint, headers = M365APIHeaders)
    if UserInfoQuery.status_code != 200:
        #statusMessage = "Retrieve user information failed with error " +
        # print(UserInfoQuery.json())
        return render_teams_status("Error " + str(UserInfoQuery.status_code), "", "", UserInfoQuery.json()["error"]["code"] + " -- " + UserInfoQuery.json()["error"]["message"], False)
    else:
        userDisplayName = UserInfoQuery.json()["names"][0]["displayName"]

    UserPresenceQuery = http.get(M365PresenceAPIEndpoint, headers = M365APIHeaders)
    if UserPresenceQuery.status_code != 200:
        #statusMessage = "Retrieve user information failed with error " +
        # print(UserPresenceQuery.json())
        return render_teams_status("Error " + str(UserPresenceQuery.status_code), "", "", UserPresenceQuery.json()["error"]["code"] + " -- " + UserPresenceQuery.json()["error"]["message"], False)
    else:
        availability = UserPresenceQuery.json()["availability"]
        activity = UserPresenceQuery.json()["activity"]
        if UserPresenceQuery.json()["statusMessage"]:
            statusMessage = UserPresenceQuery.json()["statusMessage"]["message"]["content"]
        else:
            statusMessage = ""
        if UserPresenceQuery.json()["outOfOfficeSettings"]:
            isOutOfOffice = UserPresenceQuery.json()["outOfOfficeSettings"]["isOutOfOffice"]

    return render_teams_status(userDisplayName, availability, activity, statusMessage, isOutOfOffice)

def render_teams_status(userDisplayName, availability, activity, statusMessage, isOutOfOffice):
    if availability == "":
        availability = "PresenceUnknown"
    if activity == "":
        activity = "PresenceUnknown"

    if (activity in activityMap) and (availability in availabilityMap):
        if "label" in activityMap[activity]:
            statusLabel = activityMap[activity]["label"]
        else:
            statusLabel = availabilityMap[activityMap[activity]["presence"]]["label"]

        if "color" in activityMap[activity]:
            statusColor = activityMap[activity]["color"]
        else:
            statusColor = availabilityMap[activityMap[activity]["presence"]]["color"]

        #dotColor = availabilityMap[availability]["color"]
        dotColor = availabilityMap[activityMap[activity]["presence"]]["color"]
    else:
        statusLabel = "Invalid"
        statusColor = "#ff4f00"
        dotColor = "#ff4f00"
        if (activity not in activityMap):
            statusLabel = statusLabel + " Activity (" + activity + ")"
        if (availability not in availabilityMap):
            statusLabel = statusLabel + " Availability (" + availability + ")"

    if isOutOfOffice:
        dotColor = activityMap["OutOfOffice"]["color"]
        statusLabel = statusLabel + " / " + activityMap["OutOfOffice"]["label"]

    return render.Root(
        delay = 1,
        #max_age = 5,
        child = render.Row(
            children = [
                render.Padding(
                    child =
                        render.Box(
                            width = 5,
                            color = statusColor,
                        ),
                    pad = (0, 0, 1, 0),
                ),
                render.Column(
                    children = [
                        render.Marquee(
                            child = render.Text(
                                content = userDisplayName,
                            ),
                            width = 59,
                            offset_start = 59,
                            offset_end = 59,
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    child = render.Circle(
                                        diameter = 6,
                                        color = dotColor,
                                    ),
                                    pad = (0, 1, 1, 2),
                                    color = "#000",
                                ),
                                render.Marquee(
                                    width = 51,
                                    child = render.Text(
                                        content = statusLabel,
                                        color = statusColor,
                                    ),
                                    offset_start = 0,
                                ),
                            ],
                        ),
                        render.Marquee(
                            child = render.WrappedText(
                                content = statusMessage,
                                font = "CG-pixel-3x5-mono",
                                linespacing = 2,
                            ),
                            scroll_direction = "vertical",
                            height = 15,
                            align = "center",
                            offset_start = 0,
                        ),
                    ],
                ),
            ],
        ),
    )

def refresh_msft_access_token(config):
    if DEBUG_ON:
        print("ENTERING refresh_msft_access_token")

    # Use refresh token to collect access token
    msft_refresh_token = config.get("auth")
    #print(" - Check refresh token. Config.auth returned " + str(config.get("auth")))

    if msft_refresh_token:
        #print (" -- Attempt to retrieve cached access token for refresh token " + str(msft_refresh_token))
        msft_access_token = cache.get(msft_refresh_token)
        #print (" -- Retrieved cached access token: " + str(cache.get(msft_refresh_token)))

    else:
        #print(" -- Missing refresh token")
        #print("RETURNING refresh_msft_access_token: None")
        return None

    if msft_access_token:
        #print ("RETURNING refresh_msft_access_token: " + str(msft_access_token))
        return msft_access_token
    else:
        #print (" -- Missing access token. Obtain new.")
        headers = {
            "Content-type": "application/x-www-form-urlencoded",
        }
        body = (
            "client_id=" + (prodClientID or devClientID) +
            "&scope=offline_access%20User.read%20Presence.Read" +
            "&refresh_token=" + msft_refresh_token +
            "&grant_type=refresh_token" +
            "&client_secret=" + (prodClientSecret or devClientSecret)
        )
        response = http.post(url = TokenEndpoint, headers = headers, body = body)

        #print (" --- Obtain access token returned " + str(response.status_code))
        if response.status_code != 200:
            fail("Refresh of Access Token failed with Status Code: %d - %s" % (response.status_code, response.body()))

        response_json = response.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            response_json["refresh_token"],
            response_json["access_token"],
            ttl_seconds = int(response_json["expires_in"]) - 30,
        )

        #print (" -- Cached token for " + str(int(response_json["expires_in"] - 30)) + " seconds")
        #print ("RETURNING refresh_msft_access_token: " + response_json["access_token"])
        return response_json["access_token"]

def oauth_handler(params):
    if DEBUG_ON:
        print("ENTERING oauth_handler")

    params = json.decode(params)

    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    body = (
        "client_id=" + params["client_id"] +
        "&scope=offline_access%20User.read%20Presence.Read" +
        "&code=" + params["code"] +
        "&redirect_uri=" + params["redirect_uri"] +
        "&grant_type=authorization_code" +
        "&client_secret=" + (prodClientSecret or devClientSecret)  # Provide runtime a default secret
    )
    response = http.post(url = TokenEndpoint, headers = headers, body = body)

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    response_json = response.json()

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(
        response_json["refresh_token"],
        response_json["access_token"],
        ttl_seconds = int(response_json["expires_in"]) - 30,
    )
    if DEBUG_ON:
        print("RETURNING oauth_handler: " + str(response_json["refresh_token"]))

    return response_json["refresh_token"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Account",
                desc = "Connect your Microsoft 365 account",
                icon = "windows",
                handler = oauth_handler,
                client_id = (prodClientID or devClientID),
                authorization_endpoint = AuthEndpoint,
                scopes = [
                    "Presence.Read",
                    "User.Read",
                    "offline_access",
                ],
            ),
        ],
    )

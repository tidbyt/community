"""
Applet: Timeular Activity
Summary: Current timeular activity
Description: Tracks the ammount of time spent on the current Timeular activity.
Author: tommylin1212
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIMEULAR_LOGO = """
PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNzAuMyA0MCI+PHBhdGggZmlsbD0iIzg1ZiIgZD0iTTAgMTkuMkMwIDEyLjUgMCA5LjEgMS4zIDYuNmMxLjItMi4zIDMtNC4xIDUuMi01LjJDOS4xLjEgMTIuNC4xIDE5LjEuMWgxLjZjNi43IDAgMTAuMSAwIDEyLjYgMS4zIDIuMyAxLjIgNC4xIDMgNS4yIDUuMiAxLjMgMi42IDEuMyA1LjkgMS4zIDEyLjZ2MS42YzAgNi43IDAgMTAuMS0xLjMgMTIuNi0xLjIgMi4zLTMgNC4xLTUuMiA1LjItMi42IDEuMy01LjkgMS4zLTEyLjYgMS4zaC0xLjZjLTYuNyAwLTEwLjEgMC0xMi42LTEuMy0yLjMtMS4yLTQuMS0zLTUuMi01LjJDMCAzMC44IDAgMjcuNSAwIDIwLjh2LTEuNloiLz48cGF0aCBmaWxsPSIjZmZmIiBkPSJNMTMuNCAzMi41Yy0uMiAwLS40IDAtLjYtLjItLjQtLjItLjYtLjYtLjYtMVY4LjZjMC0uNC4yLS44LjYtMSAuNC0uMi44LS4yIDEuMiAwTDMzLjkgMTljLjQuMi42LjYuNiAxcy0uMi44LS42IDFMMTQgMzIuNGMtLjIuMS0uNC4yLS42LjJabS40LTIzLjF2MjEuMkwzMi40IDIwIDEzLjggOS40WiIvPjxwYXRoIGZpbGw9IiNmZmYiIGQ9Ik0yNS42IDMzLjNIMTQuNGMtMS4zIDAtMi41LS43LTMuMi0xLjhsLTUuNi05LjZjLS43LTEuMS0uNy0yLjYgMC0zLjdzNS42LTkuNiA1LjYtOS42Yy43LTEuMSAxLjktMS44IDMuMi0xLjhoMTEuMmMxLjMgMCAyLjUuNyAzLjIgMS44bDUuNiA5LjZjLjcgMS4xLjcgMi42IDAgMy43bC01LjYgOS42Yy0uNyAxLjEtMS45IDEuOC0zLjIgMS44Wk03LjggMTkuNGMtLjIuMy0uMi44IDAgMS4xbDUuNiA5LjZjLjIuMy42LjUuOS41aDExLjJjLjQgMCAuOC0uMiAxLS41bDUuNi05LjZjLjItLjMuMi0uOCAwLTEuMWwtNS42LTkuNmMtLjItLjMtLjYtLjUtMS0uNUgxNC4zYy0uNCAwLS44LjItLjkuNWwtNS42IDkuNloiLz48cGF0aCBmaWxsPSIjZmZmIiBkPSJNMTQuNCAzMi4zYy0uNSAwLS45LS4xLTEuNC0uNC0uOC0uNS0xLjMtMS40LTEuMy0yLjNWMTAuNGMwLTEgLjUtMS44IDEuMy0yLjMuOC0uNSAxLjktLjUgMi43IDBsMTYuOCA5LjZjLjkuNSAxLjQgMS40IDEuNCAyLjNzLS41IDEuOS0xLjQgMi4zbC0xNi44IDkuNmMtLjQuMi0uOS40LTEuMy40Wm0wLTIydjE5LjNoLjFMMzEuMyAyMGwtMTYuOC05LjdaIi8+PHBhdGggZmlsbD0iIzg1ZiIgZD0iTTU2IDI5LjNjLS43IDAtMS4zLS42LTEuMy0xLjNWMTMuM0g1MGMtLjcgMC0xLjMtLjYtMS4zLTEuM3MuNi0xLjMgMS4zLTEuM2gxMmMuNyAwIDEuMy42IDEuMyAxLjNzLS42IDEuMy0xLjMgMS4zaC00LjdWMjhjMCAuNy0uNiAxLjMtMS4zIDEuM1ptMTEgMGMtLjcgMC0xLjMtLjYtMS4zLTEuM1YxMmMwLS43LjYtMS4zIDEuMy0xLjNzMS4zLjYgMS4zIDEuM3YxNmMwIC43LS42IDEuMy0xLjMgMS4zWm0yMSAwYy0uNyAwLTEuMy0uNi0xLjMtMS4zVjE3LjVsLTQuNSA5Yy0uMS4zLS4zLjUtLjYuNy0uMiAwLS40LjEtLjYuMS0uMiAwLS40IDAtLjYtLjEtLjMtLjItLjUtLjQtLjYtLjdsLTQuNS05VjI4YzAgLjctLjYgMS4zLTEuMyAxLjNzLTEuMy0uNi0xLjMtMS4zVjEyYzAtLjYuNC0xLjEgMS0xLjMuNi0uMSAxLjIuMSAxLjUuN0w4MSAyMy4xbDUuOC0xMS43Yy4yLS41LjctLjcgMS4yLS43LjcgMCAxLjIuNiAxLjIgMS4zdjE2YzAgLjctLjYgMS4zLTEuMyAxLjNabTE2LS4ySDkzYy0uNyAwLTEuMy0uNi0xLjMtMS4zcy42LTEuMyAxLjMtMS4zaDExYy43IDAgMS4zLjYgMS4zIDEuM3MtLjYgMS4zLTEuMyAxLjNabS0yLTcuOGgtOWMtLjcgMC0xLjMtLjYtMS4zLTEuM3MuNi0xLjMgMS4zLTEuM2g5Yy43IDAgMS4zLjYgMS4zIDEuM3MtLjYgMS4zLTEuMyAxLjNabTItNy44SDkzYy0uNyAwLTEuMy0uNi0xLjMtMS4zcy42LTEuMyAxLjMtMS4zaDExYy43IDAgMS4zLjYgMS4zIDEuM3MtLjYgMS4zLTEuMyAxLjNabTExIDE2LjhjLTQgMC03LjMtMy4zLTcuMy03LjNWMTJjMC0uNy42LTEuMyAxLjMtMS4zczEuMy42IDEuMyAxLjN2MTFjMCAyLjYgMi4xIDQuNyA0LjcgNC43czQuNy0yLjEgNC43LTQuN1YxMmMwLS43LjYtMS4zIDEuMy0xLjNzMS4zLjYgMS4zIDEuM3YxMWMwIDQtMy4zIDcuMy03LjMgNy4zWm0yMC0xaC04Yy0uNyAwLTEuMy0uNi0xLjMtMS4zVjEyYzAtLjcuNi0xLjMgMS4zLTEuM3MxLjMuNiAxLjMgMS4zdjE0LjdoNi43Yy43IDAgMS4zLjYgMS4zIDEuM3MtLjYgMS4zLTEuMyAxLjNabTE4IDBjLS41IDAtMS0uMy0xLjItLjhMMTQ2IDE1LjJsLTUuOCAxMy4zYy0uMy43LTEuMSAxLTEuNy43LS43LS4zLTEtMS4xLS43LTEuN2w2LjktMTUuOWMuMS0uMy40LS42LjctLjguMiAwIC40IDAgLjUtLjEuMiAwIC40IDAgLjUuMS40LjIuNi40LjcuOGw2LjkgMTUuOWMuMy43IDAgMS40LS43IDEuNy0uMiAwLS4zLjEtLjUuMVptMTYgMGMtLjUgMC0xLjEtLjMtMS4yLS45bC0xLjctNWMtLjEtLjQtLjQtLjktLjctMS4yLS42LS42LTEuMy0uOS0yLjItLjloLTQuOVYyOGMwIC43LS42IDEuMy0xLjMgMS4zcy0xLjMtLjYtMS4zLTEuM1YxMmMwLS43LjYtMS4zIDEuMy0xLjNoOGMyLjkgMCA1LjMgMi40IDUuMyA1LjNzLTEuMSAzLjgtMi44IDQuN2MuNS42LjggMS4yIDEuMSAxLjlsMS43IDVjLjIuNy0uMSAxLjQtLjggMS42aC0uNFptLTUuOC0xMC42aDEuOGMxLjUgMCAyLjctMS4yIDIuNy0yLjdzLTEuMi0yLjctMi43LTIuN2gtNi43djUuNGg0LjlaIi8+PC9zdmc+
"""
TIMEULAR_LOGIN_URL = "https://api.timeular.com/api/v3/developer/sign-in"
TIMEULAR_ACTIVITIES_URL = "https://api.timeular.com/api/v3/tracking"
TIMEULAR_LIST_ALL_ACTIVITIES_URL = "https://api.timeular.com/api/v3/activities"

def print_error(error):
    """
    Prints an error message to the screen

    Args:
        error (str): Error message to print

    Returns:
        render.Root: Rendered error message
    """
    return render.Root(
        child = render.Box(
            render.Marquee(
                width = 64,
                child = render.Text(error),
                offset_start = 5,
                offset_end = 32,
            ),
        ),
    )

def authorize_timeular(timeular_api_key, timeular_api_secret):
    """
    Authorizes the Timeular API and returns the token

    Args:
        timeular_api_key (str): Timeular API Key
        timeular_api_secret (str): Timeular API Secret

    Returns:
        bool: True if authorized, False if not
        str: Error message if not authorized
    """
    timeular_auth = http.post(TIMEULAR_LOGIN_URL, json_body = {"apiKey": timeular_api_key, "apiSecret": timeular_api_secret}, headers = {"Content-Type": "application/json"})
    if not timeular_auth.status_code == 200:
        return False, timeular_auth.json()["message"]
    else:
        timeular_auth_json = timeular_auth.json()
        timeular_token = timeular_auth_json["token"]
        return True, timeular_token

def get_timeular_activities(timeular_token):
    """
    Gets the current Timeular activities

    Args:
        timeular_token (str): Timeular API Token

    Returns:
        bool: True if successful, False if not
        str: Error message if not successful
        dict: Timeular activities if successful
    """
    timeular_activities = http.get(TIMEULAR_ACTIVITIES_URL, headers = {"Authorization": "Bearer " + timeular_token}, ttl_seconds = 60)
    if not timeular_activities.status_code == 200:
        return False, timeular_activities.json()["message"]
    else:
        timeular_activities_json = timeular_activities.json()
        return True, timeular_activities_json

def get_timeular_activities_list(timeular_token):
    """
    Gets the current Timeular activities

    Args:
        timeular_token (str): Timeular API Token

    Returns:
        bool: True if successful, False if not
        str: Error message if not successful
        dict: Timeular activities if successful
    """
    timeular_activities_list = http.get(TIMEULAR_LIST_ALL_ACTIVITIES_URL, headers = {"Authorization": "Bearer " + timeular_token})
    if not timeular_activities_list.status_code == 200:
        return False, timeular_activities_list.json()["message"]
    else:
        timeular_activities_list_json = timeular_activities_list.json()
        return True, timeular_activities_list_json

def render_text_no_activity(config):
    """
    Renders the text for when there is no activity

    Returns:
        render.Root: Rendered text
    """
    if config.bool("active_only_when_tracking", False):  ## no activity, hide app
        return []
    else:
        return render.Root(
            child = render.Box(
                render.Row(
                    cross_align = "center",
                    main_align = "center",
                    children = [render.Marquee(width = 64, child = render.Text("Not tracking activity"))],
                    expanded = True,
                ),
            ),
        )

def build_timeular_current_activity(timeular_activities_json, timeular_activities_list_json):
    """
    Builds the current Timeular activity

    Args:
        timeular_activities_json (dict): Timeular activities
        timeular_activities_list_json (dict): Timeular activities list

    Returns:
        bool: True if successful, False if not
        str: Error message if not successful
        dict: Timeular activity if successful
    """
    if (timeular_activities_json["currentTracking"] == None):
        return False, "No activity"
    activity_id = timeular_activities_json["currentTracking"]["activityId"]
    activity_name = [item for item in timeular_activities_list_json["activities"] if item["id"] == activity_id][0]["name"]
    if activity_name == None:
        return False, "Error getting activity name"
    activity_color = [item for item in timeular_activities_list_json["activities"] if item["id"] == activity_id][0]["color"]
    if activity_color == None:
        return False, "Error getting activity color"
    activity_started_at = timeular_activities_json["currentTracking"]["startedAt"]
    return True, activity_name, activity_color, activity_started_at

def get_current_activity(timeular_activities_json):
    if (timeular_activities_json["currentTracking"] == None):
        return False, "No activity"
    else:
        return build_timeular_current_activity(timeular_activities_json)

def render_text_activity(config, activity_name, activity_color, parsed_time):
    """
    Renders the text for the current activity

    Args:
        activity_name (str): Activity name
        activity_color (str): Activity color
        parsed_time (dict): Parsed time

    Returns:
        render.Root: Rendered text
    """
    time_string = str(parsed_time["hours"]) + "H " + str(parsed_time["minutes"]) + "M"
    return render.Root(
        delay = 50,
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 2),
                        child = render.Image(
                            src = base64.decode(TIMEULAR_LOGO),
                            width = 41,
                        ),
                    ) if config.bool("display_logo", False) else None,
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(activity_name, color = activity_color),
                    ),
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Text(time_string, color = activity_color),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_parsed_time(activity_started_at, now):
    """
    Gets the parsed time

    Args:
        activity_started_at (str): Timeular activity started at
        now (time.Time): Current time

    Returns:
        dict: Parsed time
    """
    time_since_started = now - time.parse_time(activity_started_at)
    hours_int = int(time_since_started.hours)
    minutes_int = int(time_since_started.minutes - hours_int * 60)

    #only get first two digits of seconds
    seconds_int = int(str(time_since_started.seconds)[:2])
    parsed_time = {"hours": hours_int, "minutes": minutes_int, "seconds": seconds_int}
    return parsed_time

def main(config):
    """
    Main function

    Args:
        config (dict): Config dict

    Returns:
        render.Root: Rendered text
    """

    # Everything we do is UTC and relative to now
    now = time.now()

    timeular_api_key = config.str("timeular_api_key")
    timeular_api_secret = config.str("timeular_api_secret")

    #Guard Clauses
    if timeular_api_key == None or timeular_api_secret == None:
        return print_error("Input your Timeular API Key and Secret in the config.")

    auth_ok, timeular_token = authorize_timeular(timeular_api_key, timeular_api_secret)
    if not auth_ok:
        return print_error(timeular_token)

    activities_ok, timeular_activities_json = get_timeular_activities(timeular_token)
    if not activities_ok:
        return print_error(timeular_activities_json)

    activities_list_ok, timeular_activities_list_json = get_timeular_activities_list(timeular_token)
    if not activities_list_ok:
        return print_error(timeular_activities_list_json)

    if timeular_activities_json["currentTracking"] == None:
        return render_text_no_activity(config)

    could_build_activity, activity_name, activity_color, activity_started_at = build_timeular_current_activity(timeular_activities_json, timeular_activities_list_json)
    if not could_build_activity:
        return print_error(activity_name)

    #Finally safe to build the activity
    timeular_current_activity = {
        "name": activity_name,
        "color": activity_color,
        # replace the last character of the string with a Z to make it parser happy
        "started_at": activity_started_at[:-1] + "Z",
    }

    return render_text_activity(config, timeular_current_activity.get("name"), timeular_current_activity.get("color"), get_parsed_time(timeular_current_activity["started_at"], now))

def get_schema():
    """
    Gets the config schema

    Returns:
        schema.Schema: Config schema
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "timeular_api_key",
                name = "Timeular API Key",
                desc = "Your Timeular API Key",
                icon = "key",
            ),
            schema.Text(
                id = "timeular_api_secret",
                name = "Timeular API Secret",
                desc = "Your Timeular API Secret",
                icon = "lock",
            ),
            schema.Toggle(
                id = "active_only_when_tracking",
                name = "Hide when not tracking activity",
                desc = "Enable to only show app when an activity is being tracked.",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Toggle(
                id = "display_logo",
                name = "Display Timeular logo",
                desc = "Enable to display Timeular logo at top of app.",
                icon = "image",
                default = False,
            ),
        ],
    )

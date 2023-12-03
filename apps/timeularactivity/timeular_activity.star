"""
Applet: Timeular Activity
Summary: Current timeular activity
Description: Tracks the ammount of time spent on the current Timeular activity.
Author: tommylin1212
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

timeular_login_url = "https://api.timeular.com/api/v3/developer/sign-in"
timeular_activities_url = "https://api.timeular.com/api/v3/tracking"
timeular_list_all_activities_url = "https://api.timeular.com/api/v3/activities"

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
    timeular_auth = http.post(timeular_login_url, json_body = {"apiKey": timeular_api_key, "apiSecret": timeular_api_secret}, headers = {"Content-Type": "application/json"})
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
    timeular_activities = http.get(timeular_activities_url, headers = {"Authorization": "Bearer " + timeular_token}, ttl_seconds = 60)
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
    timeular_activities_list = http.get(timeular_list_all_activities_url, headers = {"Authorization": "Bearer " + timeular_token})
    if not timeular_activities_list.status_code == 200:
        return False, timeular_activities_list.json()["message"]
    else:
        timeular_activities_list_json = timeular_activities_list.json()
        return True, timeular_activities_list_json

def render_text_no_activity():
    """
    Renders the text for when there is no activity

    Returns:
        render.Root: Rendered text
    """
    return render.Root(
        child = render.Box(
            render.Row(
                cross_align = "center",
                main_align = "center",
                children = [render.Marquee(width = 64, child = render.Text("Not Tracking Activity"))],
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
    activity_id = ["currentTracking"]["activityId"]
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

def render_text_activity(activity_name, activity_color, parsed_time):
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
        return render_text_no_activity()

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

    return render_text_activity(timeular_current_activity.get("name"), timeular_current_activity.get("color"), get_parsed_time(timeular_current_activity["started_at"], now))

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
                icon = "lock",
            ),
            schema.Text(
                id = "timeular_api_secret",
                name = "Timeular API Secret",
                desc = "Your Timeular API Secret",
                icon = "lock",
            ),
        ],
    )

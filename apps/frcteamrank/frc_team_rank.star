"""
Applet: FRC Team Rank
Summary: Display FRC event ranking
Description: Displays the ranking of an FRC team at the team's active event.
Author: dragid10
"""

# Imports
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

## ==================== BEGIN CONSTANTS ====================
# Cache and API settings
TEAM_INFO_CACHE_SECS = 600
TEAM_RANK_CACHE_SECS = 100
IMG_MAX_WIDTH = 20
IMG_MAX_HEIGHT = 20
DATETIME_FORMAT = "yyyy-MM-dd"
MARQUEE_OFFSET_START = 15
MARQUEE_WIDTH = 40
WIDGET_HEIGHT = 1
WIDGET_COLOR = "#ffffff"

# Default values for UI display when API calls fail
DEFAULT_TEAM_AVATAR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0N1AAACFlBMVEVHcEwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAADqWkcAAAD///+MNit9MCZmZmZ3d3fpWkffVkTkWEUEAgHdVUOEMyjgVkTnWUaCMiiBMidIHBYRBwWpQTMiDQrZVEIQBgW4RzjhVkQVCAZRHxgYCQdPHhi9STlSHxnOzs4tEQ45FhHaVELHTTzZU0KnQDPGTDxhJR5kJh4UCAYTBwZOHhi6SDkWCAeAMScXCQdrKSGmQDJqKSBuKiFsKiHeVUPITT2QNywhDQq8SDkkDgvYU0G/STp2LiReJBxFRUVYIhvmWUZfJB1RUVHAwMBzLCNgJR1iJh63RjdlJx+5Rzi2RjcPBgVjJh4ZCggaCgi+SToFAgLJTT3KTj1fJR1dJBxJHBZMHRdLHRfBwcG/v784FhEvEg5QHxjMzMyzDRfUAAAAU3RSTlMA+cgzJQiO7QH89jCV3bvFxjHuJ5BIzvq9LSSL42XhKOQuaJbiZmeXx0rE6/hLvjX9SZLMB9Aj7Dr1PDjbvNrcio2MTUyU3svK35HPN/ZHO+/1JiyWEyAAAALISURBVFjD7ZdlVxtBFIYhREhw9xa3lhbXurvdt5aNkRCCu7sUKVKkReru/g+b8Kmc7uzO0o/k+bjn7HNm9965846Pjxcvu4+9qVmxQeExMeFHY9MyI3ZqCdAmYxuJ2gDlFv+T2e5Xx9qttT3dJlN3T621ucn9IDTPX5nn4FnAOThKf2NseOUEVH4KNJrCfLy2NtI/2Owt0EdqeD03SmCetpEothkzotV8nspwLC4RkzYXdOU8ngIDvggkgaUGl6PkPVXX8fARSVL9EYZKOU/ENayRLCvQyfwnTQm+VsuLqmtwUbp2hVgUiAOLC5GSfZj/bom4eGvWS3Sm/zlMEyeTULF3yym8aeQVCS3IYYqyYSVuHAhhecLgbOQX2eqRwhBp8YwUMIAEhigZo0pEDUhnzFU0GZWIjE0Qb+9UNJMiWpEhKsry1KzOcZsLRx2RHYGiogOoJdoEJ5tE9xAsKjqPD57lrt/lYB2/iO4jSFSkg3u5P/DtJgcb6CJ6gH2iIl+YiDrRwSPqQCeRCfv/W/QbP9mirU/rwgaP6LvUp53Be6J2rN7hYBXt7J+9Vf5l3vIvs8uf5mlIy9wtLuYsnoY8LSrKVLpFRpAkfhJhSNmmHUa8+PZPxHMlohfYw5hHxzGoRPQYx1gRDU4bv0eoRxxraIfCzi8aRy7zFMlDi8DrmR1DAfuAVGGGVzSFUIkj209vbuPzLJj1YVKH/wW4LFwhYh5a6VgTjRq+WFNULB2Q1DqsyPf0J5SVykW2SxXy0W8NhqvyITKqAp9nZcKo4QpPrC3XwSVRu4V5lFXxBW11NMyTjM4UpswoKuWN/ppIPSYcIvtOGJ+AXlus4DbipwLqnzRsm0/GpwMvgZAwhdesnBD3YB5qtff195pMvf19jpFh94PcKB/lpJxI3z7v9yTE7fQSqc4IPHxI5+urOxIcmBTvvZp72YX8ATB0xtXBaCzPAAAAAElFTkSuQmCC")
DEFAULT_TEAM_NAME = "N/A"
DEFAULT_TEAM_NUMBER = 0
DEFAULT_RANKING_MSG = "No Ranking"
DEFAULT_ERROR_MSG = "No valid Blue Alliance API key provided. Please enter a valid TBA api key."
DEFAULT_NO_EVENTS_MSG = "No active events for team %d!"

# Use The Blue Alliance API to get the team's current competition ranking
TBA_BASE_URL = "https://www.thebluealliance.com/api/v3"
TBA_API_KEY_DEFAULT = "YOUR_TBA_READ_API_KEY_HERE"
TBA_API_KEY_ENCRYPTED = "AV6+xWcEi7teQ3dIi5syCMRdr8X9t5Cc0NS2zyaivQLlKToPL+7cd0MQk3ZXQSvLNh2DvGJUgxvX9vfkT6GASc1+ZYni9ENlOyeVAsmvnmgDCQtYogqW0UkKluSxSWc/p9k7HKQT3dzAXitJfzIio6aFZvg1KejmuVO2TLXicXTp91hGO65ci4Cudz8m9Jo0zwL+k1vh6ppKBqA2e74Ie9DsMSgP9A=="  # Encrypted READ key

## ==================== END CONSTANTS ====================

## ==================== BEGIN MESSAGE CONSTANTS ====================
# Error messages
MSG_TEAM_EVENTS_ERROR = "Error fetching team events for %d"
MSG_TEAM_AVATAR_ERROR = "Error fetching team avatar for %d"
MSG_TEAM_INFO_ERROR = "Error fetching team info for %s"
MSG_TEAM_RANKING_ERROR = "Error fetching team ranking for %d"
MSG_NO_ACTIVE_EVENTS = "No active events for team %d!"

# Info messages
MSG_CACHE_HIT = "Hit! Displaying cached data."
MSG_CACHE_MISS = "Miss! Calling TBA API."
MSG_TEAM_EVENTS_COUNT = "Got %d team events for team: %d"
MSG_TEAM_RANKING = "Team %d is ranked %d out of %d"
## ==================== END MESSAGE CONSTANTS ====================

## ==================== BEGIN HELPER FUNCTIONS ====================
# Time and date helper functions
def get_year():
    """Returns the current year.

    Returns:
        Integer representing the current year
    """
    return time.now().year

def get_current_date():
    """Returns the current date formatted as YYYY-MM-DD.

    Returns:
        String representing the current date in YYYY-MM-DD format
    """
    formatted_time = humanize.time_format(DATETIME_FORMAT, time.now())
    return formatted_time

# Team information helper functions
def get_team_info(team_id, tba_api_key):
    """Fetches team information from The Blue Alliance API.

    Args:
        team_id: The FRC team ID in the format "frcXXXX"
        tba_api_key: The Blue Alliance API key

    Returns:
        Tuple containing team number (int) and team name (string)

    Raises:
        Error if API request fails
    """

    #  Make API call to get team info
    team_info_resp = http.get(
        "%s/team/%s" % (TBA_BASE_URL, team_id),
        headers = {"X-TBA-Auth-Key": tba_api_key},
        ttl_seconds = TEAM_INFO_CACHE_SECS,
    )

    # If the request fails, return an error message
    if team_info_resp.status_code != 200:
        team_info_error = MSG_TEAM_INFO_ERROR % team_id
        fail("%s - Status code: %s" % (team_info_error, team_info_resp.status_code))

    # Parse the response JSON
    team_info = team_info_resp.json()
    return team_info["team_number"], team_info["nickname"]

def get_team_events_for_current_year(team_number, tba_api_key):
    """Fetches all events for a given team for the current year.

    Args:
        team_number: The FRC team number
        tba_api_key: The Blue Alliance API key

    Returns:
        List of events the team is participating in for the current year

    Raises:
        Error if API request fails
    """

    # Make API call to get team events
    team_events_url = "%s/team/frc%d/events/%d/simple" % (TBA_BASE_URL, team_number, get_year())
    team_events_resp = http.get(team_events_url, headers = {"X-TBA-Auth-Key": tba_api_key}, ttl_seconds = TEAM_INFO_CACHE_SECS)

    # If the request fails, return an error message
    if team_events_resp.status_code != 200:
        team_events_error = MSG_TEAM_EVENTS_ERROR % team_number
        fail("%s - Status code: %s" % (team_events_error, team_events_resp.status_code))

    # Parse the response JSON
    team_events = team_events_resp.json()
    return team_events

def get_team_ranking(team_number, event_key, tba_api_key):
    """Fetches team ranking for a specific event from The Blue Alliance API.

    Args:
        team_number: The FRC team number
        event_key: The event key identifier
        tba_api_key: The Blue Alliance API key

    Returns:
        Tuple containing team ranking (int) and total number of teams (int)

    Raises:
        Error if API request fails
    """
    team_ranking_resp = http.get(
        "%s/team/frc%d/event/%s/status" % (TBA_BASE_URL, team_number, event_key),
        headers = {"X-TBA-Auth-Key": tba_api_key},
        ttl_seconds = TEAM_RANK_CACHE_SECS,
    )

    # If the request fails, return an error message
    if team_ranking_resp.status_code != 200:
        team_ranking_error = MSG_TEAM_RANKING_ERROR % team_number
        fail("%s - Status code: %s" % (team_ranking_error, team_ranking_resp.status_code))

    # Parse the team ranking data
    ranking_data = team_ranking_resp.json()
    if "qual" not in ranking_data:
        return -1, 999
    if "ranking" not in ranking_data["qual"]:
        return -1, 999
    if "rank" not in ranking_data["qual"]["ranking"]:
        return -1, 999
    team_ranking = ranking_data["qual"]["ranking"]["rank"]
    total_teams = ranking_data["qual"]["num_teams"]

    return team_ranking, total_teams

def build_avatar_url(team_number):
    """Builds the URL for a team's avatar on The Blue Alliance.

    Args:
        team_number: The FRC team number

    Returns:
        URL string to the team's avatar image
    """
    avatar_url = "https://www.thebluealliance.com/avatar/%s/frc%d.png" % (get_year(), team_number)
    return avatar_url

def get_team_avatar(team_number):
    """Retrieves a team's avatar image from The Blue Alliance.

    Args:
        team_number: The FRC team number

    Returns:
        Binary data of the team's avatar image

    Raises:
        Error if API request fails
    """
    avatar_url = build_avatar_url(team_number)

    avatar_resp = http.get(avatar_url, ttl_seconds = TEAM_INFO_CACHE_SECS)

    if avatar_resp.status_code != 200:
        print(MSG_TEAM_AVATAR_ERROR % team_number)
        return None

    return avatar_resp.body()

## ==================== END HELPER FUNCTIONS ====================

## ==================== BEGIN MAIN FUNCTION ====================
def main(config):
    """Main entry point for the app.

    Args:
        config: Configuration dictionary containing user settings

    Returns:
        A render object representing the UI
    """

    # Get team number from the user
    team_number_input = config.get("team_number") or DEFAULT_TEAM_NUMBER
    USER_INPUT_TEAM_NUMBER = "frc%s" % team_number_input
    print("Team number: %s" % USER_INPUT_TEAM_NUMBER)

    # Parse the team number (assuming it's valid)
    team_number = int(team_number_input)

    # Initialize with default values from constants
    team_name = DEFAULT_TEAM_NAME
    team_ranking_msg = DEFAULT_RANKING_MSG
    team_avatar = DEFAULT_TEAM_AVATAR

    # Get Blue Alliance API key from the user
    TBA_API_KEY = secret.decrypt(TBA_API_KEY_ENCRYPTED) or config.get("tba_api_key", TBA_API_KEY_DEFAULT)

    # Check if we have a valid API key
    if TBA_API_KEY and TBA_API_KEY != TBA_API_KEY_DEFAULT:
        # API key is valid, proceed with API calls

        # Get team info
        team_number, team_name = get_team_info(USER_INPUT_TEAM_NUMBER, TBA_API_KEY)

        # Get team events
        team_events = get_team_events_for_current_year(team_number, TBA_API_KEY)
        print(MSG_TEAM_EVENTS_COUNT % (len(team_events), team_number))

        # Process events if any exist
        # Look for active events and get ranking
        current_date = get_current_date()

        # Check if there are any active events
        for event in team_events:
            event_start_date = event["start_date"]
            event_end_date = event["end_date"]

            if event_start_date <= current_date and current_date <= event_end_date:
                event_key = event["key"]

                # Get ranking for the team's active event
                team_ranking, total_teams = get_team_ranking(team_number, event_key, TBA_API_KEY)
                print(MSG_TEAM_RANKING % (team_number, team_ranking, total_teams))

                # Update ranking message
                team_ranking_msg = "Rank: %d of %d" % (team_ranking, total_teams)

                # Break after finding the first active event
                # Note: There should never be more than 1 active event
                break

        # Get team avatar - will use default if this fails
        team_avatar = get_team_avatar(team_number)

    # Create widgets with whatever data we have
    # Avatar widget - create a fallback if no avatar is available
    if team_avatar:
        TEAM_AVATAR_WIDGET = render.Column(
            children = [
                render.Image(
                    src = team_avatar,
                    width = IMG_MAX_WIDTH,
                    height = IMG_MAX_HEIGHT,
                ),
            ],
        )
    else:
        # Create a simple placeholder for the avatar
        TEAM_AVATAR_WIDGET = render.Column(
            children = [
                render.Box(
                    width = IMG_MAX_WIDTH,
                    height = IMG_MAX_HEIGHT,
                    color = "#333333",
                    child = render.Text("FRC"),
                ),
            ],
        )

    # Team number widget
    TEAM_NUMBER_WIDGET = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Text("FRC %d" % team_number),
        ],
    )

    # Team name scrolling marquee
    TEAM_NAME_MARQUEE = render.Marquee(
        scroll_direction = "horizontal",
        align = "center",
        offset_start = MARQUEE_OFFSET_START,
        offset_end = MARQUEE_OFFSET_START,
        width = MARQUEE_WIDTH,
        child = render.Text(team_name),
    )

    # Team ranking display
    TEAM_RANKING_WIDGET = render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(team_ranking_msg),
        ],
    )

    DIVIDER_LINE_WIDGET = render.Box(width = 64, height = WIDGET_HEIGHT, color = WIDGET_COLOR)

    # Always render the main UI
    return render.Root(
        show_full_animation = True,
        child = render.Box(
            render.Column(
                children = [
                    render.Row(
                        main_align = "space_evenly",
                        expanded = True,
                        children = [
                            TEAM_AVATAR_WIDGET,
                            render.Column(
                                cross_align = "center",
                                children = [
                                    TEAM_NUMBER_WIDGET,
                                    TEAM_NAME_MARQUEE,
                                ],
                            ),
                        ],
                    ),
                    DIVIDER_LINE_WIDGET,
                    TEAM_RANKING_WIDGET,
                ],
            ),
        ),
    )

def get_schema():
    """Defines the configuration schema for the app.

    Returns:
        A schema object defining the configurable parameters for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team_number",
                name = "FRC Team Number",
                desc = "The FRC Team whose stats you want to display. List of team numbers can be found here: https://www.thebluealliance.com/teams",
                icon = "hashtag",
            ),
            schema.Text(
                id = "tba_api_key",
                name = "TheBlueAlliance API Key",
                desc = "READ Api key to access TheBlueAlliance API. Can be generated from your TBA account settings: https://www.thebluealliance.com/account",
                icon = "key",
            ),
        ],
    )

## ==================== END MAIN FUNCTION ====================

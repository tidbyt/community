"""
Applet: HomeGame
Summary: Upcoming college FB games
Description: Displays upcoming college football game information with home/away indicator.
Author: tscott98
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ESPN API endpoint for college football
ESPN_API_BASE = "http://site.api.espn.com/apis/site/v2/sports/football/college-football"

# Default configuration
DEFAULT_TEAM_ID = "245"  # Example: Texas A&M
DEFAULT_TIMEZONE = "America/Chicago"

def main(config):
    """
    Main entry point for the HomeGame applet.

    Args:
        config: Configuration object with user settings

    Returns:
        render.Root object with the display layout
    """

    # Get configuration values
    team_id = config.get("team_id", DEFAULT_TEAM_ID)
    timezone = config.get("timezone", DEFAULT_TIMEZONE)

    # Fetch game data
    game_data = get_next_game(team_id, timezone)

    # Handle error or no game found
    if game_data == None:
        return render_error("No upcoming game found")

    # Parse game data
    our_team = game_data.get("home_team", "TEAM")  # "home_team" key actually contains our team
    opponent = game_data.get("away_team", "OPP")  # "away_team" key actually contains opponent
    is_home_game = game_data.get("is_home_game", True)
    kickoff_date = game_data.get("kickoff_date", "")
    kickoff_time = game_data.get("kickoff_time", "")
    game_status = game_data.get("status", "upcoming")  # upcoming, countdown, in_progress
    countdown_text = game_data.get("countdown_text", "")

    # Render the display
    return render_game_display(
        our_team,
        opponent,
        is_home_game,
        kickoff_date,
        kickoff_time,
        game_status,
        countdown_text,
    )

def get_next_game(team_id, timezone):
    """
    Fetches the next scheduled game for the specified team.

    Args:
        team_id: ESPN team ID for the college football team
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with game data or None if no game found
    """

    # Create cache key
    cache_key = "game_data_%s" % team_id

    # Check cache first (cache for 5 minutes)
    cached_data = cache.get(cache_key)
    if cached_data != None:
        return json.decode(cached_data)

    # Fetch team schedule from ESPN API
    url = "%s/teams/%s" % (ESPN_API_BASE, team_id)

    # Make HTTP request with error handling
    response = http.get(url, ttl_seconds = 300)

    if response.status_code != 200:
        print("Error fetching team data: HTTP %d" % response.status_code)
        return None

    # Parse response
    team_data = response.json()

    # Extract next event from team data
    # Note: The API structure may vary, this is a best-effort parse
    if not team_data or "team" not in team_data:
        print("Invalid team data structure")
        return None

    team_info = team_data.get("team", {})
    next_event = team_info.get("nextEvent", None)

    if next_event == None:
        # Try alternate API endpoint - scoreboard
        return get_next_game_from_scoreboard(team_id, timezone)

    # Parse next event
    game_data = parse_game_event(next_event, team_id, timezone)

    # Cache the result
    if game_data:
        cache.set(cache_key, json.encode(game_data), ttl_seconds = 300)

    return game_data

def get_next_game_from_scoreboard(team_id, timezone):
    """
    Fallback method to fetch game from scoreboard API.

    Args:
        team_id: ESPN team ID
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with game data or None
    """

    # Get current date and next 30 days
    now = time.now()
    end_date = now + time.parse_duration("720h")  # 30 days

    date_range = "%s-%s" % (
        now.format("20060102"),
        end_date.format("20060102"),
    )

    url = "%s/scoreboard?dates=%s&groups=80" % (ESPN_API_BASE, date_range)

    response = http.get(url, ttl_seconds = 300)

    if response.status_code != 200:
        print("Error fetching scoreboard: HTTP %d" % response.status_code)
        return None

    scoreboard_data = response.json()
    events = scoreboard_data.get("events", [])

    # Find the next game for this team
    for event in events:
        competitions = event.get("competitions", [])
        for competition in competitions:
            competitors = competition.get("competitors", [])

            # Check if this game involves our team
            for competitor in competitors:
                if competitor.get("id") == team_id or competitor.get("team", {}).get("id") == team_id:
                    return parse_game_event(event, team_id, timezone)

    return None

def parse_game_event(event, team_id, timezone):
    """
    Parses game event data from ESPN API.

    Args:
        event: Event data from ESPN API
        team_id: Our team's ID to determine home/away
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with parsed game data
    """

    # Handle both dict and list access patterns
    if type(event) == "list":
        if len(event) == 0:
            return None
        event = event[0]

    competitions = event.get("competitions", [])
    if len(competitions) == 0:
        return None

    competition = competitions[0]

    # Safely access competitors
    if type(competition) == "dict":
        competitors = competition.get("competitors", [])
    else:
        return None

    # Find home and away teams
    home_team_data = None
    away_team_data = None
    is_home_game = False
    our_team_data = None
    opponent_team_data = None

    for competitor in competitors:
        home_away = competitor.get("homeAway", "")
        team = competitor.get("team", {})
        comp_team_id = str(team.get("id", ""))

        if home_away == "home":
            home_team_data = team
        elif home_away == "away":
            away_team_data = team

        # Check if this is our team
        if comp_team_id == str(team_id):
            our_team_data = team
            is_home_game = (home_away == "home")
        else:
            opponent_team_data = team

    if not home_team_data or not away_team_data:
        return None

    if not our_team_data or not opponent_team_data:
        return None

    # Get team names (use abbreviation for compact display)
    # Always show: OUR_TEAM vs OPPONENT
    our_team = our_team_data.get("abbreviation", our_team_data.get("name", "TEAM"))
    opponent = opponent_team_data.get("abbreviation", opponent_team_data.get("name", "OPP"))

    # Get game date/time
    # ESPN API returns time in UTC (with "Z" suffix)
    date_str = event.get("date", "")
    if date_str:
        # Parse the time from ESPN
        if date_str.endswith("Z") and date_str.count(":") == 1:
            # Format: "YYYY-MM-DDTHH:MMZ" (no seconds)
            parsed_time = time.parse_time(date_str, format = "2006-01-02T15:04Z")
        else:
            # Try RFC3339 format (with seconds)
            parsed_time = time.parse_time(date_str)

        # Convert from UTC to user's local timezone
        game_time = parsed_time.in_location(timezone)
    else:
        game_time = time.now().in_location(timezone)

    # Determine game status
    status_data = competition.get("status", {})
    status_type = status_data.get("type", {}).get("name", "scheduled")

    game_status = "upcoming"
    countdown_text = ""

    now = time.now().in_location(timezone)
    time_until_game = game_time - now

    # Check if game is in progress
    if status_type == "in" or status_type == "STATUS_IN_PROGRESS":
        game_status = "in_progress"

    # Check if it's game day (same calendar day)
    # Compare dates: game date vs current date in same timezone
    game_date = game_time.format("2006-01-02")
    current_date = now.format("2006-01-02")

    if game_date == current_date and time_until_game.seconds > 0:
        # It's game day and game hasn't started yet - show countdown
        game_status = "countdown"
        countdown_text = format_countdown(time_until_game)
    elif game_date == current_date and time_until_game.seconds <= 0:
        # It's game day and game time has passed - check if in progress
        # (If we got here, status_type didn't indicate in progress, so treat as upcoming)
        game_status = "countdown"
        countdown_text = "0m"

    # Format kickoff time - split into date and time for flexible display
    kickoff_date = game_time.format("Jan 2")
    kickoff_time = game_time.format("3:04 PM")

    return {
        "home_team": our_team,
        "away_team": opponent,
        "is_home_game": is_home_game,
        "kickoff_date": kickoff_date,
        "kickoff_time": kickoff_time,
        "status": game_status,
        "countdown_text": countdown_text,
    }

def format_countdown(duration):
    """
    Formats time duration as countdown string.

    Args:
        duration: time.duration object

    Returns:
        Formatted countdown string (e.g., "2h 30m")
    """

    hours = int(duration.hours)
    minutes = int(duration.minutes % 60)

    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    else:
        return "%dm" % minutes

def render_game_display(our_team, opponent, is_home_game, kickoff_date, kickoff_time, game_status, countdown_text):
    """
    Renders the game display layout with context-aware date/time formatting.

    Args:
        our_team: Our team name/abbreviation
        opponent: Opponent team name/abbreviation
        is_home_game: Boolean indicating if it's a home game for our team
        kickoff_date: Formatted kickoff date (e.g., "Oct 12")
        kickoff_time: Formatted kickoff time (e.g., "3:30 PM")
        game_status: Game status (upcoming, countdown, in_progress)
        countdown_text: Countdown text if applicable

    Returns:
        render.Root object
    """

    # Determine status color and text
    # REQUIREMENTS: HOME in RED, AWAY in GREEN
    if is_home_game:
        status_color = "#FF0000"  # RED for HOME
        status_text = "HOME"
    else:
        status_color = "#00FF00"  # GREEN for AWAY
        status_text = "AWAY"

    # Build display children
    children = [
        # Team matchup: OUR_TEAM vs OPPONENT
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    content = our_team,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
                render.Text(
                    content = " vs ",
                    font = "tb-8",
                    color = "#AAAAAA",
                ),
                render.Text(
                    content = opponent,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
            ],
        ),
        render.Box(width = 64, height = 2),  # Spacer

        # Home/Away indicator
        render.Box(
            width = 64,
            height = 12,
            color = status_color,
            child = render.Text(
                content = status_text,
                font = "6x13",
                color = "#000000",
            ),
        ),
        render.Box(width = 64, height = 2),  # Spacer
    ]

    # Add status-specific content based on game state
    if game_status == "in_progress":
        # Game is in progress: Show "IN PROGRESS"
        children.append(
            render.Text(
                content = "IN PROGRESS",
                font = "tb-8",
                color = "#FFFF00",
            ),
        )
    elif game_status == "countdown":
        # Game day (same calendar day): Show kickoff time and countdown timer on same line
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(
                        content = kickoff_time,
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                    render.Text(
                        content = countdown_text,
                        font = "tb-8",
                        color = "#FFFF00",
                    ),
                ],
            ),
        )
    else:
        # Not game day: Show date and time on separate lines
        children.extend([
            render.Text(
                content = kickoff_date,
                font = "tb-8",
                color = "#FFFFFF",
            ),
            render.Text(
                content = kickoff_time,
                font = "tb-8",
                color = "#FFFFFF",
            ),
        ])

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def render_error(message):
    """
    Renders an error message.

    Args:
        message: Error message to display

    Returns:
        render.Root object
    """

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = "ERROR",
                        font = "6x13",
                        color = "#FF0000",
                    ),
                    render.Box(width = 64, height = 2),
                    render.Text(
                        content = message,
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        ),
    )

def get_schema():
    """
    Defines the configuration schema for user customization.

    Returns:
        schema.Schema object
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team_id",
                name = "Team ID",
                desc = "ESPN Team ID for your college football team",
                icon = "football",
                default = DEFAULT_TEAM_ID,
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Your local timezone (e.g., America/Chicago)",
                icon = "clock",
                default = DEFAULT_TIMEZONE,
            ),
        ],
    )

"""
Applet: HomeGame
Summary: Upcoming college FB games
Description: Displays upcoming college football game information with home/away indicator.
Author: tscott98
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
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
DEFAULT_LOCATION = """
{
    "lat": "30.62",
    "lng": "-96.33",
    "description": "College Station, TX, USA",
    "locality": "College Station",
    "place_id": "ChIJn2tQoqvFRIYRJWQX3VJQvOY",
    "timezone": "America/Chicago"
}
"""

def main(config):
    """
    Main entry point for the HomeGame applet.

    Args:
        config: Configuration object with user settings

    Returns:
        render.Root object with the display layout
    """

    # Get team ID from dropdown or custom field
    team_dropdown = config.get("team_dropdown", DEFAULT_TEAM_ID)
    if team_dropdown == "custom":
        team_id = config.get("custom_team_id", DEFAULT_TEAM_ID)
    else:
        team_id = team_dropdown

    # Get timezone from location JSON
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location.get("timezone", DEFAULT_TIMEZONE)

    # TEST INJECTION POINT - allows testing without API calls
    # When _test_event_b64 is provided, decode base64, parse JSON, skip API
    test_event_b64 = config.get("_test_event_b64", None)
    test_time_str = config.get("_test_time", None)

    # Parse mock time if provided
    mock_now = None
    if test_time_str:
        mock_now = time.parse_time(test_time_str, format = "2006-01-02T15:04:05Z07:00").in_location(timezone)

    if test_event_b64:
        # Test mode - decode base64, parse JSON, then parse mock event
        test_event_json = base64.decode(test_event_b64)
        test_event = json.decode(test_event_json)
        game_data = parse_game_event(test_event, team_id, timezone, mock_now)
    else:
        # Production mode - fetch from API
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
    our_score = game_data.get("our_score", 0)
    opp_score = game_data.get("opp_score", 0)
    period = game_data.get("period", "")
    is_final = game_data.get("is_final", False)

    # Render the display
    return render_game_display(
        our_team,
        opponent,
        is_home_game,
        kickoff_date,
        kickoff_time,
        game_status,
        countdown_text,
        our_score,
        opp_score,
        period,
        is_final,
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

def parse_game_event(event, team_id, timezone, mock_now = None):
    """
    Parses game event data from ESPN API.

    Args:
        event: Event data from ESPN API
        team_id: Our team's ID to determine home/away
        timezone: User's timezone for time conversion
        mock_now: Optional mock time for testing (Time object)

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

    # Use mock time if provided (for testing), otherwise use current time
    now = mock_now if mock_now else time.now().in_location(timezone)
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

    # Extract scores and period for in-progress games
    our_score = 0
    opp_score = 0
    period = ""
    is_final = False

    if game_status == "in_progress":
        # Get scores from competitors
        for competitor in competitors:
            comp_team_id = str(competitor.get("team", {}).get("id", ""))
            score = competitor.get("score", "0")

            if comp_team_id == str(team_id):
                our_score = int(score)
            else:
                opp_score = int(score)

        # Get period/quarter information
        period_num = status_data.get("period", 0)
        status_detail = status_data.get("type", {}).get("detail", "")
        is_final = (status_type == "post" or "final" in status_detail.lower())

        if is_final:
            period = "FINAL"
        elif period_num > 0:
            # College football has 4 quarters
            if period_num == 1:
                period = "Q1"
            elif period_num == 2:
                period = "Q2"
            elif period_num == 3:
                period = "Q3"
            elif period_num == 4:
                period = "Q4"
            elif period_num > 4:
                period = "OT" + str(period_num - 4) if period_num > 5 else "OT"

    return {
        "home_team": our_team,
        "away_team": opponent,
        "is_home_game": is_home_game,
        "kickoff_date": kickoff_date,
        "kickoff_time": kickoff_time,
        "status": game_status,
        "countdown_text": countdown_text,
        "our_score": our_score,
        "opp_score": opp_score,
        "period": period,
        "is_final": is_final,
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

def render_game_display(our_team, opponent, is_home_game, kickoff_date, kickoff_time, game_status, countdown_text, our_score, opp_score, period, is_final):
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
        our_score: Our team's score (for in_progress games)
        opp_score: Opponent's score (for in_progress games)
        period: Game period/quarter (Q1, Q2, Q3, Q4, OT, FINAL)
        is_final: Whether the game is final

    Returns:
        render.Root object
    """

    # Determine status color and text based on game day
    is_game_day = (game_status == "countdown" or game_status == "in_progress")

    if is_game_day:
        # Game day: Use solid color backgrounds
        if is_home_game:
            status_bg_color = "#FF0000"  # RED solid for HOME
            status_text_color = "#000000"  # Black text
            status_text = "HOME"
        else:
            status_bg_color = "#00FF00"  # GREEN solid for AWAY
            status_text_color = "#000000"  # Black text
            status_text = "AWAY"

        # Render Home/Away indicator with solid background
        status_indicator = render.Box(
            width = 64,
            height = 12,
            color = status_bg_color,
            child = render.Text(
                content = status_text,
                font = "6x13",
                color = status_text_color,
            ),
        )
    else:
        # Not game day: Use colored text on black background (no border)
        if is_home_game:
            status_text_color = "#FF0000"  # RED text for HOME
            status_text = "HOME"
        else:
            status_text_color = "#00FF00"  # GREEN text for AWAY
            status_text = "AWAY"

        # Render Home/Away indicator with colored text, no border
        status_indicator = render.Box(
            width = 64,
            height = 12,
            color = "#000000",  # Black background
            child = render.Text(
                content = status_text,
                font = "6x13",
                color = status_text_color,
            ),
        )

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
        status_indicator,
        render.Box(width = 64, height = 2),  # Spacer
    ]

    # Add bottom row content based on game state
    if game_status == "in_progress":
        # Game in progress: Show scores on left/right, period in center
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    # Our score (left)
                    render.Text(
                        content = str(our_score),
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                    # Period/quarter (center)
                    render.Text(
                        content = period,
                        font = "tb-8",
                        color = "#FFFF00" if not is_final else "#FFFFFF",
                    ),
                    # Opponent score (right)
                    render.Text(
                        content = str(opp_score),
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        )
    elif game_status == "countdown":
        # Game day (countdown): Show countdown timer and kickoff time on same line
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(
                        content = countdown_text,
                        font = "tb-8",
                        color = "#FFFF00",
                    ),
                    render.Text(
                        content = kickoff_time,
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        )
    else:
        # Not game day: Show date and time on single line
        children.append(
            render.Text(
                content = kickoff_date + " " + kickoff_time,
                font = "tb-8",
                color = "#FFFFFF",
            ),
        )

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

def team_id_handler(team_dropdown):
    """
    Handler for team selection. If 'custom' is selected, shows text input
    for custom team ID.

    Args:
        team_dropdown: Selected team value from dropdown

    Returns:
        List of schema fields for custom team ID input, or empty list
    """

    if team_dropdown == "custom":
        return [
            schema.Text(
                id = "custom_team_id",
                name = "Custom Team ID",
                desc = "Enter ESPN Team ID (e.g., 245 for Texas A&M)",
                icon = "hashtag",
                default = DEFAULT_TEAM_ID,
            ),
        ]
    return []

def get_popular_teams():
    """
    Returns list of popular college football teams for dropdown selection.

    Includes Power 5 conferences (SEC, Big Ten, Big 12, ACC, Pac-12) plus
    major independents and popular teams.

    Returns:
        List of schema.Option objects for team selection
    """

    return [
        # SEC
        schema.Option(display = "Alabama Crimson Tide", value = "333"),
        schema.Option(display = "Arkansas Razorbacks", value = "8"),
        schema.Option(display = "Auburn Tigers", value = "2"),
        schema.Option(display = "Florida Gators", value = "57"),
        schema.Option(display = "Georgia Bulldogs", value = "61"),
        schema.Option(display = "Kentucky Wildcats", value = "96"),
        schema.Option(display = "LSU Tigers", value = "99"),
        schema.Option(display = "Mississippi State Bulldogs", value = "344"),
        schema.Option(display = "Missouri Tigers", value = "142"),
        schema.Option(display = "Ole Miss Rebels", value = "145"),
        schema.Option(display = "South Carolina Gamecocks", value = "2579"),
        schema.Option(display = "Tennessee Volunteers", value = "2633"),
        schema.Option(display = "Texas A&M Aggies", value = "245"),
        schema.Option(display = "Texas Longhorns", value = "251"),
        schema.Option(display = "Vanderbilt Commodores", value = "238"),
        # Big Ten
        schema.Option(display = "Illinois Fighting Illini", value = "356"),
        schema.Option(display = "Indiana Hoosiers", value = "84"),
        schema.Option(display = "Iowa Hawkeyes", value = "2294"),
        schema.Option(display = "Maryland Terrapins", value = "120"),
        schema.Option(display = "Michigan Wolverines", value = "130"),
        schema.Option(display = "Michigan State Spartans", value = "127"),
        schema.Option(display = "Minnesota Golden Gophers", value = "135"),
        schema.Option(display = "Nebraska Cornhuskers", value = "158"),
        schema.Option(display = "Northwestern Wildcats", value = "77"),
        schema.Option(display = "Ohio State Buckeyes", value = "194"),
        schema.Option(display = "Oregon Ducks", value = "2483"),
        schema.Option(display = "Penn State Nittany Lions", value = "213"),
        schema.Option(display = "Purdue Boilermakers", value = "2509"),
        schema.Option(display = "Rutgers Scarlet Knights", value = "164"),
        schema.Option(display = "UCLA Bruins", value = "26"),
        schema.Option(display = "USC Trojans", value = "30"),
        schema.Option(display = "Washington Huskies", value = "264"),
        schema.Option(display = "Wisconsin Badgers", value = "275"),
        # Big 12
        schema.Option(display = "Arizona Wildcats", value = "12"),
        schema.Option(display = "Arizona State Sun Devils", value = "9"),
        schema.Option(display = "Baylor Bears", value = "239"),
        schema.Option(display = "BYU Cougars", value = "252"),
        schema.Option(display = "Cincinnati Bearcats", value = "2132"),
        schema.Option(display = "Colorado Buffaloes", value = "38"),
        schema.Option(display = "Houston Cougars", value = "248"),
        schema.Option(display = "Iowa State Cyclones", value = "66"),
        schema.Option(display = "Kansas Jayhawks", value = "2305"),
        schema.Option(display = "Kansas State Wildcats", value = "2306"),
        schema.Option(display = "Oklahoma State Cowboys", value = "197"),
        schema.Option(display = "TCU Horned Frogs", value = "2628"),
        schema.Option(display = "Texas Tech Red Raiders", value = "2641"),
        schema.Option(display = "UCF Knights", value = "2116"),
        schema.Option(display = "Utah Utes", value = "254"),
        schema.Option(display = "West Virginia Mountaineers", value = "277"),
        # ACC
        schema.Option(display = "Boston College Eagles", value = "103"),
        schema.Option(display = "Clemson Tigers", value = "228"),
        schema.Option(display = "Duke Blue Devils", value = "150"),
        schema.Option(display = "Florida State Seminoles", value = "52"),
        schema.Option(display = "Georgia Tech Yellow Jackets", value = "59"),
        schema.Option(display = "Louisville Cardinals", value = "97"),
        schema.Option(display = "Miami Hurricanes", value = "2390"),
        schema.Option(display = "NC State Wolfpack", value = "152"),
        schema.Option(display = "North Carolina Tar Heels", value = "153"),
        schema.Option(display = "Pittsburgh Panthers", value = "221"),
        schema.Option(display = "Syracuse Orange", value = "183"),
        schema.Option(display = "Virginia Cavaliers", value = "258"),
        schema.Option(display = "Virginia Tech Hokies", value = "259"),
        schema.Option(display = "Wake Forest Demon Deacons", value = "154"),
        # Pac-12 / Other
        schema.Option(display = "California Golden Bears", value = "25"),
        schema.Option(display = "Stanford Cardinal", value = "24"),
        schema.Option(display = "Washington State Cougars", value = "265"),
        # Independents
        schema.Option(display = "Army Black Knights", value = "349"),
        schema.Option(display = "Notre Dame Fighting Irish", value = "87"),
        # Custom option
        schema.Option(display = "Other (Enter Team ID)", value = "custom"),
    ]

def get_schema():
    """
    Defines the configuration schema for user customization.

    Returns:
        schema.Schema object
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team_dropdown",
                name = "Select Team",
                desc = "Choose your college football team",
                icon = "football",
                default = DEFAULT_TEAM_ID,
                options = get_popular_teams(),
            ),
            schema.Generated(
                id = "team_id",
                source = "team_dropdown",
                handler = team_id_handler,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location (used for timezone)",
                icon = "locationDot",
            ),
        ],
    )

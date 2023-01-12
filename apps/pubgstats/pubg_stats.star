"""
Applet: PUBG Stats
Summary: Shows PUBG Player Stats
Description: Displays individual player's gaming stats from PlayerUnknown's Battlegrounds.
Author: joes-io
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

# Encrypted API Key for "pubgstats"
ENCRYPTED_API_KEY = "AV6+xWcEcIMca+JxD06W2mGLG3rxsGdBDLVvr/kfE9BJ9c6k+CEjkiUzeX2RK080M9bVLeahQH5GD9gL19VSSIpGKWLOtYNNkau4vzh6od+fTU0ZROCc6yRpekenuABnN6E/gVoNoR5HW//VXQdGY72B9Tx3KQxaS8ODa1fMf34h17Z1H7zKUoNliiVDwnHlCe2Jvim7xwZmHWCDOQD4wjROTE8m6Hmf7vTazjxPaP9w+XLcSg+Vaa3IjR8KFXXJ8ad7i6tj35jf//g2GAvI8lTw5Te8Pu9iBBBPSmuPRZXPGf4VY3TNkgP7gGc7ovGm3uBTq6i2QcWFQOwV7OY1LNYbbg/BEleQfcDSC+4ZMjfKFJyxDeNbULOBhox4ht/LLb4SWlQGk6G5IwfY0YYtGKAMBt1lIMEDxllP0oObvfjWvD3FDnLySAQacQ6sCmRm7XiOwQ7XLchwO/XL2Kk2IR5KUA=="

# Default settings if no configuration set in Tidbyt app
DEFAULT_PLAYER_NAME = "chocoTaco"
DEFAULT_PLATFORM = "steam"
DEFAULT_SELECTED_STAT = "wins"

# App display options
background_color = "#eba919"
text_color = "#000000"
background_render = render.Box(width = 64, height = 32, color = background_color)

# Base64 PUBG logo displayed in app
pubg_logo = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAATlJREFUaEPtWEkOwyAMLP9/dKNUJaKWlzEmjQD3GDUOs3ijvDb/FYL/vQkfF+4kIB3wywBNAeqQWTNExGWlwDYESMVvVQKqk0sFiBBgdYiWLMlyWopF4nOpqZ3nFgLOoBKh1vPz3UcJqIx4FOJAWUDR+L1x2viIIy/FkoAvA6hCkt17laMpEInD1YMhbRApbJGDc/ZFvtmKIc0pSQBhBt4FkEIyQjmrA1CVOUV70hcugsgBI20QiW+JMTUByBzgJdgi7JMVnl3AUgn5IKpSbzF9ZA7wtJ0kQKrGZBROBxiDGTIfICkZqgHaqowcUGtt6YB/O6DnPsDjAGlERXb29l3r/oL7r9ZiQxci1m2Rp20ic4DVsiXwwwiQVJzh+ZBlaAagt26DWxIwM2jt7PA6nAQsyoDogEXxyrAO/E6qIVyYj7UAAAAASUVORK5CYII=""")

# Cache timers for API calls (seconds)
# 604800 = 7 days
ttl_player_id = 604800

# 1800 = 30 minutes
ttl_lifetime_stats = 1800

# Animation settings (frames)
logo_delay = 20
logo_duration = 30
name_delay = logo_delay + 27
name_duration = 7
stat_label_delay = name_delay + 7
stat_label_duration = 7
stat_delay = stat_label_delay + 7
stat_duration = 7

# API header to access PUBG developer API
header = {
    "Authorization": "Bearer {}".format(secret.decrypt(ENCRYPTED_API_KEY)),
    "Accept": "application/vnd.api+json",
}

# Tuples are 0 = Stat label shown in options, 1 = API use, 2 = Tidbyt display label, 3 = Tidbyt display units of measure (if any)
stat_details = [
    ("Chicken Dinners (Wins)", "wins", "CHICKEN DINNERS", ""),
    ("Kills", "kills", "KILLS", ""),
    ("Headshots", "headshotKills", "HEADSHOTS", ""),
    ("Assists", "assists", "ASSISTS", ""),
    ("Enemies Knocked", "dBNOs", "KNOCKS", ""),
    ("Damage Dealt", "damageDealt", "DAMAGE DEALT", ""),
    ("Teammates Revived", "revives", "TEAMMATES REVIVED", ""),
    ("Teamkills", "teamKills", "TEAMKILLS", ""),
    ("Suicides", "suicides", "SUICIDES", ""),
    ("Heals Used", "heals", "HEALS USED", ""),
    ("Boosts Used", "boosts", "BOOSTS USED", ""),
    ("Weapons Picked Up", "weaponsAcquired", "WEAPONS PICKED UP", ""),
    ("Kills with Vehicles", "roadKills", "ROADKILLS", ""),
    ("Vehicles Destroyed", "vehicleDestroys", "VEHICLES DESTROYED", ""),
    ("Distance in Vehicles", "rideDistance", "VEHICLE DISTANCE RIDDEN", "km"),
    ("Distance Swam", "swimDistance", "SWAM", "m"),
    ("Distance Walked", "walkDistance", "WALKED", "km"),
    ("Time Survived", "timeSurvived", "TOTAL TIME SURVIVED", "m"),
    ("Days Played", "days", "DAYS PLAYED", ""),
    ("Rounds Played", "roundsPlayed", "ROUNDS PLAYED", ""),
    ("Top 10s", "top10s", "TOP TEN FINISHES", ""),
    ("Matches Lost", "losses", "MATCHES LOST", ""),
    ("Most Kills in a Match", "roundMostKills", "MOST MATCH KILLS", ""),
    ("Max Kill Streak", "maxKillStreaks", "MAX KILL STREAK", ""),
    ("Furthest Kill Distance", "longestKill", "FURTHEST KILL", "m"),
    ("Longest Time Survived in a Match", "longestTimeSurvived", "LONGEST MATCH", "s"),
    ("Past Day's Wins", "dailyWins", "PAST DAY'S WINS", ""),
    ("Past Day's Kills", "dailyKills", "PAST DAY'S KILLS", ""),
    ("Past Week's Wins", "weeklyWins", "PAST WEEK'S WINS", ""),
    ("Past Week's Kills", "weeklyKills", "PAST WEEK'S KILLS", ""),
]

def main(config):
    # Load user settings from Tidbyt app, or grab defaults
    player_name = config.str("player_name", DEFAULT_PLAYER_NAME)
    platform = config.str("platform", DEFAULT_PLATFORM)
    selected_stat = config.str("selected_stat", DEFAULT_SELECTED_STAT)

    # App defaults
    display_label = ""
    display_unit = ""

    # Create player cache key
    player_cache_key = player_name + "_" + platform

    # Get the player id from the player name and platform
    # Check cache for id of entered player name on selected platform
    player_id_cached = cache.get(player_cache_key)

    # Use cached data if available
    if player_id_cached != None:
        player_id = player_id_cached

        # Otherwise make new API call
    else:
        # URL to request player data
        url = "https://api.pubg.com/shards/{}/players?filter[playerNames]={}".format(platform, player_name)

        # Request player data
        resp = http.get(url, headers = header)

        # Check for API errors
        if resp.status_code != 200:
            # Display error on Tidbyt and end
            return pretty_error(resp)

        # Get player id from API response
        player_id = resp.json()["data"][0]["id"]

        # Set player id in cache
        cache.set(player_cache_key, str(player_id), ttl_seconds = ttl_player_id)

    # Get lifetime stats for that player id
    # Create lifetime stats cache key
    lifetime_stats_cache_key = player_id + "_" + platform

    # Check cache for lifetime stats for that player id on selected platform
    lifetime_stats_cached = cache.get(lifetime_stats_cache_key)

    # Use cached data if available
    if lifetime_stats_cached != None:
        lifetime_stats = lifetime_stats_cached

        # Otherwise make new API call
    else:
        # URL to request lifetime stats for player
        url = "https://api.pubg.com/shards/{}/players/{}/seasons/lifetime".format(platform, player_id)

        # Add gamepad filter to Stadia API requests
        if platform == "stadia":
            url = url + "?filter[gamepad]=true"

        # Request lifetime stats for player
        resp = http.get(url, headers = header)

        # Check for API errors
        if resp.status_code != 200:
            # Display error on Tidbyt and end
            return pretty_error(resp)

        # Encode JSON data to be stored in cache
        lifetime_stats = json.encode(resp.json())

        # Set cache with JSON object from lifetime_stats serialized to string
        cache.set(lifetime_stats_cache_key, str(lifetime_stats), ttl_seconds = ttl_lifetime_stats)

    # Decode string back to JSON object to be read
    lifetime_stats = json.decode(lifetime_stats)

    # Find label and unit type to display for selected stat
    for i in stat_details:
        if i[1] == selected_stat:
            display_label = i[2]
            display_unit = i[3]
            break

    display_label_len = len(display_label)

    # If label for stat is too wide then replicate label and marquee scroll with a longer end delay for readability
    if display_label_len > 12:
        end_delay = display_label_len * 7
        display_label = display_label + "   " + display_label + "   " + display_label
        stat_label_child = render.Marquee(width = 64, offset_start = 64, child = render.Text(content = display_label, color = text_color))
    else:
        end_delay = 0
        stat_label_child = render.Text(content = display_label, color = text_color)

    # Render output to display
    return render.Root(
        render.Stack(
            children = [
                # Background
                background_render,

                # PUBG logo animation
                animation.Transformation(
                    child = render.Image(src = pubg_logo),
                    duration = logo_duration,
                    delay = logo_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(-64, 0)],
                        ),
                    ],
                ),

                # Scrolling name animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 2, 0, 0),
                        child = render.Text(
                            content = player_name,
                            font = "CG-pixel-3x5-mono",
                            color = text_color,
                        ),
                    ),
                    duration = name_duration,
                    delay = name_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # Scrolling stat label animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 10, 0, 0),
                        child = stat_label_child,
                    ),
                    duration = stat_label_duration,
                    delay = stat_label_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # Scrolling stat animation
                animation.Transformation(
                    child = render.Padding(
                        pad = (2, 18, 0, 0),
                        child = render.Text(
                            content = (calc_lifetime_stat(lifetime_stats, selected_stat) + display_unit),
                            font = "6x13",
                            color = text_color,
                        ),
                    ),
                    duration = stat_duration,
                    delay = stat_delay,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(62, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # End delay animation
                animation.Transformation(
                    child = render.Box(),
                    duration = 0,
                    delay = end_delay,
                    keyframes = [],
                ),
            ],
        ),
    )

# Return render of scrolling error message for Tidbyt display
def pretty_error(resp):
    # Get plaintext error from API response
    if resp.status_code == 401:
        error = "BAD AUTHORIZATION"
    else:
        error = resp.json()["errors"][0]["detail"].upper()

    # Return render of error to Tidbyt
    return render.Root(
        render.Stack(
            children = [
                # Background
                background_render,

                # Error message
                render.Marquee(
                    width = 64,
                    child = render.Padding(
                        pad = (0, 11, 0, 0),
                        child = render.Text(
                            content = "PUBG STATS ERROR: {}".format(error),
                            color = text_color,
                        ),
                    ),
                ),
            ],
        ),
    )

# Return stat total from across all game modes
def calc_lifetime_stat(lifetime_stats, selected_stat):
    duo_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["duo"][selected_stat]
    duo_fpp_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["duo-fpp"][selected_stat]
    solo_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["solo"][selected_stat]
    solo_fpp_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["solo-fpp"][selected_stat]
    squad_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["squad"][selected_stat]
    squad_fpp_stat = lifetime_stats["data"]["attributes"]["gameModeStats"]["squad-fpp"][selected_stat]

    # Total stat count from all game modes
    lifetime_total_stat = (duo_stat + duo_fpp_stat + solo_stat + solo_fpp_stat + squad_stat + squad_fpp_stat)

    # Convert timeSurvived from seconds to minutes
    if selected_stat == "timeSurvived":
        lifetime_total_stat = lifetime_total_stat // 60

    # Convert rideDistance and walkDistance to km
    if selected_stat == "rideDistance" or selected_stat == "walkDistance":
        lifetime_total_stat = lifetime_total_stat // 1000

    # Make stat readable
    lifetime_total_stat = humanize.comma(int(lifetime_total_stat))

    # Return total lifetime stat
    return lifetime_total_stat

# Defines app configuration settings available on Tidbyt mobile app
def get_schema():
    # List of options for gaming platform
    platforms = [
        schema.Option(
            display = "Steam",
            value = "steam",
        ),
        schema.Option(
            display = "PlayStation Network",
            value = "psn",
        ),
        schema.Option(
            display = "Xbox",
            value = "xbox",
        ),
        schema.Option(
            display = "Stadia",
            value = "stadia",
        ),
        schema.Option(
            display = "Kakao",
            value = "kakao",
        ),
    ]

    # List of options for stat to display
    stats = []
    for i in stat_details:
        stats.append(
            schema.Option(
                display = i[0],
                value = i[1],
            ),
        )

    # Configuration options available to user
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "player_name",
                name = "PUBG Player Name",
                desc = "Player name is case sensitive",
                icon = "user",
            ),
            schema.Dropdown(
                id = "platform",
                name = "Gaming Platform",
                desc = "Player's gaming platform",
                icon = "gamepad",
                default = platforms[0].value,
                options = platforms,
            ),
            schema.Dropdown(
                id = "selected_stat",
                name = "Stat to Display",
                desc = "Lifetime statistic to display",
                icon = "chartLine",
                default = stats[0].value,
                options = stats,
            ),
        ],
    )

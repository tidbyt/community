"""
Applet: PUBG Stats
Summary: Shows PUBG Player Stats
Description: Displays individual player gaming stats from PlayerUnknown's Battlegrounds.
Author: joes-io
"""

load("render.star", "render")
load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("schema.star", "schema")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("secret.star", "secret")

# Encrypted API Key for "pubgstats"
ENCRYPTED_API_KEY = "AV6+xWcEqs4E82PyBw4KYQ1mCIv7h0lMNg2HH3dPhyQEtP6zZrg+c1Lt153uLGcisNSzK4mMB+YtUPivxKjpOqM27JZubu/4DaBudMYHViZzlo+E/9Wp2JxHHg3buLIsW5j/eRXjiSwDzf5+689vfrWFWwaYcwigiIHh8VlM9VbR1Agq29MxyFxHcQm/LIWOeKe7HK3GDmHm7aXgLp4OlWRuPsDPLGcODvZgtYmBO9uO67F7DCw26rOwP6nNOcDzEX7/zUkL4EUxCXiDcu8L46IiTnhoTfumnZM0Jk6NnBXvWhmCFQdwkDdQnW8ZQGOtQnGs2BskeJu8WOjmfgRPqk9FpuL07eb1Ea2VkbzNmvACOBu5u8NcfGBQ4w3hcRBhbX2Yo0lDy1q2pukmAE3jQjMCN7YjKZPVojO+BWDpaTj9VzmtLzGka8Bm3gEuPRY+VK+bXhwXFJXwSoOuvE3fYSiBQIQi2kbe96lMj/cZvsBq4AouBQqZj+m3ld7XH/p6+y7DaroqottgSKLro8ZwBvEGGPJldYXZIhOaJhKwFzVTZ/HZV3wcoxhwXi57oiYQc1O6+v007K35n9r5PbpylqDwZXef3NAUN4h2Fec0G29x5Mm5n0Dk2N8s38AP6uvwiwxtwpaR1ZIBergB2CIw7LfyhNNu0k86dIOqBPkkmgwre6M30e/F7JWNT2t6BYBmhCnz9DxRb00u1pQr5k9GOqtT5nyCjjy998cdRJWl0x2/O3TJMuLf6GfCCKNvGNhMCntSefVEkYau3UKBA2EQy99toSAE02dChFfx6dCTN8M2YC1BZ24="

# Default settings if no configuration set in Tidbyt app
DEFAULT_PLAYER_NAME = "chocoTaco"
DEFAULT_PLATFORM = "steam"
DEFAULT_SELECTED_STAT = "wins"

# App display options
BACKGROUND_COLOR = "#eba919"
TEXT_COLOR = "#000000"
BACKGROUND_RENDER = render.Box(width = 64, height = 32, color = BACKGROUND_COLOR)

# Animation settings (frames)
logo_delay = 20
logo_duration = 30
name_delay = logo_delay + 27
name_duration = 7
stat_label_delay = name_delay + 7
stat_label_duration = 7
stat_delay = stat_label_delay + 7
stat_duration = 7

# Cache timers for API calls (seconds)
# 604800 = 7 days
TTL_PLAYER_ID = 604800

# 1800 = 30 minutes
TTL_LIFETIME_STATS = 1800

# Base64 PUBG logo displayed in app
PUBG_LOGO = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAATlJREFUaEPtWEkOwyAMLP9/dKNUJaKWlzEmjQD3GDUOs3ijvDb/FYL/vQkfF+4kIB3wywBNAeqQWTNExGWlwDYESMVvVQKqk0sFiBBgdYiWLMlyWopF4nOpqZ3nFgLOoBKh1vPz3UcJqIx4FOJAWUDR+L1x2viIIy/FkoAvA6hCkt17laMpEInD1YMhbRApbJGDc/ZFvtmKIc0pSQBhBt4FkEIyQjmrA1CVOUV70hcugsgBI20QiW+JMTUByBzgJdgi7JMVnl3AUgn5IKpSbzF9ZA7wtJ0kQKrGZBROBxiDGTIfICkZqgHaqowcUGtt6YB/O6DnPsDjAGlERXb29l3r/oL7r9ZiQxci1m2Rp20ic4DVsiXwwwiQVJzh+ZBlaAagt26DWxIwM2jt7PA6nAQsyoDogEXxyrAO/E6qIVyYj7UAAAAASUVORK5CYII=""")

# API header to access PUBG developer API
header = {
    "Authorization": "Bearer {}".format(secret.decrypt(ENCRYPTED_API_KEY)),
    "Accept": "application/vnd.api+json",
}

# Stat values paired to the labels that should be displayed on Tidbyt
stat_labels = {
    "wins": "DINNERS",
    "kills": "KILLS",
    "headshotKills": "HEADSHOTS",
    "dBNOs": "KNOCKS",
}

def main(config):
    # Load user settings from Tidbyt app, or grab defaults
    player_name = config.str("player_name", DEFAULT_PLAYER_NAME)
    platform = config.str("platform", DEFAULT_PLATFORM)
    selected_stat = config.str("selected_stat", DEFAULT_SELECTED_STAT)

    # Get the player id from the player name
    # First check cache for id of entered player name (cache identifier is player name)
    player_id_cached = cache.get(player_name)

    # If data is in cache then use it
    if player_id_cached != None:
        player_id = player_id_cached

        # Otherwise make new API call
    else:
        # URL to request player data
        url = "https://api.pubg.com/shards/{}/players?filter[playerNames]={}".format(platform, player_name)

        # Request player data
        resp = http.get(url, headers = header)

        if resp.status_code != 200:
            # Display error on Tidbyt
            return pretty_error(resp)

        # Get player id from API response
        player_id = resp.json()["data"][0]["id"]

        # Set player id cache
        cache.set(player_name, str(player_id), ttl_seconds = TTL_PLAYER_ID)

    # Get lifetime stats for that player id
    # First check cache for lifetime stats (cache identifier is player id)
    lifetime_stats_cached = cache.get(player_id)

    # If data is in cache then use it
    if lifetime_stats_cached != None:
        lifetime_stats = lifetime_stats_cached

        # Otherwise make new API call
    else:
        # URL to request lifetime stats for player
        url = "https://api.pubg.com/shards/steam/players/{}/seasons/lifetime".format(player_id)

        # Request lifetime stats for player
        resp = http.get(url, headers = header)

        if resp.status_code != 200:
            # Display error on Tidbyt
            return pretty_error(resp)

        # Encode JSON data to be stored in cache
        lifetime_stats = json.encode(resp.json())

        # Set cache with JSON object from lifetime_stats serialized to string
        cache.set(player_id, str(lifetime_stats), ttl_seconds = TTL_LIFETIME_STATS)

    # Decode string back to JSON object to be read
    lifetime_stats = json.decode(lifetime_stats)

    # Render output to display
    return render.Root(
        render.Stack(
            children = [
                # Background
                BACKGROUND_RENDER,

                # PUBG logo animation
                animation.Transformation(
                    child = render.Image(src = PUBG_LOGO),
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
                            color = TEXT_COLOR,
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
                        child = render.Text(
                            content = stat_labels[selected_stat],
                            color = TEXT_COLOR,
                        ),
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
                            content = calc_lifetime_stat(lifetime_stats, selected_stat),
                            font = "6x13",
                            color = TEXT_COLOR,
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
            ],
        ),
    )

# Return render widget of scrolling error message for Tidbyt display
def pretty_error(resp):
    # Get plaintext error from API response
    error = resp.json()["errors"][0]["detail"].upper()

    # Return render of error to Tidbyt
    return render.Root(
        render.Stack(
            children = [
                # Background
                BACKGROUND_RENDER,

                # Error message
                render.Marquee(
                    width = 64,
                    child = render.Padding(
                        pad = (0, 11, 0, 0),
                        child = render.Text(
                            content = "PUBG STATS ERROR: {}".format(error),
                            color = TEXT_COLOR,
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

    # Total stat count from all game modes, first converting to int, and then
    lifetime_total_stat = humanize.comma(int(duo_stat + duo_fpp_stat + solo_stat + solo_fpp_stat + squad_stat + squad_fpp_stat))

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
    stats = [
        schema.Option(
            display = "Total Chicken Dinners",
            value = "wins",
        ),
        schema.Option(
            display = "Total Kills",
            value = "kills",
        ),
        schema.Option(
            display = "Total Knocks",
            value = "dBNOs",
        ),
        schema.Option(
            display = "Total Headshots",
            value = "headshotKills",
        ),
    ]

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
                icon = "gear",
                default = platforms[0].value,
                options = platforms,
            ),
            schema.Dropdown(
                id = "selected_stat",
                name = "Display Stat",
                desc = "Statistic to display",
                icon = "gear",
                default = stats[0].value,
                options = stats,
            ),
        ],
    )

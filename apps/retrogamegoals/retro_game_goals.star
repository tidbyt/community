"""
Applet: Retro Game Goals
Summary: RetroAchievements for games
Description: Display RetroAchievements for a random game on a specified or random console.
Author: UnBurn
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAFCAYAAAB4ka1VAAAAN0lEQVQIW2PcsmXLfwY8gBGmYNKkSQx5eXkYSsEKQJIwAFNkmVHAcHzGBAasJsAkQZrgCnA5AwA+Gx6Nb5UO7QAAAABJRU5ErkJggg==
""")

ONE_HOUR_IN_SECONDS = 3600
TEN_MINUTES_IN_SECONDS = 600

RA_URL = "https://retroachievements.org"
RA_API_URL = "https://retroachievements.org/API"

CONSOLES = [
    {
        "ID": 0,
        "Name": "Any console",
    },
    {
        "ID": 1,
        "Name": "Mega Drive",
    },
    {
        "ID": 2,
        "Name": "Nintendo 64",
    },
    {
        "ID": 3,
        "Name": "SNES",
    },
    {
        "ID": 4,
        "Name": "Game Boy",
    },
    {
        "ID": 5,
        "Name": "Game Boy Advance",
    },
    {
        "ID": 6,
        "Name": "Game Boy Color",
    },
    {
        "ID": 7,
        "Name": "NES",
    },
    {
        "ID": 8,
        "Name": "PC Engine",
    },
    {
        "ID": 9,
        "Name": "Sega CD",
    },
    {
        "ID": 10,
        "Name": "32X",
    },
    {
        "ID": 11,
        "Name": "Master System",
    },
    {
        "ID": 12,
        "Name": "PlayStation",
    },
    {
        "ID": 13,
        "Name": "Atari Lynx",
    },
    {
        "ID": 14,
        "Name": "Neo Geo Pocket",
    },
    {
        "ID": 15,
        "Name": "Game Gear",
    },
    {
        "ID": 16,
        "Name": "GameCube",
    },
    {
        "ID": 17,
        "Name": "Atari Jaguar",
    },
    {
        "ID": 18,
        "Name": "Nintendo DS",
    },
    {
        "ID": 19,
        "Name": "Wii",
    },
    {
        "ID": 21,
        "Name": "PlayStation 2",
    },
    {
        "ID": 23,
        "Name": "Magnavox Odyssey 2",
    },
    {
        "ID": 24,
        "Name": "Pokemon Mini",
    },
    {
        "ID": 25,
        "Name": "Atari 2600",
    },
    {
        "ID": 27,
        "Name": "Arcade",
    },
    {
        "ID": 28,
        "Name": "Virtual Boy",
    },
    {
        "ID": 29,
        "Name": "MSX",
    },
    {
        "ID": 33,
        "Name": "SG-1000",
    },
    {
        "ID": 37,
        "Name": "Amstrad CPC",
    },
    {
        "ID": 38,
        "Name": "Apple II",
    },
    {
        "ID": 39,
        "Name": "Saturn",
    },
    {
        "ID": 40,
        "Name": "Dreamcast",
    },
    {
        "ID": 41,
        "Name": "PlayStation Portable",
    },
    {
        "ID": 43,
        "Name": "3DO Interactive Multiplayer",
    },
    {
        "ID": 44,
        "Name": "ColecoVision",
    },
    {
        "ID": 45,
        "Name": "Intellivision",
    },
    {
        "ID": 46,
        "Name": "Vectrex",
    },
    {
        "ID": 47,
        "Name": "PC-8000/8800",
    },
    {
        "ID": 49,
        "Name": "PC-FX",
    },
    {
        "ID": 51,
        "Name": "Atari 7800",
    },
    {
        "ID": 53,
        "Name": "WonderSwan",
    },
    {
        "ID": 56,
        "Name": "Neo Geo CD",
    },
    {
        "ID": 57,
        "Name": "Fairchild Channel F",
    },
    {
        "ID": 62,
        "Name": "Nintendo 3DS",
    },
    {
        "ID": 63,
        "Name": "Watara Supervision",
    },
    {
        "ID": 71,
        "Name": "Arduboy",
    },
    {
        "ID": 72,
        "Name": "WASM-4",
    },
    {
        "ID": 76,
        "Name": "PC Engine CD",
    },
    {
        "ID": 77,
        "Name": "Atari Jaguar CD",
    },
    {
        "ID": 78,
        "Name": "Nintendo DSi",
    },
    {
        "ID": 80,
        "Name": "Uzebox",
    },
]

encrypted_api_key = "AV6+xWcEbCjn7Cfz7MYqXyGzzOUfiAZwRw6SrglD7eLnZNiJL6XtjbuUPWyYPj5y3OoDK9qLs2u2Ea1koK5fVd8AKpT+EAEYzsEb+9C9Rk1yU03e1f7hy0Cn6EWSWOd+noco9u4nhfzz1jlvOotV6Gk64czlVBzqegsxDRd8Jvg6IoZ78/w="

def auth_params():
    return {
        "y": secret.decrypt(encrypted_api_key) or "",
        "z": "",
    }

def get_games_from_console(console_id):
    endpoint = "%s/%s" % (RA_API_URL, "API_GetGameList.php")

    params = auth_params()
    params.update({"f": "1", "i": console_id})
    games = http.get(endpoint, headers = {"User-Agent": "pixlet"}, params = params, ttl_seconds = ONE_HOUR_IN_SECONDS * 24 * 7).json()
    return games

def get_game_info(game_id):
    endpoint = "%s/%s" % (RA_API_URL, "API_GetGameExtended.php")

    params = auth_params()
    params.update({"i": game_id})
    game_data = http.get(endpoint, headers = {"User-Agent": "pixlet"}, params = params, ttl_seconds = ONE_HOUR_IN_SECONDS).json()
    ra_aches = game_data["Achievements"]
    achievements = ra_aches.values()
    achs = []
    for ach in achievements:
        achs.append({
            "title": ach["Title"],
            "description": ach["Description"],
            "order": ach["DisplayOrder"],
        })
    achs = sorted(achs, key = lambda x: x["order"])

    parsed_title = game_data["Title"].replace("~Prototype~", "").replace("~Hack~", "").replace("~Homebrew~", "")

    return {
        "title": parsed_title,
        "image": game_data["ImageIcon"],
        "console": game_data["ConsoleName"],
        "achievements": achs,
    }

def get_random_game_from_console(console_id):
    console_games = get_games_from_console(console_id)
    game = console_games[random.number(0, len(console_games) - 1)]
    return str(int(game["ID"]))

def get_random_game_from_any():
    endpoint = "%s/%s" % (RA_URL, "/random.php")
    return http.get(endpoint, headers = {"User-Agent": "pixlet"}, ttl_seconds = ONE_HOUR_IN_SECONDS).url.split("/")[-1]

def get_img_data(img_path):
    endpoint = "%s/%s" % (RA_URL, img_path)
    return http.get(endpoint, headers = {"User-Agent": "pixlet"}, ttl_seconds = ONE_HOUR_IN_SECONDS).body()

def main(config):
    if auth_params()["y"] == "":
        return []

    console = str(config.str("console", "6"))
    console_cache_key = "console-%s" % console
    game_id = cache.get(console_cache_key)
    if game_id == None:
        game_id = get_random_game_from_any() if console == "0" else get_random_game_from_console(console)
        cache.set(console_cache_key, game_id, ttl_seconds = TEN_MINUTES_IN_SECONDS)
    game = get_game_info(game_id)

    total_achievements_count = len(game["achievements"])

    achievement = game["achievements"][random.number(0, total_achievements_count - 1)]
    game_title = game["title"]
    ach_title = achievement["title"]
    ach_description = achievement["description"]

    top_bar = render.Row(
        children = [
            render.Stack(children = [
                render.Box(color = "#ff0", width = 10, height = 7),
                render.Padding(child = render.Image(src = ICON, width = 8, height = 5), pad = (1, 1, 1, 0)),
            ]),
            render.Stack(children = [
                render.Box(color = "#0000ff", width = 64, height = 7),
                render.Padding(child = render.Marquee(width = 56, delay = 20, child = render.Text(content = game_title, font = "tom-thumb", color = "#ff0")), pad = (1, 1, 0, 0)),
            ]),
        ],
        main_align = "space-between",
        cross_align = "start",
    )

    body = render.Row(
        children = [
            render.Padding(child = render.Image(src = get_img_data(game["image"]), width = 20, height = 20), pad = (0, 0, 1, 0)),
            render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        delay = 20,
                        offset_start = 0,
                        scroll_direction = "vertical",
                        child = render.Column(children = [
                            render.WrappedText(content = ach_title, color = "#ff0"),
                            render.WrappedText(content = ach_description),
                        ]),
                    ),
                ],
            ),
        ],
        cross_align = "center",
    )

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                top_bar,
                body,
            ],
        ),
    )

options = [
    schema.Option(
        display = opt["Name"],
        value = str(opt["ID"]),
    )
    for opt in CONSOLES
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "console",
                name = "Console",
                desc = "Only get games from a certain console",
                default = options[0].value,
                options = options,
                icon = "gamepad",
            ),
        ],
    )

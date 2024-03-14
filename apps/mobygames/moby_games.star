"""
Applet: Moby Games
Summary: Game info from MobyGames
Description: Display information about random games from the extensive MobyGames database. Includes basic information such as a thumbnail, year of release, etc.
Author: pandincus

Big thanks to MobyGames for offering the Moby Games API https://www.mobygames.com/info/api/ free of charge
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("secret.star", "secret")

# Root url for the Moby Games API
MOBY_GAMES_API_ROOT_URL = "https://api.mobygames.com/v1/"

# Random games API endpoint
# See docs here: https://www.mobygames.com/info/api/#gamesrandom
RANDOM_GAMES_API = MOBY_GAMES_API_ROOT_URL + "games/random?api_key={api_key}&limit=100&format=normal"

# Encrypted API key for the Moby Games API, with the app id moby-games
API_KEY_ENCRYPTED = "AV6+xWcEc6rPe1wSqCqAHZkWBJ4GSzaFNCqdo40f93LRwkKpGiZbRiUWNjvw/TlvYM0VvaAYmj/Adz1DPRZpxzfkT+rp4hZ0kv14oN56eXOH0v2vhCOos3bSQcSwl9C7Xr7UtLcfElIGR7piA/dXbEq31YTylXd9jDPvdUk/kw4KGlmlmSA="

# MobyGames API requests are limited to 360 per hour, or one every 10 seconds
# We can retrieve up to 100 games per request, and we cache the results for 1 hour,
# so you'll see a randomly selected game out of 100 for all the renders during that hour
CACHE_TTL_SECONDS = 60 * 60 * 1
CACHE_KEY = "mobygames_game_data"

# Store a default game, hard-coded from the Moby Games database, so that we can render something
# in the event of a network failure, or if the Moby Games API is down, or if we haven't yet
# provided an API key (e.g. when Tidbyt renders preview gifs for the app store)
# For now, we've selected Captive (1990 on the Amiga)
DEFAULT_GAME_INFO = {
    "description": "\u003cp\u003eYou awake in prison, without the memory of who you are, where you are and why you are imprisoned. In the corner of your cell you find a briefcase computer, which gives you the control over a unit of four droids. Now you must use these droids to find yourself, and free yourself. \u003c/p\u003e\n\u003cp\u003e\u003cem\u003eCaptive\u003c/em\u003e has a sci-fi setting, but resembles more a fantasy RPGs with robots and droids. With the help of the droids you explore tech-dungeons and seek information, which leads to the next planet(s) on a path, the end of which is your cell.\u003c/p\u003e\n\u003cp\u003eThe movement and fighting is similar to games like \u003ca href=\"https://www.mobygames.com/search/?q=Eye+of+the+Beholder\"\u003eEye of the Beholder\u003c/a\u003e, but you can buy droid parts in shops beside the usual weapons and items. The droids haven't levels like in \"normal\" role-playing games; you must buy upgrades for the different parts of the droids, which make them stronger and faster. You can also buy a variety of chips, which allow the droids to see in darkness, invert the gravity or simple to shield a little period of time.\u003c/p\u003e",
    "genres": [
        {"genre_category": "Basic Genres", "genre_name": "Role-playing (RPG)"},
        {"genre_category": "Perspective", "genre_name": "1st-person"},
        {"genre_category": "Setting", "genre_name": "Sci-fi / futuristic"},
    ],
    "id": "5330.0",
    "moby_score": 7.7,
    "num_votes": 21,
    "platforms": [
        {"first_release_date": "1992", "platform_name": "DOS"},
        {"first_release_date": "1990", "platform_name": "Amiga"},
        {"first_release_date": "1990", "platform_name": "Atari ST"},
    ],
    "thumbnail_image": "https://cdn.mobygames.com/316c16a8-abb8-11ed-a188-02420a00019a.webp",
    "title": "Captive",
}

### -------------------------------------------------- ###
###                   Helper functions                 ###
### -------------------------------------------------- ###
def debug_print(debug, string):
    """Prints a string to the console, but only if the debug parameter is set to true

    Args:
        debug (bool): whether or not debug mode is enabled, which determines whether or not to print
        string (str): the string to print

    Returns:
        None
    """
    if debug:
        print(string)

def load_and_cache_random_games(api_key, debug = False, bypass_cache = False):
    """Loads a random game from the MobyGames API, and caches it for CACHE_TTL_SECONDS seconds

    Args:
        api_key (str): the API key to use when making requests to the MobyGames API
        debug (bool): whether or not debug mode is enabled, which determines whether or not to print log messages
        bypass_cache (bool): whether or not to bypass the cache

    Returns:
        A dict of games, where the key is the game_id, and each object is a dict containing information about the game
    """

    # If we're not bypassing the cache, try to load the games from the cache
    cached_games_string = cache.get(CACHE_KEY)
    if bypass_cache == False and cached_games_string != None:
        debug_print(debug, "[Cache] Random Games cache hit, found bytes: " + str(len(cached_games_string)))
        return json.decode(cached_games_string)

    # If we're bypassing the cache, or if the cache was empty, load the games from the API
    debug_print(debug, "[Cache] Random Games cache miss, loading from API")
    response = http.get(RANDOM_GAMES_API.format(api_key = api_key))
    if response.status_code != 200:
        # If the call failed, print the error code to debug (if we're debugging), and return an empty dict
        debug_print(debug, "[HTTP] Moby Games API returned non-200 status code: " + str(response.status_code))
        return {}

    # Decode the response
    response_json = response.json()
    if response_json == None:
        # If the decode failed, print a message to debug (if we're debugging), and return an empty dict
        debug_print(debug, "[HTTP] Failed to decode response from Moby Games API")
        return {}

    # Construct a dict of dicts containing information about each game
    # We specifically are interested in the following fields:
    # * title - the title of the game
    # * description - a long description of the game
    # * moby_score - the MobyScore of the game
    # * num_votes - the number of votes the game has received on MobyGames
    # * platforms - a list of platforms the game is available on (note: each platform is a dict containing a platform_name and first_release_date)
    # * genres - a list of genres the game belongs to (note: each genre is a dict containing a genre_name and genre_category)
    # * sample_cover - a dict containing information about the game's cover art (note: this is a dict containing only one field we care about: thumbnail_image

    # Construct a dict of dicts containing information about each game
    games = {}
    for game in response_json["games"]:
        # Construct a dict containing information about the game
        game_info = {}
        game_info["id"] = str(game["game_id"])
        game_info["title"] = game["title"]
        game_info["description"] = game["description"]
        game_info["moby_score"] = game["moby_score"]
        game_info["num_votes"] = game["num_votes"]
        game_info["platforms"] = []
        game_info["genres"] = []

        # Add information about each platform the game is available on
        for platform in game["platforms"]:
            game_info["platforms"].append({
                "platform_name": platform["platform_name"],
                "first_release_date": platform["first_release_date"],
            })

        # Add information about each genre the game belongs to
        for genre in game["genres"]:
            game_info["genres"].append({
                "genre_name": genre["genre_name"],
                "genre_category": genre["genre_category"],
            })

        # Add information about the game's cover art
        game_info["thumbnail_image"] = game["sample_cover"]["thumbnail_image"]

        # Add the game to the games dict, keyed by the game ID
        games[game_info["id"]] = game_info

    # Cache the games for CACHE_TTL_SECONDS seconds
    cache.set(CACHE_KEY, json.encode(games), CACHE_TTL_SECONDS)
    debug_print(debug, "[Cache] Random Games cache set, bytes: " + str(len(json.encode(games))))

    return games

def render_output(title, moby_score, description, first_platform_name, first_platform_release_date, image_content):
    """Return the rendered output for the given game information
    """

    # Construct the output
    # That should be a row with two columns, where the left column is the thumbnail image, and the right column is the game title
    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [image_content],
                ),
                render.Column(
                    children = [
                        # Inside of a colored box, display the title and moby score in a marquee, like so: "Title (7.8)"
                        render.Box(
                            width = 40,
                            height = 8,
                            color = "#540007",
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    font = "tb-8",
                                    content = title + " (" + moby_score + ")",
                                ),
                            ),
                        ),
                        # Display the description in a vertical scrolling marquee
                        render.Marquee(
                            height = 19,
                            scroll_direction = "vertical",
                            child = render.WrappedText(
                                font = "CG-pixel-4x5-mono",
                                width = 40,
                                content = description,
                            ),
                        ),
                        # Inside of a colored box, display the first platform and release date in a scrolling marquee, like so: "Platform (YYYY-MM-DD)"
                        render.Box(
                            width = 40,
                            height = 5,
                            color = "#540007",
                            child = render.Marquee(
                                width = 40,
                                child = render.Text(
                                    font = "CG-pixel-4x5-mono",
                                    content = first_platform_name + " " + first_platform_release_date,
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

### -------------------------------------------------- ###
###                  Main Applet Logic                 ###
### -------------------------------------------------- ###
def main(config):
    """Main function, invoked by the Pixlet runtime

    Args:
      config (dict): a dictionary of configuration parameters, passed in by the Pixlet runtime
                     The following parameters are supported:
                        - api_key: the API key to use when making requests to the MobyGames API when running locally
                        - debug: whether or not to print debug statements to the console (set to true to enable)
                        - bypass_cache: whether or not to bypass the cache and make a network request directly to the MobyGames API
                     Supply the config parameter when using the pixlet render command
                        For example, pixlet render moby_games.star api_key=my_api_key debug=true
                     Or, when using the pixlet serve command, you can pass the same paramters via query string
                        For example, http://localhost:8080/?api_key=my_api_key&debug=true

    Returns:
        render.Root: The rendered output
    """

    # Load the config parameters
    debug = config.get("debug") != None and config.get("debug").lower() == "true"
    bypass_cache = config.get("bypass_cache") != None and config.get("bypass_cache").lower() == "true"

    # Decrypt the hardcoded API key, or use the api_key config parameter if running locally
    api_key = secret.decrypt(API_KEY_ENCRYPTED)
    if api_key == None:
        debug_print(debug, "[Config] Unable to decrypt API key, falling back to api_key config parameter")
        api_key = config.get("api_key")
        if api_key == None:
            debug_print(debug, "[Config] No API key specified, please specify an API key using the api_key config parameter when running locally")
        else:
            debug_print(debug, "[Config] API key loaded from config parameter")
    else:
        debug_print(debug, "[Config] API key decrypted successfully")

    # If we were able to get an API key, load the game data from the MobyGames API
    if api_key != None:
        games = load_and_cache_random_games(api_key, debug, bypass_cache)
    else:
        # Otherwise, assume an empty dict. We'll fall back to the default game info later.
        games = {}

    # Pick a random game from the list of games
    game_ids_list = games.keys()
    random_game = {}
    if len(game_ids_list) == 0:
        debug_print(debug, "[Main] No games found. Falling back to default.")
        random_game = DEFAULT_GAME_INFO
    else:
        random_game_index = random.number(0, len(game_ids_list) - 1)
        random_game_id = game_ids_list[random_game_index]
        random_game = games[random_game_id]

    debug_print(debug, "[Main] Selected game: " + json.encode(random_game))

    # Compute the first platform by looking at all platforms the game is available on, and picking the earliest date
    # Note that the dates are represented as strings in ISO 8601 YYYY-MM-DD format, which is lexicographically sortable,
    # so we can just sort the list of dates and pick the first one
    first_platform = None
    for platform in random_game["platforms"]:
        if first_platform == None or platform["first_release_date"] < first_platform["first_release_date"]:
            first_platform = platform

    # Use the html library to clean up the text from the title and description
    # This should strip out html tags, and convert encoded html entities to their decoded values
    description_html = html(random_game["description"])
    description = description_html.text()
    title_html = html(random_game["title"])
    title = title_html.text()

    game_for_render = {
        "title": title,
        "moby_score": str(random_game["moby_score"]),
        "description": description,
        "platform_name": first_platform["platform_name"],
        "first_release_date": first_platform["first_release_date"],
        "image_content": render.Image(
            src = http.get(random_game["thumbnail_image"]).body(),
            width = 24,
            height = 32,
        ),
    }

    return render_output(
        title = game_for_render["title"],
        moby_score = game_for_render["moby_score"],
        description = game_for_render["description"],
        first_platform_name = game_for_render["platform_name"],
        first_platform_release_date = game_for_render["first_release_date"],
        image_content = game_for_render["image_content"],
    )

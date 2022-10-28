"""
Applet: Roblox
Summary: Online friends & games
Description: Real time views of your Roblox experiences.
Author: Chad Milburn / CODESTRONG
"""

load("http.star", "http")
load("time.star", "time")
load("cache.star", "cache")
load("schema.star", "schema")
load("render.star", "render")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")

### CONSTANTS
TTL_SECONDS = 240
TRIO_CIRCLES_TOP_OFFSET = 12

### DEFAULTS
DEFAULT_DARK_MODE = True
DEFAULT_USER_NAME = "C0DESTR0NG"
DEFAULT_ACCENT_COLOR = "#f77a24"

### VIEW MODES
VIEW_FRIENDS = "view_friends"
VIEW_FAVORITE_GAMES = "view_favorite_games"

def main(config):
    ### SET VIEW MODE FROM APP CONFIG SETTINGS
    view_mode = config.str("view_mode") if config.str("view_mode") != None and config.str("view_mode") != "" else VIEW_FRIENDS

    ### SET ACCENT COLOR FROM APP CONFIG SETTINGS
    accent_color = config.str("accent_color") if config.str("accent_color") != None and config.str("accent_color") != "" else DEFAULT_ACCENT_COLOR

    ### SET IS DARK MODE FROM APP CONFIG SETTINGS
    dark_mode = config.bool("dark_mode") if config.bool("dark_mode") != None and config.bool("dark_mode") != "" else DEFAULT_DARK_MODE

    ### SET USERNAME
    username = config.str("username") if config.str("username") != None and config.str("username") != "" else DEFAULT_USER_NAME

    ### GET USER ID
    user_id_cached = cache.get("user_id_%s" % username)
    if user_id_cached != None and user_id_cached != str(""):
        print("Using cached user id")
        userRobloxId = str(user_id_cached)
    else:
        getUserId = "https://users.roblox.com/v1/users/search?keyword=%s&limit=10" % username
        repGetUserId = http.get(getUserId)
        if repGetUserId.status_code == 200:
            print("Fetching user id")
            userId = "%d" % repGetUserId.json()["data"][0]["id"] if len(repGetUserId.json()["data"]) > 0 else ""
            userRobloxId = "%s" % userId
            cache.set("user_id_%s" % username, str(userRobloxId), ttl_seconds = TTL_SECONDS)
        else:
            userRobloxId = ""

    ### RETURN AND SHOW 'USER NOT FOUND' SCREEN IF FAILS TO GET USER ID
    if userRobloxId == None or userRobloxId == "":
        print("User id not found")

        return render.Root(
            child = render.Stack(
                children = [
                    render.Padding(
                        pad = (2, 2, 0, 0),
                        child = render.Row(
                            children = [
                                render.Stack(
                                    children = [
                                        render.Circle(
                                            color = "#888",
                                            diameter = 21,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (19, 19, 0, 0),
                        child = render.Circle(
                            color = "#333",
                            diameter = 4,
                        ),
                    ),
                    render.Padding(
                        pad = (9, 25, 0, 0),
                        child = render.Marquee(
                            width = 64,
                            child = render.Text(content = "User not found. User not found.", font = "tom-thumb"),
                        ),
                    ),
                    render.Padding(
                        pad = (1, 24, 0, 0),
                        child = render.Image(src = ROBLOX_DARK_LOGO, width = 7, height = 7),
                    ),
                ],
            ),
        )

    ### GET USER AVATAR
    user_avatar_cached = cache.get("user_avatar_%s" % username)
    if user_avatar_cached != None and user_avatar_cached != str(""):
        print("Using cached user avatar")
        profilePhotoImg = str(user_avatar_cached)
    else:
        print("Fetching user avatar")
        getProfilePhoto = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=60x60&format=Png&isCircular=true" % userRobloxId
        repGetProfilePhoto = http.get(getProfilePhoto)
        if repGetProfilePhoto.status_code != 200:
            print("Fetching user avatar failed with status %d" % repGetProfilePhoto.status_code)
            profilePhotoImg = ""
        else:
            profilePhotoUrl = repGetProfilePhoto.json()["data"][0]["imageUrl"]
            profilePhotoImg = http.get(profilePhotoUrl).body()

        ### Caching profilePhotoImg value from fetched logic
        cache.set("user_avatar_%s" % username, str(profilePhotoImg), ttl_seconds = TTL_SECONDS)

    ### GET ONLINE STYLE
    user_online_status_cached = cache.get("user_online_status_%s" % username)
    if user_online_status_cached != None and user_online_status_cached != str(""):
        print("Using cached user online status")
        isOnline = json.decode(user_online_status_cached)
    else:
        print("Fetching user online status")
        getUserOnlineStatus = "https://api.roblox.com/users/%s/onlinestatus/" % userRobloxId
        repGetUserOnlineStatus = http.get(getUserOnlineStatus)
        if repGetUserOnlineStatus.status_code != 200:
            print("Fetching user online status failed with status %d" % repGetUserOnlineStatus.status_code)
            isOnline = False
        else:
            isOnline = repGetUserOnlineStatus.json()["IsOnline"]

        ### Caching isOnline value from fetched logic
        cache.set("user_online_status_%s" % username, json.encode(isOnline), ttl_seconds = TTL_SECONDS)

    ### FRIEND MODE
    if view_mode == VIEW_FRIENDS:
        ### GET USER FRIENDS
        user_friend_list_cached = cache.get("user_friend_list_%s" % username)
        if user_friend_list_cached != None and user_friend_list_cached != str(""):
            print("Using cached user friend list")
            userFriends = json.decode(user_friend_list_cached)
        else:
            print("Fetching user friend list")
            getUsersFriends = "https://friends.roblox.com/v1/users/%s/friends?userSort=StatusFrequents" % userRobloxId
            repGetUsersFriends = http.get(getUsersFriends)
            if repGetUsersFriends.status_code != 200:
                print("Fetching user friend list failed with status %d" % repGetUsersFriends.status_code)
                userFriends = []
            else:
                userFriends = repGetUsersFriends.json()["data"]

            ### Caching userFriends value from fetched logic
            cache.set("user_friend_list_%s" % username, json.encode(userFriends), ttl_seconds = TTL_SECONDS)

        ### POPULATE FRIENDS LIST
        friendsList = []
        for friend in userFriends:
            getUserAvatar = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=48x48&format=Png&isCircular=true" % friend["id"]
            repGetUserAvatar = http.get(getUserAvatar)
            friendObject = {"username": friend["name"], "id": "%d" % friend["id"], "isOnline": friend["isOnline"], "avatarUrl": repGetUserAvatar.json()["data"][0]["imageUrl"]}
            friendsList.append(friendObject)

        ### SORT BY ONLINE STATUS
        friendsList = sorted(friendsList, key = lambda f: f["isOnline"], reverse = True)

        ### BUILD FRIEND RENDER LIST
        renderFriend = []
        for friend in range(3):
            friend_avatar_cached = cache.get("user_avatar_%s" % friendsList[friend]["username"]) if friend < len(userFriends) else ""

            if friend_avatar_cached != None and friend_avatar_cached != str(""):
                print("Using cached friend avatar")
                friendAvatar = str(friend_avatar_cached)
            else:
                print("Fetching friend avatar")
                friendAvatar = ""
                if len(userFriends) != 0 and friend < len(userFriends):
                    friendAvatarUrl = friendsList[friend]["avatarUrl"]
                    friendAvatar = http.get(friendAvatarUrl).body()

                ### Caching friendAvatar value from fetched logic
                if friend < len(userFriends):
                    cache.set("user_avatar_%s" % friendsList[friend]["username"], str(friendAvatar), ttl_seconds = TTL_SECONDS)

            renderFriend.append(
                render.Padding(
                    pad = (25 + (13 * friend), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#333" if dark_mode == True else "#222",
                                        diameter = 11,
                                    ),
                                    render.Image(src = friendAvatar, width = 11, height = 11) if friendAvatar != "" else render.Text(content = ""),
                                    render.Padding(
                                        pad = (10, 10, 0, 0),
                                        child = render.Circle(
                                            color = "#0f0" if len(userFriends) != 0 and friend < len(userFriends) and friend != len(userFriends) and friendsList[friend]["isOnline"] else "#888",
                                            diameter = 1,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )

        ### FAVORITE GAME MODE
    else:
        ### GET USER FAVORITE GAMES
        user_favorite_games_list_cached = cache.get("user_favorite_games_list_%s" % username)
        if user_favorite_games_list_cached != None and user_favorite_games_list_cached != str(""):
            print("Using cached user favorite game list")
            userFavoriteGames = json.decode(user_favorite_games_list_cached)
        else:
            print("Fetching user favorite game list")
            getUsersFavoriteGames = "https://games.roblox.com/v2/users/%s/favorite/games?accessFilter=Public&sortOrder=Desc&limit=10" % userRobloxId
            repGetUsersFavoriteGames = http.get(getUsersFavoriteGames)
            if repGetUsersFavoriteGames.status_code != 200:
                print("Fetching user favorite game list failed with status %d" % repGetUsersFavoriteGames.status_code)
                userFavoriteGames = []
            else:
                userFavoriteGames = repGetUsersFavoriteGames.json()["data"]

            ### Caching userFavoriteGames value from fetched logic
            cache.set("user_favorite_games_list_%s" % username, json.encode(userFavoriteGames), ttl_seconds = TTL_SECONDS)

        ### POPULATE FAVORITE GAMES RENDER LIST
        favoriteGamesList = []
        for game in userFavoriteGames:
            getGameAvatar = "https://thumbnails.roblox.com/v1/games/icons?universeIds=%d&size=50x50&format=Png&isCircular=false" % game["id"]
            repGetUserGame = http.get(getGameAvatar)
            gameObject = {"gameId": "%d" % game["id"], "avatarUrl": repGetUserGame.json()["data"][0]["imageUrl"]}
            favoriteGamesList.append(gameObject)

        ### BUILD POPULATE FAVORITE GAMES
        renderGame = []
        for game in range(3):
            game_avatar_cached = cache.get("game_avatar_%s" % favoriteGamesList[game]["gameId"]) if game < len(userFavoriteGames) else ""

            if game_avatar_cached != None and game_avatar_cached != str(""):
                print("Using cached game avatar")
                gameAvatar = str(game_avatar_cached)
            else:
                print("Fetching game avatar")
                gameAvatar = ""
                if len(userFavoriteGames) != 0 and game < len(userFavoriteGames):
                    gameAvatarUrl = favoriteGamesList[game]["avatarUrl"]
                    gameAvatar = http.get(gameAvatarUrl).body()

                ### Caching gameAvatar value from fetched logic
                if game < len(userFavoriteGames):
                    cache.set("game_avatar_%s" % favoriteGamesList[game]["gameId"], str(gameAvatar), ttl_seconds = TTL_SECONDS)

            renderGame.append(
                render.Padding(
                    pad = (25 + (13 * game), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(
                                        color = "#333",
                                        width = 11,
                                        height = 11,
                                    ),
                                    render.Image(src = gameAvatar, width = 11, height = 11) if gameAvatar != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
            )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    color = "#000" if dark_mode == True else "#fff",
                    width = 64,
                    height = 32,
                ),
                render.Padding(
                    pad = (2, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#fff" if dark_mode == True else "#222",
                                        diameter = 21,
                                    ),
                                    render.Image(src = profilePhotoImg, width = 21, height = 21) if profilePhotoImg != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (19, 19, 0, 0),
                    child = PULSATING_ONLINE_DOT if isOnline else render.Circle(diameter = 4, color = "#888"),
                ),
                render.Padding(
                    pad = (30, 4, 0, 0),
                    child = render.Text(content = "friends", font = "CG-pixel-3x5-mono", color = accent_color),
                ) if view_mode == VIEW_FRIENDS else render.Padding(
                    pad = (26, 4, 0, 0),
                    child = render.Text(content = "favorites", font = "CG-pixel-3x5-mono", color = accent_color),
                ),
                render.Padding(
                    pad = (10, 26, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(content = "%s" % username, color = "#c7d0d8" if dark_mode == True else "#333", font = "CG-pixel-4x5-mono"),
                    ),
                ),
                render.Padding(
                    pad = (1, 24, 0, 0),
                    child = render.Image(src = ROBLOX_DARK_LOGO if dark_mode == True else ROBLOX_LIGHT_LOGO, width = 7, height = 7),
                ),
                renderFriend[0] if view_mode == VIEW_FRIENDS else renderGame[0],
                renderFriend[1] if view_mode == VIEW_FRIENDS else renderGame[1],
                renderFriend[2] if view_mode == VIEW_FRIENDS else renderGame[2],
            ],
        ),
    )

def get_schema():
    userIcons = ("userAstronaut", "userDoctor", "userTie", "userNurse", "userNinja")
    randomUserIcon = userIcons[time.now().second % 5]

    cubesIcons = ("cube", "cubes", "cubesStacked")
    randomCubeIcon = cubesIcons[time.now().second % 3]

    colorIcons = ("droplet", "palette", "eyeDropper")
    randomColorIcon = colorIcons[time.now().second % 3]

    darkModeIcons = ("sun", "moon", "lightbulb")
    randomDarkModeIcon = darkModeIcons[time.now().second % 3]

    view_mode_options = [
        schema.Option(
            display = "Online Friends",
            value = VIEW_FRIENDS,
        ),
        schema.Option(
            display = "Favorite Games",
            value = VIEW_FAVORITE_GAMES,
        ),
    ]

    accent_color_options = [
        schema.Option(
            display = "White",
            value = "#fff",
        ),
        schema.Option(
            display = "Red",
            value = "#f72525",
        ),
        schema.Option(
            display = "Orange",
            value = "#f77a24",
        ),
        schema.Option(
            display = "Yellow",
            value = "#f7cd25",
        ),
        schema.Option(
            display = "Green",
            value = "#25f739",
        ),
        schema.Option(
            display = "Blue",
            value = "#1a57f0",
        ),
        schema.Option(
            display = "Purple",
            value = "#8329e9",
        ),
        schema.Option(
            display = "Pink",
            value = "#fe2fe8",
        ),
        schema.Option(
            display = "Gray",
            value = "#444",
        ),
        schema.Option(
            display = "Clear",
            value = "#000",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Roblox username",
                desc = "Enter a Roblox username",
                icon = randomUserIcon,
                default = "",
            ),
            schema.Dropdown(
                id = "view_mode",
                name = "View mode",
                desc = "Display your friends or games",
                icon = randomCubeIcon,
                default = view_mode_options[0].value,
                options = view_mode_options,
            ),
            schema.Dropdown(
                id = "accent_color",
                name = "Accent color",
                desc = "Choose an accent color",
                icon = randomColorIcon,
                default = accent_color_options[0].value,
                options = accent_color_options,
            ),
            schema.Toggle(
                id = "dark_mode",
                name = "Dark mode",
                desc = "Toggle between light and dark modes",
                icon = randomDarkModeIcon,
                default = True,
            ),
        ],
    )

PULSATING_ONLINE_DOT = render.Animation(
    children = [
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
    ],
)

ROBLOX_LIGHT_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAFAAAABRCAYAAABFTSEIAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlk
Ij8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDcuMi1jMDAwIDc5LjFiNjVhNzliNCwgMjAyMi8wNi8xMy0yMjowMTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3Lncz
Lm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAv
c1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RTM0OTQzODgyQzYyMTFFREFEQkNFREVGREZCRTRCMDgiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RTM0
OTQzODcyQzYyMTFFREFEQkNFREVGREZCRTRCMDgiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKE1hY2ludG9zaCkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1MTM2MzIwNzJCQjMxMUVEQTAzMEVB
NzQ5NTRFQjY2MyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1MTM2MzIwODJCQjMxMUVEQTAzMEVBNzQ5NTRFQjY2MyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PvmtxvYAABbBSURBVHja
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
""")

ROBLOX_DARK_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAFAAAABRCAYAAABFTSEIAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlk
Ij8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDcuMi1jMDAwIDc5LjFiNjVhNzliNCwgMjAyMi8wNi8xMy0yMjowMTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3Lncz
Lm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAv
c1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTI2Qjc0RUIyQzYzMTFFREFEQkNFREVGREZCRTRCMDgiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTI2
Qjc0RUEyQzYzMTFFREFEQkNFREVGREZCRTRCMDgiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKE1hY2ludG9zaCkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1MTM2MzIwNzJCQjMxMUVEQTAzMEVB
NzQ5NTRFQjY2MyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1MTM2MzIwODJCQjMxMUVEQTAzMEVBNzQ5NTRFQjY2MyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/fQwUAACDHSURBVHja
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
RK5CYII=
""")

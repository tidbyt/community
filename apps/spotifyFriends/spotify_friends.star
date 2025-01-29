"""
Applet: Spotify Friends
Summary: Spotify friend activity
Description: Displays last listening activity for random spotify friend.
Author: klaffitte
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

spotifyTokenUrl = "https://open.spotify.com/get_access_token?reason=transport&productType=web_player"
spotifyFriendUrl = "https://guc-spclient.spotify.com/presence-view/v1/buddylist"

def main(config):
    configCookie = config.get("spDcCookie")
    username = config.get("username")
    if type(configCookie) == "string" and type(username) == "string":
        spDcCookie = "sp_dc=" + str(configCookie)

        tokenResponse = getAuthToken(spotifyTokenUrl, spDcCookie, username)
        if tokenResponse["status"] != 200:
            return render.Root(
                child = render.WrappedText("token request failed, status: ", tokenResponse["status"]),
            )

        else:
            friendResponse = getFriendData(spotifyFriendUrl, tokenResponse["token"], username)
            if friendResponse["status"] != 200:
                return render.Root(
                    child = render.WrappedText("friend data request failed, status: ", friendResponse["status"]),
                )

            else:
                index = generateIndex(friendResponse["friendData"])

                imageResponse = getImage(friendResponse["friendData"], index)
                if imageResponse["status"] != 200:
                    return render.Root(
                        child = render.WrappedText("image request failed, status: ", imageResponse["status"]),
                    )

                else:
                    return render.Root(
                        child = render.Padding(
                            pad = 2,
                            child = render.Column(
                                expanded = True,
                                main_align = "space_between",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(
                                            content = friendResponse["friendData"]["friends"][index]["user"]["name"],
                                            offset = 1,
                                            color = "#1DB954",
                                        ),
                                    ),
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        children = [
                                            render.Image(
                                                width = 20,
                                                src = imageResponse["image"],
                                            ),
                                            render.Column(
                                                expanded = True,
                                                main_align = "space_between",
                                                children = [
                                                    render.Marquee(
                                                        width = 38,
                                                        child = render.Text(
                                                            content = friendResponse["friendData"]["friends"][index]["track"]["name"],
                                                        ),
                                                    ),
                                                    render.Marquee(
                                                        width = 38,
                                                        child = render.Text(
                                                            content = friendResponse["friendData"]["friends"][index]["track"]["artist"]["name"],
                                                            offset = 1,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    )

    else:
        return render.Root(
            child = render.WrappedText("missing username or sp_dc cookie"),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "spDcCookie",
                name = "spDc Cookie",
                desc = "Your Spotify web browser authentication cookie",
                icon = "spotify",
            ),
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Your Spotify username (not display name)",
                icon = "user",
            ),
        ],
    )

#get auth token
def getAuthToken(spotifyTokenUrl, spDcCookie, username):
    tokenCache = cache.get("token" + username)
    if tokenCache != None:
        print("using cached token")
        tokenResponse = {
            "token": tokenCache,
            "status": 200,
        }
        return tokenResponse
    else:
        print("no cached token, calling spotify API")
        res = http.get(spotifyTokenUrl, headers = {"Cookie": spDcCookie})
        resForm = res.json()
        accessToken = "Bearer " + resForm["accessToken"]
        cache.set("token" + username, accessToken, ttl_seconds = 1800)
        tokenResponse = {
            "token": accessToken,
            "status": res.status_code,
        }
        return tokenResponse

#get friend data
def getFriendData(spotifyFriendUrl, accessToken, username):
    friendCache = cache.get("friend" + username)
    if friendCache != None:
        print("using cached friend data")
        friendResponse = {
            "friendData": json.decode(friendCache),
            "status": 200,
        }
        return friendResponse
    else:
        print("no cached token, calling spotify API")
        res = http.get(spotifyFriendUrl, headers = {"Authorization": accessToken})
        friendData = res.json()
        cache.set("friend" + username, json.encode(friendData), ttl_seconds = 120)
        friendResponse = {
            "friendData": friendData,
            "status": res.status_code,
        }
        return friendResponse

def generateIndex(friendData):
    friendNum = len(friendData["friends"]) - 1
    index = random.number(0, friendNum)
    return index

#get cover art
def getImage(friendData, index):
    res = http.get(friendData["friends"][index]["track"]["imageUrl"])
    image = res.body()
    imageResponse = {
        "image": image,
        "status": res.status_code,
    }
    return imageResponse

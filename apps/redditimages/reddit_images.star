"""
Applet: Reddit Images
Summary: Shuffle Subreddit Images
Description: Show a random image post from a custom list of subreddits (up to 10) and/or a list of default subreddits. Use the ID displayed to access the post on a computer, at http://www.reddit.com/{id}. All fields are optional.
Author: Nicole Brooks
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_SUBREDDITS = ["blackcats", "aww", "eyebleach", "itookapicture", "cats", "pic", "otters", "plants"]
APPROVED_FILETYPES = [".png", ".jpg", ".jpeg", ".bmp"]

ERROR_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACMAAAAjCAYAAAAe2bNZAAAAAXNSR0IArs4c6QAAAXJJREFUWEftlz1OAzEQhe1V
+tCQnoarUADHgQJqUoTjAAVXoaEPDemjNZpEI00Wz4+fttiVkjLOe/k8nhmPc5rQJ0+IJc0D5vZy+dTl/KJFri/l
+eNnt5briEbqq5Fh0+uuqKf41eckgRDN0LwKc7+6KAxy1f3n+e6P3xHQ2/b34IFommBqIGxAQDWYFk0Y5mahHxGb
fO5PI9OqOcPICMhohiJzt1o+5JQ3VtjJtKTy+L7dvZIpognBcHV4MFxJbEoV1apx+8wZJiX9bkJCjmhCx2Ql5DB5
2RDRhGCsvLHKU4uOpWEgc4RAjBHN/GBqOaDli5U3niYUGTka0G08vKm1YYfHiRYNebljp5xThjOMB8PrctTQNPOD
4bzhHcnLUdsloglFxgrr2GtuziC7RDRuZCZV2kg3RTShPoMYI5owDL2f5PPDa3yy4fGfeJoQDOeMfFlSA7PKG9GE
YOhHSGUgGreaxu4jnp/bZzyDMdcnBfMH+p/AM/kQywMAAAAASUVORK5CYII=
""")

def main(config):
    # Build full sub list based on user options.
    allSubs = combineSubs(config)

    # Get subreddit name and chosen post (pseudo)randomly.
    chosenSub = allSubs[getRandomNumber(len(allSubs))]
    currentPost = getPosts(chosenSub)

    # Render image/text
    if currentPost["id"] != "00000":
        imgSrc = http.get(currentPost["url"]).body()
    else:
        imgSrc = ERROR_IMG
    return render.Root(
        child =
            render.Box(
                color = "#0f0f0f",
                child = render.Row(
                    children = [
                        render.Image(
                            src = imgSrc,
                            width = 35,
                            height = 35,
                        ),
                        render.Padding(
                            expanded = True,
                            pad = 1,
                            child = render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                children = [
                                    render.Marquee(
                                        width = 28,
                                        child = render.Text(
                                            content = currentPost["title"],
                                            font = "tom-thumb",
                                            color = "#8899A6",
                                        ),
                                    ),
                                    render.Marquee(
                                        width = 28,
                                        child = render.Text(
                                            content = currentPost["sub"],
                                            font = "tom-thumb",
                                            color = "#6B8090",
                                        ),
                                    ),
                                    render.Text(
                                        content = currentPost["id"],
                                        font = "tom-thumb",
                                        color = "#556672",
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
    )

# Gets a random number from 0 to the number specified (non-inclusive).
def getRandomNumber(max):
    seed = time.now().unix
    return seed % max

# Combines the default subs (if applicable) with any custom subs inputted.
def combineSubs(config):
    allSubs = []
    allSubs = checkCustomSubSchema("subOne", config, allSubs)
    allSubs = checkCustomSubSchema("subTwo", config, allSubs)
    allSubs = checkCustomSubSchema("subThree", config, allSubs)
    allSubs = checkCustomSubSchema("subFour", config, allSubs)
    allSubs = checkCustomSubSchema("subFive", config, allSubs)
    allSubs = checkCustomSubSchema("subSix", config, allSubs)
    allSubs = checkCustomSubSchema("subSeven", config, allSubs)
    allSubs = checkCustomSubSchema("subEight", config, allSubs)
    allSubs = checkCustomSubSchema("subNine", config, allSubs)
    allSubs = checkCustomSubSchema("subTen", config, allSubs)

    # If the toggle is set to true, or there are no custom values, add the defaults too
    if config.bool("defaults", False) == True or len(allSubs) == 0:
        allSubs = allSubs + DEFAULT_SUBREDDITS

    return allSubs

# Checks if the user entered data in the given input.
def checkCustomSubSchema(subNum, config, currentArray):
    sub = config.get(subNum, "")
    if len(sub) > 1:
        currentArray.append(buildSubPrefix(sub))
    return currentArray

# Removes any /r or /r/ characters users might have put on the sub name.
def buildSubPrefix(name):
    formattedName = name
    rIndex = name.find("r/")
    if rIndex != -1:
        formattedName = name[rIndex + 2:]

    return formattedName

# Gets either the cached posts or runs an API call to reddit for more.
def getPosts(subname):
    print("Pulling posts for subreddit " + subname)
    cacheName = "reddit-image-posts-" + subname
    cachedPosts = cache.get(cacheName)

    # Check the cache and return a random post from the stored posts if able.
    if cachedPosts != None:
        print("Cache hit")
        cachedPosts = json.decode(cachedPosts)
        return setRandomPost(cachedPosts, subname)

    print("Cache miss, refreshing posts")

    # In lieu of the cache, pull a new set of posts from the API.
    apiUrl = "https://www.reddit.com/r/" + subname + "/hot.json?limit=30"
    rep = http.get(apiUrl, headers = {"User-Agent": "Tidbyt App: Reddit Image Shuffler " + str(getRandomNumber(9999))})
    if "application/json" not in rep.headers.get("Content-Type"):
        return handleApiError()
    data = rep.json()
    if "error" in data.keys():
        return handleApiError(data)
    else:
        posts = data["data"]["children"]
        allImagePosts = []

        # Add all image posts to a new list.
        for i in range(0, len(posts) - 1):
            for j in range(0, len(APPROVED_FILETYPES) - 1):
                if posts[i]["data"]["url"].endswith(APPROVED_FILETYPES[j]):
                    allImagePosts.append(posts[i]["data"])

        # Cache the posts for 2 hours
        print("Caching " + subname + " posts")
        cache.set(cacheName, json.encode(allImagePosts), 2 * 60 * 60)
        return setRandomPost(allImagePosts, subname)

# Build an error display for users. Log error.
def handleApiError(data = None):
    if data == None:
        message = "Unknown Error"
    else:
        message = data["message"]
    print("error :( " + message)
    return {
        "sub": "r/???",
        "title": "error",
        "id": "00000",
    }

# Get random post from all image posts for that sub. Build and return display data.
def setRandomPost(allImagePosts, subname):
    if len(allImagePosts) > 0:
        chosen = allImagePosts[getRandomNumber(len(allImagePosts) - 1)]
        print("Post picked is:")
        print(chosen["title"] + " | " + chosen["id"])
        return {
            "url": chosen["url"],
            "sub": chosen["subreddit_name_prefixed"],
            "id": chosen["id"],
            "title": chosen["title"],
        }
        # This else will only run if there are no image posts in the top 30 in /r/hot for a sub.

    else:
        return {
            "sub": "r/" + subname,
            "title": "no results",
            "id": "00000",
        }

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "subOne",
                name = "Custom sub 1",
                desc = "Enter up to 10 subreddits you would like to pull images from.",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subTwo",
                name = "Custom sub 2",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subThree",
                name = "Custom sub 3",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subFour",
                name = "Custom sub 4",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subFive",
                name = "Custom sub 5",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subSix",
                name = "Custom sub 6",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subSeven",
                name = "Custom sub 7",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subEight",
                name = "Custom sub 8",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subNine",
                name = "Custom sub 9",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Text(
                id = "subTen",
                name = "Custom sub 10",
                desc = "",
                icon = "redditAlien",
            ),
            schema.Toggle(
                id = "defaults",
                name = "Include defaults",
                desc = "In addition to custom subreddits, include defaults? (/r/cats, /r/otters, /r/blackcats, /r/plants, /r/itookapicture, /r/aww, /r/eyebleach, /r/pic)",
                icon = "otter",
                default = False,
            ),
        ],
    )

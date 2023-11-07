"""
Applet: Marvel of the Day
Summary: A Marvel character a day
Description: Shows the name and image of a Marvel Comics character using the Marvel API.
Author: flynnt
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("secret.star", "secret")
load("time.star", "time")

BASE_URL = "https://gateway.marvel.com/v1/public/characters"
PUBLIC_KEY = secret.decrypt("AV6+xWcE+glik4Q/UJ64HVitCtX/Iw4GMs4PXCybCA8EyTUt1POPVYqKOU3RGgOe2mjHa8PjfUuOBJRUjmViYUg+siN6ApfbF9qbr4N4JjcIblHXyLK5Pud1Ur5dgWkKpUZU1OdzTWz4pUnS7WKWnKXqASO81oGyzth03l+vQ3Wk1oVxZIA=")
PRIVATE_KEY = secret.decrypt("AV6+xWcEPi0x8wyUv3WvkbErpatqjOP8YnClZuerV7D3Y/8tFLtFEw5FhlxuN2mNEPt54DqB+94xcybYJ5dNglGmc2XmXIrtISvO1+7TQ2U3djvTPARlZg7vOS/EXFWnSGMiLw8Bx8733nzQPbhklqMUBW27Bi6Nji7Y2ByDQuTexA74mtZRmuYPXV4XVA==")

def main():
    """
    App entrypoint.
    Retrieves and parses a single Marvel character.
    Returns rendered application root.
    """
    if PUBLIC_KEY == None or PRIVATE_KEY == None:
        image = http.get("http://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body()
        name = "Something went wrong, enjoy this image of Wolverine while we fix it."

        return render_data(image, name)
    else:
        characterId = get_random_character_id()
        key = base64.encode("character-" + str(characterId))
        data = cache.get(key)
        params = get_auth_params()

        if data != None:
            res = base64.decode(data)
        else:
            req = http.get(BASE_URL + "/" + str(characterId), params = params)
            res = req.body()
            if req.status_code != 200:
                fail("API request failed with status:", req.status_code)

            cache.set(key, base64.encode(res), ttl_seconds = 86400)

        data = json.decode(res)
        item = data["data"]["results"][0]
        name = item["name"]
        imageUrlSegments = item["thumbnail"]
        imageUrl = imageUrlSegments["path"] + "." + imageUrlSegments["extension"]
        image = http.get(imageUrl).body()

        return render_data(image, name)

def render_data(image, name):
    return render.Root(
        render.Row(
            children = [
                render.Box(
                    height = 32,
                    width = 28,
                    child = render.Image(
                        src = image,
                        height = 28,
                    ),
                ),
                render.Box(
                    height = 32,
                    child = render.Marquee(
                        align = "center",
                        width = 35,
                        child = render.Text(name),
                    ),
                ),
            ],
        ),
    )

def get_auth_params():
    """
    Returns Marvel API authentication params.
    """
    params = {
        "ts": str(time.now().unix),
        "apikey": PUBLIC_KEY,
        "hash": hash.md5(str(time.now().unix) + PRIVATE_KEY + PUBLIC_KEY),
    }

    return params

def get_random_character_id():
    """
    Get a single, random character.
    Only return a character if the character has an image.
    """
    limit = 1
    maxOffset = 1562
    offset = random.number(0, maxOffset)
    baseParams = {"limit": str(limit), "offset": str(offset)}
    params = baseParams | get_auth_params()
    key = base64.encode("character-rand")
    data = cache.get(key)

    if data != None:
        res = base64.decode(data)
    else:
        req = http.get(BASE_URL, params = params)
        if req.status_code != 200:
            fail("API request failed with status:", req.status_code)
        res = req.body()

    data = json.decode(res)
    responseCharacter = data["data"]["results"][0]
    imagePath = responseCharacter["thumbnail"]["path"]
    hasImage = imagePath != "http://i.annihil.us/u/prod/marvel/i/mg/b/40/image_not_available"
    characterId = responseCharacter["id"]

    if not hasImage:
        print("Seeking...")
        return get_random_character_id()

    print("Character found...")
    cache.set(key, base64.encode(res), ttl_seconds = 82200)
    return int(characterId)

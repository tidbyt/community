"""
Applet: Marvel of the Day
Summary: A Marvel character a day
Description: Shows the name and image of a Marvel Comics character using the Marvel API.
Author: flynnt
"""

load("hash.star", "hash")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("secret.star", "secret")
load("time.star", "time")

BASE_URL = "https://gateway.marvel.com/v1/public/characters"
PUBLIC_KEY = secret.decrypt("AV6+xWcEy092dgpbVtrQ6viXx2aP7gUnMvuSV2fPo8z7rcpCsZSB7iKhbuhn1Y9uf4X944Jxz5IaunEkS5HWH0nADmdQVa1EMOu8boaEFwxIXin9b9f4fu80Yh/hhgdZSmIZG446mxhINuZWXXEkjw9YXjyzrL5jTj23CTEMcYAGRMXovks=")
PRIVATE_KEY = secret.decrypt("AV6+xWcExLAtVmhSs9vr0xHtg8hRIWQcXAKa1qG3l2W/Frgr+EcICQuMg9CbUwqEbVrY/OhIhFsGczEJkGjhEMsn+MFFqSTm68ZZvNXIbr3MFhOSPnKPCFybCmXU5T97NNLGDAARgtB+/7VgF0w7Ki8eiX5sbW7yisbLpFrEe/2mKxh9OcDmZ6tQAwhhYg==")

def main():
    """
    App entrypoint.
    Retrieves and parses a single Marvel character.
    Returns rendered application root.
    """
    if PUBLIC_KEY == None or PRIVATE_KEY == None:
        return render.Root(render.Box(
            child = render.Marquee(
                align = "center",
                width = 64,
                child = render.Text("Something went wrong.", font = "tom-thumb"),
            ),
        ))

    characterId = get_random_character_id()
    params = get_auth_params()
    req = http.get(BASE_URL + "/" + str(characterId), ttl_seconds = 86400, params = params)
    if req.status_code != 200:
        fail("API request failed with status:", req.status_code)

    item = req.json()["data"]["results"][0]
    name = item["name"]
    imageUrlSegments = item["thumbnail"]
    imageUrl = imageUrlSegments["path"] + "." + imageUrlSegments["extension"]
    image = http.get(imageUrl).body()

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

    req = http.get(BASE_URL, ttl_seconds = 82800, params = params)
    if req.status_code != 200:
        fail("API request failed with status:", req.status_code)

    responseCharacter = req.json()["data"]["results"][0]
    imagePath = responseCharacter["thumbnail"]["path"]
    hasImage = imagePath != "http://i.annihil.us/u/prod/marvel/i/mg/b/40/image_not_available"
    characterId = responseCharacter["id"]

    if not hasImage:
        print("Seeking...")
        return get_random_character_id()

    print("Character found...")
    return int(characterId)

"""
Applet: CraftNFT
Summary: Craft NFT Display
Description: Display random Craft NFT owned by a user.
Author: tavdog
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star","http")
load("encoding/json.star","json")
load("time.star", "time")
load("cache.star","cache")

DEFAULT_USER_ADDRESS = "hx5c9d08a9d85539760b69e160d9376bc5eed948f5"

USER_URL = "https://api.craft.network/user/{}"

TOKEN_URL = "https://utils.craft.network/metadata/{}/{}"

def main(config):
    address = config.str("user_address", DEFAULT_USER_ADDRESS)
    nft_image_src = cache.get(address)
    #nft_image_src = http.get("http://wildc.net/tmp/2551.png").body()
    if nft_image_src == None:
        nft_image_url = fetch_random_nft(address)
        nft_image_src = http.get(nft_image_url).body()
    else:
        print("Using Cache")
    
    if nft_image_src == None:
        return render.Root(
            child = render.Text("no nfts"),
        )
    else:
        # set the cache since this is the image we are rendering
        cache.set(address, nft_image_src, ttl_seconds = 3600) # 1 hour
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = nft_image_src,
                        height = 32,
                    ),
                ]
            )
        )
            


def fetch_random_nft(address):
    user_page_body = http.get(USER_URL.format(address)).body()
    user_json_obj = json.decode(user_page_body)
    # the token_map holds the collections and ids of token a user owns
    collections = user_json_obj["userData"]["tokenMap"]
    image_list = []
    for collection,token in collections.items():
        #print(collection)
        for token_id in token.keys():
            token_page_body = http.get(TOKEN_URL.format(collection,token_id)).body()
            token_json_obj = json.decode(token_page_body)
            image_url = token_json_obj["preview"]["hash"]
            if (image_url[-4:] in [".jpg",".png","peg",".gif"]):
                image_list.append(image_url)
                print("added :" + image_url + " to image_list")
    if len(image_list) > 0:
        # pick a random image
        random_image = image_list[random(len(image_list))]
        #print("picked: " + random_image)
        return random_image
    return None


def random(max):
    """Return a pseudo-random number in [0, max)"""
    return int(time.now().nanosecond % max)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_address",
                name = "User Address",
                desc = "The user address.",
                icon = "user",
            ),
        ],
    )

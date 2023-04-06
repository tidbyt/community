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

DEFAULT_TTL = 10 #300

MAX_IMAGES = 10 # set to 50 for production

def main(config):
    nft_ttl_seconds = int(config.get("nft_cycle_seconds",DEFAULT_TTL)) # default 5 minutes
    print("ttl:"+str(nft_ttl_seconds))
    address = config.str("user_address", DEFAULT_USER_ADDRESS)
    nft_image_src = cache.get(address+"_random")
    #nft_image_src = http.get("http://wildc.net/tmp/2551.png").body()
    if nft_image_src == None:
        nft_image_url = fetch_random_nft(address)
        if nft_image_url != None:
            nft_image_src = http.get(nft_image_url).body()
            cache.set(address+"_random", nft_image_src, ttl_seconds = nft_ttl_seconds) # 1 hour
    else:
        print("Using Cache")
    
    if nft_image_src == None:
        return render.Root(
            render.Box(
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            children = [
                                render.WrappedText(
                                    content = " No Displayable NFTs Found",
                                    font = "tb-8",
                                    color = "#FF0000",
                                    align = "center",
                                )
                            ]
                        )
                    ],
                ),
            )
        )
    else:
        # set the cache since this is the image we are rendering

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
    print(USER_URL.format(address))
    # pull the cache for the image list. this is expensive so we cache for longer (24 hours)
    user_dict = cache.get(address+"_image_list")
    if user_dict == None:
        user_dict = dict()
        resp = http.get(USER_URL.format(address))
        user_page_body = resp.body()
        user_json_obj = json.decode(user_page_body)
        # the token_map holds the collections and ids of token a user owns
        if resp.status_code != 200:
            return None

        collections = user_json_obj["userData"]["tokenMap"]
        user_dict["token_map"] = collections
        image_list = []
        counter = 0
        for collection,token in collections.items():
            print(token)
            if counter > MAX_IMAGES:
                break
            for token_id in token.keys():
                if counter > MAX_IMAGES:
                    break
                print(TOKEN_URL.format(collection,token_id))
                token_page_body = http.get(TOKEN_URL.format(collection,token_id)).body()
                token_json_obj = json.decode(token_page_body)
                if "cloudinary" in token_json_obj and token_json_obj["cloudinary"][-4:] in [".jpg",".png","peg",".gif"]:
                    user_dict["token_map"][collection][token_id] = True # set to True to indicate we've seen this and it does have a preview
                    image_url = token_json_obj["cloudinary"]
                else:
                    print("no cloudinary image")
                    user_dict["token_map"][collection][token_id] = False
                    break
                image_list.append(image_url)
                #print("added :" + image_url + " to image_list")
                print(counter+1)
                counter = counter + 1


        user_dict["image_list"] = image_list
        cache.set(address+"_image_list", json.encode(image_list), ttl_seconds = 86400) # 24 hours
#        print(str(user_dict))
    else:
        image_list = json.decode(user_dict)

    if len(image_list) > 0:
        # pick a random image
        num = random(len(image_list))
        print("picking #" + str(num+1) + " of " + str(len(image_list)))
        
        random_image = image_list[num]
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
            # schema.Text(
            #     id = "nft_cycle_seconds",
            #     name = "Display Time",
            #     desc = "How long to display each NFT",
            #     icon = "clock"
            # )
        ],
    )

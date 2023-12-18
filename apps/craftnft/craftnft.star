"""
Applet: CraftNFT
Summary: Craft NFT Display
Description: Display random Craft NFT owned by a user.
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_USER_ADDRESS = "hx5c9d08a9d85539760b69e160d9376bc5eed948f5"

USER_URL = "https://api.craft.network/user/{}"

TOKEN_URL = "https://utils.craft.network/metadata/{}/{}"

DEFAULT_TTL = 300  #300

def main(config):
    nft_ttl_seconds = int(config.get("nft_cycle_seconds", DEFAULT_TTL))  # default 5 minutes
    print("ttl:" + str(nft_ttl_seconds))
    address = config.str("user_address", DEFAULT_USER_ADDRESS)
    nft_image_src = cache.get(address + "_random")

    if nft_image_src == None:
        nft_image_url = fetch_random_nft(address)
        if nft_image_url != None:
            nft_image_src = http.get(nft_image_url).body()

            # set the cache since this is the image we are rendering
            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(address + "_random", nft_image_src, ttl_seconds = nft_ttl_seconds)

    else:
        print("Using Cache")

    # Here is the error screen
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
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )
    else:
        # Here is the main render screen.
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
                ],
            ),
        )

def fetch_random_nft(address):
    image_dict_orig = fetch_image_dict(address)
    if image_dict_orig == None:
        return None

    # cull any Nones so we don't have to deal with them.
    image_dict = dict()
    for k, v in image_dict_orig.items():
        if v != None:
            image_dict[k] = v

    random.seed(time.now().unix)  # // 15)
    key_list = image_dict.keys()
    cur_url = ""
    for i in range(len(key_list)):
        print(str(i))
        num = random.number(0, len(key_list) - 1)
        print("picking #" + str(num + 1) + " of " + str(len(key_list)))
        cur_url = image_dict[key_list[num]]
        if cur_url == "":  # we haven't check this token page for an image url yet so lets check and buildup the cache
            collection, token_id = key_list[num].split(":")
            print(TOKEN_URL.format(collection, token_id))
            token_page_body = http.get(TOKEN_URL.format(collection, token_id), ttl_seconds = 60 * 60).body()  # 1 hour http cache
            token_json_obj = json.decode(token_page_body)
            if "cloudinary" in token_json_obj and token_json_obj["cloudinary"][-4:] in [".jpg", ".png", "peg", ".gif"]:
                #print("setting " + key_list[num] + " to " + token_json_obj["cloudinary"] )
                image_dict_orig[key_list[num]] = token_json_obj["cloudinary"]  # set the preview url in our image_dict
                cur_url = token_json_obj["cloudinary"]

                #title = token_json_obj["title"]
                break  # break out and display our newly discovered token image
            else:
                #print("Setting None")
                image_dict_orig[key_list[num]] = None
                continue  # no displayable image so continue with the next random choice.
        else:
            # we must have an image url so lets just fetch it and return it, no need to update cache
            cur_url = image_dict[key_list[num]]
            break

    # re-store the cache with the updated info.
    # we are storing a custom dictionary that is updated each time the script is run so http cache
    # will not work here.
    cache.set(address + "_image_dict", json.encode(image_dict_orig), ttl_seconds = 86400)  # 1 day
    if cur_url:
        #print("picked: " + cur_url)
        return cur_url
    else:
        return None

def fetch_image_dict(address):
    print(USER_URL.format(address))

    # pull the cacheed image list and update if needed.
    image_dict_json_str = cache.get(address + "_image_dict")

    # fetch current image list
    resp = http.get(USER_URL.format(address), ttl_seconds = 60 * 60)  # 1 hour http cache
    if resp.status_code != 200 and image_dict_json_str == None:  # if we hav not cache and http.get fails return None
        return None

    # the token_map holds the collections and ids of token a user owns
    user_page_body = resp.body()
    user_json_obj = json.decode(user_page_body)

    if image_dict_json_str == None:
        print("new image_dict")
        image_dict = dict()

        #print(user_json_obj["userData"]["tokenMap"])
        for collection, token in user_json_obj["userData"]["tokenMap"].items():
            #print(token)
            for token_id in token.keys():
                image_dict[collection + ":" + token_id] = ""
        print(image_dict)

        # no need to cache here, the fetch_random_nft will do that.
        return image_dict

    else:  # update the cache if new tokens exist
        image_dict_cache = json.decode(image_dict_json_str)
        print(image_dict_cache)
        for collection, token in user_json_obj["userData"]["tokenMap"].items():
            #print(token)
            for token_id in token.keys():
                if collection + ":" + token_id not in image_dict_cache:
                    #print("updating")
                    image_dict_cache[collection + ":" + token_id] = ""

        return image_dict_cache

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

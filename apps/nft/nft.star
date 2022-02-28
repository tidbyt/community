"""
Applet: NFT
Summary: Random Opensea NFT
Description: Displays a random NFT associated with an Ethereum public address.
Author: nipterink
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

ASSETS_URL = "https://api.opensea.io/api/v1/assets?format=json&owner={}"

def main(config):
    api_key = secret.decrypt("AV6+xWcEgyom3axWmveQsUXTRbQOZS5J+86SzzjX6xzGZdxe3TCmX1whv2nacbrV87OVvRLL2W9KC6+fN2Sikz4cKFxYPBth3Pv5I8on/9znxCWkyNyYxnfoK33i+f2Jwmn2Ffmdt2qdGm907dtB7pInMKLPIr+ikDYteSXA7FtQUUslxws=") or config.get("opensea-api-key") or ""
    public_address = config.get("public_address") or "0xd6a984153acb6c9e2d788f08c2465a1358bb89a7"
    nfts = fetch_opensea_assets(public_address, api_key)
    nft = nfts[random(len(nfts))]
    (nft_name, nft_thumbnail) = fetch_nft_thumbnail(nft)

    return render.Root(
        child = render.Box(
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Marquee(
                        offset_start = 64,
                        width = 64,
                        child = render.Text(nft_name),
                    ),
                    render.Row(
                        children = [
                            render.Image(
                                src = nft_thumbnail,
                                height = 24,
                                width = 24,
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def fetch_opensea_assets(public_address, api_key):
    cached_nfts = cache.get("public_address=%s" % public_address)
    if cached_nfts != None:
        print("Hit! Using cached Opensea response for", public_address)
        nfts = json.decode(cached_nfts)
    else:
        fetch_url = ASSETS_URL.format(public_address)
        print("Miss! Fetching OpenSea Assets for", public_address)
        assets_resp = http.get(fetch_url, headers = {"X-API-KEY": api_key})
        if (assets_resp.status_code != 200):
            fail("OpenSea request failed with status", assets_resp.status_code)

        nfts = assets_resp.json()["assets"]
        cache.set("public_address=%s" % public_address, json.encode(nfts), ttl_seconds = 3600)

    return nfts

def fetch_nft_thumbnail(nft):
    nft_name = nft["name"]
    thumbnail_url = nft["image_thumbnail_url"]
    cached_thumbnail = cache.get("thumbnail=%s" % thumbnail_url)
    if cached_thumbnail != None:
        print("Hit! Using cached thumbnail for", nft_name)
        return (nft_name, base64.decode(cached_thumbnail))
    else:
        print("Miss! Fetching image thumbnail for", nft_name)
        thumbnail_resp = http.get(thumbnail_url)
        if (thumbnail_resp.status_code != 200):
            fail("Failed to fetch thumbnail with status", thumbnail_resp.status_code)
        cache.set("thumbnail=%s" % thumbnail_url, base64.encode(thumbnail_resp.body()), ttl_seconds = 3600)
        return (nft_name, thumbnail_resp.body())

def random(max):
    """Return a pseudo-random number in [0, max)"""
    return int(time.now().nanosecond % max)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "public_address",
                name = "Public Address",
                desc = "Ethereum Public Address",
                icon = "ethereum",
                default = "0xd6a984153acb6c9e2d788f08c2465a1358bb89a7",
            ),
        ],
    )

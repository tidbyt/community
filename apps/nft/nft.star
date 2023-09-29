"""
Applet: NFT
Summary: Random Opensea NFT
Description: Displays a random NFT associated with an Ethereum public address.
Author: nipterink
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

NFTS_URL = "https://api.opensea.io/v2/chain/ethereum/account/{}/nfts"
COLLECTION_STATS_URL = "https://api.opensea.io/api/v1/collection/{}/stats"

def main(config):
    api_key = secret.decrypt("AV6+xWcE6aY6fd81YrVzBfapeIGfdHtBrvi3x5uhwn+APhh3N8foO4a7CpW55B0ZKsZ6Ut1CR5F0y1QG3UTlj/pD5tGToAoCoVYMsxPCyDyVu1tFX1MK1w5DX2yDKFR6lYnYrV5djtLUx1VFs9iPVBbpx26IelzoG8Nc1KghjlnPmPlIdVM=") or config.get("opensea-api-key") or ""
    public_address = config.get("public_address")

    nfts = fetch_opensea_nfts(public_address, api_key)
    nft = nfts[random.number(0, len(nfts) - 1)]
    (nft_name, nft_thumbnail) = fetch_nft_thumbnail(nft)

    floor_price = None
    display_floor = config.bool("display_floor", False)
    if display_floor:
        collection_stats = fetch_collection_stats(nft, api_key)
        floor_price = str(collection_stats["floor_price"])[:4] if collection_stats["floor_price"] else None

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
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = nft_thumbnail,
                                height = 24,
                                width = 24,
                            ),
                            render.Text(" Ξ%s" % floor_price) if display_floor and floor_price else None,
                        ],
                    ),
                ],
            ),
        ),
    )

def fetch_opensea_nfts(public_address, api_key):
    fetch_url = NFTS_URL.format(public_address)
    print("Fetch URL:", fetch_url)

    nfts_resp = http.get(fetch_url, headers = {"X-API-KEY": api_key}, ttl_seconds = 3600)
    if (nfts_resp.status_code != 200):
        fail("OpenSea request failed with status", nfts_resp.status_code)

    nfts = nfts_resp.json()["nfts"]
    return nfts

def fetch_nft_thumbnail(nft):
    nft_name = nft["name"] if nft["name"] else ""
    thumbnail_url = nft["image_url"]
    if not thumbnail_url:
        fail("NFT has no image to display")

    # request a much smaller thumbnail than the default
    thumbnail_url = thumbnail_url.replace("?w=500", "?w=64")
    print("Thumbnail URL for {}:".format(nft_name), thumbnail_url)

    thumbnail_resp = http.get(thumbnail_url, ttl_seconds = 3600)
    if (thumbnail_resp.status_code != 200):
        fail("Failed to fetch thumbnail with status", thumbnail_resp.status_code)

    return (nft_name, thumbnail_resp.body())

def fetch_collection_stats(nft, api_key):
    collection_slug = nft["collection"]
    collection_url = COLLECTION_STATS_URL.format(collection_slug)
    print("Collection Stats URL for {}:".format(collection_slug), collection_url)

    collection_resp = http.get(collection_url, headers = {"X-API-KEY": api_key}, ttl_seconds = 3600)
    if (collection_resp.status_code != 200):
        fail("OpenSea request failed with status", collection_resp.status_code)

    collection_stats = collection_resp.json()["stats"]
    return collection_stats

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
            schema.Toggle(
                id = "display_floor",
                name = "Display Floor",
                desc = "A toggle to display the collection's floor price.",
                icon = "chartLine",
                default = False,
            ),
        ],
    )

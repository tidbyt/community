"""
Applet: Steam Sales
Summary: List sales on Steam
Description: Lists current Steam sales from their featured section.
Author: Par Johansson
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

STEAM_API = "https://store.steampowered.com/api/featuredcategories"

def main():
    return render.Root(
        render.Marquee(
            height=32,
            offset_start=32,
            scroll_direction="vertical",
            child = render.Column(
                children = drawDeals(),
            ),
        ),
    )

def drawDeals():
    data = json.decode(get_cacheData(STEAM_API, 3600))
    dealCol = []
    uniqueDeal = []

    for item in data["specials"]["items"]:
        if item not in uniqueDeal:
            uniqueDeal.append(item)
    
    for i in uniqueDeal:
        icon = http.get(i["small_capsule_image"]).body()
        centStr = str(i["final_price"])
        d, c = centStr[:-2], centStr[-2:]

        if int(centStr) > 99:
            priceStr = "$" + d + "." + c
        else:
            priceStr = "$0." + c

        dealCol.extend( 
            [ 
                render.Column( 
                    children=[
                        render.Row(
                            children = [ 
                                render.Image(src=icon, width=15, height=10), 
                                render.Box(width=1, height=1),
                                render.WrappedText(i["name"] + " " + priceStr + " " + str(i["discount_percent"]) + "%", font="tom-thumb"),
                            ],
                        ),
                        render.Box(width=64, height=3),
                    ],
                ),
            ],
        )
    return dealCol
            
        

def get_cacheData(url, ttl):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl)

    return res.body()

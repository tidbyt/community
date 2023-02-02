"""
Applet: Meh
Summary: Meh Deal
Description: Current deal on meh.com.
Author: hoop33
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("secret.star", "secret")

MEH_CACHE = "meh"
MEH_IMAGE_CACHE = "meh-image"
MEH_URL = "https://meh.com/api/1/current.json?apikey="
TTL_SECONDS = 600

ENCRYPTED_API_KEY = "AV6+xWcEpadSSHWrfsPfqzfkU86tJQxSamXKz9Ya+sdQHvXAw5oYBxdsBhU94lEDMB4yhT9Y/seAKLCdW2EzWGt/UOx6YkAm0ojADUNhrnXw3U8tgfJPMkbdtKlojngw2iwdjhWmNEeZZxtZNfMU3Xf1OA+kAMiCFdtFKItmXPcLNdk037w="

NO_DEAL_IMAGE = """
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9
kT1Iw1AUhU9TpaIVBwuKOmSoThZERRy1CkWoEGqFVh1MXvojNGlIUlwcBdeCgz+LVQcXZ10dXAVB
8AfE1cVJ0UVKvC8ptIjxwuN9nHfP4b37AKFWYprVNgZoum2mEnExk10RQ68IYBB9ALpkZhmzkpSE
b33dUzfVXYxn+ff9Wd1qzmJAQCSeYYZpE68TT23aBud94ggryirxOfGoSRckfuS64vEb54LLAs+M
mOnUHHGEWCy0sNLCrGhqxJPEUVXTKV/IeKxy3uKslSqscU/+wnBOX17iOq0hJLCARUgQoaCCDZRg
I0a7ToqFFJ3HffwDrl8il0KuDTByzKMMDbLrB/+D37O18hPjXlI4DrS/OM7HMBDaBepVx/k+dpz6
CRB8Bq70pr9cA6Y/Sa82tegR0LMNXFw3NWUPuNwB+p8M2ZRdKUhLyOeB9zP6pizQewt0rnpza5zj
9AFI06ySN8DBITBSoOw1n3d3tM7t357G/H4ADQByfpnitNwAAAAGYktHRAAxAHsAjjemA98AAAAJ
cEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQfnARwSOwjN8VAZAAABhElEQVRYw82Xr04EMRDGf92m
gQZPcpJgUORe4AQIXgCBI6BQJIfgJUguh0Agz8IrkPAKHEgIGMQ6bEOaBsxegtj+2907tnJ3+s3X
6czXGUHmckr/hP5La0QOnujCaRsyYhmOc4iIZTuPkRCrcB4iIdo4XwA22VNLIAUolli5GEXmyQ9T
wHNIikwC38CWtKZsW74LkkXmHa4Bd12U38Jn0SCZR07pZ6f0oAsxihGYeL7vAi+pJIJK6Au/tEZU
Dh6BHc/+d2CUkhM+P0UkfCWwDzx4TLaBeZtIFAl3WEprDoB7j8km8OGUvuyMQF3iSGuOgJkHZx24
ckrf5iZjVhVIa06Bm4DJmVN63DoCEQE5By6AL4/JtI6EDzNYBZGsHgBvwIbHZFZFrHkVJFTIccDk
xCn9lNQRNY1CtXcMTAMmc2Dowy/aKpm05rrKCd8aNtaB1EeqIrEHfGZLcc7TmXAdMemuf467asv/
SPdro7ngP1qyfjWlvWjLezGY9GI068Vwuorx/Bc/vstf17aXXwAAAABJRU5ErkJggg==
"""

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("dev_api_key")

    deal = get_deal(api_key)
    image = base64.decode(get_image(deal))

    return render.Root(
        delay = 150,
        child = render.Row(
            children = [
                render.Box(
                    width = 32,
                    height = 32,
                    child = render.Image(
                        src = image,
                        width = 32,
                        height = 32,
                    ),
                ),
                render.Box(
                    width = 32,
                    height = 32,
                    child = render.Padding(
                        pad = (1, 0, 0, 0),
                        child = render.Column(
                            main_align = "space_around",
                            children = [
                                render.WrappedText(
                                    content = deal["title"],
                                    font = "tom-thumb",
                                    color = "#0ff",
                                    width = 32,
                                    height = 24,
                                ),
                                render.Text(
                                    content = "$" + str(deal["items"][0]["price"]),
                                    font = "tom-thumb",
                                    color = "#f00",
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def get_deal(api_key):
    deal = {"title": "No Deal", "items": [{"price": 0}]}

    deal_cached = cache.get(MEH_CACHE)
    if deal_cached != None:
        deal = json.decode(deal_cached)
    elif api_key != None:
        response = http.get(MEH_URL + api_key)
        if response.status_code == 200:
            deal = response.json()["deal"]
            cache.set(MEH_CACHE, json.encode(deal), ttl_seconds = TTL_SECONDS)

    return deal

def get_image(deal):
    image = NO_DEAL_IMAGE

    image_cached = cache.get(MEH_IMAGE_CACHE)
    if image_cached != None:
        image = image_cached
    else:
        item = deal["items"][0]
        if "photo" in item.keys():
            photo_url = item["photo"]
            response = http.get(photo_url)
            if response.status_code == 200:
                image = base64.encode(response.body())
                cache.set(MEH_IMAGE_CACHE, image, ttl_seconds = TTL_SECONDS)

    return image

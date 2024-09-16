"""
Applet: Divbyt
Summary: Displays gifs from mrdiv 
Description: Looping geometric animations from animated GIF artist Mr. Div, designed specifically for Tidbyt. A random animation will play each time from a (possibly) expanding pool of GIFs.
Author: imnotdannorton
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

def main():
    random.seed(time.now().unix // 10)

    # now = time.now()

    # timestring = str(now.unix)
    listUrl = "https://us-central1-divgifs.cloudfunctions.net/giflist/"

    # WIP RANDOM DIV AS A SERVICE
    # url = "https://us-central1-divgifs.cloudfunctions.net/giflist/random?t=" + timestring
    # base = "https://storage.googleapis.com/"
    randNum = get_random(listUrl)
    file = get_feed(listUrl)[randNum]
    path = file["public"]
    imgSrc = get_cached(path)
    children = []
    children.append(
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Image(
                    src = imgSrc,
                    # width = 65,
                    height = 32,
                ),
            ],
        ),
    )
    return render.Root(
        # delay = 60,
        child = render.Column(
            main_align = "space_between",
            cross_align = "center",
            children = children,
        ),
    )

def get_random(feed):
    # check if feed length available
    feedData = get_feed(feed)

    # check if random
    randomIndex = random.number(0, len(feedData) - 1)
    cachedIndex = cache.get("random")
    if cachedIndex:
        if int(cachedIndex) == randomIndex:
            # try again if the rand num is the existing one
            return get_random(feed)
        else:
            cache.set("random", str(randomIndex), ttl_seconds = 60)
            return randomIndex
    else:
        cache.set("random", str(randomIndex), ttl_seconds = 60)
        return randomIndex

def get_feed(url):
    # return the files array from the feed JSON
    data = cache.get(url)
    if data:
        return json.decode(data)["files"]
    res = http.get(url)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))
    data = res.body()
    feed = json.decode(data)
    cache.set(url, data, ttl_seconds = 15)
    return feed["files"]

def get_cached(url, ttl_seconds = 20):
    data = cache.get(url)
    if data:
        return data

    res = http.get(url)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))

    data = res.body()
    cache.set(url, data, ttl_seconds = ttl_seconds)
    return data

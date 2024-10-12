"""
Applet: Divbyt
Summary: Displays gifs from mrdiv 
Description: Looping geometric animations from animated GIF artist Mr. Div, designed specifically for Tidbyt. A random animation will play each time from a (possibly) expanding pool of GIFs.
Author: imnotdannorton
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

def main():
    random.seed(time.now().unix // 60)

    # now = time.now()

    # timestring = str(now.unix)
    listUrl = "https://us-central1-divgifs.cloudfunctions.net/giflist/"

    imgSrc = get_random_file(listUrl)
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

def get_random_file(feed):
    res = http.get(feed, ttl_seconds = 600)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, feed, res.body()))
    feedData = res.json()

    url = feedData["files"][random.number(0, len(feedData["files"]) - 1)]["public"]

    res = http.get(url, ttl_seconds = 5 * 3600)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))
    return res.body()

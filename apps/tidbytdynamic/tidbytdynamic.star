"""
Applet: TidbytDynamic
Summary: Reveal DM to Tidbyt
Description: Reveal discord bot support DM's to developer.
Author: Dara
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("xpath.star", "xpath")

RSS_URL = "https://localhost:9177/api/values"
CACHE_TIMEOUT = 1800  # 30 mins

def main():
    feed = get_cachable_data(RSS_URL, CACHE_TIMEOUT)
    rss = xpath.loads(feed)
    channel = rss.query_node("//rss/channel")

    dynamicSend1 = channel.query("/DynamicSend1")
    dynamicSend2 = channel.query("/DynamicSend2")
    dynamicSend3 = channel.query("/DynamicSend3")
    dynamicSend4 = channel.query("/DynamicSend4")

    return render.Root(
        delay = 0,
        child = render.Column(
            expanded = True,
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "top",
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            offset_end = 0,
                            child = render.Text(
                                content = dynamicSend1,
                                font = "5x8",
                                color = "#9a00ff",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "top",
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            offset_end = 0,
                            child = render.Text(
                                content = dynamicSend2,
                                font = "5x8",
                                color = "#9a00ff",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "top",
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            offset_end = 0,
                            child = render.Text(
                                content = dynamicSend3,
                                font = "5x8",
                                color = "#9a00ff",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "top",
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 0,
                            offset_end = 0,
                            child = render.Text(
                                content = dynamicSend4,
                                font = "5x8",
                                color = "#9a00ff",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_cachable_data(url, timeout):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        return base64.decode(data)

    res = http.get(url = url)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = timeout)

    return res.body()

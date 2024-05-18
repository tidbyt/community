"""
Applet: No Laying Up
Summary: Lists NLU content
Description: No Laying Up produces golf and golf adjacent media content. This app displays the last 6 items posted to the No Laying Up RSS feed. Orange for NLU podcasts, green for Trap Draw podcasts, blue for blogs entries and red for video content. 
Author: M0ntyP

Very niche app for the true NLU sickos out there
"""

load("http.star", "http")
load("render.star", "render")
load("xpath.star", "xpath")

RSS_FEED = "https://nolayingup.com/feeds/all.xml"

def main():
    # Update feed every hour
    feed = get_cachable_data(RSS_FEED, 3600)
    rss = xpath.loads(feed)

    channel = rss.query_all("//rss/channel/item/title")
    link = rss.query_all("//rss/channel/item/link")
    description = []
    content_type = []
    pod_type = []
    NLUPOD = True

    for i in range(0, 6, 1):
        desc = channel[i]
        strippedlink = link[i][23:]
        NLUPOD = True

        # if its a podcast, check which one and remove chars at the front depending on which one - NLU or TrapDraw
        if strippedlink.startswith("p"):
            podstrip = strippedlink[9:]
            if podstrip.startswith("n"):
                desc = desc[26:]
            else:
                desc = desc[13:]
                NLUPOD = False

        # if its video content, check if its Nest or NLU content and revise description
        if strippedlink.startswith("v"):
            vidstrip = strippedlink[7:]
            if vidstrip.startswith("ne"):
                desc = desc[12:]
                desc = "Nest:" + desc
            elif vidstrip.startswith("no"):
                desc = desc[26:]
                desc = "NLU:" + desc

        strippedlink = strippedlink[:3]

        description.append(desc)
        content_type.append(strippedlink)
        pod_type.append(NLUPOD)

    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    padding = 0,
                    color = "#000",
                    child = render.Text("NO LAYING UP", color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = articles(description, content_type, pod_type),
                        ),
                ),
            ],
        ),
    )

def articles(description, content_type, pod_type):
    articles = []
    content_color = "#000"

    for i in range(0, len(description), 1):
        if content_type[i] == "pod":
            if pod_type[i] == True:
                content_color = "#eb9b34"
            else:
                content_color = "#019b5b"
        elif content_type[i] == "vid":
            content_color = "#eb3449"
        elif content_type[i] == "blo":
            content_color = "#3440eb"

        articles.append(render.WrappedText(content = description[i], color = content_color, font = "CG-pixel-3x5-mono", linespacing = 1))
        articles.append(render.Box(width = 64, height = 3, color = "#000"))

    return articles

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

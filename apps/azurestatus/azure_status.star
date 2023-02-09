"""
Applet: Azure Status
Summary: Shows Azure Status messages
Description: Simple app that looks at the Azure Status RSS feed and shows the latest incident and time of the last update. Visit https://status.azure.com/en-us/status/ for more info!
Author: M0ntyP
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")
load("xpath.star", "xpath")

RSS_URL = "https://rssfeed.azure.status.microsoft/en-au/status/feed/"
DEFAULT_TIMEZONE = "Australia/Adelaide"

def get_rss_feed():
    feed = http.get(RSS_URL)
    if feed.status_code != 200:
        print("Could not fetch RSS feed")
        return None
    return feed.body()

def main(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)

    feed = get_rss_feed()
    rss = xpath.loads(feed)
    channel = rss.query_node("//rss/channel")
    title = channel.query("/title")
    lastupdate = channel.query("/lastBuildDate")

    # time formatting
    lastupdate = lastupdate[5:]
    MyTime = time.parse_time(lastupdate, format = "02 Jan 2006 15:04:05 Z").in_location(timezone)
    Time = MyTime.format("15:04")
    Date = MyTime.format("Jan 2")

    item = channel.query("/item/title")
    itemcolor = "#f00"

    if item == None:
        item = "No issues reported"
        itemcolor = "#59d657"

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 64,
                            height = 9,
                            color = "#243a5e",
                            child = render.Text(content = title, font = "CG-pixel-4x5-mono"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 10, child = render.Marquee(width = 64, child = render.Text(content = item, color = itemcolor))),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 6, color = "#243a5e", child = render.Text(content = "Last update", font = "CG-pixel-3x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 8, color = "#243a5e", child = render.Text(content = Date + " " + Time, font = "CG-pixel-3x5-mono")),
                    ],
                ),
            ],
        ),
    )

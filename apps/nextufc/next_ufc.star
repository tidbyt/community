"""
Applet: Next UFC
Summary: Next UFC event
Description: Shows next upcoming UFC event with date and time.
Author: Stephen So
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")

url = "https://www.espn.com/mma/schedule"

def main():
    rep = http.get(url, ttl_seconds = 3600)

    if rep.status_code != 200:
        fail("get failed with status %d", rep.status_code)

    doc = html(rep.body())

    def check_event(i):
        check = doc.find("tbody").children().find("a").eq(i)
        if "UFC" in check.text():
            #print(i)
            return check
        else:
            i += 1
            return check_event(i)

    event_node = check_event(1)
    event = event_node.text()

    date = event_node.parent().siblings().eq(0).text()
    time = event_node.parent().siblings().eq(1).text()

    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    render.Box(
                        width = 64,
                        height = 9,
                        color = "#a61212",
                        child = render.Marquee(
                            width = 64,
                            offset_start = 12,
                            offset_end = 12,
                            align = "center",
                            child = render.Text(
                                content = event,
                            ),
                        ),
                    ),
                    pad = (0, 4, 0, 0),
                ),
                render.WrappedText(
                    content = date,
                    width = 64,
                    align = "center",
                ),
                render.WrappedText(
                    content = time,
                    width = 64,
                    align = "center",
                ),
            ],
        ),
    )

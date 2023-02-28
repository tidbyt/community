"""
Applet: RantinglyNews
Summary: Show news from Rantingly
Description: Show top news stories from Rantingly.com.
Author: @Mad-Chemist
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")

URL = "https://api.feedly.com/v3/mixes/contents?streamId=feed%2Fhttps%3A%2F%2Frantingly.com%2Ffeed%2F"

def main():
    cacheTest = cache.get("l_one")
    if cacheTest != None:
        print("Displaying Cached Data")
        l_one = cache.set("l_one")
        l_two = cache.set("l_two")
        l_three = cache.set("l_three")
    else:
        print("Fetching Rantingly")
        rep = http.get(URL)
        if rep.status_code != 200:
            fail("Rantingly request failed with status %d", rep.status_code)

        d = rep.json()
        l_one = d["items"][0]["title"]
        l_two = d["items"][1]["title"]
        l_three = d["items"][2]["title"]
        cache.set("l_one", str(300), ttl_seconds = 300)
        cache.set("l_two", str(300), ttl_seconds = 300)
        cache.set("l_three", str(300), ttl_seconds = 300)
        print("Successful Fetch")

    return render.Root(
        delay = 100,
        show_full_animation = bool("true"),
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 35,
            child = render.Column(
                children = [
                    render.WrappedText(content = l_one, font = "tom-thumb"),
                    render.Text("-------"),
                    render.WrappedText(content = l_two, font = "tom-thumb"),
                    render.Text("-------"),
                    render.WrappedText(content = l_three, font = "tom-thumb"),
                ],
            ),
        ),
    )

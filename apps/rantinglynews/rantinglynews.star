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
    cacheTest = cache.get("rantinglyNews_lineone")
    if cacheTest != None:
        print("Displaying Cached Data")

        rantinglyNews_lineone = cache.get("rantinglyNews_lineone")

        rantinglyNews_linetwo = cache.get("rantinglyNews_linetwo")

        rantinglyNews_linethree = cache.get("rantinglyNews_linethree")
    else:
        print("Fetching Rantingly")
        rep = http.get(URL)
        if rep.status_code != 200:
            fail("Rantingly request failed with status %d", rep.status_code)

        d = rep.json()
        rantinglyNews_lineone = d["items"][0]["title"]
        rantinglyNews_linetwo = d["items"][1]["title"]
        rantinglyNews_linethree = d["items"][2]["title"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("rantinglyNews_lineone", str(300), ttl_seconds = 300)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("rantinglyNews_linetwo", str(300), ttl_seconds = 300)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("rantinglyNews_linethree", str(300), ttl_seconds = 300)
        print("Successful Fetch")

    return render.Root(
        delay = 100,
        show_full_animation = bool("true"),
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 35,
            child = render.Column(
                children = [
                    render.WrappedText(content = rantinglyNews_lineone, font = "tom-thumb"),
                    render.Text("-------"),
                    render.WrappedText(content = rantinglyNews_linetwo, font = "tom-thumb"),
                    render.Text("-------"),
                    render.WrappedText(content = rantinglyNews_linethree, font = "tom-thumb"),
                ],
            ),
        ),
    )

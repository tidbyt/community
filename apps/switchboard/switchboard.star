"""
Applet: Switchboard
Summary: Display Switchboard data
Description: Displays data from Switchboard on your Tidbyt.
Author: bguggs
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("cache.star", "cache")
load("schema.star", "schema")

BASE_API_URL = "https://oneswitchboard.com/handle_tidbyt/"
SB_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAYAAADE6YVjAAAAAXNSR0IArs4c6QAAA6dJREFUSEu1ln9oVWUYxz/vvefE3XZLm6wmVFs0mFuShLiybXQLKRtt9MMNbAyGOukfmZYXhdKKitUfaSmUhCaoSK0FKRWbhXfNa4mgzLkmxQgnxepO3Wmb07t77n3jvdvZPef+2O3n8985z/N+v8/zfd/3eV7BnObzokfWIUUdsBhYALiAGDAG9ANdmNH34furmaBEeofPgxZtA9kC5M2dSNwbRvAJEa0Vuo3k+FQS/aFl4OpActdfAE8KEVdANGD2HLc7nCTuyhqEaE/OvmVtLWWLih2APcFePj9yIl0eMSRNRIOHLWeCRFUgXQFF4HIJWjc0sPjeu+Nxzzz9MPPnex2AhjHBh3u/wJvn4eLQMDEZ450dH1sxMZArMU9+rX7MkKg9MHuBUvVzy+ZG3mp7Pqta+z46Rsk9C1mzfjdfHt3G8sr1GH9MzKwTVzCj5fBdaJpEq3oDeMlCHeg7RFlZEef6BhkdHadiWRm5uR4HaSg0in/rB2iam2vXbhAKXSXQfdaZmGQf0eA6AT4vmvkzUGBF/P7rUebNy6Og8EnGJ66j9qS83Lkn3/Zk3BM7UQxTKxLo1c1Iud/uUSRebw4FC2uZnLyRVbY5A4TcJNCqj4BUl23W/lMSOC3Qqs7P3GYHiV2uf1cKEUUyDBTagS70H2ZR6Z0ET/YzNmadlrmpRi6PsnHTLtvpSsQruS6DVD1p1l7Z1syr29f+7QI+7QjQsHp7yrq0lSRfxmxsHs9N1K96BLfbzYLbalKqSbsn2UDT+c/3Hoh3iOKSeoaGfrOHRAR6VTuS+n8CbF/Te2Y/S+4rSUcSELirn0XIjv+NRIgWAUt19JzBbK295onl+F9c7chlZMSgqfl1wuEIGeSKYEYLp3uXXrkRKXbaEd7b0cqlXwyeqnuQHwYu0dT4aEr/isUkAxcu4na5KC2dHj833/qYvUu8iRl8eaYLL9XRcoJAhUUU+GYX/q0H2btnA53HzrDFvyqrojvfbecF/+7pOCkGibrvh+6JxDzx+IoxzdNWoyy8PZ/iosQd9W9+Lj5X7BYOT9H29kEmJ6cwjHEOHOqMSxcfxy5RwdSJPvXhnIx61RIkatDMdmQLND//FlY+/oCDRA2uzq5TKNlsFgZWYAaVMnFL85Dw3YFmfmaXLqtOiYAfcVNHOPiTfU2G14o6cbmNSNmW3NcyEBoI+RoRfQ90p8yGDCQWlDoQedUga0GuANTQzwGuI8UwyC6QXxHVj6cDt1D+BMh2T15AzmrQAAAAAElFTkSuQmCC""")

def render_failure():
    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = SB_ICON),
                    render.Marquee(width = 64 - 25, child = render.Text("Switchboard")),
                ],
            ),
        ),
    )

def main(config):
    sb_api_token = config.get("sb_api_token") or "NO_API_TOKEN"
    if sb_api_token == "NO_API_TOKEN":
        return render_failure()

    api_url = BASE_API_URL + "?sb_api_token=%s" % sb_api_token

    sb_cached_result = cache.get("sb_cached_result")
    if sb_cached_result != None:
        print("Hit! Displaying cached data.")
        data = sb_cached_result
    else:
        print("Miss! Calling API.")
        res = http.get(api_url)
        if res.status_code != 200:
            return render_failure()

        data = res.json()["donations"]
        cache.set("sb_cached_result", data, ttl_seconds = 5)

    data = res.json()["donations"]

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = SB_ICON),
                    render.Marquee(width = 64 - 25, child = render.Text(data)),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "sb_api_token",
                name = "Switchboard API Token",
                desc = "The API Token found in your Organization Settings",
                icon = "key",
            ),
        ],
    )

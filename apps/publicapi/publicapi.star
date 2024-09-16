"""
Applet: Public Api
Summary: View random public apis
Description: Display a random public api from api.publicapis.org/random.
Author: noahpodgurski
"""

load("http.star", "http")
load("render.star", "render")

REFRESH_TIME = 60

# colors
YELLOW = "8eb707"
BLUE = "079ab7"

def request():
    res = http.get("https://api.publicapis.org/random", ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    return res.json()

def main():
    api = request()["entries"][0]

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.WrappedText(align = "center", content = api["API"], color = YELLOW) if len(api["API"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(api["API"], color = YELLOW),
                        ),
                        render.Box(width = 64, height = 1, color = "857fc6"),
                        render.WrappedText(align = "center", content = api["Category"], font = "tom-thumb", color = BLUE) if len(api["Category"]) < 14 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(api["Category"], font = "tom-thumb", color = BLUE),
                        ),
                        # render.WrappedText("Auth: %s" % api["Auth"], font = "tom-thumb") if api["Auth"] else None,
                        render.WrappedText(align = "center", content = api["Description"], font = "tom-thumb") if len(api["Description"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            child = render.Text(api["Description"], font = "tom-thumb"),
                        ),
                    ],
                ),
            ),
        ),
    )

load("http.star", "http")
load("render.star", "render")

API_URL = "https://www.frederickscanner.com/fredscannerpro/fredscannertweet.json"

def main():
    rep = http.get(API_URL)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    config = {}
    data = rep.json()
    tweet = data[0]["text"]
    #level = data[0]["truncated"]

    return render.Root(
        #        show_full_animation = True,
        delay = int(config.get("scroll", 10)),
        child = render.Column(
            children = [
                render.Text("  FredScanner", color = "#00FFFF"),
                render.Text("  Latest Alert", color = "#cc0000"),
                render.Text("-------------------", color = "#3944BC"),
                render.Marquee(
                    width = 64,
                    child = render.Text("%s" % tweet, color = "#FFFFFF"),
                ),
            ],
        ),
    )

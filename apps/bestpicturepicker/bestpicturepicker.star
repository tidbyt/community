load("http.star", "http")
load("random.star", "random")
load("render.star", "render")

def main():
    resp = http.get("http://pandemicpictures.info/imdb", ttl_seconds = 21600)
    jsonResp = resp.json()
    movie = jsonResp[random.number(0, len(jsonResp))]
    img = http.get(movie["ImageUrl"]).body()

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "end",
                children = [
                    render.WrappedText(
                        content = "%s (%d) %s" % (movie["Title"], movie["OscarYear"], movie["Rating"]),
                        color = "#099",
                        width = 40,
                        font = "tom-thumb",
                    ),
                    render.Image(
                        src = img,
                        width = 20,
                        height = 40,
                    ),
                ],
            ),
        ),
    )

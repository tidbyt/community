"""
Applet: Wiki Page Today
Summary: Wikipedia Featured Article
Description: Display Wikipedia's Featured Article of the Day in a Tidbyt format.
Author: UnBurn
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

WIKIPEDIA_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAALUlEQVQIW2NkAIL/QACikQEjCIAkgBRIAVwOxkeRhAtCFROWBJmHrgsshs9BAO7FNfeFAdnIAAAAAElFTkSuQmCC")
WIKIPEDIA_URL = "https://api.wikimedia.org/feed/v1/wikipedia/en/featured/%s/%s/%s"

TTL_TIME = 86400
MARQUEE_DELAY = 150

def get_featured_article(date):
    url = (WIKIPEDIA_URL % date)

    article = http.get(url, ttl_seconds = TTL_TIME).json()["tfa"]
    return article

def get_reduced_extract(extract):
    MAX_LENGTH = 100

    sentences = extract.split(".")
    ret = sentences[0] + "."
    for s in sentences[1:]:
        new_sentence = ret + s + "."
        if s != "" and len(new_sentence) <= MAX_LENGTH:
            ret = new_sentence
        else:
            break

    return ret

def main():
    now = time.now()
    date = (now.year, now.month, now.day)
    article = get_featured_article(date)

    title = article["normalizedtitle"]
    extract = article["extract"]
    description = get_reduced_extract(extract)
    image = http.get(article["thumbnail"]["source"], ttl_seconds = TTL_TIME).body()

    top_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 6, color = "#3f3f3f"),
            render.Row(
                children = [
                    render.Padding(child = render.Image(src = WIKIPEDIA_ICON, width = 7, height = 6), pad = (1, 0, 1, 0)),
                    render.Marquee(width = 56, delay = MARQUEE_DELAY, child = render.Text(title, font = "tom-thumb")),
                ],
            ),
        ],
    )

    body = render.Row(
        children = [
            render.Padding(child = render.Image(src = image, width = 16, height = 25), pad = (0, 0, 1, 0)),
            render.Marquee(
                height = 25,
                delay = MARQUEE_DELAY,
                scroll_direction = "vertical",
                child = (render.WrappedText(content = description, font = "tb-8")),
            ),
        ],
    )

    return render.Root(
        show_full_animation = True,
        delay = 20,
        child = render.Column(
            children = [top_bar, render.Box(color = "#fff", width = 64, height = 1), body],
        ),
    )

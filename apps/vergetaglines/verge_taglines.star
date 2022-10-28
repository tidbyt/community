"""
Applet: Verge Taglines
Summary: The Verge's latest tagline
Description: Displays the latest tagline from the top of popular tech news site The Verge (dot com).
Author: joevgreathead
"""

load("render.star", "render")
load("http.star", "http")
load("html.star", "html")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("random.star", "random")

# 16x16
VERGE_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGd
BTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdT
AAAOpgAAA6mAAAF3CculE8AAABfVBMVEXU1NTsAIw1K5AAAAA5M
JI5MJI5MJI2MZKyD47vDI3kU6M0KpA2LZE2LZE4LpE3MJJPKpHS
BYznOJ/Xu8x6dK7U19XU1NTV1dTV0NPV1dTW1tXIyM9cWKLVzdL
U1dTU1NTU1tXlOqDWwM3U1tXU1NTb3NdkXqTU19XU1dTU0tPtAI
rtAIozKY80L5HU09TU1NTU19XsAIvvAIwAT5Y4MJLU1NTU1tXsA
43xAIwzMpI3MZLU1NTU1tXpAItUKZHU1NTU19WXFo+YFo/U1dTV
z9LU1NTU19XU1NTU1NTU1NTU1NTU1dXU1tXU1NTU1dTU1dTU1NT
U1NR3cqx3cq14c61YUZ84L5KRGI/rCI7cjrzV0dPWydBYJZDZA4
zlSKTXusvlP6E+MZOoEY7sEpLZpsThX6xrIpDjAoziYa3XucvoI
pdDLZK9C43rIpfefLaAHZDpBI3Wxs/mNp5NK5HOBozoNp7blb/r
Co/sCo/kTqbkAIvZq8bqFZPgaK////+CX/OAAAAAUnRSTlMAAAA
ABxgZGRkYB2vT1dXV1dXSatjZj/z38fH0/vyPHsrAPDY2NJzKXf
jwRyXY+AyyuhACkEHt+mQ76wSU1sIp3P7+df0Xxlf2VgqrqznLy
gMWolv+0AAAAAFiS0dEfj+4QXMAAAAHdElNRQfgCwESLy7ElKXq
AAAA3UlEQVQY02NgYWWDA3YOTi4Gbh5eKODjFxAUEmYQCQoKBoO
Q0LDwiEhRBjHxqGgJSUlJKWmZmNg4WTkGeYX4BEUlZRVVtcSk5B
R1eQYGDc1ULW1GJh3dtPQMPQ0GBgZ9g8wsQyNjk+yc3EwDfaAAg
6lZnrmFpVV+QZ6ZKZDLzGBtU1hka1dcUlpoYw3kMjMw2DuUlTs6
VZQ52IPkmYEizi6VVVWVLs4MIB4zELu6VdfUVLu5gjkgzODuUVv
r4ckAE2Bm8PIuLPTxgrDBBIOvn78vA0KAmSEgMDAAwgQA0Zcrny
RT7DEAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTYtMTEtMDFUMTg6N
Dc6NDYrMDE6MDDeSimFAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE2
LTExLTAxVDE4OjQ3OjQ2KzAxOjAwrxeROQAAAFd6VFh0UmF3IHB
yb2ZpbGUgdHlwZSBpcHRjAAB4nOPyDAhxVigoyk/LzEnlUgADIw
suYwsTIxNLkxQDEyBEgDTDZAMjs1Qgy9jUyMTMxBzEB8uASKBKL
gDqFxF08kI1lQAAAABJRU5ErkJggg==
""")

NEW_VERGE_TEAL = "#3cffd0"
NEW_VERGE_PURP = "#5200ff"
NEW_VERGE_ORAN = "#ff3d00"
NEW_VERGE_YELL = "#d6f31f"
NEW_VERGE_PINK = "#ffc2e7"

NEW_VERGE_LOGO = base64.decode("""
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
""")

PLACEHOLDER_IMG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXN
SR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGg
AAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAAaADAAQAAAABA
AAAAQAAAAD5Ip3+AAAADUlEQVQIHWNgYGD4DwABBAEAHnOcQAAA
AABJRU5ErkJggg==
""")
PLACEHOLDER_TEXT = "THE VERGE"

SITE = "https://www.theverge.com"
CACHE_KEY_TAGLINE = "verge-dot-com-tagline"
SELECTOR_TAGLINE = ".duet--recirculation--storystream-header > p > span > a"

def main():
    tagline = cache.get(CACHE_KEY_TAGLINE)

    if tagline == None:
        resp = http.get(SITE)
        html_body = html(resp.body())
        tagline = get_tagline(html_body)
        cache.set(CACHE_KEY_TAGLINE, tagline, ttl_seconds = 900)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = content(tagline),
        ),
    )

def get_tagline(html_body):
    text = html_body.find(SELECTOR_TAGLINE).text()
    if text == None:
        return PLACEHOLDER_TEXT
    else:
        return text

def content(value):
    return [
        image_stack(),
        render.Marquee(
            height = 8,
            width = 64,
            scroll_direction = "horizontal",
            align = "center",
            offset_start = 64,
            offset_end = 64,
            child = render.Text(
                content = value,
            ),
        ),
    ]

def background():
    number = random.number(1, 100)
    if number <= 20:
        return NEW_VERGE_ORAN
    elif number > 20 and number <= 40:
        return NEW_VERGE_PINK
    elif number > 40 and number <= 60:
        return NEW_VERGE_YELL
    elif number > 60 and number <= 80:
        return NEW_VERGE_TEAL
    else:
        return NEW_VERGE_PURP

def image_stack():
    return render.Box(
        color = background(),
        child = render.Image(src = NEW_VERGE_LOGO),
        height = 24,
        width = 64,
    )

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

SITE = "https://www.theverge.com"
TAGLINE_CACHE_KEY = "tagline"
TAAGLINE_SELECTOR = "span.c-masthead__tagline > a"

def main():
    resp = http.get(SITE)
    html_body = html(resp.body())
    tagline = cache.get(TAGLINE_CACHE_KEY)

    if tagline == None:
        tagline = html_body.find(TAAGLINE_SELECTOR).text()
        cache.set(TAGLINE_CACHE_KEY, tagline, ttl_seconds = 900)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = content(tagline),
        ),
    )

def content(value):
    if len(value) > 13:
        return [
            render.Image(src = VERGE_LOGO),
            render.Marquee(
                height = 8,
                width = 64,
                scroll_direction = "horizontal",
                child = render.Text(
                    content = value,
                ),
            ),
        ]
    else:
        return [
            render.Padding(
                pad = 3,
                child = render.Image(src = VERGE_LOGO),
            ),
            render.Box(
                child = render.Text(
                    height = 8,
                    content = value,
                ),
            ),
        ]

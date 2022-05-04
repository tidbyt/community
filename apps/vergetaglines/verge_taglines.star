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
CACHE_KEY_TOP_IMG = "verge-dot-com-header"
SELECTOR_TAGLINE = "span.c-masthead__tagline > a"
SELECTOR_TOP_IMG = "div.c-masthead__main"

def main():
    tagline = cache.get(CACHE_KEY_TAGLINE)
    top_img = cache.get(CACHE_KEY_TOP_IMG)

    if tagline == None or top_img == None:
        resp = http.get(SITE)
        html_body = html(resp.body())
        tagline = get_tagline(html_body)
        top_img = get_top_img(html_body)
        cache.set(CACHE_KEY_TAGLINE, tagline, ttl_seconds = 900)
        cache.set(CACHE_KEY_TOP_IMG, top_img, ttl_seconds = 900)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = content(tagline, top_img),
        ),
    )

def get_tagline(html_body):
    text = html_body.find(SELECTOR_TAGLINE).text()
    if text == None:
        return PLACEHOLDER_TEXT
    else:
        return text

def get_top_img(html_body):
    header_style = html_body.find(SELECTOR_TOP_IMG).attr("style")
    style_parts = header_style.split("(")
    url = None
    last_part = None
    for style_part in style_parts:
        if last_part != None and last_part.startswith("background-image:"):
            if style_part.startswith("https"):
                url = style_part.removesuffix(")")
        last_part = style_part

    image_content = None
    if url != None:
        resp = http.get(url)
        return resp.body()
    else:
        return PLACEHOLDER_IMG

def content(value, img):
    if len(value) > 13:
        return [
            image_stack(img),
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
            image_stack(img),
            render.Box(
                child = render.Text(
                    height = 8,
                    content = value,
                ),
            ),
        ]

def image_stack(img):
    return render.Stack(
        children = [
            render.Padding(
                pad = (-16, 0, -16, 0),
                child = render.Image(src = img, width = 96, height = 24),
            ),
            render.Box(
                child = render.Image(src = VERGE_LOGO),
                height = 24,
            ),
        ],
    )

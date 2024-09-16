"""
Applet: Petitions Please
Summary: Tell MPs to do something
Description: Shows currently popular petitions for the UK Parliament and HM Government with a QR link for signing.
Author: dinosaursrarr
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")

# Data is provided under the Open Government Licence v3.0, which allows
# commercial and non-commercial use of the information. Wish they had an
# RSS feed or API but sadly they don't.
# https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
BASE_URL = "https://petition.parliament.uk"
POPULAR_URL = "https://petition.parliament.uk/petitions?state=open"

FONT = "tom-thumb"
GREEN = "#008800"  # from the House of Commons website

# Public domain per https://commons.wikimedia.org/wiki/File:Crowned_Portcullis_redesign_2018.svg
PORTCULLIS = "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeBAMAAADJHrORAAAAD1BMVEUAAAAARAAAiAAAIgAAZgAh56PKAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAA4ElEQVR4nG2R2xHEIAhFL8YCXEwBES3APAowxv5rWtxX/Fh+HAbO5cwIvIol4leTm1ZZ9ekNRVDYk/C6ObDTxknyIrLWSpwBWXyYvByZd9N6VECCFYcK7qHGozbdrwlr6YFSRdrcqiRRnLIE9z5bE2Wc7bF/63GeiEbXP5WWQ+PtdaRddr6OorfI2WIDBFxsIdfnd88XLmN/fImMuQ18aqAy8gV2zLMOrQ58U59t4N8+w72/Pjevc/W5+bh1n3v/v08wiSTXyB+fRf+kz033WYzNtGCGydR9jkBAgYc+eb6eTl0ztCv+CVQAAAAASUVORK5CYII="

def extract_petition(node):
    link = node.find("a")
    return {
        "title": link.text(),
        "url": BASE_URL + link.attr("href"),
        "count": node.find(".count").text(),
    }

def render_marquee(petition):
    return render.Padding(
        pad = (1, 1, 0, 0),
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 29,
            child = render.Padding(
                pad = (0, 0, 0, 100),
                child = render.Column(
                    children = [
                        render.WrappedText(
                            petition["title"],
                            width = 62,
                            font = FONT,
                            align = "center",
                        ),
                        render.Padding(
                            pad = (0, 5, 0, 0),
                            child = render.WrappedText(
                                petition["count"] + " signed",
                                width = 62,
                                font = FONT,
                                align = "center",
                            ),
                        ),
                    ],
                ),
            ),
        ),
    )

def render_petition(petition):
    # I'm assuming generating a code is heavy on compute
    # since the example on tidbyt.dev uses the cache.
    cached_code = cache.get(petition["url"])
    if cached_code:
        qr_code = base64.decode(cached_code)
    else:
        qr_code = qrcode.generate(
            url = petition["url"],
            size = "large",
            color = GREEN,
            background = "#000000",
        )
        cache.set(petition["url"], base64.encode(qr_code), ttl_seconds = 86400)

    header = render.Box(
        height = 1,
        width = 64,
        color = "#008800",
    )
    background = [
        render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Image(base64.decode(PORTCULLIS)),
        ),
        render.Padding(
            pad = (34, 1, 0, 100),
            child = render.Image(qr_code),
        ),
    ]

    return render.Padding(
        pad = (0, 0, 0, 0),
        child = render.Column(
            children = [
                header,
                render.Stack(
                    children =
                        background + [
                            render_marquee(petition),
                        ],
                ),
            ],
        ),
    )

def fetch_open_petition(index):
    resp = http.get(POPULAR_URL, ttl_seconds = 3600)
    page = html(resp.body())
    nodes = page.find("li.petition-open")
    return extract_petition(nodes.eq(index))

def main(config):
    number = int(config.str("number", "1"))
    petition = fetch_open_petition(number)

    return render.Root(
        child = render_petition(petition),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "number",
                name = "Number",
                desc = "Show the nth most popular open petition",
                icon = "arrowUpRightDots",
                options = [
                    schema.Option(display = "%s" % (i + 1), value = "%s" % (i + 1))
                    for i in range(10)
                ],
                default = "1",
            ),
        ],
    )

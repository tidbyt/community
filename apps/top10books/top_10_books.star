"""
Applet: Top 10 Books
Summary: Top 10 books from B&N top
Description: Displays the current top 10 books on Barnes & Nobles top 100 book list.
Author: shhhmuck
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# 1 hour
CACHE_TTL = 3600
TOP_100 = "https://www.barnesandnoble.com/b/books/_/N-1fZ29Z8q8"
PER_PAGE = 10

# random user agents
AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393",
    "Mozilla/5.0 (compatible, MSIE 11, Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (iPad; CPU OS 8_4_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H321 Safari/600.1.4",
]

# generic web scraping headers
HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.google.com/",
    "Cache-Control": "max-age=0",
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "cross-site",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}

def main():
    # cache key
    rand_num_str = str(random.number(0, PER_PAGE - 1))

    cached = cache.get(rand_num_str)

    if cached != None:
        print("Cache hit")
        b = json.decode(cached)
    else:
        print("Cache miss")

        res = http.get(
            url = "{}?Nrpp={}&page={}".format(TOP_100, PER_PAGE, 1),
            headers = HEADERS | {"User-Agent": AGENTS[random.number(0, len(AGENTS) - 1)]},
        )

        if res.status_code != 200:
            print("Got code '%s' from top 10 response" % res.status_code)
            return render.Root(
                render.WrappedText("Something went wrong getting books!"),
            )

        doc = html(res.body())
        books = doc.find(".pb-s")

        for i in range(PER_PAGE):
            book = books.eq(i)

            rank = book.find(".count").text()
            title = book.find(".product-info-title").find("a").text().split(" (")[0]
            author = book.find(".product-shelf-author").find("a").text().split(" (")[0]
            img_raw = book.find("noscript").text()
            img_link = img_raw[img_raw.index("prodimage"):img_raw.index("jpg") + 3]

            cache.set(
                str(i),
                json.encode({"rank": rank, "title": title, "author": author, "img_link": img_link}),
                CACHE_TTL,
            )

        b = json.decode(cache.get(rand_num_str))

    book_cover_res = http.get(
        url = "https://{}".format(b["img_link"]),
        headers = HEADERS | {
            "User-Agent": AGENTS[random.number(0, len(AGENTS) - 1)],
            "Host": "prodimage.images-bn.com",
        },
        ttl_seconds = CACHE_TTL,
    )

    if book_cover_res.status_code != 200:
        print("Got code '%s' from book cover response" % book_cover_res.status_code)
        return render.Root(
            render.WrappedText("Something went wrong getting book cover!"),
        )

    book_cover_bytes = book_cover_res.body()

    return render.Root(
        child = render.Row(
            expanded = True,
            children = [
                render.Column(
                    children = [
                        render.Image(
                            src = book_cover_bytes,
                            width = 20,
                            height = 32,
                        ),
                    ],
                ),
                render.Column(
                    main_align = "space_around",
                    expanded = True,
                    children = [
                        render.Text(
                            content = b["rank"],
                            font = "tb-8",
                        ),
                        render.Marquee(
                            width = 44,
                            child = render.Text(
                                b["title"],
                                font = "6x13",
                            ),
                            offset_start = 0,
                            offset_end = 0,
                            delay = 30,
                        ),
                        render.Marquee(
                            width = 44,
                            child = render.Text(
                                "by {}".format(b["author"]),
                                font = "5x8",
                            ),
                            offset_start = 0,
                            offset_end = 0,
                            delay = 60,
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

"""
Applet: Packt Free Ebook
Summary: Packt's daily free eBook
Description: View Packt's daily free developer eBook.
Author: Daniel Sitnik
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

DEFAULT_COVER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABkAAAAgCAYAAADnnNMGAAAAAXNSR0IArs4c6QAAAShJREFUSEvtls0NwjAMhVOxBmOAKIIDKzANjMA2rMABCSTGgDVQkCO5erXsxpREHKCn5s+f37MjpZkt2hgqfw1BjptJh9mensEz5n3afplzB5GHtDEfpiRwneZ5TjPFrYSCIoT+5RyOEdZTYmUqsxytRMsKg3EClo1Zuyo3V0h2/SFeB7J23a6XMG+XKZ78pzleGwK6IByMIRbYArkglC0FljCp7mMIBqympGpNvB2ULTz6zZvlHFokrUMA1o9r2MQYo2xRzfMhiGxjeb4HQRXW3eBMcZ3PWXNuJe90l7xP6Z54aqKpZLBWE1SVvYzFuqtEoGwL/zYE32aWE/xuGF14hEwP58R57Nc9XlEIRdZAHeS+WxV7SFiKitiVVTL2SfSVmmgdxjV5AclbXRaAhIgGAAAAAElFTkSuQmCC
""")

def main():
    """Main app method.

    Returns:
        render.Root: Root widget tree.
    """

    # packt publishes a new book every day at 00:00 UTC
    # we can calculate how many seconds we have left in the current day and cache the response
    utc_time = time.now().in_location("UTC")
    utc_eod = time.time(
        year = utc_time.year,
        month = utc_time.month,
        day = utc_time.day,
        hour = 23,
        minute = 59,
        second = 59,
        location = "UTC",
    )

    cache_ttl = utc_eod.unix - utc_time.unix

    # try to get book data from cache
    book_data = cache.get("book:data")

    if book_data == None:
        # get from web page
        res = http.get("https://www.packtpub.com/free-learning/")

        if res.status_code != 200:
            print("API error %d: %s" % (res.status_code, res.body()))
            return render_error(res.status_code, res.body())

        book_data = res.body()
        cache.set("book:data", book_data, ttl_seconds = cache_ttl)

    # transform to html nodes
    dom = html(book_data)

    # find title element
    title = None
    title_elem = dom.find("h3.product-info__title")
    if title_elem.len() > 0:
        title = title_elem.text().replace("Free eBook - ", "")
    else:
        title = "No title"

    # find pages element
    pages = None
    pages_elem = dom.find("div.free_learning__product_pages > span")
    if pages_elem.len() > 0:
        pages = pages_elem.text().replace("Pages: ", "")
    else:
        pages = "0"

    # try to get cover from cache
    book_cover = cache.get("book:cover")
    if book_cover != None:
        book_cover = base64.decode(book_cover)
    else:
        # find cover image element
        cover_elem = dom.find("img.product-image")
        if cover_elem.len() > 0:
            # download cover
            cover_res = http.get(cover_elem.attr("src"))

            if cover_res.status_code == 200:
                book_cover = cover_res.body()
                cache.set("book:cover", base64.encode(book_cover), ttl_seconds = cache_ttl)
            else:
                print("Cover download error %d: %s" % (cover_res.status_code, cover_res.body()))
                book_cover = DEFAULT_COVER
        else:
            # use default cover
            book_cover = DEFAULT_COVER

    # calculate space left for content based on the cover width
    cover_widget = render.Image(src = book_cover, height = 32)
    cover_width = cover_widget.size()[0]
    content_width = 64 - cover_width

    return render.Root(
        delay = 100,
        child = render.Row(
            main_align = "space_around",
            cross_align = "start",
            children = [
                cover_widget,
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "start",
                    children = [
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Marquee(
                                scroll_direction = "vertical",
                                height = 24,
                                width = content_width,
                                offset_start = 12,
                                offset_end = 12,
                                child = render.WrappedText(
                                    width = content_width,
                                    content = title,
                                    font = "tom-thumb",
                                    color = "#e3773b",
                                ),
                            ),
                        ),
                        render.Box(
                            width = content_width,
                            height = 6,
                            child = render.Text(
                                content = "{} pages".format(pages),
                                font = "tom-thumb",
                                color = "#fff",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error(status_code, message):
    """Renders the status code and message when there are API errors.

    Args:
        status_code (int): The http status code.
        message (str): The error message.

    Returns:
        render.Root: Root widget tree to show an error.
    """
    return render.Root(
        delay = 100,
        child = render.Row(
            main_align = "space_around",
            cross_align = "start",
            children = [
                render.Image(src = DEFAULT_COVER),
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Text(
                                content = "Error",
                                font = "tom-thumb",
                                color = "#f00",
                            ),
                        ),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Text(
                                content = "Code {}".format(str(status_code)),
                                font = "tom-thumb",
                                color = "#ff0",
                            ),
                        ),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Marquee(
                                width = 38,
                                child = render.Text(
                                    content = message,
                                    font = "tom-thumb",
                                    color = "#fff",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

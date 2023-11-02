"""
Applet: Big Brother News
Summary: Ticker for Big Blagger
Description: Shows the top story from bigblagger.co.uk.
Author: meejle
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

NEWS_ICON = base64.decode("""
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
""")

def main(config):
    fontsize = config.get("fontsize", "tb-8")
    articles = get_cacheable_data("https://bigblagger.co.uk/feed", 1)

    if fontsize == "tb-8":
        return render.Root(
            delay = 50,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 24,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_larger(articles),
                            ),
                    ),
                ],
            ),
        )

    else:
        return render.Root(
            delay = 50,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 24,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_smaller(articles),
                            ),
                    ),
                ],
            ),
        )

def render_article_larger(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#FAE24C", font = "tb-8", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tb-8", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tb-8", color = "#EA37A5", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def render_article_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#FAE24C", font = "tom-thumb", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tom-thumb", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tom-thumb", color = "#EA37A5", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    errorHead = "Error: Couldn't get the top story"
    errorBlurb = "For the latest headlines, visit bigblagger .co.uk"
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 26,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = errorHead, width = 64, color = "#FAE24C", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#EA37A5", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def get_cacheable_data(url, articlecount):
    articles = []

    res = http.get("https://bigblagger.co.uk/feed".format(url), ttl_seconds = 900)
    if res.status_code != 200:
        return connectionError()
    data = res.body()

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

def get_schema():
    fsoptions = [
        schema.Option(
            display = "Larger",
            value = "tb-8",
        ),
        schema.Option(
            display = "Smaller",
            value = "tom-thumb",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "fontsize",
                name = "Change the text size",
                desc = "To prevent long words falling off the edge.",
                icon = "textHeight",
                default = fsoptions[0].value,
                options = fsoptions,
            ),
        ],
    )

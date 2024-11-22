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
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tb-8", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tb-8", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tb-8", color = "#faa708", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def render_article_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tom-thumb", linespacing = 1, width = 64, align = "left"))

        # news_text.append(render.Box(width = 64, height = 2))
        # news_text.append(render.WrappedText("%s" % article[1], font = "tom-thumb", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bigblagger .co.uk", font = "tom-thumb", color = "#faa708", linespacing = 1, width = 64, align = "left"))

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
                    render.WrappedText(content = errorHead, width = 64, color = "#FFFFFF", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#faa708", font = fontsize, linespacing = 1, align = "left"),
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

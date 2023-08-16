"""
Applet: Big Brother News
Summary: Ticker for bbspy
Description: Shows the top story from bbspy.co.uk.
Author: meejle
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

NEWS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAMAAACVQ462AAACN1BMVEUAAAD///93d3e7u7s7OzuYmJji4uJYWFgeHh7v7++Hh4enp6ctLS1nZ2dLS0vT09MODg7JycmRkZHb29uxsbH6+voGBgYFBQUICAj7+/sJCQng4OARERH19fX29vYLCwuBgYGQkJCurq6qqqozMzMxMTEyMjJHR0dGRkbp6elMTExNTU3q6urr6+uhoaGioqKOjo6NjY1jY2MUFBTKysoNDQ0gICAPDw8MDAz09PTz8/MSEhJqamppaWmDg4OCgoKFhYXMzMwoKCgmJibPz89KSkrR0dHS0tLs7OykpKQqKipkZGTx8fHy8vIvLy8nJyckJCSlpaWmpqbu7u4rKyuLi4uKioqJiYksLCxmZmYhISEWFhbAwMCEhIRfX1+GhoaIiIigoKAuLi7t7e0iIiIXFxdhYWHo6OgaGhpRUVFSUlIcHBwbGxtcXFxZWVlQUFBTU1MdHR1VVVVaWlpPT09WVlZXV1ff39/Q0NCAgIDY2Njm5ubk5OTe3t7l5eXn5+dBQUHW1taSkpKTk5Obm5vj4+Pc3NxDQ0NFRUWVlZWdnZ2enp6UlJSWlpbh4eHFxcXIyMjDw8MwMDA/Pz+ysrI0NDQ+Pj44ODg5OTmwsLC/v7+zs7O1tbW9vb20tLS2tra5ubm6urpgYGCPj49sbGxubm5vb29wcHBxcXFzc3NycnJ0dHR1dXV2dnZ+fn58fHx5eXl7e3t9fX339/cQEBD4+Pjw8PAEBAQBAQH5+fn8/Pz9/f3+/v69J2ETAAACa0lEQVR42u3S6TdUYQDH8d9vIiTJkkH2pbIr2Yq0kDU0WRrUMGNJmzRFZEwUWqi0UFFUSqI0lca4/rieuaOjV0m9quPz6neec+73PM85F2v+Tc0e7vgbtR5kKf7c8eciwNfLB0rvn9ZviB+fpLD8CteYYNtIvOd0HSsyl9hTdgtLyFHbqNNxHCuqyFGXU2YPGx+GJr1JKwQqdQxpnhBL2Pi+LVKJ2lcHETXTmIwih6ZEcTrcEuWN/MVd+ym78SPQEyPfKEHHjmhrWYl8ieSgbwZf9pPcGnaeTAf8etibApxcVGsou7MU4IKhgNyXkmNdTqRGeZcGlX97cgbJgs5FNjzxYBVwgQyCcG7BJYOyWLMcsDjMF2ezIdxIi36+4jAjwnvoNjyUgGpy7IyXiTwRREsJnOlfBLnAtI+U5ZpFQH6LA3m5lbfFaiGvDZBsnYCGqYcAcyarSixU+EbTGVbeuZTSPlOmMotAmTjcTuoN3CnWDnITNDqSF03UnRIngzyAET7Tky4QfEeYHim9+0TZuAgYtfAa4Te7TkY8gNKTc8WFedCLm83K/2yWD2vQxD3tJHfX56nXcRJolBT13f3dpQP9IkCnUVcy7msOeeyFWDXagFT7WIkbTNZPPI9QegjfLpJlk+u5hZyFcOnLo9Apx5pagGwIIHl/r5+ORuty80syULh6to1zvSSltwAUpJMjlH0dpB2ssqSu08bszYApXtunUuUHQjkdrO076qwOBBKmQjzbHFFNaUjxND4MglZiHIShsQ+w2VaX516JX6omh7FkmryJ1SpfDnhdYaYZq6WgpRA2j304gzX/r+8805IKkDVoSgAAAABJRU5ErkJggg==
""")

def main(config):
    fontsize = config.get("fontsize", "tb-8")
    articles = get_cacheable_data("https://www.bbspy.co.uk/feed", 1)

    if fontsize == "tb-8":
        return render.Root(
            delay = 50,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 26,
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
                        offset_start = 26,
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
        news_text.append(render.WrappedText("%s" % article[0], color = "#e48a47", font = "tb-8", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("%s" % article[1], font = "tb-8", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bbspy.co.uk", font = "tb-8", color = "#964c98", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def render_article_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.Image(width = 64, height = 32, src = NEWS_ICON))
        news_text.append(render.WrappedText("%s" % article[0], color = "#e48a47", font = "tom-thumb", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("%s" % article[1], font = "tom-thumb", color = "#ffffff", linespacing = 1, width = 64, align = "left"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at bbspy.co.uk", font = "tom-thumb", color = "#964c98", linespacing = 1, width = 64, align = "left"))

    return (news_text)

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    errorHead = "Error: Couldn't get the top story"
    errorBlurb = "For the latest headlines, visit bbspy.co.uk"
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
                    render.WrappedText(content = errorHead, width = 64, color = "#e48a47", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def get_cacheable_data(url, articlecount):
    articles = []

    res = http.get("https://www.bbspy.co.uk/feed".format(url), ttl_seconds = 900)
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

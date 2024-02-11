"""
Applet: Wiki Page Today
Summary: Wikipedia Featured Article
Description: Display Wikipedia's Featured Article of the Day in a Tidbyt format.
Author: UnBurn
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIKIPEDIA_URL = "https://api.wikimedia.org/feed/v1/wikipedia/%s/featured/%s"
WIKIPEDIA_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAGCAYAAAAPDoR2AAAALUlEQVQIW2NkAIL/QACikQEjCIAkgBRIAVwOxkeRhAtCFROWBJmHrgsshs9BAO7FNfeFAdnIAAAAAElFTkSuQmCC")
WIKIPEDIA_THUMBNAIL = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAM6SURBVFhH7ZfLK7RxFMd/80xvhIUklyiSWIh6SbmEjbKgpkRZKclrIyv8A1aYjetMk4WFWVJko9hY0ZRZoCgLJAkb5JLb9/2d85x554m5WbwzG5966jnfM/Oc7+/8Ls+MIgAYHx8fffra1deLjv8L9Gyp0adDw1rcy5+II1LTsJEbm83mYTdxRhv4QwZ2tYHfosUVbcBve9H80ogWV141NpoPiROCuRITyI+BL2vA6XSq5+dniUwaGhpUU1OT8ng86urqSlSlysvLlcPhUPPz8+ry8lJUpTo7O1VOTo6anp4WxSQ5OVkNDQ1JJJABK36/H729vWSKr9XVVeiHc25vbw91dXWst7S04OTkhPWjoyN0dHRAbyZ4vV7c399DL3Bsb2+jtbUVeptjcHAQPp+PP2/liwHi9vYW6enp/wxYoYfSA/Py8vD4+MiaPktQWVmJ/v5+jq309PSgvb1doq+ENECMjIywgcbGRlGCNDc3c25mZobjtbU16Pbi7OyM4wA3NzdISUkJOfIAYQ2cn58jKSmJR7uzsyOqyebmJhsoKCiAXi88LdTiz4yPj4ccgJWwBghqHxXSi0oUE2p5TU0N57q7u5GamoqLiwvJmry9vaGoqAjLy8uihCaigYODAxiGAbvdjuPjY1FNVlZW2ABdw8PDogahtVNcXMxGIhHRANHW1sZFBgYGRDF5f3+H3oacW1xcFDUI7ZKpqSmJwhPVwNbWFhdJS0vD9fW1qCa1tbWcq6ioYEMBDg8PkZGRgbu7O1HCE9WAdb5HR0dFBdbX15GVlYWSkhLOWeeaFmSoaQlFVAPE0tISF8nOzua9T6b06YiJiQksLCxwrqqqinUadWZmJk5PT+XbkYnJALU3MFJ9HGNjYwO5ubl4eHiA/jmBwsJCztF5MDc3h66uLvlmdGIyQLjdbi5SWlqK+vp6TE5OSgaYnZ3lXHV1NcrKyvi0jJWYDVDr9QuGC+Xn5+Pp6UkyZo46Qjky9x1iNkDQIqQiLpdLlCB06lGO1st3+JYBesuNjY3xm+4z1BGaCut2jIWf34SGbsCr3Mcdqk0d2DfDhLBPBlzmfUJwURsS+ueUbdCNFhLw91ypvxbdg++ANBC+AAAAAElFTkSuQmCC")


TTL_TIME = 86400
MARQUEE_DELAY = 150

DEFAULT_LANG = "en"
DEFAULT_COLOR = "#FFFFFF"

def get_featured_article_json(lang, date):
    url = WIKIPEDIA_URL % (lang, date)

    article_json = http.get(url, ttl_seconds = TTL_TIME).json()
    return article_json

def extract_article_information(article_json):
    article = article_json["tfa"]
    title = article["normalizedtitle"]
    extract = article["extract"]
    description = get_reduced_extract(extract)
    if "thumbnail" in article and "source" in article["thumbnail"]:
        image = http.get(article["thumbnail"]["source"], ttl_seconds = TTL_TIME).body()
    else:
        image = WIKIPEDIA_THUMBNAIL
    return (title, extract, description, image)

def has_featured_article(article_json):
    return 'tfa' in article_json.keys() and 'extract' in article_json['tfa'].keys()

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

def main(config):
    CURRENT_ARTICLE_UNAVAILABLE = False
    PREVIOUS_ARTICLE_UNAVAILABLE = False

    lang = config.str("lang", DEFAULT_LANG)
    today =  time.now().format("2006/01/02")
    article_json = get_featured_article_json(lang, today)

    # Check if the current day's article is present in the JSON
    if has_featured_article(article_json):
        title, extract, description, image = extract_article_information(article_json)
    # Otherwise, get yesterday's article
    else:
        CURRENT_ARTICLE_UNAVAILABLE = True
	yesterday = (time.now() - time.parse_duration("24h")).format("2006/01/02")
	article_json = get_featured_article_json(lang, today)
	if has_featured_article(article_json):
            title, extract, description, image = extract_article_information(article_json)
        else:
            PREVIOUS_ARTICLE_UNAVAILABLE = True

    # If neither the current nor previous article can be found, fail 
    if CURRENT_ARTICLE_UNAVAILABLE and PREVIOUS_ARTICLE_UNAVAILABLE:
        fail("Featured article is currently unavailable")

    top_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 6, color = "#3f3f3f"),
            render.Row(
                children = [
                    render.Padding(child = render.Image(src = WIKIPEDIA_ICON, width = 7, height = 6), pad = (1, 0, 1, 0)),
                    render.Marquee(
                        width = 56,
                        delay = MARQUEE_DELAY,
                        child = render.Text(
                            title,
                            font = "tom-thumb",
                        )
                    ),
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
                child = (
                    render.WrappedText(
                        content = description,
                        font = "tb-8",
                        color = config.str("color", DEFAULT_COLOR)
                    )
                ),
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

def get_schema():
    options=[
        schema.Option(
            display="Deutsch",
            value="de",
        ),
        schema.Option(
            display="English",
            value="en",
        ),
        schema.Option(
            display="Magyar",
            value="hu",
        ),
        schema.Option(
            display="Latina",
            value="la",
        ),
        schema.Option(
            display="Svenska",
            value="sv",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields=[
            schema.Dropdown(
                id="lang",
                name="Language",
                desc="The language of the article",
                icon="language",
                default="en",
                options=options,
            ),
            schema.Color(
                id="color",
                name="Color",
                desc="The color of the font",
                icon="brush",
                default=DEFAULT_COLOR,
            ),
        ],
    )
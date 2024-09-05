"""
Applet: Czechianews
Summary: Headline news from Czechia
Description: Dispaly only the news title from Czechia.
Author: solarisle
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

MEDIA_SEZNAM = "seznam"
MEDIA_IROZHLAS = "irozhlas"

SEZNAM_URL = "https://www.seznamzpravy.cz/"
IROZHLAS_URL = "https://www.irozhlas.cz/"

SEZNAM_ICON = base64.decode("UklGRswAAABXRUJQVlA4TMAAAAAvH8AHEDcgEEjaH3oNgUCSv9tMCwiK/B+NIIAkf6o2GGWDA/yvwFALhOPatp3k0QGHNPcCzi0hz7GCbP9FvGAJEf1XmLYNY6fzFLMW7wiNWeC36BUAnhdJmhzAUc4B3E/BDjA4lCw5DVusAYDIZcJ7dHyJPiVpIFOS7imrJI1prlK1rKqyLfW6udyL1Gs1YCcph1WailGTH3+xT4llbeSi00STcNNpgMZcnosuE4CZGdx0+gFumj2W0xcgTGvxegA=")
IROZHLAS_ICON = base64.decode("UklGRmwAAABXRUJQVlA4TGAAAAAvH8AHACegEEAAxJ+2oREIJP5ezbOCQCDZH3eB5j/441gGGLRtJKkQ9hisBsFB2I8/qflnCET0fwLABz1dALBc04UjkVHKJ6MEY5f6kJfrd2G7Vlh9GH3XNV247LMe1h8=")

DEFAULT_COLOR = "#FF0000"
TEXT_SPEED = "100"

def main(config):
    if config.str("media_source", MEDIA_SEZNAM) == MEDIA_SEZNAM:
        response = http.get(SEZNAM_URL, ttl_seconds = 300)
    else:
        response = http.get(IROZHLAS_URL, ttl_seconds = 300)

    if response.status_code != 200:
        return render.Root(
            child = render.WrappedText(
                content = "Web source not availible now",
                color = DEFAULT_COLOR,
                width = 64,
            ),
        )

    if config.str("media_source", MEDIA_SEZNAM) == MEDIA_SEZNAM:
        news_title = parse_head_line_seznam(response.body())
    else:
        news_title = parse_head_line_irozhlas(response.body())

    return render_text(config, news_title)

def parse_head_line_seznam(htmlBody):
    #fetch the first <h3> element
    html_elements = html(htmlBody).find("h3")
    if html_elements.len() == 0:
        html_text = ""
    else:
        html_text = html_elements.eq(0).text()

    if html_text == "":
        html_text = "There is no news..."

    return html_text

def parse_head_line_irozhlas(htmlBody):
    #fetch the second <h3> element
    html_elements = html(htmlBody).find("h3")
    if html_elements.len() < 2:
        html_text = ""
    else:
        html_text = html_elements.eq(2).text()

    if html_text == "":
        html_text = "There is no news..."

    return html_text

def render_text(config, headlineText):
    if config.str("media_source", MEDIA_SEZNAM) == MEDIA_SEZNAM:
        iconFile = SEZNAM_ICON
    else:
        iconFile = IROZHLAS_ICON

    return render.Root(
        delay = int(config.str("text_speed", TEXT_SPEED)),
        child = render.Marquee(
            width = 64,
            height = 32,
            scroll_direction = "vertical",
            align = "center",
            child = render.Column(
                cross_align = "center",
                children = [
                    render.Image(src = iconFile, width = 12, height = 12),
                    render.WrappedText(
                        content = headlineText,
                        color = config.str("font_color", DEFAULT_COLOR),
                        width = 64,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "font_color",
                name = "Font Color",
                desc = "Color of the font",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Dropdown(
                id = "text_speed",
                name = "Display Speed",
                desc = "The speed for rotating the text.",
                icon = "personRunning",
                default = "100",
                options = [
                    schema.Option(
                        display = "Fast",
                        value = "50",
                    ),
                    schema.Option(
                        display = "Normal",
                        value = "100",
                    ),
                    schema.Option(
                        display = "Slow",
                        value = "150",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "media_source",
                name = "Media Source",
                desc = "Select your favorite news source.",
                icon = "bars",
                default = "seznam",
                options = [
                    schema.Option(
                        display = "seznamzpravy.cz",
                        value = "seznam",
                    ),
                    schema.Option(
                        display = "irozhlas.cz",
                        value = "irozhlas",
                    ),
                ],
            ),
        ],
    )

"""
Applet: MercuryRetrograde
Summary: Mercury Retrograde
Description: Is Mercury in retrograde?
Author: FlyingLooper
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://mercuryretrogradeapi.com"
DEFAULT_COLOR = "#ffffff"
DEFAULT_COLOR_FALSE = "#00ff00"
DEFAULT_COLOR_TRUE = "#ff0000"
PADDING = 1
TTL_SECONDS = 60 * 60 * 24

def main(config):
    color = DEFAULT_COLOR
    message = ""
    response = http.get(API_URL, ttl_seconds = TTL_SECONDS)

    if response:
        if response.json().get("is_retrograde"):
            text = ""
            color = config.get("color_true", DEFAULT_COLOR_TRUE)
        else:
            text = "not "
            color = config.get("color_false", DEFAULT_COLOR_FALSE)

        message = "Mercury is %sin retrograde." % text

    if message:
        return render.Root(
            render.Padding(
                child = render.Box(
                    child = render.WrappedText(
                        content = message,
                        color = color,
                    ),
                ),
                pad = PADDING,
            ),
        )
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color_true",
                name = "Yes Color",
                desc = "The color of text if Mercury is in retrograde",
                icon = "brush",
                default = DEFAULT_COLOR_TRUE,
            ),
            schema.Color(
                id = "color_false",
                name = "No Color",
                desc = "The color of text if Mercury is not in retrograde",
                icon = "brush",
                default = DEFAULT_COLOR_FALSE,
            ),
        ],
    )

"""
Applet: Buienradar
Summary: Buienradar (BE/NL)
Description: Shows the rain radar of Belgium or The Netherlands.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_COUNTRY = "NL"

def get_radar(country = DEFAULT_COUNTRY, ttl_seconds = 60 * 15):
    url = "https://image.buienradar.nl/2.0/image/animation/RadarMapRainWebMercator{}?width=64&height=64&renderBackground=True&renderBranding=False&renderText=False".format(country)
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Buienradar request failed with status %d @ %s", response.status_code, url)
    return response.body()

def main(config):
    country = config.str("country", DEFAULT_COUNTRY)

    radar = get_radar(country)
    radar_image = render.Image(
        src = radar,
        width = 64,
        height = 64,
    )

    return render.Root(
        delay = radar_image.delay,
        child = render.Stack(
            children = [
                render.Box(
                    child = radar_image,
                ),
                render.Padding(
                    pad = (1, 1, 1, 1),
                    child = render.WrappedText(
                        width = 24,
                        linespacing = 1,
                        content = "Buien- radar",
                        color = "#fff",
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Nederland",
            value = "NL",
        ),
        schema.Option(
            display = "België",
            value = "BE",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "country",
                name = "Land",
                desc = "Welk land weergegeven moet worden.",
                icon = "globe",
                default = options[0].value,
                options = options,
            ),
        ],
    )

"""
Applet: Daily Horoscope
Summary: Daily horoscope
Description: Displays today's horoscope for a specific sign from USA Today.
Author: frame-shift
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set default values
DEFAULT_SIGN = "aries"
DEFAULT_SPEED = "70"

# 12x12 zodiac icons
SIGN_ICONS = {
    "aries": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAATklEQVQoU2NkAILHkVb/QTQhILv8GCMjTLHMsqNg9U+irFH0oYuDNYAEYQoJseEaYKZj04BsC9xJMHfgsgEmj6EBJIHLPyC5kamB1KQBAC3GVp8HxI4rAAAAAElFTkSuQmCC",
    "aquarius": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAASElEQVQoU2NkAAKp8pn/QTQh8KwznZGRWMUww1A0PO1IY5CumAWWw8WGawApAAGQBlxskDxYA8w0fJpgNo/6gVBMg4OV1KQBADlYWafbstR4AAAAAElFTkSuQmCC",
    "cancer": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAYElEQVQoU5VS0RIAIQQ8P8s38bNXbkaDTDovlWy7S/DMYOZX1y6ICOC22B7bAIgYiEQknBfACn2BB1v+A+iFJfy+8tQCMnMrKTMfu1RJ3RhUd2U8mPbmrtvaTXkN7u/XGJD+U/F0szLpAAAAAElFTkSuQmCC",
    "capricorn": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAXklEQVQoU2NkAIKEpMT/IJoQWDBvPiMjsYphhsE1zJ87jyExOYkBRIMAiI0NoNgA0wRSiMxG1kh9Deg24bUB5hdkTXhDCTkgYIGAUwM2xSAbMTSQFKyEYhpsA6lJAwDj71BhsUw4fwAAAABJRU5ErkJggg==",
    "gemini": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAATUlEQVQoU2NkAIL/m8T/g2hCgNHvJSMjsYphhiE0+L6AiG2WQLUITRzVBpgkutuQDMF0EkgTTAEyG2rIoNdAkqfJClZCUQ2UZyQ1aQAAxm4/00fMRqwAAAAASUVORK5CYII=",
    "leo": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAYUlEQVQoU2NkAILnfXr/QTQhIFl0iZGRWMUww7BqkCi8iGLZi359OB9DA0wxTBE6H0UDuiTMWJA4zAC4BmRBXGyQAXg1YLMRr5OQbcIbSiBJXM7CGw8EnUQopsGeJjVpAABkylJhynoggAAAAABJRU5ErkJggg==",
    "libra": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAV0lEQVQoU2NkAILHLpX/QTQhILunnZGRWMUww7BqkNndBpZ/4lqFYSmGBpBimEJkNlYbsClAF0OxgWQNIGuJdhLMo8iexSZGfrAim4YtAmEhR7oNpCYNALPARkNsD3IMAAAAAElFTkSuQmCC",
    "pisces": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAUElEQVQoU2NkAILOPfH/QTQhUO6ykJGRWMUww+AaypwXMHTtTcBqCbIcig3YNKGLYTgJWQE2AyjTADIRG0D2G2U2gEwnyQ8khRLR8UBq0gAAR0JVa3NL0ucAAAAASUVORK5CYII=",
    "sagittarius": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAXklEQVQoU2NkAILNTi3/QTQh4LuvhpGRWMUww7Bq8NlbjWHZFudWsBhBG2CasWoAScIkQKbB+MjiGDZgU4RXA7LJMI+QbANyCKA4CZcfsGpAV4wrEgkGK7pGRlKTBgCdwk29wbksRwAAAABJRU5ErkJggg==",
    "scorpio": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAUElEQVQoU2NkAAInJ6f/IJoQ2LdvHyMjsYphhoE17N27F8x3dnZmQGZjsxGuAaYYmR6kGmB+gvmRKD8gBwRBDSDFyAGBMx5wBS/pEUdq0gAAl99kvyhWgR8AAAAASUVORK5CYII=",
    "taurus": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAU0lEQVQoU2NkAALH5ZP/g2hCYH9kLiMjsYphhsE17IvIAYs5rZiCYhG6OIYNIAUwTchsDBuQjcVlG0gNZTZgcwK6GIoNJGsAuZH2niYU24ykJg0AB1NK0YLvzgsAAAAASUVORK5CYII=",
    "virgo": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAW0lEQVQoU2NkAIJtXcb/QTQh4FV2lpGRWMUww+AaPEvPgMW2d5swILPRbUXRAFOMjcZqA7pCZBtBciBA0AaQIpATaacB2XS8TkJ3Coan0YMPZjJ6EJMecaQmDQD8GXGBlHyauAAAAABJRU5ErkJggg==",
}

# Error messages
def render_error(code):
    return render.Root(
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText(
                    color = "#ff00ff",
                    content = "Horoscope error",
                    font = "CG-pixel-4x5-mono",
                    align = "center",
                ),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#ff00ff",
                ),
                render.WrappedText(
                    content = code,
                    font = "tb-8",
                    align = "center",
                ),
            ],
        ),
    )

# Main app
def main(config):
    zodiac = config.str("zodiac_choice", DEFAULT_SIGN)
    horoscope_url = "https://www.usatoday.com/horoscopes/daily/" + zodiac

    # Get horoscope data
    scope_response = http.get(horoscope_url, ttl_seconds = 3600)  # Cache for 1 hour

    if scope_response.status_code != 200:
        return render_error("Could not reach source")

    scope_html = html(scope_response.body())

    # Parse date that horoscope was written
    date_extracted = scope_html.find("time").attr("datetime")

    if date_extracted == None:
        return render_error("Could not get date")

    date_parsed = time.parse_time(date_extracted, format = "2006-01-02")
    date_m = humanize.time_format("MMM", date_parsed).upper()
    date_d = humanize.time_format("d", date_parsed)

    # Parse horoscope
    horoscope = scope_html.find("p").eq(1).text()

    if horoscope == "":
        return render_error("Could not get horoscope")

    # Display everything!
    scroll_speed = int(config.str("speed_choice", DEFAULT_SPEED))
    date_font = "CG-pixel-3x5-mono"
    date_color = "#ffda9c"

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Row(
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            child = render.Image(src = base64.decode(SIGN_ICONS[zodiac])),
                            pad = (0, 0, 2, 4),
                        ),
                        render.Padding(
                            child = render.Text(
                                content = date_m,
                                font = date_font,
                                color = date_color,
                            ),
                            pad = (0, 0, 0, 1),
                        ),
                        render.Text(
                            content = date_d,
                            font = date_font,
                            color = date_color,
                        ),
                    ],
                ),
                render.Marquee(
                    child = render.WrappedText(
                        content = horoscope,
                        font = "tom-thumb",
                    ),
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 24,
                    offset_end = -32,
                ),
            ],
        ),
    )

# Options menu
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # Select zodiac sign
            schema.Dropdown(
                id = "zodiac_choice",
                name = "Zodiac sign",
                desc = "The zodiac sign you wish to follow",
                icon = "star",
                options = [
                    schema.Option(display = "Aries", value = "aries"),
                    schema.Option(display = "Taurus", value = "taurus"),
                    schema.Option(display = "Gemini", value = "gemini"),
                    schema.Option(display = "Cancer", value = "cancer"),
                    schema.Option(display = "Leo", value = "leo"),
                    schema.Option(display = "Virgo", value = "virgo"),
                    schema.Option(display = "Libra", value = "libra"),
                    schema.Option(display = "Scorpio", value = "scorpio"),
                    schema.Option(display = "Sagittarius", value = "sagittarius"),
                    schema.Option(display = "Capricorn", value = "capricorn"),
                    schema.Option(display = "Aquarius", value = "aquarius"),
                    schema.Option(display = "Pisces", value = "pisces"),
                ],
                default = DEFAULT_SIGN,
            ),

            # Select scroll speed
            schema.Dropdown(
                id = "speed_choice",
                name = "Scroll speed",
                desc = "How fast the horoscope scrolls",
                icon = "gaugeSimpleHigh",
                options = [
                    schema.Option(display = "Slower", value = "120"),
                    schema.Option(display = "Slow", value = "90"),
                    schema.Option(display = "Normal", value = DEFAULT_SPEED),
                    schema.Option(display = "Fast", value = "55"),
                    schema.Option(display = "Faster", value = "40"),
                ],
                default = DEFAULT_SPEED,
            ),
        ],
    )

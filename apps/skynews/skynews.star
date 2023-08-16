"""
Applet: Sky News
Summary: Latest news
Description: The current top story (and a short blurb) from SkyNews.com.
Author: meejle
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NEWS_ICON = base64.decode("""
R0lGODlhQAAgANUAAMsFBlFRUfvV1XR0dJmZme5BQ+EMDvaam9TU1Lq6uuwpKzg4OPerrLOzs/709cPDw6urq2gDBGZmZvSys/JzdYODg+uEhPFsbe5JSvrg4BQUFOwxM+5iY/SjpPSCg8rKyu06O8AiJHcrK3cdHvrFxvfCwiYmJu9RU/rLy+9ZWuZzdOJVVv3p6SgEBOc4OcQCA74BAePj49sKC9IHCNYICvzc3frR0fnHyOhISeMdHt9GRv3w8ORHSPKUlf///wAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RTM3MzI0OTk5RENDMTFFREFGRThENkRDMjM0MDcwRTEiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RTM3MzI0OUE5RENDMTFFREFGRThENkRDMjM0MDcwRTEiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpFMzczMjQ5NzlEQ0MxMUVEQUZFOEQ2REMyMzQwNzBFMSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpFMzczMjQ5ODlEQ0MxMUVEQUZFOEQ2REMyMzQwNzBFMSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovq6ejn5uXk4+Lh4N/e3dzb2tnY19bV1NPS0dDPzs3My8rJyMfGxcTDwsHAv769vLu6ubi3trW0s7KxsK+urayrqqmop6alpKOioaCfnp2cm5qZmJeWlZSTkpGQj46NjIuKiYiHhoWEg4KBgH9+fXx7enl4d3Z1dHNycXBvbm1sa2ppaGdmZWRjYmFgX15dXFtaWVhXVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj08Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQQDAgEAACH5BAAAAAAALAAAAABAACAAAAb/wJ9wSCwaj8ikcslsOp/QqHRKrVqv2Kx2y+16v1iNydlSmM/otHrNNoeOCwTCOdrY7/i8fs+/HyVydCCDhIWGh4iJhEILjQsagHNCGgtjQ5QaPyMFnJ2en6Chop0LCR+nHxISp0IBqJk/GqYBPyIYtzYdJD41HrcYHjW8vgc2vzYktxw2Hhe7PjYHvwkP1dULEtU/C9YPBEIDDw2ZIifmPj4CDCw+FCcH6QwCPh499Cce6O7wFCwODAxQMDB3IkGCAZZ+SDBoAkICCBUMPnIoQYiIFBh9oMB4wQeDFA4EYEwhIEPHjyXYdUiBwkEKjSlO/MIAgkCDmw0qmAhwE0ID/wgmNNgkwHOcRQ5IfUxIcctHBwoaJ0id50LAjRwsDky4uqODAXtdLxgYa0DDAIcGiVIj8MHogg8I4FYYIoKsDwt2LeDwkaGEX79ffbgQzMHHXg5jU3TIoJTspQoxEAyIEWMB5W8/CFCuPCSCjM93P8sIrVS0aB4+SuyQoQCajxymZXTwIRry5siTY/ywTUsD5QREItAYfnc4jeL2JqxQoXz4DqfDbUAbPsGCjhU2dhiHcBtBgMlzZEXW4DsGrc4z0vtQkX7G3fQWnvNdkX6CDx3w16cvgW5+exOOPBKLgAMukFkMHxQRAQAMNujggxBGKGGDT5Q3gIITZqjhhE9IMDGegi+EKOKIJJZo4okiQpEQES3A4OKLMMYo44w0vgjGjTjmqOOOPPbo449ABimkFEEAADs=
""")

def main(config):
    fontsize = config.get("fontsize", "tb-8")
    GET_SKYNEWS = http.get("http://www.mikelee.me.uk/stuff/xml-to-json/?xml=https://feeds.skynews.com/feeds/rss/home.xml", ttl_seconds = 900)
    if GET_SKYNEWS.status_code != 200:
        return connectionError()
    GET_HEADLINE = GET_SKYNEWS.json()["rss"]["channel"]["item"][0]["title"]
    GET_BLURB = GET_SKYNEWS.json()["rss"]["channel"]["item"][0]["description"][1]
    finalheadline = str(GET_HEADLINE)
    finalblurb = str(GET_BLURB)

    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 24,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = finalheadline, width = 64, color = "#fde000", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = finalblurb, width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    errorHead = "Error: Couldn't get the top story"
    errorBlurb = "For the latest headlines, visit skynews.com"
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 24,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = errorHead, width = 64, color = "#fde000", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

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

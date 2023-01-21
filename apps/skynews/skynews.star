"""
Applet: Sky News
Summary: Latest news
Description: The current top story (and a short blurb) from SkyNews.com.
Author: meejle
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")

NEWS_ICON = base64.decode("""
R0lGODlhQAAgALMAANEEA+05Ouw9PcwDA+02N8gDA90EBOxFRdoEBNYEBOxBQetISf///wAAAAAAAAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNy4xLWMwMDAgNzkuOWNjYzRkZTkzLCAyMDIyLzAzLzE0LTE0OjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjMuMyAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzM5RTMwQjk5OTBEMTFFREI1N0FBOENEQUFERDJEQTciIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzM5RTMwQkE5OTBEMTFFREI1N0FBOENEQUFERDJEQTciPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMzlFMzBCNzk5MEQxMUVEQjU3QUE4Q0RBQUREMkRBNyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMzlFMzBCODk5MEQxMUVEQjU3QUE4Q0RBQUREMkRBNyIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovq6ejn5uXk4+Lh4N/e3dzb2tnY19bV1NPS0dDPzs3My8rJyMfGxcTDwsHAv769vLu6ubi3trW0s7KxsK+urayrqqmop6alpKOioaCfnp2cm5qZmJeWlZSTkpGQj46NjIuKiYiHhoWEg4KBgH9+fXx7enl4d3Z1dHNycXBvbm1sa2ppaGdmZWRjYmFgX15dXFtaWVhXVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj08Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQQDAgEAACH5BAAAAAAALAAAAABAACAAAATTsMlJq7046827/2AojmRpnmiqrmzrvnAszyjTEXiu7zx/2puAcEgsGo8BE1AjaDqf0KhUEGJYJcDsBKjoMhTWLjgMFn/H5y5oaWtv342D3Do/MOT2fP1el1fZSw1sEguFDIULh1aLiY2HiY+II1qDgkAGmAyYBpqam5ygnpmfa29aWG4NCKsMqwitrayvs7CusQh/p4IVQAm+DL4JwMJWwcDDxMgJLJUAzs/Q0dLTAC2LEwPZ2tvc3d4DNAXi4+Tl5uY06err7O3u7/Dx8vP09fYUEQA7
""")

def main():
    headline_cached = cache.get("cached_headline")
    blurb_cached = cache.get("cached_blurb")
    if headline_cached != None and blurb_cached != None:
        finalheadline = str(headline_cached)
        finalblurb = str(blurb_cached)
    else:
        GET_SKYNEWS = http.get("https://api.factmaven.com/xml-to-json/?xml=https://feeds.skynews.com/feeds/rss/home.xml")
        if GET_SKYNEWS.status_code != 200:
            return connectionError()
        GET_HEADLINE = GET_SKYNEWS.json()["rss"]["channel"]["item"][0]["title"]
        GET_BLURB = GET_SKYNEWS.json()["rss"]["channel"]["item"][0]["description"][1]
        finalheadline = str(GET_HEADLINE)
        cache.set("cached_headline", finalheadline, ttl_seconds=900)
        finalblurb = str(GET_BLURB)
        cache.set("cached_blurb", finalblurb, ttl_seconds=900)

    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height= 32,
            offset_start = 32,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = finalheadline, width = 64, color = "#fde000", font = "tb-8", linespacing = 0, align = "left"),
                    render.WrappedText(content = finalblurb, width = 64, color = "#fff", font = "tb-8", linespacing = 0, align = "left"),
                ]
            ),
        ),
    )

def connectionError():
    errorHead = "Error: Couldn't get the top story"
    errorBlurb = "For the latest headlines, visit skynews.com"
    return render.Root(
        delay = 70,
        child = render.Marquee(
            scroll_direction = "vertical",
            height= 32,
            offset_start = 32,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = errorHead, width = 64, color = "#fde000", font = "tb-8", linespacing = 0, align = "left"),
                    render.WrappedText(content = errorBlurb, width = 64, color = "#fff", font = "tb-8", linespacing = 0, align = "left"),
                ]
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

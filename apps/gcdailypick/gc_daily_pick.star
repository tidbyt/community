"""
Applet: GC Daily Pick
Summary: Guitar Center daily pick
Description: Shows the daily pick deal from Guitar Center.
Author: Bennett Schoonerman
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")

# only changes once per day but we will refetch on the hour to be safe
CACHE_TTL = 3600

# Load Guitar Center logo from base64 encoded data
GUITAR_CENTER_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAoAAAAF/BAMAAAArz2VBAAAFnmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgdGlmZjpJbWFnZUxlbmd0aD0iMzgzIgogICB0aWZmOkltYWdlV2lkdGg9IjY0MCIKICAgdGlmZjpSZXNvbHV0aW9uVW5pdD0iMiIKICAgdGlmZjpYUmVzb2x1dGlvbj0iNzIvMSIKICAgdGlmZjpZUmVzb2x1dGlvbj0iNzIvMSIKICAgZXhpZjpQaXhlbFhEaW1lbnNpb249IjY0MCIKICAgZXhpZjpQaXhlbFlEaW1lbnNpb249IjM4MyIKICAgZXhpZjpDb2xvclNwYWNlPSIxIgogICBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIgogICBwaG90b3Nob3A6SUNDUHJvZmlsZT0ic1JHQiBJRUM2MTk2Ni0yLjEiCiAgIHhtcDpNb2RpZnlEYXRlPSIyMDI0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
""")

def fetchDealImage(page):
    imageUrl = page.find(".daily_pick_content .dealImage").attr("src")
    resp = http.get(
        url = imageUrl,
        headers = {
            "User-Agent": "Tidbyt App: Daily Pick",
        },
        ttl_seconds = CACHE_TTL,
    )
    return resp.body()

# helper to remove new lines like Price or Save that is part of the scraped text
def polishStrings(input_string):
    # Find the indices of '\n' and '\u00a0'
    start_index = input_string.find("\n")
    end_index = input_string.find("\u00a0")

    if start_index != -1 and end_index != -1:
        modified_string = input_string[:start_index] + input_string[end_index + 2:]
        return modified_string
    else:
        return input_string

def extractDealInfo(page):
    dealImageData = fetchDealImage(page)
    data = {
        "itemName": page.find(".daily_pick_content .displayNameColor").text(),
        "originalPrice": page.find(".dailypick-was .price-display-value").text(),
        "savings": polishStrings(page.find(".daily_pick_content .dailypick-save").text()),
        "price": polishStrings(page.find(".daily_pick_content .dailypick-price").text()),
        "dealImage": dealImageData,
    }
    return data

def getDailyPick():
    resp = http.get(
        url = "https://www.guitarcenter.com/Daily-Pick.gc",
        headers = {
            "User-Agent": "Tidbyt App: Daily Pick",
        },
        ttl_seconds = CACHE_TTL,
    )
    page = html(resp.body())
    return extractDealInfo(page)

def main():
    data = getDailyPick()

    # print(data)
    return render.Root(
        child = render.Stack(
            children = [
                animation.Transformation(
                    duration = 450,
                    child = render.Image(src = GUITAR_CENTER_LOGO, width = 64, height = 32),
                    keyframes = [
                        #slide GC logo up
                        animation.Keyframe(
                            percentage = 0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 0.1,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 0.2,
                            transforms = [animation.Translate(0, -64)],
                        ),
                        animation.Keyframe(
                            percentage = 1,
                            transforms = [animation.Translate(0, -64)],
                            curve = "ease_in",
                        ),
                    ],
                ),
                animation.Transformation(
                    duration = 450,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(data["itemName"], ""),
                                offset_start = 5,
                                offset_end = 32,
                            ),
                            render.Row(
                                children = [
                                    render.Column(
                                        children = [
                                            render.Box(width = 40, height = 8, child = render.Row(children = [render.Text(content = data["originalPrice"])])),
                                            render.Box(width = 40, height = 8, child = render.Text(content = "-" + data["savings"], color = "#EA202E")),
                                            render.Box(width = 40, height = 1, child = render.Row(children = [render.Box(width = 30, height = 1, color = "#ccc")])),
                                            render.Box(width = 40, height = 8, child = render.Text(content = data["price"], color = "#85BB65")),
                                        ],
                                    ),
                                    render.Image(width = 24, height = 24, src = data["dealImage"]),
                                ],
                            ),
                        ],
                    ),
                    keyframes = [
                        #slide GC logo up
                        animation.Keyframe(
                            percentage = 0,
                            transforms = [animation.Translate(0, 64)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            percentage = 0.1,
                            transforms = [animation.Translate(0, 64)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            percentage = 0.20,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

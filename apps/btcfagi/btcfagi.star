"""
Applet: BtcFagi
Summary: BTC Fear And Greed Index
Description: Shows the Fear And Greed Index for Bitcoin.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

BACKGROUND = base64.decode("""
R0lGODlhPAABAMQAAMCoE71VE7s4E8CzE7q5FbsoE8CEE8B3E5S3IYuzJGukLp25HrsbFsCcE7tIE7S5F625GaW5HFycM1aZNb9iE3qrKcCQE3GnLHWpKn6uJ2SgMFGXNsBsE4OwJmGeMb+4EyH5BAAAAAAALAAAAAA8AAEAAAUuICMWpGA6ThBQFHcchmFZTQPcw/DtBPE8EEgkslggEIlEJ1PBXBQKjUcimUw2IQA7
""")

def get_data(url, ttl_seconds = 60 * 60 * 6):
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Alternative.me API request failed with status %d @ %s", response.status_code, url)
    return response.json()["data"][0]

def get_text_color(index_value):
    text_color = "#fff"
    if index_value < 25:
        text_color = "#bb2313"
    if index_value >= 25 and index_value < 50:
        text_color = "#c0b713"
    if index_value >= 50 and index_value < 75:
        text_color = "#9ab91f"
    if index_value >= 75:
        text_color = "#519736"
    return text_color

def main():
    data = get_data("https://api.alternative.me/fng/")

    value = int(data["value"])
    classification = data["value_classification"]
    text_color = get_text_color(value)

    return render.Root(
        delay = 15,
        max_age = 60 * 60 * 6,
        child = render.Stack(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(
                                content = "Fear & Greed",
                                font = "tom-thumb",
                            ),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (2, 12, 2, 2),
                    child = render.Image(
                        src = BACKGROUND,
                        width = 60,
                        height = 5,
                    ),
                ),
                render.Padding(
                    pad = (2, 11, 2, 2),
                    child = animation.Transformation(
                        child = render.Box(
                            width = 1,
                            height = 7,
                            color = "#fff",
                        ),
                        duration = 1500,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.001,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 18, 0, 0),
                            child = render.Text(
                                content = classification,
                                color = text_color,
                                font = "6x13",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

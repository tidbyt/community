"""
Applet: Noderunners
Summary: Current song at Noderunners
Description: Shows the current song what is playing on Noderunners Radio.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

BACKGROUND_IMAGE = base64.decode("""
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
""")

def get_current_song(ttl_seconds = 30):
    url = "https://radio.noderunners.org/assets/api.php"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code == 200:
        return response.json()["title"]
    return "OFFLINE"

def metronome():
    return animation.Transformation(
        child = render.Box(
            width = 38,
            height = 22,
            child = render.Column(
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(width = 1, height = 16, color = "#fff"),
                    render.Circle(diameter = 4, color = "#fc6a03"),
                ],
            ),
        ),
        duration = 100,
        delay = 0,
        origin = animation.Origin(0.5, 0),
        direction = "alternate",
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Rotate(-55), animation.Rotate(0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 0.5,
                transforms = [animation.Rotate(0), animation.Rotate(55)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Rotate(-55), animation.Rotate(0)],
                curve = "ease_in_out",
            ),
        ],
    )

def tick_tock_next_block():
    color = "#fff"
    font = "Dina_r400-6"

    text_empty = [render.Text(content = "", color = color, font = font)] * 12
    text_tick = [render.Text(content = "TICK", color = color, font = font)] * 13
    text_tock = [render.Text(content = "TOCK", color = color, font = font)] * 13
    text_next = [render.Text(content = "NEXT", color = color, font = font)] * 13
    text_block = [render.Text(content = "BLOCK", color = color, font = font)] * 13

    return render.Animation(
        children = text_tick + text_empty + text_tock + text_empty + text_next + text_empty + text_block + text_empty,
    )

def now_playing(song):
    return render.Box(
        color = "#0008",
        width = 64,
        height = 9,
        child = render.Marquee(
            align = "center",
            width = 64,
            height = 10,
            child = render.Text(
                content = song,
                color = "#fff",
                font = "tb-8",
            ),
        ),
    )

def main():
    song = get_current_song()

    return render.Root(
        show_full_animation = True,
        max_age = 30,
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND_IMAGE,
                    width = 64,
                    height = 32,
                ),
                render.Stack(
                    children = [
                        render.Padding(
                            pad = (29, 6, 0, 0),
                            child = tick_tock_next_block(),
                        ),
                        render.Padding(
                            pad = (22, 0, 0, 0),
                            child = metronome(),
                        ),
                        render.Padding(
                            pad = (0, 23, 0, 0),
                            child = now_playing(song),
                        ),
                    ],
                ),
            ],
        ),
    )

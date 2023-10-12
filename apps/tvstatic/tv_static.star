"""
Applet: TV Static
Summary: Show static on an old TV
Description: Make your Tidbyt look like it is showing static on an old TV that is turned to Channel 3.
Author: Snuckey
"""

load("random.star", "random")
load("render.star", "render")

STATIC_DIM = 2
STATIC_FRAME_COUNT = 100

def main():
    return render.Root(
        child = render.Stack(
            children = [
                render.Animation(
                    children = staticFrames(),
                ),
                render.Row(
                    children = [
                        render.Text(content = "03", color = "#00ff00", font = "10x20"),
                    ],
                    main_align = "end",
                    expanded = True,
                ),
            ],
        ),
    )

def staticFrames():
    frames = []
    for _ in range(STATIC_FRAME_COUNT):
        frames.append(staticScreen())
    return frames

def staticScreen():
    static = []

    for _ in range(int(32 / STATIC_DIM)):
        static.append(render.Row(children = staticRow()))

    return render.Column(children = static)

def staticRow():
    static = []
    color = ""

    for _ in range(int(64 / STATIC_DIM)):
        num = random.number(0, 2)

        if num == 0:
            color = "#000000"
        else:
            color = "#ffffff"

        static.append(render.Box(width = STATIC_DIM, height = STATIC_DIM, color = color))

    return static

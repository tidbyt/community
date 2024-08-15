"""
Applet: Unix Epoch Clock
Summary: Seconds from the Unix epoch
Description: A clock showing seconds from the Unix epoch.
Author: paultyng
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main():
    now = time.now()
    unix = now.unix

    time_frames = []
    for x in range(20):
        time_frame = render.Text(
            content = str(unix + x),
            font = "6x13",
            color = "#E01E5A",
        )
        time_frames.append(time_frame)

    return render.Root(
        delay = 1000,
        max_age = 120,
        child = render.Box(
            child = render.Animation(children = time_frames),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )

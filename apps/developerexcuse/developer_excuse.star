"""
Applet: Developer Excuse
Summary: Developer Excuse
Description: Developer Excuse app generates playful and imaginative excuses to bring a smile to developers facing coding hiccups and bugs.
Author: masonwongcs
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

EXCUSE_URL = "https://excuser-three.vercel.app/v1/excuse/developers/"


def main(config):
    rep = http.get(EXCUSE_URL)
    if rep.status_code != 200:
        fail("Excuse request failed with status %d", rep.status_code)

    excuse = rep.json()[0]["excuse"]

    return render.Root(
        child=render.Box(
            render.Row(
                expanded=True,
                main_align="space_evenly",
                cross_align="cebter",
                children=[
                    render.Marquee(
                        width=64,
                        child=render.Text(excuse),
                    )
                ],
            )
        )
    )


def get_schema():
    return schema.Schema(
        version="1",
        fields=[],
    )

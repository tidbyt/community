"""
Applet: Binary Clock
Summary: Shows a binary clock
Description: This app show the current date and time in a binary format.
Author: LukiLeu
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    return render.Root(
        child = render.Box(height = 1, width = 1),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
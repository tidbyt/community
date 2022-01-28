"""
Applet: NYC Bus
Summary: NYC Bus departures
Description: Realtime bus departures for your preferred stop.
Author: samandmoore
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
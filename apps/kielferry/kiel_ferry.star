"""
Applet: Kiel Ferry
Summary: Kiel Ferry Departures
Description: Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.
Author: hloeding
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
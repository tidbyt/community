"""
Applet: Bay Wheels
Summary: Bay Wheels availability
Description: Shows the availability of bikes and e-bikes at a Bay Wheels station.
Author: Martin Strauss
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
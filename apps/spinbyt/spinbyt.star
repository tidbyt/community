"""
Applet: Spinbyt
Summary: Shows Spin scooters info
Description: App that shows the nearest Spin scooter, its battery level, and number of other nearby scooters. Includes a scooter icon.
Author: zachlucas
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

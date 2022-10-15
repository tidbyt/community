"""
Applet: AirThings
Summary: Environment sensor readings
Description: Environment sensor readings from an AirThings sensor.
Author: joshspicer
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
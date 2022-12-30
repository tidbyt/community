"""
Applet: Hass Entity
Summary: Display Hass entity state
Description: Display an externaly accessible Home Assistant entity state or attribute.
Author: InTheDaylight14
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
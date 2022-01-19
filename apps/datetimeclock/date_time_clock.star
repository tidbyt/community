"""
Applet: Date Time Clock
Summary: Shows full time and date
Description: Displays the full date and current time for user.
Author: Alex Miller/AmillionAir
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
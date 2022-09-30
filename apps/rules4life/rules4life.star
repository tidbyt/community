"""
Applet: Rules4Life
Summary: Displays the Rules 4 Life
Description: Displays Jordan B. Peterson's Rules for Life from his book.
Author: Robert Ison
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

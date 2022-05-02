"""
Applet: Step Counter
Summary: Tracks Daily Step Progress
Description: Fetches your Step Data from Google Fit, Reports progress versus daily goal.
Author: Matt-Pesce
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

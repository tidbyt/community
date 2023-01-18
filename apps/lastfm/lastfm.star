"""
Applet: Lastfm
Summary: What are you scrobbling
Description: This app will display whatever track is currently being scrobbled to your Last.fm profile.
Author: mattygroch
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
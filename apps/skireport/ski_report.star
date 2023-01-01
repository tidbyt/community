"""
Applet: Ski Report
Summary: Weather and Trails
Description: Weather and Trail status for Mountains that are part of the Epic Pass resort system.
Author: Colin Morrisseau
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

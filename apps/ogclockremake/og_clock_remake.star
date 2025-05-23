"""
Applet: OG Clock Remake
Summary: OG Clock Remake
Description: A remake of the original Tidbyt Clock App (Reddit initiative).
Author: bendiep
"""

load("render.star", "render")

def main():
    return render.Root(
        child = render.Text("Hello, World!")
    )
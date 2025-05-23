"""
Applet: OG Clock Remake
Summary: OG Clock Remake
Description: A remake of the original Tidbyt Clock App (Reddit initiative).
Author: bendiep
"""

load("encoding/base64.star", "base64")
load("render.star", "render")

PLACEHOLDER_WEATHER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAVFBMVEVHcEwOCgAAAAAAAACFciD/5UgAAAD/4kcAAAAAAAAfGQQAAAAAAAAyKQYJBwEAAAATDwIJBgA8Mwr/40f/2kT92EPmxDzLrTTDpjFvXhf710P71kNJ8ar5AAAAFHRSTlMASkp6uvwJ+2/ohIGGqLECe6uc+nKi/4AAAACcZVhJZk1NACoAAAAIAAYBEgADAAAAAQABAAABGgAFAAAAAQAAAFYBGwAFAAAAAQAAAF4BKAADAAAAAQACAAACEwADAAAAAQABAACHaQAEAAAAAQAAAGYAAAAAAAAAWgAAAAEAAABaAAAAAQAEkAAABwAAAAQwMjMykQEABwAAAAQBAgMAoAAABwAAAAQwMTAwoAEAAwAAAAEAAQAAAAAAABbGwGQAAAB5SURBVBjTZU9HEsQwCJNb3L0p65Lk//8MXG0ODNIgkPADNsQClEgDCO4CCBnIARA7qB0SzqfkHeQheF+eSvcxulanZBWg7masNe1WjGJwul1Prc/VtAsRJftu3j/Va7rP9A5p2MpEtSOxZiYWyXJ0ebsam60v4eb4H0J7CeWxaizWAAAAAElFTkSuQmCC
""")

def main():
    # return render.Root(
    #     child = render.Text("Hello, World!")
    # )

    return render.Root(
        child = render.Row( # Row lays out its children horizontally
                children = [
                    render.Image(src=PLACEHOLDER_WEATHER_ICON),
                    render.Text("Hello, World!")
                ],
        )
    )
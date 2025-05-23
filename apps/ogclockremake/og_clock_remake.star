"""
Applet: OG Clock Remake
Summary: OG Clock Remake
Description: A remake of the original Tidbyt Clock App (Reddit initiative).
Author: bendiep

TODO:
- Get real weather data from API
- Get more weather icons
- Get timezone from location
- Add display location toggle option
- Add 24-hour clock toggle option
- Add display weather toggle option
- Add blinking separator toggle option
- Add temperature units option (Celsius/Fahrenheit)
- Add time color option
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("time.star", "time")

PLACEHOLDER_WEATHER_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAVFBMVEVHcEwOCgAAAAAAAACFciD/5UgAAAD/4kcAAAAAAAAfGQQAAAAAAAAyKQYJBwEAAAATDwIJBgA8Mwr/40f/2kT92EPmxDzLrTTDpjFvXhf710P71kNJ8ar5AAAAFHRSTlMASkp6uvwJ+2/ohIGGqLECe6uc+nKi/4AAAACcZVhJZk1NACoAAAAIAAYBEgADAAAAAQABAAABGgAFAAAAAQAAAFYBGwAFAAAAAQAAAF4BKAADAAAAAQACAAACEwADAAAAAQABAACHaQAEAAAAAQAAAGYAAAAAAAAAWgAAAAEAAABaAAAAAQAEkAAABwAAAAQwMjMykQEABwAAAAQBAgMAoAAABwAAAAQwMTAwoAEAAwAAAAEAAQAAAAAAABbGwGQAAAB5SURBVBjTZU9HEsQwCJNb3L0p65Lk//8MXG0ODNIgkPADNsQClEgDCO4CCBnIARA7qB0SzqfkHeQheF+eSvcxulanZBWg7masNe1WjGJwul1Prc/VtAsRJftu3j/Va7rP9A5p2MpEtSOxZiYWyXJ0ebsam60v4eb4H0J7CeWxaizWAAAAAElFTkSuQmCC
""")

def main():
    # Time
    timezone = "Australia/Melbourne"
    now = time.now().in_location(timezone)

    # Layout
    return render.Root(
        delay = 500,
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # Render Time
                    render.Animation(
                        children = [
                            render.Text(
                                content = now.format("3:04 PM"),
                                font = "6x13",
                            ),
                            render.Text(
                                content = now.format("3 04 PM"),
                                font = "6x13",
                            ),
                        ],
                    ),
                    # Render Weather Placeholder
                    render.Image(src = PLACEHOLDER_WEATHER_ICON),
                ],
            ),
        ),
    )

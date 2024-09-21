"""
Applet: FlyByWire Flights
Summary: FlyByWire Number of Flights
Description: Shows a count of the number of flights using the FlyByWire Simulations systems.
Author: Philippe Dellaert (pdellaert)
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("animation.star", "animation")

FBW_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAeCAYAAABNChwpAAAABmJLR0QA/wD/AP+gvaeTAAACNklEQVRIibWWvW4TQRSFv7k2YEBCJB2ksKkoI/EGFKFzWiRAoqSIUtEgaBCKRAEFj0BJQ8MLpKPxelFcU9vvwI8Phb3O7M7sj9fLkVbyXu/e+831uTN2/A8lusI1XjvjOaYhhuFABmTXSot+58Ul52Z8Bca5sAOy61JTo2P1LniKY4xfMF4cpI4BzjUQnHkVwmd8CGeTTgHsNqc4hqWrL3YA0jDUVjPt2ZKfcuxvjGYCK5jvsuKckR101gH7wxtgv3L1/nLFFPyB2EWphhgn+WKR3z9H7LoDMHGGGAQlKyeABGD3fSDVIfCkrOWKmw8ghQ464JZ8CPPUjB/MGbnFzgD9RI+c46jWeGH7p9nH9gCSLeF9ljxmuVIbrg24E0Av4RnwAKhffYkB2wOcayDHu3ihmvFbKd0JwG5xCgyz+1zJ+u13Y8B2ADPtIV6VFvPHLybPgK0A7Nd6yy3JnlOsA54BtwdINQROcsm3Md+KMfFvtwKwv5wBgw0AW47fSql/0/w4TnVoS1Iy6PXxmjtqY8dvXnNGduAHGncgt+VG29xg/AoGbAzQm+jYwVGYL6MruYJqrgXAd12X41MuVjV+VbkKBmwEYFf5CNyrfsorW9kBfhRDlSbsTfVY4kvwRmBAhbEw84KR3Q2ZStRP9FDic9n3W49fpP2lAL2JjpfwjWzmfbXdgFAai+b/kiW6YeKtHC+jcNECjU4/MAsmYAVwoZv85r45xogXOO7U5VIRpnb1gAv3AIB/ckOaE1gXKjEAAAAASUVORK5CYII=")
FBW_COUNT_API = "https://api.flybywiresim.com/txcxn/_count"

def getCount():
    response = http.get(FBW_COUNT_API, ttl_seconds = 60)
    if response.status_code == 200:
        return response.body()
    else:
        print("Failed to fetch data from API. Status code:", response.status_code)
        return "N/A"

def main():
    return render.Root(
        child = animation.Transformation(
            child = render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "space_around",
                children = [
                        render.Padding(
                            child = render.Image(
                                src = FBW_ICON,
                                width = 32,
                                height = 30,
                            ),
                            pad = (0, 1, 0, 0),
                        ),
                    render.Text(
                        content = "%s" % getCount(),
                        font = "6x13",
                        color = "#00c2cc",
                    ),
                ],
            ),
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    curve = "ease_in",
                    transforms = [
                        animation.Translate(
                            x = 64,
                            y = 0,
                        )
                    ]
                ),
                animation.Keyframe(
                    percentage = 0.1,
                    transforms = [
                        animation.Translate(
                            x = 0,
                            y = 0,
                        )
                    ],
                ),
                animation.Keyframe(
                    percentage = 0.9,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [
                        animation.Translate(
                            x = -64,
                            y = 0,
                        )
                    ],
                ),
            ],
            origin = animation.Origin(x = 1, y = 0),
            duration = 250,
            delay = 0,
        ),
    )

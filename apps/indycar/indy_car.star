"""
Applet: Indy Car
Summary: Indy Car Race & Standings
Description: Show Indy Car next race info and current driver standings.
Author: jvivona
"""

load("render.star", "render")
load("encoding/base64.star", "base64")

VERSION = 23045

IMAGES = {
    "oval": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAACXBIWXMAAC4jAAAuIwF4pT92AAABiElEQVRIieWWwU5TURCGv0IXBNpEE13AnqUhxH1TNtRH6K57cFF4CPVtYFv0AXRhjLJpom+giQQLizbysbhzwm17ewVC7YI/meRmOjNfc+6ZmVtRWYSWFkJ9lODqLWKeALvAS+AFsAk8Cz/AGfAL+AF8Az4DJ+GfLbXIqmpbfa8OLdbfsCINI7cdtaYYRdBdtZ8rcqEeq6/Vhrqh1nLxtfA1IuYocpL6UbMU/Fa9ioRTtaOuzDiVMluJ3NOodRW1C8FvIuhSPVSX7wGctCX1IGoajDFwK3esOw8AnLSd3PG38uCTcO7PAZpsLxg9lYrZyPwDrAJ14PIu/XgHrQHnUb/+PwfI2FJI4E/x3JkjuBOMj9nfmL5czTm83+asy5V62Lj63WiFh2inrjft9C79Nhm4kAGS7JXjI3NgNgbTyFx3emSuOz4yB7n8fjref4HxZkl8UEcWq2xJjCJ35pJIfVymp0AL2Aa2yNbic7Keh2wG/AS+A1+BL0AP+F1W9DbguejxffosDHwNqbxbDFlMpXoAAAAASUVORK5CYII=",
    "road": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAACXBIWXMAAC4jAAAuIwF4pT92AAABnUlEQVRIieXWv2sUQRjG8c/pqWlSWBoEg42kCFrYWNmI2GmhsTIgtgEjaqU2CoIW/qqsAhYWkliksPAvsFMrEQSFU2yNkBAtdCzuVpa9d25vL8IVPrA7y/O+M999d2Z2t5VSMg5tGwsV7V57B0fwHRNION5wrJuYwi6s4wPuZbNTSlJKz1O/bvdidcdS0LfQu5TS1ahfUfHv4J5+DlHlWxwcEJ/BXcxivhzYyhy/qYGWdQ5P/gV4CYca9pnHwlbB5zP+Y9zAi0z8ZHHRziQM0q3A62BfxbuPxYp3rLgYpeLpwHuG3RXvEl4HuVdGBe8MvA6+Bf7nwJssg1tBQu5d+ivwJjK5UWEpFyi0mfF/BF5urWyvA0cvkD365w32B17uJrMqwF+D2Fn983YZR4Pch03BxSNaxMVKbAqf8BRfcBgXgjFeNYWWwbCC05X4NK7VjLEyCri8uM7oVthEqwZ9+oYEEy+cnF7i1CjQCEx3Ty/X9HuEE0OMH22n9t9ToLle+wB7sQMb+IjrQwALdXrte92CDmANWv/dz97YwH8ARhmjTPwdskgAAAAASUVORK5CYII=",
    "street": "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAYCAYAAADtaU2/AAAACXBIWXMAAC4jAAAuIwF4pT92AAABY0lEQVRIie3WsUtWURjH8Y+lmYomWJYNQoqCQ9Qg0haE/4yOgkO7k9GQk0GTBQ4uDU4ObkFD0CLUECIvRTQ0aCmI0ONwz4Xr2/WVq+Tb8P7gcJ/zPOfcL+e595zztEWEZuhKU6ingJ8gsNRg3h3cxhSO0vi3VcDtJb6r6Xm9JHYPXVhP9iFqGEH3ecHdGMeD1B/CfXxPsEEsY1K2wo/4gBfYqgIFEZG3iSjXYkS8LvQ3I2IlIgbq5m0U3nVmK0v1V7zENB5jPvk38AXPsFN5hXUqA3/CAn4kcK5XWKsb24nZZI9iDn24iVW8qwKuoluYSfYInhditUbg/2oft8Dn1VNsy771LzwsBi/6czVSf2q5rhWDl5nqsWaB32CiGeATaoFb4H+mtlRlvpdVHMPYx2fcTb5c3/ATHakfyT6xP89QTVbRPMrBu7J7dFd2wnTJirgDWVb+oMffJ13gdwVwL/Zw4xji9Z/+bRF76AAAAABJRU5ErkJggg==",
}

DEFAULT_WHO = "world"

def main(config):
    return render.Root(
            child = render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("Next Race: "),
                        offset_start = 5,
                        offset_end = 5,
                    ),
                    render.Box(width = 64, height = 1, color = "#a0a"),
                    render.Image(src = base64.decode(IMAGES["oval"]), height = 24, width = 30),
                ]
            )
    )

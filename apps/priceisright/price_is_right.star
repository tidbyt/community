"""
Applet: Price Is Right
Summary: Turn the display into a bid
Description: Use the display to show a contestant bid screen like on the show, for use as a standalone display or part of a costume.
Author: Blkhwks19
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    amount = "%s" % config.str("bid_amount", "799")
    bg = "%s" % config.str("bg_color", "#FF0000")
    row = ""

    if len(amount) == 0:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                # nothing
            ],
        )
    elif len(amount) == 1:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Box(width = 2, height = 32, color = bg),
            ],
        )
    elif len(amount) == 2:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Box(width = 2, height = 32, color = bg),
                render.Image(src = getImg(amount[1])),
                render.Box(width = 2, height = 32, color = bg),
            ],
        )
    elif len(amount) == 3:
        row = render.Row(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Image(src = getImg(amount[1])),
                render.Image(src = getImg(amount[2])),
            ],
        )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(width = 64, height = 32, color = bg),
                render.Column(
                    expanded = True,
                    children = [
                        render.Box(width = 64, height = 1, color = bg),
                        row,
                    ],
                ),
            ],
        ),
    )

def getImg(num):
    if num == "0":
        return ZERO
    if num == "1":
        return ONE
    if num == "2":
        return TWO
    if num == "3":
        return THREE
    if num == "4":
        return FOUR
    if num == "5":
        return FIVE
    if num == "6":
        return SIX
    if num == "7":
        return SEVEN
    if num == "8":
        return EIGHT
    if num == "9":
        return NINE
    return 0

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bid_amount",
                name = "Bid amount",
                desc = "0 - 9999",
                icon = "dollarSign",
                default = "799",
            ),
            schema.Color(
                id = "bg_color",
                name = "Background Color",
                desc = "Background color",
                icon = "palette",
                default = "#FF0000",
                palette = [
                    "#FF0000",  #red
                    "#00FF00",  #green
                    "#0000FF",  #blue
                    "#FFFF00",  #yellow
                    "#FFAA00",  #orange
                    "#00AAFF",  #light blue
                ],
            ),
        ],
    )

ZERO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAAQElEQVRIS2P8DwQMVACMg9sgRiAgxZfIvkHx2qhB8GAcDSPCKWo0jEbDCBoCo8UI9qQwmkUoyCKEteJWMfiqbADcT9enuIINwgAAAABJRU5ErkJggg==
""")

ONE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAANElEQVRIS2NkoAD8BwKYdkYKzGEYNYhw6I2G0WgYQUNgNK9hTwqjWWQ0i4xmEbxpYHBnEQDNTHenh8ys/AAAAABJRU5ErkJggg==
""")

TWO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAAS0lEQVRIS2P8DwQMVACMg88gSnyF7BvGUYOwhsBoGBFOGLQJo8GX12jiIkYgIBzE2FWglEejBmENpNEwIpy6BnkYEfYAbhWDr8oGAOoXd9O0Tlr5AAAAAElFTkSuQmCC
""")

THREE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAAS0lEQVRIS2P8DwQMVACMg88gSnyF7BvGUYOwhsBoGBFOGLQPI0ryHUrKHnwGEQ5eVBW0D+xRF8FDYDSwCScG2oQRJRkV2c2Dr8oGAKXkd6efGhJ/AAAAAElFTkSuQmCC
""")

FOUR = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAATklEQVRIS2NkoAD8BwKYdkYKzGGgjUEopjIykuRCFL2jBmGN3NEwIpzmaR9GhN2AWwUjsvMGh0GUuII2xcioiwjn/tEwGg0jMtMAcqYFAOfJn6e+YkLoAAAAAElFTkSuQmCC
""")

FIVE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAATElEQVRIS2P8DwQMVACMg9sgRiAg15coXhs1CGswjoYR4dQ1yMOIsAdwqxiEuZ8S7yCXZWQXGyAHjBpEOBpGw4jEMBrcNS1hz+BWAQCNQnfT4wjjHAAAAABJRU5ErkJggg==
""")

SIX = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAARElEQVRIS2P8DwQMVACMg9sgRiAg15coXhs1CGswjoYR4dQ1yMOIsAdwqxhmuR+5LKMo1kYNIpyqRsOIgjAirHUoZVoAIRGf0wyfapkAAAAASUVORK5CYII=
""")

SEVEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAAN0lEQVRIS2P8DwQMVACMg88gSnyF7BvGUYOwhsBoGBFOGKNhNBpG0BAYLUawJ4XRLDKaRaAhAACaqXenRsActAAAAABJRU5ErkJggg==
""")

EIGHT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAASUlEQVRIS2P8DwQMVACMg9sgRiAgxZfIvkHx2qhB8GAcDSPCKYr2YUTYDbhVjGZa7GFD+1gbLUZGixESci7OBEmCGRhKB1/uBwAFEsunJkN49QAAAABJRU5ErkJggg==
""")

NINE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABIAAAAeCAYAAAAhDE4sAAAAS0lEQVRIS2P8DwQMVACMg9sgRiAgxZfIvkHx2qhB8GAcDSPCKYr2YUTYDbhVDMJMS4l3UAJ71CCsITAaRoQTxiAPo8Fd0xIOXtwqAIKDn6eMkxGXAAAAAElFTkSuQmCC
""")

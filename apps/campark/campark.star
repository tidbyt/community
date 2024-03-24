"""
Applet: CamPark
Summary: Cambridge Car Park Spaces
Description: Real Time spaces in Cambridge UK Car Parks
Author: derekllaw

Uses Smart Cambridge parking API
"""

# V1.0 - single page, horizontal scrolling
# V2.0 - vertical scrolling with logo

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("secret.star", "secret")

# constants
LOGO_GIF = base64.decode("""
R0lGODlhQAAgAHAAACwAAAAAQAAgAIcAAAAAAAEAAgUBBw4AAQEDGScUUncfcJ8lgLUniMApi8Uoi
sMqjskpjsgoiMEfcaAUUXUCFiQfcqIrkcwmhb0XWoIRR2cGJzofb50zqu80q/IypekaYYsWV30dbJ
opjMYslNEgc6MfcaEFJTg2sfk4uP83tf4OP1srks8gcaEBAQEFJDcCFSEFITMaYYoebZsQRWQ5u/8
EHi4FIzY1rvUmg7k2sfoebp0RSGczqe8CAgImgrg0rfQhd6kslNAkfbICEyAzqe0LNk8woOE2s/0B
ChIjeq40q/EhdaYxouUtltMpi8Qnhr4tl9UpjccsldIid6kBDRcPQV4ILEEILkQGKDsHK0AHLEIJM
UkPQ2EOQF0MOlQILUMieKsZX4csk9ASSmsCDxobY44vnd0EHzATTXAWWH4TTnEZX4gVUXUPQl8FIj
QcZ5MMO1cdbJkvnd40rPMumdkumtk3tP0tmdg2svstmNYvnt4daZYwoeMjfLAxpOc1sPgumtoypus
BBgwBBAYbZZAwoeQmg7okfrMieawgc6QcaJUda5ghdaUbZI41r/Y2s/w3tP4oicIVVHgJMkoMOVQN
PlsPRGMRSWkTT3ISTG47wf8vn+ARRmQqkMojfK8qj8oYXIMAAQIDAwMFBQUEBAQQEBCqqqrFxcW2t
rZRUVF8fHy/v78eHh66urq5ublfX1/Nzc2Hh4esrKzBwcF5eXmwsLCXl5dra2vHx8etra0zMzOZmZ
l1dXUWFhaysrI2NjaVlZW7u7vZ2dl/f3+0tLTl5eWrq6tkZGSpqaljY2PR0dFWVlbPz8/Ly8sODg4
/Pz88PDyenp6IiIi9vb1vb2+Kioqmpqa3t7eampqurq6goKC+vr7T09PIyMhtbW05OTkJCQlBQUHX
19fb29snJyePj49YWFjKysrCwsIhISGioqJbW1uSkpJSUlJ6enrQ0NBJSUkcHBwKCgpKSkqkpKRmZ
maEhIQHBwcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAI/wABCBxIsKDBgwgTKlzIsK
HDhxAjSpxIkWAAgwIGHLxYsSMAAgILGDiAIIGCBQwaKHCA4AGECAJBeqwoYQKFAxUsXMCQQcMGDh0
8fAARYqZEjgBEUBhBkAOJEiYOgDyxIQOKFCoEIjW6cAWLCS0+gnTx1MQLgTAyxEggg4GMGVwdhqCR
ooaKrAA42IB64yOOHDEcqNCxQwSPHnEXqnihwccPAEAAQAhCgsYLkEKGEHEAoAgAIz6OiEicUCaSJ
EqWfFCAQokSH0wSJJjQBIRqJ0ueJIEiEC9pgiqiQDkgRcUUKlWsXMEiREoWLVuwXOFShcsUACcwdI
n82yAML0u+IP8BwwJAVhUgL94dGAZMCNtecHQHnlXMhDEMppDRUgaHmTNopOFCGWbgUIYaa1zgxBg
TsDHfQW0MwYQbAEzwBhxxkCDHHHTUYUcdcsBxBwgA4MFEHlo82JsKAbTIhh5ZBLBHEnyMUUcfJshh
QodjkJCEHyqcYAQef6g4kAAAAMJAHIEAUBcKNfSRgCALJEFBHzX4MEgIKnBgBwMsqIBkd+vlRQEhe
hhRiCEiYICBG3jgwcYhiLzwwg0iJFKIET8QQoEiRt7FxCJH8MCHDXUwQsQcjZhAhAlQOTrHHHXYQA
IPRyziyINlAiABlI9AEokkakxCSRmVpFGJJZRMosYJW0D/ksYOKCRipHlZTXAJJmAYxBFenWYyxiU
++PZbmQGYockmWBy0XqdZUbEJJ53cepcALF7kCUIyIYseASoA4pEOBX0iECjPmkcQKAOFAkAo56ng
bgDoAYAuAOQSRK676jIkyiiklGIKQaegkgpeqaiyikCstOLKQK/AokosZcoyC64q0FKLKrbcMhAuq
ICSSym6KGTLLrz08gpBvvwCDEHBCEMLAMMIQ0xMxYxizDEDIZOMMsvgxcwxzazizEDPQIOMKtEopI
syvLQrkCmkSOPLYAJNQ00xAPiCCjJ4VaOMNbusdw0u2MSCayrZFKPNNgPlkkwp3OCbUDfKMCOQN7j
2zvKNKuCEo+4o0qwiTjXUjCOQDtWsQoxv5JRzTNnkmtPKM8lEPVgutWDDSr8InQMNOtPIIlAqx5wC
ACnOrOdLOrh8o04rTQtENkg6qLAOOwCo84spd7XzjTvUXDOQOOWoQ846DIFcjMcqoANNLgCcM8o7A
LhjDS7w4NLOKi8TQEA8xXyCVzrBhNOOLy8DII8vxGxzzuLp7ALAPNaUjJCx+JqbFT0DyZ34CsIuHY
DkLipgV28+AgoFtiuBi8NL7hrSqRUZRCYfAZZvnrVBiQQEADs=""")
SECRET = "AV6+xWcEWfKUGe/P0Ndmq+DM9dPl/v//QNSfFjI+XkhQtHl59qJzWkT0cGkKVCbfpNsZQphvxjuG6jtmPYxsd1qBotcLqc6KaUCUDsUOqmhV1vtnpwel5GDk7EgzpLd+1lh6uHgiHbRCC/Sz0rJe75tqK7rLBW5cZovC8b3JSKaaeYWukYXWrJXp7CCU/A=="
API_BASE = "https://smartcambridge.org/api/v1/parking/"
SCREEN_WIDTH = 64
SCREEN_HEIGHT = 32
GOOD_COLOUR = "#0F0"
BAD_COLOUR = "#F00"
PARK = "car_park"
RIDE = "park_and_ride"

FONTS = ["tom-thumb", "5x8", "Dina_r400-6"]
FONT_SMALL = 0
FONT_LARGE = 1

def render_fixed(n):
    """ Render number in at least 3 characters

    Args:
        n: number

    Returns:
        padded string
    """
    text_num = "%d" % n
    pad = ""
    if len(text_num) == 2:
        pad = " "
    elif len(text_num) == 1:
        pad = "  "
    return (pad + text_num)

def render_row(capacity, free, name, fontsize):
    """ Render row with free spaces in green, or red if less than 10% free

    Args:
        capacity: total spaces
        free: free spaces
        name: text
        fontsize: font index
    """
    free_colour = GOOD_COLOUR if free > (capacity // 10) else BAD_COLOUR
    free_text = render_fixed(free)
    return render.Row(children = [
        render.Text(free_text, color = free_colour, font = FONTS[fontsize]),
        render.Marquee(child = render.Text(name, font = FONTS[fontsize]), width = (SCREEN_WIDTH - len(free_text) * 5)),
    ])

def render_page(capacity, free, name, fontsize):
    """ Render page with free spaces in green, or red if less than 10% free

    Args:
        capacity: total spaces
        free: free spaces
        name: text
        fontsize: font index
    """
    free_colour = GOOD_COLOUR if free > (capacity // 10) else BAD_COLOUR
    free_text = render_fixed(free)
    return render.Column(
        children = [
            render.WrappedText(name, font = FONTS[fontsize], width = SCREEN_WIDTH),
            render.Text(free_text, color = free_colour, font = FONTS[fontsize + 1]),
        ],
    )

def main(config):
    """ Entry point

    Args:
        config: config object

    Returns:
        render root
    """

    # Collect output rows here
    rows = [render.Image(src = LOGO_GIF)]

    api_token = secret.decrypt(SECRET) or config.get("api_token")

    # check for missing api_token
    if not api_token:
        rows.append(render.Text("No key found", color = BAD_COLOUR))
    else:
        headers = {"Authorization": "Token %s" % api_token}

        # fetch list of parking ids
        response = http.get(API_BASE, headers = headers, ttl_seconds = 60 * 60 * 24)  # this list is unlikely to change
        if response.status_code != 200:
            rows.append(render.Text("API error %d" % response.status_code), color = BAD_COLOUR)
        else:
            park_list = response.json()["parking_list"]
            count = {PARK: 0, RIDE: 0}

            for park in park_list:
                count[park["parking_type"]] += 1

            for parking_type in [PARK, RIDE]:
                fontsize = FONT_LARGE if count[parking_type] <= 5 else FONT_SMALL
                for park in park_list:
                    if park["parking_type"] == parking_type:
                        api_latest = "{}/latest/{}/".format(API_BASE, park["parking_id"])

                        response = http.get(api_latest, headers = headers, ttl_seconds = 60 * 15)  # 15 minutes between updates
                        if response.status_code != 200:
                            rows.append(render.Text("API error %d" % response.status_code))
                        else:
                            data = response.json()
                            rows.append(render_page(data["spaces_capacity"], data["spaces_free"], park["parking_name"].title(), fontsize))

    return render.Root(
        show_full_animation = True,
        child = render.Marquee(
            child = render.Column(children = rows),
            height = SCREEN_HEIGHT,
            scroll_direction = "vertical",
        ),
    )

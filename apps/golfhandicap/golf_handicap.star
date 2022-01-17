"""
Applet: Golf Handicap
Summary: Displays your golf handicap
Description: Displays your golf handicap using data from GHIN. Includes low/high and cap information.
Author: Chris Jones (IPv6Freely)
"""


load("render.star", "render")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("schema.star", "schema")

USGA_LOGO = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABsAAAAICAYAAAAIloRgAAAACXBIWXMAAAsTAAALEwEAmpwYAAAB
xElEQVQokV3STUiUYRAH8N/upmbQh0luZqWCiAWp0AexdQg8GCVReavrWtA1sqRjt7x1CeKl7kEU
RUTQB3RYEgQ1gjoUqyTGG0gtVOLHth3eZ2lpLjPPMM//P/+ZSU119M5KbLS/OHMfpjv7ZlHBHrzG
gfD+hJHB1oMLuI7jaMUPvMO5uBB9zebyVzEWcHfEheg3rEN7SG7wz6q5eTTjFn7iyHhrTyOmsSkQ
PMVWdCPO5vJpXMTmgLEXk1WyJTRiuYZsBfWBCG7jS39x5teLXH4yEJ3A87gQ/an5J5vLD6ATb3EY
j7K5/K64EFXSAVgg9V/8ocbPv+w5dLNOZX/ILf5PFOxC8CfxEW3YWFVWtbqaeH3wRzEaAJqal5ev
DFVKHqa2wLagJINFPAt1pxFjFXPowT0Mp1EOwPtgurOvCw1B3Up/ceZaGEsRdpaXVkP9KYgLURkp
HMOIZPxZTGGgWpvN5benpjp6uySLzuCVZKG7MYhxlLCAs8g8aGmvv5NpWQsgT/AelwNJdf9NkoNq
C02m0J0Oki/hm+SUGzCENzgfVJ3BZ7TdmHhcxjAmJEcyFhot4XtQVIoL0VpciOYk1zqHu38BakGH
6Fy+5J0AAAAASUVORK5CYII=
""")

GHIN_NUMBER_DEFAULT = "11183158"
LAST_NAME_DEFAULT = "Jones"
GHIN_URL = "https://api2.ghin.com/api/v1/public/login.json?ghinNumber={}&lastName={}&remember_me=false"


def main(config):

    ghin_number = config.get("ghin_number", GHIN_NUMBER_DEFAULT)
    last_name = config.get("last_name", LAST_NAME_DEFAULT)

    tb8 = config.get("font", "tb-8")
    tomthumb = config.get("font", "tom-thumb")
    hcp_font = config.get("font", "6x13")

    ghin_url = GHIN_URL.format(ghin_number, last_name)
    data = http.get(ghin_url).json()

    first_name = data['golfers'][0]['FirstName']
    last_name = data['golfers'][0]['LastName']
    ghin = data['golfers'][0]['GHINNumber']
    hcp = data['golfers'][0]['Display']
    hi = data['golfers'][0]['HiDisplay']
    lo = data['golfers'][0]['LowHIDisplay']
    cap = ""

    if data['golfers'][0]['SoftCap'] == "true":
        cap = "S"

    if data['golfers'][0]['HardCap'] == "true":
        cap = "H"

    return render.Root(
        child = render.Column(
            children = [
                render.Box(width=64, height=8, color="#163963", child=render.Text(content=first_name.upper() + " " + last_name.upper(), color="#ffffff", font=tb8)),
                render.Box(width=64, height=8, child=render.Text(content="GHIN:" + ghin, color="#ccc", font=tomthumb)),
                render.Box(
                    width=64, 
                    height=5,
                    child=render.Row(
                        children = [
                            render.Box(width=32, height=6, child=render.Text(content="LO:" + lo, color="#ff0000", font=tomthumb)),
                            render.Box(width=32, height=6, child=render.Text(content="HI:" + hi, color="#00ff00", font=tomthumb)),
                        ],
                    ),
                ),
                render.Box(
                    width=64,
                    height=11,
                    child=render.Row(
                        children = [
                            render.Box(width=32, height=11, child=render.Image(src=USGA_LOGO, height=9, width=30)),
                            render.Box(width=24, height=11, child=render.Text(content=hcp, color="#fff", font=hcp_font)),
                            render.Box(width=8, height=11, child=render.Text(content=cap, color="#666", font=tb8)),
                        ],
                    ),
                ),
            ],
        ),
    )


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ghin_number",
                name = "GHIN Number",
                desc = "A text entry for your GHIN number.",
                icon = "golfFlagHole",
            ),
            schema.Text(
                id = "last_name",
                name = "Last Name",
                desc = "A text entry for your last name.",
                icon = "user",
            ),            
        ],
    )
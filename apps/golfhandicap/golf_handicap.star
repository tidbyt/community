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

FAIL_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABoAAAAVCAYAAABYHP4bAAAACXBIWXMAAAsTAAALEwEAmpwYAAAC
E0lEQVRIibXV3YtNYRQG8N+7z9n7TMbHIGZGkYgSuTMpSiFRFOXWV1xQigu3/gGllCj5qrkQKfeU
uJAL5aPkAkWJUhhinDB7n+3inGHsOZ05R6za9fbstfaznr2e1hvydyt1GOtxAss6KYo6JFmNQSzF
NUz7X0RL0N84b8Ok/0E0BasK2BYk/5roGHYVsDNY005xuQOieoQx57z9snYVXZHarwszw+8nQs0N
7J3oAxMpKuEctuoL7l3PnDqfmdETxDFHj5RN6UXV8UbTZ/9WUQnbNQb+/EVu8Grm4qXM4JVM9VtO
JVC3+dq/VRSrWzgeBSZ3B7OmB3P6g0pCqYTar0EtwCI871TRPlxGpVWnY2IAN7G8E6LdOF0Eazk/
UkZGGEk1c91cPMSs4ouO7J2mDA/ztUqWkef+tHuLCE2W6kGcHJeZ8Ok9r17n4jJRxML5QbmCbFz2
W2zCo1GgmaLFTVuq0jM76Fkw5m8P1RjRbAB9mD4WKBINqG/o8TEjePm45tadTHd3UIrYvKGkayp+
NK3Yg2d4UySajwvqV8D4SLh9p2bv4RRBV8zLh5G+ORFDTXfRDnzHAaSjRBEeFOUWo3d2sHBe0N8b
JAlJgrTlwttXb9Gu9l33IbdxXeTJ3YrQcFoc43N75WX1a/nQhJkZUUJlGmoNrNo4t7b4TsRlDOMp
7jdKS03TI6T4UsBbk3zHCnz8CXvFekwE5dOLAAAAAElFTkSuQmCC
""")

GHIN_NUMBER_DEFAULT = ""
LAST_NAME_DEFAULT = ""
GHIN_URL = "https://api2.ghin.com/api/v1/public/login.json?ghinNumber={}&lastName={}&remember_me=false"

def main(config):
    """ Main function.
    - Grabs HCP data from GHIN API
    - Ensures data is valid
    - Outputs data to Tidbyt
    """

    # Define Font Variable Names
    tb8 = config.get("font", "tb-8")
    tomthumb = config.get("font", "tom-thumb")
    hcp_font = config.get("font", "6x13")

    # Grab GHIN and Last Name from Schema
    ghin_number = config.get("ghin_number", GHIN_NUMBER_DEFAULT)
    last_name = config.get("last_name", LAST_NAME_DEFAULT)

    if ghin_number == "" and last_name == "":
        first_name = "HAPPY"
        last_name = "GILMORE"
        ghin = "88888888"
        hcp = "88.8"
        hi = "88.8"
        lo = "88.8"
        cap = "H"

    else:
        # Request data from GHIN API
        ghin_url = GHIN_URL.format(ghin_number, last_name)
        resp = http.get(ghin_url)
        data = resp.json()

        # Error Handling
        if resp.status_code != 200:
            if "errors" in data:
                return display_failure("Invalid User")
            else:
                return display_failure("General API Error")

        elif len(data["golfers"]) == 0:
            return display_failure("User Not Found")

        elif len(data["golfers"]) > 1:
            return display_failure("User Not Found")

        # Assign data points to variables
        first_name = data["golfers"][0]["FirstName"]
        last_name = data["golfers"][0]["LastName"]
        ghin = data["golfers"][0]["GHINNumber"]
        hcp = data["golfers"][0]["Display"]
        hi = data["golfers"][0]["HiDisplay"]
        lo = data["golfers"][0]["LowHIDisplay"]
        cap = ""

        # Determine if a soft or hard cap is in place
        if data["golfers"][0]["SoftCap"] == "true":
            cap = "S"

        if data["golfers"][0]["HardCap"] == "true":
            cap = "H"

    # Render Output
    return render.Root(
        child = render.Column(
            children = [
                render.Box(width = 64, height = 8, color = "#163963", child = render.Text(content = first_name.upper() + " " + last_name.upper(), color = "#ffffff", font = tb8)),
                render.Box(width = 64, height = 8, child = render.Text(content = "GHIN:" + ghin, color = "#ccc", font = tomthumb)),
                render.Box(
                    width = 64,
                    height = 5,
                    child = render.Row(
                        children = [
                            render.Box(width = 32, height = 6, child = render.Text(content = "LO:" + lo, color = "#ff0000", font = tomthumb)),
                            render.Box(width = 32, height = 6, child = render.Text(content = "HI:" + hi, color = "#00ff00", font = tomthumb)),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 11,
                    child = render.Row(
                        children = [
                            render.Box(width = 32, height = 11, child = render.Image(src = USGA_LOGO, height = 9, width = 30)),
                            render.Box(width = 24, height = 11, child = render.Text(content = hcp, color = "#fff", font = hcp_font)),
                            render.Box(width = 8, height = 11, child = render.Text(content = cap, color = "#666", font = tb8)),
                        ],
                    ),
                ),
            ],
        ),
    )

def display_failure(msg):
    """ Displays Failure Messages """
    return render.Root(
        child = render.Row(
            children = [
                render.Box(width = 24, height = 32, color = "#000", child = render.Image(src = FAIL_ICON, width = 16, height = 16)),
                render.Box(padding = 2, width = 40, height = 32, child = render.WrappedText(content = msg, color = "#ccc")),
            ],
        ),
    )

def get_schema():
    """ Get Tidbyt Schema Information
    - Valid GHIN or WHS number
    - Last name, case insensitive
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ghin_number",
                name = "GHIN Number",
                desc = "A text entry for your GHIN number.",
                icon = "globeAmericas",
            ),
            schema.Text(
                id = "last_name",
                name = "Last Name",
                desc = "A text entry for your last name.",
                icon = "user",
            ),
        ],
    )

"""
Applet: Company Clock
Summary: Clock from Lethal Company
Description: Displays a rendition of the clock from the game "Lethal Company".
Author: qqvq-d
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

orange = "d6440b"
font = "5x8"

# Image Data
sun = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAB8AAAAgCAYAAADqgqNBAAAA2UlEQVRIS9WWyw3DMAxDk3M36RwZu3N0k55b+CAgcC2TlALIyTGx+UTr4+xb4bMXsrcU/H08vs/XJ6wR3thO7HK4IphdO3TOimbXucfOCqOCnelMc+5tbO976KjwkAFYcGcBg3qgFpB9Q+C2FsLNISOmdgAFZ8FqoBCugpUA1oVHXbPuQ62GeluC932rtMssEDs5T7/euRd9ac7VoXE2wQS+bquxVdunjXG9/mwvu9XK7nM2b2jayX8yLDi77q/VWEF1Box0YZ8zsxsdvff9vvCoY9uXcn5r+A/fc/ghrzk7MQAAAABJRU5ErkJggg==""")
half_sun = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAB8AAAAZCAYAAADJ9/UkAAAAs0lEQVRIS+2UQQ6AIAwE5exPfIfP9h3+xLOmB0zTALsUEjTBo7Y77JYaloFPGMhe/gs/9/XejsttwN0o4+oOrxFsrU06Z0Vb67Kxs8JoW0o6xZmXGuVbBOcuHTIAL5wViFANzL1DmwDh0V0KYCNnanQPBUfxpQ6BXEsPhNeCdVLoAN+Fe12z7t2rhvab+f2+cL230ijzsu8YoK1J6cS7AGfuAbI9E84m1bVuxt41TlZsaOwP4p2AGhTy6mIAAAAASUVORK5CYII=""")
moon = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAB8AAAAgCAYAAADqgqNBAAAA6UlEQVRIS+2WSw6DMAxEYc1NOEeP3XNwk66LItVSMP6M3SSwgA0SOHmesXGYpwuv+UL29MBh97fX8uXB6/uTchBaVANrUHmeBRcBLlwD/At24T3BJrw3WIVblrawmxpWrPkI1aLyUarvBffq6b2HJ9Uv8FBzZHMkhidBQ4oPpDC8bBxJgGKlNSk4mkANbAqnBMqd2ynZ3BxOteUnnXTYdIN7Xa71yGnCRZrJg9bOSG50h1tiQrMdVeopTh0sQ+DWZ4QmgPRO+jdKS0IbpVK8C0ddiEDNmnuqpPeZv1hIOVrnaNwDjzrWJH4HXvrYIZUXqT4AAAAASUVORK5CYII=""")
skull = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAB8AAAAgCAYAAADqgqNBAAABF0lEQVRIS+2Wyw3DQAhE7XM6SR0uO3WkE59jcUBCBJgBR3IixUezy2OG/a3Lhd96IXv5Hfhzu70qp+6PvSWGGmyhGYAZ4wuHcE3KquqML+GdRFYVOy+FSwJWbbYOUI4QzlaOtinKk8LPqtbCKvXfBUdWIat9vMr3ptzbFB0sviV+jI234VK9Joh6Zv9N4uoO1fNKmSRCyrPFS8E7fY7a1oZb6yM4OkCsIy24Tqz2OrMrUIHj45W5xT4GR4kmrSmVoy1XAZm2wCtV+u4TVStaY4xTLXik1Bancf2HLicKbm8otOerk7H1jMr6lllqLUfnhMSpNxyyL7rJmDkQzhw4/v3GgCnlnX4zVttCKeVokU3jf/jUuVPzDvGEIDCT7colAAAAAElFTkSuQmCC""")

# To manually set the time
debug = False

def main(config):
    timezone = config.get("location")["timezone"] if config.get("location") != None else "America/New_York"
    now = time.now().in_location(timezone)

    if debug == True:
        now = time.parse_time("2021-03-22T22:00:50.52Z")

    tp_adj = 0

    if now.hour >= 6 and now.hour < 12:
        img_src = sun
    elif now.hour >= 12 and now.hour < 18:
        img_src = half_sun
        tp_adj = 5
    elif now.hour >= 18 and now.hour < 22:
        img_src = moon
    else:
        img_src = skull

    return render.Root(
        delay = 500,
        child = render.Stack(
            children = [
                # Border
                render.Plot(
                    data = [(0, 0), (0, 32), (64, 32), (64, 0), (0, 0)],
                    color = orange,
                    width = 64,
                    height = 32,
                ),
                # Time
                render.Padding(
                    pad = (4, 8, 0, 0),
                    child = render.Animation(
                        children = [
                            render.Text(
                                content = now.format("3:04"),
                                color = orange,
                                font = font,
                            ),
                            render.Text(
                                content = now.format("3 04"),
                                color = orange,
                                font = font,
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (4, 16, 0, 0),
                    child = render.Text(
                        content = now.format("PM"),
                        color = orange,
                        font = font,
                    ),
                ),
                # Image
                render.Padding(
                    pad = (33, tp_adj, 0, 0),
                    child = render.Image(
                        src = img_src,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone to display",
                icon = "clock",
            ),
        ],
    )

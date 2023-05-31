"""
Applet: LibreNMS Devices
Summary: LibreNMS Device Summary
Description: Displays a LibreNMS device availability map.
Author: @jtinel
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ENDPOINT_DEVICES = "/api/v0/devices"
MARQUEE_SCROLL_SPEED = 100
BOX_SIZE = 4

RED = "F92323"
GREEN = "#2AF923"
ORANGE = "#FFA31A"
WHITE = "#FFFFFF"
BLACK = "000000"

LIBRENMS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAiklEQVQoU42SQRLAEAxF6wws
a6dXcWhXqZ0u6wwpHTFEaG1MIn+en0Rsk3PrA1Q4BffMJu/dgLq8iNqADH6oGRIxEWRDsNaC
c66r64KYCDITyo0CKqwiLEQPtLCNX9EXgRLrV5Dwh8iSZp6QOPW0Ii67R4loYZxTaffMY86z
G0G7SVeJFbVj4HbvAYKAnd83qTc7AAAAAElFTkSuQmCC
""")

# Define the configuration schema
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "librenms_url",
                name = "LibreNMS URL:",
                desc = "URL of the LibreNMS server. Include the protocol and [optionally] port, e.g. https://my.nms, or https://my.nms:8443. TLS connections must use a publicly trusted TLS certificate such as LetsEncrypt, Digicert, etc.",
                icon = "globe",
            ),
            schema.Text(
                id = "api_key",
                name = "LibreNMS API Key:",
                desc = "API Key for the LibreNMS server. Create/manage keys from the LibreNMS web interface at Home -> Settings -> API Settings",
                icon = "key",
            ),
        ],
    )

# Print the logo and header text
def render_header():
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = LIBRENMS_ICON),
            render.WrappedText(
                content = "DEVICE STATUS",
                font = "5x8",
                align = "center",
            ),
        ],
    )

# Display an error message using render.Marquee.
def render_error(error_msg):
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render_header(),
                    render.Marquee(
                        width = 64,
                        offset_start = 64,
                        offset_end = 64,
                        align = "center",
                        child = render.Text(
                            content = error_msg,
                        ),
                    ),
                ],
            ),
        ),
    )

# Render a one pixel line
def render_line(color):
    return render.Box(
        width = 64,
        height = 1,
        color = color,
    )

# Render a single box representing a device's status
def render_box(color, size = BOX_SIZE):
    colors = {"green": GREEN, "red": RED, "orange": ORANGE}
    return render.Box(
        height = size,
        width = size,
        color = colors[color],
    )

# Render rows of up/down data by querying LibreNMS server for device status
def render_rows(devices):
    boxes = list()
    children = list()

    for device in devices:
        # Device is currently offline
        if device["status"] == 0:
            # See if the "Ignore Alerts" flag is set
            if device["ignore"] == 1:
                # Device is offline but set to ignore alerts, mark as green
                boxes.append(render_box("green"))

            else:
                # Device is offline and not set to ignore alerts, mark as red
                boxes.append(render_box("red"))

        else:
            # Device is up, and uptime information is present in device record
            if device["uptime"] != None:
                # Check if the device has been up for more than 24 hours
                if int(device["uptime"]) < 86400:
                    # Uptime is less than 24 hours, mark as orange
                    boxes.append(render_box("orange"))

                else:
                    # Device uptime is more than 24 hours, mark as green
                    boxes.append(render_box("green"))

            else:
                # Device has no uptime data but is up - mark as green
                boxes.append(render_box("green"))

        boxes.append(
            render.Box(
                height = BOX_SIZE,
                width = 1,
                color = "#000000",
            ),
        )

    # Split the list into chunks
    rows = [boxes[x:x + 23] for x in range(0, len(boxes), 23)]

    for row in rows:
        r = render.Row(
            children = row,
            expanded = False,
            main_align = "center",
        )
        children.append(r)

        padding_row = render.Row(
            children = [
                render_line(BLACK),
            ],
        )
        children.append(padding_row)

    return children

def main(config):
    children = list()

    librenms_url = config.str("librenms_url") or ""
    if librenms_url == "":
        return render_error("LibreNMS URL invalid - check config")

    api_key = config.str("api_key") or ""
    if api_key == "":
        return render_error("LibreNMS API key not specified - check config")
    headers = {"X-Auth-Token": api_key}

    r = http.get((librenms_url + ENDPOINT_DEVICES), headers = headers)
    if r.status_code != 200:
        return render_error("Request failed with error {}".format(r.status_code))

    devices = r.json()["devices"]

    children += render_rows(devices)

    return render.Root(
        delay = MARQUEE_SCROLL_SPEED,
        child = render.Column(
            expanded = True,
            children = [
                render_header(),
                render_line(WHITE),
                render_line(BLACK),
                render.Box(
                    width = 64,
                    child = render.Marquee(
                        height = 14,
                        offset_start = 0,
                        offset_end = 0,
                        align = "center",
                        scroll_direction = "vertical",
                        child = render.Column(
                            expanded = False,
                            main_align = "center",
                            cross_align = "center",
                            children = children,
                        ),
                    ),
                ),
            ],
        ),
    )

"""
Applet: LibreNMS Availability Map
Summary: LibreNMS Availability Map
Description: Displays a LibreNMS device availability map.
Author: @jtinel
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ENDPOINT_DEVICES = "/api/v0/devices"
MARQUEE_SCROLL_SPEED = 100
BOX_SIZE = 4
LIBRENMS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAiklEQVQoU42SQRLAEAxF6wws
a6dXcWhXqZ0u6wwpHTFEaG1MIn+en0Rsk3PrA1Q4BffMJu/dgLq8iNqADH6oGRIxEWRDsNaC
c66r64KYCDITyo0CKqwiLEQPtLCNX9EXgRLrV5Dwh8iSZp6QOPW0Ii67R4loYZxTaffMY86z
G0G7SVeJFbVj4HbvAYKAnd83qTc7AAAAAElFTkSuQmCC
""")

colors = {
    "red": "F92323",
    "green": "#2AF923",
    "orange": "#FFA31A",
    "white": "#FFFFFF",
    "black": "000000",
}

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

def print_header():
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

def print_line(color):
    return render.Box(
        width = 64,
        height = 1,
        color = color,
    )

def print_box(color, size = BOX_SIZE):
    return render.Box(
        height = size,
        width = size,
        color = color,
    )

def build_rows(device_info):
    """ Create rows of boxes indicating up/down statuses.

    Args:
        device_info: dict object provided by librenms devices API
    Returns:
        children: a list object containing the rendered rows of boxes
    """
    children = list()

    if "demo" in device_info:
        children.append(
            render.Row(
                children = [
                    render.Text("Demo Mode", font = "tb-8"),
                ],
            ),
        )
        children.append(
            render.Row(
                children = [
                    render.Text("Verify config", font = "tb-8"),
                ],
            ),
        )

    # Iterate through the devices and their statuses. Create a list
    # of boxes, each box indicating a single device's availability status.

    devices = device_info["devices"]
    boxes = list()

    for device in devices:
        # Check if device is currently down
        if device["status"] == 0:
            # Check if ignore_alerts flag is set
            if device["ignore"] == 1:
                # Device offline; ignore alerts is set, mark as green
                boxes.append(print_box(colors["green"]))

            else:
                # Device offline; ignore alerts is NOT set, mark as red
                boxes.append(print_box(colors["red"]))

        else:  # Device is online
            # Check if uptime information is present in device record
            if device["uptime"] != None:
                # Check if device has been up for more than 24 hours
                if int(device["uptime"]) < 86400:
                    # If uptime is less than 24 hours, mark as orange
                    boxes.append(print_box(colors["orange"]))
                else:
                    # Uptime is more than 24 hours, mark as green
                    boxes.append(print_box(colors["green"]))
            else:
                # Device has no uptime data but is up - mark as green
                boxes.append(print_box(colors["green"]))

        # Add a 1px space between boxes
        boxes.append(
            render.Box(
                height = BOX_SIZE,
                width = 1,
                color = colors["black"],
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
                print_line(colors["black"]),
            ],
        )
        children.append(padding_row)

    return children

def get_librenms_devices(config):
    """
    Get a list of devices and their data from the LibreNMS API.

    Args:
        config: A dict containing the LibreNMS URL and API key.
    Returns:
        device_info: A dict, with the 'devices' key containing the devices
        from LibreNMS. If the HTTP request was unsuccessful, instead return
        the HTTP status code and sample device data.
    """

    headers = {"X-Auth-Token": config["api_key"]}
    url = config["librenms_url"] + ENDPOINT_DEVICES
    r = http.get(url, headers = headers)

    if r.status_code != 200:
        return {"error": r.status_code}

    else:
        return {"devices": r.json()["devices"]}

def render_error(error_msg):
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    # Print the libreNMS header
                    print_header(),

                    # Print horizontal divider line
                    print_line(colors["white"]),
                    print_line(colors["black"]),

                    # Print the error message
                    render.Marquee(
                        width = 64,
                        offset_start = 48,
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

def render_output(rows):
    return render.Root(
        delay = MARQUEE_SCROLL_SPEED,
        child = render.Column(
            expanded = True,
            children = [

                # Print the libreNMS header
                print_header(),

                # Print horizontal divider line
                print_line(colors["white"]),
                print_line(colors["black"]),

                # Print the results in a vertical marquee
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
                            children = rows,
                        ),
                    ),
                ),
            ],
        ),
    )

def demo_data():
    """ Creates sample data to be used if config is missing

    Returns:
        a dict with two keys:
            demo: boolean field set to True indicating the data is sample data
            devices: a list of dicts representing the sample device data

    """
    device_list = {}
    device_list["demo"] = True
    device_list["devices"] = []
    for _ in range(1, random.number(15, 40)):
        device_entry = {}
        device_entry["status"] = 1 if random.number(1, 100) > 9 else 0
        device_entry["uptime"] = random.number(86395, 86440)
        device_entry["ignore"] = 0

        device_list["devices"].append(device_entry)

    rows = build_rows(device_list)
    return render_output(rows)

def main(config):
    """ Display a LibreNMS device availability map.

    Args:
        config: The config object provided to main*( at runtime.

    Returns:
        Renders output to the Tidbyt display.

    """
    if "librenms_url" not in config or "api_key" not in config:
        return demo_data()

    # Get the list of device statuses
    devices = get_librenms_devices(config)

    # Display an error if the HTTP request failed
    if "error" in devices:
        return render_error("HTTP error {} - check config".format(devices["error"]))

    # Create the rows to be rendered for output
    rows = build_rows(devices)

    # Render the display output
    return render_output(rows)

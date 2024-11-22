"""
Applet: LibreNMS Alerts
Summary: LibreNMS Alerts
Description: Displays the current count of LibreNMS alerts and a marquee
listing the LibreNMS friendly hostnames of the devices that are alerting.
Author: @jtinel
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ENDPOINT_ALERTS = "/api/v0/alerts"
ENDPOINT_DEVICES = "/api/v0/devices"
FRAME_DELAY_MS = 25
CACHE_TTL_SECONDS = 30
LIBRENMS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAiklEQVQoU42SQRLAEAxF6wws
a6dXcWhXqZ0u6wwpHTFEaG1MIn+en0Rsk3PrA1Q4BffMJu/dgLq8iNqADH6oGRIxEWRDsNaC
c66r64KYCDITyo0CKqwiLEQPtLCNX9EXgRLrV5Dwh8iSZp6QOPW0Ii67R4loYZxTaffMY86z
G0G7SVeJFbVj4HbvAYKAnd83qTc7AAAAAElFTkSuQmCC
""")

colors = {
    "red": "F92323",
    "green": "#2AF923",
    "white": "#FFFFFF",
    "black": "000000",
}

demo_alerting_devices = [
    "demo-srv01",
    "lab-switch02",
    "demo_data-check_config!",
]

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

def get_librenms_alerts(config):
    """ Get a list of alerts from the LibreNMS API

    Args:
        config: The configuration object passed to main()

    Returns:
        A dict containing the alert count and alert data, or if the request
        fails, an 'error' key containing the HTTP status code.

    """
    headers = {"X-Auth-Token": config["api_key"]}
    url = config["librenms_url"] + ENDPOINT_ALERTS
    r = http.get(url, headers = headers, ttl_seconds = CACHE_TTL_SECONDS)

    if r.status_code != 200:
        return {"error": r.status_code}

    else:
        return r.json()

def print_logo():
    return render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Image(src = LIBRENMS_ICON),
        ],
    )

def print_line(color):
    return render.Box(
        width = 64,
        height = 1,
        color = color,
    )

def render_error(error_msg):
    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    print_logo(),
                    print_line(colors["white"]),
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

def build_rows(alert_count, alerting_devices):
    """ Build a list of rows to be added to the body of the output.

    If the alert count is 0, a single row is returned showing 0 alerts.
    If the alert count is > 0, an additional row is included, containing
    a marquee of the devices which are in an alert status.

    Args:
        alert_count: int value representing the total number of alerts
        alerting_devices: a string listing the devices
    Returns:
        a list of rows to be rendered

    """
    rows = [
        render.Row(
            main_align = "center",
            expanded = True,
            children = [
                render.Text(
                    content = "Alerts:" + str(alert_count),
                    font = "6x13",
                    color = colors["red"] if alert_count > 0 else colors["green"],
                    height = 11,
                ),
            ],
        ),
    ]

    if (alert_count > 0):
        rows.append(
            render.Marquee(
                width = 64,
                offset_start = 64,
                offset_end = 64,
                align = "center",
                child = render.Text(
                    content = alerting_devices,
                    font = "5x8",
                ),
            ),
        )

    return rows

def get_device_config(hostname, config):
    url = config["librenms_url"] + ENDPOINT_DEVICES + "/" + hostname
    headers = {"X-Auth-Token": config["api_key"]}
    r = http.get(url, headers = headers, ttl_seconds = CACHE_TTL_SECONDS)
    return r.json()["devices"][0]

def get_device_friendly_name(hostname, config):
    device_config = get_device_config(hostname, config)
    return device_config["display"] or device_config["sysName"]

def render_output(alert_count, alerting_devices):
    # Build a list containing the output, starting with the LibreNMS logo
    children = [print_logo()]

    # Add the alert count and list of the alerting devices if alerts > 0
    children += build_rows(alert_count, alerting_devices)

    # Render the output
    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Box(
            height = 32,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = children,
            ),
        ),
    )

def demo_data():
    return render_output(1, ", ".join(demo_alerting_devices))

def main(config):
    """ Display a count of LibreNMS alerts and a list of the alerting hosts.

    Args:
        config: The config object provided to main() at runtime.

    Returns:
        Renders output to the Tidbyt display.

    """
    if "librenms_url" not in config or "api_key" not in config:
        return demo_data()

    # Get the alert list
    alert_results = get_librenms_alerts(config)

    # Display an error if the HTTP request failed
    if "error" in alert_results:
        return render_error("HTTP error {} - check config".format(alert_results["error"]))

    # Create a list of the friendly names of the devices in alert status
    alerting_devices = list()
    if "alerts" in alert_results:
        for alert_item in alert_results["alerts"]:
            device_friendly_name = get_device_friendly_name(alert_item["hostname"], config)
            if device_friendly_name not in alerting_devices:
                alerting_devices.append(device_friendly_name)
    else:
        return render_error("Data missing in server response.")

    return render_output(int(alert_results["count"]), ", ".join(alerting_devices))

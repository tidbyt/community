# librenms_alerts.star
# Gets the current count of alerts from a LibreNMS server.  If alerts are
# present, displays a marquee listing the hosts which are alerting.
# Justin Tinel 2023-05 jt@justintinel.com

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# Caching: The list of devices which are in an alert state is cached when it
# is first resolved. This avoids subsequent API calls to repeatedly resolve
# device info. The cached device data is then used when a hash of the http
# response data matches the hash of the cached response data.
CACHE_TTL_SECONDS = 60

# LibreNMS endpoint definitions
ENDPOINT_ALERTS = "/api/v0/alerts"
ENDPOINT_DEVICES = "/api/v0/devices"

# Output colors
RED = "F92323"
GREEN = "#2AF923"

LIBRENMS_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAiklEQVQoU42SQRLAEAxF6wws
a6dXcWhXqZ0u6wwpHTFEaG1MIn+en0Rsk3PrA1Q4BffMJu/dgLq8iNqADH6oGRIxEWRDsNaC
c66r64KYCDITyo0CKqwiLEQPtLCNX9EXgRLrV5Dwh8iSZp6QOPW0Ii67R4loYZxTaffMY86z
G0G7SVeJFbVj4HbvAYKAnd83qTc7AAAAAElFTkSuQmCC
""")

HTTP_REGEXP = "^((http|https)://)[-a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)$"

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

# Print the logo centered on a row by itself
def render_logo():
    return render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Image(src = LIBRENMS_ICON),
        ],
    )

# Get the list of rows to be added to the body of the output.
# If the alert count is 0, a single row is returned, indicating that there
# are no alerts. If the alert count > 0, an additional row is displayed,
# containing a marquee of the devices which are in an alert status.
def get_body_rows(alert_count, alerting_devices = ""):
    rows = []

    row_alert_count = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Text(
                content = "Alerts:" + str(alert_count),
                font = "6x13",
                color = RED if alert_count > 0 else GREEN,
                height = 11,
            ),
        ],
    )
    rows.append(row_alert_count)

    if (alert_count > 0):
        row_marquee_alerting_devices = render.Marquee(
            width = 64,
            offset_start = 64,
            offset_end = 64,
            align = "center",
            child = render.Text(
                content = alerting_devices,
                font = "5x8",
            ),
        )
        rows.append(row_marquee_alerting_devices)

    return rows

# Display an error message using render.Marquee.
def render_error(error_msg):
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render_logo(),
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

# Get the list of devices which are alerting. The "alerts" response only
# includes the device ID, so we have to look up the device name separately.
def get_alerting_devices(librenms_url, headers, alerts):
    r_devices = http.get((librenms_url + ENDPOINT_DEVICES), headers = headers)
    if r_devices.status_code != 200:
        return render_error("HTTP Request failed with error {}".format(r_devices.status_code))

    # Get the device list to cross-reference the alert against
    devices = r_devices.json()["devices"]

    # Iterate through the alerts and create a list of the devices which are in
    # an alert state
    alerting_devices = list()
    for alert in alerts:
        # For each alert, look for a device record match
        for item in devices:
            if alert["hostname"] == item["hostname"]:
                # Use the Display name if it is set
                if item["display"]:
                    alerting_devices.append(item["display"])

                    # Otherwise use SNMP sysName
                else:
                    alerting_devices.append(item["sysName"])

    return ", ".join(alerting_devices)

# Render the output
def render_output(alert_count, alerting_devices = ""):
    children = list()
    children.append(render_logo())
    children = children + get_body_rows(alert_count, alerting_devices)

    return render.Root(
        child = render.Box(
            height = 32,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = children,
            ),
        ),
    )

def main(config):
    librenms_url = config.str("librenms_url") or ""
    if not (re.match(HTTP_REGEXP, librenms_url)):
        return render_error("LibreNMS URL invalid - check config")

    api_key = config.str("api_key") or ""
    if api_key == "":
        return render_error("LibreNMS API key not specified - check config")

    headers = {"X-Auth-Token": api_key}

    r_alerts = http.get((librenms_url + ENDPOINT_ALERTS), headers = headers)

    if r_alerts.status_code != 200:
        return render_error("HTTP Request failed with error {}".format(r_alerts.status_code))

    alerts = r_alerts.json()["alerts"]

    if len(alerts) == 0:  # There are no alerts
        return render_output(0)

    else:  # Number of alerts is > 1
        alert_hash_cached = cache.get(librenms_url + "_alert_hash")
        alerting_devices_cached = cache.get(librenms_url + "_alerting_devices")

        # See if the alert data has already been cached before fetching device info
        if (alert_hash_cached != None) and (alerting_devices_cached != None):
            # Cache hit.
            if alert_hash_cached == hash.sha1(r_alerts.body()):
                # Cached data hash matches HTTP response hash. Using cached data.
                alerting_devices = alerting_devices_cached
            else:
                # Hash of cached data does not match HTTP response hash. Calling LibreNMS API.
                alerting_devices = get_alerting_devices(librenms_url, headers, alerts)
                cache.set(librenms_url + "_alert_hash", hash.sha1(r_alerts.body()), ttl_seconds = CACHE_TTL_SECONDS)
                cache.set(librenms_url + "_alerting_devices", alerting_devices, ttl_seconds = CACHE_TTL_SECONDS)
        else:
            # Cache miss. Calling LibreNMS API.
            alerting_devices = get_alerting_devices(librenms_url, headers, alerts)
            cache.set(librenms_url + "_alert_hash", hash.sha1(r_alerts.body()), ttl_seconds = CACHE_TTL_SECONDS)
            cache.set(librenms_url + "_alerting_devices", alerting_devices, ttl_seconds = CACHE_TTL_SECONDS)

        return render_output(len(alerts), alerting_devices)

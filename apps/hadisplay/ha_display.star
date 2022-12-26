"""
Applet: HA Display
Summary: Home Assistant Display
Description: Displays values from a Home Assistant device.
Author: Etienne Michels
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")

def getHistory(sensor, baseURL, headers):
    url = baseURL + "/api/history/period?filter_entity_id=" + sensor
    res = http.get(url, headers = headers)
    if res.status_code != 200:
        fail("Failed to reach api :: %d", res.status_code)
    r = res.json()
    h = [float(t["state"]) for t in r[0]]
    h = list(zip(range(len(h)), h))
    c = str(h[len(h) - 1][1])
    if "unit_of_measurement" in r[0][len(r[0]) - 1]["attributes"]:
        c += r[0][len(r[0]) - 1]["attributes"]["unit_of_measurement"]

    n = r[0][0]["attributes"]["friendly_name"]
    return h, c, n

def main(config):
    children = []
    offset = 5
    baseURL = config.get("url")

    key = config.get("key")

    headers = {"Authorization": "Bearer {}".format(key), "content-type": "application/json"}
    history, current, name = getHistory(config.get("sensor"), baseURL, headers)

    if config.bool("displayName"):
        children.append(render.Marquee(width = 64, child = render.Text(name, font = "tom-thumb")))
        offset = 0

    if config.bool("graph"):
        font = "tb-8"
        align = "start"
        children.append(render.Plot(
            data = history,
            width = 64,
            height = 15 + offset,
            color = "#0f0",
            color_inverted = "#f00",
            fill = True,
        ))

    else:
        align = "center"
        font = "10x20"
    children.insert(-1, render.Text(current, font = font))

    return render.Root(render.Column(
        children = children,
        cross_align = align,
        main_align = "space_evenly",
    ))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "url",
                name = "Home Assistant local URL",
                desc = "The URL for your Home Assistant interface, your local IP address including http://",
                icon = "addressBook",
            ),
            schema.Text(
                id = "key",
                name = "API Key",
                desc = "Long-Lived Access Token generated in the Home Assistant interface",
                icon = "key",
            ),
            schema.Text(
                id = "sensor",
                name = "Sensor Entity ID",
                desc = "The entity ID of thesensor to read data from, can be found by selecting device in Home Assistant and going to the settings tab.",
                icon = "key",
            ),
            schema.Toggle(
                id = "displayName",
                name = "Display Scrolling Device Name",
                desc = "If the device name should be shown",
                icon = "tag",
            ),
            schema.Toggle(
                id = "graph",
                name = "Show graph of last 24 hours",
                desc = "If a graph of the readings over the last 24 hours should be displayed",
                icon = "timeline",
            ),
        ],
    )

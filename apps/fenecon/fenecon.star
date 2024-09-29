"""
Applet: Fenecon
Summary: Fenecon charts
Description: It displays the status of the battery, the generated energy and the consumption, which is fetched from the Fenecon solar system.
Author: raven-rwho
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("schema.star", "schema")

DEFAULT_FENECON_IP = "192.168.x.x"
FENECON_LOCAL_PORT = "80"

SOLAR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IA
rs4c6QAAAFNJREFUOE9jZKAQMIL0/////z+p5jAyMoL1wg1g3PEBbsZ/
DwEGgnyqGzDqhf//CYY6eiwNrljAFYWgFApLcbjUgFMixQZQnBdITYXI6vF6gRiDAUgCahGX8Q+LAAAAAElFTkSuQmCC
""")

BULB_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IA
rs4c6QAAAH9JREFUOE9jZMAB/n9i+I8uxcjHwIghhk0/WPMFPkwpg08M
6IZgmIhTM8w4NENQDEDXPHeGHtwVyRmXEC5CMgSnASDNyJpQ+EPDAJCH
SQ4DkCaKYgEWzBSlAxRD0JIS0SkR5hVGpMT4/xMDRioEqcNIicguGHgD
yM6NuLI4NnEAmfVdEYopENsAAAAASUVORK5CYII=
""")

def battery(local_ip):
    BATTERY_URL = "http://" + local_ip + ":" + FENECON_LOCAL_PORT + "/rest/channel/_sum/EssSoc"
    bat = http.get(BATTERY_URL, auth=("x","user"), ttl_seconds = 120) # cache for 2 minutes
    if bat.status_code != 200:
        fail("Fenecon request to the battery state failed with status %d", bat.status_code)
    bat_rate = bat.json()["value"]
    return bat_rate

def production(local_ip):
    PRODUCTION_URL = "http://" + local_ip + ":" + FENECON_LOCAL_PORT + "/rest/channel/_sum/ProductionActivePower"
    prod = http.get(PRODUCTION_URL, auth=("x","user"), ttl_seconds = 120) # cache for 2 minutes
    if prod.status_code != 200:
        fail("Fenecon request to the production endpoint failed with status %d", prod.status_code)
    prod_rate = prod.json()["value"]
    return (prod_rate)

def consumption(local_ip):
    CONSUMPTION_URL = "http://" + local_ip + ":" + FENECON_LOCAL_PORT + "/rest/channel/_sum/ConsumptionActivePower"
    con = http.get(CONSUMPTION_URL, auth=("x","user"), ttl_seconds = 120) # cache for 2 minutes
    if con.status_code != 200:
        fail("Fenecon request the consumption endpoint failed with status %d", con.status_code)
    con_rate = con.json()["value"]
    return (con_rate)

def main(config):
    local_ip = config.str("ip", DEFAULT_FENECON_IP)

    if (local_ip != DEFAULT_FENECON_IP):
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded=True,
                    main_align="space_evenly",
                    cross_align="center",
                    children = [
                        render.Column(
                            expanded=True,
                            main_align="space_evenly",
                            cross_align="center",
                            children = [
                                render.PieChart(
                                colors = [ "#fff", "#0f0"],
                                weights  = [ 100-battery(local_ip), battery(local_ip)],
                                diameter = 19,
                                ),
                                render.Text(content = "%d" % battery(local_ip) + "%", color="#099", font = "CG-pixel-4x5-mono")
                            ]
                        ),
                        render.Column(
                            children = [
                                render.Row(
                                    cross_align="center",
                                    children = [
                                        render.Image(src=SOLAR_ICON),
                                        render.Text("%d W" % production(local_ip), font = "CG-pixel-4x5-mono")
                                    ]
                                ),
                                render.Row(
                                        cross_align="center",
                                    children = [
                                        render.Image(src=BULB_ICON),
                                        render.Text(content = "%d W" % consumption(local_ip), font = "CG-pixel-4x5-mono")
                                    ]
                                ),
                            ]  
                        )
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            render.Text("No Connection", color="#099", font = "CG-pixel-4x5-mono")
        )

    def get_schema():
        return schema.Schema(
            version = "1",
            fields = [
                schema.Text(
                    id = "ip",
                    name = "Local IP?",
                    desc = "The local IP of your Fenecon solar systems - something like 192.168.2.100",
                    icon = "networkWired",
                ),
            ],
        )

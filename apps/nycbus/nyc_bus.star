"""
Applet: NYC Bus
Summary: NYC Bus departures
Description: Real-time bus departures for your preferred stop.
Author: samandmoore
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_KEY = "<INSERT_API_KEY_HERE>"
STOP_CODE = "550685"
BUSTIME_STOP_TIMES_URL = "http://bustime.mta.info/api/siri/stop-monitoring.json"
BUSTIME_STOP_INFO_URL = "http://bustime.mta.info/api/where/stop/%s.json"

def get_schema():
    stop_options = [
        schema.Option(
            display = "21 ST/BROADWAY SW",
            value = "550685",
        ),
        schema.Option(
            display = "21 ST/41 AV NE",
            value = "550670",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to use for nearby stops.",
                icon = "place",
            ),
            schema.Dropdown(
                id = "stop_code",
                name = "Stop Code",
                desc = "The stop code to use.",
                icon = "bus",
                default = stop_options[1].value,
                options = stop_options,
            ),
        ],
    )

def main(config):
    api_key = config.get("api_key") or API_KEY
    stop_code = config.get("stop_code") or STOP_CODE
    journeys = get_journeys(api_key, stop_code)
    first_journey = journeys[0]
    second_journey = journeys[1]

    return render.Root(
        child=render.Column(
            expanded=True,
            main_align="space_evenly",
            children=[
                build_row(first_journey),
                render.Box(
                    width=64,
                    height=1,
                    color="#f5f5f5",
                ),
                build_row(second_journey),
            ]
        )
    )

def build_row(journey):
    return render.Row(
        expanded=True,
        main_align="space_evenly",
        children=[
            render.Circle(
                color="#%s" % journey["line_color"],
                diameter=14,
                child=render.Text(journey["line_name"], color="#fff", font="CG-pixel-3x5-mono"),
            ),
            render.Column(
                children=[
                    render.Marquee(
                        width=48,
                        child=render.Text(journey["destination_name"]),
                    ),
                    render.Text(journey["eta_text"], color="#c1773e", font="tom-thumb"),
                ]
            ),
        ]
    )

def get_journeys(api_key, stop_code):
    rep = http.get(
        BUSTIME_STOP_TIMES_URL,
        params={
            "version": "2",
            "key": api_key,
            "MonitoringRef": stop_code,
        }
    )
    if rep.status_code != 200:
        fail("MTA BusTime request failed with status %d", rep.status_code)

    journeys = rep.json()["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]["MonitoredStopVisit"]
    first_journey = build_journey(journeys[0]["MonitoredVehicleJourney"], api_key)
    second_journey = build_journey(journeys[1]["MonitoredVehicleJourney"], api_key)
    return [first_journey, second_journey]

def build_journey(raw_journey, api_key):
    line_ref = raw_journey["LineRef"]
    stop_id = raw_journey["MonitoredCall"]["StopPointRef"]
    line_info = get_line_info(stop_id, line_ref, api_key)
    line_color = line_info["color"]
    line_name = raw_journey["PublishedLineName"][0]
    destination_name = raw_journey["DestinationName"][0]
    eta = raw_journey["MonitoredCall"]["ExpectedArrivalTime"]
    now = time.now()
    eta_time = time.parse_time(eta)
    diff = eta_time - now
    diff_minutes = int(diff.minutes)
    eta_text = "%d minutes" % diff_minutes if diff_minutes > 0 else "now"
    return {
        "line_color": line_color,
        "line_name": line_name,
        "destination_name": destination_name,
        "eta_text": eta_text,
    }

def get_line_info(stop_id, line_ref, api_key):
    cache_key = "line-info-%s-%s" % (stop_id, line_ref)
    route = cache.get(cache_key)
    if route != None:
        return json.decode(base64.decode(route))

    print("No line info in cache, requesting...")

    res = http.get(
        BUSTIME_STOP_INFO_URL % stop_id,
        params={
            "key": api_key,
        }
    )
    if res.status_code != 200:
        fail("MTA BusTime request failed with status %d", res.status_code)

    routes = res.json()["data"]["routes"]
    route = [x for x in routes if x["id"] == line_ref][0]
    result = {
        "color": route["color"],
    }

    cache.set(cache_key, base64.encode(json.encode(result)), ttl_seconds=3600)

    return result

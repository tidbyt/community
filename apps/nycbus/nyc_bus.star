"""
Applet: NYC Bus
Summary: NYC Bus departures
Description: Real time bus departures for your preferred stop.
Author: samandmoore
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

EXAMPLE_STOP_CODE = "550685"
ENCRYPTED_API_KEY = "AV6+xWcEsr4R4d680czLc/RnfvU1ZpOx7ofrv0uAb8j7KoKa/Mw9Apbv6dfRFBPPu1oGMxIOSUhdEJV8IdBSwrRHvoOhfSPMmyYzcTJsSdDOoPT0p1KfvAcsyixqdCsYGJcif2+HL4W/qnX6X1hdDZV8pfaQzgswXFmvgnkoFPOWuL9dpc7drUDA"
BUSTIME_STOP_TIMES_URL = "http://bustime.mta.info/api/siri/stop-monitoring.json"
BUSTIME_STOP_INFO_URL = "http://bustime.mta.info/api/where/stop/%s.json"
BUSTIME_STOPS_FOR_LOCATION_URL = "http://bustime.mta.info/api/where/stops-for-location.json"
PREVIEW_DATA = [{"line_color": "FAA61A", "line_name": "Q100", "destination_name": "LIMITED LI CITY QUEENS PLZ", "eta_text": "15 min"}, {"line_color": "00AEEF", "line_name": "Q69", "destination_name": "LI CITY QUEENS PLZ via DITMARS BL via 21 ST", "eta_text": "45 min"}]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop_code",
                name = "Bus Stop",
                desc = "A list of bus stops based on a location.",
                icon = "bus",
                handler = get_stops,
            ),
        ],
    )

def get_stops(location):
    api_key = secret.decrypt(ENCRYPTED_API_KEY)
    loc = json.decode(location)

    res = http.get(
        BUSTIME_STOPS_FOR_LOCATION_URL,
        params = {
            "key": api_key,
            "lat": loc["lat"],
            "latSpan": "0.001",
            "lon": loc["lng"],
            "longSpan": "0.001",
        },
    )
    if res.status_code != 200:
        fail("MTA BusTime request failed with status %d", res.status_code)

    data = res.json()["data"]["stops"]
    stops = [
        schema.Option(display = "%s - %s" % (stop["name"], stop["direction"]), value = stop["code"])
        for stop in data
    ]

    return stops

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY) or config.get("api_key")
    stop_code = config.get("stop_code")
    if stop_code == None:
        stop_code = EXAMPLE_STOP_CODE
    else:
        stop_code = json.decode(stop_code)["value"]

    if api_key:
        journeys = get_journeys(api_key, stop_code)
    else:
        journeys = PREVIEW_DATA

    if journeys == None or len(journeys) == 0:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("No buses found"),
                    ),
                ],
            ),
        )

    if len(journeys) == 1:
        return render.Root(
            child = render.Column(
                expanded = True,
                children = [
                    build_row(journeys[0]),
                ],
            ),
        )

    return render.Root(
        delay = 75,
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                build_row(journeys[0]),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                build_row(journeys[1]),
            ],
        ),
    )

def build_row(journey):
    # Only match names of bus lines that we know won't fit
    multi_line = re.compile("([A-Za-z]+)([0-9]+)([\\/ -])([A-Za-z0-9]+)")
    match = multi_line.match(journey["line_name"])
    if len(journey["line_name"]) > 4 and len(match):
        _, borough, first, sep, second = match[0]

        # Lines like "M55/56" should translate to -> M55, M56
        if sep in ("\\", "/"):
            parts = [borough + first, borough + second]
        elif sep == "-":
            # Lines like "Bx41-SBS"
            parts = journey["line_name"].split("-")
        else:
            # Lines like "M44 Ltd"
            parts = journey["line_name"].split(sep)

        # Add 20 frames for each part, * 75ms root delay = 1.5 seconds each
        anim = []
        for part in parts:
            anim.extend(
                [render.Text(part, color = "#000", font = "CG-pixel-4x5-mono")] * 20,
            )

        line_name = render.Animation(children = anim)
    else:
        line_name = render.Text(journey["line_name"], color = "#000", font = "CG-pixel-4x5-mono")

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(children = [
                render.Box(
                    color = "#%s" % journey["line_color"],
                    width = 22,
                    height = 11,
                ),
                render.Box(
                    color = "#0000",
                    width = 22,
                    height = 11,
                    child = line_name,
                ),
            ]),
            render.Column(
                children = [
                    render.Marquee(
                        width = 36,
                        child = render.Text(
                            journey["destination_name"],
                            font = "Dina_r400-6",
                            offset = -2,
                            height = 7,
                        ),
                    ),
                    render.Text(journey["eta_text"], color = "#f3ab3f"),
                ],
            ),
        ],
    )

def get_journeys(api_key, stop_code):
    rep = http.get(
        BUSTIME_STOP_TIMES_URL,
        params = {
            "version": "2",
            "key": api_key,
            "MonitoringRef": stop_code,
        },
    )
    if rep.status_code != 200:
        fail("MTA BusTime request failed with status %d", rep.status_code)

    json = rep.json()
    deliveries = json["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"]
    if len(deliveries) > 0:
        delivery = deliveries[0]
    else:
        print("No delivery found in response from API!")
        print(deliveries)
        delivery = None

    if delivery != None and "MonitoredStopVisit" in delivery:
        journeys = delivery["MonitoredStopVisit"]
    else:
        print("Delivery response invalid from API!")
        print(delivery)
        journeys = []

    return [build_journey(journey["MonitoredVehicleJourney"], api_key) for journey in journeys[:2]]

def build_journey(raw_journey, api_key):
    line_ref = raw_journey["LineRef"]
    stop_id = raw_journey["MonitoredCall"]["StopPointRef"]
    line_info = get_line_info(stop_id, line_ref, api_key)
    line_color = line_info["color"]
    line_name = raw_journey["PublishedLineName"][0]
    destination_name = raw_journey["DestinationName"][0]
    eta = raw_journey["MonitoredCall"]["ExpectedArrivalTime"]
    now = time.now().in_location("America/New_York")
    eta_time = time.parse_time(eta)
    diff = eta_time - now
    diff_minutes = int(diff.minutes)
    eta_text = "%d min" % diff_minutes if diff_minutes > 0 else "now"
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

    print("Miss! No line info in cache, calling MTA API.")

    res = http.get(
        BUSTIME_STOP_INFO_URL % stop_id,
        params = {
            "key": api_key,
        },
    )
    if res.status_code != 200:
        fail("MTA BusTime request failed with status %d", res.status_code)

    routes = res.json()["data"]["routes"]
    route = [x for x in routes if x["id"] == line_ref][0]
    result = {
        "color": route["color"],
    }

    cache.set(cache_key, base64.encode(json.encode(result)), ttl_seconds = 3600)

    return result

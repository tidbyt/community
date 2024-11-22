"""
Applet: MTA Bus
Summary: MTA bus stop tracker
Description: Track the arrival time for MTA buses.
* Requires an MTA Bus Time API key and MTA bus stop ID. You can request an API key at this URL: https://register.developer.obanyc.com/",
* You also need to set a bus stop ID. It should be a 6-digit number. Look it up at: https://bustime.mta.info/m/routes/",
Author: Kevin Eder
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VISITS_KEY_PREFIX = "mta_bus_visits_"
CACHE_TTL_SECONDS = 60
BUSTIME_URL = "https://bustime.mta.info/api/siri/stop-monitoring.json?key={key}&OperatorRef=MTA&MonitoringRef={stop}"
BUS_IMAGE_BASE_64 = """
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
"""
BUS_ANIMATION_DURATION = 200

def main(config):
    is_key_set = "key" in config
    is_stop_set = "stop" in config
    bus_name = "Bus"
    response_was_error = False
    api_key = config.get("key")
    stop = config.str("stop")
    cache_key = VISITS_KEY_PREFIX + stop

    visits = get_visits_from_cache(cache_key)

    if not visits:
        visits, response_was_error = get_visits_from_api(api_key, stop, cache_key)

    # Try to determine bus line name.
    if len(visits) > 0:
        visit_0 = visits[0]
        if "MonitoredVehicleJourney" in visit_0:
            journey = visit_0.get("MonitoredVehicleJourney")

            if "PublishedLineName" in journey:
                bus_name = journey.get("PublishedLineName")

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 11,
                    child = render.Text("Next {}".format(bus_name), font = "6x13"),
                ),
                render.Box(
                    width = 64,
                    height = 24,
                    child = render.Stack(
                        children = [
                            render.Column(
                                children = get_wait_time_rows(visits, is_key_set, is_stop_set, response_was_error),
                            ),
                            animation.Transformation(
                                child = render.Image(src = base64.decode(BUS_IMAGE_BASE_64), width = 26),
                                duration = BUS_ANIMATION_DURATION,
                                delay = 60,
                                keyframes = [
                                    animation.Keyframe(
                                        percentage = 0.0,
                                        transforms = [animation.Translate(-64, 0)],
                                    ),
                                    animation.Keyframe(
                                        percentage = 1.0,
                                        transforms = [animation.Translate(64, 0)],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_visits_from_api(api_key, stop, cache_key):
    response = http.get(get_url(api_key, stop))
    response_was_error = response.status_code != 200
    delivery = dict()

    if not response_was_error:
        delivery = response.json()["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]

    visits = delivery["MonitoredStopVisit"] if "MonitoredStopVisit" in delivery else []

    encoded_visits = json.encode(visits)
    cache.set(cache_key, encoded_visits, ttl_seconds = CACHE_TTL_SECONDS)

    return visits, response_was_error

def get_visits_from_cache(cache_key):
    cached_val = cache.get(cache_key)

    if cached_val:
        return json.decode(cached_val)

    return None

def get_url(key, stop):
    return BUSTIME_URL.format(key = key, stop = stop)

def get_wait_time_rows(visits, is_key_set, is_stop_set, response_was_error):
    result = list()

    # Check for the next bus.
    if len(visits) > 0:
        expected_arrival = get_expected_arrival(visits[0])

        if expected_arrival:
            result.append(get_minutes_row(time.parse_time(expected_arrival)))

    # Check for the bus after that.
    if len(visits) > 1:
        expected_arrival = get_expected_arrival(visits[1])

        if expected_arrival:
            result.append(get_minutes_row(time.parse_time(expected_arrival)))

    if not is_key_set:
        result.append(get_no_key_set_row())
    elif not is_stop_set:
        result.append(get_no_stop_set_row())
    elif response_was_error:
        result.append(get_api_error_row())
    elif len(result) < 1:
        result.append(get_no_visits_returned())

    return result

def get_minutes_row(arrival):
    diff = arrival - time.now()
    s = str(int(math.round(diff.minutes)))

    return render.Row(
        children = [render.Text("{} minutes".format(s), height = 9, color = "#ff9900")],
        main_align = "center",
        expanded = True,
    )

def get_no_key_set_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No API key set."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_no_stop_set_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No stop set."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_api_error_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("API error."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_no_visits_returned():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No ETA :("),
        ],
        main_align = "center",
    )

def get_error_text_row(text):
    return render.Row(
        children = [
            render.Text(
                text,
                height = 9,
                color = "#ff9900",
            ),
        ],
        expanded = True,
        main_align = "center",
        cross_align = "center",
    )

def get_unknown_time_row():
    return render.Row(
        children = [render.Text("?? minutes", height = 9, color = "#ff9900")],
        main_align = "center",
        expanded = True,
    )

def get_expected_arrival(visit):
    return visit["MonitoredVehicleJourney"]["MonitoredCall"].get("ExpectedArrivalTime", None)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "MTA BusTime API Key",
                desc = "MTA BusTime Developer API Key. Request at: https://register.developer.obanyc.com/",
                icon = "key",
            ),
            schema.Text(
                id = "stop",
                name = "MTA Bus Time Stop ID",
                desc = "Used to identify which bus stop to display. Look it up at: https://bustime.mta.info/m/routes/",
                icon = "bus",
            ),
        ],
    )

"""
Applet: Gvbyt
Summary: Live tram departures
Description: Displays live tram departures for GVB stops in Amsterdam.
Author: Matt Jones (mattjones0111)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

GVB_URL = "https://gvb.nl/api/gvb-shared-services/travelinformation/api/v1/DepartureTimes/GetVisits?stopType=Cluster&previewInterval=60&passageType=Departure&stopCodes="

def main(config):
    departures = get_departures(config)

    if len(departures) == 0:
        return render.Root(
            child = render.Text("No departures"),
        )

    lines = []

    if len(departures) > 0:
        build_marquee(departures[0], lines)

    if len(departures) > 1:
        build_marquee(departures[1], lines)

    return render.Root(
        child = render.Column(
            children = lines,
        ),
    )

def build_marquee(element, lines):
    departureTime = time.parse_time(element["departureGroup"]["expectedDateTime"]).in_location("Europe/Amsterdam")
    relativeDeparture = departureTime - time.now().in_location("Europe/Amsterdam")

    lines.append(
        render.Box(
            width = 64,
            height = 1,
        ),
    )
    lines.append(
        render.Row(
            children = [
                render.Marquee(
                    width = 52,
                    height = 7,
                    child = render.Text(
                        content = element["publishedLineNumber"] + " " + element["destinationName"],
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
                render.Box(
                    width = 1,
                    height = 7,
                ),
                render.Text(
                    content = str(int(relativeDeparture.minutes)) + "m",
                    font = "CG-pixel-3x5-mono",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "stop",
                name = "Stop",
                desc = "Stop name.",
                icon = "gear",
                handler = search_stop,
            ),
        ],
    )

def get_departures(config):
    stop_config = json.decode(config.get("stop", '{"display":"IJburg","text":"IJburg","value":"9508252"}'))
    from_cache = cache.get("gvb-" + stop_config["value"])
    if from_cache == None:
        url = GVB_URL + stop_config["value"]
        response = http.get(url)
        if response.status_code != 200:
            return []
        cache.set("gvb-" + stop_config["value"], response.body(), ttl_seconds = 60)
        departures_string = response.body()
    else:
        departures_string = from_cache

    return json.decode(departures_string)

def search_stop(pattern):
    GVB_STOP_SEARCH_URL = "https://gvb.nl/api/gvb-shared-services/travelinformation/api/v1/DepartureTimes/GetStopsByQuery?stopType=Cluster&inService=true&searchString="

    if len(pattern) < 3:
        return []

    url = GVB_STOP_SEARCH_URL + pattern

    stopSearch = http.get(url)
    stopJs = stopSearch.json()

    result = []

    for stop in stopJs:
        if stop["place"] == "Amsterdam" and "Tram" in stop["stopCategories"]:
            result.append(
                schema.Option(
                    display = stop["stopName"],
                    value = stop["stopCode"],
                ),
            )

    return result

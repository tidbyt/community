"""
Applet: LA Metro
Summary: LA Metro rail services
Description: Shows arrival times for LA Metro rail services.
Author: M0ntyP, tal42levy

v1.0 - Initial Release
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LINE_COLORS = """
{
    "A": "#0072bc",
    "B": "#e3131b",
    "C": "#58a738",
    "D": "#a05da5",
    "E": "#fdb913",
    "K": "#e96bb0"
}
"""
DEFAULT_LOCATION = """
{
    "lat": "34.04803",
    "lng": "-118.25868",
    "description": "Los Angeles, CA, USA",
    "locality": "Los Angeles",
    "timezone": "America/Los_Angeles"
}
"""

BASE_API = "https://api.goswift.ly/real-time"
CACHE_TTL_SECS = 60

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = location["lat"]
    lon = location["lng"]
    api_key = config.get("api_key", "")
    include_busses = config.get("include_bus")

    agency_key = "lametro-rail"
    NextSchedCacheData = None
    if api_key:
        api_url = "{}/{}/predictions-near-location?lat={}&lon={}".format(BASE_API, agency_key, lat, lon)
        NextSchedCacheData = get_cachable_data(api_url, api_key, CACHE_TTL_SECS)

    # Display error, suggest requesting a new key
    if not NextSchedCacheData:
        return render.Root(get_failure_message())

    if NextSchedCacheData.status_code != 200:
        return render.Root(get_failure_message())

    NextSchedCacheData = NextSchedCacheData.body()
    predictions = json.decode(NextSchedCacheData)
    StationData = predictions["data"]["predictionsData"]
    if include_busses:
        api_url = "{}/{}/predictions-near-location?lat={}&lon={}&meters=800".format(BASE_API, "lametro", lat, lon)
        bus_data = get_cachable_data(api_url, api_key, CACHE_TTL_SECS)
        if bus_data.status_code != 200:
            print("Error! Your API key didn't have permission to read busses. Request access to agencykey 'lametro")
        else:
            bus_arrivals = json.decode(bus_data.body())["data"]["predictionsData"]
            StationData += dedupe_routes(bus_arrivals)

    children = []
    for line in StationData:
        children.append(get_line_child(line))
    return render.Root(render.Sequence(children = children), show_full_animation = True)

def get_line_child(line_data):
    DestinationCount = len(line_data["destinations"])
    SelectedLine = line_data["routeName"].replace("Metro ", "").replace(" Line", "")
    ColorMapping = json.decode(LINE_COLORS)

    HEADSIGN_LIST = []

    headsign1 = ""
    arrival_str1 = ""
    LineColor = "#000"

    for i in range(0, DestinationCount, 1):
        HEADSIGN_LIST.append(line_data["destinations"][i]["headsign"])

    # if we have trains going both directions
    if DestinationCount == 2:
        headsign0 = HEADSIGN_LIST.pop(0)
        headsign1 = HEADSIGN_LIST.pop(0)
        if len(line_data["destinations"][0]["predictions"]) > 1:
            headsign0_arr = str(line_data["destinations"][0]["predictions"][0]["min"])
            headsign0_arr1 = str(line_data["destinations"][0]["predictions"][1]["min"])
            arrival_str = " " + headsign0_arr + ", " + headsign0_arr1 + " mins"
            # else if 1 time only

        elif len(line_data["destinations"][0]["predictions"]) == 1:
            headsign0_arr = str(line_data["destinations"][0]["predictions"][0]["min"])
            arrival_str = " " + headsign0_arr + " mins"
        else:
            arrival_str = " No times"

        # if we have 2 times listed going one way
        if len(line_data["destinations"][1]["predictions"]) > 1:
            headsign1_arr = str(line_data["destinations"][1]["predictions"][0]["min"])
            headsign1_arr1 = str(line_data["destinations"][1]["predictions"][1]["min"])
            arrival_str1 = " " + headsign1_arr + ", " + headsign1_arr1 + " mins"
            # else if 1 time only

        elif len(line_data["destinations"][1]["predictions"]) == 1:
            headsign1_arr = str(line_data["destinations"][1]["predictions"][0]["min"])
            arrival_str1 = " " + headsign1_arr + " mins"
        else:
            arrival_str1 = " No times"

    else:
        headsign0 = HEADSIGN_LIST.pop(0)

        # if we have 2 times listed going one way
        if len(line_data["destinations"][0]["predictions"]) > 1:
            headsign0_arr = str(line_data["destinations"][0]["predictions"][0]["min"])
            headsign0_arr1 = str(line_data["destinations"][0]["predictions"][1]["min"])
            arrival_str = " " + headsign0_arr + ", " + headsign0_arr1 + " mins"
            # else if 1 time only

        elif len(line_data["destinations"][0]["predictions"]) == 1:
            headsign0_arr = str(line_data["destinations"][0]["predictions"][0]["min"])
            arrival_str = headsign0_arr + " mins"
        else:
            arrival_str = " No times"

    if SelectedLine in LINE_COLORS:
        LineColor = ColorMapping[SelectedLine]

    if DestinationCount == 2:
        return render.Column(
            expanded = True,
            main_align = "start",
            children = [
                next_arrival(headsign0, arrival_str, SelectedLine, LineColor),
                next_arrival(headsign1, arrival_str1, SelectedLine, LineColor),
            ],
        )
    else:
        return render.Column(
            expanded = True,
            main_align = "start",
            children = [
                next_arrival(headsign0, arrival_str, SelectedLine, LineColor),
            ],
        )

def next_arrival(headsign, arrival_str, SelectedLine, LineColor):
    headsign = headsign.replace(" Station", "")
    headsign = headsign.upper()
    return render.Row(
        expanded = True,
        main_align = "left",
        cross_align = "center",
        children = [
            render.Circle(
                color = LineColor,
                diameter = 14,
                child = render.Text(SelectedLine, font = "5x8"),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 52,
                        child = render.Text(" " + headsign, font = "5x8"),
                        delay = 20,
                    ),
                    render.Text(arrival_str, color = "#fff"),
                ],
            ),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to pull predictions near",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "Swiftly API Key",
                desc = "API Key from Swiftly. Must have access to predictions-near-location for lametro-rail",
                icon = "key",
            ),
            schema.Toggle(
                id = "include_bus",
                name = "Include busses",
                desc = "Check to include bus arrivals. If unset, will only show nearby rail arrivals",
                icon = "bus",
                default = False,
            ),
        ],
    )

def dedupe_routes(arrivals):
    # Because of different stops,, bus arrivals don't merge multiple destinations
    route_id_map = {}
    for arrival in arrivals:
        route_id = arrival["routeId"]
        if route_id not in route_id_map:
            route_id_map[route_id] = arrival
        else:
            route_id_map[route_id]["destinations"] += arrival["destinations"]
    return list(route_id_map.values())

def get_failure_message():
    print("Your API key was invalid or didn't have sufficient permissions!")
    print("Request an API key from swiftly at bit.ly/slyapi, with the agency key 'lametro-rail', and request access to the predictions-near-location endpoint")

    key_msg = "Invalid Key! Request an API key at bit.ly/slyapi"
    return render.WrappedText(key_msg, color = "#fa0", align = "center", font = "tom-thumb")

def get_headers(api_key):
    return {"Authorization": api_key, "Accept": "application/xml, application/json"}

def get_cachable_data(url, api_key, timeout):
    return http.get(url = url, headers = get_headers(api_key), ttl_seconds = timeout)

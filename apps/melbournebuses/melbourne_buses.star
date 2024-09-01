"""
Applet: Melbourne Buses
Summary: Melbourne Bus Departures
Description: Real time bus departures for your preferred stop in Melbourne, Australia.
Author: bendiep

API Name: PTV Timetable API v3
API Swagger URL: https://timetableapi.ptv.vic.gov.au/swagger/ui/index

Changelog:
- v1.0 - First release to Tidbyt
"""

load("encoding/json.star", "json")
load("hmac.star", "hmac")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

LOCAL_MODE = False
LOCAL_API_ID = None
LOCAL_API_KEY = None

BASE_URL = "https://timetableapi.ptv.vic.gov.au"
CACHE_TTL_SECS = 60
ENCRYPTED_API_ID = "AV6+xWcEUFsKJsqPRm2NWEco08PVmBJ0/xLKFPb97mPipfV2hGzYDlDX8Dto1M0DadIGw2zXS4VsQdl+dRVPKJPr9ia2JhJuQ1dxqTVe9C17SZNl7NFtlWDHbOvx/Ht9oNaCg1QBuhaeiIsP6A=="
ENCRYPTED_API_KEY = "AV6+xWcE/JHThbqzYMoWyDLVy1u238TC4dqKalBth5ycLUKFCf7BmUnF5vYB8sAE5S8NgXbD26KZ26b3cF69+mVqLWD3iCjKMPr18SxS5Yjnv/qcCM1nciJKLvr2De2asUtU0VqDirS9Vu6dGNqJHuslI4cRkLDikRMN3DvHqF6bYjFJBwP608eL"

COLOR_CODE_BLUE = "#31AAD5"
COLOR_CODE_ORANGE_HEADER = "#FF8200"
COLOR_CODE_ORANGE_TIME = "#F3AB3F"
COLOR_CODE_RED = "#D47664"
COLOR_CODE_WHITE = "#FFFFFF"
COLOR_CODE_YELLOW = "#F3B22C"

DEFAULT_LOCATION = """
{
    "lat": -37.89064565327984,
    "lng": 145.089161459262,
    "locality": "Melbourne, AU",
    "timezone": "Australia/Melbourne"
}
"""

def main(location):
    # Get Location
    if type(location) == "string":
        location = json.decode(location)
    else:
        location = json.decode(DEFAULT_LOCATION)
    latitude = float(location["lat"])
    longitude = float(location["lng"])

    if latitude and longitude:
        departures, stop = get_departures(latitude, longitude)

        # Render - API Credential Error
        if departures == -1:
            return render.Root(
                render.Box(
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text("API", color = "#7fd856"),
                                    render.Text("CREDENTIAL", color = "#ffdd5a"),
                                    render.Text("ERROR", color = "#ff3232"),
                                ],
                            ),
                        ],
                    ),
                ),
            )

        # Render - API Health Error
        if departures == -2:
            return render.Root(
                render.Box(
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text("API", color = "#7fd856"),
                                    render.Text("HEALTH", color = "#ffdd5a"),
                                    render.Text("ERROR", color = "#ff3232"),
                                ],
                            ),
                        ],
                    ),
                ),
            )

        # Render - Single Departure Row
        if len(departures) == 1:
            return render.Root(
                delay = 75,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        build_header_row(stop),
                        build_divider_visible_row(),
                        build_departure_row(departures[0], stop),
                        build_divider_visible_row(),
                    ],
                ),
            )

        # Render - Double Departure Rows
        if len(departures) == 2:
            return render.Root(
                delay = 75,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        build_header_row(stop),
                        build_divider_invisible_row(),
                        build_divider_visible_row(),
                        build_departure_row(departures[0], stop),
                        build_divider_visible_row(),
                        build_departure_row(departures[1], stop),
                    ],
                ),
            )

    # Render - Default (No Departures)
    return render.Root(
        child = render.Column(
            expanded = False,
            main_align = "space_evenly",
            children = [
                render.WrappedText(
                    content = "No bus departures found",
                    width = 64,
                ),
            ],
        ),
    )

# Render Function - Header Row
def build_header_row(stop):
    return render.Row(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Stack(children = [
                # Render - Bus Label
                render.Box(
                    color = COLOR_CODE_ORANGE_HEADER,
                    width = 16,
                    height = 8,
                    child = render.Text("BUS", color = COLOR_CODE_WHITE, font = "5x8"),
                ),
            ]),
            render.Column(
                children = [
                    # Render - Stop Name
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            stop["stop_name"].upper(),
                            font = "Dina_r400-6",
                            offset = -2,
                            height = 7,
                        ),
                    ),
                ],
            ),
        ],
    )

# Render Function - Departure Row
def build_departure_row(departure, stop):
    route_number = render.Text(stop["stop_routes"][departure["route_id"]]["route_number"], color = COLOR_CODE_WHITE, font = "5x8")

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Stack(children = [
                # Render - Bus Route Number
                render.Box(
                    color = departure["color"],
                    width = 26,
                    height = 10,
                    child = route_number,
                ),
            ]),
            render.Column(
                children = [
                    # Render - Departure Time Remaining
                    render.Text(departure["eta_time_text"] + " ", color = COLOR_CODE_ORANGE_TIME),
                ],
            ),
        ],
    )

# Render Function - Divider Visible Row
def build_divider_visible_row():
    return render.Box(
        width = 64,
        height = 1,
        color = "#666",
    )

# Render Function - Divider Invisible Row
def build_divider_invisible_row():
    return render.Box(
        width = 64,
        height = 1,
        color = "#000000",
    )

# API - GET Departures Data and Transform
def get_departures(latitude, longitude):
    # Set API ID/KEY
    api_id = LOCAL_API_ID if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_ID)
    api_key = LOCAL_API_KEY if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_KEY)
    if api_id == None or api_key == None:
        print("[ERROR]: Failed to retrieve API credentials")
        return -1, None

    # Retrieve Data - Bus Stop
    stop_data = get_bus_stop(api_id, api_key, latitude, longitude)
    if stop_data == -2:
        return -2, None

    # Retrieve Data - Departures
    request_path = "/v3/departures/route_type/2/stop/" + stop_data["stop_id"]
    request_additional_params = "max_results=2&include_cancelled=false"
    signature_url = request_path + "?" + request_additional_params + "&devid=" + api_id
    signature = get_request_signature(signature_url, api_key)
    url = BASE_URL + request_path + "?" + request_additional_params + "&devid=" + api_id + "&signature=" + signature

    response = http.get(url, ttl_seconds = CACHE_TTL_SECS)
    if response.status_code != 200:
        print("[ERROR]: Request failed with status code: %d - %s and request url: %s" % (response.status_code, response.body(), url))
        return -2, None

    # Transform Data - Departures
    departures = response.json()["departures"]
    departures_data = []

    for i, item in enumerate(departures):
        route_id = str(int(item["route_id"]))
        estimated_time = item["estimated_departure_utc"]
        scheduled_time = item["scheduled_departure_utc"]
        departure_time = estimated_time if estimated_time != None else scheduled_time
        remaining_time_minutes = get_remaining_time_minutes(departure_time)
        eta_time_text = "now" if remaining_time_minutes == 0 else str(remaining_time_minutes) + " mins"
        color = get_color_code(remaining_time_minutes)

        departure = {
            "route_id": route_id,
            "departure_time": departure_time,
            "remaining_time_minutes": remaining_time_minutes,
            "eta_time_text": eta_time_text,
            "color": color,
        }
        departures_data.append(departure)

    # Sort by remaining time
    departures_data = sorted(departures_data, key = lambda x: x["remaining_time_minutes"])

    # Remove any "combined" routes (i.e. duplicates)
    departures_data = [departure for departure in departures_data if "C" not in stop_data["stop_routes"][departure["route_id"]]["route_number"]]

    # Only collect enough data to render the first two departures
    if len(departures_data) > 2:
        departures_data = departures_data[:2]

    return (departures_data, stop_data)

# API - GET Bus Stop Data and Transform
def get_bus_stop(api_id, api_key, latitude, longitude):
    # Retrieve Data - Stops
    request_path = "/v3/stops/location/" + str(latitude) + "," + str(longitude)
    request_additional_params = "route_types=2"
    signature_url = request_path + "?" + request_additional_params + "&devid=" + api_id
    signature = get_request_signature(signature_url, api_key)
    url = BASE_URL + request_path + "?" + request_additional_params + "&devid=" + api_id + "&signature=" + signature

    response = http.get(url, ttl_seconds = CACHE_TTL_SECS)
    if response.status_code != 200:
        print("[ERROR]: Request failed with status code: %d - %s and request url: %s" % (response.status_code, response.body(), url))
        return -2

    # Transform Data - Stops
    stops = response.json()["stops"]
    if not len(stops) >= 1:
        print("[ERROR]: No stops found for the given location")
        return -2

    stop = stops[0]
    stop_id = str(int(stop["stop_id"]))
    stop_name = stop["stop_name"]
    stop_routes = {}

    for i, route in enumerate(stop["routes"]):
        route_id = int(route["route_id"])
        route_name = route["route_name"]

        if "combined" in route["route_number"].lower():
            route_number = route["route_number"][:3] + "C"
        elif len(route["route_number"]) > 3:
            route_number = route["route_number"][:3] + "*"
        else:
            route_number = route["route_number"]

        stop_routes[str(route_id)] = {
            "route_name": route_name,
            "route_number": route_number,
        }

    transformed_data = {
        "stop_id": stop_id,
        "stop_name": stop_name,
        "stop_routes": stop_routes,
    }

    return transformed_data

# Helper - Generate request signature in HMAC-SHA1 hash format (required query parameter in every request)
def get_request_signature(signature_url, key):
    signature = hmac.sha1(key, signature_url).upper()
    return signature

# Helper - Calculate remaining time from given UTC timestamp in minutes
def get_remaining_time_minutes(departure_time):
    now = time.now().in_location("Australia/Melbourne")
    eta_time = time.parse_time(departure_time)
    diff = eta_time - now
    diff_minutes = int(diff.minutes)
    return diff_minutes

# Helper - Return color code based on time remaining
def get_color_code(remaining_time_minutes):
    if remaining_time_minutes <= 10:
        return COLOR_CODE_RED
    elif remaining_time_minutes <= 20:
        return COLOR_CODE_YELLOW
    else:
        return COLOR_CODE_BLUE

# Main Schema Function
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "location",
                name = "Bus Location",
                desc = "Find the nearest bus stop by location",
                icon = "locationDot",
                handler = main,
            ),
        ],
    )

"""
Applet: Melbourne Trams
Summary: Melbourne Tram Departures
Description: Real time tram departures for your preferred stop in Melbourne, Australia.
Author: bendiep

API Name: PTV Timetable API v3
API Swagger URL: https://timetableapi.ptv.vic.gov.au/swagger/ui/index

Changelog:
- v1.0 - First release to Tidbyt
"""

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
ENCRYPTED_API_ID = "AV6+xWcEIM2iOjwBGhNs3JMeHoYX/R0bDcXZDW3WC7XE3f8KftL3+9T/3zuK0utBCG5WL93CZjecRjHXfpbfC5w/CzqFyfTHzmICSVBOsVYSINoXoo2efGLSi8W+oWeTIgXBHcmL0gZjziKeIQ=="
ENCRYPTED_API_KEY = "AV6+xWcErKRGH+v/Dxtu+6FEfsNZAuEUV0jn24sj3M6UWo0my7ftqrWNMWkf+N2g1Ak5wZiFNWloOV+DRnh8/DaK+JMWt0TrAPhfdXRQDRaLECBeJ8QZvdNR4+AU7aHWCU0OfmUihME7FiSfftF5i6ppHIzIkAYr7UKgER4qxBW8NHqEXFq8SYQo"

COLOR_CODE_TRAM_ROUTE_1 = "#ADB838"
COLOR_CODE_TRAM_ROUTE_3 = "#8EBFD9"
COLOR_CODE_TRAM_ROUTE_5 = "#C92437"
COLOR_CODE_TRAM_ROUTE_6 = "#193A58"
COLOR_CODE_TRAM_ROUTE_11 = "#70BFA3"
COLOR_CODE_TRAM_ROUTE_12 = "#007B8C"
COLOR_CODE_TRAM_ROUTE_16 = "#F8D271"
COLOR_CODE_TRAM_ROUTE_19 = "#7E2454"
COLOR_CODE_TRAM_ROUTE_30 = "#524A81"
COLOR_CODE_TRAM_ROUTE_35 = "#5D3228"
COLOR_CODE_TRAM_ROUTE_48 = "#373736"
COLOR_CODE_TRAM_ROUTE_57 = "#00B3C1"
COLOR_CODE_TRAM_ROUTE_58 = "#808180"
COLOR_CODE_TRAM_ROUTE_59 = "#006F3B"
COLOR_CODE_TRAM_ROUTE_64 = "#009E81"
COLOR_CODE_TRAM_ROUTE_67 = "#8E6453"
COLOR_CODE_TRAM_ROUTE_70 = "#E991AE"
COLOR_CODE_TRAM_ROUTE_72 = "#95B59F"
COLOR_CODE_TRAM_ROUTE_75 = "#009ECD"
COLOR_CODE_TRAM_ROUTE_78 = "#918DB8"
COLOR_CODE_TRAM_ROUTE_82 = "#D0D358"
COLOR_CODE_TRAM_ROUTE_86 = "#F2B02A"
COLOR_CODE_TRAM_ROUTE_96 = "#B71C6F"
COLOR_CODE_TRAM_ROUTE_109 = "#E06E2B"
COLOR_CODE_GREEN_HEADER = "#78BE20"
COLOR_CODE_TIME = "#F3AB3F"
COLOR_CODE_WHITE = "#FFFFFF"
COLOR_CODE_BLACK = "#000000"

DEFAULT_ROUTE_ID = "897"
DEFAULT_ROUTE_NUMBER = "59"
DEFAULT_STOP_ID = "2685"
DEFAULT_STOP_NAME = "32: Moonee Ponds Jct/Pascoe Vale Rd"
DEFAULT_DIRECTION_ID = "11"
DEFAULT_DIRECTION_DATA = ["11", "Flinders St Stn (City)"]

def main(config):
    schema_tram_route = config.get("tram-route")
    route_id, route_number = schema_tram_route.split(",") if schema_tram_route != None else (DEFAULT_ROUTE_ID, DEFAULT_ROUTE_NUMBER)

    schema_tram_stop = config.get("stop-list-" + route_id) if route_id != None else None
    stop_id, stop_name = schema_tram_stop.split(",") if schema_tram_stop != None else (DEFAULT_STOP_ID, DEFAULT_STOP_NAME)

    schema_direction = config.get("direction-list-" + route_id) if route_id != None else None
    direction_data = schema_direction.split(",") if schema_direction != None else DEFAULT_DIRECTION_DATA
    direction_id = direction_data[0] if schema_direction != None else DEFAULT_DIRECTION_ID

    color_code = get_tram_route_color_code(route_number)

    # print("\n\n\n[DEBUG]: \
    #         \nschema_tram_route: %s\
    #         \nroute_id: %s\
    #         \nroute_number: %s\
    #         \nschema_tram_stop: %s\
    #         \nstop_id: %s\
    #         \nstop_name: %s\
    #         \nschema_direction: %s\
    #         \ndirection_id: %s\
    #         \ndirection_data: %s\
    #         \ncolor_code: %s"
    #         % (schema_tram_route, route_id, route_number, schema_tram_stop,
    #         stop_id, stop_name, schema_direction, direction_id, direction_data,
    #         color_code))

    if route_id and stop_id and direction_id:
        departures = get_departures(route_id, stop_id, direction_id, route_number, stop_name, direction_data, color_code)

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
                        build_departure_row(departures[0]),
                        build_divider_visible_row(),
                        build_divider_invisible_row(),
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
                        build_departure_row(departures[0]),
                        build_divider_visible_row(),
                        build_divider_invisible_row(),
                        build_departure_row(departures[1]),
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
                    content = "No tram departures found",
                    width = 64,
                ),
            ],
        ),
    )

# Render Function - Departure Row
def build_departure_row(departure):
    route_number = render.Text(departure["route_number"], color = COLOR_CODE_BLACK, font = "5x8")
    stop_number = departure["stop_name"].split(":")[0]

    return render.Row(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Stack(children = [
                # Render - Tram Route Color Code and Route Number
                render.Box(
                    color = departure["color"],
                    width = 16,
                    height = 14,
                    child = route_number,
                ),
            ]),
            render.Box(
                width = 1,
                height = 1,
                color = "#000000",
            ),
            render.Column(
                children = [
                    # Render - Departure Direction
                    render.Marquee(
                        width = 48,
                        child = render.Text(
                            departure["direction_name"].upper() + " (STOP " + stop_number + ")",
                            font = "Dina_r400-6",
                            offset = -2,
                            height = 7,
                        ),
                    ),
                    # Render - Departure Time Remaining
                    render.Text(departure["eta_time_text"], color = COLOR_CODE_TIME),
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
def get_departures(route_id, stop_id, direction_id, route_number, stop_name, direction_data, color_code):
    # Set API ID/KEY
    api_id = LOCAL_API_ID if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_ID)
    api_key = LOCAL_API_KEY if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_KEY)
    if api_id == None or api_key == None:
        print("[ERROR]: Failed to retrieve API credentials")
        return -1

    # Retrieve Data
    request_path = "/v3/departures/route_type/1/stop/" + stop_id + "/route/" + route_id
    request_additional_params = "max_results=2&include_cancelled=false"
    request_additional_params += "&direction_id=" + direction_id if direction_id != "All" else ""
    signature_url = request_path + "?" + request_additional_params + "&devid=" + api_id
    signature = get_request_signature(signature_url, api_key)
    url = BASE_URL + request_path + "?" + request_additional_params + "&devid=" + api_id + "&signature=" + signature

    response = http.get(url, ttl_seconds = CACHE_TTL_SECS)
    if response.status_code != 200:
        print("[ERROR]: Request failed with status code: %d - %s and request url: %s" % (response.status_code, response.body(), url))
        return -2

    # Transform Data
    departures = response.json()["departures"]
    transformed_data = []

    for i, item in enumerate(departures):
        estimated_time = item["estimated_departure_utc"]
        scheduled_time = item["scheduled_departure_utc"]
        departure_time = estimated_time if estimated_time != None else scheduled_time

        remaining_time_minutes = get_remaining_time_minutes(departure_time)
        eta_time_text = "now" if remaining_time_minutes == 0 else str(remaining_time_minutes) + " mins"

        if direction_id == "All":
            ext_direction_id = item["direction_id"]
            mapped_direction_id = direction_data[1 if int(ext_direction_id) == int(direction_data[1]) else 3]
            mapped_direction_name = direction_data[2 if int(ext_direction_id) == int(direction_data[1]) else 4]
        else:
            mapped_direction_id, mapped_direction_name = direction_data[0], direction_data[1]

        departure = {
            "processed_id": i,
            "route_id": route_id,
            "route_number": route_number,
            "stop_id": stop_id,
            "stop_name": stop_name,
            "direction_id": mapped_direction_id,
            "direction_name": mapped_direction_name,
            "departure_time": departure_time,
            "remaining_time_minutes": remaining_time_minutes,
            "eta_time_text": eta_time_text,
            "color": color_code,
        }
        transformed_data.append(departure)

    # Sort by remaining time
    transformed_data = sorted(transformed_data, key = lambda x: x["remaining_time_minutes"])

    # Only collect enough data to render the first two departures
    # For direction_id = "All", response contains 4 departures, therefore we need to trim the results down to just 2 departures
    if len(transformed_data) > 2:
        transformed_data = transformed_data[:2]

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

# Helper - Return color code theme for each tram route
def get_tram_route_color_code(route_number):
    if route_number == "1":
        return COLOR_CODE_TRAM_ROUTE_1
    elif route_number == "3":
        return COLOR_CODE_TRAM_ROUTE_3
    elif route_number == "5":
        return COLOR_CODE_TRAM_ROUTE_5
    elif route_number == "6":
        return COLOR_CODE_TRAM_ROUTE_6
    elif route_number == "11":
        return COLOR_CODE_TRAM_ROUTE_11
    elif route_number == "12":
        return COLOR_CODE_TRAM_ROUTE_12
    elif route_number == "16":
        return COLOR_CODE_TRAM_ROUTE_16
    elif route_number == "19":
        return COLOR_CODE_TRAM_ROUTE_19
    elif route_number == "30":
        return COLOR_CODE_TRAM_ROUTE_30
    elif route_number == "35":
        return COLOR_CODE_TRAM_ROUTE_35
    elif route_number == "48":
        return COLOR_CODE_TRAM_ROUTE_48
    elif route_number == "57":
        return COLOR_CODE_TRAM_ROUTE_57
    elif route_number == "58":
        return COLOR_CODE_TRAM_ROUTE_58
    elif route_number == "59":
        return COLOR_CODE_TRAM_ROUTE_59
    elif route_number == "64":
        return COLOR_CODE_TRAM_ROUTE_64
    elif route_number == "67":
        return COLOR_CODE_TRAM_ROUTE_67
    elif route_number == "70":
        return COLOR_CODE_TRAM_ROUTE_70
    elif route_number == "72":
        return COLOR_CODE_TRAM_ROUTE_72
    elif route_number == "75":
        return COLOR_CODE_TRAM_ROUTE_75
    elif route_number == "78":
        return COLOR_CODE_TRAM_ROUTE_78
    elif route_number == "82":
        return COLOR_CODE_TRAM_ROUTE_82
    elif route_number == "86":
        return COLOR_CODE_TRAM_ROUTE_86
    elif route_number == "96":
        return COLOR_CODE_TRAM_ROUTE_96
    elif route_number == "109":
        return COLOR_CODE_TRAM_ROUTE_109
    else:
        return COLOR_CODE_WHITE

# Schema Options - Tram Route Options (value = route_id,route_number)
TramRouteOptions = [
    schema.Option(
        display = "1: East Coburg - South Melbourne Beach",
        value = "721,1",
    ),
    schema.Option(
        display = "3: Melbourne University - East Malvern",
        value = "15833,3",
    ),
    schema.Option(
        display = "5: Melbourne University - Malvern",
        value = "1083,5",
    ),
    schema.Option(
        display = "6: Moreland - Glen Iris",
        value = "11544,6",
    ),
    schema.Option(
        display = "11: West Preston - Victoria Harbour Docklands",
        value = "3343,11",
    ),
    schema.Option(
        display = "12: Victoria Gardens - St Kilda",
        value = "8314,12",
    ),
    schema.Option(
        display = "16: Melbourne University - Kew via St Kilda Beach",
        value = "724,16",
    ),
    schema.Option(
        display = "19: North Coburg - Flinders St Stn & City",
        value = "725,19",
    ),
    schema.Option(
        display = "30: St Vincents Plaza - Central Pier Docklands via La Trobe St",
        value = "1880,30",
    ),
    schema.Option(
        display = "35: City Circle (Free Tourist Tram)",
        value = "15834,35",
    ),
    schema.Option(
        display = "48: North Balwyn - Victoria Harbour Docklands",
        value = "2903,48",
    ),
    schema.Option(
        display = "57: West Maribyrnong - Flinders St Stn & City",
        value = "887,57",
    ),
    schema.Option(
        display = "58: West Coburg - Toorak",
        value = "11529,58",
    ),
    schema.Option(
        display = "59: Airport West - Flinders St Stn & City",
        value = "897,59",
    ),
    schema.Option(
        display = "64: Melbourne University - East Brighton",
        value = "909,64",
    ),
    schema.Option(
        display = "67: Melbourne University - Carnegie",
        value = "913,67",
    ),
    schema.Option(
        display = "70: Waterfront City Docklands -  Wattle Park",
        value = "940,70",
    ),
    schema.Option(
        display = "72: Melbourne University - Camberwell",
        value = "947,72",
    ),
    schema.Option(
        display = "75: Vermont South - Central Pier Docklands",
        value = "958,75",
    ),
    schema.Option(
        display = "78: North Richmond - Balaclava via Prahran",
        value = "976,78",
    ),
    schema.Option(
        display = "82: Moonee Ponds - Footscray",
        value = "1002,82",
    ),
    schema.Option(
        display = "86: Bundoora RMIT - Waterfront City Docklands",
        value = "1881,86",
    ),
    schema.Option(
        display = "96: East Brunswick - St Kilda Beach",
        value = "1041,96",
    ),
    schema.Option(
        display = "109: Box Hill - Port Melbourne",
        value = "722,109",
    ),
]

# Schema Options - Stop Options Per Tram Route (value = stop_id,stop_name)
Route1StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Arts Precinct/Sturt St",
        value = "2266,17: Arts Precinct/Sturt St",
    ),
    schema.Option(
        display = "18: Grant St/Sturt St",
        value = "2268,18: Grant St/Sturt St",
    ),
    schema.Option(
        display = "19: Miles St/Sturt St",
        value = "2269,19: Miles St/Sturt St",
    ),
    schema.Option(
        display = "20: Kings Way/Sturt St",
        value = "2270,20: Kings Way/Sturt St",
    ),
    schema.Option(
        display = "22: Dorcas St/Eastern Rd",
        value = "2271,22: Dorcas St/Eastern Rd",
    ),
    schema.Option(
        display = "23: Moray St/Park St",
        value = "2272,23: Moray St/Park St",
    ),
    schema.Option(
        display = "24: Clarendon St/Park St",
        value = "2273,24: Clarendon St/Park St",
    ),
    schema.Option(
        display = "25: Cecil St/Park St",
        value = "2274,25: Cecil St/Park St",
    ),
    schema.Option(
        display = "26: Ferrars St/Park St",
        value = "2275,26: Ferrars St/Park St",
    ),
    schema.Option(
        display = "27: Montague St/Park St",
        value = "2276,27: Montague St/Park St",
    ),
    schema.Option(
        display = "27: Park St/Montague St",
        value = "2277,27: Park St/Montague St",
    ),
    schema.Option(
        display = "28: Montague St/Bridport St",
        value = "2279,28: Montague St/Bridport St",
    ),
    schema.Option(
        display = "28: Bridport St/Montague St",
        value = "2278,28: Bridport St/Montague St",
    ),
    schema.Option(
        display = "29: Bridport St/Victoria Ave",
        value = "2280,29: Bridport St/Victoria Ave",
    ),
    schema.Option(
        display = "30: Richardson St/Victoria Ave",
        value = "2282,30: Richardson St/Victoria Ave",
    ),
    schema.Option(
        display = "31: Graham St/Victoria Ave",
        value = "2283,31: Graham St/Victoria Ave",
    ),
    schema.Option(
        display = "32: Beaconsfield Pde/Victoria Ave",
        value = "2285,32: Beaconsfield Pde/Victoria Ave",
    ),
    schema.Option(
        display = "112: Lygon St/Elgin St",
        value = "2216,112: Lygon St/Elgin St",
    ),
    schema.Option(
        display = "113: Lytton St/Lygon St",
        value = "2217,113: Lytton St/Lygon St",
    ),
    schema.Option(
        display = "114: Princes St/Lygon St",
        value = "2218,114: Princes St/Lygon St",
    ),
    schema.Option(
        display = "115: Melbourne Cemetery/Lygon St",
        value = "2219,115: Melbourne Cemetery/Lygon St",
    ),
    schema.Option(
        display = "116: Fenwick St/Lygon St",
        value = "2220,116: Fenwick St/Lygon St",
    ),
    schema.Option(
        display = "117: Richardson St/Lygon St",
        value = "2221,117: Richardson St/Lygon St",
    ),
    schema.Option(
        display = "118: Pigdon St/Lygon St",
        value = "2222,118: Pigdon St/Lygon St",
    ),
    schema.Option(
        display = "120: Brunswick Rd/Lygon St",
        value = "2224,120: Brunswick Rd/Lygon St",
    ),
    schema.Option(
        display = "121: Weston St/Lygon St",
        value = "2225,121: Weston St/Lygon St",
    ),
    schema.Option(
        display = "122: Glenlyon Rd/Lygon St",
        value = "2226,122: Glenlyon Rd/Lygon St",
    ),
    schema.Option(
        display = "123: Albert St/Lygon St",
        value = "2227,123: Albert St/Lygon St",
    ),
    schema.Option(
        display = "124: Victoria St/Lygon St",
        value = "2228,124: Victoria St/Lygon St",
    ),
    schema.Option(
        display = "125: Blyth St/Lygon St",
        value = "2229,125: Blyth St/Lygon St",
    ),
    schema.Option(
        display = "126: Stewart St/Lygon St",
        value = "2230,126: Stewart St/Lygon St",
    ),
    schema.Option(
        display = "127: Albion St/Holmes St",
        value = "2240,127: Albion St/Holmes St",
    ),
    schema.Option(
        display = "127: Albion St/Lygon St",
        value = "2231,127: Albion St/Lygon St",
    ),
    schema.Option(
        display = "128: Mitchell St/Holmes St",
        value = "2232,128: Mitchell St/Holmes St",
    ),
    schema.Option(
        display = "129: Moreland Rd/Holmes St",
        value = "2233,129: Moreland Rd/Holmes St",
    ),
    schema.Option(
        display = "129: Moreland Rd/Nicholson St",
        value = "2265,129: Moreland Rd/Nicholson St",
    ),
    schema.Option(
        display = "130: The Avenue/Nicholson St",
        value = "2264,130: The Avenue/Nicholson St",
    ),
    schema.Option(
        display = "131: Rennie St/Nicholson St",
        value = "2263,131: Rennie St/Nicholson St",
    ),
    schema.Option(
        display = "132: Crozier St/Nicholson St",
        value = "2262,132: Crozier St/Nicholson St",
    ),
    schema.Option(
        display = "133: Harding St/Nicholson St",
        value = "2261,133: Harding St/Nicholson St",
    ),
    schema.Option(
        display = "134: Merribell Ave/Nicholson St",
        value = "2260,134: Merribell Ave/Nicholson St",
    ),
    schema.Option(
        display = "135: Bell St/Nicholson St",
        value = "2044,135: Bell St/Nicholson St",
    ),
]
Route3StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "29: Union St/St Kilda Rd",
        value = "2403,29: Union St/St Kilda Rd",
    ),
    schema.Option(
        display = "30: St Kilda Jct/St Kilda Rd",
        value = "2401,30: St Kilda Jct/St Kilda Rd",
    ),
    schema.Option(
        display = "31: Barkly St/St Kilda Rd",
        value = "2399,31: Barkly St/St Kilda Rd",
    ),
    schema.Option(
        display = "32: Alma Rd/St Kilda Rd",
        value = "2314,32: Alma Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "33: Argyle St/St Kilda Rd",
        value = "2313,33: Argyle St/St Kilda Rd",
    ),
    schema.Option(
        display = "34: Inkerman St/St Kilda Rd",
        value = "2398,34: Inkerman St/St Kilda Rd",
    ),
    schema.Option(
        display = "35: Brighton Rd/Carlisle St",
        value = "2311,35: Brighton Rd/Carlisle St",
    ),
    schema.Option(
        display = "35: Carlisle St/St Kilda Rd",
        value = "2779,35: Carlisle St/St Kilda Rd",
    ),
    schema.Option(
        display = "36: St Kilda Town Hall/Carlisle St",
        value = "2310,36: St Kilda Town Hall/Carlisle St",
    ),
    schema.Option(
        display = "37: Chapel St/Carlisle St",
        value = "2974,37: Chapel St/Carlisle St",
    ),
    schema.Option(
        display = "37: Chapel St/Carlisle St",
        value = "2737,37: Chapel St/Carlisle St",
    ),
    schema.Option(
        display = "38: Balaclava Stn/Carlisle St",
        value = "2736,38: Balaclava Stn/Carlisle St",
    ),
    schema.Option(
        display = "39: Carlisle Ave/Carlisle St",
        value = "2778,39: Carlisle Ave/Carlisle St",
    ),
    schema.Option(
        display = "39: Orange Gr/Carlisle St",
        value = "2735,39: Orange Gr/Carlisle St",
    ),
    schema.Option(
        display = "40: Hotham St/Balaclava Rd",
        value = "2777,40: Hotham St/Balaclava Rd",
    ),
    schema.Option(
        display = "40: Hotham St/Carlisle St",
        value = "2734,40: Hotham St/Carlisle St",
    ),
    schema.Option(
        display = "41: Empress Rd/Balaclava Rd",
        value = "2733,41: Empress Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "41: Vadlure Ave/Balaclava Rd",
        value = "2776,41: Vadlure Ave/Balaclava Rd",
    ),
    schema.Option(
        display = "42: Allan Rd/Balaclava Rd",
        value = "2775,42: Allan Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "42: Sidwell Ave/Balaclava Rd",
        value = "2732,42: Sidwell Ave/Balaclava Rd",
    ),
    schema.Option(
        display = "43: Orrong Rd/Balaclava Rd",
        value = "2731,43: Orrong Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "44: Ontario St/Balaclava Rd",
        value = "2730,44: Ontario St/Balaclava Rd",
    ),
    schema.Option(
        display = "44: Otira Rd/Balaclava Rd",
        value = "2774,44: Otira Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "45: Kent Gr/Balaclava Rd",
        value = "2773,45: Kent Gr/Balaclava Rd",
    ),
    schema.Option(
        display = "45: Lumeah Rd/Balaclava Rd",
        value = "2729,45: Lumeah Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "46: Kooyong Rd/Balaclava Rd",
        value = "2728,46: Kooyong Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "47: Caulfield Junior College/Balaclava Rd",
        value = "2309,47: Caulfield Junior College/Balaclava Rd",
    ),
    schema.Option(
        display = "47: Elmhurst Rd/Balaclava Rd",
        value = "2247,47: Elmhurst Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "51: Hawthorn Rd/Balaclava Rd",
        value = "2308,51: Hawthorn Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "52: Caulfield Park Bowling Club/Balaclava Rd",
        value = "2306,52: Caulfield Park Bowling Club/Balaclava Rd",
    ),
    schema.Option(
        display = "53: Caulfield Park/Balaclava Rd",
        value = "2305,53: Caulfield Park/Balaclava Rd",
    ),
    schema.Option(
        display = "54: Kambrook Rd/Balaclava Rd",
        value = "2402,54: Kambrook Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "54: Kambrook Rd/Balaclava Rd",
        value = "2304,54: Kambrook Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "55: Balaclava Rd/Normanby Rd",
        value = "2302,55: Balaclava Rd/Normanby Rd",
    ),
    schema.Option(
        display = "55: Normanby Rd/Balaclava Rd",
        value = "2303,55: Normanby Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "56: Caulfield Racecourse/Normanby Rd",
        value = "2301,56: Caulfield Racecourse/Normanby Rd",
    ),
    schema.Option(
        display = "56: Caulfield Racecourse/Normanby Rd",
        value = "2312,56: Caulfield Racecourse/Normanby Rd",
    ),
    schema.Option(
        display = "57: Caulfield Stn/Derby Rd",
        value = "2299,57: Caulfield Stn/Derby Rd",
    ),
    schema.Option(
        display = "58: Dandenong Rd/Derby Rd",
        value = "2298,58: Dandenong Rd/Derby Rd",
    ),
    schema.Option(
        display = "59: Dandenong Rd/Waverley Rd",
        value = "2295,59: Dandenong Rd/Waverley Rd",
    ),
    schema.Option(
        display = "59: Dandenong Rd/Waverley Rd",
        value = "2296,59: Dandenong Rd/Waverley Rd",
    ),
    schema.Option(
        display = "60: Burke Rd/Waverley Rd",
        value = "2294,60: Burke Rd/Waverley Rd",
    ),
    schema.Option(
        display = "61: Tennyson St/Waverley Rd",
        value = "2293,61: Tennyson St/Waverley Rd",
    ),
    schema.Option(
        display = "62: Macgregor St/Waverley Rd",
        value = "2291,62: Macgregor St/Waverley Rd",
    ),
    schema.Option(
        display = "62: The Avenue/Waverley Rd",
        value = "2292,62: The Avenue/Waverley Rd",
    ),
    schema.Option(
        display = "63: Hughes St/Waverley Rd",
        value = "2289,63: Hughes St/Waverley Rd",
    ),
    schema.Option(
        display = "63: Oak Gr/Waverley Rd",
        value = "2290,63: Oak Gr/Waverley Rd",
    ),
    schema.Option(
        display = "64: Darling Rd/Waverley Rd",
        value = "2684,64: Darling Rd/Waverley Rd",
    ),
]
Route5StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "29: Union St/St Kilda Rd",
        value = "2403,29: Union St/St Kilda Rd",
    ),
    schema.Option(
        display = "30: St Kilda Jct/St Kilda Rd",
        value = "2401,30: St Kilda Jct/St Kilda Rd",
    ),
    schema.Option(
        display = "31: Queens Way/Queens Way",
        value = "2975,31: Queens Way/Queens Way",
    ),
    schema.Option(
        display = "31: Queens Way/Queens Way",
        value = "2605,31: Queens Way/Queens Way",
    ),
    schema.Option(
        display = "32: Chapel St/Dandenong Rd",
        value = "2604,32: Chapel St/Dandenong Rd",
    ),
    schema.Option(
        display = "33: Hornby St/Dandenong Rd",
        value = "2603,33: Hornby St/Dandenong Rd",
    ),
    schema.Option(
        display = "34: The Avenue/Dandenong Rd",
        value = "2602,34: The Avenue/Dandenong Rd",
    ),
    schema.Option(
        display = "34: Westbury St/Dandenong Rd",
        value = "2601,34: Westbury St/Dandenong Rd",
    ),
    schema.Option(
        display = "35: Williams Rd/Dandenong Rd",
        value = "2599,35: Williams Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "36: Alexandra St/Dandenong Rd",
        value = "2597,36: Alexandra St/Dandenong Rd",
    ),
    schema.Option(
        display = "36: Closeburn Ave/Dandenong Rd",
        value = "2598,36: Closeburn Ave/Dandenong Rd",
    ),
    schema.Option(
        display = "37: Lansdowne Rd/Dandenong Rd",
        value = "2596,37: Lansdowne Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "37: Lansdowne Rd/Dandenong Rd",
        value = "2621,37: Lansdowne Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "38: Orrong Rd/Dandenong Rd",
        value = "2623,38: Orrong Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "38: Orrong Rd/Dandenong Rd",
        value = "2595,38: Orrong Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "40: Wattletree Rd/Dandenong Rd",
        value = "2593,40: Wattletree Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "41: Armadale St/Wattletree Rd",
        value = "2591,41: Armadale St/Wattletree Rd",
    ),
    schema.Option(
        display = "42: Kooyong Rd/Wattletree Rd",
        value = "2590,42: Kooyong Rd/Wattletree Rd",
    ),
    schema.Option(
        display = "43: Egerton Rd/Wattletree Rd",
        value = "2589,43: Egerton Rd/Wattletree Rd",
    ),
    schema.Option(
        display = "44: Duncraig Ave/Wattletree Rd",
        value = "2588,44: Duncraig Ave/Wattletree Rd",
    ),
    schema.Option(
        display = "45: Glenferrie Rd/Wattletree Rd",
        value = "2587,45: Glenferrie Rd/Wattletree Rd",
    ),
    schema.Option(
        display = "46: Nicholls St/Wattletree Rd",
        value = "2586,46: Nicholls St/Wattletree Rd",
    ),
    schema.Option(
        display = "46: Soudan St/Wattletree Rd",
        value = "2585,46: Soudan St/Wattletree Rd",
    ),
    schema.Option(
        display = "47: Cabrini Hospital/Wattletree Rd",
        value = "2584,47: Cabrini Hospital/Wattletree Rd",
    ),
    schema.Option(
        display = "48: Dixon St/Wattletree Rd",
        value = "2583,48: Dixon St/Wattletree Rd",
    ),
    schema.Option(
        display = "49: Tooronga Rd/Wattletree Rd",
        value = "2582,49: Tooronga Rd/Wattletree Rd",
    ),
    schema.Option(
        display = "50: Anderson St/Wattletree Rd",
        value = "2580,50: Anderson St/Wattletree Rd",
    ),
    schema.Option(
        display = "50: Vincent St/Wattletree Rd",
        value = "2581,50: Vincent St/Wattletree Rd",
    ),
    schema.Option(
        display = "51: Erica Ave/Wattletree Rd",
        value = "2579,51: Erica Ave/Wattletree Rd",
    ),
    schema.Option(
        display = "51: Nott St/Wattletree Rd",
        value = "2578,51: Nott St/Wattletree Rd",
    ),
    schema.Option(
        display = "52: Burke Rd/Wattletree Rd",
        value = "2577,52: Burke Rd/Wattletree Rd",
    ),
]
Route6StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "28: Punt Rd/High St",
        value = "2648,28: Punt Rd/High St",
    ),
    schema.Option(
        display = "28: Punt Rd/High St",
        value = "2978,28: Punt Rd/High St",
    ),
    schema.Option(
        display = "29: Perth St/High St",
        value = "2647,29: Perth St/High St",
    ),
    schema.Option(
        display = "29: Perth St/High St",
        value = "2977,29: Perth St/High St",
    ),
    schema.Option(
        display = "30: Prahran Stn/High St",
        value = "2646,30: Prahran Stn/High St",
    ),
    schema.Option(
        display = "30: Prahran Stn/High St",
        value = "2645,30: Prahran Stn/High St",
    ),
    schema.Option(
        display = "31: Chapel St/High St",
        value = "2644,31: Chapel St/High St",
    ),
    schema.Option(
        display = "32: Hornby St/High St",
        value = "2642,32: Hornby St/High St",
    ),
    schema.Option(
        display = "33: The Avenue/High St",
        value = "2640,33: The Avenue/High St",
    ),
    schema.Option(
        display = "34: Lewisham Rd/High St",
        value = "2639,34: Lewisham Rd/High St",
    ),
    schema.Option(
        display = "35: Williams Rd/High St",
        value = "2638,35: Williams Rd/High St",
    ),
    schema.Option(
        display = "36: Chatsworth Rd/High St",
        value = "2636,36: Chatsworth Rd/High St",
    ),
    schema.Option(
        display = "37: Airlie Ave/High St",
        value = "2635,37: Airlie Ave/High St",
    ),
    schema.Option(
        display = "38: Orrong Rd/High St",
        value = "2976,38: Orrong Rd/High St",
    ),
    schema.Option(
        display = "38: Orrong Rd/High St",
        value = "2634,38: Orrong Rd/High St",
    ),
    schema.Option(
        display = "39: Auburn Gr/High St",
        value = "2633,39: Auburn Gr/High St",
    ),
    schema.Option(
        display = "40: Armadale Stn/High St",
        value = "2631,40: Armadale Stn/High St",
    ),
    schema.Option(
        display = "41: Kooyong Rd/High St",
        value = "2630,41: Kooyong Rd/High St",
    ),
    schema.Option(
        display = "42: Huntingtower Rd/High St",
        value = "2629,42: Huntingtower Rd/High St",
    ),
    schema.Option(
        display = "43: Mercer Rd/High St",
        value = "2628,43: Mercer Rd/High St",
    ),
    schema.Option(
        display = "44: Glenferrie Rd/High St",
        value = "2627,44: Glenferrie Rd/High St",
    ),
    schema.Option(
        display = "45: De La Salle College/High St",
        value = "2626,45: De La Salle College/High St",
    ),
    schema.Option(
        display = "46: Fraser St/High St",
        value = "2625,46: Fraser St/High St",
    ),
    schema.Option(
        display = "47: Dixon St/High St",
        value = "2624,47: Dixon St/High St",
    ),
    schema.Option(
        display = "48: Tooronga Rd/High St",
        value = "2622,48: Tooronga Rd/High St",
    ),
    schema.Option(
        display = "49: Harold Holt Swim Centre/High St",
        value = "2620,49: Harold Holt Swim Centre/High St",
    ),
    schema.Option(
        display = "50: Belmont Ave/High St",
        value = "2618,50: Belmont Ave/High St",
    ),
    schema.Option(
        display = "51: Burke Rd/High St",
        value = "2617,51: Burke Rd/High St",
    ),
    schema.Option(
        display = "52: Boyanda Rd/High St",
        value = "2616,52: Boyanda Rd/High St",
    ),
    schema.Option(
        display = "53: Malvern Rd/High St",
        value = "2300,53: Malvern Rd/High St",
    ),
    schema.Option(
        display = "112: Lygon St/Elgin St",
        value = "2216,112: Lygon St/Elgin St",
    ),
    schema.Option(
        display = "113: Lytton St/Lygon St",
        value = "2217,113: Lytton St/Lygon St",
    ),
    schema.Option(
        display = "114: Princes St/Lygon St",
        value = "2218,114: Princes St/Lygon St",
    ),
    schema.Option(
        display = "115: Melbourne Cemetery/Lygon St",
        value = "2219,115: Melbourne Cemetery/Lygon St",
    ),
    schema.Option(
        display = "116: Fenwick St/Lygon St",
        value = "2220,116: Fenwick St/Lygon St",
    ),
    schema.Option(
        display = "117: Richardson St/Lygon St",
        value = "2221,117: Richardson St/Lygon St",
    ),
    schema.Option(
        display = "118: Pigdon St/Lygon St",
        value = "2222,118: Pigdon St/Lygon St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "120: Brunswick Rd/Lygon St",
        value = "2224,120: Brunswick Rd/Lygon St",
    ),
    schema.Option(
        display = "121: Weston St/Lygon St",
        value = "2225,121: Weston St/Lygon St",
    ),
    schema.Option(
        display = "122: Glenlyon Rd/Lygon St",
        value = "2226,122: Glenlyon Rd/Lygon St",
    ),
    schema.Option(
        display = "123: Albert St/Lygon St",
        value = "2227,123: Albert St/Lygon St",
    ),
    schema.Option(
        display = "124: Victoria St/Lygon St",
        value = "2228,124: Victoria St/Lygon St",
    ),
    schema.Option(
        display = "125: Blyth St/Lygon St",
        value = "2229,125: Blyth St/Lygon St",
    ),
    schema.Option(
        display = "126: Stewart St/Lygon St",
        value = "2230,126: Stewart St/Lygon St",
    ),
    schema.Option(
        display = "127: Albion St/Holmes St",
        value = "2240,127: Albion St/Holmes St",
    ),
    schema.Option(
        display = "127: Albion St/Lygon St",
        value = "2231,127: Albion St/Lygon St",
    ),
    schema.Option(
        display = "128: Mitchell St/Holmes St",
        value = "2232,128: Mitchell St/Holmes St",
    ),
    schema.Option(
        display = "129: Moreland Rd/Holmes St",
        value = "2233,129: Moreland Rd/Holmes St",
    ),
    schema.Option(
        display = "130: Barrow St/Moreland Rd",
        value = "2234,130: Barrow St/Moreland Rd",
    ),
    schema.Option(
        display = "131: De Carle St/Moreland Rd",
        value = "2235,131: De Carle St/Moreland Rd",
    ),
    schema.Option(
        display = "132: Sydney Rd/Moreland Rd",
        value = "2236,132: Sydney Rd/Moreland Rd",
    ),
    schema.Option(
        display = "133: Moreland Stn/Cameron St",
        value = "2781,133: Moreland Stn/Cameron St",
    ),
    schema.Option(
        display = "133: Moreland Stn/Moreland Rd",
        value = "2237,133: Moreland Stn/Moreland Rd",
    ),
]
Route11StopOptions = [
    schema.Option(
        display = "1: Spencer St/Collins St",
        value = "2496,1: Spencer St/Collins St",
    ),
    schema.Option(
        display = "3: William St/Collins St",
        value = "2494,3: William St/Collins St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Collins St",
        value = "2492,5: Elizabeth St/Collins St",
    ),
    schema.Option(
        display = "6: Melbourne Town Hall/Collins St",
        value = "2491,6: Melbourne Town Hall/Collins St",
    ),
    schema.Option(
        display = "7: Exhibition St/Collins St",
        value = "2174,7: Exhibition St/Collins St",
    ),
    schema.Option(
        display = "8: Spring St/Collins St",
        value = "2488,8: Spring St/Collins St",
    ),
    schema.Option(
        display = "10: Parliament Stn/Macarthur St",
        value = "2487,10: Parliament Stn/Macarthur St",
    ),
    schema.Option(
        display = "11: Albert St/Gisborne St",
        value = "2485,11: Albert St/Gisborne St",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2484,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2483,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "13: Gertrude St/Brunswick St",
        value = "2551,13: Gertrude St/Brunswick St",
    ),
    schema.Option(
        display = "14: Hanover St/Brunswick St",
        value = "2550,14: Hanover St/Brunswick St",
    ),
    schema.Option(
        display = "14: King William St/Brunswick St",
        value = "2549,14: King William St/Brunswick St",
    ),
    schema.Option(
        display = "15: Bell St/Brunswick St",
        value = "2548,15: Bell St/Brunswick St",
    ),
    schema.Option(
        display = "15: St David St/Brunswick St",
        value = "2547,15: St David St/Brunswick St",
    ),
    schema.Option(
        display = "16: Johnston St/Brunswick St",
        value = "2546,16: Johnston St/Brunswick St",
    ),
    schema.Option(
        display = "17: Leicester St/Brunswick St",
        value = "2545,17: Leicester St/Brunswick St",
    ),
    schema.Option(
        display = "18: Alexandra Pde/Brunswick St",
        value = "2966,18: Alexandra Pde/Brunswick St",
    ),
    schema.Option(
        display = "18: Alexandra Pde/Brunswick St",
        value = "2544,18: Alexandra Pde/Brunswick St",
    ),
    schema.Option(
        display = "19: Newry St/Brunswick St",
        value = "2543,19: Newry St/Brunswick St",
    ),
    schema.Option(
        display = "20: Fitzroy Bowls Club/Brunswick St",
        value = "2541,20: Fitzroy Bowls Club/Brunswick St",
    ),
    schema.Option(
        display = "21: Alfred Cres/St Georges Rd",
        value = "2539,21: Alfred Cres/St Georges Rd",
    ),
    schema.Option(
        display = "22: Scotchmer St/St Georges Rd",
        value = "2538,22: Scotchmer St/St Georges Rd",
    ),
    schema.Option(
        display = "23: Park St/St Georges Rd",
        value = "2536,23: Park St/St Georges Rd",
    ),
    schema.Option(
        display = "24: Holden St/St Georges Rd",
        value = "2535,24: Holden St/St Georges Rd",
    ),
    schema.Option(
        display = "25: Miller St/St Georges Rd",
        value = "2534,25: Miller St/St Georges Rd",
    ),
    schema.Option(
        display = "26: Clarke St/St Georges Rd",
        value = "2533,26: Clarke St/St Georges Rd",
    ),
    schema.Option(
        display = "27: Westbourne Gr/St Georges Rd",
        value = "2532,27: Westbourne Gr/St Georges Rd",
    ),
    schema.Option(
        display = "28: Sumner Ave/St Georges Rd",
        value = "2531,28: Sumner Ave/St Georges Rd",
    ),
    schema.Option(
        display = "29: Arthurton Rd/St Georges Rd",
        value = "2530,29: Arthurton Rd/St Georges Rd",
    ),
    schema.Option(
        display = "30: Gladstone Ave/St Georges Rd",
        value = "2529,30: Gladstone Ave/St Georges Rd",
    ),
    schema.Option(
        display = "31: Bird Ave/St Georges Rd",
        value = "2528,31: Bird Ave/St Georges Rd",
    ),
    schema.Option(
        display = "31: Gadd St/St Georges Rd",
        value = "2527,31: Gadd St/St Georges Rd",
    ),
    schema.Option(
        display = "32: Normanby Ave/St Georges Rd",
        value = "2526,32: Normanby Ave/St Georges Rd",
    ),
    schema.Option(
        display = "33: Hutton St/St Georges Rd",
        value = "2525,33: Hutton St/St Georges Rd",
    ),
    schema.Option(
        display = "34: Miller St/St Georges Rd",
        value = "2524,34: Miller St/St Georges Rd",
    ),
    schema.Option(
        display = "35: St Georges Rd/Miller St",
        value = "3343,35: St Georges Rd/Miller St",
    ),
    schema.Option(
        display = "36: Bracken Ave/Miller St",
        value = "2523,36: Bracken Ave/Miller St",
    ),
    schema.Option(
        display = "36: Devon St/Miller St",
        value = "2522,36: Devon St/Miller St",
    ),
    schema.Option(
        display = "37: Miller St/Gilbert Rd",
        value = "2521,37: Miller St/Gilbert Rd",
    ),
    schema.Option(
        display = "38: Oakover Rd/Gilbert Rd",
        value = "2520,38: Oakover Rd/Gilbert Rd",
    ),
    schema.Option(
        display = "39: Latona Ave/Gilbert Rd",
        value = "2519,39: Latona Ave/Gilbert Rd",
    ),
    schema.Option(
        display = "40: Bell St/Gilbert Rd",
        value = "2518,40: Bell St/Gilbert Rd",
    ),
    schema.Option(
        display = "41: Bruce St/Gilbert Rd",
        value = "2517,41: Bruce St/Gilbert Rd",
    ),
    schema.Option(
        display = "42: Cramer St/Gilbert Rd",
        value = "2516,42: Cramer St/Gilbert Rd",
    ),
    schema.Option(
        display = "43: Murray Rd/Gilbert Rd",
        value = "2515,43: Murray Rd/Gilbert Rd",
    ),
    schema.Option(
        display = "44: Cooper St/Gilbert Rd",
        value = "2514,44: Cooper St/Gilbert Rd",
    ),
    schema.Option(
        display = "45: Jacka St/Gilbert Rd",
        value = "2512,45: Jacka St/Gilbert Rd",
    ),
    schema.Option(
        display = "46: McNamara St/Gilbert Rd",
        value = "2513,46: McNamara St/Gilbert Rd",
    ),
    schema.Option(
        display = "47: West Preston/Gilbert Rd",
        value = "2511,47: West Preston/Gilbert Rd",
    ),
]
Route12StopOptions = [
    schema.Option(
        display = "1: Spencer St/Collins St",
        value = "2496,1: Spencer St/Collins St",
    ),
    schema.Option(
        display = "1: Spencer St/La Trobe St",
        value = "3271,1: Spencer St/La Trobe St",
    ),
    schema.Option(
        display = "3: William St/Collins St",
        value = "2494,3: William St/Collins St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Collins St",
        value = "2492,5: Elizabeth St/Collins St",
    ),
    schema.Option(
        display = "6: Melbourne Town Hall/Collins St",
        value = "2491,6: Melbourne Town Hall/Collins St",
    ),
    schema.Option(
        display = "7: Exhibition St/Collins St",
        value = "2174,7: Exhibition St/Collins St",
    ),
    schema.Option(
        display = "8: Spring St/Collins St",
        value = "2488,8: Spring St/Collins St",
    ),
    schema.Option(
        display = "10: Parliament Stn/Macarthur St",
        value = "2487,10: Parliament Stn/Macarthur St",
    ),
    schema.Option(
        display = "11: Albert St/Gisborne St",
        value = "2485,11: Albert St/Gisborne St",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2483,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2484,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "13: Lansdowne St/Victoria Pde",
        value = "2167,13: Lansdowne St/Victoria Pde",
    ),
    schema.Option(
        display = "13: Lansdowne St/Victoria Pde",
        value = "2481,13: Lansdowne St/Victoria Pde",
    ),
    schema.Option(
        display = "15: Smith St/Victoria Pde",
        value = "2246,15: Smith St/Victoria Pde",
    ),
    schema.Option(
        display = "15: Smith St/Victoria Pde",
        value = "2477,15: Smith St/Victoria Pde",
    ),
    schema.Option(
        display = "16: Wellington St/Victoria Pde",
        value = "2540,16: Wellington St/Victoria Pde",
    ),
    schema.Option(
        display = "16: Wellington St/Victoria Pde",
        value = "2475,16: Wellington St/Victoria Pde",
    ),
    schema.Option(
        display = "18: Hoddle St/Victoria Pde",
        value = "2471,18: Hoddle St/Victoria Pde",
    ),
    schema.Option(
        display = "19: North Richmond Stn/Victoria St",
        value = "2470,19: North Richmond Stn/Victoria St",
    ),
    schema.Option(
        display = "19: North Richmond Stn/Victoria St",
        value = "2468,19: North Richmond Stn/Victoria St",
    ),
    schema.Option(
        display = "20: Lennox St/Victoria St",
        value = "2466,20: Lennox St/Victoria St",
    ),
    schema.Option(
        display = "20: Lennox St/Victoria St",
        value = "2469,20: Lennox St/Victoria St",
    ),
    schema.Option(
        display = "21: Church St/Victoria St",
        value = "3352,21: Church St/Victoria St",
    ),
    schema.Option(
        display = "21: Church St/Victoria St",
        value = "2467,21: Church St/Victoria St",
    ),
    schema.Option(
        display = "22: McKay St/Victoria St",
        value = "2465,22: McKay St/Victoria St",
    ),
    schema.Option(
        display = "23: Flockhart St/Victoria St",
        value = "2463,23: Flockhart St/Victoria St",
    ),
    schema.Option(
        display = "23: Leslie St/Victoria St",
        value = "2462,23: Leslie St/Victoria St",
    ),
    schema.Option(
        display = "24: Burnley St/Victoria St",
        value = "2461,24: Burnley St/Victoria St",
    ),
    schema.Option(
        display = "119: La Trobe St/Spencer St",
        value = "2050,119: La Trobe St/Spencer St",
    ),
    schema.Option(
        display = "120: Lonsdale St/Spencer St",
        value = "2053,120: Lonsdale St/Spencer St",
    ),
    schema.Option(
        display = "122: Southern Cross Stn/Spencer St",
        value = "2497,122: Southern Cross Stn/Spencer St",
    ),
    schema.Option(
        display = "124: Batman Park/Spencer St",
        value = "2499,124: Batman Park/Spencer St",
    ),
    schema.Option(
        display = "125: Clarendon St/Whiteman St",
        value = "2503,125: Clarendon St/Whiteman St",
    ),
    schema.Option(
        display = "125: Port Jct/79 Whiteman St",
        value = "2504,125: Port Jct/79 Whiteman St",
    ),
    schema.Option(
        display = "126: City Rd/Clarendon St",
        value = "2552,126: City Rd/Clarendon St",
    ),
    schema.Option(
        display = "127: York St/Clarendon St",
        value = "2553,127: York St/Clarendon St",
    ),
    schema.Option(
        display = "128: Dorcas St/Clarendon St",
        value = "2554,128: Dorcas St/Clarendon St",
    ),
    schema.Option(
        display = "129: Park St/Clarendon St",
        value = "2555,129: Park St/Clarendon St",
    ),
    schema.Option(
        display = "130: Albert Rd/Clarendon St",
        value = "2558,130: Albert Rd/Clarendon St",
    ),
    schema.Option(
        display = "130: Clarendon St/Albert Rd",
        value = "2559,130: Clarendon St/Albert Rd",
    ),
    schema.Option(
        display = "131: Melbourne Sports & Aquatic Centre/Albert Rd",
        value = "2560,131: Melbourne Sports & Aquatic Centre/Albert Rd",
    ),
    schema.Option(
        display = "132: Canterbury Rd/Albert Rd",
        value = "2561,132: Canterbury Rd/Albert Rd",
    ),
    schema.Option(
        display = "132: Kerferd Rd/Canterbury Rd",
        value = "2562,132: Kerferd Rd/Canterbury Rd",
    ),
    schema.Option(
        display = "133: Canterbury Rd/Mills St",
        value = "2563,133: Canterbury Rd/Mills St",
    ),
    schema.Option(
        display = "134: Carter St/Mills St",
        value = "2564,134: Carter St/Mills St",
    ),
    schema.Option(
        display = "135: Richardson St/Mills St",
        value = "2565,135: Richardson St/Mills St",
    ),
    schema.Option(
        display = "136: Danks St/Mills St",
        value = "2566,136: Danks St/Mills St",
    ),
    schema.Option(
        display = "136: Mills St/Danks St",
        value = "2567,136: Mills St/Danks St",
    ),
    schema.Option(
        display = "137: Harold St/Danks St",
        value = "2568,137: Harold St/Danks St",
    ),
    schema.Option(
        display = "138: Armstrong St/Danks St",
        value = "2569,138: Armstrong St/Danks St",
    ),
    schema.Option(
        display = "139: Langridge St/Patterson St",
        value = "2570,139: Langridge St/Patterson St",
    ),
    schema.Option(
        display = "140: Fraser St/Park St",
        value = "2572,140: Fraser St/Park St",
    ),
    schema.Option(
        display = "140: Fraser St/Patterson St",
        value = "2571,140: Fraser St/Patterson St",
    ),
    schema.Option(
        display = "141: Cowderoy St/Park St",
        value = "2573,141: Cowderoy St/Park St",
    ),
    schema.Option(
        display = "141: Deakin St/Park St",
        value = "2574,141: Deakin St/Park St",
    ),
    schema.Option(
        display = "142: Mary St/Park St",
        value = "2575,142: Mary St/Park St",
    ),
    schema.Option(
        display = "143: Fitzroy St/Park St",
        value = "2576,143: Fitzroy St/Park St",
    ),
]
Route16StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "29: Union St/St Kilda Rd",
        value = "2403,29: Union St/St Kilda Rd",
    ),
    schema.Option(
        display = "30: St Kilda Jct/St Kilda Rd",
        value = "2401,30: St Kilda Jct/St Kilda Rd",
    ),
    schema.Option(
        display = "32: Havelock St/Carlisle St",
        value = "2741,32: Havelock St/Carlisle St",
    ),
    schema.Option(
        display = "33: Barkly St/Carlisle St",
        value = "2739,33: Barkly St/Carlisle St",
    ),
    schema.Option(
        display = "34: Greeves St/Carlisle St",
        value = "2740,34: Greeves St/Carlisle St",
    ),
    schema.Option(
        display = "34: Mitchell St/Carlisle St",
        value = "2738,34: Mitchell St/Carlisle St",
    ),
    schema.Option(
        display = "35: Brighton Rd/Carlisle St",
        value = "2311,35: Brighton Rd/Carlisle St",
    ),
    schema.Option(
        display = "35: St Kilda Rd/Carlisle St",
        value = "3345,35: St Kilda Rd/Carlisle St",
    ),
    schema.Option(
        display = "36: St Kilda Town Hall/Carlisle St",
        value = "2310,36: St Kilda Town Hall/Carlisle St",
    ),
    schema.Option(
        display = "37: Chapel St/Carlisle St",
        value = "2737,37: Chapel St/Carlisle St",
    ),
    schema.Option(
        display = "37: Chapel St/Carlisle St",
        value = "2974,37: Chapel St/Carlisle St",
    ),
    schema.Option(
        display = "38: Balaclava Stn/Carlisle St",
        value = "2736,38: Balaclava Stn/Carlisle St",
    ),
    schema.Option(
        display = "39: Carlisle Ave/Carlisle St",
        value = "2778,39: Carlisle Ave/Carlisle St",
    ),
    schema.Option(
        display = "39: Orange Gr/Carlisle St",
        value = "2735,39: Orange Gr/Carlisle St",
    ),
    schema.Option(
        display = "40: Hotham St/Balaclava Rd",
        value = "2777,40: Hotham St/Balaclava Rd",
    ),
    schema.Option(
        display = "40: Hotham St/Carlisle St",
        value = "2734,40: Hotham St/Carlisle St",
    ),
    schema.Option(
        display = "41: Empress Rd/Balaclava Rd",
        value = "2733,41: Empress Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "41: Vadlure Ave/Balaclava Rd",
        value = "2776,41: Vadlure Ave/Balaclava Rd",
    ),
    schema.Option(
        display = "42: Allan Rd/Balaclava Rd",
        value = "2775,42: Allan Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "42: Sidwell Ave/Balaclava Rd",
        value = "2732,42: Sidwell Ave/Balaclava Rd",
    ),
    schema.Option(
        display = "43: Orrong Rd/Balaclava Rd",
        value = "2731,43: Orrong Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "44: Ontario St/Balaclava Rd",
        value = "2730,44: Ontario St/Balaclava Rd",
    ),
    schema.Option(
        display = "44: Otira Rd/Balaclava Rd",
        value = "2774,44: Otira Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "45: Kent Gr/Balaclava Rd",
        value = "2773,45: Kent Gr/Balaclava Rd",
    ),
    schema.Option(
        display = "45: Lumeah Rd/Balaclava Rd",
        value = "2729,45: Lumeah Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "46: Kooyong Rd/Balaclava Rd",
        value = "2728,46: Kooyong Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "47: Caulfield Junior College/Balaclava Rd",
        value = "2309,47: Caulfield Junior College/Balaclava Rd",
    ),
    schema.Option(
        display = "47: Elmhurst Rd/Balaclava Rd",
        value = "2247,47: Elmhurst Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "48: Dandenong Rd/Glenferrie Rd",
        value = "2891,48: Dandenong Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "48: Hawthorn Rd/Dandenong Rd",
        value = "2998,48: Hawthorn Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "49: Arthur St/Hawthorn Rd",
        value = "2725,49: Arthur St/Hawthorn Rd",
    ),
    schema.Option(
        display = "49: Wanda Rd/Hawthorn Rd",
        value = "2724,49: Wanda Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "50: Inkerman Rd/Hawthorn Rd",
        value = "2726,50: Inkerman Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "51: Balaclava Rd/Hawthorn Rd",
        value = "2727,51: Balaclava Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "51: Hawthorn Rd/Balaclava Rd",
        value = "2308,51: Hawthorn Rd/Balaclava Rd",
    ),
    schema.Option(
        display = "52: Dandenong Rd/Glenferrie Rd",
        value = "2892,52: Dandenong Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "53: Malvern Stn/Glenferrie Rd",
        value = "2893,53: Malvern Stn/Glenferrie Rd",
    ),
    schema.Option(
        display = "54: Wattletree Rd/Glenferrie Rd",
        value = "2895,54: Wattletree Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "55: Edsall St/Glenferrie Rd",
        value = "2896,55: Edsall St/Glenferrie Rd",
    ),
    schema.Option(
        display = "55: Llaneast St/Glenferrie Rd",
        value = "2897,55: Llaneast St/Glenferrie Rd",
    ),
    schema.Option(
        display = "56: Malvern Tram Depot/Glenferrie Rd",
        value = "2446,56: Malvern Tram Depot/Glenferrie Rd",
    ),
    schema.Option(
        display = "57: High St/Glenferrie Rd",
        value = "2900,57: High St/Glenferrie Rd",
    ),
    schema.Option(
        display = "58: Bell St/Glenferrie Rd",
        value = "2901,58: Bell St/Glenferrie Rd",
    ),
    schema.Option(
        display = "58: Sorrett Ave/Glenferrie Rd",
        value = "2902,58: Sorrett Ave/Glenferrie Rd",
    ),
    schema.Option(
        display = "59: Malvern Rd/Glenferrie Rd",
        value = "2903,59: Malvern Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "60: Stonnington Pl/Glenferrie Rd",
        value = "2904,60: Stonnington Pl/Glenferrie Rd",
    ),
    schema.Option(
        display = "61: Moorakyne Ave/Glenferrie Rd",
        value = "2906,61: Moorakyne Ave/Glenferrie Rd",
    ),
    schema.Option(
        display = "62: Mayfield Ave/Glenferrie Rd",
        value = "2907,62: Mayfield Ave/Glenferrie Rd",
    ),
    schema.Option(
        display = "63: Toorak Rd/Glenferrie Rd",
        value = "2908,63: Toorak Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "63: Toorak Rd/Glenferrie Rd",
        value = "2989,63: Toorak Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "64: Mernda Rd/Glenferrie Rd",
        value = "2910,64: Mernda Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "64: Power St/Glenferrie Rd",
        value = "2909,64: Power St/Glenferrie Rd",
    ),
    schema.Option(
        display = "65: Kooyong Stn/Glenferrie Rd",
        value = "2911,65: Kooyong Stn/Glenferrie Rd",
    ),
    schema.Option(
        display = "65: Warra St/Glenferrie Rd",
        value = "2912,65: Warra St/Glenferrie Rd",
    ),
    schema.Option(
        display = "66: Kooyong Tennis Centre/Glenferrie Rd",
        value = "2914,66: Kooyong Tennis Centre/Glenferrie Rd",
    ),
    schema.Option(
        display = "66: Vision Australia/Glenferrie Rd",
        value = "2913,66: Vision Australia/Glenferrie Rd",
    ),
    schema.Option(
        display = "67: Gardiner Rd/Glenferrie Rd",
        value = "2915,67: Gardiner Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "68: Callantina Rd/Glenferrie Rd",
        value = "2916,68: Callantina Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "69: South St/Glenferrie Rd",
        value = "2917,69: South St/Glenferrie Rd",
    ),
    schema.Option(
        display = "70: Riversdale Rd/Glenferrie Rd",
        value = "2918,70: Riversdale Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "71: Urquhart St/Glenferrie Rd",
        value = "2919,71: Urquhart St/Glenferrie Rd",
    ),
    schema.Option(
        display = "72: Manningtree Rd/Glenferrie Rd",
        value = "2920,72: Manningtree Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "73: Burwood Rd/Glenferrie Rd",
        value = "2922,73: Burwood Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "74: Glenferrie Stn/Glenferrie Rd",
        value = "2923,74: Glenferrie Stn/Glenferrie Rd",
    ),
    schema.Option(
        display = "74: Glenferrie Stn/Glenferrie Rd",
        value = "2924,74: Glenferrie Stn/Glenferrie Rd",
    ),
    schema.Option(
        display = "75: Chrystobel Cres/Glenferrie Rd",
        value = "2925,75: Chrystobel Cres/Glenferrie Rd",
    ),
    schema.Option(
        display = "75: Liddiard St/Glenferrie Rd",
        value = "2926,75: Liddiard St/Glenferrie Rd",
    ),
    schema.Option(
        display = "76: Johnson St/Glenferrie Rd",
        value = "2927,76: Johnson St/Glenferrie Rd",
    ),
    schema.Option(
        display = "77: Barkers Rd/Glenferrie Rd",
        value = "2928,77: Barkers Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "78: Fitzwilliam St/Glenferrie Rd",
        value = "2929,78: Fitzwilliam St/Glenferrie Rd",
    ),
    schema.Option(
        display = "79: Wellington St/Glenferrie Rd",
        value = "2930,79: Wellington St/Glenferrie Rd",
    ),
    schema.Option(
        display = "80: Cotham Rd/Glenferrie Rd",
        value = "2931,80: Cotham Rd/Glenferrie Rd",
    ),
    schema.Option(
        display = "131: St Kilda Rd/Fitzroy St",
        value = "2113,131: St Kilda Rd/Fitzroy St",
    ),
    schema.Option(
        display = "132: Princes St/Fitzroy St",
        value = "2126,132: Princes St/Fitzroy St",
    ),
    schema.Option(
        display = "133: Canterbury Rd/Fitzroy St",
        value = "2884,133: Canterbury Rd/Fitzroy St",
    ),
    schema.Option(
        display = "134: Park St/Fitzroy St",
        value = "2886,134: Park St/Fitzroy St",
    ),
    schema.Option(
        display = "135: Acland St/Fitzroy St",
        value = "2887,135: Acland St/Fitzroy St",
    ),
    schema.Option(
        display = "135: Jacka Bvd/Fitzroy St",
        value = "2888,135: Jacka Bvd/Fitzroy St",
    ),
    schema.Option(
        display = "136: Alfred Square/The Esplanade",
        value = "2889,136: Alfred Square/The Esplanade",
    ),
    schema.Option(
        display = "138: Luna Park/The Esplanade",
        value = "2968,138: Luna Park/The Esplanade",
    ),
]
Route19StopOptions = [
    schema.Option(
        display = "1: Flinders St Stn/Elizabeth St",
        value = "2722,1: Flinders St Stn/Elizabeth St",
    ),
    schema.Option(
        display = "2: Collins St/Elizabeth St",
        value = "2721,2: Collins St/Elizabeth St",
    ),
    schema.Option(
        display = "3: Bourke St Mall/Elizabeth St",
        value = "2720,3: Bourke St Mall/Elizabeth St",
    ),
    schema.Option(
        display = "5: Melbourne Central Stn/Elizabeth St",
        value = "2718,5: Melbourne Central Stn/Elizabeth St",
    ),
    schema.Option(
        display = "7: Queen Victoria Market/Elizabeth St",
        value = "2258,7: Queen Victoria Market/Elizabeth St",
    ),
    schema.Option(
        display = "9: Pelham St/Elizabeth St",
        value = "2714,9: Pelham St/Elizabeth St",
    ),
    schema.Option(
        display = "10: Royal Melbourne Hospital-Parkville Stn/Royal Pde",
        value = "2986,10: Royal Melbourne Hospital-Parkville Stn/Royal Pde",
    ),
    schema.Option(
        display = "10: Royal Melbourne Hospital-Parkville Stn/Royal Pde",
        value = "2822,10: Royal Melbourne Hospital-Parkville Stn/Royal Pde",
    ),
    schema.Option(
        display = "12: Morrah St/Royal Pde",
        value = "2820,12: Morrah St/Royal Pde",
    ),
    schema.Option(
        display = "13: Gatehouse St/Royal Pde",
        value = "2819,13: Gatehouse St/Royal Pde",
    ),
    schema.Option(
        display = "14: Cemetery Rd West/Royal Pde",
        value = "2817,14: Cemetery Rd West/Royal Pde",
    ),
    schema.Option(
        display = "14: Macarthur Rd/Royal Pde",
        value = "2818,14: Macarthur Rd/Royal Pde",
    ),
    schema.Option(
        display = "15: Leonard St/Royal Pde",
        value = "2816,15: Leonard St/Royal Pde",
    ),
    schema.Option(
        display = "16: Visy Park/Royal Pde",
        value = "2815,16: Visy Park/Royal Pde",
    ),
    schema.Option(
        display = "16: Walker St/Royal Pde",
        value = "2244,16: Walker St/Royal Pde",
    ),
    schema.Option(
        display = "17: Ievers St/Royal Pde",
        value = "2814,17: Ievers St/Royal Pde",
    ),
    schema.Option(
        display = "19: Brunswick Rd/Sydney Rd",
        value = "2812,19: Brunswick Rd/Sydney Rd",
    ),
    schema.Option(
        display = "20: Barkly Square/115 Sydney Rd",
        value = "2400,20: Barkly Square/115 Sydney Rd",
    ),
    schema.Option(
        display = "20: Barkly Square/Sydney Rd",
        value = "2811,20: Barkly Square/Sydney Rd",
    ),
    schema.Option(
        display = "21: Brunswick Town Hall/Sydney Rd",
        value = "2810,21: Brunswick Town Hall/Sydney Rd",
    ),
    schema.Option(
        display = "21: Glenlyon Rd/Sydney Rd",
        value = "2809,21: Glenlyon Rd/Sydney Rd",
    ),
    schema.Option(
        display = "22: Albert St/Sydney Rd",
        value = "2808,22: Albert St/Sydney Rd",
    ),
    schema.Option(
        display = "23: Victoria St/Sydney Rd",
        value = "2117,23: Victoria St/Sydney Rd",
    ),
    schema.Option(
        display = "24: Blyth St/Sydney Rd",
        value = "2133,24: Blyth St/Sydney Rd",
    ),
    schema.Option(
        display = "24: Brunswick Baptist Church/Sydney Rd",
        value = "2806,24: Brunswick Baptist Church/Sydney Rd",
    ),
    schema.Option(
        display = "25: Stewart St/Sydney Rd",
        value = "2805,25: Stewart St/Sydney Rd",
    ),
    schema.Option(
        display = "26: Albion St/Sydney Rd",
        value = "2804,26: Albion St/Sydney Rd",
    ),
    schema.Option(
        display = "27: Brunswick Tram Depot/Sydney Rd",
        value = "2119,27: Brunswick Tram Depot/Sydney Rd",
    ),
    schema.Option(
        display = "28: Moreland Rd/Sydney Rd",
        value = "2802,28: Moreland Rd/Sydney Rd",
    ),
    schema.Option(
        display = "28: Moreland Rd/Sydney Rd",
        value = "2985,28: Moreland Rd/Sydney Rd",
    ),
    schema.Option(
        display = "29: Moore St/Sydney Rd",
        value = "2801,29: Moore St/Sydney Rd",
    ),
    schema.Option(
        display = "30: The Avenue/Sydney Rd",
        value = "2002,30: The Avenue/Sydney Rd",
    ),
    schema.Option(
        display = "31: Edward St/Sydney Rd",
        value = "2632,31: Edward St/Sydney Rd",
    ),
    schema.Option(
        display = "31: Reynard St/Sydney Rd",
        value = "2798,31: Reynard St/Sydney Rd",
    ),
    schema.Option(
        display = "32: Harding St/Sydney Rd",
        value = "2796,32: Harding St/Sydney Rd",
    ),
    schema.Option(
        display = "32: Munro St/Sydney Rd",
        value = "2797,32: Munro St/Sydney Rd",
    ),
    schema.Option(
        display = "33: Coburg Market/Sydney Rd",
        value = "2795,33: Coburg Market/Sydney Rd",
    ),
    schema.Option(
        display = "34: Bell St/Sydney Rd",
        value = "2794,34: Bell St/Sydney Rd",
    ),
    schema.Option(
        display = "35: St Pauls Catholic Church/Sydney Rd",
        value = "2792,35: St Pauls Catholic Church/Sydney Rd",
    ),
    schema.Option(
        display = "36: Rogers St/Sydney Rd",
        value = "2791,36: Rogers St/Sydney Rd",
    ),
    schema.Option(
        display = "37: Gaffney St/Sydney Rd",
        value = "2984,37: Gaffney St/Sydney Rd",
    ),
    schema.Option(
        display = "37: Gaffney St/Sydney Rd",
        value = "2790,37: Gaffney St/Sydney Rd",
    ),
    schema.Option(
        display = "38: Carr St/Sydney Rd",
        value = "2983,38: Carr St/Sydney Rd",
    ),
    schema.Option(
        display = "38: Renown St/Sydney Rd",
        value = "2789,38: Renown St/Sydney Rd",
    ),
    schema.Option(
        display = "39: Mercy College/Sydney Rd",
        value = "2670,39: Mercy College/Sydney Rd",
    ),
    schema.Option(
        display = "40: North Coburg Terminus/Sydney Rd",
        value = "2786,40: North Coburg Terminus/Sydney Rd",
    ),
]
Route30StopOptions = [
    schema.Option(
        display = "1: Spencer St/La Trobe St",
        value = "3271,1: Spencer St/La Trobe St",
    ),
    schema.Option(
        display = "3: Flagstaff Stn/La Trobe St",
        value = "3325,3: Flagstaff Stn/La Trobe St",
    ),
    schema.Option(
        display = "5: Melbourne Central Stn/La Trobe St",
        value = "3114,5: Melbourne Central Stn/La Trobe St",
    ),
    schema.Option(
        display = "6: Melbourne Central & State Library Stns/La Trobe St",
        value = "2863,6: Melbourne Central & State Library Stns/La Trobe St",
    ),
    schema.Option(
        display = "8: Exhibition St/La Trobe St",
        value = "2861,8: Exhibition St/La Trobe St",
    ),
    schema.Option(
        display = "9: La Trobe St/Victoria St",
        value = "2859,9: La Trobe St/Victoria St",
    ),
    schema.Option(
        display = "9: Victoria St/La Trobe St",
        value = "2860,9: Victoria St/La Trobe St",
    ),
    schema.Option(
        display = "10: Nicholson St/Victoria Pde",
        value = "2858,10: Nicholson St/Victoria Pde",
    ),
    schema.Option(
        display = "10: Nicholson St/Victoria Pde",
        value = "2988,10: Nicholson St/Victoria Pde",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2484,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2483,12: St Vincents Plaza/Victoria Pde",
    ),
]
Route35StopOptions = [
    schema.Option(
        display = "0: Bourke St/Spring St",
        value = "2013,0: Bourke St/Spring St",
    ),
    schema.Option(
        display = "1: Spencer St/Flinders St",
        value = "3318,1: Spencer St/Flinders St",
    ),
    schema.Option(
        display = "1: Spencer St/La Trobe St",
        value = "3271,1: Spencer St/La Trobe St",
    ),
    schema.Option(
        display = "2: Melbourne Aquarium/Flinders St",
        value = "3317,2: Melbourne Aquarium/Flinders St",
    ),
    schema.Option(
        display = "3: Flagstaff Stn/La Trobe St",
        value = "3325,3: Flagstaff Stn/La Trobe St",
    ),
    schema.Option(
        display = "3: Market St/Flinders St",
        value = "2092,3: Market St/Flinders St",
    ),
    schema.Option(
        display = "4: Elizabeth St/Flinders St",
        value = "2095,4: Elizabeth St/Flinders St",
    ),
    schema.Option(
        display = "5: Melbourne Central Stn/La Trobe St",
        value = "3114,5: Melbourne Central Stn/La Trobe St",
    ),
    schema.Option(
        display = "5: Swanston St/Flinders St",
        value = "2096,5: Swanston St/Flinders St",
    ),
    schema.Option(
        display = "6: Melbourne Central & State Library Stns/La Trobe St",
        value = "2863,6: Melbourne Central & State Library Stns/La Trobe St",
    ),
    schema.Option(
        display = "6: Russell St/Flinders St",
        value = "2097,6: Russell St/Flinders St",
    ),
    schema.Option(
        display = "8: Exhibition St/La Trobe St",
        value = "2861,8: Exhibition St/La Trobe St",
    ),
    schema.Option(
        display = "8: Spring St/Flinders St",
        value = "2877,8: Spring St/Flinders St",
    ),
    schema.Option(
        display = "9: Victoria St/La Trobe St",
        value = "2860,9: Victoria St/La Trobe St",
    ),
    schema.Option(
        display = "10: Albert St/Nicholson St",
        value = "2005,10: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "10: Nicholson St/Victoria Pde",
        value = "2858,10: Nicholson St/Victoria Pde",
    ),
]
Route48StopOptions = [
    schema.Option(
        display = "1: Spencer St/Collins St",
        value = "2496,1: Spencer St/Collins St",
    ),
    schema.Option(
        display = "3: William St/Collins St",
        value = "2494,3: William St/Collins St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Collins St",
        value = "2492,5: Elizabeth St/Collins St",
    ),
    schema.Option(
        display = "6: Melbourne Town Hall/Collins St",
        value = "2491,6: Melbourne Town Hall/Collins St",
    ),
    schema.Option(
        display = "7: Exhibition St/Collins St",
        value = "2174,7: Exhibition St/Collins St",
    ),
    schema.Option(
        display = "8: Spring St/Collins St",
        value = "2488,8: Spring St/Collins St",
    ),
    schema.Option(
        display = "9: Lansdowne St/Wellington Pde",
        value = "3123,9: Lansdowne St/Wellington Pde",
    ),
    schema.Option(
        display = "9: Lansdowne St/Wellington Pde",
        value = "3041,9: Lansdowne St/Wellington Pde",
    ),
    schema.Option(
        display = "10: Jolimont Rd/Wellington Pde",
        value = "2823,10: Jolimont Rd/Wellington Pde",
    ),
    schema.Option(
        display = "11: Jolimont Stn-MCG/Wellington Pde",
        value = "2825,11: Jolimont Stn-MCG/Wellington Pde",
    ),
    schema.Option(
        display = "13: Simpson St/Wellington Pde",
        value = "2826,13: Simpson St/Wellington Pde",
    ),
    schema.Option(
        display = "14: Punt Rd/Bridge Rd",
        value = "2827,14: Punt Rd/Bridge Rd",
    ),
    schema.Option(
        display = "14: Punt Rd/Wellington Pde",
        value = "3000,14: Punt Rd/Wellington Pde",
    ),
    schema.Option(
        display = "15: Epworth Hospital/Bridge Rd",
        value = "3001,15: Epworth Hospital/Bridge Rd",
    ),
    schema.Option(
        display = "17: Bosisto St/Bridge Rd",
        value = "3002,17: Bosisto St/Bridge Rd",
    ),
    schema.Option(
        display = "17: Waltham St/Bridge Rd",
        value = "3315,17: Waltham St/Bridge Rd",
    ),
    schema.Option(
        display = "18: Church St/Bridge Rd",
        value = "2829,18: Church St/Bridge Rd",
    ),
    schema.Option(
        display = "19: Richmond Town Hall/Bridge Rd",
        value = "3003,19: Richmond Town Hall/Bridge Rd",
    ),
    schema.Option(
        display = "20: Coppin St/Bridge Rd",
        value = "2999,20: Coppin St/Bridge Rd",
    ),
    schema.Option(
        display = "21: Burnley St/Bridge Rd",
        value = "3004,21: Burnley St/Bridge Rd",
    ),
    schema.Option(
        display = "22: Yarra Bvd/Bridge Rd",
        value = "3005,22: Yarra Bvd/Bridge Rd",
    ),
    schema.Option(
        display = "23: Hawthorn Bridge/Bridge Rd",
        value = "2416,23: Hawthorn Bridge/Bridge Rd",
    ),
    schema.Option(
        display = "24: Grattan St/Church St",
        value = "2881,24: Grattan St/Church St",
    ),
    schema.Option(
        display = "24: Hill St/Church St",
        value = "2880,24: Hill St/Church St",
    ),
    schema.Option(
        display = "25: Brook St/Church St",
        value = "2879,25: Brook St/Church St",
    ),
    schema.Option(
        display = "26: Barkers Rd/Church St",
        value = "2878,26: Barkers Rd/Church St",
    ),
    schema.Option(
        display = "29: Barkers Rd/High St",
        value = "2450,29: Barkers Rd/High St",
    ),
    schema.Option(
        display = "31: Stevenson St/High St",
        value = "2447,31: Stevenson St/High St",
    ),
    schema.Option(
        display = "32: Kew Jct/High St",
        value = "2444,32: Kew Jct/High St",
    ),
    schema.Option(
        display = "33: Kew Shopping Centre/High St",
        value = "2445,33: Kew Shopping Centre/High St",
    ),
    schema.Option(
        display = "34: Pakington St/High St",
        value = "2857,34: Pakington St/High St",
    ),
    schema.Option(
        display = "34: Union St/High St",
        value = "2856,34: Union St/High St",
    ),
    schema.Option(
        display = "35: Charles St/High St",
        value = "2854,35: Charles St/High St",
    ),
    schema.Option(
        display = "35: Cobden St/High St",
        value = "2855,35: Cobden St/High St",
    ),
    schema.Option(
        display = "36: Gladstone St/High St",
        value = "2852,36: Gladstone St/High St",
    ),
    schema.Option(
        display = "36: Parkhill Rd/High St",
        value = "2853,36: Parkhill Rd/High St",
    ),
    schema.Option(
        display = "37: Kew Cemetery/High St",
        value = "2259,37: Kew Cemetery/High St",
    ),
    schema.Option(
        display = "38: Victoria Park/High St",
        value = "2850,38: Victoria Park/High St",
    ),
    schema.Option(
        display = "38: Victoria Park/High St",
        value = "2987,38: Victoria Park/High St",
    ),
    schema.Option(
        display = "39: Harp Rd/High St",
        value = "2849,39: Harp Rd/High St",
    ),
    schema.Option(
        display = "39: Harp Rd/High St",
        value = "2848,39: Harp Rd/High St",
    ),
    schema.Option(
        display = "40: Harp Village/High St",
        value = "2847,40: Harp Village/High St",
    ),
    schema.Option(
        display = "41: Clyde St/High St",
        value = "2160,41: Clyde St/High St",
    ),
    schema.Option(
        display = "41: Station St/High St",
        value = "2846,41: Station St/High St",
    ),
    schema.Option(
        display = "42: Irymple Ave/High St",
        value = "2845,42: Irymple Ave/High St",
    ),
    schema.Option(
        display = "42: Woodlands Ave/High St",
        value = "2844,42: Woodlands Ave/High St",
    ),
    schema.Option(
        display = "43: Kew High School/High St",
        value = "2843,43: Kew High School/High St",
    ),
    schema.Option(
        display = "44: Burke Rd/Doncaster Rd",
        value = "3399,44: Burke Rd/Doncaster Rd",
    ),
    schema.Option(
        display = "44: Burke Rd/High St",
        value = "2842,44: Burke Rd/High St",
    ),
    schema.Option(
        display = "46: Wattle Ave/Doncaster Rd",
        value = "2839,46: Wattle Ave/Doncaster Rd",
    ),
    schema.Option(
        display = "47: North Balwyn Shopping Centre/Doncaster Rd",
        value = "2837,47: North Balwyn Shopping Centre/Doncaster Rd",
    ),
    schema.Option(
        display = "48: Osburn Ave/Doncaster Rd",
        value = "2835,48: Osburn Ave/Doncaster Rd",
    ),
    schema.Option(
        display = "48: Sunburst Ave/Doncaster Rd",
        value = "2836,48: Sunburst Ave/Doncaster Rd",
    ),
    schema.Option(
        display = "49: Buchanan Ave/Doncaster Rd",
        value = "2833,49: Buchanan Ave/Doncaster Rd",
    ),
    schema.Option(
        display = "49: Cityview Rd/Doncaster Rd",
        value = "2834,49: Cityview Rd/Doncaster Rd",
    ),
    schema.Option(
        display = "50: Dight Ave/Doncaster Rd",
        value = "2831,50: Dight Ave/Doncaster Rd",
    ),
    schema.Option(
        display = "50: Hill Rd/Doncaster Rd",
        value = "2832,50: Hill Rd/Doncaster Rd",
    ),
    schema.Option(
        display = "51: Balwyn Rd/Doncaster Rd",
        value = "2830,51: Balwyn Rd/Doncaster Rd",
    ),
]
Route57StopOptions = [
    schema.Option(
        display = "1: Flinders St Stn/Elizabeth St",
        value = "2722,1: Flinders St Stn/Elizabeth St",
    ),
    schema.Option(
        display = "2: Collins St/Elizabeth St",
        value = "2721,2: Collins St/Elizabeth St",
    ),
    schema.Option(
        display = "3: Bourke St Mall/Elizabeth St",
        value = "2720,3: Bourke St Mall/Elizabeth St",
    ),
    schema.Option(
        display = "5: Melbourne Central Stn/Elizabeth St",
        value = "2718,5: Melbourne Central Stn/Elizabeth St",
    ),
    schema.Option(
        display = "7: Queen Victoria Market/Elizabeth St",
        value = "2258,7: Queen Victoria Market/Elizabeth St",
    ),
    schema.Option(
        display = "8: Peel St/Victoria St",
        value = "3122,8: Peel St/Victoria St",
    ),
    schema.Option(
        display = "9: Howard St/Victoria St",
        value = "3121,9: Howard St/Victoria St",
    ),
    schema.Option(
        display = "9: Pelham St/Elizabeth St",
        value = "2714,9: Pelham St/Elizabeth St",
    ),
    schema.Option(
        display = "9: William St/Victoria St",
        value = "3120,9: William St/Victoria St",
    ),
    schema.Option(
        display = "10: Chetwynd St/Victoria St",
        value = "3164,10: Chetwynd St/Victoria St",
    ),
    schema.Option(
        display = "11: Errol St/Victoria St",
        value = "3163,11: Errol St/Victoria St",
    ),
    schema.Option(
        display = "11: Victoria St/Errol St",
        value = "3162,11: Victoria St/Errol St",
    ),
    schema.Option(
        display = "12: North Melbourne Town Hall/Errol St",
        value = "3160,12: North Melbourne Town Hall/Errol St",
    ),
    schema.Option(
        display = "12: North Melbourne Town Hall/Queensberry St",
        value = "3161,12: North Melbourne Town Hall/Queensberry St",
    ),
    schema.Option(
        display = "13: Curzon St/Queensberry St",
        value = "3159,13: Curzon St/Queensberry St",
    ),
    schema.Option(
        display = "14: Abbotsford St/Queensberry St",
        value = "3158,14: Abbotsford St/Queensberry St",
    ),
    schema.Option(
        display = "14: Queensberry St/Abbotsford St",
        value = "3157,14: Queensberry St/Abbotsford St",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2712,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2711,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "15: Arden St/Abbotsford St",
        value = "3156,15: Arden St/Abbotsford St",
    ),
    schema.Option(
        display = "15: Murphy St/Flemington Rd",
        value = "3311,15: Murphy St/Flemington Rd",
    ),
    schema.Option(
        display = "16: Haines St/Abbotsford St",
        value = "3155,16: Haines St/Abbotsford St",
    ),
    schema.Option(
        display = "19: Abbotsford St Interchange/Abbotsford St",
        value = "3149,19: Abbotsford St Interchange/Abbotsford St",
    ),
    schema.Option(
        display = "19: Royal Childrens Hospital/Flemington Rd",
        value = "2707,19: Royal Childrens Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "20: Melrose St/Flemington Rd",
        value = "2706,20: Melrose St/Flemington Rd",
    ),
    schema.Option(
        display = "22: Boundary Rd/Racecourse Rd",
        value = "3148,22: Boundary Rd/Racecourse Rd",
    ),
    schema.Option(
        display = "23: Stubbs St/Racecourse Rd",
        value = "3147,23: Stubbs St/Racecourse Rd",
    ),
    schema.Option(
        display = "24: Collett St/Racecourse Rd",
        value = "3146,24: Collett St/Racecourse Rd",
    ),
    schema.Option(
        display = "24: Victoria St/Racecourse Rd",
        value = "3145,24: Victoria St/Racecourse Rd",
    ),
    schema.Option(
        display = "25: Wellington St/Racecourse Rd",
        value = "3144,25: Wellington St/Racecourse Rd",
    ),
    schema.Option(
        display = "26: Newmarket Plaza/Racecourse Rd",
        value = "3142,26: Newmarket Plaza/Racecourse Rd",
    ),
    schema.Option(
        display = "26: Newmarket Plaza/Racecourse Rd",
        value = "3143,26: Newmarket Plaza/Racecourse Rd",
    ),
    schema.Option(
        display = "28: Smithfield Rd/Racecourse Rd",
        value = "3141,28: Smithfield Rd/Racecourse Rd",
    ),
    schema.Option(
        display = "29: Flemington Racecourse/Racecourse Rd",
        value = "3139,29: Flemington Racecourse/Racecourse Rd",
    ),
    schema.Option(
        display = "30: Flemington Racecourse/Epsom Rd",
        value = "3137,30: Flemington Racecourse/Epsom Rd",
    ),
    schema.Option(
        display = "30: Flemington Racecourse/Epsom Rd",
        value = "3138,30: Flemington Racecourse/Epsom Rd",
    ),
    schema.Option(
        display = "31: Racing Victoria/161 Epsom Rd",
        value = "3136,31: Racing Victoria/161 Epsom Rd",
    ),
    schema.Option(
        display = "31: Racing Victoria/400 Epsom Rd",
        value = "3135,31: Racing Victoria/400 Epsom Rd",
    ),
    schema.Option(
        display = "32: Sandown Rd/Epsom Rd",
        value = "3133,32: Sandown Rd/Epsom Rd",
    ),
    schema.Option(
        display = "33: Melbourne Showgrounds/Union Rd",
        value = "3132,33: Melbourne Showgrounds/Union Rd",
    ),
    schema.Option(
        display = "34: Burrowes St/Union Rd",
        value = "3130,34: Burrowes St/Union Rd",
    ),
    schema.Option(
        display = "35: Bloomfield Rd/Union Rd",
        value = "3129,35: Bloomfield Rd/Union Rd",
    ),
    schema.Option(
        display = "35: Munro St/Union Rd",
        value = "3128,35: Munro St/Union Rd",
    ),
    schema.Option(
        display = "36: St Leonards Rd/Union Rd",
        value = "3127,36: St Leonards Rd/Union Rd",
    ),
    schema.Option(
        display = "37: Maribyrnong Rd/Union Rd",
        value = "3125,37: Maribyrnong Rd/Union Rd",
    ),
    schema.Option(
        display = "37: Union Rd/Maribyrnong Rd",
        value = "2390,37: Union Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "38: Ferguson St/Maribyrnong Rd",
        value = "2389,38: Ferguson St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "38: Hotham St/Maribyrnong Rd",
        value = "2388,38: Hotham St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "39: Bowen St/Maribyrnong Rd",
        value = "2387,39: Bowen St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "40: Epsom Rd/Maribyrnong Rd",
        value = "2385,40: Epsom Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "40: Epsom Rd/Maribyrnong Rd",
        value = "2386,40: Epsom Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "41: Maribyrnong Park/Maribyrnong Rd",
        value = "2383,41: Maribyrnong Park/Maribyrnong Rd",
    ),
    schema.Option(
        display = "42: Clyde St/Raleigh Rd",
        value = "2382,42: Clyde St/Raleigh Rd",
    ),
    schema.Option(
        display = "43: Van Ness Ave/Raleigh Rd",
        value = "2381,43: Van Ness Ave/Raleigh Rd",
    ),
    schema.Option(
        display = "44: Barb St/Raleigh Rd",
        value = "2379,44: Barb St/Raleigh Rd",
    ),
    schema.Option(
        display = "44: Warrs Rd/Raleigh Rd",
        value = "2380,44: Warrs Rd/Raleigh Rd",
    ),
    schema.Option(
        display = "45: Maribyrnong Community Centre/Raleigh Rd",
        value = "2378,45: Maribyrnong Community Centre/Raleigh Rd",
    ),
    schema.Option(
        display = "45: Randall St/Raleigh Rd",
        value = "2001,45: Randall St/Raleigh Rd",
    ),
    schema.Option(
        display = "46: Rosamond Rd/Raleigh Rd",
        value = "2377,46: Rosamond Rd/Raleigh Rd",
    ),
    schema.Option(
        display = "48: Wests Rd/Cordite Ave",
        value = "2396,48: Wests Rd/Cordite Ave",
    ),
    schema.Option(
        display = "48: Wests Rd/Raleigh Rd",
        value = "2376,48: Wests Rd/Raleigh Rd",
    ),
    schema.Option(
        display = "49: Central Park Ave/Cordite Ave",
        value = "3126,49: Central Park Ave/Cordite Ave",
    ),
]
Route58StopOptions = [
    schema.Option(
        display = "1: Flinders St/Queens Bridge St",
        value = "3111,1: Flinders St/Queens Bridge St",
    ),
    schema.Option(
        display = "4: Collins St/William St",
        value = "3107,4: Collins St/William St",
    ),
    schema.Option(
        display = "5: Bourke St/William St",
        value = "3106,5: Bourke St/William St",
    ),
    schema.Option(
        display = "7: Flagstaff Stn/William St",
        value = "3104,7: Flagstaff Stn/William St",
    ),
    schema.Option(
        display = "9: Queen Victoria Market/39 Peel St",
        value = "3101,9: Queen Victoria Market/39 Peel St",
    ),
    schema.Option(
        display = "9: Queen Victoria Market/Peel St",
        value = "2267,9: Queen Victoria Market/Peel St",
    ),
    schema.Option(
        display = "10: Victoria St/Peel St",
        value = "3100,10: Victoria St/Peel St",
    ),
    schema.Option(
        display = "11: Queensberry St/Peel St",
        value = "3329,11: Queensberry St/Peel St",
    ),
    schema.Option(
        display = "12: Flemington Rd/Peel St",
        value = "3328,12: Flemington Rd/Peel St",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2711,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2712,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "15: Murphy St/Flemington Rd",
        value = "3311,15: Murphy St/Flemington Rd",
    ),
    schema.Option(
        display = "19: Royal Childrens Hospital/Flemington Rd",
        value = "2707,19: Royal Childrens Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Elliott Ave/Royal Park",
        value = "2556,24: Elliott Ave/Royal Park",
    ),
    schema.Option(
        display = "25: State Netball Hockey Centre/Royal Park",
        value = "3097,25: State Netball Hockey Centre/Royal Park",
    ),
    schema.Option(
        display = "26: Melbourne Zoo/Royal Park",
        value = "2697,26: Melbourne Zoo/Royal Park",
    ),
    schema.Option(
        display = "27: Royal Park Stn/Royal Park",
        value = "2146,27: Royal Park Stn/Royal Park",
    ),
    schema.Option(
        display = "28: Park St/Royal Park",
        value = "2170,28: Park St/Royal Park",
    ),
    schema.Option(
        display = "29: Brunswick Rd/Grantham St",
        value = "3222,29: Brunswick Rd/Grantham St",
    ),
    schema.Option(
        display = "29: Heller St/Grantham St",
        value = "3324,29: Heller St/Grantham St",
    ),
    schema.Option(
        display = "30: Union Square Shopping Centre/Grantham St",
        value = "3093,30: Union Square Shopping Centre/Grantham St",
    ),
    schema.Option(
        display = "31: Dawson St/Grantham St",
        value = "3091,31: Dawson St/Grantham St",
    ),
    schema.Option(
        display = "31: Grantham St/Dawson St",
        value = "3092,31: Grantham St/Dawson St",
    ),
    schema.Option(
        display = "33: Daly St/Dawson St",
        value = "3089,33: Daly St/Dawson St",
    ),
    schema.Option(
        display = "33: South Daly St/Dawson St",
        value = "3194,33: South Daly St/Dawson St",
    ),
    schema.Option(
        display = "34: Smith St/Melville Rd",
        value = "3165,34: Smith St/Melville Rd",
    ),
    schema.Option(
        display = "34: Smith St/Melville Rd",
        value = "3088,34: Smith St/Melville Rd",
    ),
    schema.Option(
        display = "35: Victoria St/Melville Rd",
        value = "3087,35: Victoria St/Melville Rd",
    ),
    schema.Option(
        display = "36: Hope St/Melville Rd",
        value = "3086,36: Hope St/Melville Rd",
    ),
    schema.Option(
        display = "37: Albion St/Melville Rd",
        value = "3085,37: Albion St/Melville Rd",
    ),
    schema.Option(
        display = "38: Jacobs Reserve/Melville Rd",
        value = "3084,38: Jacobs Reserve/Melville Rd",
    ),
    schema.Option(
        display = "40: Moreland Rd/Melville Rd",
        value = "3081,40: Moreland Rd/Melville Rd",
    ),
    schema.Option(
        display = "41: Woodlands Ave/Melville Rd",
        value = "3079,41: Woodlands Ave/Melville Rd",
    ),
    schema.Option(
        display = "42: Reynard St/Melville Rd",
        value = "3078,42: Reynard St/Melville Rd",
    ),
    schema.Option(
        display = "43: Princes Tce/Melville Rd",
        value = "3077,43: Princes Tce/Melville Rd",
    ),
    schema.Option(
        display = "44: Brearley Pde/Melville Rd",
        value = "3076,44: Brearley Pde/Melville Rd",
    ),
    schema.Option(
        display = "45: Bell St/Melville Rd",
        value = "3075,45: Bell St/Melville Rd",
    ),
    schema.Option(
        display = "115: Casino/Southbank/Queens Bridge St",
        value = "3007,115: Casino/Southbank/Queens Bridge St",
    ),
    schema.Option(
        display = "116: City Rd/Kings Way",
        value = "3116,116: City Rd/Kings Way",
    ),
    schema.Option(
        display = "117: York St/Kings Way",
        value = "3117,117: York St/Kings Way",
    ),
    schema.Option(
        display = "118: Sturt St/Kings Way",
        value = "3118,118: Sturt St/Kings Way",
    ),
    schema.Option(
        display = "119: Wells St/Park St",
        value = "3119,119: Wells St/Park St",
    ),
    schema.Option(
        display = "123: Fawkner Park/Toorak Rd",
        value = "2253,123: Fawkner Park/Toorak Rd",
    ),
    schema.Option(
        display = "124: Walsh St/Toorak Rd",
        value = "2192,124: Walsh St/Toorak Rd",
    ),
    schema.Option(
        display = "125: Punt Rd/Toorak Rd",
        value = "2191,125: Punt Rd/Toorak Rd",
    ),
    schema.Option(
        display = "127: South Yarra Stn/Toorak Rd",
        value = "2189,127: South Yarra Stn/Toorak Rd",
    ),
    schema.Option(
        display = "128: Chapel St/Toorak Rd",
        value = "2188,128: Chapel St/Toorak Rd",
    ),
    schema.Option(
        display = "129: Tivoli Rd/Toorak Rd",
        value = "2187,129: Tivoli Rd/Toorak Rd",
    ),
    schema.Option(
        display = "130: Hawksburn Rd/Toorak Rd",
        value = "2186,130: Hawksburn Rd/Toorak Rd",
    ),
    schema.Option(
        display = "131: Williams Rd/Toorak Rd",
        value = "2242,131: Williams Rd/Toorak Rd",
    ),
    schema.Option(
        display = "131: Williams Rd/Toorak Rd",
        value = "2185,131: Williams Rd/Toorak Rd",
    ),
    schema.Option(
        display = "132: Toorak Village/Toorak Rd",
        value = "2184,132: Toorak Village/Toorak Rd",
    ),
    schema.Option(
        display = "133: Canterbury Rd/Toorak Rd",
        value = "2254,133: Canterbury Rd/Toorak Rd",
    ),
    schema.Option(
        display = "133: Grange Rd/Toorak Rd",
        value = "2183,133: Grange Rd/Toorak Rd",
    ),
    schema.Option(
        display = "134: Orrong Rd/Toorak Rd",
        value = "2182,134: Orrong Rd/Toorak Rd",
    ),
    schema.Option(
        display = "135: Woorigoleen Rd/Toorak Rd",
        value = "2181,135: Woorigoleen Rd/Toorak Rd",
    ),
    schema.Option(
        display = "136: Irving Rd/Toorak Rd",
        value = "2180,136: Irving Rd/Toorak Rd",
    ),
    schema.Option(
        display = "137: Kooyong Rd/Toorak Rd",
        value = "2179,137: Kooyong Rd/Toorak Rd",
    ),
    schema.Option(
        display = "138: Moonga Rd/Toorak Rd",
        value = "2178,138: Moonga Rd/Toorak Rd",
    ),
    schema.Option(
        display = "139: Glenbervie Rd/Toorak Rd",
        value = "2142,139: Glenbervie Rd/Toorak Rd",
    ),
    schema.Option(
        display = "139: Glenferrie Rd/Toorak Rd",
        value = "2056,139: Glenferrie Rd/Toorak Rd",
    ),
]
Route59StopOptions = [
    schema.Option(
        display = "1: Flinders St Stn/Elizabeth St",
        value = "2722,1: Flinders St Stn/Elizabeth St",
    ),
    schema.Option(
        display = "2: Collins St/Elizabeth St",
        value = "2721,2: Collins St/Elizabeth St",
    ),
    schema.Option(
        display = "3: Bourke St Mall/Elizabeth St",
        value = "2720,3: Bourke St Mall/Elizabeth St",
    ),
    schema.Option(
        display = "5: Melbourne Central Stn/Elizabeth St",
        value = "2718,5: Melbourne Central Stn/Elizabeth St",
    ),
    schema.Option(
        display = "7: Queen Victoria Market/Elizabeth St",
        value = "2258,7: Queen Victoria Market/Elizabeth St",
    ),
    schema.Option(
        display = "9: Pelham St/Elizabeth St",
        value = "2714,9: Pelham St/Elizabeth St",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2711,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "14: Royal Melbourne Hospital/Flemington Rd",
        value = "2712,14: Royal Melbourne Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "15: Murphy St/Flemington Rd",
        value = "3311,15: Murphy St/Flemington Rd",
    ),
    schema.Option(
        display = "19: Royal Childrens Hospital/Flemington Rd",
        value = "2707,19: Royal Childrens Hospital/Flemington Rd",
    ),
    schema.Option(
        display = "20: Melrose St/Flemington Rd",
        value = "2706,20: Melrose St/Flemington Rd",
    ),
    schema.Option(
        display = "22: Flemington Bridge Stn/Flemington Rd",
        value = "2281,22: Flemington Bridge Stn/Flemington Rd",
    ),
    schema.Option(
        display = "23: Flemington Community Centre/Mt Alexander Rd",
        value = "2702,23: Flemington Community Centre/Mt Alexander Rd",
    ),
    schema.Option(
        display = "24: Mooltan St/Mt Alexander Rd",
        value = "2700,24: Mooltan St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "25: Mount Alexander College/Mt Alexander Rd",
        value = "2699,25: Mount Alexander College/Mt Alexander Rd",
    ),
    schema.Option(
        display = "25: Mount Alexander College/Mt Alexander Rd",
        value = "3390,25: Mount Alexander College/Mt Alexander Rd",
    ),
    schema.Option(
        display = "26: Wellington St/Mt Alexander Rd",
        value = "2698,26: Wellington St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "27: Essendon Tram Depot/Mt Alexander Rd",
        value = "2689,27: Essendon Tram Depot/Mt Alexander Rd",
    ),
    schema.Option(
        display = "28: Middle St/Mt Alexander Rd",
        value = "2694,28: Middle St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "29: Warrick St/Mt Alexander Rd",
        value = "2480,29: Warrick St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "30: Maribyrnong Rd/Mt Alexander Rd",
        value = "2691,30: Maribyrnong Rd/Mt Alexander Rd",
    ),
    schema.Option(
        display = "30: Ormond Rd/Mt Alexander Rd",
        value = "2690,30: Ormond Rd/Mt Alexander Rd",
    ),
    schema.Option(
        display = "31: Montgomery St/Mt Alexander Rd",
        value = "2688,31: Montgomery St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "32: Moonee Ponds Jct/Pascoe Vale Rd",
        value = "2685,32: Moonee Ponds Jct/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "34: Moonee Valley Civic Centre/Pascoe Vale Rd",
        value = "2683,34: Moonee Valley Civic Centre/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "35: Queens Park/Pascoe Vale Rd",
        value = "2682,35: Queens Park/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "36: Murray St/Pascoe Vale Rd",
        value = "2681,36: Murray St/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "36: Salisbury St/Pascoe Vale Rd",
        value = "2680,36: Salisbury St/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "37: Buckley St/Pascoe Vale Rd",
        value = "2772,37: Buckley St/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "37: Buckley St/Pascoe Vale Rd",
        value = "2679,37: Buckley St/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "38: Fletcher St/Pascoe Vale Rd",
        value = "2678,38: Fletcher St/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "38: Pascoe Vale Rd/Fletcher St",
        value = "2677,38: Pascoe Vale Rd/Fletcher St",
    ),
    schema.Option(
        display = "39: Hoddle St/Fletcher St",
        value = "2676,39: Hoddle St/Fletcher St",
    ),
    schema.Option(
        display = "40: Nicholson St/Fletcher St",
        value = "2675,40: Nicholson St/Fletcher St",
    ),
    schema.Option(
        display = "41: Fletcher St/Napier St",
        value = "2674,41: Fletcher St/Napier St",
    ),
    schema.Option(
        display = "42: Grice Cres/Mt Alexander Rd",
        value = "2478,42: Grice Cres/Mt Alexander Rd",
    ),
    schema.Option(
        display = "42: Shamrock St/Mt Alexander Rd",
        value = "2673,42: Shamrock St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "43: Brewster St/Mt Alexander Rd",
        value = "2671,43: Brewster St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "43: Thistle St/Mt Alexander Rd",
        value = "2672,43: Thistle St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "44: Thorn St/Mt Alexander Rd",
        value = "2669,44: Thorn St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "45: Glass St/Mt Alexander Rd",
        value = "2667,45: Glass St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "45: Leake St/Mt Alexander Rd",
        value = "2750,45: Leake St/Mt Alexander Rd",
    ),
    schema.Option(
        display = "46: Lincoln Rd/Mt Alexander Rd",
        value = "2666,46: Lincoln Rd/Mt Alexander Rd",
    ),
    schema.Option(
        display = "47: Mt Alexander Rd/Keilor Rd",
        value = "2664,47: Mt Alexander Rd/Keilor Rd",
    ),
    schema.Option(
        display = "48: Service St/Keilor Rd",
        value = "2980,48: Service St/Keilor Rd",
    ),
    schema.Option(
        display = "48: Service St/Keilor Rd",
        value = "2663,48: Service St/Keilor Rd",
    ),
    schema.Option(
        display = "49: Essendon North PS/Keilor Rd",
        value = "2443,49: Essendon North PS/Keilor Rd",
    ),
    schema.Option(
        display = "49: Essendon North Primary School/Keilor Rd",
        value = "2662,49: Essendon North Primary School/Keilor Rd",
    ),
    schema.Option(
        display = "50: Cooper St/Keilor Rd",
        value = "2661,50: Cooper St/Keilor Rd",
    ),
    schema.Option(
        display = "50: Cooper St/Keilor Rd",
        value = "2660,50: Cooper St/Keilor Rd",
    ),
    schema.Option(
        display = "51: Bradshaw St/Keilor Rd",
        value = "2659,51: Bradshaw St/Keilor Rd",
    ),
    schema.Option(
        display = "52: Hoffmans Rd/Keilor Rd",
        value = "2785,52: Hoffmans Rd/Keilor Rd",
    ),
    schema.Option(
        display = "52: Treadwell Rd/Keilor Rd",
        value = "2788,52: Treadwell Rd/Keilor Rd",
    ),
    schema.Option(
        display = "53: Keilor Rd/Matthews Ave",
        value = "2657,53: Keilor Rd/Matthews Ave",
    ),
    schema.Option(
        display = "54: Fullarton Rd/Matthews Ave",
        value = "2655,54: Fullarton Rd/Matthews Ave",
    ),
    schema.Option(
        display = "54: Fullarton Rd/Matthews Ave",
        value = "2656,54: Fullarton Rd/Matthews Ave",
    ),
    schema.Option(
        display = "55: Cameron St/Matthews Ave",
        value = "2654,55: Cameron St/Matthews Ave",
    ),
    schema.Option(
        display = "56: Earl St/Matthews Ave",
        value = "2652,56: Earl St/Matthews Ave",
    ),
    schema.Option(
        display = "57: Hawker St/Matthews Ave",
        value = "2651,57: Hawker St/Matthews Ave",
    ),
    schema.Option(
        display = "58: Marshall Rd/Matthews Ave",
        value = "2650,58: Marshall Rd/Matthews Ave",
    ),
    schema.Option(
        display = "59: Airport West/Matthews Ave",
        value = "2649,59: Airport West/Matthews Ave",
    ),
]
Route64StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "29: Union St/St Kilda Rd",
        value = "2403,29: Union St/St Kilda Rd",
    ),
    schema.Option(
        display = "30: St Kilda Jct/St Kilda Rd",
        value = "2401,30: St Kilda Jct/St Kilda Rd",
    ),
    schema.Option(
        display = "31: Queens Way/Queens Way",
        value = "2975,31: Queens Way/Queens Way",
    ),
    schema.Option(
        display = "31: Queens Way/Queens Way",
        value = "2605,31: Queens Way/Queens Way",
    ),
    schema.Option(
        display = "32: Chapel St/Dandenong Rd",
        value = "2604,32: Chapel St/Dandenong Rd",
    ),
    schema.Option(
        display = "33: Hornby St/Dandenong Rd",
        value = "2603,33: Hornby St/Dandenong Rd",
    ),
    schema.Option(
        display = "34: The Avenue/Dandenong Rd",
        value = "2602,34: The Avenue/Dandenong Rd",
    ),
    schema.Option(
        display = "34: Westbury St/Dandenong Rd",
        value = "2601,34: Westbury St/Dandenong Rd",
    ),
    schema.Option(
        display = "35: Williams Rd/Dandenong Rd",
        value = "2599,35: Williams Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "36: Alexandra St/Dandenong Rd",
        value = "2597,36: Alexandra St/Dandenong Rd",
    ),
    schema.Option(
        display = "36: Closeburn Ave/Dandenong Rd",
        value = "2598,36: Closeburn Ave/Dandenong Rd",
    ),
    schema.Option(
        display = "37: Lansdowne Rd/Dandenong Rd",
        value = "2596,37: Lansdowne Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "37: Lansdowne Rd/Dandenong Rd",
        value = "2621,37: Lansdowne Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "38: Orrong Rd/Dandenong Rd",
        value = "2595,38: Orrong Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "38: Orrong Rd/Dandenong Rd",
        value = "2623,38: Orrong Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "40: Wattletree Rd/Dandenong Rd",
        value = "2593,40: Wattletree Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "42: Kooyong Rd/Dandenong Rd",
        value = "2770,42: Kooyong Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "43: Egerton Rd/Dandenong Rd",
        value = "2769,43: Egerton Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "43: Matlock Ct/Dandenong Rd",
        value = "2768,43: Matlock Ct/Dandenong Rd",
    ),
    schema.Option(
        display = "44: Bailey Ave/Dandenong Rd",
        value = "2767,44: Bailey Ave/Dandenong Rd",
    ),
    schema.Option(
        display = "48: Hawthorn Rd/Dandenong Rd",
        value = "2464,48: Hawthorn Rd/Dandenong Rd",
    ),
    schema.Option(
        display = "49: Arthur St/Hawthorn Rd",
        value = "2725,49: Arthur St/Hawthorn Rd",
    ),
    schema.Option(
        display = "49: Wanda Rd/Hawthorn Rd",
        value = "2724,49: Wanda Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "50: Inkerman Rd/Hawthorn Rd",
        value = "2726,50: Inkerman Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "51: Balaclava Rd/Hawthorn Rd",
        value = "2727,51: Balaclava Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "52: Halstead St/Hawthorn Rd",
        value = "2764,52: Halstead St/Hawthorn Rd",
    ),
    schema.Option(
        display = "53: Crotonhurst Ave/Hawthorn Rd",
        value = "2762,53: Crotonhurst Ave/Hawthorn Rd",
    ),
    schema.Option(
        display = "53: Northcote Ave/Hawthorn Rd",
        value = "2763,53: Northcote Ave/Hawthorn Rd",
    ),
    schema.Option(
        display = "54: Glen Eira Rd/Hawthorn Rd",
        value = "2982,54: Glen Eira Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "54: Glen Eira Rd/Hawthorn Rd",
        value = "2761,54: Glen Eira Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "55: Sylverly Gr/Hawthorn Rd",
        value = "2760,55: Sylverly Gr/Hawthorn Rd",
    ),
    schema.Option(
        display = "55: Sylverly Gr/Hawthorn Rd",
        value = "3331,55: Sylverly Gr/Hawthorn Rd",
    ),
    schema.Option(
        display = "56: Briggs St/Hawthorn Rd",
        value = "2759,56: Briggs St/Hawthorn Rd",
    ),
    schema.Option(
        display = "56: Lockhart St/Hawthorn Rd",
        value = "2758,56: Lockhart St/Hawthorn Rd",
    ),
    schema.Option(
        display = "57: Glenhuntly Rd/Hawthorn Rd",
        value = "2981,57: Glenhuntly Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "57: Glenhuntly Rd/Hawthorn Rd",
        value = "2757,57: Glenhuntly Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "58: Sycamore St/Hawthorn Rd",
        value = "2756,58: Sycamore St/Hawthorn Rd",
    ),
    schema.Option(
        display = "59: Princes Park/Hawthorn Rd",
        value = "2754,59: Princes Park/Hawthorn Rd",
    ),
    schema.Option(
        display = "60: Dover St/Hawthorn Rd",
        value = "2753,60: Dover St/Hawthorn Rd",
    ),
    schema.Option(
        display = "61: Raynes St/Hawthorn Rd",
        value = "2751,61: Raynes St/Hawthorn Rd",
    ),
    schema.Option(
        display = "61: Stone St/Hawthorn Rd",
        value = "2752,61: Stone St/Hawthorn Rd",
    ),
    schema.Option(
        display = "62: Gardenvale Rd/Hawthorn Rd",
        value = "2668,62: Gardenvale Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "63: North Rd/Hawthorn Rd",
        value = "2749,63: North Rd/Hawthorn Rd",
    ),
    schema.Option(
        display = "64: Taylor St/Hawthorn Rd",
        value = "2748,64: Taylor St/Hawthorn Rd",
    ),
    schema.Option(
        display = "65: Davey Ave/Hawthorn Rd",
        value = "2746,65: Davey Ave/Hawthorn Rd",
    ),
    schema.Option(
        display = "66: Union St/Hawthorn Rd",
        value = "2745,66: Union St/Hawthorn Rd",
    ),
    schema.Option(
        display = "67: Howell St/Hawthorn Rd",
        value = "2743,67: Howell St/Hawthorn Rd",
    ),
    schema.Option(
        display = "67: Rogers Ave/Hawthorn Rd",
        value = "2744,67: Rogers Ave/Hawthorn Rd",
    ),
    schema.Option(
        display = "68: East Brighton/Hawthorn Rd",
        value = "2742,68: East Brighton/Hawthorn Rd",
    ),
]
Route67StopOptions = [
    schema.Option(
        display = "1: Flinders St/Queens Bridge St",
        value = "3111,1: Flinders St/Queens Bridge St",
    ),
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Collins St/William St",
        value = "3107,4: Collins St/William St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "5: Bourke St/William St",
        value = "3106,5: Bourke St/William St",
    ),
    schema.Option(
        display = "7: Flagstaff Stn/William St",
        value = "3104,7: Flagstaff Stn/William St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Beatrice St/St Kilda Rd",
        value = "2407,26: Beatrice St/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Moubray St/St Kilda Rd",
        value = "2408,26: Moubray St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: High St/St Kilda Rd",
        value = "2406,27: High St/St Kilda Rd",
    ),
    schema.Option(
        display = "27: Lorne St/St Kilda Rd",
        value = "2405,27: Lorne St/St Kilda Rd",
    ),
    schema.Option(
        display = "29: Union St/St Kilda Rd",
        value = "2403,29: Union St/St Kilda Rd",
    ),
    schema.Option(
        display = "30: St Kilda Jct/St Kilda Rd",
        value = "2401,30: St Kilda Jct/St Kilda Rd",
    ),
    schema.Option(
        display = "31: Barkly St/St Kilda Rd",
        value = "2399,31: Barkly St/St Kilda Rd",
    ),
    schema.Option(
        display = "32: Alma Rd/St Kilda Rd",
        value = "2314,32: Alma Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "33: Argyle St/St Kilda Rd",
        value = "2313,33: Argyle St/St Kilda Rd",
    ),
    schema.Option(
        display = "34: Inkerman St/St Kilda Rd",
        value = "2398,34: Inkerman St/St Kilda Rd",
    ),
    schema.Option(
        display = "35: Carlisle St/St Kilda Rd",
        value = "2779,35: Carlisle St/St Kilda Rd",
    ),
    schema.Option(
        display = "36: St Kilda Primary School/Brighton Rd",
        value = "3365,36: St Kilda Primary School/Brighton Rd",
    ),
    schema.Option(
        display = "36: St Kilda Primary School/Brighton Rd",
        value = "3166,36: St Kilda Primary School/Brighton Rd",
    ),
    schema.Option(
        display = "37: Chapel St/Brighton Rd",
        value = "3168,37: Chapel St/Brighton Rd",
    ),
    schema.Option(
        display = "38: Brunning St/Brighton Rd",
        value = "3169,38: Brunning St/Brighton Rd",
    ),
    schema.Option(
        display = "38: Wimbledon Ave/Brighton Rd",
        value = "3170,38: Wimbledon Ave/Brighton Rd",
    ),
    schema.Option(
        display = "39: Glen Eira Rd/Brighton Rd",
        value = "3171,39: Glen Eira Rd/Brighton Rd",
    ),
    schema.Option(
        display = "39: Glen Eira Rd/Brighton Rd",
        value = "3172,39: Glen Eira Rd/Brighton Rd",
    ),
    schema.Option(
        display = "40: Scott St/Brighton Rd",
        value = "3173,40: Scott St/Brighton Rd",
    ),
    schema.Option(
        display = "40: Scott St/Brighton Rd",
        value = "3174,40: Scott St/Brighton Rd",
    ),
    schema.Option(
        display = "41: Coleridge St/Brighton Rd",
        value = "3175,41: Coleridge St/Brighton Rd",
    ),
    schema.Option(
        display = "41: Coleridge St/Brighton Rd",
        value = "3176,41: Coleridge St/Brighton Rd",
    ),
    schema.Option(
        display = "42: Hotham St/Brighton Rd",
        value = "3366,42: Hotham St/Brighton Rd",
    ),
    schema.Option(
        display = "42: Hotham St/Brighton Rd",
        value = "3177,42: Hotham St/Brighton Rd",
    ),
    schema.Option(
        display = "43: Brighton Rd/Glenhuntly Rd",
        value = "3178,43: Brighton Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "44: Elsternwick Stn/Glenhuntly Rd",
        value = "3179,44: Elsternwick Stn/Glenhuntly Rd",
    ),
    schema.Option(
        display = "45: Elsternwick Shopping Centre/Glenhuntly Rd",
        value = "3180,45: Elsternwick Shopping Centre/Glenhuntly Rd",
    ),
    schema.Option(
        display = "46: Orrong Rd/Glenhuntly Rd",
        value = "3181,46: Orrong Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "47: Shoobra Rd/Glenhuntly Rd",
        value = "3182,47: Shoobra Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "48: Parkside St/Glenhuntly Rd",
        value = "3184,48: Parkside St/Glenhuntly Rd",
    ),
    schema.Option(
        display = "49: Kooyong Rd/Glenhuntly Rd",
        value = "3186,49: Kooyong Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "50: Royal Pde/Glenhuntly Rd",
        value = "3187,50: Royal Pde/Glenhuntly Rd",
    ),
    schema.Option(
        display = "51: Hawthorn Rd/Glenhuntly Rd",
        value = "3188,51: Hawthorn Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "52: Jasmine St/Glenhuntly Rd",
        value = "3189,52: Jasmine St/Glenhuntly Rd",
    ),
    schema.Option(
        display = "53: Glenhuntly Tram Depot/Glenhuntly Rd",
        value = "3190,53: Glenhuntly Tram Depot/Glenhuntly Rd",
    ),
    schema.Option(
        display = "54: Bambra Rd/Glenhuntly Rd",
        value = "3192,54: Bambra Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "55: Fallon St/Glenhuntly Rd",
        value = "3193,55: Fallon St/Glenhuntly Rd",
    ),
    schema.Option(
        display = "56: Kambrook Rd/Glenhuntly Rd",
        value = "3195,56: Kambrook Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "56: Kean St/Glenhuntly Rd",
        value = "3196,56: Kean St/Glenhuntly Rd",
    ),
    schema.Option(
        display = "57: Clarke Ave/Glenhuntly Rd",
        value = "3197,57: Clarke Ave/Glenhuntly Rd",
    ),
    schema.Option(
        display = "57: Laura St/Glenhuntly Rd",
        value = "3198,57: Laura St/Glenhuntly Rd",
    ),
    schema.Option(
        display = "58: Booran Rd/Glenhuntly Rd",
        value = "3199,58: Booran Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "58: Booran Rd/Glenhuntly Rd",
        value = "3367,58: Booran Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "60: Glenhuntly Shops/Glenhuntly Rd",
        value = "3201,60: Glenhuntly Shops/Glenhuntly Rd",
    ),
    schema.Option(
        display = "60: Glenhuntly Shops/Glenhuntly Rd",
        value = "3200,60: Glenhuntly Shops/Glenhuntly Rd",
    ),
    schema.Option(
        display = "61: Glen Huntly Stn/Glen Huntly Rd",
        value = "3203,61: Glen Huntly Stn/Glen Huntly Rd",
    ),
    schema.Option(
        display = "61: Glen Huntly Stn/Glen Huntly Rd",
        value = "3202,61: Glen Huntly Stn/Glen Huntly Rd",
    ),
    schema.Option(
        display = "62: Grange Rd/Glenhuntly Rd",
        value = "3305,62: Grange Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "62: Grange Rd/Glenhuntly Rd",
        value = "3204,62: Grange Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "63: Maroona Rd/Glenhuntly Rd",
        value = "2486,63: Maroona Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "64: Mernda Ave/Glenhuntly Rd",
        value = "2653,64: Mernda Ave/Glenhuntly Rd",
    ),
    schema.Option(
        display = "65: Mimosa Rd/Glenhuntly Rd",
        value = "2665,65: Mimosa Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "66: Glenhuntly Rd/Truganini Rd",
        value = "3208,66: Glenhuntly Rd/Truganini Rd",
    ),
    schema.Option(
        display = "66: Truganini Rd/Glenhuntly Rd",
        value = "3209,66: Truganini Rd/Glenhuntly Rd",
    ),
    schema.Option(
        display = "67: Centre Rd/Truganini Rd",
        value = "3210,67: Centre Rd/Truganini Rd",
    ),
    schema.Option(
        display = "68: Carnegie/Truganini Rd",
        value = "3211,68: Carnegie/Truganini Rd",
    ),
    schema.Option(
        display = "115: Casino/Southbank/Queens Bridge St",
        value = "3007,115: Casino/Southbank/Queens Bridge St",
    ),
    schema.Option(
        display = "116: City Rd/Kings Way",
        value = "3116,116: City Rd/Kings Way",
    ),
    schema.Option(
        display = "117: York St/Kings Way",
        value = "3117,117: York St/Kings Way",
    ),
    schema.Option(
        display = "118: Sturt St/Kings Way",
        value = "3118,118: Sturt St/Kings Way",
    ),
    schema.Option(
        display = "119: Wells St/Park St",
        value = "3119,119: Wells St/Park St",
    ),
]
Route70StopOptions = [
    schema.Option(
        display = "1: Spencer St/Flinders St",
        value = "3318,1: Spencer St/Flinders St",
    ),
    schema.Option(
        display = "2: Melbourne Aquarium/Flinders St",
        value = "3317,2: Melbourne Aquarium/Flinders St",
    ),
    schema.Option(
        display = "3: Market St/Flinders St",
        value = "2092,3: Market St/Flinders St",
    ),
    schema.Option(
        display = "4: Elizabeth St/Flinders St",
        value = "2095,4: Elizabeth St/Flinders St",
    ),
    schema.Option(
        display = "5: Swanston St/Flinders St",
        value = "2096,5: Swanston St/Flinders St",
    ),
    schema.Option(
        display = "6: Russell St/Flinders St",
        value = "2097,6: Russell St/Flinders St",
    ),
    schema.Option(
        display = "8: Richmond Stn/Swan St",
        value = "2115,8: Richmond Stn/Swan St",
    ),
    schema.Option(
        display = "8: Richmond Stn/Swan St",
        value = "3381,8: Richmond Stn/Swan St",
    ),
    schema.Option(
        display = "9: Lennox St/Swan St",
        value = "2138,9: Lennox St/Swan St",
    ),
    schema.Option(
        display = "10: Swan St Shopping Centre/Swan St",
        value = "2111,10: Swan St Shopping Centre/Swan St",
    ),
    schema.Option(
        display = "11: Church St/Swan St",
        value = "2110,11: Church St/Swan St",
    ),
    schema.Option(
        display = "12: Coppin St/Swan St",
        value = "2114,12: Coppin St/Swan St",
    ),
    schema.Option(
        display = "13: Edinburgh St/Swan St",
        value = "2121,13: Edinburgh St/Swan St",
    ),
    schema.Option(
        display = "13: Edinburgh St/Swan St",
        value = "2120,13: Edinburgh St/Swan St",
    ),
    schema.Option(
        display = "14: Burnley St/Swan St",
        value = "2107,14: Burnley St/Swan St",
    ),
    schema.Option(
        display = "14: Burnley St/Swan St",
        value = "2108,14: Burnley St/Swan St",
    ),
    schema.Option(
        display = "15: Stawell St/Swan St",
        value = "2153,15: Stawell St/Swan St",
    ),
    schema.Option(
        display = "15: Stawell St/Swan St",
        value = "2154,15: Stawell St/Swan St",
    ),
    schema.Option(
        display = "16: Park Gr/Swan St",
        value = "2145,16: Park Gr/Swan St",
    ),
    schema.Option(
        display = "17: Madden Gr/Swan St",
        value = "2141,17: Madden Gr/Swan St",
    ),
    schema.Option(
        display = "18: Yarra Bvd/Swan St",
        value = "2118,18: Yarra Bvd/Swan St",
    ),
    schema.Option(
        display = "29: Power St/Riversdale Rd",
        value = "2147,29: Power St/Riversdale Rd",
    ),
    schema.Option(
        display = "30: Through St/Riversdale Rd",
        value = "2157,30: Through St/Riversdale Rd",
    ),
    schema.Option(
        display = "31: Fordholm Rd/Riversdale Rd",
        value = "2128,31: Fordholm Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "32: Glenferrie Rd/Riversdale Rd",
        value = "2131,32: Glenferrie Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "33: Berkeley St/Riversdale Rd",
        value = "2104,33: Berkeley St/Riversdale Rd",
    ),
    schema.Option(
        display = "34: Kooyongkoot Rd/Riversdale Rd",
        value = "2137,34: Kooyongkoot Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "35: Robinson Rd/Riversdale Rd",
        value = "2149,35: Robinson Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "36: Auburn Rd/Riversdale Rd",
        value = "2103,36: Auburn Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "37: Tooronga Rd/Riversdale Rd",
        value = "2158,37: Tooronga Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "38: Hastings Rd/Riversdale Rd",
        value = "2134,38: Hastings Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "39: Camberwell Tram Depot/Riversdale Rd",
        value = "2150,39: Camberwell Tram Depot/Riversdale Rd",
    ),
    schema.Option(
        display = "40: Camberwell Jct/Riversdale Rd",
        value = "2106,40: Camberwell Jct/Riversdale Rd",
    ),
    schema.Option(
        display = "40: Camberwell Jct/Riversdale Rd",
        value = "2105,40: Camberwell Jct/Riversdale Rd",
    ),
    schema.Option(
        display = "41: Camberwell Market/517 Riversdale Rd",
        value = "2109,41: Camberwell Market/517 Riversdale Rd",
    ),
    schema.Option(
        display = "42: Fermanagh Rd/Riversdale Rd",
        value = "2125,42: Fermanagh Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "43: Trafalgar Rd/Riversdale Rd",
        value = "2159,43: Trafalgar Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "44: Derby St/Riversdale Rd",
        value = "2116,44: Derby St/Riversdale Rd",
    ),
    schema.Option(
        display = "46: Spencer Rd/Riversdale Rd",
        value = "2151,46: Spencer Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "46: Spencer Rd/Riversdale Rd",
        value = "2152,46: Spencer Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "47: Willow Gr/Riversdale Rd",
        value = "2168,47: Willow Gr/Riversdale Rd",
    ),
    schema.Option(
        display = "47: Willow Gr/Riversdale Rd",
        value = "2169,47: Willow Gr/Riversdale Rd",
    ),
    schema.Option(
        display = "48: Cooloongatta Rd/Riversdale Rd",
        value = "2112,48: Cooloongatta Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "49: Glyndon Rd/Riversdale Rd",
        value = "2132,49: Glyndon Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "50: Wattle Valley Rd/Riversdale Rd",
        value = "2165,50: Wattle Valley Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "51: Highfield Rd/Riversdale Rd",
        value = "2135,51: Highfield Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "51: Highfield Rd/Riversdale Rd",
        value = "2136,51: Highfield Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "52: Lockhart St/Riversdale Rd",
        value = "2139,52: Lockhart St/Riversdale Rd",
    ),
    schema.Option(
        display = "53: Essex Rd/Riversdale Rd",
        value = "2124,53: Essex Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "53: Essex Rd/Riversdale Rd",
        value = "2123,53: Essex Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "54: Through Rd/Riversdale Rd",
        value = "2155,54: Through Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "54: Through Rd/Riversdale Rd",
        value = "2156,54: Through Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "55: Union Rd/Riversdale Rd",
        value = "2162,55: Union Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "55: Union Rd/Riversdale Rd",
        value = "2161,55: Union Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "56: Warrigal Rd/Riversdale Rd",
        value = "2164,56: Warrigal Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "57: Glendale St/Riversdale Rd",
        value = "2130,57: Glendale St/Riversdale Rd",
    ),
    schema.Option(
        display = "58: Wattle Park/1013 Riversdale Rd",
        value = "2143,58: Wattle Park/1013 Riversdale Rd",
    ),
    schema.Option(
        display = "58: Wattle Park/Riversdale Rd",
        value = "2239,58: Wattle Park/Riversdale Rd",
    ),
    schema.Option(
        display = "59: Alandale St/Riversdale Rd",
        value = "2102,59: Alandale St/Riversdale Rd",
    ),
    schema.Option(
        display = "60: Ferndale St/Riversdale Rd",
        value = "2127,60: Ferndale St/Riversdale Rd",
    ),
    schema.Option(
        display = "61: Elgar Rd/Riversdale Rd",
        value = "2686,61: Elgar Rd/Riversdale Rd",
    ),
]
Route72StopOptions = [
    schema.Option(
        display = "1: Melbourne University/Swanston St",
        value = "2214,1: Melbourne University/Swanston St",
    ),
    schema.Option(
        display = "3: Lincoln Square/Swanston St",
        value = "2212,3: Lincoln Square/Swanston St",
    ),
    schema.Option(
        display = "4: Queensberry St/Swanston St",
        value = "2211,4: Queensberry St/Swanston St",
    ),
    schema.Option(
        display = "7: RMIT University/Swanston St",
        value = "2209,7: RMIT University/Swanston St",
    ),
    schema.Option(
        display = "8: Melbourne Central Stn/Swanston St",
        value = "2208,8: Melbourne Central Stn/Swanston St",
    ),
    schema.Option(
        display = "10: Bourke St Mall/Swanston St",
        value = "2206,10: Bourke St Mall/Swanston St",
    ),
    schema.Option(
        display = "11: City Square/Swanston St",
        value = "2205,11: City Square/Swanston St",
    ),
    schema.Option(
        display = "13: Federation Square/Swanston St",
        value = "2204,13: Federation Square/Swanston St",
    ),
    schema.Option(
        display = "14: Arts Precinct/St Kilda Rd",
        value = "2203,14: Arts Precinct/St Kilda Rd",
    ),
    schema.Option(
        display = "17: Grant St-Police Memorial/St Kilda Rd",
        value = "2200,17: Grant St-Police Memorial/St Kilda Rd",
    ),
    schema.Option(
        display = "19: Shrine of Remembrance/St Kilda Rd",
        value = "2198,19: Shrine of Remembrance/St Kilda Rd",
    ),
    schema.Option(
        display = "20: ANZAC Stn/St Kilda Rd",
        value = "3062,20: ANZAC Stn/St Kilda Rd",
    ),
    schema.Option(
        display = "22: Toorak Rd/St Kilda Rd",
        value = "2612,22: Toorak Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "23: Arthur St/St Kilda Rd",
        value = "2610,23: Arthur St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2609,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "24: Leopold St/St Kilda Rd",
        value = "2608,24: Leopold St/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2606,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "25: Commercial Rd/St Kilda Rd",
        value = "2607,25: Commercial Rd/St Kilda Rd",
    ),
    schema.Option(
        display = "26: Alfred Hospital/Commercial Rd",
        value = "3290,26: Alfred Hospital/Commercial Rd",
    ),
    schema.Option(
        display = "26: Alfred Hospital/Commercial Rd",
        value = "3213,26: Alfred Hospital/Commercial Rd",
    ),
    schema.Option(
        display = "27: Punt Rd/Commercial Rd",
        value = "3214,27: Punt Rd/Commercial Rd",
    ),
    schema.Option(
        display = "27: Punt Rd/Commercial Rd",
        value = "3291,27: Punt Rd/Commercial Rd",
    ),
    schema.Option(
        display = "28: Braille Library/Commercial Rd",
        value = "3215,28: Braille Library/Commercial Rd",
    ),
    schema.Option(
        display = "28: Braille Library/Commercial Rd",
        value = "3216,28: Braille Library/Commercial Rd",
    ),
    schema.Option(
        display = "29: Porter St/Commercial Rd",
        value = "3217,29: Porter St/Commercial Rd",
    ),
    schema.Option(
        display = "29: Porter St/Commercial Rd",
        value = "3218,29: Porter St/Commercial Rd",
    ),
    schema.Option(
        display = "30: Prahran Market/Commercial Rd",
        value = "3292,30: Prahran Market/Commercial Rd",
    ),
    schema.Option(
        display = "30: Prahran Market/Commercial Rd",
        value = "3219,30: Prahran Market/Commercial Rd",
    ),
    schema.Option(
        display = "31: Chapel St/Commercial Rd",
        value = "3220,31: Chapel St/Commercial Rd",
    ),
    schema.Option(
        display = "31: Chapel St/Malvern Rd",
        value = "3221,31: Chapel St/Malvern Rd",
    ),
    schema.Option(
        display = "32: Bendigo St/Malvern Rd",
        value = "3223,32: Bendigo St/Malvern Rd",
    ),
    schema.Option(
        display = "32: Surrey Rd/Malvern Rd",
        value = "3224,32: Surrey Rd/Malvern Rd",
    ),
    schema.Option(
        display = "33: Francis St/Malvern Rd",
        value = "3225,33: Francis St/Malvern Rd",
    ),
    schema.Option(
        display = "33: Hobson St/Malvern Rd",
        value = "3226,33: Hobson St/Malvern Rd",
    ),
    schema.Option(
        display = "34: Williams Rd/Malvern Rd",
        value = "3293,34: Williams Rd/Malvern Rd",
    ),
    schema.Option(
        display = "34: Williams Rd/Malvern Rd",
        value = "3227,34: Williams Rd/Malvern Rd",
    ),
    schema.Option(
        display = "35: Lorne Rd/Malvern Rd",
        value = "3228,35: Lorne Rd/Malvern Rd",
    ),
    schema.Option(
        display = "35: Mathoura Rd/Malvern Rd",
        value = "3229,35: Mathoura Rd/Malvern Rd",
    ),
    schema.Option(
        display = "36: A'Beckett St/Malvern Rd",
        value = "3231,36: A'Beckett St/Malvern Rd",
    ),
    schema.Option(
        display = "36: Canterbury Rd/Malvern Rd",
        value = "3230,36: Canterbury Rd/Malvern Rd",
    ),
    schema.Option(
        display = "37: Orrong Rd/Malvern Rd",
        value = "2341,37: Orrong Rd/Malvern Rd",
    ),
    schema.Option(
        display = "38: Clendon Rd/Malvern Rd",
        value = "3233,38: Clendon Rd/Malvern Rd",
    ),
    schema.Option(
        display = "39: Densham Rd/Malvern Rd",
        value = "3234,39: Densham Rd/Malvern Rd",
    ),
    schema.Option(
        display = "39: Irving Rd/Malvern Rd",
        value = "3235,39: Irving Rd/Malvern Rd",
    ),
    schema.Option(
        display = "40: Kooyong Rd/Malvern Rd",
        value = "3236,40: Kooyong Rd/Malvern Rd",
    ),
    schema.Option(
        display = "41: Albany Rd/Malvern Rd",
        value = "3237,41: Albany Rd/Malvern Rd",
    ),
    schema.Option(
        display = "41: Murray St/Malvern Rd",
        value = "3238,41: Murray St/Malvern Rd",
    ),
    schema.Option(
        display = "42: Lauriston Girls School/Malvern Rd",
        value = "3240,42: Lauriston Girls School/Malvern Rd",
    ),
    schema.Option(
        display = "42: Lauriston Girls School/Malvern Rd",
        value = "3239,42: Lauriston Girls School/Malvern Rd",
    ),
    schema.Option(
        display = "43: Glenferrie Rd/Malvern Rd",
        value = "3295,43: Glenferrie Rd/Malvern Rd",
    ),
    schema.Option(
        display = "43: Glenferrie Rd/Malvern Rd",
        value = "3296,43: Glenferrie Rd/Malvern Rd",
    ),
    schema.Option(
        display = "44: Plant St/Malvern Rd",
        value = "3241,44: Plant St/Malvern Rd",
    ),
    schema.Option(
        display = "45: Elizabeth St/Malvern Rd",
        value = "3243,45: Elizabeth St/Malvern Rd",
    ),
    schema.Option(
        display = "46: Meredith St/Malvern Rd",
        value = "3245,46: Meredith St/Malvern Rd",
    ),
    schema.Option(
        display = "46: Shaftesbury Ave/Malvern Rd",
        value = "3246,46: Shaftesbury Ave/Malvern Rd",
    ),
    schema.Option(
        display = "47: Tooronga Rd/Malvern Rd",
        value = "3247,47: Tooronga Rd/Malvern Rd",
    ),
    schema.Option(
        display = "47: Tooronga Rd/Malvern Rd",
        value = "3297,47: Tooronga Rd/Malvern Rd",
    ),
    schema.Option(
        display = "48: Edgar St/Malvern Rd",
        value = "3248,48: Edgar St/Malvern Rd",
    ),
    schema.Option(
        display = "48: Edgar St/Malvern Rd",
        value = "3298,48: Edgar St/Malvern Rd",
    ),
    schema.Option(
        display = "49: Belmont Ave/Malvern Rd",
        value = "3249,49: Belmont Ave/Malvern Rd",
    ),
    schema.Option(
        display = "49: Kenilworth Gr/Malvern Rd",
        value = "3250,49: Kenilworth Gr/Malvern Rd",
    ),
    schema.Option(
        display = "50: Burke Rd/Malvern Rd",
        value = "3299,50: Burke Rd/Malvern Rd",
    ),
    schema.Option(
        display = "50: Glenarm Rd/Malvern Rd",
        value = "3251,50: Glenarm Rd/Malvern Rd",
    ),
    schema.Option(
        display = "51: Gardiner Stn/Burke Rd",
        value = "3253,51: Gardiner Stn/Burke Rd",
    ),
    schema.Option(
        display = "51: Gardiner Stn/Burke Rd",
        value = "3252,51: Gardiner Stn/Burke Rd",
    ),
    schema.Option(
        display = "52: Bickleigh St/Burke Rd",
        value = "3255,52: Bickleigh St/Burke Rd",
    ),
    schema.Option(
        display = "52: Harris Ave/Burke Rd",
        value = "3256,52: Harris Ave/Burke Rd",
    ),
    schema.Option(
        display = "54: Toorak Rd/Burke Rd",
        value = "3300,54: Toorak Rd/Burke Rd",
    ),
    schema.Option(
        display = "54: Toorak Rd/Burke Rd",
        value = "3259,54: Toorak Rd/Burke Rd",
    ),
    schema.Option(
        display = "55: Middle Rd/Burke Rd",
        value = "3260,55: Middle Rd/Burke Rd",
    ),
    schema.Option(
        display = "55: Middle Rd/Burke Rd",
        value = "3301,55: Middle Rd/Burke Rd",
    ),
    schema.Option(
        display = "56: Anderson Rd/Burke Rd",
        value = "3261,56: Anderson Rd/Burke Rd",
    ),
    schema.Option(
        display = "56: Anderson Rd/Burke Rd",
        value = "3302,56: Anderson Rd/Burke Rd",
    ),
    schema.Option(
        display = "57: Pine Ave/Burke Rd",
        value = "3262,57: Pine Ave/Burke Rd",
    ),
    schema.Option(
        display = "57: Pine Ave/Burke Rd",
        value = "3263,57: Pine Ave/Burke Rd",
    ),
    schema.Option(
        display = "58: Currajong Ave/Burke Rd",
        value = "3264,58: Currajong Ave/Burke Rd",
    ),
    schema.Option(
        display = "58: Leura Gr/Burke Rd",
        value = "3265,58: Leura Gr/Burke Rd",
    ),
    schema.Option(
        display = "59: Pleasant Rd/Burke Rd",
        value = "3266,59: Pleasant Rd/Burke Rd",
    ),
    schema.Option(
        display = "59: Seymour Gr/Burke Rd",
        value = "3267,59: Seymour Gr/Burke Rd",
    ),
    schema.Option(
        display = "61: Camberwell Jct/Burke Rd",
        value = "3270,61: Camberwell Jct/Burke Rd",
    ),
    schema.Option(
        display = "61: Riversdale Rd/Burke Rd",
        value = "3272,61: Riversdale Rd/Burke Rd",
    ),
    schema.Option(
        display = "62: Camberwell Shopping Centre/755 Burke Rd",
        value = "3273,62: Camberwell Shopping Centre/755 Burke Rd",
    ),
    schema.Option(
        display = "63: Prospect Hill Rd/Burke Rd",
        value = "3275,63: Prospect Hill Rd/Burke Rd",
    ),
    schema.Option(
        display = "63: Prospect Hill Rd/Burke Rd",
        value = "3274,63: Prospect Hill Rd/Burke Rd",
    ),
    schema.Option(
        display = "64: Camberwell Stn/Burke Rd",
        value = "3277,64: Camberwell Stn/Burke Rd",
    ),
    schema.Option(
        display = "64: Camberwell Stn/Burke Rd",
        value = "3276,64: Camberwell Stn/Burke Rd",
    ),
    schema.Option(
        display = "65: Victoria Rd/Burke Rd",
        value = "3278,65: Victoria Rd/Burke Rd",
    ),
    schema.Option(
        display = "65: Victoria Rd/Burke Rd",
        value = "3289,65: Victoria Rd/Burke Rd",
    ),
    schema.Option(
        display = "66: Canterbury Rd/Burke Rd",
        value = "3279,66: Canterbury Rd/Burke Rd",
    ),
    schema.Option(
        display = "66: Rathmines Rd/Burke Rd",
        value = "3280,66: Rathmines Rd/Burke Rd",
    ),
    schema.Option(
        display = "67: Camberwell Girls Grammar/Burke Rd",
        value = "3281,67: Camberwell Girls Grammar/Burke Rd",
    ),
    schema.Option(
        display = "67: Camberwell Girls Grammar/Burke Rd",
        value = "3282,67: Camberwell Girls Grammar/Burke Rd",
    ),
    schema.Option(
        display = "68: Mont Albert Rd/Burke Rd",
        value = "3283,68: Mont Albert Rd/Burke Rd",
    ),
    schema.Option(
        display = "68: Mont Albert Rd/Burke Rd",
        value = "3284,68: Mont Albert Rd/Burke Rd",
    ),
    schema.Option(
        display = "69: Peverill St/Burke Rd",
        value = "3285,69: Peverill St/Burke Rd",
    ),
    schema.Option(
        display = "69: Sackville St/Burke Rd",
        value = "3286,69: Sackville St/Burke Rd",
    ),
    schema.Option(
        display = "70: Cotham Rd/Burke Rd",
        value = "2695,70: Cotham Rd/Burke Rd",
    ),
]
Route75StopOptions = [
    schema.Option(
        display = "1: Spencer St/Flinders St",
        value = "3318,1: Spencer St/Flinders St",
    ),
    schema.Option(
        display = "2: Melbourne Aquarium/Flinders St",
        value = "3317,2: Melbourne Aquarium/Flinders St",
    ),
    schema.Option(
        display = "3: Market St/Flinders St",
        value = "2092,3: Market St/Flinders St",
    ),
    schema.Option(
        display = "4: Elizabeth St/Flinders St",
        value = "2095,4: Elizabeth St/Flinders St",
    ),
    schema.Option(
        display = "5: Swanston St/Flinders St",
        value = "2096,5: Swanston St/Flinders St",
    ),
    schema.Option(
        display = "6: Russell St/Flinders St",
        value = "2097,6: Russell St/Flinders St",
    ),
    schema.Option(
        display = "8: Spring St/Flinders St",
        value = "2877,8: Spring St/Flinders St",
    ),
    schema.Option(
        display = "9: Lansdowne St/Wellington Pde",
        value = "3041,9: Lansdowne St/Wellington Pde",
    ),
    schema.Option(
        display = "9: Lansdowne St/Wellington Pde",
        value = "3123,9: Lansdowne St/Wellington Pde",
    ),
    schema.Option(
        display = "10: Jolimont Rd/Wellington Pde",
        value = "2823,10: Jolimont Rd/Wellington Pde",
    ),
    schema.Option(
        display = "11: Jolimont Stn-MCG/Wellington Pde",
        value = "2825,11: Jolimont Stn-MCG/Wellington Pde",
    ),
    schema.Option(
        display = "13: Simpson St/Wellington Pde",
        value = "2826,13: Simpson St/Wellington Pde",
    ),
    schema.Option(
        display = "14: Punt Rd/Bridge Rd",
        value = "2827,14: Punt Rd/Bridge Rd",
    ),
    schema.Option(
        display = "14: Punt Rd/Wellington Pde",
        value = "3000,14: Punt Rd/Wellington Pde",
    ),
    schema.Option(
        display = "15: Epworth Hospital/Bridge Rd",
        value = "3001,15: Epworth Hospital/Bridge Rd",
    ),
    schema.Option(
        display = "17: Bosisto St/Bridge Rd",
        value = "3002,17: Bosisto St/Bridge Rd",
    ),
    schema.Option(
        display = "17: Waltham St/Bridge Rd",
        value = "3315,17: Waltham St/Bridge Rd",
    ),
    schema.Option(
        display = "18: Church St/Bridge Rd",
        value = "2829,18: Church St/Bridge Rd",
    ),
    schema.Option(
        display = "19: Richmond Town Hall/Bridge Rd",
        value = "3003,19: Richmond Town Hall/Bridge Rd",
    ),
    schema.Option(
        display = "20: Coppin St/Bridge Rd",
        value = "2999,20: Coppin St/Bridge Rd",
    ),
    schema.Option(
        display = "21: Burnley St/Bridge Rd",
        value = "3004,21: Burnley St/Bridge Rd",
    ),
    schema.Option(
        display = "22: Yarra Bvd/Bridge Rd",
        value = "3005,22: Yarra Bvd/Bridge Rd",
    ),
    schema.Option(
        display = "23: Hawthorn Bridge/Bridge Rd",
        value = "2416,23: Hawthorn Bridge/Bridge Rd",
    ),
    schema.Option(
        display = "25: St James Park/Burwood Rd",
        value = "2166,25: St James Park/Burwood Rd",
    ),
    schema.Option(
        display = "26: Hawthorn Stn/Burwood Rd",
        value = "3008,26: Hawthorn Stn/Burwood Rd",
    ),
    schema.Option(
        display = "27: Burwood Rd/Power St",
        value = "3056,27: Burwood Rd/Power St",
    ),
    schema.Option(
        display = "27: Power St/Burwood Rd",
        value = "3009,27: Power St/Burwood Rd",
    ),
    schema.Option(
        display = "28: Wattle Rd/Power St",
        value = "3010,28: Wattle Rd/Power St",
    ),
    schema.Option(
        display = "29: Power St/Riversdale Rd",
        value = "2147,29: Power St/Riversdale Rd",
    ),
    schema.Option(
        display = "30: Through St/Riversdale Rd",
        value = "2157,30: Through St/Riversdale Rd",
    ),
    schema.Option(
        display = "31: Fordholm Rd/Riversdale Rd",
        value = "2128,31: Fordholm Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "32: Glenferrie Rd/Riversdale Rd",
        value = "2131,32: Glenferrie Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "33: Berkeley St/Riversdale Rd",
        value = "2104,33: Berkeley St/Riversdale Rd",
    ),
    schema.Option(
        display = "34: Kooyongkoot Rd/Riversdale Rd",
        value = "2137,34: Kooyongkoot Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "35: Robinson Rd/Riversdale Rd",
        value = "2149,35: Robinson Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "36: Auburn Rd/Riversdale Rd",
        value = "2103,36: Auburn Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "37: Tooronga Rd/Riversdale Rd",
        value = "2158,37: Tooronga Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "38: Hastings Rd/Riversdale Rd",
        value = "2134,38: Hastings Rd/Riversdale Rd",
    ),
    schema.Option(
        display = "39: Camberwell Tram Depot/Riversdale Rd",
        value = "2150,39: Camberwell Tram Depot/Riversdale Rd",
    ),
    schema.Option(
        display = "40: Camberwell Jct/Camberwell Rd",
        value = "3340,40: Camberwell Jct/Camberwell Rd",
    ),
    schema.Option(
        display = "40: Camberwell Jct/Riversdale Rd",
        value = "2106,40: Camberwell Jct/Riversdale Rd",
    ),
    schema.Option(
        display = "41: Burke Rd/Camberwell Rd",
        value = "3012,41: Burke Rd/Camberwell Rd",
    ),
    schema.Option(
        display = "42: Camberwell Primary School/Camberwell Rd",
        value = "3013,42: Camberwell Primary School/Camberwell Rd",
    ),
    schema.Option(
        display = "43: Camberwell Civic Centre/Camberwell Rd",
        value = "3014,43: Camberwell Civic Centre/Camberwell Rd",
    ),
    schema.Option(
        display = "44: Trafalgar Rd/Camberwell Rd",
        value = "3015,44: Trafalgar Rd/Camberwell Rd",
    ),
    schema.Option(
        display = "45: Bowen St/Camberwell Rd",
        value = "3042,45: Bowen St/Camberwell Rd",
    ),
    schema.Option(
        display = "46: Acheron Ave/Camberwell Rd",
        value = "3061,46: Acheron Ave/Camberwell Rd",
    ),
    schema.Option(
        display = "46: Christowel St/Camberwell Rd",
        value = "3016,46: Christowel St/Camberwell Rd",
    ),
    schema.Option(
        display = "47: Maple Cres/Camberwell Rd",
        value = "2172,47: Maple Cres/Camberwell Rd",
    ),
    schema.Option(
        display = "47: Orange Gr/Camberwell Rd",
        value = "3017,47: Orange Gr/Camberwell Rd",
    ),
    schema.Option(
        display = "48: Glen Iris Rd/Camberwell Rd",
        value = "3018,48: Glen Iris Rd/Camberwell Rd",
    ),
    schema.Option(
        display = "48: Orrong Cres/Camberwell Rd",
        value = "2417,48: Orrong Cres/Camberwell Rd",
    ),
    schema.Option(
        display = "49: Tyrone St/Camberwell Rd",
        value = "3019,49: Tyrone St/Camberwell Rd",
    ),
    schema.Option(
        display = "49: Wilson Gr/Camberwell Rd",
        value = "2384,49: Wilson Gr/Camberwell Rd",
    ),
    schema.Option(
        display = "50: Fordham Gardens/Camberwell Rd",
        value = "2248,50: Fordham Gardens/Camberwell Rd",
    ),
    schema.Option(
        display = "50: Smith Rd/Camberwell Rd",
        value = "3043,50: Smith Rd/Camberwell Rd",
    ),
    schema.Option(
        display = "51: Toorak Rd/Camberwell Rd",
        value = "3020,51: Toorak Rd/Camberwell Rd",
    ),
    schema.Option(
        display = "52: Summerhill Rd/Toorak Rd",
        value = "3044,52: Summerhill Rd/Toorak Rd",
    ),
    schema.Option(
        display = "53: Highfield Rd/Toorak Rd",
        value = "3021,53: Highfield Rd/Toorak Rd",
    ),
    schema.Option(
        display = "53: Lithgow St/Toorak Rd",
        value = "3065,53: Lithgow St/Toorak Rd",
    ),
    schema.Option(
        display = "54: Grandview Ave/Toorak Rd",
        value = "3066,54: Grandview Ave/Toorak Rd",
    ),
    schema.Option(
        display = "54: Oberwyl Rd/Toorak Rd",
        value = "3022,54: Oberwyl Rd/Toorak Rd",
    ),
    schema.Option(
        display = "55: Beryl St/Toorak Rd",
        value = "3067,55: Beryl St/Toorak Rd",
    ),
    schema.Option(
        display = "55: Through Rd/Toorak Rd",
        value = "3023,55: Through Rd/Toorak Rd",
    ),
    schema.Option(
        display = "56: Alfred Rd/Toorak Rd",
        value = "3068,56: Alfred Rd/Toorak Rd",
    ),
    schema.Option(
        display = "56: Barkly St/Toorak Rd",
        value = "3024,56: Barkly St/Toorak Rd",
    ),
    schema.Option(
        display = "57: Fairview Ave/Toorak Rd",
        value = "3025,57: Fairview Ave/Toorak Rd",
    ),
    schema.Option(
        display = "57: Queens Pde/Toorak Rd",
        value = "3069,57: Queens Pde/Toorak Rd",
    ),
    schema.Option(
        display = "58: Warrigal Rd/Burwood Hwy",
        value = "3027,58: Warrigal Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "58: Warrigal Rd/Burwood Hwy",
        value = "3312,58: Warrigal Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "59: Gilmour St/Burwood Hwy",
        value = "3070,59: Gilmour St/Burwood Hwy",
    ),
    schema.Option(
        display = "59: Somers St/Burwood Hwy",
        value = "3028,59: Somers St/Burwood Hwy",
    ),
    schema.Option(
        display = "60: Millicent St/Burwood Hwy",
        value = "3071,60: Millicent St/Burwood Hwy",
    ),
    schema.Option(
        display = "60: Roslyn St/Burwood Hwy",
        value = "3030,60: Roslyn St/Burwood Hwy",
    ),
    schema.Option(
        display = "61: Presbyterian Ladies College/Burwood Hwy",
        value = "3031,61: Presbyterian Ladies College/Burwood Hwy",
    ),
    schema.Option(
        display = "62: Elgar Rd/Burwood Hwy",
        value = "3032,62: Elgar Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "63: Deakin University/Burwood Hwy",
        value = "3049,63: Deakin University/Burwood Hwy",
    ),
    schema.Option(
        display = "64: Station St/Burwood Hwy",
        value = "3033,64: Station St/Burwood Hwy",
    ),
    schema.Option(
        display = "65: Starling St/Burwood Hwy",
        value = "3048,65: Starling St/Burwood Hwy",
    ),
    schema.Option(
        display = "66: Middleborough Rd/Burwood Hwy",
        value = "3034,66: Middleborough Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "67: Old Burwood Rd/Burwood Hwy",
        value = "2423,67: Old Burwood Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "68: Benwerrin Reserve/Burwood Hwy",
        value = "3036,68: Benwerrin Reserve/Burwood Hwy",
    ),
    schema.Option(
        display = "69: Highview Gr/Burwood Hwy",
        value = "3037,69: Highview Gr/Burwood Hwy",
    ),
    schema.Option(
        display = "69: Keats St/Burwood Hwy",
        value = "2476,69: Keats St/Burwood Hwy",
    ),
    schema.Option(
        display = "70: Blackburn Rd/Burwood Hwy",
        value = "3038,70: Blackburn Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "71: Sevenoaks Rd/Burwood Hwy",
        value = "3047,71: Sevenoaks Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "72: Lakeside Dr/Burwood Hwy",
        value = "3046,72: Lakeside Dr/Burwood Hwy",
    ),
    schema.Option(
        display = "73: Springvale Rd/Burwood Hwy",
        value = "3115,73: Springvale Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "73: Springvale Rd/Burwood Hwy",
        value = "3039,73: Springvale Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "74: Stanley Rd/Burwood Hwy",
        value = "3045,74: Stanley Rd/Burwood Hwy",
    ),
    schema.Option(
        display = "75: Vermont South Shopping Centre/Burwood Hwy",
        value = "3040,75: Vermont South Shopping Centre/Burwood Hwy",
    ),
]
Route78StopOptions = [
    schema.Option(
        display = "36: Brighton Rd/Chapel St",
        value = "2434,36: Brighton Rd/Chapel St",
    ),
    schema.Option(
        display = "37: Carlisle St/Chapel St",
        value = "2122,37: Carlisle St/Chapel St",
    ),
    schema.Option(
        display = "38: Inkerman St/Chapel St",
        value = "2350,38: Inkerman St/Chapel St",
    ),
    schema.Option(
        display = "39: Argyle St/Chapel St",
        value = "2349,39: Argyle St/Chapel St",
    ),
    schema.Option(
        display = "40: Alma Rd/Chapel St",
        value = "2348,40: Alma Rd/Chapel St",
    ),
    schema.Option(
        display = "41: St Michaels Grammar School/Chapel St",
        value = "2346,41: St Michaels Grammar School/Chapel St",
    ),
    schema.Option(
        display = "41: St Michaels Grammar School/Chapel St",
        value = "2347,41: St Michaels Grammar School/Chapel St",
    ),
    schema.Option(
        display = "42: Dandenong Rd/Chapel St",
        value = "2459,42: Dandenong Rd/Chapel St",
    ),
    schema.Option(
        display = "42: Dandenong Rd/Chapel St",
        value = "2345,42: Dandenong Rd/Chapel St",
    ),
    schema.Option(
        display = "43: Windsor Stn/Chapel St",
        value = "2456,43: Windsor Stn/Chapel St",
    ),
    schema.Option(
        display = "43: Windsor Stn/Chapel St",
        value = "2344,43: Windsor Stn/Chapel St",
    ),
    schema.Option(
        display = "44: Duke St/Chapel St",
        value = "2455,44: Duke St/Chapel St",
    ),
    schema.Option(
        display = "44: Duke St/Chapel St",
        value = "2343,44: Duke St/Chapel St",
    ),
    schema.Option(
        display = "45: High St/Chapel St",
        value = "2342,45: High St/Chapel St",
    ),
    schema.Option(
        display = "46: Chatham St/Chapel St",
        value = "2340,46: Chatham St/Chapel St",
    ),
    schema.Option(
        display = "47: Commercial Rd/Chapel St",
        value = "2339,47: Commercial Rd/Chapel St",
    ),
    schema.Option(
        display = "47: Malvern Rd/Chapel St",
        value = "2338,47: Malvern Rd/Chapel St",
    ),
    schema.Option(
        display = "48: Cliff St/Chapel St",
        value = "2337,48: Cliff St/Chapel St",
    ),
    schema.Option(
        display = "48: Wilson St/Chapel St",
        value = "2336,48: Wilson St/Chapel St",
    ),
    schema.Option(
        display = "49: Arthur St/Chapel St",
        value = "2334,49: Arthur St/Chapel St",
    ),
    schema.Option(
        display = "49: Palermo St/Chapel St",
        value = "2335,49: Palermo St/Chapel St",
    ),
    schema.Option(
        display = "50: Toorak Rd/Chapel St",
        value = "2333,50: Toorak Rd/Chapel St",
    ),
    schema.Option(
        display = "51: Malcolm St/Chapel St",
        value = "2332,51: Malcolm St/Chapel St",
    ),
    schema.Option(
        display = "53: Howard St/Church St",
        value = "2330,53: Howard St/Church St",
    ),
    schema.Option(
        display = "54: Balmain St/Church St",
        value = "2328,54: Balmain St/Church St",
    ),
    schema.Option(
        display = "54: Cotter St/Church St",
        value = "2329,54: Cotter St/Church St",
    ),
    schema.Option(
        display = "55: Adelaide St/Church St",
        value = "2327,55: Adelaide St/Church St",
    ),
    schema.Option(
        display = "55: Gibbons St/Church St",
        value = "2326,55: Gibbons St/Church St",
    ),
    schema.Option(
        display = "56: East Richmond Stn/Church St",
        value = "3347,56: East Richmond Stn/Church St",
    ),
    schema.Option(
        display = "57: Swan St/Church St",
        value = "2325,57: Swan St/Church St",
    ),
    schema.Option(
        display = "58: Gipps St/Church St",
        value = "2324,58: Gipps St/Church St",
    ),
    schema.Option(
        display = "59: St Ignatius Church/Church St",
        value = "2323,59: St Ignatius Church/Church St",
    ),
    schema.Option(
        display = "60: Abinger St/Church St",
        value = "2322,60: Abinger St/Church St",
    ),
    schema.Option(
        display = "61: Bridge Rd/Church St",
        value = "2321,61: Bridge Rd/Church St",
    ),
    schema.Option(
        display = "62: Highett St/Church St",
        value = "2320,62: Highett St/Church St",
    ),
    schema.Option(
        display = "63: Kent St/Church St",
        value = "2318,63: Kent St/Church St",
    ),
    schema.Option(
        display = "63: Tweedie Pl/Church St",
        value = "2319,63: Tweedie Pl/Church St",
    ),
    schema.Option(
        display = "64: Baker St/Church St",
        value = "2316,64: Baker St/Church St",
    ),
    schema.Option(
        display = "64: Elizabeth St/Church St",
        value = "2317,64: Elizabeth St/Church St",
    ),
    schema.Option(
        display = "65: Victoria St/Church St",
        value = "2315,65: Victoria St/Church St",
    ),
]
Route82StopOptions = [
    schema.Option(
        display = "32: Moonee Ponds Jct/Pascoe Vale Rd",
        value = "2685,32: Moonee Ponds Jct/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "33: Chaucer St/Ascot Vale Rd",
        value = "2395,33: Chaucer St/Ascot Vale Rd",
    ),
    schema.Option(
        display = "34: Ascot Vale Rd/Maribyrnong Rd",
        value = "2393,34: Ascot Vale Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "34: Maribyrnong Rd/Ascot Vale Rd",
        value = "2394,34: Maribyrnong Rd/Ascot Vale Rd",
    ),
    schema.Option(
        display = "35: Moore St/Maribyrnong Rd",
        value = "2392,35: Moore St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "37: Union Rd/Maribyrnong Rd",
        value = "2390,37: Union Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "38: Ferguson St/Maribyrnong Rd",
        value = "2389,38: Ferguson St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "38: Hotham St/Maribyrnong Rd",
        value = "2388,38: Hotham St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "39: Bowen St/Maribyrnong Rd",
        value = "2387,39: Bowen St/Maribyrnong Rd",
    ),
    schema.Option(
        display = "40: Epsom Rd/Maribyrnong Rd",
        value = "2386,40: Epsom Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "40: Epsom Rd/Maribyrnong Rd",
        value = "2385,40: Epsom Rd/Maribyrnong Rd",
    ),
    schema.Option(
        display = "41: Maribyrnong Park/Maribyrnong Rd",
        value = "2383,41: Maribyrnong Park/Maribyrnong Rd",
    ),
    schema.Option(
        display = "42: Clyde St/Raleigh Rd",
        value = "2382,42: Clyde St/Raleigh Rd",
    ),
    schema.Option(
        display = "43: Van Ness Ave/Raleigh Rd",
        value = "2381,43: Van Ness Ave/Raleigh Rd",
    ),
    schema.Option(
        display = "44: Barb St/Raleigh Rd",
        value = "2379,44: Barb St/Raleigh Rd",
    ),
    schema.Option(
        display = "44: Warrs Rd/Raleigh Rd",
        value = "2380,44: Warrs Rd/Raleigh Rd",
    ),
    schema.Option(
        display = "45: Maribyrnong Community Centre/Raleigh Rd",
        value = "2378,45: Maribyrnong Community Centre/Raleigh Rd",
    ),
    schema.Option(
        display = "45: Randall St/Raleigh Rd",
        value = "2001,45: Randall St/Raleigh Rd",
    ),
    schema.Option(
        display = "46: Rosamond Rd/Raleigh Rd",
        value = "2377,46: Rosamond Rd/Raleigh Rd",
    ),
    schema.Option(
        display = "48: Raleigh Rd/Wests Rd",
        value = "2375,48: Raleigh Rd/Wests Rd",
    ),
    schema.Option(
        display = "49: Highpoint Shopping Centre/Wests Rd",
        value = "2374,49: Highpoint Shopping Centre/Wests Rd",
    ),
    schema.Option(
        display = "50: Wests Rd/Williamson Rd",
        value = "2372,50: Wests Rd/Williamson Rd",
    ),
    schema.Option(
        display = "50: Williamson Rd/Wests Rd",
        value = "2373,50: Williamson Rd/Wests Rd",
    ),
    schema.Option(
        display = "51: Williamson Rd/Rosamond Rd",
        value = "2371,51: Williamson Rd/Rosamond Rd",
    ),
    schema.Option(
        display = "52: River St/Rosamond Rd",
        value = "2542,52: River St/Rosamond Rd",
    ),
    schema.Option(
        display = "52: Rosamond Rd/River St",
        value = "2370,52: Rosamond Rd/River St",
    ),
    schema.Option(
        display = "53: Maribyrnong College/River St",
        value = "2369,53: Maribyrnong College/River St",
    ),
    schema.Option(
        display = "54: Gordon St/River St",
        value = "2368,54: Gordon St/River St",
    ),
    schema.Option(
        display = "55: Lyric St/Gordon St",
        value = "2366,55: Lyric St/Gordon St",
    ),
    schema.Option(
        display = "56: Edgewater Square/Gordon St",
        value = "2364,56: Edgewater Square/Gordon St",
    ),
    schema.Option(
        display = "57: Titch St/Gordon St",
        value = "2363,57: Titch St/Gordon St",
    ),
    schema.Option(
        display = "58: Ballarat Rd/Gordon St",
        value = "2361,58: Ballarat Rd/Gordon St",
    ),
    schema.Option(
        display = "59: Droop St/Ballarat Rd",
        value = "2360,59: Droop St/Ballarat Rd",
    ),
    schema.Option(
        display = "60: Tiernan St/Droop St",
        value = "2359,60: Tiernan St/Droop St",
    ),
    schema.Option(
        display = "61: Geelong Rd/Droop St",
        value = "2358,61: Geelong Rd/Droop St",
    ),
    schema.Option(
        display = "62: Nicholson St/Droop St",
        value = "2357,62: Nicholson St/Droop St",
    ),
    schema.Option(
        display = "62: Nicholson St/Hopkins St",
        value = "2356,62: Nicholson St/Hopkins St",
    ),
    schema.Option(
        display = "63: Footscray Market/Leeds St",
        value = "2354,63: Footscray Market/Leeds St",
    ),
    schema.Option(
        display = "63: Leeds St/Hopkins St",
        value = "2355,63: Leeds St/Hopkins St",
    ),
    schema.Option(
        display = "64: Footscray Stn/Leeds St",
        value = "2353,64: Footscray Stn/Leeds St",
    ),
]
Route86StopOptions = [
    schema.Option(
        display = "1: Spencer St/Bourke St",
        value = "2091,1: Spencer St/Bourke St",
    ),
    schema.Option(
        display = "1: Spencer St/La Trobe St",
        value = "3271,1: Spencer St/La Trobe St",
    ),
    schema.Option(
        display = "3: William St/Bourke St",
        value = "2087,3: William St/Bourke St",
    ),
    schema.Option(
        display = "4: Queen St/Bourke St",
        value = "2067,4: Queen St/Bourke St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Bourke St",
        value = "2029,5: Elizabeth St/Bourke St",
    ),
    schema.Option(
        display = "6: Swanston St/Bourke St",
        value = "2077,6: Swanston St/Bourke St",
    ),
    schema.Option(
        display = "7: Russell St/Bourke St",
        value = "2071,7: Russell St/Bourke St",
    ),
    schema.Option(
        display = "9: Spring St/Bourke St",
        value = "2076,9: Spring St/Bourke St",
    ),
    schema.Option(
        display = "10: Albert St/Nicholson St",
        value = "2005,10: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "10: Albert St/Nicholson St",
        value = "2003,10: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "11: Melbourne Museum/Nicholson St",
        value = "2032,11: Melbourne Museum/Nicholson St",
    ),
    schema.Option(
        display = "13: Brunswick St/Gertrude St",
        value = "2016,13: Brunswick St/Gertrude St",
    ),
    schema.Option(
        display = "14: Napier St/Gertrude St",
        value = "2064,14: Napier St/Gertrude St",
    ),
    schema.Option(
        display = "15: Gertrude St/Smith St",
        value = "2074,15: Gertrude St/Smith St",
    ),
    schema.Option(
        display = "15: Smith St/Gertrude St",
        value = "2033,15: Smith St/Gertrude St",
    ),
    schema.Option(
        display = "16: Peel St/Smith St",
        value = "2066,16: Peel St/Smith St",
    ),
    schema.Option(
        display = "17: Charles St/Smith St",
        value = "2019,17: Charles St/Smith St",
    ),
    schema.Option(
        display = "18: Hodgson St/Smith St",
        value = "2043,18: Hodgson St/Smith St",
    ),
    schema.Option(
        display = "19: Johnston St/Smith St",
        value = "2045,19: Johnston St/Smith St",
    ),
    schema.Option(
        display = "20: Keele St/Smith St",
        value = "2070,20: Keele St/Smith St",
    ),
    schema.Option(
        display = "20: Rose St/Smith St",
        value = "2046,20: Rose St/Smith St",
    ),
    schema.Option(
        display = "21: Alexandra Pde/Smith St",
        value = "2094,21: Alexandra Pde/Smith St",
    ),
    schema.Option(
        display = "21: Alexandra Pde/Smith St",
        value = "2006,21: Alexandra Pde/Smith St",
    ),
    schema.Option(
        display = "22: Smith St/Queens Pde",
        value = "2075,22: Smith St/Queens Pde",
    ),
    schema.Option(
        display = "23: Wellington St/Queens Pde",
        value = "2084,23: Wellington St/Queens Pde",
    ),
    schema.Option(
        display = "24: Gold St/Queens Pde",
        value = "2060,24: Gold St/Queens Pde",
    ),
    schema.Option(
        display = "24: Michael St/Queens Pde",
        value = "2034,24: Michael St/Queens Pde",
    ),
    schema.Option(
        display = "25: Clifton Hill Interchange/Queens Pde",
        value = "2042,25: Clifton Hill Interchange/Queens Pde",
    ),
    schema.Option(
        display = "26: Walker St/High St",
        value = "2083,26: Walker St/High St",
    ),
    schema.Option(
        display = "27: Westgarth St/High St",
        value = "2086,27: Westgarth St/High St",
    ),
    schema.Option(
        display = "30: Clarke St/High St",
        value = "2021,30: Clarke St/High St",
    ),
    schema.Option(
        display = "31: Northcote Town Hall/High St",
        value = "2090,31: Northcote Town Hall/High St",
    ),
    schema.Option(
        display = "32: Mitchell St/High St",
        value = "2061,32: Mitchell St/High St",
    ),
    schema.Option(
        display = "33: Arthurton Rd/High St",
        value = "2072,33: Arthurton Rd/High St",
    ),
    schema.Option(
        display = "33: Separation St/High St",
        value = "3418,33: Separation St/High St",
    ),
    schema.Option(
        display = "34: Bent St/High St",
        value = "2057,34: Bent St/High St",
    ),
    schema.Option(
        display = "34: McCutcheon St/High St",
        value = "2009,34: McCutcheon St/High St",
    ),
    schema.Option(
        display = "35: Dennis St/High St",
        value = "2026,35: Dennis St/High St",
    ),
    schema.Option(
        display = "36: Darebin Rd/High St",
        value = "2024,36: Darebin Rd/High St",
    ),
    schema.Option(
        display = "37: Woolton Ave/High St",
        value = "2089,37: Woolton Ave/High St",
    ),
    schema.Option(
        display = "38: Clarendon St/High St",
        value = "2020,38: Clarendon St/High St",
    ),
    schema.Option(
        display = "38: Normanby Ave/High St",
        value = "3353,38: Normanby Ave/High St",
    ),
    schema.Option(
        display = "39: Ballantyne St/High St",
        value = "2035,39: Ballantyne St/High St",
    ),
    schema.Option(
        display = "39: Gooch St/High St",
        value = "2007,39: Gooch St/High St",
    ),
    schema.Option(
        display = "40: Mansfield St/High St",
        value = "2055,40: Mansfield St/High St",
    ),
    schema.Option(
        display = "41: Blythe St/High St",
        value = "2010,41: Blythe St/High St",
    ),
    schema.Option(
        display = "41: Collins St/High St",
        value = "2023,41: Collins St/High St",
    ),
    schema.Option(
        display = "42: Dundas St/Plenty Rd",
        value = "2028,42: Dundas St/Plenty Rd",
    ),
    schema.Option(
        display = "42: Miller St/High St",
        value = "2027,42: Miller St/High St",
    ),
    schema.Option(
        display = "43: Raglan St/Plenty Rd",
        value = "2068,43: Raglan St/Plenty Rd",
    ),
    schema.Option(
        display = "44: Osborne Gr/Plenty Rd",
        value = "2065,44: Osborne Gr/Plenty Rd",
    ),
    schema.Option(
        display = "44: Seymour St/Plenty Rd",
        value = "2692,44: Seymour St/Plenty Rd",
    ),
    schema.Option(
        display = "45: Bell St/Plenty Rd",
        value = "2008,45: Bell St/Plenty Rd",
    ),
    schema.Option(
        display = "47: David St/Plenty Rd",
        value = "2025,47: David St/Plenty Rd",
    ),
    schema.Option(
        display = "48: Gower St/Plenty Rd",
        value = "2036,48: Gower St/Plenty Rd",
    ),
    schema.Option(
        display = "49: Murray Rd/Plenty Rd",
        value = "2063,49: Murray Rd/Plenty Rd",
    ),
    schema.Option(
        display = "50: Sylvester Gr/Plenty Rd",
        value = "2078,50: Sylvester Gr/Plenty Rd",
    ),
    schema.Option(
        display = "51: Wood St/Plenty Rd",
        value = "2088,51: Wood St/Plenty Rd",
    ),
    schema.Option(
        display = "52: Tyler St/Plenty Rd",
        value = "2080,52: Tyler St/Plenty Rd",
    ),
    schema.Option(
        display = "53: Ethel Gr/Plenty Rd",
        value = "2030,53: Ethel Gr/Plenty Rd",
    ),
    schema.Option(
        display = "54: Wilkinson St/Plenty Rd",
        value = "2018,54: Wilkinson St/Plenty Rd",
    ),
    schema.Option(
        display = "55: Albert St/Plenty Rd",
        value = "2787,55: Albert St/Plenty Rd",
    ),
    schema.Option(
        display = "55: Boldrewood Pde/Plenty Rd",
        value = "2004,55: Boldrewood Pde/Plenty Rd",
    ),
    schema.Option(
        display = "56: Loddon Ave/Plenty Rd",
        value = "2052,56: Loddon Ave/Plenty Rd",
    ),
    schema.Option(
        display = "57: Reservoir District Secondary College/Plenty Rd",
        value = "2039,57: Reservoir District Secondary College/Plenty Rd",
    ),
    schema.Option(
        display = "58: Browning St/Plenty Rd",
        value = "2015,58: Browning St/Plenty Rd",
    ),
    schema.Option(
        display = "59: Preston Cemetery/Plenty Rd",
        value = "2014,59: Preston Cemetery/Plenty Rd",
    ),
    schema.Option(
        display = "60: La Trobe University/Plenty Rd",
        value = "2048,60: La Trobe University/Plenty Rd",
    ),
    schema.Option(
        display = "61: Bundoora Park/Plenty Rd",
        value = "2054,61: Bundoora Park/Plenty Rd",
    ),
    schema.Option(
        display = "62: Metropolitan Fire Brigade/Plenty Rd",
        value = "2017,62: Metropolitan Fire Brigade/Plenty Rd",
    ),
    schema.Option(
        display = "63: Greenwood Dr/Plenty Rd",
        value = "2038,63: Greenwood Dr/Plenty Rd",
    ),
    schema.Option(
        display = "64: Mount Cooper Dr/Plenty Rd",
        value = "2062,64: Mount Cooper Dr/Plenty Rd",
    ),
    schema.Option(
        display = "65: Grimshaw St/Plenty Rd",
        value = "2040,65: Grimshaw St/Plenty Rd",
    ),
    schema.Option(
        display = "66: Settlement Rd/Plenty Rd",
        value = "2073,66: Settlement Rd/Plenty Rd",
    ),
    schema.Option(
        display = "67: Bundoora Square SC/Plenty Rd",
        value = "2059,67: Bundoora Square SC/Plenty Rd",
    ),
    schema.Option(
        display = "68: Greenhills Rd/Plenty Rd",
        value = "2037,68: Greenhills Rd/Plenty Rd",
    ),
    schema.Option(
        display = "69: Taunton Dr/Plenty Rd",
        value = "2079,69: Taunton Dr/Plenty Rd",
    ),
    schema.Option(
        display = "70: Clements Dr/Plenty Rd",
        value = "2755,70: Clements Dr/Plenty Rd",
    ),
    schema.Option(
        display = "70: Janefield Dr/Plenty Rd",
        value = "2022,70: Janefield Dr/Plenty Rd",
    ),
    schema.Option(
        display = "71: RMIT/Plenty Rd",
        value = "2058,71: RMIT/Plenty Rd",
    ),
    schema.Option(
        display = "119: La Trobe St/Spencer St",
        value = "2050,119: La Trobe St/Spencer St",
    ),
    schema.Option(
        display = "120: Lonsdale St/Spencer St",
        value = "2053,120: Lonsdale St/Spencer St",
    ),
]
Route96StopOptions = [
    schema.Option(
        display = "1: Spencer St/Bourke St",
        value = "2091,1: Spencer St/Bourke St",
    ),
    schema.Option(
        display = "3: William St/Bourke St",
        value = "2087,3: William St/Bourke St",
    ),
    schema.Option(
        display = "4: Queen St/Bourke St",
        value = "2067,4: Queen St/Bourke St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Bourke St",
        value = "2029,5: Elizabeth St/Bourke St",
    ),
    schema.Option(
        display = "6: Swanston St/Bourke St",
        value = "2077,6: Swanston St/Bourke St",
    ),
    schema.Option(
        display = "7: Russell St/Bourke St",
        value = "2071,7: Russell St/Bourke St",
    ),
    schema.Option(
        display = "9: Spring St/Bourke St",
        value = "2076,9: Spring St/Bourke St",
    ),
    schema.Option(
        display = "10: Albert St/Nicholson St",
        value = "2003,10: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "10: Albert St/Nicholson St",
        value = "2005,10: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "11: Melbourne Museum/Nicholson St",
        value = "2032,11: Melbourne Museum/Nicholson St",
    ),
    schema.Option(
        display = "12: Moor St/Nicholson St",
        value = "2958,12: Moor St/Nicholson St",
    ),
    schema.Option(
        display = "13: Johnston St/Nicholson St",
        value = "2955,13: Johnston St/Nicholson St",
    ),
    schema.Option(
        display = "13: Johnston St/Nicholson St",
        value = "2954,13: Johnston St/Nicholson St",
    ),
    schema.Option(
        display = "14: Rose St/Nicholson St",
        value = "2952,14: Rose St/Nicholson St",
    ),
    schema.Option(
        display = "14: Rose St/Nicholson St",
        value = "2953,14: Rose St/Nicholson St",
    ),
    schema.Option(
        display = "15: Alexandra Pde/Nicholson St",
        value = "2951,15: Alexandra Pde/Nicholson St",
    ),
    schema.Option(
        display = "15: Alexandra Pde/Nicholson St",
        value = "2950,15: Alexandra Pde/Nicholson St",
    ),
    schema.Option(
        display = "16: Freeman St/Nicholson St",
        value = "2948,16: Freeman St/Nicholson St",
    ),
    schema.Option(
        display = "17: Reid St/Nicholson St",
        value = "2946,17: Reid St/Nicholson St",
    ),
    schema.Option(
        display = "17: Reid St/Nicholson St",
        value = "2945,17: Reid St/Nicholson St",
    ),
    schema.Option(
        display = "18: Scotchmer St/Nicholson St",
        value = "2943,18: Scotchmer St/Nicholson St",
    ),
    schema.Option(
        display = "18: Scotchmer St/Nicholson St",
        value = "2944,18: Scotchmer St/Nicholson St",
    ),
    schema.Option(
        display = "19: Brunswick Rd/Nicholson St",
        value = "2942,19: Brunswick Rd/Nicholson St",
    ),
    schema.Option(
        display = "19: Holden St/Nicholson St",
        value = "2941,19: Holden St/Nicholson St",
    ),
    schema.Option(
        display = "20: Miller St/Nicholson St",
        value = "2939,20: Miller St/Nicholson St",
    ),
    schema.Option(
        display = "20: Miller St/Nicholson St",
        value = "2940,20: Miller St/Nicholson St",
    ),
    schema.Option(
        display = "21: Glenlyon Rd/Nicholson St",
        value = "2937,21: Glenlyon Rd/Nicholson St",
    ),
    schema.Option(
        display = "21: Glenlyon Rd/Nicholson St",
        value = "2938,21: Glenlyon Rd/Nicholson St",
    ),
    schema.Option(
        display = "22: Albert St/Nicholson St",
        value = "2936,22: Albert St/Nicholson St",
    ),
    schema.Option(
        display = "23: Blyth St/Nicholson St",
        value = "2934,23: Blyth St/Nicholson St",
    ),
    schema.Option(
        display = "122: Southern Cross Stn/Spencer St",
        value = "2497,122: Southern Cross Stn/Spencer St",
    ),
    schema.Option(
        display = "124: Batman Park/Spencer St",
        value = "2499,124: Batman Park/Spencer St",
    ),
    schema.Option(
        display = "125: Clarendon St/Whiteman St",
        value = "2503,125: Clarendon St/Whiteman St",
    ),
    schema.Option(
        display = "125: Port Jct/79 Whiteman St",
        value = "2504,125: Port Jct/79 Whiteman St",
    ),
    schema.Option(
        display = "126: City Rd/Light Rail",
        value = "2959,126: City Rd/Light Rail",
    ),
    schema.Option(
        display = "127: South Melbourne Stn/Light Rail",
        value = "2960,127: South Melbourne Stn/Light Rail",
    ),
    schema.Option(
        display = "128: Albert Park Stn/Light Rail",
        value = "2961,128: Albert Park Stn/Light Rail",
    ),
    schema.Option(
        display = "129: Melbourne Sports and Aquatic Centre/Light Rail",
        value = "2800,129: Melbourne Sports and Aquatic Centre/Light Rail",
    ),
    schema.Option(
        display = "130: Middle Park Stn/Light Rail",
        value = "2963,130: Middle Park Stn/Light Rail",
    ),
    schema.Option(
        display = "131: Fraser St/Light Rail",
        value = "2964,131: Fraser St/Light Rail",
    ),
    schema.Option(
        display = "132: St Kilda Stn/Fitzroy St",
        value = "2883,132: St Kilda Stn/Fitzroy St",
    ),
    schema.Option(
        display = "133: Canterbury Rd/Fitzroy St",
        value = "2884,133: Canterbury Rd/Fitzroy St",
    ),
    schema.Option(
        display = "134: Park St/Fitzroy St",
        value = "2886,134: Park St/Fitzroy St",
    ),
    schema.Option(
        display = "135: Acland St/Fitzroy St",
        value = "2887,135: Acland St/Fitzroy St",
    ),
    schema.Option(
        display = "135: Jacka Bvd/Fitzroy St",
        value = "2888,135: Jacka Bvd/Fitzroy St",
    ),
    schema.Option(
        display = "136: Alfred Square/The Esplanade",
        value = "2889,136: Alfred Square/The Esplanade",
    ),
    schema.Option(
        display = "138: Luna Park/The Esplanade",
        value = "2968,138: Luna Park/The Esplanade",
    ),
    schema.Option(
        display = "139: Belford St/Acland St",
        value = "2284,139: Belford St/Acland St",
    ),
]
Route109StopOptions = [
    schema.Option(
        display = "1: Spencer St/Collins St",
        value = "2496,1: Spencer St/Collins St",
    ),
    schema.Option(
        display = "3: William St/Collins St",
        value = "2494,3: William St/Collins St",
    ),
    schema.Option(
        display = "5: Elizabeth St/Collins St",
        value = "2492,5: Elizabeth St/Collins St",
    ),
    schema.Option(
        display = "6: Melbourne Town Hall/Collins St",
        value = "2491,6: Melbourne Town Hall/Collins St",
    ),
    schema.Option(
        display = "7: Exhibition St/Collins St",
        value = "2174,7: Exhibition St/Collins St",
    ),
    schema.Option(
        display = "8: Spring St/Collins St",
        value = "2488,8: Spring St/Collins St",
    ),
    schema.Option(
        display = "10: Parliament Stn/Macarthur St",
        value = "2487,10: Parliament Stn/Macarthur St",
    ),
    schema.Option(
        display = "11: Albert St/Gisborne St",
        value = "2485,11: Albert St/Gisborne St",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2483,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "12: St Vincents Plaza/Victoria Pde",
        value = "2484,12: St Vincents Plaza/Victoria Pde",
    ),
    schema.Option(
        display = "13: Lansdowne St/Victoria Pde",
        value = "2167,13: Lansdowne St/Victoria Pde",
    ),
    schema.Option(
        display = "13: Lansdowne St/Victoria Pde",
        value = "2481,13: Lansdowne St/Victoria Pde",
    ),
    schema.Option(
        display = "15: Smith St/Victoria Pde",
        value = "2246,15: Smith St/Victoria Pde",
    ),
    schema.Option(
        display = "15: Smith St/Victoria Pde",
        value = "2477,15: Smith St/Victoria Pde",
    ),
    schema.Option(
        display = "16: Wellington St/Victoria Pde",
        value = "2540,16: Wellington St/Victoria Pde",
    ),
    schema.Option(
        display = "16: Wellington St/Victoria Pde",
        value = "2475,16: Wellington St/Victoria Pde",
    ),
    schema.Option(
        display = "18: Hoddle St/Victoria Pde",
        value = "2471,18: Hoddle St/Victoria Pde",
    ),
    schema.Option(
        display = "19: North Richmond Stn/Victoria St",
        value = "2468,19: North Richmond Stn/Victoria St",
    ),
    schema.Option(
        display = "19: North Richmond Stn/Victoria St",
        value = "2470,19: North Richmond Stn/Victoria St",
    ),
    schema.Option(
        display = "20: Lennox St/Victoria St",
        value = "2466,20: Lennox St/Victoria St",
    ),
    schema.Option(
        display = "20: Lennox St/Victoria St",
        value = "2469,20: Lennox St/Victoria St",
    ),
    schema.Option(
        display = "21: Church St/Victoria St",
        value = "3352,21: Church St/Victoria St",
    ),
    schema.Option(
        display = "21: Church St/Victoria St",
        value = "2467,21: Church St/Victoria St",
    ),
    schema.Option(
        display = "22: McKay St/Victoria St",
        value = "2465,22: McKay St/Victoria St",
    ),
    schema.Option(
        display = "23: Flockhart St/Victoria St",
        value = "2463,23: Flockhart St/Victoria St",
    ),
    schema.Option(
        display = "23: Leslie St/Victoria St",
        value = "2462,23: Leslie St/Victoria St",
    ),
    schema.Option(
        display = "24: Burnley St/Victoria St",
        value = "2461,24: Burnley St/Victoria St",
    ),
    schema.Option(
        display = "25: River Bvd/Victoria St",
        value = "2458,25: River Bvd/Victoria St",
    ),
    schema.Option(
        display = "27: Findon Cres/Barkers Rd",
        value = "2454,27: Findon Cres/Barkers Rd",
    ),
    schema.Option(
        display = "27: Findon St/Barkers Rd",
        value = "2473,27: Findon St/Barkers Rd",
    ),
    schema.Option(
        display = "29: Barkers Rd/High St",
        value = "2450,29: Barkers Rd/High St",
    ),
    schema.Option(
        display = "29: High St/Barkers Rd",
        value = "2451,29: High St/Barkers Rd",
    ),
    schema.Option(
        display = "31: Stevenson St/High St",
        value = "2447,31: Stevenson St/High St",
    ),
    schema.Option(
        display = "32: Kew Jct/High St",
        value = "2444,32: Kew Jct/High St",
    ),
    schema.Option(
        display = "33: Kew Shopping Centre/High St",
        value = "2445,33: Kew Shopping Centre/High St",
    ),
    schema.Option(
        display = "34: High St/Cotham Rd",
        value = "2615,34: High St/Cotham Rd",
    ),
    schema.Option(
        display = "34: QPO/Cotham Rd",
        value = "2442,34: QPO/Cotham Rd",
    ),
    schema.Option(
        display = "35: Charles St/Cotham Rd",
        value = "2441,35: Charles St/Cotham Rd",
    ),
    schema.Option(
        display = "36: Glenferrie Rd/Cotham Rd",
        value = "2440,36: Glenferrie Rd/Cotham Rd",
    ),
    schema.Option(
        display = "37: Belmont Ave/Cotham Rd",
        value = "2439,37: Belmont Ave/Cotham Rd",
    ),
    schema.Option(
        display = "38: Marshall Ave/Cotham Rd",
        value = "2438,38: Marshall Ave/Cotham Rd",
    ),
    schema.Option(
        display = "39: Florence Ave/Cotham Rd",
        value = "2241,39: Florence Ave/Cotham Rd",
    ),
    schema.Option(
        display = "39: Thomas St/Cotham Rd",
        value = "2437,39: Thomas St/Cotham Rd",
    ),
    schema.Option(
        display = "40: St George's Hospital/Cotham Rd",
        value = "2435,40: St George's Hospital/Cotham Rd",
    ),
    schema.Option(
        display = "41: Kew Traffic School/Cotham Rd",
        value = "2433,41: Kew Traffic School/Cotham Rd",
    ),
    schema.Option(
        display = "42: Burke Rd/Cotham Rd",
        value = "2432,42: Burke Rd/Cotham Rd",
    ),
    schema.Option(
        display = "42: Burke Rd/Whitehorse Rd",
        value = "2431,42: Burke Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "43: Deepdene Shopping Centre/Whitehorse Rd",
        value = "2429,43: Deepdene Shopping Centre/Whitehorse Rd",
    ),
    schema.Option(
        display = "44: Deepdene Park/Whitehorse Rd",
        value = "2427,44: Deepdene Park/Whitehorse Rd",
    ),
    schema.Option(
        display = "45: Hardwicke St/Whitehorse Rd",
        value = "2426,45: Hardwicke St/Whitehorse Rd",
    ),
    schema.Option(
        display = "46: Balwyn Cinema/Whitehorse Rd",
        value = "2425,46: Balwyn Cinema/Whitehorse Rd",
    ),
    schema.Option(
        display = "47: Balwyn Rd/Whitehorse Rd",
        value = "2424,47: Balwyn Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "48: Balwyn Shopping Centre/Whitehorse Rd",
        value = "2422,48: Balwyn Shopping Centre/Whitehorse Rd",
    ),
    schema.Option(
        display = "49: Northcote Ave/Whitehorse Rd",
        value = "2421,49: Northcote Ave/Whitehorse Rd",
    ),
    schema.Option(
        display = "50: Wharton St/Whitehorse Rd",
        value = "2420,50: Wharton St/Whitehorse Rd",
    ),
    schema.Option(
        display = "51: Narrak Rd/Whitehorse Rd",
        value = "2418,51: Narrak Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "51: Narrak Rd/Whitehorse Rd",
        value = "2419,51: Narrak Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "53: Union Rd/Whitehorse Rd",
        value = "2460,53: Union Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "53: Union Rd/Whitehorse Rd",
        value = "2415,53: Union Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "54: Inglisby Rd/Whitehorse Rd",
        value = "2413,54: Inglisby Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "55: Hood St/Whitehorse Rd",
        value = "2412,55: Hood St/Whitehorse Rd",
    ),
    schema.Option(
        display = "56: Elgar Rd/Whitehorse Rd",
        value = "2411,56: Elgar Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "57: Nelson Rd/Whitehorse Rd",
        value = "2410,57: Nelson Rd/Whitehorse Rd",
    ),
    schema.Option(
        display = "58: Box Hill Central/Whitehorse Rd",
        value = "2409,58: Box Hill Central/Whitehorse Rd",
    ),
    schema.Option(
        display = "124: Batman Park/Spencer St",
        value = "2499,124: Batman Park/Spencer St",
    ),
    schema.Option(
        display = "125: Clarendon St/Whiteman St",
        value = "2503,125: Clarendon St/Whiteman St",
    ),
    schema.Option(
        display = "125: Port Jct/79 Whiteman St",
        value = "2504,125: Port Jct/79 Whiteman St",
    ),
    schema.Option(
        display = "126: Montague St/Light Rail",
        value = "2507,126: Montague St/Light Rail",
    ),
    schema.Option(
        display = "127: North Port Stn/Light Rail",
        value = "2508,127: North Port Stn/Light Rail",
    ),
    schema.Option(
        display = "128: Graham St/Light Rail",
        value = "2509,128: Graham St/Light Rail",
    ),
    schema.Option(
        display = "129: Beacon Cove/Light Rail",
        value = "2510,129: Beacon Cove/Light Rail",
    ),
]

# Schema Options - Direction Options Per Tram Route (value = direction_id,direction_name)
Route1DirectionOptions = [
    schema.Option(
        display = "East Coburg",
        value = "0,East Coburg",
    ),
    schema.Option(
        display = "South Melbourne Beach",
        value = "1,South Melbourne Beach",
    ),
    schema.Option(
        display = "All",
        value = "All,0,East Coburg,1,South Melbourne Beach",
    ),
]
Route3DirectionOptions = [
    schema.Option(
        display = "East Malvern",
        value = "12,East Malvern",
    ),
    schema.Option(
        display = "Melbourne University",
        value = "13,Melbourne University",
    ),
    schema.Option(
        display = "All",
        value = "All,12,East Malvern,13,Melbourne University",
    ),
]
Route5DirectionOptions = [
    schema.Option(
        display = "Malvern (Burke Road)",
        value = "18,Malvern (Burke Road)",
    ),
    schema.Option(
        display = "Melbourne University",
        value = "13,Melbourne University",
    ),
    schema.Option(
        display = "All",
        value = "All,18,Malvern (Burke Road),13,Melbourne University",
    ),
]
Route6DirectionOptions = [
    schema.Option(
        display = "Glen Iris",
        value = "23,Glen Iris",
    ),
    schema.Option(
        display = "Moreland",
        value = "24,Moreland",
    ),
    schema.Option(
        display = "All",
        value = "All,23,Glen Iris,24,Moreland",
    ),
]
Route11DirectionOptions = [
    schema.Option(
        display = "Victoria Harbour Docklands",
        value = "5,Victoria Harbour Docklands",
    ),
    schema.Option(
        display = "West Preston",
        value = "4,West Preston",
    ),
    schema.Option(
        display = "All",
        value = "All,5,Victoria Harbour Docklands,4,West Preston",
    ),
]
Route12DirectionOptions = [
    schema.Option(
        display = "St Kilda (Fitzroy St)",
        value = "7,St Kilda (Fitzroy St)",
    ),
    schema.Option(
        display = "Victoria Gardens",
        value = "6,Victoria Gardens",
    ),
    schema.Option(
        display = "All",
        value = "All,7,St Kilda (Fitzroy St),6,Victoria Gardens",
    ),
]
Route16DirectionOptions = [
    schema.Option(
        display = "Kew via St Kilda Beach",
        value = "8,Kew via St Kilda Beach",
    ),
    schema.Option(
        display = "Melbourne University via St Kilda Beach",
        value = "9,Melbourne University via St Kilda Beach",
    ),
    schema.Option(
        display = "All",
        value = "All,8,Kew via St Kilda Beach,9,Melbourne University via St Kilda Beach",
    ),
]
Route19DirectionOptions = [
    schema.Option(
        display = "Flinders St Stn (City)",
        value = "11,Flinders St Stn (City)",
    ),
    schema.Option(
        display = "North Coburg",
        value = "10,North Coburg",
    ),
    schema.Option(
        display = "All",
        value = "All,11,Flinders St Stn (City),10,North Coburg",
    ),
]
Route30DirectionOptions = [
    schema.Option(
        display = "Central Pier Docklands",
        value = "15,Central Pier Docklands",
    ),
    schema.Option(
        display = "St Vincents Plaza",
        value = "14,St Vincents Plaza",
    ),
    schema.Option(
        display = "All",
        value = "All,15,Central Pier Docklands,14,St Vincents Plaza",
    ),
]
Route35DirectionOptions = [
    schema.Option(
        display = "Clockwise",
        value = "16,Clockwise",
    ),
]
Route48DirectionOptions = [
    schema.Option(
        display = "North Balwyn",
        value = "17,North Balwyn",
    ),
    schema.Option(
        display = "Victoria Harbour Docklands",
        value = "5,Victoria Harbour Docklands",
    ),
    schema.Option(
        display = "All",
        value = "All,17,North Balwyn,5,Victoria Harbour Docklands",
    ),
]
Route57DirectionOptions = [
    schema.Option(
        display = "Flinders St Stn (City)",
        value = "11,Flinders St Stn (City)",
    ),
    schema.Option(
        display = "West Maribyrnong",
        value = "19,West Maribyrnong",
    ),
    schema.Option(
        display = "All",
        value = "All,11,Flinders St Stn (City),19,West Maribyrnong",
    ),
]
Route58DirectionOptions = [
    schema.Option(
        display = "Toorak",
        value = "21,Toorak",
    ),
    schema.Option(
        display = "West Coburg",
        value = "20,West Coburg",
    ),
    schema.Option(
        display = "All",
        value = "All,21,Toorak,20,West Coburg",
    ),
]
Route59DirectionOptions = [
    schema.Option(
        display = "Airport West",
        value = "22,Airport West",
    ),
    schema.Option(
        display = "Flinders St Stn (City)",
        value = "11,Flinders St Stn (City)",
    ),
    schema.Option(
        display = "All",
        value = "All,22,Airport West,11,Flinders St Stn (City)",
    ),
]
Route64DirectionOptions = [
    schema.Option(
        display = "East Brighton",
        value = "25,East Brighton",
    ),
    schema.Option(
        display = "Melbourne University",
        value = "13,Melbourne University",
    ),
    schema.Option(
        display = "All",
        value = "All,25,East Brighton,13,Melbourne University",
    ),
]
Route67DirectionOptions = [
    schema.Option(
        display = "Carnegie",
        value = "26,Carnegie",
    ),
    schema.Option(
        display = "Melbourne University",
        value = "13,Melbourne University",
    ),
    schema.Option(
        display = "All",
        value = "All,26,Carnegie,13,Melbourne University",
    ),
]
Route70DirectionOptions = [
    schema.Option(
        display = "Waterfront City Docklands",
        value = "28,Waterfront City Docklands",
    ),
    schema.Option(
        display = "Wattle Park",
        value = "27,Wattle Park",
    ),
    schema.Option(
        display = "All",
        value = "All,28,Waterfront City Docklands,27,Wattle Park",
    ),
]
Route72DirectionOptions = [
    schema.Option(
        display = "Camberwell",
        value = "29,Camberwell",
    ),
    schema.Option(
        display = "Melbourne University",
        value = "13,Melbourne University",
    ),
    schema.Option(
        display = "All",
        value = "All,29,Camberwell,13,Melbourne University",
    ),
]
Route75DirectionOptions = [
    schema.Option(
        display = "Central Pier Docklands",
        value = "15,Central Pier Docklands",
    ),
    schema.Option(
        display = "Vermont South",
        value = "30,Vermont South",
    ),
    schema.Option(
        display = "All",
        value = "All,15,Central Pier Docklands,30,Vermont South",
    ),
]
Route78DirectionOptions = [
    schema.Option(
        display = "Balaclava via Prahran",
        value = "32,Balaclava via Prahran",
    ),
    schema.Option(
        display = "North Richmond",
        value = "31,North Richmond",
    ),
    schema.Option(
        display = "All",
        value = "All,32,Balaclava via Prahran,31,North Richmond",
    ),
]
Route82DirectionOptions = [
    schema.Option(
        display = "Footscray",
        value = "33,Footscray",
    ),
    schema.Option(
        display = "Moonee Ponds",
        value = "34,Moonee Ponds",
    ),
    schema.Option(
        display = "All",
        value = "All,33,Footscray,34,Moonee Ponds",
    ),
]
Route86DirectionOptions = [
    schema.Option(
        display = "Bundoora RMIT",
        value = "35,Bundoora RMIT",
    ),
    schema.Option(
        display = "Waterfront City Docklands",
        value = "28,Waterfront City Docklands",
    ),
    schema.Option(
        display = "All",
        value = "All,35,Bundoora RMIT,28,Waterfront City Docklands",
    ),
]
Route96DirectionOptions = [
    schema.Option(
        display = "East Brunswick",
        value = "36,East Brunswick",
    ),
    schema.Option(
        display = "St Kilda Beach",
        value = "37,St Kilda Beach",
    ),
    schema.Option(
        display = "All",
        value = "All,36,East Brunswick,37,St Kilda Beach",
    ),
]
Route109DirectionOptions = [
    schema.Option(
        display = "Box Hill",
        value = "2,Box Hill",
    ),
    schema.Option(
        display = "Port Melbourne",
        value = "3,Port Melbourne",
    ),
    schema.Option(
        display = "All",
        value = "All,2,Box Hill,3,Port Melbourne",
    ),
]

# Helper - Generate Proper Schema Options Per Tram Route
def more_options(tram_route):
    if tram_route == "721,1":
        return [
            schema.Dropdown(
                id = "stop-list-721",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route1StopOptions[0].value,
                options = Route1StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-721",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route1DirectionOptions[2].value,
                options = Route1DirectionOptions,
            ),
        ]
    elif tram_route == "15833,3":
        return [
            schema.Dropdown(
                id = "stop-list-15833",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route3StopOptions[0].value,
                options = Route3StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-15833",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route3DirectionOptions[2].value,
                options = Route3DirectionOptions,
            ),
        ]
    elif tram_route == "1083,5":
        return [
            schema.Dropdown(
                id = "stop-list-1083",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route5StopOptions[0].value,
                options = Route5StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1083",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route5DirectionOptions[2].value,
                options = Route5DirectionOptions,
            ),
        ]
    elif tram_route == "11544,6":
        return [
            schema.Dropdown(
                id = "stop-list-11544",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route6StopOptions[0].value,
                options = Route6StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-11544",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route6DirectionOptions[2].value,
                options = Route6DirectionOptions,
            ),
        ]
    elif tram_route == "3343,11":
        return [
            schema.Dropdown(
                id = "stop-list-3343",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route11StopOptions[0].value,
                options = Route11StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-3343",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route11DirectionOptions[2].value,
                options = Route11DirectionOptions,
            ),
        ]
    elif tram_route == "8314,12":
        return [
            schema.Dropdown(
                id = "stop-list-8314",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route12StopOptions[0].value,
                options = Route12StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-8314",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route12DirectionOptions[2].value,
                options = Route12DirectionOptions,
            ),
        ]
    elif tram_route == "724,16":
        return [
            schema.Dropdown(
                id = "stop-list-724",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route16StopOptions[0].value,
                options = Route16StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-724",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route16DirectionOptions[2].value,
                options = Route16DirectionOptions,
            ),
        ]
    elif tram_route == "725,19":
        return [
            schema.Dropdown(
                id = "stop-list-725",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route19StopOptions[0].value,
                options = Route19StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-725",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route19DirectionOptions[2].value,
                options = Route19DirectionOptions,
            ),
        ]
    elif tram_route == "1880,30":
        return [
            schema.Dropdown(
                id = "stop-list-1880",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route30StopOptions[0].value,
                options = Route30StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1880",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route30DirectionOptions[2].value,
                options = Route30DirectionOptions,
            ),
        ]
    elif tram_route == "15834,35":
        return [
            schema.Dropdown(
                id = "stop-list-15834",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route35StopOptions[0].value,
                options = Route35StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-15834",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route35DirectionOptions[0].value,
                options = Route35DirectionOptions,
            ),
        ]
    elif tram_route == "2903,48":
        return [
            schema.Dropdown(
                id = "stop-list-2903",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route48StopOptions[0].value,
                options = Route48StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-2903",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route48DirectionOptions[2].value,
                options = Route48DirectionOptions,
            ),
        ]
    elif tram_route == "887,57":
        return [
            schema.Dropdown(
                id = "stop-list-887",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route57StopOptions[0].value,
                options = Route57StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-887",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route57DirectionOptions[2].value,
                options = Route57DirectionOptions,
            ),
        ]
    elif tram_route == "11529,58":
        return [
            schema.Dropdown(
                id = "stop-list-11529",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route58StopOptions[0].value,
                options = Route58StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-11529",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route58DirectionOptions[2].value,
                options = Route58DirectionOptions,
            ),
        ]
    elif tram_route == "897,59":
        return [
            schema.Dropdown(
                id = "stop-list-897",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route59StopOptions[0].value,
                options = Route59StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-897",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route59DirectionOptions[2].value,
                options = Route59DirectionOptions,
            ),
        ]
    elif tram_route == "909,64":
        return [
            schema.Dropdown(
                id = "stop-list-909",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route64StopOptions[0].value,
                options = Route64StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-909",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route64DirectionOptions[2].value,
                options = Route64DirectionOptions,
            ),
        ]
    elif tram_route == "913,67":
        return [
            schema.Dropdown(
                id = "stop-list-913",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route67StopOptions[0].value,
                options = Route67StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-913",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route67DirectionOptions[2].value,
                options = Route67DirectionOptions,
            ),
        ]
    elif tram_route == "940,70":
        return [
            schema.Dropdown(
                id = "stop-list-940",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route70StopOptions[0].value,
                options = Route70StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-940",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route70DirectionOptions[2].value,
                options = Route70DirectionOptions,
            ),
        ]
    elif tram_route == "947,72":
        return [
            schema.Dropdown(
                id = "stop-list-947",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route72StopOptions[0].value,
                options = Route72StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-947",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route72DirectionOptions[2].value,
                options = Route72DirectionOptions,
            ),
        ]
    elif tram_route == "958,75":
        return [
            schema.Dropdown(
                id = "stop-list-958",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route75StopOptions[0].value,
                options = Route75StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-958",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route75DirectionOptions[2].value,
                options = Route75DirectionOptions,
            ),
        ]
    elif tram_route == "976,78":
        return [
            schema.Dropdown(
                id = "stop-list-976",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route78StopOptions[0].value,
                options = Route78StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-976",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route78DirectionOptions[2].value,
                options = Route78DirectionOptions,
            ),
        ]
    elif tram_route == "1002,82":
        return [
            schema.Dropdown(
                id = "stop-list-1002",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route82StopOptions[0].value,
                options = Route82StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1002",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route82DirectionOptions[2].value,
                options = Route82DirectionOptions,
            ),
        ]
    elif tram_route == "1881,86":
        return [
            schema.Dropdown(
                id = "stop-list-1881",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route86StopOptions[0].value,
                options = Route86StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1881",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route86DirectionOptions[2].value,
                options = Route86DirectionOptions,
            ),
        ]
    elif tram_route == "1041,96":
        return [
            schema.Dropdown(
                id = "stop-list-1041",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route96StopOptions[0].value,
                options = Route96StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1041",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route96DirectionOptions[2].value,
                options = Route96DirectionOptions,
            ),
        ]
    elif tram_route == "722,109":
        return [
            schema.Dropdown(
                id = "stop-list-722",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "circleStop",
                default = Route109StopOptions[0].value,
                options = Route109StopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-722",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = Route109DirectionOptions[2].value,
                options = Route109DirectionOptions,
            ),
        ]
    else:
        return []

# Main Schema Function
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "tram-route",
                name = "Tram Route",
                desc = "Choose your tram route",
                icon = "trainTram",
                default = TramRouteOptions[0].value,
                options = TramRouteOptions,
            ),
            schema.Generated(
                id = "generated",
                source = "tram-route",
                handler = more_options,
            ),
        ],
    )

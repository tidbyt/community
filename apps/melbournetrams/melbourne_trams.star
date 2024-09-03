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

DEFAULT_ROUTE_ID = "1002"
DEFAULT_ROUTE_NUMBER = "82"
DEFAULT_STOP_ID = "2685"
DEFAULT_STOP_NAME = "32: Moonee Ponds Jct/Pascoe Vale Rd"
DEFAULT_DIRECTION_ID = "33"
DEFAULT_DIRECTION_DATA = ["33", "Footscray"]

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
        display = "19: North Coburg - Flinders Street Station & City",
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
        display = "57: West Maribyrnong - Flinders Street Station & City",
        value = "887,57",
    ),
    schema.Option(
        display = "58: West Coburg - Toorak",
        value = "11529,58",
    ),
    schema.Option(
        display = "59: Airport West - Flinders Street Station & City",
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
Route1StopOptions = []
Route3StopOptions = []
Route5StopOptions = []
Route6StopOptions = []
Route11StopOptions = []
Route12StopOptions = []
Route16StopOptions = []
Route19StopOptions = []
Route30StopOptions = []
Route35StopOptions = []
Route48StopOptions = []
Route57StopOptions = []
Route58StopOptions = []
Route59StopOptions = []
Route64StopOptions = []
Route67StopOptions = []
Route70StopOptions = []
Route72StopOptions = []
Route75StopOptions = []
Route78StopOptions = []
Route82StopOptions = [
    schema.Option(
        display = "32: Moonee Ponds Jct/Pascoe Vale Rd",
        value = "2685,32: Moonee Ponds Jct/Pascoe Vale Rd",
    ),
    schema.Option(
        display = "33: Test",
        value = "12312,33: Test",
    ),
]
Route86StopOptions = []
Route96StopOptions = []
Route109StopOptions = []

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
        display = "Flinders Street Station (City)",
        value = "11,Flinders Street Station (City)",
    ),
    schema.Option(
        display = "North Coburg",
        value = "10,North Coburg",
    ),
    schema.Option(
        display = "All",
        value = "All,11,Flinders Street Station (City),10,North Coburg",
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
        display = "Flinders Street Station (City)",
        value = "11,Flinders Street Station (City)",
    ),
    schema.Option(
        display = "West Maribyrnong",
        value = "19,West Maribyrnong",
    ),
    schema.Option(
        display = "All",
        value = "All,11,Flinders Street Station (City),19,West Maribyrnong",
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
        display = "Flinders Street Station (City)",
        value = "11,Flinders Street Station (City)",
    ),
    schema.Option(
        display = "All",
        value = "All,22,Airport West,11,Flinders Street Station (City)",
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
    if tram_route == "1002,82":
        return [
            schema.Dropdown(
                id = "stop-list-1002",
                name = "Tram Stop",
                desc = "Choose your stop",
                icon = "tram",
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
                icon = "tram",
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

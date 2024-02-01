"""
Applet: Melbourne Trains
Summary: Melbourne Train Departures
Description: Real time train departures for your preferred station in Melbourne, Australia.
Author: bendiep

API Name: PTV Timetable API v3
API Swagger URL: https://timetableapi.ptv.vic.gov.au/swagger/ui/index

Inspired by other Tidbyt transit apps, I had to make one for Melbourne, Australia.
Shoutouts to the following developers below for code examples in their apps:
- adelaide_metro by M0ntyP
- nyc_bus by samandmoore

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

DEFAULT_ROUTE_ID = "11"
DEFAULT_ROUTE_NAME = "Pakenham"
DEFAULT_STOP_ID = "1150"
DEFAULT_STOP_NAME = "Oakleigh Station"
DEFAULT_DIRECTION_ID = "1"
DEFAULT_DIRECTION_DATA = ["1","City (Flinders Street)"]

BASE_URL = "https://timetableapi.ptv.vic.gov.au"
CACHE_TTL_SECS = 60
ENCRYPTED_API_ID = "AV6+xWcE9Nq1F6uJX9RuQ1dgyOZHzOYjBjDesG+Nc3Ph9hGwPBmsgwNt73LQo5CNQqrclsnTLyiNkM+dxPpJZGEbpFP018QIR/cNw1iErU0ZdsmXLMRr13uDjcf2C+V/qrNw4maRkwq4o8R5qQ=="
ENCRYPTED_API_KEY = "AV6+xWcEKqaID2+Wl9wxZ1SaZRP+/2cHL12n8erWc6rwKW9jKAwYVstgsfLPcO/VqkwzLPOh7qz9+zMBcpZhBnIWlP4XHTCsXPgK53AkRd6HtgpGRGxvRD0DwNuKwS6U1uhK+3rKELnbFxB1U/br+hUCmh3dlbQAD5fOGFlcZ7o/zHCsIi3iifW0"

COLOR_CODE_MERNDA_HURSTBRIDGE = "#D47664"
COLOR_CODE_SUNBURY_CRAIGIEBURN_UPFIELD = "#F3B22C"
COLOR_CODE_BELGRAVE_LILYDALE_ALAMEIN_GLENWAVERLY = "#184977"
COLOR_CODE_CRANBOURNE_PAKENHAM = "#31AAD5"
COLOR_CODE_FRANKSTON_WERRIBEE_WILLIAMSTOWN = "#4FA367"
COLOR_CODE_SANDRINGHAM = "#E997B7"
COLOR_CODE_STONYPOINT = "#5DA971"
COLOR_CODE_DEFAULT = "#000000"
COLOR_CODE_TIME = "#F3AB3F"
COLOR_CODE_PLATFORM_NUMBER = "#FFFFFF"

def main(config):
    schema_train_line = config.get("train-line")
    route_id, route_name = schema_train_line.split(",") if schema_train_line != None else (DEFAULT_ROUTE_ID, DEFAULT_ROUTE_NAME)

    schema_train_station = config.get("station-list-" + route_id) if route_id != None else None
    stop_id, stop_name = schema_train_station.split(",") if schema_train_station != None else (DEFAULT_STOP_ID, DEFAULT_STOP_NAME)

    schema_direction = config.get("direction-list-" + route_id) if route_id != None else None
    direction_data = schema_direction.split(",") if schema_direction != None else DEFAULT_DIRECTION_DATA
    direction_id = direction_data[0] if schema_direction != None else DEFAULT_DIRECTION_ID

    color_code = get_train_line_color_code(route_name)

    if route_id and stop_id and direction_id:
        departures = get_departures(route_id, stop_id, direction_id, route_name, stop_name, direction_data, color_code)

        # print ("\n\n\n[DEBUG]: \
        #     \nschema_train_line: %s\
        #     \nroute_id: %s\
        #     \nroute_name: %s\
        #     \nschema_train_station: %s\
        #     \nstop_id: %s\
        #     \nstop_name: %s\
        #     \nschema_direction: %s\
        #     \ndirection_id: %s\
        #     \ndirection_data: %s\
        #     \ncolor_code: %s\
        #     \ndepartures: %s"
        #     % (schema_train_line, route_id, route_name, schema_train_station,
        #     stop_id, stop_name, schema_direction, direction_id, direction_data,
        #     color_code, departures))

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
        
        # Render - Single Departure Row
        if len(departures) == 1:
            return render.Root(
                delay = 75,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        build_row(departures[0]),
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#666",
                        ),
                    ],
                ),
            )

        # Render - Double Departure Rows
        elif len(departures) == 2:
            return render.Root(
                delay = 75,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        build_row(departures[0]),
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "#666",
                        ),
                        build_row(departures[1]),
                    ],
                ),
            )

    # Render - Default
    return render.Root(
        child = render.Column(
            expanded = False,
            main_align = "space_evenly",
            children = [
                render.WrappedText(
                    content = "No train departures found",
                    width = 64,
                ),
            ],
        ),
    )

# Render Function
def build_row(departure):
    platform_number = render.Text(departure["platform_number"], color = COLOR_CODE_PLATFORM_NUMBER, font = "5x8")

    return render.Row(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Stack(children = [
                # Render - Train Line Color Code and Platform Number
                render.Box(
                    color = departure["color"],
                    width = 11,
                    height = 10,
                    child = platform_number,
                ),
            ]),
            render.Column(
                children = [
                    # Render - Departure Direction
                    render.Marquee(
                        width = 48,
                        child = render.Text(
                            departure["direction_name"].replace(" (Flinders Street)", "").upper() +
                            " (" + departure["stop_name"].replace(" Station", "") + ")",
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

# API - GET Departures Data and Transform
def get_departures(route_id, stop_id, direction_id, route_name, stop_name, direction_data, color_code):
    # Set API ID/KEY
    api_id = LOCAL_API_ID if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_ID)
    api_key = LOCAL_API_KEY if LOCAL_MODE else secret.decrypt(ENCRYPTED_API_KEY)
    if api_id == None or api_key == None:
        print("[ERROR]: Failed to retrieve API credentials")
        return -1

    # Retrieve Data
    request_path = "/v3/departures/route_type/0/stop/" + stop_id + "/route/" + route_id
    request_additional_params = "max_results=2&include_cancelled=false"
    request_additional_params += "&direction_id=" + direction_id if direction_id != "All" else ""
    signature_url = request_path + "?" + request_additional_params + "&devid=" + api_id
    signature = get_request_signature(signature_url, api_key)
    url = BASE_URL + request_path + "?" + request_additional_params + "&devid=" + api_id + "&signature=" + signature

    response = http.get(url, ttl_seconds = CACHE_TTL_SECS)
    if response.status_code != 200:
        fail("Request to %s failed with status code: %d - %s" % (url, response.status_code, response.body()))

    # Transform Data
    departures = response.json()["departures"]
    transformed_data = []
    for i, item in enumerate(departures):
        # Only collect enough data to render the first two departures
        if i < 2:
            estimated_time = item["estimated_departure_utc"]
            scheduled_time = item["scheduled_departure_utc"]
            departure_time = estimated_time if estimated_time != None else scheduled_time

            platform_number = item["platform_number"]
            mapped_platform_number = platform_number if platform_number != None else "-"

            remaining_time_minutes = get_remaining_time_minutes(departure_time)
            eta_time_text = "now" if remaining_time_minutes == 0 else str(remaining_time_minutes) + " mins"

            if direction_id == "All":
                if int(item["direction_id"]) == direction_data[1]:
                    mapped_direction_id, mapped_direction_name = direction_data[1], direction_data[2]
                else:
                    mapped_direction_id, mapped_direction_name = direction_data[3], direction_data[4]
            else:
                mapped_direction_id, mapped_direction_name = direction_data[0], direction_data[1]

            departure = {
                "route_id": route_id,
                "route_name": route_name,
                "stop_id": stop_id,
                "stop_name": stop_name,
                "direction_id": mapped_direction_id,
                "direction_name": mapped_direction_name,
                "departure_time": departure_time,
                "eta_time_text": eta_time_text,
                "platform_number": mapped_platform_number,
                "color": color_code,
            }
            transformed_data.append(departure)
        else:
            break

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

# Helper - Return color code theme for each train line
def get_train_line_color_code(route_name):
    group_mernda_hurstbridge = ["Mernda", "Hurstbridge"]
    group_sunbury_craigieburn_upfield = ["Sunbury", "Craigieburn", "Upfield"]
    group_belgrave_lilydale_alamein_glenwaverly = ["Belgrave", "Lilydale", "Alamein", "Glen Waverley"]
    group_cranbourne_pakenham = ["Cranbourne", "Pakenham"]
    group_frankston_werribee_williamstown = ["Frankston", "Werribee", "Williamstown"]
    group_sandringham = ["Sandringham"]
    group_stonypoint = ["Stony Point"]

    if route_name in group_mernda_hurstbridge:
        return COLOR_CODE_MERNDA_HURSTBRIDGE
    elif route_name in group_sunbury_craigieburn_upfield:
        return COLOR_CODE_SUNBURY_CRAIGIEBURN_UPFIELD
    elif route_name in group_belgrave_lilydale_alamein_glenwaverly:
        return COLOR_CODE_BELGRAVE_LILYDALE_ALAMEIN_GLENWAVERLY
    elif route_name in group_cranbourne_pakenham:
        return COLOR_CODE_CRANBOURNE_PAKENHAM
    elif route_name in group_frankston_werribee_williamstown:
        return COLOR_CODE_FRANKSTON_WERRIBEE_WILLIAMSTOWN
    elif route_name in group_sandringham:
        return COLOR_CODE_SANDRINGHAM
    elif route_name in group_stonypoint:
        return COLOR_CODE_STONYPOINT
    else:
        return COLOR_CODE_DEFAULT

# Schema Options - Train Line Options (value = route_id,route_name)
TrainLineOptions = [
    schema.Option(
        display = "Alamein",
        value = "1,Alamein",
    ),
    schema.Option(
        display = "Belgrave",
        value = "2,Belgrave",
    ),
    schema.Option(
        display = "Craigieburn",
        value = "3,Craigieburn",
    ),
    schema.Option(
        display = "Cranbourne",
        value = "4,Cranbourne",
    ),
    schema.Option(
        display = "Mernda",
        value = "5,Mernda",
    ),
    schema.Option(
        display = "Frankston",
        value = "6,Frankston",
    ),
    schema.Option(
        display = "Glen Waverley",
        value = "7,Glen Waverley",
    ),
    schema.Option(
        display = "Hurstbridge",
        value = "8,Hurstbridge",
    ),
    schema.Option(
        display = "Lilydale",
        value = "9,Lilydale",
    ),
    schema.Option(
        display = "Pakenham",
        value = "11,Pakenham",
    ),
    schema.Option(
        display = "Sandringham",
        value = "12,Sandringham",
    ),
    schema.Option(
        display = "Stony Point",
        value = "13,Stony Point",
    ),
    schema.Option(
        display = "Sunbury",
        value = "14,Sunbury",
    ),
    schema.Option(
        display = "Upfield",
        value = "15,Upfield",
    ),
    schema.Option(
        display = "Werribee",
        value = "16,Werribee",
    ),
    schema.Option(
        display = "Williamstown",
        value = "17,Williamstown",
    ),
]

# Schema Options - Stop Options Per Train Line (value = stop_id,stop_name)
AlameinStopOptions = [
    schema.Option(
        display = "Alamein Station",
        value = "1002,Alamein Station",
    ),
    schema.Option(
        display = "Ashburton Station",
        value = "1010,Ashburton Station",
    ),
    schema.Option(
        display = "Auburn Station",
        value = "1012,Auburn Station",
    ),
    schema.Option(
        display = "Burnley Station",
        value = "1030,Burnley Station",
    ),
    schema.Option(
        display = "Burwood Station",
        value = "1031,Burwood Station",
    ),
    schema.Option(
        display = "Camberwell Station",
        value = "1032,Camberwell Station",
    ),
    schema.Option(
        display = "East Richmond Station",
        value = "1059,East Richmond Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Glenferrie Station",
        value = "1080,Glenferrie Station",
    ),
    schema.Option(
        display = "Hartwell Station",
        value = "1087,Hartwell Station",
    ),
    schema.Option(
        display = "Hawthorn Station",
        value = "1090,Hawthorn Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Riversdale Station",
        value = "1166,Riversdale Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Willison Station",
        value = "1213,Willison Station",
    ),
]
BelgraveStopOptions = [
    schema.Option(
        display = "Auburn Station",
        value = "1012,Auburn Station",
    ),
    schema.Option(
        display = "Bayswater Station",
        value = "1016,Bayswater Station",
    ),
    schema.Option(
        display = "Belgrave Station",
        value = "1018,Belgrave Station",
    ),
    schema.Option(
        display = "Blackburn Station",
        value = "1023,Blackburn Station",
    ),
    schema.Option(
        display = "Boronia Station",
        value = "1025,Boronia Station",
    ),
    schema.Option(
        display = "Box Hill Station",
        value = "1026,Box Hill Station",
    ),
    schema.Option(
        display = "Burnley Station",
        value = "1030,Burnley Station",
    ),
    schema.Option(
        display = "Camberwell Station",
        value = "1032,Camberwell Station",
    ),
    schema.Option(
        display = "Canterbury Station",
        value = "1033,Canterbury Station",
    ),
    schema.Option(
        display = "Chatham Station",
        value = "1037,Chatham Station",
    ),
    schema.Option(
        display = "East Camberwell Station",
        value = "1057,East Camberwell Station",
    ),
    schema.Option(
        display = "East Richmond Station",
        value = "1059,East Richmond Station",
    ),
    schema.Option(
        display = "Ferntree Gully Station",
        value = "1067,Ferntree Gully Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Glenferrie Station",
        value = "1080,Glenferrie Station",
    ),
    schema.Option(
        display = "Hawthorn Station",
        value = "1090,Hawthorn Station",
    ),
    schema.Option(
        display = "Heatherdale Station",
        value = "1091,Heatherdale Station",
    ),
    schema.Option(
        display = "Heathmont Station",
        value = "1092,Heathmont Station",
    ),
    schema.Option(
        display = "Laburnum Station",
        value = "1111,Laburnum Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Mitcham Station",
        value = "1128,Mitcham Station",
    ),
    schema.Option(
        display = "Nunawading Station",
        value = "1148,Nunawading Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Ringwood Station",
        value = "1163,Ringwood Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Tecoma Station",
        value = "1191,Tecoma Station",
    ),
    schema.Option(
        display = "Union Station",
        value = "1229,Union Station",
    ),
    schema.Option(
        display = "Upper Ferntree Gully Station",
        value = "1199,Upper Ferntree Gully Station",
    ),
    schema.Option(
        display = "Upwey Station",
        value = "1200,Upwey Station",
    ),
]
CraigieburnStopOptions = [
    schema.Option(
        display = "Ascot Vale Station",
        value = "1009,Ascot Vale Station",
    ),
    schema.Option(
        display = "Broadmeadows Station",
        value = "1028,Broadmeadows Station",
    ),
    schema.Option(
        display = "Coolaroo Station",
        value = "1221,Coolaroo Station",
    ),
    schema.Option(
        display = "Craigieburn Station",
        value = "1044,Craigieburn Station",
    ),
    schema.Option(
        display = "Essendon Station",
        value = "1064,Essendon Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Glenbervie Station",
        value = "1079,Glenbervie Station",
    ),
    schema.Option(
        display = "Glenroy Station",
        value = "1082,Glenroy Station",
    ),
    schema.Option(
        display = "Jacana Station",
        value = "1102,Jacana Station",
    ),
    schema.Option(
        display = "Kensington Station",
        value = "1108,Kensington Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Moonee Ponds Station",
        value = "1131,Moonee Ponds Station",
    ),
    schema.Option(
        display = "Newmarket Station",
        value = "1140,Newmarket Station",
    ),
    schema.Option(
        display = "North Melbourne Station",
        value = "1144,North Melbourne Station",
    ),
    schema.Option(
        display = "Oak Park Station",
        value = "1149,Oak Park Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Pascoe Vale Station",
        value = "1156,Pascoe Vale Station",
    ),
    schema.Option(
        display = "Roxburgh Park Station",
        value = "1219,Roxburgh Park Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Strathmore Station",
        value = "1186,Strathmore Station",
    ),
]
CranbourneStopOptions = [
    schema.Option(
        display = "Armadale Station",
        value = "1008,Armadale Station",
    ),
    schema.Option(
        display = "Carnegie Station",
        value = "1034,Carnegie Station",
    ),
    schema.Option(
        display = "Caulfield Station",
        value = "1036,Caulfield Station",
    ),
    schema.Option(
        display = "Clayton Station",
        value = "1040,Clayton Station",
    ),
    schema.Option(
        display = "Cranbourne Station",
        value = "1045,Cranbourne Station",
    ),
    schema.Option(
        display = "Dandenong Station",
        value = "1049,Dandenong Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Hawksburn Station",
        value = "1089,Hawksburn Station",
    ),
    schema.Option(
        display = "Hughesdale Station",
        value = "1098,Hughesdale Station",
    ),
    schema.Option(
        display = "Huntingdale Station",
        value = "1099,Huntingdale Station",
    ),
    schema.Option(
        display = "Lynbrook Station",
        value = "1222,Lynbrook Station",
    ),
    schema.Option(
        display = "Malvern Station",
        value = "1118,Malvern Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Merinda Park Station",
        value = "1123,Merinda Park Station",
    ),
    schema.Option(
        display = "Murrumbeena Station",
        value = "1138,Murrumbeena Station",
    ),
    schema.Option(
        display = "Noble Park Station",
        value = "1142,Noble Park Station",
    ),
    schema.Option(
        display = "Oakleigh Station",
        value = "1150,Oakleigh Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Sandown Park Station",
        value = "1172,Sandown Park Station",
    ),
    schema.Option(
        display = "South Yarra Station",
        value = "1180,South Yarra Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Springvale Station",
        value = "1183,Springvale Station",
    ),
    schema.Option(
        display = "Toorak Station",
        value = "1194,Toorak Station",
    ),
    schema.Option(
        display = "Westall Station",
        value = "1208,Westall Station",
    ),
    schema.Option(
        display = "Yarraman Station",
        value = "1215,Yarraman Station",
    ),
]
MerndaStopOptions = [
    schema.Option(
        display = "Bell Station",
        value = "1019,Bell Station",
    ),
    schema.Option(
        display = "Clifton Hill Station",
        value = "1041,Clifton Hill Station",
    ),
    schema.Option(
        display = "Collingwood Station",
        value = "1043,Collingwood Station",
    ),
    schema.Option(
        display = "Croxton Station",
        value = "1047,Croxton Station",
    ),
    schema.Option(
        display = "Epping Station",
        value = "1063,Epping Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Hawkstowe Station",
        value = "1227,Hawkstowe Station",
    ),
    schema.Option(
        display = "Jolimont-MCG Station",
        value = "1104,Jolimont-MCG Station",
    ),
    schema.Option(
        display = "Keon Park Station",
        value = "1109,Keon Park Station",
    ),
    schema.Option(
        display = "Lalor Station",
        value = "1112,Lalor Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Mernda Station",
        value = "1228,Mernda Station",
    ),
    schema.Option(
        display = "Merri Station",
        value = "1125,Merri Station",
    ),
    schema.Option(
        display = "Middle Gorge Station",
        value = "1226,Middle Gorge Station",
    ),
    schema.Option(
        display = "North Richmond Station",
        value = "1145,North Richmond Station",
    ),
    schema.Option(
        display = "Northcote Station",
        value = "1147,Northcote Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Preston Station",
        value = "1159,Preston Station",
    ),
    schema.Option(
        display = "Regent Station",
        value = "1160,Regent Station",
    ),
    schema.Option(
        display = "Reservoir Station",
        value = "1161,Reservoir Station",
    ),
    schema.Option(
        display = "Rushall Station",
        value = "1170,Rushall Station",
    ),
    schema.Option(
        display = "Ruthven Station",
        value = "1171,Ruthven Station",
    ),
    schema.Option(
        display = "South Morang Station",
        value = "1224,South Morang Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Thomastown Station",
        value = "1192,Thomastown Station",
    ),
    schema.Option(
        display = "Thornbury Station",
        value = "1193,Thornbury Station",
    ),
    schema.Option(
        display = "Victoria Park Station",
        value = "1201,Victoria Park Station",
    ),
    schema.Option(
        display = "West Richmond Station",
        value = "1207,West Richmond Station",
    ),
]
FrankstonStopOptions = [
    schema.Option(
        display = "Armadale Station",
        value = "1008,Armadale Station",
    ),
    schema.Option(
        display = "Aspendale Station",
        value = "1011,Aspendale Station",
    ),
    schema.Option(
        display = "Bentleigh Station",
        value = "1020,Bentleigh Station",
    ),
    schema.Option(
        display = "Bonbeach Station",
        value = "1024,Bonbeach Station",
    ),
    schema.Option(
        display = "Carrum Station",
        value = "1035,Carrum Station",
    ),
    schema.Option(
        display = "Caulfield Station",
        value = "1036,Caulfield Station",
    ),
    schema.Option(
        display = "Chelsea Station",
        value = "1038,Chelsea Station",
    ),
    schema.Option(
        display = "Cheltenham Station",
        value = "1039,Cheltenham Station",
    ),
    schema.Option(
        display = "Edithvale Station",
        value = "1060,Edithvale Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Frankston Station",
        value = "1073,Frankston Station",
    ),
    schema.Option(
        display = "Glen Huntly Station",
        value = "1081,Glen Huntly Station",
    ),
    schema.Option(
        display = "Hawksburn Station",
        value = "1089,Hawksburn Station",
    ),
    schema.Option(
        display = "Highett Station",
        value = "1095,Highett Station",
    ),
    schema.Option(
        display = "Kananook Station",
        value = "1106,Kananook Station",
    ),
    schema.Option(
        display = "Malvern Station",
        value = "1118,Malvern Station",
    ),
    schema.Option(
        display = "McKinnon Station",
        value = "1119,McKinnon Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Mentone Station",
        value = "1122,Mentone Station",
    ),
    schema.Option(
        display = "Moorabbin Station",
        value = "1132,Moorabbin Station",
    ),
    schema.Option(
        display = "Mordialloc Station",
        value = "1134,Mordialloc Station",
    ),
    schema.Option(
        display = "Ormond Station",
        value = "1152,Ormond Station",
    ),
    schema.Option(
        display = "Parkdale Station",
        value = "1154,Parkdale Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Patterson Station",
        value = "1157,Patterson Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Seaford Station",
        value = "1174,Seaford Station",
    ),
    schema.Option(
        display = "South Yarra Station",
        value = "1180,South Yarra Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Southland Station",
        value = "1001,Southland Station",
    ),
    schema.Option(
        display = "Toorak Station",
        value = "1194,Toorak Station",
    ),
]
GlenWaverleyStopOptions = [
    schema.Option(
        display = "Burnley Station",
        value = "1030,Burnley Station",
    ),
    schema.Option(
        display = "Darling Station",
        value = "1051,Darling Station",
    ),
    schema.Option(
        display = "East Malvern Station",
        value = "1058,East Malvern Station",
    ),
    schema.Option(
        display = "East Richmond Station",
        value = "1059,East Richmond Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Gardiner Station",
        value = "1075,Gardiner Station",
    ),
    schema.Option(
        display = "Glen Iris Station",
        value = "1077,Glen Iris Station",
    ),
    schema.Option(
        display = "Glen Waverley Station",
        value = "1078,Glen Waverley Station",
    ),
    schema.Option(
        display = "Heyington Station",
        value = "1094,Heyington Station",
    ),
    schema.Option(
        display = "Holmesglen Station",
        value = "1096,Holmesglen Station",
    ),
    schema.Option(
        display = "Jordanville Station",
        value = "1105,Jordanville Station",
    ),
    schema.Option(
        display = "Kooyong Station",
        value = "1110,Kooyong Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Mount Waverley Station",
        value = "1137,Mount Waverley Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Syndal Station",
        value = "1190,Syndal Station",
    ),
    schema.Option(
        display = "Tooronga Station",
        value = "1195,Tooronga Station",
    ),
]
HurstbridgeStopOptions = [
    schema.Option(
        display = "Alphington Station",
        value = "1004,Alphington Station",
    ),
    schema.Option(
        display = "Clifton Hill Station",
        value = "1041,Clifton Hill Station",
    ),
    schema.Option(
        display = "Collingwood Station",
        value = "1043,Collingwood Station",
    ),
    schema.Option(
        display = "Darebin Station",
        value = "1050,Darebin Station",
    ),
    schema.Option(
        display = "Dennis Station",
        value = "1053,Dennis Station",
    ),
    schema.Option(
        display = "Diamond Creek Station",
        value = "1054,Diamond Creek Station",
    ),
    schema.Option(
        display = "Eaglemont Station",
        value = "1056,Eaglemont Station",
    ),
    schema.Option(
        display = "Eltham Station",
        value = "1062,Eltham Station",
    ),
    schema.Option(
        display = "Fairfield Station",
        value = "1065,Fairfield Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Greensborough Station",
        value = "1084,Greensborough Station",
    ),
    schema.Option(
        display = "Heidelberg Station",
        value = "1093,Heidelberg Station",
    ),
    schema.Option(
        display = "Hurstbridge Station",
        value = "1100,Hurstbridge Station",
    ),
    schema.Option(
        display = "Ivanhoe Station",
        value = "1101,Ivanhoe Station",
    ),
    schema.Option(
        display = "Jolimont-MCG Station",
        value = "1104,Jolimont-MCG Station",
    ),
    schema.Option(
        display = "Macleod Station",
        value = "1117,Macleod Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Montmorency Station",
        value = "1130,Montmorency Station",
    ),
    schema.Option(
        display = "North Richmond Station",
        value = "1145,North Richmond Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Rosanna Station",
        value = "1168,Rosanna Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Victoria Park Station",
        value = "1201,Victoria Park Station",
    ),
    schema.Option(
        display = "Watsonia Station",
        value = "1203,Watsonia Station",
    ),
    schema.Option(
        display = "Wattle Glen Station",
        value = "1204,Wattle Glen Station",
    ),
    schema.Option(
        display = "West Richmond Station",
        value = "1207,West Richmond Station",
    ),
    schema.Option(
        display = "Westgarth Station",
        value = "1209,Westgarth Station",
    ),
]
LilydaleStopOptions = [
    schema.Option(
        display = "Auburn Station",
        value = "1012,Auburn Station",
    ),
    schema.Option(
        display = "Blackburn Station",
        value = "1023,Blackburn Station",
    ),
    schema.Option(
        display = "Box Hill Station",
        value = "1026,Box Hill Station",
    ),
    schema.Option(
        display = "Burnley Station",
        value = "1030,Burnley Station",
    ),
    schema.Option(
        display = "Camberwell Station",
        value = "1032,Camberwell Station",
    ),
    schema.Option(
        display = "Canterbury Station",
        value = "1033,Canterbury Station",
    ),
    schema.Option(
        display = "Chatham Station",
        value = "1037,Chatham Station",
    ),
    schema.Option(
        display = "Croydon Station",
        value = "1048,Croydon Station",
    ),
    schema.Option(
        display = "East Camberwell Station",
        value = "1057,East Camberwell Station",
    ),
    schema.Option(
        display = "East Richmond Station",
        value = "1059,East Richmond Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Glenferrie Station",
        value = "1080,Glenferrie Station",
    ),
    schema.Option(
        display = "Hawthorn Station",
        value = "1090,Hawthorn Station",
    ),
    schema.Option(
        display = "Heatherdale Station",
        value = "1091,Heatherdale Station",
    ),
    schema.Option(
        display = "Laburnum Station",
        value = "1111,Laburnum Station",
    ),
    schema.Option(
        display = "Lilydale Station",
        value = "1115,Lilydale Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Mitcham Station",
        value = "1128,Mitcham Station",
    ),
    schema.Option(
        display = "Mooroolbark Station",
        value = "1133,Mooroolbark Station",
    ),
    schema.Option(
        display = "Nunawading Station",
        value = "1148,Nunawading Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Ringwood Station",
        value = "1163,Ringwood Station",
    ),
    schema.Option(
        display = "Ringwood East Station",
        value = "1164,Ringwood East Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Union Station",
        value = "1229,Union Station",
    ),
]
PakenhamStopOptions = [
    schema.Option(
        display = "Armadale Station",
        value = "1008,Armadale Station",
    ),
    schema.Option(
        display = "Beaconsfield Station",
        value = "1017,Beaconsfield Station",
    ),
    schema.Option(
        display = "Berwick Station",
        value = "1021,Berwick Station",
    ),
    schema.Option(
        display = "Cardinia Road Station",
        value = "1223,Cardinia Road Station",
    ),
    schema.Option(
        display = "Carnegie Station",
        value = "1034,Carnegie Station",
    ),
    schema.Option(
        display = "Caulfield Station",
        value = "1036,Caulfield Station",
    ),
    schema.Option(
        display = "Clayton Station",
        value = "1040,Clayton Station",
    ),
    schema.Option(
        display = "Dandenong Station",
        value = "1049,Dandenong Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Hallam Station",
        value = "1085,Hallam Station",
    ),
    schema.Option(
        display = "Hawksburn Station",
        value = "1089,Hawksburn Station",
    ),
    schema.Option(
        display = "Hughesdale Station",
        value = "1098,Hughesdale Station",
    ),
    schema.Option(
        display = "Huntingdale Station",
        value = "1099,Huntingdale Station",
    ),
    schema.Option(
        display = "Malvern Station",
        value = "1118,Malvern Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Murrumbeena Station",
        value = "1138,Murrumbeena Station",
    ),
    schema.Option(
        display = "Narre Warren Station",
        value = "1139,Narre Warren Station",
    ),
    schema.Option(
        display = "Noble Park Station",
        value = "1142,Noble Park Station",
    ),
    schema.Option(
        display = "Oakleigh Station",
        value = "1150,Oakleigh Station",
    ),
    schema.Option(
        display = "Officer Station",
        value = "1151,Officer Station",
    ),
    schema.Option(
        display = "Pakenham Station",
        value = "1153,Pakenham Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Sandown Park Station",
        value = "1172,Sandown Park Station",
    ),
    schema.Option(
        display = "South Yarra Station",
        value = "1180,South Yarra Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Springvale Station",
        value = "1183,Springvale Station",
    ),
    schema.Option(
        display = "Toorak Station",
        value = "1194,Toorak Station",
    ),
    schema.Option(
        display = "Westall Station",
        value = "1208,Westall Station",
    ),
    schema.Option(
        display = "Yarraman Station",
        value = "1215,Yarraman Station",
    ),
]
SandringhamStopOptions = [
    schema.Option(
        display = "Balaclava Station",
        value = "1013,Balaclava Station",
    ),
    schema.Option(
        display = "Brighton Beach Station",
        value = "1027,Brighton Beach Station",
    ),
    schema.Option(
        display = "Elsternwick Station",
        value = "1061,Elsternwick Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Gardenvale Station",
        value = "1074,Gardenvale Station",
    ),
    schema.Option(
        display = "Hampton Station",
        value = "1086,Hampton Station",
    ),
    schema.Option(
        display = "Middle Brighton Station",
        value = "1126,Middle Brighton Station",
    ),
    schema.Option(
        display = "North Brighton Station",
        value = "1143,North Brighton Station",
    ),
    schema.Option(
        display = "Prahran Station",
        value = "1158,Prahran Station",
    ),
    schema.Option(
        display = "Richmond Station",
        value = "1162,Richmond Station",
    ),
    schema.Option(
        display = "Ripponlea Station",
        value = "1165,Ripponlea Station",
    ),
    schema.Option(
        display = "Sandringham Station",
        value = "1173,Sandringham Station",
    ),
    schema.Option(
        display = "South Yarra Station",
        value = "1180,South Yarra Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Windsor Station",
        value = "1214,Windsor Station",
    ),
]
StonyPointStopOptions = [
    schema.Option(
        display = "Baxter Station",
        value = "1015,Baxter Station",
    ),
    schema.Option(
        display = "Bittern Station",
        value = "1022,Bittern Station",
    ),
    schema.Option(
        display = "Crib Point Station",
        value = "1046,Crib Point Station",
    ),
    schema.Option(
        display = "Frankston Station",
        value = "1073,Frankston Station",
    ),
    schema.Option(
        display = "Hastings Station",
        value = "1088,Hastings Station",
    ),
    schema.Option(
        display = "Leawarra Station",
        value = "1114,Leawarra Station",
    ),
    schema.Option(
        display = "Morradoo Station",
        value = "1136,Morradoo Station",
    ),
    schema.Option(
        display = "Somerville Station",
        value = "1178,Somerville Station",
    ),
    schema.Option(
        display = "Stony Point Station",
        value = "1185,Stony Point Station",
    ),
    schema.Option(
        display = "Tyabb Station",
        value = "1197,Tyabb Station",
    ),
]
SunburyStopOptions = [
    schema.Option(
        display = "Albion Station",
        value = "1003,Albion Station",
    ),
    schema.Option(
        display = "Diggers Rest Station",
        value = "1055,Diggers Rest Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Footscray Station",
        value = "1072,Footscray Station",
    ),
    schema.Option(
        display = "Ginifer Station",
        value = "1076,Ginifer Station",
    ),
    schema.Option(
        display = "Keilor Plains Station",
        value = "1107,Keilor Plains Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Middle Footscray Station",
        value = "1127,Middle Footscray Station",
    ),
    schema.Option(
        display = "North Melbourne Station",
        value = "1144,North Melbourne Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "South Kensington Station",
        value = "1179,South Kensington Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "St Albans Station",
        value = "1184,St Albans Station",
    ),
    schema.Option(
        display = "Sunbury Station",
        value = "1187,Sunbury Station",
    ),
    schema.Option(
        display = "Sunshine Station",
        value = "1218,Sunshine Station",
    ),
    schema.Option(
        display = "Tottenham Station",
        value = "1196,Tottenham Station",
    ),
    schema.Option(
        display = "Watergardens Station",
        value = "1202,Watergardens Station",
    ),
    schema.Option(
        display = "West Footscray Station",
        value = "1206,West Footscray Station",
    ),
]
UpfieldStopOptions = [
    schema.Option(
        display = "Anstey Station",
        value = "1006,Anstey Station",
    ),
    schema.Option(
        display = "Batman Station",
        value = "1014,Batman Station",
    ),
    schema.Option(
        display = "Brunswick Station",
        value = "1029,Brunswick Station",
    ),
    schema.Option(
        display = "Coburg Station",
        value = "1042,Coburg Station",
    ),
    schema.Option(
        display = "Fawkner Station",
        value = "1066,Fawkner Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flemington Bridge Station",
        value = "1069,Flemington Bridge Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Gowrie Station",
        value = "1083,Gowrie Station",
    ),
    schema.Option(
        display = "Jewell Station",
        value = "1103,Jewell Station",
    ),
    schema.Option(
        display = "Macaulay Station",
        value = "1116,Macaulay Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Merlynston Station",
        value = "1124,Merlynston Station",
    ),
    schema.Option(
        display = "Moreland Station",
        value = "1135,Moreland Station",
    ),
    schema.Option(
        display = "North Melbourne Station",
        value = "1144,North Melbourne Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Royal Park Station",
        value = "1169,Royal Park Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Upfield Station",
        value = "1198,Upfield Station",
    ),
]
WerribeeStopOptions = [
    schema.Option(
        display = "Aircraft Station",
        value = "1220,Aircraft Station",
    ),
    schema.Option(
        display = "Altona Station",
        value = "1005,Altona Station",
    ),
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Footscray Station",
        value = "1072,Footscray Station",
    ),
    schema.Option(
        display = "Hoppers Crossing Station",
        value = "1097,Hoppers Crossing Station",
    ),
    schema.Option(
        display = "Laverton Station",
        value = "1113,Laverton Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Newport Station",
        value = "1141,Newport Station",
    ),
    schema.Option(
        display = "North Melbourne Station",
        value = "1144,North Melbourne Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Seaholme Station",
        value = "1175,Seaholme Station",
    ),
    schema.Option(
        display = "Seddon Station",
        value = "1176,Seddon Station",
    ),
    schema.Option(
        display = "South Kensington Station",
        value = "1179,South Kensington Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Spotswood Station",
        value = "1182,Spotswood Station",
    ),
    schema.Option(
        display = "Werribee Station",
        value = "1205,Werribee Station",
    ),
    schema.Option(
        display = "Westona Station",
        value = "1210,Westona Station",
    ),
    schema.Option(
        display = "Williams Landing Station",
        value = "1225,Williams Landing Station",
    ),
    schema.Option(
        display = "Yarraville Station",
        value = "1216,Yarraville Station",
    ),
]
WilliamstownStopOptions = [
    schema.Option(
        display = "Flagstaff Station",
        value = "1068,Flagstaff Station",
    ),
    schema.Option(
        display = "Flinders Street Station",
        value = "1071,Flinders Street Station",
    ),
    schema.Option(
        display = "Footscray Station",
        value = "1072,Footscray Station",
    ),
    schema.Option(
        display = "Melbourne Central Station",
        value = "1120,Melbourne Central Station",
    ),
    schema.Option(
        display = "Newport Station",
        value = "1141,Newport Station",
    ),
    schema.Option(
        display = "North Melbourne Station",
        value = "1144,North Melbourne Station",
    ),
    schema.Option(
        display = "North Williamstown Station",
        value = "1146,North Williamstown Station",
    ),
    schema.Option(
        display = "Parliament Station",
        value = "1155,Parliament Station",
    ),
    schema.Option(
        display = "Seddon Station",
        value = "1176,Seddon Station",
    ),
    schema.Option(
        display = "South Kensington Station",
        value = "1179,South Kensington Station",
    ),
    schema.Option(
        display = "Southern Cross Station",
        value = "1181,Southern Cross Station",
    ),
    schema.Option(
        display = "Spotswood Station",
        value = "1182,Spotswood Station",
    ),
    schema.Option(
        display = "Williamstown Station",
        value = "1211,Williamstown Station",
    ),
    schema.Option(
        display = "Williamstown Beach Station",
        value = "1212,Williamstown Beach Station",
    ),
    schema.Option(
        display = "Yarraville Station",
        value = "1216,Yarraville Station",
    ),
]

# Schema Options - Direction Options Per Train Line (value = direction_id,direction_name)
AlameinDirectionOptions = [
    schema.Option(
        display = "Alamein",
        value = "0,Alamein",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),0,Alamein",
    ),
]
BelgraveDirectionOptions = [
    schema.Option(
        display = "Belgrave",
        value = "3,Belgrave",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),3,Belgrave",
    ),
]
CraigieburnDirectionOptions = [
    schema.Option(
        display = "Craigieburn",
        value = "2,Craigieburn",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),2,Craigieburn",
    ),
]
CranbourneDirectionOptions = [
    schema.Option(
        display = "Cranbourne",
        value = "4,Cranbourne",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),4,Cranbourne",
    ),
]
MerndaDirectionOptions = [
    schema.Option(
        display = "Mernda",
        value = "9,Mernda",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),9,Mernda",
    ),
]
FrankstonDirectionOptions = [
    schema.Option(
        display = "Frankston",
        value = "5,Frankston",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),5,Frankston",
    ),
]
GlenWaverleyDirectionOptions = [
    schema.Option(
        display = "Glen Waverley",
        value = "6,Glen Waverley",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),6,Glen Waverley",
    ),
]
HurstbridgeDirectionOptions = [
    schema.Option(
        display = "Hurstbridge",
        value = "7,Hurstbridge",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),7,Hurstbridge",
    ),
]
LilydaleDirectionOptions = [
    schema.Option(
        display = "Lilydale",
        value = "8,Lilydale",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),8,Lilydale",
    ),
]
PakenhamDirectionOptions = [
    schema.Option(
        display = "Pakenham",
        value = "10,Pakenham",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),10,Pakenham",
    ),
]
SandringhamDirectionOptions = [
    schema.Option(
        display = "Sandringham",
        value = "11,Sandringham",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),11,Sandringham",
    ),
]
StonyPointDirectionOptions = [
    schema.Option(
        display = "Stony Point",
        value = "12,Stony Point",
    ),
    schema.Option(
        display = "Frankston",
        value = "5,Frankston",
    ),
    schema.Option(
        display = "All",
        value = "All,5,Frankston,12,Stony Point",
    ),
]
SunburyDirectionOptions = [
    schema.Option(
        display = "Sunbury",
        value = "13,Sunbury",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),13,Sunbury",
    ),
]
UpfieldDirectionOptions = [
    schema.Option(
        display = "Upfield",
        value = "14,Upfield",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),14,Upfield",
    ),
]
WerribeeDirectionOptions = [
    schema.Option(
        display = "Werribee",
        value = "15,Werribee",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),15,Werribee",
    ),
]
WilliamstownDirectionOptions = [
    schema.Option(
        display = "Williamstown",
        value = "16,Williamstown",
    ),
    schema.Option(
        display = "City (Flinders Street)",
        value = "1,City (Flinders Street)",
    ),
    schema.Option(
        display = "All",
        value = "All,1,City (Flinders Street),16,Williamstown",
    ),
]

# Helper - Generate Proper Schema Options Per Train Line
def more_options(train_line):
    if train_line == "1,Alamein":
        return [
            schema.Dropdown(
                id = "station-list-1",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = AlameinStopOptions[0].value,
                options = AlameinStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-1",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = AlameinDirectionOptions[2].value,
                options = AlameinDirectionOptions,
            ),
        ]
    elif train_line == "2,Belgrave":
        return [
            schema.Dropdown(
                id = "station-list-2",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = BelgraveStopOptions[0].value,
                options = BelgraveStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-2",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = BelgraveDirectionOptions[2].value,
                options = BelgraveDirectionOptions,
            ),
        ]
    elif train_line == "3,Craigieburn":
        return [
            schema.Dropdown(
                id = "station-list-3",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = CraigieburnStopOptions[0].value,
                options = CraigieburnStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-3",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = CraigieburnDirectionOptions[2].value,
                options = CraigieburnDirectionOptions,
            ),
        ]
    elif train_line == "4,Cranbourne":
        return [
            schema.Dropdown(
                id = "station-list-4",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = CranbourneStopOptions[0].value,
                options = CranbourneStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-4",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = CranbourneDirectionOptions[2].value,
                options = CranbourneDirectionOptions,
            ),
        ]
    elif train_line == "5,Mernda":
        return [
            schema.Dropdown(
                id = "station-list-5",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = MerndaStopOptions[0].value,
                options = MerndaStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-5",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = MerndaDirectionOptions[2].value,
                options = MerndaDirectionOptions,
            ),
        ]
    elif train_line == "6,Frankston":
        return [
            schema.Dropdown(
                id = "station-list-6",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = FrankstonStopOptions[0].value,
                options = FrankstonStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-6",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = FrankstonDirectionOptions[2].value,
                options = FrankstonDirectionOptions,
            ),
        ]
    elif train_line == "7,Glen Waverley":
        return [
            schema.Dropdown(
                id = "station-list-7",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = GlenWaverleyStopOptions[0].value,
                options = GlenWaverleyStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-7",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = GlenWaverleyDirectionOptions[2].value,
                options = GlenWaverleyDirectionOptions,
            ),
        ]
    elif train_line == "8,Hurstbridge":
        return [
            schema.Dropdown(
                id = "station-list-8",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = HurstbridgeStopOptions[0].value,
                options = HurstbridgeStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-8",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = HurstbridgeDirectionOptions[2].value,
                options = HurstbridgeDirectionOptions,
            ),
        ]
    elif train_line == "9,Lilydale":
        return [
            schema.Dropdown(
                id = "station-list-9",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = LilydaleStopOptions[0].value,
                options = LilydaleStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-9",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = LilydaleDirectionOptions[2].value,
                options = LilydaleDirectionOptions,
            ),
        ]
    elif train_line == "11,Pakenham":
        return [
            schema.Dropdown(
                id = "station-list-11",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = PakenhamStopOptions[0].value,
                options = PakenhamStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-11",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = PakenhamDirectionOptions[2].value,
                options = PakenhamDirectionOptions,
            ),
        ]
    elif train_line == "12,Sandringham":
        return [
            schema.Dropdown(
                id = "station-list-12",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = SandringhamStopOptions[0].value,
                options = SandringhamStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-12",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = SandringhamDirectionOptions[2].value,
                options = SandringhamDirectionOptions,
            ),
        ]
    elif train_line == "13,Stony Point":
        return [
            schema.Dropdown(
                id = "station-list-13",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = StonyPointStopOptions[0].value,
                options = StonyPointStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-13",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = StonyPointDirectionOptions[2].value,
                options = StonyPointDirectionOptions,
            ),
        ]
    elif train_line == "14,Sunbury":
        return [
            schema.Dropdown(
                id = "station-list-14",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = SunburyStopOptions[0].value,
                options = SunburyStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-14",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = SunburyDirectionOptions[2].value,
                options = SunburyDirectionOptions,
            ),
        ]
    elif train_line == "15,Upfield":
        return [
            schema.Dropdown(
                id = "station-list-15",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = UpfieldStopOptions[0].value,
                options = UpfieldStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-15",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = UpfieldDirectionOptions[2].value,
                options = UpfieldDirectionOptions,
            ),
        ]
    elif train_line == "16,Werribee":
        return [
            schema.Dropdown(
                id = "station-list-16",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = WerribeeStopOptions[0].value,
                options = WerribeeStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-16",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = WerribeeDirectionOptions[2].value,
                options = WerribeeDirectionOptions,
            ),
        ]
    elif train_line == "17,Williamstown":
        return [
            schema.Dropdown(
                id = "station-list-17",
                name = "Train Station",
                desc = "Choose your station",
                icon = "train",
                default = WilliamstownStopOptions[0].value,
                options = WilliamstownStopOptions,
            ),
            schema.Dropdown(
                id = "direction-list-17",
                name = "Direction",
                desc = "Choose your direction",
                icon = "arrow-right",
                default = WilliamstownDirectionOptions[2].value,
                options = WilliamstownDirectionOptions,
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
                id = "train-line",
                name = "Train Line",
                desc = "Chose your train line",
                icon = "train",
                default = TrainLineOptions[0].value,
                options = TrainLineOptions,
            ),
            schema.Generated(
                id = "generated",
                source = "train-line",
                handler = more_options,
            ),
        ],
    )

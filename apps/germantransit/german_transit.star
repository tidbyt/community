"""
Applet: German Transit
Summary: German transit departures
Description: Provides upcoming train and bus departures for a given station throughout Germany, based on consolidated data from VRN.
Author: kmartinez834
"""

#Majority of the code is based on the berlin transit app by flambeauRiverTours

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#Constants for the VRN API
VRN_API_BASE_URL = "https://www.vrn.de/mngvrn/"
DEPARTURE_BOARD_PREFIX = "XML_DM_REQUEST?"
LOCATION_SEARCH_PREFIX = "XML_STOPFINDER_REQUEST?"

#Styling stuff
ORANGE = "#FFA500"
WHITE = "#FFFFFF"
GREEN = "#0AE300"
RED = "E33954"
PURPLE = "#B40DF7"
BLUE = "0093E6"
GRAY = "8E949E"
FONT = "tb-8"
MINUTES_TO_DEPARTURE_COLOR_THRESHOLD = 5  #if the time until departure is less than this, we'll color it orange
MAX_DEPATURES_PER_FRAME = 2  #maximum number of departures to display per frame
TOTAL_FRAME_DURATION = 300  #duration of all frames in the animation

#Modality icons
U_BAHN_ICON = "https://upload.wikimedia.org/wikipedia/commons/e/ee/U-Bahn_Berlin_logo.svg"
S_BAHN_ICON = "https://www.vrn.de/images/icons/vrn-icon-auskunft-sbahn.svg"
TRAM_ICON = "https://www.vrn.de/images/icons/vrn-icon-auskunft-straba.svg"
BUS_ICON = "https://www.vrn.de/images/icons/vrn-icon-auskunft-bus.svg"
REGIONAL_ICON = "https://www.vrn.de/images/icons/vrn-icon-auskunft-zug.svg"
ICE_ICON = "https://www.vrn.de/images/icons/vrn-icon-auskunft-zug-fern.svg"

#configuration keys
CONFIG_STATION = "station"
CONFIG_STATION_VALUE = "value"
CONFIG_STATION_ID = "station_id"
CONFIG_STATION_NAME = "station_name"
CONFIG_SHOW_U_BAHN = "uBahn"
CONFIG_SHOW_S_BAHN = "sBahn"
CONFIG_SHOW_TRAM = "tram"
CONFIG_SHOW_BUS = "bus"
CONFIG_SHOW_REGIONAL = "regional"
CONFIG_SHOW_ICE = "ice"
CONFIG_DEPARTURE_TIME_OFFSET = "departure_time_offset"
CONFIG_DEPARTURE_TIME_OFFSET_VALUES = [0, 5, 10, 15, 20, 25, 30]

#keys for departure data dictionaries
DEPARTURE_ICON = "icon"
DEPARTURE_DATA_LINE = "line"
DEPARTURE_DATA_LINE_COLOR = "lineColor"
DEPARTURE_DATA_DIRECTION = "direction"
DEPARTURE_DATA_TIME_UNTIL_DEPARTURE = "timeUntilDeparture"
DEPARTURE_DATA_TIME_COLOR = "timeColor"

#product classes for the VRN API
PRODUCT_CLASS_S_BAHN = [1]
PRODUCT_CLASS_U_BAHN = [2]
PRODUCT_CLASS_TRAM = [3, 4]
PRODUCT_CLASS_BUS = [5, 6, 7]
PRODUCT_CLASS_REGIONAL = [13]
PRODUCT_CLASS_ICE = [14, 15, 16]

#Time-related constants
BERLIN_TIMEZONE = "Europe/Berlin"

#Departure Board API Tuning Parameters
MAX_DEPARTURES = 8  #maximum number of departures to fetch
MAX_MINUTES_IN_FUTURE = "59"  #limit to departures in the next hour
DEPARTURES_TTL_CACHE_LENGTH_SECONDS = 60  #cache the departure board for one minute
ICON_TTL_CACHE_LENGTH_SECONDS = 14400  #cache the modality icon for 4 hours
JSON_FORMAT = "json"

#Station Lookup API Tuning Parameters
MAX_STATIONS_TO_FETCH = "10"  #maximum number of stations to fetch
STATIONS_TTL_CACHE_LENGTH_SECONDS = 604800  #cache the station lookup for one week

#Strings displayed to the end user
MINUTES_ABBREVIATION = "m"
NO_DEPARTURES_FOUND = "No departures found"

#Main app entry point. Fetches the departures for the selected station and renders them
#config: the configuration for the app. See https://tidbyt.dev/docs/build/authoring-apps
def main(config):
    if not config:
        return get_error_message("No configuration provided")

    #Parse the station data. The "value" field is a stringified JSON object holding the station-id and station-name
    station = config.get(CONFIG_STATION)
    if not station:
        return get_error_message("No station selected")
    data = json.decode(json.decode(station)[CONFIG_STATION_VALUE])
    station_id = data[CONFIG_STATION_ID]
    if not station_id:
        return get_error_message("No station selected")

    #Pull product class configurations from the schema
    show_u_bahn = config.bool(CONFIG_SHOW_U_BAHN, True)
    show_s_bahn = config.bool(CONFIG_SHOW_S_BAHN, True)
    show_tram = config.bool(CONFIG_SHOW_TRAM, True)
    show_bus = config.bool(CONFIG_SHOW_BUS, True)
    show_regional = config.bool(CONFIG_SHOW_REGIONAL, True)
    show_ice = config.bool(CONFIG_SHOW_ICE, True)

    product_list = parse_class_configs(show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice)

    #Pull the departure time offset from the schema
    offset_minutes = int(config.get(CONFIG_DEPARTURE_TIME_OFFSET))
    if not offset_minutes in CONFIG_DEPARTURE_TIME_OFFSET_VALUES:
        return get_error_message("Invalid departure time offset selected")

    departures = get_station_departures(station_id, product_list, offset_minutes)

    return get_root_element(departures)

#RENDERING FUNCTIONS

#Renders the root element for the app
#departures: the list of departures to render
def get_root_element(departures):
    return render.Root(
        max_age = 120,
        child = render.Column(
            children = [
                render_departures(departures),
            ],
        ),
    )

#Renders the departures for a station. Rotates through sets of two rows at a time
#departures: the list of departures to render
def render_departures(departures):
    if len(departures) == 0:  #Show no
        return render.Box(
            width = 64,
            child = render.WrappedText(
                content = NO_DEPARTURES_FOUND,
                width = 62,
                align = "center",
                color = ORANGE,
                font = FONT,
            ),
        )

    frames = []
    frame_duration = int(TOTAL_FRAME_DURATION / math.ceil(len(departures) / MAX_DEPATURES_PER_FRAME))
    for i in range(0, len(departures), MAX_DEPATURES_PER_FRAME):
        frame = render_departures_frame(departures[i:i + MAX_DEPATURES_PER_FRAME])
        frames.extend([frame] * frame_duration)
    return render.Sequence(
        children = [
            render.Animation(frames[i:i + frame_duration])
            for i in range(0, len(frames), frame_duration)
        ],
    )

#Add a a row for each departure
#departures: the list of departures to render
def render_departures_frame(departures):
    return render.Column(
        expanded = True,
        main_align = "space_around" if len(departures) == 2 else "start",
        children = [
            render.Row(
                cross_align = "end",
                expanded = True,
                children = [
                    render.Padding(
                        pad = (0, 0, 1, 0),
                        child = render.Image(
                            src = departure[DEPARTURE_ICON],
                            width = 14,
                            height = 14,
                        ),
                    ),
                    render.Column(
                        children = [
                            render.Row(
                                children = [
                                    render.WrappedText(
                                        content = departure[DEPARTURE_DATA_LINE].upper(),
                                        color = departure[DEPARTURE_DATA_LINE_COLOR],
                                        font = FONT,
                                        width = 24,
                                        height = 7,
                                        align = "left",
                                    ),
                                    render.WrappedText(
                                        content = str(departure[DEPARTURE_DATA_TIME_UNTIL_DEPARTURE]) + MINUTES_ABBREVIATION,
                                        color = departure[DEPARTURE_DATA_TIME_COLOR],
                                        font = FONT,
                                        width = 24,
                                        height = 7,
                                        align = "right",
                                    ),
                                ],
                            ),
                            render.Marquee(
                                offset_start = 5,
                                width = 47,
                                child = render.Text(
                                    departure[DEPARTURE_DATA_DIRECTION],
                                    height = 8,
                                    font = FONT,
                                ),
                            ),
                        ],
                    ),
                ],
            )
            for departure in departures
        ],
    )

#Loads the departure icon for display in the board. Converts the fill color to white.
#url: the url of the icon svg
#Returns the xml string
def load_image(url):
    img = http.get(url, ttl_seconds = ICON_TTL_CACHE_LENGTH_SECONDS).body()
    img = img.replace("0664ab", "000000")
    return img.replace("#032D57", WHITE)

#Parses the station name for display in the marquee. Removes common formatting that isn't helpful for display
#station_name: the name of the station to parse
#Returns the parsed station name
def parse_station_name(station_name):
    abbr_name = strip_common_abbrev(station_name.upper())
    split_name = abbr_name.split(" ")
    if (is_common_prefix(split_name[0])):
        split_name.pop(0)
    return trim_station_name(split_name)

#Checks if a station name has a common name that can be abbreviated
#name: the name of the station to check
#Replaces common name with abbreviation
def strip_common_abbrev(name):
    name = name.replace("HAUPTBAHNHOF", "HBF")
    name = name.replace("BAHNHOF", "BF")
    name = name.replace("FLUGHAFEN", "FLUGH")
    return name.replace(",", "")

#Checks if a station name has a common prefix that isn't helpful for display
#name: the name of the station to check
#Returns whether the name is a common prefix
def is_common_prefix(name):
    return name == "S" or name == "U" or name == "S+U"

#Finds separators and capitalizes each segment
#E.g. -> "Hans-thoma-platz/heidelberg" -> "Hans-Thoma-Platz/Heidelberg"
def capitalize_piece(name):
    name_list = []
    for i in name.split("-"):
        for j in i.split("/"):
            name_list.append("/".join([j.capitalize()]))
    return "-".join(name_list)

#Excludes any parentheticals and formats each segment
# E.g. -> "Botzow. (Berlin)" -> "Botzow."
def trim_station_name(split_name):
    result_name = ""
    for name_piece in split_name[0:]:
        if name_piece[0:1] == "(":
            continue
        if not result_name == "":  #prepend a space if we're not at the beginning of the name to avoid trailing spaces
            result_name += " "
        result_name += capitalize_piece(name_piece)
    return result_name

#spits out an error message onto the tidbyt if the app is configured incorrectly
def get_error_message(errorMessage):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(errorMessage),
        ),
    )

#DEPARTUREBOARD REQUEST FUNCTIONS

#Fetches the departures for a station from the VRN departure board API
#station_id: the ID of the station to fetch departures for. Pulled from the schema
#included_mots: the modes of transportation to be included in the request
#departure_offset_minutes: exclude departures leaving within the offset minutes parameter
#Returns a list of dictionaries, each representing a departure
def get_station_departures(station_id, included_mots, departure_offset_minutes):
    params = {
        "name_dm": station_id,
        "limit": str(MAX_DEPARTURES),
        "outputFormat": JSON_FORMAT,
        "type_dm": "any",
        "depType": "stopEvents",
        "mode": "direct",
        "useRealtime": "1",
        "coordOutputFormat": "EPSG:4326",
        "includeCompleteStopSeq": "1",
        "locationServerActive": "1",
        "useOnlyStops": "1",
        "includedMeans": "checkbox",
    }

    departure_req = DEPARTURE_BOARD_PREFIX
    for mot in included_mots:
        departure_req += "&inclMOT_" + str(mot)
        departure_req += "&includedMeans=" + str(mot)

    if departure_offset_minutes > 0:  #we only need to add the time parameter if we're not looking for immediate departures - it defautls to now
        params["timeOffset"] = str(departure_offset_minutes)

    resp = execute_http_get(departure_req, params, DEPARTURES_TTL_CACHE_LENGTH_SECONDS)
    return parse_departures_json(resp)

#Executes an HTTP GET request to the specified VRN API endpoint.  Fails the app if the request fails
#vrn_api_prefix_params: the prefix for the VRN API endpoint
#request_params: the parameters to pass to the VRN API
#ttl_seconds: the time-to-live for the cache
#Returns the response from the VRN API
def execute_http_get(vrn_api_prefix_params, request_params, ttl_seconds):
    http_response = http.get(VRN_API_BASE_URL + "/" + vrn_api_prefix_params, params = request_params, ttl_seconds = ttl_seconds)
    check_http_status_code(http_response, vrn_api_prefix_params)
    return http_response

#Rounds the minutes of a time or duration object to the nearest minute
#minutes: the minutes to round
#seconds: the seconds to round
#Returns the rounded minutes
def get_rounded_minutes(minutes, seconds):
    minutes = math.floor(minutes)
    minutes += 1 if seconds > 30 else 0  #round up if we're more than 30 seconds into the next minute
    return minutes

#Gets the current time in Berlin
#Returns the current time in Berlin as a time object
def get_time_now_in_berlin():
    return time.now().in_location(BERLIN_TIMEZONE)

#Gets the modality classes to show from the schema
#show_u_bahn: whether to show U-Bahn departures
#show_s_bahn: whether to show S-Bahn departures
#show_tram: whether to show tram departures
#show_bus: whether to show bus departures
#show_regional: whether to show regional train departures
#show_ice: whether to show ICE train departuress
#Returns a list of integers corresponding to the modes of transportation to include
def parse_class_configs(show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice):
    product = []
    if show_u_bahn:
        for id in PRODUCT_CLASS_U_BAHN:
            product.append(id)
    if show_s_bahn:
        for id in PRODUCT_CLASS_S_BAHN:
            product.append(id)
    if show_tram:
        for id in PRODUCT_CLASS_TRAM:
            product.append(id)
    if show_bus:
        for id in PRODUCT_CLASS_BUS:
            product.append(id)
    if show_regional:
        for id in PRODUCT_CLASS_REGIONAL:
            product.append(id)
    if show_ice:
        for id in PRODUCT_CLASS_ICE:
            product.append(id)
    return product

#Fails the app if the HTTP request fails
#resp: the response object from the HTTP request
#api_name_invoked: the name of the API that was invoked
def check_http_status_code(resp, api_name_invoked):
    if resp.status_code != 200:
        print(api_name_invoked + " request failed with status _" + str(resp.status_code))

#DEPARTUREBOARD RESPONSE PARSING FUNCTIONS

#Parses the JSON response from the VRN departure board API
#http_response: the JSON response from the VRN departure board API
#Returns a list of dictionaries, each representing a departure. See parse_departure for the structure of each dictionary
def parse_departures_json(http_response):
    departures_data = []  #parse out all departures, return them in a list

    #no departures found. Check this separately because http_response.json()["departureList"] will throw an error if there are no departures
    if not http_response.json()["departureList"]:
        return departures_data

    #if there is only one departure, convert to list for parsing
    departure_list = http_response.json()["departureList"]
    if type(departure_list) == "dict":
        departure_list = [departure_list["departure"]]

    #parse the departure list
    for departures in departure_list:
        parsed_departure = parse_departure(departures)
        if parsed_departure:  #don't add None departures
            departures_data.append(parsed_departure)

    return sort_departures(departures_data)

#Parse the relevant data from a departure JSON object
#Input should be a JSON object returned by the VRN departure board API representing a single departure
#Returns a dictionary with the parsed data:
#- DEPARTURE_DATA_DIRECTION: the terminal stop of the train
#- DEPARTURE_DATA_TIME_UNTIL_DEPARTURE: the time until the train departs in minutes
#- DEPARTURE_DATA_TIME_COLOR: the color of the time until departure text (orange if less than 5 minutes, white otherwise)
#- DEPARTURE_ICON: the icon of the mode of transportation
#- DEPARTURE_DATA_LINE: the line number of the train
#- DEPARTURE_DATA_LINE_COLOR: the color of the line number text
def parse_departure(departure_json):
    time_until_departure = get_minutes_until_departure(departure_json)
    if not check_time_until_departure_valid_for_board(time_until_departure):  #don't show invalid departures
        return None

    product_at_stop = departure_json.get("servingLine")  #internal structure in the JSON response that holds more data about the product
    return {
        DEPARTURE_DATA_DIRECTION: parse_station_name(product_at_stop.get("direction")),
        DEPARTURE_DATA_TIME_UNTIL_DEPARTURE: time_until_departure,
        DEPARTURE_DATA_TIME_COLOR: get_time_color(time_until_departure),
        DEPARTURE_ICON: parse_icon(product_at_stop),
        DEPARTURE_DATA_LINE: parse_line(product_at_stop),
        DEPARTURE_DATA_LINE_COLOR: parse_color(product_at_stop),
    }

#Checks if the time until departure is valid for display on the board
#time_until_departure: the number of minutes until the train departs
#Returns whether the time until departure is valid for display on the board
def check_time_until_departure_valid_for_board(time_until_departure):
    if not time_until_departure or time_until_departure == 0:  #don't show departures that are already gone
        return False
    if time_until_departure > int(MAX_MINUTES_IN_FUTURE):  #no room for three-digit numbers on the board
        return False
    return True

#Fetch the icon to display for the modality
#product_at_stop: the JSON object representing the product at the stop
#Returns the icon of modality
def parse_icon(product_at_stop):
    product_type = int(product_at_stop.get("motType"))
    if product_type in PRODUCT_CLASS_S_BAHN:
        return load_image(S_BAHN_ICON)
    if product_type in PRODUCT_CLASS_U_BAHN:
        return load_image(U_BAHN_ICON)
    if product_type in PRODUCT_CLASS_TRAM:
        return load_image(TRAM_ICON)
    if product_type in PRODUCT_CLASS_BUS:
        return load_image(BUS_ICON)
    if product_type in PRODUCT_CLASS_REGIONAL:
        return load_image(REGIONAL_ICON)
    if product_type in PRODUCT_CLASS_ICE:
        return load_image(ICE_ICON)
    return load_image(REGIONAL_ICON)

#formats the line number for display. If the line number is not available, uses the second word in the product name
#product_at_stop: the JSON object representing the product at the stop
#Returns the line number or ICE train name
def parse_line(product_at_stop):
    line = product_at_stop.get("symbol")
    if line:
        return line
    else:
        name = product_at_stop.get("trainNum")
        return "I" + name  #ICE trains don't have line numbers, so we'll use the number instead

#Fetch the color to display for the modality
#product_at_stop: the JSON object representing the product at the stop
#Returns the color of the line number text
def parse_color(product_at_stop):
    product_type = int(product_at_stop.get("motType"))
    if product_type in PRODUCT_CLASS_S_BAHN:
        return GREEN
    if product_type in PRODUCT_CLASS_U_BAHN:
        return BLUE
    if product_type in PRODUCT_CLASS_TRAM:
        return RED
    if product_type in PRODUCT_CLASS_BUS:
        return PURPLE
    if product_type in PRODUCT_CLASS_REGIONAL:
        return GRAY
    if product_type in PRODUCT_CLASS_ICE:
        return WHITE
    return WHITE

#Returns the color of the time until departure text. Currently, marks departure times in orange if they are less than 5 minutes away, otherwise green
#time_until_departure: the number of minutes until the train departs
#Returns the color of the time until departure text as a hex string (with a prepended #)
def get_time_color(time_until_departure):
    if time_until_departure < MINUTES_TO_DEPARTURE_COLOR_THRESHOLD:
        return ORANGE
    return GREEN

#Retrieves the number of minutes until a train departs from the JSON response from the VRN API
#departure_json: the JSON object representing a single departure from the VRN API
#Returns the rounded number of minutes until the train departs, or None if the departure time is in the past. Will return 0 if the departure is less than 30 seconds in the future,
def get_minutes_until_departure(departure_json):
    if not departure_json.get("realDateTime"):
        departure_rt = departure_json.get("dateTime")
    else:
        departure_rt = departure_json.get("realDateTime")

    year = departure_rt["year"]
    month = departure_rt["month"]
    day = departure_rt["day"]
    hour = departure_rt["hour"]
    minute = departure_rt["minute"]

    now = get_time_now_in_berlin()
    departure_time_object = time.time(year = int(year), month = int(month), day = int(day), hour = int(hour), minute = int(minute), location = BERLIN_TIMEZONE)

    if now > departure_time_object:  #we don't care about past departures
        return None
    date_diff = departure_time_object - now  #subtracting two time objects gives us a Duration object representing the difference
    return get_rounded_minutes(date_diff.minutes, date_diff.seconds)

#Sorts the departures by time until departure
#departures: the list of departures to sort
#Returns the sorted list of departures
def sort_departures(departures):
    return sorted(departures, key = lambda x: x[DEPARTURE_DATA_TIME_UNTIL_DEPARTURE])

#SCHEMA FUNCTIONS

#Returns the schema for the app. See https://tidbyt.dev/docs/reference/schema
def get_schema():
    departure_time_offset_options = get_departure_time_offset_options()
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = CONFIG_STATION,
                name = "Station",
                desc = "A list of stations based on a location.",
                icon = "train",
                handler = get_stations,
            ),
            schema.Dropdown(
                id = CONFIG_DEPARTURE_TIME_OFFSET,
                name = "Departure Time Offset",
                desc = "Use this option to filter out departures within the selected number of minutes.",
                icon = "gear",
                options = departure_time_offset_options,
                default = departure_time_offset_options[0].value,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_U_BAHN,
                name = "U-Bahn",
                desc = "Toggle on/off U-Bahn departures.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_S_BAHN,
                name = "S-Bahn",
                desc = "Toggle on/off S-Bahn departures.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_TRAM,
                name = "Tram",
                desc = "Toggle on/off tram departures.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_BUS,
                name = "Bus",
                desc = "Toggle on/off bus departures.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_REGIONAL,
                name = "Regional Trains",
                desc = "Toggle on/off regional train departures.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = CONFIG_SHOW_ICE,
                name = "ICE Trains",
                desc = "Toggle on/off ICE train departures.",
                icon = "gear",
                default = True,
            ),
        ],
    )

#Returns the options for the departure time offset dropdown as a list of schema.Option objects
def get_departure_time_offset_options():
    options = []
    for minutes in CONFIG_DEPARTURE_TIME_OFFSET_VALUES:
        options.append(schema.Option(display = str(minutes), value = str(minutes)))
    return options

#Given a location as provided by the LocationBased schema, returns a list of stations near that location for selection by the user
#location: a JSON object representing a location, as provided by the LocationBased schema
#Returns a list of schema.Option objects representing the stations near the location
def get_stations(location):
    found_stations = []

    stations_json = fetch_stations(json.decode(location))
    if not stations_json:
        return found_stations
    for station in stations_json["stopFinder"]["itdOdvAssignedStops"]:
        station_id = station.get("stopID")
        if not station_id:  #the ID is critical for later operations. If we don't have one, throw this stop out
            continue
        station_name = station.get("nameWithPlace")
        if not station_name:  #How will a user know what station they're selecting if it doesn't have a name?
            continue
        option = schema.Option(
            display = station.get("nameWithPlace"),
            value = json.encode({CONFIG_STATION_ID: station_id, CONFIG_STATION_NAME: station_name}),
        )
        found_stations.append(option)
        if len(found_stations) == MAX_STATIONS_TO_FETCH:
            break

    return found_stations

#Fetches the stations near a location from the VRN API
#location: a JSON object representing a location, as provided by the LocationBased schema
#Returns the JSON response from the VRN API
def fetch_stations(location):
    truncated_lat = math.round(1000.0 * float(location["lat"])) / 1000.0  # Truncate to 3dp for better caching and to protect user privacy
    truncated_lng = math.round(1000.0 * float(location["lng"])) / 1000.0  # Means to the nearest ~110 metres.
    params = {
        "type_sf": "coord",
        "name_sf": "coord:" + str(truncated_lat) + ":" + str(truncated_lng) + ":WGS84[dd.ddddd]",
        "anyObjFilter_sf": "2",  #limits this to just stations
        "outputFormat": JSON_FORMAT,
        "coordOutputFormat": "EPSG:4326",
        "locationServerActive": "1",
    }
    resp = execute_http_get(LOCATION_SEARCH_PREFIX, params, STATIONS_TTL_CACHE_LENGTH_SECONDS)
    if not resp.json().get("stopFinder"):
        return None

    return resp.json()

"""
Applet: Berlin Transit
Summary: Trains/Bus in Berlin
Description: Provides upcoming train and bus departures for a given Berlin station.
Author: flambeauRiverTours
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

#Constants for the VBB API
VBB_API_BASE_URL = "https://fahrinfo.vbb.de/restproxy/2.32/"
DEPARTURE_BOARD_PREFIX = "departureBoard"
LOCATION_SEARCH_PREFIX = "location.nearbystops"
VBB_API_ACCESS_ID = "AV6+xWcEI8CsOUIFnXt0vF1LdXyxqE5dXpHL81cPAKdfM2GVcejYVFUlAellkLXdCLl00kJwil5IZHItOndUUwBqoYocm23s1EXe/fB1G78M6+qU/zU5uYk5wB2tFM8+XupxRRk2HTdwAZEk0ZS4R78jZyLVX/HsP73pW+fCR8dkHRQ="

#Styling stuff
ORANGE = "#FFA500"
WHITE = "#FFFFFF"
GREEN = "#0AE300"
FONT = "tom-thumb"
LINE_NAME_LENGTH_MIN_FOR_EXTRA_PADDING = 4  #if the line name length is equal to or longer than this, we'll give it extra padding
MINUTES_TO_DEPARTURE_COLOR_THRESHOLD = 5  #if the time until departure is less than this, we'll color it orange
MAX_STATION_NAME_LENGTH = 16  #maximum length of the station name to display
MAX_DIRECTION_NAME_LENGTH = 9  #maximum length of the direction name to display
MAX_DEPATURES_PER_FRAME = 4  #maximum number of departures to display per frame
FRAME_DURATION = 120  #duration of each frame in the animation

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
DEPARTURE_DATA_LINE = "line"
DEPARTURE_DATA_LINE_COLOR = "lineColor"
DEPARTURE_DATA_DIRECTION = "direction"
DEPARTURE_DATA_TIME_UNTIL_DEPARTURE = "timeUntilDeparture"
DEPARTURE_DATA_TIME_COLOR = "timeColor"

#product classes for the VBB API
PRODUCT_CLASS_S_BAHN = 0
PRODUCT_CLASS_U_BAHN = 1
PRODUCT_CLASS_TRAM = 2
PRODUCT_CLASS_BUS = 3
PRODUCT_CLASS_ICE = 5
PRODUCT_CLASS_REGIONAL = 6

#Time-related constants
BERLIN_TIMEZONE = "Europe/Berlin"

#Departure Board API Tuning Parameters
MAX_DEPARTURES = "20"  #maximum number of departures to fetch
MAX_MINUTES_IN_FUTURE = "59"  #limit to departures in the next hour
DEPARTURES_TTL_CACHE_LENGTH_SECONDS = 60  #cache the departure board for one minute
JSON_FORMAT = "JSON"

#Station Lookup API Tuning Parameters
MAX_DISTANCE_FROM_STATION_METERS = "300"  #radius from the user's location for station lookcup
MAX_STATIONS_TO_FETCH = "5"  #maximum number of stations to fetch
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
    station_name = parse_station_name(data[CONFIG_STATION_NAME])
    if not station_id:
        return get_error_message("No station selected")

    #Pull product class configurations from the schema
    show_u_bahn = config.bool(CONFIG_SHOW_U_BAHN, True)
    show_s_bahn = config.bool(CONFIG_SHOW_S_BAHN, True)
    show_tram = config.bool(CONFIG_SHOW_TRAM, True)
    show_bus = config.bool(CONFIG_SHOW_BUS, True)
    show_regional = config.bool(CONFIG_SHOW_REGIONAL, True)
    show_ice = config.bool(CONFIG_SHOW_ICE, True)

    #Pull the departure time offset from the schema
    offset_minutes = int(config.get(CONFIG_DEPARTURE_TIME_OFFSET))
    if not offset_minutes in CONFIG_DEPARTURE_TIME_OFFSET_VALUES:
        return get_error_message("Invalid departure time offset selected")

    departures = get_station_departures(station_id, show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice, offset_minutes)
    return get_root_element(departures, station_name)

#RENDERING FUNCTIONS

#Renders the root element for the app
#departures: the list of departures to render
#station_name: the name of the station to render
def get_root_element(departures, station_name):
    return render.Root(
        max_age = 120,
        delay = 25,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    child = render.Padding(
                        pad = (1, 1, 1, 0),
                        child = render.Column(
                            children = [
                                #Marquee to be safe - should be limited to 15 characters
                                render.Marquee(
                                    width = 62,
                                    align = "center",
                                    child = render.Text(
                                        content = station_name,
                                        font = FONT,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                render_departures(departures),
            ],
        ),
    )

#Renders the departures for a station. Rotates through sets of four rows at a time
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
    for i in range(0, len(departures), MAX_DEPATURES_PER_FRAME):
        frame = render_departures_frame(departures[i:i + MAX_DEPATURES_PER_FRAME])
        frames.extend([frame] * FRAME_DURATION)
    return render.Animation(
        children = frames,
    )

#Add a a row of text for each departure
#departures: the list of departures to render
def render_departures_frame(departures):
    return render.Column(
        main_align = "space_evenly",
        expanded = True,
        children = [
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.WrappedText(
                            content = departure[DEPARTURE_DATA_LINE],
                            color = departure[DEPARTURE_DATA_LINE_COLOR],
                            font = FONT,
                            width = 20 if should_use_extra_line_padding(departure) else 16,
                            height = 6,
                            align = "left",
                        ),
                        render.WrappedText(
                            content = departure[DEPARTURE_DATA_DIRECTION],
                            font = FONT,
                            width = 28 if should_use_extra_line_padding(departure) else 32,
                            height = 6,
                            align = "left",
                        ),
                        render.WrappedText(
                            content = str(departure[DEPARTURE_DATA_TIME_UNTIL_DEPARTURE]) + MINUTES_ABBREVIATION,
                            color = departure[DEPARTURE_DATA_TIME_COLOR],
                            font = FONT,
                            width = 12,
                            height = 6,
                            align = "right",
                        ),
                    ],
                ),
            )
            for departure in departures
        ],
    )

#Parses the station name for display in the marquee. Removes common formatting that isn't helpful for display
#station_name: the name of the station to parse
#Returns the parsed station name
def parse_station_name(station_name):
    split_name = station_name.split(" ")
    if (is_common_prefix(split_name[0])):
        split_name.pop(0)
        return trim_station_name(split_name)
    else:
        return trim_station_name(split_name)

#Checks if a station name has a common prefix that isn't helpful for display
#name: the name of the station to check
#Returns whether the name is a common prefix
def is_common_prefix(name):
    return name == "S" or name == "U" or name == "S+U"

#Trims the station name to 15 characters, excluding any parentheticals
# E.g. -> "Botzow. (Berlin)" -> "Botzow."
def trim_station_name(split_name):
    result_name = ""
    for name_piece in split_name[0:]:
        if name_piece[0:1] == "(":
            continue
        if not result_name == "":  #prepend a space if we're not at the beginning of the name to avoid trailing spaces
            result_name += " "
        result_name += name_piece
    return result_name[:MAX_STATION_NAME_LENGTH - 1]

#spits out an error message onto the tidbyt if the app is configured incorrectly
def get_error_message(errorMessage):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(errorMessage),
        ),
    )

#Determines whether a line name is long enough to warrant extra padding
#departure: the departure data to check
#Returns whether the line name is long enough to warrant extra padding
def should_use_extra_line_padding(departure):
    return len(departure[DEPARTURE_DATA_LINE]) >= LINE_NAME_LENGTH_MIN_FOR_EXTRA_PADDING

#DEPARTUREBOARD REQUEST FUNCTIONS

#Fetches the departures for a station from the VBB departure board API
#station_id: the ID of the station to fetch departures for. Pulled from the schema
#show_u_bahn: whether to show U-Bahn departures
#show_s_bahn: whether to show S-Bahn departures
#show_tram: whether to show tram departures
#show_bus: whether to show bus departures
#show_regional: whether to show regional train departures
#show_ice: whether to show ICE train departuress
#Returns a list of dictionaries, each representing a departure
def get_station_departures(station_id, show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice, departure_offset_minutes):
    product = compute_product_bitwise(show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice)
    if product == "0":  #no products selected
        return []

    params = {
        "accessId": get_VBB_API_access_id(),
        "id": station_id,
        "maxJourneys": MAX_DEPARTURES,
        "format": JSON_FORMAT,
        "products": product,
        "duration": MAX_MINUTES_IN_FUTURE,
    }

    if departure_offset_minutes > 0:  #we only need to add the time parameter if we're not looking for immediate departures - it defautls to now
        params["time"] = get_departure_board_request_time(departure_offset_minutes)

    resp = execute_http_get(DEPARTURE_BOARD_PREFIX, params, DEPARTURES_TTL_CACHE_LENGTH_SECONDS)
    return parse_departures_json(resp)

#Executes an HTTP GET request to the specified VBB API endpoint.  Fails the app if the request fails
#vbb_api_prefix_params: the prefix for the VBB API endpoint
#request_params: the parameters to pass to the VBB API
#ttl_seconds: the time-to-live for the cache
#Returns the response from the VBB API
def execute_http_get(vbb_api_prefix_params, request_params, ttl_seconds):
    http_response = http.get(VBB_API_BASE_URL + "/" + vbb_api_prefix_params, params = request_params, ttl_seconds = ttl_seconds)
    check_http_status_code(http_response, vbb_api_prefix_params)
    return http_response

#Gets the time string to pass to the VBB API for the departure board request
#offset_minutes: the number of minutes to offset the request time by
#Returns the time string to pass to the VBB API for the departure board request, formatted as HH:MM:SS
def get_departure_board_request_time(offset_minutes):
    time_for_request = time.now().in_location(BERLIN_TIMEZONE) + time.parse_duration(str(offset_minutes) + "m")

    #round to the nearest minute. We don't want second-level precision so as to avoid constantly invalidating the ttl cache
    hours = time_for_request.hour
    minutes = get_rounded_minutes(time_for_request.minute, time_for_request.second)

    if minutes > 59:
        hours += math.floor(minutes / 60)
        minutes = minutes % 60
    if hours > 23:
        hours = hours % 24

    return format_int_as_time_number(hours) + ":" + format_int_as_time_number(minutes) + ":00"

#Rounds the minutes of a time or duration object to the nearest minute
#minutes: the minutes to round
#seconds: the seconds to round
#Returns the rounded minutes
def get_rounded_minutes(minutes, seconds):
    minutes = math.floor(minutes)

    #it would be great if we could just pass in a time or duration object in here, but we can't because the fields for hours and minutes are named slightly differently
    minutes += 1 if seconds > 30 else 0  #round up if we're more than 30 seconds into the next minute
    return minutes

#Gets the current time in Berlin
#Returns the current time in Berlin as a time object
def get_time_now_in_berlin():
    return time.now().in_location(BERLIN_TIMEZONE)

#Formats an integer as a time number. Adds a leading 0 if the integer is less than 10
#integer: the integer to format
#Returns the formatted integer as a string
def format_int_as_time_number(integer):
    return "0" + str(integer) if integer < 10 else str(integer)

#Decrypts the VBB API access ID for use in the HTTP request. See https://tidbyt.dev/docs/build/authoring-apps#secrets
#Returns the decrypted VBB API access ID
def get_VBB_API_access_id():
    return secret.decrypt(VBB_API_ACCESS_ID)  #NOTE: When running locally, secret.decrypt will return None. Add in "or <the access id>"

#We need a bitwise product of the target products to tell the VBB departureboard API the specific products we want
#show_u_bahn: whether to show U-Bahn departures
#show_s_bahn: whether to show S-Bahn departures
#show_tram: whether to show tram departures
#show_bus: whether to show bus departures
#show_regional: whether to show regional train departures
#show_ice: whether to show ICE train departuress
#Returns the bitwise product of the selected products as a string with decimal places removed (this is the format needed by the VBB API)
def compute_product_bitwise(show_u_bahn, show_s_bahn, show_tram, show_bus, show_regional, show_ice):
    product = 0
    if show_u_bahn:
        product += get_power_for_product(PRODUCT_CLASS_U_BAHN)
    if show_s_bahn:
        product += get_power_for_product(PRODUCT_CLASS_S_BAHN)
    if show_tram:
        product += get_power_for_product(PRODUCT_CLASS_TRAM)
    if show_bus:
        product += get_power_for_product(PRODUCT_CLASS_BUS)
    if show_regional:
        product += get_power_for_product(PRODUCT_CLASS_REGIONAL)
    if show_ice:
        product += get_power_for_product(PRODUCT_CLASS_ICE)
    return humanize.ftoa(product)  #remove any decimal points that may have been added by the math library

#Fails the app if the HTTP request fails
#resp: the response object from the HTTP request
#api_name_invoked: the name of the API that was invoked
def check_http_status_code(resp, api_name_invoked):
    if resp.status_code != 200:
        print(api_name_invoked + " request failed with status _" + str(resp.status_code))

#Computes the power of 2 for a given product
#product: the product to compute the power for
#Returns the power of 2 for the product
def get_power_for_product(product):
    return math.pow(2, product)

#DEPARTUREBOARD RESPONSE PARSING FUNCTIONS

#Parses the JSON response from the VBB departure board API
#http_response: the JSON response from the VBB departure board API
#Returns a list of dictionaries, each representing a departure. See parse_departure for the structure of each dictionary
def parse_departures_json(http_response):
    departures_data = []  #parse out all departures, return them in a list

    #no departures found. Check this separately because resp.json()["Deoarture"] will throw an error if there are no departures
    if http_response.body().find("Departure") == -1:
        return []

    for departures in http_response.json()["Departure"]:
        parsed_departure = parse_departure(departures)
        if parsed_departure:  #don't add None departures
            departures_data.append(parsed_departure)

    return sort_departures(departures_data)

#Parse the relevant data from a departure JSON object
#Input should be a JSON object returned by the VBB departure board API representing a single departure
#Returns a dictionary with the parsed data:
#- DEPARTURE_DATA_DIRECTION: the terminal stop of the train
#- DEPARTURE_DATA_TIME_UNTIL_DEPARTURE: the time until the train departs in minutes
#- DEPARTURE_DATA_TIME_COLOR: the color of the time until departure text (orange if less than 5 minutes, white otherwise)
#- DEPARTURE_DATA_LINE: the line number of the train
#- DEPARTURE_DATA_LINE_COLOR: the color of the line number text
def parse_departure(departure_json):
    time_until_departure = get_minutes_until_departure(departure_json)
    if not check_time_until_departure_valid_for_board(time_until_departure):  #don't show invalid departures
        return None

    product_at_stop = departure_json.get("ProductAtStop")  #internal structure in the JSON response that holds more data about the product
    return {
        DEPARTURE_DATA_DIRECTION: parse_direction(departure_json.get("direction")),
        DEPARTURE_DATA_TIME_UNTIL_DEPARTURE: time_until_departure,
        DEPARTURE_DATA_TIME_COLOR: get_time_color(time_until_departure),
        DEPARTURE_DATA_LINE: parse_line(product_at_stop),
        DEPARTURE_DATA_LINE_COLOR: parse_color(product_at_stop),
    }

#Checks if the time until departure is valid for display on the board
#time_until_departure: the number of minutes until the train departs
#Returns whether the time until departure is valid for display on the board
def check_time_until_departure_valid_for_board(time_until_departure):
    if not time_until_departure or time_until_departure == 0:  #don't show departures that are already gone
        return False
    if time_until_departure > 99:  #no room for three-digit numbers on the board
        return False
    return True

#formats the line number for display. If the line number is not available, uses the second word in the product name
#product_at_stop: the JSON object representing the product at the stop
#Returns the line number or ICE train name
def parse_line(product_at_stop):
    line = product_at_stop.get("line")
    if line:
        return line
    name = product_at_stop.get("name")

    return "I" + name.split(" ")[1]  #ICE trains don't have line numbers, so we'll use the second word in the name instead

#Some products have a white foreground color and a colored background color. In this case, we want to use the background color as the line color
#product_at_stop: the JSON object representing the product at the stop
#Returns the color of the line number text
def parse_color(product_at_stop):
    foreground_color = product_at_stop.get("icon").get("foregroundColor").get("hex")
    background_color = product_at_stop.get("icon").get("backgroundColor").get("hex")
    if foreground_color == WHITE and not background_color == WHITE:
        return background_color
    elif background_color == WHITE and not foreground_color == WHITE:
        return foreground_color
    else:
        return WHITE

#Cleans up common prefixes in station names that aren't helpful for our purposes
#direction: the string representing the direction of the train
#Returns the cleaned up direction string
def parse_direction(direction):
    direction_array = direction.split(" ")
    direction_result = ""
    if is_common_prefix(direction_array[0]):
        direction_result = direction_array[1]
    else:
        direction_result = direction_array[0]

    return direction_result[:MAX_DIRECTION_NAME_LENGTH - 1]

#Returns the color of the time until departure text. Currently, marks departure times in orange if they are less than 5 minutes away, otherwise green
#time_until_departure: the number of minutes until the train departs
#Returns the color of the time until departure text as a hex string (with a prepended #)
def get_time_color(time_until_departure):
    if time_until_departure < MINUTES_TO_DEPARTURE_COLOR_THRESHOLD:
        return ORANGE
    return GREEN

#Retrieves the number of minutes until a train departs from the JSON response from the VBB API
#departure_json: the JSON object representing a single departure from the VBB API
#Returns the rounded number of minutes until the train departs, or None if the departure time is in the past. Will return 0 if the departure is less than 30 seconds in the future
def get_minutes_until_departure(departure_json):
    departure_time = departure_json.get("rtTime")
    departure_date = departure_json.get("rtDate")
    if not departure_time or not departure_time:  #some products don't have rt data (notabaly, RE trains). Fall back to scheduled time/date instead
        departure_time = departure_json.get("time")
        departure_date = departure_json.get("date")
    return parse_minutes_to_departure(departure_date, departure_time)

#Given a train departure date an time, determines the number of minutes until it departs.
#Note that this assumes the user is in the Berlin timezone. I don't see a use case for this plugin outside of Berlin,
#so I'm not going to bother with user-specified timezones.
#This also assumes a maximum time difference between the current time and the departure time of 59 minutes.
#departure_date: the date of the departure in the format "YYYY-MM-DD"
#departure_time: the time of the departure in the format "HH:MM:SS"
#Returns the number of minutes until the departure, or None if incomplete data was provided or the time is in the past
def parse_minutes_to_departure(departure_date, departure_time):
    if not departure_date or not departure_time:
        return None

    date_split = departure_date.split("-")  #see comment on format above
    time_split = departure_time.split(":")
    now = get_time_now_in_berlin()
    departure_time_object = time.time(year = int(date_split[0]), month = int(date_split[1]), day = int(date_split[2]), hour = int(time_split[0]), minute = int(time_split[1]), second = int(time_split[2]), location = BERLIN_TIMEZONE)

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
                name = "Train Station",
                desc = "A list of train stations based on a location.",
                icon = "train",
                handler = get_stations,
            ),
            schema.Dropdown(
                id = CONFIG_DEPARTURE_TIME_OFFSET,
                name = "Departure Time Offset",
                desc = "Use this option to filter out trains departing in fewer than the selected number of minutes.",
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

    for station in stations_json["stopLocationOrCoordLocation"]:
        inner_station = station.get("StopLocation")
        station_id = inner_station.get("id")
        if not station_id:  #the ID is critical for later operations. If we don't have one, throw this stop out
            continue
        station_name = inner_station.get("name")
        if not station_name:  #How will a user know what station they're selecting if it doesn't have a name?
            continue
        option = schema.Option(
            display = inner_station.get("name"),
            value = json.encode({CONFIG_STATION_ID: station_id, CONFIG_STATION_NAME: station_name}),
        )
        found_stations.append(option)
    return found_stations

#Fetches the stations near a location from the VBB API
#location: a JSON object representing a location, as provided by the LocationBased schema
#Returns the JSON response from the VBB API
def fetch_stations(location):
    truncated_lat = math.round(1000.0 * float(location["lat"])) / 1000.0  # Truncate to 3dp for better caching and to protect user privacy
    truncated_lng = math.round(1000.0 * float(location["lng"])) / 1000.0  # Means to the nearest ~110 metres.
    params = {
        "accessId": get_VBB_API_access_id(),
        "originCoordLat": str(truncated_lat),
        "originCoordLong": str(truncated_lng),
        "r": MAX_DISTANCE_FROM_STATION_METERS,  #radius from the user's location for station lookup
        "type": "S",  #limits this to just stations
        "maxNo": MAX_STATIONS_TO_FETCH,  #limits the number of stations returned
        "format": JSON_FORMAT,
    }
    resp = execute_http_get(LOCATION_SEARCH_PREFIX, params, STATIONS_TTL_CACHE_LENGTH_SECONDS)
    if not resp.json().get("stopLocationOrCoordLocation"):
        return None

    return resp.json()

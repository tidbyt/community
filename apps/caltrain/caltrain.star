"""
Applet: Caltrain
Summary: Caltrain Departures
Description: Check the departures for your nearest Caltrain stop, the one near your work, or anywhere in between.
Author: quacksire
"""

# Using [MTC's Open Data API](https://511.org/open-data/transit) with a BYOK (Bring Your Own Key) system as there is throttling for the API.
#
# You don't want to cache the time sensitive responses
#
# Caltrain stop ids are 5 digits long, however there's two ids for each stop, XXXX1 for northbound and XXXX2 for southbound

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
#

STATIC_STATIONS = [
    {"id": "7002", "Name": "22nd Street"},
    {"id": "7003", "Name": "Bayshore"},
    {"id": "7012", "Name": "Belmont"},
    {"id": "7029", "Name": "Blossom Hill"},
    {"id": "7007", "Name": "Broadway"},
    {"id": "7008", "Name": "Burlingame"},
    {"id": "7019", "Name": "California Avenue"},
    {"id": "7028", "Name": "Capitol"},
    {"id": "7025", "Name": "College Park"},
    {"id": "7032", "Name": "Gilroy"},
    {"id": "7010", "Name": "Hayward Park"},
    {"id": "7011", "Name": "Hillsdale"},
    {"id": "7023", "Name": "Lawrence"},
    {"id": "7016", "Name": "Menlo Park"},
    {"id": "7006", "Name": "Millbrae"},
    {"id": "7030", "Name": "Morgan Hill"},
    {"id": "7021", "Name": "Mountain View"},
    {"id": "7017", "Name": "Palo Alto"},
    {"id": "7014", "Name": "Redwood City"},
    {"id": "7020", "Name": "San Antonio"},
    {"id": "7005", "Name": "San Bruno"},
    {"id": "7013", "Name": "San Carlos"},
    {"id": "7001", "Name": "San Francisco"},
    {"id": "7026", "Name": "San Jose"},
    {"id": "7031", "Name": "San Martin"},
    {"id": "7009", "Name": "San Mateo"},
    {"id": "7024", "Name": "Santa Clara"},
    {"id": "7004", "Name": "South San Francisco"},
    {"id": "7022", "Name": "Sunnyvale"},
    {"id": "253774", "Name": "Stanford"},
    {"id": "7027", "Name": "Tamien"},
]

# Function to get Caltrain departures
def get_caltrain_departures(stop_id, key):
    # stop_id is the 5 digit stop id, with the last digit being 1 or 2 indicating the direction
    # key is the 511 API key

    # We want to modify this function to add support for allowing the user to select both directions

    # get only the first 3 of visits
    ETAS = []
    FUTURE_ETAS = []
    print(stop_id, key)

    if (len(stop_id) == 4):
        # We need to get the northbound and southbound departures

        northbound_stop_id = stop_id + "1"
        southbound_stop_id = stop_id + "2"

        # --- Northbound departures ---

        # Define the URL and make an HTTP request
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, northbound_stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        # Trim BOM or unwanted characters from the beginning of the response
        cleaned_content = clean_response(response.body())

        # Extract Caltrain departures
        monitored_stop = json.decode(cleaned_content)

        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

        # --- Southbound departures ---
        # Define the URL and make an HTTP request
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, southbound_stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        # Trim BOM or unwanted characters from the beginning of the response
        cleaned_content = clean_response(response.body())

        # Extract Caltrain departures
        monitored_stop = json.decode(cleaned_content)

        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

        ## Now we have the departures for both directions, we need to sort them by time
        FUTURE_ETAS = manual_sort(FUTURE_ETAS, compare_stops)

    if (len(stop_id) == 5):
        # Define the URL and make an HTTP request
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        # Trim BOM or unwanted characters from the beginning of the response
        cleaned_content = clean_response(response.body())

        # Extract Caltrain departures
        monitored_stop = json.decode(cleaned_content)

        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

    if len(FUTURE_ETAS) > 0:
        first_slot = FUTURE_ETAS[0]["MonitoredVehicleJourney"]
        first_train_number = get_train_color(first_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"])

        ETAS.append(
            render.Row(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Text(content = first_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"], color = first_train_number, font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = get_first_8_chars(stationNameCleaner(first_slot["DestinationName"])), color = "#F00", font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = simplify_time_duration(humanize.time(time.parse_time(first_slot["MonitoredCall"]["AimedDepartureTime"]))), font = "tom-thumb"),
                ],
            ),
        )
    if len(FUTURE_ETAS) > 1:
        second_slot = FUTURE_ETAS[1]["MonitoredVehicleJourney"]
        second_train_number = get_train_color(second_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"])

        ETAS.append(
            render.Row(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Text(content = second_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"], color = second_train_number, font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = get_first_8_chars(stationNameCleaner(second_slot["DestinationName"])), color = "#F00", font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = simplify_time_duration(humanize.time(time.parse_time(second_slot["MonitoredCall"]["AimedDepartureTime"]))), font = "tom-thumb"),
                ],
            ),
        )
        if len(FUTURE_ETAS) > 2:
            third_slot = FUTURE_ETAS[2]["MonitoredVehicleJourney"]
            third_train_number = get_train_color(third_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"])

            ETAS.append(
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = third_slot["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"],
                            color = third_train_number,
                            font = "tom-thumb",
                        ),
                        render.Text(content = "|", color = "#000", font = "tom-thumb"),
                        render.Text(
                            content = get_first_8_chars(stationNameCleaner(third_slot["DestinationName"])),
                            font = "tom-thumb",
                            color = "#F00",
                        ),
                        render.Text(content = "|", color = "#000", font = "tom-thumb"),
                        render.Text(
                            content = simplify_time_duration(
                                humanize.time(time.parse_time(third_slot["MonitoredCall"]["AimedDepartureTime"])),
                            ),
                            font = "tom-thumb",
                        ),
                    ],
                ),
            )

        # check if the ETAS array has three item, and if not add blank elements until its up to three
        # this Starlark dialect does **not** support while loops
        if len(ETAS) < 3:
            ETAS.append(
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Text(content = "|", color = "#000", font = "tom-thumb"),
                        render.Text(content = "|", color = "#000", font = "tom-thumb"),
                        render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    ],
                ),
            )
            if len(ETAS) < 3:
                ETAS.append(
                    render.Row(
                        expanded = True,
                        cross_align = "center",
                        children = [
                            render.Text(content = "|", color = "#000", font = "tom-thumb"),
                            render.Text(content = "|", color = "#000", font = "tom-thumb"),
                            render.Text(content = "|", color = "#000", font = "tom-thumb"),
                        ],
                    ),
                )

    #"""
    return ETAS

# Manually implement sorting
def manual_sort(lst, compare_func):
    for i in range(len(lst)):
        for j in range(i + 1, len(lst)):
            if compare_func(lst[j], lst[i]):
                lst[i], lst[j] = lst[j], lst[i]
    return lst

# Comparison function for sorting
def compare_stops(a, b):
    return int(a["id"]) - int(b["id"])

# Function to clean the response by removing unwanted characters
def clean_response(content):
    # Find the position of the first '{' character
    start_index = content.find("{")

    # Return the substring starting from the first '{' character
    return content[start_index:] if start_index != -1 else content

def stationNameCleaner(station_name):
    return station_name.replace(" Northbound", "").replace(" Southbound", "").replace("Caltrain Station", "").replace("Caltrain", "")

# Function to filter and modify Caltrain stops
def filter_and_modify_stops(caltrain_stops):
    processed_stations = set()
    filtered_stops = []

    for stop in caltrain_stops:
        # Extract station name without "Northbound" or "Southbound"

        station_name = stationNameCleaner(stop["Name"])
        print(stop["Name"])

        # Trim the last digit of the stop ID
        stop["id"] = stop["id"][:-1]

        # If the station name is in the set, skip it
        if station_name in processed_stations:
            continue

        # Add the modified stop to the result
        filtered_stops.append({
            "id": stop["id"],
            "Name": station_name,
        })

        # Add the station name to the set
        processed_stations.add(station_name)

    return filtered_stops

def ljust(input_string, width, fillchar = " "):
    return input_string + fillchar * (width - len(input_string))

def get_first_8_chars(input_string):
    if len(input_string) < 8:
        input_string = ljust(input_string, 8)
    return input_string[:8]

# function to get color of train number, according to the caltrain website
def get_train_color(train_number):
    # Caltrain's new color scheme for the Full Electrification schedule post September 21, 2024
    # we want #rgb
    # 1XX, 6XX are grey
    # 8XX are yellow
    # 5XX is red
    # 4XX is turquoise
    # 9XX and others are light purple
    if train_number[0] == "1" or train_number[0] == "6":
        return "#888"
    if train_number[0] == "4":
        return "#0ff"
    if train_number[0] == "5":
        return "#f00"
    if train_number[0] == "8":
        return "#ff0"
    if train_number[0] == "9":
        return "#f0f"
    return "#f0f"

# Function to convert time duration string to simplified format
def simplify_time_duration(duration_string):
    # Split the input string to extract the numeric value and unit
    parts = duration_string.split()
    print(parts)

    # only return the duration in minutes

    # ["5", "minutes", "from", "now"] => 5
    # ["1", "hour", "from", "now"] => 60
    # ["1", "hour", "and", "5", "minutes", "from", "now"] => 65
    # ["1", "second", "from", "now"] => 1
    # ["1", "minute", "from", "now"] => 1

    #now create it
    # if it only contains the word "minutes" then return the number
    if len(parts) == 4 and parts[1] == "minutes":
        return parts[0]

    # if it contains the word "hour" then return the number * 60
    if len(parts) == 4 and parts[1] == "hour":
        return str(int(parts[0]) * 60)

    # if it contains the word "hour" and "minutes" then return the number * 60 + the number of minutes
    if len(parts) == 7 and parts[1] == "hour" and parts[3] == "minutes":
        return str(int(parts[0]) * 60 + int(parts[2]))

    # if it contains the word "second" then return "now"
    if len(parts) == 4 and parts[1] == "second":
        return "now"

    # if it contains the word "minute" then return "now"
    if len(parts) == 4 and parts[1] == "minute":
        return "now"

    # If the input string doesn't match the expected format, return the original string
    return duration_string

def main(config):
    stationID = config.get("stop", STATIC_STATIONS[11]["id"])
    direction = config.get("direction", "south")
    api_key = config.get("apiKey", "")

    # Caltrain Logo
    CT_LOGO_RQ = http.get("https://agency-logos.sfbatransit.community/caltrain-circle.png")
    CT_LOGO = CT_LOGO_RQ.body()

    # Demo mode, for render preview
    #
    #return render.Root(
    #    child=render.Column(
    #        expanded=True,
    #        children=[
    #            render.Row(
    #                expanded=True,
    #                main_align="left",
    #                children=[
    #                    render.Image(
    #                        src=CT_LOGO,
    #                        width=10,
    #                        height=10,
    #                    ),
    #                    render.Text(content="San Francisco", offset=2, height=10, font="tom-thumb"),
    #                ],
    #            ),
    #            render.Row(
    #                expanded=True,
    #                cross_align="center",
    #                children=[
    #                    render.Text(
    #                        content="102",
    #                        color=get_train_color("102"),
    #                        font="tom-thumb",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="San Jose",
    #                        font="tom-thumb",
    #                        color="#F00",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="4",
    #                        font="tom-thumb",
    #                    ),
    #                ],
    #            ),
    #            render.Row(
    #                expanded=True,
    #                cross_align="center",
    #                children=[
    #                    render.Text(
    #                        content="512",
    #                        color=get_train_color("512"),
    #                        font="tom-thumb",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="Tamien  ",
    #                        font="tom-thumb",
    #                        color="#F00",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="13",
    #                        font="tom-thumb",
    #                    ),
    #                ],
    #            ),
    #            render.Row(
    #                expanded=True,
    #                cross_align="center",
    #                children=[
    #                    render.Text(
    #                        content="416",
    #                        color=get_train_color("416"),
    #                        font="tom-thumb",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="Gilroy  ",
    #                        font="tom-thumb",
    #                        color="#F00",
    #                    ),
    #                    render.Text(content="|", color="#000", font="tom-thumb"),
    #                    render.Text(
    #                        content="18",
    #                        font="tom-thumb",
    #                    ),
    #                ],
    #            ),
    #        ],
    #    ),
    #)
    #"""

    # If the API key is empty, fail
    if api_key == "":
        return render.Root(
            child = render.Column(
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "No 511 API token", offset = 2, height = 10, color = "#F00", font = "tom-thumb"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "Get one from", offset = 2, height = 10, font = "tom-thumb"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "ducks.win/511", offset = 2, height = 10, font = "tom-thumb"),
                        ],
                    ),
                ],
            ),
        )

    # Caltrain stop ids are 5 digits long, however there's two ids for each stop, XXXX1 for northbound and XXXX2 for southbound
    # We are provided the first 4 digits of the stop with `stationID`, and the direction "Northbound" or "Southbound" with `direction`
    etaID = ""
    ETA = []

    if direction == "north":
        etaID = stationID + "1"
    if direction == "south":
        etaID = stationID + "2"
    ETA = get_caltrain_departures(etaID, api_key)

    # find the stop name
    stop_name = ""
    for stop in STATIC_STATIONS:
        if stop["id"] == stationID:
            stop_name = stop["Name"]

    children = [
        render.Row(
            expanded = True,
            main_align = "left",
            children = [
                render.Image(
                    src = CT_LOGO,
                    width = 10,
                    height = 10,
                ),
                render.Text(content = stop_name, offset = 2, height = 10, font = "tom-thumb"),
            ],
        ),
    ]

    if (len(ETA) == 0):
        children.append(
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(content = "No trains :(", offset = 2, height = 10, font = "tom-thumb"),
                ],
            ),
        )

    for eta in ETA:
        if len(children) < 4:
            children.append(eta)

    #,
    return render.Root(
        child = render.Column(
            expanded = True,
            children = children,
        ),
    )

def get_schema():
    # apiKey has a value here
    stops = STATIC_STATIONS

    agency_list_chooser = []
    for stop in stops:
        agency_list_chooser.append(
            schema.Option(
                display = "%s" % stop["Name"],
                value = "%s" % stop["id"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "511 API Token",
                desc = "Request from https://ducks.win/511 then find key in your second email",
                icon = "gears",
            ),
            schema.Dropdown(
                id = "stop",
                name = "Stop",
                desc = "The stop to see departures for",
                icon = "train",
                default = agency_list_chooser[0].value,
                options = agency_list_chooser,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Which direction to see",
                icon = "rightLeft",
                default = "north",
                options = [
                    schema.Option(
                        display = "Northbound",
                        value = "north",
                    ),
                    schema.Option(
                        display = "Southbound",
                        value = "south",
                    ),
                ],
            ),
        ],
    )

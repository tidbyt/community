"""
Applet: New Jersey PATH
Summary: NJ Path real-time arrivals
Description: Displays real-time departures for a New Jersey PATH station.
Author: karmeleon
Updated: API modernization
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Updated API endpoint
PATH_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json"

# Station mapping - keys are used in config, values are station IDs from new API
STATIONS = {
    "fourteenth_street": "14S",
    "twenty_third_street": "23S",
    "thirty_third_street": "33S",
    "christopher_street": "CHR",
    "exchange_place": "EXP",
    "grove_street": "GRV",
    "harrison": "HAR",
    "hoboken": "HOB",
    "journal_square": "JSQ",
    "newark": "NWK",
    "newport": "NEW",
    "ninth_street": "09S",
    "world_trade_center": "WTC",
}

# Display names for stations
STATION_NAMES = {
    "fourteenth_street": "14th Street",
    "twenty_third_street": "23rd Street",
    "thirty_third_street": "33rd Street",
    "christopher_street": "Christopher Street",
    "exchange_place": "Exchange Place",
    "grove_street": "Grove Street",
    "harrison": "Harrison",
    "hoboken": "Hoboken",
    "journal_square": "Journal Square",
    "newark": "Newark",
    "newport": "Newport",
    "ninth_street": "Ninth Street",
    "world_trade_center": "World Trade Center",
}

def get_display_row(message, widgetMode):
    """Create a display row for a single route"""
    # Use the provided arrival time message
    wait_time_text = message["arrivalTimeMessage"]
    if wait_time_text == "0 min":
        wait_time_text = "now"

    # Convert hex color to proper format
    line_color = "#" + message["lineColor"]

    circle_widget = render.Circle(
        color = line_color,
        diameter = 11,
    )

    return render.Row(
        children = [
            render.Padding(
                child = circle_widget,
                pad = 2,
            ),
            render.Column(
                cross_align = "start",
                children = [
                    render.Marquee(
                        child = render.Text(message["headSign"]),
                        width = 49,
                    ) if not widgetMode else render.Text(message["headSign"]),
                    render.Text(
                        content = wait_time_text,
                        color = "#ffa500",
                        offset = 1,
                    ),
                ],
            ),
        ],
    )

def parse_api_response(api_response, station_id, direction):
    """Parse the new API response format to find relevant trains"""
    messages = []
    
    # Find our station in the results
    for station in api_response["results"]:
        if station["consideredStation"] != station_id:
            continue
            
        # Process each destination direction
        for dest in station["destinations"]:
            # Map API direction labels to our direction values
            current_direction = "TO_NY" if dest["label"] == "ToNY" else "TO_NJ"
            
            # Skip if we're filtering by direction and this isn't the one we want
            if direction != "both" and direction != current_direction:
                continue
                
            # Add all messages for this direction
            for message in dest["messages"]:
                if message["secondsToArrival"] != "":  # Skip entries with no arrival time
                    messages.append(message)
    
    # Sort by arrival time
    return sorted(messages, key = lambda x: int(x["secondsToArrival"]))

def query_api():
    """Query the PATH API with caching"""
    response = cache.get("path_data")
    if response != None:
        return json.decode(response)

    api_response = http.get(PATH_URL)
    if api_response.status_code != 200:
        fail("PATH API request failed with status {}".format(api_response.status_code))
    
    response_json = api_response.json()
    cache.set("path_data", json.encode(response_json), ttl_seconds = 30)
    return response_json

def main(config):
    station = config.get("station") or "grove_street"
    desired_direction = config.get("direction") or "both"
    widgetMode = config.bool("$widget")

    api_response = query_api()
    messages = parse_api_response(api_response, STATIONS[station], desired_direction)

    if len(messages) == 0:
        extra_text = ""
        if desired_direction != "both":
            extra_text = " toward {}".format("NY" if desired_direction == "TO_NY" else "NJ")
        text_content = "No scheduled PATH departures from {}{}.".format(STATION_NAMES[station], extra_text)
        content = render.WrappedText(text_content, font = "tom-thumb")
    elif len(messages) == 1:
        content = get_display_row(messages[0], widgetMode)
    else:
        content = render.Column(
            children = [
                get_display_row(messages[0], widgetMode),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                get_display_row(messages[1], widgetMode),
            ],
        )

    return render.Root(
        child = content,
        max_age = 60,
        delay = 100,
    )

def get_station_options():
    """Generate station options for the config schema"""
    options = []
    for value, display in STATION_NAMES.items():
        options.append(schema.Option(
            display = display,
            value = value,
        ))
    return options

def get_schema():
    """Define the config schema"""
    station_options = get_station_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "The station to view arrivals for.",
                icon = "trainSubway",
                options = station_options,
                default = station_options[0].value,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "The direction to display arrivals for.",
                icon = "arrowsTurnToDots",
                options = [
                    schema.Option(
                        display = "Both",
                        value = "both",
                    ),
                    schema.Option(
                        display = "NY",
                        value = "TO_NY",
                    ),
                    schema.Option(
                        display = "NJ",
                        value = "TO_NJ",
                    ),
                ],
                default = "both",
            ),
        ],
    )
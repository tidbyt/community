"""
Applet: CTA "L" Tracker
Summary: CTA "L" Train arrivals
Description: Shows the next two arriving CTA "L" Trains for a selected station. If there is an "S" to the right of an estimated arrival, that means this arrival is scheduled rather than live.
Author: samshapiro13
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

##### constants #####

CTA_STATIONS_URL = "https://data.cityofchicago.org/resource/8pix-ypme.json"
CTA_ARRIVALS_URL = "https://lapi.transitchicago.com/api/1.0/ttarrivals.aspx"

ENCRYPTED_ARRIVALS_API_KEY = "AV6+xWcEhAzrJFZmB5FlsB4E4pyYkKIPUE4vQpQtTPI7v6AS1NCuh2T/w1KoBWjGuZx+cx/4abjDo4sDdnFgBBxl+m8ETPNR2oZNM/QpQUNXI5lbtnaMcR/ydkkOj+/V7+96OW9F2tHn2ztHDBa2sHC6oEKEqrWPP9wqDyxpHzqA6EJ82ZQ="

# Gets Hex color code for a given train line
COLOR_MAP = {
    # Train Lines
    "Red": "#c60c30",  # Red line
    "Blue": "#00a1de",  # Blue line
    "Brn": "#62361b",  # Brown line
    "G": "#009b3a",  # Green line
    "Org": "#f9461c",  # Orange line
    "P": "#522398",  # Purple line
    "Pink": "#e27ea6",  # Pink line
    "Y": "#f9e300",  # Yellow line
}

DESTINATION_STATIONS = [
    "No Destination",
    "Loop",
    "Kimball",
    "Linden",
    "Howard",
    "95th/Dan Ryan",
    "O'Hare",
    "Forest Park",
    "Harlem/Lake",
    "Ashland/63rd-Cottage Grove",
    "Midway",
    "54th/Cermak",
    "Skokie",
]

DEFAULT_STATION = "40830"  # Default station is 18th (Pink Line)
DEFAULT_DESTINATION_STATION = "No Destination"

##### config #####

def fetch_cta_stations():
    """
    Gets a list of "L" stations from API and
    eliminates duplicate stations
    """
    response = http.get(CTA_STATIONS_URL, ttl_seconds = 3600)

    if response.status_code != 200:
        fail("CTA L Stops request failed with status %d", response.status_code)

    data = response.json()

    if len(data) == 0:
        fail("CTA L Stops API returned no stops")

    stations = [{
        "station_descriptive_name": station["station_descriptive_name"],
        "map_id": station["map_id"],
    } for station in data]
    deduped_stations = [i for n, i in enumerate(stations) if i not in stations[n + 1:]]

    return deduped_stations

def get_schema():
    departure_station_options = [schema.Option(
        display = station["station_descriptive_name"],
        value = station["map_id"],
    ) for station in fetch_cta_stations()]
    time_delay_options = [schema.Option(
        display = str(time),
        value = str(time),
    ) for time in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]]
    destination_station_options = [schema.Option(
        display = destination,
        value = destination,
    ) for destination in DESTINATION_STATIONS]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Departing Station",
                desc = "The CTA \"L\" Station to you would depart from",
                icon = "train",
                default = departure_station_options[0].value,
                options = departure_station_options,
            ),
            schema.Dropdown(
                id = "destination_station",
                name = "Destination Station",
                desc = "The CTA \"L\" Station that indicates the direction of the train",
                icon = "train",
                default = destination_station_options[0].value,
                options = destination_station_options,
            ),
            schema.Dropdown(
                id = "time_delay",
                name = "Your estiamted time to station",
                desc = "Set a estimated time for you to get to the station",
                icon = "stopwatch",
                default = time_delay_options[0].value,
                options = time_delay_options,
            ),
        ],
    )

##### main #####

def fetch_cta_arrival_estimates(station_code):
    """
    Gets top 2 arrivals scheduled for the selected station
    from CTA Arrivals API
    """
    api_key = secret.decrypt(ENCRYPTED_ARRIVALS_API_KEY)
    if api_key == None:
        api_key = ""

    response = http.get(CTA_ARRIVALS_URL, params = {"key": api_key, "mapid": station_code, "outputType": "JSON"}, ttl_seconds = 60)

    if response.status_code != 200:
        fail("CTA Arrivals request failed with status %d", response.status_code)

    if "eta" in response.json()["ctatt"]:
        arrivals = response.json()["ctatt"]["eta"]
    else:
        arrivals = []

    return [{
        "destination_name": prediction["destNm"],
        "line": prediction["rt"],
        "eta": (time.parse_time(prediction["arrT"], format = "2006-01-02T15:04:05", location = "America/Chicago") - time.now().in_location("America/Chicago")).minutes,
        "is_scheduled": prediction["isSch"],
    } for prediction in arrivals]

def filter_arrival_predictions(arrival_predictions, destination_station, time_delay):
    filtered_arrivals = []
    for prediction in arrival_predictions:
        if (destination_station == prediction["destination_name"] or destination_station == DEFAULT_DESTINATION_STATION) and (int(prediction["eta"]) > time_delay):
            filtered_arrivals.append(prediction)
    return filtered_arrivals[:2]

def render_arrival_prediction(prediction, widgetMode):
    """
    Creates a Row and adds needed children objects
    for a single arrival
    """
    background_color = render.Box(width = 22, height = 11, color = COLOR_MAP[prediction["line"]])
    destination_text = render.Text(prediction["destination_name"], font = "CG-pixel-4x5-mono", height = 7)
    eta_text = "%d min" % int(prediction["eta"]) if int(prediction["eta"]) > 1 else "Due"
    eta_text += " S" if bool(int(prediction["is_scheduled"])) else ""
    arrival_in_text = render.Text(eta_text, color = "#f3ab3f")

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Stack(children = [background_color]),
            render.Box(width = 1, height = 1),
            render.Column(
                cross_align = "start",
                children = [
                    render.Marquee(width = 36, child = destination_text) if not widgetMode else destination_text,
                    arrival_in_text,
                ],
            ),
        ],
    )

def render_no_arrival_predications_data_available(widgetMode):
    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = [
            render.Marquee(
                width = 64,
                child = render.Text("No trains found"),
            ) if not widgetMode else render.Text("No trains"),
        ],
    )

def main(config):
    widgetMode = config.bool("$widget")
    selected_station = config.get("station", DEFAULT_STATION)
    destination_station = config.get("destination_name", DEFAULT_DESTINATION_STATION)
    time_delay = int(config.get("time_delay", "0"))

    arrival_predictions = fetch_cta_arrival_estimates(selected_station)
    filter_arrivals = filter_arrival_predictions(arrival_predictions, destination_station, time_delay)

    if len(filter_arrivals) == 0:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render_no_arrival_predications_data_available(widgetMode),
        )

    if len(filter_arrivals) == 1:
        return render.Root(
            delay = 75,
            max_age = 60,
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render_arrival_prediction(filter_arrivals[0], widgetMode),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                ],
            ),
        )

    return render.Root(
        delay = 75,
        max_age = 60,
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                render_arrival_prediction(filter_arrivals[0], widgetMode),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#666",
                ),
                render_arrival_prediction(filter_arrivals[1], widgetMode),
            ],
        ),
    )

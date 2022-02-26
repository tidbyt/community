"""imports"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIMEZONE = "America/New_York"
GREEN = "#30BF4C"
RED = "#F5413B"

STATION_NAME_KEY = "station_name_key"
TRAIN_TIME_KEY = "train_time_key"

def main(config):
    station = config.get("station") or "JOURNAL_SQUARE"
    all_trains = getTrainDataFromApi(station)

    return render.Root(
        render.Column(
            children = [
                renderTrainMarquee(all_trains[0]),
                renderDivider(),
                renderTrainMarquee(all_trains[1]),
            ],
        ),
    )

# FUNCTIONS FOR MAIN APP
def getUrlForStation(station_name):
    return "https://path.api.razza.dev/v1/stations/{station}/realtime".format(station = station_name)

def getResponseFromApi(station_name):
    """ gets response from api

    Args:
        station_name: name of station.

    Returns:
        struct: the response from the api
    """
    url = getUrlForStation(station_name)
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep

def getArrivalInMinutes(arrival_time):
    arr_time = time.parse_time(arrival_time).in_location(TIMEZONE)
    now = time.now().in_location(TIMEZONE)
    mins = int((arr_time - now).minutes)
    return mins

def jsonToTrainData(json):
    """ formats json data to dict of train data

    Args:
        json: json to format

    Returns:
        dict: formatted data from json
    """
    trains_data = []
    for train in json:
        data = {
            "name": train["lineName"],
            "status": train["status"].replace("_", " "),
            "minutes": getArrivalInMinutes(train["projectedArrival"]),
        }
        trains_data.append(data)

    return trains_data

def getTrainsFromResponse(rep):
    return rep.json()["upcomingTrains"][0:2]

def getTrainDataFromApi(station_name):
    """ gets train data

    Args:
        station_name: name of station.

    Returns:
        dict: train data dict
    """
    rep = getResponseFromApi(station_name)

    # cache.set(TRAIN_TIME_KEY, str(rep), ttl_seconds = 60)
    trains = getTrainsFromResponse(rep)
    api_data = jsonToTrainData(trains)
    return api_data

def renderTrainMarquee(train):
    """ renders marquee for given train

    Args:
        train: train to show

    Returns:
        column: the train marquee
    """
    status = train["status"]
    status_color = GREEN if status == "ON TIME" else RED
    time_string = "{mins}mins".format(mins = train["minutes"])
    text_text = render.Text(time_string, color = status_color, font = "tom-thumb")

    status_text = render.WrappedText(train["status"], color = status_color, font = "tom-thumb")
    status_array = [text_text, status_text] if status == "ON TIME" else [status_text]

    return render.Column(
        children = [
            render.Marquee(
                width = 64,
                child = render.Text(train["name"]),
            ),
            render.Row(
                main_align = "space_between",
                expanded = True,
                children = status_array,
            ),
        ],
    )

def renderDivider():
    return render.Box(
        color = "#CC6C1B",
        width = 64,
        height = 1,
    )

# FUNCTIONS FOR SCHEMA

def getAllStationsJson():
    """ gets all stations as json

    Returns:
        struct: the response from the api
    """
    url = "https://path.api.razza.dev/v1/stations"
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep.json()["stations"]

def getAllStations():
    """ maps stations to options

    Returns:
        list: list of options for schema
    """
    stations = []
    json_stations = getAllStationsJson()
    for station in json_stations:
        stations.append(
            schema.Option(
                display = station["name"],
                value = station["station"],
            ),
        )
    return stations

# OPTIONS FOR USER
def get_schema():
    options = getAllStations()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Station for arrival times.",
                icon = "train-subway",
                default = options[0].value,
                options = options,
            ),
        ],
    )

"""imports"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("cache.star", "cache")


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
            ]
        )
    )

# FUNCTIONS FOR MAIN APP

def getUrlForStation(stationName):
        """returns a formated url for the station name
        Args:
          stationName: name of station for url
        """
    return "https://path.api.razza.dev/v1/stations/{station}/realtime".format(station = stationName)


def getResponseFromApi(stationName):
        """returns response from api 
        Args:
          stationName: name of station for query
        """
    url = getUrlForStation(stationName)
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep

def getArrivalInMinutes(arrivalTime):
        """takes the arrival time of the train and returns how many minutes it will arrive
        Args:
          arrivalTime: arrivalTime of train from API response
        """
    arrTime = time.parse_time(arrivalTime).in_location(TIMEZONE)
    now = time.now().in_location(TIMEZONE)
    mins = int((arrTime - now).minutes)
    return mins


def jsonToTrainData(json):
        """takes the json object and formats it to a dict 
        Args:
          json: json to map
        """
    trainsData = []
    for train in json:
        data = {
            "name": train["lineName"],
            "status": train["status"].replace("_", " "),
            "minutes": getArrivalInMinutes(train["projectedArrival"])
        }
        trainsData.append(data)

    return trainsData

def getTrainsFromResponse(rep):
        """takes the response and gets the first twp trains
        Args:
          rep: response from api
        """
    return rep.json()["upcomingTrains"][0:2]


def getTrainDataFromApi(stationName):
        """returns array of the upcomming two trains from the api
        Args:
          stationName: station to query
        """
    rep = getResponseFromApi(stationName)
    cache.set(TRAIN_TIME_KEY, str(rep), ttl_seconds = 60)
    trains = getTrainsFromResponse(rep)
    apiData =  jsonToTrainData(trains)
    return apiData



def getTrainData(stationName):
        """returns array of the upcomming two trains from the api
        Args:
          stationName: station to query
        """
    cacheData = cache.get(TRAIN_TIME_KEY)
    if cacheData != None:
        print("pulliing from cache")
        trains = getTrainsFromResponse(cacheData)
        data = jsonToTrainData(trains)
        return data
    print("fetching from api")
    apiData =  getTrainDataFromApi(stationName)
    return apiData
        

def renderTrainMarquee(train):
        """takes train and renders the info in a marquee
        Args:
          train: train to show
        """
    status = train["status"]
    statusColor = GREEN if status == "ON TIME" else RED
    timeString = "{mins}mins".format(mins = train["minutes"])
    textText = render.Text(timeString, color = statusColor, font = "tom-thumb",)
    
    
    statusText = render.WrappedText(train["status"], color = statusColor, font = "tom-thumb",)
    statusArray = [textText, statusText] if status == "ON TIME" else [statusText]

    return render.Column(
        children = [
            render.Marquee(
                width=64,
                child=render.Text(train["name"]),
                ),
            render.Row(
                main_align = "space_between",
                expanded = True,
                children = statusArray
            )
            
            
        ]
    )

def renderDivider():
        """renders the divider
        """
    return render.Box(
        color="#CC6C1B",
        width=64,
        height=1
    )

# FUNCTIONS FOR SCHEMA

def getAllStationsJson():
        """returns all the stations as json from the api
        """
    url = "https://path.api.razza.dev/v1/stations"
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep.json()["stations"]

def getAllStations():
        """gets all stations as options for the config
        """
    stations = []
    jsonStations = getAllStationsJson()
    for station in jsonStations:    
        stations += [schema.Option(
            display = station["name"],
            value = station["station"],
        )]
    return stations

# OPTIONS FOR USER
def get_schema():
        """shows the options to the user
        """
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
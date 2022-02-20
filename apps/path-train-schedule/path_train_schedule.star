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
    allTrains = getTrainDataFromApi(station)

    return render.Root(
        render.Column(
            children = [
                renderTrainMarquee(allTrains[0]),
                renderDivider(),
                renderTrainMarquee(allTrains[1]),
            ]
        )
    )

# FUNCTIONS FOR MAIN APP

def getUrlForStation(stationName):
    return "https://path.api.razza.dev/v1/stations/{station}/realtime".format(station = stationName)


def getResponseFromApi(stationName):
    url = getUrlForStation(stationName)
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep

def getArrivalInMinutes(arrivalTime):
    arrTime = time.parse_time(arrivalTime).in_location(TIMEZONE)
    now = time.now().in_location(TIMEZONE)
    mins = int((arrTime - now).minutes)
    return mins


def jsonToTrainData(json):
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
    return rep.json()["upcomingTrains"][0:2]


def getTrainDataFromApi(stationName):
    rep = getResponseFromApi(stationName)
    cache.set(TRAIN_TIME_KEY, str(rep), ttl_seconds = 60)
    trains = getTrainsFromResponse(rep)
    apiData =  jsonToTrainData(trains)
    return apiData



def getTrainData(stationName):
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
    return render.Box(
        color="#CC6C1B",
        width=64,
        height=1
    )

# FUNCTIONS FOR SCHEMA

def getAllStationsJson():
    url = "https://path.api.razza.dev/v1/stations"
    rep = http.get(url)
    if rep.status_code != 200:
        fail("PATH request failed with status {}".format(rep.status_code))
    return rep.json()["stations"]

def getAllStations():
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
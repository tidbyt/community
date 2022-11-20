"""
Applet: NJ Transit Depature Vision
Summary: Shows the next departing trains of a station
Description: Shows the departing NJ Transit Trains of a selected station
Author: jason-j-hunt
"""
load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/csv.star", "csv")
load("encoding/base64.star", "base64")
load("time.star", "time")

#URL TO NJ TRANSIT DEPARTURE VISION WEBSITE
NJ_TRANSIT_DV_URL = "https://www.njtransit.com/dv-to"
DEFAULT_STATION = "New York Penn Station"



STATION_CACHE_KEY = "stations"
STATION_CACHE_TTL = 604800 #1 Week

def main(config):

    selected_station = config.get("station", DEFAULT_STATION)

    departures = get_departures_for_station(selected_station)


    marquee = render.Marquee(
        width=64,
        child=render.Text("✈"),
        offset_start=5,
        offset_end=32,
    )

    return render.Root(
        child = marquee
    )
    return



def get_schema():
    
    options = getStationListOptions()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Departing Station",
                desc = "The NJ Transit Station to get departure schedule for.",
                icon = "train",
                default = options[0].value,
                options = options,
            ),
        ],
    )

'''
Function gets all depatures for a given station
returns a list of structs with the following fields

depature_item struct:
    departing_at: string
    destination: string
    train_number: time
'''
def get_departures_for_station(station):


    print("Getting departures for '%s'" % station)

    station_suffix = station.replace(' ', "%20")
    station_url = "{}/{}".format(NJ_TRANSIT_DV_URL, station_suffix)

    print(station_url)

    nj_dv_page_response = http.get(station_url)

    if nj_dv_page_response.status_code != 200:
        print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return None

    selector = html(nj_dv_page_response.body())
    departures = selector.find(".border.mb-3.rounded")

    print("Found '%s' departures" % departures.len())

    result = []

    for index in range(0, departures.len()):
        departure = departures.eq(index)
        item = extract_fields_from_departure(departure)
        print("{}/{}/{}".format(item.departing_at, item.destination, item.train_number))
        result.append(item)

    return result

'''
Function Extracts necessary data from HTML of a given depature
'''
def extract_fields_from_departure(departure):

    data = departure.find(".media-body").first()
    
    depature_time = get_departure_time(data)
    destination_name = get_destination_name(data)
    train_number = get_train_number(data)

    return struct(departing_at = depature_time, destination = destination_name, train_number = train_number)

'''
Function gets depature time for a given depature
'''
def get_departure_time(data):
    time_string = data.find(".d-block.ff-secondary--bold.flex-grow-1.h2.mb-0").first().text().strip()
    return time_string

'''
Function gets the train number from a given depature
'''
def get_train_number(data):
    nodes = data.find(".media-body").first().find(".mb-0")
    srvc_train_number = nodes.eq(1).text().strip().split()
    train_number = "{} {}".format(srvc_train_number[0].strip(), srvc_train_number[2].strip())
    return train_number
'''
Function gets the destation froma  given depature
'''
def get_destination_name(data):
    nodes = data.find(".media-body").first().find(".mb-0")
    destination_name = nodes.eq(0).text().strip()
    return destination_name

'''
Function fetches trains station list from NJ Transit website
To be used for creating Schema option list
'''
def fetch_stations_from_website():

    result = []
    nj_dv_page_response = http.get(NJ_TRANSIT_DV_URL)

    if nj_dv_page_response.status_code != 200:
        print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return result
    
    selector = html(nj_dv_page_response.body())
    stations = selector.find(".vbt-autocomplete-list.list-unstyled.position-absolute.pt-1.shadow.w-100").first().children()
    print("Got response of '%s' stations" % stations.len())

    for index in range(0, stations.len()):
        station = stations.eq(index)
        station_name = station.find("a").first().text()
        print("Found station '%s' from page response" % station_name)
        result.append(station_name)

    return result


'''
Creates a list of schema options from station list
'''
def getStationListOptions():
    
    options = []
    cache_string = cache.get(STATION_CACHE_KEY)

    stations = None

    if cache_string != None:
        stations = json.decode(cache_string)

    if stations == None:
        stations = fetch_stations_from_website()
        cache.set(STATION_CACHE_KEY, json.encode(stations), STATION_CACHE_TTL)
    
    for station in stations:
        options.append(create_option(station, station))

    return options

'''
Helper function to create a schema option of a given display name and value
'''
def create_option(display_name, value):
    return schema.Option(
            display = display_name,
            value = value,
        )


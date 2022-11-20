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

#URL TO NJ TRANSIT DEPARTURE VISION WEBSITE
NJ_TRANSIT_DV_URL = "https://www.njtransit.com/dv-to"
DEFAULT_STATION = "New York Penn Station"



STATION_CACHE_KEY = "stations"
STATION_CACHE_TTL = 604800 #1 Week

def main(config):

    selected_station = config.get("station", DEFAULT_STATION)
    return render.Root(
        child = render.Text("Hello, World!")
    )



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

def getNJTransitHTML(station):

    station_suffix = station.replace(' ', "%20")
    station_url = "{}/{}".format(NJ_TRANSIT_DV_URL, station_suffix)

    nj_dv_page_response = http.get(station_url)

    if nj_dv_page_response.status_code != 200:
        print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return None

    html_response = html(wotd_page_response.body())

    return html_response

def fetch_stations_from_website():

    result = []
    nj_dv_page_response = http.get(station_url)

    if nj_dv_page_response.status_code != 200:
        print("Got code '%s' from page response" % nj_dv_page_response.status_code)
        return result

    selector = html(nj_dv_page_response.body())
    stations = selector.find(".vbt-autocomplete-list list-unstyled position-absolute pt-1 shadow w-100").first().children()

    for station in stations:
        result.append(station.find("a").first().text())

    return result



def getStationListOptions():
    
    options = []
    stations = json.decode(cache.get(STATION_CACHE_KEY))

    if stations == None:
        stations = fetch_stations_from_website()
        cache.set(STATION_CACHE_KEY, json.encode(stations), STATION_CACHE_TTL)
    
    for station in stations:
        options.append(create_option(station, station))

    return options


def create_option(display_name, value):
    return schema.Option(
            display = display_name,
            value = value,
        )


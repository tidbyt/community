"""
Applet: CTA "L" Tracker
Summary: CTA "L" Train arrivals
Description: Shows the next two arriving CTA "L" Trains for a selected station. If there is an "S" to the right of an estimated arrival, that means this arrival is scheduled rather than live.
Author: samshapiro13
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

CTA_STATIONS_URL = "https://data.cityofchicago.org/resource/8pix-ypme.json"
CTA_ARRIVALS_URL = "https://lapi.transitchicago.com/api/1.0/ttarrivals.aspx"

L_STOPS_CACHE_KEY = "lstops"
ARRIVALS_CACHE_KEY_PREFIX = "arrivals"

ENCRYPTED_L_STOPS_APP_TOKEN = "AV6+xWcElqoWzINC+4lBzeZuL6rIz1WGOqo0vKlZLAmNZ58lOUCXnBWaXKxD7thBgCYJ36jW5LTnRMkgavzgjYcaLzI1T4545Q54RkwzjCz+FTEgK5p6zVoMaEY10385T1Sycp9ZKer0b34Vig8XeDXUY+z1EKJ5mggHGoiQhQ=="
ENCRYPTED_ARRIVALS_API_KEY = "AV6+xWcER6HjcvANXDhGJqhXg09FtzGZjmyft97YTwLYSLwd+gBAYSfDiTqjB2qhD14cjg9qpzRaYksr2S+0ectDcdVEUq2AyfdaVKzqn4sYoeGmtmsSHbweibhglsfdgKC1yN8OqrYZjv7k0Y15NPoDj78kFm/iV/g1IaeOYTx1p5QbKqE="

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

# Default station is 18th (Pink Line)
DEFAULT_STATION = "40830"

def get_schema():
    options = get_station_options()

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Departing Station",
                desc = "The CTA \"L\" Station to get departure schedule for.",
                icon = "train",
                default = options[0].value,
                options = options,
            ),
        ],
    )

def main(config):
    selected_station = config.get("station", DEFAULT_STATION)

    arrivals = get_journeys(selected_station)

    rendered_rows = render_arrival_list(arrivals)

    return render.Root(
        delay = 75,
        max_age = 60,
        child = rendered_rows,
    )

def render_arrival_list(arrivals):
    """
    Renders a given lists of arrivals
    """
    rendered = []

    if arrivals:
        for a in arrivals:
            rendered.append(render_arrival_row(a))

    if rendered == None or len(rendered) == 0 or arrivals == None:
        return render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text("No trains found"),
                ),
            ],
        )

    if len(rendered) == 1:
        return render.Column(
            expanded = True,
            children = [
                rendered[0],
            ],
        )

    return render.Column(
        expanded = True,
        main_align = "start",
        children = [
            rendered[0],
            render.Box(
                width = 64,
                height = 1,
                color = "#666",
            ),
            rendered[1],
        ],
    )

def render_arrival_row(arrival):
    """
    Creates a Row and adds needed children objects
    for a single arrival
    """
    background_color = render.Box(width = 22, height = 11, color = arrival["color_hex"])
    destination_text = render.Marquee(
        width = 36,
        child = render.Text(arrival["destination_name"], font = "CG-pixel-4x5-mono", height = 7),
    )
    arrival_in_text = render.Text(arrival["eta_text"], color = "#f3ab3f")

    stack = render.Stack(children = [
        background_color,
    ])

    column = render.Column(
        children = [
            destination_text,
            arrival_in_text,
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            stack,
            column,
        ],
    )

def get_stations():
    """
    Gets a list of "L" stations from API and
    eliminates duplicate stations
    """
    cache_stations = cache.get(L_STOPS_CACHE_KEY)
    if cache_stations != None:
        return json.decode(cache_stations)

    print("Miss! No L Stops info in cache, calling L Stops API.")

    app_token = secret.decrypt(ENCRYPTED_L_STOPS_APP_TOKEN)
    if not app_token:
        return None

    response = http.get(
        CTA_STATIONS_URL,
        params = {
            "$$app_token": app_token,
        },
    )
    if response.status_code != 200:
        fail("CTA L Stops request failed with status %d", response.status_code)

    data = response.json()
    if len(data) == 0:
        fail("CTA L Stops API returned no stops")

    stations = [build_station(station) for station in data]
    deduped_stations = [i for n, i in enumerate(stations) if i not in stations[n + 1:]]
    cache.set(L_STOPS_CACHE_KEY, json.encode(deduped_stations), ttl_seconds = 3600)
    return deduped_stations

def build_station(station):
    """
    Creates a dictionary for the passed in "L" station
    containing station name and id
    """
    return {
        "station_descriptive_name": station["station_descriptive_name"],
        "map_id": station["map_id"],
    }

def get_station_options():
    """
    Formats list of "L" stations into options
    for dropdown
    """
    stations = get_stations()

    if stations:
        station_options = [
            schema.Option(
                display = station["station_descriptive_name"],
                value = station["map_id"],
            )
            for station in stations
        ]
    else:
        station_options = [
            schema.Option(
                display = "No Stations Available",
                value = "No Stations Available",
            ),
        ]
    return station_options

def get_journeys(station_code):
    """
    Gets top 2 arrivals scheduled for the selected station
    from CTA Arrivals API
    """
    station_cache_key = ARRIVALS_CACHE_KEY_PREFIX + "_" + station_code
    cache_arrivals = cache.get(station_cache_key)
    if cache_arrivals != None:
        return json.decode(cache_arrivals)

    api_key = secret.decrypt(ENCRYPTED_ARRIVALS_API_KEY)
    if api_key == None or station_code == None:
        return None

    response = http.get(
        CTA_ARRIVALS_URL,
        params = {
            "key": api_key,
            "mapid": station_code,
            "outputType": "JSON",
        },
    )
    if response.status_code != 200:
        fail("CTA Arrivals request failed with status %d", response.status_code)

    if "eta" in response.json()["ctatt"]:
        journeys = response.json()["ctatt"]["eta"]
    else:
        print("No trains found in response from API!")
        print(response.json()["ctatt"])
        journeys = []

    next_arrivals = [build_journey(prediction) for prediction in journeys[:2]]
    cache.set(station_cache_key, json.encode(next_arrivals), ttl_seconds = 60)
    return next_arrivals

def build_journey(prediction):
    """
    Parses CTA Arrivals API response for fields that we
    are interested in
    """
    destination_name = prediction["destNm"]
    line = prediction["rt"]
    color_hex = COLOR_MAP[line]
    is_scheduled = prediction["isSch"]
    now = time.now().in_location("America/Chicago")
    arrival_time = time.parse_time(prediction["arrT"], format = "2006-01-02T15:04:05", location = "America/Chicago")
    diff = arrival_time - now
    diff_minutes = int(diff.minutes)
    eta_text = "%d min" % diff_minutes if diff_minutes > 1 else "Due"
    eta_text += " S" if bool(int(is_scheduled)) else ""
    return {
        "destination_name": destination_name,
        "line": line,
        "color_hex": color_hex,
        "eta_text": eta_text,
        "is_scheduled": is_scheduled,
    }

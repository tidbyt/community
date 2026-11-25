load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

# Core cities meet the 1,000,000 population threshold in Census Vintage 2025.
# Denison and Gunter are additional city picks selected by the user.
# Coordinates are city-center points used only to request current weather.
CITIES = [
    {"name": "Houston", "lat": 29.7604, "lon": -95.3698},
    {"name": "San Antonio", "lat": 29.4241, "lon": -98.4936},
    {"name": "Dallas", "lat": 32.7767, "lon": -96.7970},
    {"name": "Fort Worth", "lat": 32.7555, "lon": -97.3308},
    {"name": "Austin", "lat": 30.2672, "lon": -97.7431},
    {"name": "Denison", "lat": 33.7573, "lon": -96.5655},
    {"name": "Gunter", "lat": 33.4425, "lon": -96.7254},
]

# A small original pixel silhouette, designed for the 64x32 Tidbyt display.
TEXAS = [
    "#####.............",
    "#####.............",
    "#####.............",
    "##################",
    "##################",
    "##################",
    "##################",
    "#################.",
    "################..",
    "################..",
    "###############...",
    "##############....",
    "##############....",
    "#############.....",
    "############......",
    "###########.......",
    "###########.......",
    "#########.........",
]

def texas_map():
    rows = []
    for row in TEXAS:
        cells = []
        for x in range(len(row)):
            pixel = row[x]
            color = "#42A5F5" if pixel == "#" else "#000000"
            cells.append(render.Box(width = 1, height = 1, color = color))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def current_temperature(city):
    headers = {
        "User-Agent": "Texas Clock Tidbyt app",
        "Accept": "application/geo+json",
    }
    point_url = "https://api.weather.gov/points/%s,%s" % (city["lat"], city["lon"])
    point_response = http.get(point_url, headers = headers, ttl_seconds = 86400)
    if point_response.status_code != 200:
        return "--"

    stations_url = point_response.json()["properties"]["observationStations"]
    stations_response = http.get(stations_url, headers = headers, ttl_seconds = 3600)
    if stations_response.status_code != 200:
        return "--"

    # NWS lists stations nearest to this city first. Try up to three in case
    # the closest one has not reported a temperature recently.
    features = stations_response.json()["features"]
    for i in range(len(features)):
        if i >= 3:
            break
        station_id = features[i]["properties"]["stationIdentifier"]
        observation_url = "https://api.weather.gov/stations/%s/observations/latest" % station_id
        observation_response = http.get(observation_url, headers = headers, ttl_seconds = 600)
        if observation_response.status_code != 200:
            continue
        celsius = observation_response.json()["properties"]["temperature"]["value"]
        if celsius != None:
            return "%d" % int(celsius * 9 / 5 + 32)
    return "--"

def main():
    now = time.now().in_location("America/Chicago")

    # Cycle through the list by minute so requests stay limited to one city.
    city = CITIES[int(now.format("04")) % len(CITIES)]
    temperature = current_temperature(city)

    info = render.Column(
        cross_align = "left",
        children = [
            render.Text(content = now.format("15:04"), font = "6x13", color = "#FFFFFF"),
            render.Text(content = city["name"], font = "CG-pixel-3x5-mono", color = "#FFD54F"),
            render.Text(content = temperature + " F", font = "CG-pixel-3x5-mono", color = "#FFFFFF"),
        ],
    )

    return render.Root(
        delay = 1000,
        max_age = 60,
        child = render.Box(
            color = "#000000",
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [texas_map(), info],
            ),
        ),
    )


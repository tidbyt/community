"""
Applet: Bay Wheels
Summary: Bay Wheels availability
Description: Shows the availability of bikes and e-bikes at a Bay Wheels station.
Author: Martin Strauss
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# TODO: query these from https://gbfs.baywheels.com/gbfs/gbfs.json maybe?
STATIONS_URL = "https://gbfs.baywheels.com/gbfs/fr/station_information.json"
STATUS_URL = "https://gbfs.baywheels.com/gbfs/fr/station_status.json"

DEFAULT_STATION = '{ "display": "18th St at Noe St", "value": "cd7359fc-6798-48ed-af32-9d5f6cff9ffa"}'

IMAGE_BICYCLE = base64.decode("""
R0lGODlhNgAgAIABAP8A/////yH5BAEKAAEALAAAAAA2ACAAAAK5jI+pe+DAopz0OYqztLB1DWKP
F5bTaFzmuqiBy8avCrMcWtFffNfRLUtYNMCg0PcbGj240wXJJBadkObR2urlOlimr6fbZXfTlNIM
RnSjaI76DIZDZ5/4G3Wm4+f7/P3Z1GfGIEg3BihWiFVoqOBWE4joGPZ2mGe1d8XWduXmFQdK8tl5
CWpaOfrnp2e6mIg5NMe2urkRKxspdidyywepu0sVpuvneWiL0zq51mbMqupskpYKvfSsWgAAOw==
""")

IMAGE_LIGHTNING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAp/s
AAKf7ATxDYQ0AAAMySURBVFhHtZZPSFRRFMbPueMfjApcRH8giAiCqNSZ/mlWFGKBFZqaWBS1aRFtgmiXJW6kldCmRdEqcHTIEa
uFYFGZBTojmZuiIlpERASBWfGce/rezG3CZubNe+Prt3lzvufwnfvdc+/I9B+Q25vKpbS4Fx9XcnO8gpkk9SYTZZ6+IQMVa6S0Z
JSJ61H+cDK38bUBHQ5tk0TgGWLdAFfbuCP1Jje+NSCRUCMF5CFWviIlyFNuiQ8nPzuw4AZEiHV/6LygBZgvMjIRUweScIzfZkFD
KH2tAeG3Pcx8zkhJ4DqiWmJ1pnSk4AR0tGaJ0LtoFnNNCX3JlHkpKAEdrVpFFg/BPGikNCJyX7XGG0yZF88J6N7KCpg/z2pur57
ksild4akB3R+spyL1GOarjTQfoUHVOjlhKle4bkAiwTN43MOkL00p88EpmCPFec/9v+RtAMdMwbwbp+06Vl5k5EyEIqp5YtpUrn
EcQh3eUUbKuoXrtM1IWcHgzVGx2qgaJ14ZyTU5G9DhymUUUFFEXmOknCD+r/i7EVPmY1bYuqiapz7bRdYGdHjLelyrd/FynZF8A
1uKk8K7VOvEmF1nzICOVO2mgB77T+a/SMuJP+Y28xLQfcHjxHwTe15qJN/AnHzB4wguqScpJUW6AekL1QoTzrjzYBYCLqg3ZKkG
1T7+2khp0mZ6cPtysqyr8C8zkiOIsw7NlpsyJxjQUS7hJj4csxPIoKDV6iiGdE5Po9nc9wJAk2GeWXyKTz/6aaQMPP8WJLGk08k
cxthy6ebp2DEncxvPCej+qs3EahJfzNo8jC3kflYdjd8wkiMFJKCu5DIH37CkQ27NbTwlIAPBkMzxeLaTgtQ/UIIOqrb4SyO5wl
MCkqCuHMc0RkVS7dXcxnUDOhLaicAOmDINBm5IZq09qnHyo5E84SUBTP7f1eNysYf9GsvaJnVy6ruRPeNqBnQkuBfJPzClvd8J/
KRcwLD1GKlg8iaAZdq73mVKe+UzEFr8MLfJ38CdrftZGPufXPkn/Fjt45ZYNPnSB/LPgCQ6kw+RabYS1fi3azyp+4RjA8n4icqw
8mGkUMvtL96n3vgF0W/iaRpXqhpMFQAAAABJRU5ErkJggg==
""")

def main(config):
    station = json.decode(config.get("station_id", DEFAULT_STATION))

    allStatuses = fetch_cached(STATUS_URL, 240)["data"]["stations"]

    ebikes = 0
    bikes = 0
    stationStatus = [status for status in allStatuses if status["station_id"] == station["value"]]

    if len(stationStatus) > 0:
        stationStatus = stationStatus[0]

        # The Lyft API renders the total number of bikes, and the number of those that are
        # e-bikes, so we calculate the number of "classic" bikes.
        ebikes = stationStatus["num_ebikes_available"]
        bikes = stationStatus["num_bikes_available"] - ebikes

    return render.Root(
        child = render.Column(
            cross_align = "end",
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(station["display"]),
                        ),
                        render.Box(width = 64, height = 1, color = "#FFF"),
                    ],
                ),
                render.Row(
                    main_align = "space_around",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = IMAGE_BICYCLE, width = 32, height = 18),
                        render.Column(
                            main_align = "space_evenly",
                            cross_align = "end",
                            expanded = True,
                            children = [
                                render.Text("%d" % bikes),
                                render.Row(
                                    children = [
                                        render.Image(src = IMAGE_LIGHTNING, width = 8, height = 8),
                                        render.Text("%d" % ebikes),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station_id",
                name = "Bay Wheels Station",
                desc = "A list of bike share stations based on a location.",
                icon = "bicycle",
                handler = get_stations,
            ),
        ],
    )

def get_stations(location):
    loc = json.decode(location)

    result = fetch_cached(STATIONS_URL, 86400)
    if "data" not in result:
        fail("No data field found in result: %s" % str(result)[:100])
    if "stations" not in result["data"]:
        fail("No stations field found in data: %s" % str(result["data"])[:100])
    stations = result["data"]["stations"]

    return [
        schema.Option(
            display = station["name"],
            value = station["station_id"],
        )
        for station in sorted(stations, key = lambda station: square_distance(loc["lat"], loc["lng"], station["lat"], station["lon"]))
    ]

def square_distance(lat1, lon1, lat2, lon2):
    latitude_difference = int((float(lat2) - float(lat1)) * 10000)
    longitude_difference = int((float(lon2) - float(lon1)) * 10000)
    return latitude_difference * latitude_difference + longitude_difference * longitude_difference

def fetch_cached(url, ttl):
    cached = cache.get(url)
    if cached != None:
        return json.decode(cached)
    else:
        res = http.get(url)
        if res.status_code != 200:
            fail("GBFS request to %s failed with status %d", (url, res.status_code))
        data = res.json()
        cache.set(url, json.encode(data), ttl_seconds = ttl)
        return data

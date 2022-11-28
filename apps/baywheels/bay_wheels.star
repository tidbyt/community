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
Z2ltcCB4Y2YgdjAxMQAAAAA2AAAAIAAAAAAAAACWAAAAEQAAAAEBAAAAEwAAAAhCkAScQpAEnAAAABQAAAAEAAAAAgAAABYAAAAEA
AAAAgAAABUAAAODAAAAEGdpbXAtaW1hZ2UtZ3JpZAAAAAABAAAArChzdHlsZSBzb2xpZCkKKGZnY29sb3IgKGNvbG9yLXJnYmEgMC
AwIDAgMSkpCihiZ2NvbG9yIChjb2xvci1yZ2JhIDEgMSAxIDEpKQooeHNwYWNpbmcgMTApCih5c3BhY2luZyAxMCkKKHNwYWNpbmc
tdW5pdCBpbmNoZXMpCih4b2Zmc2V0IDApCih5b2Zmc2V0IDApCihvZmZzZXQtdW5pdCBpbmNoZXMpCgAAAAAGZ2FtbWEAAAAAAQAA
ABQwLjQ1NDU1MDAwMDAwMDAwMDAxAAAAABRnaW1wLWltYWdlLW1ldGFkYXRhAAAAAAEAAAJ1PD94bWwgdmVyc2lvbj0nMS4wJyBlb
mNvZGluZz0nVVRGLTgnPz4KPG1ldGFkYXRhPgogIDx0YWcgbmFtZT0iRXhpZi5JbWFnZS5CaXRzUGVyU2FtcGxlIj44IDggODwvdG
FnPgogIDx0YWcgbmFtZT0iRXhpZi5JbWFnZS5FeGlmVGFnIj45MDwvdGFnPgogIDx0YWcgbmFtZT0iRXhpZi5JbWFnZS5JbWFnZUx
lbmd0aCI+MzI8L3RhZz4KICA8dGFnIG5hbWU9IkV4aWYuSW1hZ2UuSW1hZ2VXaWR0aCI+NTQ8L3RhZz4KICA8dGFnIG5hbWU9IkV4
aWYuSW1hZ2UuT3JpZW50YXRpb24iPjE8L3RhZz4KICA8dGFnIG5hbWU9IkV4aWYuSW1hZ2UuUmVzb2x1dGlvblVuaXQiPjM8L3RhZ
z4KICA8dGFnIG5hbWU9IkV4aWYuSW1hZ2UuWFJlc29sdXRpb24iPjU2Ny8yMDwvdGFnPgogIDx0YWcgbmFtZT0iRXhpZi5JbWFnZS
5ZUmVzb2x1dGlvbiI+NTY3LzIwPC90YWc+CiAgPHRhZyBuYW1lPSJFeGlmLlBob3RvLkNvbG9yU3BhY2UiPjE8L3RhZz4KICA8dGF
nIG5hbWU9IkV4aWYuUGhvdG8uUGl4ZWxYRGltZW5zaW9uIj41MDA8L3RhZz4KICA8dGFnIG5hbWU9IkV4aWYuUGhvdG8uUGl4ZWxZ
RGltZW5zaW9uIj4yOTk8L3RhZz4KICA8dGFnIG5hbWU9IlhtcC50aWZmLk9yaWVudGF0aW9uIj4xPC90YWc+CjwvbWV0YWRhdGE+C
gAAAAAAAAAAAAAAAAAAAAP6AAAAAAAAAAAAAAAAAAAAAAAAADYAAAAgAAAAAQAAAA5iYXl3aGVlbHMucG5nAAAAAAIAAAAAAAAABg
AAAAQAAAD/AAAAIQAAAAQ/gAAAAAAACAAAAAQAAAABAAAACQAAAAQAAAAAAAAAIgAAAAQAAAAAAAAAHAAAAAQAAAAAAAAACgAAAAQ
AAAAAAAAAIAAAAAQAAAAAAAAACwAAAAQAAAAAAAAADAAAAAQAAAAAAAAADQAAAAQAAAAAAAAADwAAAAgAAAAAAAAAAAAAAAcAAAAE
AAAAHAAAACUAAAAEAAAAAAAAACQAAAAE/////wAAACMAAAAE/////wAAABQAAAAEAAAAAgAAAAAAAAAAAAAAAAAABQgAAAAAAAAAA
AAAADYAAAAgAAAABAAAAAAAAAUkAAAAAAAAAAAAAAA2AAAAIAAAAAAAAAU8AAAAAAAAAAAeAAP/MQAE/zAABP8DAAH/LQAC/wIAAf
8tAAL/AgAB/y4AAf8CAAH/LgAC/wEAAf8YAAf/DQAC/wEAAf8YAAf/DQAF/xsAA/8OAAX/HQAC/w4ABP8cAAT/DQAC//0A//8JAAL
/DgAG/wwAAv//AAL/CAAE/wsAB/8LAAL/AQAC/wgABP8FAAj/AQAC/woAAv8CAP+ABf8EAAT/AwAJ/wMAAv8JAAL/AgAH/wMABP8C
AAv/AgAC/wgAAv8BAP/VCP8DAAT/AQAD/wMABf8BAAL/BwD/2wL/AQAF/wcABP//AAP/AwAC/wEAAv8BAAH/BwAC/wEAAv8BAAL/B
gAE//8AAv8EAAL/AQAC/wEAAv8FAAL/AQAC/wIAAv8GAAT//QD//wQAAv8DAAL//wAC/wUAAv8BAAL/AwAB/wYAB/8DAAL/BAAC/w
EAAf8EAAL/AgAC/wMAA/8EAAf/AwAW/wIAAf8DAAT/BAAH/wMAFf8DAAH/AwAE/wQAB/8FABH/BQAB///bAwAD/wQABP/9AP//CwA
C/wEAA/8IAAL/DAAE//8AAv8JAAL/AwAC/wgAAv8MAAT//wAD/wgAAv8EAAH/CQAC/wsABP8BAAP/BQAD/wQABP8IAAP/CQAE/wIA
C/8FAAT/CAD/qgj/AwAE/wMACf8WAAf/AwAE/wUABf8aAAT/BAAE/38DGQD/gGgA/9UuAP/bfwF/AP/bfwENAP+qfQAeAAP/MQAE/
zAABP8DAAH/LQAC/wIAAf8tAAL/AgAB/y4AAf8CAAH/LgAC/wEAAf8YAAf/DQAC/wEAAf8YAAf/DQAF/xsAA/8OAAX/HQAC/w4ABP
8cAAT/DQAC//0A//8JAAL/DgAG/wwAAv//AAL/CAAE/wsAB/8LAAL/AQAC/wgABP8FAAj/AQAC/woAAv8CAP+ABf8EAAT/AwAJ/wM
AAv8JAAL/AgAH/wMABP8CAAv/AgAC/wgAAv8BAP/VCP8DAAT/AQAD/wMABf8BAAL/BwD/2wL/AQAF/wcABP//AAP/AwAC/wEAAv8B
AAH/BwAC/wEAAv8BAAL/BgAE//8AAv8EAAL/AQAC/wEAAv8FAAL/AQAC/wIAAv8GAAT//QD//wQAAv8DAAL//wAC/wUAAv8BAAL/A
wAB/wYAB/8DAAL/BAAC/wEAAf8EAAL/AgAC/wMAA/8EAAf/AwAW/wIAAf8DAAT/BAAH/wMAFf8DAAH/AwAE/wQAB/8FABH/BQAB//
/bAwAD/wQABP/9AP//CwAC/wEAA/8IAAL/DAAE//8AAv8JAAL/AwAC/wgAAv8MAAT//wAD/wgAAv8EAAH/CQAC/wsABP8BAAP/BQA
D/wQABP8IAAP/CQAE/wIAC/8FAAT/CAD/qgj/AwAE/wMACf8WAAf/AwAE/wUABf8aAAT/BAAE/x4AA/8xAAT/MAAE/wMAAf8tAAL/
AgAB/y0AAv8CAAH/LgAB/wIAAf8uAAL/AQAB/xgAB/8NAAL/AQAB/xgAB/8NAAX/GwAD/w4ABf8dAAL/DgAE/xwABP8NAAL//QD//
wkAAv8OAAb/DAAC//8AAv8IAAT/CwAH/wsAAv8BAAL/CAAE/wUACP8BAAL/CgAC/wIA/wIF/wQABP8DAAn/AwAC/wkAAv8CAAf/Aw
AE/wIAC/8CAAL/CAAC/wEA/wYI/wMABP8BAAP/AwAF/wEAAv8HAP8HAv8BAAX/BwAE//8AA/8DAAL/AQAC/wEAAf8HAAL/AQAC/wE
AAv8GAAT//wAC/wQAAv8BAAL/AQAC/wUAAv8BAAL/AgAC/wYABP/9AP//BAAC/wMAAv//AAL/BQAC/wEAAv8DAAH/BgAH/wMAAv8E
AAL/AQAB/wQAAv8CAAL/AwAD/wQAB/8DABb/AgAB/wMABP8EAAf/AwAV/wMAAf8DAAT/BAAH/wUAEf8FAAH//wcDAAP/BAAE//0A/
/8LAAL/AQAD/wgAAv8MAAT//wAC/wkAAv8DAAL/CAAC/wwABP//AAP/CAAC/wQAAf8JAAL/CwAE/wEAA/8FAAP/BAAE/wgAA/8JAA
T/AgAL/wUABP8IAP8DCP8DAAT/AwAJ/xYAB/8DAAT/BQAF/xoABP8EAAT/
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
                        render.Image(src = IMAGE_BICYCLE, width = 32, height = 32),
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

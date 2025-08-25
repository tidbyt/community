"""
Applet: Bluebikes
Summary: Boston Bluebikes Status
Description: Displays Boston Bluebike Station Status (Available Bikes, E-Bikes, Docks).
Author: eric-pierce
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Bluebikes Urls
BLUEBIKE_STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_information.json"
BLUEBIKE_STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_status.json"
BLUEBIKE_MISSING_DATA = "DATA_NOT_FOUND"

#Images
BLUEBIKE_IMAGE = base64.decode("""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""")
LIGHTNING_BOLT_IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAQCAYAAAArij59AAAAAXNSR0IArs4c6QAAAMRlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAExAAIAAAATAAAAZodpAAQAAAABAAAAegAAAAAAAABIAAAAAQAAAEgAAAABUGl4ZWxtYXRvciBQcm8gMy43AAAABJAEAAIAAAAUAAAAsKABAAMAAAABAAEAAKACAAQAAAABAAAACKADAAQAAAABAAAAEAAAAAAyMDI1OjA3OjMwIDE1OjU2OjQ1AAm/5pUAAAAJcEhZcwAACxMAAAsTAQCanBgAAAOtaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHRpZmY6WVJlc29sdXRpb24+NzIwMDAwLzEwMDAwPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpYUmVzb2x1dGlvbj43MjAwMDAvMTAwMDA8L3RpZmY6WFJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4xNjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj44PC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAyNS0wNy0zMFQxNTo1NzoxNC0wNDowMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdGVEYXRlPjIwMjUtMDctMzBUMTU6NTY6NDUtMDQ6MDA8L3htcDpDcmVhdGVEYXRlPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sPlBpeGVsbWF0b3IgUHJvIDMuNzwveG1wOkNyZWF0b3JUb29sPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KdYFmswAAAc1JREFUKBVjZEADhXscXHhYeL5+/yl4qcd98VcmkHzD/wYwPelxoZmOtPNuaUGlYxYqP2eD5FhAhORZSWYg9Y+HXbSE5Tv7/1+M9xm4Gf6/A8mBFaTdS2Pk/fJdj+U/g/+TB9cYedne/pX/7z2DgWELA9P+/Q0sjGGMv9g4mFIZmH+z/Wa+yMDF/HWRlkr1FZAJjCBi+ovpYpLC/269eHyd98+Xm4ys7D9Lf3OzLsiR2fsW7DgR4T85jAwf+P7/+vGX47vFv9/vjHu+PmI68/9/Ax/L////GbNPOppwC3xnlPiuwMT+j4Xh3uur/38+u//3OZviH7AJzLPEKz+ukj7JwML9//2vR/8+vb7LKPyWK13KZNY3hoYGSBic/rlfp/dR1O+UdVL/s3tkF4DcBgJMQAX/QIzLTLtCn3+/yPz17ucXel/ESoBCYA8w3b59gu//s/9cL9/fC3x1/S4j+0vG4vSGs2/2n1/PD9LI8H//f5Z9v7YY510w/B9Sy7gLJHbs8SpOEA0CTIyOjH8OvV0b9vLCnX+i19gzGP4zMFrJhn2HSEPJkAVKV4MrWLrA3FAGULwgwKpVq5id4xjUVq3K4jlz5gwXiI+QZWAAAHPFuzOZoDC+AAAAAElFTkSuQmCC""")
ELECTRIC_BIKE_IMAGE = base64.decode("""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""")

#Station cache names
STATION_NAME_CACHE_SUFFIX = "_station_name"
STATION_STATUS_NAME_SUFFIX = "_station_status"
STATIONS_INFO_CACHE = "cache_stations_info"

def find_station_status_by_id(station_id):
    station_status_cached = cache.get(station_id + STATION_STATUS_NAME_SUFFIX)
    if station_status_cached != None:
        station_status = json.decode(station_status_cached)
        return station_status
    else:
        rep = http.get(BLUEBIKE_STATION_STATUS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for find_station_status_by_id failed with status %d", rep.status_code)
        station_list = rep.json()["data"]["stations"]
        for station in station_list:
            if station["station_id"] == station_id:
                station_status = station
                cache.set(station_id + STATION_STATUS_NAME_SUFFIX, json.encode(station_status), ttl_seconds = 30)
                return station_status

    #unable to retrieve station status
    return BLUEBIKE_MISSING_DATA

def find_station_name_by_id(station_id):
    station_name = ""
    station_name_cached = cache.get(station_id + STATION_NAME_CACHE_SUFFIX)
    if station_name_cached != None:
        station_name = station_name_cached
    else:
        rep = http.get(BLUEBIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for find_station_name_by_id failed with status %d", rep.status_code)
        station_list = rep.json()["data"]["stations"]
        for station in station_list:
            if station["station_id"] == station_id:
                station_name = station["name"]
                break
        cache.set(station_id + STATION_NAME_CACHE_SUFFIX, station_name, ttl_seconds = 600)
    return station_name

def get_all_stations():
    stations_info_cached = cache.get(STATIONS_INFO_CACHE)
    if stations_info_cached != None:
        stations_info = json.decode(stations_info_cached)
    else:
        rep = http.get(BLUEBIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for get_all_stations failed with status %d", rep.status_code)
        stations_info = rep.json()["data"]["stations"]
        cache.set(STATIONS_INFO_CACHE, json.encode(stations_info), ttl_seconds = 600)
    return stations_info

def bluebike_station_search(pattern):
    station_list = get_all_stations()
    matching_stations_results = []
    for station in station_list:
        if pattern.upper() in station["name"].upper():
            matching_stations_results.append(
                schema.Option(
                    display = station["name"],
                    value = station["station_id"],
                ),
            )

    # Only show stations when we have a narrower set of results
    if len(matching_stations_results) > 60:
        return []
    else:
        return matching_stations_results

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station",
                name = "Bluebike Station",
                desc = "Name of the Bluebike station",
                icon = "building",
                handler = bluebike_station_search,
            ),
        ],
    )

def main(config):
    station_config = config.get("station")
    if station_config == None:  # Generate fake data
        ebikes_available = "8"
        bikes_available = "2"
        docks_available = "5"
        station_name = "Fenway Outfield"
    else:
        station_config = json.decode(station_config)
        station_id = station_config["value"]
        station = find_station_status_by_id(station_id)

        # Number of ebikes
        ebikes_available = str(int(station["num_ebikes_available"]))

        # Number of docks
        docks_available = str(int(station["num_docks_available"]))

        # bikes_available includes classic and ebikes. Subtracting the ebikes to get classic (non-ebikes) count
        bikes_available = str(int(station["num_bikes_available"] - int(station["num_ebikes_available"])))
        station_name = find_station_name_by_id(station_id = station_id)
    return render.Root(
        render.Column(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render.Marquee(
                    child = render.Text(
                        content = station_name,
                        font = "5x8",
                    ),
                    width = 64,
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Image(src = BLUEBIKE_IMAGE),
                        render.Text(content = bikes_available, font = "6x13"),
                        #render.Image(src = ELECTRIC_BIKE_IMAGE),
                        render.Image(src = LIGHTNING_BOLT_IMAGE),
                        render.Text(content = ebikes_available, font = "6x13"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text(content = "Docks:", font = "5x8", color = "4683B7"),
                        render.Text(content = docks_available, font = "5x8", color = "4683B7"),
                    ],
                ),
            ],
        ),
    )

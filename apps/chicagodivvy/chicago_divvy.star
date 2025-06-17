"""
Applet: Chicago Divvy
Summary: Chicago Divvy Bikes
Description: Displays the number of Divvy bikes available at a Divvy station.
Author: Will (@wilcot)
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Divvy Urls
DIVVY_BIKE_STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_information.json"
DIVVY_BIKE_STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/chi/en/station_status.json"
DIVVY_MISSING_DATA = "DATA_NOT_FOUND"

#Images
DIVVY_BIKE_IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABwAAAAUCAYAAACeXl35AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHKADAAQAAAABAAAAFAAAAABUzb9jAAABZUlEQVRIDdVUO47CQAydrJAoOMByEqjScQ0mVS6DRE0P14AqHcXWnACx9QrakDcaW47HSSDaLdYS8ow/79keB+f+m9RRZN2WjfwZHaRGQtaItPWdEa/97+Q7AGjRgNZ9cbwnxDruQxtwR3WQ5enBZytujM0kHAP0as5EB3rveSwX7fyFOy8GEe1XG1evPwN0URRBX/wu6PNqxvGam96vL4ZzQEbi9rcaPylUDIFyYjwEe8zTPn1PRorussN3+FGnOqnz7ucZyLfTr1ZInuftycgOqTPZKXUIFN0ld9f4qqqqtR85sEMHGSKjAixSTUaYfaTJZ4FxQvrGicUA6Pn641wzRnSQjI3Yo4YfceENaRvh8zGgOMbDCMUFGVs9KcvS6eqskYB34Xf8FqG7EcUkWwoM61t6ZWyS38KAP3lDmfRn59baGixDfqQMxST+xBCJu+xGXZ2kEqP1DyAdBKgXiuxdegjjCc3PJietDLH4AAAAAElFTkSuQmCC""")
LIGHTNING_BOLT_IMAGE = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAEqADAAQAAAABAAAAEgAAAACaqbJVAAAAlUlEQVQ4EaXRwQ2AMAgF0OoYHhzLIR3Lg2to/oEE8FNo5aApwvNHWxus/T4etrKyZtSLEMyXoR4CaMElK41c20l30kQa6b2Q6rLgkSgN5sNEHhE8utNEI4ik/EAzCFIaaBYx0B/EQDj4Yrh8Ez8b/jU/iHOE4Jn5RmhI+TQ9BDulRBkCiCbSaSpImqiKAKKlE9EB0nwByC03I9lPbDMAAAAASUVORK5CYII=""")

#Station cache names
STATION_NAME_CACHE_SUFFIX = "_station_name"
STATION_STATUS_NAME_SUFFIX = "_station_status"
STATIONS_INFO_CACHE = "cache_stations_info"

def find_station_status_by_id(station_id):
    station_status_cached = cache.get(station_id + STATION_STATUS_NAME_SUFFIX)
    if station_status_cached != None:
        station_status = json.decode(station_status_cached)
    else:
        rep = http.get(DIVVY_BIKE_STATION_STATUS_URL)
        if rep.status_code != 200:
            fail("Divvy request for find_station_status_by_id failed with status %d", rep.status_code)
        station_list = rep.json()["data"]["stations"]
        for station in station_list:
            if station["station_id"] == station_id:
                station_status = station
                cache.set(station_id + STATION_STATUS_NAME_SUFFIX, json.encode(station_status), ttl_seconds = 30)
                return station_status

    #unable to retrieve station status
    return DIVVY_MISSING_DATA

def find_station_name_by_id(station_id):
    station_name = ""
    station_name_cached = cache.get(station_id + STATION_NAME_CACHE_SUFFIX)
    if station_name_cached != None:
        station_name = station_name_cached
    else:
        rep = http.get(DIVVY_BIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Divvy request for find_station_name_by_id failed with status %d", rep.status_code)
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
        rep = http.get(DIVVY_BIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Divvy request for get_all_stations failed with status %d", rep.status_code)
        stations_info = rep.json()["data"]["stations"]
        cache.set(STATIONS_INFO_CACHE, json.encode(stations_info), ttl_seconds = 600)
    return stations_info

def divvy_station_search(pattern):
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
                name = "Divvy Station",
                desc = "Name of the Divvy station",
                icon = "building",
                handler = divvy_station_search,
            ),
        ],
    )

def main(config):
    station_config = config.get("station")
    if station_config == None:  # Generate fake data
        ebikes_available = "3"
        bikes_available = "5"
        station_name = "Halsted & Roscoe"
    else:
        station_config = json.decode(station_config)
        station_id = station_config["value"]
        station = find_station_status_by_id(station_id = station_id)

        # Number of ebikes
        ebikes_available = str(int(station["num_ebikes_available"]))

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
                        render.Image(src = DIVVY_BIKE_IMAGE),
                        render.Text(content = bikes_available, font = "6x13"),
                        render.Image(src = LIGHTNING_BOLT_IMAGE),
                        render.Text(content = ebikes_available, font = "6x13"),
                    ],
                ),
            ],
        ),
    )

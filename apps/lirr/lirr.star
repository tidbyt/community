"""
Applet: LIRR
Summary: LIRR Train Times
Description: Long Island Railroad Train Times.
Author: bralax
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DELTA = .1
STATIC_GTFS_FILE = "static_gtfs"

CORE_BACKGROUND_COLOR = "#4D5357"
CORE_TEXT_COLOR = "#FFFFFF"
PENN_STATION = "237"

def main(config):
    station_id = config.str("station")
    if station_id == None:
        station_id = PENN_STATION
    else:
        station_id = json.decode(station_id)["value"]
    gtfs = get_gtfs()
    stops = getIds(gtfs, station_id)
    if stops == None or len(stops) == 0:
        return render.Root(child = render.Marquee(
            width = 64,
            child = render.Text("No trains found"),
            offset_start = 5,
            offset_end = 32,
        ))
    if len(stops) == 1:
        return render.Root(child = renderTrain(gtfs, stops[0]))
    return render.Root(child = render.Column(
        children = [
            renderTrain(gtfs, stops[0]),
            render.Box(
                color = "#ffffff",
                width = 64,
                height = 1,
            ),
            renderTrain(gtfs, stops[1]),
        ],
    ))

def renderTrain(gtfs, stop_time):
    trip = gtfs["trips"][stop_time["trip_id"]]
    destination = trip["trip_headsign"]
    route = gtfs["routes"][trip["route_id"]]
    textColor = "#" + route["route_text_color"]
    backgroundColor = "#" + route["route_color"]
    if trip["direction_id"] == "1":
        textColor = CORE_TEXT_COLOR
        backgroundColor = CORE_BACKGROUND_COLOR

    time = display_time(stop_time["arrival_time"])

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [render.Padding(
            pad = 2,
            child = render.Box(
                width = 10,
                height = 10,
                color = backgroundColor,
                child = render.Text(
                    color = textColor,
                    content = destination[0],
                ),
            ),
        ), render.Column(
            children = [
                render.Marquee(
                    width = 64 - 16,
                    child = render.Text(
                        content = destination.upper(),
                    ),
                ),
                render.Text(
                    content = time,
                    color = "#ff9900",
                ),
            ],
        )],
    )

def display_time(time_string):
    spl = time_string.split(":")
    hours = int(spl[0])
    if hours > 24:
        hours -= 24
    minutes = int(spl[1])
    seconds = int(spl[2])
    time_obj = time.time(hour = hours, minute = minutes, second = seconds)
    return time_obj.format("03:04 PM")

def now():
    tim = time.now().in_location("America/New_York")
    return {"time": (tim.hour * 3600) + (tim.minute * 60) + tim.second, "date": tim.year * 10000 + tim.month * 100 + tim.day, "timeObj": tim}

def prevDay(cur_date):
    tim = cur_date["timeObj"]
    duration = time.parse_duration("24h")
    tim = tim - duration
    return {"time": (tim.hour * 3600) + (tim.minute * 60) + tim.second, "date": tim.year * 10000 + tim.month * 100 + tim.day, "timeObj": tim}

def nextDay(cur_date):
    tim = cur_date["timeObj"]
    duration = time.parse_duration("24h")
    tim = tim + duration
    return {"time": (tim.hour * 3600) + (tim.minute * 60) + tim.second, "date": tim.year * 10000 + tim.month * 100 + tim.day, "timeObj": tim}

def getIds(gtfs, station_id):
    ids = []
    time_now = now()
    id = getId(gtfs, station_id, time_now)
    if not id == None:
        ids.append(gtfs["stop_times"][station_id][id])
        id = getId(gtfs, station_id, time_now, id + 1)
        if not id == None:
            ids.append(gtfs["stop_times"][station_id][id])
    if len(ids) == 2:
        return ids
    time_now = nextDay(time_now)
    time_now["time"] = 0
    id = getId(gtfs, station_id, time_now)
    if not id == None:
        ids.append(gtfs["stop_times"][station_id][id])
        if len(ids) == 2:
            return ids
        id = getId(gtfs, station_id, time_now, id + 1)
        if not id == None:
            ids.append(gtfs["stop_times"][station_id][id])
    return ids

def getId(gtfs, station_id, time_now, startingIndex = 0):
    stop_times = gtfs["stop_times"][station_id]
    for i in range(startingIndex, len(stop_times)):
        stop_time = stop_times[i]
        cur_date = time_now["date"]
        tim = time_now["time"]
        if stop_time["is_previous"]:
            cur_date = prevDay(time_now)["date"]
        if stop_time["timestamp"] > tim and str(cur_date) in gtfs["calendar"] and gtfs["trips"][stop_time["trip_id"]]["service_id"] in gtfs["calendar"][str(cur_date)]:
            return i

    return None

def get_stations(loc):
    location = json.decode(loc)
    res = get_gtfs()
    stops = res["stops"]
    closeStops = []
    for stop in stops.values():
        delt = math.fabs(float(stop["stop_lat"]) - float(location["lat"])) + math.fabs(float(stop["stop_lon"]) - float(location["lng"]))
        if delt < DELTA:
            stop["delta"] = delt
            closeStops.append(stop)
    sortedStops = sorted(closeStops, key = get_delta)
    options = []
    for stop in sortedStops:
        options.append(schema.Option(display = stop["stop_name"], value = stop["stop_id"]))
    return options

def get_delta(stop):
    return stop["delta"]

def get_gtfs():
    cached = cache.get(STATIC_GTFS_FILE)
    if cached == None:
        resText = http.get("http://web.mta.info/developers/data/lirr/lirr_gtfs.json").body()
        res = parse_gtfs(json.decode(resText)["gtfs"])
        cache.set(STATIC_GTFS_FILE, json.encode(res), ttl_seconds = 3600)
        return res
    else:
        return json.decode(cached)

def parse_gtfs(gtfs):
    calendar = generate_calendar(gtfs)
    trips = generate_triplist(gtfs)
    routes = generate_routeslist(gtfs)
    stops = generate_stoplist(gtfs)
    stop_times = generate_stoptimelist(remove_destinations(gtfs["stop_times"], trips, stops))
    return {"stop_times": stop_times, "calendar": calendar, "trips": trips, "routes": routes, "stops": stops}

def generate_calendar(gtfs):
    calendar_dates = gtfs["calendar_dates"]
    calendar = {}
    for item in calendar_dates:
        date = str(item["date"])
        if not calendar.get(date):
            calendar[date] = [item["service_id"]]
        else:
            calendar[date].append(item["service_id"])
    return calendar

def generate_stoptimelist(stop_times):
    stops = {}
    for item in stop_times:
        set_timestamp(item)
        if not stops.get(item["stop_id"]):
            stops[item["stop_id"]] = [item]
        else:
            stops[item["stop_id"]].append(item)
    sorted_stops = {}
    for stop in stops:
        sorted_stops[stop] = sorted(stops[stop], key = get_time)
    return sorted_stops

def set_timestamp(stop_time):
    time = stop_time["arrival_time"]
    spl = time.split(":")
    hours = int(spl[0])
    is_previous = hours > 23
    stop_time["is_previous"] = is_previous
    if is_previous:
        hours -= 24
    minutes = int(spl[1])
    seconds = int(spl[2])
    stop_time["timestamp"] = (hours * 3600) + (minutes * 60) + seconds

def get_time(stop):
    return stop["timestamp"]

def generate_triplist(gtfs):
    trip_list = gtfs["trips"]
    trips = {}
    for item in trip_list:
        trips[item["trip_id"]] = item
    return trips

def generate_routeslist(gtfs):
    route_list = gtfs["routes"]
    routes = {}
    for item in route_list:
        routes[item["route_id"]] = item
    return routes

def generate_stoplist(gtfs):
    stop_list = gtfs["stops"]
    stops = {}
    for item in stop_list:
        stops[item["stop_id"]] = item
    return stops

def remove_destinations(stop_time_list, trip_list, stop_list):
    cleaned_stops = []
    for stop_time in stop_time_list:
        trip_name = trip_list[stop_time["trip_id"]]["trip_headsign"]
        stop_name = stop_list[stop_time["stop_id"]]["stop_name"]
        if not trip_name == stop_name:
            cleaned_stops.append(stop_time)
    return cleaned_stops

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "station",
                name = "Train Station",
                desc = "A list of LIRR train stations based on a location.",
                icon = "train",
                handler = get_stations,
            ),
        ],
    )

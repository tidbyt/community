"""
Applet: NS Timetable
Author: tim-hanssen
Summary: NS Timetable
Description: Shows a timetable for a station in the Dutch Railways.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

API_KEY = "20f49c5c5e43465cab9ac8812c84ab22"

CORE_BACKGROUND_COLOR = "#003082"
CANCELED_BACKGROUND_COLOR = "#DB0029"

CORE_TEXT_COLOR = "#FFFFFF"
NORMAL_TEXT_COLOR = "#FFC917"
DELAYED_TEXT_COLOR = "#DB0029"

NO_FRAMES_TOGGLE = 60

DEFAULT_STATION = "ASD"

def main(config):
    station_id = config.str("station")
    skiptime = config.get("skiptime", 0)

    # Check if we need to convert the skiptime to Int
    if type(skiptime) == "string":
        skiptime = int(skiptime)

    # Check that the skip time is valid
    if skiptime < 0:
        skiptime = 0

    if station_id == None:
        station_id = DEFAULT_STATION
    else:
        station_id = json.decode(station_id)["value"]

    resp_cached = cache.get("ns_%s" % station_id)
    if resp_cached != None:
        # Get the cached response
        # print("Hit!")
        stops = json.decode(resp_cached)
    else:
        # print("Miss!")
        stops = getTrains(station_id, skiptime)
        cache.set("ns_%s" % station_id, json.encode(stops), ttl_seconds = 60)

    if stops == None or len(stops) == 0:
        return render.Root(child = render.Marquee(
            width = 64,
            child = render.Text("No trains running"),
            offset_start = 5,
            offset_end = 32,
        ))
    if len(stops) == 1:
        return render.Root(child = renderTrain(stops[0]))
    return render.Root(child = render.Column(
        children = [
            renderTrain(stops[0]),
            render.Box(
                color = "#ffffff",
                width = 64,
                height = 1,
            ),
            renderTrain(stops[1]),
        ],
    ))

def renderTrain(stop_info):
    destination = stop_info["direction"]
    departureTime = display_time(stop_info["plannedDateTime"])
    backgroundColor = CORE_BACKGROUND_COLOR
    textColor = CORE_TEXT_COLOR

    train = stop_info["trainCategory"]

    departureTimeText = humanize.relative_time(time.now(), parse_time(stop_info["actualDateTime"]))

    destination = train + " " + destination

    if stop_info["cancelled"] == True:
        backgroundColor = CANCELED_BACKGROUND_COLOR
        departureTime = stop_info["messages"][0]["message"]

    actualTime = parse_time(stop_info["actualDateTime"])
    scheduledTime = parse_time(stop_info["plannedDateTime"])
    delay = actualTime - scheduledTime
    trainDelay = format_duration(delay)

    departureTimeRender = render.Text(
        content = departureTime,
        color = NORMAL_TEXT_COLOR,
    )

    if trainDelay != "":
        renderTimeChild = []
        renderTimeChild.extend([departureTimeRender] * NO_FRAMES_TOGGLE)
        renderTimeChild.extend(
            [
                render.Text(
                    content = "+" + trainDelay + " min",
                    color = DELAYED_TEXT_COLOR,
                ),
            ] * NO_FRAMES_TOGGLE,
        )

        departureTimeRender = render.Animation(children = renderTimeChild)

    else:
        renderTimeChild = []
        renderTimeChild.extend([departureTimeRender] * NO_FRAMES_TOGGLE)
        renderTimeChild.extend(
            [
                render.Text(
                    content = departureTimeText[:-5],
                    color = NORMAL_TEXT_COLOR,
                ),
            ] * NO_FRAMES_TOGGLE,
        )

        departureTimeRender = render.Animation(children = renderTimeChild)

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            render.Padding(
                pad = 2,
                child = render.Box(
                    width = 10,
                    height = 10,
                    color = backgroundColor,
                    child = render.Text(
                        color = textColor,
                        content = stop_info["actualTrack"],
                    ),
                ),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 64 - 13,
                        child = render.Text(
                            content = destination.upper(),
                        ),
                    ),
                    departureTimeRender,
                ],
            ),
        ],
    )

def format_duration(d):
    if d.hours > 1:
        return str(int(d.hours + 0.5)) * 60
    elif d.minutes > 1:
        return str(int(d.minutes + 0.5))
    else:
        return ""

def display_time(time_string):
    time_obj = time.parse_time(time_string[0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
    return time_obj.format("15:04")

def parse_time(time_string):
    time_obj = time.parse_time(time_string[0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
    return time_obj

def getTrains(station_id, skiptime):
    departureRes = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/departures", params = {"station": station_id}, headers = {"Ocp-Apim-Subscription-Key": "20f49c5c5e43465cab9ac8812c84ab22"}).body()
    departures = json.decode(departureRes)
    departuresTrains = departures["payload"]
    departuresTrains = departuresTrains["departures"]

    startID = 0

    if skiptime > 0:
        timeStart = time.parse_duration("%im" % skiptime) + time.now()

        for i, train in enumerate(departuresTrains):
            timeDepart = time.parse_time(train["actualDateTime"][0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
            if timeDepart >= timeStart:
                startID = i
                break

    return departuresTrains[startID:]

def search_station1(loc):
    location = json.decode(loc)
    resp = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/stations", params = {"q": location["locality"], "limit": "10"}, headers = {"Ocp-Apim-Subscription-Key": "20f49c5c5e43465cab9ac8812c84ab22"})

    if resp.status_code != 200:
        # Return an Error
        return [
            schema.Option(
                display = "No stations found",
                value = "No stations found",
            ),
        ]

    stations = json.decode(resp.body())

    # Check if the response is empty
    if len(stations["payload"]) == 0:
        return [
            schema.Option(
                display = "No stations found",
                value = "No stations found",
            ),
        ]

    stationslist = stations["payload"]
    options = []
    for stop in stationslist:
        options.append(schema.Option(display = stop["namen"]["lang"], value = stop["code"]))
    return options

def search_station(pattern):
    ns_dict = {"q": pattern}  # Provide the pattern with a dict, as this will be encoded
    resp = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/stations", params = ns_dict, headers = {"Ocp-Apim-Subscription-Key": "20f49c5c5e43465cab9ac8812c84ab22"})

    if resp.status_code != 200:
        # Return an Error
        return [
            schema.Option(
                display = "No stations found",
                value = "No stations found",
            ),
        ]

    resp = json.decode(resp.body())

    # Check if the response is empty
    if len(resp["payload"]) == 0:
        return [
            schema.Option(
                display = "No stations found",
                value = "No stations found",
            ),
        ]

    # Create Return list
    options = []

    # Loop through all returned stations
    for station in resp["payload"]:
        options.append(
            schema.Option(
                display = station["namen"]["lang"],
                value = station["code"],
            ),
        )

    # Return the station options
    return options

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station",
                name = "Station",
                desc = "Station from which the timetable shall be shown.",
                icon = "train",
                handler = search_station,
            ),
            schema.Text(
                id = "skiptime",
                name = "Departure Offset (Minutes)",
                desc = "Shows the connections starting n minutes in the future.",
                icon = "clock",
            ),
        ],
    )

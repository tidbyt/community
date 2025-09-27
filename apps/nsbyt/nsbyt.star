"""
Applet: NS Timetable
Author: tim-hanssen
Summary: NS Timetable
Description: Shows a timetable for a station in the Netherlands (NS).
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_KEY = "20f49c5c5e43465cab9ac8812c84ab22"

CORE_BACKGROUND_COLOR = "#003082"
INFO_BACKGROUND_COLOR = "#FF7700"
MAINTENANCE_BACKGROUND_COLOR = "#FFB519"
CANCELED_BACKGROUND_COLOR = "#DB0029"

TIME_GREEN = "#5fdb00"
TIME_ORANGE = "#FF7700"
TIME_RED = "#DB0029"

BLACK_TEXT_COLOR = "#000"
CORE_TEXT_COLOR = "#FFFFFF"
NORMAL_TEXT_COLOR = "#FFC917"
DELAYED_TEXT_COLOR = "#DB0029"
MAINTENANCE_TEXT_COLOR = "#FF7700"

NO_FRAMES_TOGGLE = 60

DEFAULT_STATION = "ehv"

def main(config):
    station_id = config.str("station")
    station_dest = config.str("dest_station")
    skip_time = config.get("skiptime", 0)
    time_to_leave = config.bool("time_to_leave", False)

    if station_id == None:
        station_id = DEFAULT_STATION
    else:
        station_id = json.decode(station_id)["value"]

    # Check if we need to convert the skip_time to Int
    if (skip_time):
        if type(skip_time) == "string":
            skip_time = int(skip_time)

    # Check that the skip time is valid
    if skip_time < 0:
        skip_time = 0

    # If we don't have a Trip, list trains for station.
    if station_dest == None:
        # Normal Train Operations
        stops = getTrains(station_id, skip_time)

    else:
        station_dest = json.decode(station_dest)["value"]
        stops = getTrip(station_id, station_dest, skip_time)

    if stops == None or len(stops) == 0:
        return render.Root(
            child = render.Padding(
                pad = (3, 8, 1, 1),
                child = render.WrappedText(
                    content = "No trains scheduled",
                ),
            ),
        )

    if len(stops) == 1:
        return render.Root(child = renderTrain(stops[0], skip_time, time_to_leave))

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                renderTrain(stops[0], skip_time, time_to_leave),
                render.Box(
                    color = "#ffffff",
                    width = 64,
                    height = 1,
                ),
                renderTrain(stops[1], skip_time, time_to_leave),
            ],
        ),
    )

def renderTrain(stop_info, skip_time, time_to_leave):
    backgroundColor = CORE_BACKGROUND_COLOR
    textColor = CORE_TEXT_COLOR

    destination = stop_info["direction"]
    departureTime = display_time(stop_info["plannedDateTime"])
    actualTime = display_time(stop_info["actualDateTime"])

    # For later.
    # train = stop_info["trainCategory"]

    # Calculate minutes to departure.
    departureTimeText = humanize.relative_time(time.now(), parse_time(stop_info["actualDateTime"]))
    departureTimeText = re.sub("(minutes|minute)", "min", departureTimeText)
    departureTimeText = re.sub("(seconds|second)", "sec", departureTimeText)

    # Info messages.
    message = None

    # If trains is cancelled, rewrite to message.
    if stop_info["cancelled"] == True:
        backgroundColor = CANCELED_BACKGROUND_COLOR
        departureTime = "-"
        actualTime = "-"

        if stop_info.get("messages"):
            actualTime = stop_info["messages"][0]["message"]

    # If trains is changed due to maintenance, rewrite to message.
    if stop_info.get("alternativeTransport") == True:
        backgroundColor = MAINTENANCE_BACKGROUND_COLOR
        message = stop_info["displayName"]

    if stop_info.get("messages") != None:
        if len(stop_info.get("messages")) > 0:
            message = stop_info["messages"][0]["message"]

    # Calculate if there are delays.
    delay = parse_time(stop_info["actualDateTime"]) - parse_time(stop_info["plannedDateTime"])
    trainDelay = format_duration(delay)

    # Render Scheduled Time.
    departureTimeRender = render.Text(
        content = departureTime,
        color = NORMAL_TEXT_COLOR,
    )

    # If there is a delay, change render.
    if trainDelay != "":
        renderTimeChild = []
        renderTimeChild.extend([departureTimeRender] * NO_FRAMES_TOGGLE)
        renderTimeChild.extend(
            [
                render.Text(
                    content = actualTime + " +" + trainDelay,
                    color = DELAYED_TEXT_COLOR,
                ),
            ] * NO_FRAMES_TOGGLE,
        )

        departureTimeRender = render.Animation(children = renderTimeChild)

    else:
        # Special notices content = actualTime + " | " + message,
        if message:
            departureTimeRender = render.Marquee(
                width = 64 - 13,
                child = render.Text(
                    content = actualTime,
                    color = MAINTENANCE_TEXT_COLOR,
                ),
            )

            departureTimeRenderMaintenance = render.Marquee(
                width = 64 - 13,
                child = render.Text(
                    content = message,
                    color = MAINTENANCE_TEXT_COLOR,
                ),
            )

            renderTimeChild = []
            renderTimeChild.extend([departureTimeRender] * departureTimeRender.frame_count())
            renderTimeChild.extend([departureTimeRenderMaintenance] * (departureTimeRenderMaintenance.frame_count() + departureTimeRender.frame_count()))
            renderTimeChild.extend(
                [
                    render.Text(
                        content = departureTimeText,
                        color = NORMAL_TEXT_COLOR,
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
                        content = departureTimeText,
                        color = NORMAL_TEXT_COLOR,
                    ),
                ] * NO_FRAMES_TOGGLE,
            )

            departureTimeRender = render.Animation(children = renderTimeChild)

    # Render Time To Leave indicator
    timeToLeaveColor = TIME_GREEN

    if time_to_leave == True:
        departureTimeInSeconds = (parse_time(stop_info["actualDateTime"]) - time.now()).seconds

        # LESS THAN SKIP TIME + 3 MIN
        if departureTimeInSeconds < ((skip_time * 60) + 180):
            timeToLeaveColor = TIME_RED

        # LESS THAN SKIP TIME + 6 MIN
        if departureTimeInSeconds < ((skip_time * 60) + 360):
            if departureTimeInSeconds > ((skip_time * 60) + 180):
                timeToLeaveColor = TIME_ORANGE

        # Hide TTL indicator if cancelled
        if stop_info["cancelled"] == True:
            timeToLeaveColor = BLACK_TEXT_COLOR

    # Render Final rows
    renderTrainFinal = []

    if time_to_leave == True:
        renderTrainFinal.extend([
            render.Padding(
                pad = (0, 0, 0, 2),
                child = render.Box(
                    width = 2,
                    height = 10,
                    color = timeToLeaveColor,
                ),
            ),
        ])

    renderTrainFinal.extend([
        render.Padding(
            pad = 2,
            child = render.Box(
                width = 10,
                height = 10,
                color = backgroundColor,
                child = render.Text(
                    color = textColor,
                    content = stop_info.get("actualTrack", "-"),
                ),
            ),
        ),
        render.Column(
            children = [
                render.Marquee(
                    width = 64 - 14,
                    child = render.Text(
                        content = destination.upper(),
                    ),
                ),
                departureTimeRender,
            ],
        ),
    ])

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = renderTrainFinal,
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

def getTrip(station_id, station_dest, skip_time):
    resp = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v3/trips", params = {"fromStation": station_id, "toStation": station_dest}, headers = {"Ocp-Apim-Subscription-Key": API_KEY}, ttl_seconds = 30)

    if resp.status_code != 200:
        return []
    else:
        departures = json.decode(resp.body())

    # Create return list
    stops = []

    # Loop through all returned stations
    for trip in departures["trips"][0:4]:
        origin = trip["legs"][0]["origin"]
        originTime = origin.get("actualDateTime", origin.get("plannedDateTime"))

        # Skip departed trains.
        timeDepart = time.parse_time(originTime[0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
        if timeDepart <= time.now():
            continue

        # Skip trains that are not in allowed frame.
        if skip_time > 0:
            timeStart = time.parse_duration("%im" % skip_time) + time.now()
            timeDepart = time.parse_time(originTime[0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
            if timeDepart >= timeStart:
                stops.append(
                    {
                        "direction": trip["legs"][0]["direction"],
                        "plannedDateTime": trip["legs"][0]["origin"]["plannedDateTime"],
                        "actualDateTime": originTime,
                        "actualTrack": trip["legs"][0]["origin"].get("plannedTrack", "-"),
                        "trainCategory": trip["legs"][0]["product"]["categoryCode"],
                        "alternativeTransport": trip["legs"][0].get("alternativeTransport"),
                        "displayName": trip["legs"][0]["product"]["displayName"],
                        "cancelled": trip["legs"][0]["cancelled"],
                    },
                )
        else:
            stops.append(
                {
                    "direction": trip["legs"][0]["direction"],
                    "plannedDateTime": trip["legs"][0]["origin"]["plannedDateTime"],
                    "actualDateTime": originTime,
                    "actualTrack": trip["legs"][0]["origin"].get("plannedTrack", "-"),
                    "trainCategory": trip["legs"][0]["product"]["categoryCode"],
                    "alternativeTransport": trip["legs"][0].get("alternativeTransport"),
                    "displayName": trip["legs"][0]["product"]["displayName"],
                    "cancelled": trip["legs"][0]["cancelled"],
                },
            )

    return stops

def getTrains(station_id, skip_time):
    resp = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/departures", params = {"station": station_id}, headers = {"Ocp-Apim-Subscription-Key": API_KEY}, ttl_seconds = 30)

    if resp.status_code != 200:
        cache.set("ns_%s" % station_id, json.encode([]), ttl_seconds = 30)
        return []
    else:
        departures = json.decode(resp.body())
        cache.set("ns_%s" % station_id, resp.body(), ttl_seconds = 30)

    # Return the trains
    departuresTrains = departures["payload"]["departures"]

    startID = 0

    if skip_time > 0:
        timeStart = time.parse_duration("%im" % skip_time) + time.now()

        for i, train in enumerate(departuresTrains):
            timeDepart = time.parse_time(train["actualDateTime"][0:19], format = "2006-01-02T15:04:05", location = "Europe/Amsterdam")
            if timeDepart >= timeStart:
                startID = i
                break

    return departuresTrains[startID:]

def search_station(pattern):
    ns_dict = {"q": pattern}  # Provide the pattern with a dict, as this will be encoded
    resp = http.get("https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/stations", params = ns_dict, headers = {"Ocp-Apim-Subscription-Key": API_KEY}, ttl_seconds = 8600)

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
            schema.Typeahead(
                id = "dest_station",
                name = "Destination Station",
                desc = "Trains will be filtered by destination (optional).",
                icon = "train",
                handler = search_station,
            ),
            schema.Text(
                id = "skiptime",
                name = "Departure Offset (Minutes)",
                desc = "Shows the connections starting n minutes in the future.",
                icon = "clock",
            ),
            schema.Toggle(
                id = "time_to_leave",
                name = "Time To Leave",
                desc = "Shows a green/orange/red line to indicate how soon you need to leave your house to catch the train. (uses Departure Offset to render the indicator).",
                icon = "personWalking",
            ),
        ],
    )

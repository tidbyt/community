"""
Applet: SBB Timetable
Author: LukiLeu
Summary: SBB Timetable
Description: Shows a timetable for a station in the Swiss Public Transport
    network.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ERROR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/
9hAAAAbklEQVQ4y72S0Q2AIAwFj8YRZBf2/2IXVtDU
D6LRBAsIsUm/aHMvV8AoTUE1BbVmhMFyFv0x6KP7L8
FFP1/1PYUUlgXYAFhj7k6JO7C0eJniQGqEWop5V2ih
l/6FncDH3DUHvfT7zriDL/SpVzgA+N8ttq4TxtUAAA
AASUVORK5CYII=
""")

# Define some constants
SBB_URL = "https://fahrplan.search.ch/api/stationboard.json?show_delays=1&transportation_types=train"
SBB_URL_COMPLETION = "https://fahrplan.search.ch/api/completion.json"

SBB_COMPLETION_TRAINSTATION_STRING = "sl-icon-type-train"

FONT_TO_USE = "CG-pixel-3x5-mono"
NO_FRAMES_TOGGLE = 20
COLOR_CATEGORY = {
    "IC": "#700",
    "ICN": "#700",
    "ICE": "#700",
    "EC": "#700",
    "IR": "#700",
    "RE": "#700",
    "RJX": "#700",
    "TGV": "#700",
    "NJ": "#700",
    "S": "#007",
    "SN": "#111",
}
COLOR_DELAY = "#F00"

DEFAULT_STATION = {
    "value": "Bern",
}

# Show an error message
def display_error(msg):
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    width = 20,
                    height = 32,
                    color = "#000",
                    child = render.Image(
                        src = ERROR_ICON,
                        width = 16,
                        height = 16,
                    ),
                ),
                render.Box(
                    padding = 0,
                    width = 44,
                    height = 32,
                    child =
                        render.WrappedText(
                            content = msg,
                            color = "#FFF",
                            linespacing = 1,
                            font = FONT_TO_USE,
                        ),
                ),
            ],
        ),
    )

def main(config):
    # Get the config values
    station_full = config.get("station")
    station_json = json.decode(station_full) if station_full else DEFAULT_STATION
    station = station_json.get("value")
    skiptime = config.get("skiptime", 0)

    # Check if we need to convert the skiptime
    if type(skiptime) == "string":
        skiptime = int(skiptime)

    # Check that the skip time is valid
    if skiptime < 0:
        skiptime = 0

    # Check if we have the requested data in the cache
    resp_cached = cache.get("sbb_%s" % station)
    if resp_cached != None:
        # Get the cached response
        print("Hit! Displaying cached data.")
        resp = json.decode(resp_cached)
    else:
        # Get a new reponse
        print("Miss! Calling API.")
        sbb_dict = {"stop": station}  # Provide the station with a dict, as this will be encoded
        resp = http.get(SBB_URL, params = sbb_dict)
        if resp.status_code != 200:
            # Show an error message
            return (display_error("API Error occured"))
        cache.set("sbb_%s" % station, resp.body(), ttl_seconds = 120)
        resp = json.decode(resp.body())

    # Check if we got a valid response
    if "connections" not in resp:
        # Show an error message
        return (display_error("%s is not a valid station." % station))
    elif resp["connections"] == None:
        # Show an error message
        return (display_error("No connections found."))
    else:
        # Get the starting id in the data, this is prepared in case the cache time needs to be increased due to much api calls
        startID = 0
        timeStart = time.parse_duration("%im" % skiptime) + time.now()
        for i, connection in enumerate(resp["connections"]):
            timeDepart = time.parse_time(connection["time"], format = "2006-01-02 15:04:05", location = "Europe/Zurich")
            if timeDepart >= timeStart:
                startID = i
                break

        # Generate the board
        childRow = []
        for i in range(startID, startID + 5):
            # Get the data from the response
            trainCategory = resp["connections"][i]["*G"]
            if trainCategory[0] == "S":
                trainCategoryLine = resp["connections"][i]["line"].replace("S", "")
            else:
                trainCategoryLine = trainCategory
            trainDest = resp["connections"][i]["terminal"]["name"]
            trainTime = resp["connections"][i]["time"]
            if "dep_delay" in resp["connections"][i]:
                trainDelay = resp["connections"][i]["dep_delay"]
            else:
                trainDelay = "+0"
            if trainCategory in COLOR_CATEGORY:
                trainCategoryColor = COLOR_CATEGORY[trainCategory]
            else:
                trainCategoryColor = "#111"

            # Render the train category
            renderCategory = []
            renderCategory.extend(
                [
                    render.Box(
                        width = 8,
                        height = 5,
                        color = trainCategoryColor,
                        padding = 0,
                        child = render.Text(
                            content = "%s" % trainCategory,
                            font = FONT_TO_USE,
                        ),
                    ),
                ] * NO_FRAMES_TOGGLE,
            )

            renderCategory.extend(
                [
                    render.Box(
                        width = 8,
                        height = 5,
                        color = trainCategoryColor,
                        padding = 0,
                        child = render.Text(
                            content = "%s" % trainCategoryLine,
                            font = FONT_TO_USE,
                        ),
                    ),
                ] * NO_FRAMES_TOGGLE,
            )

            # Render the train delay
            renderTimeNormal = render.Text(
                content = "%s" % time.parse_time(trainTime, format = "2006-01-02 15:04:05").format("15:04"),
                font = FONT_TO_USE,
            )

            if trainDelay == "+0":
                renderTime = renderTimeNormal
            else:
                renderTimeChild = []
                renderTimeChild.extend([renderTimeNormal] * NO_FRAMES_TOGGLE)
                if trainDelay == "X":
                    delayText = "--:--"
                else:
                    delayText = (time.parse_duration("%sm" % trainDelay) + time.parse_time(trainTime, format = "2006-01-02 15:04:05")).format("15:04")
                renderTimeChild.extend(
                    [
                        render.Text(
                            content = delayText,
                            font = FONT_TO_USE,
                            color = COLOR_DELAY,
                        ),
                    ] * NO_FRAMES_TOGGLE,
                )
                renderTime = render.Animation(children = renderTimeChild)

            # Render the full row
            childRow.append(
                render.Row(
                    children = [
                        render.Animation(children = renderCategory),
                        render.Box(width = 1, height = 5),
                        renderTime,
                        render.Text(
                            content = "" if trainDelay == "+0" else "%s" % trainDelay,
                            color = COLOR_DELAY,
                            font = FONT_TO_USE,
                        ),
                        render.Marquee(
                            width = 36 if trainDelay == "+0" else 36 - len(trainDelay) * 4,
                            child = render.Text(
                                content = "%s" % trainDest,
                                font = FONT_TO_USE,
                            ),
                            offset_start = 0,
                            offset_end = 0,
                        ),
                    ],
                ),
            )

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = childRow,
        ),
    )

def search_station(pattern):
    # Check if we have the requested data in the cache
    resp_cached = cache.get("sbb_pattern_%s" % pattern)
    if resp_cached != None:
        # Get the cached response
        print("Pattern Hit! Displaying cached data.")
        resp = json.decode(resp_cached)
    else:
        # Get a new reponse
        print("Pattern Miss! Calling API.")
        sbb_dict = {"term": pattern}  # Provide the pattern with a dict, as this will be encoded
        resp = http.get(SBB_URL_COMPLETION, params = sbb_dict)
        if resp.status_code != 200:
            # Return an error message
            return [
                schema.Option(
                    display = "API Error",
                    value = "API Error",
                ),
            ]
        cache.set("sbb_pattern_%s" % pattern, resp.body(), ttl_seconds = 604800)
        resp = json.decode(resp.body())

    # Check if the response is empty
    if len(resp) == 0:
        return [
            schema.Option(
                display = "No Stations found",
                value = "No Stations found",
            ),
        ]

    # Create empty list
    trainStations = []

    # Loop through all returned elements and filter out the trainstations
    for station in resp:
        if station["iconclass"] == SBB_COMPLETION_TRAINSTATION_STRING:
            trainStations.append(
                schema.Option(
                    display = station["label"],
                    value = station["label"],
                ),
            )

    # Check if we did not found some train stations
    if len(trainStations) == 0:
        return [
            schema.Option(
                display = "No Train-Stations found",
                value = "No Train-Stations found",
            ),
        ]

    # Return the found stations
    return trainStations

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

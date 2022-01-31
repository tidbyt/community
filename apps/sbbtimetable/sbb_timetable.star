load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")

# Define some constants
SBB_URL = "https://fahrplan.search.ch/api/stationboard.json?show_delays=1&transportation_types=train&stop="
FONT_TO_USE = "CG-pixel-3x5-mono"
NO_FRAMES_TOGGLE = 20
COLOR_CATEGORY = {
    "IC": "#700",
    "EC": "#700",
    "IR": "#700",
    "RE": "#700",
    "RJX": "#700",
    "TGV": "#700",
    "NJ": "#700",
    "S": "#007",
    "SN": "#000",
}
COLOR_DELAY = "#F00"

def main(config):
    # Get the config values
    station = config.get("station", "Bern")
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
        resp = http.get("%s%s" % (SBB_URL, station))
        if resp.status_code != 200:
            fail("Request failed with status %d", resp.status_code)
        cache.set("sbb_%s" % station, resp.body(), ttl_seconds = 120)
        resp = json.decode(resp.body())

    # Check if we got a valid response
    if "connections" not in resp:
        # Show an error message
        childRow = [
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "%s is not a valid station." % station,
                    font = FONT_TO_USE,
                ),
                offset_start = 0,
                offset_end = 0,
            ),
        ]
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

            # Render the train category
            renderCategory = []
            renderCategory.extend(
                [
                    render.Box(
                        width = 8,
                        height = 5,
                        color = COLOR_CATEGORY[trainCategory],
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
                        color = COLOR_CATEGORY[trainCategory],
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

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station",
                name = "Station",
                desc = "Station from which the timetable shall be shown.",
                icon = "train",
            ),
            schema.Text(
                id = "skiptime",
                name = "Departure Offset (Minutes)",
                desc = "Shows the connections starting n minutes in the future.",
                icon = "clock",
            ),
        ],
    )

"""
Applet: MBTA New Trains
Summary: Track new MBTA subway cars
Description: Displays the real time location of new subway cars in Boston's MBTA rapid transit system.
Author: joshspicer
"""

load("render.star", "render")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

# MBTA New Train Tracker
#
# Copyright (c) 2022 Josh Spicer <hello@joshspicer.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

STATION_NAMES_URL = "https://traintracker.transitmatters.org/stops/Green-B,Green-C,Green-D,Green-E,Orange,Red"
TRAIN_LOCATION_URL = "https://traintracker.transitmatters.org/trains/Green-B,Green-C,Green-D,Green-E,Orange,Red-A,Red-B"

ARROW_DOWN = "⇩"
ARROW_UP = "⇧"
ARROW_RIGHT = "⇨"
ARROW_LEFT = "⇦"

RED = "#FF0000"
GREEN = "#00FF00"
ORANGE = "#FFA500"

img = base64.decode("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")

CACHE_TTL_SECONDS = 3600 * 24  # 1 day in seconds.

# mockData = [
#     {
#         "direction": 0,
#         "stationId": "place-rugg",
#         "route": "Orange"
#         "isNewTrain": "true"
#     },
#     {
#         "direction": 0,
#         "stationId": "place-unsqu",
#         "route": "Green-E"
#         "isNewTrain": "true"
#     },
#     {
#         "direction": 1,
#         "stationId": "place-bbsta",
#         "route": "Orange",
#         "isNewTrain": "true"
#     },
#         {
#         "direction": 1,
#         "stationId": "place-davis",
#         "route": "Red-A",
#         "isNewTrain": "true"
#     },
# ]

def fetchStationNames(useCache):
    cachedStations = cache.get("stations")
    if cachedStations == None or useCache == False:
        res = http.get(STATION_NAMES_URL)
        if res.status_code != 200:
            fail("stations request failed with status %d", res.status_code)
        cachedStations = res.body()
        cache.set("stations", cachedStations, ttl_seconds = CACHE_TTL_SECONDS)

    stations = json.decode(cachedStations)
    map = {}
    for station in stations:
        map[station["id"]] = station["name"]

    return map

def mapStationIdToName(id):
    stations = fetchStationNames(True)
    return stations[id]

def mapRouteToColor(route, config):
    split = route.split("-")
    line = ""
    if len(split) > 1:
        line = split[1]

    if "Red" in route and config.bool("disableRed") != True:
        return (RED, line)
    elif "Green" in route and config.bool("disableGreen") != True:
        return (GREEN, line)
    elif "Orange" in route and config.bool("disableOrange") != True:
        return (ORANGE, line)

    return None

def createTrain(loc, config):
    if loc["isNewTrain"] != True:
        return None

    routeResult = mapRouteToColor(loc["route"], config)
    if routeResult == None:
        return
    (color, line) = routeResult

    stationName = mapStationIdToName(loc["stationId"])

    if line != "":
        stationName += " (" + line + ")"

    isGreenLine = color == "#00FF00"

    if loc["direction"] == 1:
        arrow = ARROW_RIGHT if isGreenLine else ARROW_UP
    else:
        arrow = ARROW_LEFT if isGreenLine else ARROW_DOWN

    return render.Row(
        children = [
            render.Text(
                content = "{} ".format(arrow),
                color = color,
            ),
            render.Marquee(
                child = render.WrappedText(
                    content = stationName,
                    width = 56,
                    color = color,
                ),
                width = 64,
            ),
        ],
    )

def displayIndividualTrains(apiResult, config):
    trains = []
    for loc in apiResult:
        train = createTrain(loc, config)
        if train != None:
            trains.append(train)

    #    for mock in mockData:
    #        trains.append(createTrain(mock))

    if len(trains) == 0:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No New Trains Running!",
                    width = 60,
                ),
            ),
        )

    return render.Root(
        child = render.Marquee(
            child = render.Column(
                children = trains,
            ),
            scroll_direction = "vertical",
            height = 32,
            offset_start = 32,
        ),
    )

def renderDigestRow(color, count, disabled):
    if not disabled:
        return render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Row(
                children = [
                    render.Circle(
                        color = color,
                        diameter = 9,
                        child = render.Text(
                            content = "T",
                            font = "Dina_r400-6",
                        ),
                    ),
                    render.Padding(
                        pad = (4, 1, 0, 0),
                        child = render.Text(
                            content = "{} ".format(count),
                        ),
                    ),
                ],
            ),
        )
    else:
        return

def displayDigest(apiResult, config):
    r = 0
    g = 0
    o = 0
    for loc in apiResult:
        if loc["isNewTrain"] != True:
            continue
        route = loc["route"]
        if "Red" in route:
            r += 1
        elif "Green" in route:
            g += 1
        elif "Orange" in route:
            o += 1

    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        renderDigestRow(RED, r, config.bool("disableRed")),
                        renderDigestRow(GREEN, g, config.bool("disableGreen")),
                        renderDigestRow(ORANGE, o, config.bool("disableOrange")),
                    ],
                ),
                render.Padding(
                    pad = (6, 1, 0, 0),
                    child = render.Image(
                        src = img,
                        width = 36,
                        height = 30,
                    ),
                ),
            ],
        ),
    )

def main(config):
    res = http.get(TRAIN_LOCATION_URL)
    if res.status_code != 200:
        fail("location request failed with status %d", res.status_code)

    apiResult = res.json()

    if config.bool("showLiveLocations"):
        return displayIndividualTrains(apiResult, config)
    else:
        return displayDigest(apiResult, config)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showLiveLocations",
                name = "Show Live Locations",
                desc = "Shows live location of new trains in a scrolling marquee.  If disabled, only the count of new trains running will be displayed.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableRed",
                name = "Hide Red Line Trains",
                desc = "If enabled, new trains on the red line will be hidden.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableGreen",
                name = "Hide Green Line Trains",
                desc = "If enabled, new trains on the green line will be hidden.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableOrange",
                name = "Hide Orange Line Trains",
                desc = "If enabled, new trains on the orange line will be hidden.",
                icon = "gear",
                default = False,
            ),
        ],
    )

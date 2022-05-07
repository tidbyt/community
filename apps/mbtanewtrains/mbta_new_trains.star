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

redImg = base64.decode("")

CACHE_TTL_SECONDS = 3600 * 24  # 1 day in seconds.

# mockData = [
#     {
#         "direction": 0,
#         "stationId": "place-rugg",
#         "route": "Orange"
#     },
#     {
#         "direction": 0,
#         "stationId": "place-unsqu",
#         "route": "Green-E"
#     },
#     {
#         "direction": 1,
#         "stationId": "place-bbsta",
#         "route": "Orange"
#     },
#         {
#         "direction": 1,
#         "stationId": "place-davis",
#         "route": "Red-A"
#     },
# ]

def fetchStationNames(useCache):
    cachedStations = cache.get("stations")
    if cachedStations == None or useCache == False:
        res = http.get(STATION_NAMES_URL)
        if res.status_code != 200:
            fail("stations request failed with status %d", res.status_code)
        cachedStations = res.body()
        cache.set("stations", cachedStations, ttl_seconds=CACHE_TTL_SECONDS)

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

    if "Red" in route and config.bool("showRed"):
        return (RED, line)
    elif "Green" in route and config.bool("showGreen"):
        return (GREEN, line)
    elif "Orange" in route and config.bool("showOrange"):
        return (ORANGE, line)

    return None

def createTrain(loc, config):
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

def renderDigestRow(color, count, enabled):
    if enabled:
        return render.Row(
                    children = [
                        render.Circle(
                            color=color,
                            diameter= 9,
                            child = render.Text("T")
                        ),
                        render.Text(
                            content = "{} ".format(count),
                        ),
                    ],
                    # main_align="space_between",
                    # cross_align="center",
                    # expanded=True
        )
    else:
        return

def displayDigest(apiResult, config):
    r = 0
    g = 0
    o = 0
    for loc in apiResult:
        route = loc["route"]
        if "Red" in route:
            r += 1
        elif "Green" in route:
            g += 1
        elif "Orange" in route:
            o += 1
    
    return render.Root(
        child = render.Column(
            children = [
                renderDigestRow(RED,    r,   config.bool("showRed")),
                renderDigestRow(GREEN,  g,   config.bool("showGreen")),
                renderDigestRow(ORANGE, o,   config.bool("showOrange")),
            ]
        )
)

def main(config):
    res = http.get(TRAIN_LOCATION_URL)
    if res.status_code != 200:
        fail("location request failed with status %d", res.status_code)

    apiResult = res.json()

    if config.bool("showDigestOnly"):
        return displayDigest(apiResult, config)
    else:
        return displayIndividualTrains(apiResult, config)



def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showDigestOnly",
                name = "Show Counts Only",
                desc = "Show just a counter of how many active new trains are currently in service. If disabled, this app shows the the individual trains and their location.",
                icon = "cog",
                default = False
            ),
            schema.Toggle(
                id = "showRed",
                name = "Show Red Line Trains",
                desc = "If disabled, new trains on the red line will be hidden.",
                icon = "cog",
                default = True
            ),
            schema.Toggle(
                id = "showGreen",
                name = "Show Green Line Trains",
                desc = "If disabled, new trains on the green line will be hidden.",
                icon = "cog",
                default = True
            ),
            schema.Toggle(
                id = "showOrange",
                name = "Show Orange Line Trains",
                desc = "If disabled, new trains on the orange line will be hidden.",
                icon = "cog",
                default = True
            ),
        ]
    )
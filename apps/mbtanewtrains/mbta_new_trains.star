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

    if "Red" in route and config.bool("disableRed") != True:
        return (RED, line)
    elif "Green" in route and config.bool("disableGreen") != True:
        return (GREEN, line)
    elif "Orange" in route and config.bool("disableOrange") != True:
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

def renderDigestRow(color, count, disabled):
    if not disabled:
        return render.Padding(
                pad = (1, 1, 0, 0),
                child=render.Row(
                    children = [
                        render.Circle(
                            color=color,
                            diameter= 9,
                            child = render.Text(
                                content="T",
                                font='Dina_r400-6'
                            )
                        ),
                        render.Padding(
                            pad = (4, 1, 0, 0),
                            child = render.Text(
                                content = "{} ".format(count),
                            ),
                        )
                    ],
                )
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
        render.Row(
            children = [
                render.Column(
                    children = [
                        renderDigestRow(RED,    r,   config.bool("disableRed")),
                        renderDigestRow(GREEN,  g,   config.bool("disableGreen")),
                        renderDigestRow(ORANGE, o,   config.bool("disableOrange")),
                    ]
                ),
                render.Padding(
                    pad = (4,1,0,0),
                    child= render.Image(
                        src=img,
                        width=36,
                        height=30,  
                    )
                )
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
                id = "disableRed",
                name = "Hide Red Line Trains",
                desc = "If enabled, new trains on the red line will be hidden.",
                icon = "cog",
                default = False
            ),
            schema.Toggle(
                id = "disableGreen",
                name = "Hide Green Line Trains",
                desc = "If enabled, new trains on the green line will be hidden.",
                icon = "cog",
                default = False
            ),
            schema.Toggle(
                id = "disableOrange",
                name = "Hide Orange Line Trains",
                desc = "If enabled, new trains on the orange line will be hidden.",
                icon = "cog",
                default = False
            ),
        ]
    )
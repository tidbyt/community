"""
Applet: MBTA New Trains
Summary: Track new MBTA subway cars
Description: Displays the real time location of new subway cars in Boston's MBTA rapid transit system.
Author: joshspicer
"""

load("render.star", "render")
load("http.star", "http")

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

def fetchStationNames():
    res = http.get(STATION_NAMES_URL)
    if res.status_code != 200:
        fail("stations request failed with status %d", res.status_code)

    stations = res.json()
    map = {}
    for station in stations:
        map[station["id"]] = station["name"]

    return map

def mapStationIdToName(id):
    stations = fetchStationNames()
    return stations[id]

def mapRouteToColor(route):
    if "Red" in route:
        return "#FF0000"
    elif "Green" in route:
        return "#00FF00"
    elif "Orange" in route:
        return "#FFA500"
    else:
        return "#0ff"

def createTrain(loc):
    if loc["direction"] == 1:
        arrow = ARROW_UP
    else:
        arrow = ARROW_DOWN

    stationName = mapStationIdToName(loc["stationId"])
    color = mapRouteToColor(loc["route"])

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

def main():
    res = http.get(TRAIN_LOCATION_URL)
    if res.status_code != 200:
        fail("location request failed with status %d", res.status_code)

    apiResult = res.json()

    trains = []
    for loc in apiResult:
        trains.append(createTrain(loc))

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
        ),
    )

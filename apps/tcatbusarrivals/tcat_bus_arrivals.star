"""
Applet: TCAT Bus Arrivals
Summary: Show TCAT arrival times
Description: Display Arrival Times for TCAT Ithaca Buses at a Specific Stop.
Author: Harry Samuels
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

ROUTES_DETAILS = "https://transitime-api.goswift.ly/api/v1/key/81YENWXv/agency/tcat/command/routesDetails"

PREDICTION = "https://transitime-api.goswift.ly/api/v1/key/81YENWXv/agency/tcat/command/predictions?rs="

TCAT_AND_CAR = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACsAAAAGCAIAAADVDfB/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAJh2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDIgNzkuMTY0NDYwLCAyMDIwLzA1LzEyLTE2OjA0OjE3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHhtcDpDcmVhdGVEYXRlPSIyMDIyLTA3LTI3VDAwOjA3OjEzLTA0OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDIyLTA3LTI3VDE1OjIyOjA5LTA0OjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wNy0yN1QxNToyMjowOS0wNDowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MzI2MjkwMGEtODNiZi00M2IzLTg5NzItYmZkZmZmN2JjNWNlIiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6ZTY1YzE3YzQtNGYwOC01OTQ3LTg0NTctNjNlYmM4ZGQ3YWQ1IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MzM1MzdlYTQtYzA4YS00YzAwLTgwNjEtYjM4NWM0OTllZDk2IiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiBwaG90b3Nob3A6SUNDUHJvZmlsZT0ic1JHQiBJRUM2MTk2Ni0yLjEiPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjMzNTM3ZWE0LWMwOGEtNGMwMC04MDYxLWIzODVjNDk5ZWQ5NiIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yN1QwMDowNzoxMy0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjA4ZWZjZTdkLWUxZjEtNDFkNi04NDRjLTFjMDUyNDk0NzMwMCIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yN1QxNTowODoxNy0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjcyZjU0Yjg5LTZiNmItNGY5Yi05ZmQyLWU0NjIxMDIxMjA2ZCIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yN1QxNToyMjowOS0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249ImNvbnZlcnRlZCIgc3RFdnQ6cGFyYW1ldGVycz0iZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iZGVyaXZlZCIgc3RFdnQ6cGFyYW1ldGVycz0iY29udmVydGVkIGZyb20gYXBwbGljYXRpb24vdm5kLmFkb2JlLnBob3Rvc2hvcCB0byBpbWFnZS9wbmciLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjMyNjI5MDBhLTgzYmYtNDNiMy04OTcyLWJmZGZmZjdiYzVjZSIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yN1QxNToyMjowOS0wNDowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKE1hY2ludG9zaCkiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjcyZjU0Yjg5LTZiNmItNGY5Yi05ZmQyLWU0NjIxMDIxMjA2ZCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDozMzUzN2VhNC1jMDhhLTRjMDAtODA2MS1iMzg1YzQ5OWVkOTYiIHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDozMzUzN2VhNC1jMDhhLTRjMDAtODA2MS1iMzg1YzQ5OWVkOTYiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz66yudYAAAAo0lEQVQokWOcd+olAwPD8hdiDHjBbj9G/ArIBixQCy49JFXnnj17GBgYXFxcqOMC2tn9zN4ezpY6eBDTHEaGlgdwof/V8rgMYmRkhGsjxu7/JwKfl7/DKgVxB9wcpv/V8pP4Nk3i24Rp/eTJkydPngxhT5o0CcIg0uvPy9+tCQ5eExwMF4FzIUbBzWGCe44RAyCL5+XlEWMxmkchDAiCc9GMAgD0r0JMRErxqwAAAABJRU5ErkJggg==")

NO_BUSES = [
    render.Circle(
        diameter = 12,
        color = "#20B7BC",
        child = render.Text("N"),
    ),
    render.Circle(
        diameter = 12,
        color = "#2722B3",
        child = render.Text("O"),
    ),
    render.Box(
        height = 12,
        width = 6,
    ),
    render.Circle(
        diameter = 12,
        color = "#7C26A6",
        child = render.Text("B"),
    ),
    render.Circle(
        diameter = 12,
        color = "#E22DD0",
        child = render.Text("U"),
    ),
    render.Circle(
        diameter = 12,
        color = "#EE1C1C",
        child = render.Text("S"),
    ),
    render.Circle(
        diameter = 12,
        color = "#F0A524",
        child = render.Text("E"),
    ),
    render.Circle(
        diameter = 12,
        color = "#DCDC37",
        child = render.Text("S"),
    ),
]

def main(config):
    stopCode = config.get("stopCode", "1524")
    kid_list = []
    time_list = []
    cached_info = cache.get(stopCode)
    if cached_info != None:
        stopName = cached_info[0:cached_info.index("&")]
        cached_info = cached_info[(cached_info.index("&") + 1):]
        dataSets = cached_info.count("&")
        for _ in range(0, dataSets):
            cached_info = cached_info[(cached_info.find("$COLOR") + 6):]
            cacheColor = cached_info[:cached_info.find("$ROUTE")]
            cached_info = cached_info[(cached_info.find("$ROUTE") + 6):]
            cacheRoute = cached_info[:cached_info.find("$MINUTES")]
            cached_info = cached_info[(cached_info.find("$MINUTES") + 8):]
            cacheMinutes = cached_info[:cached_info.find("&")]
            kid_list.append(
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Circle(
                            diameter = 12,
                            color = cacheColor,
                            child =
                                render.Text(content = cacheRoute),
                        ),
                        render.Text(
                            color = "#25FF51",
                            content = (" in " + cacheMinutes + " min  "),
                        ),
                    ],
                ),
            )
            time_list.append(cacheMinutes)

    else:
        routesList = http.get(ROUTES_DETAILS)
        if routesList.status_code != 200:
            return render.Root(child = render.WrappedText(color = "#FF0000", content = ("TCAT request failed w/ %d. Bus Data Not Found" % routesList.status_code)))
        servicingRoutes = []
        stopName = "blank"
        for line in routesList.json()["routes"]:
            foundStopInLine = False
            for direction in line["directions"]:
                if foundStopInLine:
                    break
                for stop in direction["stops"]:
                    if stop["code"] == int(stopCode) and (not (line["id"] in servicingRoutes)):
                        servicingRoutes.append(line["id"])
                        stopName = stop["name"]
                        foundStopInLine = True
                        break

        cache_string = stopName + "&"
        for route in servicingRoutes:
            routeColor = "#000000"
            for line in routesList.json()["routes"]:
                if line["id"] == route:
                    routeColor = ("#" + line["color"])
                    break
            current_predictions = http.get(PREDICTION + route + "," + stopCode)
            if current_predictions.status_code != 200:
                return render.Root(child = render.WrappedText(color = "#FF0000", content = ("TCAT request failed w/ %d. Bus Data Not Found" % current_predictions.status_code)))
            if current_predictions.json()["predictions"] == []:
                break
            if current_predictions.json()["predictions"][0]["destinations"] == []:
                break
            num_active_buses = len(current_predictions.json()["predictions"][0]["destinations"][0]["predictions"])
            active_buses = []
            if num_active_buses != 0:
                x = 0
                for x in range(0, num_active_buses):
                    if current_predictions.json()["predictions"][0]["destinations"][0]["predictions"][x] != []:
                        arrival_mins = str(current_predictions.json()["predictions"][0]["destinations"][0]["predictions"][x]["min"])
                        headsign = current_predictions.json()["predictions"][0]["destinations"][0]["headsign"]
                        stopName = current_predictions.json()["predictions"][0]["stopName"]
                        active_buses.append([route, stopName, headsign, arrival_mins[0:arrival_mins.index(".")]])
                        kid_list.append(
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Circle(
                                        diameter = 12,
                                        color = routeColor,
                                        child =
                                            render.Text(content = active_buses[x][0]),
                                    ),
                                    render.Text(
                                        color = "#25FF51",
                                        content = (" in " + active_buses[x][3] + " min  "),
                                    ),
                                ],
                            ),
                        )
                        time_list.append(active_buses[x][3])
                        cache_string = (cache_string + "$COLOR" + routeColor + "$ROUTE" + active_buses[x][0] + "$MINUTES" + active_buses[x][3] + "&")
        cache.set(stopCode, cache_string, ttl_seconds = 60)

    return render.Root(
        child = render.Column(
            main_align = "start",
            children = [
                render.WrappedText(
                    height = 12,
                    color = "#FFD546",
                    font = "CG-pixel-4x5-mono",
                    linespacing = 1,
                    content = stopName,
                ),
                render.Box(
                    height = 1,
                    color = "#FF0000",
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 32,
                    offset_end = 32,
                    child = render.Row(
                        children = timeSort(kid_list, time_list),
                    ),
                ),
                render.Box(
                    height = 1,
                    color = "#FF0000",
                ),
                #render.Box(
                #    height= 1,
                #),
                render.Marquee(
                    scroll_direction = "horizontal",
                    width = 64,
                    offset_start = 64,
                    offset_end = 64,
                    child = render.Row(
                        children = [
                            render.Image(
                                src = TCAT_AND_CAR,
                            ),
                            render.Box(
                                width = 22,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def timeSort(kid_list, time_list):
    sorted_list = []
    sorted_times = []

    if kid_list != []:
        sorted_list.append(kid_list[0])
        sorted_times.append(time_list[0])
        iterations = len(kid_list)
        for x in range(1, iterations):
            y = 0
            eta = int(time_list[x])
            for _ in range(0, iterations):
                if y < len(sorted_list) and eta >= int(sorted_times[y]):
                    y = y + 1
            if y < len(sorted_list):
                sorted_list.insert(y, kid_list[x])
                sorted_times.insert(y, time_list[x])
            else:
                sorted_list.append(kid_list[x])
                sorted_times.append(time_list[x])
    else:
        sorted_list = NO_BUSES
    return sorted_list

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stopCode",
                name = "Bus Stop Number",
                desc = "The number of the bus stop. (Located on the sign at each bus stop)",
                icon = "locationDot",
                default = "1524",
            ),
        ],
    )

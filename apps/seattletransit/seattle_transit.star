"""
Applet: Seattle Transit
Summary: Seattle transit arrivals
Description: Displays transit arrivals in the Seattle area for a user selected stop.
Author: maxa010
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

ENCRYPTED_API_KEY = "AV6+xWcEhALFeAkaO4q1aYXDTm4yFiCx1H6qhmrLmXDZaapsABtJzAyD0TelD6CkpX8nNlxDU2deCXMUiVPNMAbovbSfCC0wUq8qsPF/A6PSdKXR4A9SVX5t9VA/gHsp4f1YGCVL40/E8edn61MMtb/4FYvp5derIaU4Gc5wmyUx9vPOeH5uyZdb"

def main(config):
    api_key = secret.decrypt(ENCRYPTED_API_KEY)

    stopid = config.get("stop")
    if stopid == None:
        stopid = "29_2229"
    else:
        stopid = json.decode(stopid)["value"]

    default_color = config.get("color", "#FFBF00")

    if stopid == "1_SS01" or stopid == "40_SS01":
        stopid = "40_S_KS"

    if api_key != None:
        stop_url = "https://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/" + stopid + ".json?key=" + api_key
    else:
        stop_url = "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/1_75403.json?key=TEST"

    font = "CG-pixel-3x5-mono"

    print(str(default_color))

    routes_cached = cache.get("routes" + stopid)
    headsigns_cached = cache.get("headsigns" + stopid)
    arrivals_cached = cache.get("arrivals" + stopid)
    sched_Dev_cached = cache.get("sched_Dev" + stopid)
    route_color_cached = cache.get("route_color" + stopid)
    route_background_cached = cache.get("route_background" + stopid)
    stop_name_cached = cache.get("stop_name" + stopid)

    if routes_cached != None:
        print("Hit! Displaying cached data.")
        routes = routes_cached.split('", "')
        headsigns = headsigns_cached.split('", "')
        arrivals = arrivals_cached.split('", "')
        sched_Dev = sched_Dev_cached.split('", "')
        route_color = route_color_cached.split('", "')
        route_background = route_background_cached.split('", "')
        stop_name = stop_name_cached

        routes[0] = routes[0][2:]
        headsigns[0] = headsigns[0][2:]
        arrivals[0] = arrivals[0][2:]
        sched_Dev[0] = sched_Dev[0][2:]
        route_color[0] = route_color[0][2:]
        route_background[0] = route_background[0][2:]

        routes[-1] = routes[-1][:-2]
        headsigns[-1] = headsigns[-1][:-2]
        arrivals[-1] = arrivals[-1][:-2]
        sched_Dev[-1] = sched_Dev[-1][:-2]
        route_color[-1] = route_color[-1][:-2]
        route_background[-1] = route_background[-1][:-2]

    else:
        print("Miss! Calling OBA API.")
        rep = http.get(stop_url)
        if rep.status_code != 200:
            fail("OBA request failed with status %d", rep.status_code)

        trip_count = len(rep.json()["data"]["entry"]["arrivalsAndDepartures"])
        print(trip_count)
        stop_name = str(rep.json()["data"]["references"]["stops"][0]["name"])

        routes = []
        headsigns = []
        arrivals = []
        delay = 0
        sched_Dev = []
        route_color = []
        route_background = []
        route_id = ""
        removed_trips = 0

        for i in range(trip_count):
            if i > 0:
                if rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["scheduledArrivalTime"] == rep.json()["data"]["entry"]["arrivalsAndDepartures"][i - 1]["scheduledArrivalTime"] and rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["routeId"] == rep.json()["data"]["entry"]["arrivalsAndDepartures"][i - 1]["routeId"] and rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["tripHeadsign"] == rep.json()["data"]["entry"]["arrivalsAndDepartures"][i - 1]["tripHeadsign"]:
                    removed_trips += 1
                    continue

            routes.append(rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["routeShortName"])
            headsigns.append(rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["tripHeadsign"])
            arrivals.append(int(rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["predictedArrivalTime"]))
            route_id = rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["routeId"]

            for j in rep.json()["data"]["references"]["routes"]:
                if j["id"] == route_id:
                    if j["textColor"] == "000000":
                        route_background.append("#000000")
                        route_color.append("#" + j["color"])
                    elif j["color"] == "":
                        route_color.append("0")
                        route_background.append("#000000")
                    else:
                        route_color.append("#" + j["textColor"])
                        route_background.append("#" + j["color"])
                        break
            delay = rep.json()["data"]["entry"]["arrivalsAndDepartures"][i].get("tripStatus", 0)
            if delay == 0:
                arrivals[-1] = 0
            else:
                delay = int(rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["tripStatus"]["scheduleDeviation"])

            if (delay // 60) == 0:
                sched_Dev.append("#00FF00")
            elif (delay // 60) > 0:
                sched_Dev.append("#0080FF")
            elif (delay // 60) < 0:
                sched_Dev.append("#FF0000")
            else:
                sched_Dev.append("0")
            if arrivals[-1] == 0:
                arrivals[-1] = int(rep.json()["data"]["entry"]["arrivalsAndDepartures"][i]["scheduledArrivalTime"])
                sched_Dev[-1] = "0"

        for i in range(len(routes)):
            if int(arrivals[i] - rep.json()["currentTime"]) // 60000 < -9:
                routes.pop(0)
                headsigns.pop(0)
                arrivals.pop(0)
                sched_Dev.pop(0)
                route_color.pop(0)
                route_background.pop(0)
            else:
                break

        trip_count = len(routes)

        if trip_count > 4:
            for i in range(trip_count - 4):
                if int(arrivals[0] - rep.json()["currentTime"]) // 60000 < 0:
                    routes.pop(0)
                    headsigns.pop(0)
                    arrivals.pop(0)
                    sched_Dev.pop(0)
                    route_color.pop(0)
                    route_background.pop(0)
                    removed_trips += 1

            routes = routes[0:4]
            headsigns = headsigns[0:4]
            arrivals = arrivals[0:4]
            sched_Dev = sched_Dev[0:4]
            route_color = route_color[0:4]
            route_background = route_background[0:4]

        for i in range(len(routes)):
            if routes[i][-4:] == "Line":
                if routes[i][0] == "A":
                    routes[i] = " A"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "B":
                    routes[i] = " B"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "C":
                    routes[i] = " C"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "D":
                    routes[i] = " D"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "E":
                    routes[i] = " E"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "F":
                    routes[i] = " F"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "H":
                    routes[i] = " H"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "G":
                    routes[i] = " G"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "I":
                    routes[i] = " I"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "J":
                    routes[i] = " J"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "K":
                    routes[i] = " K"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "R":
                    routes[i] = " R"
                    route_background[i] = "#A00000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "1":
                    routes[i] = " 1"
                    #    route_background[i] = "#3DAE2B"
                    #    route_color[i] = "#FFFFFF"

                elif routes[i][0] == "2":
                    routes[i] = " 2"
                    route_background[i] = "#00A0DF"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "3":
                    routes[i] = " 3"
                    route_background[i] = "#ED40A9"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "4":
                    routes[i] = " 4"
                    route_background[i] = "#B14FC5"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "T":
                    routes[i] = " T"
                    route_background[i] = "#000000"
                    route_color[i] = "#FFBF00"
                elif routes[i][0] == "N":
                    routes[i] = " N"
                    route_background[i] = "#63768A"
                    route_color[i] = "#FFFFFF"
                elif routes[i][0] == "S":
                    routes[i] = " S"
                    route_background[i] = "#63768A"
                    route_color[i] = "#FFFFFF"
                else:
                    pass
            if routes[i][0:5] == "Swift":
                if routes[i][6] == "G":
                    routes[i] = "SFT"
                    route_background[i] = "#008000"
                    route_color[i] = "#FFFFFF"
                elif routes[i][6] == "B":
                    routes[i] = "SFT"
                    route_background[i] = "#0080FF"
                    route_color[i] = "#FFFFFF"
                else:
                    routes[i] = "SFT"
            if routes[i][-9:] == "Streetcar":
                if routes[i][0:5] == "First":
                    routes[i] = "FH"
                elif routes[i][0:5] == "South":
                    routes[i] = "SLU"
                else:
                    routes[i] = "SC"

            if int(arrivals[i] - rep.json()["currentTime"]) // 60000 == 0:
                arrivals[i] = "due"
            else:
                arrivals[i] = str(int(arrivals[i] - rep.json()["currentTime"]) // 60000) + "m"
            routes[i] = routes[i][:3]

        if len(routes) < 4:
            for i in range(4 - len(routes)):
                routes.append("")
                headsigns.append("")
                arrivals.append("")
                sched_Dev.append("#000000")
                route_background.append("#000000")
                route_color.append("#000000")

        cache.set("routes" + stopid, str(routes), ttl_seconds = 30)
        cache.set("headsigns" + stopid, str(headsigns), ttl_seconds = 30)
        cache.set("arrivals" + stopid, str(arrivals), ttl_seconds = 30)
        cache.set("sched_Dev" + stopid, str(sched_Dev), ttl_seconds = 30)
        cache.set("route_color" + stopid, str(route_color), ttl_seconds = 30)
        cache.set("route_background" + stopid, str(route_background), ttl_seconds = 30)
        cache.set("stop_name" + stopid, str(stop_name), ttl_seconds = 30)

        print(routes)

        #print(headsigns)
        print(arrivals)
        print(sched_Dev)
        print(route_color)

        #print(route_background)
        print(removed_trips)

    for i in range(len(routes)):
        if config.bool("single_color", False):
            sched_Dev[i] = default_color
            route_color[i] = default_color
            route_background[i] = "#000000"
        if route_color[i] == "0":
            route_color[i] = default_color
            route_background[i] = "#000000"
        if sched_Dev[i] == "0":
            sched_Dev[i] = default_color

    return render.Root(
        max_age = 60,
        child = render.Column(
            children = [
                render.Box(height = 1),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [render.Marquee(width = 64, align = "center", child = render.Text(content = stop_name, color = default_color, font = font))],
                ),
                render.Box(height = 1),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 12, height = 5, color = route_background[0], child =
                                                                                            render.Marquee(width = 12, child = render.Text(content = routes[0], color = route_color[0], font = font))),
                        render.Marquee(width = 40, align = "center", child = render.Text(content = headsigns[0], color = default_color, font = font)),
                        render.Marquee(width = 12, align = "end", child = render.Text(content = arrivals[0], color = sched_Dev[0], font = font)),
                    ],
                ),
                render.Box(height = 1),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 12, height = 5, color = route_background[1], child =
                                                                                            render.Marquee(width = 12, child = render.Text(content = routes[1], color = route_color[1], font = font))),
                        render.Marquee(width = 40, align = "center", child = render.Text(content = headsigns[1], color = default_color, font = font)),
                        render.Marquee(width = 12, align = "end", child = render.Text(content = arrivals[1], color = sched_Dev[1], font = font)),
                    ],
                ),
                render.Box(height = 1),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 12, height = 5, color = route_background[2], child =
                                                                                            render.Marquee(width = 12, child = render.Text(content = routes[2], color = route_color[2], font = font))),
                        render.Marquee(width = 40, align = "center", child = render.Text(content = headsigns[2], color = default_color, font = font)),
                        render.Marquee(width = 12, align = "end", child = render.Text(content = arrivals[2], color = sched_Dev[2], font = font)),
                    ],
                ),
                render.Box(height = 1),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Box(width = 12, height = 5, color = route_background[3], child =
                                                                                            render.Marquee(width = 12, child = render.Text(content = routes[3], color = route_color[3], font = font))),
                        render.Marquee(width = 40, align = "center", child = render.Text(content = headsigns[3], color = default_color, font = font)),
                        render.Marquee(width = 12, align = "end", child = render.Text(content = arrivals[3], color = sched_Dev[3], font = font)),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    colors = [
        schema.Option(
            display = "Amber",
            value = "#FFBF00",
        ),
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop",
                name = "Stop",
                desc = "A list of stops based on a location.",
                icon = "bus",
                handler = get_stops,
            ),
            schema.Dropdown(
                id = "color",
                name = "Default Text Color",
                desc = "The default color of text to be displayed.",
                icon = "brush",
                default = colors[0].value,
                options = colors,
            ),
            schema.Toggle(
                id = "single_color",
                name = "Single Color Mode",
                desc = "Makes all text the default text color (removes special route and trip status colors).",
                icon = "palette",
                default = False,
            ),
        ],
    )

def get_stops(location):
    loc = json.decode(location)
    api_key = secret.decrypt(ENCRYPTED_API_KEY)

    stop_search = "http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=" + api_key + "&lat=" + str(loc["lat"]) + "&lon=" + str(loc["lng"])
    res = http.get(stop_search)
    if res.status_code != 200:
        fail("OBA request failed with status %d", res.status_code)
    data = res.json()["data"]["list"]

    stops = [
        schema.Option(display = "%s - %s" % (stop["name"], stop["direction"]), value = stop["id"])
        for stop in data
    ]

    return stops

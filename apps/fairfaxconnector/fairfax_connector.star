"""
Applet: Fairfax Connector
Summary: Connector bus stop info
Description: Shows when your next bus is arriving. Visit fairfaxconnector.com for more information.
Author: Austin Pearce
"""

load("render.star", "render")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("schema.star", "schema")
load("secret.star", "secret")

apiKey = secret.decrypt("AV6+xWcEHWq0zUeozY3oe2t6xhMzEHRhb/Tn+2RBF5rGUi5jc8XcDKxG2RC7lqqhGYS8z0+glkxCg1ZsTf6sCsNAMB7RD+HQpPyyhmB8cek35AnYxHQQsy2A7o9uLswG3g3k3edobR3Qy4KHckKqGdtkVYxXNG3HK0yEqCG4hQ==")
ONE_MINUTE = 60
ONE_DAY = ONE_MINUTE * 60 * 24
ONE_WEEK = ONE_DAY * 7
BASE_URL = "https://www.fairfaxcounty.gov/bustime/api/v3"
DEFAULT_STOP = "6484"

def getAllRoutes():
    routes = cache.get("ROUTES")
    if routes == None:
        routesUrl = BASE_URL + "/getroutes?key=" + apiKey + "&format=json"
        routes = http.get(routesUrl).body()
        cache.set("ROUTES", routes, ONE_DAY)

    routes = json.decode(routes).get("bustime-response").get("routes")
    return routes

def getRouteDirections(route):
    cacheKey = "DIRECTIONS-" + route.get("rt")
    directions = cache.get(cacheKey)
    if directions == None:
        dirUrl = BASE_URL + "/getdirections?key=" + apiKey + "&rt=" + route.get("rt") + "&format=json"
        directions = http.get(dirUrl).body()
        cache.set(cacheKey, directions, ONE_DAY)

    directions = json.decode(directions).get("bustime-response").get("directions")
    return directions

def getStops(route, direction):
    cacheKey = "STOPS-" + route.get("rt") + "-" + direction.get("id")
    stops = cache.get(cacheKey)
    if stops == None:
        stopsUrl = BASE_URL + "/getstops?key=" + apiKey + "&rt=" + route.get("rt") + "&dir=" + direction.get("id") + "&format=json"

        # Some of the directions have spaces in their IDs. Why this is allowed, I have no clue. I can't seem to find a starlark lib
        # for URL encoding, so I'm doing this one-off here where it's needed.
        stopsUrl = stopsUrl.replace(" ", "%20")
        stops = http.get(stopsUrl).body()
        cache.set(cacheKey, stops, ONE_DAY)

    stops = json.decode(stops).get("bustime-response").get("stops")
    return stops

# Warning: Expensive operation! Sends a lot of network requests the first time it's called
# before the cache is filled up (and again every 24h when the cache expires).
def getAllStops():
    allStops = []
    routes = getAllRoutes()
    for route in routes:
        directions = getRouteDirections(route)
        for direction in directions:
            stops = getStops(route, direction)
            if stops == None:
                continue
            for stop in stops:
                allStops.append([route, stop])

    return allStops

def getRouteColor(routeId):
    routeColor = cache.get("COLOR-" + routeId)
    if routeColor == None:
        routes = getAllRoutes()

        # Find the matching route and extract its color
        for route in routes:
            if route["rt"] == routeId:
                routeColor = route["rtclr"]
                cache.set("COLOR-" + routeId, routeColor, ONE_WEEK)
                break
    return routeColor or "#ffffff"

# Gets the list of predicted bus times for an individual bus stop
def getPredictions(stopId):
    stopPredictions = cache.get(stopId)
    if stopPredictions == None:
        predictionUrl = BASE_URL + "/getpredictions?key=" + apiKey + "&stpid=" + stopId + "&format=json"
        stopPredictions = http.get(predictionUrl).body()
        cache.set(stopId, stopPredictions, ONE_MINUTE)

    stopPredictions = json.decode(stopPredictions).get("bustime-response").get("prd")
    return stopPredictions

def renderBusRow(prediction):
    routeColor = getRouteColor(prediction.get("rt"))
    if prediction == None:
        return render.Text("")
    minutesRemaining = prediction.get("prdctdn")
    if minutesRemaining != "DUE":
        minutesRemaining = minutesRemaining + " min"
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(
                content = prediction.get("rt"),
                color = routeColor,
            ),
            render.Text(
                content = minutesRemaining,
            ),
        ],
    )

def main(config):
    stop = config.get("stop") or DEFAULT_STOP
    banner = render.Row(
        children = [
            render.Text(
                content = "FFX",
                color = "#f00",
            ),
            render.Text(
                content = " Connector",
                color = "#ff0",
            ),
        ],
    )
    predictions = getPredictions(stop)
    if predictions == None:
        return render.Root(
            child = render.Column(
                children = [
                    banner,
                    render.Text(
                        content = "API Error",
                    ),
                ],
            ),
        )

    rows = [
        banner,
        render.Marquee(
            width = 64,
            child = render.Text(
                content = predictions[0].get("stpnm"),
                color = "#bbb",
            ),
        ),
    ]
    for prediction in predictions:
        rows.append(renderBusRow(prediction))
    return render.Root(
        child = render.Column(
            children = rows,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "The ID of the stop, found on the bus stop sign or online at https://www.fairfaxcounty.gov/bustime/map/displaymap.jsp",
                icon = "busSimple",
            ),
        ],
    )

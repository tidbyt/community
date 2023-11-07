"""
Applet: Chi L Track
Summary: Track arrivals for CTA L
Description: Track arrivals at Chicago CTA L (rapid transit) stations. App allows two different stops - usually 2 directions for a single station. The app can differentiate between scheduled and live tracked trains as well.
Author: FabioCZ
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

CTA_ARRIVAL_URL = "http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx"
CTA_API_KEY_ENCRYPTED = "AV6+xWcExXu2MptD37JLjkz3aZBkAO7HBcLRIkN9+Z49P0+NOzgvskzwV7E/gWfN3vjUyQxvdXMeKkhuYlHA414OtiD/dHB7wjMBAQ7omAa7I4Ngo/RTAg7fGn+Y1Tkwa/TWMkbpDGWNON0b3iTB9tGm9k4DKIm3Gxgi3oRQnHeU01lFZVc="

CTA_L_STATON_LIST_URL = "https://data.cityofchicago.org/resource/8pix-ypme.json"

def getApiUrl(predConfig, key):
    return CTA_ARRIVAL_URL + "?stpid=" + predConfig.stopId + "&rt=" + predConfig.route + "&key=" + key + "&outputType=JSON"

def getPredictionTime(arrivalTimeStr):
    now = time.now()
    arrivalTime = time.parse_time(arrivalTimeStr, format = "2006-01-02T15:04:05", location = "America/Chicago")
    arrivalDuration = arrivalTime - now
    return str(int(arrivalDuration.minutes))

def getPredictionSuffix(route, destinationName, destinationId, isScheduled):
    if isScheduled:
        return ""
    elif route == "Blue":
        if destinationId == "30171" or destinationId == "30077":
            return ""
        elif destinationId == "30069":
            return "U"
        elif destinationId == "Rosemont":
            return "R"
        elif destinationId == "30247":
            return "J"
        else:
            return "!"
    elif route == "Brn":
        if destinationId == "30249":
            return ""
        else:
            return "!"
    elif route == "G":
        if destinationId == "30057" or destinationId == "30004":
            return ""
        elif destinationId == "30139":
            return "C"
        else:
            return "!"
    elif route == "Org":
        if destinationId == "30182":
            return ""
        else:
            return "!"
    elif route == "P":
        if destinationId == "30203" and destinationName == "Linden":
            return ""
        elif destinationId == "30203" and destinationName == "Loop":
            return "L"
        elif destinationId == "30176":
            return ""
        else:
            return "!"
    elif route == "Pink":
        if destinationId == "30114":
            return ""
        else:
            return "!"
    elif route == "Red":
        if destinationId == "30173" or destinationId == "30089":
            return ""
        else:
            return "!"
    elif route == "Y":
        if destinationId == "30297" or destinationId == "30174" or destinationId == "30176":
            return ""
        else:
            return "!"
    else:
        return ""

def getPredictions(predConfig, devApiKey):
    preds = []
    respJson = {}
    apiKey = secret.decrypt(CTA_API_KEY_ENCRYPTED) or devApiKey
    resp = http.get(getApiUrl(predConfig, apiKey), ttl_seconds = 45)

    if resp.status_code != 200:
        fail("CTA request failed with: %d, %s", resp.status_code, resp.body())
    if resp.body()[0] == "<":
        fail("CTA request failed - we got a bad xml response")

    respJson = resp.json()
    if "eta" not in respJson["ctatt"]:
        return preds

    for pred in respJson["ctatt"]["eta"]:
        if pred["rt"] == predConfig.route:
            time = getPredictionTime(pred["arrT"])
            isDelayed = pred["isDly"] == "1"
            isScheduled = pred["isSch"] == "1"
            suffix = getPredictionSuffix(pred["rt"], pred["destNm"], pred["destSt"], isScheduled)
            if not isScheduled or predConfig.showSched:
                preds.append(struct(time = time, isDelayed = isDelayed, isScheduled = isScheduled, suffix = suffix, direction = pred["trDr"]))

    return preds

def renderLine(r, dest, arrivals):
    r.Row(
        children = [
            render.Box(width = 1, height = 1),
            render.Box(
                width = 20,
                height = 15,
                color = "#0af",
                child = render.Text(content = dest, font = "6x13", height = 13, color = "#fff"),
            ),
            render.Marquee(
                width = 43,
                child = render.Text(content = arrivals, font = "6x13", height = 15),
            ),
        ],
    )

def predColor(isFirst, isDelayed, isSched):
    if isDelayed:
        return "#f00"
    elif isSched:
        return "#888"
    elif isFirst:
        return "#fb0"
    else:
        return "#fff"

def renderFirstPred(r, preds):
    if len(preds) > 0:
        pred = preds[0]
        return r.Text(content = pred.time + pred.suffix, height = 13, font = "6x13", color = predColor(True, pred.isDelayed, pred.isScheduled))
    else:
        return r.Text(content = "nothin'", height = 13, font = "6x13", color = "#fb0")

def renderOtherPreds(r, preds):
    if (len(preds) < 2):
        return [r.Text(content = "")]
    else:
        predsCopy = list(preds)
        predsCopy.pop(0)
        predsTexts = []
        for i in range(len(predsCopy)):
            pred = predsCopy[i]
            predsTexts.append(r.Text(content = pred.time + pred.suffix, height = 12, color = predColor(False, pred.isDelayed, pred.isScheduled)))
            if i < (len(predsCopy)) - 1:
                predsTexts.append(r.Text(content = ",", height = 12, color = predColor(False, pred.isDelayed, pred.isScheduled)))
        return predsTexts

def getRouteColor(route):
    if route == "Blue":
        return struct(fg = "#fff", bg = "#0af")
    elif route == "Brn":
        return struct(fg = "#fff", bg = "#632")
    elif route == "G":
        return struct(fg = "#fff", bg = "#0a4")
    elif route == "Org":
        return struct(fg = "#fff", bg = "#f42")
    elif route == "P":
        return struct(fg = "#fff", bg = "#52a")
    elif route == "Pink":
        return struct(fg = "#fff", bg = "#e8a")
    elif route == "Red":
        return struct(fg = "#fff", bg = "#c13")
    elif route == "Y":
        return struct(fg = "#000", bg = "#fe0")
    else:
        return struct(fg = "#fff", bg = "#000")

def getDestName(predConfig, preds):
    route = predConfig.route
    cacheKey = predConfig.route + predConfig.stopId
    destName = cache.get(cacheKey)
    if destName != None:
        return destName

    if len(preds) == 0:
        destName = "??"
    elif route == "Blue":
        if preds[0].direction == "1":
            destName = "ORD"
        else:
            destName = "FP"
    elif route == "Brn":
        if preds[0].direction == "1":
            destName = "KB"
        else:
            destName = "LP"
    elif route == "G":
        if preds[0].direction == "1":
            destName = "HAR"
        else:
            destName = "A63"
    elif route == "Org":
        if preds[0].direction == "1":
            destName = "LP"
        else:
            destName = "MDW"
    elif route == "P":
        if preds[0].direction == "1":
            destName = "LDN"
        else:
            destName = "H/L"
    elif route == "Pink":
        if preds[0].direction == "1":
            destName = "LP"
        else:
            destName = "54C"
    elif route == "Red":
        if preds[0].direction == "1":
            destName = "HOW"
        else:
            destName = "95"
    elif route == "Y":
        if preds[0].direction == "1":
            destName = "SKO"
        else:
            destName = "HOW"
    else:
        destName = "??"

    if destName != "??":
        cache.set(cacheKey, destName, ttl_seconds = 315569520)  #ttl 10 years, whatevs
    return destName

def renderPredictions(r, predConfig, devApiKey):
    if predConfig.stopId == None or predConfig.route == None:
        return r.Box(
            width = 64,
            height = 14,
            color = "#f00",
        )
    preds = getPredictions(predConfig, devApiKey)
    routeColor = getRouteColor(predConfig.route)
    destName = getDestName(predConfig, preds)
    return r.Row(
        children = [
            r.Box(width = 1, height = 1, color = "#000"),
            r.Box(
                width = 19,
                height = 13,
                color = routeColor.bg,
                child = r.Row(
                    children = [
                        r.Box(width = 1, height = 1, color = routeColor.bg),
                        r.Text(content = destName, font = "6x13", color = routeColor.fg),
                    ],
                ),
            ),
            r.Box(width = 2, height = 1, color = "#000"),
            renderFirstPred(r, preds),
            r.Box(width = 1, height = 1, color = "#000"),
            r.Marquee(
                width = 40,
                child = r.Row(children = renderOtherPreds(r, preds)),
            ),
        ],
    )

def renderAnimatedTrain(r, showAnimatedTrain):
    if showAnimatedTrain:
        return r.Column(
            children = [
                r.Marquee(
                    width = 64,
                    child = r.Row(
                        children = [
                            r.Box(width = 64, height = 1),
                            r.Column(
                                children = [
                                    r.Box(width = 6, height = 2, color = "#888"),
                                    r.Row(
                                        children = [
                                            r.Box(width = 1, height = 1, color = "#000"),
                                            r.Box(width = 1, height = 1, color = "#888"),
                                            r.Box(width = 2, height = 1, color = "#000"),
                                            r.Box(width = 1, height = 1, color = "#888"),
                                        ],
                                    ),
                                ],
                            ),
                            r.Column(
                                children = [
                                    r.Box(width = 1, height = 1, color = "#000"),
                                    r.Box(width = 1, height = 1, color = "#888"),
                                ],
                            ),
                            r.Column(
                                children = [
                                    r.Box(width = 6, height = 2, color = "#888"),
                                    r.Row(
                                        children = [
                                            r.Box(width = 1, height = 1, color = "#000"),
                                            r.Box(width = 1, height = 1, color = "#888"),
                                            r.Box(width = 2, height = 1, color = "#000"),
                                            r.Box(width = 1, height = 1, color = "#888"),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
                r.Box(width = 64, height = 1, color = "#888"),
            ],
        )
    else:
        return r.Box(
            width = 64,
            height = 4,
            color = "#000",
        )

def main(config):
    firstLineConfig = struct(stopId = config.str("firstStop", "30111"), route = config.str("firstRoute", "Blue"), showSched = config.bool("firstShowSched", False))
    showAnimatedTrain = config.bool("showAnimatedTrain", True)
    secondLineConfig = struct(stopId = config.str("secondStop", "30112"), route = config.str("secondRoute", "Blue"), showSched = config.bool("secondShowSched", False))
    devApiKey = config.str("devApiKey", "dev_key_here")

    return render.Root(
        render.Column(
            children = [
                render.Box(width = 1, height = 1),
                renderPredictions(render, firstLineConfig, devApiKey),
                renderAnimatedTrain(render, showAnimatedTrain),
                renderPredictions(render, secondLineConfig, devApiKey),
            ],
        ),
    )

def directionName(dirId):
    if dirId == "W":
        return "West"
    if dirId == "E":
        return "East"
    if dirId == "S":
        return "South"
    if dirId == "N":
        return "North"
    else:
        return "??"

def getStationOptions():
    resp = http.get(CTA_L_STATON_LIST_URL, ttl_seconds = 86400)  # 1 day
    if resp.status_code != 200:
        fail("Failed to get L station list %d %s", resp.status_code, resp.body())
    stationsJson = resp.json()
    options = [schema.Option(display = x["station_descriptive_name"] + " - " + directionName(x["direction_id"]), value = x["stop_id"]) for x in stationsJson]
    return options

def get_schema():
    stopOptions = getStationOptions()
    routeOptions = [
        schema.Option(
            display = "Red",
            value = "Red",
        ),
        schema.Option(
            display = "Blue",
            value = "Blue",
        ),
        schema.Option(
            display = "Brown",
            value = "Brn",
        ),
        schema.Option(
            display = "Green",
            value = "G",
        ),
        schema.Option(
            display = "Orange",
            value = "Org",
        ),
        schema.Option(
            display = "Purple",
            value = "P",
        ),
        schema.Option(
            display = "Pink",
            value = "Pink",
        ),
        schema.Option(
            display = "Yellow",
            value = "Y",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "firstStop",
                name = "First Stop",
                desc = "The ID of stop in the top slot.",
                icon = "locationDot",
                default = stopOptions[0].value,
                options = stopOptions,
            ),
            schema.Dropdown(
                id = "firstRoute",
                name = "First Route",
                desc = "The route in the top slot, make sure the route is available at your selected stop.",
                icon = "route",
                default = routeOptions[6].value,
                options = routeOptions,
            ),
            schema.Toggle(
                id = "firstShowSched",
                name = "First - Include Scheduled",
                desc = "Whether scheduled trains should also appear in top slot. By default, only live-tracked trains are shown.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "secondStop",
                name = "Second Stop",
                desc = "The ID of stop in the bottom slot.",
                icon = "locationDot",
                default = stopOptions[1].value,
                options = stopOptions,
            ),
            schema.Dropdown(
                id = "secondRoute",
                name = "Second Route",
                desc = "The route in the bottom slot.",
                icon = "route",
                default = routeOptions[6].value,
                options = routeOptions,
            ),
            schema.Toggle(
                id = "secondShowSched",
                name = "Second - Include Scheduled",
                desc = "Whether scheduled trains should also appear in bottom slot. By default, only live-tracked trains are shown.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "showAnimatedTrain",
                name = "Show Animated Train",
                desc = "Whether animated train is shown between top and bottom slot",
                icon = "train",
                default = True,
            ),
        ],
    )

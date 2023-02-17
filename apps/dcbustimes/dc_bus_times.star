"""
Applet: DC Bus Times
Summary: DC (WMATA) Bus Arrival Times
Description: Displays the predicted arrival times for next buses at specified DC bus stop(s).
Author: Steven Pressnall
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

NEXTBUS_URL = "https://api.wmata.com/NextBusService.svc/json/jPredictions"
DEFAULT_STOPID1 = "1001155"
DEFAULT_STOPID2 = ""
ENCRYPTED_API_KEY = "AV6+xWcEN/eoKQ8PCUXypIgPSO7IT4v5uu6/yNmDXvJjtwrYANFMNpXiU/ki/yEvf7u9wpNjLLsx2ab7y9SFBL15w/elg7AkgtJVueJbhGGOwnlGyvAnhUEEvcDQh57x5vQT186xKDDUo/RgMEjSIj0bGnigi2hJUET8ydOFsz1DGbwtP6c="

def main(config):
    numPredictions = 0
    numPredictions2 = 0
    iMinutes = [0, 0, 0, 0, 0, 0, 0, 0]

    apiKey = secret.decrypt(ENCRYPTED_API_KEY)

    Bus = [render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    ), render.Row(
        children = [
            render.Text(""),
        ],
    )]

    StopID1 = config.get("StopID_1", DEFAULT_STOPID1)
    if len(StopID1) < 7:
        StopID1 = DEFAULT_STOPID1

    objPredictions = GetTimes1(StopID1, apiKey)

    numPredictions = min(len(objPredictions["Predictions"]), 4)
    if numPredictions == 0:
        return render.Root(
            delay = 100,
            child = render.Marquee(
                scroll_direction = "horizontal",
                width = 64,
                align = "end",
                offset_start = 32,
                offset_end = 64,
                child = render.Text("No predictions available", font = "5x8", color = "#ff0"),
            ),
        )

    for i in range(0, numPredictions):
        iMinutes[i] = objPredictions["Predictions"][i]["Minutes"]
        Bus[i] = render.Row(
            children = [
                render.Text("%s " % objPredictions["Predictions"][i]["RouteID"], font = "5x8", color = "#0f0"),
                render.Text("%d min" % iMinutes[i], font = "5x8", color = "#ff0"),
            ],
        )

    StopID2 = config.get("StopID_2", DEFAULT_STOPID2)
    if len(StopID2) == 7:
        objPredictions2 = GetTimes1(StopID2, apiKey)
        numPredictions2 = min(len(objPredictions2["Predictions"]), 4)

        for i in range(0, numPredictions2):
            iMinutes[i + numPredictions] = objPredictions2["Predictions"][i]["Minutes"]
            Bus[i + numPredictions] = render.Row(
                children = [
                    render.Text("%s " % objPredictions2["Predictions"][i]["RouteID"], font = "5x8", color = "#0ff"),
                    render.Text("%d min" % iMinutes[i + numPredictions], font = "5x8", color = "#ff0"),
                ],
            )

    numPredictions += numPredictions2
    if numPredictions <= 4:
        return render.Root(
            delay = 500,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 0,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Bus[0],
                        Bus[1],
                        Bus[2],
                        Bus[3],
                    ],
                ),
            ),
        )
    elif numPredictions == 5:
        return render.Root(
            delay = 500,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 2,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Bus[0],
                        Bus[1],
                        Bus[2],
                        Bus[3],
                        Bus[4],
                    ],
                ),
            ),
        )
    elif numPredictions == 6:
        return render.Root(
            delay = 500,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 2,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Bus[0],
                        Bus[1],
                        Bus[2],
                        Bus[3],
                        Bus[4],
                        Bus[5],
                    ],
                ),
            ),
        )
    elif numPredictions == 7:
        return render.Root(
            delay = 500,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 2,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Bus[0],
                        Bus[1],
                        Bus[2],
                        Bus[3],
                        Bus[4],
                        Bus[5],
                        Bus[6],
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            delay = 500,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 2,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Bus[0],
                        Bus[1],
                        Bus[2],
                        Bus[3],
                        Bus[4],
                        Bus[5],
                        Bus[6],
                        Bus[7],
                    ],
                ),
            ),
        )

def GetTimes1(stopID, apiKey):
    cached = cache.get(stopID)
    if cached:
        return json.decode(cached)

    rep = http.get(NEXTBUS_URL, params = {"StopID": stopID}, headers = {"api_key": apiKey})
    if rep.status_code != 200:
        fail("NextBus request failed with status ", rep.status_code)

    cache.set(stopID, rep.body(), ttl_seconds = 20)
    return rep.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "StopID_1",
                name = "Stop ID #1 (e.g. 1001155)",
                desc = "Bus Stop ID Number (7 digit number located on Bus Stop sign)",
                icon = "busSimple",
            ),
            schema.Text(
                id = "StopID_2",
                name = "Stop ID #2 (optional)",
                desc = "Bus Stop ID Number (leave blank if 2nd stop not desired)",
                icon = "busSimple",
            ),
        ],
    )

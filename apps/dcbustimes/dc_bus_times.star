"""
Applet: DC Bus Times
Summary: DC (WMATA) Bus Arrival Times
Description: Displays the predicted arrival times for next buses at specified DC bus stop(s).
Author: Steven Pressnall
Version: 2.0 - Add option to show bus route details (Show Details)
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
ENCRYPTED_API_KEY = "AV6+xWcES/gMdrg972dJlYM7I3LF3UXYTSPv/+lz7A7gYqYlVouA0V1Hp1KEE8PaE2OcMYwNZVTjuvAMxxW2rs+BgcBsJMwzB7UV8qNaD6VXM3LRHpKzTSywYBHqcoSFGkU/91Z1a/Raxnh0zvygyxKAcNypjFs/+ZW1qarI7+Xm/aqwt4g="

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

    Details = [render.Row(
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

    Divider = render.Row(
        children = [
            render.Box(height = 1, width = 64, color = "#a0d"),
        ],
    )

    ShowDetails = config.bool("DetailMode", False)

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
        Details[i] = render.Row(
            children = [
                render.WrappedText("%s " % objPredictions["Predictions"][i]["DirectionText"], font = "tom-thumb", color = "#0ff", linespacing = 0),
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
                    render.Text("%s " % objPredictions2["Predictions"][i]["RouteID"], font = "5x8", color = "#f00"),
                    render.Text("%d min" % iMinutes[i + numPredictions], font = "5x8", color = "#ff0"),
                ],
            )
            Details[i + numPredictions] = render.Row(
                children = [
                    render.WrappedText("%s " % objPredictions2["Predictions"][i]["DirectionText"], font = "tom-thumb", color = "#0ff", linespacing = 0),
                ],
            )

    numPredictions += numPredictions2
    if numPredictions <= 3:
        if ShowDetails == True:
            return render.Root(
                delay = 300,
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    align = "start",
                    offset_start = 2,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Divider,
                            Bus[0],
                            Details[0],
                            Divider,
                            Bus[1],
                            Details[1],
                            Divider,
                            Bus[2],
                            Details[2],
                            Divider,
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
                    offset_start = 0,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Bus[0],
                            Bus[1],
                            Bus[2],
                        ],
                    ),
                ),
            )
    elif numPredictions == 4:
        if ShowDetails == True:
            return render.Root(
                delay = 300,
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    align = "start",
                    offset_start = 2,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Divider,
                            Bus[0],
                            Details[0],
                            Divider,
                            Bus[1],
                            Details[1],
                            Divider,
                            Bus[2],
                            Details[2],
                            Divider,
                            Bus[3],
                            Details[3],
                            Divider,
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
        if ShowDetails == True:
            return render.Root(
                delay = 300,
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    align = "start",
                    offset_start = 2,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Divider,
                            Bus[0],
                            Details[0],
                            Divider,
                            Bus[1],
                            Details[1],
                            Divider,
                            Bus[2],
                            Details[2],
                            Divider,
                            Bus[3],
                            Details[3],
                            Divider,
                            Bus[4],
                            Details[4],
                            Divider,
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
                        ],
                    ),
                ),
            )
    elif numPredictions == 6:
        if ShowDetails == True:
            return render.Root(
                delay = 300,
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    align = "start",
                    offset_start = 2,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Divider,
                            Bus[0],
                            Details[0],
                            Divider,
                            Bus[1],
                            Details[1],
                            Divider,
                            Bus[2],
                            Details[2],
                            Divider,
                            Bus[3],
                            Details[3],
                            Divider,
                            Bus[4],
                            Details[4],
                            Divider,
                            Bus[5],
                            Details[5],
                            Divider,
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
                        ],
                    ),
                ),
            )
    elif numPredictions == 7:
        if ShowDetails == True:
            return render.Root(
                delay = 300,
                child = render.Marquee(
                    scroll_direction = "vertical",
                    height = 32,
                    align = "start",
                    offset_start = 2,
                    offset_end = 32,
                    child = render.Column(
                        children = [
                            Divider,
                            Bus[0],
                            Details[0],
                            Divider,
                            Bus[1],
                            Details[1],
                            Divider,
                            Bus[2],
                            Details[2],
                            Divider,
                            Bus[3],
                            Details[3],
                            Divider,
                            Bus[4],
                            Details[4],
                            Divider,
                            Bus[5],
                            Details[5],
                            Divider,
                            Bus[6],
                            Details[6],
                            Divider,
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
                        ],
                    ),
                ),
            )
    elif ShowDetails == True:
        return render.Root(
            delay = 300,
            child = render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                align = "start",
                offset_start = 2,
                offset_end = 32,
                child = render.Column(
                    children = [
                        Divider,
                        Bus[0],
                        Details[0],
                        Divider,
                        Bus[1],
                        Details[1],
                        Divider,
                        Bus[2],
                        Details[2],
                        Divider,
                        Bus[3],
                        Details[3],
                        Divider,
                        Bus[4],
                        Details[4],
                        Divider,
                        Bus[5],
                        Details[5],
                        Divider,
                        Bus[6],
                        Details[6],
                        Divider,
                        Bus[7],
                        Details[7],
                        Divider,
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
            schema.Toggle(
                id = "DetailMode",
                name = "Show Details",
                desc = "Enable display of detailed bus route information",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

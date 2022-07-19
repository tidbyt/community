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

ONE_MINUTE = 60
BASE_URL = "https://www.fairfaxcounty.gov/bustime/api/v3"
DEFAULT_STOP = "6484"

# Gets the list of predicted bus times for an individual bus stop
def getPredictions(apiKey, stopId):
    stopPredictions = cache.get(stopId)
    if stopPredictions == None:
        predictionUrl = BASE_URL + "/getpredictions?key=" + apiKey + "&stpid=" + stopId + "&format=json"
        stopPredictions = http.get(predictionUrl).body()
        cache.set(stopId, stopPredictions, ONE_MINUTE)

    stopPredictions = json.decode(stopPredictions).get("bustime-response").get("prd")
    return stopPredictions

def renderBusRow(prediction):
    if prediction == None:
        return render.Text("")
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(
                content = prediction.get("rt"),
                color = "#00f",
            ),
            render.Text(
                content = prediction.get("prdtm").split(" ")[1],
            ),
        ],
    )

def main(config):
    apiKey = secret.decrypt("AV6+xWcEHWq0zUeozY3oe2t6xhMzEHRhb/Tn+2RBF5rGUi5jc8XcDKxG2RC7lqqhGYS8z0+glkxCg1ZsTf6sCsNAMB7RD+HQpPyyhmB8cek35AnYxHQQsy2A7o9uLswG3g3k3edobR3Qy4KHckKqGdtkVYxXNG3HK0yEqCG4hQ==")

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
    predictions = getPredictions(apiKey, stop)
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

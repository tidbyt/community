"""
Applet: WMATA Buses
Summary: Buses in the WMATA system
Description: This app tells you the next buses to arrive at 1-2 bus stops in in Washington, DC.
Author: abrahamrowe
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")


def main(config):
    api_key = "42585dc3f14741fa999f64f6458727fa"
    defaultN = 1002491
    defaultS = 1002493
    oneStop = False

    northbound = config.str("bustStopN", defaultN)
    southbound = config.str("bustStopS", defaultS)

    if northbound == southbound:
        oneStop = True

    wmata_urlN = str("https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=" + str(northbound))
    wmata_urlS = str("https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=" + str(southbound))

    headers = {"api_key": api_key, "Accept": "application/json"}
    WMATA_data1 = http.get(wmata_urlN, headers = headers, ttl_seconds = 60)  # cache for 1 minute
    WMATA_data2 = http.get(wmata_urlS, headers = headers, ttl_seconds = 60)  # cache for 1 minute
    if WMATA_data1.status_code != 200:
        fail("WMATA request failed with status %d", WMATA_data1.status_code)
    if WMATA_data2.status_code != 200:
        fail("WMATA request failed with status %d", WMATA_data2.status_code)
    predictions1 = WMATA_data1.json()["Predictions"]
    predictions2 = WMATA_data2.json()["Predictions"]

    # Check if result was served from cache or not
    if WMATA_data1.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling WMATA API.")

    if WMATA_data2.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling WMATA API.")
    if oneStop == False:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                                height = 14,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                color = "#ffffff",
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 2,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions2[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions2[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions2[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[0]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                                height = 14,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[0]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[0]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                color = "#ffffff",
                                height = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                width = 64,
                                height = 2,
                            ),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Box(
                                color = "#00f",
                                width = 15,
                                height = 13,
                                child = render.Row(
                                    children = [
                                        render.Box(
                                            width = 1,
                                        ),
                                        render.Text(content = predictions1[1]["RouteID"], font = "6x13"),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 1,
                            ),
                            render.Column(
                                main_align = "start",
                                cross_align = "left",
                                children = [
                                    render.Marquee(
                                        width = 64,
                                        child = render.Text(predictions1[1]["DirectionText"]),
                                    ),
                                    render.Text(content = str(int(predictions1[1]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "busStopN",
                name = "Northbound Bus Stop ID",
                desc = "Go to https://buseta.wmata.com, and click on the stop. But the numbers only after the Bus Stop #. For example: 1002362.",
                icon = "bus",
            ),
            schema.Text(
                id = "busStopS",
                name = "Southbound Bus Stop ID",
                desc = "Same as the northbound instructions for the southbound stop. If you'd like to display the next two buses for a single stop, enter the Northbound stop ID again.",
                icon = "bus",
            ),
        ],
    )

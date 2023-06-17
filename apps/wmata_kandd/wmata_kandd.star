"""
Applet: WMATA KandD
Summary: Buses at Kansas and Decatur
Description: This app tells you the next buses to arrive at Kansas and Decatur in Washington, DC.
Author: abrahamrowe
"""

load("http.star", "http")
load("render.star", "render")

WMATA_URL1 = "https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=1002491"
WMATA_URL2 = "https://api.wmata.com/NextBusService.svc/json/jPredictions?StopID=1002493"
api_key = "42585dc3f14741fa999f64f6458727fa"
WMATA_HOST = "api.wmata.com"

def main():
    headers = {"api_key": api_key, "Accept": "application/json"}
    WMATA_data1 = http.get(WMATA_URL1, headers = headers, ttl_seconds = 60)  # cache for 1 minutes
    WMATA_data2 = http.get(WMATA_URL2, headers = headers, ttl_seconds = 60)  # cache for 1 minutes
    if WMATA_data1.status_code != 200:
        fail("WMATA request failed with status %d", WMATA_data1.status_code)
    if WMATA_data2.status_code != 200:
        fail("WMATA request failed with status %d", WMATA_data2.status_code)
    predictions1 = WMATA_data1.json()["Predictions"]
    predictions2 = WMATA_data2.json()["Predictions"]

    # for development purposes: check if result was served from cache or not
    if WMATA_data1.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling WMATA API.")

    if WMATA_data2.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling WMATA API.")

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
                                    render.Text(content = predictions2[1]["RouteID"], font = "6x13"),
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
                                    child = render.Text(predictions2[1]["DirectionText"]),
                                ),
                                render.Text(content = str(int(predictions2[1]["Minutes"])) + " min", font = "tom-thumb", color = "#FFD580"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

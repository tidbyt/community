"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs Real-Time Flight Data API to find the flight overhead your location.
Author: Kyle Bolstad
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

URL = "https://airlabs.co/api/v9/flights"

def main(config):
    api_key = config.get("api_key")
    bbox = config.get("bbox")

    request = http.get("%s?api_key=%s&bbox=%s" % (URL, api_key, bbox), ttl_seconds = 60)  # cache for 1 minute

    if request.status_code != 200:
        fail("Request failed with status %d", request.status_code)

    json = request.json()

    if json.get("response"):
        response = json["response"]

        if response:
            response = response[0]

            return render.Root(
                child = render.Box(
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text("%s %s" % (response["airline_iata"], response["flight_number"])),
                            render.Text("%s - %s" % (response["dep_iata"], response["arr_iata"])),
                            render.Text("%dkts %dft" % (response["speed"] * 0.53995680345572, response["alt"] * 3.28)),
                        ],
                    ),
                ),
            )
        else:
            return []
    elif json.get("error"):
        return render.Root(
            child = render.WrappedText(json["error"]["message"]),
        )
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "AirLabs API Key",
                icon = "key",
            ),
            schema.Text(
                id = "bbox",
                name = "BBox",
                desc = "AirLabs Bounding box",
                icon = "locationArrow",
            ),
        ],
    )

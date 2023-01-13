"""
Applet: Minnesota Light Rail
Summary: Train Departure Times
Description: Shows Light Rail Departure Times from Selected Stop.
Author: Alex Miller
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

#Assign Default Stop Code
DEFAULT_STOP_CODE = "51408"

def main(config):
    #Establish API URL
    stop_code = config.get("stop_code", DEFAULT_STOP_CODE)
    url = "https://svc.metrotransit.org/NexTripv2/" + stop_code + "?format=json"
    MTT = http.get(url).json()

    #Find color and destination of first and second train and use that for rendering square color and 3 letter destination code
    if MTT["departures"][0]["route_short_name"] == "Blue":
        CB = "#00a"

        if MTT["departures"][0]["description"] == "to Mpls-Target Field":
            DB = "MTF"
        else:
            DB = "MOA"

    else:
        CB = "#0a0"

        if MTT["departures"][0]["description"] == "to Mpls-Target Field":
            DB = "MTF"
        else:
            DB = "STP"

    if MTT["departures"][1]["route_short_name"] == "Blue":
        CB2 = "#00a"

        if MTT["departures"][1]["description"] == "to Mpls-Target Field":
            DB2 = "MTF"
        else:
            DB2 = "MOA"

    else:
        CB2 = "#0a0"

        if MTT["departures"][1]["description"] == "to Mpls-Target Field":
            DB2 = "MTF"
        else:
            DB2 = "STP"

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(MTT["stops"][0]["description"], font = "tb-8"),
                    offset_start = 5,
                    offset_end = 5,
                ),
                render.Box(width = 64, height = 1),
                render.Box(width = 64, height = 1, color = "#a00"),
                render.Row(
                    children = [
                        render.Stack(
                            children = [
                                render.Box(width = 12, height = 10, color = CB),
                                render.Text(DB, font = "tom-thumb"),
                            ],
                        ),
                        render.Box(width = 6, height = 10),
                        render.Text(MTT["departures"][0]["departure_text"], font = "Dina_r400-6"),
                    ],
                ),
                render.Box(width = 64, height = 1, color = "#a00"),
                render.Row(
                    children = [
                        render.Stack(
                            children = [
                                render.Box(width = 12, height = 10, color = CB2),
                                render.Text(DB2, font = "tom-thumb"),
                            ],
                        ),
                        render.Box(width = 6, height = 10),
                        render.Text(MTT["departures"][1]["departure_text"], font = "Dina_r400-6"),
                    ],
                ),
                render.Box(width = 64, height = 1, color = "#a00"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_code",
                name = "Stop ID",
                desc = "Light Rail Station's Stop ID from (https://www.metrotransit.org/stops-stations)",
                icon = "trainSubway",
            ),
        ],
    )

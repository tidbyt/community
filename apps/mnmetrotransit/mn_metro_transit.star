"""
Applet: MN Metro Transit
Summary: Train, BRT, ABRT, and Bus Departure Times
Description: Shows Transit Departure Times from Selected Stop.
Authors: Alex Miller & Jonathan Wescott
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("schema.star", "schema")

#Assign Default Stop Code
DEFAULT_STOP_CODE = "15264"

def main(config):
    #Establish API URL
    stop_code = config.get("stop_code", DEFAULT_STOP_CODE)
    url = "https://svc.metrotransit.org/NexTripv2/" + stop_code + "?format=json"
    MTT = http.get(url).json()

    #departure slot 1
    #Find color and destination of first and second train and use that for rendering square color and 3 letter destination code
    route1 = MTT["departures"][0]["route_short_name"]
    route2 = MTT["departures"][1]["route_short_name"]
    r1Desc = MTT["departures"][0]["direction_text"]
    r2Desc = MTT["departures"][1]["direction_text"]
    r1D = MTT["departures"][0]["description"]
    r2D = MTT["departures"][1]["description"]
    if r1Desc == "NB":
        r1Desc = "North"
    elif r1Desc == "WB":
        r1Desc = "West"
    elif r1Desc == "SB":
        r1Desc = "South"
    elif r1Desc == "EB":
        r1Desc = "East"
    if r2Desc == "NB":
        r2Desc = "North"
    elif r2Desc == "WB":
        r2Desc = "West"
    elif r2Desc == "SB":
        r2Desc = "South"
    elif r2Desc == "EB":
        r2Desc = "East"

    if route1 == "Blue":
        CB = "#00a"
        CT = "#FFF"

        if r1D == "to Mpls-Target Field":
            DB = "MPLS"
        else:
            DB = "MOA"

    elif route1 == "Green":
        CB = "#070"
        CT = "#FFF"

        if r1D == "to Mpls-Target Field":
            DB = "MPLS"
        else:
            DB = "STPAUL"

    elif route1 == "Orange":
        CB = "#fa0"
        CT = "#222"
        DB = route1

    elif route1 == "Red":
        CB = "#F00"
        CT = "#222"
        DB = route1

    else:
        CB = "#333"
        DB = route1
        CT = "#fa0"

    if route1[2:7] == "Line":
        CB = "#555"
        CT = "#FFF"
        DB = route1

    #departure slot 2
    if route2 == "Blue":
        CB2 = "#00a"
        CT2 = "#FFF"

        if r2D == "to Mpls-Target Field":
            DB2 = "MPLS"
        else:
            DB2 = "MOA"

    elif route2 == "Green":
        CB2 = "#070"
        CT2 = "#FFF"

        if r2D == "to Mpls-Target Field":
            DB2 = "MPLS"
        else:
            DB2 = "STPAUL"

    elif route2 == "Orange":
        CB2 = "#fa0"
        CT2 = "#222"
        DB2 = route2

    elif route2 == "Red":
        CB2 = "#F00"
        CT2 = "#222"
        DB2 = route2

    else:
        CB2 = "#333"
        DB2 = route2
        CT2 = "#fa0"

    if route2[2:7] == "Line":
        CB2 = "#555"
        CT2 = "#FFF"
        DB2 = route2

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(MTT["stops"][0]["description"], font = "tb-8"),
                    offset_start = 5,
                    offset_end = 5,
                ),
                render.Box(width = 64, height = 1, color = CB),
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Box(width = 1, height = 11, color = CB),
                            ],
                        ),
                        render.Stack(
                            children = [
                                render.Box(width = 24, height = 11, color = CB),
                                render.Column(
                                    cross_align = "center",
                                    children = [
                                        render.Text(DB, font = "CG-pixel-3x5-mono", color = CT),
                                        render.Box(width = 24, height = 1, color = CB),
                                        render.Text(r1Desc, font = "CG-pixel-3x5-mono", color = CT),
                                    ],
                                ),
                            ],
                        ),
                        render.Box(width = 3, height = 10),
                        render.Text(MTT["departures"][0]["departure_text"], font = "Dina_r400-6"),
                    ],
                ),
                render.Box(width = 64, height = 1, color = CB2),
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Box(width = 1, height = 11, color = CB2),
                            ],
                        ),
                        render.Stack(
                            children = [
                                render.Box(width = 24, height = 11, color = CB2),
                                render.Column(
                                    cross_align = "center",
                                    children = [
                                        render.Text(DB2, font = "CG-pixel-3x5-mono", color = CT2),
                                        render.Box(width = 24, height = 1, color = CB2),
                                        render.Text(r2Desc, font = "CG-pixel-3x5-mono", color = CT2),
                                    ],
                                ),
                            ],
                        ),
                        render.Box(width = 3, height = 10),
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
                icon = "train-subway",
            ),
        ],
    )

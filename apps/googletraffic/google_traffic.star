"""
Applet: Google Traffic
Summary: Drive Duration in Traffic
Description: This app shows the duration to get from an origin to a destination by using traffic information from Google.
Author: LukiLeu
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("time.star", "time")
load("schema.star", "schema")

GOOGLE_URL = "https://maps.googleapis.com/maps/api/distancematrix/json?departure_time=now&key="

FONT_TO_USE = "tb-8"

DEST_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAEJJREFUKFNjZEAC/////4/MZ2RkZITx4Qx0RXAFUMVghTBFyCagi9NIITbr0Z1DmmdgPiQqeNAVo4cA3GrkgMbGBgDoyjQLaTLLZwAAAABJRU5ErkJggg==
""")

ORIG_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAD9JREFUKFNjZCASMKKr+////3+QGCMjI4ocCgemCKYZWTFcIboidMVghbgUISsmzURkU2HuQvcUhonUU0go3AFP2iwLdKPsRAAAAABJRU5ErkJggg==
""")

TIME_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAEdJREFUKFNjZCASMCKr+////39kPiMjI1wezgApQpYAaUAWAytEFkDXAONTphBkC8wZOE1EDwQUhejuhCnG8AyyBMHgIRTuAL4iRAvjZUoyAAAAAElFTkSuQmCC
""")

CAR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAPUlEQVQY06WOSQ4AIAgDqfH/Xx4PJoCKXuypDEsxe0rugKDSMgV4O/uqTqSXxyMFmElnNqByaf/rBpv9aACqSC/jGvR/lAAAAABJRU5ErkJggg==
""")

TRAIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAM0lEQVQY05WMsQ0AIAzDYsT/L4ehW1WI8JjIRpJtTQBLkdGuMdjh3o9+twHgI84tXplgH2jgDxDs9RTyAAAAAElFTkSuQmCC
""")

BIKE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAOklEQVQY02NgIBX8////////+ITgbEZMIagEIyO6VrgKuAjj////IQqRdcNFmNAMRJiJx6lYHE8OAAAwfzXe5vPvegAAAABJRU5ErkJggg==
""")

WALK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAO0lEQVQY042PMQ4AMAgCof//M92IGkzLJoYTgS5Jkjwe/GtEAdCL5pITbusNNyxXM4k1uh6qnfPfsdoFM+Mj9n0J0akAAAAASUVORK5CYII=
""")

DEFAULT_DEPARTURE = {
    "locality": "Barcellona",
}
DEFAULT_DESTINATION = {
    "locality": "Paris",
}

TRANSPORTATION_MODES = {
    "Car": "driving",
    "Walk": "walking",
    "Bicycle": "bicycling",
    "Public Transport": "transit",
}

def render_animation(roadDest, roadOrigin, roadDuration, transportationmode):
    if transportationmode == TRANSPORTATION_MODES.get("Car"):
        icon = CAR_ICON
    elif transportationmode == TRANSPORTATION_MODES.get("Walk"):
        icon = WALK_ICON
    elif transportationmode == TRANSPORTATION_MODES.get("Bicycle"):
        icon = BIKE_ICON
    else:
        icon = TRAIN_ICON

    renderChildren = [
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = ORIG_ICON),
                render.Box(width = 1, height = 10),
                render.Marquee(
                    width = 53,
                    child = render.Text(
                        content = "%s" % roadOrigin,
                        font = FONT_TO_USE,
                    ),
                    offset_start = 0,
                    offset_end = 0,
                ),
            ],
        ),
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = DEST_ICON),
                render.Box(width = 1, height = 10),
                render.Marquee(
                    width = 53,
                    child = render.Text(
                        content = "%s" % roadDest,
                        font = FONT_TO_USE,
                    ),
                    offset_start = 0,
                    offset_end = 0,
                ),
            ],
        ),
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = icon),
                render.Box(width = 1, height = 10),
                render.Marquee(
                    width = 53,
                    child = render.Text(
                        content = "%s" % roadDuration,
                        font = FONT_TO_USE,
                    ),
                    offset_start = 0,
                    offset_end = 0,
                ),
            ],
        ),
    ]
    return renderChildren

def main(config):
    departureFull = config.get("departure")
    departureJSON = json.decode(departureFull) if departureFull else DEFAULT_DEPARTURE
    departure = departureJSON.get("locality")
    destinationFull = config.get("destination")
    destinationJSON = json.decode(destinationFull) if destinationFull else DEFAULT_DESTINATION
    destination = destinationJSON.get("locality")
    apikey = config.get("apikey", "ABC")
    transportationmode = TRANSPORTATION_MODES.get(config.get("transportationmode", "Car"))
    showDistance = config.bool("showDistance", False)

    # Get the cached response
    rep_cached = cache.get("%s&destinations=%s&origins=%s&mode=%s" % (apikey, destination, departure, transportationmode))
    if rep_cached != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(rep_cached)
    else:
        print("Miss! Calling Google API.")
        rep = http.get("%s%s&destinations=%s&origins=%s&mode=%s" % (GOOGLE_URL, apikey, destination, departure, transportationmode))
        if rep.status_code != 200:
            fail("Google request failed with status %d", rep.status_code)
        cache.set("%s&destinations=%s&origins=%s&mode=%s" % (apikey, destination, departure, transportationmode), rep.body(), ttl_seconds = 300)
        rep = json.decode(rep.body())

    # Prepare empty list
    renderChildren = []

    # Check for errors
    if rep["status"] != "OK":
        renderChildren.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = rep["status"],
                    font = FONT_TO_USE,
                ),
                offset_start = 0,
                offset_end = 0,
            ),
        )
    elif rep["rows"][0]["elements"][0]["status"] != "OK":
        roadDest = rep["destination_addresses"][0]
        roadOrigin = rep["origin_addresses"][0]
        roadDuration = rep["rows"][0]["elements"][0]["status"]
        renderChildren = render_animation(roadDest, roadOrigin, roadDuration, transportationmode)
    else:
        roadDest = rep["destination_addresses"][0].replace(", Switzerland", "")
        roadOrigin = rep["origin_addresses"][0].replace(", Switzerland", "")

        if "duration_in_traffic" in rep["rows"][0]["elements"][0]:
            roadDuration = rep["rows"][0]["elements"][0]["duration_in_traffic"]["text"]
        else:
            roadDuration = rep["rows"][0]["elements"][0]["duration"]["text"]
        if showDistance:
            roadDuration = "%s (%s)" % (roadDuration, rep["rows"][0]["elements"][0]["distance"]["text"])
        renderChildren = render_animation(roadDest, roadOrigin, roadDuration, transportationmode)

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = renderChildren,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "departure",
                name = "Departure",
                desc = "Departure adress",
                icon = "home",
            ),
            schema.Location(
                id = "destination",
                name = "Destination",
                desc = "Destination adress",
                icon = "place",
            ),
            schema.Dropdown(
                id = "transportationmode",
                name = "Transportation Mode",
                icon = "car",
                desc = "Specify the mode of transportation.",
                options = [
                    schema.Option(display = transportationmode, value = transportationmode)
                    for transportationmode in TRANSPORTATION_MODES
                ],
                default = "Car",
            ),
            schema.Toggle(
                id = "showDistance",
                name = "Show Distance",
                desc = "Show Distance from departure to destination.",
                icon = "route",
                default = True,
            ),
            schema.Text(
                id = "apikey",
                name = "API Key",
                desc = "Google Maps Distance Matrix API Key",
                icon = "google",
            ),
        ],
    )

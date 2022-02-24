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
load("secret.star", "secret")
load("math.star", "math")

GOOGLE_URL = "https://maps.googleapis.com/maps/api/distancematrix/json?departure_time=now"

FONT_TO_USE = "tb-8"

DEST_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAASUlEQVQY03XOMQ7AIAxD0W+pW0/A/e/HUKmoE2aBqgXylgxWEkPnv2L7BNAIWV1A0jeUtCwcfVbgIWI7e+PtsOsx3s2X7qBwrAEvtkW1IRA0bQAAAABJRU5ErkJggg==
""")

ORIG_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAMUlEQVQY02NgQAL/oQBZjBFZEkWCkZERrgBdElkRIy5JFCvwmcCEYSTUbhhgYqAUAACphBgFTEVAIAAAAABJRU5ErkJggg==
""")

CAR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAASklEQVQY042LMQ7AIBDDHHH/f22ZOJQuPRVRhnp0HHjovXulvADKSSrPnJOIEKfXGMO2nZkOXq41AmitEQCStI/lPsORU/TrCHADLjdKnaoEIscAAAAASUVORK5CYII=
""")

TRAIN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAM0lEQVQY042NQQ4AIAzCyrL/fxlPeiAu2hMhkArAtrkgSUyD3RUPOh9JpfN4J2fmnkbfLIXsG/7HXrcsAAAAAElFTkSuQmCC
""")

BIKE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAP0lEQVQY042NsQ2AQBDDYjqWYMTbvzMNBR9AwtUpUXzJX1TU3Ysul/B+b0kC0MXD0CbVmTlQBej1kr2pP981J/H6Q0DDzqOfAAAAAElFTkSuQmCC
""")

WALK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAQ0lEQVQY03WNQRLAMAgC2U7//2IjvTQd41huwCpS01rLtr391YGIOPwBZKZtC2BnSFJ9+RUvRA07CHBrUJ0Yr6fJXz3cmSHnOt8PoAAAAABJRU5ErkJggg==
""")

DIST_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAANUlEQVQY04WOQQoAIBACFTpF///udNoICndugiNaHwDUUaXR2DPNL0nybdh+cjwF4PT8LCQ2Qq8kBgP3F6UAAAAASUVORK5CYII=
""")

ERROR_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/
9hAAAAbklEQVQ4y72S0Q2AIAwFj8YRZBf2/2IXVtDU
D6LRBAsIsUm/aHMvV8AoTUE1BbVmhMFyFv0x6KP7L8
FFP1/1PYUUlgXYAFhj7k6JO7C0eJniQGqEWop5V2ih
l/6FncDH3DUHvfT7zriDL/SpVzgA+N8ttq4TxtUAAA
AASUVORK5CYII=
""")

DEFAULT_DEPARTURE = {
    "lat": "41.392727",
    "lng": "2.1051698",
}
DEFAULT_DESTINATION = {
    "lat": "48.858906",
    "lng": "2.3120158",
}

# DEFAULT_DESTINATION = {
#      "lat": "36.81680492999389",
#      "lng": "75.32979660185084",
# }

TRANSPORTATION_MODES = {
    "Car": "driving",
    "Walk": "walking",
    "Bicycle": "bicycling",
    "Public Transport": "transit",
}

DISTANCE_UNIT = {
    "Kilometer": "Kilometer",
    "Mile": "Mile",
}

# Show an error message
def display_error(msg):
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    width = 20,
                    height = 32,
                    color = "#000",
                    child = render.Image(
                        src = ERROR_ICON,
                        width = 16,
                        height = 16,
                    ),
                ),
                render.Box(
                    padding = 0,
                    width = 44,
                    height = 32,
                    child =
                        render.WrappedText(
                            content = msg.replace("_", " "),
                            color = "#FFF",
                            linespacing = 1,
                            font = "CG-pixel-3x5-mono",
                        ),
                ),
            ],
        ),
    )

def render_animation(roadDest, roadOrigin, roadDuration, roadDistance, transportationmode):
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
                render.Image(src = ORIG_ICON, height = 8),
                render.Box(width = 1, height = 8),
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
                render.Image(src = DEST_ICON, height = 8),
                render.Box(width = 1, height = 8),
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
                render.Image(src = icon, height = 8),
                render.Box(width = 1, height = 8),
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

    if roadDistance != None:
        renderChildren.append(
            render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = DIST_ICON, height = 8),
                    render.Box(width = 1, height = 8),
                    render.Marquee(
                        width = 53,
                        child = render.Text(
                            content = "%s" % roadDistance,
                            font = FONT_TO_USE,
                        ),
                        offset_start = 0,
                        offset_end = 0,
                    ),
                ],
            ),
        )
    return renderChildren

# Create a string from a time in seconds
def duration_to_string(sec):
    seconds_in_day = 60 * 60 * 24
    seconds_in_hour = 60 * 60
    seconds_in_minute = 60

    days = sec // seconds_in_day
    hours = (sec - (days * seconds_in_day)) // seconds_in_hour
    minutes = (sec - (days * seconds_in_day) - (hours * seconds_in_hour)) // seconds_in_minute

    timestring = ""
    if minutes > 0:
        timestring = "%im %s" % (minutes, timestring)
    if hours > 0:
        timestring = "%ih %s" % (hours, timestring)
    if days > 0:
        timestring = "%id %s" % (days, timestring)

    return timestring

def main(config):
    departureFull = config.get("departure")
    departureJSON = json.decode(departureFull) if departureFull else DEFAULT_DEPARTURE
    departure = "%s,%s" % (departureJSON.get("lat"), departureJSON.get("lng"))
    destinationFull = config.get("destination")
    destinationJSON = json.decode(destinationFull) if destinationFull else DEFAULT_DESTINATION
    destination = "%s,%s" % (destinationJSON.get("lat"), destinationJSON.get("lng"))
    apikey = secret.decrypt("AV6+xWcEKcu8TenAfiwgtgo9YdGTaE2bVJI2BT08Zvb9GZwzl8m6Pb2RudfILMRj0UH/pZaSh9tCFAlHzFwQ2CPaDcyLAEcuHcJYq6bMrMDuR2z7QjNCkaIvabOE9Db5lNwDqGv+yMr2QFWHffBxvwLWfqOOpDViS4KlLuFUwb/29V2dr/v6OBaEJz3w") or config.get("apikey") or ""
    transportationmode = TRANSPORTATION_MODES.get(config.get("transportationmode", "Car"))
    showDistance = config.bool("showDistance", False)
    distanceUnit = DISTANCE_UNIT.get(config.get("distanceUnit", "Kilometer"))
    showCountry = config.bool("showCountry", True)
    departureAlias = config.get("departureAlias", "")
    destinationAlias = config.get("destinationAlias", "")

    # Get the cached response
    rep_cached = cache.get("%s&destinations=%s&origins=%s&mode=%s" % (apikey, destination, departure, transportationmode))
    if rep_cached != None:
        print("Hit! Displaying cached data.")
        rep = json.decode(rep_cached)
    else:
        print("Miss! Calling Google API.")

        # Provide the parameters with a dict, as this will be encoded
        google_dict = {
            "destinations": destination,
            "origins": departure,
            "mode": transportationmode,
            "key": apikey,
        }
        rep = http.get(GOOGLE_URL, params = google_dict)
        if rep.status_code != 200:
            return (display_error("API Error occured"))
        cache.set("%s&destinations=%s&origins=%s&mode=%s" % (apikey, destination, departure, transportationmode), rep.body(), ttl_seconds = 300)
        rep = json.decode(rep.body())

    # Prepare empty list
    renderChildren = []

    # Check for errors
    if rep["status"] != "OK":
        return (display_error(rep["status"]))
    elif rep["rows"][0]["elements"][0]["status"] != "OK":
        roadDest = rep["destination_addresses"][0]
        roadOrigin = rep["origin_addresses"][0]
        roadDuration = rep["rows"][0]["elements"][0]["status"]
        renderChildren = render_animation(roadDest, roadOrigin, roadDuration, None, transportationmode)
    else:
        if departureAlias == "":
            roadOrigin = rep["origin_addresses"][0]
            if showCountry == False:
                roadOrigin = roadOrigin[0:roadOrigin.rfind(",")]
        else:
            roadOrigin = departureAlias

        if destinationAlias == "":
            roadDest = rep["destination_addresses"][0]
            if showCountry == False:
                roadDest = roadDest[0:roadDest.rfind(",")]
        else:
            roadDest = destinationAlias

        if "duration_in_traffic" in rep["rows"][0]["elements"][0]:
            roadDurationVal = rep["rows"][0]["elements"][0]["duration_in_traffic"]["value"]
        else:
            roadDurationVal = rep["rows"][0]["elements"][0]["duration"]["value"]
        roadDuration = duration_to_string(roadDurationVal)
        if showDistance:
            roadDistance = rep["rows"][0]["elements"][0]["distance"]["value"]
            if distanceUnit == DISTANCE_UNIT.get("Miles"):
                roadDistanceText = "%imi" % int(roadDistance / 1000 * 0.621371)
            else:
                roadDistanceText = "%ikm" % int(roadDistance / 1000)
            renderChildren = render_animation(roadDest, roadOrigin, roadDuration, roadDistanceText, transportationmode)
        else:
            renderChildren = render_animation(roadDest, roadOrigin, roadDuration, None, transportationmode)

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
            schema.Text(
                id = "departureAlias",
                name = "Departure Alias",
                desc = "Alias for the departure that is shown instead of the address",
                default = "",
                icon = "home",
            ),
            schema.Location(
                id = "destination",
                name = "Destination",
                desc = "Destination adress",
                icon = "place",
            ),
            schema.Text(
                id = "destinationAlias",
                name = "Destination Alias",
                desc = "Alias for the destination that is shown instead of the address",
                default = "",
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
                default = False,
            ),
            schema.Dropdown(
                id = "distanceUnit",
                name = "Distance unit",
                icon = "road",
                desc = "Specify the unit of the distance",
                options = [
                    schema.Option(display = distanceunit, value = distanceunit)
                    for distanceunit in DISTANCE_UNIT
                ],
                default = "Kilometer",
            ),
            schema.Toggle(
                id = "showCountry",
                name = "Show Country",
                desc = "Shows the country in the departure and destination adress",
                icon = "flag",
                default = True,
            ),
        ],
    )

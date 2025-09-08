"""
Applet: Norway Transit
Summary: Check departures in Norway
Description: Check your favourite stop in real time, anywhre in Norway.
Author: Mats Grosvik
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TRAM_BLUE = "#6fe9ff"
RUTER_RED = "#E60000"
WHITE = "#FFFFFF"
YELLOW = "#f9C66b"
BLACK = "#000000"

def main(config):
    direction = config.get("directionId", "outbound")
    air = config.get("showAir", True)
    bus = config.get("showBus", True)
    cableway = config.get("showCableway", True)
    water = config.get("showWater", False)
    funicular = config.get("showFunicular", True)
    lift = config.get("showLift", True)
    rail = config.get("showRail", True)
    metro = config.get("showMetro", True)
    tram = config.get("showTram", True)
    coach = config.get("showCoach", True)
    search = config.get("searchId", '{"display": "Ryen", "value": "NSR:StopPlace:5900"}')
    searchHit = json.decode(search)

    checkTransportMode = [{"air": air}, {"bus": bus}, {"cableway": cableway}, {"water": water}, {"funicular": funicular}, {"lift": lift}, {"rail": rail}, {"metro": metro}, {"tram": tram}, {"coach": coach}]

    graphql_query = """\r
    query ($id: String!) {\r
      stopPlace(id: $id) {\r
        name\r
         id\r
    estimatedCalls {\r
      expectedArrivalTime\r
      destinationDisplay {\r
        frontText\r
      }\r
      serviceJourney {\r
        line {\r
          publicCode\r
          transportMode\r
          presentation {\r
            colour\r
          }\r
        }\r
        journeyPattern {\r
          directionType\r
        }\r
      }\r
    }\r
      }\r
    }\r
    """

    query_variables = '{"id": "' + searchHit["value"] + '"}'

    graphql_payload = '{"query": ' + repr(graphql_query) + ', "variables": ' + repr(query_variables) + "}"

    headers = {
        "Content-Type": "application/json",
        "ET-Client-Name": "tidbyt-widgett",
    }

    rep = http.post(
        "https://api.entur.io/journey-planner/v3/graphql",
        body = graphql_payload,
        headers = headers,
    )

    if rep.status_code != 200:
        fail("ENTUR request failed with status %d", rep.status_code)

    response_json = rep.json()

    selected_modes = [mode_key for mode in checkTransportMode for mode_key, value in mode.items() if value == "true"]
    stop_place = response_json.get("data", {}).get("stopPlace", {})
    estimated_calls = stop_place.get("estimatedCalls", [])

    filtered_calls = [call for call in estimated_calls if call.get("serviceJourney", {}).get("journeyPattern", {}).get("directionType") == direction and call.get("serviceJourney", {}).get("line", {}).get("transportMode") in selected_modes]
    fall_back = ""
    first_arrival_time = ""
    first_destination = ""
    first_line_info = ""
    first_color = ""
    first_public_code = ""
    first_transport_mode = ""
    first_countdown = ""
    second_countdown = ""
    second_arrival_time = ""
    second_destination = ""
    second_line_info = ""
    second_color = ""
    second_public_code = ""
    second_transport_mode = ""

    def format_time_difference(diff_seconds):
        if diff_seconds < 30:
            return "Nå"
        if diff_seconds < 90:
            return "1 min"
        if diff_seconds > 7199:
            return "{} hours".format(int(diff_seconds // 3600))
        if diff_seconds > 3599:
            return "{} hour".format(int(diff_seconds // 3600))
        else:
            return "{} min".format(int(diff_seconds // 60))

    def getColor(transport, color):
        if color == "000000":
            return WHITE
        if color:
            return color
        if transport == "tram":
            return TRAM_BLUE
        if transport == "bus":
            return RUTER_RED
        if transport == "metro":
            return YELLOW
        else:
            return WHITE

    now = time.now().in_location("Europe/Oslo")

    if (filtered_calls == []):
        fall_back = "Found no calls @ " + searchHit["display"]
    elif (len(filtered_calls) == 1):
        first_call = filtered_calls[0]

        first_arrival_time = first_call.get("expectedArrivalTime", "")
        first_destination = first_call.get("destinationDisplay", {}).get("frontText", "")
        first_line_info = first_call.get("serviceJourney", {}).get("line", {})
        first_color = first_line_info.get("presentation", {}).get("colour", "")
        first_public_code = first_line_info.get("publicCode", "")
        first_transport_mode = first_line_info.get("transportMode", "")

        first_arrival_time_obj = time.parse_time(first_arrival_time, location = "Europe/Oslo")
        first_time_difference = (first_arrival_time_obj - now).seconds
        first_countdown = format_time_difference(first_time_difference)
    else:
        first_call = filtered_calls[0]
        second_call = filtered_calls[1]

        first_arrival_time = first_call.get("expectedArrivalTime", "")
        first_destination = first_call.get("destinationDisplay", {}).get("frontText", "")
        first_line_info = first_call.get("serviceJourney", {}).get("line", {})
        first_color = first_line_info.get("presentation", {}).get("colour", "")
        first_public_code = first_line_info.get("publicCode", "")
        first_transport_mode = first_line_info.get("transportMode", "")

        second_arrival_time = second_call.get("expectedArrivalTime", "")
        second_destination = second_call.get("destinationDisplay", {}).get("frontText", "")
        second_line_info = second_call.get("serviceJourney", {}).get("line", {})
        second_color = second_line_info.get("presentation", {}).get("colour", "")
        second_public_code = second_line_info.get("publicCode", "")
        second_transport_mode = second_line_info.get("transportMode", "")

        first_arrival_time_obj = time.parse_time(first_arrival_time, location = "Europe/Oslo")
        second_arrival_time_obj = time.parse_time(second_arrival_time, location = "Europe/Oslo")

        first_time_difference = (first_arrival_time_obj - now).seconds
        second_time_difference = (second_arrival_time_obj - now).seconds

        first_countdown = format_time_difference(first_time_difference)
        second_countdown = format_time_difference(second_time_difference)

    if (fall_back == ""):
        if (len(filtered_calls) == 1):
            return render.Root(
                max_age = 15,
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(first_public_code, color = getColor(first_transport_mode, first_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(first_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(first_countdown, color = YELLOW, font = "tb-8"),
                        ),
                    ],
                ),
            )
        else:
            return render.Root(
                max_age = 15,
                child = render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(first_public_code, color = getColor(first_transport_mode, first_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(first_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(first_countdown, color = YELLOW, font = "tb-8"),
                        ),
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (2, 0, 2, 0),
                                            child = render.Text(second_public_code, color = getColor(second_transport_mode, second_color), font = "tb-8"),
                                        ),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(second_destination.upper(), color = WHITE, font = "tb-8"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (2, 0, 2, 0),
                            child = render.Text(second_countdown, font = "tb-8", color = YELLOW),
                        ),
                    ],
                ),
            )
    else:
        return render.Root(
            max_age = 15,
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.Padding(
                                        pad = (2, 0, 2, 0),
                                        child = render.WrappedText(content = fall_back, color = WHITE, font = "tb-8"),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def search(pattern):
    headers = {
        "Content-Type": "application/json",
        "ET-Client-Name": "tidbyt-widgett",
    }
    stopList = http.get(
        "https://api.entur.io/geocoder/v1/autocomplete?text=" + pattern + "",
        headers = headers,
    )
    if stopList.status_code == 200:
        response_json = stopList.json()

        options = [
            schema.Option(
                display = feature["properties"]["name"],
                value = feature["properties"]["id"],
            )
            for feature in response_json["features"]
            if feature["properties"]["id"].startswith("NSR:StopPlace")
        ]
        return options
    else:
        print("Error:", stopList.status_code)
        return []

def get_schema():
    directionOptions = [
        schema.Option(
            display = "Outbound",
            value = "outbound",
        ),
        schema.Option(
            display = "Inbound",
            value = "inbound",
        ),
    ]

    transport_modes = ["metro", "bus", "rail", "tram", "cableway", "water", "funicular", "lift", "air", "coach"]
    transportOptions = []
    for mode in transport_modes:
        option = schema.Toggle(
            id = "show" + mode.capitalize(),
            name = mode.capitalize(),
            desc = "Do you want to display " + mode + " departures?",
            icon = "",
            default = True,
        )
        transportOptions.append(option)
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "searchId",
                name = "Search",
                desc = "Find your stop",
                icon = "bus",
                handler = search,
            ),
            schema.Dropdown(
                id = "directionId",
                name = "Direction",
                desc = "Wich direction do you want to display",
                icon = "compass",
                default = directionOptions[0].value,
                options = directionOptions,
            ),
        ] + transportOptions,
    )

"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs or OpenSky to find the flight overhead a location.
Author: Kyle Bolstad
"""

load("animation.star", "animation")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AIRLABS_URL = "https://airlabs.co/api/v9"
HEXDB_URL = "https://hexdb.io/api/v1"
OPENSKY_URL = "https://opensky-network.org/api"

DEFAULT_DISABLE_END_HOUR = "None"
DEFAULT_DISABLE_START_HOUR = "None"
DEFAULT_IGNORE = "None"
DEFAULT_LIMIT = 1
DEFAULT_PRINT_LOG = False
DEFAULT_PROVIDER = "None"
DEFAULT_PROVIDER_TTL_SECONDS = 0
DEFAULT_RETURN_MESSAGE_ON_EMPTY = ""
DEFAULT_SHOW_OPENSKY_ROUTE = True
DEFAULT_TIMEZONE = "America/Chicago"

KN_RATIO = 1.94
KM_RATIO = 0.54
M_RATIO = 3.28

MAX_LIMIT = 5

def main(config):
    provider = config.get("provider")

    airlabs_api_key = config.get("airlabs_api_key")
    opensky_username = config.get("opensky_username")
    opensky_password = config.get("opensky_password")

    provider_bbox = config.get("provider_bbox")

    provider_ttl_seconds = DEFAULT_PROVIDER_TTL_SECONDS
    if config.get("provider_ttl_seconds"):
        provider_ttl_seconds = re.sub("\\D", "", config.get("provider_ttl_seconds")) or DEFAULT_PROVIDER_TTL_SECONDS
    provider_ttl_seconds = int(provider_ttl_seconds)

    timezone = config.get("timezone", DEFAULT_TIMEZONE)
    disable_start_hour = config.get("disable_start_hour", DEFAULT_DISABLE_START_HOUR)
    disable_end_hour = config.get("disable_end_hour", DEFAULT_DISABLE_END_HOUR)
    now = time.now().in_location(timezone).hour

    return_message_on_empty = config.get("return_message_on_empty", DEFAULT_RETURN_MESSAGE_ON_EMPTY)

    ignore = config.get("ignore", DEFAULT_IGNORE)

    show_opensky_route = config.bool("show_opensky_route", DEFAULT_SHOW_OPENSKY_ROUTE)

    limit = DEFAULT_LIMIT
    if config.get("limit"):
        limit = re.sub("\\D", "", config.get("limit")) or DEFAULT_LIMIT
    limit = int(limit)
    if limit > MAX_LIMIT:
        limit = MAX_LIMIT

    flights = []

    def check_request_headers(provider, request, ttl_seconds):
        if request.headers.get("Tidbyt-Cache-Status") == "HIT":
            print_log("displaying cached data for %s" % humanize.plural(ttl_seconds, "second"))

        else:
            print_log("calling %s api" % provider)

        print_log(request.url)

    def empty_message():
        if return_message_on_empty:
            print_log("Returning empty message: %s" % return_message_on_empty)

            return render.Root(
                child = render.Box(
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.WrappedText("%s" % return_message_on_empty),
                        ],
                    ),
                ),
            )

        return []

    def print_log(statement):
        if config.bool("print_log", DEFAULT_PRINT_LOG):
            print(statement)

    def _render(provider, response):
        print_log(response)

        child = ""

        for flight in response:
            plane = ""
            route = ""
            owners = ""
            location = ""

            if provider == "airlabs":
                plane = "%s" % flight.get("reg_number")
                location = "%dkt %dft" % (flight.get("speed") * KM_RATIO, flight.get("alt") * M_RATIO)

                if flight.get("flight_number"):
                    plane = "%s %s" % (flight.get("airline_iata") or flight.get("airline_icao"), flight.get("flight_number"))

                if flight.get("aircraft_icao"):
                    plane += " (%s)" % flight.get("aircraft_icao")

                if flight.get("dep_iata"):
                    route = "%s" % flight.get("dep_iata")

                if flight.get("arr_iata"):
                    route += " - %s" % (flight.get("arr_iata"))

            if provider == "opensky":
                plane = "%s" % re.sub("\\s", "", flight[1])
                location = "%dkt %dft" % (flight[9] * KN_RATIO, flight[7] * M_RATIO)

                aircraft_request_url = "%s/aircraft/%s" % (HEXDB_URL, flight[0])
                aircraft_request = http.get(aircraft_request_url, ttl_seconds = provider_ttl_seconds)
                check_request_headers("hexdb", aircraft_request, provider_ttl_seconds)
                print_log(aircraft_request.json())

                route_request_url = "%s/route/iata/%s" % (HEXDB_URL, plane)
                route_request = http.get(route_request_url, ttl_seconds = provider_ttl_seconds)
                check_request_headers("hexdb", route_request, provider_ttl_seconds)
                print_log(route_request.json())

                aircraft_json = aircraft_request.json()

                if aircraft_json.get("ICAOTypeCode"):
                    plane += " (%s)" % aircraft_json.get("ICAOTypeCode")

                route_json = route_request.json()

                if show_opensky_route and route_json.get("route"):
                    route = route_json.get("route")

                _owners = aircraft_json.get("RegisteredOwners")

                if _owners:
                    if len(_owners) < 15:
                        owners = _owners
                    else:
                        owners = _owners.split(" ") and _owners.split(" ")[0]

            if ignore.count(plane):
                print_log("ignoring %s" % plane)

                return empty_message()

            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(plane),
                        render.Text(route or owners),
                        render.Text(location),
                    ],
                ),
            )

            if len(response) > 1:
                if (limit == 0 or limit > 1) and len(flights) < limit:
                    flights.append(
                        animation.Transformation(
                            direction = "reverse",
                            duration = 150,
                            child = child,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Translate(0, -32)],
                                    curve = "ease_in_out",
                                ),
                                animation.Keyframe(
                                    percentage = 0.1,
                                    transforms = [animation.Translate(0, -0)],
                                    curve = "ease_in_out",
                                ),
                                animation.Keyframe(
                                    percentage = 0.9,
                                    transforms = [animation.Translate(0, -0)],
                                    curve = "ease_in_out",
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Translate(0, -32)],
                                    curve = "ease_in_out",
                                ),
                            ],
                        ),
                    )

        if len(flights) > 0:
            child = render.Sequence(
                children = flights,
            )

        return render.Root(
            child = child,
        )

    print_log(time.now())

    if disable_start_hour != DEFAULT_DISABLE_START_HOUR and disable_end_hour != DEFAULT_DISABLE_END_HOUR:
        disable_start_hour = int(disable_start_hour)
        disable_end_hour = int(disable_end_hour)

        print_log("Disabling between %d:00 and %d:00" % (disable_start_hour, disable_end_hour))

        if (disable_end_hour >= disable_start_hour and now >= disable_start_hour and now < disable_end_hour) or (disable_end_hour < disable_start_hour and now >= disable_start_hour or now < disable_end_hour):
            print_log("Disabled")

            return empty_message()

    if provider:
        provider_request = ""

        if provider == "airlabs":
            provider_request_url = "%s/flights?bbox=%s" % (AIRLABS_URL, provider_bbox)
            if airlabs_api_key:
                provider_request_url += "&api_key=%s" % airlabs_api_key
            provider_request = http.get(provider_request_url, ttl_seconds = provider_ttl_seconds)

        if provider == "opensky":
            lamin = ""
            lomin = ""
            lamax = ""
            lomax = ""

            if provider_bbox:
                lamin = provider_bbox.split(",")[0]
                lomin = provider_bbox.split(",")[1]
                lamax = provider_bbox.split(",")[2]
                lomax = provider_bbox.split(",")[3]

            provider_request_url = "%s/states/all?lamin=%s&lomin=%s&lamax=%s&lomax=%s" % (OPENSKY_URL, lamin, lomin, lamax, lomax)
            provider_request = http.get(provider_request_url, auth = (opensky_username, opensky_password), ttl_seconds = provider_ttl_seconds)

        if provider_request:
            check_request_headers(provider, provider_request, provider_ttl_seconds)

            if provider_request.status_code != 200:
                fail("%s" % provider_request)

            provider_json = provider_request.json()

            if provider_json.get("response"):
                return _render(provider, provider_json.get("response"))

            elif provider_json.get("states"):
                return _render(provider, provider_json.get("states"))

            elif provider_json.get("error"):
                message = provider_json["error"]["message"]

                print_log("Error: %s" % message)

                return render.Root(
                    child = render.WrappedText(message),
                )

            else:
                print_log("no flights found")

                return empty_message()

        else:
            return empty_message()
    else:
        return empty_message()

def get_schema():
    timezones = [
        schema.Option(display = "Hawaii (-10)", value = "Pacific/Honolulu"),
        schema.Option(display = "Alaska (-9)", value = "America/Anchorage"),
        schema.Option(display = "Pacific (-8)", value = "America/Los_Angeles"),
        schema.Option(display = "Mountain (-7)", value = "America/Denver"),
        schema.Option(display = "Central (-6)", value = "America/Chicago"),
        schema.Option(display = "Eastern (-5)", value = "America/New_York"),
        schema.Option(display = "Atlantic (-4)", value = "America/Halifax"),
        schema.Option(display = "Newfoundland (-3.5)", value = "America/St_Johns"),
        schema.Option(display = "Brazil (-3)", value = "America/Sao_Paulo"),
        schema.Option(display = "UTC (0)", value = "UTC"),
        schema.Option(display = "Central Europe (+1)", value = "Europe/Berlin"),
        schema.Option(display = "Eastern Europe (+2)", value = "Europe/Moscow"),
        schema.Option(display = "India (+5.5)", value = "Asia/Kolkata"),
        schema.Option(display = "China (+8)", value = "Asia/Shanghai"),
        schema.Option(display = "Japan (+9)", value = "Asia/Tokyo"),
        schema.Option(display = "Australia Eastern (+10)", value = "Australia/Sydney"),
        schema.Option(display = "New Zealand (+12)", value = "Pacific/Auckland"),
    ]

    hours = [
        schema.Option(display = "None", value = "None"),
        schema.Option(display = "1 AM", value = "1"),
        schema.Option(display = "2 AM", value = "2"),
        schema.Option(display = "3 AM", value = "3"),
        schema.Option(display = "4 AM", value = "4"),
        schema.Option(display = "5 AM", value = "5"),
        schema.Option(display = "6 AM", value = "6"),
        schema.Option(display = "7 AM", value = "7"),
        schema.Option(display = "8 AM", value = "8"),
        schema.Option(display = "9 AM", value = "9"),
        schema.Option(display = "10 AM", value = "10"),
        schema.Option(display = "11 AM", value = "11"),
        schema.Option(display = "Noon", value = "12"),
        schema.Option(display = "1 PM", value = "13"),
        schema.Option(display = "2 PM", value = "14"),
        schema.Option(display = "3 PM", value = "15"),
        schema.Option(display = "4 PM", value = "16"),
        schema.Option(display = "5 PM", value = "17"),
        schema.Option(display = "6 PM", value = "18"),
        schema.Option(display = "7 PM", value = "19"),
        schema.Option(display = "8 PM", value = "20"),
        schema.Option(display = "9 PM", value = "21"),
        schema.Option(display = "10 PM", value = "22"),
        schema.Option(display = "11 PM", value = "23"),
        schema.Option(display = "Midnight", value = "0"),
    ]

    limits = []

    for i in range(MAX_LIMIT):
        limits.append(schema.Option(display = "%d" % (i + 1), value = "%d" % (i + 1)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "provider",
                name = "Provider",
                desc = "Provider",
                icon = "ioxhost",
                default = DEFAULT_PROVIDER,
                options = [
                    schema.Option(display = "AirLabs", value = "airlabs"),
                    schema.Option(display = "OpenSky", value = "opensky"),
                ],
            ),
            schema.Text(
                id = "airlabs_api_key",
                name = "AirLabs API Key",
                desc = "AirLabs API Key",
                icon = "key",
            ),
            schema.Text(
                id = "opensky_username",
                name = "OpenSky Username",
                desc = "OpenSky Username",
                icon = "user",
            ),
            schema.Text(
                id = "opensky_password",
                name = "OpenSky Password",
                desc = "OpenSky Password",
                icon = "key",
            ),
            schema.Text(
                id = "provider_bbox",
                name = "Provider BBox",
                desc = "Provider Bounding box",
                icon = "locationArrow",
            ),
            schema.Text(
                id = "provider_ttl_seconds",
                name = "Provider TTL Seconds",
                desc = "Number of seconds to cache results",
                icon = "clock",
                default = "%s" % DEFAULT_PROVIDER_TTL_SECONDS,
            ),
            schema.Dropdown(
                id = "limit",
                name = "Limit",
                desc = "Limit number of results",
                icon = "list",
                default = "%s" % DEFAULT_LIMIT,
                options = limits,
            ),
            schema.Dropdown(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone",
                icon = "clock",
                default = DEFAULT_TIMEZONE,
                options = timezones,
            ),
            schema.Dropdown(
                id = "disable_start_hour",
                name = "Disable Start Hour",
                desc = "Disable during certain timeframe",
                icon = "clock",
                default = DEFAULT_DISABLE_START_HOUR,
                options = hours,
            ),
            schema.Dropdown(
                id = "disable_end_hour",
                name = "Disable End Hour",
                desc = "Disable during certain timeframe",
                icon = "clock",
                default = DEFAULT_DISABLE_END_HOUR,
                options = hours,
            ),
            schema.Text(
                id = "return_message_on_empty",
                name = "Return Message on Empty",
                desc = "Message to return if no flights found",
                icon = "message",
                default = DEFAULT_RETURN_MESSAGE_ON_EMPTY,
            ),
            schema.Toggle(
                id = "print_log",
                name = "Print Log",
                desc = "Print log statements to help debug",
                icon = "bug",
                default = DEFAULT_PRINT_LOG,
            ),
        ],
    )

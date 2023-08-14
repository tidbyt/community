"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs or OpenSky to find the flight overhead a location.
Author: Kyle Bolstad
"""

load("animation.star", "animation")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PROVIDERS = {
    "adsblol": {
        "name": "ADSB.lol",
        "url": "https://api.adsb.lol/api/0",
        "display": False,
    },
    "airlabs": {
        "name": "AirLabs",
        "url": "https://airlabs.co/api/v9",
        "display": True,
    },
    "hexdb": {
        "name": "HexDB",
        "url": "https://hexdb.io/api/v1",
        "display": False,
    },
    "opensky": {
        "name": "OpenSky",
        "url": "https://opensky-network.org/api",
        "display": True,
    },
}

DEFAULT_AIRLABS_API_KEY = ""
DEFAULT_DISABLE_END_HOUR = "None"
DEFAULT_DISABLE_START_HOUR = "None"
DEFAULT_IGNORE = ""
DEFAULT_LIMIT = 1
DEFAULT_LOCATION = ""
DEFAULT_OPENSKY_USERNAME = ""
DEFAULT_OPENSKY_PASSWORD = ""
DEFAULT_PRINT_LOG = False
DEFAULT_PROVIDER = "None"
DEFAULT_PROVIDER_BBOX = ""
DEFAULT_PROVIDER_TTL_SECONDS = 0
DEFAULT_RADIUS = 1
DEFAULT_RETURN_MESSAGE_ON_EMPTY = ""
DEFAULT_SHOW_ROUTE = True
DEFAULT_TIMEZONE = "America/Chicago"

KN_RATIO = 1.94
KM_RATIO = 0.54
M_RATIO = 3.28

MAX_AGE = 300
MAX_WIDTH_CHARACTERS = 16
MAX_LIMIT = 5
MAX_RADIUS = 10

def main(config):
    provider = config.get("provider")

    airlabs_api_key = config.get("airlabs_api_key", DEFAULT_AIRLABS_API_KEY)
    opensky_username = config.get("opensky_username", DEFAULT_OPENSKY_USERNAME)
    opensky_password = config.get("opensky_password", DEFAULT_OPENSKY_PASSWORD)

    location = DEFAULT_LOCATION
    if config.get("location"):
        location = re.sub("[^\\d-,\\.]", "", config.get("location")) or DEFAULT_LOCATION

    radius = DEFAULT_RADIUS
    if config.get("radius"):
        radius = re.sub("[^\\d\\.]", "", config.get("radius")) or DEFAULT_RADIUS
    radius = int(radius)
    if radius > MAX_RADIUS:
        radius = MAX_RADIUS

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

    show_route = config.bool("show_route", DEFAULT_SHOW_ROUTE)

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

    def get_aircraft_info(aircraft):
        type = ""
        _owners = ""
        owners = ""

        if aircraft:
            aircraft_request_url = "%s/aircraft/%s" % (PROVIDERS["hexdb"]["url"], aircraft)
            aircraft_request = http.get(aircraft_request_url, ttl_seconds = provider_ttl_seconds)
            check_request_headers("hexdb", aircraft_request, provider_ttl_seconds)
            print_log(aircraft_request.json())

            aircraft_json = aircraft_request.json()

            if aircraft_json.get("ICAOTypeCode"):
                type = aircraft_json.get("ICAOTypeCode")
                _owners = aircraft_json.get("RegisteredOwners")

            if _owners:
                if len(_owners) < MAX_WIDTH_CHARACTERS:
                    owners = _owners
                else:
                    owners = _owners[0:MAX_WIDTH_CHARACTERS]

        return {"owners": owners, "type": type}

    def is_flying(flight_info):
        return flight_info.get("altitude", 0) > 0

    def should_ignore(flight_info):
        return ignore and flight_info.get("callsign") and ignore.count(flight_info.get("callsign"))

    def print_log(statement):
        if config.bool("print_log", DEFAULT_PRINT_LOG):
            print(statement)

    def _render(provider, response):
        print_log(response)

        child = ""
        children = []

        flights_index = 0

        print_log("found %s" % (humanize.plural(len(response), "flight")))

        for flight in response:
            flight_info = {}

            if flights_index < limit:
                if provider == "airlabs":
                    flight_info["hex"] = flight.get("hex")
                    flight_info["altitude"] = flight.get("alt") * M_RATIO
                    flight_info["callsign"] = flight.get("reg_number")

                    if is_flying(flight_info) and not should_ignore(flight_info):
                        flight_info["plane"] = flight_info.get("callsign")
                        flight_info["location"] = "%dkt %dft" % (flight.get("speed") * KM_RATIO, flight_info.get("altitude"))
                        flight_info["aircraft_info"] = get_aircraft_info(flight_info.get("hex"))
                        flight_info["owners"] = flight_info.get("aircraft_info").get("owners")

                        if flight.get("flight_number"):
                            flight_info["plane"] = "%s %s" % (flight.get("airline_iata") or flight.get("airline_icao"), flight.get("flight_number"))

                        if flight.get("aircraft_icao"):
                            flight_info["plane"] += " (%s)" % flight.get("aircraft_icao")

                        if show_route:
                            if flight.get("dep_iata"):
                                flight_info["route"] = "%s" % flight.get("dep_iata")

                            if flight.get("arr_iata"):
                                flight_info["route"] += " - %s" % (flight.get("arr_iata"))

                if provider == "opensky":
                    flight_info["icao24"] = flight[0]
                    flight_info["altitude"] = (flight[7] or 0) * M_RATIO
                    flight_info["callsign"] = "%s" % re.sub("\\s", "", flight[1])

                    if is_flying(flight_info) and not should_ignore(flight_info):
                        flight_info["plane"] = flight_info.get("callsign")
                        flight_info["location"] = "%dkt %dft" % ((flight[9] or 0) * KN_RATIO, flight_info.get("altitude"))
                        flight_info["aircraft_info"] = get_aircraft_info(flight_info.get("icao24"))
                        flight_info["owners"] = flight_info.get("aircraft_info").get("owners")
                        flight_info["type"] = flight_info.get("aircraft_info").get("type")

                        if show_route and flight_info.get("plane"):
                            route_request_url = "%s/route/%s" % (PROVIDERS["adsblol"]["url"], flight_info.get("callsign"))
                            route_request = http.get(route_request_url, ttl_seconds = provider_ttl_seconds)
                            check_request_headers("adsblol", route_request, provider_ttl_seconds)

                            if route_request.status_code == 200:
                                print_log(route_request.json())
                                route_json = route_request.json()

                                route = route_json.get("airport_codes")
                                if route and route != route_json.get("_airport_codes_iata") and route != "unknown":
                                    flight_info["route"] = route
                                    airport_codes = route.split("-")
                                    airport_codes_iata = []

                                    for airport_code in airport_codes:
                                        airport_codes_request_url = "%s/airport/%s" % (PROVIDERS["adsblol"]["url"], airport_code)
                                        airport_codes_request = http.get(airport_codes_request_url, ttl_seconds = provider_ttl_seconds)
                                        check_request_headers("adsblol", airport_codes_request, provider_ttl_seconds)
                                        if airport_codes_request.status_code == 200:
                                            print_log(airport_codes_request.json())

                                        if airport_codes_request.status_code == 200 and airport_codes_request.json() and airport_codes_request.json().get("iata"):
                                            airport_codes_iata.append(airport_codes_request.json().get("iata"))
                                        else:
                                            airport_codes_iata.append(airport_code)

                                    if len(airport_codes_iata) > 0:
                                        flight_info["route"] = "-".join(airport_codes_iata)

                        if flight_info["type"]:
                            flight_info["plane"] += " (%s)" % flight_info.get("type")

                if should_ignore(flight_info):
                    print_log("ignoring %s" % flight_info.get("callsign"))

                elif is_flying(flight_info):
                    second_line_content = flight_info.get("route", flight_info.get("owners"))
                    second_line_font = ""
                    if len(second_line_content) > MAX_WIDTH_CHARACTERS * 0.75:
                        second_line_font = "CG-pixel-3x5-mono"

                    flights.append(
                        render.Box(
                            render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [
                                    render.Text(flight_info.get("plane")),
                                    render.Text(
                                        content = second_line_content,
                                        font = second_line_font,
                                    ),
                                    render.Text(flight_info.get("location")),
                                ],
                            ),
                        ),
                    )
                    flights_index += 1

        print_log("showing %s within %dnm of %s" % (humanize.plural(flights_index, "flight"), radius, location))

        if len(flights) > 1:
            for flight in flights:
                children.append(
                    animation.Transformation(
                        direction = "reverse",
                        duration = 150,
                        child = flight,
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

            child = render.Sequence(
                children = children,
            )
        else:
            child = flights and flights[0]

        if child:
            return render.Root(
                max_age = MAX_AGE,
                show_full_animation = True,
                child = child,
            )

        else:
            return empty_message()

    print_log(time.now())

    if disable_start_hour != DEFAULT_DISABLE_START_HOUR and disable_end_hour != DEFAULT_DISABLE_END_HOUR:
        disable_start_hour = int(disable_start_hour)
        disable_end_hour = int(disable_end_hour)

        print_log("Disabling between %d:00 and %d:00" % (disable_start_hour, disable_end_hour))

        if (disable_end_hour >= disable_start_hour and now >= disable_start_hour and now < disable_end_hour) or (disable_end_hour < disable_start_hour and now >= disable_start_hour or now < disable_end_hour):
            print_log("Disabled")

            return empty_message()

    if provider:
        auth = ()
        provider_request = ""
        provider_request_url = ""
        lat = 0
        long = 0
        la_min = 0
        lo_min = 0
        la_max = 0
        lo_max = 0
        bbox = ""

        lat_lng = location.split(",")
        if len(lat_lng) == 2:
            lat = lat_lng[0]
            long = lat_lng[1]

        if lat and long:
            lat = float(lat)
            long = float(long)
            miles_per_deg_lat = 69.1
            miles_per_deg_long = 69.1 * math.cos(lat / 180 * math.pi)
            lat_pm = radius / miles_per_deg_lat
            long_pm = radius / miles_per_deg_long
            la_min = lat - lat_pm
            lo_min = long - long_pm
            la_max = lat + lat_pm
            lo_max = long + long_pm
            bbox = "%s,%s,%s,%s" % (la_min, lo_min, la_max, lo_max)

        if provider == "airlabs":
            provider_request_url = "%s/flights?bbox=%s" % (PROVIDERS["airlabs"]["url"], bbox)
            if airlabs_api_key:
                provider_request_url += "&api_key=%s" % airlabs_api_key

        if provider == "opensky":
            provider_request_url = "%s/states/all?lamin=%s&lomin=%s&lamax=%s&lomax=%s" % (PROVIDERS["opensky"]["url"], la_min, lo_min, la_max, lo_max)
            if opensky_username and opensky_password:
                auth = (opensky_username, opensky_password)

        if provider_request_url:
            provider_request = http.get(provider_request_url, auth = auth, ttl_seconds = provider_ttl_seconds)

        if provider_request:
            check_request_headers(provider, provider_request, provider_ttl_seconds)

            if provider_request.status_code != 200:
                fail("%s" % provider_request)

            provider_json = provider_request.json()

            if provider == "airlabs" and provider_json.get("response"):
                return _render(provider, provider_json.get("response"))

            elif provider == "opensky" and provider_json.get("states"):
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
    providers = []

    for provider in PROVIDERS:
        if PROVIDERS[provider]["display"]:
            providers.append(
                schema.Option(
                    display = PROVIDERS[provider]["name"],
                    value = provider,
                ),
            )

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

    radii = []

    for i in range(MAX_RADIUS):
        radii.append(schema.Option(display = "%d" % (i + 1), value = "%d" % (i + 1)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "provider",
                name = "Provider",
                desc = "Provider",
                icon = "ioxhost",
                default = DEFAULT_PROVIDER,
                options = providers,
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
                id = "location",
                name = "Location",
                desc = "Latitude, Longitude",
                icon = "mapLocationDot",
            ),
            schema.Dropdown(
                id = "radius",
                name = "Radius",
                desc = "Radius in Nautical Miles",
                icon = "circleDot",
                default = "%s" % DEFAULT_RADIUS,
                options = radii,
            ),
            schema.Text(
                id = "provider_ttl_seconds",
                name = "Provider TTL Seconds",
                desc = "Number of seconds to cache results",
                icon = "clock",
                default = "%s" % DEFAULT_PROVIDER_TTL_SECONDS,
            ),
            schema.Toggle(
                id = "show_route",
                name = "Show Route",
                desc = "Some providers can often display incorrect routes",
                icon = "route",
                default = DEFAULT_SHOW_ROUTE,
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

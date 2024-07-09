"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs or OpenSky to find the flight overhead a location.
Author: Kyle Bolstad
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
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
DEFAULT_IGNORE = ""
DEFAULT_LIMIT = 1
DEFAULT_LOCATION = json.encode({
    "lat": "40.6969512",
    "lng": "-73.9538453",
    "description": "Brooklyn, NY, USA",
    "locality": "Tidbyt",
    "place_id": "ChIJr3Hjqu5bwokRmeukysQhFCU",
    "timezone": "America/New_York",
})
DEFAULT_OPENSKY_USERNAME = ""
DEFAULT_OPENSKY_PASSWORD = ""
DEFAULT_PRINT_LOG = False
DEFAULT_PROVIDER = "opensky"
DEFAULT_PROVIDER_BBOX = ""
DEFAULT_PROVIDER_TTL_SECONDS = 0
DEFAULT_RADIUS = 1
DEFAULT_RETURN_MESSAGE_ON_EMPTY = ""
DEFAULT_SHOW_ROUTE = True

KN_RATIO = 1.94
KM_RATIO = 0.54
M_RATIO = 3.28

MAX_AGE = 300
MAX_WIDTH_CHARACTERS = 16
MAX_LIMIT = 5
MAX_RADIUS = 10

def main(config):
    provider = config.get("provider", DEFAULT_PROVIDER)

    airlabs_api_key = config.get("airlabs_api_key", DEFAULT_AIRLABS_API_KEY)
    opensky_username = config.get("opensky_username", DEFAULT_OPENSKY_USERNAME)
    opensky_password = config.get("opensky_password", DEFAULT_OPENSKY_PASSWORD)

    location = json.decode(config.get("location", DEFAULT_LOCATION))

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

    def check_response_headers(provider, response, ttl_seconds):
        if response.headers.get("Tidbyt-Cache-Status") == "HIT":
            print_log("displaying cached data for %s" % humanize.plural(ttl_seconds, "second"))

        else:
            print_log("calling %s api" % provider)

        print_log(response.url)

    def validate_json(response):
        return json.decode(json.encode(response.json() if (hasattr(response, "json") and response.status_code == 200) else {}), {})

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
            aircraft_response_url = "%s/aircraft/%s" % (PROVIDERS["hexdb"]["url"], aircraft)
            aircraft_response = http.get(aircraft_response_url, ttl_seconds = provider_ttl_seconds)
            check_response_headers("hexdb", aircraft_response, provider_ttl_seconds)
            aircraft_json = validate_json(aircraft_response)
            print_log(aircraft_json)

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
                            route_response_url = "%s/route/%s" % (PROVIDERS["adsblol"]["url"], flight_info.get("callsign"))
                            route_response = http.get(route_response_url, ttl_seconds = provider_ttl_seconds)
                            check_response_headers("adsblol", route_response, provider_ttl_seconds)

                            if route_response.status_code == 200:
                                route_json = validate_json(route_response)
                                print_log(route_json)

                                route = route_json.get("airport_codes")
                                if route and route != route_json.get("_airport_codes_iata") and route != "unknown":
                                    flight_info["route"] = route
                                    airport_codes = route.split("-")
                                    airport_codes_iata = []

                                    for airport_code in airport_codes:
                                        airport_codes_response_url = "%s/airport/%s" % (PROVIDERS["adsblol"]["url"], airport_code)
                                        airport_codes_response = http.get(airport_codes_response_url, ttl_seconds = provider_ttl_seconds)
                                        check_response_headers("adsblol", airport_codes_response, provider_ttl_seconds)
                                        if airport_codes_response.status_code == 200:
                                            print_log(airport_codes_response.json())

                                        if airport_codes_response.status_code == 200 and airport_codes_response.json() and airport_codes_response.json().get("iata"):
                                            airport_codes_iata.append(airport_codes_response.json().get("iata"))
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

    if provider:
        auth = ()
        provider_response = ""
        provider_response_url = ""
        la_min = 0
        lo_min = 0
        la_max = 0
        lo_max = 0
        bbox = ""

        lat = location["lat"]
        lng = location["lng"]

        if lat and lng:
            lat = float(lat)
            lng = float(lng)
            miles_per_deg_lat = 69.1
            miles_per_deg_lng = 69.1 * math.cos(lat / 180 * math.pi)
            lat_pm = radius / miles_per_deg_lat
            lng_pm = radius / miles_per_deg_lng
            la_min = lat - lat_pm
            lo_min = lng - lng_pm
            la_max = lat + lat_pm
            lo_max = lng + lng_pm
            bbox = "%s,%s,%s,%s" % (la_min, lo_min, la_max, lo_max)

        if provider == "airlabs":
            provider_response_url = "%s/flights?bbox=%s" % (PROVIDERS["airlabs"]["url"], bbox)
            if airlabs_api_key:
                provider_response_url += "&api_key=%s" % airlabs_api_key

        if provider == "opensky":
            provider_response_url = "%s/states/all?lamin=%s&lomin=%s&lamax=%s&lomax=%s" % (PROVIDERS["opensky"]["url"], la_min, lo_min, la_max, lo_max)
            if opensky_username and opensky_password:
                auth = (opensky_username, opensky_password)

        if provider_response_url:
            provider_response = http.get(provider_response_url, auth = auth, ttl_seconds = provider_ttl_seconds)

        if provider_response:
            check_response_headers(provider, provider_response, provider_ttl_seconds)

            if provider_response.status_code != 200:
                fail("%s" % provider_response)

            provider_json = validate_json(provider_response)

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
                name = "Provider (Required)",
                desc = "The provider for the data",
                icon = "ioxhost",
                default = DEFAULT_PROVIDER,
                options = providers,
            ),
            schema.Location(
                id = "location",
                name = "Location (Required)",
                desc = "The decimalized latitude and longitude to search",
                icon = "mapLocationDot",
            ),
            schema.Dropdown(
                id = "radius",
                name = "Radius",
                desc = "The radius (in nautical miles) to search",
                icon = "circleDot",
                default = "%s" % DEFAULT_RADIUS,
                options = radii,
            ),
            schema.Text(
                id = "airlabs_api_key",
                name = "AirLabs API Key",
                desc = "An AirLabs API Key is required to use AirLabs as the provider",
                icon = "key",
                default = DEFAULT_AIRLABS_API_KEY,
            ),
            schema.Text(
                id = "opensky_username",
                name = "OpenSky Username",
                desc = "An OpenSky account can be used to extend the request quota",
                icon = "user",
                default = DEFAULT_OPENSKY_USERNAME,
            ),
            schema.Text(
                id = "opensky_password",
                name = "OpenSky Password",
                desc = "An OpenSky account can be used to extend the request quota",
                icon = "key",
                default = DEFAULT_OPENSKY_PASSWORD,
            ),
            schema.Text(
                id = "provider_ttl_seconds",
                name = "Provider TTL Seconds",
                desc = "The number of seconds to cache results from the provider",
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
                desc = "Limit the number of results to display",
                icon = "list",
                default = "%s" % DEFAULT_LIMIT,
                options = limits,
            ),
            schema.Text(
                id = "return_message_on_empty",
                name = "Return Message on Empty",
                desc = "The message to return if no flights are found",
                icon = "message",
                default = DEFAULT_RETURN_MESSAGE_ON_EMPTY,
            ),
        ],
    )

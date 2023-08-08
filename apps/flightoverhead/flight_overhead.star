"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs Real-Time Flight Data API to find the flight overhead your location.
Author: Kyle Bolstad
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AIRLABS_URL = "https://airlabs.co/api/v9"
OPENSKY_URL = "https://opensky-network.org/api"

DEFAULT_DISABLE_END_HOUR = "None"
DEFAULT_DISABLE_START_HOUR = "None"
DEFAULT_PRINT_LOG = False
DEFAULT_PROVIDER = "None"
DEFAULT_PROVIDER_TTL_SECONDS = 0
DEFAULT_RETURN_MESSAGE_ON_EMPTY = ""
DEFAULT_TIMEZONE = "America/Chicago"

KN_RATIO = 1.94
KM_RATIO = 0.54
M_RATIO = 3.28

def main(config):
    provider = config.get("provider")

    airlabs_api_key = config.get("airlabs_api_key")
    opensky_api_key = config.get("opensky_api_key")

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
        plane = ""
        flight_plan = "No flight plan"
        location = ""

        if provider and response:
            print_log(response)

            if provider == "airlabs":
                plane = "%s" % response.get("reg_number")
                location = "%dkt %dft" % (response.get("speed") * KM_RATIO, response.get("alt") * M_RATIO)

                if response.get("flight_number"):
                    plane = "%s %s" % (response.get("airline_iata") or response.get("airline_icao"), response.get("flight_number"))

                if response.get("aircraft_icao"):
                    plane += " (%s)" % response.get("aircraft_icao")

                if response.get("dep_iata"):
                    flight_plan = "%s" % response.get("dep_iata")

                if response.get("arr_iata"):
                    flight_plan += " - %s" % (response.get("arr_iata"))

            if provider == "opensky":
                plane = "%s" % response[1]
                location = "%dkt %dft" % (response[9] * KN_RATIO, response[7] * M_RATIO)

        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(plane),
                        render.Text(flight_plan),
                        render.Text(location),
                    ],
                ),
            ),
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
        url = ""

        if provider == "airlabs":
            url = "%s/flights?bbox=%s" % (AIRLABS_URL, provider_bbox)
            if airlabs_api_key:
                url += "&api_key=%s" % airlabs_api_key
            provider_request = http.get(url, ttl_seconds = provider_ttl_seconds)

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

            url = "%s/states/all?lamin=%s&lomin=%s&lamax=%s&lomax=%s" % (OPENSKY_URL, lamin, lomin, lamax, lomax)
            if opensky_api_key:
                url += "&api_key=%s" % opensky_api_key

            provider_request = http.get(url, ttl_seconds = provider_ttl_seconds)

        if provider_request:
            print_log(provider_request.url)

            if provider_request.headers.get("Tidbyt-Cache-Status") == "HIT":
                print_log("Displaying cached data for %s" % humanize.plural(provider_ttl_seconds, "second"))

            else:
                print_log("Calling API")

            if provider_request.status_code != 200:
                fail("Request failed with status %d" % provider_request.status_code)

            provider_json = provider_request.json()

            if provider_json.get("response"):
                return _render(provider, provider_json.get("response")[0])

            elif provider_json.get("states"):
                return _render(provider, provider_json.get("states")[0])

            elif provider_json.get("error"):
                message = provider_json["error"]["message"]

                print_log("Error: %s" % message)

                return render.Root(
                    child = render.WrappedText(message),
                )

            else:
                print_log("No flights found")

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

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "provider",
                name = "Provider",
                desc = "Provider",
                icon = "",
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

"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs Real-Time Flight Data API to find the flight overhead your location.
Author: Kyle Bolstad
"""

load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AIRLABS_URL = "https://airlabs.co/api/v9/flights"

def main(config):
    airlabs_api_key = config.get("airlabs_api_key")
    airlabs_bbox = config.get("airlabs_bbox")

    airlabs_ttl_seconds = 0
    if config.get("airlabs_ttl_seconds"):
        airlabs_ttl_seconds = re.sub("\\D", "", config.get("airlabs_ttl_seconds")) or 0
    airlabs_ttl_seconds = int(airlabs_ttl_seconds)

    timezone = config.get("timezone", "America/Chicago")
    disable_start_hour = config.get("disable_start_hour", "None")
    disable_end_hour = config.get("disable_end_hour", "None")
    now = time.now().in_location(timezone).hour

    def print_log(statement):
        if config.bool("print_log", False):
            print(statement)

    print_log(time.now())

    if disable_start_hour != "None" and disable_end_hour != "None":
        disable_start_hour = int(disable_start_hour)
        disable_end_hour = int(disable_end_hour)

        print_log("Disabling between %d:00 and %d:00" % (disable_start_hour, disable_end_hour))

        if disable_end_hour >= disable_start_hour:
            duration = disable_end_hour - disable_start_hour

        else:
            duration = (24 - disable_start_hour) + disable_end_hour

        if now >= disable_start_hour and now < disable_start_hour + duration:
            print_log("Disabled")

            return []

    airlabs_request = http.get("%s?api_key=%s&bbox=%s" % (AIRLABS_URL, airlabs_api_key, airlabs_bbox), ttl_seconds = airlabs_ttl_seconds)

    if airlabs_request.headers.get("Tidbyt-Cache-Status") == "HIT":
        print_log("Displaying cached data for %s seconds" % airlabs_ttl_seconds)

    else:
        print_log("Calling API")

    if airlabs_request.status_code != 200:
        fail("Request failed with status %d" % airlabs_request.status_code)

    airlabs_json = airlabs_request.json()

    if airlabs_json.get("response"):
        airlabs_response = airlabs_json["response"]

        if airlabs_response:
            airlabs_response = airlabs_response[0]

            print_log(airlabs_response)

            plane = "%s" % airlabs_response.get("reg_number")
            flight_plan = "No flight plan"
            location = "%dkt %dft" % (airlabs_response.get("speed") * 0.53995680345572, airlabs_response.get("alt") * 3.28)

            if airlabs_response.get("flight_number"):
                plane = "%s %s" % (airlabs_response.get("airline_iata"), airlabs_response.get("flight_number"))

            if airlabs_response.get("aircraft_icao"):
                plane += " (%s)" % airlabs_response.get("aircraft_icao")

            if airlabs_response.get("dep_iata"):
                flight_plan = "%s" % airlabs_response.get("dep_iata")

            if airlabs_response.get("arr_iata"):
                flight_plan += " - %s" % (airlabs_response.get("arr_iata"))

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

        else:
            print_log("No flights found")

            return []

    elif airlabs_json.get("error"):
        message = airlabs_json["error"]["message"]

        print_log("Error: %s" % message)

        return render.Root(
            child = render.WrappedText(message),
        )

    else:
        print_log("No flights found")

        return []

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
            schema.Text(
                id = "airlabs_api_key",
                name = "AirLabs API Key",
                desc = "AirLabs API Key",
                icon = "key",
            ),
            schema.Text(
                id = "airlabs_bbox",
                name = "AirLabs BBox",
                desc = "AirLabs Bounding box",
                icon = "locationArrow",
            ),
            schema.Text(
                id = "airlabs_ttl_seconds",
                name = "AirLabs TTL Seconds",
                desc = "Number of seconds to cache results",
                icon = "clock",
                default = "0",
            ),
            schema.Dropdown(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone",
                icon = "clock",
                default = "America/Chicago",
                options = timezones,
            ),
            schema.Dropdown(
                id = "disable_start_hour",
                name = "Disable Start Hour",
                desc = "Disable during certain timeframe",
                icon = "clock",
                default = "None",
                options = hours,
            ),
            schema.Dropdown(
                id = "disable_end_hour",
                name = "Disable End Hour",
                desc = "Disable during certain timeframe",
                icon = "clock",
                default = "None",
                options = hours,
            ),
            schema.Toggle(
                id = "print_log",
                name = "Print Log",
                desc = "Print log statements to help debug",
                icon = "bug",
                default = False,
            ),
        ],
    )

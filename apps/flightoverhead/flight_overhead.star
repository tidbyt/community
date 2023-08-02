"""
Applet: Flight Overhead
Summary: Finds flight overhead
Description: Uses AirLabs Real-Time Flight Data API to find the flight overhead your location.
Author: Kyle Bolstad
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

URL = "https://airlabs.co/api/v9/flights"

def main(config):
    api_key = config.get("api_key")
    bbox = config.get("bbox")
    timezone = config.get("timezone") or "America/Chicago"
    disable_start_hour = config.get("disable_start_hour") or 0
    disable_duration = config.get("disable_duration") or 0
    now = time.now().in_location(timezone).hour
    ttl_seconds = config.get("ttl_seconds") or 0

    if int(disable_duration) > 0 and now >= int(disable_start_hour) and now <= (int(disable_start_hour) + int(disable_duration)):
        print("Disabled")

        return []

    request = http.get("%s?api_key=%s&bbox=%s" % (URL, api_key, bbox), ttl_seconds = int(ttl_seconds))

    if request.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Displaying cached data for %s seconds." % ttl_seconds)
    else:
        print("Calling API.")

    if request.status_code != 200:
        fail("Request failed with status %d" % request.status_code)

    json = request.json()

    if json.get("response"):
        response = json["response"]

        if response:
            response = response[0]
            print(response)

            return render.Root(
                child = render.Box(
                    render.Column(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text("%s %s" % (response.get("airline_iata"), response.get("flight_number"))),
                            render.Text("%s - %s" % (response.get("dep_iata"), response.get("arr_iata"))),
                            render.Text("%dkts %dft" % (response.get("speed") * 0.53995680345572, response.get("alt") * 3.28)),
                        ],
                    ),
                ),
            )

        else:
            return []

    elif json.get("error"):
        return render.Root(
            child = render.WrappedText(json["error"]["message"]),
        )

    else:
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
        schema.Option(display = "0", value = "0"),
        schema.Option(display = "1", value = "1"),
        schema.Option(display = "2", value = "2"),
        schema.Option(display = "3", value = "3"),
        schema.Option(display = "4", value = "4"),
        schema.Option(display = "5", value = "5"),
        schema.Option(display = "6", value = "6"),
        schema.Option(display = "7", value = "7"),
        schema.Option(display = "8", value = "8"),
        schema.Option(display = "9", value = "9"),
        schema.Option(display = "10", value = "10"),
        schema.Option(display = "11", value = "11"),
        schema.Option(display = "12", value = "12"),
        schema.Option(display = "13", value = "13"),
        schema.Option(display = "14", value = "14"),
        schema.Option(display = "15", value = "15"),
        schema.Option(display = "16", value = "16"),
        schema.Option(display = "17", value = "17"),
        schema.Option(display = "18", value = "18"),
        schema.Option(display = "19", value = "19"),
        schema.Option(display = "20", value = "20"),
        schema.Option(display = "21", value = "21"),
        schema.Option(display = "22", value = "22"),
        schema.Option(display = "23", value = "23"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "AirLabs API Key",
                icon = "key",
            ),
            schema.Text(
                id = "bbox",
                name = "BBox",
                desc = "AirLabs Bounding box",
                icon = "locationArrow",
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
                default = "0",
                options = hours,
            ),
            schema.Dropdown(
                id = "disable_duration",
                name = "Disable Duration",
                desc = "Disable during certain timeframe",
                icon = "clock",
                default = "0",
                options = hours,
            ),
            schema.Text(
                id = "ttl_seconds",
                name = "TTL Seconds",
                desc = "Amount of time to cache results",
                icon = "clock",
                default = "0",
            ),
        ],
    )

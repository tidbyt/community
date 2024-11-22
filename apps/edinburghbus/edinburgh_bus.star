"""
Applet: Edinburgh Bus
Summary: Shows the next 3 buses
Description: Give it an Edinburgh stop ID and it will show the next 3 arrivals for the next 3 services at that stop.
Author: dan0
"""

# buildifier: disable=<category_name>

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_STOP = 6200201940
DEFAULT_DISPLAY_DESTINATIONS = False

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "Stop ID",
                desc = "Enter your preferred Stop ID.",
                icon = "bus",
            ),
            schema.Toggle(
                id = "display_destinations",
                name = "Show Bus Destinations",
                desc = "Show the final destination for each individual arrival for a service.",
                icon = "flag",
                default = False,
            ),
        ],
    )

def main(config):
    # Get stop ID from config or use the default stop ID
    stop_id = config.get("stop_id") or DEFAULT_STOP
    display_destinations = config.bool("display_destinations") or DEFAULT_DISPLAY_DESTINATIONS

    # Fetch bus information using the stop ID
    bus_info = fetch_bus_info(stop_id)

    # Get stop text and bus text for display
    stop_text = get_stop_text(bus_info)
    bus_text = next_buses(bus_info, display_destinations)

    font = config.get("font", "tb-8")

    def render_bus_row(row_info):
        service_name = "" if not row_info[0] else str(row_info[0])
        next_times_text = "" if not row_info[1] else str(row_info[1])

        return render.Row(
            children = [
                render.Box(
                    # Bus service number in red box
                    width = 16,
                    height = 8,
                    padding = 0,
                    color = "#8c1713",
                    child = render.Text(service_name, font = font, color = "#fff"),
                ),
                render.Box(
                    # Black dividing 1px row for padding
                    width = 1,
                    height = 8,
                    padding = 0,
                    color = "#000",
                ),
                render.Marquee(
                    # Marquee showing times of next buses for given service
                    width = 48,
                    child = render.Text(next_times_text, font = font, color = "#FCFCFC"),
                ),
            ],
        )

    def render_divider():
        return render.Box(
            width = 64,
            height = 1,
            color = "#333",
        )

    # Initialize an empty list for the children of the render.Column
    column_children = [
        render.Text(
            content = stop_text,
            color = "#ae9962",
            font = "CG-pixel-3x5-mono",
        ),
    ]

    # Loop through the first three elements of bus_text and add render_bus_row and render_divider for each element
    for bus_info in bus_text[:3]:
        column_children.append(render_divider())
        column_children.append(render_bus_row(bus_info))

    return render.Root(
        child = render.Column(
            children = column_children,
        ),
    )

def fetch_bus_info(stop_id):
    # Construct the URL using the provided stop_id
    url = "https://tfeapp.com/api/website/stop_times.php?stop_id=" + str(stop_id)
    bus_info_cached = cache.get("bus_stop_response")

    if bus_info_cached != None:
        # Grabbing json data from cache
        bus_info = json.decode(bus_info_cached)
    else:
        # Dang, no cached data.  Writing json to cache as string, 30 second TTL (it's live bus times...)
        response = http.get(url)
        if response.status_code != 200:
            # We need to fail, we have no cached data and no API response
            fail("API request failed with status %d", response.status_code)
        bus_info = response.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("bus_stop_response", json.encode(bus_info), ttl_seconds = 30)

    return bus_info

def time_left(minutes):
    # Return "Due" if the time left is 0 or negative, otherwise return the time left in minutes
    time_left_text = "Due" if minutes <= 0 else str(minutes) + "m"

    # if there are over 60 minutes return it in the format eg. 1h 15m
    if minutes > 60:
        time_left_text = str(minutes // 60) + "h " + str(minutes % 60) + "m"

    return time_left_text

def get_stop_text(data):
    # Format and return the stop name and direction as a string
    return data["stop"]["name"] + " " + data["stop"]["direction"]

def next_buses(data, display_destinations):
    # Initialize an empty list to store the formatted bus information
    lines = []

    # Iterate through the services in the data
    for service in data["services"]:
        line = []

        # Get the departures for each service
        next_three_departures = service["departures"]

        # Format the minutes until each departure
        minutes_list = []
        for departure in next_three_departures:
            readable_time = time_left(int(departure["minutes"]))
            if display_destinations:
                bus_text = "" + departure["destination"] + " " + readable_time
            else:
                bus_text = readable_time

            minutes_list.append(bus_text)

        line = [service["service_name"], " · ".join(minutes_list)]

        # Join the formatted minutes and add the result to the list
        lines.append(line)

    # Join the lines and return the result
    return lines

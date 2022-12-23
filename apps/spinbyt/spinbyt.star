"""
Applet: Spinbyt
Summary: Shows Spin scooters info
Description: App that shows the nearest Spin scooter, its battery level, and number of other nearby scooters. Includes a scooter icon.
Author: zachlucas
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("schema.star", "schema")
load("cache.star", "cache")

DEFAULT_URL = "https://gbfs.spin.pm/api/gbfs/v2_3/%s/free_bike_status"

DEFAULT_LOCATION = """
{
	"lat": "40.46049905272754",
	"lng": "-79.95109706964388",
	"description": "600 Grant St, Pittsburgh, PA, USA",
	"locality": "Pittsburgh",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

DEFAULT_CITY = "pittsburgh"

def main(config):
    # City from configuration:
    city = config.get("city", DEFAULT_CITY)
    url = DEFAULT_URL % city

    # Location (Lat/Lon) from configuration:
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    # Simple scooter image:
    scooter_image = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAHKADAAQAAAABAAAAHAAAAABkvfSiAAABO0lEQVRIDe2V0Q3CMAxEA2IMviokGIYdugd8lIpJwlR8dQNmKFzFBcdOWkErQIhIVZzkzi9OIXXuU8173+J5K/8d0BkrSlVXlmVYp25sn0yo4VOCk8C2Wnfv8lTsooKmAM+jjGogATJWsqeGBtjemjucQxKC9DEHwdgAwK7dj3VsPu03Fc5uzR02WjfZ2AAny5xJ9AdmDub16d8/0sXrh2OducuBlwccTwNzSS3+MQMPoVkgLm7v3agPMiCAbffHQDdACE5heTjgzqmsqiraJNYvy1WYiz5PgMHYNA39riiKLtaJg0AEGoaluq67Kuk3QAljLpgY53rCpDY1F/0PCYOJDwA05mB6vk8fAaWxzyR1qVhWqdfNj4aCPhM1socem9Qb1XnMu9EGJNUmCdKx9Kd8BogEQyYN+erxFYZIkUf9Flp2AAAAAElFTkSuQmCC")

    # Network Request to get the local scooter information
    # Uses the GBFS standard: https://github.com/MobilityData/gbfs/blob/v2.3/gbfs.md
    # First, let's check if we have cached response json:
    scooter_info_cached = cache.get("scooter_information")
    if scooter_info_cached != None:
        print("Cache hit, displaying cached scooter data.")
        rep = json.decode(scooter_info_cached)
    else:
        # Make the GET request
        print("Cache miss, calling Spin API.")
        rep = http.get(url)
        if rep.status_code != 200:
            fail("Spin request failed with status %d", rep.status_code)
        rep = rep.json()
        cache.set("scooter_information", json.encode(rep), ttl_seconds = 240)

    # Start with a super-far distance and no closest bike
    closest_distance = 100000
    closest_bike = None

    number_of_nearby_bikes = 0
    nearby_distance = 0.2 * 1.60934  # Bikes within 0.3 miles

    # Go through the bikes and find the closest one:
    for bike in rep["data"]["bikes"]:
        lat = float(bike["lat"])
        lon = float(bike["lon"])
        bike_distance = distance((float(loc["lat"]), float(loc["lng"])), (lat, lon))

        if bike_distance < closest_distance:
            closest_distance = bike_distance
            closest_bike = bike

        if bike_distance <= nearby_distance:
            number_of_nearby_bikes += 1

    # Now that we have the closest bike, get the battery percentage
    # The max range is 19,200 meters, so use that to figure out the battery percentage:
    # Max range is found in the scooter type response here:
    #  https://gbfs.spin.pm/api/gbfs/v2_3/{city}/vehicle_types
    closest_bike_battery_percentage = closest_bike["current_range_meters"] / 19200.0
    battery_width = int(24 * closest_bike_battery_percentage)

    # Convert distance to miles for display:
    closest_distance *= 0.621371

    # Battery UI stack:
    battery_background_color = "#555"
    battery_stack = render.Stack(
        children = [
            render.Box(width = 24, height = 2, color = "#222"),
            render.Box(width = battery_width, height = 2, color = "#0f0"),
        ],
    )

    battery_column = render.Column(
        children = [
            render.Box(width = 24, height = 1, color = battery_background_color),
            battery_stack,
            render.Box(width = 24, height = 1, color = battery_background_color),
        ],
    )

    full_battery = render.Row(
        expanded = True,  # Use as much horizontal space as possible
        main_align = "center",  # Controls horizontal alignment
        cross_align = "center",  # Controls vertical alignment
        children = [
            render.Box(width = 1, height = 2, color = battery_background_color),
            render.Box(width = 1, height = 4, color = battery_background_color),
            battery_column,
            render.Box(width = 1, height = 4, color = battery_background_color),
            render.Box(width = 1, height = 2, color = battery_background_color),
        ],
    )

    # Scooter and battery UI box:
    scooter_and_battery_box = render.Column(
        children = [
            render.Image(src = scooter_image),
            full_battery,
        ],
    )

    distance_string = ("%f" % closest_distance)[:5]
    closest_bike_box = render.Column(
        children = [
            render.Text("Closest:"),
            render.Text(distance_string + " mi"),
            render.Box(width = 34, height = 1, color = "#555"),
            render.Text("Nearby:"),
            render.Text("%d" % number_of_nearby_bikes),
        ],
    )

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        closest_bike_box,
                        scooter_and_battery_box,
                    ],
                ),
            ],
        ),
    )

def get_schema():
    city_options = [
        schema.Option(
            display = "Pittsburgh",
            value = "pittsburgh",
        ),
        schema.Option(
            display = "Washington, D.C.",
            value = "washington_dc",
        ),
        schema.Option(
            display = "Baltimore",
            value = "baltimore",
        ),
        schema.Option(
            display = "Minneapolis",
            value = "minneapolis",
        ),
        schema.Option(
            display = "Chicago",
            value = "chicago",
        ),
        schema.Option(
            display = "Omaha",
            value = "omaha",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location used to check for nearby scooters and bikes.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "city",
                name = "City",
                desc = "The city for which to search for scooters and bikes.",
                icon = "city",
                default = city_options[0].value,
                options = city_options,
            ),
        ],
    )

# Distance in km, from Stack Overflow.
def distance(origin, destination):
    """
    Calculate the Haversine distance.

    Parameters
    ----------
    origin : tuple of float
        (lat, long)
    destination : tuple of float
        (lat, long)

    Returns
    -------
    distance_in_km : float

    Examples
    --------
    >>> origin = (48.1372, 11.5756)  # Munich
    >>> destination = (52.5186, 13.4083)  # Berlin
    >>> round(distance(origin, destination), 1)
    504.2
    """
    lat1, lon1 = origin
    lat2, lon2 = destination
    radius = 6371  # km

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) * math.sin(dlon / 2))
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    d = radius * c

    return d

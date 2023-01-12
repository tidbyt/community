"""
Applet: Traffic
Summary: Time to your destination
Description: Shows your estimated travel duration using traffic information from Bing/MapQuest.
Author: Rob Kimball
Honorable Mention: LukiLeu, for the inspiration with Google Traffic
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BING_URL = "http://dev.virtualearth.net/REST/v1"
MQ_URL = "http://www.mapquestapi.com"
ORS_URL = "https://api.openrouteservice.org"

BASE_CACHE = "traffic"
CACHE_TTL = {
    "location": 60 * 60 * 365,  # locations are very unlikely to change coorindates, so we'll keep these for 1 year
    "directions": 60 * 5,  # to reduce API load, we'll only request directions every 5 minutes
    "bing": 60 * 15,  # Bing Maps allows 125k transactions annually before we're billed, so we'll cache slightly longer
}

DEFAULT_FONT = "tb-8"
COMPACT_FONT = "tom-thumb"
# The use of two fonts here means we won't have to Marquee the origin/destination labels until they are very long

RATIO_COLORS = {
    0.0: "#090",
    1.1: "#CC0",
    1.4: "#F50",
    2.0: "#900",
}
# When we are able to get both typical travel times, and a time including traffic, we can calculate the ratio and change
# the color of the duration text based on how much higher it is. We can safely assume that it will never be lower than 1,
# We change from green to white when the time is 20% higher, white to yellow if it exceeds +70%, and finally we'll display
# the time in red if we estimate the trip will be twice as long as it would be without traffic.

SAMPLE_DATA = {
    "coordinates": {
        "origin": ("40.644461105185385", "-73.78255247613296"),  # Kennedy Airport
        "destination": ("40.771771628998565", "-73.97485055572092"),  # Central Park
        # "origin": ("47.378954", "8.535667"),  # Zurich, CHE
        # "destination": ("47.165775", "8.516988"),  # Zug, CHE
    },
    "labels": {
        "origin": "JFK Airport",
        "destination": "Central Park",
        # "origin": "Zurich",
        # "destination": "Zug",
    },
    # These times were calculated using ORS in a traffic-less vacuum, for entertainment purposes only.
    "time_to_destination": {
        "Driving": time.parse_duration("994.7s"),
        "Transit": time.parse_duration("3120.1s"),
        "fastest": time.parse_duration("994.7s"),
        "shortest": time.parse_duration("994.7s"),
        "driving-car": time.parse_duration("994.7s"),
        "driving-hgv": time.parse_duration("1058.1s"),
        "bicycle": time.parse_duration("2259.8s"),
        "cycling-road": time.parse_duration("1743.2s"),
        "cycling-regular": time.parse_duration("2259.8s"),
        "cycling-mountain": time.parse_duration("1960.1s"),
        "cycling-electric": time.parse_duration("1843.6s"),
        "pedestrian": time.parse_duration("5601.3s"),
        "wheelchair": time.parse_duration("6517.7s"),
        "foot-hiking": time.parse_duration("6352.5s"),
        "foot-walking": time.parse_duration("5601.3s"),
    },
}

# Values match "travelMode" parameter
BING_MODES = {
    "Driving": "Driving",
    "Transit": "Transit",
    # MapQuest is preferred here:
    # "Walking": "Walking",
}

ORS_MODES = {
    # We'll use MapQuest for these modes
    # "Car": "driving-car",
    # "Bike": "cycling-regular",
    # "Walking": "foot-walking",  # this mode includes ferries by default but not other forms of public transit
    "Hiking": "foot-hiking",
    "Wheelchair": "wheelchair",
    "Road bike": "cycling-road",
    "E-Bike": "cycling-electric",
    "Mountain bike": "cycling-mountain",
    # "Truck (LGV)": "driving-hgv",  # This isn't useful unless we allow people to specify the dimensions of the truck
}

# "routeType" parameter
MQ_MODES = {
    "Driving - Fastest": "fastest",
    "Driving - Shortest": "shortest",
    "Walking": "pedestrian",
    "Bike": "bicycle",
}

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def bing_reverse_geo(coordinates, key):
    """
    Reverse-search a pair of GPS coordinates using Bing to return the name, region and state/province of a location.

    We also round coordinates to 4 decimal places (precision to 11.1 meters) and cache the results for a year.

    :param coordinates: tuple of lat/lon as floats
    :param key: string, Bing API Key
    :return: tuple of address parts as strings
    """
    coordinates = [round(float(coordinates[0]), 4), round(float(coordinates[1]), 4)]

    location = ",".join((str(coordinates[0]), str(coordinates[1])))
    cache_id = "%s/geo/%s" % (BASE_CACHE, str(coordinates))

    data = cache.get(cache_id)

    if data:
        print("Returning cached address from %s" % cache_id)
        address_parts = json.decode(data)
    else:
        req_url = "%s/Locations/%s?key=%s" % (BING_URL, location, key)
        print("Requesting address from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200 or response.get("statusCode", False) != 200:
            print("API Failure: %s" % response.get("statusDescription", "No error message provided"))
            return None
        else:
            resources = []
            resource_sets = response.get("resourceSets", [])
            if len(resource_sets):
                resources = resource_sets[0].get("resources", [])
            if not len(resources):
                print("Uncaught parsing exception, no results: %s" % response)
                return None

            # I'm feeling lucky:
            first = resources[0]

            # We'll return address parts in a tuple and match the parts between origin/destination; we can then only
            # display the more broad information if parts don't match (i.e. traveling between cities or countries)
            address_parts = [first["address"].get(item, None) for item in ["addressLine", "locality", "adminDistrict", "countryRegion"]]
            cache.set(cache_id, json.encode(address_parts), ttl_seconds = CACHE_TTL["location"])

    return address_parts

def mq_reverse_geo(coordinates, key):
    """
    Reverse-search a pair of GPS coordinates using MapQuest to return the name, region and state/province of a location.

    We also round coordinates to 4 decimal places (precision to 11.1 meters) and cache the results for a year.

    :param coordinates: tuple of lat/lon as floats
    :param key: string, MapQuest API Key
    :return: tuple of address parts as strings
    """
    coordinates = [round(float(coordinates[0]), 4), round(float(coordinates[1]), 4)]

    location = ",".join((str(coordinates[0]), str(coordinates[1])))
    cache_id = "%s/geo/%s" % (BASE_CACHE, str(coordinates))

    data = cache.get(cache_id)

    if data:
        print("Returning cached address from %s" % cache_id)
        address_parts = json.decode(data)
    else:
        req_url = "%s/search/v2/radius?key=%s&origin=%s" % (MQ_URL, key, location)
        print("Requesting directions from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200 or response.get("info", {}).get("statusCode", False) != 0:
            print("API Failure: %s" % response.get("error", "No error message provided"))
            return None
        else:
            results = response.get("searchResults", [])

            if not len(results):
                return None

            # I'm feeling lucky:
            first = results[0]

            # We'll return address parts in a tuple and match the parts between origin/destination; we can then only
            # display the more broad information if parts don't match (i.e. traveling between cities or countries)
            address_parts = [first["fields"].get(item, None) for item in ["address", "city", "state", "country"]]
            cache.set(cache_id, json.encode(address_parts), ttl_seconds = CACHE_TTL["location"])

    return address_parts

def ors_reverse_geo(coordinates, key):
    """
    Reverse-search a pair of GPS coordinates using MapQuest to return the name, region and state/province of a location.

    We also round coordinates to 4 decimal places (precision to 11.1 meters) and cache the results for a year.

    :param coordinates: tuple of lat/lon as floats
    :param key: string, OpenRouteService API Key
    :return: tuple of address parts as strings
    """
    coordinates = [round(float(coordinates[0]), 4), round(float(coordinates[1]), 4)]
    lat, lon = str(coordinates[0]), str(coordinates[1])
    cache_id = "%s/geo/%s" % (BASE_CACHE, str(coordinates))

    data = cache.get(cache_id)

    if data:
        print("Returning cached address from %s" % cache_id)
        address_parts = json.decode(data)
    else:
        req_url = "%s/geocode/reverse?api_key=%s&point.lat=%s&point.lon=%s" % (ORS_URL, key, lat, lon)
        print("Requesting data from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200:
            print("API Failure: %s" % response.get("error", "No error message provided"))
            return None
        else:
            results = response.get("features", [])

            if not len(results):
                return None

            # I'm feeling lucky:
            first = results[0]

            # We'll return address parts in a tuple and match the parts between origin/destination; we can then only
            # display the more broad information if parts don't match (i.e. traveling between cities or countries)
            address_parts = [first["properties"].get(item, None) for item in ["name", "locality", "region", "country_a"]]
            cache.set(cache_id, json.encode(address_parts), ttl_seconds = CACHE_TTL["location"])

    return address_parts

def ors_directions(origin, destination, mode, key, **kwargs):
    """
    Build URL and request data from the OpenRouteService API for travel time with different modes of transportation.
    ORS is interesting due to the wide array of different modes it supports. While the driving directions are not
    very useful since they assume empty streets, the travel time for walking/mountain biking/wheelchairs should be
    unaffected by the absence of this data. However, a key benefit is the data is 100% community-supported!

    Since we use the Bing/ORS/MapQuest direction functions interchangeably, the function signatures must match!

    :param origin: tuple of coordinates for the journey origin, (lng, lat)
    :param destination: tuple of coordinates for the destination, (lng, lat)
        Note that for both the origin and the destination we have to invert the tuple - the API receives them backwards!
    :param mode: str, ORS-recognized codes for profiles ("driving-car", "foot-walking", "road-bike", etc.)
        See the docs for details: https://openrouteservice.org/dev/#/api-docs/v2/directions/{profile}/get
    :param key: ORS API key as a string
    :param kwargs: optional arguments that are relevant to the MapQuest Directions API
        See the docs for details: https://openrouteservice.org/dev/#/api-docs/v2/directions/{profile}/get
    :return: tuple, the travel time with traffic and travel time without
    """

    # ORS uses lng,lat instead of lat,lng:
    start = ",".join((str(origin[1]), str(origin[0])))
    end = ",".join((str(destination[1]), str(destination[0])))
    cache_id = "%s/travel_time/%s/%s/%s/%s" % (BASE_CACHE, mode, start, end, json.encode(kwargs))

    data = cache.get(cache_id)

    if data:
        print("Returning cached data from %s" % cache_id)
        data = json.decode(data)
    else:
        req_url = "%s/v2/directions/%s?api_key=%s&start=%s&end=%s" % (ORS_URL, mode, key, start, end)
        print("Requesting directions from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200:
            print("API Failure: %s" % response.get("error", "No error message provided"))

            msg = {
                400: "Tidbyt app error (400)",
                401: "Access unauthorized with this API key",
                403: "Access forbidden with this API key",
                # 404: "",  # in this case the response error will have more specific information
                405: "Tidbyt app error (405)",
                413: "Too far!",
                # 500: "",  # in this case the response error will have more specific information
                501: "Feature not supported (501).",
                503: "OCS unavailable, check again later (503).",
            }.get(request.status_code, response.get("error").get("message"))

            return msg, None

        else:
            data = response
            cache.set(cache_id, json.encode(response), ttl_seconds = CACHE_TTL["directions"])

    features = data.get("features", [{}])[0]
    properties = features.get("properties", {})
    summary = properties.get("summary", {})

    time_retrieved = time.from_timestamp(int(data.get("metadata", {}).get("timestamp", None)))

    print("Returning directions from %s to %s, estimated time %d vs. %d. (Retrieved %s)" % (start, end, summary.get("duration", 0), summary.get("duration", 1), time_retrieved))

    # Have to return the same time twice here since ORS has no traffic info to create variance
    return summary.get("duration", 0), summary.get("duration", 1)

def mq_directions(origin, destination, mode, key, **kwargs):
    """
    Build URL and request data from the MapQuest API for travel time with different modes of transportation.
    The key advantage here over ORS is the presence of traffic data which we can use to display a more accurate
    prediction of the travel time, as well as the "zero traffic" travel time which we can use to display how bad the
    traffic is on a relative basis.

    Since we use the Bing/ORS/MapQuest direction functions interchangeably, the function signatures must match!

    :param origin: tuple of coordinates for the journey origin, (lng, lat)
    :param destination: tuple of coordinates for the destination, (lng, lat)
    :param mode: str, MapQuest-recognized codes for routeTypes ("fastest", "shortest", "bicycle", "pedestrian")
    :param key: MapQuest API key as a string
    :param kwargs: optional arguments that are relevant to the MapQuest Directions API
        See the docs for details: https://developer.mapquest.com/documentation/directions-api/route/get/
    :return: tuple, the travel time with traffic and travel time without
    """
    start = ",".join((str(origin[0]), str(origin[1])))
    end = ",".join((str(destination[0]), str(destination[1])))
    cache_id = "%s/travel_time/%s/%s/%s/%s" % (BASE_CACHE, mode, start, end, json.encode(kwargs))

    data = cache.get(cache_id)

    if data:
        print("Returning cached data from %s" % cache_id)
        data = json.decode(data)
    else:
        req_url = "%s/directions/v2/optimizedroute?routeType=%s&key=%s&from=%s&to=%s&doReverseGeocode=false" % (
            MQ_URL,
            mode,
            key,
            start,
            end,
        )
        if len(kwargs.get("avoids", [])):
            req_url += "&avoids=" + ",".join([a.replace(" ", "%20") for a in kwargs["avoids"]])
        if kwargs.get("no_hills", False):
            req_url += "&roadGradeStrategy=AVOID_ALL_HILLS"
        if kwargs.get("prefer_bike_lanes", False):
            req_url += "&cyclingRoadFactor=50"

        print("Requesting directions from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200 or response.get("info", {}).get("statuscode", False) != 0:
            print("API Failure: %s" % response.get("error", "No error message provided"))
            msg = ";".join(response.get("info").get("messages", []))
            return msg, None
        else:
            data = response
            cache.set(cache_id, json.encode(response), ttl_seconds = CACHE_TTL["directions"])

    travel_time = int(data.get("route", {}).get("time", None))
    travel_time_with_traffic = int(data.get("route", {}).get("realTime", None))

    # This indicates some kind of data issue that we'll override with traffic-naive duration.
    if travel_time_with_traffic in (-1, 10000000):
        travel_time_with_traffic = travel_time

    print("Returning directions from %s to %s, estimated time %d vs. %d" % (start, end, travel_time_with_traffic, travel_time))
    return travel_time_with_traffic, travel_time

def bing_directions(origin, destination, mode, key, **kwargs):
    """
    Build URL and request data from the Bing Maps API for travel time with different modes of transportation.
    The key advantage here over MapQuest is international traffic coverage, while MapQuest allows more API calls but
    only has coverage in select regions (primarily US).

    Since we use the Bing/ORS/MapQuest direction functions interchangeably, the function signatures must match!

    :param origin: tuple of coordinates for the journey origin, (lng, lat)
    :param destination: tuple of coordinates for the destination, (lng, lat)
    :param mode: str, Bing-recognized codes for routeTypes ("Driving", "Walking", "Transit")
    :param key: Bing API key as a string
    :param kwargs: optional arguments that are relevant to the Bing Routes API endpoint
        See the docs for details: https://docs.microsoft.com/en-us/bingmaps/rest-services/routes/calculate-a-route
    :return: tuple, the travel time with traffic and travel time without
    """
    start = ",".join((str(origin[0]), str(origin[1])))
    end = ",".join((str(destination[0]), str(destination[1])))
    cache_id = "%s/travel_time/%s/%s/%s/%s" % (BASE_CACHE, mode, start, end, json.encode(kwargs))

    data = cache.get(cache_id)

    if data:
        print("Returning cached data from %s" % cache_id)
        data = json.decode(data)
    else:
        req_url = "%s/Routes/%s?key=%s&wayPoint.1=%s&wayPoint.2=%s" % (
            BING_URL,
            mode,
            key,
            start,
            end,
        )
        if mode == "Driving":
            req_url += "&optimize=timeWithTraffic"
        if len(kwargs.get("avoids", [])):
            req_url += "&avoid=" + ",".join([a.replace(" ", "%20") for a in kwargs["avoids"]])

        print("Requesting directions from API: %s" % req_url)

        request = http.get(req_url)
        response = request.json()

        if request.status_code != 200 or response.get("statusCode", False) != 200:
            print("API Failure: %s" % response.get("statusDescription", "No error message provided"))
            msg = ";".join(response.get("errorDetails", []))
            return msg, None
        else:
            data = response
            cache.set(cache_id, json.encode(response), ttl_seconds = CACHE_TTL["bing"])

    resources = []
    resource_sets = data.get("resourceSets", [])
    if len(resource_sets):
        resources = resource_sets[0].get("resources", [])
    if len(resources):
        route = resources[0]
        travel_time = int(route.get("travelDuration", None))
        travel_time_with_traffic = int(route.get("travelDurationTraffic", None))
    else:
        travel_time, travel_time_with_traffic = None, None

    # This indicates some kind of data issue that we'll override with traffic-naive duration.
    if travel_time_with_traffic in (-1, 0):
        travel_time_with_traffic = travel_time

    print("Returning directions from %s to %s, estimated time %d vs. %d" % (start, end, travel_time_with_traffic, travel_time))
    return travel_time_with_traffic, travel_time

def duration_to_string(sec):
    """
    Builds a prettier duration display from the total seconds than what is natively available in Go.
    This function was contributed by LukiLeu in the original Google Traffic app, which was sadly retired.

    :param sec: numeric type, total seconds of the trip duration
    :return: string, formatted result like "3d 1h 34m"
    """
    seconds_in_day = 60 * 60 * 24
    seconds_in_hour = 60 * 60
    seconds_in_minute = 60

    days = sec // seconds_in_day
    hours = (sec - (days * seconds_in_day)) // seconds_in_hour
    minutes = (sec - (days * seconds_in_day) - (hours * seconds_in_hour)) // seconds_in_minute

    time_string = ""
    if minutes > 0:
        time_string = "%im %s" % (minutes, time_string)
    if hours > 0:
        time_string = "%ih %s" % (hours, time_string)
    if days > 0:
        time_string = "%id %s" % (days, time_string)

    return time_string

def main(config):
    bing_key = config.get("bing_auth", None)
    ors_key = config.get("ors_auth", None)
    mq_key = config.get("mq_auth", None)
    mode = config.get("mode", MQ_MODES["Bike"])

    key = None
    if mode in ORS_MODES.values():
        directions = ors_directions
        key = ors_key
        service = "ORS"
    elif mode in MQ_MODES.values():
        directions = mq_directions
        key = mq_key
        service = "MapQuest"
    else:
        directions = bing_directions
        key = bing_key
        service = "Bing"

    search_key = None
    reverse_search = lambda *_: None

    # The reverse geo results from Bing/ORS are actually a little better than MapQuest, we'll take those unless we can't
    if ors_key:
        reverse_search = ors_reverse_geo
        search_key = ors_key
    elif bing_key:
        reverse_search = bing_reverse_geo
        search_key = bing_key
    elif mq_key:
        reverse_search = mq_reverse_geo
        search_key = mq_key

    data = SAMPLE_DATA

    origin = data["coordinates"]["origin"]
    destination = data["coordinates"]["destination"]

    origin_name = data["labels"]["origin"]
    destination_name = data["labels"]["destination"]

    # Adding an asterisk to indicate that this is sample data
    travel_time = "* " + duration_to_string(data["time_to_destination"][mode].seconds) + "*"

    duration_color = "#FFF"
    cfg_origin = json.decode(config.get("origin", "{}"))
    cfg_destination = json.decode(config.get("destination", "{}"))

    # FOR TESTING PURPOSES:
    # cfg_origin, cfg_destination = True, True

    if key and cfg_origin and cfg_destination:
        # COMMENT OUT FOR TESTING:
        origin = (cfg_origin.get("lat"), cfg_origin.get("lng"))
        destination = (cfg_destination.get("lat"), cfg_destination.get("lng"))

        origin_name = config.get("origin_label", None)
        destination_name = config.get("destination_label", None)

        if not origin_name:
            origin_name = reverse_search(origin, search_key)
            if not origin_name:
                origin_name = "Start"
        if not destination_name:
            destination_name = reverse_search(destination, search_key)
            if not destination_name:
                destination_name = "End"

        if type(origin_name) == type(destination_name) and type(origin_name) == "list":
            compare = list(zip(origin_name, destination_name))
            different = []
            for o, d in compare:
                if o != d:
                    different.append((o, d))
            origin_name, destination_name = zip(*different)
            origin_name = ", ".join(origin_name)
            destination_name = ", ".join(destination_name)
        elif type(origin_name) == "list":
            origin_name = ", ".join(origin_name)
        elif type(destination_name) == "list":
            destination_name = ", ".join(destination_name)

        avoid_configs = dict()
        if service == "MapQuest":
            avoid_configs = {
                "avoid_bandt": ["Bridge", "Tunnel"],
                "avoid_ferry": ["Ferry"],
                "avoid_tolls": ["Toll Road"],
                "avoid_unpaved": ["Unpaved"],
                "avoid_highways": ["Limited Access"],
            }
        elif service == "Bing":
            avoid_configs = {
                "avoid_ferry": ["ferry"],
                "avoid_tolls": ["tolls"],
                # Minimize instead of remove since we still want the routing to succeed if we can't do without it
                "avoid_highways": ["minimizeHighways"],
            }
        avoids = []
        for cfg_key, features in avoid_configs.items():
            if config.bool(cfg_key):
                avoids.extend(features)

        no_hills = config.bool("avoid_hills")
        prefer_bike_lanes = config.bool("prefer_bike_lanes")

        raw_time, no_traffic = directions(
            # tuples of GPS coordinates
            origin,
            destination,
            mode,  # must correspond to a key known by the API being queried
            key,  # API key
            # MQ-specific settings:
            avoids = avoids,
            no_hills = no_hills,
            prefer_bike_lanes = prefer_bike_lanes,
        )
        print("Got", raw_time, no_traffic)
        if not no_traffic:
            travel_time = raw_time  # This is actually an error message now
        elif service != "ORS":
            ratio = raw_time / no_traffic

            for threshold, color in RATIO_COLORS.items():
                if ratio > threshold:
                    duration_color = color
                else:
                    break
        if no_traffic:
            travel_time = time.parse_duration("%ds" % raw_time)
    elif key and not cfg_origin:
        travel_time = "We need a starting point! Check your settings."
    elif key and not cfg_destination:
        travel_time = "We need a destination! Check your settings."
    elif not key and cfg_origin and cfg_destination:
        travel_time = "%s API key required." % service

    if type(travel_time) == "time.duration":
        travel_time = duration_to_string(travel_time.seconds)

    origin_font = COMPACT_FONT if len(origin_name) >= 10 else DEFAULT_FONT
    destination_font = COMPACT_FONT if len(destination_name) >= 10 else DEFAULT_FONT

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_around",
                    children = [
                        render.Image(PIN_ICON),
                        render.Marquee(
                            width = 50,
                            child = render.Text(str(origin_name), font = origin_font),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_around",
                    children = [
                        render.Image(FLAG_ICON),
                        render.Marquee(
                            width = 50,
                            child = render.Text(str(destination_name), font = destination_font),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_around",
                    children = [
                        render.Image(MODE_ICONS[mode]),
                        render.Marquee(
                            width = 50,
                            child = render.Text(
                                str(travel_time),
                                font = DEFAULT_FONT,
                                color = duration_color,
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Mode of Transport",
                desc = "",
                icon = "car",
                options = [
                    schema.Option(value = v, display = k + " (Bing)")
                    for k, v in BING_MODES.items()
                ] + [
                    schema.Option(value = v, display = k + " (MapQuest)")
                    for k, v in MQ_MODES.items()
                ] + [
                    schema.Option(value = v, display = k + " (ORS)")
                    for k, v in ORS_MODES.items()
                ],
                default = MQ_MODES["Bike"],
            ),
            schema.Text(
                id = "origin_label",
                name = "Origin label",
                desc = "Optional, if you don't provide a label we'll use the address instead.",
                icon = "locationDot",
                default = "",
            ),
            schema.Location(
                id = "origin",
                name = "Origin",
                desc = "Origin adress",
                icon = "locationCrosshairs",
            ),
            schema.Text(
                id = "destination_label",
                name = "Destination label",
                desc = "Optional, if you don't provide a label we'll use the address instead.",
                icon = "flag",
                default = "",
            ),
            schema.Location(
                id = "destination",
                name = "Destination",
                desc = "Destination adress",
                icon = "locationCrosshairs",
            ),
            schema.Toggle(
                id = "avoid_highways",
                name = "Avoid highways",
                desc = "Limited access roads will be deprioritized",
                icon = "road",
                default = False,
            ),
            schema.Toggle(
                id = "avoid_tolls",
                name = "Avoid toll roads",
                desc = "Toll roads will be deprioritized",
                icon = "dollarSign",
                default = False,
            ),
            schema.Toggle(
                id = "avoid_bandt",
                name = "Avoid bridges & tunnels",
                desc = "Bridges and tunnels will be avoided if possible",
                icon = "archway",
                default = False,
            ),
            schema.Toggle(
                id = "avoid_ferry",
                name = "No ferries",
                desc = "Routes will not include ferries",
                icon = "anchor",
                default = False,
            ),
            schema.Toggle(
                id = "avoid_unpaved",
                name = "Avoid unpaved roads",
                desc = "Routes will avoid unpaved roads.",
                icon = "tree",
                default = True,
            ),
            schema.Toggle(
                id = "avoid_hills",
                name = "Avoid hilly routes",
                desc = "Routing will prefer flat routes to hilly ones.",
                icon = "stairs",
                default = True,
            ),
            schema.Toggle(
                id = "prefer_bike_lanes",
                name = "Bike-friendly roads",
                desc = "Routes will prioritize roads with bike lanes.",
                icon = "personBiking",
                default = True,
            ),
            schema.Text(
                id = "bing_auth",
                name = "Bing Maps API Key",
                desc = "Enter your API Key from bingmapsportal.com/Application. Bringing your own key means all Tidbyt owners can use this app!",
                icon = "userGear",
                default = "",
            ),
            schema.Text(
                id = "mq_auth",
                name = "MapQuest API Consumer Key",
                desc = "Enter your free or paid API Key from mapquestapi.com. Bringing your own key means all Tidbyt owners can use this app!",
                icon = "userGear",
                default = "",
            ),
            schema.Text(
                id = "ors_auth",
                name = "OpenRouteService Free API Key",
                desc = "Enter your free API Key from openrouteservice.org. Bringing your own key means all Tidbyt owners can use this app!",
                icon = "userGear",
                default = "",
            ),
        ],
    )

FLAG_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAHhJREFUKFNj/H/20n9GYz1GBgKA8Wlx8f+HW7cy8LKzg5V+/vkTRQtIXPfiRUawwksrVzLw8/CAFXz88gXOhumwunEDoRAkCFIMUggDML7nkyeYCmGmIttPlEKQqVitBjn+ydu3YANh7gYrnDdv3v+kpCTCwUN1hQDajk8L9CuJKgAAAABJRU5ErkJggg==""")

PIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAH9JREFUKFNjZEACVxkY/sO42gwMjMhycA5I0SMZGbic3JMnDMiKwQphijw2bmNgkJNhYHj0hGGHvxcDsmKwwu0yMmArPc5fYmAQEWRgePOeYYehHth0zydPwGpQFaKZiKEQ3X0wh2JYjexObIrgVsMkYSaj+5h8hTAnoAc2SBwAWAA5CwcOk+IAAAAASUVORK5CYII=""")

BIKE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAHZJREFUKFNjZCASMBKpjgGuMCSv6j9M05pJbWDxhNpuuBiKicc0NOASME1WN24wgjSAFf7/////cU1NBpAgiA/SYHn9OgNIDEQzggBIEYhGlgRpQNYMVoOsEGQazFSYOMxGuNUgAZDJyKEAUgwVR/iaUDARHY4AjrtI0FBsjcUAAAAASUVORK5CYII=""")

EBIKE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIFJREFUKFNjZCASMBKpjgGuMCSv6j9M05pJbWDxhNpuuBiKiYrTPsMlYJruZ/GC1YCJ/////1ea/oUBJgjScC+ThwEkBqIZQQCkiOEQB4PS1TdgQZgGmOZ72iIMDHY/GOAKQSaDFMNMhRkAdgJIIcxqsDsYGVHcDFYMFSc9eAiFJwBxuUFqGPJnQwAAAABJRU5ErkJggg==""")

MTNBIKE_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAHhJREFUKFNjZCASMBKpjgFFYUhe1X+QxjWT2sDiCbXdYP6C5lJGDBN91geAJUFgS+AGuDyYMW/ePLDkOsFNcEmQhqD3fmANSUlJjIwgRSAGTAKdDTMIrhAkALMWZCXMALhCZKtBpiGHAsxJYKv9TPTgjscXVESHIwCT6UBs1TrXkQAAAABJRU5ErkJggg==""")

CAR_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAKxJREFUKFNjZCASMCKrO6ah8R9dn9WNG2A1cIUgRW/3XmHI2/idYekkUwbbxjMMh+tNwPpAisEKQYp2r7nE0HT1F1gCpACkEMaGK9wuI/Pfc8EOuK3bEzwYYHww+8kTRkaQIkL+4efhYWD8f5D9v3qhIVztgm8fwOwELgG42M3+8wyM8+bN+98xZRZDRU4aA4wGqUAXA3tGzcgCbv2tcyewijFOWLKOoBtBhgEAPI5MoAfdihMAAAAASUVORK5CYII=""")

TRAIN_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAHZJREFUKFNjZICCefPm/YexkemkpCRGEB9M4FIE0wBSzLhh31GsJqGbDlZYmZ3C8OPHD4b+uUsYwpJbwWpWza1mQBYHKyxMjgFLoitEFmfkdV+IYvXPWyvBmtjVwlFsJ14h0Z4hOnhgDvn/2vo/o+hRcLhiEwMAfc5Cuz9XduwAAAAASUVORK5CYII=""")

BIKE_ICON2 = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAP0lEQVQY042NsQ2AQBDDYjqWYMTbvzMNBR9AwtUpUXzJX1TU3Ysul/B+b0kC0MXD0CbVmTlQBej1kr2pP981J/H6Q0DDzqOfAAAAAElFTkSuQmCC""")

WALK_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAQ0lEQVQY03WNQRLAMAgC2U7//2IjvTQd41huwCpS01rLtr391YGIOPwBZKZtC2BnSFJ9+RUvRA07CHBrUJ0Yr6fJXz3cmSHnOt8PoAAAAABJRU5ErkJggg==""")

WHEELCHAIR_ICON = base64.decode("""iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAIVJREFUKFNjZEAC/////w/jMjIyMiLLoXCIVggyAaQY3TSQOIqJIAGf9QFg6zcHrGdA1gBXCDJph6wsw9TJJgxbAjdgGAAWgCnyfPKEkXnlF7CJf8N5MD2DrBCkCKYYWQOGibAg2S4j89+n9wbDnzBusFsx3AhT6PH4MVjB/4PsYKcQHY4AQ3FH0Sv7jXEAAAAASUVORK5CYII=""")

MODE_ICONS = {
    "Driving": CAR_ICON,
    "fastest": CAR_ICON,
    "shortest": CAR_ICON,
    "driving-car": CAR_ICON,
    "Transit": TRAIN_ICON,
    "pedestrian": WALK_ICON,
    "foot-hiking": WALK_ICON,
    "bicycle": BIKE_ICON,
    "cycling-regular": BIKE_ICON,
    "cycling-electric": EBIKE_ICON,
    "wheelchair": WHEELCHAIR_ICON,
    "cycling-road": BIKE_ICON,
    "cycling-mountain": MTNBIKE_ICON,
}

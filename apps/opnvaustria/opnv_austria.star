load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """{
    "lat": "48.185051",
    "lng": "16.377473",
	"description": "Wien, Austria",
	"locality": "Wien HBF",
	"timezone": "Europe/Zurich"
}"""

UNDERLINE = [(0, 0), (1, 0)]

BASE_REST_CALL = """https://routenplaner.verkehrsauskunft.at/vao/restproxy/v1.6.0/{endpoint}?accessId={api_key}&format=json"""

def main(config):
    """main app function

    Args:
        config: is a dict from the schema
    Returns:
        a render.Root object
    """

    #This is the dict which gets filled with infos from the rest calls
    response_dict = {
        "error": "No error",
        "stop_name": "No stop name",
        "stop_id": "No stop id",
        "next_departure_lines": ["No next departures"],
        "next_departure_times": ["No next departures"],
        "next_departure_dates": ["No next departures"],
        "next_departure_destinations": ["No next departures"],
        "next_departure_colors": ["No next departures"],
        "next_departure_times_until": [],
    }

    #Check if the response_dict is cached
    response_dict_cached = cache.get("response_dict")
    if response_dict_cached != None:
        #print("Using cached response_dict")
        response_dict = json.decode(response_dict_cached)
    else:
        #print("Performing new API calls")
        #Get the infos of the nearest stop
        response_dict = get_stop_infos(config, response_dict)

        #Get the next departures if stop was found
        if ((response_dict["error"] == "No error") and (response_dict["stop_id"] != "No stop id") and (response_dict["stop_name"] != "No stop name")):
            response_dict = get_next_departures(config, response_dict)

        #If cache time is set to 900s, 100 free API calls per day are not exceeded
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("response_dict", str(response_dict), 1)

    response_dict = calculate_time_until(response_dict)

    response_dict = drop_missed_departures(response_dict)

    #Render the results
    if response_dict["error"] != "No error":
        return render.Root(
            child = render.Row(
                children = [
                    render.WrappedText(
                        content = response_dict["error"],
                        color = "#FFFFFF",
                        align = "left",
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            show_full_animation = True,
            child = render.Column(
                children = [
                    render_station(response_dict),
                    render_departure(response_dict, dep_number = 0),
                    render_departure(response_dict, dep_number = 1),
                    render_departure(response_dict, dep_number = 2),
                ],
            ),
        )

def get_stop_infos(config, response_dict):
    """gets the stop infos from the VAO API.

    Args:
        config: is a dict from the schema
        response_dict: is a dict with the stop infos
    Returns:
        a dict with the stop infos
    """

    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    rest_call_stop_info = BASE_REST_CALL.format(
        endpoint = "location.nearbystops",
        api_key = config.get("key"),  #for testing and screenshots, paste API key here
    ) + "&originCoordLat={lat}&originCoordLong={long}&maxNo{maxNo}".format(
        #use the coordinates for screenshot
        lat = loc["lat"],  #"48.185051"
        long = loc["lng"],  #"16.377473"
        maxNo = "1",
    )

    response = http.get(url = rest_call_stop_info)
    if response.status_code != 200:
        response_dict["error"] = "Stopfinder request failed with status {statuscode}".format(
            statuscode = response.status_code,
        )
        return response_dict

    data = json.decode(response.body())

    #if key 'stopLocationOrCoordLocation' is not in data, set response_dict["error"] to "No stop found within 1000 meters" and return
    if "stopLocationOrCoordLocation" not in data:
        response_dict["error"] = "No stop found within 1000 meters"
        return response_dict
    else:
        response_dict["stop_name"] = data["stopLocationOrCoordLocation"][0]["StopLocation"]["name"]
        response_dict["stop_id"] = data["stopLocationOrCoordLocation"][0]["StopLocation"]["extId"]

    return response_dict

def get_next_departures(config, response_dict):
    """gets the next departures from the VAO API.

    Args:
        config: is a dict from the schema
        response_dict: is a dict with the stop infos
    Returns:
        a dict with the next departures"""

    rest_call_next_departures = BASE_REST_CALL.format(
        endpoint = "departureBoard",
        api_key = config.get("key"),  #for testing and screenshots, paste API key here
    ) + "&id={stop_id}".format(
        stop_id = response_dict["stop_id"],
    )

    response = http.get(url = rest_call_next_departures)
    if response.status_code != 200:
        response_dict["error"] = "Departurefinder request failed with status {statuscode}".format(
            statuscode = response.status_code,
        )
        return response_dict

    data = json.decode(response.body())

    #if key 'Departure' is not in data, set response_dict["error"] to "No departures found" and return
    if "Departure" not in data:
        response_dict["error"] = "No departures found"
        return response_dict
    else:
        response_dict["next_departure_lines"] = [entry["name"] for entry in data["Departure"]]
        response_dict["next_departure_times"] = [entry["time"] for entry in data["Departure"]]
        response_dict["next_departure_dates"] = [entry["date"] for entry in data["Departure"]]
        response_dict["next_departure_colors"] = [entry["ProductAtStop"]["icon"]["backgroundColor"]["hex"] for entry in data["Departure"]]
        response_dict["next_departure_destinations"] = [entry["direction"] for entry in data["Departure"]]

    return response_dict

def calculate_time_until(response_dict):
    """calculates the time until the next departures.

    Args:
        response_dict: is a dict with the next departures
    Returns:
        a dict with the time until the next departures"""

    #Get the current time
    now = time.now()

    #Get time and date from response dict and calculate the time until departure
    #Format strings to only numbers in minutes
    for t, d in zip(response_dict["next_departure_times"], response_dict["next_departure_dates"]):
        if t != "No next departures":
            time_from_response = d + "T" + t
            deptime = time.parse_time(time_from_response, "2006-01-02T15:04:05", "Europe/Berlin")
            duration_until_departure = humanize.relative_time(now, deptime)

            #humanize.relative_time has no negative time, if now is greater than deptime, so calculate differently
            real_time_difference = now - deptime
            if now + real_time_difference < now:
                #split the string at the first space
                duration_until_departure = duration_until_departure.split(" ", 1)
                if "seconds" in duration_until_departure[1]:
                    duration_until_departure[0] = "now"
            else:
                duration_until_departure = ["missed departure"]

            response_dict["next_departure_times_until"].append(duration_until_departure[0])

    return response_dict

def render_station(response_dict):
    """renders the station name.

    Args:
        response_dict: is a dict with the stop infos
    Returns:
        a render object displaying the station name"""
    return render.Stack(
        children = [
            render.Plot(width = 64, height = 8, x_lim = (0, 1), y_lim = (0, 8), data = UNDERLINE, color = "#FFFFFF"),
            render.Marquee(
                width = 64,
                child = render.Text(content = response_dict["stop_name"], color = "FFAF0F"),
            ),
        ],
    )

def render_departure(response_dict, dep_number):
    """renders the next departures.

    Args:
        response_dict: is a dict with the next departures
        dep_number: is the number of the departure to render
    Returns:
        a render object displaying the next departures"""

    #Colors are static, as colors from VAO API are return many very black values. Black value
    #handler is not implemented yet
    return render.Row(
        children = [
            render.Text(content = response_dict["next_departure_times_until"][dep_number], color = "#099"),
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = response_dict["next_departure_lines"][dep_number] +
                              " Destination: " + response_dict["next_departure_destinations"][dep_number],
                    color = "#FFFFFF",
                ),
            ),
        ],
    )

def drop_missed_departures(response_dict):
    """drops the missed departures so even if caching 900s is on, only future departures are shown.

    Args:
        response_dict: is a dict with the next departures
    Returns:
        a dict with the next departures without missed departures"""

    #loop through list and drop all entries with "missed departure" and all entries on the same index in other list
    count = 0
    for departure in response_dict["next_departure_times_until"]:
        if departure == "missed departure":
            count += 1

    response_dict["next_departure_lines"] = response_dict["next_departure_lines"][count:]
    response_dict["next_departure_times"] = response_dict["next_departure_times"][count:]
    response_dict["next_departure_dates"] = response_dict["next_departure_dates"][count:]
    response_dict["next_departure_destinations"] = response_dict["next_departure_destinations"][count:]
    response_dict["next_departure_colors"] = response_dict["next_departure_colors"][count:]
    response_dict["next_departure_times_until"] = response_dict["next_departure_times_until"][count:]

    return response_dict

def get_schema():
    """returns the schema of the app"""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "API key",
                desc = "Paste your VAO API Key here, you can get it from https://www.verkehrsauskunft.at/start",
                icon = "gear",
            ),
            schema.Location(
                id = "location",
                name = "Your preferred stop",
                desc = "Search for any location to find the stop you want to use",
                icon = "locationDot",
            ),
        ],
    )

"""
Applet: World Tides
Summary: Display global tides
Description: Display global tide predictions in list format.
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

debug = False  #  debug mode will not hit network apis
print_debug = True

DEFAULT_LOCATION = """
  {
	"lat": "20.891111111",
	"lng": "-156.501111111",
	"description": "Wailuku, HI, USA",
	"locality": "Maui",
	"timezone": "Pacific/Honolulu"
}
"""

DATUM = "MLLW"
API_URL_HILO = "https://api.stormglass.io/v2/tide/extremes/point?lat=%s&lng=%s&start=%s&end=%s&datum=%s"
API_URL_GRAPH = "https://api.stormglass.io/v2/tide/sea-level/point?lat=%s&lng=%s&start=%s&end=%s&datum=%s"

def debug_print(arg):
    if print_debug:
        print(arg)

def get_tides_hilo(api_key, lat, lon, start, end, datum):
    tides = {}
    url = API_URL_HILO % (lat, lon, start, end, datum)
    debug_print("HILO Url : " + url)
    if not debug:
        resp = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 0)  # cache for 4 hours (tides don't change much)

        # we don't check for http 200 here because an error will have an "errors" key in the json and so we check for that later
        tides = json.decode(resp.body())
    else:  # in debug mode return None so main program will just use hilo data for graphing
        tides_json = """{"data": [{"height": 0.14883773536746614, "time": "2024-09-27T14:51:00+00:00", "type": "low"}, {"height": 0.7378985547873065, "time": "2024-09-27T22:17:00+00:00", "type": "high"}, {"height": 0.1888841019406355, "time": "2024-09-28T05:19:00+00:00", "type": "low"}], "meta": {"cost": 1, "dailyQuota": 10, "datum": "MLLW", "end": "2024-09-28 09:59", "lat": 20.89, "lng": -156.5, "offset": -0.34, "requestCount": 7, "start": "2024-09-27 10:00", "station": {"distance": 2, "lat": 20.895, "lng": -156.476694, "name": "kahului, kahului harbor, hi", "source": "noaa"}}}"""
        tides = json.decode(tides_json)
    return tides

def get_tides_graph(api_key, lat, lon, start, end, datum):
    tides = {}
    url = API_URL_GRAPH % ((lat, lon, start, end, datum))
    debug_print("Graph Url : " + url)
    if not debug:
        resp = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 0)  # cache for 4 hours (tides don't change much)

        # print(resp.headers.get("Tidbyt-Cache-Status"))
        # we don't check for http 200 here because an error will have an "errors" key in the json and so we check for that later
        tides = json.decode(resp.body())
    else:
        tides = json.decode("""{"data": [{"sg": 0.31, "time": "2024-09-27T10:00:00+00:00"}, {"sg": 0.29, "time": "2024-09-27T11:00:00+00:00"}, {"sg": 0.25, "time": "2024-09-27T12:00:00+00:00"}, {"sg": 0.2, "time": "2024-09-27T13:00:00+00:00"}, {"sg": 0.16, "time": "2024-09-27T14:00:00+00:00"}, {"sg": 0.15, "time": "2024-09-27T15:00:00+00:00"}, {"sg": 0.18, "time": "2024-09-27T16:00:00+00:00"}, {"sg": 0.25, "time": "2024-09-27T17:00:00+00:00"}, {"sg": 0.35, "time": "2024-09-27T18:00:00+00:00"}, {"sg": 0.48, "time": "2024-09-27T19:00:00+00:00"}, {"sg": 0.6, "time": "2024-09-27T20:00:00+00:00"}, {"sg": 0.69, "time": "2024-09-27T21:00:00+00:00"}, {"sg": 0.74, "time": "2024-09-27T22:00:00+00:00"}, {"sg": 0.72, "time": "2024-09-27T23:00:00+00:00"}, {"sg": 0.66, "time": "2024-09-28T00:00:00+00:00"}, {"sg": 0.55, "time": "2024-09-28T01:00:00+00:00"}, {"sg": 0.43, "time": "2024-09-28T02:00:00+00:00"}, {"sg": 0.31, "time": "2024-09-28T03:00:00+00:00"}, {"sg": 0.23, "time": "2024-09-28T04:00:00+00:00"}, {"sg": 0.19, "time": "2024-09-28T05:00:00+00:00"}, {"sg": 0.2, "time": "2024-09-28T06:00:00+00:00"}, {"sg": 0.24, "time": "2024-09-28T07:00:00+00:00"}, {"sg": 0.3, "time": "2024-09-28T08:00:00+00:00"}, {"sg": 0.35, "time": "2024-09-28T09:00:00+00:00"}], "meta": {"cost": 1, "dailyQuota": 10, "datum": "MLLW", "end": "2024-09-28 09:59", "lat": 20.89, "lng": -156.5, "offset": -0.34, "requestCount": 8, "start": "2024-09-27 10:00", "station": {"distance": 2, "lat": 20.895, "lng": -156.476694, "name": "kahului, kahului harbor, hi", "source": "noaa"}}}""")
    return tides

def utc_to_local(utc, tz):
    utc_time = time.parse_time(utc)

    # Convert UTC time to your local timezone (adjust "Local" to your actual timezone)
    local_time = utc_time.in_location(tz)

    # Format the local time as a string
    return local_time.format("2006-01-02 15:04:05")

def error(reason):
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                cross_align = "center",
                main_align = "space_evenly",
                children = [
                    render.Text(
                        content = "Error:",
                        font = "tb-8",
                        color = "#FF5500",
                    ),
                    render.WrappedText(
                        content = reason,
                        font = "tb-8",
                        color = "#FF0000",
                    ),
                ],
            ),
        ),
    )

def main(config):
    debug_print("Program Start ############################################################")
    units = "ft"

    # get preferences
    units_pref = config.get("h_units", "feet")
    time_format = config.get("time_format", "24HR")
    station_name = config.get("station_name")  #  we want this to be blank or None
    color_label = config.get("label_color", "#0a0")  # green
    color_low = config.get("low_color", "#A00")  # red
    color_high = config.get("high_color", "#D2691E")  # nice orange
    y_lim_min = config.get("y_lim_min", 0)
    y_lim_max = config.get("y_lim_max", None)
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = math.round(1000.0 * float(location["lat"])) / 1000.0  # Truncate to 3dp for better caching and to protect user privacy
    lon = math.round(1000.0 * float(location["lng"])) / 1000.0
    tz = location["timezone"]
    debug_print(tz)
    api_key = config.get("api_key", "")
    if api_key == "":
        return error("No API Key")

    now = time.now().in_location(tz)

    # Create the start of the day (00:00) for today
    start_local = time.time(year = now.year, month = now.month, day = now.day, hour = 0, minute = 0, second = 0, location = tz)

    # Create the end of the day (23:59) for today
    end_local = time.time(year = now.year, month = now.month, day = now.day, hour = 23, minute = 59, second = 0, location = tz)

    # Convert both times to UTC
    start_utc = start_local.in_location("UTC")
    end_utc = end_local.in_location("UTC")

    # Format the times into the desired string format
    start = start_utc.format("2006-01-02T15:04")
    end = end_utc.format("2006-01-02T15:04")

    ################################ CACHINE CODE
    tides_hilo = {}

    #load HILO cache
    cache_key_hilo = "world_tides_%s_%s" % (lat + lon, start)
    cache_str_hilo = cache.get(cache_key_hilo)  #  not actually a json object yet, just a string

    #load GRAPH cache
    cache_key_graph = "world_tides_graph_%s_%s" % (lat + lon, start)
    cache_str_graph = cache.get(cache_key_graph)
    debug_print("cache keys : %s , %s" % (cache_key_hilo, cache_key_graph))

    tides_graph = {}

    if cache_str_hilo != None:
        debug_print("loading cached hilo data")
        tides_hilo = json.decode(cache_str_hilo)
    if cache_str_graph != None:
        debug_print("loading cached graph data")
        tides_graph = json.decode(cache_str_graph)

    if len(tides_hilo) == 0:  # len(None) is 0 too
        debug_print("pulling fresh tide data")

        tides_hilo = get_tides_hilo(api_key, lat, lon, start, end, DATUM)
        if "errors" in tides_hilo:
            return error(tides_hilo["errors"].values()[0])
        if tides_hilo != None:
            cache.set(cache_key_hilo, json.encode(tides_hilo), ttl_seconds = 86400)  # 24 hours

        tides_graph = get_tides_graph(api_key, lat, lon, start, end, DATUM)
        if tides_graph != None:
            cache.set(cache_key_graph, json.encode(tides_graph), ttl_seconds = 86400)  # 24 hours

    # debug_print(tides_hilo)
    # debug_print(tides_graph)
    # if tides_hilo != None:
    #     # TODO: Determine if this cache call can be converted to the new HTTP cache.
    #     cache.set(cache_key_hilo, json.encode(tides_hilo), ttl_seconds = 14400)  # 4 hours

    #     # TODO: Determine if this cache call can be converted to the new HTTP cache.
    #     cache.set(cache_key_graph, json.encode(tides_graph), ttl_seconds = 14400)  # 4 hours

    # debug_print("Tides HILO : " + str(tides_hilo))
    # debug_print("Tides GRAPH: " + str(tides_graph))
    line_color = color_low
    lines = list()
    points = []

    # generate up HILO lines
    debug_print("generating hilos")
    if tides_hilo != None and "data" in tides_hilo:
        debug_print("tide data is present")
        if station_name == None or station_name == "":  # set via config.get at the top
            station_name = tides_hilo["meta"]["station"]["name"].split(",")[0].title()
            # if station name is short enough we can use tb-8

        if len(station_name) < 12:
            lines.append(render.Text(content = station_name, color = color_label, font = "tb-8"))
        else:
            if len(station_name) > 16:
                station_name = station_name[0:16]
            lines.append(render.Text(content = station_name, color = color_label, font = "tom-thumb"))
        for pred in tides_hilo["data"]:
            _type = "L"
            if "high" in pred["type"]:
                _type = "H"
            if units_pref == "meters":
                v = int((float(pred["height"]) + 0.05) * 10) / 10.0  # round to 1 decimal
                units = "m"
            else:
                v = int((float(pred["height"]) * 3.28 + 0.05) * 10) / 10.0  # round to 1 decimal
            if y_lim_min == "" or v < int(y_lim_min):
                y_lim_min = v  # set the lower level of graph to be the lowest negative

            #  probably need to convert back to local here
            t = utc_to_local(pred["time"], tz)[11:16]  # strip the date from the front = start to first occurence of a space
            if time_format == "AMPM":
                m = "A"
                hr = int(t[0:2])
                debug_print(hr)
                mn = t[3:5]
                if hr > 11:
                    m = "P"
                    if hr > 12:
                        hr = hr - 12
                if hr < 10:  # pad a space
                    if hr == 0:
                        hr = "12"
                    else:
                        hr = "0" + str(hr)

                left_side = "%s %s:%s%s" % (_type, hr, mn, m)
                right_side = "%s%s" % (v, units)
            else:
                left_side = "%s %s" % (_type, t)
                right_side = "%s%s" % (v, units)
            if "H" in _type:
                line_color = color_high
            else:
                line_color = color_low

            lines.append(
                render.Row(
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "start",
                            cross_align = "bottom",
                            children = [render.Text(
                                content = left_side,
                                font = "tom-thumb",
                                color = line_color,
                            )],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "end",
                            children = [render.Text(
                                content = right_side,
                                font = "tom-thumb",
                                color = line_color,
                            )],
                        ),
                    ],
                ),
            )

        # Create the graph points list and populate it
        height_key = "sg"
        if tides_graph == None or "data" not in tides_graph:
            tides_graph = tides_hilo
            height_key = "height"
        x = 0
        for height_at_time in tides_graph["data"]:
            points.append((x, float(height_at_time[height_key] * 3.3)))
            x = x + 1

    else:  # append error message to lines, return it down below
        lines.append(render.WrappedText(
            content = "Enter API Key",
            font = "tb-8",
            color = "#FF0000",
            align = "center",
        ))

    main_text = render.Box(
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = lines,
        ),
    )
    data_graph = None
    if len(points) > 0:
        if y_lim_max == "":
            y_lim_max = None
        elif y_lim_max != None:
            y_lim_max = int(y_lim_max)
        data_graph = render.Plot(
            data = points,
            width = 64,
            height = 32,
            color = "#00c",  #00c
            color_inverted = "#505",
            fill = True,
            y_lim = (int(y_lim_min), y_lim_max),
        )
    root_children = [main_text]

    if config.bool("display_graph") and len(points) > 0:  # panic if we try to render an empty graph object
        root_children = [data_graph, main_text]

    return render.Root(
        render.Stack(
            children = root_children,
        ),
    )

COLOR_LIST = {
    "White": "#fff",
    "Cyan": "#0ff",
    "Red": "#a00",
    "Green": "#0a0",
    "Blue": "#00a",
    "Orange": "#D2691E",
}

def get_schema():
    colors = [
        schema.Option(display = key, value = value)
        for key, value in COLOR_LIST.items()
    ]
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    time_formats = [
        schema.Option(display = "24HR", value = "24HR"),
        schema.Option(display = "AM/PM", value = "AMPM"),
    ]
    fields = []

    fields.append(
        schema.Text(
            id = "api_key",
            name = "StormGlass API Key",
            icon = "key",
            desc = "Mandatory Personal API Key",
            default = "",
        ),
    )
    fields.append(
        schema.Location(
            id = "location",
            name = "Location",
            desc = "Location for which to display tide.",
            icon = "locationDot",
        ),
    )

    fields.append(
        schema.Text(
            id = "station_name",
            name = "Custom Display Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )
    fields.append(
        schema.Color(
            id = "label_color",
            name = "Label Color",
            icon = "brush",
            desc = "The color to use for station label.",
            default = colors[3].value,
        ),
    )
    fields.append(
        schema.Color(
            id = "high_color",
            name = "High Tide Color",
            icon = "brush",
            desc = "The color to use for high tides.",
            default = colors[5].value,
        ),
    )
    fields.append(
        schema.Color(
            id = "low_color",
            name = "Low Tide Color",
            icon = "brush",
            desc = "The color to use for low tides.",
            default = colors[2].value,
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "time_format",
            name = "Time Format",
            icon = "quoteRight",
            desc = "Use AM/PM or 24 hour time",
            options = time_formats,
            default = "24HR",
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "h_units",
            name = "Height Units",
            icon = "quoteRight",
            desc = "Tide height units preference",
            options = h_unit_options,
            default = "feet",
        ),
    )

    fields.append(
        schema.Toggle(
            id = "display_graph",
            name = "Display Graph",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = True,
        ),
    )
    fields.append(
        schema.Text(
            id = "y_lim_min",
            name = "Graph minimum",
            desc = "Scale the graph by setting a local tide maximum. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )
    fields.append(
        schema.Text(
            id = "y_lim_max",
            name = "Graph maximum",
            desc = "Scale the graph by setting a local tide maximum. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    )
    return schema.Schema(
        version = "1",
        fields = fields,
    )

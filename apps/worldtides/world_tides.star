"""
Applet: World Tides
Summary: Display global tides
Description: Display global tide predictions in list format.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

production = True
debug = False  #  debug mode will not hit network apis
print_debug = True

DEFAULT_LOCATION = """
  {
	"lat": "20.89",
	"lng": "-156.50",
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

def get_tides_hilo(api_key,lat,lon,start,end,datum):
    tides = {}
    url = API_URL_HILO % (lat,lon,start,end,datum)
    debug_print("HILO Url : " + url)
    if not debug:
        resp = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 0)  # cache for 4 hours (tides don't change much)
        if resp.status_code != 200:
            tides = None
        else:
            tides = json.decode(resp.body())
            debug_print(tides)
    else:  # in debug mode return None so main program will just use hilo data for graphing
        # tides_json = """{"predictions": [{"t": "2022-03-04 00:19", "v": "1.630", "type": "H"}, {"t": "2022-03-04 11:05", "v": "-5.532", "type": "L"}, {"t": "2022-03-04 17:10", "v": "12.85", "type": "H"}, {"t": "2022-03-04 22:52", "v": "-1.058", "type": "L"}]}"""
        tides_json = """{"data":[{"height":0.1704194207101767,"time":"2024-09-26T13:19:00+00:00","type":"low"},{"height":0.718609558578788,"time":"2024-09-26T21:42:00+00:00","type":"high"},{"height":0.21023378849638952,"time":"2024-09-27T05:21:00+00:00","type":"low"},{"height":0.30855932928070645,"time":"2024-09-27T09:43:00+00:00","type":"high"}],"meta":{"cost":1,"dailyQuota":10,"datum":"MLLW","end":"2024-09-27 09:59","lat":20.89,"lng":-156.5,"offset":-0.34,"requestCount":2,"start":"2024-09-26 10:00","station":{"distance":2,"lat":20.895,"lng":-156.476694,"name":"kahului, kahului harbor, hi","source":"noaa"}}}"""
        tides = json.decode(tides_json)
    return tides

def get_tides_graph(api_key,lat,lon,start,end,datum):
    tides = {}
    url = API_URL_GRAPH % ((lat,lon,start,end,datum))
    debug_print("Graph Url : " + url)
    if not debug:
        resp = http.get(url, headers = {"Authorization": api_key}, ttl_seconds = 0)  # cache for 4 hours (tides don't change much)
        print(resp.headers.get("Tidbyt-Cache-Status"))
        if resp.status_code != 200:
            tides = None
        else:
            tides = json.decode(resp.body())
    else:
        tides = json.decode("""{"data":[{"sg":0.22,"time":"2024-09-26T10:00:00+00:00"},{"sg":0.21,"time":"2024-09-26T11:00:00+00:00"},{"sg":0.18,"time":"2024-09-26T12:00:00+00:00"},{"sg":0.17,"time":"2024-09-26T13:00:00+00:00"},{"sg":0.18,"time":"2024-09-26T14:00:00+00:00"},{"sg":0.21,"time":"2024-09-26T15:00:00+00:00"},{"sg":0.27,"time":"2024-09-26T16:00:00+00:00"},{"sg":0.36,"time":"2024-09-26T17:00:00+00:00"},{"sg":0.46,"time":"2024-09-26T18:00:00+00:00"},{"sg":0.57,"time":"2024-09-26T19:00:00+00:00"},{"sg":0.65,"time":"2024-09-26T20:00:00+00:00"},{"sg":0.71,"time":"2024-09-26T21:00:00+00:00"},{"sg":0.72,"time":"2024-09-26T22:00:00+00:00"},{"sg":0.68,"time":"2024-09-26T23:00:00+00:00"},{"sg":0.6,"time":"2024-09-27T00:00:00+00:00"},{"sg":0.5,"time":"2024-09-27T01:00:00+00:00"},{"sg":0.4,"time":"2024-09-27T02:00:00+00:00"},{"sg":0.31,"time":"2024-09-27T03:00:00+00:00"},{"sg":0.24,"time":"2024-09-27T04:00:00+00:00"},{"sg":0.21,"time":"2024-09-27T05:00:00+00:00"},{"sg":0.22,"time":"2024-09-27T06:00:00+00:00"},{"sg":0.24,"time":"2024-09-27T07:00:00+00:00"},{"sg":0.28,"time":"2024-09-27T08:00:00+00:00"},{"sg":0.3,"time":"2024-09-27T09:00:00+00:00"}],"meta":{"cost":1,"dailyQuota":10,"datum":"MLLW","end":"2024-09-27 09:59","lat":20.89,"lng":-156.5,"offset":-0.34,"requestCount":4,"start":"2024-09-26 10:00","station":{"distance":2,"lat":20.895,"lng":-156.476694,"name":"kahului, kahului harbor, hi","source":"noaa"}}}""")
    return tides

def utc_to_local(utc,tz):
    utc_time = time.parse_time(utc)
    # Convert UTC time to your local timezone (adjust "Local" to your actual timezone)
    local_time = utc_time.in_location(tz)

    # Format the local time as a string
    return local_time.format("2006-01-02 15:04:05")
    

def main(config):
    debug_print("Program Start ############################################################")
    units = "ft"

    # get preferences
    units_pref = config.get("h_units", "feet")
    time_format = config.get("time_format", "24HR")
    custom_lat = config.get("custom_lat", "")
    custom_lon = config.get("custom_long","")
    station_name = config.get("station_name")  #  we want this to be blank or None
    color_label = config.get("label_color", "#0a0")  # green
    color_low = config.get("low_color", "#A00")  # red
    color_high = config.get("high_color", "#D2691E")  # nice orange
    y_lim_min = config.get("y_lim_min", "")
    y_lim_max = config.get("y_lim_max", "")
    location = json.decode(config.get("location",DEFAULT_LOCATION))
    lat = location['lat']
    lon = location['lng']
    tz = location['timezone']
    debug_print(tz)
    # api_key = config.get("api_key","de381698-7c4f-11ef-95ed-0242ac130004-de381738-7c4f-11ef-95ed-0242ac130004")
    api_key = config.get("api_key","")
    need_api_key = False
    if api_key == "":
        need_api_key = True

    now = time.now().in_location(tz)

    # Create the start of the day (00:00) for today
    start_local = time.time(year=now.year, month=now.month, day=now.day, hour=0, minute=0, second=0,location=tz)
    
    # Create the end of the day (23:59) for today
    end_local = time.time(year=now.year, month=now.month, day=now.day, hour=23, minute=59, second=0,location=tz)

    # Convert both times to UTC
    start_utc = start_local.in_location("UTC")
    end_utc = end_local.in_location("UTC")

    # Format the times into the desired string format
    start = start_utc.format("2006-01-02T15:04")
    end = end_utc.format("2006-01-02T15:04")  


    ################################ CACHINE CODE
    tides_hilo = {}

    # #load HILO cache
    # cache_key_hilo = "noaa_tides_%s" % (station_id)
    # cache_str_hilo = cache.get(cache_key_hilo)  #  not actually a json object yet, just a string

    # #load GRAPH cache
    # cache_key_graph = "noaa_tides_graph_%s" % (station_id)
    # cache_str_graph = cache.get(cache_key_graph)

    tides_graph = {}

    # # if cache_str_hilo != None:
    # #     debug_print("loading cached data")
    # #     tides_hilo = json.decode(cache_str_hilo)
    # #     tides_graph = json.decode(cache_str_graph)
    # if len(tides_hilo) == 0:
    #     debug_print("pulling fresh tide data")
    tides_hilo = get_tides_hilo(api_key,lat,lon,start,end,DATUM)
    tides_graph = get_tides_graph(api_key,lat,lon,start,end,DATUM)
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
    if tides_hilo != None and "data" in tides_hilo and need_api_key != True:
        debug_print("tide data is present")
        if station_name == None or station_name == "":  # set via config.get at the top
            station_name = tides_hilo['meta']['station']['name'].split(',')[0].title()
            # if station name is short enough we can use tb-8
        if len(station_name) < 12:
            lines.append(render.Text(content = station_name, color = color_label, font = "tb-8"))
        else:
            if len(station_name) > 16:
                station_name = station_name[0:16]
            lines.append(render.Text(content = station_name, color = color_label, font = "tom-thumb"))
        for pred in tides_hilo["data"]:
            _type = "L"
            if "high" in pred['type']:
                _type = "H"
            if units_pref == "meters":
                v = int((float(pred["height"]) + 0.05) * 10) / 10.0  # round to 1 decimal
                units = "m"
            else:
                v = int((float(pred["height"]) * 3.28  + 0.05 ) * 10) / 10.0  # round to 1 decimal

            if y_lim_min == "" or v < y_lim_min:
                y_lim_min = v  # set the lower level of graph to be the lowest negative
            #  probably need to convert back to local here
            t = utc_to_local(pred["time"],tz)[11:16]  # strip the date from the front = start to first occurence of a space
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
        if tides_graph == None or "data" not in tides_graph:
            tides_graph = tides_hilo
        x = 0
        for height_at_time in tides_graph["data"]:
            points.append((x, float(height_at_time["sg"]*3.3)))
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
    if need_api_key != True and len(points) > 0:
        if y_lim_max == "":
            y_lim_max = None
        elif y_lim_max != None:
            y_lim_max = float(y_lim_max)
        data_graph = render.Plot(
            data = points,
            width = 64,
            height = 32,
            color = "#00c",  #00c
            color_inverted = "#505",
            fill = True,
            y_lim = (y_lim_min, y_lim_max),
        )
    root_children = [main_text]

    if config.bool("display_graph") and len(points) > 0 and need_api_key != True:  # panic if we try to render an empty graph object
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
    # if not production:
    #     stations_list = get_stations((default_location))  # locationbased schema don't work so use default location
    #     fields.append(
    #         schema.Dropdown(
    #             id = "local_station_id",
    #             name = "Local Tide Station",
    #             icon = "monument",
    #             desc = "Debug Location Stations",
    #             options = stations_list,
    #             default = "None Found",
    #         ),
    #     )
    # else:  # in production, locationbased schema fields work
        # fields.append(
        #     schema.LocationBased(
        #         id = "local_station_id",
        #         name = "Local Tide Station",
        #         icon = "monument",
        #         desc = "Location Based Stations",
        #         handler = get_stations,
        #     ),
        # )
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
        schema.Text(
            id = "station_name",
            name = "Custom Display Name",
            icon = "user",
            desc = "Optional Custom Label",
            default = "",
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "label_color",
            name = "Label Color",
            icon = "brush",
            desc = "The color to use for station label.",
            default = colors[3].value,
            options = colors,
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "high_color",
            name = "High Tide Color",
            icon = "brush",
            desc = "The color to use for high tides.",
            default = colors[5].value,
            options = colors,
        ),
    )
    fields.append(
        schema.Dropdown(
            id = "low_color",
            name = "Low Tide Color",
            icon = "brush",
            desc = "The color to use for low tides.",
            default = colors[2].value,
            options = colors,
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
        schema.Text(
            id = "custom_lat",
            name = "Custom Location Latitude",
            icon = "monument",
            desc = "Optional manual latitude",
        ),
    )
    fields.append(
        schema.Text(
            id = "custom_lon",
            name = "Custom Location Longitude",
            icon = "monument",
            desc = "Optional manual longitude",
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
    fields.append(
        schema.Location(
            id = "location",
            name = "Location",
            desc = "Location for which to display tide.",
            icon = "locationDot",
        )
    )
    return schema.Schema(
        version = "1",
        fields = fields,
    )

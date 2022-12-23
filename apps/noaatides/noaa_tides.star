"""
Applet: NOAA Tides
Summary: Display NOAA Tides
Description: Display daily tides from NOAA stations.
Author: tavdog
"""

production = True
debug = False  #  debug mode will not hit network apis
print_debug = False

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("xpath.star", "xpath")
load("re.star", "re")
load("humanize.star", "humanize")

default_location = """
  {
	"lat": "20.89",
	"lng": "-156.50",
	"description": "Wailuku, HI, USA",
	"locality": "Maui",
	"timezone": "America/Honolulu"
}
"""
NOAA_API_URL_GRAPH = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=%s&product=predictions&datum=MLLW&time_zone=lst_ldt&units=english&format=json"
NOAA_API_URL_HILO = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=%s&product=predictions&datum=MLLW&time_zone=lst_ldt&units=english&format=json&interval=hilo"

def debug_print(arg):
    if print_debug:
        print(arg)

def get_stations(location):  # assume we have a valid location json string
    location = json.decode(location)
    stations_json = {}
    station_options = list()
    url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/tidepredstations.json?lat=%s&lon=%s&radius=50" % (humanize.float("#.##", float(location["lat"])), humanize.float("#.##", float(location["lng"])))
    debug_print(url)
    if not debug:
        req_result = http.get(url)
        if req_result.status_code == 200:
            stations_json = req_result.body()
    else:
        stations_json = """{
    "stationList": [
    {
      "name": "KAHULUI, KAHULUI HARBOR",
      "state": "HI",
      "region": "Maui Island",
      "timeZoneCorr": "-10",
      "stationName": "Kahului, Kahului Harbor",
      "commonName": "Kahului, Kahului Harbor",
      "distance": 1.5085605251089405,
      "stationFullName": "KAHULUI, KAHULUI HARBOR, MAUI ISLAND",
      "etidesStnName": "KAHULUI",
      "stationId": "1615680",
      "lat": 20.895,
      "lon": -156.4766944444444,
      "refStationId": null,
      "stationType": "R",
      "parentGeoGroupId": "1734",
      "seq": "0",
      "geoGroupId": "1734",
      "geoGroupName": null,
      "level": "7",
      "geoGroupType": "ETIDES",
      "abbrev": null
    },
    {
      "name": "Kihei, Maalaea Bay",
      "state": null,
      "region": "Maui Island",
      "timeZoneCorr": "-10",
      "stationName": "Kihei, Maalaea Bay",
      "commonName": "Kihei, Maalaea Bay",
      "distance": 7.714681369437793,
      "stationFullName": "KIHEI, MAALAEA BAY",
      "etidesStnName": "Kihei, Maalaea Bay",
      "stationId": "TPT2797",
      "lat": 20.78333333333299,
      "lon": -156.46666666667008,
      "refStationId": null,
      "stationType": "S",
      "parentGeoGroupId": "1734",
      "seq": "3",
      "geoGroupId": "1734",
      "geoGroupName": null,
      "level": "7",
      "geoGroupType": "ETIDES",
      "abbrev": null
    }
  ]
  }"""
    stations = json.decode(stations_json)

    if "stationList" in stations and stations["stationList"] != None:
        stations = stations["stationList"]
        debug_print("Found %s stations" % len(stations))
        for station in stations:
            #debug_print("%s : %s" % (station["stationId"],station["name"]))
            station_options.append(
                schema.Option(
                    display = station["name"],
                    value = station["stationId"],
                ),
            )
    else:
        debug_print("no stations in json")
        station_options.append(
            schema.Option(
                display = "No Results",
                value = "",
            ),
        )

    return station_options

    # return decode json object of tide data

def get_tides_hilo(station_id):
    tides = {}
    url = NOAA_API_URL_HILO % (station_id)
    if not debug:
        debug_print("HILO Url : " + url)
        resp = http.get(url)
        if resp.status_code != 200:
            tides = None
        else:
            tides = json.decode(resp.body())
            debug_print(tides)
    else:  # in debug mode return None so main program will just use hilo data for graphing
        tides_json = """{"predictions": [{"t": "2022-03-04 00:19", "v": "1.630", "type": "H"}, {"t": "2022-03-04 11:05", "v": "-5.532", "type": "L"}, {"t": "2022-03-04 17:10", "v": "12.85", "type": "H"}, {"t": "2022-03-04 22:52", "v": "-1.058", "type": "L"}]}"""
        tides = json.decode(tides_json)
    return tides

def get_tides_graph(station_id):
    tides = {}
    url = NOAA_API_URL_GRAPH % (station_id)
    if not debug:
        debug_print("Graph Url : " + url)
        resp = http.get(url)
        if resp.status_code != 200:
            tides = None
        else:
            tides = json.decode(resp.body())
    else:
        tides = None
    return tides

def main(config):
    debug_print("Program Start ############################################################")
    units = "ft"

    # get preferences
    units_pref = config.get("h_units", "feet")
    time_format = config.get("time_format", "24HR")
    station_id = config.get("station_id", "")
    station_name = config.get("station_name")  #  we want this to be blank or None
    color_label = config.get("label_color", "#0a0")  # green
    color_low = config.get("low_color", "#A00")  # red
    color_high = config.get("high_color", "#D2691E")  # nice orange
    y_lim_min = config.get("y_lim_min", 0)
    y_lim_max = config.get("y_lim_max", None)

    # get our station_id
    debug_print("station id from config.get: " + station_id)
    if station_id == "none" or station_id == "" or not station_id:  # if manual input is empty load from local selection
        debug_print("getting local_station_id")
        if production:
            local_selection = config.get("local_station_id", '{"display": "Kahului Harbor", "value": "1613198"}')
        else:
            local_selection = config.get("local_station_id", "1613198")  # default is Waimea

        if local_selection == "None Found":
            local_selection = "1613198"  # config.get bug ?
        debug_print("Local selection : " + local_selection)

        # this is needed for locationbased selection in production environment
        if "value" in local_selection:
            station_id = json.decode(local_selection)["value"]
            if station_name == None or station_name == "":
                station_name = json.decode(local_selection)["display"]
        else:
            station_id = local_selection  # san fran

    debug_print("using station_id: " + station_id)

    ################################ CACHINE CODE
    tides_hilo = {}

    #load HILO cache
    cache_key_hilo = "noaa_tides_%s" % (station_id)
    cache_str_hilo = cache.get(cache_key_hilo)  #  not actually a json object yet, just a string

    #load GRAPH cache
    cache_key_graph = "noaa_tides_graph_%s" % (station_id)
    cache_str_graph = cache.get(cache_key_graph)

    if cache_str_hilo != None:
        debug_print("loading cached data")
        tides_hilo = json.decode(cache_str_hilo)
        tides_graph = json.decode(cache_str_graph)
    if len(tides_hilo) == 0:
        debug_print("pulling fresh tide data")
        tides_hilo = get_tides_hilo(station_id)
        tides_graph = get_tides_graph(station_id)
        if tides_hilo != None:
            cache.set(cache_key_hilo, json.encode(tides_hilo), ttl_seconds = 14400)  # 4 hours
            cache.set(cache_key_graph, json.encode(tides_graph), ttl_seconds = 14400)  # 4 hours

    debug_print("Tides HILO : " + str(tides_hilo))
    debug_print("Tides GRAPH: " + str(tides_graph))
    line_color = color_low
    lines = list()

    # check for custom name label
    debug_print("station_name:" + str(station_name))
    if station_name == None or station_name == "":  # set via config.get at the top
        lines.append(render.Text(content = "NOAA Tides", color = color_label, font = "tb-8"))
    else:
        # if station name is short enough we can use tb-8
        if len(station_name) < 12:
            lines.append(render.Text(content = station_name, color = color_label, font = "tb-8"))
        else:
            if len(station_name) > 16:
                station_name = station_name[0:16]
            lines.append(render.Text(content = station_name, color = color_label, font = "tom-thumb"))

    points = []

    # generate up HILO lines
    debug_print("generating hilos")
    if tides_hilo != None and "predictions" in tides_hilo:
        debug_print("tide data is present")
        for pred in tides_hilo["predictions"]:
            if units_pref == "meters":
                v = int((float(pred["v"]) / 3 + 0.05) * 10) / 10.0  # round to 1 decimal
                units = "m"
            else:
                v = int((float(pred["v"]) + 0.05) * 10) / 10.0  # round to 1 decimal

            if v < y_lim_min:
                y_lim_min = v  # set the lower level of graph to be the lowest negative
            t = pred["t"][11:]  # strip the date from the front = start to first occurence of a space
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

                left_side = "%s %s:%s%s" % (pred["type"], hr, mn, m)
                right_side = "%s%s" % (v, units)
            else:
                left_side = "%s %s" % (pred["type"], t)
                right_side = "%s%s" % (v, units)
            if "H" in pred["type"]:
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
        if tides_graph == None or "predictions" not in tides_graph:
            tides_graph = tides_hilo
        x = 0
        for height_at_time in tides_graph["predictions"]:
            points.append((x, float(height_at_time["v"])))
            x = x + 1

    else:  # append error message to lines, return it down below
        lines.append(render.WrappedText(
            content = "Invalid Station ID",
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
    if not production:
        stations_list = get_stations((default_location))  # locationbased schema don't work so use default location
        fields.append(
            schema.Dropdown(
                id = "local_station_id",
                name = "Local Tide Station",
                icon = "monument",
                desc = "Debug Location Stations",
                options = stations_list,
                default = "None Found",
            ),
        )
    else:  # in production, locationbased schema fields work
        fields.append(
            schema.LocationBased(
                id = "local_station_id",
                name = "Local Tide Station",
                icon = "monument",
                desc = "Location Based Stations",
                handler = get_stations,
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
            id = "station_id",
            name = "Manual Station ID Input",
            icon = "monument",
            desc = "Optional manual station id",
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
